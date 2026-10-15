import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { coverThumb } from "./temple_index.js";
import {
  THUMB_CACHE_CONTROL,
  applyCoverThumbPlans,
  authorizeApply,
  main,
  parseArgs,
  planCoverThumb,
} from "./resize_cover_thumbs.js";

const here = dirname(fileURLToPath(import.meta.url));

test("cover thumb fixture matches the Dart writer", () => {
  const cases = JSON.parse(
    readFileSync(resolve(here, "fixtures/cover_thumb_cases.json"), "utf8"),
  );
  for (const row of cases) {
    assert.equal(coverThumb(row.data), row.expect, row.name);
  }
});

test("a storage cover plans a _480 object and a wikimedia cover does not", () => {
  const storage = planCoverThumb({
    id: "shore-temple",
    images: ["https://storage.googleapis.com/bucket/temples/shore-temple/01.jpg"],
  });
  assert.equal(storage.action, "upload");
  assert.equal(storage.thumbPath, "temples/shore-temple/01_480.jpg");
  assert.equal(storage.cacheControl, THUMB_CACHE_CONTROL);
  assert.equal(storage.contentType, "image/jpeg");
  assert.equal(
    storage.thumbUrl,
    "https://storage.googleapis.com/bucket/temples/shore-temple/01_480.jpg",
  );

  const wiki = planCoverThumb({
    id: "meenakshi",
    imageUrl:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg",
  });
  assert.equal(wiki.action, "skip");
  assert.equal(wiki.reason, "not-storage");
});

test("dry-run lists a missing thumb and does not upload", async () => {
  const uploads = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: () => {},
    load: async () => [
      {
        id: "shore-temple",
        images: ["https://storage.googleapis.com/bucket/temples/shore-temple/01.jpg"],
      },
      {
        id: "wiki",
        imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg",
      },
    ],
    exists: async () => false,
    upload: async (file) => {
      uploads.push(file);
    },
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows.find((row) => row.id === "shore-temple").result, "would-upload");
  assert.equal(rows.find((row) => row.id === "wiki").result, "skipped");
  assert.equal(rows.find((row) => row.id === "wiki").reason, "not-storage");
});

test("apply uploads one missing thumb and skips one that already exists", async () => {
  const uploads = [];
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: () => {},
    confirm: async () => {
      throw new Error("emulator apply must not prompt");
    },
    load: async () => [
      {
        id: "new-temple",
        images: ["https://storage.googleapis.com/bucket/temples/new-temple/01.jpg"],
      },
      {
        id: "old-temple",
        images: ["https://storage.googleapis.com/bucket/temples/old-temple/01.jpg"],
      },
    ],
    exists: async (path) => path.startsWith("temples/old-temple/"),
    download: async () => Buffer.from("full-size"),
    encode: async (_bytes, ext) => Buffer.from(`thumb-${ext}`),
    upload: async (file) => {
      uploads.push(file);
    },
  });
  assert.equal(uploads.length, 1);
  assert.equal(uploads[0].path, "temples/new-temple/01_480.jpg");
  assert.equal(uploads[0].cacheControl, THUMB_CACHE_CONTROL);
  assert.equal(uploads[0].contentType, "image/jpeg");
  assert.equal(uploads[0].bytes.toString(), "thumb-jpg");
  assert.equal(rows.find((row) => row.id === "old-temple").result, "exists");
  assert.equal(rows.find((row) => row.id === "new-temple").result, "uploaded");
});

test("apply refuses CI and does not upload", async () => {
  const uploads = [];
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: { CI: "true", FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
        log: () => {},
        load: async () => {
          throw new Error("load should not run");
        },
        exists: async () => false,
        upload: async (file) => {
          uploads.push(file);
        },
      }),
    /CI/,
  );
  assert.equal(uploads.length, 0);
});

test("prod apply without a project is refused", async () => {
  assert.throws(() => parseArgs(["--apply", "--nope"]), /Unknown argument/);
  await assert.rejects(
    () => authorizeApply("", { FIRESTORE_EMULATOR_HOST: "" }),
    /project/,
  );
});

test("the script does not write Firestore", () => {
  const source = readFileSync(resolve(here, "resize_cover_thumbs.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.match(source, /THUMB_CACHE_CONTROL/);
  assert.doesNotMatch(source, /collection\("temples"\)[\s\S]{0,80}\.(set|update|create)\(/);
  assert.doesNotMatch(source, /batch\.(set|update|commit)/);
  assert.doesNotMatch(source, /firebase deploy/);
});

test("apply stops before upload when the encoder returns nothing", async () => {
  const uploads = [];
  await assert.rejects(
    () =>
      applyCoverThumbPlans(
        [
          planCoverThumb({
            id: "shore",
            images: ["https://storage.googleapis.com/bucket/temples/shore/01.jpg"],
          }),
        ],
        {
          dryRun: false,
          exists: async () => false,
          download: async () => Buffer.from("full"),
          encode: async () => Buffer.alloc(0),
          upload: async (file) => {
            uploads.push(file);
          },
        },
      ),
    /empty thumb/,
  );
  assert.equal(uploads.length, 0);
});
