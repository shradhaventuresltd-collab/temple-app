/**
 * One `cover_ok` photo per pack. Two is a validation error, not a choice.
 * The backfill and the research uploader both call this.
 */
export function assertOneCoverOk(docId, photos) {
  const flagged = (Array.isArray(photos) ? photos : []).filter((photo) => photo?.cover_ok === true);
  if (flagged.length <= 1) return;
  const names = flagged.map((photo) => photo.filename || "(unnamed)").join(", ");
  throw new Error(`${docId} has ${flagged.length} cover_ok photos (${names}). One cover only.`);
}
