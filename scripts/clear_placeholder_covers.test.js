import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  applyClearPlans,
  authorizeApply,
  commitClearCover,
  formatClearReport,
  main,
  parseArgs,
  persistClearCover,
  planClearCover,
  placeholderHostUrl,
  removableImageUrl,
  stockHostUrl,
} from "./clear_placeholder_covers.js";

const here = dirname(fileURLToPath(import.meta.url));
const wiki = "https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg";
const picsum = "https://picsum.photos/seed/anjengo/800/600";

const known = [
  ["anjengo-sree-durga-devi-temple", "Anjengo Sree Durga Devi Temple", "Kerala", picsum],
  [
    "mahamaya-temple",
    "Mahamaya Temple",
    "Jammu and Kashmir",
    "https://picsum.photos/seed/mahamaya-temple/800/600",
  ],
  [
    "ranbireshwar-temple",
    "Ranbireshwar Temple",
    "Jammu and Kashmir",
    "https://via.placeholder.com/800x600",
  ],
  [
    "sudh-mahadev-temple",
    "Sudh Mahadev Temple",
    "Jammu and Kashmir",
    "https://dummyimage.com/600x400",
  ],
];

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
    id: "anjengo-sree-durga-devi-temple",
    name: "Anjengo Sree Durga Devi Temple",
    state: "Kerala",
    city: "Thiruvananthapuram",
    deity: "Devi",
    imageUrl: picsum,
    images: [picsum, "https://source.unsplash.com/random"],
    photos: [
      { url: picsum, licence: "CC0", order: 0 },
      {
        url: wiki,
        licence: "CC-BY-SA",
        credit: "Photographer",
        order: 1,
        thumbUrl: "https://placehold.co/480x320",
      },
    ],
    ...extra,
  };
}

test("placeholder hosts are recognised and other URLs stay", () => {
  assert.equal(placeholderHostUrl(picsum), true);
  assert.equal(placeholderHostUrl("https://fastly.picsum.photos/id/1/800/600"), true);
  assert.equal(placeholderHostUrl("https://i.picsum.photos/id/1/800/600"), true);
  assert.equal(placeholderHostUrl("https://loremflickr.com/800/600"), true);
  assert.equal(placeholderHostUrl("https://www.loremflickr.com/800/600"), true);
  assert.equal(placeholderHostUrl("https://placekitten.com/800/600"), true);
  assert.equal(placeholderHostUrl("https://fakeimg.pl/800"), true);
  assert.equal(placeholderHostUrl("https://placeimg.com/800/600"), true);
  assert.equal(placeholderHostUrl("https://notpicsum.photos/800"), false);
  assert.equal(placeholderHostUrl("https://cdn.source.unsplash.com/random"), false);
  assert.equal(placeholderHostUrl("https://placeholder.com/800"), true);
  assert.equal(placeholderHostUrl("https://via.placeholder.com/800"), true);
  assert.equal(placeholderHostUrl("https://source.unsplash.com/random"), true);
  assert.equal(placeholderHostUrl("https://lorempixel.com/800/600"), true);
  assert.equal(placeholderHostUrl("https://dummyimage.com/600x400"), true);
  assert.equal(placeholderHostUrl("https://placehold.co/800"), true);
  assert.equal(placeholderHostUrl("https://placehold.it/800"), true);
  assert.equal(placeholderHostUrl("https://images.unsplash.com/photo-1"), false);
  assert.equal(placeholderHostUrl("https://www.shutterstock.com/image-photo/temple"), false);
  assert.equal(stockHostUrl("https://www.shutterstock.com/image-photo/temple"), true);
  assert.equal(stockHostUrl("https://media.gettyimages.com/id/1/photo.jpg"), true);
  assert.equal(stockHostUrl("https://www.gettyimages.co.uk/detail/photo/temple"), true);
  assert.equal(stockHostUrl("https://gettyimages.example.com/photo.jpg"), false);
  assert.equal(stockHostUrl("https://images.unsplash.com/photo-1"), false);
  assert.equal(removableImageUrl("https://www.shutterstock.com/image-photo/temple"), true);
  assert.equal(removableImageUrl("https://images.unsplash.com/photo-1"), false);
  assert.equal(
    placeholderHostUrl(
      "https://upload.wikimedia.org/wikipedia/commons/x/xx/Placeholder_temple.jpg",
    ),
    false,
  );
  assert.equal(
    placeholderHostUrl("https://storage.googleapis.com/bucket/temples/placeholder-x.jpg"),
    false,
  );
  assert.equal(placeholderHostUrl(wiki), false);
  assert.equal(placeholderHostUrl(""), false);
  assert.equal(placeholderHostUrl("not-a-url"), false);
});

