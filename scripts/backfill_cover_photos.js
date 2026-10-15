/**
 * Add a cover `photos[]` entry when `imageUrl` is already in Storage and
 * no photo url matches it.
 *
 * Dry-run is the default. It reads temple documents and prints which covers
 * would gain `photos[0]`. It does not write.
 *
 *   node scripts/backfill_cover_photos.js --project temple-directory-india
 *
 * The new entry is `{ url: imageUrl, credit, licence, order: 0 }`, and every
 * photo's `order` is then the array index, so the old cover is 1 rather
 * than a second 0. Credit and licence are copied only from a `photos` or
 * `images` object whose `url` equals that cover, or whose recorded mirror
 * source equals it. That source is the original URL
 * `patch_image_url_mirror` copied from, when the object stores it on
 * `source`, `sourceUrl`, `source_url`, or `mirroredFrom`. A Storage mirror
 * whose document has no such object is resolved through the photo-pack
 * manifest: `temples/{id}/{frame}` must be that temple's id and a manifest
 * filename for the seed document id `upload_research_pack.js` uses. Credit
 * then comes from that frame, or from a `photos` or `images` object whose
 * url is that frame's `source_url` or `downloaded_url`. A different file's
 * credit is not used. `image_N.jpg` is not treated as a frame. Otherwise
 * the doc is skipped with `no-matching-credit`. A real credit is a
 * non-empty string of at most 200 characters. On a document object, licence
 * must already be CC-BY, CC-BY-SA, CC0, Own, or Permission. A manifest
 * licence is the Commons string for that same frame, mapped with the
 * uploader's rules onto those five. Nothing is defaulted. Two different
 * pairs for the same cover are skipped as `ambiguous`.
 *
 * Apply re-reads each document in its own transaction, skips it when the
 * cover plan no longer matches, and writes `photos`. The index entry is
 * rewritten from the fresh document, and meta is bumped, only when that
 * entry changed. imageUrl and images are not changed.
 *
 *   node scripts/backfill_cover_photos.js --apply --project temple-directory-india
 *
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { mapPhotoLicence, photoCredit } from "./photo_licence.js";
import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { changedFields, entryFromTemple, stateSlug, storageObjectFromUrl } from "./temple_index.js";
import { resolveSeedDocId } from "./upload_research_pack.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packsRoot = resolve(__dirname, "..", "tools", "photo-packs");

/**
 * Wire values already accepted by firestore.rules and PhotoLicence.
 * Architect kept Own and Permission on this list.
 */
export const PHOTO_LICENCES = ["CC-BY", "CC-BY-SA", "CC0", "Own", "Permission"];

/** Original URL a mirror copied from, when an image object stored it. */
const MIRROR_SOURCE_KEYS = ["source", "sourceUrl", "source_url", "mirroredFrom"];
const MAX_CREDIT = 200;
const MAX_PHOTOS = 12;
const MAX_URL = 2000;

function printUsage() {
  console.log(`
Usage:
  node backfill_cover_photos.js [--dry-run] [--project <firebase-project-id>]
  node backfill_cover_photos.js --apply --project <firebase-project-id>

Default is dry-run: list Storage covers whose photos[] has no matching url.
Nothing is written. prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.
`);
}

