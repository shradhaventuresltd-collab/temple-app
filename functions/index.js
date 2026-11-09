/**
 * Cloud Functions for Temple Directory India.
 *
 * setTemplePhotos (KAN-200): admin-only photo writes in asia-south1, the
 * Firestore region. App Check is enforced when ENFORCE_APP_CHECK is true.
 * It stays false until the app ships firebase_app_check (KAN-200 follow-up:
 * add firebase_app_check, register Play Integrity, debug tokens, then flip).
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { makeSetTemplePhotos } from "./src/set_temple_photos.js";

/** Flip to true, and redeploy, once the app sends App Check tokens. */
export const ENFORCE_APP_CHECK = false;

initializeApp();

export const setTemplePhotos = onCall(
  {
    region: "asia-south1",
    enforceAppCheck: ENFORCE_APP_CHECK,
    maxInstances: 5,
    timeoutSeconds: 30,
  },
  makeSetTemplePhotos({
    db: () => getFirestore(),
    enforceAppCheck: () => ENFORCE_APP_CHECK,
  }),
);
