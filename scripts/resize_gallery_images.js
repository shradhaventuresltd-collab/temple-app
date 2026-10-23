/**
 * Write `_1080` Storage copies for every temple photo and store the
 * download URL on `photos[].galleryUrl`. List and mosaic covers keep
 * `photos[].thumbUrl` at 480. This script does not write the index.
 *
 * Dry-run is the default. It reads temple documents and prints which
 * objects would gain a `temples/{id}/{file}_1080_g{generation}.jpg` sibling.
 * It does not write. Reads and uploads use only
 * temple-directory-india.firebasestorage.app. A photo whose URL names
 * another bucket is skipped and logged. --apply refuses --bucket for any
 * other name.
 *
 *   node scripts/resize_gallery_images.js --project temple-directory-india
 *   node scripts/resize_gallery_images.js --limit 25 --resume --project temple-directory-india
 *
 * A prod apply asks you to type the project id. There is no default
 * project. Apply uploads gallery copies and writes `photos[].galleryUrl`.
 * It does not deploy.
 *
 *   node scripts/resize_gallery_images.js --apply --project temple-directory-india
 *
 * The object name includes the source generation. A photo that already has
 * galleryUrl is left alone, even when the source is newer. The upload uses
 * ifGenerationMatch: 0, so an object that is already there is not overwritten.
 * Images whose long edge is already under 1080 are not enlarged. An encoded
 * copy that is not smaller than the source is not uploaded and galleryUrl
 * stays unset, so the app keeps the smaller original.
 *
 * One transaction per temple writes galleryUrl on the photos whose url still
 * matches. A photo whose url changed is skipped. Other photos in that
 * temple are still written. The index is not updated.
 *
 * Fetch, Storage, Firestore, image encoding, the resume file, and admin
 * init abort after --timeout-ms (default 60000) and retry with backoff.
 * A Firestore write that times out is re-read before the next try. When
 * galleryUrl already equals the target, or the download token or the
 * gallery object checksum matches, the photo is counted as linked after
 * timeout and is not written again. A resume row that is already on disk
 * is not recorded a second time.
 * Apply prints a progress line per batch and a final summary of written,
 * failed, and skipped photos. APPLY-FINISHED is printed only when every
 * photo succeeded. A failed photo prints APPLY-INCOMPLETE and the process
 * exits non-zero. If the run never reaches that summary, beforeExit prints
 * APPLY-INCOMPLETE and exits 1.
 *
 * Encoding uses encodeGalleryJpeg in resize_cover_thumbs.js (sharp).
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { randomUUID } from "node:crypto";
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken, redactThrown } from "./redact_url.js";
import {
  DEFAULT_TIMEOUT_MS,
  attemptWithTimeout,
  beginRun,
  boundIo,
  callBounded,
  chunk,
  failureText,
  finishRun,
  incompleteOnBeforeExit,
  isTimeoutError,
  logBatch,
  networkLimits,
  objectAfterUploadTimeout,
  parseTimeoutMs,
  readWithSignal,
  reportProcessFault,
  writeWithSignal,
} from "./run_guard.js";
import {
  encodeGalleryJpeg,
  firebaseDownloadUrl,
  firebaseMediaUrl,
  staysFullSizeWikimedia,
  thumbSaveOptions,
  usesEmulator,
  verifyPublicObject,
} from "./resize_cover_thumbs.js";
import {
  assertApplyBucket,
  assertStorageAuth,
  isLockedStorageBucket,
  STORAGE_AUTH_BUCKET,
  useNativeFetchForStorageAuth,
} from "./storage_auth.js";
import { galleryObjectPath, storageObjectFromUrl } from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const runTracker = { active: false, summarized: false, rows: [], started: 0 };
let ioLimits = networkLimits({});

export const GALLERY_CACHE_CONTROL = "public, max-age=31536000, immutable";
export const RESUME_FILE = resolve(__dirname, ".resize_gallery_images.resume.json");

function printUsage() {
  console.log(`
Usage:
  node resize_gallery_images.js [--dry-run] [--limit N] [--resume] [--project <id>]
  node resize_gallery_images.js --apply [--limit N] [--resume] --project <id>

Reads and uploads use only temple-directory-india.firebasestorage.app.
A photo URL that names another bucket is skipped. --apply --bucket <other>
is refused.

Default is dry-run: list photos that still need a _1080 sibling.
Nothing is written. prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.

--limit N stops after N photos that still need a gallery copy.
--resume skips a photo only when scripts/.resize_gallery_images.resume.json
records that photo URL for this project. Apply rewrites the file after
each temple whose galleryUrl values were stored.
--timeout-ms N aborts each fetch, Storage call, and Firestore write after
N milliseconds (default 60000) and retries it with backoff.

Apply writes the gallery object with a Firebase download token, checks that
URL, then one transaction per temple for photos[].galleryUrl. A photo whose
url changed is skipped. thumbUrl and the index are not changed.
`);
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    project: null,
    bucket: null,
    help: false,
    limit: null,
    resume: false,
    timeoutMs: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--resume") opts.resume = true;
    else if (arg === "--limit") {
      const parsed = Number(argv[++i]);
      if (!Number.isInteger(parsed) || parsed < 1) {
        throw new Error("--limit needs a positive integer.");
      }
      opts.limit = parsed;
    } else if (arg === "--timeout-ms") opts.timeoutMs = parseTimeoutMs(argv[++i]);
    else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--bucket") opts.bucket = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function resolveProject(opts, env = process.env) {
  if (typeof opts.project === "string" && opts.project.trim() !== "") {
    return assertExplicitProject(opts.project);
  }
  if (usesEmulator(env)) {
    return env.GCLOUD_PROJECT || env.GOOGLE_CLOUD_PROJECT || "demo-temple-index";
  }
  throw new Error(
    "Pass --project <firebase-project-id>. Dry-run reads Firestore and does not write. There is no default project.",
  );
}

export async function authorizeApply(project, env = process.env, deps = {}) {
  assertNotCi(env);
  const id = assertExplicitProject(project);
  if (usesEmulator(env)) return id;
  const confirm = deps.confirm ?? confirmProject;
  return confirm(id);
}

function downloadToken(url) {
  try {
    return new URL(String(url)).searchParams.get("token") || "";
  } catch {
    return "";
  }
}

/** Generation-named gallery object. Two URLs of that object share a checksum. */
function galleryChecksum(url) {
  const located = storageObjectFromUrl(url);
  if (!located) return "";
  const file = located.objectPath.split("/").pop() || "";
  if (!/_1080_g\d+/.test(file)) return "";
  return `${located.bucket}/${located.objectPath}`;
}

