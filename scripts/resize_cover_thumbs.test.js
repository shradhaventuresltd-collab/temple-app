import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { coverThumb, fullCoverUrlFromThumb, thumbObjectPath, wikimediaOriginalUrl } from "./temple_index.js";
import {
  THUMB_CACHE_CONTROL,
  applyCoverThumbPlans,
  applyLimitAndResume,
  authorizeApply,
  commitCoverThumb,
  firebaseMediaUrl,
  formatThumbReport,
  loadResume,
  main,
  parseArgs,
  persistCoverPhotos,
  planCoverThumb,
  saveResume,
  sourceIsNewer,
  staysFullSizeWikimedia,
  thumbSaveOptions,
  withCoverThumbUrl,
} from "./resize_cover_thumbs.js";

const here = dirname(fileURLToPath(import.meta.url));
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };

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

function shore(id = "shore-temple") {
  const source = `https://storage.googleapis.com/bucket/temples/${id}/01.jpg`;
  return {
    id,
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    address: "Mahabalipuram",
    images: [source],
    photos: [{ url: source, licence: "CC0", credit: "", order: 0 }],
  };
}

test("cover thumb fixture matches the Dart writer", () => {
  const cases = JSON.parse(readFileSync(resolve(here, "fixtures/cover_thumb_cases.json"), "utf8"));
  for (const row of cases) {
    assert.equal(coverThumb(row.data), row.expect, row.name);
  }
  const names = JSON.parse(readFileSync(resolve(here, "fixtures/thumb_name_cases.json"), "utf8"));
  for (const row of names) {
    assert.equal(thumbObjectPath(row.objectPath, row.generation), row.thumbPath);
    assert.equal(fullCoverUrlFromThumb(row.thumbUrl), row.fullUrl);
  }
});

test("a storage cover plans an upload and a wikimedia cover does not", () => {
  const storage = planCoverThumb(shore());
  assert.equal(storage.action, "upload");
  assert.equal(storage.objectPath, "temples/shore-temple/01.jpg");
  assert.equal(storage.bucket, "bucket");
  assert.equal(storage.cacheControl, THUMB_CACHE_CONTROL);
  assert.equal(storage.contentType, "image/jpeg");
  assert.equal(Object.hasOwn(storage, "thumbUrl"), false);
  const firebase = planCoverThumb({
    ...shore(),
    images: [
      "https://firebasestorage.googleapis.com/v0/b/other.appspot.com/o/temples%2Fshore-temple%2F01.jpg?alt=media&token=abc",
    ],
    photos: [
      {
        url: "https://firebasestorage.googleapis.com/v0/b/other.appspot.com/o/temples%2Fshore-temple%2F01.jpg?alt=media&token=abc",
        licence: "CC0",
        order: 0,
      },
    ],
  });
  assert.equal(firebase.bucket, "other.appspot.com");
  assert.equal(thumbSaveOptions({ token: "t" }).preconditionOpts.ifGenerationMatch, 0);

  const wiki = planCoverThumb({
    id: "meenakshi",
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg",
  });
  assert.equal(wiki.action, "skip");
  assert.equal(wiki.reason, "not-storage");
});

