/**
 * Write `_480` Storage thumbs for temple cover images and store the real
 * download URL on `photos[].thumbUrl`. The index entry is then rebuilt with
 * the same `entryFromTemple` path as `rebuild_index.js`. coverThumb does not
 * guess a sibling URL.
 *
 * Dry-run is the default. It reads temple documents and prints which cover
 * objects would gain a `temples/{id}/{file}_480_g{generation}.jpg` sibling.
 * It does not write.
 *
 *   node scripts/resize_cover_thumbs.js --project temple-directory-india
 *   node scripts/resize_cover_thumbs.js --limit 25 --resume --project temple-directory-india
 *
 * A prod apply asks you to type the project id. There is no default
 * project. Apply uploads thumbs and writes `photos[].thumbUrl` plus that
 * temple's index entry. It does not deploy.
 *
 *   node scripts/resize_cover_thumbs.js --apply --project temple-directory-india
 *
 * The thumb name includes the source generation. A newer source is uploaded
 * again even when an older thumb object exists. The upload uses
 * ifGenerationMatch: 0, so an object that is already there is not overwritten.
 * Stat, download, and upload use the bucket named in the cover URL, not the
 * app's default bucket. A cover with no photos[] entry for that URL is not
 * uploaded. Apply confirms the Firebase download URL (?alt=media and the
 * stored token) before it writes photos[].thumbUrl. A check that is not
 * HTTP 200 logs the storage object path, not the token URL. Each
 * successful row is one transaction: re-read the temple, skip it when
 * the cover photo changed, set thumbUrl only on that photo, and write
 * that temple's index entry from the fresh document. The index is not
 * batched at the end of the run. The resume file is rewritten after
 * each successful row and records the cover URL. --resume processes a
 * recorded temple again when that cover has changed.
 *
 * Encoding uses the sharp dependency in scripts/package.json.
 * `npm ci` in scripts/ installs the prebuilt binary. Most tests inject an
 * encoder. The encode unit test calls sharp.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { randomUUID } from "node:crypto";
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken } from "./redact_url.js";
import { assertStorageAuth, STORAGE_AUTH_BUCKET, useNativeFetchForStorageAuth } from "./storage_auth.js";
import {
  entryFromTemple,
  firstThumbSource,
  stateSlug,
  storageObjectFromUrl,
  thumbObjectPath,
} from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const THUMB_CACHE_CONTROL = "public, max-age=31536000, immutable";
export const THUMB_EDGE = 480;
export const THUMB_JPEG_QUALITY = 80;
export const RESUME_FILE = resolve(__dirname, ".resize_cover_thumbs.resume.json");

function printUsage() {
  console.log(`
Usage:
  node resize_cover_thumbs.js [--dry-run] [--limit N] [--resume] [--project <id>]
  node resize_cover_thumbs.js --apply [--limit N] [--resume] --project <id>

Default is dry-run: list cover objects that still need a _480 sibling.
Nothing is written. prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.

--limit N stops after N covers that still need a thumb.
--resume skips a temple only when scripts/.resize_cover_thumbs.resume.json
records the same cover URL for this project. A recorded temple whose cover
changed is processed again. Legacy files that list ids without covers still
skip those ids. Apply rewrites the file after each uploaded or current thumb.
A download check that is not HTTP 200 logs the storage object path.

Apply writes the thumb object, checks its Firebase download URL, then
one transaction per temple for photos[].thumbUrl and that temple's index
entry. A cover that changed is skipped. A cover with no matching photos[]
entry is listed as no-photo and not uploaded.
It does not deploy rules. JPEG encoding uses the sharp dependency
installed by npm ci in scripts/.
`);
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    project: null,
    help: false,
    limit: null,
    resume: false,
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
    } else if (arg === "--project") opts.project = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function usesEmulator(env) {
  const firestore = env.FIRESTORE_EMULATOR_HOST;
  const storage = env.FIREBASE_STORAGE_EMULATOR_HOST;
  return (
    (typeof firestore === "string" && firestore.trim() !== "") ||
    (typeof storage === "string" && storage.trim() !== "")
  );
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

export function firebaseDownloadUrl(bucket, objectPath, token) {
  return (
    "https://firebasestorage.googleapis.com/v0/b/" +
    `${encodeURIComponent(bucket)}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`
  );
}

/**
 * The Firebase download URL Apply GETs before writing thumbUrl.
 * storage.googleapis.com returns 403 on a Firebase bucket, so that host is
 * not the check. The URL must be https and carry alt=media plus a token.
 */