/**
 * True when [existing] is already the gallery this run would store.
 * Equality, the same download token, or the same gallery-object checksum
 * all count. A different object does not.
 */
export function galleryUrlMatchesTarget(existing, target) {
  const left = typeof existing === "string" ? existing.trim() : "";
  const right = typeof target === "string" ? target.trim() : "";
  if (!left.startsWith("https://") || !right.startsWith("https://")) return false;
  if (left === right) return true;
  const tokenA = downloadToken(left);
  const tokenB = downloadToken(right);
  if (tokenA && tokenB && tokenA === tokenB) return true;
  const sumA = galleryChecksum(left);
  const sumB = galleryChecksum(right);
  return sumA !== "" && sumA === sumB;
}

/**
 * Every assignment whose photo is still on [temple] already points at the
 * target gallery. Used after a client timeout, before another write.
 */
export function galleryLinksMatch(temple, assignments) {
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  const storedUrls = [];
  for (const assignment of assignments ?? []) {
    const source = assignment?.source;
    const target = typeof assignment?.galleryUrl === "string" ? assignment.galleryUrl.trim() : "";
    if (!source || !target) return { complete: false, storedUrls: [] };
    const matches = photos.filter((photo) => photo && samePhotoUrl(photo.url, source));
    if (matches.length === 0) return { complete: false, storedUrls: [] };
    if (!matches.every((photo) => galleryUrlMatchesTarget(existingGalleryUrl(photo), target))) {
      return { complete: false, storedUrls: [] };
    }
    storedUrls.push(source);
  }
  return { complete: storedUrls.length > 0 && storedUrls.length === (assignments ?? []).length, storedUrls };
}

/**
 * Record [source] once. A retry that already has the URL returns false so
 * resume state is not counted again.
 */
