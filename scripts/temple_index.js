import { createHash } from "node:crypto";

/**
 * Pure temple_index projection. No Firestore client.
 * Entry shape matches lib/models/temple_index.dart.
 * Tradition / living flags follow DetailHonesty for the cases in
 * scripts/fixtures/temple_index_flags.json.
 */

export const ENTRY_VERSION = 1;
export const MAX_ENTRIES = 400;
export const MAX_SHARDS = 48;
export const SHORT_ADDRESS_MAX = 340;
export const COVER_THUMB_MAX = 500;
/** Wikimedia serves 500px and rejects 480px with HTTP 400. */
export const COMMONS_THUMB_PX = 500;
/** Hotlinked thumb widths from w.wiki/GHai ($wgThumbnailSteps). */
const WIKIMEDIA_THUMB_STEPS = new Set([
  20, 40, 60, 120, 250, 330, 500, 960, 1280, 1920, 3840,
]);

/**
 * List covers only. Widths above 500, including 960, 1280, 1920, and 3840,
 * become 500. 480 becomes 500. Any other non-standard width below 500
 * becomes 330. A listed width of 500 or below stays. Detail keeps the
 * stored gallery URL.
 */
function commonsThumbWidth(width) {
  if (width === 480 || width > COMMONS_THUMB_PX) return COMMONS_THUMB_PX;
  if (WIKIMEDIA_THUMB_STEPS.has(width)) return width;
  return 330;
}
export const NAME_MAX = 80;
export const CITY_MAX = 40;
export const STATE_MAX = 40;
export const DEITY_MAX = 60;
export const ALT_NAME_MAX = 8;
export const ALT_NAME_LENGTH = 80;
export const FIRESTORE_BATCH_LIMIT = 500;
/** Firestore's per-document limit. A full shard must stay under this. */
export const DOCUMENT_BYTE_LIMIT = 1048576;

const INDEX_ID = /^[A-Za-z0-9_-]{1,200}$/;

const LIVING_PHRASES = [
  "living temple",
  "living shrine",
  "living pilgrimage",
  "living monument",
  "living asi",
  "living pooja",
  "living cult",
  "living peetha",
  "daily worship",
  "daily pooja",
  "daily puja",
  "daily darshan",
  "daily aarti",
  "daily observance",
  "six pooja",
  "active ritual",
  "active worship",
  "active jain",
  "worship continues",
  "pooja continues",
  "hr&ce",
  "hrce",
  "devaswom",
  "endowments",
];

const MONUMENT_PHRASES = [
  "not a living",
  "no living",
  "empty sanctum",
  "no installed deity",
  "no installed cult",
  "not a dependable living",
  "rather than a conventional living",
  "rather than a routine living",
  "heritage visit only",
  "monument visit",
  "archaeological site",
  "visitor monument",
  "no regular living",
  "no recurring public aarti",
  "not a typical hr&ce",
  "not a typical darshan",
];

const DENIAL_WORDS = new Set(["no", "not", "without", "never", "unlike"]);
const WORSHIP =
  /\b(?:widely worshipped|darshan time|darshans?|aartis?|artis?|poojas?|pujas?|abhisheks?)\b/g;
const CEASED_AFTER =
  /\b(?:discontinued|ceased|stopped|ended|abandoned|abolished)\b|\bno more\b|\bno longer\b|\bonce worshipped\b|\b(?:was|were)\b(?:\s+\w+){0,4}\s+once\b/;
const QUALIFIER_BEFORE = /\b(once|historic|historical|formerly|former|erstwhile)\b/;
const DENIED_AFTER =
  /\b(?:not|never|no)\b(?:\s+\w+){0,2}\s+(?:allowed|permitted|offered|held|performed|available|conducted)\b/;

export function stateSlug(state) {
  const slug = String(state ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return slug === "" ? "unknown" : slug;
}

export function assertIndexId(id) {
  if (!INDEX_ID.test(String(id ?? ""))) {
    throw new Error(`Temple id "${id}" cannot be used as an index entry key.`);
  }
}

export function shortAddress(raw) {
  const text = String(raw ?? "")
    .trim()
    .replace(/\s+/g, " ");
  if (text.length <= SHORT_ADDRESS_MAX) return text;
  let cut = text.slice(0, SHORT_ADDRESS_MAX);
  const space = cut.lastIndexOf(" ");
  if (space >= 40) cut = cut.slice(0, space);
  return cut.trimEnd().replace(/[,\s]+$/, "");
}

/** Same placeholder domains as state_batch.js. `source.unsplash.com` is exact. */
const PLACEHOLDER_SUFFIX_HOSTS = [
  "picsum.photos",
  "placeholder.com",
  "placehold.co",
  "placehold.it",
  "dummyimage.com",
  "lorempixel.com",
  "loremflickr.com",
  "placekitten.com",
  "fakeimg.pl",
  "placeimg.com",
];

/** Same stock list as state_batch.js. Not applied by Firestore rules. */
const STOCK_HOSTS = [
  "shutterstock.com",
  "istockphoto.com",
  "istock.com",
  "pexels.com",
  "stock.adobe.com",
  "alamy.com",
  "dreamstime.com",
  "123rf.com",
  "depositphotos.com",
  "freepik.com",
];

function placeholder(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return true;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return true;
  const host = parsed.hostname.toLowerCase();
  if (!host) return true;
  if (host === "source.unsplash.com") return true;
  return PLACEHOLDER_SUFFIX_HOSTS.some(
    (known) => host === known || host.endsWith(`.${known}`),
  );
}

function unlicensedStock(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return false;
  const host = parsed.hostname.toLowerCase();
  if (!host) return false;
  if (host.split(".").includes("gettyimages")) return true;
  return STOCK_HOSTS.some((stock) => host === stock || host.endsWith(`.${stock}`));
}

function httpUrl(raw) {
  const trimmed = String(raw ?? "").trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return null;
    return trimmed;
  } catch {
    return null;
  }
}