export function firebaseMediaUrl(url) {
  if (typeof url !== "string" || !url.startsWith("https://")) return null;
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }
  const host = parsed.hostname.toLowerCase();
  if (host !== "firebasestorage.googleapis.com" && !host.endsWith(".firebasestorage.app")) {
    return null;
  }
  if (parsed.searchParams.get("alt") !== "media") return null;
  const token = parsed.searchParams.get("token");
  if (!token) return null;
  return url;
}

/** Bucket named by the cover URL. Never the app default. */
export function bucketNameForPlan(plan) {
  const name = typeof plan?.bucket === "string" ? plan.bucket.trim() : "";
  if (!name) throw new Error("Cover URL has no Storage bucket. No write.");
  return name;
}

/**
 * Save options for a new thumb. ifGenerationMatch 0 creates the object only
 * when it does not already exist, so a generation-named thumb is never
 * overwritten.
 */
export function thumbSaveOptions(file) {
  return {
    resumable: false,
    preconditionOpts: { ifGenerationMatch: 0 },
    metadata: {
      contentType: file.contentType,
      cacheControl: file.cacheControl,
      metadata: { firebaseStorageDownloadTokens: file.token },
    },
  };
}

/**
 * A Wikimedia original (no `/thumb/` in the path). Browse coverThumb may
 * rewrite it to a Commons 500px URL. This planner still skips it: the file
 * is not in Storage, and this script does not upload a thumb.
 */
export function staysFullSizeWikimedia(source) {
  if (typeof source !== "string" || !source.startsWith("https://")) return false;
  let host = "";
  let path = "";
  try {
    const url = new URL(source);
    host = url.hostname.toLowerCase();
    path = url.pathname;
  } catch {
    return false;
  }
  if (!host.endsWith("wikimedia.org")) return false;
  return !/\/thumb\//i.test(path);
}

/** GET the Firebase download URL. True only for 200. */
export async function verifyPublicObject(url, fetchImpl = globalThis.fetch) {
  if (typeof fetchImpl !== "function") {
    throw new Error("This Node has no fetch. No Firestore write.");
  }
  const response = await fetchImpl(url, { method: "GET", redirect: "follow" });
  try {
    await response.body?.cancel?.();
  } catch {
    // The status is what the check needs.
  }
  return response.status === 200;
}

/**
 * Resume rows for [project]. The map value is the cover URL that was
 * stored. `null` is a legacy id with no cover, which still skips.
 * A later cover that differs from the stored URL is processed again.
 */
export function loadResume(raw, project) {
  if (raw == null || String(raw).trim() === "") return new Map();
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return new Map();
  }
  if (!parsed || parsed.project !== project) return new Map();
  const covers = new Map();
  if (parsed.covers && typeof parsed.covers === "object" && !Array.isArray(parsed.covers)) {
    for (const [id, cover] of Object.entries(parsed.covers)) {
      if (!id) continue;
      covers.set(id, typeof cover === "string" ? cover : "");
    }
    return covers;
  }
  if (Array.isArray(parsed.ids)) {
    for (const id of parsed.ids) {
      if (typeof id === "string" && id !== "") covers.set(id, null);
    }
  }
  return covers;
}

export function saveResume(project, covers) {
  const entries = [...covers.entries()].sort((a, b) => String(a[0]).localeCompare(String(b[0])));
  return `${JSON.stringify({ project, covers: Object.fromEntries(entries) }, null, 2)}\n`;
}

/**
/**
 * Same cover string, or two URLs that name one Storage object. A token URL
 * and the storage.googleapis.com URL of that object are the same file.
 */
