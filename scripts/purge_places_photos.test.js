import assert from "node:assert/strict";
import { test } from "node:test";

import {
  applyPurgePlans,
  authorizeApply,
  commitPurgePlaces,
  formatPurgeReport,
  main,
  parseArgs,
  persistPurgePlaces,
  placesDeletePlan,
  planPurgePlaces,
  referencedObjectPaths,
  selectTemples,
} from "./purge_places_photos.js";
import { isPlacesMirrorUrl } from "./places_mirror.js";

const bucket = "temple-directory-india.firebasestorage.app";

function publicUrl(id, file) {
  return `https://storage.googleapis.com/${bucket}/temples/${id}/${file}`;
}

function tokenUrl(id, file, token = "secret-token") {
  return (
    "https://firebasestorage.googleapis.com/v0/b/" +
    `${bucket}/o/${encodeURIComponent(`temples/${id}/${file}`)}?alt=media&token=${token}`
  );
}

function temple(id, extra = {}) {
  return {
    id,
    name: id,
    state: "Kerala",
    city: "City",
    deity: "Devi",
    imageUrl: "",
    images: [],
    photos: [],
    ...extra,
  };
}

const pendingIds = [
  "anjengo-sree-durga-devi-temple",
  "meenakshi-amman-temple",
  "shore-temple",
  "mannarsala-sree-nagaraja-temple",
  "sri-manjunatha-temple-dharmasthala",
  "srikanteshwara-temple-nanjangud",
  "chamundeshwari-temple",
  "mahabaleshwar-temple-gokarna",
  "sabarimala-ayyappan-temple",
];

