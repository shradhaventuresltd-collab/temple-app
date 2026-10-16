/**
 * One marked cover per pack. Two is a validation error, not a choice.
 * `cover_ok` keeps its own message. `cover: true` counts as a mark too,
 * including one `cover` plus a different `cover_ok`. The backfill and the
 * research uploader both call this.
 */
export function assertOneCoverOk(docId, photos) {
  const list = Array.isArray(photos) ? photos : [];
  const flagged = list.filter((photo) => photo?.cover_ok === true);
  if (flagged.length > 1) {
    const names = flagged.map((photo) => photo.filename || "(unnamed)").join(", ");
    throw new Error(`${docId} has ${flagged.length} cover_ok photos (${names}). One cover only.`);
  }
  const marked = list.filter((photo) => photo?.cover === true || photo?.cover_ok === true);
  if (marked.length <= 1) return;
  const names = marked.map((photo) => photo.filename || "(unnamed)").join(", ");
  throw new Error(`${docId} has ${marked.length} cover photos (${names}). One cover only.`);
}