test("known covers lose placeholder hosts from imageUrl, images, and photos", () => {
  for (const [id, name, state, imageUrl] of known) {
    const plan = planClearCover({
      id,
      name,
      state,
      imageUrl,
      images: [imageUrl],
      photos: [],
    });
    assert.equal(plan.action, "clear", id);
    assert.equal(plan.patch.imageUrl, "");
    assert.deepEqual(plan.patch.images, []);
  }
  const mixed = planClearCover(temple());
  assert.equal(mixed.patch.imageUrl, "");
  assert.deepEqual(mixed.patch.images, []);
  assert.equal(mixed.patch.photos.length, 1);
  assert.equal(mixed.patch.photos[0].url, wiki);
  assert.equal(Object.hasOwn(mixed.patch.photos[0], "thumbUrl"), false);
  assert.equal(planClearCover(temple({ imageUrl: wiki, images: [wiki], photos: [] })).action, "ready");
  const stock = "https://www.shutterstock.com/image-photo/temple";
  const getty = "https://www.gettyimages.com/detail/photo/temple";
  const cleared = planClearCover(
    temple({
      imageUrl: stock,
      images: [stock, wiki, getty],
      photos: [
        { url: stock, licence: "CC0", order: 0 },
        {
          url: wiki,
          licence: "CC-BY",
          credit: "Photographer",
          order: 1,
          thumbUrl: "https://media.gettyimages.com/id/1/photo.jpg",
        },
      ],
    }),
  );
  assert.equal(cleared.action, "clear");
  assert.equal(cleared.patch.imageUrl, "");
  assert.deepEqual(cleared.patch.images, [wiki]);
  assert.equal(cleared.patch.photos.length, 1);
  assert.equal(cleared.patch.photos[0].url, wiki);
  assert.equal(Object.hasOwn(cleared.patch.photos[0], "thumbUrl"), false);
  const otherSite = planClearCover(
    temple({
      imageUrl: "https://gettyimages.example.com/photo.jpg",
      images: ["https://gettyimages.example.com/photo.jpg"],
      photos: [],
    }),
  );
  assert.equal(otherSite.action, "ready");
  const unsplash = planClearCover(
    temple({
      imageUrl: "https://images.unsplash.com/photo-1",
      images: ["https://images.unsplash.com/photo-1"],
      photos: [],
    }),
  );
  assert.equal(unsplash.action, "ready");
});

test("dry-run lists the known temples and does not write", async () => {
  let writes = 0;
  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => lines.push(line),
    load: async () => [
      ...known.map(([id, name, state, imageUrl]) => ({
        id,
        name,
        state,
        city: "City",
        deity: "Devi",
        imageUrl,
        images: [],
        photos: [],
      })),
      temple({ id: "keesaragutta-temple", name: "Keesaragutta", imageUrl: wiki, images: [wiki], photos: [] }),
    ],
    write: async () => {
      writes += 1;
    },
  });
  assert.equal(writes, 0);
  assert.equal(rows.filter((row) => row.result === "would-clear").length, 4);
  for (const [id] of known) {
    assert.equal(rows.find((row) => row.id === id).result, "would-clear");
  }
  assert.equal(rows.find((row) => row.id === "keesaragutta-temple").action, "ready");
  const report = lines.join("\n");
  assert.match(report, /cleared: 4/);
  assert.match(report, /would-clear anjengo-sree-durga-devi-temple/);
  assert.match(report, /would-clear mahamaya-temple/);
  assert.match(report, /would-clear ranbireshwar-temple/);
  assert.match(report, /would-clear sudh-mahadev-temple/);
  assert.match(report, /Dry-run only/);
  assert.equal(formatClearReport(rows).includes("picsum.photos"), false);
});

test("apply rewrites the index from the fresh doc and skips a changed doc", async () => {
  const fresh = temple({ name: "Fresh Name" });
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const plan = planClearCover(temple());
  const rows = await applyClearPlans([plan], {
    dryRun: false,
    write: (item) => persistClearCover(db, item, { admin: indexAdmin }),
  });
  assert.equal(rows[0].result, "cleared");
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const update = writes.find((write) => write.path === "temples/anjengo-sree-durga-devi-temple");
  assert.equal(update.args[0].imageUrl, "");
  assert.deepEqual(update.args[0].images, []);
  assert.equal(update.args[0].photos[0].url, wiki);
  const index = writes.find((write) => write.path === "temple_index/kerala");
  assert.equal(index.data.entries["anjengo-sree-durga-devi-temple"].name, "Fresh Name");
  assert.equal(index.data.entries["anjengo-sree-durga-devi-temple"].coverThumb, null);
  assert.equal(index.data.entries["anjengo-sree-durga-devi-temple"].updatedAt, "SERVER_TIME");
  assert.deepEqual(index.options.mergeFields[0].parts, ["entries", "anjengo-sree-durga-devi-temple"]);
  const meta = writes.find((write) => write.path === "meta/temple_index");
  assert.equal(meta.data.indexVersion, 1);

  const moved = memoryDb(() => ({
    exists: true,
    id: "anjengo-sree-durga-devi-temple",
    data: () => ({ ...fresh, imageUrl: wiki, images: [wiki], photos: [] }),
  }));
  const skipped = await persistClearCover(moved, plan, { admin: indexAdmin });
  assert.equal(skipped.ok, false);
  assert.equal(skipped.reason, "already");
  assert.equal(moved.ops.length, 0);
  assert.equal(
    commitClearCover({ ...fresh, imageUrl: "https://placehold.it/1" }, plan).reason,
    "changed",
  );
});

test("prod apply is refused in CI and without a project", async () => {
  assert.throws(() => parseArgs(["--nope"]), /Unknown argument/);
  await assert.rejects(() => authorizeApply("temple-directory-india", { CI: "true" }), /CI/);
  await assert.rejects(
    () => main(["--apply"], { env: {}, load: async () => [], write: async () => {} }),
    /project/,
  );
  const source = readFileSync(resolve(here, "clear_placeholder_covers.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.match(
    source,
    /prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI/,
  );
  assert.doesNotMatch(source, /from an agent/);
});
