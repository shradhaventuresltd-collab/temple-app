/**
 * Uncredited Google Places mirrors live at
 * `temples/{id}/image_<n>.jpg` (jpeg, png, or webp), including a resized
 * sibling `image_<n>_480_g<generation>.jpg`. Public Storage URLs and
 * Firebase download-token URLs name the same object.
 */
import { storageObjectFromUrl } from "./temple_index.js";

const PLACES_FILENAME =
  /^image_\d+(?:_480(?:_g\d+(?:u\d+)?)?(?:_(?:jpe?g|png|webp))?)?\.(?:jpe?g|png|webp)$/i;

export function isPlacesObjectPath(objectPath) {
  const parts = String(objectPath ?? "").split("/");
  if (parts.length !== 3 || parts[0] !== "temples") return false;
  if (!parts[1] || parts[1] === "." || parts[1] === "..") return false;
  return PLACES_FILENAME.test(parts[2]);
}

/** Firebase or Cloud Storage object when [raw] is a Places mirror or its thumb. */
export function placesObjectFromUrl(raw) {
  const located = storageObjectFromUrl(raw);
  if (!located || !isPlacesObjectPath(located.objectPath)) return null;
  return located;
}

export function isPlacesMirrorUrl(raw) {
  return placesObjectFromUrl(raw) !== null;
}
