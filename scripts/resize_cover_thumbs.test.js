import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  coverThumb,
  fullCoverUrlFromThumb,
  storageObjectFromUrl,
  thumbObjectPath,
  wikimediaOriginalUrl,
} from "./temple_index.js";
import { planCoverPhoto } from "./backfill_cover_photos.js";
import { STORAGE_AUTH_BUCKET } from "./storage_auth.js";
import {
  THUMB_CACHE_CONTROL,
  THUMB_EDGE,
  applyCoverThumbPlans,
  applyLimitAndResume,
  authorizeApply,
  commitCoverThumb,
  encodeWithSharp,
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
  const source = `https://storage.googleapis.com/${STORAGE_AUTH_BUCKET}/temples/${id}/01.jpg`;
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

test("every stored storage url form names the object", () => {
  const cases = JSON.parse(readFileSync(resolve(here, "fixtures/storage_url_cases.json"), "utf8"));
  for (const row of cases) {
    const located = storageObjectFromUrl(row.url);
    if (row.objectPath == null) {
      assert.equal(located, null, row.name);
      continue;
    }
    assert.equal(located?.kind, row.kind, row.name);
    assert.equal(located?.bucket, row.bucket, row.name);
    assert.equal(located?.objectPath, row.objectPath, row.name);
    const temple = {
      id: "shore-temple",
      images: [row.url],
      photos: [{ url: row.url, licence: "CC0", order: 0 }],
    };
    const plan = planCoverThumb(temple);
    assert.equal(plan.action, "upload", row.name);
    assert.equal(plan.bucket, row.bucket, row.name);
    assert.equal(plan.objectPath, row.objectPath, row.name);
    assert.notEqual(plan.reason, "not-storage", row.name);
  }
  for (const url of [
    "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg",
    "https://evil.example/v0/b/bucket/o/temples%2Fshore-temple%2F01.jpg",
    "https://bucket.firebasestorage.app.evil.com/o/temples%2Fshore-temple%2F01.jpg",
    "http://storage.googleapis.com/bucket/temples/shore-temple/01.jpg",
  ]) {
    assert.equal(storageObjectFromUrl(url), null, url);
  }
});

test("a wiki cover stays not-storage when a storage url is later in the gallery", () => {
  const wiki = "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg";
  const storage = "gs://bucket/temples/shore-temple/01.jpg";
  const plan = planCoverThumb({
    id: "shore-temple",
    images: [wiki, storage],
    photos: [
      { url: wiki, licence: "CC0", order: 0 },
      { url: storage, licence: "CC0", order: 1 },
    ],
  });
  assert.equal(plan.action, "skip");
  assert.equal(plan.reason, "wikimedia-full");
});

test("a backfilled storage cover is picked up, including another url for the same object", () => {
  const imageUrl =
    "https://storage.googleapis.com/temple-directory-india.firebasestorage.app/temples/virupaksha-temple/01_Hemakuta_Hills.jpg";
  const firebase =
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fvirupaksha-temple%2F01_Hemakuta_Hills.jpg?alt=media&token=t";
  const bare = {
    id: "virupaksha-temple",
    name: "Virupaksha Temple",
    state: "Karnataka",
    city: "Hampi",
    deity: "Shiva",
    imageUrl,
    images: [firebase],
    photos: [],
  };
  assert.equal(planCoverThumb(bare).reason, "no-photo");
  const backfill = planCoverPhoto({ ...bare, images: [imageUrl] });
  assert.equal(backfill.action, "add");
  const filled = { ...bare, photos: backfill.photos };
  const plan = planCoverThumb(filled);
  assert.equal(plan.action, "upload");
  assert.equal(plan.objectPath, "temples/virupaksha-temple/01_Hemakuta_Hills.jpg");
  assert.notEqual(plan.reason, "no-photo");
});

test("twelve wikimedia full-size covers are reported and not uploaded", () => {
  const dart = readFileSync(resolve(here, "../lib/data/sample_data.dart"), "utf8");
  const urls = [];
  const re = /imageUrl:\s*(?:\n\s*)?'([^']*)'/g;
  let match;
  while ((match = re.exec(dart))) urls.push(match[1]);
  const originals = urls.filter(
    (url) => url.startsWith("https://upload.wikimedia.org/") && !url.includes("/thumb/"),
  );
  assert.equal(originals.length, 12);
  const temples = originals.map((url, index) => ({
    id: `wiki-full-${index}`,
    imageUrl: url,
    images: [url],
    photos: [],
  }));
  for (const temple of temples) {
    const plan = planCoverThumb(temple);
    assert.equal(plan.action, "skip", temple.imageUrl);
    assert.equal(plan.reason, "wikimedia-full", temple.imageUrl);
    const thumb = coverThumb(temple);
    assert.match(thumb, /\/500px-/, temple.imageUrl);
    assert.equal(thumb.includes("/thumb/"), true, temple.imageUrl);
  }
  const uploads = [];
  const rows = [];
  return applyCoverThumbPlans(
    temples.map((temple) => planCoverThumb(temple)),
    {
      dryRun: true,
      stat: async () => {
        throw new Error("a wikimedia original must not be stat'd");
      },
      upload: async (file) => {
        uploads.push(file);
        return { url: "https://example.com/thumb.jpg" };
      },
    },
  ).then((planned) => {
    rows.push(...planned);
    assert.equal(uploads.length, 0);
    assert.equal(rows.every((row) => row.reason === "wikimedia-full"), true);
    const report = formatThumbReport(rows);
    assert.match(report, /wikimedia full-size: 12/);
    assert.match(report, /full-size wiki-full-0 /);
    assert.equal(report.includes("would-upload"), false);
  });
});