function knownThumbUrl(raw) {
  const trimmed = httpUrl(raw);
  if (!trimmed || placeholder(trimmed) || unlicensedStock(trimmed) || trimmed.length > COVER_THUMB_MAX) {
    return null;
  }
  return trimmed;
}

function commonsMd5(filename) {
  return createHash("md5").update(filename, "utf8").digest("hex");
}

/** MediaWiki path encoding. Commas stay literal so Dart and JS match. */
function commonsEncode(name) {
  return encodeURIComponent(name).replace(
    /%(3B|40|24|21|2A|28|29|2C|7E|3A)/gi,
    (token) => String.fromCharCode(Number.parseInt(token.slice(1), 16)),
  );
}

/**
 * 500px thumb for a Commons original, or null.
 * `h`/`hh` are the MD5 of the underscored filename. Existing segments must
 * match that digest. An SVG thumb appends `.png`. A TIFF thumb appends
 * `.jpg`. PDF, DjVu, WebM, and OGV stay the full URL.
 */
function commonsThumbName(decoded, encoded) {
  const lower = decoded.toLowerCase();
  const width = `${COMMONS_THUMB_PX}px`;
  if (lower.endsWith(".svg")) return `${width}-${encoded}.png`;
  if (lower.endsWith(".tif") || lower.endsWith(".tiff")) return `${width}-${encoded}.jpg`;
  if (/\.(pdf|djvu|webm|ogv)$/i.test(lower)) return null;
  return `${width}-${encoded}`;
}

function commonsOriginal480(trimmed) {
  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch {
    return null;
  }
  if (parsed.hostname.toLowerCase() !== "upload.wikimedia.org") return null;
  const parts = rawUrlPath(trimmed).split("/");
  if (parts.length < 4 || parts[1].toLowerCase() !== "wikipedia" || parts[2].toLowerCase() !== "commons") {
    return null;
  }
  if (parts.includes("thumb")) return null;
  let rawName;
  let givenH = null;
  let givenHh = null;
  if (parts.length === 4) {
    rawName = parts[3];
  } else if (parts.length === 6) {
    givenH = parts[3];
    givenHh = parts[4];
    rawName = parts[5];
  } else {
    return null;
  }
  if (!rawName) return null;
  const decoded = safeDecode(rawName).replace(/ /g, "_");
  if (!decoded || decoded.includes("/") || decoded.includes("\\")) return null;
  const digest = commonsMd5(decoded);
  const h = digest[0];
  const hh = digest.slice(0, 2);
  if (givenH != null && (givenH.toLowerCase() !== h || givenHh.toLowerCase() !== hh)) {
    return null;
  }
  const encoded = commonsEncode(decoded);
  const thumbFile = commonsThumbName(decoded, encoded);
  if (!thumbFile) return null;
  const next = `https://upload.wikimedia.org/wikipedia/commons/thumb/${h}/${hh}/${encoded}/${thumbFile}`;
  if (next.length > COVER_THUMB_MAX) return null;
  return next;
}

/**
 * Wikimedia URL on the thumbnail ladder, or null when [raw] is not a
 * Commons file. An existing `/thumb/` above 500px, including 960, 1280,
 * 1920, and 3840, becomes 500px. 480px becomes 500px. Any other
 * non-standard width below 500 becomes 330px. A listed width of 500 or
 * below stays. An original becomes a 500px thumb.
 */