export function rememberResume(photos, id, source) {
  if (typeof id !== "string" || id === "" || typeof source !== "string" || source === "") return false;
  if (!photos.has(id)) photos.set(id, new Set());
  const set = photos.get(id);
  if (set.has(source)) return false;
  set.add(source);
  return true;
}

function samePhotoUrl(photoUrl, source) {
  const left = typeof photoUrl === "string" ? photoUrl.trim() : "";
  const right = typeof source === "string" ? source.trim() : "";
  if (!left || !right) return false;
  if (left === right) return true;
  const a = storageObjectFromUrl(left);
  const b = storageObjectFromUrl(right);
  if (!a || !b) return false;
  return a.bucket === b.bucket && a.objectPath === b.objectPath;
}

function existingGalleryUrl(photo) {
  const value = typeof photo?.galleryUrl === "string" ? photo.galleryUrl.trim() : "";
  return value.startsWith("https://") ? value : "";
}

/**
 * One row per photos[] entry. `upload` means a Storage original should gain
 * a gallery copy. A photo that already has galleryUrl is `has-gallery` and
 * is not regenerated. Wikimedia and other non-Storage URLs are `skip`.
 */
export function planGalleryPhoto(temple, photo, index) {
  const id = String(temple?.id ?? "");
  const source = typeof photo?.url === "string" ? photo.url.trim() : "";
  if (existingGalleryUrl(photo)) {
    return { id, index, action: "skip", reason: "has-gallery", source, temple };
  }
  if (!source) return { id, index, action: "skip", reason: "no-url", temple };
  const located = storageObjectFromUrl(source);
  if (!located) {
    const reason = staysFullSizeWikimedia(source) ? "wikimedia-full" : "not-storage";
    return { id, index, action: "skip", reason, source, temple };
  }
  if (!isLockedStorageBucket(located.bucket)) {
    return {
      id,
      index,
      action: "skip",
      reason: "other-bucket",
      source,
      bucket: located.bucket,
      temple,
    };
  }
  if (!galleryObjectPath(located.objectPath, "1")) {
    return { id, index, action: "skip", reason: "already-derivative", source, temple };
  }
  return {
    id,
    index,
    action: "upload",
    source,
    objectPath: located.objectPath,
    bucket: located.bucket,
    contentType: "image/jpeg",
    cacheControl: GALLERY_CACHE_CONTROL,
    temple,
  };
}

export function planGalleryPhotos(temples) {
  const plans = [];
  for (const temple of temples ?? []) {
    const photos = Array.isArray(temple?.photos) ? temple.photos : [];
    photos.forEach((photo, index) => {
      plans.push(planGalleryPhoto(temple, photo, index));
    });
  }
  return plans;
}

/**
 * Resume rows for [project]. The map value is the set of photo URLs that
 * already gained a galleryUrl. A new photo on a recorded temple is processed.
 */
export function loadResume(raw, project) {
  if (raw == null || String(raw).trim() === "") return new Map();
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return new Map();
  }
  if (!parsed || parsed.project !== project || !parsed.photos || typeof parsed.photos !== "object") {
    return new Map();
  }
  const photos = new Map();
  for (const [id, urls] of Object.entries(parsed.photos)) {
    if (!id || !Array.isArray(urls)) continue;
    const set = new Set();
    for (const url of urls) {
      if (typeof url === "string" && url !== "") set.add(url);
    }
    if (set.size > 0) photos.set(id, set);
  }
  return photos;
}

export function saveResume(project, photos) {
  const entries = [...photos.entries()].sort((a, b) => String(a[0]).localeCompare(String(b[0])));
  const body = {};
  for (const [id, urls] of entries) {
    body[id] = [...urls].sort();
  }
  return `${JSON.stringify({ project, photos: body }, null, 2)}\n`;
}

export function applyLimitAndResume(plans, { limit = null, resumePhotos = null } = {}) {
  const done = resumePhotos ?? new Map();
  let uploads = 0;
  return plans.map((plan) => {
    if (plan.action !== "upload") return plan;
    const recorded = done.get(plan.id);
    if (recorded && recorded.has(plan.source)) {
      return { ...plan, action: "skip", reason: "resume" };
    }
    if (limit != null && uploads >= limit) return { ...plan, action: "skip", reason: "limit" };
    uploads += 1;
    return plan;
  });
}

