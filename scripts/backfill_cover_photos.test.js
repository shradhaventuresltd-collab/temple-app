import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  PHOTO_LICENCES,
  applyCoverPhotoPlans,
  authorizeApply,
  commitCoverPhoto,
  formatCoverPhotoReport,
  main,
  parseArgs,
  persistCoverPhoto,
  planCoverPhoto,
} from "./backfill_cover_photos.js";
import { entryFromTemple } from "./temple_index.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..");
const storage =
  "https://storage.googleapis.com/temple-directory-india.firebasestorage.app/temples/virupaksha-temple/01_Hemakuta_Hills.jpg";
const wiki = "https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg";

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
      if (!result || result.ok === false) {
        assert.equal(writes.length, 0);
        return result;
      }
      ops.push(writes);
      return result;
    },
  };
}

function temple(extra = {}) {
  return {
    id: "virupaksha-temple",
    name: "Virupaksha Temple",
    state: "Karnataka",
    city: "Hampi",
    deity: "Shiva",
    imageUrl: storage,
    images: [storage],
    photos: [
      {
        url: "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Hemakuta_Hills.jpg/1280px-Hemakuta_Hills.jpg",
        credit: "Arjun Dharne · CC BY-SA 4.0",
        licence: "CC-BY-SA",
        order: 0,
      },
    ],
    ...extra,
  };
}

test("a storage cover copies the credit and licence already on the doc", () => {
  const plan = planCoverPhoto(temple());
  assert.equal(plan.action, "add");
  assert.deepEqual(plan.photo, {
    url: storage,
    credit: "Arjun Dharne · CC BY-SA 4.0",
    licence: "CC-BY-SA",
    order: 0,
  });
  assert.equal(plan.photos[0], plan.photo);
  assert.equal(plan.photos[1].url, temple().photos[0].url);
  assert.equal(plan.photos[1].order, 1);
  assert.equal(plan.photos.length, 2);
});

test("a prepended cover renumbers every photo from the array index", () => {
  const plan = planCoverPhoto(
    temple({
      photos: [
        {
          url: wiki,
          credit: "Arjun Dharne · CC BY-SA 4.0",
          licence: "CC-BY-SA",
          order: 0,
        },
        {
          url: `${wiki}?2`,
          credit: "Arjun Dharne · CC BY-SA 4.0",
          licence: "CC-BY-SA",
          order: 4,
        },
      ],
    }),
  );
  assert.equal(plan.action, "add");
  assert.deepEqual(
    plan.photos.map((photo) => photo.order),
    [0, 1, 2],
  );
  assert.equal(plan.photos[0].url, storage);
  assert.equal(plan.photos[2].url, `${wiki}?2`);
});

test("CC0 is already an allowed licence and is copied when the credit is real", () => {
  const rules = readFileSync(resolve(repoRoot, "firestore.rules"), "utf8");
  const model = readFileSync(resolve(repoRoot, "lib/models/photo_licence.dart"), "utf8");
  assert.match(rules, /'CC-BY', 'CC-BY-SA', 'CC0', 'Own', 'Permission'/);
  assert.match(model, /cc0\('CC0'\)/);
  assert.deepEqual(PHOTO_LICENCES, ["CC-BY", "CC-BY-SA", "CC0", "Own", "Permission"]);
  const plan = planCoverPhoto(
    temple({
      photos: [{ url: wiki, credit: "Author", licence: "CC0", order: 0 }],
    }),
  );
  assert.equal(plan.action, "add");
  assert.equal(plan.photo.licence, "CC0");
  assert.equal(plan.photo.credit, "Author");
});

test("missing, unmapped, or disagreeing image fields are skipped", () => {
  assert.equal(
    planCoverPhoto(temple({ photos: [], images: [storage] })).reason,
    "no-attribution",
  );
  assert.equal(
    planCoverPhoto(
      temple({ photos: [{ url: wiki, credit: "  ", licence: "CC0", order: 0 }] }),
    ).reason,
    "no-credit",
  );
  assert.equal(
    planCoverPhoto(
      temple({
        photos: [{ url: wiki, credit: "Author", licence: "CC BY-SA 4.0", order: 0 }],
      }),
    ).reason,
    "licence",
  );
  assert.equal(
    planCoverPhoto(
      temple({
        photos: [
          { url: wiki, credit: "One", licence: "CC-BY", order: 0 },
          { url: `${wiki}?2`, credit: "Two", licence: "CC0", order: 1 },
        ],
      }),
    ).reason,
    "ambiguous",
  );
  const agreed = planCoverPhoto(
    temple({
      photos: [
        { url: wiki, credit: "Author", licence: "Own", order: 0 },
        { url: `${wiki}?2`, credit: "Author", licence: "Own", order: 1 },
      ],
    }),
  );
  assert.equal(agreed.action, "add");
  assert.equal(agreed.photo.licence, "Own");
});

