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

test("latitude and longitude are both null or both set", async () => {
  const db = adminDb("admin-coord-pair");
  await assertSucceeds(
    setDoc(at(db, "temples/both-null"), templePayload("both-null", { latitude: null, longitude: null })),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/both-set"), templePayload("both-set", { latitude: 0, longitude: 0 })),
  );
  await assertFails(
    setDoc(
      at(db, "temples/lat-only"),
      templePayload("lat-only", { latitude: 12.6, longitude: null }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/lng-only"),
      templePayload("lng-only", { latitude: null, longitude: 80 }),
    ),
  );

  await assertSucceeds(
    setDoc(at(db, "temples/paired"), templePayload("paired", { latitude: 12.6, longitude: 80 })),
  );
  await assertFails(
    setDoc(at(db, "temples/paired"), { latitude: null }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, "temples/paired"), { longitude: null }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/paired"), { latitude: null, longitude: null }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/paired"), { city: "Mamallapuram" }, { merge: true }),
  );
  const saved = await getDoc(at(db, "temples/paired"));
  assert.equal(saved.data().latitude, null);
  assert.equal(saved.data().longitude, null);
  assert.equal(saved.data().city, "Mamallapuram");
});

test("an update that does not touch coordinates leaves an unpaired doc writable", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      at(context.firestore(), "temples/legacy-unpaired"),
      templePayload("legacy-unpaired", { latitude: 12.6, longitude: null }),
    );
  });
  const db = adminDb("admin-legacy-coords");
  await assertSucceeds(
    setDoc(at(db, "temples/legacy-unpaired"), { city: "Mamallapuram" }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, "temples/legacy-unpaired"), { latitude: 13 }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(
      at(db, "temples/legacy-unpaired"),
      { latitude: null, longitude: null },
      { merge: true },
    ),
  );
  const saved = await getDoc(at(db, "temples/legacy-unpaired"));
  assert.equal(saved.data().latitude, null);
  assert.equal(saved.data().longitude, null);
  assert.equal(saved.data().city, "Mamallapuram");
});

test("thumbUrl is an optional https URL capped at 2000 characters", async () => {
  const db = adminDb("admin-thumb-cap");
  await assertSucceeds(setDoc(at(db, "temples/no-thumb"), templePayload("no-thumb")));
  const saved = await getDoc(at(db, "temples/no-thumb"));
  assert.equal(saved.data().photos[0].thumbUrl, undefined);
  const prefix = "https://example.com/";
  const atCap = prefix + "a".repeat(2000 - prefix.length);
  assert.equal(atCap.length, 2000);
  await assertSucceeds(
    setDoc(
      at(db, "temples/thumb-cap"),
      templePayload("thumb-cap", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, thumbUrl: atCap }],
      }),
    ),
  );
  const over = `${atCap}a`;
  await assertFails(
    setDoc(
      at(db, "temples/thumb-over"),
      templePayload("thumb-over", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, thumbUrl: over }],
      }),
    ),
  );
});

test("photos may store an https thumbUrl", async () => {
  const db = adminDb("admin-thumb-url");
  const thumb =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fshore%2F01_480_g42.jpg?alt=media&token=real";
  await assertSucceeds(
    setDoc(
      at(db, "temples/with-thumb"),
      templePayload("with-thumb", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, thumbUrl: thumb }],
      }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/bad-thumb"),
      templePayload("bad-thumb", {
        photos: [
          { url: "https://example.com/full.jpg", licence: "CC0", order: 0, thumbUrl: "http://example.com/t.jpg" },
        ],
      }),
    ),
  );
});

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

test("placeholder hosts and their subdomains fail on imageUrl and images[0], and extra photo keys fail", async () => {
  const db = adminDb("admin-placeholder-hosts");
  const hosts = [
    "https://picsum.photos/seed/a/800/600",
    "https://placeholder.com/800",
    "https://via.placeholder.com/800",
    "https://placehold.co/800x600",
    "https://placehold.it/800",
    "https://dummyimage.com/800x600",
    "https://lorempixel.com/800/600",
    "https://source.unsplash.com/random",
    "https://fastly.picsum.photos/id/1/800/600",
    "https://i.picsum.photos/id/1/800/600",
    "https://loremflickr.com/800/600",
    "https://www.loremflickr.com/800/600",
    "https://placekitten.com/800/600",
    "https://www.placekitten.com/800/600",
    "https://fakeimg.pl/800",
    "https://cdn.fakeimg.pl/800",
    "https://placeimg.com/800/600",
    "https://img.placeimg.com/800/600",
  ];
  for (const url of hosts) {
    await assertFails(
      setDoc(at(db, "temples/bad-cover"), templePayload("bad-cover", { imageUrl: url })),
    );
    await assertFails(
      setDoc(at(db, "temples/bad-images"), templePayload("bad-images", { images: [url, "https://example.com/real.jpg"] })),
    );
  }
  const passes = [
    "https://upload.wikimedia.org/wikipedia/commons/x/xx/Placeholder_temple.jpg",
    "https://storage.googleapis.com/bucket/temples/placeholder-x.jpg",
    "https://images.unsplash.com/photo-1",
    "https://cdn.source.unsplash.com/random",
    "https://notpicsum.photos/800",
    "https://www.shutterstock.com/image-photo/temple",
  ];
  for (const url of passes) {
    await assertSucceeds(
      setDoc(
        at(db, "temples/real-cover"),
        templePayload("real-cover", {
          imageUrl: url,
          images: [url],
          photos: [{ url, licence: "CC0", order: 0 }],
        }),
      ),
    );
  }
  await assertSucceeds(
    setDoc(
      at(db, "temples/later-placeholder"),
      templePayload("later-placeholder", {
        imageUrl: "https://example.com/cover.jpg",
        images: ["https://example.com/cover.jpg", "https://picsum.photos/seed/a/800/600"],
      }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/foo-bar"),
      templePayload("foo-bar", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, foo: 1, bar: 2 }],
      }),
    ),
  );
});

test("a Commons file named with Unsplash passes the photo key checks", async () => {
  const db = adminDb("admin-unsplash-name");
  const unsplashName =
    "https://upload.wikimedia.org/wikipedia/commons/f/fe/Temple_Unsplash_view.jpg";
  await assertSucceeds(
    setDoc(
      at(db, "temples/unsplash-name"),
      templePayload("unsplash-name", {
        imageUrl: unsplashName,
        images: [unsplashName],
        photos: [{ url: unsplashName, licence: "CC0", order: 0 }],
      }),
    ),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/photo-pending"), templePayload("photo-pending", { imageUrl: "", images: [] })),
  );
  await assertSucceeds(
    setDoc(
      at(db, "temples/commons-cover"),
      templePayload("commons-cover", {
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg",
        images: ["https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg"],
      }),
    ),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/photo-pending"), { city: "Anchuthengu" }, { merge: true }),
  );
  const gallery = Array.from({ length: 8 }, (_, i) => `https://example.com/gallery-${i}.jpg`);
  const photos = [0, 1, 2].map((i) => ({
    url: gallery[i],
    licence: "CC0",
    order: i,
  }));
  await assertSucceeds(
    setDoc(
      at(db, "temples/full-gallery"),
      templePayload("full-gallery", { imageUrl: gallery[0], images: gallery, photos }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/extra-photo-key"),
      templePayload("extra-photo-key", {
        photos: [{
          url: "https://example.com/full.jpg",
          licence: "CC0",
          order: 0,
          credit: "Ada",
          thumbUrl: "https://example.com/t.jpg",
          extra: true,
        }],
      }),
    ),
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