/**
 * Set galleryUrl on photos whose url still matches [assignments].
 * A photo that already has galleryUrl is not overwritten. A photo whose
 * url is gone is listed in skippedUrls. thumbUrl and every other field
 * stay. Returns without a write when nothing changed.
 */
export function assignGalleryUrls(temple, assignments) {
  const photos = Array.isArray(temple?.photos) ? temple.photos.map((photo) => ({ ...photo })) : [];
  const storedUrls = [];
  const skippedUrls = [];
  let changed = false;
  for (const assignment of assignments ?? []) {
    const source = assignment?.source;
    const galleryUrl = firebaseMediaUrl(assignment?.galleryUrl);
    if (!source || !galleryUrl) {
      skippedUrls.push(source ?? "");
      continue;
    }
    const matches = photos.filter((photo) => photo && samePhotoUrl(photo.url, source));
    if (matches.length === 0) {
      skippedUrls.push(source);
      continue;
    }
    let kept = false;
    for (const photo of matches) {
      if (existingGalleryUrl(photo)) {
        kept = true;
        continue;
      }
      photo.galleryUrl = galleryUrl;
      changed = true;
      kept = true;
    }
    if (kept) storedUrls.push(source);
  }
  return { ok: true, changed, photos, storedUrls, skippedUrls };
}

export async function persistGalleryUrls(db, assigned) {
  const id = String(assigned?.id ?? assigned?.temple?.id ?? "");
  const assignments = assigned?.assignments ?? [];
  if (!id || assignments.length === 0) return { ok: false, reason: "gallery-url" };
  return db.runTransaction(async (tx) => {
    const ref = db.collection("temples").doc(id);
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...snap.data(), id: snap.id };
    const committed = assignGalleryUrls(fresh, assignments);
    if (!committed.ok) return committed;
    if (committed.changed) tx.update(ref, { photos: committed.photos });
    return {
      ok: true,
      id,
      photos: committed.photos,
      storedUrls: committed.storedUrls,
      skippedUrls: committed.skippedUrls,
      wrote: committed.changed,
    };
  });
}

function bucketNameForPlan(plan) {
  const name = typeof plan?.bucket === "string" ? plan.bucket.trim() : "";
  if (!name) throw new Error("Photo URL has no Storage bucket. No write.");
  return name;
}

async function confirmDownloadUrl(downloadUrl, deps) {
  const check = deps.verifyPublic;
  if (typeof check !== "function") {
    throw new Error("Apply needs a public-read check. No Firestore write.");
  }
  const ok = await check(downloadUrl);
  return ok === true;
}

/**
 * @param {object[]} plans from [planGalleryPhotos]
 * @param {{
 *   dryRun: boolean,
 *   stat: (path: string, opts?: object) => Promise<object|null>,
 *   download?: (path: string, opts?: object) => Promise<Buffer>,
 *   encode?: (bytes: Buffer) => Promise<Buffer>,
 *   upload?: (file: object) => Promise<{url: string}>,
 *   verifyPublic?: (url: string) => Promise<boolean>,
 *   writeGalleryUrls?: (assigned: object) => Promise<object>,
 *   reread?: (id: string) => Promise<object|null>,
 *   onResume?: (id: string, source: string) => Promise<void> | void,
 * }} deps
 */
const GALLERY_IO = [
  ["stat", "storage stat", "path"],
  ["download", "storage download", "path"],
  ["encode", "encode", "bytes"],
  ["upload", "storage upload", "file"],
  ["verifyPublic", "fetch", "url"],
  ["writeGalleryUrls", "firestore write", "doc"],
  ["reread", "firestore read", "id"],
  ["onResume", "resume write", "pair"],
];

