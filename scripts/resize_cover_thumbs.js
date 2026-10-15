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
 * Apply is hand-run only. CI cannot apply. A prod apply asks you to type
 * the project id. There is no default project. Apply uploads thumbs and
 * writes `photos[].thumbUrl` plus that temple's index entry. It does not
 * deploy.
 *
 *   node scripts/resize_cover_thumbs.js --apply --project temple-directory-india
 *
 * The thumb name includes the source generation. A newer source is uploaded
 * again even when an older thumb object exists. The upload uses
 * ifGenerationMatch: 0, so an object that is already there is not overwritten.
 * Stat, download, and upload use the bucket named in the cover URL, not the
 * app's default bucket. A cover with no photos[] entry for that URL is not
 * uploaded. Apply confirms the Firebase download URL (?alt=media and the
 * stored token) before it writes photos[].thumbUrl. That write re-reads
 * the temple in a transaction. A cover that is no longer the same photo
 * is skipped and reported. Only that photo's thumbUrl is set, on the
 * fresh document. Index entries for the run are built from those fresh
 * documents and written once at the end, per shard, not once per temple.
 * The resume file is rewritten after each successful row.
 *
 * Encoding uses sharp, installed by Deployer
 * (`npm install --prefix scripts sharp`). Tests inject an encoder and never
 * import sharp. Do not run --apply from CI or from an agent against production.
 */
import { randomUUID } from "node:crypto";
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import {
  entryFromTemple,
  firstVerifiedGalleryUrl,
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
Nothing is written. --apply is for Deployer, in a terminal, after merge.
CI is refused. Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.

--limit N stops after N covers that still need a thumb.
--resume skips ids already recorded in scripts/.resize_cover_thumbs.resume.json
for this project. Apply rewrites that file after each uploaded or current thumb.

Apply writes the thumb object, checks its Firebase download URL, then
photos[].thumbUrl. Index entries are batched per shard at the end of the run.
A cover with no matching photos[] entry is listed as no-photo and not uploaded.
It does not deploy rules. Install sharp before apply:
  npm install --prefix scripts sharp
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
 * A Wikimedia file URL that coverThumb leaves at full size. Thumb paths are
 * rewritten to 480px when they are wider, so they are not listed here.
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

export function loadResume(raw, project) {
  if (raw == null || String(raw).trim() === "") return new Set();
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return new Set();
  }
  if (!parsed || parsed.project !== project || !Array.isArray(parsed.ids)) return new Set();
  return new Set(parsed.ids.filter((id) => typeof id === "string" && id !== ""));
}

export function saveResume(project, ids) {
  return `${JSON.stringify({ project, ids: [...ids].sort() }, null, 2)}\n`;
}

/**
/**
 * True when some photos[] url is the cover. Without that entry there is
 * nowhere to store thumbUrl, and no new top-level field is added.
 */
export function coverHasPhoto(temple, source = firstVerifiedGalleryUrl(temple)) {
  if (typeof source !== "string" || source === "") return false;
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  return photos.some(
    (photo) => photo && typeof photo.url === "string" && photo.url.trim() === source,
  );
}

/**
 * One cover. `upload` means a full-size Storage object should gain a thumb.
 * Wikimedia and other non-Storage covers are `skip`. A Storage cover with no
 * matching photos[] entry is `no-photo` and is not uploaded. The download
 * URL is not guessed here; apply stores the URL Storage returns.
 */
