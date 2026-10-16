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
 * manifest: the object must be in the temple-directory-india bucket
 * (`temple-directory-india.firebasestorage.app` or
 * `temple-directory-india.appspot.com`) and `temples/{id}/{frame}` must be
 * that temple's id and a manifest filename for the seed document id
 * `upload_research_pack.js` uses. Credit then comes from that frame, or
 * from a `photos` or `images` object whose url is that frame's
 * `source_url` or `downloaded_url`. A different file's credit is not used.
 * `image_N.jpg` is not treated as a frame. Otherwise the doc is skipped
 * with `no-matching-credit`. A plain dry-run or `--apply` never replaces
 * a cover. `--replace-uncredited-cover` is opt-in. It plans a replacement
 * only when `imageUrl` is `temples/{id}/image_N.jpg` (jpeg, jpg, png, or
 * webp) in the temple-directory-india bucket, that temple is Wave A or
 * Wave B, and `photos[]` has no credit for that cover. Timestamp admin
 * uploads, custom names, and `_480` thumbs are reported and left in
 * place. The new cover is a creditable photo marked `cover_ok`, or frame
 * 01 when no photo has that flag. A later frame is not used unless it is
 * `cover_ok`. `no_cover_frame` is checked first, so that pack is reported
 * as `no-cover-frame` even when a photo is also `cover_ok`, and frame 01
 * is left unused. A pack with two `cover_ok` photos fails validation.
 * The new object is `temples/{id}/{filename}`. Apply uploads it only when
 * it is missing, and does not set an object ACL or public IAM. The written
 * imageUrl is the Firebase download URL
 * `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>?alt=media&token=<token>`.
 * A new object gets a UUID in metadata.firebaseStorageDownloadTokens. An
 * object that already has a token keeps the first one. Before the write,
 * that token URL must return HTTP 200. A storage.googleapis.com URL is not
 * the check. A network error from that check skips the temple as
 * `public-check-failed` and the run continues. Apply checks once, before
 * any temple, that `fetch` exists. Each check aborts after about 10 seconds,
 * and that timeout is `public-check-failed` too. `--exclude id1,id2`
 * skips those temple ids and warns when an id is not in the loaded set.
 * Apply lists `temples/` once before any Firestore write. That list is
 * read-only. Any failure, including a 403 for storage.objects.list, stops
 * the run and names the error. Nothing is written to Firestore or Storage.
 * The transaction skips the doc when `imageUrl` is no longer the planned old
 * URL. The old Places object stays in Storage. A temple with no creditable
 * frame 01 is reported (`no-creditable-frame`, or `no-wave-pack`).
 * A placeholder author is `no-credit`: empty;
 * "unknown", "unknown author", "unknown artist", or "unknown photographer"
 * (repeats and extra spaces allowed); a name starting with "Unknown (";
 * "See " only when the next words are a placeholder (Commons, file page,
 * source, description, below); or a non-name such as "N/A", "-", "?",
 * "various", "author", "Myself", "Own work", "Self", "Self-photographed",
 * "Wikimedia Commons", "Commons", "public domain", or a bare URL.
 * A bracketed note is dropped and the name is kept, so Anonymous0006 and
 * "Rajesh Unknown" stay. A real
 * credit is a non-empty string of at most 200 characters. On a document
 * object, licence
 * must already be CC-BY, CC-BY-SA, CC0, Own, or Permission. A manifest
 * licence is the Commons string for that same frame, mapped with the
 * uploader's rules onto those five. Nothing is defaulted. Two different
 * pairs for the same cover are skipped as `ambiguous`.
 *
 * Apply re-reads each document in its own transaction, skips it when the
 * cover plan no longer matches, and writes `photos`. A replacement also
 * writes `imageUrl` and `images` after the frame is in Storage. The index
 * entry is rewritten from the fresh document, and meta is bumped, only
 * when that entry changed. An add does not change imageUrl or images.
 * The previous Storage object is not deleted.
 *
 *   node scripts/backfill_cover_photos.js --apply --project temple-directory-india
 *
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertOneCoverOk } from "./cover_ok.js";
import { downloadTokenUrl, ensureDownloadToken, withDownloadToken } from "./download_token.js";
import { firebaseMediaUrl } from "./resize_cover_thumbs.js";
import { assertStorageAuth, STORAGE_AUTH_BUCKET, useNativeFetchForStorageAuth } from "./storage_auth.js";
import { cleanAuthor, mapPhotoLicence, photoCredit } from "./photo_licence.js";
import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { changedFields, entryFromTemple, stateSlug, storageObjectFromUrl } from "./temple_index.js";
import {
  resolveSeedDocId,
  WAVE_A_TN_KL_PACKS,
  WAVE_B_KARNATAKA_PACKS,
} from "./upload_research_pack.js";