function sameCover(photoUrl, source) {
  const left = typeof photoUrl === "string" ? photoUrl.trim() : "";
  const right = typeof source === "string" ? source.trim() : "";
  if (!left || !right) return false;
  if (left === right) return true;
  const a = storageObjectFromUrl(left);
  const b = storageObjectFromUrl(right);
  if (!a || !b) return false;
  return a.bucket === b.bucket && a.objectPath === b.objectPath;
}

/**
 * True when some photos[] url is the cover. Without that entry there is
 * nowhere to store thumbUrl, and no new top-level field is added. The
 * backfill writes photos[].url from imageUrl; a gallery string that is the
 * same Storage object still counts.
 */
export function coverHasPhoto(temple, source = firstThumbSource(temple)) {
  if (typeof source !== "string" || source === "") return false;
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  return photos.some((photo) => photo && sameCover(photo.url, source));
}

/**
 * One cover. `upload` means a full-size Storage object should gain a thumb.
 * Wikimedia and other non-Storage covers are `skip`. A Storage cover with no
 * matching photos[] entry is `no-photo` and is not uploaded. The download
 * URL is not guessed here; apply stores the URL Storage returns.
 */
export function planCoverThumb(temple) {
  const id = String(temple?.id ?? "");
  const source = firstThumbSource(temple);
  if (!source) return { id, action: "skip", reason: "no-cover", temple };
  const located = storageObjectFromUrl(source);
  if (!located) {
    const reason = staysFullSizeWikimedia(source) ? "wikimedia-full" : "not-storage";
    return { id, action: "skip", reason, source, temple };
  }
  if (!coverHasPhoto(temple, source)) {
    return { id, action: "skip", reason: "no-photo", source, temple };
  }
  if (!thumbObjectPath(located.objectPath, "1")) {
    return { id, action: "skip", reason: "already-thumb", source, temple };
  }
  return {
    id,
    action: "upload",
    source,
    objectPath: located.objectPath,
    bucket: located.bucket,
    contentType: "image/jpeg",
    cacheControl: THUMB_CACHE_CONTROL,
    temple,
  };
}

export function planCoverThumbs(temples) {
  return (temples ?? []).map((temple) => planCoverThumb(temple));
}

function recordedCoverSkips(plan, covers) {
  if (!covers.has(plan.id)) return false;
  const recorded = covers.get(plan.id);
  // Legacy id with no cover: the change cannot be detected, so skip.
  if (recorded == null) return true;
  return recorded === plan.source;
}

export function applyLimitAndResume(
  plans,
  { limit = null, resumeIds = new Set(), resumeCovers = null } = {},
) {
  const covers = resumeCovers ?? new Map([...resumeIds].map((id) => [id, null]));
  let uploads = 0;
  return plans.map((plan) => {
    if (plan.action !== "upload") return plan;
    if (recordedCoverSkips(plan, covers)) return { ...plan, action: "skip", reason: "resume" };
    if (limit != null && uploads >= limit) return { ...plan, action: "skip", reason: "limit" };
    uploads += 1;
    return plan;
  });
}

export function sourceIsNewer(sourceUpdated, thumbUpdated) {
  const source = Date.parse(sourceUpdated ?? "");
  const thumb = Date.parse(thumbUpdated ?? "");
  if (!Number.isFinite(source) || !Number.isFinite(thumb)) return false;
  return source > thumb;
}

/**
 * Attach [thumbUrl] to the photo whose url is the cover. The index entry
 * is `entryFromTemple`, the same projection rebuild_index writes.
 */
export function withCoverThumbUrl(temple, thumbUrl) {
  const source = firstThumbSource(temple);
  if (typeof thumbUrl !== "string" || !thumbUrl.startsWith("https://") || !source) {
    return { ok: false, reason: "thumb-url" };
  }
  const photos = Array.isArray(temple?.photos) ? temple.photos.map((photo) => ({ ...photo })) : [];
  let matched = false;
  for (const photo of photos) {
    if (photo && sameCover(photo.url, source)) {
      photo.thumbUrl = thumbUrl;
      matched = true;
    }
  }
  if (!matched) return { ok: false, reason: "no-photo" };
  const next = { ...temple, photos };
  return { ok: true, temple: next, photos, entry: entryFromTemple(next) };
}