test("gettyimages.example.com is not treated as the stock host", () => {
  const other = planCoverThumb({
    id: "other-site",
    imageUrl: "https://gettyimages.example.com/photo.jpg",
  });
  assert.equal(other.reason, "not-storage");
  const stock = planCoverThumb({
    id: "getty",
    imageUrl: "https://media.gettyimages.com/id/1/photo.jpg",
  });
  assert.equal(stock.reason, "no-cover");
  const country = planCoverThumb({
    id: "getty-uk",
    imageUrl: "https://www.gettyimages.co.uk/detail/photo/temple",
  });
  assert.equal(country.reason, "no-cover");
  const adobe = planCoverThumb({
    id: "adobe-stock",
    imageUrl: "https://t4.ftcdn.net/jpg/01/temple.jpg",
  });
  assert.equal(adobe.reason, "no-cover");
});

test("a storage cover plans an upload and a wikimedia cover does not", () => {
  const storage = planCoverThumb(shore());
  assert.equal(storage.action, "upload");
  assert.equal(storage.objectPath, "temples/shore-temple/01.jpg");
  assert.equal(storage.bucket, STORAGE_AUTH_BUCKET);
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
  assert.equal(firebase.action, "skip");
  assert.equal(firebase.reason, "other-bucket");
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
  const locked = STORAGE_AUTH_BUCKET.replaceAll(".", "\\.");
  assert.match(
    report,
    new RegExp(
      `no-photo bare-temple https://storage\\.googleapis\\.com/${locked}/temples/bare-temple/01\\.jpg`,
    ),
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
  assert.equal(
    wikimediaOriginalUrl(
      "https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Example.svg/480px-Example.svg.png",
    ),
    "https://upload.wikimedia.org/wikipedia/commons/8/84/Example.svg",
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
  assert.equal(uploads[0].bucket, STORAGE_AUTH_BUCKET);
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
      assert.equal(file.bucket, STORAGE_AUTH_BUCKET);
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
  const lines = [];
  let code = null;
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: emulator,
        log: (line) => lines.push(line),
        exit: (status) => {
          code = status;
        },
        attempts: 1,
        backoffMs: 0,
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
    /APPLY-INCOMPLETE/,
  );
  assert.equal(code, 1);
  const text = lines.join("\n");
  assert.match(text, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
  assert.match(text, /failed b-temple/);
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
  const source = `https://storage.googleapis.com/${STORAGE_AUTH_BUCKET}/temples/kept-temple/01.jpg`;
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

test("apply records an empty encoder as failed and does not upload", async () => {
  const uploads = [];
  const rows = await applyCoverThumbPlans([planCoverThumb(shore())], {
    dryRun: false,
    attempts: 1,
    backoffMs: 0,
    stat: async (path) =>
      path.endsWith("/01.jpg") ? { generation: "3", updated: "2024-01-01T00:00:00.000Z" } : null,
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.alloc(0),
    upload: async (file) => {
      uploads.push(file);
      return { url: "https://example.com/t" };
    },
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows[0].result, "failed");
  assert.match(rows[0].reason, /empty thumb/);
});

test("source updated time decides a stale thumb", () => {
  assert.equal(sourceIsNewer("2024-02-01T00:00:00.000Z", "2024-01-01T00:00:00.000Z"), true);
  assert.equal(sourceIsNewer("2024-01-01T00:00:00.000Z", "2024-02-01T00:00:00.000Z"), false);
  assert.equal(sourceIsNewer(undefined, "2024-01-01T00:00:00.000Z"), false);
});

test("resume re-processes a temple whose cover changed", async () => {
  const same = shore("same-cover");
  const previous = shore("moved-cover");
  const next = `https://storage.googleapis.com/${STORAGE_AUTH_BUCKET}/temples/moved-cover/02.jpg`;
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

test("apply stops before a thumb write when the Storage preflight fails", async () => {
  let loads = 0;
  let uploads = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: emulator,
        storagePreflight: async () => {
          throw new Error("Storage auth preflight failed. No Firestore write.");
        },
        load: async () => {
          loads += 1;
          return [];
        },
        stat: async () => {
          throw new Error("stat");
        },
        upload: async () => {
          uploads += 1;
          return { url: "https://example.invalid/thumb" };
        },
      }),
    /Storage auth preflight failed\. No Firestore write\./,
  );
  assert.equal(loads, 0);
  assert.equal(uploads, 0);
});

test("encodeWithSharp writes a 480-wide jpeg and does not enlarge a smaller frame", async () => {
  const sharp = (await import("sharp")).default;
  const wide = await sharp({
    create: {
      width: 960,
      height: 640,
      channels: 3,
      background: { r: 18, g: 72, b: 140 },
    },
  })
    .jpeg()
    .toBuffer();
  const thumb = await encodeWithSharp(wide);
  assert.equal(thumb[0], 0xff);
  assert.equal(thumb[1], 0xd8);
  const wideMeta = await sharp(thumb).metadata();
  assert.equal(wideMeta.format, "jpeg");
  assert.equal(wideMeta.width, THUMB_EDGE);
  assert.equal(wideMeta.height, 320);

  const small = await sharp({
    create: {
      width: 120,
      height: 80,
      channels: 3,
      background: { r: 200, g: 30, b: 30 },
    },
  })
    .png()
    .toBuffer();
  const smallThumb = await encodeWithSharp(small);
  const smallMeta = await sharp(smallThumb).metadata();
  assert.equal(smallMeta.format, "jpeg");
  assert.equal(smallMeta.width, 120);
  assert.equal(smallMeta.height, 80);

  const encodedUploads = [];
  const plan = planCoverThumb(shore("encode-temple"));
  assert.equal(plan.action, "upload");
  const rows = await applyCoverThumbPlans([plan], {
    dryRun: true,
    stat: async (path) =>
      path.endsWith("/01.jpg")
        ? { generation: "7", updated: "2024-01-01T00:00:00.000Z" }
        : null,
    download: async () => {
      throw new Error("dry-run must not download");
    },
    encode: async () => {
      throw new Error("dry-run must not encode");
    },
    upload: async () => {
      throw new Error("dry-run must not upload");
    },
  });
  assert.equal(rows[0].result, "would-upload");
  assert.equal(rows[0].thumbPath, "temples/encode-temple/01_480_g7.jpg");

  const applied = await applyCoverThumbPlans([plan], {
    dryRun: false,
    stat: async (path) =>
      path.endsWith("/01.jpg")
        ? { generation: "7", updated: "2024-01-01T00:00:00.000Z" }
        : null,
    download: async () => wide,
    encode: encodeWithSharp,
    upload: async (file) => {
      encodedUploads.push(file);
      return {
        url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
      };
    },
    verifyPublic: async () => true,
    writeThumbUrl: async () => ({ ok: true }),
  });
  assert.equal(encodedUploads.length, 1);
  assert.equal(encodedUploads[0].bytes[0], 0xff);
  assert.equal(encodedUploads[0].bytes[1], 0xd8);
  const uploaded = await sharp(encodedUploads[0].bytes).metadata();
  assert.equal(uploaded.format, "jpeg");
  assert.equal(uploaded.width, THUMB_EDGE);
  assert.equal(applied[0].result, "uploaded");
  assert.equal(applied[0].thumbPath, "temples/encode-temple/01_480_g7.jpg");
});

test("encodeWithSharp keeps a portrait frame portrait at 480 wide", async () => {
  const sharp = (await import("sharp")).default;
  const portrait = await sharp({
    create: {
      width: 800,
      height: 1600,
      channels: 3,
      background: { r: 40, g: 90, b: 30 },
    },
  })
    .jpeg()
    .toBuffer();
  const thumb = await encodeWithSharp(portrait);
  const meta = await sharp(thumb).metadata();
  assert.equal(meta.format, "jpeg");
  assert.equal(meta.width, THUMB_EDGE);
  assert.equal(meta.height, 960);
  assert.equal(meta.height > meta.width, true);
});

test("encodeWithSharp shrinks a generated 6000x4000 source to a 480-wide jpeg", async () => {
  const sharp = (await import("sharp")).default;
  const huge = await sharp({
    create: {
      width: 6000,
      height: 4000,
      channels: 3,
      background: { r: 12, g: 24, b: 48 },
    },
  })
    .jpeg()
    .toBuffer();
  const thumb = await encodeWithSharp(huge);
  assert.equal(thumb[0], 0xff);
  assert.equal(thumb[1], 0xd8);
  const meta = await sharp(thumb).metadata();
  assert.equal(meta.format, "jpeg");
  assert.equal(meta.width, THUMB_EDGE);
  assert.equal(meta.height, 320);
  assert.equal(thumb.length < huge.length, true);
});

test("another bucket is skipped and logged, and --apply refuses --bucket", async () => {
  const foreign =
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.appspot.com/o/temples%2Fother-temple%2F01.jpg?alt=media&token=abc";
  const temple = {
    id: "other-temple",
    images: [foreign],
    photos: [{ url: foreign, licence: "CC0", credit: "", order: 0 }],
  };
  const planned = planCoverThumb(temple);
  assert.equal(planned.action, "skip");
  assert.equal(planned.reason, "other-bucket");
  assert.equal(planned.bucket, "temple-directory-india.appspot.com");

  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: emulator,
    log: (line) => lines.push(line),
    load: async () => [temple],
    stat: async () => {
      throw new Error("other-bucket must not be stated");
    },
    download: async () => {
      throw new Error("other-bucket must not be downloaded");
    },
    upload: async () => {
      throw new Error("other-bucket must not be uploaded");
    },
  });
  assert.equal(rows[0].reason, "other-bucket");
  assert.match(lines.join("\n"), /skip other-temple other-bucket/);

  const calls = [];
  const forged = await applyCoverThumbPlans(
    [
      {
        id: "forged",
        action: "upload",
        source: foreign,
        objectPath: "temples/other-temple/01.jpg",
        bucket: "other.appspot.com",
        temple: {
          id: "forged",
          images: [foreign],
          photos: [{ url: foreign, licence: "CC0", order: 0 }],
        },
      },
    ],
    {
      dryRun: false,
      stat: async () => {
        calls.push("stat");
        throw new Error("stat");
      },
      download: async () => {
        calls.push("download");
        throw new Error("download");
      },
      upload: async () => {
        calls.push("upload");
        throw new Error("upload");
      },
    },
  );
  assert.deepEqual(calls, []);
  assert.equal(forged[0].reason, "other-bucket");

  let confirmed = 0;
  let loads = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--bucket", "other.appspot.com", "--project", "demo-temple-index"], {
        env: emulator,
        confirm: async () => {
          confirmed += 1;
          return "demo-temple-index";
        },
        load: async () => {
          loads += 1;
          return [];
        },
        stat: async () => {
          throw new Error("refused apply must not stat");
        },
      }),
    /Refusing --bucket other\.appspot\.com\. --apply writes only temple-directory-india\.firebasestorage\.app/,
  );
  assert.equal(confirmed, 0);
  assert.equal(loads, 0);

  const dry = await main(["--bucket", "other.appspot.com", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    load: async () => [shore()],
    stat: async (path) =>
      path.endsWith("/01.jpg") ? { generation: "1", updated: "2024-01-01T00:00:00.000Z" } : null,
  });
  assert.equal(dry.find((row) => row.id === "shore-temple").result, "would-upload");
  assert.equal(dry.find((row) => row.id === "shore-temple").bucket, STORAGE_AUTH_BUCKET);
});