async function runGalleryGroup(group, deps, report) {
  let temple = group.plans[0]?.temple;
  if (!deps.dryRun && typeof deps.reread === "function") {
    const fresh = await deps.reread(group.id);
    if (fresh) temple = { ...fresh, id: fresh.id ?? group.id };
  }
  const assignments = [];
  const pending = [];
  for (const plan of group.plans) {
    try {
      const current = { ...plan, temple: temple ?? plan.temple };
      const prepared = await prepareGalleryPhoto(current, deps);
      report.push(prepared.row);
      if (prepared.assignment) {
        assignments.push(prepared.assignment);
        pending.push(report.length - 1);
      }
    } catch (error) {
      report.push({ ...plan, result: "failed", reason: failureText(error) });
    }
  }
  if (deps.dryRun || assignments.length === 0 || typeof deps.writeGalleryUrls !== "function") {
    return;
  }
  let written;
  try {
    written = await deps.writeGalleryUrls({
      id: group.id,
      temple,
      assignments,
    });
  } catch (error) {
    for (const index of pending) {
      report[index] = { ...report[index], result: "failed", reason: failureText(error) };
    }
    return;
  }
  const skipped = new Set(written?.skippedUrls ?? []);
  const stored = new Set(written?.storedUrls ?? []);
  if (!written || written.ok === false) {
    for (const index of pending) {
      report[index] = {
        ...report[index],
        result: "failed",
        reason: written?.reason || "write",
      };
    }
    return;
  }
  for (const index of pending) {
    const source = report[index].source;
    if (written.linkedAfterTimeout === true && stored.has(source)) {
      report[index] = { ...report[index], result: "linked-after-timeout", stored: false };
    } else if (skipped.has(source) && !stored.has(source)) {
      report[index] = { ...report[index], result: "skipped", reason: "url-changed" };
    } else {
      report[index] = { ...report[index], stored: true };
    }
  }
  if (deps.onResume) {
    for (const source of stored) {
      try {
        await deps.onResume(group.id, source);
      } catch (error) {
        report.push({ id: group.id, result: "failed", reason: failureText(error), source });
      }
    }
  }
}

export async function applyGalleryPlans(plans, deps) {
  const report = [];
  if (deps.track) deps.track.rows = report;
  const io = boundIo(deps, GALLERY_IO);
  const groups = [];
  for (const plan of plans) {
    const last = groups[groups.length - 1];
    if (!last || last.id !== plan.id) groups.push({ id: plan.id, plans: [plan] });
    else last.plans.push(plan);
  }
  const batches = chunk(groups, deps.batchSize);
  for (let index = 0; index < batches.length; index += 1) {
    const batch = batches[index];
    for (const group of batch) {
      try {
        await runGalleryGroup(group, io, report);
      } catch (error) {
        for (const plan of group.plans) {
          report.push({ ...plan, result: "failed", reason: failureText(error) });
        }
      }
    }
    logBatch(deps.log, {
      batch: index + 1,
      batches: batches.length,
      temples: batch.length,
      rows: report,
      noun: "photos",
    });
  }
  return report;
}

