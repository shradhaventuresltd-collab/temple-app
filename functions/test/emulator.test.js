/**
 * setTemplePhotos through the Functions emulator, on the 9-photo Kavlem
 * fixture. Local emulators only (demo- project).
 *
 *   cd functions && npm ci
 *   ../scripts/node_modules/.bin/firebase emulators:exec --only functions,firestore \
 *     --project demo-temple-index "node --test functions/test/emulator.test.js"
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { before, test } from "node:test";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { prodPhoto } from "./photo_cases.js";

const PROJECT = "demo-temple-index";
const fsHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const fnHost = process.env.FUNCTIONS_EMULATOR_HOST ?? "127.0.0.1:5001";
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(fsHost)) throw new Error(`Need a local Firestore emulator, got "${fsHost}"`);
const fnBase = fnHost.startsWith("http") ? fnHost : `http://${fnHost}`;
const URL_ = `${fnBase}/${PROJECT}/asia-south1/setTemplePhotos`;

const fixture = JSON.parse(
  readFileSync(new URL("../../scripts/fixtures/kan200_shantadurga_kavlem.json", import.meta.url), "utf8"),
);
const ID = fixture.id;

initializeApp({ projectId: PROJECT });
const db = getFirestore();

// Unsigned ID token, as the emulators accept (never valid in prod).
function token(claims) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  return `${b64({ alg: "none", typ: "JWT" })}.${b64({
    iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, iat: now, exp: now + 3600,
    auth_time: now, sub: claims.sub ?? "admin", user_id: claims.sub ?? "admin", ...claims,
  })}.`;
}

async function call(data, claims = { admin: true }) {
  const headers = { "content-type": "application/json" };
  if (claims) headers.authorization = `Bearer ${token(claims)}`;
  const res = await fetch(URL_, { method: "POST", headers, body: JSON.stringify({ data }), signal: AbortSignal.timeout(20000) });
  const body = await res.json();
  return { status: res.status, body };
}

async function stored() {
  return (await db.doc(`temples/${ID}`).get()).data();
}

before(async () => {
  await db.doc(`temples/${ID}`).set({ ...fixture, createdAt: new Date(fixture.createdAt) });
});

test("admin add, reorder, cover change and delete on the 9-photo Kavlem doc", async () => {
  const start = await stored();
  assert.equal(start.photos.length, 9);

  // Add a 10th photo.
  const added = [...start.photos, prodPhoto(ID, 9)];
  let r = await call({ templeId: ID, photos: added });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  let doc = await stored();
  assert.equal(doc.photos.length, 10);
  assert.deepEqual(doc.images, added.map((p) => p.url));

  // Fill to 12.
  const twelve = [...added, prodPhoto(ID, 10), prodPhoto(ID, 11)];
  r = await call({ templeId: ID, photos: twelve });
  assert.equal(r.status, 200, JSON.stringify(r.body));

  // Reorder: reverse all 12 and renumber.
  const reordered = twelve.slice().reverse().map((p, i) => ({ ...p, order: i }));
  r = await call({ templeId: ID, photos: reordered });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  doc = await stored();
  assert.equal(doc.imageUrl, reordered[0].url, "cover follows order 0");
  assert.deepEqual(doc.photos.map((p) => p.url), reordered.map((p) => p.url));

  // Cover change: move photo 5 to the front.
  const cover = [reordered[5], ...reordered.filter((_, i) => i !== 5)].map((p, i) => ({ ...p, order: i }));
  r = await call({ templeId: ID, photos: cover });
  assert.equal(r.status, 200);
  assert.equal((await stored()).imageUrl, reordered[5].url);

  // Delete down to 2, then to none.
  r = await call({ templeId: ID, photos: cover.slice(0, 2) });
  assert.equal(r.status, 200);
  assert.equal((await stored()).photos.length, 2);
  r = await call({ templeId: ID, photos: [] });
  assert.equal(r.status, 200);
  doc = await stored();
  assert.deepEqual([doc.photos, doc.imageUrl, doc.images], [[], "", []]);

  // Text fields and research fields are untouched.
  for (const k of ["name", "description", "story", "dressCode", "dressCodeVerified", "timingsVerified"]) {
    assert.deepEqual(doc[k], fixture[k], k);
  }
});

test("bad photos, non-admins and missing temples are refused through the emulator", async () => {
  await db.doc(`temples/${ID}`).set({ ...fixture, createdAt: new Date(fixture.createdAt) });
  const before = await stored();
  const bad = { ...before.photos[0], licence: "All rights reserved" };
  let r = await call({ templeId: ID, photos: [bad] });
  assert.equal(r.status, 400);
  assert.equal(r.body.error.status, "INVALID_ARGUMENT");
  r = await call({ templeId: ID, photos: [] }, { admin: false, sub: "user-1" });
  assert.equal(r.status, 403);
  r = await call({ templeId: ID, photos: [] }, null);
  assert.equal(r.status, 401);
  r = await call({ templeId: "no-such-temple", photos: [] });
  assert.equal(r.status, 404);
  assert.deepEqual(await stored(), before);
});

test("1 photo + 4 images: photo changes refused until photos cover all URLs", async () => {
  const id = "brihadeeswarar-temple-emu";
  const cover = prodPhoto(id, 0);
  const images = [
    cover.url,
    "https://firebasestorage.googleapis.com/v0/b/app/o/extra1.jpg",
    "https://firebasestorage.googleapis.com/v0/b/app/o/extra2.jpg",
    "https://firebasestorage.googleapis.com/v0/b/app/o/extra3.jpg",
  ];
  await db.doc(`temples/${id}`).set({
    id, name: "Brihadeeswarar", photos: [cover], imageUrl: cover.url, images,
    description: "d", story: "s",
  });

  for (const [name, photos] of [
    ["add", [cover, prodPhoto(id, 1)]],
    ["delete", []],
    ["reorder/cover", [{ ...prodPhoto(id, 0), url: images[1], order: 0 }]],
  ]) {
    const r = await call({ templeId: id, photos });
    assert.equal(r.status, 400, name);
    assert.equal(r.body.error.status, "FAILED_PRECONDITION", name);
    assert.match(r.body.error.message, /Add licences for the existing photos/, name);
    const doc = (await db.doc(`temples/${id}`).get()).data();
    assert.deepEqual(doc.images, images, name);
    assert.equal(doc.photos.length, 1, name);
  }

  const covered = images.map((url, i) => ({
    ...prodPhoto(id, Math.min(i, 11)),
    url,
    order: i,
    credit: `Licensed ${i}`,
  }));
  const ok = await call({ templeId: id, photos: covered });
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  const after = (await db.doc(`temples/${id}`).get()).data();
  assert.deepEqual(after.images, images);
  assert.equal(after.photos.length, 4);
});
