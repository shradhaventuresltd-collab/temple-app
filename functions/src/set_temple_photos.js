/**
 * KAN-200: setTemplePhotos callable handler.
 *
 * Replaces `temples/{templeId}.photos` with the list the admin app sends
 * (add, reorder, delete, cover change) and writes the imageUrl / images
 * mirror in the same transaction. Text fields are not touched; the app
 * saves them directly, and that save also refreshes the temple_index entry.
 */
import { HttpsError } from "firebase-functions/v2/https";
import { photoMirror, photosError } from "./photo_validator.js";

const TEMPLE_ID = /^[a-z0-9][a-z0-9-]{0,199}$/;

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

    const mirror = photoMirror(photos);
    const ref = db().collection("temples").doc(templeId);
    await db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Temple was not found. It may have been deleted.");
      }
      tx.update(ref, { photos, imageUrl: mirror.imageUrl, images: mirror.images });
    });
    return { templeId, photos, ...mirror };
  };
}