async function prepareGalleryPhoto(plan, deps) {
  if (plan.action !== "upload") return { row: { ...plan, result: "skipped" } };
  const photos = Array.isArray(plan.temple?.photos) ? plan.temple.photos : [];
  const live = photos.find((photo) => photo && samePhotoUrl(photo.url, plan.source));
  if (!live) return { row: { ...plan, result: "skipped", reason: "url-changed" } };
  if (existingGalleryUrl(live)) {
    return { row: { ...plan, result: "skipped", reason: "has-gallery" } };
  }
  const bucket = plan.bucket;
  if (!isLockedStorageBucket(bucket)) {
    return { row: { ...plan, result: "skipped", reason: "other-bucket" } };
  }
  const sourceStat = await deps.stat(plan.objectPath, { bucket });
  const generation = String(sourceStat?.generation ?? "");
  if (!/^\d+$/.test(generation)) {
    return { row: { ...plan, result: "skipped", reason: "no-generation" } };
  }
  const galleryPath = galleryObjectPath(plan.objectPath, generation);
  if (!galleryPath) {
    return { row: { ...plan, result: "skipped", reason: "already-derivative" } };
  }
  const galleryStat = await deps.stat(galleryPath, { bucket });
  if (galleryStat) {
    const media = firebaseMediaUrl(galleryStat.url ?? null);
    if (!media) {
      return { row: { ...plan, result: "not-public", galleryPath } };
    }
    if (deps.dryRun) return { row: { ...plan, result: "exists", galleryPath } };
    const readable = await confirmDownloadUrl(media, deps);
    if (!readable) return { row: { ...plan, result: "not-public", galleryPath } };
    return {
      row: { ...plan, result: "exists", galleryPath },
      assignment: { source: plan.source, galleryUrl: media },
    };
  }
  if (deps.dryRun) return { row: { ...plan, result: "would-upload", galleryPath } };
  const bytes = await deps.download(plan.objectPath, { bucket });
  const encoded = await deps.encode(bytes);
  if (!encoded || encoded.length === 0) {
    throw new Error(`Encoder returned an empty gallery image for ${galleryPath}. No write.`);
  }
  if (encoded.length >= bytes.length) {
    return { row: { ...plan, result: "skipped", reason: "not-smaller", galleryPath } };
  }
  let uploaded;
  try {
    uploaded = await deps.upload({
      path: galleryPath,
      bucket,
      bytes: encoded,
      contentType: plan.contentType,
      cacheControl: plan.cacheControl,
      ifGenerationMatch: 0,
    });
  } catch (error) {
    const landed = await objectAfterUploadTimeout(error, deps.stat, galleryPath, bucket);
    if (!landed) throw error;
    const recovered = firebaseMediaUrl(landed.url ?? null);
    if (!recovered) return { row: { ...plan, result: "not-public", galleryPath } };
    const readable = await confirmDownloadUrl(recovered, deps);
    if (!readable) return { row: { ...plan, result: "not-public", galleryPath } };
    return {
      row: { ...plan, result: "exists", galleryPath },
      assignment: { source: plan.source, galleryUrl: recovered },
    };
  }
  const media = firebaseMediaUrl(uploaded?.url);
  if (!media) return { row: { ...plan, result: "not-public", galleryPath } };
  const readable = await confirmDownloadUrl(media, deps);
  if (!readable) return { row: { ...plan, result: "not-public", galleryPath } };
  return {
    row: { ...plan, result: "uploaded", galleryPath, bytes: encoded.length },
    assignment: { source: plan.source, galleryUrl: media },
  };
}

export function formatGalleryReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const counts = { upload: 0, exists: 0, skip: 0, uploaded: 0, linked: 0 };
  for (const row of rows) {
    if (row.result === "linked-after-timeout") counts.linked += 1;
    else if (row.result === "would-upload" || row.result === "uploaded") counts.upload += 1;
    else if (row.result === "exists") counts.exists += 1;
    else counts.skip += 1;
    if (row.result === "uploaded") counts.uploaded += 1;
  }
  const linkedNote = counts.linked > 0 ? `  linked-after-timeout: ${counts.linked}` : "";
  lines.push(
    `photos: ${rows.length}  gallery: ${counts.upload}  exists: ${counts.exists}  skip: ${counts.skip}${linkedNote}`,
  );
  for (const row of rows) {
    if (row.result === "linked-after-timeout") {
      lines.push(`linked-after-timeout ${row.id} ${row.galleryPath || ""}`.trimEnd());
    } else if (row.result === "would-upload" || row.result === "uploaded" || row.result === "exists") {
      lines.push(`${row.result} ${row.id} ${row.galleryPath}`);
    } else if (row.result === "failed") {
      lines.push(`failed ${row.id ?? ""} ${row.reason ?? ""}`.trimEnd());
    } else if (row.result === "not-public") {
      lines.push(`not-public ${row.id} ${row.galleryPath || row.objectPath || ""}`.trimEnd());
    } else if (row.reason && row.reason !== "wikimedia-full") {
      lines.push(`skip ${row.id} ${row.reason}`);
    } else if (row.reason === "wikimedia-full") {
      lines.push(`skip ${row.id} wikimedia-full`);
    }
  }
  if (!apply) lines.push("Dry-run only. No Storage writes.");
  else lines.push("Storage gallery copies plus photos[].galleryUrl. The index was not written.");
  return redactDownloadToken(lines.join("\n"));
}

