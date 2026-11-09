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
  updateDoc,
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

test("galleryUrl is an optional https URL capped at 2000 characters", async () => {
  const db = adminDb("admin-gallery-cap");
  await assertSucceeds(setDoc(at(db, "temples/no-gallery"), templePayload("no-gallery")));
  const saved = await getDoc(at(db, "temples/no-gallery"));
  assert.equal(saved.data().photos[0].galleryUrl, undefined);
  const prefix = "https://example.com/";
  const atCap = prefix + "g".repeat(2000 - prefix.length);
  assert.equal(atCap.length, 2000);
  await assertSucceeds(
    setDoc(
      at(db, "temples/gallery-cap"),
      templePayload("gallery-cap", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, galleryUrl: atCap }],
      }),
    ),
  );
  const over = `${atCap}g`;
  await assertFails(
    setDoc(
      at(db, "temples/gallery-over"),
      templePayload("gallery-over", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, galleryUrl: over }],
      }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/gallery-http"),
      templePayload("gallery-http", {
        photos: [
          { url: "https://example.com/full.jpg", licence: "CC0", order: 0, galleryUrl: "http://example.com/g.jpg" },
        ],
      }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/gallery-space"),
      templePayload("gallery-space", {
        photos: [
          {
            url: "https://example.com/full.jpg",
            licence: "CC0",
            order: 0,
            galleryUrl: "https://example.com/a b.jpg",
          },
        ],
      }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/gallery-not-string"),
      templePayload("gallery-not-string", {
        photos: [
          { url: "https://example.com/full.jpg", licence: "CC0", order: 0, galleryUrl: 1080 },
        ],
      }),
    ),
  );
});

