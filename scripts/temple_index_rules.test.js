/**
 * Firestore emulator rules and index-write tests.
 *
 * Local emulator only. The project id is demo-temple-index, which the
 * emulator refuses to route at production.
 *
 *   npm ci --prefix scripts
 *   scripts/node_modules/.bin/firebase emulators:exec --only firestore --project demo-temple-index "node --test scripts/temple_index_rules.test.js"
 */
import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteField,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  writeBatch,
  FieldPath,
} from "firebase/firestore";

import { entryFromTemple } from "./temple_index.js";

const PROJECT_ID = "demo-temple-index";
const repoRoot = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");

function assertLocalEmulator() {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? "";
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
    throw new Error(
      `Refusing to run without a local Firestore emulator (FIRESTORE_EMULATOR_HOST=${host || "unset"}).`,
    );
  }
  if (!PROJECT_ID.startsWith("demo-")) {
    throw new Error(`Refusing project ${PROJECT_ID}. Emulator tests use a demo- project id.`);
  }
}

let testEnv;

before(async () => {
  assertLocalEmulator();
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(repoRoot, "firestore.rules"), "utf8"),
    },
  });
  assert.equal(testEnv.projectId, PROJECT_ID);
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function adminDb(uid) {
  return testEnv.authenticatedContext(uid, { admin: true }).firestore();
}

function at(db, path) {
  return doc(db, path);
}

test("a shard cannot grow past 400 entry keys", async () => {
  const entries = {};
  for (let i = 0; i < 400; i += 1) entries[`t${i}`] = { id: `t${i}` };
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(at(context.firestore(), "temple_index/cap"), { entries });
  });
  const db = adminDb("admin-cap");
  const ref = at(db, "temple_index/cap");
  await assertSucceeds(
    setDoc(
      ref,
      { entries: { t0: { id: "t0", name: "kept" } } },
      { mergeFields: [new FieldPath("entries", "t0")] },
    ),
  );
  await assertFails(
    setDoc(
      ref,
      { entries: { extra: { id: "extra" } } },
      { mergeFields: [new FieldPath("entries", "extra")] },
    ),
  );
});