test("dry-run lists a missing thumb, counts not-storage, and does not upload", async () => {
  const uploads = [];
  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: emulator,
    log: (line) => lines.push(line),
    load: async () => [
      shore(),
      {
        id: "wiki",
        imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg",
      },
      {
        id: "wiki-original",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg",
      },
      (() => {
        const bare = shore("bare-temple");
        delete bare.photos;
        return bare;
      })(),
    ],
    stat: async (path) =>
      path.endsWith("/01.jpg")
        ? { generation: "1", updated: "2024-01-01T00:00:00.000Z" }
        : null,
    upload: async (file) => {
      uploads.push(file);
      return { url: "https://example.com/thumb.jpg" };
    },
    writeResume: () => {
      throw new Error("dry-run must not write the resume file");
    },
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows.find((row) => row.id === "shore-temple").result, "would-upload");
  assert.equal(rows.find((row) => row.id === "shore-temple").thumbPath, "temples/shore-temple/01_480_g1.jpg");
  assert.equal(rows.find((row) => row.id === "wiki").reason, "not-storage");
  assert.equal(rows.find((row) => row.id === "wiki-original").reason, "wikimedia-full");
  assert.equal(staysFullSizeWikimedia(rows.find((row) => row.id === "wiki").source), false);
  const report = lines.join("\n");
  assert.match(report, /skip not-storage: 2/);
  assert.match(report, /wikimedia full-size: 1/);
  assert.match(
    report,
    /full-size wiki-original https:\/\/upload\.wikimedia\.org\/wikipedia\/commons\/2\/20\/File\.jpg/,
  );
  assert.match(report, /no-photo: 1/);
  assert.match(
    report,
    /no-photo bare-temple https:\/\/storage\.googleapis\.com\/bucket\/temples\/bare-temple\/01\.jpg/,
  );
  assert.equal(report.includes("coverThumbUrl"), false);
  assert.equal(
    fullCoverUrlFromThumb("https://storage.googleapis.com/bucket/temples/shore/01_480.jpg"),
    "https://storage.googleapis.com/bucket/temples/shore/01.jpg",
  );
  assert.equal(
    wikimediaOriginalUrl(
      "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/480px-File.jpg",
    ),
    "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg",
  );
  assert.equal(
    wikimediaOriginalUrl(
      "https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/File.jpg/1280px-File.jpg",
    ),
    "https://upload.wikimedia.org/wikipedia/commons/7/76/File.jpg",
  );
});

test("apply stores the download URL and does not skip a stale thumb", async () => {
  const uploads = [];
  const writes = [];
  const resumes = [];
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    confirm: async () => {
      throw new Error("emulator apply must not prompt");
    },
    writeResume: (body) => resumes.push(body),
    load: async () => [shore("new-temple"), shore("old-temple"), shore("stale-temple")],
    stat: async (path) => {
      if (path.endsWith("/01.jpg")) {
        const updated = path.includes("stale-temple")
          ? "2024-06-01T00:00:00.000Z"
          : "2024-01-01T00:00:00.000Z";
        return { generation: "42", updated };
      }
      if (path.endsWith("/01_480_g42.jpg") && path.includes("old-temple")) {
        return {
          generation: "9",
          updated: "2024-03-01T00:00:00.000Z",
          url: "https://firebasestorage.googleapis.com/v0/b/b/o/old?alt=media&token=kept",
        };
      }
      if (path.endsWith("/01_480_g42.jpg") && path.includes("stale-temple")) {
        return { generation: "9", updated: "2024-01-01T00:00:00.000Z" };
      }
      return null;
    },
    download: async () => Buffer.from("full-size"),
    encode: async (bytes) => Buffer.from(`thumb-${bytes.length}`),
    upload: async (file) => {
      uploads.push(file);
      return {
        url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
      };
    },
    verifyPublic: async (url) => {
      writes.push({ verified: url });
      return true;
    },
    writeThumbUrl: async (assigned) => {
      writes.push(assigned);
    },
  });
  assert.equal(uploads.length, 2);
  assert.equal(uploads[0].path, "temples/new-temple/01_480_g42.jpg");
  assert.equal(uploads[0].bucket, "bucket");
  assert.equal(uploads[0].ifGenerationMatch, 0);
  assert.equal(
    uploads[1].path,
    `temples/stale-temple/01_480_g42u${Date.parse("2024-06-01T00:00:00.000Z")}.jpg`,
  );
  assert.equal(uploads[0].contentType, "image/jpeg");
  assert.equal(uploads[0].cacheControl, THUMB_CACHE_CONTROL);
  assert.equal(rows.find((row) => row.id === "old-temple").result, "exists");
  assert.equal(rows.find((row) => row.id === "new-temple").result, "uploaded");
  const verified = writes.find((write) => write.verified);
  const download =
    "https://firebasestorage.googleapis.com/v0/b/bucket/o/" +
    `${encodeURIComponent("temples/new-temple/01_480_g42.jpg")}?alt=media&token=real`;
  assert.equal(verified.verified, download);
  assert.equal(firebaseMediaUrl(verified.verified), download);
  assert.equal(firebaseMediaUrl("https://storage.googleapis.com/bucket/temples/new-temple/01_480_g42.jpg"), null);
  assert.equal(resumes.length, 3);
  assert.match(resumes[0], /new-temple/);
  assert.doesNotMatch(resumes[0], /old-temple/);
  assert.match(resumes[2], /stale-temple/);
  const stored = writes.find((write) => write.temple?.id === "new-temple");
  assert.equal(stored.photos[0].thumbUrl, stored.entry.coverThumb);
  assert.match(stored.entry.coverThumb, /token=real/);
  assert.equal(coverThumb(stored.temple), stored.photos[0].thumbUrl);
});