test("attribution can come from an images object and is not invented", () => {
  const plan = planCoverPhoto(
    temple({
      photos: [],
      images: [{ url: storage, credit: "Sanu", licence: "Permission" }],
    }),
  );
  assert.equal(plan.action, "add");
  assert.equal(plan.photo.credit, "Sanu");
  assert.equal(plan.photo.licence, "Permission");
  const source = readFileSync(resolve(here, "backfill_cover_photos.js"), "utf8");
  assert.doesNotMatch(source, /mapPhotoLicence/);
  assert.doesNotMatch(source, /photoCredit\(/);
});

test("a matching photo, a full list, and a non-https storage url are not added", () => {
  assert.equal(planCoverPhoto(temple({ photos: [{ url: storage, credit: "A", licence: "CC0", order: 0 }] })).action, "ready");
  assert.equal(planCoverPhoto(temple({ imageUrl: wiki, photos: [] })).action, "ready");
  const full = Array.from({ length: 12 }, (_, order) => ({
    url: `https://example.com/${order}.jpg`,
    credit: "A",
    licence: "CC0",
    order,
  }));
  assert.equal(planCoverPhoto(temple({ photos: full })).reason, "photos-full");
  assert.equal(
    planCoverPhoto(
      temple({
        imageUrl: "gs://bucket/temples/virupaksha-temple/01.jpg",
        photos: [{ url: wiki, credit: "A", licence: "CC0", order: 0 }],
      }),
    ).reason,
    "not-https",
  );
  assert.equal(
    planCoverPhoto(temple({ photos: ["https://example.com/a.jpg"] })).reason,
    "photos-shape",
  );
});

test("dry-run lists ids and does not write", async () => {
  let writes = 0;
  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => lines.push(line),
    load: async () => [
      temple(),
      temple({
        id: "vaikom-mahadeva-temple",
        name: "Vaikom",
        photos: [],
        images: [storage],
      }),
      temple({
        id: "sringeri-sharada-peetham",
        photos: [{ url: wiki, credit: "A", licence: "CC BY", order: 0 }],
      }),
    ],
    write: async () => {
      writes += 1;
    },
  });
  assert.equal(writes, 0);
  assert.equal(rows.find((row) => row.id === "virupaksha-temple").result, "would-add");
  assert.equal(rows.find((row) => row.id === "vaikom-mahadeva-temple").reason, "no-attribution");
  assert.equal(rows.find((row) => row.id === "sringeri-sharada-peetham").reason, "licence");
  const report = lines.join("\n");
  assert.match(report, /added: 1/);
  assert.match(report, /would-add virupaksha-temple/);
  assert.match(report, /skipped: 2/);
  assert.match(report, /skip vaikom-mahadeva-temple no-attribution/);
  assert.match(report, /skip sringeri-sharada-peetham licence/);
  assert.match(report, /Dry-run only/);
  assert.equal(formatCoverPhotoReport(rows).includes("https://"), false);
});

test("apply writes photos and the index from the fresh doc, and skips a changed doc", async () => {
  const fresh = temple({ name: "Fresh Name" });
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const plan = planCoverPhoto(temple());
  const rows = await applyCoverPhotoPlans([plan], {
    dryRun: false,
    write: (item) => persistCoverPhoto(db, item, { admin: indexAdmin }),
  });
  assert.equal(rows[0].result, "added");
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const photos = writes.find((write) => write.path === "temples/virupaksha-temple");
  assert.equal(photos.args[0].photos[0].url, storage);
  assert.equal(photos.args[0].photos[0].licence, "CC-BY-SA");
  assert.equal(photos.args[0].photos[1].credit, "Arjun Dharne · CC BY-SA 4.0");
  assert.equal(Object.keys(photos.args[0]).length, 1);
  const index = writes.find((write) => write.path === "temple_index/karnataka");
  assert.equal(index.data.entries["virupaksha-temple"].name, "Fresh Name");
  assert.equal(index.data.entries["virupaksha-temple"].coverThumb, storage);
  assert.equal(index.data.entries["virupaksha-temple"].updatedAt, "SERVER_TIME");
  assert.deepEqual(index.options.mergeFields[0].parts, ["entries", "virupaksha-temple"]);
  const meta = writes.find((write) => write.path === "meta/temple_index");
  assert.equal(meta.data.indexVersion, 1);

  const moved = memoryDb(() => ({
    exists: true,
    id: "virupaksha-temple",
    data: () => ({ ...fresh, imageUrl: wiki }),
  }));
  const skipped = await persistCoverPhoto(moved, plan, { admin: indexAdmin });
  assert.equal(skipped.ok, false);
  assert.equal(skipped.reason, "changed");
  assert.equal(moved.ops.length, 0);
  assert.equal(commitCoverPhoto({ ...fresh, photos: [{ url: storage, credit: "A", licence: "CC0", order: 0 }] }, plan).reason, "already");
});

test("apply leaves meta alone when the index entry did not change", async () => {
  const fresh = temple({ name: "Fresh Name" });
  const plan = planCoverPhoto(temple());
  const committed = commitCoverPhoto(fresh, plan);
  assert.equal(committed.ok, true);
  const expected = entryFromTemple(committed.temple);
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "temple_index") {
      return {
        exists: true,
        id: ref.id,
        data: () => ({ entries: { [fresh.id]: { ...expected, updatedAt: "OLD" } } }),
      };
    }
    if (ref.collection === "meta") {
      return { exists: true, id: ref.id, data: () => ({ indexVersion: 4, shards: {} }) };
    }
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const written = await persistCoverPhoto(db, plan, { admin: indexAdmin });
  assert.equal(written.ok, true);
  assert.equal(written.entryChanged, false);
  const [writes] = db.ops;
  assert.equal(writes.some((write) => write.path.startsWith("meta/")), false);
  assert.equal(writes.some((write) => write.path.startsWith("temple_index/")), false);
  const photos = writes.find((write) => write.path === "temples/virupaksha-temple");
  assert.deepEqual(
    photos.args[0].photos.map((photo) => photo.order),
    [0, 1],
  );
});

test("prod apply is refused in CI and without a project", async () => {
  assert.throws(() => parseArgs(["--nope"]), /Unknown argument/);
  await assert.rejects(() => authorizeApply("temple-directory-india", { CI: "true" }), /CI/);
  await assert.rejects(
    () => main(["--apply"], { env: {}, load: async () => [], write: async () => {} }),
    /project/,
  );
  const source = readFileSync(resolve(here, "backfill_cover_photos.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.match(
    source,
    /prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI/,
  );
  assert.doesNotMatch(source, /from an agent/);
});