function fastNet(extra = {}) {
  return { attempts: 1, backoffMs: 0, timeoutMs: 60, ...extra };
}

test("cover resize guards a hung fetch, a rejected upload, and a full success", async () => {
  const source = readFileSync(resolve(here, "resize_cover_thumbs.js"), "utf8");
  assert.match(source, /unhandledRejection/);
  assert.match(source, /uncaughtException/);
  assert.match(source, /--timeout-ms/);
  assert.equal(parseArgs(["--timeout-ms", "2500"]).timeoutMs, 2500);

  const hangLines = [];
  let hangCode = null;
  let fetches = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--timeout-ms", "40", "--project", "demo-temple-index"], {
        env: emulator,
        ...fastNet({ attempts: 2, timeoutMs: 5_000 }),
        log: (line) => hangLines.push(line),
        exit: (status) => {
          hangCode = status;
        },
        load: async () => [shore("hang-temple")],
        stat: async (path) => (path.includes("_480") ? null : { generation: "3", updated: "2024-01-01T00:00:00.000Z" }),
        download: async () => Buffer.from("full"),
        encode: async () => Buffer.from("thumb"),
        upload: async (file) => ({
          url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
        }),
        verifyPublic: (_url, options) =>
          new Promise((_resolve, reject) => {
            fetches += 1;
            assert.equal(options?.signal instanceof AbortSignal, true);
            options.signal.addEventListener("abort", () => {
              reject(Object.assign(new Error("aborted"), { name: "AbortError" }));
            });
          }),
        writeThumbUrl: async () => {
          throw new Error("a timed-out fetch must not write thumbUrl");
        },
      }),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(hangCode, 1);
  assert.equal(fetches, 2);
  const hangText = hangLines.join("\n");
  assert.match(hangText, /batch 1\/1 temples 1 covers written 0 failed 1 skipped 0 so far/);
  assert.match(hangText, /summary written=0 failed=1 skipped=0 elapsed=/);
  assert.match(hangText, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(hangText, /APPLY-FINISHED/);

  const rejectLines = [];
  let rejectCode = null;
  let uploads = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: emulator,
        ...fastNet({ attempts: 2 }),
        log: (line) => rejectLines.push(line),
        exit: (status) => {
          rejectCode = status;
        },
        load: async () => [shore("reject-temple")],
        stat: async (path) => (path.includes("_480") ? null : { generation: "3", updated: "2024-01-01T00:00:00.000Z" }),
        download: async () => Buffer.from("full"),
        encode: async () => Buffer.from("thumb"),
        upload: async () => {
          uploads += 1;
          throw new Error("upload rejected");
        },
        verifyPublic: async () => true,
        writeThumbUrl: async () => {
          throw new Error("a rejected upload must not write thumbUrl");
        },
      }),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(rejectCode, 1);
  assert.equal(uploads, 2);
  const rejectText = rejectLines.join("\n");
  assert.match(rejectText, /summary written=0 failed=1 skipped=0 elapsed=/);
  assert.match(rejectText, /APPLY-INCOMPLETE/);
  assert.match(rejectText, /upload rejected/);
  assert.doesNotMatch(rejectText, /APPLY-FINISHED/);

  const okLines = [];
  let okCode = null;
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet(),
    batchSize: 1,
    log: (line) => okLines.push(line),
    exit: (status) => {
      okCode = status;
    },
    load: async () => [shore("ok-temple"), shore("skip-temple")],
    stat: async (path) => (path.includes("_480") ? null : { generation: "8", updated: "2024-01-01T00:00:00.000Z" }),
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: async (file) => ({
      url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
    }),
    verifyPublic: async () => true,
    writeThumbUrl: async () => ({ ok: true }),
    writeResume: () => {},
  });
  assert.equal(okCode, 0);
  assert.equal(rows.filter((row) => row.result === "uploaded").length, 2);
  const okText = okLines.join("\n");
  assert.match(okText, /batch 1\/2 temples 1 covers written 1 failed 0 skipped 0 so far/);
  assert.match(okText, /batch 2\/2 temples 1 covers written 2 failed 0 skipped 0 so far/);
  assert.match(okText, /summary written=2 failed=0 skipped=0 elapsed=/);
  assert.match(okText, /APPLY-FINISHED/);
  assert.doesNotMatch(okText, /APPLY-INCOMPLETE/);

  const resumeLines = [];
  const same = shore("same-cover");
  const resumed = await main(["--resume", "--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet(),
    log: (line) => resumeLines.push(line),
    readResume: () => saveResume("demo-temple-index", new Map([["same-cover", same.images[0]]])),
    load: async () => [same],
    stat: async () => {
      throw new Error("a resumed cover must not stat");
    },
  });
  assert.equal(resumed[0].reason, "resume");
  assert.match(resumeLines.join("\n"), /summary written=0 failed=0 skipped=1 \(resume=1\) elapsed=/);
  assert.match(resumeLines.join("\n"), /APPLY-FINISHED/);

  const guardSource = readFileSync(resolve(here, "resize_cover_thumbs.js"), "utf8");
  assert.match(guardSource, /process\.on\("beforeExit"/);
  assert.match(guardSource, /admin init/);
});