/**
 * Set thumbUrl on the cover photo of a document read just now.
 * [source] is the cover URL this row already resized. A different cover
 * is `cover-changed` and is not written. Only the matching photo's
 * thumbUrl is set; the other photo fields and the index entry come from
 * [fresh]. A differing updateTime is not a separate skip: the apply path
 * never had a read stamp to compare, and the cover URL is the check.
 */
export function commitCoverThumb(fresh, { source, thumbUrl } = {}) {
  if (!source || firstThumbSource(fresh) !== source) {
    return { ok: false, reason: "cover-changed" };
  }
  return withCoverThumbUrl(fresh, thumbUrl);
}

/**
 * @param {object[]} plans from [planCoverThumbs]
 * @param {{
 *   dryRun: boolean,
 *   stat: (path: string) => Promise<{generation?: string, updated?: string, url?: string}|null>,
 *   download?: (path: string) => Promise<Buffer>,
 *   encode?: (bytes: Buffer, ext: string) => Promise<Buffer>,
 *   upload?: (file: object) => Promise<{url: string}>,
 *   verifyPublic?: (url: string) => Promise<boolean>,
 *   writeThumbUrl?: (assigned: object) => Promise<object|void>,
 *   reread?: (id: string) => Promise<object|null>,
 *   onResume?: (id: string) => Promise<void> | void,
 * }} deps
 * stat, download, and upload receive `{ bucket }` from the cover URL.
 * [reread] loads the temple again before upload. A cover that moved is
 * skipped. [writeThumbUrl] may return `{ ok: false }` to skip the resume
 * line. The index entry is written inside that call, not after the run.
 * [onResume] runs after each row whose thumbUrl was stored.
 */
export async function applyCoverThumbPlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "upload") {
      report.push({ ...plan, result: "skipped" });
      continue;
    }
    const plannedState = plan.temple?.state;
    let current = { ...plan, plannedState };
    if (!deps.dryRun && typeof deps.reread === "function") {
      const fresh = await deps.reread(plan.id);
      const freshId = fresh?.id ?? plan.id;
      if (!fresh || firstThumbSource(fresh) !== plan.source) {
        report.push({ ...plan, result: "skipped", reason: "cover-changed" });
        continue;
      }
      if (!coverHasPhoto(fresh, plan.source)) {
        report.push({ ...plan, result: "skipped", reason: "no-photo" });
        continue;
      }
      current = { ...plan, plannedState, temple: { ...fresh, id: freshId } };
    }
    if (!coverHasPhoto(current.temple, current.source)) {
      report.push({ ...current, result: "skipped", reason: "no-photo" });
      continue;
    }
    const bucket = current.bucket;
    const sourceStat = await deps.stat(current.objectPath, { bucket });
    const generation = String(sourceStat?.generation ?? "");
    if (!/^\d+$/.test(generation)) {
      report.push({ ...current, result: "skipped", reason: "no-generation" });
      continue;
    }
    let thumbPath = thumbObjectPath(current.objectPath, generation);
    let thumbStat = thumbPath ? await deps.stat(thumbPath, { bucket }) : null;
    if (thumbStat && sourceIsNewer(sourceStat.updated, thumbStat.updated)) {
      const millis = Date.parse(sourceStat.updated);
      if (Number.isFinite(millis)) {
        thumbPath = thumbObjectPath(current.objectPath, generation, { updatedMillis: millis });
        thumbStat = await deps.stat(thumbPath, { bucket });
      }
    }
    if (thumbStat && !sourceIsNewer(sourceStat.updated, thumbStat.updated)) {
      const stored = await storeThumbUrl(current, thumbStat.url ?? null, deps, {
        result: "exists",
        thumbPath,
      });
      report.push(stored);
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...current, result: "would-upload", thumbPath });
      continue;
    }
    const bytes = await deps.download(current.objectPath, { bucket });
    const thumb = await deps.encode(bytes, "jpg");
    if (!thumb || thumb.length === 0) {
      throw new Error(`Encoder returned an empty thumb for ${thumbPath}. No write.`);
    }
    const uploaded = await deps.upload({
      path: thumbPath,
      bucket,
      bytes: thumb,
      contentType: current.contentType,
      cacheControl: current.cacheControl,
      ifGenerationMatch: 0,
    });
    const stored = await storeThumbUrl(current, uploaded?.url, deps, {
      result: "uploaded",
      thumbPath,
      bytes: thumb.length,
    });
    report.push(stored);
  }
  return report;
}