test("an older thumb name does not count as current", async () => {
  const uploads = [];
  await applyCoverThumbPlans([planCoverThumb(shore())], {
    dryRun: false,
    stat: async (path) => {
      if (path.endsWith("/01.jpg")) return { generation: "5", updated: "2024-01-01T00:00:00.000Z" };
      if (path.endsWith("/01_480.jpg")) return { generation: "1", updated: "2020-01-01T00:00:00.000Z" };
      return null;
    },
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: async (file) => {
      uploads.push(file);
      return { url: "https://example.com/t?token=1" };
    },
    verifyPublic: async () => true,
    writeThumbUrl: async () => {},
  });
  assert.equal(uploads.length, 1);
  assert.equal(uploads[0].path, "temples/shore-temple/01_480_g5.jpg");
});

test("limit and resume skip the rest", () => {
  const plans = [
    { id: "a", action: "upload" },
    { id: "b", action: "skip", reason: "not-storage" },
    { id: "c", action: "upload" },
  ];
  const selected = applyLimitAndResume(plans, { limit: 1, resumeIds: new Set(["a"]) });
  assert.equal(selected[0].reason, "resume");
  assert.equal(selected[1].reason, "not-storage");
  assert.equal(selected[2].action, "upload");
  const report = formatThumbReport(selected);
  assert.match(report, /skip not-storage: 1/);
});

test("apply refuses CI and does not upload", async () => {
  const uploads = [];
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: { CI: "true", ...emulator },
        log: () => {},
        load: async () => {
          throw new Error("load should not run");
        },
        stat: async () => null,
        upload: async (file) => {
          uploads.push(file);
          return { url: "https://example.com/t" };
        },
      }),
    /CI/,
  );
  assert.equal(uploads.length, 0);
});

test("prod apply without a project is refused", async () => {
  assert.throws(() => parseArgs(["--apply", "--nope"]), /Unknown argument/);
  assert.throws(() => parseArgs(["--limit", "0"]), /limit/);
  await assert.rejects(() => authorizeApply("", { FIRESTORE_EMULATOR_HOST: "" }), /project/);
});

test("a thumb that is not publicly readable is not written to the index", async () => {
  const writes = [];
  const rows = await applyCoverThumbPlans([planCoverThumb(shore())], {
    dryRun: false,
    stat: async (path) =>
      path.endsWith("/01.jpg") ? { generation: "3", updated: "2024-01-01T00:00:00.000Z" } : null,
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: async (file) => {
      assert.equal(file.ifGenerationMatch, 0);
      assert.equal(file.bucket, "bucket");
      return {
        url: "https://firebasestorage.googleapis.com/v0/b/bucket/o/temples%2Fshore-temple%2F01_480_g3.jpg?alt=media&token=real",
      };
    },
    verifyPublic: async (url) => {
      assert.equal(
        url,
        "https://firebasestorage.googleapis.com/v0/b/bucket/o/temples%2Fshore-temple%2F01_480_g3.jpg?alt=media&token=real",
      );
      return false;
    },
    writeThumbUrl: async (assigned) => {
      writes.push(assigned);
    },
  });
  assert.equal(writes.length, 0);
  assert.equal(rows[0].result, "not-public");
  assert.equal(rows[0].publicUrl, "temples/shore-temple/01_480_g3.jpg");
  const report = formatThumbReport(rows, { apply: true });
  assert.match(report, /not-public shore-temple temples\/shore-temple\/01_480_g3\.jpg/);
  assert.doesNotMatch(report, /token=/);
  assert.doesNotMatch(report, /alt=media/);
});

