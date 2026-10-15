import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { coverThumb, fullCoverUrlFromThumb, thumbObjectPath } from "./temple_index.js";
import {
  THUMB_CACHE_CONTROL,
  applyCoverThumbPlans,
  applyLimitAndResume,
  authorizeApply,
  formatThumbReport,
  main,
  parseArgs,
  planCoverThumb,
  publicObjectUrl,
  sourceIsNewer,
  staysFullSizeWikimedia,
  thumbSaveOptions,
  withCoverThumbUrl,
} from "./resize_cover_thumbs.js";

const here = dirname(fileURLToPath(import.meta.url));
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };

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
  assert.equal(
    fullCoverUrlFromThumb("https://storage.googleapis.com/bucket/temples/shore/01_480.jpg"),
    "https://storage.googleapis.com/bucket/temples/shore/01.jpg",
  );
});

test("apply stores the download URL and does not skip a stale thumb", async () => {
  const uploads = [];
  const writes = [];
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    confirm: async () => {
      throw new Error("emulator apply must not prompt");
    },
    writeResume: () => {},
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
  assert.equal(
    verified.verified,
    publicObjectUrl("bucket", "temples/new-temple/01_480_g42.jpg"),
  );
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
      return { url: "https://example.com/t?token=1" };
    },
    verifyPublic: async (url) => {
      assert.equal(url, publicObjectUrl("bucket", "temples/shore-temple/01_480_g3.jpg"));
      return false;
    },
    writeThumbUrl: async (assigned) => {
      writes.push(assigned);
    },
  });
  assert.equal(writes.length, 0);
  assert.equal(rows[0].result, "not-public");
  assert.match(formatThumbReport(rows, { apply: true }), /not-public shore-temple/);
});

test("a missing photo does not invent thumbUrl", () => {
  const temple = shore();
  delete temple.photos;
  const assigned = withCoverThumbUrl(temple, "https://example.com/thumb.jpg");
  assert.equal(assigned.ok, false);
  assert.equal(assigned.reason, "no-photo");
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
