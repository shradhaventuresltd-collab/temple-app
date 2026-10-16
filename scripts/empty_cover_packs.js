/**
 * Sanctioned write for research packs on temples that have no cover.
 *
 * Dry-run is the default. --apply uploads every manifest frame with a
 * Firebase download token, checks that URL returns HTTP 200, then writes
 * one transaction per temple. The transaction writes nothing unless
 * imageUrl, images[], and photos[] are still empty. photos[].thumbUrl is
 * not set. resize_cover_thumbs --apply fills that and the index afterwards.
 *
 * --patch-firestore is refused by the uploader. This is the write to use.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { existsSync, readFileSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { coverFrameForPack, fetchPublicUrl, manifestPair, PHOTO_LICENCES } from "./backfill_cover_photos.js";
import { assertOneCoverOk } from "./cover_ok.js";
import { ensureDownloadToken, withDownloadToken } from "./download_token.js";
import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken } from "./redact_url.js";
import { firebaseMediaUrl } from "./resize_cover_thumbs.js";
import { assertStorageAuth, STORAGE_AUTH_BUCKET, useNativeFetchForStorageAuth } from "./storage_auth.js";
import { resolveSeedDocId } from "./upload_research_pack.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packsRoot = resolve(__dirname, "..", "tools", "photo-packs");

const MAX_PHOTOS = 12;

export function usesEmulator(env) {
  const firestore = env.FIRESTORE_EMULATOR_HOST;
  return typeof firestore === "string" && firestore.trim() !== "";
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

/** One slug or pack path per line. Blank lines and # comments are ignored. */
export function readPackList(file) {
  if (!file || !existsSync(file)) throw new Error(`Pack list not found: ${file}`);
  const slugs = [];
  for (const line of readFileSync(file, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    slugs.push(trimmed);
  }
  if (slugs.length === 0) throw new Error(`Pack list ${file} has no slugs.`);
  return slugs;
}

/** A slug under tools/photo-packs, or a path that already contains manifest.json. */
export function packDirForSlug(slug) {
  const trimmed = String(slug ?? "").trim();
  if (!trimmed) throw new Error("Pack list has an empty slug.");
  const direct = resolve(process.cwd(), trimmed);
  if (existsSync(resolve(direct, "manifest.json"))) return direct;
  const packed = resolve(packsRoot, trimmed);
  if (existsSync(resolve(packed, "manifest.json"))) return packed;
  throw new Error(`Pack not found for ${trimmed}`);
}

function emptyList(value) {
  if (value == null) return true;
  if (!Array.isArray(value)) return false;
  return value.every((item) => {
    if (item == null || item === "") return true;
    if (typeof item === "string") return item.trim() === "";
    if (typeof item === "object") {
      const url = typeof item.url === "string" ? item.url.trim() : "";
      return url === "";
    }
    return false;
  });
}

/**
 * True only when imageUrl is blank and images[] and photos[] have no URLs.
 * A non-array images or photos value is treated as already having a cover.
 */
export function isEmptyCover(temple) {
  if (!temple || typeof temple !== "object") return false;
  if (Object.prototype.hasOwnProperty.call(temple, "imageUrl")) {
    if (typeof temple.imageUrl !== "string") return false;
    if (temple.imageUrl.trim() !== "") return false;
  }
  return emptyList(temple.images) && emptyList(temple.photos);
}

function assertFilename(filename) {
  if (typeof filename !== "string" || filename.trim() === "" || filename !== basename(filename)) {
    throw new Error(`Invalid pack filename: ${filename || "(missing)"}`);
  }
  if (filename.includes("..")) throw new Error(`Invalid pack filename: ${filename}`);
}

function contentTypeFor(filename) {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  return "image/jpeg";
}

function assertGalleryOnlyNotCover(id, photos) {
  for (const photo of photos) {
    if (photo?.gallery_only === true && (photo.cover === true || photo.cover_ok === true)) {
      throw new Error(
        `${id} marks ${photo.filename || "(unnamed)"} cover and gallery_only. A gallery-only frame is not the cover.`,
      );
    }
  }
}

/**
 * Plan one pack against one temple. Validation failures throw.
 * A temple that already has a cover is skipped and reported.
 */
export function planEmptyCoverPack({ temple, packDir, manifest, docIdOverride = null }) {
  const id = resolveSeedDocId(packDir, manifest, docIdOverride);
  if (!temple) return { id, action: "skip", reason: "missing" };
  if (!isEmptyCover(temple)) return { id, action: "skip", reason: "has-cover" };
  const photos = Array.isArray(manifest?.photos) ? manifest.photos : [];
  if (photos.length === 0) return { id, action: "skip", reason: "empty-pack" };
  if (photos.length > MAX_PHOTOS) {
    throw new Error(`${id} has ${photos.length} photos. The cap is 12.`);
  }
  assertOneCoverOk(id, photos);
  assertGalleryOnlyNotCover(id, photos);
  const frames = [];
  for (const photo of photos) {
    assertFilename(photo?.filename);
    const localPath = resolve(packDir, photo.filename);
    if (!existsSync(localPath)) {
      throw new Error(`Missing pack file listed in manifest: ${photo.filename}`);
    }
    const pair = manifestPair(photo);
    if (!pair.ok || !PHOTO_LICENCES.includes(pair.licence)) {
      return { id, action: "skip", reason: pair.reason || "licence", filename: photo.filename };
    }
    frames.push({
      filename: photo.filename,
      localPath,
      objectPath: `temples/${id}/${photo.filename}`,
      credit: pair.credit,
      licence: pair.licence,
    });
  }
  const chosen = coverFrameForPack(manifest);
  if (!chosen?.pair) {
    return {
      id,
      action: "skip",
      reason: manifest?.no_cover_frame === true ? "no-cover-frame" : "no-creditable-frame",
    };
  }
  const cover = frames.find((frame) => frame.filename === chosen.filename);
  if (!cover) {
    return { id, action: "skip", reason: "no-creditable-frame" };
  }
  const ordered = [cover, ...frames.filter((frame) => frame.filename !== cover.filename)];
  return {
    id,
    action: "write",
    coverFilename: cover.filename,
    frames: ordered,
    plannedState: temple.state,
    temple,
  };
}

export function photosFromFrames(frames, urls) {
  return frames.map((frame, order) => ({
    url: urls[order],
    credit: frame.credit,
    licence: frame.licence,
    order,
  }));
}

/**
 * Re-read the temple and write only while the cover is still empty.
 * The patch is imageUrl, images, and photos. No thumbUrl and no new fields.
 */
export async function persistEmptyCover(db, assigned) {
  const id = String(assigned?.id ?? "");
  if (!id) return { ok: false, reason: "missing" };
  return db.runTransaction(async (tx) => {
    const ref = db.collection("temples").doc(id);
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false, reason: "missing" };
    const fresh = snap.data() ?? {};
    if (!isEmptyCover({ ...fresh, id: snap.id })) return { ok: false, reason: "has-cover" };
    tx.update(ref, {
      imageUrl: assigned.imageUrl,
      images: assigned.images,
      photos: assigned.photos,
    });
    return { ok: true };
  });
}