test("a missing photo does not invent thumbUrl", async () => {
  const temple = shore();
  delete temple.photos;
  const assigned = withCoverThumbUrl(temple, "https://example.com/thumb.jpg");
  assert.equal(assigned.ok, false);
  assert.equal(assigned.reason, "no-photo");
  const planned = planCoverThumb(temple);
  assert.equal(planned.action, "skip");
  assert.equal(planned.reason, "no-photo");
  const uploads = [];
  const rows = await applyCoverThumbPlans([planned], {
    dryRun: false,
    stat: async () => {
      throw new Error("no-photo must not read Storage");
    },
    upload: async (file) => {
      uploads.push(file);
      return { url: "https://example.com/t" };
    },
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows[0].reason, "no-photo");
  const report = formatThumbReport(rows);
  assert.match(report, /no-photo shore-temple /);
  assert.equal(report.includes("coverThumbUrl"), false);
});

test("the resize script does not batch the index after the run", () => {
  const source = readFileSync(resolve(here, "resize_cover_thumbs.js"), "utf8");
  assert.doesNotMatch(source, /applyThumbIndex|applyIndex|thumbIndexReport/);
});

test("a failed later row keeps the resume line and does not flush an index batch", async () => {
  const resumes = [];
  const indexWrites = [];
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: emulator,
        log: () => {},
        confirm: async () => "demo-temple-index",
        load: async () => [shore("a-temple"), shore("b-temple")],
        stat: async (path) =>
          path.endsWith("/01.jpg") ? { generation: "1", updated: "2024-01-01T00:00:00.000Z" } : null,
        download: async () => Buffer.from("full"),
        encode: async () => Buffer.from("thumb"),
        upload: async (file) => {
          if (file.path.includes("b-temple")) throw new Error("boom");
          return {
            url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
          };
        },
        verifyPublic: async () => true,
        writeThumbUrl: async (assigned) => {
          indexWrites.push(assigned.temple.id);
        },
        writeResume: (body) => resumes.push(body),
      }),
    /boom/,
  );
  assert.equal(resumes.length, 1);
  assert.match(resumes[0], /a-temple/);
  assert.doesNotMatch(resumes[0], /b-temple/);
  assert.deepEqual(indexWrites, ["a-temple"]);
});

