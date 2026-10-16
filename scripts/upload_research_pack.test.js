import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { coverFrameForPack } from "./backfill_cover_photos.js";
import { downloadTokenUrl } from "./download_token.js";
import {
  formatEmptyCoverReport,
  isEmptyCover,
  packDirForSlug,
  persistEmptyCover,
  photosFromFrames,
  planEmptyCoverPack,
  readPackList,
  runEmptyCoverPacks,
} from "./empty_cover_packs.js";
import { encodeWithSharp } from "./resize_cover_thumbs.js";
import { main as resizeMain } from "./resize_cover_thumbs.js";
import { main as rebuildMain } from "./rebuild_index.js";
import { assertStorageAuth, STORAGE_AUTH_LIST } from "./storage_auth.js";
import { emptyCoverMode, parseArgs } from "./upload_research_pack.js";

const bucket = "temple-directory-india.firebasestorage.app";
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };

function photo(filename, extra = {}) {
  return {
    filename,
    author: "Ada Lovelace",
    license: "CC BY 4.0",
    ...extra,
  };
}

function writePack(manifest, files = null) {
  const dir = mkdtempSync(join(tmpdir(), "empty-cover-"));
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "manifest.json"), JSON.stringify(manifest));
  const names = files ?? manifest.photos.map((item) => item.filename);
  for (const name of names) writeFileSync(join(dir, name), "frame");
  return dir;
}

function emptyTemple(id = "empty-shore") {
  return {
    id,
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    address: "Mahabalipuram",
    imageUrl: "",
    images: [],
    photos: [],
  };
}

function baseOpts(extra = {}) {
  return {
    apply: false,
    project: "demo-temple-index",
    bucket,
    only: new Set(),
    exclude: new Set(),
    docId: null,
    packDirs: [],
    ...extra,
  };
}

test("--patch-firestore is refused and empty-cover mode is dry-run until --apply", () => {
  assert.throws(
    () => parseArgs(["--patch-firestore", "--pack", "x"]),
    /Refusing --patch-firestore/,
  );
  const dry = parseArgs(["--packs-file", "slugs.txt", "--project", "temple-directory-india"]);
  assert.equal(dry.apply, false);
  assert.equal(emptyCoverMode(dry), true);
  const apply = parseArgs([
    "--apply",
    "--packs-file",
    "slugs.txt",
    "--only",
    "empty-shore,other",
    "--exclude",
    "kept-out",
    "--project",
    "temple-directory-india",
  ]);
  assert.equal(apply.apply, true);
  assert.equal(apply.dryRun, false);
  assert.deepEqual([...apply.only], ["empty-shore", "other"]);
  assert.equal(apply.exclude.has("kept-out"), true);
  assert.throws(() => parseArgs(["--exclude"]), /--exclude needs/);
  assert.equal(emptyCoverMode(parseArgs(["--exclude", "kept-out"])), true);
  assert.equal(emptyCoverMode(parseArgs(["--all-packs"])), false);
});

test("a pack list is slugs, and cover choice prefers cover:true over gallery frames", () => {
  assert.equal(packDirForSlug("virupaksha-temple").endsWith("virupaksha-temple"), true);
  const file = join(mkdtempSync(join(tmpdir(), "slugs-")), "slugs.txt");
  writeFileSync(file, "# comment\n\nvirupaksha-temple\nempty-shore\n");
  assert.deepEqual(readPackList(file), ["virupaksha-temple", "empty-shore"]);
  const chosen = coverFrameForPack({
    temple_slug: "empty-shore",
    photos: [
      photo("01_side.jpg", { gallery_only: true }),
      photo("02_front.jpg", { cover: true, license: "CC BY-SA 4.0" }),
    ],
  });
  assert.equal(chosen.filename, "02_front.jpg");
});