/**
 * Check the Firebase download URL, then write photos[].thumbUrl.
 * A URL that is not that download URL, or that does not return 200, is
 * `not-public` and is not written. The report names the storage object
 * path, not the token URL. Resume is recorded only after the write.
 */
function storagePathForReport(plan, extra) {
  if (typeof extra?.thumbPath === "string" && extra.thumbPath !== "") return extra.thumbPath;
  if (typeof plan?.objectPath === "string" && plan.objectPath !== "") return plan.objectPath;
  return "";
}

async function storeThumbUrl(plan, thumbUrl, deps, extra) {
  const media = firebaseMediaUrl(thumbUrl);
  if (!deps.dryRun && deps.writeThumbUrl) {
    if (!media) {
      return {
        ...plan,
        ...extra,
        result: "not-public",
        publicUrl: storagePathForReport(plan, extra),
      };
    }
    const readable = await confirmDownloadUrl(media, deps);
    if (!readable.ok) {
      return {
        ...plan,
        ...extra,
        result: "not-public",
        publicUrl: storagePathForReport(plan, extra),
      };
    }
    const assigned = withCoverThumbUrl(plan.temple, media);
    if (!assigned.ok) {
      return { ...plan, ...extra, result: "skipped", reason: assigned.reason, thumbUrl: media };
    }
    const written = await deps.writeThumbUrl({
      ...assigned,
      source: plan.source,
      plannedState: plan.plannedState ?? plan.temple?.state,
    });
    if (written && written.ok === false) {
      return { ...plan, ...extra, result: "skipped", reason: written.reason, thumbUrl: media };
    }
    if (deps.onResume) await deps.onResume(plan.id, plan.source);
    return { ...plan, ...extra, thumbUrl: media };
  }
  return { ...plan, ...extra, thumbUrl: media ?? thumbUrl ?? null };
}

/**
 * GET the Firebase download URL. False skips the Firestore write.
 * Dry-run does not call this.
 */
async function confirmDownloadUrl(downloadUrl, deps) {
  const check = deps.verifyPublic;
  if (typeof check !== "function") {
    throw new Error("Apply needs a public-read check. No Firestore write.");
  }
  const ok = await check(downloadUrl);
  return { ok: ok === true, url: downloadUrl };
}

export function formatThumbReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const counts = { upload: 0, exists: 0, skip: 0, uploaded: 0 };
  let notStorage = 0;
  const fullSize = [];
  const noPhoto = [];
  for (const row of rows) {
    if (row.reason === "not-storage" || row.reason === "wikimedia-full") notStorage += 1;
    if (row.reason === "wikimedia-full") fullSize.push(row);
    if (row.reason === "no-photo") noPhoto.push(row);
    if (row.result === "would-upload" || row.result === "uploaded") counts.upload += 1;
    else if (row.result === "exists") counts.exists += 1;
    else counts.skip += 1;
    if (row.result === "uploaded") counts.uploaded += 1;
  }
  lines.push(
    `covers: ${rows.length}  thumbs: ${counts.upload}  exists: ${counts.exists}  skip: ${counts.skip}`,
  );
  lines.push(`skip not-storage: ${notStorage}`);
  lines.push(`wikimedia full-size: ${fullSize.length}`);
  for (const row of fullSize) {
    lines.push(`full-size ${row.id} ${row.source}`);
  }
  lines.push(`no-photo: ${noPhoto.length}`);
  for (const row of noPhoto) {
    lines.push(`no-photo ${row.id} ${row.source ?? ""}`.trimEnd());
  }
  for (const row of rows) {
    if (row.result === "would-upload" || row.result === "uploaded") {
      lines.push(`${row.result} ${row.id} ${row.thumbPath}`);
    } else if (row.result === "exists") {
      lines.push(`exists ${row.id} ${row.thumbPath}`);
    } else if (row.result === "not-public") {
      const path = row.thumbPath || row.objectPath || row.publicUrl || "";
      lines.push(`not-public ${row.id} ${path}`.trimEnd());
    } else if (row.reason && row.reason !== "wikimedia-full" && row.reason !== "no-photo") {
      lines.push(`skip ${row.id} ${row.reason}`);
    }
  }
  if (!apply) lines.push("Dry-run only. No Storage writes.");
  else {
    lines.push(
      "Storage thumbs plus photos[].thumbUrl and the index entry. Rules were not deployed.",
    );
  }
  return redactDownloadToken(lines.join("\n"));
}