test("a mid-run edit is kept and a replaced cover is not overwritten", async () => {
  const kept = shore("kept-temple");
  const moved = shore("moved-temple");
  const live = {
    "kept-temple": structuredClone(kept),
    "moved-temple": structuredClone(moved),
  };
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      const data = live[ref.id];
      return { exists: Boolean(data), id: ref.id, data: () => structuredClone(data) };
    }
    if (ref.collection === "meta") {
      return { exists: true, id: ref.id, data: () => ({ indexVersion: 4, shards: {} }) };
    }
    return { exists: true, id: ref.id, data: () => ({ entries: {} }) };
  });
  const uploads = [];
  const resumes = [];
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    confirm: async () => "demo-temple-index",
    load: async () => {
      const snapshot = [structuredClone(live["kept-temple"]), structuredClone(live["moved-temple"])];
      live["kept-temple"].name = "New Name";
      live["kept-temple"].photos = [
        { ...live["kept-temple"].photos[0], credit: "Admin" },
        { url: "https://example.com/other.jpg", licence: "CC0", credit: "Keep", order: 1 },
      ];
      const other = "https://upload.wikimedia.org/wikipedia/commons/2/20/Other.jpg";
      live["moved-temple"].images = [other];
      live["moved-temple"].photos = [{ url: other, licence: "CC0", credit: "Moved", order: 0 }];
      return snapshot;
    },
    reread: async (id) => structuredClone(live[id]),
    stat: async (path) =>
      path.endsWith("/01.jpg") ? { generation: "1", updated: "2024-01-01T00:00:00.000Z" } : null,
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: async (file) => {
      uploads.push(file.path);
      return {
        url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
      };
    },
    verifyPublic: async () => true,
    writeThumbUrl: (assigned) => persistCoverPhotos(db, assigned, { admin: indexAdmin }),
    writeResume: (body) => resumes.push(body),
  });
  assert.deepEqual(uploads, ["temples/kept-temple/01_480_g1.jpg"]);
  assert.equal(rows.find((row) => row.id === "moved-temple").reason, "cover-changed");
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const photos = writes.find((write) => write.path === "temples/kept-temple");
  assert.equal(photos.args[0].photos[0].credit, "Admin");
  assert.match(photos.args[0].photos[0].thumbUrl, /token=real/);
  assert.equal(photos.args[0].photos[1].credit, "Keep");
  assert.equal(photos.args[0].photos[1].thumbUrl, undefined);
  const index = writes.find((write) => write.path === "temple_index/tamil-nadu");
  assert.equal(index.data.entries["kept-temple"].name, "New Name");
  assert.equal(index.data.entries["kept-temple"].coverThumb, photos.args[0].photos[0].thumbUrl);
  assert.equal(index.data.entries["kept-temple"].updatedAt, "SERVER_TIME");
  assert.deepEqual(index.options.mergeFields[0].parts, ["entries", "kept-temple"]);
  const meta = writes.find((write) => write.path === "meta/temple_index");
  assert.deepEqual(meta.args[0].indexVersion, { increment: 1 });
  assert.equal(meta.args[0]["shards.tamil-nadu"], "SERVER_TIME");
  assert.equal(resumes.length, 1);
  assert.match(resumes[0], /kept-temple/);
  assert.doesNotMatch(resumes[0], /moved-temple/);
  assert.match(formatThumbReport(rows, { apply: true }), /skip moved-temple cover-changed/);
});

test("persistCoverPhotos writes the fresh thumb and index in one transaction", async () => {
  const source = "https://storage.googleapis.com/bucket/temples/kept-temple/01.jpg";
  const thumb = "https://firebasestorage.googleapis.com/v0/b/bucket/o/t?alt=media&token=real";
  const assigned = {
    ...withCoverThumbUrl(shore("kept-temple"), thumb),
    source,
    plannedState: "Tamil Nadu",
  };
  const fresh = {
    ...shore("kept-temple"),
    name: "New Name",
    photos: [
      { url: source, licence: "CC0", credit: "Admin", order: 0 },
      { url: "https://example.com/other.jpg", credit: "Keep", order: 1 },
    ],
  };
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const committed = await persistCoverPhotos(db, assigned, { admin: indexAdmin });
  assert.equal(committed.temple.name, "New Name");
  assert.equal(committed.entry.name, "New Name");
  assert.equal(committed.entry.coverThumb, thumb);
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const photos = writes.find((write) => write.op === "update" && write.path.startsWith("temples/"));
  assert.equal(photos.args[0].photos[0].credit, "Admin");
  assert.equal(photos.args[0].photos[0].thumbUrl, thumb);
  assert.equal(photos.args[0].photos[1].thumbUrl, undefined);
  assert.equal(Object.keys(photos.args[0]).length, 1);
  const index = writes.find((write) => write.path === "temple_index/tamil-nadu");
  assert.equal(index.data.entries["kept-temple"].coverThumb, thumb);
  const meta = writes.find((write) => write.path === "meta/temple_index");
  assert.equal(meta.data.indexVersion, 1);
  assert.equal(meta.data.shards["tamil-nadu"], "SERVER_TIME");

  const moved = memoryDb(() => ({
    exists: true,
    id: "kept-temple",
    data: () => ({
      ...shore("kept-temple"),
      images: ["https://upload.wikimedia.org/wikipedia/commons/2/20/Other.jpg"],
    }),
  }));
  const skipped = await persistCoverPhotos(moved, assigned, { admin: indexAdmin });
  assert.equal(skipped.ok, false);
  assert.equal(skipped.reason, "cover-changed");
  assert.equal(moved.ops.length, 0);
  const sameCover = commitCoverThumb(
    { ...shore("kept-temple"), updateTime: "t2" },
    { source, thumbUrl: thumb },
  );
  assert.equal(sameCover.ok, true);
  assert.equal(sameCover.temple.photos[0].thumbUrl, thumb);
});