export { assertOneCoverOk };

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

/** Storage buckets for project temple-directory-india. */
const DIRECTORY_BUCKETS = new Set([
  "temple-directory-india.firebasestorage.app",
  "temple-directory-india.appspot.com",
]);

/** Public URL host for a frame this script uploads. */
export const COVER_BUCKET = "temple-directory-india.firebasestorage.app";

const WAVE_PACK_SLUGS = new Set([...WAVE_A_TN_KL_PACKS, ...WAVE_B_KARNATAKA_PACKS]);

/** Places uploader names. Timestamp, custom, and `_480` names do not match. */
const PLACES_COVER_FILE = /^image_\d+\.(?:jpe?g|png|webp)$/i;

/** Abort a public GET that has not finished. */
export const PUBLIC_CHECK_TIMEOUT_MS = 10_000;

/**
 * One startup check. A missing fetch fails the run before any temple is read.
 */
export function assertFetchAvailable(fetchImpl) {
  const impl = arguments.length === 0 ? globalThis.fetch : fetchImpl;
  if (typeof impl !== "function") {
    throw new Error("This Node has no fetch. No Firestore write.");
  }
}

/**
 * GET the token URL that will be written. Redirects are errors, so a hop
 * away from that URL is not a 200. `AbortSignal.timeout` stops a hung
 * request. The caller turns that throw into `public-check-failed`.
 */
export async function fetchPublicUrl(url, deps = {}) {
  const fetchImpl = deps.fetchImpl ?? globalThis.fetch;
  const timeoutMs = deps.timeoutMs ?? PUBLIC_CHECK_TIMEOUT_MS;
  const signal = deps.signal ?? AbortSignal.timeout(timeoutMs);
  const response = await fetchImpl(url, { method: "GET", redirect: "error", signal });
  try {
    await response.body?.cancel?.();
  } catch {
    // The status is what the check needs.
  }
  return response.status === 200;
}
const MAX_PHOTOS = 12;
const MAX_URL = 2000;