test("a stalled cover encode exits 1 and prints APPLY-INCOMPLETE", { timeout: 5_000 }, async () => {
  const lines = [];
  let code = null;
  let uploads = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--timeout-ms", "40", "--project", "demo-temple-index"], {
        env: emulator,
        ...fastNet({ attempts: 1 }),
        log: (line) => lines.push(line),
        exit: (status) => {
          code = status;
        },
        load: async () => [shore("encode-temple")],
        stat: async (path) =>
          path.includes("_480") ? null : { generation: "3", updated: "2024-01-01T00:00:00.000Z" },
        download: async () => Buffer.from("full"),
        encode: () => new Promise(() => {}),
        upload: async () => {
          uploads += 1;
          return {
            url: "https://firebasestorage.googleapis.com/v0/b/bucket/o/thumb?alt=media&token=real",
          };
        },
        verifyPublic: async () => true,
        writeThumbUrl: async () => {
          throw new Error("a stalled encode must not write thumbUrl");
        },
      }),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(code, 1);
  assert.equal(uploads, 0);
  const text = lines.join("\n");
  assert.match(text, /encode timed out/);
  assert.match(text, /summary written=0 failed=1 skipped=0 elapsed=/);
  assert.match(text, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
});

test("a stalled cover resume write exits 1 and prints APPLY-INCOMPLETE", { timeout: 5_000 }, async () => {
  const lines = [];
  let code = null;
  let writes = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--timeout-ms", "40", "--project", "demo-temple-index"], {
        env: emulator,
        ...fastNet({ attempts: 1 }),
        log: (line) => lines.push(line),
        exit: (status) => {
          code = status;
        },
        load: async () => [shore("resume-temple")],
        stat: async (path) =>
          path.includes("_480") ? null : { generation: "3", updated: "2024-01-01T00:00:00.000Z" },
        download: async () => Buffer.from("full"),
        encode: async () => Buffer.from("thumb"),
        upload: async (file) => ({
          url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(file.path)}?alt=media&token=real`,
        }),
        verifyPublic: async () => true,
        writeThumbUrl: async () => {
          writes += 1;
          return { ok: true };
        },
        writeResume: () => new Promise(() => {}),
      }),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(code, 1);
  assert.equal(writes, 1);
  const text = lines.join("\n");
  assert.match(text, /resume write timed out/);
  assert.match(text, /summary written=1 failed=1 skipped=0 elapsed=/);
  assert.match(text, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
});

test("a cover upload timeout that left the object counts as written", { timeout: 5_000 }, async () => {
  const lines = [];
  let code = null;
  const created = new Set();
  const rows = await main(["--apply", "--timeout-ms", "40", "--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet({ attempts: 1 }),
    log: (line) => lines.push(line),
    exit: (status) => {
      code = status;
    },
    load: async () => [shore("relink-temple")],
    stat: async (path) => {
      if (!path.includes("_480")) return { generation: "3", updated: "2024-01-01T00:00:00.000Z" };
      if (!created.has(path)) return null;
      return {
        generation: "9",
        updated: "2024-01-01T00:00:00.000Z",
        url: `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodeURIComponent(path)}?alt=media&token=real`,
      };
    },
    download: async () => Buffer.from("full"),
    encode: async () => Buffer.from("thumb"),
    upload: (file) => {
      created.add(file.path);
      return new Promise(() => {});
    },
    verifyPublic: async () => true,
    writeThumbUrl: async () => ({ ok: true }),
    writeResume: () => {},
  });
  assert.equal(code, 0);
  assert.equal(rows.filter((row) => row.result === "exists" && row.stored === true).length, 1);
  const text = lines.join("\n");
  assert.match(text, /summary written=1 failed=0 skipped=0 elapsed=/);
  assert.match(text, /APPLY-FINISHED/);
  assert.doesNotMatch(text, /APPLY-INCOMPLETE/);
});

test("cover skip reasons include no-source-generation as its own count", async () => {
  const lines = [];
  const other = shore("other-cover");
  other.images = ["https://storage.googleapis.com/other.appspot.com/temples/other-cover/01.jpg"];
  other.photos = [{ url: other.images[0], licence: "CC0", credit: "", order: 0 }];
  await main(["--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet(),
    log: (line) => lines.push(line),
    load: async () => [shore("empty-gen"), other],
    stat: async () => ({ generation: "", updated: "" }),
  });
  const text = lines.join("\n");
  assert.match(
    text,
    /summary written=0 failed=0 skipped=2 \(no-source-generation=1 other-bucket=1\) elapsed=/,
  );
  assert.match(text, /APPLY-FINISHED/);
});