async function initAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (usesEmulator(env)) {
    process.env.FIRESTORE_EMULATOR_HOST = env.FIRESTORE_EMULATOR_HOST;
    if (env.FIREBASE_STORAGE_EMULATOR_HOST) {
      process.env.FIREBASE_STORAGE_EMULATOR_HOST = env.FIREBASE_STORAGE_EMULATOR_HOST;
    }
  }
  if (admin.apps.length > 0) return admin;
  if (usesEmulator(env)) {
    admin.initializeApp({ projectId: project, storageBucket: `${project}.appspot.com` });
    return admin;
  }
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) {
    throw new Error(
      "service-account.json was not found in scripts/ or the repo root. No write.",
    );
  }
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== project) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${project}. No write.`,
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
    storageBucket: STORAGE_AUTH_BUCKET,
  });
  return admin;
}

async function openAdmin(project, env, limits = ioLimits) {
  return callBounded(() => initAdmin(project, env), {
    ...networkLimits(limits),
    label: "admin init",
  });
}

async function loadTemples(project, env, limits) {
  const admin = await openAdmin(project, env, limits);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

function storageDeps(admin) {
  function bucket(name) {
    const resolved = bucketNameForPlan({ bucket: name });
    if (!isLockedStorageBucket(resolved)) {
      throw new Error(
        `Refusing Storage bucket ${resolved}. Reads and uploads use only ${STORAGE_AUTH_BUCKET}. No write.`,
      );
    }
    return admin.storage().bucket(STORAGE_AUTH_BUCKET);
  }
  return {
    stat: async (path, opts = {}) => {
      const file = bucket(opts.bucket).file(path);
      const [found] = await file.exists();
      if (!found) return null;
      const [metadata] = await file.getMetadata();
      const tokens = String(metadata?.metadata?.firebaseStorageDownloadTokens ?? "");
      const token = tokens.split(",")[0].trim();
      return {
        generation: String(metadata.generation ?? ""),
        updated: metadata.updated,
        url: token ? firebaseDownloadUrl(opts.bucket, path, token) : null,
      };
    },
    download: async (path, opts = {}) => {
      const file = bucket(opts.bucket).file(path);
      return readWithSignal(file, opts.signal);
    },
    encode: encodeGalleryJpeg,
    upload: async (file) => {
      const token = randomUUID();
      const name = bucketNameForPlan(file);
      const target = bucket(name).file(file.path);
      await writeWithSignal(target, file.bytes, thumbSaveOptions({ ...file, token }), file.signal);
      return { url: firebaseDownloadUrl(name, file.path, token) };
    },
  };
}

export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const writeLog = deps.log ?? ((line) => console.log(line));
  const log = (line) => writeLog(redactDownloadToken(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  if (opts.apply) assertApplyBucket(opts.bucket);
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  useNativeFetchForStorageAuth();
  const limits = networkLimits({
    timeoutMs: opts.timeoutMs ?? deps.timeoutMs ?? DEFAULT_TIMEOUT_MS,
    attempts: deps.attempts,
    backoffMs: deps.backoffMs,
    sleep: deps.sleep,
  });
  ioLimits = limits;
  const tracker =
    deps.tracker ?? (isDirect ? runTracker : { active: false, summarized: false, rows: [], started: 0 });
  beginRun(tracker);
  if (opts.apply) await authorizeApply(project, env, { confirm: deps.confirm });
  if (opts.apply) {
    if (deps.storagePreflight) {
      await callBounded(() => deps.storagePreflight(), { ...limits, label: "storage preflight" });
    } else if (!usesEmulator(env)) {
      const admin = await openAdmin(project, env, limits);
      await callBounded(() => assertStorageAuth(admin.storage().bucket(STORAGE_AUTH_BUCKET)), {
        ...limits,
        label: "storage preflight",
      });
    }
  }
  let rows = [];
  try {
    const load = deps.load ?? loadTemples;
    const temples = await callBounded(() => load(project, env, limits), { ...limits, label: "firestore read" });
    temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
    const resumeRaw = opts.resume
      ? (deps.readResume ?? (() => (existsSync(RESUME_FILE) ? readFileSync(RESUME_FILE, "utf8") : "")))()
      : "";
    const resumePhotos = opts.resume ? loadResume(resumeRaw, project) : new Map();
    const plans = applyLimitAndResume(planGalleryPhotos(temples), {
      limit: opts.limit,
      resumePhotos,
    });
    let storage = deps.storage ?? null;
    const needsBucket = !deps.stat;
    if (needsBucket && !storage) {
      const admin = await openAdmin(project, env, limits);
      storage = storageDeps(admin);
    }
    const stat = deps.stat ?? storage?.stat;
    if (!stat) throw new Error("Dry-run needs a Storage stat. No write.");
    const writeGalleryUrls = async (assigned) => {
      if (deps.writeGalleryUrls) return deps.writeGalleryUrls(assigned);
      if (!opts.apply) return assigned;
      const admin = await openAdmin(project, env, limits);
      const returned = await persistGalleryUrls(admin.firestore(), assigned);
      if (!returned || returned.ok === false) return returned ?? { ok: false, reason: "missing" };
      return returned;
    };
    const reread =
      deps.reread ??
      (opts.apply && !deps.writeGalleryUrls
        ? async (id) => {
            const admin = await openAdmin(project, env, limits);
            const snap = await admin.firestore().collection("temples").doc(id).get();
            if (!snap.exists) return null;
            return { ...snap.data(), id: snap.id };
          }
        : undefined);
    const readResumeNow = () =>
      (deps.readResume ?? (() => (existsSync(RESUME_FILE) ? readFileSync(RESUME_FILE, "utf8") : "")))();
    const onResume = opts.apply
      ? async (id, source) => {
          rememberResume(resumePhotos, id, source);
          const body = saveResume(project, resumePhotos);
          if (deps.writeResume) await deps.writeResume(body);
          else {
            const tmp = `${RESUME_FILE}.tmp`;
            writeFileSync(tmp, body);
            renameSync(tmp, RESUME_FILE);
          }
        }
      : undefined;
    const beforeRetry = opts.apply
      ? async ({ key, error, args }) => {
          if (!isTimeoutError(error)) return undefined;
          if (key === "writeGalleryUrls") {
            if (typeof reread !== "function") return undefined;
            const assigned = args?.[0];
            let fresh = null;
            try {
              fresh = await attemptWithTimeout(
                () => reread(assigned?.id),
                limits.timeoutMs,
                "firestore read",
              );
            } catch {
              return undefined;
            }
            const linked = galleryLinksMatch(fresh, assigned?.assignments);
            if (!linked.complete) return undefined;
            return {
              recover: true,
              value: {
                ok: true,
                linkedAfterTimeout: true,
                storedUrls: linked.storedUrls,
                skippedUrls: [],
                wrote: false,
              },
            };
          }
          if (key === "onResume") {
            const [id, source] = args ?? [];
            let raw = "";
            try {
              raw = readResumeNow() ?? "";
            } catch {
              return undefined;
            }
            const persisted = loadResume(typeof raw === "string" ? raw : "", project);
            if (!persisted.get(id)?.has(source)) return undefined;
            rememberResume(resumePhotos, id, source);
            return { recover: true, value: undefined };
          }
          return undefined;
        }
      : undefined;
    rows = await applyGalleryPlans(plans, {
      ...limits,
      batchSize: deps.batchSize,
      dryRun: !opts.apply,
      stat,
      download: deps.download ?? storage?.download,
      encode: deps.encode ?? storage?.encode,
      upload: deps.upload ?? storage?.upload,
      verifyPublic: deps.verifyPublic ?? (opts.apply ? verifyPublicObject : undefined),
      writeGalleryUrls: opts.apply ? writeGalleryUrls : undefined,
      reread,
      onResume,
      beforeRetry,
      track: tracker,
      log,
    });
    log(formatGalleryReport(rows, { apply: opts.apply }));
  } catch (error) {
    log(`failed ${failureText(error)}`);
    rows = [{ result: "failed", reason: failureText(error) }];
  }
  return finishRun({
    log,
    rows,
    elapsedMs: Date.now() - tracker.started,
    exit: deps.exit,
    tracker,
  });
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  process.on("beforeExit", () => {
    const reported = incompleteOnBeforeExit(runTracker, (line) => console.log(redactDownloadToken(line)));
    if (!reported) return;
    process.exit(1);
  });
  process.on("unhandledRejection", (reason) => {
    reportProcessFault("unhandledRejection", reason);
  });
  process.on("uncaughtException", (error) => {
    reportProcessFault("uncaughtException", error);
  });
  main()
    .catch((error) => {
      if (!error?.alreadyReported) console.error(redactThrown(error));
      process.exitCode = error?.exitCode || 1;
    })
    .finally(() => {
      process.exit(process.exitCode ?? 0);
    });
}