function printUsage() {
  console.log(`
Usage:
  node backfill_cover_photos.js [--dry-run] [--replace-uncredited-cover] [--exclude id1,id2] [--project <firebase-project-id>]
  node backfill_cover_photos.js --apply --project <firebase-project-id>

Default is dry-run: list Storage covers that would gain photos[0].
Nothing is written and nothing is uploaded. --replace-uncredited-cover
also lists Places image_N.jpg covers that would be replaced by frame 01.
A dry-run or --apply without that flag does not replace a cover.
prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.
`);
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    replaceUncreditedCover: false,
    exclude: new Set(),
    project: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--replace-uncredited-cover") opts.replaceUncreditedCover = true;
    else if (arg === "--exclude" || arg.startsWith("--exclude=")) {
      const raw = arg === "--exclude" ? argv[++i] : arg.slice("--exclude=".length);
      if (typeof raw !== "string" || raw.trim() === "" || raw.startsWith("--")) {
        throw new Error("--exclude needs a comma-separated list of temple ids");
      }
      for (const id of raw.split(",")) {
        const trimmed = id.trim();
        if (trimmed) opts.exclude.add(trimmed);
      }
    } else if (arg === "--apply") {
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

/** Longer tokens first so "unknown" does not swallow "unknown author". */
const PLACEHOLDER_AUTHOR_TOKENS = [
  "unknownphotographer",
  "unknownartist",
  "unknownauthor",
  "unknown",
];

/** Whole-string non-names. A longer credit that merely contains one is kept. */
const PLACEHOLDER_AUTHOR_EXACT = new Set([
  "n/a",
  "na",
  "n.a.",
  "n.a",
  "-",
  "--",
  "—",
  "–",
  "?",
  "various",
  "author",
  "myself",
  "own work",
  "self",
  "self-photographed",
  "self photographed",
  "wikimedia",
  "wikimedia commons",
  "commons",
  "public domain",
]);

function authorIsUrl(name) {
  const trimmed = String(name ?? "").trim();
  if (/^www\.\S+$/i.test(trimmed)) return true;
  try {
    const url = new URL(trimmed);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

/** "See Commons file page" and "see source". A surname such as "See" is not. */
function seePlaceholder(name) {
  const match = String(name ?? "").match(/^see\s+(.+)$/i);
  if (!match) return false;
  return /^(?:the\s+)?(?:commons|wikimedia|file(?:\s+page)?|source|description|below|above|page|original|licen[cs]e|attribution|here)\b/i.test(
    match[1].trim(),
  );
}

/**
 * No usable creator. Case-insensitive. "unknown", "unknown author",
 * "unknown artist", and "unknown photographer" may repeat, with or without
 * spaces. "See " is a placeholder only when a stock phrase follows
 * (Commons, file page, source, description, below). "See" and "Seetharaman"
 * are names. "N/A", "-", "?", "various", "author", "Myself", "Own work",
 * "Self", "Self-photographed", "Wikimedia Commons", "Commons",
 * "public domain", and a bare URL are the same gap. Anonymous0006 and
 * "Rajesh Unknown" are real names.
 */
export function placeholderAuthor(author) {
  const spaced = String(author ?? "").replace(/\s+/g, " ").trim();
  if (seePlaceholder(spaced)) return true;
  if (/^unknown\s*\(/i.test(spaced)) return true;
  if (authorIsUrl(spaced)) return true;
  const name = cleanAuthor(author);
  if (!name) return true;
  if (seePlaceholder(name) || authorIsUrl(name)) return true;
  const key = name.toLowerCase().replace(/\s+/g, " ").trim();
  if (PLACEHOLDER_AUTHOR_EXACT.has(key)) return true;
  let rest = key.replace(/\s+/g, "");
  if (!rest) return true;
  while (rest) {
    const token = PLACEHOLDER_AUTHOR_TOKENS.find((item) => rest.startsWith(item));
    if (!token) return false;
    rest = rest.slice(token.length);
  }
  return true;
}

function manifestPair(photo) {
  if (placeholderAuthor(photo?.author)) return { ok: false, reason: "no-credit" };
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
 * `waveDocIds` is the seed id of each Karnataka Wave B and TN+Kerala Wave A pack.
 */
let packFrames;
let waveDocIds;
let packManifests;
function loadPacks() {
  if (packFrames) return;
  const index = new Map();
  const waves = new Set();
  const manifests = new Map();
  if (!existsSync(packsRoot)) {
    packFrames = index;
    waveDocIds = waves;
    packManifests = manifests;
    return;
  }
  for (const entry of readdirSync(packsRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const packDir = resolve(packsRoot, entry.name);
    const manifestPath = resolve(packDir, "manifest.json");
    if (!existsSync(manifestPath)) continue;
    const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    const docId = resolveSeedDocId(packDir, manifest, null);
    if (!docId) continue;
    if (WAVE_PACK_SLUGS.has(entry.name)) waves.add(docId);
    manifests.set(docId, manifest);
    const list = index.get(docId) ?? [];
    const photos = Array.isArray(manifest.photos) ? manifest.photos : [];
    assertOneCoverOk(docId, photos);
    for (const photo of photos) {
      if (!photo || typeof photo.filename !== "string" || photo.filename === "") continue;
      const pair = manifestPair(photo);
      list.push({
        filename: photo.filename,
        localPath: resolve(packDir, photo.filename),
        coverOk: photo.cover_ok === true,
        pair: pair.ok ? { credit: pair.credit, licence: pair.licence } : null,
        reason: pair.ok ? null : pair.reason,
        sourceUrls: sourceUrlsFor(photo),
      });
    }
    index.set(docId, list);
  }
  packFrames = index;
  waveDocIds = waves;
  packManifests = manifests;
}

function framesByTempleId() {
  loadPacks();
  return packFrames;
}

function waveTempleIds() {
  loadPacks();
  return waveDocIds;
}

function manifestByTempleId() {
  loadPacks();
  return packManifests;
}

function isExcluded(exclude, id) {
  if (!exclude || id === "") return false;
  if (exclude instanceof Set) return exclude.has(id);
  if (Array.isArray(exclude)) return exclude.includes(id);
  return false;
}

/**
 * `no_cover_frame` wins over `cover_ok` and over frame 01. Otherwise the
 * choice is a creditable `cover_ok` photo, then frame 01 when it is creditable.
 */
export function bestCreditableFrame(frames, opts = {}) {
  if (!Array.isArray(frames) || frames.length === 0) return null;
  if (opts.noCoverFrame === true) return null;
  const flagged = frames.find((frame) => frame.coverOk && frame.pair);
  if (flagged) return flagged;
  const cover = frames.find((frame) => /^01(?:_|\.|$)/.test(frame.filename));
  if (!cover?.pair) return null;
  return cover;
}

/**
 * The frame a pack manifest would use as a replacement cover.
 * `no_cover_frame` returns null even when a photo is `cover_ok`.
 */
export function coverFrameForPack(manifest) {
  const photos = Array.isArray(manifest?.photos) ? manifest.photos : [];
  const docId = String(manifest?.doc_id_hint || manifest?.temple_slug || "pack");
  assertOneCoverOk(docId, photos);
  const frames = [];
  for (const photo of photos) {
    if (!photo || typeof photo.filename !== "string" || photo.filename === "") continue;
    const pair = manifestPair(photo);
    frames.push({
      filename: photo.filename,
      coverOk: photo.cover_ok === true,
      pair: pair.ok ? { credit: pair.credit, licence: pair.licence } : null,
    });
  }
  return bestCreditableFrame(frames, { noCoverFrame: manifest?.no_cover_frame === true });
}

export function storageCoverUrl(docId, filename) {
  return `https://storage.googleapis.com/${COVER_BUCKET}/temples/${docId}/${filename}`;
}

/** Download URL written to imageUrl. The token is the object's Firebase token. */
export function coverDownloadUrl(objectPath, token) {
  return downloadTokenUrl(COVER_BUCKET, objectPath, token);
}

/**
 * `images[0]` becomes the new cover. A cover slot that was the old object
 * is replaced in the list. The Storage object itself is not removed.
 */
export function mirrorCoverImages(images, oldUrl, newUrl) {
  const list = Array.isArray(images)
    ? images.filter((item) => {
        if (typeof item === "string") return item !== newUrl;
        if (item && typeof item === "object" && typeof item.url === "string") return item.url !== newUrl;
        return true;
      })
    : [];
  if (list.length === 0) return [newUrl];
  const first = list[0];
  const firstIsOld =
    first === oldUrl || (first && typeof first === "object" && first.url === oldUrl);
  if (firstIsOld) return [newUrl, ...list.slice(1)];
  return [newUrl, ...list];
}

/**
 * This temple's object in the temple-directory-india bucket, at
 * `temples/{id}/{filename}`.
 */
function directoryObject(templeId, imageUrl) {
  const located = storageObjectFromUrl(imageUrl);
  if (!located || !DIRECTORY_BUCKETS.has(located.bucket.toLowerCase())) return null;
  const parts = located.objectPath.split("/").filter(Boolean);
  if (parts.length !== 3 || parts[0] !== "temples") return null;
  const slug = parts[1];
  const filename = parts[2];
  if (String(templeId ?? "") !== slug) return null;
  return { slug, filename, objectPath: `${parts[0]}/${slug}/${filename}` };
}

/**
 * The manifest frame named by a Storage cover, when the object is in the
 * temple-directory-india bucket, the path is `temples/{templeId}/{filename}`,
 * and that filename is in that temple's pack. Another bucket, a different
 * slug, or a Places `image_N.jpg` name does not match.
 */
function packFrameForCover(templeId, imageUrl) {
  const located = directoryObject(templeId, imageUrl);
  if (!located) return null;
  const { slug, filename } = located;
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

function photoHasCredit(photo) {
  const credit = typeof photo?.credit === "string" ? photo.credit.trim() : "";
  return credit !== "" && !placeholderAuthor(credit);
}

/**
 * Places `image_N` cover on a Wave A/B temple, replaced by frame 01.
 * Timestamp names, custom names, and `_480` thumbs are reported and left
 * in place. Returns null when this cover is not in this temple's bucket.
 */
function replacementPlan(temple, imageUrl, photos, failed, opts = {}) {
  const located = directoryObject(temple?.id, imageUrl);
  if (!located) return null;
  if (failed.reason !== "no-matching-credit" && failed.reason !== "no-credit") return null;
  const id = located.slug;
  if (!PLACES_COVER_FILE.test(located.filename)) {
    return { id, action: "skip", reason: "not-places-cover", imageUrl, oldObject: located.objectPath };
  }
  if (photos.some((photo) => photoUrl(photo) === imageUrl && photoHasCredit(photo))) return null;
  const frames = framesByTempleId().get(id) ?? [];
  if (!waveTempleIds().has(id)) {
    return { id, action: "skip", reason: "no-wave-pack", imageUrl, oldObject: located.objectPath };
  }
  const manifest = manifestByTempleId().get(id);
  const chosen = manifest ? coverFrameForPack(manifest) : null;
  const stored = chosen ? frames.find((frame) => frame.filename === chosen.filename) : null;
  const best = stored && chosen.pair ? { ...stored, pair: chosen.pair } : null;
  if (!best || best.filename === located.filename) {
    return {
      id,
      action: "skip",
      reason: manifest?.no_cover_frame === true ? "no-cover-frame" : "no-creditable-frame",
      imageUrl,
      oldObject: located.objectPath,
    };
  }
  const objectPath = `temples/${id}/${best.filename}`;
  const url = opts.downloadToken
    ? coverDownloadUrl(objectPath, opts.downloadToken)
    : storageCoverUrl(id, best.filename);
  if (!url.startsWith("https://") || url.length > MAX_URL) {
    return { id, action: "skip", reason: "not-https", imageUrl };
  }
  const rest = photos.filter((photo) => photoUrl(photo) !== url);
  if (rest.length >= MAX_PHOTOS) return { id, action: "skip", reason: "photos-full", imageUrl };
  const nextPhotos = [{ url, credit: best.pair.credit, licence: best.pair.licence }, ...rest].map(
    (item, order) => ({ ...item, order }),
  );
  return {
    id,
    action: "replace",
    imageUrl: url,
    oldImageUrl: imageUrl,
    oldObject: located.objectPath,
    filename: best.filename,
    objectPath,
    downloadToken: opts.downloadToken,
    localPath: best.localPath,
    upload: "if-missing",
    photo: nextPhotos[0],
    photos: nextPhotos,
    images: mirrorCoverImages(temple?.images, imageUrl, url),
    plannedState: temple?.state,
    temple,
  };
}

/**
 * Plan for one temple. `add` prepends the Storage cover. `replace` is
 * planned only when `opts.replaceUncreditedCover` is true. Other docs are
 * `skip` with a reason. A Storage cover that already has a matching photo
 * is `ready` and is not listed as added or skipped.
 */
export function planCoverPhoto(temple, opts = {}) {
  const replaceUncredited = opts.replaceUncreditedCover === true;
  const id = String(temple?.id ?? "");
  if (isExcluded(opts.exclude, id)) return { id, action: "skip", reason: "excluded" };
  const imageUrl = typeof temple?.imageUrl === "string" ? temple.imageUrl.trim() : "";
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  if (!imageUrl || !storageObjectFromUrl(imageUrl)) {
    return { id, action: "ready", reason: "not-storage" };
  }
  if (!imageUrl.startsWith("https://") || imageUrl.length > MAX_URL) {
    return { id, action: "skip", reason: "not-https", imageUrl };
  }
  if (photos.some((photo) => photoUrl(photo) === imageUrl)) {
    const credited = photos.some((photo) => photoUrl(photo) === imageUrl && photoHasCredit(photo));
    if (credited || !replaceUncredited) return { id, action: "ready", reason: "already" };
  }
  const shape = photosShape(photos);
  if (shape) return { id, action: "skip", reason: shape, imageUrl };
  if (photos.length >= MAX_PHOTOS) return { id, action: "skip", reason: "photos-full", imageUrl };
  const copied = attribution(temple, imageUrl);
  if (!copied.ok) {
    if (!replaceUncredited) return { id, action: "skip", reason: copied.reason, imageUrl };
    return replacementPlan(temple, imageUrl, photos, copied, opts) ?? {
      id,
      action: "skip",
      reason: copied.reason,
      imageUrl,
    };
  }
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

export function planCoverPhotos(temples, opts = {}) {
  return (temples ?? []).map((temple) => planCoverPhoto(temple, opts));
}

/**
 * Re-read check. A doc whose plan is no longer the same add or replace
 * is not written.
 */
export function commitCoverPhoto(fresh, plan) {
  if (plan.action === "replace") {
    const current = typeof fresh?.imageUrl === "string" ? fresh.imageUrl.trim() : "";
    if (current !== plan.oldImageUrl) return { ok: false, reason: "changed" };
  }
  const again = planCoverPhoto(
    { ...fresh, id: fresh?.id ?? plan.id },
    {
      replaceUncreditedCover: plan.action === "replace",
      downloadToken: plan.downloadToken,
    },
  );
  const sameAction = again.action === plan.action && (plan.action === "add" || plan.action === "replace");
  if (!sameAction || again.photo.url !== plan.photo.url) {
    const reason = again.reason === "already" ? "already" : "changed";
    return { ok: false, reason };
  }
  if (again.photo.credit !== plan.photo.credit || again.photo.licence !== plan.photo.licence) {
    return { ok: false, reason: "changed" };
  }
  if (plan.action === "replace" && again.imageUrl !== plan.imageUrl) {
    return { ok: false, reason: "changed" };
  }
  const id = String(fresh?.id ?? plan.id);
  const temple = { ...fresh, id, photos: again.photos };
  if (plan.action === "replace") {
    temple.imageUrl = again.imageUrl;
    temple.images = again.images;
    return {
      ok: true,
      photos: again.photos,
      imageUrl: again.imageUrl,
      images: again.images,
      temple,
    };
  }
  return { ok: true, photos: again.photos, temple };
}

export function formatCoverPhotoReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const added = rows.filter((row) => row.action === "add" && row.result !== "skipped");
  const replaced = rows.filter((row) => row.action === "replace" && row.result !== "skipped");
  const skipped = rows.filter((row) => row.action === "skip" || row.result === "skipped");
  lines.push(`added: ${added.length}`);
  for (const row of added) lines.push(`${row.result ?? "would-add"} ${row.id}`);
  lines.push(`replaced: ${replaced.length}`);
  for (const row of replaced) {
    lines.push(`${row.result ?? "would-replace"} ${row.id}`);
    lines.push(`  old: ${row.oldObject}`);
    lines.push(`  new: ${row.filename}`);
    lines.push(`  credit: ${row.photo.credit}`);
    lines.push(`  licence: ${row.photo.licence}`);
    lines.push(`  upload: ${row.upload ?? "if-missing"}`);
  }
  lines.push(`skipped: ${skipped.length}`);
  for (const row of skipped) lines.push(`skip ${row.id} ${row.reason}`);
  if (!apply) lines.push("Dry-run only. No Firestore writes. No Storage uploads.");
  else {
    lines.push(
      "photos, and for a replaced cover imageUrl and images. The previous Storage object is kept. Rules were not deployed.",
    );
  }
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
    const templePatch = { photos: committed.photos };
    if (plan.action === "replace") {
      templePatch.imageUrl = committed.imageUrl;
      templePatch.images = committed.images;
    }
    tx.update(templeRef, templePatch);
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
    if (plan.action !== "add" && plan.action !== "replace") {
      report.push(plan.action === "skip" ? { ...plan, result: "skipped" } : plan);
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...plan, result: plan.action === "replace" ? "would-replace" : "would-add" });
      continue;
    }
    if (plan.action === "replace" && deps.ensureUploaded) {
      const ensured = await deps.ensureUploaded(plan);
      if (!ensured || ensured.ok === false) {
        report.push({
          ...plan,
          action: "skip",
          result: "skipped",
          reason: ensured?.reason || "upload",
        });
        continue;
      }
      if (typeof ensured.imageUrl === "string" && ensured.imageUrl !== "") {
        assignCoverDownloadUrl(plan, ensured.imageUrl, ensured.token);
      }
    }
    const written = await deps.write(plan);
    if (written && written.ok === false) {
      report.push({ ...plan, action: "skip", result: "skipped", reason: written.reason });
      continue;
    }
    report.push({ ...plan, result: plan.action === "replace" ? "replaced" : "added" });
  }
  return report;
}

/**
 * Put the verified download URL on the plan the transaction will write.
 * The replan uses `downloadToken`, so the guard still compares that same URL.
 */
export function assignCoverDownloadUrl(plan, imageUrl, token) {
  const previous = plan.imageUrl;
  plan.downloadToken = token;
  plan.imageUrl = imageUrl;
  if (plan.photo && plan.photo.url === previous) plan.photo = { ...plan.photo, url: imageUrl };
  if (Array.isArray(plan.photos)) {
    plan.photos = plan.photos.map((photo) =>
      photo && photo.url === previous ? { ...photo, url: imageUrl } : photo,
    );
  }
  if (Array.isArray(plan.images)) {
    plan.images = plan.images.map((item) => {
      if (typeof item === "string") return item === previous ? imageUrl : item;
      if (item && typeof item === "object" && item.url === previous) return { ...item, url: imageUrl };
      return item;
    });
  }
  return plan;
}

/**
 * HTTP 200 on the Firebase download URL this plan will write. Redirects
 * are refused. A storage.googleapis.com URL is not public under uniform
 * bucket-level access, so it fails this check. DNS failure, connection
 * reset, and timeout are `public-check-failed` so the next temple still runs.
 */
async function writtenUrlIsPublic(url, deps) {
  if (firebaseMediaUrl(url) == null) return { ok: false, reason: "not-public" };
  const check = deps.verifyPublic ?? ((next) => fetchPublicUrl(next, deps));
  try {
    const ok = (await check(url)) === true;
    return ok ? { ok: true } : { ok: false, reason: "not-public" };
  } catch {
    return { ok: false, reason: "public-check-failed" };
  }
}

/**
 * Upload `temples/{id}/{filename}` when that object is missing. The object
 * keeps a Firebase download token and is not made public. An existing token
 * is reused. The previous cover object is not deleted.
 */
export async function ensureCoverFrame(plan, deps = {}) {
  const objectPath = typeof plan?.objectPath === "string" ? plan.objectPath : "";
  const localPath = typeof plan?.localPath === "string" ? plan.localPath : "";
  if (!objectPath || !localPath) return { ok: false, reason: "missing-file" };
  const bucket = deps.bucket ?? deps.admin.storage().bucket(COVER_BUCKET);
  const file = bucket.file(objectPath);
  const ensured = await ensureDownloadToken(file, COVER_BUCKET, objectPath, { newToken: deps.newToken });
  if (!ensured.exists) {
    if (!existsSync(localPath)) return { ok: false, reason: "missing-file" };
    const contentType = localPath.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
    await bucket.upload(localPath, {
      destination: objectPath,
      metadata: withDownloadToken(
        {
          contentType,
          cacheControl: "public, max-age=3600",
        },
        ensured.token,
      ),
    });
  }
  const readable = await writtenUrlIsPublic(ensured.url, deps);
  if (!readable.ok) return { ok: false, reason: readable.reason };
  return { ok: true, uploaded: !ensured.exists, imageUrl: ensured.url, token: ensured.token };
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
  const warn = deps.warn ?? ((line) => console.warn(line));
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
  const fetchImpl = Object.prototype.hasOwnProperty.call(deps, "fetchImpl")
    ? deps.fetchImpl
    : globalThis.fetch;
  if (opts.apply && opts.replaceUncreditedCover) assertFetchAvailable(fetchImpl);
  const load = deps.load ?? loadTemples;
  const temples = await load(project, env);
  temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  const knownIds = new Set(temples.map((temple) => String(temple?.id ?? "")));
  for (const id of [...opts.exclude].sort()) {
    if (!knownIds.has(id)) warn(`exclude: unknown temple id ${id}`);
  }
  const plans = planCoverPhotos(temples, {
    replaceUncreditedCover: opts.replaceUncreditedCover === true,
    exclude: opts.exclude,
  });
  const rows = await applyCoverPhotoPlans(plans, {
    dryRun: !opts.apply,
    ensureUploaded:
      deps.ensureUploaded ??
      (async (plan) => {
        const admin = await openAdmin(project, env);
        return ensureCoverFrame(plan, { admin, fetchImpl });
      }),
    write:
      deps.write ??
      (async (plan) => {
        const admin = await openAdmin(project, env);
        return persistCoverPhoto(admin.firestore(), plan, { admin });
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