async function defaultUploadFrames(plan, admin, bucketName) {
  const bucket = admin.storage().bucket(bucketName);
  const urls = [];
  for (const frame of plan.frames) {
    const file = bucket.file(frame.objectPath);
    const ensured = await ensureDownloadToken(file, bucketName, frame.objectPath);
    if (!ensured.exists) {
      await bucket.upload(frame.localPath, {
        destination: frame.objectPath,
        metadata: withDownloadToken(
          {
            contentType: contentTypeFor(frame.filename),
            cacheControl: "public, max-age=3600",
          },
          ensured.token,
        ),
      });
    }
    urls.push(ensured.url);
  }
  return urls;
}

async function urlIsPublic(url, deps) {
  if (firebaseMediaUrl(url) == null) return { ok: false, reason: "not-public" };
  const check = deps.verifyPublic ?? ((next) => fetchPublicUrl(next, deps));
  try {
    const ok = (await check(url)) === true;
    return ok ? { ok: true } : { ok: false, reason: "not-public" };
  } catch {
    return { ok: false, reason: "public-check-failed" };
  }
}

export function formatEmptyCoverReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const writes = rows.filter((row) => row.action === "write" && row.result !== "skipped");
  const skipped = rows.filter((row) => row.action === "skip" || row.result === "skipped");
  lines.push(`write: ${writes.length}`);
  for (const row of writes) {
    const count = row.frames?.length ?? row.photos?.length ?? 0;
    lines.push(`${row.result ?? "would-write"} ${row.id} cover ${row.coverFilename} photos ${count}`);
  }
  lines.push(`skipped: ${skipped.length}`);
  for (const row of skipped) lines.push(`skip ${row.id} ${row.reason ?? ""}`.trimEnd());
  if (!apply) lines.push("Dry-run only. No Firestore writes. No Storage uploads.");
  else {
    lines.push(
      "Download-token URLs written on empty covers. photos[].thumbUrl was not set. Rules were not deployed.",
    );
  }
  return redactDownloadToken(lines.join("\n"));
}