test("apply stops before upload when the encoder returns nothing", async () => {
  const uploads = [];
  await assert.rejects(
    () =>
      applyCoverThumbPlans([planCoverThumb(shore())], {
        dryRun: false,
        stat: async (path) =>
          path.endsWith("/01.jpg") ? { generation: "3", updated: "2024-01-01T00:00:00.000Z" } : null,
        download: async () => Buffer.from("full"),
        encode: async () => Buffer.alloc(0),
        upload: async (file) => {
          uploads.push(file);
          return { url: "https://example.com/t" };
        },
      }),
    /empty thumb/,
  );
  assert.equal(uploads.length, 0);
});

test("source updated time decides a stale thumb", () => {
  assert.equal(sourceIsNewer("2024-02-01T00:00:00.000Z", "2024-01-01T00:00:00.000Z"), true);
  assert.equal(sourceIsNewer("2024-01-01T00:00:00.000Z", "2024-02-01T00:00:00.000Z"), false);
  assert.equal(sourceIsNewer(undefined, "2024-01-01T00:00:00.000Z"), false);
});

test("resume re-processes a temple whose cover changed", async () => {
  const same = shore("same-cover");
  const previous = shore("moved-cover");
  const next = "https://storage.googleapis.com/bucket/temples/moved-cover/02.jpg";
  const changed = {
    ...previous,
    images: [next],
    photos: [{ url: next, licence: "CC0", credit: "New", order: 0 }],
  };
  const recorded = loadResume(
    saveResume(
      "demo-temple-index",
      new Map([
        ["same-cover", same.images[0]],
        ["moved-cover", previous.images[0]],
      ]),
    ),
    "demo-temple-index",
  );
  const plans = applyLimitAndResume([planCoverThumb(changed), planCoverThumb(same)], {
    resumeCovers: recorded,
  });
  assert.equal(plans[0].action, "upload");
  assert.equal(plans[0].source, next);
  assert.equal(plans[1].reason, "resume");

  const legacy = loadResume(
    JSON.stringify({ project: "demo-temple-index", ids: ["same-cover"] }),
    "demo-temple-index",
  );
  assert.equal(applyLimitAndResume([planCoverThumb(same)], { resumeCovers: legacy })[0].reason, "resume");

  const uploads = [];
  const resumes = [];
  const rows = await main(["--apply", "--resume", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    confirm: async () => {
      throw new Error("emulator apply must not prompt");
    },
    readResume: () =>
      saveResume(
        "demo-temple-index",
        new Map([
          ["same-cover", same.images[0]],
          ["moved-cover", previous.images[0]],
        ]),
      ),
    load: async () => [changed, same],
    stat: async (path) =>
      path.includes("_480") ? null : { generation: "7", updated: "2024-01-01T00:00:00.000Z" },
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: async (file) => {
      uploads.push(file.path);
      return {
        url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
      };
    },
    verifyPublic: async () => true,
    writeThumbUrl: async () => {},
    writeResume: (body) => resumes.push(body),
  });
  assert.deepEqual(uploads, ["temples/moved-cover/02_480_g7.jpg"]);
  assert.equal(rows.find((row) => row.id === "same-cover").reason, "resume");
  assert.equal(rows.find((row) => row.id === "moved-cover").result, "uploaded");
  assert.equal(resumes.length, 1);
  const saved = JSON.parse(resumes[0]);
  assert.equal(saved.covers["moved-cover"], next);
  assert.equal(saved.covers["same-cover"], same.images[0]);
  assert.equal(JSON.stringify(saved).includes("token"), false);
});