function wikimedia480(raw) {
  const trimmed = knownThumbUrl(raw);
  if (!trimmed) return null;
  let pathname = trimmed;
  try {
    pathname = decodeURIComponent(new URL(trimmed).pathname);
  } catch {
    return null;
  }
  if (!pathname.includes("/thumb/")) return commonsOriginal480(trimmed);
  return trimmed.replace(/\/(\d+)px-([^/?#]+)/, (full, width, rest) => {
    const parsed = Number(width);
    if (!Number.isFinite(parsed)) return full;
    const next = commonsThumbWidth(parsed);
    if (next === parsed) return full;
    return `/${next}px-${rest}`;
  });
}

function safeDecode(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

/**
 * `temples/{id}/{stem}_480_g{generation}.jpg` for a full-size temple photo.
 * Null when [objectPath] is already a thumb or is not a temple photo.
 * A non-jpg source keeps that extension in the name so a failed card can
 * request the original once (`hero_480_g42_PNG.jpg` → `hero.PNG`).
 * [updatedMillis] is set only when the generation-named thumb is older than
 * the source, so the immutable URL changes.
 */
export function thumbObjectPath(objectPath, generation, { updatedMillis } = {}) {
  const parts = String(objectPath ?? "").split("/");
  if (parts.length !== 3 || parts[0] !== "temples") return null;
  const id = parts[1];
  if (!id || id === "." || id === "..") return null;
  const ext = /^(.*)\.(jpe?g|png|webp)$/i.exec(parts[2]);
  if (!ext || !ext[1] || /_480_g\d+(?:u\d+)?(?:_[A-Za-z0-9]+)?$|[_-]480$/i.test(ext[1])) {
    return null;
  }
  const gen = String(generation ?? "");
  if (!/^\d+$/.test(gen)) return null;
  const sourceExt = ext[2];
  const suffix = sourceExt === "jpg" ? "" : `_${sourceExt}`;
  const bust =
    updatedMillis == null || updatedMillis === "" ? "" : `u${updatedMillis}`;
  return `temples/${id}/${ext[1]}_480_g${gen}${bust}${suffix}.jpg`;
}

function firebaseDownloadHost(host) {
  const lower = String(host ?? "").toLowerCase();
  return lower === "firebasestorage.googleapis.com" || lower.endsWith(".firebasestorage.app");
}

/** Path after the host, before `?` or `#`, still percent-encoded. */
function rawUrlPath(trimmed) {
  const match = /^[a-z][a-z0-9+.-]*:\/\/[^/?#]+([^?#]*)/i.exec(trimmed);
  return match ? match[1] : "";
}

/**
 * Object name on `https://<bucket>.firebasestorage.app`.
 * `/o/<encoded>` is one Storage object (`%2F` stays inside the name).
 * `/o/temples/...` and `/temples/...` are the same object with slashes left in the path.
 */
function firebaseHostObjectPath(rawPath) {
  if (!rawPath) return null;
  const path = rawPath.replace(/\/+$/, "");
  const encoded = /^\/o\/([^/]+)$/i.exec(path);
  if (encoded) {
    const decoded = safeDecode(encoded[1]).replace(/^\/+|\/+$/g, "");
    return decoded || null;
  }
  let body = path.replace(/^\/+/, "");
  if (/^o\//i.test(body)) body = body.slice(2);
  if (!body) return null;
  return body.split("/").map(safeDecode).join("/");
}

/**
 * Firebase or Cloud Storage object named by [raw]. The path is taken from
 * the raw URL so a `%2F` inside the Firebase object name stays one object.
 * Forms: `firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded>`,
 * `https://<bucket>.firebasestorage.app/...`, `gs://<bucket>/<path>`, and
 * `storage.googleapis.com/<bucket>/<path>`.
 * @returns {{ kind: "firebase" | "gcs", bucket: string, objectPath: string } | null}
 */
export function storageObjectFromUrl(raw) {
  const trimmed = String(raw ?? "").trim();
  if (!trimmed) return null;
  if (/^gs:\/\//i.test(trimmed)) {
    const gs = /^gs:\/\/([^/?#]+)\/([^?#]+)/i.exec(trimmed);
    if (!gs) return null;
    const objectPath = gs[2].replace(/\/+$/, "").split("/").map(safeDecode).join("/");
    const bucket = safeDecode(gs[1]);
    if (!bucket || !objectPath) return null;
    return { kind: "gcs", bucket, objectPath };
  }
  if (!httpUrl(trimmed) || !trimmed.toLowerCase().startsWith("https://")) return null;
  const firebase = /^https:\/\/([^/?#]+)\/v0\/b\/([^/?#]+)\/o\/([^?#]+)/i.exec(trimmed);
  if (firebase) {
    if (!firebaseDownloadHost(firebase[1])) return null;
    const objectPath = safeDecode(firebase[3]);
    if (!objectPath) return null;
    return {
      kind: "firebase",
      bucket: safeDecode(firebase[2]),
      objectPath,
    };
  }
  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch {
    return null;
  }
  const host = parsed.hostname.toLowerCase();
  if (host.endsWith(".firebasestorage.app")) {
    const objectPath = firebaseHostObjectPath(rawUrlPath(trimmed));
    if (!objectPath) return null;
    return { kind: "firebase", bucket: host, objectPath };
  }
  const gcs = /^https:\/\/storage\.googleapis\.com\/([^/?#]+)\/([^?#]+)/i.exec(trimmed);
  if (!gcs) return null;
  const objectPath = gcs[2].split("/").map(safeDecode).join("/");
  if (!objectPath) return null;
  return {
    kind: "gcs",
    bucket: safeDecode(gcs[1]),
    objectPath,
  };
}

function publicStorageUrl(located, objectPath) {
  if (located.kind === "gcs") {
    const segments = objectPath.split("/").map(encodeURIComponent).join("/");
    return `https://storage.googleapis.com/${encodeURIComponent(located.bucket)}/${segments}`;
  }
  return (
    "https://firebasestorage.googleapis.com/v0/b/" +
    `${encodeURIComponent(located.bucket)}/o/${encodeURIComponent(objectPath)}?alt=media`
  );
}

/**
 * Full-size object path named by a generation thumb, or by a guessed
 * `{stem}_480.{ext}` sibling. Null when [objectPath] is not one of those.
 */
export function fullObjectPathFromThumb(objectPath) {
  const parts = String(objectPath ?? "").split("/");
  if (parts.length !== 3 || parts[0] !== "temples" || !parts[1]) return null;
  const file = parts[2];
  const match = /_480_g(\d+)(?:u(\d+))?(?:_([A-Za-z0-9]+))?\.jpg$/i.exec(file);
  if (match) {
    const stem = file.slice(0, file.length - match[0].length);
    if (!stem) return null;
    const ext = match[3] || "jpg";
    return `temples/${parts[1]}/${stem}.${ext}`;
  }
  const legacy = /^(.*)_480\.(jpe?g|png|webp)$/i.exec(file);
  if (!legacy || !legacy[1]) return null;
  return `temples/${parts[1]}/${legacy[1]}.${legacy[2]}`;
}

/**
 * Public URL of the original behind a `_480_g` thumb. The thumb's download
 * token is not reused. Storage rules make this as readable as the original.
 * Null when [raw] is not one of our thumbs. Cards call this after an error.
 */
export function fullCoverUrlFromThumb(raw) {
  const located = storageObjectFromUrl(raw);
  if (!located) return null;
  const fullPath = fullObjectPathFromThumb(located.objectPath);
  if (!fullPath) return null;
  return publicStorageUrl(located, fullPath);
}

/**
 * Original file behind a Wikimedia `/thumb/.../NNNpx-` URL.
 * `thumb.wikimedia.org` is rewritten to `upload.wikimedia.org`.
 * Null when [raw] is not a Wikimedia thumb. Cards use this after a
 * thumb URL fails, so the full image is tried before the placeholder.
 */
export function wikimediaOriginalUrl(raw) {
  const trimmed = typeof raw === "string" ? raw.trim() : "";
  const noHash = trimmed.split("#")[0];
  const noQuery = noHash.split("?")[0];
  const match = /^(https:\/\/)([^/]+)(\/.*)$/i.exec(noQuery);
  if (!match) return null;
  let host = match[2].toLowerCase();
  if (host !== "upload.wikimedia.org" && host !== "thumb.wikimedia.org") return null;
  if (host === "thumb.wikimedia.org") host = "upload.wikimedia.org";
  const parts = match[3].split("/");
  if (parts.length < 4 || !/^\d+px-/.test(parts[parts.length - 1])) return null;
  const thumbAt = parts.indexOf("thumb");
  if (thumbAt <= 0 || thumbAt >= parts.length - 2) return null;
  parts.splice(parts.length - 1, 1);
  parts.splice(thumbAt, 1);
  const result = `https://${host}${parts.join("/")}`;
  return result === noQuery ? null : result;
}

function explicitThumb(data, source) {
  const photos = Array.isArray(data?.photos) ? data.photos : [];
  for (const photo of photos) {
    if (!photo || typeof photo !== "object") continue;
    if (typeof photo.url !== "string" || photo.url.trim() !== source) continue;
    const thumb = knownThumbUrl(photo.thumbUrl);
    if (thumb) return thumb;
  }
  return null;
}

function galleryCandidates(data) {
  const images = Array.isArray(data?.images) ? data.images : [];
  const urls = [];
  for (const item of images) {
    if (typeof item !== "string") continue;
    const trimmed = item.trim();
    if (trimmed) urls.push(trimmed);
  }
  if (urls.length > 0) return urls;
  const imageUrl = typeof data?.imageUrl === "string" ? data.imageUrl.trim() : "";
  return imageUrl ? [imageUrl] : [];
}

/** First verified gallery URL, before a 500px rewrite. Matches browse. */
export function firstVerifiedGalleryUrl(data) {
  for (const url of galleryCandidates(data)) {
    if (!httpUrl(url) || placeholder(url) || unlicensedStock(url)) continue;
    return url;
  }
  return null;
}

/**
 * Cover the thumb planner resizes. Same order as [firstVerifiedGalleryUrl].
 * A `gs://` object in that position is kept. Browse still skips `gs://`
 * because a card cannot load it.
 */
export function firstThumbSource(data) {
  for (const url of galleryCandidates(data)) {
    if (storageObjectFromUrl(url)) return url;
    if (!httpUrl(url) || placeholder(url) || unlicensedStock(url)) continue;
    return url;
  }
  return null;
}

/**
 * Browse cover. Same photo as the gallery: first verified `images` URL, or
 * `imageUrl` when `images` is empty.
 *
 * A stored `photos[].thumbUrl` is used as written unless it is a Commons
 * thumb, which is snapped the same way. Widths above 500, including 960,
 * 1280, 1920, and 3840, become 500px. 480px becomes 500px. Any other
 * non-standard width below 500 becomes 330px. A listed width of 500 or
 * below stays. A Commons original
 * `.../commons/<h>/<hh>/<name>` becomes a 500px thumb when `<h>/<hh>` match
 * the MD5 of the underscored filename. An SVG thumb appends `.png`. A TIFF
 * thumb appends `.jpg`. PDF, DjVu, WebM, and OGV stay the full URL.
 * Anything else stays the full URL. Storage siblings are not invented.
 * Result is at most 500 characters. Detail keeps the full gallery URL.
 */
export function coverThumb(data) {
  const source = firstVerifiedGalleryUrl(data);
  if (!source) return null;
  const explicit = explicitThumb(data, source);
  if (explicit) return wikimedia480(explicit) || explicit;
  const wiki = wikimedia480(source);
  if (wiki) return wiki;
  return knownThumbUrl(source);
}

function isHistoricalPrintCaption(credit) {
  const lower = credit.toLowerCase();
  return lower.includes("lithograph") || lower.includes("1847 print");
}

function printYear(credit) {
  const match =
    /\b(1[5-9]\d{2}|20\d{2})\b\s*(?:lithographs?|lithographic|prints?)\b|\b(?:lithographs?|lithographic|prints?)\b(?:\s*[\(,:\-–]|\s+(?:of|from|circa|c\.|ca\.|dated|in)\s+)\s*(1[5-9]\d{2}|20\d{2})\b/i.exec(
      credit,
    );
  const year = match?.[1] ?? match?.[2];
  if (!year) return null;
  const value = Number(year);
  if (!Number.isFinite(value) || value < 1500 || value > 2099) return null;
  return year;
}

/** "Lithograph, 1847" when [url] is a historical print in [photos]. */
export function historicalCoverCaption(photos, url) {
  if (!Array.isArray(photos) || typeof url !== "string" || !url) return null;
  for (const photo of photos) {
    if (!photo || photo.url !== url) continue;
    const credit = text(photo.credit);
    if (!isHistoricalPrintCaption(credit)) return null;
    const year = printYear(credit);
    if (!year) return "Lithograph";
    return `Lithograph, ${year}`;
  }
  return null;
}

/**
 * KAN-145 browse filter. hidden:true or published:false drops the entry.
 * Missing flags stay listed. The client does not apply this yet.
 */
export function entryListed(entry) {
  if (entry?.hidden === true) return false;
  if (entry?.published === false) return false;
  return true;
}

/**
 * `lat` / `lng` for an index entry. Missing numbers and (0, 0) are null.
 * Longitude is always a finite number here (never a string). Whole degrees
 * stay numeric; the Dart writer stores the same magnitude as a double.
 */
export function coordinates(data) {
  const lat = data?.latitude;
  const lng = data?.longitude;
  if (typeof lat !== "number" || typeof lng !== "number") {
    return { lat: null, lng: null };
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return { lat: null, lng: null };
  }
  if (lat === 0 && lng === 0) return { lat: null, lng: null };
  return { lat: storedDouble(lat), lng: storedDouble(lng) };
}

function storedDouble(value) {
  if (Object.is(value, -0)) return 0;
  return value;
}

function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

function clip(value, max) {
  const collapsed = text(value).replace(/\s+/g, " ");
  if (collapsed.length <= max) return collapsed;
  return collapsed.slice(0, max).trimEnd();
}

function normalize(raw) {
  return String(raw ?? "")
    .toLowerCase()
    .replace(/[’‘]/g, "'")
    .replace(/[–—]/g, " ");
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function words(value) {
  const found = [];
  for (const part of String(value).split(/[^a-z0-9.'’-]+/)) {
    const word = part.replace(/^[.'’-]+|[.'’-]+$/g, "");
    if (word) found.push(word);
  }
  return found;
}

function isDigit(ch) {
  const code = ch.charCodeAt(0);
  return code >= 48 && code <= 57;
}

function isWordChar(ch) {
  const code = ch.charCodeAt(0);
  return (code >= 48 && code <= 57) || (code >= 97 && code <= 122);
}

function isDecimalDot(text, index) {
  if (index === 0 || index + 1 >= text.length) return false;
  return isDigit(text[index - 1]) && isDigit(text[index + 1]);
}

function wordImmediatelyBefore(text, dotIndex, word) {
  const start = dotIndex - word.length;
  if (start < 0) return false;
  if (text.slice(start, dotIndex) !== word) return false;
  if (start === 0) return true;
  return !isWordChar(text[start - 1]);
}

function isAbbreviationDot(text, index) {
  if (wordImmediatelyBefore(text, index, "st")) return true;
  const firstOfAd =
    wordImmediatelyBefore(text, index, "a") &&
    index + 2 < text.length &&
    text[index + 1] === "d" &&
    text[index + 2] === ".";
  if (firstOfAd) return true;
  return (
    index >= 2 &&
    text[index - 1] === "d" &&
    text[index - 2] === "." &&
    wordImmediatelyBefore(text, index - 2, "a")
  );
}

const ITEM_VERBS = new Set([
  "is",
  "are",
  "was",
  "were",
  "be",
  "been",
  "has",
  "have",
  "had",
  "do",
  "does",
  "did",
  "held",
  "holds",
  "begins",
  "runs",
  "starts",
]);

function commaContinuesList(text, commaIndex) {
  let i = commaIndex + 1;
  const limit = Math.min(text.length, i + 80);
  let buffer = "";
  for (; i < limit; i += 1) {
    const ch = text[i];
    if (ch === "." && isDecimalDot(text, i)) {
      buffer += ch;
      continue;
    }
    if (ch === "," || ch === "." || ch === "!" || ch === "?" || ch === ";" || ch === "\n") {
      break;
    }
    buffer += ch;
  }
  const list = words(buffer);
  if (list.length === 0) return false;
  if (list[0] === "or") return true;
  if (list[0] === "and" || list[0] === "but") return false;
  let coord = -1;
  for (let n = 0; n < list.length; n += 1) {
    if (list[n] === "or" || list[n] === "and") {
      coord = n;
      break;
    }
  }
  if (coord <= 0 || coord > 3 || coord + 1 >= list.length) return false;
  for (let n = 0; n < coord; n += 1) {
    if (ITEM_VERBS.has(list[n])) return false;
  }
  return true;
}

function isClauseBreak(text, index) {
  const ch = text[index];
  if (ch === ",") return !commaContinuesList(text, index);
  if (ch === "\n" || ch === "!" || ch === "?" || ch === ";") return true;
  if (ch !== ".") return false;
  if (isDecimalDot(text, index) || isAbbreviationDot(text, index)) return false;
  return true;
}

function clauseStart(corpus, index) {
  const floor = Math.max(0, index - 240);
  for (let i = index - 1; i >= floor; i -= 1) {
    if (isClauseBreak(corpus, i)) return i + 1;
  }
  return floor;
}

function clauseEnd(corpus, index) {
  const limit = Math.min(corpus.length, index + 120);
  for (let i = index; i < limit; i += 1) {
    if (isClauseBreak(corpus, i)) return i;
  }
  return limit;
}

const INCIDENTAL_RUIN = new Set([
  "above",
  "around",
  "beside",
  "excavated",
  "excavation",
  "excavations",
  "fort",
  "revealed",
]);

/**
 * True when ruin wording describes this shrine. A fort, an excavation, or a
 * neighbouring site does not make the shrine a monument.
 */
function shrineIsRuin(corpus) {
  const ruinWord = /\b(?:ruined|ruins?)\b/g;
  for (const match of corpus.matchAll(ruinWord)) {
    const before = corpus.slice(clauseStart(corpus, match.index), match.index);
    const after = corpus.slice(
      match.index + match[0].length,
      clauseEnd(corpus, match.index + match[0].length),
    );
    const beforeWords = words(before);
    const afterWords = words(after);
    const tail = beforeWords.length <= 8 ? beforeWords : beforeWords.slice(-8);
    const head = afterWords.length <= 4 ? afterWords : afterWords.slice(0, 4);
    if ([...tail, ...head].some((word) => INCIDENTAL_RUIN.has(word))) continue;
    return true;
  }
  return false;
}

function containsDenial(list) {
  for (let i = 0; i < list.length; i += 1) {
    if (DENIAL_WORDS.has(list[i])) return true;
    if (list[i] === "rather" && list[i + 1] === "than") return true;
  }
  return false;
}

function deniedBefore(before) {
  const list = words(before);
  if (list.length === 0) return false;
  const windowStart = Math.max(0, list.length - 3);
  if (containsDenial(list.slice(windowStart))) return true;
  let conjunct = 0;
  for (let i = 0; i < list.length; i += 1) {
    if (list[i] === "and" || list[i] === "but") conjunct = i + 1;
  }
  if (conjunct >= list.length) return false;
  return containsDenial(list.slice(conjunct));
}

function matchIsAffirmative(corpus, start, end) {
  const before = corpus.slice(clauseStart(corpus, start), start);
  const after = corpus.slice(end, clauseEnd(corpus, end));
  if (deniedBefore(before)) return false;
  const beforeWords = before.trim().split(/\s+/).filter(Boolean);
  const tail = beforeWords.slice(-4).join(" ");
  if (QUALIFIER_BEFORE.test(tail)) return false;
  const afterHead = after.trim().split(/\s+/).filter(Boolean).slice(0, 6).join(" ");
  if (CEASED_AFTER.test(afterHead)) return false;
  if (DENIED_AFTER.test(afterHead)) return false;
  return true;
}

function hasAffirmativePhrase(corpus, phrase) {
  const pattern = new RegExp(
    phrase.split(/\s+/).map(escapeRegExp).join("[\\s-]+"),
    "g",
  );
  for (const match of corpus.matchAll(pattern)) {
    if (matchIsAffirmative(corpus, match.index, match.index + match[0].length)) {
      return true;
    }
  }
  return false;
}

function hasBoundedPhrase(corpus, phrase) {
  return new RegExp(`${escapeRegExp(phrase)}(?![a-z0-9])`).test(corpus);
}

function festivalPujaTitle(corpus, pujaStart) {
  const previous = words(corpus.slice(0, pujaStart));
  if (previous.length === 0) return false;
  const title = previous[previous.length - 1];
  return title === "durga" || title === "kali";
}

function affirmativeWorship(data, corpus) {
  const text = normalize(`${textOf(data, "description")}\n${textOf(data, "timings")}`);
  for (const match of text.matchAll(WORSHIP)) {
    const word = match[0];
    if ((word === "puja" || word === "pujas") && festivalPujaTitle(text, match.index)) {
      continue;
    }
    if (matchIsAffirmative(text, match.index, match.index + word.length)) return true;
  }
  return corpus ? false : false;
}

function textOf(data, key) {
  const value = data?.[key];
  return typeof value === "string" ? value : "";
}

function corpusOf(data) {
  const specialities = Array.isArray(data?.specialities)
    ? data.specialities.join("\n")
    : "";
  return normalize(
    [textOf(data, "description"), textOf(data, "story"), textOf(data, "timings"), specialities].join(
      "\n",
    ),
  );
}

export function traditionOf(data) {
  const deity = textOf(data, "deity").toLowerCase();
  if (/\b(jain|tirthankaras?)\b/.test(deity)) return "jain";
  if (/\b(buddha|buddhist)\b/.test(deity)) return "buddhist";
  if (/\b(sikh|gurdwara|gurudwara|guru nanak)\b/.test(deity)) return "sikh";
  const name = textOf(data, "name").toLowerCase();
  if (name.includes("gurdwara") || name.includes("gurudwara")) return "sikh";
  const specialities = Array.isArray(data?.specialities)
    ? data.specialities.join("\n")
    : "";
  const brief = `${textOf(data, "name")}\n${textOf(data, "description")}\n${specialities}`.toLowerCase();
  if (/\bjain (temples?|tirtha|pilgrimage)\b/.test(brief)) return "jain";
  if (/\bbuddhist (temples?|pilgrimage|shrine)\b/.test(brief)) return "buddhist";
  return "unspecified";
}

export function framingOf(data) {
  const corpus = corpusOf(data);
  if (MONUMENT_PHRASES.some((phrase) => hasBoundedPhrase(corpus, phrase))) {
    return "monument";
  }
  const worship =
    LIVING_PHRASES.some((phrase) => hasAffirmativePhrase(corpus, phrase)) ||
    affirmativeWorship(data, corpus);
  const tradition = traditionOf(data);
  // A living shrine is never a monument. Fort ruins and ceased-worship
  // wording in the same story do not override present worship.
  if (worship && tradition === "unspecified") return "living";
  const ceased =
    /\b(?:once|historic|historical|formerly|former|erstwhile|discontinued|ceased|stopped|ended|abandoned|abolished)\b/.test(
      corpus,
    );
  if (!worship && shrineIsRuin(corpus) && ceased) return "monument";
  if (tradition !== "unspecified") return "neutral";
  if (worship) return "living";
  return "neutral";
}

export function indexFlags(data) {
  const framing = framingOf(data);
  return {
    tradition: traditionOf(data),
    living: framing === "living",
    framing,
  };
}

function altNames(data) {
  if (!Object.prototype.hasOwnProperty.call(data, "altNames")) return undefined;
  if (!Array.isArray(data.altNames)) return undefined;
  const names = [];
  for (const item of data.altNames) {
    if (typeof item !== "string") continue;
    const trimmed = item.trim();
    if (!trimmed) continue;
    names.push(clip(trimmed, ALT_NAME_LENGTH));
    if (names.length === ALT_NAME_MAX) break;
  }
  return names.length === 0 ? undefined : names;
}

/**
 * @param {object} data temple document fields, including id
 */
export function entryFromTemple(data) {
  const id = String(data?.id ?? "");
  assertIndexId(id);
  const flags = indexFlags(data);
  const point = coordinates(data);
  const address = shortAddress(
    text(data.address) || text(data.location),
  );
  const source = firstVerifiedGalleryUrl(data);
  const cover = coverThumb(data);
  const caption =
    historicalCoverCaption(data.photos, source) ||
    historicalCoverCaption(data.photos, cover);
  const entry = {
    id,
    slug: id,
    name: clip(data.name, NAME_MAX),
    city: clip(data.city, CITY_MAX),
    state: clip(data.state, STATE_MAX),
    deity: clip(data.deity, DEITY_MAX),
    address,
    coverThumb: cover,
    lat: point.lat,
    lng: point.lng,
    updatedAt: null,
    v: ENTRY_VERSION,
    tradition: flags.tradition,
    living: flags.living,
    framing: flags.framing,
  };
  const names = altNames(data);
  if (names) entry.altNames = names;
  if (Object.prototype.hasOwnProperty.call(data, "published") && typeof data.published === "boolean") {
    entry.published = data.published;
  }
  if (Object.prototype.hasOwnProperty.call(data, "hidden") && typeof data.hidden === "boolean") {
    entry.hidden = data.hidden;
  }
  if (caption) entry.coverCaption = caption;
  return entry;
}

function sameValue(stored, expected) {
  if (stored == null && expected == null) return true;
  if (typeof stored === "number" || typeof expected === "number") {
    return Number(stored) === Number(expected);
  }
  return JSON.stringify(stored) === JSON.stringify(expected);
}

export function changedFields(stored, expected) {
  const keys = new Set([...Object.keys(stored ?? {}), ...Object.keys(expected ?? {})]);
  keys.delete("updatedAt");
  const fields = [];
  for (const key of keys) {
    if (!sameValue(stored?.[key], expected?.[key])) fields.push(key);
  }
  fields.sort();
  return fields;
}

function shardMaps(shards) {
  const out = new Map();
  for (const [shard, value] of Object.entries(shards ?? {})) {
    const entries =
      value && typeof value === "object" && value.entries && !value.id
        ? value.entries
        : value;
    out.set(shard, entries && typeof entries === "object" ? entries : {});
  }
  return out;
}

/**
 * @param {object[]} temples documents with id
 * @param {object} shards stateSlug → entry map, or stateSlug → {entries}
 */
export function diffIndex(temples, shards) {
  const byShard = shardMaps(shards);
  const locations = new Map();
  for (const [shard, entries] of byShard) {
    for (const [id, entry] of Object.entries(entries)) {
      const list = locations.get(id) ?? [];
      list.push({ shard, entry });
      locations.set(id, list);
    }
  }

  const templeIds = new Set();
  const missing = [];
  const drifted = [];
  const moved = [];
  const upserts = [];
  const removals = [];
  let unchanged = 0;

  for (const temple of temples) {
    const id = String(temple.id);
    templeIds.add(id);
    const expected = entryFromTemple(temple);
    const shard = stateSlug(temple.state);
    const found = locations.get(id) ?? [];
    const inPlace = found.find((item) => item.shard === shard);
    for (const other of found) {
      if (other.shard === shard) continue;
      removals.push({ shard: other.shard, id });
      moved.push({ id, from: other.shard, to: shard });
    }
    if (!inPlace) {
      missing.push({ id, shard });
      upserts.push({ shard, id, entry: expected });
      continue;
    }
    const fields = changedFields(inPlace.entry, expected);
    if (fields.length === 0) {
      unchanged += 1;
      continue;
    }
    drifted.push({ id, shard, fields });
    upserts.push({ shard, id, entry: expected });
  }

  const stale = [];
  for (const [id, found] of locations) {
    if (templeIds.has(id)) continue;
    for (const item of found) {
      stale.push({ id, shard: item.shard });
      removals.push({ shard: item.shard, id });
    }
  }

  const counts = shardCounts(temples);
  const capViolations = [...counts.entries()]
    .filter(([, count]) => count > MAX_ENTRIES)
    .map(([shard, count]) => ({ shard, count }));

  return {
    missing,
    drifted,
    moved,
    stale,
    unchanged,
    upserts,
    removals,
    counts,
    capViolations,
  };
}

export function shardCounts(temples) {
  const counts = new Map();
  for (const temple of temples) {
    const shard = stateSlug(temple.state);
    counts.set(shard, (counts.get(shard) ?? 0) + 1);
  }
  return counts;
}

export function assertShardCaps(temples) {
  const over = [...shardCounts(temples).entries()].filter(([, count]) => count > MAX_ENTRIES);
  if (over.length === 0) return;
  const detail = over.map(([shard, count]) => `${shard}=${count}`).join(", ");
  throw new Error(
    `Shard cap ${MAX_ENTRIES} exceeded (${detail}). No write. Split the state before applying.`,
  );
}

function stringBytes(value) {
  return Buffer.byteLength(String(value), "utf8") + 1;
}

/**
 * Upper bound on a `temple_index` shard of [entryCount] max-size entries.
 * Field names, a 200-character id, and the trimmed text caps are included.
 * 400 of those must stay under Firestore's 1 MiB document limit.
 */
export function estimateShardBytes(entryCount = MAX_ENTRIES) {
  const strings = {
    id: 200,
    slug: 200,
    name: NAME_MAX,
    city: CITY_MAX,
    state: STATE_MAX,
    deity: DEITY_MAX,
    address: SHORT_ADDRESS_MAX,
    coverThumb: COVER_THUMB_MAX,
    coverCaption: 16,
    tradition: "unspecified".length,
    framing: "monument".length,
  };
  let entry = 32;
  for (const [name, len] of Object.entries(strings)) {
    entry += stringBytes(name) + len + 1;
  }
  for (const name of ["lat", "lng", "v", "updatedAt"]) {
    entry += stringBytes(name) + 8;
  }
  for (const name of ["living", "published", "hidden"]) {
    entry += stringBytes(name) + 1;
  }
  entry += stringBytes("altNames") + 32;
  for (let i = 0; i < ALT_NAME_MAX; i += 1) entry += ALT_NAME_LENGTH + 1;
  entry += 200 + 1;
  const overhead = stringBytes("temple_index") + stringBytes("x".repeat(80)) + stringBytes("entries") + 32;
  return overhead + entry * entryCount;
}

/**
 * One Firestore batch per state shard for seed_state_batch --apply.
 * Each batch creates the temple docs, one shard doc whose `entries` map is
 * keyed by temple id, and the meta bump. Temple count + 2 stays under
 * [maxOps] (500). A shard over the 400-key cap is refused.
 */
export function planSeedIndexBatches(temples, maxOps = FIRESTORE_BATCH_LIMIT) {
  const byShard = new Map();
  for (const temple of temples) {
    const shard = stateSlug(temple?.state);
    const list = byShard.get(shard) ?? [];
    list.push(temple);
    byShard.set(shard, list);
  }
  const batches = [];
  for (const [shard, list] of byShard) {
    if (list.length > MAX_ENTRIES) {
      throw new Error(
        `Shard ${shard} has ${list.length} temples; max is ${MAX_ENTRIES}. No write.`,
      );
    }
    const ops = list.length + 2;
    if (ops > maxOps) {
      throw new Error(
        `Shard ${shard} needs ${ops} ops; a batch holds at most ${maxOps}. No write.`,
      );
    }
    batches.push({ shard, temples: list, ops });
  }
  return batches;
}

/** True when a fresh shard read still needs this field-path write. */
export function writeNeeded(op, freshEntries) {
  const current = freshEntries?.[op.id];
  if (op.op === "delete") return current != null;
  if (current == null) return true;
  return changedFields(current, op.entry).length > 0;
}

/** One write per shard document per round. Firestore allows one write per doc per batch. */
export function batchRounds(ops) {
  const queues = new Map();
  for (const op of ops) {
    const list = queues.get(op.shard) ?? [];
    list.push(op);
    queues.set(op.shard, list);
  }
  const rounds = [];
  while ([...queues.values()].some((queue) => queue.length > 0)) {
    const round = [];
    for (const queue of queues.values()) {
      if (queue.length > 0) round.push(queue.shift());
    }
    rounds.push(round);
  }
  return rounds;
}

export function planOps(report) {
  const ops = [];
  for (const item of report.removals) {
    ops.push({ op: "delete", shard: item.shard, id: item.id });
  }
  for (const item of report.upserts) {
    ops.push({
      op: "set",
      shard: item.shard,
      id: item.id,
      entry: item.entry,
    });
  }
  return ops;
}