test("an update may touch only one entry key", async () => {
  const db = adminDb("admin-one");
  const ref = at(db, "temple_index/one");
  await assertSucceeds(setDoc(ref, { entries: { a: { id: "a" } } }));
  await assertFails(
    setDoc(ref, { entries: { a: { id: "a", name: "A" }, b: { id: "b" } } }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(
      ref,
      { entries: { a: { id: "a", name: "A" } } },
      { mergeFields: [new FieldPath("entries", "a")] },
    ),
  );
  const stored = await getDoc(ref);
  assert.deepEqual(Object.keys(stored.data().entries).sort(), ["a"]);
  assert.equal(stored.data().entries.a.name, "A");
});

test("meta indexVersion increases by exactly 1", async () => {
  const db = adminDb("admin-meta");
  const ref = at(db, "meta/temple_index");
  await assertFails(setDoc(ref, { indexVersion: 2, shards: { bihar: 1 } }));
  await assertSucceeds(setDoc(ref, { indexVersion: 1, shards: { bihar: 1 } }));
  await assertFails(
    setDoc(ref, { indexVersion: increment(2), shards: { bihar: 2 } }, { merge: true }),
  );
  await assertFails(setDoc(ref, { indexVersion: 3, shards: { bihar: 3 } }, { merge: true }));
  await assertSucceeds(
    setDoc(
      ref,
      { indexVersion: 2, shards: { bihar: 2 } },
      { mergeFields: ["indexVersion", new FieldPath("shards", "bihar")] },
    ),
  );
  await assertSucceeds(
    setDoc(ref, { indexVersion: increment(1), shards: { bihar: 3 } }, { merge: true }),
  );
  const stored = await getDoc(ref);
  assert.equal(stored.data().indexVersion, 3);
});

test("non-admins cannot write the index or meta", async () => {
  const admin = adminDb("admin-deny");
  await assertSucceeds(
    setDoc(at(admin, "temple_index/goa"), { entries: { a: { id: "a" } } }),
  );
  await assertSucceeds(
    setDoc(at(admin, "meta/temple_index"), { indexVersion: 1, shards: { goa: 1 } }),
  );
  const anon = testEnv.unauthenticatedContext().firestore();
  const member = testEnv.authenticatedContext("member", { admin: false }).firestore();
  await assertSucceeds(getDoc(at(anon, "temple_index/goa")));
  await assertSucceeds(getDoc(at(member, "meta/temple_index")));
  await assertFails(setDoc(at(anon, "temple_index/goa"), { entries: { b: { id: "b" } } }));
  await assertFails(
    setDoc(
      at(member, "temple_index/goa"),
      { entries: { a: { id: "a", name: "nope" } } },
      { mergeFields: [new FieldPath("entries", "a")] },
    ),
  );
  await assertFails(
    setDoc(at(anon, "meta/temple_index"), { indexVersion: 2, shards: { goa: 2 } }),
  );
  await assertFails(
    setDoc(
      at(member, "meta/temple_index"),
      { indexVersion: increment(1), shards: { goa: 2 } },
      { mergeFields: ["indexVersion", new FieldPath("shards", "goa")] },
    ),
  );
  const anonBatch = writeBatch(anon);
  anonBatch.delete(at(anon, "temple_index/goa"));
  await assertFails(anonBatch.commit());
  const memberBatch = writeBatch(member);
  memberBatch.delete(at(member, "meta/temple_index"));
  await assertFails(memberBatch.commit());
});

function templePayload(id, overrides = {}) {
  return {
    id,
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    imageUrl:
      "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fshore%2Fcover_480.jpg?alt=media",
    description: "Pallava sea-shore shrine.",
    story: "Built by Rajasimha.",
    address: "Mahabalipuram, Tamil Nadu",
    timings: "6:00 AM – 6:00 PM",
    specialities: ["UNESCO"],
    images: ["https://example.com/gallery.jpg"],
    photos: [
      {
        url: "https://example.com/full.jpg",
        licence: "CC0",
        order: 0,
      },
    ],
    latitude: 12.616,
    longitude: 80.199,
    ...overrides,
  };
}

function withoutUpdatedAt(entry) {
  const copy = { ...entry };
  delete copy.updatedAt;
  return copy;
}

function stateSlug(state) {
  const value = String(state ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return value === "" ? "unknown" : value;
}

async function commitTemple(db, { id, data, isNew, previous, deleteTemple = false }) {
  const next = deleteTemple ? null : data;
  const merged = next == null ? null : { ...previous, ...next };
  const entry = merged == null ? null : entryFromTemple({ ...merged, id });
  const shard = merged == null ? null : stateSlug(merged.state);
  const previousShard = previous == null ? null : stateSlug(previous.state);
  const removeShard =
    previousShard && previousShard !== shard
      ? previousShard
      : deleteTemple
        ? previousShard
        : null;
  const batch = writeBatch(db);
  const templeRef = at(db, `temples/${id}`);
  if (deleteTemple) {
    batch.delete(templeRef);
  } else if (isNew) {
    batch.set(templeRef, { ...data, createdAt: serverTimestamp() });
  } else {
    batch.set(templeRef, data, { merge: true });
  }
  if (shard && entry) {
    entry.updatedAt = serverTimestamp();
    batch.set(
      at(db, `temple_index/${shard}`),
      { entries: { [id]: entry } },
      { mergeFields: [new FieldPath("entries", id)] },
    );
  }
  if (removeShard) {
    batch.update(
      at(db, `temple_index/${removeShard}`),
      new FieldPath("entries", id),
      deleteField(),
    );
  }
  const metaShards = [shard, removeShard].filter(Boolean);
  if (metaShards.length > 0) {
    const metaRef = at(db, "meta/temple_index");
    const metaSnap = await getDoc(metaRef);
    if (metaSnap.exists()) {
      // Field paths only. Resending the whole shards map would rewrite
      // sibling timestamps. increment under mergeFields resets indexVersion.
      const patch = { indexVersion: increment(1) };
      for (const name of metaShards) {
        patch[`shards.${name}`] = serverTimestamp();
      }
      batch.update(metaRef, patch);
    } else {
      const stamps = {};
      for (const name of metaShards) stamps[name] = serverTimestamp();
      batch.set(metaRef, { indexVersion: 1, shards: stamps });
    }
  }
  await batch.commit();
}

test("an admin save without coordinates writes null", async () => {
  const db = adminDb("admin-null-coords");
  const id = "unplaced-temple";
  const payload = templePayload(id, { latitude: null, longitude: null });
  await assertSucceeds(setDoc(at(db, `temples/${id}`), payload));
  const saved = await getDoc(at(db, `temples/${id}`));
  assert.equal(saved.data().latitude, null);
  assert.equal(saved.data().longitude, null);
  await assertFails(
    setDoc(at(db, "temples/bad-lat"), templePayload("bad-lat", { latitude: "north" })),
  );
});

test("httpsUrl rejects a photo url that contains whitespace", async () => {
  const db = adminDb("admin-url");
  const spaced = templePayload("spaced-url", {
    photos: [{ url: "https://example.com/a b.jpg", licence: "CC0", order: 0 }],
  });
  await assertFails(setDoc(at(db, "temples/spaced-url"), spaced));
  await assertSucceeds(setDoc(at(db, "temples/plain-url"), templePayload("plain-url")));
});

test("create, update, state move, and delete keep the entry and meta", async () => {
  const id = "shore-temple";
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(at(context.firestore(), "temple_index/tamil-nadu"), {
      entries: { "other-temple": { id: "other-temple", name: "Other" } },
    });
  });
  const db = adminDb("admin-flow");

  const created = templePayload(id);
  await commitTemple(db, { id, data: created, isNew: true });
  let shard = await getDoc(at(db, "temple_index/tamil-nadu"));
  let entries = shard.data().entries;
  assert.equal(entries["other-temple"].name, "Other");
  assert.deepEqual(withoutUpdatedAt(entries[id]), withoutUpdatedAt(entryFromTemple(created)));
  // Browse uses the first verified gallery image, not imageUrl, when images[] is set.
  assert.equal(entries[id].coverThumb, "https://example.com/gallery.jpg");
  assert.equal(Object.hasOwn(entries[id], "description"), false);
  assert.equal(Object.hasOwn(entries[id], "photos"), false);
  assert.ok(entries[id].updatedAt);
  let meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 1);
  assert.ok(meta.data().shards["tamil-nadu"]);

  const updated = templePayload(id, {
    city: "Mamallapuram",
    address: "Mamallapuram, Tamil Nadu",
  });
  await commitTemple(db, { id, data: updated, isNew: false, previous: created });
  shard = await getDoc(at(db, "temple_index/tamil-nadu"));
  entries = shard.data().entries;
  assert.equal(entries[id].city, "Mamallapuram");
  assert.equal(entries["other-temple"].name, "Other");
  assert.deepEqual(withoutUpdatedAt(entries[id]), withoutUpdatedAt(entryFromTemple(updated)));
  meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 2);

  const moved = templePayload(id, {
    state: "Kerala",
    city: "Kochi",
    address: "Kochi, Kerala",
  });
  await commitTemple(db, { id, data: moved, isNew: false, previous: updated });
  const oldShard = await getDoc(at(db, "temple_index/tamil-nadu"));
  const newShard = await getDoc(at(db, "temple_index/kerala"));
  assert.equal(oldShard.data().entries["other-temple"].name, "Other");
  assert.equal(oldShard.data().entries[id], undefined);
  assert.equal(newShard.data().entries[id].state, "Kerala");
  assert.equal(newShard.data().entries[id].city, "Kochi");
  assert.deepEqual(
    withoutUpdatedAt(newShard.data().entries[id]),
    withoutUpdatedAt(entryFromTemple(moved)),
  );
  meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 3);
  assert.ok(meta.data().shards["tamil-nadu"]);
  assert.ok(meta.data().shards.kerala);

  await commitTemple(db, { id, deleteTemple: true, previous: moved });
  const temple = await getDoc(at(db, `temples/${id}`));
  const afterDelete = await getDoc(at(db, "temple_index/kerala"));
  assert.equal(temple.exists(), false);
  assert.equal(afterDelete.data().entries[id], undefined);
  meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 4);
});

test("a batch against an existing meta doc increments and keeps sibling shards", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(at(context.firestore(), "meta/temple_index"), {
      indexVersion: 2,
      shards: { bihar: new Date("2020-01-01T00:00:00Z") },
    });
  });
  const db = adminDb("admin-existing-meta");
  const id = "shore-temple";
  const created = templePayload(id, { longitude: 80 });
  await commitTemple(db, { id, data: created, isNew: true });
  let meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 3);
  assert.ok(meta.data().shards.bihar);
  assert.ok(meta.data().shards["tamil-nadu"]);
  const stored = await getDoc(at(db, "temple_index/tamil-nadu"));
  assert.equal(stored.data().entries[id].lng, 80);
  assert.equal(typeof stored.data().entries[id].lng, "number");

  const updated = templePayload(id, { city: "Mamallapuram", longitude: 80 });
  await commitTemple(db, { id, data: updated, isNew: false, previous: created });
  meta = await getDoc(at(db, "meta/temple_index"));
  assert.equal(meta.data().indexVersion, 4);
  assert.ok(meta.data().shards.bihar);
  assert.ok(meta.data().shards["tamil-nadu"]);
});
