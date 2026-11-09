import assert from "node:assert/strict";
import { test } from "node:test";
import { BAD_PHOTOS, prodPhoto } from "./photo_cases.js";
import { makeSetTemplePhotos } from "../src/set_temple_photos.js";

// In-memory Firestore with the calls the handler uses.
function fakeDb(docs = {}) {
  const store = new Map(Object.entries(docs).map(([k, v]) => [k, structuredClone(v)]));
  const writes = [];
  const ref = (id) => ({ id });
  return {
    store,
    writes,
    collection: (name) => {
      assert.equal(name, "temples");
      return { doc: ref };
    },
    runTransaction: async (fn) => {
      const pending = [];
      await fn({
        get: async (r) => ({ exists: store.has(r.id), data: () => store.get(r.id) }),
        update: (r, patch) => pending.push([r.id, patch]),
      });
      for (const [id, patch] of pending) {
        store.set(id, { ...store.get(id), ...patch });
        writes.push([id, patch]);
      }
    },
  };
}

const ADMIN = { uid: "admin", token: { admin: true } };
const APP = { appId: "1:109314154382:android:test" };

function setup({ enforce = false, docs } = {}) {
  const db = fakeDb(docs ?? { kavlem: { id: "kavlem", name: "Kavlem", photos: [prodPhoto("kavlem", 0)] } });
  const call = makeSetTemplePhotos({ db: () => db, enforceAppCheck: () => enforce });
  return { db, call };
}

async function rejects(promise, code) {
  await assert.rejects(promise, (e) => e.code === code || e.httpErrorCode?.canonicalName?.toLowerCase().replace(/_/g, "-") === code, code);
}

test("admin writes 0, 1, 2, 9 and 12 photos with the mirror", async () => {
  for (const n of [0, 1, 2, 9, 12]) {
    const { db, call } = setup();
    const photos = Array.from({ length: n }, (_, i) => prodPhoto("kavlem", i));
    const out = await call({ auth: ADMIN, data: { templeId: "kavlem", photos } });
    const saved = db.store.get("kavlem");
    assert.deepEqual(saved.photos, photos, `${n}`);
    assert.equal(saved.imageUrl, n ? photos[0].url : "");
    assert.deepEqual(saved.images, photos.map((p) => p.url));
    assert.equal(saved.name, "Kavlem", "text fields are not touched");
    assert.deepEqual(out.photos, photos);
    assert.deepEqual(Object.keys(db.writes[0][1]).sort(), ["imageUrl", "images", "photos"]);
  }
});

test("bad licence, URL, order and other refused photos write nothing", async () => {
  for (const [name, bad] of Object.entries(BAD_PHOTOS)) {
    const { db, call } = setup();
    const photos = [prodPhoto("kavlem", 0), bad];
    await rejects(call({ auth: ADMIN, data: { templeId: "kavlem", photos } }), "invalid-argument");
    assert.equal(db.writes.length, 0, name);
  }
});

test("13 photos, a non-list, unknown fields and bad ids are refused", async () => {
  const { db, call } = setup();
  const thirteen = Array.from({ length: 13 }, (_, i) => prodPhoto("kavlem", Math.min(i, 11)));
  await rejects(call({ auth: ADMIN, data: { templeId: "kavlem", photos: thirteen } }), "invalid-argument");
  await rejects(call({ auth: ADMIN, data: { templeId: "kavlem", photos: "x" } }), "invalid-argument");
  await rejects(call({ auth: ADMIN, data: { templeId: "kavlem", photos: [], name: "x" } }), "invalid-argument");
  for (const templeId of [undefined, "", "../meta/temple_index", "a/b", "a.b", 7]) {
    await rejects(call({ auth: ADMIN, data: { templeId, photos: [] } }), "invalid-argument");
  }
  assert.equal(db.writes.length, 0);
});

test("photos[i].order must equal i", async () => {
  const { db, call } = setup();
  const photos = [prodPhoto("kavlem", 0), { ...prodPhoto("kavlem", 1), order: 0 }];
  await rejects(call({ auth: ADMIN, data: { templeId: "kavlem", photos } }), "invalid-argument");
  assert.equal(db.writes.length, 0);
  const ok = [prodPhoto("kavlem", 0), prodPhoto("kavlem", 1)];
  await call({ auth: ADMIN, data: { templeId: "kavlem", photos: ok } });
  assert.equal(db.writes.length, 1);
});

test("uppercase and underscore temple ids match createTemple / INDEX_ID", async () => {
  const { db, call } = setup({
    docs: {
      Kavlem: { id: "Kavlem", name: "Kavlem" },
      shore_temple: { id: "shore_temple", name: "Shore" },
    },
  });
  await call({ auth: ADMIN, data: { templeId: "Kavlem", photos: [] } });
  await call({ auth: ADMIN, data: { templeId: "shore_temple", photos: [] } });
  assert.equal(db.writes.length, 2);
});

test("a missing temple is not created", async () => {
  const { db, call } = setup();
  await rejects(call({ auth: ADMIN, data: { templeId: "nope", photos: [] } }), "not-found");
  assert.equal(db.store.has("nope"), false);
});

test("non-admins are denied", async () => {
  const { db, call } = setup();
  const data = { templeId: "kavlem", photos: [] };
  await rejects(call({ data }), "unauthenticated");
  await rejects(call({ auth: { uid: "u", token: {} }, data }), "permission-denied");
  await rejects(call({ auth: { uid: "u", token: { admin: "true" } }, data }), "permission-denied");
  await rejects(call({ auth: { uid: "u", token: { admin: 1 } }, data }), "permission-denied");
  assert.equal(db.writes.length, 0);
});

test("with enforcement on, a call without App Check is denied, even for an admin", async () => {
  const { db, call } = setup({ enforce: true });
  const data = { templeId: "kavlem", photos: [] };
  await rejects(call({ auth: ADMIN, data }), "failed-precondition");
  assert.equal(db.writes.length, 0);
  await call({ auth: ADMIN, app: APP, data });
  assert.equal(db.writes.length, 1);
});

test("with enforcement off (default), an admin call without App Check works", async () => {
  const { db, call } = setup({ enforce: false });
  await call({ auth: ADMIN, data: { templeId: "kavlem", photos: [] } });
  assert.equal(db.writes.length, 1);
});