export function parseArgs(argv) {
  const opts = { dryRun: true, apply: false, project: null, help: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--project") opts.project = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

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

function photoUrl(photo) {
  if (!photo || typeof photo !== "object") return "";
  return typeof photo.url === "string" ? photo.url.trim() : "";
}

function hasOwn(source, key) {
  return Object.prototype.hasOwnProperty.call(source, key);
}

/**
 * One credit/licence pair already stored on an image object, or a reason
 * the stored fields cannot be copied.
 */
function pairFrom(source) {
  if (!source || typeof source !== "object" || Array.isArray(source)) return null;
  if (!hasOwn(source, "credit") && !hasOwn(source, "licence")) return null;
  const credit = typeof source.credit === "string" ? source.credit.trim() : "";
  const licence = typeof source.licence === "string" ? source.licence.trim() : "";
  const creditOk = credit !== "" && credit.length <= MAX_CREDIT;
  const licenceOk = PHOTO_LICENCES.includes(licence);
  if (creditOk && licenceOk) return { ok: true, credit, licence };
  if (!creditOk) return { ok: false, reason: "no-credit" };
  return { ok: false, reason: "licence" };
}

function imageObjects(temple) {
  const objects = [];
  for (const list of [temple?.photos, temple?.images]) {
    if (!Array.isArray(list)) continue;
    for (const item of list) {
      if (item && typeof item === "object" && !Array.isArray(item)) objects.push(item);
    }
  }
  return objects;
}

/** The object is this cover, or it records that the cover is the URL it was mirrored from. */
function coversImage(item, imageUrl) {
  if (photoUrl(item) === imageUrl) return true;
  for (const key of MIRROR_SOURCE_KEYS) {
    if (typeof item[key] !== "string") continue;
    if (item[key].trim() === imageUrl) return true;
  }
  return false;
}

/** Host and decoded path, without query or hash. Empty when it is not an http URL. */
function canonicalImageUrl(raw) {
  const trimmed = String(raw ?? "").trim();
  if (!trimmed) return "";
  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch {
    return "";
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return "";
  const path = parsed.pathname
    .split("/")
    .map((segment) => {
      try {
        return decodeURIComponent(segment);
      } catch {
        return segment;
      }
    })
    .join("/");
  return `${parsed.protocol}//${parsed.hostname.toLowerCase()}${path}`;
}

function manifestPair(photo) {
  let licence;
  try {
    licence = mapPhotoLicence(photo.license);
  } catch {
    return { ok: false, reason: "licence" };
  }
  if (!PHOTO_LICENCES.includes(licence)) return { ok: false, reason: "licence" };
  let credit = "";
  try {
    credit = photoCredit(photo.author || "", photo.license).trim();
  } catch {
    return { ok: false, reason: "licence" };
  }
  if (credit === "" || credit.length > MAX_CREDIT) return { ok: false, reason: "no-credit" };
  return { ok: true, credit, licence };
}

function sourceUrlsFor(photo) {
  const urls = new Set();
  for (const key of ["source_url", "downloaded_url"]) {
    const canonical = canonicalImageUrl(photo?.[key]);
    if (canonical) urls.add(canonical);
  }
  return urls;
}

/**
 * Pack photos keyed by the seed document id the uploader writes under
 * `temples/{id}/`. Built once from tools/photo-packs manifests.
 */
let packFrames;
function framesByTempleId() {
  if (packFrames) return packFrames;
  const index = new Map();
  if (!existsSync(packsRoot)) {
    packFrames = index;
    return index;
  }
  for (const entry of readdirSync(packsRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const packDir = resolve(packsRoot, entry.name);
    const manifestPath = resolve(packDir, "manifest.json");
    if (!existsSync(manifestPath)) continue;
    const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    const docId = resolveSeedDocId(packDir, manifest, null);
    if (!docId) continue;
    const list = index.get(docId) ?? [];
    const photos = Array.isArray(manifest.photos) ? manifest.photos : [];
    for (const photo of photos) {
      if (!photo || typeof photo.filename !== "string" || photo.filename === "") continue;
      const pair = manifestPair(photo);
      list.push({
        filename: photo.filename,
        pair: pair.ok ? { credit: pair.credit, licence: pair.licence } : null,
        reason: pair.ok ? null : pair.reason,
        sourceUrls: sourceUrlsFor(photo),
      });
    }
    index.set(docId, list);
  }
  packFrames = index;
  return index;
}

/**
 * The manifest frame named by a Storage cover, when the object path is
 * `temples/{templeId}/{filename}` and that filename is in that temple's pack.
 * A different slug or a Places `image_N.jpg` name does not match.
 */
function packFrameForCover(templeId, imageUrl) {
  const located = storageObjectFromUrl(imageUrl);
  if (!located) return null;
  const parts = located.objectPath.split("/").filter(Boolean);
  if (parts.length !== 3 || parts[0] !== "temples") return null;
  const slug = parts[1];
  const filename = parts[2];
  if (String(templeId ?? "") !== slug) return null;
  const frames = framesByTempleId().get(slug) ?? [];
  const matches = frames.filter((frame) => frame.filename === filename);
  if (matches.length === 0) return null;
  const usable = matches.filter((frame) => frame.pair);
  if (usable.length === 0) {
    const reason = matches.some((frame) => frame.reason === "no-credit") ? "no-credit" : "licence";
    return { ok: false, reason };
  }
  const first = usable[0].pair;
  const mixed = usable.some(
    (frame) => frame.pair.credit !== first.credit || frame.pair.licence !== first.licence,
  );
  if (mixed) return { ok: false, reason: "ambiguous" };
  const sourceUrls = new Set();
  for (const frame of usable) {
    for (const url of frame.sourceUrls) sourceUrls.add(url);
  }
  return { ok: true, ...first, sourceUrls };
}

function itemMatchesSources(item, sourceUrls) {
  if (!sourceUrls || sourceUrls.size === 0) return false;
  const keys = ["url", ...MIRROR_SOURCE_KEYS];
  for (const key of keys) {
    if (typeof item[key] !== "string") continue;
    const canonical = canonicalImageUrl(item[key]);
    if (canonical && sourceUrls.has(canonical)) return true;
  }
  return false;
}

function decidePairs(items) {
  const found = [];
  const problems = [];
  let saw = false;
  for (const source of items) {
    const pair = pairFrom(source);
    if (!pair) continue;
    saw = true;
    if (pair.ok) found.push(pair);
    else problems.push(pair.reason);
  }
  if (!saw) return null;
  if (found.length === 0) {
    if (problems.includes("no-credit")) return { ok: false, reason: "no-credit" };
    if (problems.includes("licence")) return { ok: false, reason: "licence" };
    return { ok: false, reason: "no-matching-credit" };
  }
  const first = found[0];
  const mixed = found.some((pair) => pair.credit !== first.credit || pair.licence !== first.licence);
  if (mixed) return { ok: false, reason: "ambiguous" };
  return first;
}

function attribution(temple, imageUrl) {
  const objects = imageObjects(temple);
  const direct = decidePairs(objects.filter((item) => coversImage(item, imageUrl)));
  if (direct) return direct;

  const frame = packFrameForCover(temple?.id, imageUrl);
  if (!frame) return { ok: false, reason: "no-matching-credit" };
  if (!frame.ok) return frame;

  const fromSource = decidePairs(objects.filter((item) => itemMatchesSources(item, frame.sourceUrls)));
  if (fromSource) return fromSource;
  return { ok: true, credit: frame.credit, licence: frame.licence };
}

function photosShape(photos) {
  if (!Array.isArray(photos)) return "photos-shape";
  for (const photo of photos) {
    if (!photo || typeof photo !== "object" || Array.isArray(photo)) return "photos-shape";
    if (typeof photo.url !== "string" || photo.url.trim() === "") return "photos-shape";
    if (typeof photo.order !== "number" || !Number.isInteger(photo.order)) return "photos-shape";
  }
  return null;
}

/**
 * Plan for one temple. `add` prepends the Storage cover. Other docs are
 * `skip` with a reason. A Storage cover that already has a matching photo
 * is `ready` and is not listed as added or skipped.
 */
export function planCoverPhoto(temple) {
  const id = String(temple?.id ?? "");
  const imageUrl = typeof temple?.imageUrl === "string" ? temple.imageUrl.trim() : "";
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  if (!imageUrl || !storageObjectFromUrl(imageUrl)) {
    return { id, action: "ready", reason: "not-storage" };
  }
  if (!imageUrl.startsWith("https://") || imageUrl.length > MAX_URL) {
    return { id, action: "skip", reason: "not-https", imageUrl };
  }
  if (photos.some((photo) => photoUrl(photo) === imageUrl)) {
    return { id, action: "ready", reason: "already" };
  }
  const shape = photosShape(photos);
  if (shape) return { id, action: "skip", reason: shape, imageUrl };
  if (photos.length >= MAX_PHOTOS) return { id, action: "skip", reason: "photos-full", imageUrl };
  const copied = attribution(temple, imageUrl);
  if (!copied.ok) return { id, action: "skip", reason: copied.reason, imageUrl };
  const cover = { url: imageUrl, credit: copied.credit, licence: copied.licence };
  const nextPhotos = [cover, ...photos].map((item, order) => ({ ...item, order }));
  return {
    id,
    action: "add",
    imageUrl,
    photo: nextPhotos[0],
    photos: nextPhotos,
    plannedState: temple?.state,
    temple,
  };
}

export function planCoverPhotos(temples) {
  return (temples ?? []).map((temple) => planCoverPhoto(temple));
}

/**
 * Re-read check. A doc whose plan is no longer the same add is not written.
 */
export function commitCoverPhoto(fresh, plan) {
  const again = planCoverPhoto({ ...fresh, id: fresh?.id ?? plan.id });
  if (again.action !== "add" || again.photo.url !== plan.photo.url) {
    const reason = again.reason === "already" ? "already" : "changed";
    return { ok: false, reason };
  }
  if (again.photo.credit !== plan.photo.credit || again.photo.licence !== plan.photo.licence) {
    return { ok: false, reason: "changed" };
  }
  const id = String(fresh?.id ?? plan.id);
  return {
    ok: true,
    photos: again.photos,
    temple: { ...fresh, id, photos: again.photos },
  };
}

export function formatCoverPhotoReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const added = rows.filter((row) => row.action === "add" && row.result !== "skipped");
  const skipped = rows.filter((row) => row.action === "skip" || row.result === "skipped");
  lines.push(`added: ${added.length}`);
  for (const row of added) lines.push(`${row.result ?? "would-add"} ${row.id}`);
  lines.push(`skipped: ${skipped.length}`);
  for (const row of skipped) lines.push(`skip ${row.id} ${row.reason}`);
  if (!apply) lines.push("Dry-run only. No Firestore writes.");
  else lines.push("photos, and the index entry when it changed. Rules were not deployed.");
  return lines.join("\n");
}

/**
 * One transaction per temple. Re-read, skip when the plan no longer matches,
 * then set photos and that temple's index entry from the fresh document.
 */
export async function persistCoverPhoto(db, plan, deps = {}) {
  const admin = deps.admin ?? (await import("firebase-admin")).default;
  const id = String(plan.id ?? "");
  if (!id) return { ok: false, reason: "missing" };
  const plannedState = plan.plannedState ?? plan.temple?.state;
  return db.runTransaction(async (tx) => {
    const templeRef = db.collection("temples").doc(id);
    const templeSnap = await tx.get(templeRef);
    if (!templeSnap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...templeSnap.data(), id: templeSnap.id };
    const committed = commitCoverPhoto(fresh, plan);
    if (!committed.ok) return committed;
    const shard = stateSlug(committed.temple.state);
    const previous =
      typeof plannedState === "string" && plannedState !== "" ? stateSlug(plannedState) : null;
    const indexRef = db.collection("temple_index").doc(shard);
    const metaRef = db.collection("meta").doc("temple_index");
    // Compared below so meta moves only when this entry changed.
    const indexSnap = await tx.get(indexRef);
    const metaSnap = await tx.get(metaRef);
    const oldRef = previous && previous !== shard ? db.collection("temple_index").doc(previous) : null;
    const oldSnap = oldRef ? await tx.get(oldRef) : null;
    tx.update(templeRef, { photos: committed.photos });
    const expected = entryFromTemple(committed.temple);
    const stored = indexSnap.exists ? indexSnap.data()?.entries?.[id] : undefined;
    const entryChanged = changedFields(stored, expected).length > 0;
    const moved = Boolean(oldRef && oldSnap?.exists);
    let entry = null;
    if (entryChanged) {
      entry = {
        ...expected,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.set(
        indexRef,
        { entries: { [id]: entry } },
        { mergeFields: [new admin.firestore.FieldPath("entries", id)] },
      );
    }
    if (moved) {
      tx.update(
        oldRef,
        new admin.firestore.FieldPath("entries", id),
        admin.firestore.FieldValue.delete(),
      );
    }
    if (entryChanged || moved) {
      const touched = moved ? [shard, previous] : [shard];
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
    }
    return { ...committed, shard, entry, entryChanged };
  });
}

export async function applyCoverPhotoPlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "add") {
      report.push(plan.action === "skip" ? { ...plan, result: "skipped" } : plan);
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...plan, result: "would-add" });
      continue;
    }
    const written = await deps.write(plan);
    if (written && written.ok === false) {
      report.push({ ...plan, action: "skip", result: "skipped", reason: written.reason });
      continue;
    }
    report.push({ ...plan, result: "added" });
  }
  return report;
}

async function openAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length > 0) return admin;
  if (usesEmulator(env)) {
    admin.initializeApp({ projectId: project });
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
  });
  return admin;
}

async function loadTemples(project, env) {
  const admin = await openAdmin(project, env);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
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
  const plans = planCoverPhotos(temples);
  const rows = await applyCoverPhotoPlans(plans, {
    dryRun: !opts.apply,
    write:
      deps.write ??
      (async (plan) => {
        const admin = await openAdmin(project, env);
        return persistCoverPhoto(admin.firestore(), plan);
      }),
  });
  log(formatCoverPhotoReport(rows, { apply: opts.apply }));
  return rows;
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  main().catch((error) => {
    console.error(error?.message || error);
    process.exitCode = 1;
  });
}