function loadManifest(packDir) {
  const manifestPath = resolve(packDir, "manifest.json");
  if (!existsSync(manifestPath)) throw new Error(`manifest.json not found in ${packDir}`);
  return JSON.parse(readFileSync(manifestPath, "utf8"));
}

async function openAdmin(project, env, bucketName) {
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length > 0) return admin;
  if (usesEmulator(env)) {
    admin.initializeApp({ projectId: project, storageBucket: bucketName });
    return admin;
  }
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) throw new Error("service-account.json was not found. No write.");
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== project) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${project}. No write.`,
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
    storageBucket: bucketName,
  });
  return admin;
}

async function loadTemples(project, env, bucketName) {
  const admin = await openAdmin(project, env, bucketName);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function runEmptyCoverPacks(opts, deps = {}) {
  const writeLog = deps.log ?? ((line) => console.log(line));
  const writeWarn = deps.warn ?? ((line) => console.warn(line));
  const log = (line) => writeLog(redactDownloadToken(line));
  const warn = (line) => writeWarn(redactDownloadToken(line));
  const env = deps.env ?? process.env;
  const bucketName = opts.bucket || STORAGE_AUTH_BUCKET;
  const project = resolveProject(opts, env);
  if (opts.apply) {
    await authorizeApply(project, env, { confirm: deps.confirm });
    useNativeFetchForStorageAuth();
    if (deps.storagePreflight) await deps.storagePreflight();
    else if (!usesEmulator(env)) {
      const admin = await openAdmin(project, env, bucketName);
      await assertStorageAuth(admin.storage().bucket(bucketName));
    }
  }
  const load = deps.load ?? ((id, environment) => loadTemples(id, environment, bucketName));
  const temples = await load(project, env);
  const byId = new Map((temples ?? []).map((temple) => [String(temple.id), temple]));
  const known = new Set(byId.keys());
  for (const id of [...(opts.exclude ?? [])].sort()) {
    if (!known.has(id)) warn(`exclude: unknown temple id ${id}`);
  }
  for (const id of [...(opts.only ?? [])].sort()) {
    if (!known.has(id)) warn(`only: unknown temple id ${id}`);
  }
  const only = opts.only instanceof Set ? opts.only : new Set(opts.only ?? []);
  const exclude = opts.exclude instanceof Set ? opts.exclude : new Set(opts.exclude ?? []);
  const plans = [];
  for (const packDir of opts.packDirs ?? []) {
    const manifest = loadManifest(packDir);
    const id = resolveSeedDocId(packDir, manifest, opts.docId && opts.packDirs.length === 1 ? opts.docId : null);
    if (only.size > 0 && !only.has(id)) continue;
    if (exclude.has(id)) {
      plans.push({ id, action: "skip", reason: "excluded" });
      continue;
    }
    plans.push(
      planEmptyCoverPack({
        temple: byId.get(id) ?? null,
        packDir,
        manifest,
        docIdOverride: opts.docId && opts.packDirs.length === 1 ? opts.docId : null,
      }),
    );
  }
  const rows = [];
  for (const plan of plans) {
    if (plan.action !== "write") {
      rows.push({ ...plan, result: "skipped" });
      continue;
    }
    if (!opts.apply) {
      rows.push({ ...plan, result: "would-write" });
      continue;
    }
    const upload =
      deps.uploadFrames ??
      (async (item) => {
        const admin = await openAdmin(project, env, bucketName);
        return defaultUploadFrames(item, admin, bucketName);
      });
    const urls = await upload(plan);
    let blocked = null;
    for (const url of urls) {
      const readable = await urlIsPublic(url, deps);
      if (!readable.ok) {
        log(`not-public ${plan.id} ${url}`);
        blocked = readable.reason;
        break;
      }
    }
    if (blocked) {
      rows.push({ ...plan, action: "skip", result: "skipped", reason: blocked });
      continue;
    }
    const photos = photosFromFrames(plan.frames, urls);
    const assigned = {
      ...plan,
      imageUrl: photos[0].url,
      images: photos.map((photo) => photo.url),
      photos,
    };
    const write =
      deps.write ??
      (async (item) => {
        const admin = await openAdmin(project, env, bucketName);
        return persistEmptyCover(admin.firestore(), item);
      });
    const written = await write(assigned);
    if (written && written.ok === false) {
      rows.push({ ...plan, action: "skip", result: "skipped", reason: written.reason });
      continue;
    }
    rows.push({ ...assigned, result: "wrote" });
  }
  log(formatEmptyCoverReport(rows, { apply: opts.apply === true }));
  return rows;
}
