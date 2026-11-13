/**
 * KAN-200: setTemplePhotos callable handler.
 *
 * Replaces `temples/{templeId}.photos` with the list the admin app sends
 * (add, reorder, delete, cover change) and writes the imageUrl / images
 * mirror in the same transaction. Text fields are not touched; the app
 * saves them directly, and that save also refreshes the temple_index entry.
 */
import { HttpsError } from "firebase-functions/v2/https";
import { photoMirror, photosError, uncoveredLegacyImagesError } from "./photo_validator.js";

// Same charset createTemple can index: assertTempleIndexId / INDEX_ID.
const TEMPLE_ID = /^[A-Za-z0-9_-]{1,200}$/;

/**
 * @param {{ db: () => import("firebase-admin/firestore").Firestore,
 *           enforceAppCheck: () => boolean }} deps
 */
export function makeSetTemplePhotos({ db, enforceAppCheck }) {
  return async function setTemplePhotos(request) {
    if (enforceAppCheck() && !request.app) {
      throw new HttpsError("failed-precondition", "App Check token is required.");
    }
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in as an admin.");
    }
    if (request.auth.token?.admin !== true) {
      throw new HttpsError("permission-denied", "Admin claim (admin: true) is required.");
    }
    const data = request.data ?? {};
    const templeId = data.templeId;
    if (typeof templeId !== "string" || !TEMPLE_ID.test(templeId)) {
      throw new HttpsError("invalid-argument", "templeId must be a temple slug.");
    }
    const keys = Object.keys(data);
    const extra = keys.filter((k) => k !== "templeId" && k !== "photos");
    if (extra.length) {
      throw new HttpsError("invalid-argument", `Unknown fields: ${extra.join(", ")}.`);
    }
    const photos = data.photos;
    const error = photosError(photos);
    if (error) throw new HttpsError("invalid-argument", error);
    // Cover equals the Dart deriveTemplePhotoMirror cover for any caller.
    for (let i = 0; i < photos.length; i += 1) {
      if (photos[i].order !== i) {
        throw new HttpsError(
          "invalid-argument",
          `photos[${i}].order must equal ${i}`,
        );
      }
    }

    const mirror = photoMirror(photos);
    const ref = db().collection("temples").doc(templeId);
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Temple was not found. It may have been deleted.");
      }
      // KAN-200 C6: refuse a photo rewrite that would drop legacy images[]
      // URLs not covered by the new photos[].url list.
      const stored = snap.data() ?? {};
      const legacy = uncoveredLegacyImagesError(stored.images, photos, stored.photos);
      if (legacy) throw new HttpsError("failed-precondition", legacy);
      tx.update(ref, { photos, imageUrl: mirror.imageUrl, images: mirror.images });
    });
    return { templeId, photos, ...mirror };
  };
}