test("dry-run lists an empty cover and does not upload or write", async () => {
  const dir = writePack({
    temple_slug: "empty-shore",
    photos: [photo("01_side.jpg", { gallery_only: true }), photo("02_front.jpg", { cover: true })],
  });
  const uploads = [];
  const writes = [];
  const lines = [];
  try {
    const rows = await runEmptyCoverPacks(
      baseOpts({ packDirs: [dir] }),
      {
        env: emulator,
        log: (line) => lines.push(line),
        warn: () => {},
        load: async () => [emptyTemple()],
        uploadFrames: async () => {
          uploads.push("upload");
          return [];
        },
        write: async () => {
          writes.push("write");
          return { ok: true };
        },
        confirm: async () => {
          throw new Error("dry-run must not ask for the project id");
        },
        storagePreflight: async () => {
          throw new Error("dry-run must not list Storage");
        },
      },
    );
    assert.equal(uploads.length, 0);
    assert.equal(writes.length, 0);
    assert.equal(rows.find((row) => row.id === "empty-shore").result, "would-write");
    assert.equal(rows.find((row) => row.id === "empty-shore").coverFilename, "02_front.jpg");
    const covered = planEmptyCoverPack({
      temple: { ...emptyTemple(), imageUrl: "https://example.com/a.jpg", images: ["https://example.com/a.jpg"], photos: [{ url: "https://example.com/a.jpg", credit: "Ada", licence: "CC-BY", order: 0 }] },
      packDir: dir,
      manifest: JSON.parse(readFileSync(join(dir, "manifest.json"), "utf8")),
    });
    assert.equal(covered.reason, "has-cover");
    assert.match(lines.join("\n"), /Mode: dry-run/);
    assert.match(lines.join("\n"), /Dry-run only/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("apply confirms the project, aborts when the Storage list fails, and skips a filled cover", async () => {
  const dir = writePack({
    temple_slug: "empty-shore",
    photos: [photo("01_front.jpg")],
  });
  let loads = 0;
  let confirmed = 0;
  try {
    await assert.rejects(
      () =>
        runEmptyCoverPacks(baseOpts({ apply: true, project: "temple-directory-india", packDirs: [dir] }), {
          env: {},
          confirm: async (id) => {
            confirmed += 1;
            return id;
          },
          storagePreflight: async () => {
            throw new Error("Storage auth preflight failed. No Firestore write.");
          },
          load: async () => {
            loads += 1;
            return [];
          },
        }),
      /Storage auth preflight failed/,
    );
    assert.equal(confirmed, 1);
    assert.equal(loads, 0);

    const token = "secret-token-value";
    const lines = [];
    const warnings = [];
    const written = [];
    const rows = await runEmptyCoverPacks(
      baseOpts({
        apply: true,
        packDirs: [dir],
        exclude: new Set(["not-a-temple"]),
        only: new Set(["empty-shore", "also-missing"]),
      }),
      {
        env: emulator,
        log: (line) => lines.push(line),
        warn: (line) => warnings.push(line),
        storagePreflight: async () => {
          await assertStorageAuth({
            async getFiles(query) {
              assert.equal(query.prefix, STORAGE_AUTH_LIST.prefix);
              assert.equal(query.maxResults, 1);
              return [[]];
            },
          });
        },
        load: async () => [
          emptyTemple(),
          { ...emptyTemple("filled"), imageUrl: "https://example.com/cover.jpg", images: ["https://example.com/cover.jpg"], photos: [] },
        ],
        uploadFrames: async (plan) =>
          plan.frames.map((frame) => downloadTokenUrl(bucket, frame.objectPath, token)),
        verifyPublic: async (url) => url.includes(`token=${token}`),
        write: async (assigned) => {
          written.push(assigned);
          assert.equal(Object.hasOwn(assigned.photos[0], "thumbUrl"), false);
          assert.equal(assigned.photos[0].order, 0);
          assert.equal(assigned.photos[0].licence, "CC-BY");
          assert.match(assigned.photos[0].credit, /Ada Lovelace/);
          assert.equal(assigned.imageUrl, assigned.photos[0].url);
          assert.deepEqual(assigned.images, assigned.photos.map((photo) => photo.url));
          return { ok: true };
        },
      },
    );
    assert.equal(written.length, 1);
    assert.equal(written[0].id, "empty-shore");
    assert.equal(rows.find((row) => row.id === "filled"), undefined);
    assert.match(warnings.join("\n"), /exclude: unknown temple id not-a-temple/);
    assert.match(warnings.join("\n"), /only: unknown temple id also-missing/);
    assert.equal(lines.join("\n").includes(token), false);
    assert.match(lines.join("\n"), /Mode: apply/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("--apply refuses a bucket other than temple-directory-india.firebasestorage.app", async () => {
  let confirmed = 0;
  let loads = 0;
  await assert.rejects(
    () =>
      runEmptyCoverPacks(
        baseOpts({
          apply: true,
          bucket: "other-bucket.firebasestorage.app",
          project: "temple-directory-india",
          packDirs: ["/tmp/unused-pack"],
        }),
        {
          env: {},
          confirm: async () => {
            confirmed += 1;
            return "temple-directory-india";
          },
          load: async () => {
            loads += 1;
            return [];
          },
        },
      ),
    /Refusing --bucket other-bucket\.firebasestorage\.app/,
  );
  assert.equal(confirmed, 0);
  assert.equal(loads, 0);
});

test("a cover gained mid-run deletes objects this run uploaded", async () => {
  const dir = writePack({
    temple_slug: "empty-shore",
    photos: [photo("01_front.jpg")],
  });
  const token = "secret-token-value";
  const created = ["temples/empty-shore/01_front.jpg"];
  const lines = [];
  try {
    const deleted = [];
    const rows = await runEmptyCoverPacks(baseOpts({ apply: true, packDirs: [dir] }), {
      env: emulator,
      log: (line) => lines.push(line),
      warn: () => {},
      storagePreflight: async () => {},
      load: async () => [emptyTemple()],
      uploadFrames: async (plan) => ({
        urls: plan.frames.map((frame) => downloadTokenUrl(bucket, frame.objectPath, token)),
        created,
      }),
      verifyPublic: async () => true,
      write: async () => ({ ok: false, reason: "has-cover" }),
      deleteUploads: async (paths) => {
        deleted.push(...paths);
        return { failed: [] };
      },
    });
    assert.deepEqual(deleted, created);
    assert.equal(rows[0].reason, "has-cover");
    assert.match(lines.join("\n"), /deleted empty-shore temples\/empty-shore\/01_front\.jpg/);
    assert.equal(lines.join("\n").includes(token), false);

    const kept = [];
    const existing = await runEmptyCoverPacks(baseOpts({ apply: true, packDirs: [dir] }), {
      env: emulator,
      log: () => {},
      warn: () => {},
      storagePreflight: async () => {},
      load: async () => [emptyTemple()],
      uploadFrames: async (plan) => plan.frames.map((frame) => downloadTokenUrl(bucket, frame.objectPath, token)),
      verifyPublic: async () => true,
      write: async () => ({ ok: false, reason: "has-cover" }),
      deleteUploads: async (paths) => {
        kept.push(...paths);
        return { failed: [] };
      },
    });
    assert.deepEqual(kept, []);
    assert.equal(existing[0].reason, "has-cover");

    const failed = [];
    const orphanLines = [];
    const orphaned = await runEmptyCoverPacks(baseOpts({ apply: true, packDirs: [dir] }), {
      env: emulator,
      log: (line) => orphanLines.push(line),
      warn: () => {},
      storagePreflight: async () => {},
      load: async () => [emptyTemple()],
      uploadFrames: async () => ({
        urls: [downloadTokenUrl(bucket, created[0], token)],
        created,
      }),
      verifyPublic: async () => true,
      write: async () => ({ ok: false, reason: "has-cover" }),
      deleteUploads: async (paths) => {
        failed.push(...paths);
        return {
          failed: paths.map((path) => ({
            path,
            error: new Error(
              `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/x?alt=media&token=${token} denied`,
            ),
          })),
        };
      },
    });
    assert.deepEqual(failed, created);
    assert.deepEqual(orphaned[0].orphaned, created);
    assert.match(orphanLines.join("\n"), /orphaned empty-shore temples\/empty-shore\/01_front\.jpg/);
    assert.equal(orphanLines.join("\n").includes(token), false);
    assert.match(orphanLines.join("\n"), /token=<redacted>/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("a token URL that is not HTTP 200 is not written", async () => {
  const dir = writePack({
    temple_slug: "empty-shore",
    photos: [photo("01_front.jpg")],
  });
  const token = "secret-token-value";
  const lines = [];
  let writes = 0;
  try {
    const rows = await runEmptyCoverPacks(baseOpts({ apply: true, packDirs: [dir] }), {
      env: emulator,
      log: (line) => lines.push(line),
      warn: () => {},
      storagePreflight: async () => {},
      load: async () => [emptyTemple()],
      uploadFrames: async (plan) => plan.frames.map((frame) => downloadTokenUrl(bucket, frame.objectPath, token)),
      verifyPublic: async () => false,
      write: async () => {
        writes += 1;
        return { ok: true };
      },
    });
    assert.equal(writes, 0);
    assert.equal(rows[0].reason, "not-public");
    assert.equal(lines.join("\n").includes(token), false);
    assert.match(lines.join("\n"), /not-public empty-shore/);
    assert.match(lines.join("\n"), /token=<redacted>/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("the transaction writes only an empty cover and leaves thumbUrl unset", async () => {
  const frames = [
    { filename: "02_front.jpg", credit: "Ada Lovelace · CC BY 4.0", licence: "CC-BY", objectPath: "temples/empty-shore/02_front.jpg" },
    { filename: "01_side.jpg", credit: "Ada Lovelace · CC BY 4.0", licence: "CC-BY", objectPath: "temples/empty-shore/01_side.jpg" },
  ];
  const photos = photosFromFrames(frames, [
    downloadTokenUrl(bucket, frames[0].objectPath, "tok"),
    downloadTokenUrl(bucket, frames[1].objectPath, "tok"),
  ]);
  assert.equal(photos[0].order, 0);
  assert.equal(Object.hasOwn(photos[0], "thumbUrl"), false);
  const state = { imageUrl: "", images: [], photos: [] };
  const updates = [];
  const db = {
    collection() {
      return { doc: () => ({}) };
    },
    async runTransaction(fn) {
      const writes = [];
      const result = await fn({
        get: async () => ({ exists: true, id: "empty-shore", data: () => ({ ...state }) }),
        update: (_ref, patch) => writes.push(patch),
      });
      updates.push(writes);
      if (result?.ok) Object.assign(state, writes[0]);
      return result;
    },
  };
  const first = await persistEmptyCover(db, {
    id: "empty-shore",
    imageUrl: photos[0].url,
    images: photos.map((item) => item.url),
    photos,
  });
  assert.equal(first.ok, true);
  assert.deepEqual(Object.keys(updates[0][0]).sort(), ["imageUrl", "images", "photos"]);
  assert.equal(state.photos[0].thumbUrl, undefined);
  const second = await persistEmptyCover(db, {
    id: "empty-shore",
    imageUrl: photos[0].url,
    images: photos.map((item) => item.url),
    photos,
  });
  assert.equal(second.reason, "has-cover");
  assert.equal(updates[1].length, 0);
  assert.equal(isEmptyCover({ imageUrl: "", images: [], photos: [] }), true);
  assert.equal(isEmptyCover({ imageUrl: "https://example.com/a.jpg", images: [], photos: [] }), false);
  assert.match(formatEmptyCoverReport([{ id: "empty-shore", action: "write", result: "would-write", coverFilename: "02_front.jpg", frames }], { apply: false }), /would-write empty-shore/);
});

test("two marked covers fail, and gallery_only is never the cover", () => {
  const dir = writePack({
    temple_slug: "two-covers",
    photos: [photo("01_a.jpg", { cover: true }), photo("02_b.jpg", { cover_ok: true })],
  });
  try {
    assert.throws(
      () =>
        planEmptyCoverPack({
          temple: emptyTemple("two-covers"),
          packDir: dir,
          manifest: JSON.parse(readFileSync(join(dir, "manifest.json"), "utf8")),
        }),
      /two-covers has 2 cover photos/,
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  const gallery = writePack({
    temple_slug: "gallery",
    photos: [photo("01_a.jpg", { gallery_only: true, cover: true })],
  });
  try {
    assert.throws(
      () =>
        planEmptyCoverPack({
          temple: emptyTemple("gallery"),
          packDir: gallery,
          manifest: JSON.parse(readFileSync(join(gallery, "manifest.json"), "utf8")),
        }),
      /gallery_only/,
    );
  } finally {
    rmSync(gallery, { recursive: true, force: true });
  }
  const blocked = writePack({
    temple_slug: "blocked",
    no_cover_frame: true,
    photos: [photo("01_a.jpg")],
  });
  try {
    const plan = planEmptyCoverPack({
      temple: emptyTemple("blocked"),
      packDir: blocked,
      manifest: JSON.parse(readFileSync(join(blocked, "manifest.json"), "utf8")),
    });
    assert.equal(plan.reason, "no-cover-frame");
  } finally {
    rmSync(blocked, { recursive: true, force: true });
  }
});

test("empty cover pack apply then resize then rebuild has no drift", { skip: !process.env.FIRESTORE_EMULATOR_HOST }, async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? "";
  assert.match(host, /^(127\.0\.0\.1|localhost):\d+$/);
  const project = "demo-empty-cover";
  assert.equal(project.startsWith("demo-"), true);
  const sharp = (await import("sharp")).default;
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: project, storageBucket: bucket });
  }
  const jpeg = await sharp({
    create: { width: 32, height: 24, channels: 3, background: { r: 20, g: 80, b: 140 } },
  })
    .jpeg()
    .toBuffer();
  const dir = mkdtempSync(join(tmpdir(), "emu-pack-"));
  try {
    writeFileSync(join(dir, "01_side.jpg"), jpeg);
    writeFileSync(join(dir, "02_front.jpg"), jpeg);
    writeFileSync(
      join(dir, "manifest.json"),
      JSON.stringify({
        temple_slug: "empty-shore",
        photos: [
          photo("01_side.jpg", { gallery_only: true }),
          photo("02_front.jpg", { cover: true, license: "CC BY-SA 4.0" }),
        ],
      }),
    );
    const db = admin.firestore();
    await db.collection("temples").doc("empty-shore").set({
      ...emptyTemple("empty-shore"),
      description: "Stone shore temple.",
      story: "Built on the coast.",
      timings: "6 am to 6 pm",
      specialities: [],
      latitude: 12.6,
      longitude: 80.2,
    });
    const objects = new Map();
    const token = "emu-cover-token";
    const rows = await runEmptyCoverPacks(
      baseOpts({ apply: true, project, packDirs: [dir] }),
      {
        env: process.env,
        storagePreflight: async () => {
          await assertStorageAuth({
            async getFiles(query) {
              assert.equal(query.prefix, "temples/");
              return [[]];
            },
          });
        },
        uploadFrames: async (plan) =>
          plan.frames.map((frame) => {
            objects.set(frame.objectPath, readFileSync(frame.localPath));
            return downloadTokenUrl(bucket, frame.objectPath, token);
          }),
        verifyPublic: async (url) => url.includes(`token=${token}`),
      },
    );
    assert.equal(rows.find((row) => row.id === "empty-shore").result, "wrote");
    const saved = (await db.collection("temples").doc("empty-shore").get()).data();
    assert.equal(saved.photos[0].filename, undefined);
    assert.equal(Object.hasOwn(saved.photos[0], "thumbUrl"), false);
    assert.equal(saved.photos[0].order, 0);
    assert.equal(saved.photos[1].order, 1);
    assert.equal(saved.imageUrl, saved.photos[0].url);
    assert.deepEqual(saved.images, saved.photos.map((item) => item.url));
    assert.match(saved.imageUrl, /02_front\.jpg/);
    assert.equal(saved.photos[0].licence, "CC-BY-SA");
    const thumbToken = "emu-thumb-token";
    await resizeMain(["--apply", "--project", project], {
      env: process.env,
      stat: async (path) =>
        objects.has(path) ? { generation: "3", updated: "2024-01-01T00:00:00.000Z" } : null,
      download: async (path) => objects.get(path),
      encode: encodeWithSharp,
      upload: async (file) => {
        objects.set(file.path, file.bytes);
        return { url: downloadTokenUrl(bucket, file.path, thumbToken) };
      },
      verifyPublic: async () => true,
    });
    const resized = (await db.collection("temples").doc("empty-shore").get()).data();
    assert.match(resized.photos[0].thumbUrl, /token=/);
    assert.equal(resized.photos[1].thumbUrl, undefined);
    const report = await rebuildMain(["--project", project], { env: process.env, log: () => {} });
    assert.equal(report.drifted.length, 0);
    assert.equal(report.missing.length, 0);
    assert.equal(report.unchanged >= 1, true);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