test("a photo missing url, licence, or order is rejected", async () => {
  const db = adminDb("admin-photo-required");
  const url = "https://example.com/full.jpg";
  await assertFails(
    setDoc(
      at(db, "temples/missing-url"),
      templePayload("missing-url", { photos: [{ licence: "CC0", order: 0 }] }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/missing-licence"),
      templePayload("missing-licence", { photos: [{ url, order: 0 }] }),
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/missing-order"),
      templePayload("missing-order", { photos: [{ url, licence: "CC0" }] }),
    ),
  );
});

test("photos may store an https galleryUrl beside thumbUrl", async () => {
  const db = adminDb("admin-gallery-url");
  const galleryUrl =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fshore%2F01_1080_g42.jpg?alt=media&token=real";
  const thumb =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fshore%2F01_480_g42.jpg?alt=media&token=real";
  await assertSucceeds(
    setDoc(
      at(db, "temples/with-gallery"),
      templePayload("with-gallery", {
        photos: [{ url: "https://example.com/full.jpg", licence: "CC0", order: 0, thumbUrl: thumb, galleryUrl }],
      }),
    ),
  );
  const saved = await getDoc(at(db, "temples/with-gallery"));
  assert.equal(saved.data().photos[0].galleryUrl, galleryUrl);
  assert.equal(saved.data().photos[0].thumbUrl, thumb);
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
    "https://user@picsum.photos",
    "https://picsum.photos:443",
    "https://user:pass@www.loremflickr.com:443/800/600",
    "https://source.unsplash.com:443",
    "https://user@placekitten.com/800/600",
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
    "https://notpicsum.photos:443/800",
    "https://images.unsplash.com:443/photo-1",
    "https://user@images.unsplash.com/photo-1",
    "https://cdn.source.unsplash.com:443/random",
    "https://www.shutterstock.com/image-photo/temple",
    "https://www.shutterstock.com:443/image-photo/temple",
  ];
  // A fresh doc per URL: photos are client-immutable on update (KAN-200),
  // so each case is a create.
  for (const [i, url] of passes.entries()) {
    await assertSucceeds(
      setDoc(
        at(db, `temples/real-cover-${i}`),
        templePayload(`real-cover-${i}`, {
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

test("a Firebase download-token URL is accepted for imageUrl, images, photos, and thumbUrl", async () => {
  const db = adminDb("admin-token-url");
  const tokenUrl =
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fshore-temple%2F01.jpg?alt=media&token=abc-def";
  const thumbUrl =
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fshore-temple%2F01_480.jpg?alt=media&token=thumb-token";
  await assertSucceeds(
    setDoc(
      at(db, "temples/token-cover"),
      templePayload("token-cover", {
        imageUrl: tokenUrl,
        images: [tokenUrl, "https://example.com/gallery.jpg"],
        photos: [{ url: tokenUrl, credit: "Ada", licence: "CC0", order: 0, thumbUrl }],
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

test("tradition is optional and only jain, buddhist, or sikh", async () => {
  const db = adminDb("admin-tradition");
  await assertSucceeds(
    setDoc(at(db, "temples/no-tradition"), templePayload("no-tradition")),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/stored-tradition"), templePayload("stored-tradition", { tradition: "jain" })),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/stored-tradition"), { tradition: "buddhist" }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/stored-tradition"), { tradition: "sikh" }, { merge: true }),
  );
  await assertFails(
    setDoc(
      at(db, "temples/bad-tradition"),
      templePayload("bad-tradition", { tradition: "hindu" }),
    ),
  );
  await assertFails(
    setDoc(at(db, "temples/stored-tradition"), { tradition: "unspecified" }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, "temples/stored-tradition"), { tradition: null }, { merge: true }),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/stored-tradition"), { tradition: deleteField() }, { merge: true }),
  );
  const saved = await getDoc(at(db, "temples/stored-tradition"));
  assert.equal(saved.data().tradition, undefined);
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

// KAN-197: dress-code and timings research fields are written by the Admin
// SDK (rules bypassed). The app never writes them (Temple.toFirestoreData
// leaves them out), so an admin save is a merge that must keep them, and a
// client write must not add, change, or remove them.
const RESEARCH_FIELDS = {
  dressCode: "Men: dhoti. Women: saree.",
  dressCodeSourceUrl: "https://example.org/dress",
  dressCodeSourceType: "secondary",
  dressCodeVerified: false,
  timingsVerified: false,
  timingsSourceUrl: "https://example.org/timings",
  timingsSourceType: "official",
};

async function seedResearchTemple(id, extra = RESEARCH_FIELDS) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(at(context.firestore(), `temples/${id}`), {
      ...templePayload(id),
      ...extra,
    });
  });
}

test("an admin merge save keeps dress-code and timings research fields", async () => {
  const id = "research-temple";
  await seedResearchTemple(id);
  const db = adminDb("admin-research");
  await assertSucceeds(
    setDoc(
      at(db, `temples/${id}`),
      { ...templePayload(id), story: "Edited story." },
      { merge: true },
    ),
  );
  const saved = (await getDoc(at(db, `temples/${id}`))).data();
  assert.equal(saved.story, "Edited story.");
  for (const [key, value] of Object.entries(RESEARCH_FIELDS)) {
    assert.deepEqual(saved[key], value, key);
  }
});

test("a client write cannot add, change, or delete research fields", async () => {
  const id = "research-locked";
  await seedResearchTemple(id);
  await seedResearchTemple("research-none", {});
  const db = adminDb("admin-research-locked");
  await assertFails(
    setDoc(at(db, `temples/${id}`), { dressCodeVerified: true }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, `temples/${id}`), { dressCode: "Anything." }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, `temples/${id}`), { timingsVerified: true }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, `temples/${id}`), { dressCodeSourceUrl: deleteField() }, { merge: true }),
  );
  await assertFails(
    setDoc(
      at(db, "temples/research-none"),
      { dressCode: "Added by a client." },
      { merge: true },
    ),
  );
  await assertFails(
    setDoc(
      at(db, "temples/research-new"),
      templePayload("research-new", { dressCode: "On create." }),
    ),
  );
  await assertSucceeds(
    setDoc(at(db, "temples/research-none"), { story: "Plain edit." }, { merge: true }),
  );
});

// Shapes seen in prod (Nov 9, 2026): dress-code apply wrote strings,
// official|secondary and bools; #125 wrote timings fields the same way.
const PROD_SHAPED = [
  RESEARCH_FIELDS,
  { ...RESEARCH_FIELDS, dressCodeSourceType: "official", dressCodeVerified: true },
  { timingsVerified: true, timingsSourceUrl: "https://example.org/t", timingsSourceType: "official" },
  { dressCode: "Modest clothing.", dressCodeSourceUrl: "https://example.org/d", dressCodeSourceType: "secondary", dressCodeVerified: false },
  {},
];

test("prod-shaped research docs pass an admin merge save", async () => {
  const db = adminDb("admin-research-types-ok");
  for (const [i, extra] of PROD_SHAPED.entries()) {
    const id = `research-ok-${i}`;
    await seedResearchTemple(id, extra);
    await assertSucceeds(
      setDoc(at(db, `temples/${id}`), { ...templePayload(id), story: `Edit ${i}.` }, { merge: true }),
    );
  }
});

test("a client cannot retype research fields (still immutable)", async () => {
  const id = "research-immutable-types";
  await seedResearchTemple(id);
  const db = adminDb("admin-research-immutable");
  await assertFails(
    setDoc(at(db, `temples/${id}`), { dressCodeVerified: "true" }, { merge: true }),
  );
  await assertFails(
    setDoc(at(db, `temples/${id}`), { dressCodeSourceType: "official" }, { merge: true }),
  );
});

// Budget: a prod-shaped research doc (all 7 research fields, Firebase
// Storage download URLs, credit, thumbUrl and galleryUrl) with 0 or 1 photo
// saves under the 1000-expression limit. Docs with 2 or more photos are
// KAN-200.
function prodShapedPhoto(id, i) {
  const dl = (size) =>
    `https://firebasestorage.googleapis.com/v0/b/app/o/temples%2F${id}%2Fphoto_${i}_${size}.jpg?alt=media&token=00000000-0000-4000-8000-00000000000${i}`;
  return {
    url: dl("full"),
    credit: `Contributor ${i} · CC BY-SA 3.0`,
    licence: "CC-BY-SA",
    order: i,
    thumbUrl: dl("480"),
    galleryUrl: dl("1080"),
  };
}

test("prod-shaped research docs with 0 or 1 photo stay under the expression limit", async () => {
  const db = adminDb("admin-research-budget");
  for (const n of [0, 1]) {
    const id = `research-budget-${n}`;
    const photos = Array.from({ length: n }, (_, i) => prodShapedPhoto(id, i));
    const shaped = {
      photos,
      images: photos.map((p) => p.url),
      imageUrl: photos.length ? photos[0].url : "",
    };
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(at(context.firestore(), `temples/${id}`), {
        ...templePayload(id, shaped),
        ...RESEARCH_FIELDS,
      });
    });
    await assertSucceeds(
      setDoc(at(db, `temples/${id}`), { ...templePayload(id, shaped), story: "Edit." }, { merge: true }),
    );
    await assertSucceeds(
      setDoc(at(db, `temples/${id}`), { description: "Description edit." }, { merge: true }),
    );
  }
});

// ---------------------------------------------------------------------------
// KAN-200: admin saves on temples with 2+ photos crossed the 1000-expression
// limit. Photos, imageUrl and images are client-immutable on update; the
// setTemplePhotos callable (functions/) writes them. Non-photo saves never
// check stored photos.
// ---------------------------------------------------------------------------

const MAX_GALLERY = 12; // kMaxTemplePhotos in lib/models/temple_photo.dart

// Prod-shaped temple (shri-shantadurga-temple-kavlem, 9 photos with thumbUrl
// and galleryUrl, all 7 research fields). Download tokens and contact details
// in credits are replaced.
const KAVLEM = JSON.parse(
  readFileSync(resolve(repoRoot, "scripts/fixtures/kan200_shantadurga_kavlem.json"), "utf8"),
);

async function seedRaw(id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(at(context.firestore(), `temples/${id}`), data);
  });
}

async function readRaw(id) {
  let data;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    data = (await getDoc(at(context.firestore(), `temples/${id}`))).data();
  });
  return data;
}

function kavlemDoc(photoCount = KAVLEM.photos.length) {
  const photos = Array.from({ length: photoCount }, (_, i) =>
    i < KAVLEM.photos.length
      ? { ...KAVLEM.photos[i], order: i }
      : { ...KAVLEM.photos[i % KAVLEM.photos.length], order: i, credit: `Extra ${i} · CC BY-SA 4.0` },
  );
  return {
    ...KAVLEM,
    createdAt: new Date(KAVLEM.createdAt),
    photos,
    images: photos.map((p) => p.url),
    imageUrl: photos.length ? photos[0].url : "",
  };
}

const RESEARCH_KEYS = Object.keys(RESEARCH_FIELDS);

test("Deployer gate: admin description save on the 9-photo Kavlem doc is allowed", async () => {
  const seeded = kavlemDoc();
  assert.equal(seeded.photos.length, 9);
  const id = seeded.id;
  await seedRaw(id, seeded);
  const db = adminDb("admin-uid");
  const keep = Object.fromEntries(RESEARCH_KEYS.map((k) => [k, seeded[k]]));
  await assertSucceeds(
    setDoc(
      at(db, `temples/${id}`),
      { name: seeded.name, description: `${seeded.description} [KAN-200 probe]`, ...keep },
      { merge: true },
    ),
  );
  const saved = await readRaw(id);
  assert.ok(saved.description.endsWith("[KAN-200 probe]"));
  for (const k of RESEARCH_KEYS) assert.deepEqual(saved[k], seeded[k], k);
  assert.deepEqual(saved.photos, seeded.photos);
});

test("non-photo admin saves pass at 0, 1, 2, 9 and max photos, with and without research fields", async () => {
  const db = adminDb("admin-kan200-edit");
  for (const n of [0, 1, 2, 9, MAX_GALLERY]) {
    for (const research of [false, true]) {
      const id = `kan200-edit-${n}-${research ? "r" : "plain"}`;
      const seeded = { ...kavlemDoc(n), id };
      if (!research) for (const k of RESEARCH_KEYS) delete seeded[k];
      await seedRaw(id, seeded);
      // The admin form sends the whole temple back with merge.
      const { createdAt, ...full } = seeded;
      await assertSucceeds(
        setDoc(at(db, `temples/${id}`), { ...full, story: `Story ${n}.` }, { merge: true }),
      );
      // A single-field edit.
      await assertSucceeds(
        setDoc(at(db, `temples/${id}`), { description: `Description ${n}.` }, { merge: true }),
      );
      // updateDoc, as the deploy smoke test does.
      await assertSucceeds(updateDoc(at(db, `temples/${id}`), { address: `Address ${n}` }));
    }
  }
});

test("client photo changes are denied at 0, 1, 2, 9 and max photos, with and without research fields", async () => {
  const db = adminDb("admin-kan200-photos");
  for (const n of [0, 1, 2, 9, MAX_GALLERY]) {
    for (const research of [false, true]) {
      const id = `kan200-photos-${n}-${research ? "r" : "plain"}`;
      const seeded = { ...kavlemDoc(n), id };
      if (!research) for (const k of RESEARCH_KEYS) delete seeded[k];
      const p = seeded.photos;
      const renumber = (list) => list.map((x, i) => ({ ...x, order: i }));
      const extra = { ...KAVLEM.photos[0], order: n, credit: "Added · CC BY-SA 4.0" };
      const variants = {
        add: n < MAX_GALLERY ? [...p, extra] : null,
        "delete last": n > 0 ? p.slice(0, -1) : null,
        "delete first": n > 1 ? renumber(p.slice(1)) : null,
        reorder: n > 1 ? renumber(p.slice().reverse()) : null,
        "cover change": n > 1 ? renumber([p[n - 1], ...p.slice(0, -1)]) : null,
        "credit edit": n > 0 ? p.map((x, i) => (i === 0 ? { ...x, credit: "Edited · CC BY-SA 4.0" } : x)) : null,
        clear: n > 0 ? [] : null,
      };
      await seedRaw(id, seeded);
      for (const [name, photos] of Object.entries(variants)) {
        if (photos === null) continue;
        await assertFails(setDoc(at(db, `temples/${id}`), { photos }, { merge: true }), `${name} ${n}`);
        // Same with a text edit and the mirror alongside.
        await assertFails(
          setDoc(
            at(db, `temples/${id}`),
            { story: "Edit.", photos, images: photos.map((x) => x.url), imageUrl: photos[0]?.url ?? "" },
            { merge: true },
          ),
          `${name} ${n} with text`,
        );
      }
      if (n > 0) {
        await assertFails(setDoc(at(db, `temples/${id}`), { photos: deleteField() }, { merge: true }));
        await assertFails(updateDoc(at(db, `temples/${id}`), { photos: [] }));
      }
      // Resending the stored photos unchanged is a non-photo save.
      await assertSucceeds(
        setDoc(at(db, `temples/${id}`), { story: "Resend.", photos: p }, { merge: true }),
      );
      assert.deepEqual((await readRaw(id)).photos, p);
    }
  }
});

test("client imageUrl and images changes are denied (mirror lock)", async () => {
  const db = adminDb("admin-kan200-mirror");
  for (const n of [0, 1, 2, 9, MAX_GALLERY]) {
    const id = `kan200-mirror-${n}`;
    const seeded = { ...kavlemDoc(n), id };
    await seedRaw(id, seeded);
    await assertFails(
      setDoc(at(db, `temples/${id}`), { imageUrl: "https://example.com/other.jpg" }, { merge: true }),
      `imageUrl ${n}`,
    );
    await assertFails(
      setDoc(at(db, `temples/${id}`), { images: ["https://example.com/other.jpg"] }, { merge: true }),
      `images ${n}`,
    );
    await assertFails(
      setDoc(
        at(db, `temples/${id}`),
        { imageUrl: "https://example.com/other.jpg", images: ["https://example.com/other.jpg"] },
        { merge: true },
      ),
      `both ${n}`,
    );
    if (n > 0) {
      await assertFails(setDoc(at(db, `temples/${id}`), { images: deleteField() }, { merge: true }));
      await assertFails(setDoc(at(db, `temples/${id}`), { imageUrl: deleteField() }, { merge: true }));
    }
    // Resending the stored mirror unchanged is a non-photo save.
    await assertSucceeds(
      setDoc(
        at(db, `temples/${id}`),
        { story: "Mirror ok.", imageUrl: seeded.imageUrl, images: seeded.images, photos: seeded.photos },
        { merge: true },
      ),
    );
  }
});

test("a temple without a photos field cannot gain one from a client", async () => {
  const db = adminDb("admin-kan200-nophotos");
  const { photos, ...legacy } = templePayload("kan200-legacy");
  await seedRaw("kan200-legacy", legacy);
  await assertFails(setDoc(at(db, "temples/kan200-legacy"), { photos: [] }, { merge: true }));
  await assertFails(setDoc(at(db, "temples/kan200-legacy"), { photos }, { merge: true }));
  await assertSucceeds(setDoc(at(db, "temples/kan200-legacy"), { story: "Edit." }, { merge: true }));
});

test("malicious photo writes are still rejected", async () => {
  const db = adminDb("admin-kan200-bad");
  const id = "kan200-bad";
  const base = kavlemDoc(1).photos[0];
  const bad = {
    "http url": { ...base, url: "http://example.com/a.jpg" },
    "whitespace in url": { ...base, url: "https://example.com/a b.jpg" },
    "url too long": { ...base, url: `https://example.com/${"a".repeat(2000)}` },
    "url not a string": { ...base, url: ["https://example.com/a.jpg"] },
    "unknown licence": { ...base, licence: "All rights reserved" },
    "extra key": { ...base, uploader: "someone" },
    "missing order": (({ order, ...rest }) => rest)(base),
    "order 12": { ...base, order: 12 },
    "order -1": { ...base, order: -1 },
    "order float": { ...base, order: 0.5 },
    "order string": { ...base, order: "0" },
    "CC-BY without credit": (({ credit, ...rest }) => ({ ...rest, licence: "CC-BY" }))(base),
    "CC-BY-SA empty credit": { ...base, credit: "" },
    "credit too long": { ...base, credit: "c".repeat(201) },
    "credit not a string": { ...base, credit: 7 },
    "http thumbUrl": { ...base, thumbUrl: "http://example.com/t.jpg" },
    "galleryUrl not a string": { ...base, galleryUrl: 42 },
  };
  for (const [name, photo] of Object.entries(bad)) {
    await seedRaw(id, kavlemDoc(1));
    await assertFails(setDoc(at(db, `temples/${id}`), { photos: [photo] }, { merge: true }), name);
  }
  await seedRaw(id, kavlemDoc(1));
  await assertFails(setDoc(at(db, `temples/${id}`), { photos: ["https://example.com/a.jpg"] }, { merge: true }));
  await assertFails(setDoc(at(db, `temples/${id}`), { photos: { 0: base } }, { merge: true }));
  await assertFails(setDoc(at(db, `temples/${id}`), { photos: "https://example.com/a.jpg" }, { merge: true }));
  const thirteen = Array.from({ length: 13 }, (_, i) => ({ ...base, order: Math.min(i, 11) }));
  await assertFails(setDoc(at(db, `temples/${id}`), { photos: thirteen }, { merge: true }));
  // A bad photo riding along with a text edit is still checked.
  await assertFails(
    setDoc(at(db, `temples/${id}`), { story: "Edit.", photos: [bad["http url"]] }, { merge: true }),
  );
  // A bad photo on a 9-photo doc is rejected.
  const nine = kavlemDoc(9);
  await seedRaw(id, nine);
  const tampered = nine.photos.map((p, i) => (i === 4 ? bad["extra key"] : p));
  await assertFails(setDoc(at(db, `temples/${id}`), { photos: tampered }, { merge: true }));
  // Non-admins still cannot write, with or without photos.
  const anon = testEnv.unauthenticatedContext().firestore();
  const user = testEnv.authenticatedContext("user-1").firestore();
  for (const other of [anon, user]) {
    await assertFails(setDoc(at(other, `temples/${id}`), { description: "x" }, { merge: true }));
  }
  // Photos are client-immutable now; the same bad photos are refused at
  // create (see the parity test) and by the callable validator.
});

test("new temple create still validates photos", async () => {
  const db = adminDb("admin-kan200-create");
  const good = kavlemDoc(1);
  const { createdAt, ...create } = { ...good, id: "kan200-new" };
  for (const k of RESEARCH_KEYS) delete create[k];
  await assertSucceeds(setDoc(at(db, "temples/kan200-new"), create));
  await assertFails(
    setDoc(at(db, "temples/kan200-new-bad"), {
      ...create,
      id: "kan200-new-bad",
      photos: [{ ...create.photos[0], url: "http://example.com/a.jpg" }],
    }),
  );
});

// One set of photo cases for the rules and the callable validator
// (functions/src/photo_validator.js). Create still checks photos in full.
test("create accepts and refuses the same photos as the setTemplePhotos validator", async () => {
  const db = adminDb("admin-kan200-parity");
  const { GOOD_PHOTOS, BAD_PHOTOS } = await import("../functions/test/photo_cases.js");
  const { photoError } = await import("../functions/src/photo_validator.js");
  let i = 0;
  for (const [name, photo] of Object.entries(GOOD_PHOTOS)) {
    assert.equal(photoError(photo), null, `validator: ${name}`);
    const id = `parity-good-${i++}`;
    await assertSucceeds(
      setDoc(at(db, `temples/${id}`), templePayload(id, { photos: [photo], images: [photo.url], imageUrl: photo.url })),
      name,
    );
  }
  for (const [name, photo] of Object.entries(BAD_PHOTOS)) {
    assert.notEqual(photoError(photo), null, `validator: ${name}`);
    const id = `parity-bad-${i++}`;
    if (Array.isArray(photo)) {
      // Firestore cannot store a list inside a list; the SDK refuses it
      // before the rules run.
      await assert.rejects(
        async () => setDoc(at(db, `temples/${id}`), templePayload(id, { photos: [photo] })),
        /Nested arrays are not supported/,
        name,
      );
      continue;
    }
    await assertFails(setDoc(at(db, `temples/${id}`), templePayload(id, { photos: [photo] })), name);
  }
});

// The 12-photo cap itself, not the expression limit: 13 minimal photos are
// refused by `n <= 12` before any photo is checked, so the error is a plain
// rule denial. Without the cap, the same create is refused only by the
// limit, and this test fails.
test("create with 13 photos is refused by the 12-photo cap, not the expression limit", async () => {
  const db = adminDb("admin-kan200-cap");
  const photo = (i) => ({ url: `https://e.co/${i}.jpg`, licence: "CC0", order: Math.min(i, 11) });
  const thirteen = Array.from({ length: 13 }, (_, i) => photo(i));
  let err;
  try {
    await setDoc(at(db, "temples/cap-13"), templePayload("cap-13", { photos: thirteen }));
  } catch (e) {
    err = e;
  }
  assert.ok(err, "13 photos must be refused");
  assert.match(String(err.message), /PERMISSION_DENIED/);
  assert.doesNotMatch(String(err.message), /maximum of 1000 expressions/);
});