test("public and token Places URLs match, and a pack frame does not", () => {
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_1.jpg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_2.jpeg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_3.png")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_4.webp")), true);
  assert.equal(isPlacesMirrorUrl(tokenUrl("shore-temple", "image_1.jpg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_1_480.jpg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_1_480_g4.jpg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "image_1_480_g4u1700_png.jpg")), true);
  assert.equal(isPlacesMirrorUrl(publicUrl("shore-temple", "01_Shore.jpg")), false);
  assert.equal(isPlacesMirrorUrl("https://upload.wikimedia.org/wikipedia/commons/a/a1/File.jpg"), false);
});

test("dry-run lists Photo pending temples and redacts tokens", () => {
  const places = pendingIds.map((id) =>
    temple(id, {
      imageUrl: tokenUrl(id, "image_1.jpg", `token-${id}`),
      images: [tokenUrl(id, "image_1.jpg", `token-${id}`), publicUrl(id, "image_2.jpg")],
      photos: [
        {
          url: tokenUrl(id, "image_1.jpg", `token-${id}`),
          thumbUrl: publicUrl(id, "image_1_480_g3.jpg"),
          order: 0,
        },
      ],
    }),
  );
  const kept = temple("virupaksha-temple", {
    imageUrl: publicUrl("virupaksha-temple", "02_Hemakuta.jpg"),
    images: [
      publicUrl("virupaksha-temple", "02_Hemakuta.jpg"),
      publicUrl("virupaksha-temple", "image_9.jpg"),
    ],
    photos: [
      {
        url: publicUrl("virupaksha-temple", "02_Hemakuta.jpg"),
        credit: "Ms Sarah Welch",
        licence: "CC BY-SA 4.0",
        order: 0,
      },
    ],
  });
  const creditedPlaces = temple("credited-places-temple", {
    imageUrl: tokenUrl("credited-places-temple", "image_1.jpg"),
    images: [tokenUrl("credited-places-temple", "image_1.jpg")],
    photos: [
      {
        url: publicUrl("credited-places-temple", "image_1.jpg"),
        thumbUrl: publicUrl("credited-places-temple", "image_1_480_g2.jpg"),
        credit: "Ada Lovelace",
        licence: "CC BY 4.0",
        order: 0,
      },
    ],
  });
  const plans = [kept, creditedPlaces, ...places].map((item) => planPurgePlaces(item));
  assert.equal(plans.find((plan) => plan.id === "credited-places-temple").action, "ready");
  const virupaksha = plans.find((plan) => plan.id === "virupaksha-temple");
  assert.equal(virupaksha.action, "purge");
  assert.equal(virupaksha.photoPending, false);
  assert.deepEqual(virupaksha.patch.images, [publicUrl("virupaksha-temple", "02_Hemakuta.jpg")]);
  assert.equal(Object.hasOwn(virupaksha.patch, "imageUrl"), false);
  const shore = plans.find((plan) => plan.id === "shore-temple");
  assert.equal(shore.photoPending, true);
  assert.equal(shore.patch.imageUrl, "");
  assert.deepEqual(shore.patch.images, []);
  assert.deepEqual(shore.patch.photos, []);
  assert.deepEqual(shore.objectPaths, [
    "temples/shore-temple/image_1.jpg",
    "temples/shore-temple/image_1_480_g3.jpg",
    "temples/shore-temple/image_2.jpg",
  ]);
  const rows = plans.map((plan) =>
    plan.action === "purge" ? { ...plan, result: "would-purge" } : plan,
  );
  const report = formatPurgeReport(rows, { deleted: shore.objectPaths, kept: [] });
  assert.match(report, /photo pending: 9/);
  assert.match(report, /places temples: 10/);
  for (const id of pendingIds) assert.match(report, new RegExp(`  ${id}`));
  assert.match(report, /token=<redacted>/);
  assert.doesNotMatch(report, /token-/);
  assert.match(report, /Photo pending:/);
  assert.equal(report.includes("secret"), false);
});

test("a credited thumb stays and an uncredited thumb is cleared", () => {
  const commons = "https://upload.wikimedia.org/wikipedia/commons/a/a1/File.jpg";
  const planned = planPurgePlaces(
    temple("mixed-temple", {
      imageUrl: commons,
      images: [commons],
      photos: [
        {
          url: commons,
          credit: "Ada Lovelace",
          licence: "CC BY 4.0",
          order: 0,
          thumbUrl: publicUrl("mixed-temple", "image_3_480_g1.jpg"),
        },
      ],
    }),
  );
  assert.equal(planned.action, "purge");
  assert.equal(planned.photoPending, false);
  assert.equal(Object.hasOwn(planned.patch.photos[0], "thumbUrl"), false);
  assert.equal(planned.patch.photos[0].url, commons);
});

test("--exclude warns on unknown ids and --only limits the plan", () => {
  const opts = parseArgs([
    "--exclude",
    "missing-temple,shore-temple",
    "--only=anjengo-sree-durga-devi-temple,shore-temple,also-missing",
  ]);
  assert.equal(opts.exclude.has("shore-temple"), true);
  assert.equal(opts.only.has("anjengo-sree-durga-devi-temple"), true);
  const temples = [
    temple("anjengo-sree-durga-devi-temple"),
    temple("shore-temple"),
    temple("other-temple"),
  ];
  assert.deepEqual(
    selectTemples(temples, opts).map((item) => item.id),
    ["anjengo-sree-durga-devi-temple"],
  );
  assert.throws(() => parseArgs(["--only"]), /--only needs/);
  assert.throws(() => parseArgs(["--nope"]), /Unknown argument/);
});

test("delete runs only after a successful write and skips a referenced object", async () => {
  const anjengo = temple("anjengo-sree-durga-devi-temple", {
    imageUrl: publicUrl("anjengo-sree-durga-devi-temple", "image_1.jpg"),
    images: [
      publicUrl("anjengo-sree-durga-devi-temple", "image_1.jpg"),
      publicUrl("kept-temple", "image_2.jpg"),
    ],
  });
  const kept = temple("kept-temple", {
    imageUrl: publicUrl("kept-temple", "image_2.jpg"),
    images: [publicUrl("kept-temple", "image_2.jpg")],
    photos: [
      {
        url: publicUrl("kept-temple", "image_2.jpg"),
        credit: "Ada Lovelace",
        licence: "CC BY 4.0",
        order: 0,
      },
    ],
  });
  const plan = planPurgePlaces(anjengo);
  const events = [];
  const rows = await applyPurgePlans([plan, planPurgePlaces(kept)], {
    dryRun: false,
    write: async () => {
      events.push("write");
      return { ok: true };
    },
  });
  assert.deepEqual(events, ["write"]);
  const after = [
    { ...anjengo, ...rows[0].patch },
    kept,
  ];
  const objects = await placesDeletePlan(rows, after, {
    listPrefix: async (prefix) => {
      events.push(`list:${prefix}`);
      if (prefix === "temples/anjengo-sree-durga-devi-temple/") {
        return [
          "temples/anjengo-sree-durga-devi-temple/image_1.jpg",
          "temples/anjengo-sree-durga-devi-temple/image_1_480_g9.jpg",
          "temples/anjengo-sree-durga-devi-temple/02_pack.jpg",
        ];
      }
      return ["temples/kept-temple/image_2.jpg"];
    },
    deleteObject: async (path) => {
      events.push(`delete:${path}`);
    },
    performDelete: true,
  });
  assert.deepEqual(objects.deleted, [
    "temples/anjengo-sree-durga-devi-temple/image_1.jpg",
    "temples/anjengo-sree-durga-devi-temple/image_1_480_g9.jpg",
  ]);
  assert.deepEqual(objects.kept, ["temples/kept-temple/image_2.jpg"]);
  assert.equal(events[0], "write");
  assert.ok(events.indexOf("list:temples/anjengo-sree-durga-devi-temple/") > 0);
  assert.equal(
    events.includes("delete:temples/kept-temple/image_2.jpg"),
    false,
  );
  assert.equal(referencedObjectPaths(after).has("temples/kept-temple/image_2.jpg"), true);

  const skipped = await applyPurgePlans([plan], {
    dryRun: false,
    write: async () => ({ ok: false, reason: "changed" }),
  });
  const none = await placesDeletePlan(skipped, [anjengo], {
    deleteObject: async () => {
      throw new Error("skipped write must not delete");
    },
    performDelete: true,
  });
  assert.deepEqual(none.deleted, []);
});

test("a changed document is not written", () => {
  const original = temple("shore-temple", {
    imageUrl: publicUrl("shore-temple", "image_1.jpg"),
    images: [publicUrl("shore-temple", "image_1.jpg")],
  });
  const plan = planPurgePlaces(original);
  assert.equal(commitPurgePlaces(original, plan).ok, true);
  assert.equal(
    commitPurgePlaces(
      { ...original, imageUrl: publicUrl("shore-temple", "02_Shore.jpg") },
      plan,
    ).reason,
    "changed",
  );
});

test("apply refuses CI and dry-run does not delete", async () => {
  await assert.rejects(
    () => authorizeApply("demo-temple-index", { CI: "true", FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" }),
    /CI/,
  );
  const deleted = [];
  const lines = [];
  const result = await main(["--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => lines.push(line),
    warn: (line) => lines.push(line),
    load: async () => [
      temple("shore-temple", {
        imageUrl: tokenUrl("shore-temple", "image_1.jpg"),
        images: [tokenUrl("shore-temple", "image_1.jpg")],
      }),
      temple("other-temple"),
    ],
    listPrefix: async () => ["temples/shore-temple/image_1_480_g1.jpg"],
    deleteObject: async (path) => deleted.push(path),
  });
  assert.deepEqual(deleted, []);
  assert.equal(result.rows.find((row) => row.id === "shore-temple").result, "would-purge");
  assert.deepEqual(result.objects.deleted, [
    "temples/shore-temple/image_1.jpg",
    "temples/shore-temple/image_1_480_g1.jpg",
  ]);
  assert.match(lines.join("\n"), /token=<redacted>/);
  assert.equal(lines.join("\n").includes("secret-token"), false);
  const warnings = [];
  await main(["--exclude", "missing-id", "--only", "also-missing", "--project", "demo"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: () => {},
    warn: (line) => warnings.push(line),
    load: async () => [temple("shore-temple")],
    listPrefix: async () => [],
  });
  assert.match(warnings.join("\n"), /exclude: unknown temple id missing-id/);
  assert.match(warnings.join("\n"), /only: unknown temple id also-missing/);
});

const indexAdmin = {
  firestore: {
    FieldPath: class FieldPath {
      constructor(...parts) {
        this.parts = parts;
      }
    },
    FieldValue: {
      serverTimestamp: () => "SERVER_TIME",
      increment: (n) => ({ increment: n }),
      delete: () => "DELETE",
    },
  },
};

function memoryDb(read) {
  const ops = [];
  return {
    ops,
    collection(name) {
      return { doc: (id) => ({ path: `${name}/${id}`, id, collection: name }) };
    },
    async runTransaction(fn) {
      const writes = [];
      const result = await fn({
        get: async (ref) => read(ref),
        update: (ref, ...args) => writes.push({ op: "update", path: ref.path, args }),
        set: (ref, data, options) => writes.push({ op: "set", path: ref.path, data, options }),
      });
      if (!result || result.ok === false) return result;
      ops.push(writes);
      return result;
    },
  };
}

test("the transaction writes an empty gallery and a null cover thumb", async () => {
  const fresh = temple("shore-temple", {
    name: "Shore Temple",
    imageUrl: publicUrl("shore-temple", "image_1.jpg"),
    images: [publicUrl("shore-temple", "image_1.jpg")],
  });
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const written = await persistPurgePlaces(db, planPurgePlaces(fresh), { admin: indexAdmin });
  assert.equal(written.ok, true);
  const update = db.ops[0].find((write) => write.path === "temples/shore-temple");
  assert.equal(update.args[0].imageUrl, "");
  assert.deepEqual(update.args[0].images, []);
  const index = db.ops[0].find((write) => write.path === "temple_index/kerala");
  assert.equal(index.data.entries["shore-temple"].coverThumb, null);
  assert.equal(Object.hasOwn(update.args[0], "photoPending"), false);
});

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const onEmulator = /^(127\.0\.0\.1|localhost):\d+$/.test(emulatorHost);

test(
  "emulator apply clears uncredited Places mirrors and keeps a shared object",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const admin = (await import("firebase-admin")).default;
    if (admin.apps.length === 0) admin.initializeApp({ projectId: "demo-temple-index" });
    const db = admin.firestore();
    const id = "purge-emulator-shore";
    const other = "purge-emulator-kept";
    const places = publicUrl(id, "image_1.jpg");
    const shared = publicUrl(other, "image_2.jpg");
    const base = {
      name: "Purge Emulator Shore",
      state: "Purge Test State",
      city: "Mahabalipuram",
      deity: "Shiva",
      description: "Emulator fixture.",
      story: "Emulator fixture.",
      address: "Mahabalipuram",
    };
    await db.collection("temples").doc(id).set({
      ...base,
      id,
      imageUrl: places,
      images: [places, shared],
      photos: [],
    });
    await db.collection("temples").doc(other).set({
      ...base,
      id: other,
      name: "Kept",
      imageUrl: shared,
      images: [shared],
      photos: [],
    });
    const fresh = (await db.collection("temples").doc(id).get()).data();
    const plan = planPurgePlaces({ ...fresh, id });
    const written = await persistPurgePlaces(db, plan);
    assert.equal(written.ok, true);
    const saved = await db.collection("temples").doc(id).get();
    assert.equal(saved.get("imageUrl"), "");
    assert.deepEqual(saved.get("images"), []);
    const shard = await db.collection("temple_index").doc("purge-test-state").get();
    assert.equal(shard.get("entries")[id].coverThumb, null);
    const temples = [
      { id, ...saved.data() },
      { id: other, ...(await db.collection("temples").doc(other).get()).data() },
    ];
    const deleted = [];
    const objects = await placesDeletePlan([{ ...plan, result: "purged" }], temples, {
      listPrefix: async () => [`temples/${id}/image_1.jpg`, `temples/${id}/image_1_480_g4.jpg`, `temples/${other}/image_2.jpg`],
      deleteObject: async (path) => deleted.push(path),
      performDelete: true,
    });
    assert.deepEqual(deleted, [`temples/${id}/image_1.jpg`, `temples/${id}/image_1_480_g4.jpg`]);
    assert.deepEqual(objects.kept, [`temples/${other}/image_2.jpg`]);
    await db.collection("temples").doc(id).delete();
    await db.collection("temples").doc(other).delete();
  },
);