/**
 * sharp resize to JPEG. Width is [THUMB_EDGE]. Smaller frames are not enlarged.
 */
export async function encodeWithSharp(bytes) {
  let sharp;
  try {
    ({ default: sharp } = await import("sharp"));
  } catch {
    throw new Error(
      "Thumbnail encoding needs sharp. From the repo: npm install --prefix scripts sharp. No write.",
    );
  }
  const input = sharp(bytes, { failOn: "none" }).rotate();
  const meta = await input.metadata();
  const width = meta.width ?? 0;
  const pipeline =
    width > THUMB_EDGE ? input.resize({ width: THUMB_EDGE, withoutEnlargement: true }) : input;
  return pipeline.jpeg({ quality: THUMB_JPEG_QUALITY }).toBuffer();
}

async function openAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
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
    storageBucket: env.STORAGE_BUCKET || `${project}.firebasestorage.app`,
  });
  return admin;
}

async function loadTemples(project, env) {
  const admin = await openAdmin(project, env);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

/**
 * One transaction per temple. Re-read the document, and write nothing when
 * the cover photo changed. Otherwise set thumbUrl on that photo of the fresh
 * document and write that temple's index entry from the same document.
 * Meta is stamped in this transaction. A later row does not batch these.
 */
export async function persistCoverPhotos(db, assigned, deps = {}) {
  const admin = deps.admin ?? (await import("firebase-admin")).default;
  const source = assigned.source ?? firstThumbSource(assigned.temple);
  const thumbUrl = (assigned.photos ?? []).find(
    (photo) => photo && typeof photo.url === "string" && photo.url.trim() === source && photo.thumbUrl,
  )?.thumbUrl;
  const id = String(assigned.temple?.id ?? "");
  if (!id || typeof thumbUrl !== "string") return { ok: false, reason: "thumb-url" };
  const plannedState = assigned.plannedState ?? assigned.temple?.state;
  return db.runTransaction(async (tx) => {
    const templeRef = db.collection("temples").doc(id);
    const templeSnap = await tx.get(templeRef);
    if (!templeSnap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...templeSnap.data(), id: templeSnap.id };
    const committed = commitCoverThumb(fresh, {
      source,
      thumbUrl,
    });
    if (!committed.ok) return committed;
    const shard = stateSlug(committed.temple.state);
    const previous =
      typeof plannedState === "string" && plannedState !== "" ? stateSlug(plannedState) : null;
    const indexRef = db.collection("temple_index").doc(shard);
    const metaRef = db.collection("meta").doc("temple_index");
    await tx.get(indexRef);
    const metaSnap = await tx.get(metaRef);
    const oldRef = previous && previous !== shard ? db.collection("temple_index").doc(previous) : null;
    const oldSnap = oldRef ? await tx.get(oldRef) : null;
    tx.update(templeRef, { photos: committed.photos });
    const entry = {
      ...committed.entry,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.set(
      indexRef,
      { entries: { [id]: entry } },
      { mergeFields: [new admin.firestore.FieldPath("entries", id)] },
    );
    if (oldRef && oldSnap?.exists) {
      tx.update(
        oldRef,
        new admin.firestore.FieldPath("entries", id),
        admin.firestore.FieldValue.delete(),
      );
    }
    const touched = oldRef && oldSnap?.exists ? [shard, previous] : [shard];
    if (!metaSnap.exists) {
      const stamps = {};
      for (const name of touched) stamps[name] = admin.firestore.FieldValue.serverTimestamp();
      tx.set(metaRef, { indexVersion: 1, shards: stamps }, { merge: true });
    } else {
      const patch = { indexVersion: admin.firestore.FieldValue.increment(1) };
      for (const name of touched) {
        patch[`shards.${name}`] = admin.firestore.FieldValue.serverTimestamp();
      }
      tx.update(metaRef, patch);
    }
    return { ...committed, shard, entry };
  });
}

function storageDeps(admin) {
  function bucket(name) {
    return admin.storage().bucket(bucketNameForPlan({ bucket: name }));
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
      const [bytes] = await bucket(opts.bucket).file(path).download();
      return bytes;
    },
    encode: encodeWithSharp,
    upload: async (file) => {
      const token = randomUUID();
      const name = bucketNameForPlan(file);
      await bucket(name).file(file.path).save(file.bytes, thumbSaveOptions({ ...file, token }));
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
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  useNativeFetchForStorageAuth();
  if (opts.apply) await authorizeApply(project, env, { confirm: deps.confirm });
  if (opts.apply) {
    if (deps.storagePreflight) await deps.storagePreflight();
    else if (!usesEmulator(env)) {
      const admin = await openAdmin(project, env);
      await assertStorageAuth(admin.storage().bucket(STORAGE_AUTH_BUCKET));
    }
  }
  const load = deps.load ?? loadTemples;
  const temples = await load(project, env);
  temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  const resumeRaw = opts.resume
    ? (deps.readResume ?? (() => (existsSync(RESUME_FILE) ? readFileSync(RESUME_FILE, "utf8") : "")))()
    : "";
  const resumeCovers = opts.resume ? loadResume(resumeRaw, project) : new Map();
  const plans = applyLimitAndResume(planCoverThumbs(temples), {
    limit: opts.limit,
    resumeCovers,
  });
  let storage = deps.storage ?? null;
  const needsBucket = !deps.stat;
  if (needsBucket && !storage) {
    const admin = await openAdmin(project, env);
    storage = storageDeps(admin);
  }
  const stat = deps.stat ?? storage?.stat;
  if (!stat) throw new Error("Dry-run needs a Storage stat. No write.");
  const writeThumbUrl = async (assigned) => {
    if (deps.writeThumbUrl) return deps.writeThumbUrl(assigned);
    if (!opts.apply) return assigned;
    const admin = await openAdmin(project, env);
    const returned = await persistCoverPhotos(admin.firestore(), assigned);
    if (!returned || returned.ok === false) return returned ?? { ok: false, reason: "missing" };
    return returned;
  };
  const reread =
    deps.reread ??
    (opts.apply && !deps.writeThumbUrl
      ? async (id) => {
          const admin = await openAdmin(project, env);
          const snap = await admin.firestore().collection("temples").doc(id).get();
          if (!snap.exists) return null;
          return { ...snap.data(), id: snap.id };
        }
      : undefined);
  const onResume = opts.apply
    ? async (id, source) => {
        resumeCovers.set(id, typeof source === "string" ? source : "");
        const body = saveResume(project, resumeCovers);
        if (deps.writeResume) deps.writeResume(body);
        else {
          const tmp = `${RESUME_FILE}.tmp`;
          writeFileSync(tmp, body);
          renameSync(tmp, RESUME_FILE);
        }
      }
    : undefined;
  const rows = await applyCoverThumbPlans(plans, {
    dryRun: !opts.apply,
    stat,
    download: deps.download ?? storage?.download,
    encode: deps.encode ?? storage?.encode,
    upload: deps.upload ?? storage?.upload,
    verifyPublic: deps.verifyPublic ?? (opts.apply ? verifyPublicObject : undefined),
    writeThumbUrl,
    reread,
    onResume,
  });
  log(formatThumbReport(rows, { apply: opts.apply }));
  return rows;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactDownloadToken(error.message || error));
    process.exit(1);
  });
}
