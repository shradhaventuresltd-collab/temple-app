/**
 * KAN-200: the one photo validator for the setTemplePhotos callable.
 *
 * Accepts exactly what firestore.rules accepts for `temples/{id}.photos`
 * (isValidPhoto and validPhotos, rules at 177c729), plus the rules' checks
 * on the `imageUrl` / `images` mirror the callable writes with them:
 *   - photos: a list of at most 12 maps
 *   - keys: url, licence, order required; only url, credit, licence, order,
 *     thumbUrl, galleryUrl allowed
 *   - url, thumbUrl, galleryUrl: strings of at most 2000 characters that
 *     match ^https://[^\s]+$ (RE2 \s: tab, newline, form feed, CR, space)
 *   - licence: CC-BY, CC-BY-SA, CC0, Own, Permission
 *   - order: an integer from 0 to 11
 *   - credit: a string of at most 200 characters, or absent; required and
 *     non-empty for CC-BY and CC-BY-SA
 *   - imageUrl (photos[0].url, or "" with no photos) and images[0] are not
 *     a placeholder host (placeholderHost in the rules)
 *
 * Rules count string size() in characters; this counts code points.
 */

export const MAX_PHOTOS = 12;
export const LICENCES = Object.freeze(["CC-BY", "CC-BY-SA", "CC0", "Own", "Permission"]);
const CREDIT_REQUIRED = new Set(["CC-BY", "CC-BY-SA"]);
const REQUIRED_KEYS = ["url", "licence", "order"];
const ALLOWED_KEYS = new Set(["url", "credit", "licence", "order", "thumbUrl", "galleryUrl"]);
const HTTPS_NO_SPACE = /^https:\/\/[^\t\n\f\r ]+$/;
const PLACEHOLDER_HOST =
  /^https?:\/\/([^/?#@]+@)?(([a-z0-9-]+\.){0,4}(picsum\.photos|placeholder\.com|placehold\.co|placehold\.it|dummyimage\.com|lorempixel\.com|loremflickr\.com|placekitten\.com|fakeimg\.pl|placeimg\.com)|source\.unsplash\.com)(:\d+)?([/?#][\s\S]*)?$/i;

const chars = (s) => [...s].length;

function isPlainMap(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype;
}

function photoUrlError(value, field) {
  if (typeof value !== "string") return `${field} must be a string`;
  if (chars(value) > 2000) return `${field} is over 2000 characters`;
  if (!HTTPS_NO_SPACE.test(value)) return `${field} must be https:// with no whitespace`;
  return null;
}

/** Why [photo] at [index] is refused, or null when the rules accept it. */
export function photoError(photo, index = 0) {
  const at = `photos[${index}]`;
  if (!isPlainMap(photo)) return `${at} must be a map`;
  const keys = Object.keys(photo);
  for (const k of REQUIRED_KEYS) if (!keys.includes(k)) return `${at}.${k} is required`;
  for (const k of keys) if (!ALLOWED_KEYS.has(k)) return `${at}.${k} is not allowed`;
  const urlErr = photoUrlError(photo.url, `${at}.url`);
  if (urlErr) return urlErr;
  if (!LICENCES.includes(photo.licence)) return `${at}.licence is not one of ${LICENCES.join(", ")}`;
  if (!Number.isInteger(photo.order) || photo.order < 0 || photo.order > 11) {
    return `${at}.order must be an integer from 0 to 11`;
  }
  const credit = "credit" in photo ? photo.credit : "";
  if (typeof credit !== "string") return `${at}.credit must be a string`;
  if (chars(credit) > 200) return `${at}.credit is over 200 characters`;
  if (chars(credit) === 0 && CREDIT_REQUIRED.has(photo.licence)) {
    return `${at}.credit is required for ${photo.licence}`;
  }
  if ("thumbUrl" in photo) {
    const e = photoUrlError(photo.thumbUrl, `${at}.thumbUrl`);
    if (e) return e;
  }
  if ("galleryUrl" in photo) {
    const e = photoUrlError(photo.galleryUrl, `${at}.galleryUrl`);
    if (e) return e;
  }
  return null;
}

export function isPlaceholderHost(url) {
  return typeof url === "string" && PLACEHOLDER_HOST.test(url);
}

/** imageUrl and images written with [photos]: cover first, list order kept. */
export function photoMirror(photos) {
  return {
    imageUrl: photos.length ? photos[0].url : "",
    images: photos.map((p) => p.url),
  };
}

/** Why [photos] is refused, or null when the rules accept the list and its mirror. */
export function photosError(photos) {
  if (!Array.isArray(photos)) return "photos must be a list";
  if (photos.length > MAX_PHOTOS) return `photos has ${photos.length} items; at most ${MAX_PHOTOS}`;
  for (let i = 0; i < photos.length; i += 1) {
    const e = photoError(photos[i], i);
    if (e) return e;
  }
  const { imageUrl } = photoMirror(photos);
  if (isPlaceholderHost(imageUrl)) return "the cover photo is on a placeholder host";
  return null;
}
