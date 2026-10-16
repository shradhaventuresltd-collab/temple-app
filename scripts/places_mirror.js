/**
 * Uncredited Google Places mirrors live in the temple-directory-india
 * bucket at `temples/{id}/image_<n>.jpg` (jpeg, png, or webp), including a
 * resized sibling `image_<n>_480_g<generation>.jpg`. The public Storage URL
 * and the Firebase download-token URL name the same object. A matching path
 * in any other bucket is not one of these mirrors.
 */
import { placeholderAuthor } from "./backfill_cover_photos.js";
import { STORAGE_AUTH_BUCKET } from "./storage_auth.js";
import { storageObjectFromUrl } from "./temple_index.js";

const PLACES_FILENAME =
  /^image_\d+(?:_480(?:_g\d+(?:u\d+)?)?(?:_(?:jpe?g|png|webp))?)?\.(?:jpe?g|png|webp)$/i;

function joinedHost(name) {
  return `${name}.com`;
}

const MAPS_HOST = joinedHost("maps.googleapis");
const PLACES_API_HOST = joinedHost("places.googleapis");
const LH3_HOST = joinedHost("lh3.googleusercontent");
const PLACE_PHOTO_PATH = "/maps/api/place/photo";

export function isDirectoryBucket(bucket) {
  return String(bucket ?? "").trim().toLowerCase() === STORAGE_AUTH_BUCKET.toLowerCase();
}

export function isPlacesObjectPath(objectPath) {
  const parts = String(objectPath ?? "").split("/");
  if (parts.length !== 3 || parts[0] !== "temples") return false;
  if (!parts[1] || parts[1] === "." || parts[1] === "..") return false;
  return PLACES_FILENAME.test(parts[2]);
}

/** Firebase or Cloud Storage object when [raw] is a Places mirror in our bucket. */
export function placesObjectFromUrl(raw) {
  const located = storageObjectFromUrl(raw);
  if (!located || !isDirectoryBucket(located.bucket)) return null;
  if (!isPlacesObjectPath(located.objectPath)) return null;
  return located;
}

/**
 * Real photo credit. Empty, "Unknown author", and the other placeholder
 * names used by the cover backfill are not credit.
 */
export function photoHasCredit(photo) {
  const credit = typeof photo?.credit === "string" ? photo.credit.trim() : "";
  return credit !== "" && !placeholderAuthor(credit);
}

export function isPlacesMirrorUrl(raw) {
  return placesObjectFromUrl(raw) !== null;
}

/**
 * A Google-hosted place photo that is not one of our Storage objects.
 * Maps place-photo, Places `/media`, and `lh3` user-content hosts.
 */
export function isGoogleHostedPlacePhoto(raw) {
  let parsed;
  try {
    parsed = new URL(String(raw ?? "").trim());
  } catch {
    return false;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return false;
  const host = parsed.hostname.toLowerCase();
  const path = parsed.pathname.toLowerCase();
  if (host === MAPS_HOST || host.endsWith(`.${MAPS_HOST}`)) {
    return path.includes(PLACE_PHOTO_PATH);
  }
  if (host === PLACES_API_HOST || host.endsWith(`.${PLACES_API_HOST}`)) {
    return path.includes("/media");
  }
  return host === LH3_HOST || host.endsWith(`.${LH3_HOST}`);
}