export function planCoverThumb(temple) {
  const id = String(temple?.id ?? "");
  const source = firstVerifiedGalleryUrl(temple);
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

export function applyLimitAndResume(plans, { limit = null, resumeIds = new Set() } = {}) {
  let uploads = 0;
  return plans.map((plan) => {
    if (plan.action !== "upload") return plan;
    if (resumeIds.has(plan.id)) return { ...plan, action: "skip", reason: "resume" };
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
  const source = firstVerifiedGalleryUrl(temple);
  if (typeof thumbUrl !== "string" || !thumbUrl.startsWith("https://") || !source) {
    return { ok: false, reason: "thumb-url" };
  }
  const photos = Array.isArray(temple?.photos) ? temple.photos.map((photo) => ({ ...photo })) : [];
  let matched = false;
  for (const photo of photos) {
    if (photo && typeof photo.url === "string" && photo.url.trim() === source) {
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
 * is `cover-changed` and is not written. When [updateTime] is passed and
 * the fresh document's updateTime differs, the result is `changed` and
 * nothing is written. Otherwise only the matching photo's thumbUrl is
 * set; the other photo fields and the index entry come from [fresh].
 */
export function commitCoverThumb(fresh, { source, thumbUrl, updateTime } = {}) {
  if (
    updateTime != null &&
    fresh != null &&
    Object.prototype.hasOwnProperty.call(fresh, "updateTime") &&
    fresh.updateTime !== updateTime
  ) {
    return { ok: false, reason: "changed" };
  }
  if (!source || firstVerifiedGalleryUrl(fresh) !== source) {
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
 * line, or a fresh `{ temple, photos, entry }` for the index batch.
 * [onResume] runs after each row whose thumbUrl was stored.
 */
export async function applyCoverThumbPlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "upload") {
      report.push({ ...plan, result: "skipped" });
      continue;
    }
    let current = plan;
    if (!deps.dryRun && typeof deps.reread === "function") {
      const fresh = await deps.reread(plan.id);
      const freshId = fresh?.id ?? plan.id;
      if (!fresh || firstVerifiedGalleryUrl(fresh) !== plan.source) {
        report.push({ ...plan, result: "skipped", reason: "cover-changed" });
        continue;
      }
      if (!coverHasPhoto(fresh, plan.source)) {
        report.push({ ...plan, result: "skipped", reason: "no-photo" });
        continue;
      }
      current = { ...plan, temple: { ...fresh, id: freshId } };
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
 * `not-public` and is not written. Resume is recorded only after the write.
 */
async function storeThumbUrl(plan, thumbUrl, deps, extra) {
  const media = firebaseMediaUrl(thumbUrl);
  if (!deps.dryRun && deps.writeThumbUrl) {
    if (!media) {
      return { ...plan, ...extra, result: "not-public", thumbUrl: thumbUrl ?? null, publicUrl: thumbUrl ?? null };
    }
    const readable = await confirmDownloadUrl(media, deps);
    if (!readable.ok) {
      return { ...plan, ...extra, result: "not-public", thumbUrl: media, publicUrl: readable.url };
    }
    const assigned = withCoverThumbUrl(plan.temple, media);
    if (!assigned.ok) {
      return { ...plan, ...extra, result: "skipped", reason: assigned.reason, thumbUrl: media };
    }
    const written = await deps.writeThumbUrl({ ...assigned, source: plan.source });
    if (written && written.ok === false) {
      return { ...plan, ...extra, result: "skipped", reason: written.reason, thumbUrl: media };
    }
    if (deps.onResume) await deps.onResume(plan.id);
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
      lines.push(`not-public ${row.id} ${row.publicUrl}`);
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
  return lines.join("\n");
}

/**
 * sharp resize to JPEG. Imported only when Deployer applies. Tests never
 * call this. Width is [THUMB_EDGE]. Smaller frames are not enlarged.
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
 * photos[].thumbUrl only, from a transaction re-read. The index is applied
 * later, for the whole run, from the document this returns.
 * A cover that moved returns `{ ok: false, reason: "cover-changed" }` and
 * does not write. The photos array written is the fresh one with thumbUrl
 * set on the cover photo.
 */
export async function persistCoverPhotos(db, assigned) {
  const source = assigned.source ?? firstVerifiedGalleryUrl(assigned.temple);
  const thumbUrl = (assigned.photos ?? []).find(
    (photo) => photo && typeof photo.url === "string" && photo.url.trim() === source && photo.thumbUrl,
  )?.thumbUrl;
  const id = String(assigned.temple?.id ?? "");
  if (!id || typeof thumbUrl !== "string") return { ok: false, reason: "thumb-url" };
  return db.runTransaction(async (tx) => {
    const ref = db.collection("temples").doc(id);
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...snap.data(), id: snap.id };
    const committed = commitCoverThumb(fresh, { source, thumbUrl });
    if (!committed.ok) return committed;
    tx.update(ref, { photos: committed.photos });
    return committed;
  });
}

/**
 * Index upserts for this run. Removals stay empty so sibling entries in the
 * shard are not deleted. applyPlan then writes one entry per shard per round,
 * and bumps meta once per round instead of once per temple.
 */
export function thumbIndexReport(assigned) {
  const upserts = [];
  for (const item of assigned ?? []) {
    if (!item?.temple || !item?.entry) continue;
    upserts.push({
      shard: stateSlug(item.temple.state),
      id: String(item.temple.id),
      entry: item.entry,
    });
  }
  return {
    missing: [],
    drifted: [],
    moved: [],
    stale: [],
    unchanged: 0,
    upserts,
    removals: [],
    counts: new Map(),
    capViolations: [],
  };
}

export async function applyThumbIndex(db, assigned, deps = {}) {
  const { applyPlan } = await import("./rebuild_index.js");
  return applyPlan(db, thumbIndexReport(assigned), deps);
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
  const log = deps.log ?? ((line) => console.log(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  if (opts.apply) await authorizeApply(project, env, { confirm: deps.confirm });
  const load = deps.load ?? loadTemples;
  const temples = await load(project, env);
  temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  const resumeRaw = opts.resume
    ? (deps.readResume ?? (() => (existsSync(RESUME_FILE) ? readFileSync(RESUME_FILE, "utf8") : "")))()
    : "";
  const resumeIds = opts.resume ? loadResume(resumeRaw, project) : new Set();
  const plans = applyLimitAndResume(planCoverThumbs(temples), {
    limit: opts.limit,
    resumeIds,
  });
  let storage = deps.storage ?? null;
  const needsBucket = !deps.stat;
  if (needsBucket && !storage) {
    const admin = await openAdmin(project, env);
    storage = storageDeps(admin);
  }
  const stat = deps.stat ?? storage?.stat;
  if (!stat) throw new Error("Dry-run needs a Storage stat. No write.");
  const queued = [];
  const writeThumbUrl = async (assigned) => {
    let stored = assigned;
    if (deps.writeThumbUrl) {
      const returned = await deps.writeThumbUrl(assigned);
      if (returned && returned.ok === false) return returned;
      if (returned?.entry && returned?.temple) stored = returned;
    } else if (opts.apply) {
      const admin = await openAdmin(project, env);
      const returned = await persistCoverPhotos(admin.firestore(), assigned);
      if (!returned || returned.ok === false) return returned ?? { ok: false, reason: "missing" };
      stored = returned;
    }
    queued.push(stored);
    return stored;
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
    ? async (id) => {
        resumeIds.add(id);
        const body = saveResume(project, resumeIds);
        if (deps.writeResume) deps.writeResume(body);
        else {
          const tmp = `${RESUME_FILE}.tmp`;
          writeFileSync(tmp, body);
          renameSync(tmp, RESUME_FILE);
        }
      }
    : undefined;
  let rows;
  try {
    rows = await applyCoverThumbPlans(plans, {
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
  } finally {
    if (opts.apply && queued.length > 0) {
      if (deps.applyIndex) await deps.applyIndex(queued);
      else if (!deps.writeThumbUrl) {
        const admin = await openAdmin(project, env);
        await applyThumbIndex(admin.firestore(), queued);
      }
    }
  }
  log(formatThumbReport(rows, { apply: opts.apply }));
  return rows;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}
