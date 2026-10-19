import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { photosFromFrames } from "./empty_cover_packs.js";
import { downloadTokenUrl } from "./download_token.js";
import { main as rebuildMain } from "./rebuild_index.js";
import {
  GALLERY_JPEG_QUALITY,
  GALLERY_TARGET_BYTES,
  THUMB_EDGE,
  encodeGalleryJpeg,
} from "./resize_cover_thumbs.js";
import {
  applyGalleryPlans,
  applyLimitAndResume,
  assignGalleryUrls,
  authorizeApply,
  formatGalleryReport,
  loadResume,
  main,
  parseArgs,
  persistGalleryUrls,
  planGalleryPhotos,
  saveResume,
} from "./resize_gallery_images.js";
import { STORAGE_AUTH_BUCKET } from "./storage_auth.js";
import { coverThumb, entryFromTemple, galleryObjectPath } from "./temple_index.js";

const here = dirname(fileURLToPath(import.meta.url));
const bucket = STORAGE_AUTH_BUCKET;
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };

function tokenUrl(objectPath, token = "real") {
  return downloadTokenUrl(bucket, objectPath, token);
}

function shore(id = "shore-temple") {
  const source = `https://storage.googleapis.com/${bucket}/temples/${id}/01.jpg`;
  const side = `https://storage.googleapis.com/${bucket}/temples/${id}/02.jpg`;
  return {
    id,
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    address: "Mahabalipuram",
    images: [source, side],
    photos: [
      { url: source, licence: "CC0", credit: "", order: 0, thumbUrl: `https://cdn.example/${id}/01_480.jpg` },
      { url: side, licence: "CC0", credit: "", order: 1 },
    ],
  };
}

test("gallery object names are versioned and thumbs stay 480", () => {
  assert.equal(THUMB_EDGE, 480);
  assert.equal(galleryObjectPath("temples/shore/01.jpg", "42"), "temples/shore/01_1080_g42.jpg");
  assert.equal(
    galleryObjectPath("temples/shore/hero.PNG", "9"),
    "temples/shore/hero_1080_g9_PNG.jpg",
  );
  assert.equal(galleryObjectPath("temples/shore/01_480_g3.jpg", "1"), null);
  assert.equal(galleryObjectPath("temples/shore/01_1080_g3.jpg", "1"), null);
  assert.equal(galleryObjectPath("temples/shore/01_1080_g3u9.jpg", "1"), null);
  assert.equal(galleryObjectPath("temples/shore/01.jpg", "abc"), null);
});

test("galleryUrl does not change the browse cover or the index entry", () => {
  const url = "https://storage.googleapis.com/bucket/temples/shore-temple/01.jpg";
  const thumb = "https://cdn.example/photos/shore_480.jpg";
  const gallery = tokenUrl("temples/shore-temple/01_1080_g3.jpg", "gallery");
  const base = {
    id: "shore-temple",
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    address: "Mahabalipuram",
    images: [url],
    photos: [{ url, thumbUrl: thumb, licence: "CC0", credit: "", order: 0 }],
  };
  const withGallery = {
    ...base,
    photos: [{ ...base.photos[0], galleryUrl: gallery }],
  };
  assert.equal(coverThumb(withGallery), coverThumb(base));
  assert.equal(coverThumb(withGallery), thumb);
  assert.deepEqual(entryFromTemple(withGallery), entryFromTemple(base));
});

test("every storage photo without galleryUrl is planned, and an existing one is not", () => {
  const temple = shore();
  const wiki = "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg";
  temple.photos.push({ url: wiki, licence: "CC0", credit: "", order: 2 });
  temple.photos[0].galleryUrl = tokenUrl("temples/shore-temple/01_1080_g1.jpg");
  const plans = planGalleryPhotos([temple]);
  assert.equal(plans[0].reason, "has-gallery");
  assert.equal(plans[1].action, "upload");
  assert.equal(plans[1].objectPath, "temples/shore-temple/02.jpg");
  assert.equal(plans[2].reason, "wikimedia-full");
  assert.equal(plans.filter((plan) => plan.action === "upload").length, 1);
});

test("dry-run lists the versioned path and does not download", async () => {
  const rows = await main(["--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    load: async () => [shore()],
    stat: async (path) =>
      path.endsWith("/01.jpg") || path.endsWith("/02.jpg")
        ? { generation: "3", updated: "2024-01-01T00:00:00.000Z" }
        : null,
    download: async () => {
      throw new Error("dry-run must not download");
    },
  });
  assert.deepEqual(
    rows.filter((row) => row.result === "would-upload").map((row) => row.galleryPath),
    ["temples/shore-temple/01_1080_g3.jpg", "temples/shore-temple/02_1080_g3.jpg"],
  );
});

test("apply uploads once with ifGenerationMatch 0 and a re-run does not stat", async () => {
  let temple = shore();
  const uploads = [];
  const sourceBytes = Buffer.alloc(4000, 7);
  async function run(phase) {
    const plans = planGalleryPhotos([temple]);
    return applyGalleryPlans(plans, {
      dryRun: false,
      stat: async (path) => {
        if (phase === "second") throw new Error(`re-run must not stat ${path}`);
        if (path.endsWith("/01.jpg") || path.endsWith("/02.jpg")) {
          return { generation: "8", updated: "2024-01-01T00:00:00.000Z" };
        }
        return null;
      },
      download: async () => sourceBytes,
      encode: async () => Buffer.alloc(800, 3),
      upload: async (file) => {
        uploads.push(file);
        return { url: tokenUrl(file.path, "gallery") };
      },
      verifyPublic: async () => true,
      writeGalleryUrls: async (assigned) => {
        const next = assignGalleryUrls(temple, assigned.assignments);
        temple = { ...temple, photos: next.photos };
        return next;
      },
    });
  }
  const first = await run("first");
  assert.deepEqual(
    first.filter((row) => row.result === "uploaded").map((row) => row.galleryPath),
    ["temples/shore-temple/01_1080_g8.jpg", "temples/shore-temple/02_1080_g8.jpg"],
  );
  assert.equal(uploads.length, 2);
  assert.equal(uploads[0].ifGenerationMatch, 0);
  assert.equal(temple.photos[0].thumbUrl, "https://cdn.example/shore-temple/01_480.jpg");
  assert.match(temple.photos[0].galleryUrl, /_1080_g8/);
  assert.match(temple.photos[1].galleryUrl, /_1080_g8/);
  uploads.length = 0;
  const second = await run("second");
  assert.equal(uploads.length, 0);
  assert.equal(second.every((row) => row.reason === "has-gallery"), true);
});

test("an existing gallery object is linked and not uploaded again", async () => {
  const temple = shore();
  const uploads = [];
  const existing = tokenUrl("temples/shore-temple/01_1080_g8.jpg", "already");
  const plans = planGalleryPhotos([temple]).filter((plan) => plan.index === 0);
  const rows = await applyGalleryPlans(plans, {
    dryRun: false,
    stat: async (path) => {
      if (path.endsWith("/01.jpg")) return { generation: "8", updated: "2024-01-01T00:00:00.000Z" };
      if (path.endsWith("_1080_g8.jpg")) return { generation: "1", url: existing };
      return null;
    },
    download: async () => {
      throw new Error("existing object must not be downloaded");
    },
    upload: async (file) => {
      uploads.push(file);
      return { url: existing };
    },
    verifyPublic: async () => true,
    writeGalleryUrls: async (assigned) => assignGalleryUrls(temple, assigned.assignments),
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows[0].result, "exists");
  const assigned = assignGalleryUrls(temple, [{ source: temple.photos[0].url, galleryUrl: existing }]);
  assert.equal(assigned.photos[0].galleryUrl, existing);
  assert.equal(assigned.photos[0].thumbUrl, temple.photos[0].thumbUrl);
});

test("a copy that is not smaller is not uploaded", async () => {
  const temple = shore();
  const plans = [planGalleryPhotos([temple])[0]];
  const uploads = [];
  const rows = await applyGalleryPlans(plans, {
    dryRun: false,
    stat: async (path) =>
      path.endsWith("/01.jpg") ? { generation: "2", updated: "2024-01-01T00:00:00.000Z" } : null,
    download: async () => Buffer.alloc(100, 1),
    encode: async () => Buffer.alloc(100, 2),
    upload: async (file) => {
      uploads.push(file);
      return { url: tokenUrl(file.path) };
    },
    verifyPublic: async () => true,
    writeGalleryUrls: async () => {
      throw new Error("not-smaller must not write");
    },
  });
  assert.equal(uploads.length, 0);
  assert.equal(rows[0].reason, "not-smaller");
});

test("one transaction skips a photo whose url changed and keeps the other", async () => {
  const temple = shore("moved-temple");
  const fresh = structuredClone(temple);
  fresh.photos[0] = { ...fresh.photos[0], url: "https://example.com/replaced.jpg" };
  const db = {
    writes: [],
    collection() {
      return { doc: () => ({ id: fresh.id }) };
    },
    async runTransaction(fn) {
      return fn({
        get: async () => ({ exists: true, id: fresh.id, data: () => structuredClone(fresh) }),
        update: (_ref, data) => {
          this.writes.push(data);
          fresh.photos = data.photos;
        },
      });
    },
  };
  const gallery = tokenUrl("temples/moved-temple/02_1080_g4.jpg", "gallery");
  const result = await persistGalleryUrls(db, {
    id: fresh.id,
    assignments: [
      { source: temple.photos[0].url, galleryUrl: tokenUrl("temples/moved-temple/01_1080_g4.jpg") },
      { source: temple.photos[1].url, galleryUrl: gallery },
    ],
  });
  assert.equal(result.ok, true);
  assert.deepEqual(result.skippedUrls, [temple.photos[0].url]);
  assert.equal(db.writes.length, 1);
  assert.equal(fresh.photos[1].galleryUrl, gallery);
  assert.equal(fresh.photos[1].thumbUrl, undefined);
  assert.equal(Object.hasOwn(fresh.photos[0], "galleryUrl"), false);
  assert.equal(fresh.photos[0].thumbUrl, temple.photos[0].thumbUrl);
});

test("an existing galleryUrl is not overwritten", () => {
  const temple = shore();
  const kept = tokenUrl("temples/shore-temple/01_1080_g1.jpg", "kept");
  temple.photos[0].galleryUrl = kept;
  const next = tokenUrl("temples/shore-temple/01_1080_g9.jpg", "next");
  const assigned = assignGalleryUrls(temple, [
    { source: temple.photos[0].url, galleryUrl: next },
  ]);
  assert.equal(assigned.changed, false);
  assert.equal(assigned.photos[0].galleryUrl, kept);
});

test("limit and resume skip the same way as the cover script", () => {
  const plans = planGalleryPhotos([shore("a-temple"), shore("b-temple")]);
  const limited = applyLimitAndResume(plans, { limit: 1 });
  assert.equal(limited.filter((plan) => plan.action === "upload").length, 1);
  assert.equal(limited.filter((plan) => plan.reason === "limit").length, 3);
  const done = new Map([["a-temple", new Set([shore("a-temple").photos[0].url])]]);
  const resumed = applyLimitAndResume(plans, { resumePhotos: done });
  assert.equal(resumed[0].reason, "resume");
  assert.equal(resumed[1].action, "upload");
  const raw = saveResume("demo-temple-index", done);
  const loaded = loadResume(raw, "demo-temple-index");
  assert.equal(loaded.get("a-temple").has(shore("a-temple").photos[0].url), true);
  assert.equal(loadResume(raw, "other-project").size, 0);
});

test("the report redacts download tokens and apply is refused in CI", async () => {
  const text = formatGalleryReport(
    [
      {
        id: "shore-temple",
        result: "uploaded",
        galleryPath: "temples/shore-temple/01_1080_g3.jpg",
        galleryUrl: tokenUrl("temples/shore-temple/01_1080_g3.jpg", "super-secret"),
      },
    ],
    { apply: true },
  );
  assert.equal(text.includes("super-secret"), false);
  assert.match(text, /uploaded shore-temple temples\/shore-temple\/01_1080_g3.jpg/);
  assert.match(text, /index was not written/);
  await assert.rejects(
    () => authorizeApply("temple-directory-india", { CI: "true" }),
    /CI/,
  );
  const opts = parseArgs(["--project", "temple-directory-india"]);
  assert.equal(opts.dryRun, true);
  assert.equal(opts.apply, false);
  const source = readFileSync(resolve(here, "resize_gallery_images.js"), "utf8");
  assert.match(source, /ifGenerationMatch: 0/);
  assert.match(source, /prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI/);
  assert.doesNotMatch(source, /entryFromTemple/);
  assert.doesNotMatch(source, /collection\("temple_index"\)/);
});

test("frames from a pack keep a galleryUrl that is already there", () => {
  const gallery = tokenUrl("temples/empty-shore/02_front_1080_g2.jpg", "gallery");
  const photos = photosFromFrames(
    [
      {
        credit: "Ada",
        licence: "CC-BY",
        galleryUrl: gallery,
        thumbUrl: "http://example.com/not-https.jpg",
      },
    ],
    [tokenUrl("temples/empty-shore/02_front.jpg", "src")],
  );
  assert.equal(photos[0].galleryUrl, gallery);
  assert.equal(Object.hasOwn(photos[0], "thumbUrl"), false);
});

test("encodeGalleryJpeg caps the long edge at 1080 and does not enlarge", async () => {
  const sharp = (await import("sharp")).default;
  const wide = await sharp({
    create: { width: 2000, height: 1000, channels: 3, background: { r: 20, g: 80, b: 140 } },
  })
    .jpeg()
    .toBuffer();
  const gallery = await encodeGalleryJpeg(wide);
  assert.equal(gallery[0], 0xff);
  assert.equal(gallery[1], 0xd8);
  const wideMeta = await sharp(gallery).metadata();
  assert.equal(wideMeta.format, "jpeg");
  assert.equal(wideMeta.width, 1080);
  assert.equal(wideMeta.height, 540);

  const portrait = await sharp({
    create: { width: 800, height: 1600, channels: 3, background: { r: 40, g: 90, b: 30 } },
  })
    .jpeg()
    .toBuffer();
  const tall = await sharp(await encodeGalleryJpeg(portrait)).metadata();
  assert.equal(tall.height, 1080);
  assert.equal(tall.width, 540);

  const small = await sharp({
    create: { width: 120, height: 80, channels: 3, background: { r: 200, g: 30, b: 30 } },
  })
    .png()
    .toBuffer();
  const smallMeta = await sharp(await encodeGalleryJpeg(small)).metadata();
  assert.equal(smallMeta.width, 120);
  assert.equal(smallMeta.height, 80);
  assert.equal(GALLERY_JPEG_QUALITY, 75);
  assert.equal(GALLERY_TARGET_BYTES, 250 * 1024);
});

test("galleryUrl once, a re-run is a no-op, and rebuild_index stays at 0 drift", {
  skip: process.env.FIRESTORE_EMULATOR_HOST ? false : "Firestore emulator is not running",
}, async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? "";
  assert.match(host, /^(127\.0\.0\.1|localhost):\d+$/);
  const project = "demo-gallery-url";
  assert.equal(project.startsWith("demo-"), true);
  const env = { FIRESTORE_EMULATOR_HOST: host };
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: project });
  }
  const id = "gallery-shore";
  const front = tokenUrl(`temples/${id}/02_front.jpg`, "src-front");
  const side = tokenUrl(`temples/${id}/01_side.jpg`, "src-side");
  const wiki = "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg";
  const thumb = tokenUrl(`temples/${id}/02_front_480_g1.jpg`, "thumb-token");
  const db = admin.firestore();
  await db.collection("temples").doc(id).set({
    id,
    name: "Shore Temple",
    state: "Tamil Nadu",
    city: "Mahabalipuram",
    deity: "Shiva",
    address: "Mahabalipuram",
    description: "Stone shore temple.",
    story: "Built on the coast.",
    timings: "6 am to 6 pm",
    specialities: [],
    latitude: 12.6,
    longitude: 80.2,
    imageUrl: front,
    images: [front, side, wiki],
    photos: [
      { url: front, credit: "Ada", licence: "CC-BY", order: 0, thumbUrl: thumb },
      { url: side, credit: "Ada", licence: "CC-BY", order: 1 },
      { url: wiki, credit: "Ada", licence: "CC-BY", order: 2 },
    ],
  });
  const built = await rebuildMain(["--apply", "--project", project], { env, log: () => {} });
  assert.equal(built.drifted.length, 0);

  const uploads = [];
  const deps = {
    env,
    log: () => {},
    writeResume: () => {},
    stat: async (path) => {
      if (path.endsWith(".jpg") && !path.includes("_1080_") && !path.includes("_480_")) {
        return { generation: "4", updated: "2024-01-01T00:00:00.000Z" };
      }
      return null;
    },
    download: async () => Buffer.alloc(2000, 1),
    encode: async () => Buffer.alloc(100, 2),
    upload: async (file) => {
      uploads.push(file);
      return { url: tokenUrl(file.path, "gallery-token") };
    },
    verifyPublic: async () => true,
  };
  await main(["--apply", "--project", project], deps);
  assert.equal(uploads.length, 2);
  assert.equal(uploads.every((file) => file.ifGenerationMatch === 0 && file.path.includes("_1080_g4")), true);
  const saved = (await db.collection("temples").doc(id).get()).data();
  assert.match(saved.photos[0].galleryUrl, /_1080_g4/);
  assert.match(saved.photos[0].galleryUrl, /token=/);
  assert.match(saved.photos[1].galleryUrl, /_1080_g4/);
  assert.equal(saved.photos[2].galleryUrl, undefined);
  assert.equal(saved.photos[0].thumbUrl, thumb);

  await main(["--apply", "--project", project], {
    ...deps,
    stat: async () => {
      throw new Error("re-run must not stat");
    },
    download: async () => {
      throw new Error("re-run must not download");
    },
    upload: async () => {
      throw new Error("re-run must not upload");
    },
  });
  const report = await rebuildMain(["--project", project], { env, log: () => {} });
  assert.equal(report.drifted.length, 0);
  assert.equal(report.missing.length, 0);
  assert.equal(report.unchanged >= 1, true);
});

test("another bucket is skipped and logged, and --apply refuses --bucket", async () => {
  const appspot =
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.appspot.com/o/temples%2Fother-temple%2F01.jpg?alt=media&token=abc";
  const gcs = "https://storage.googleapis.com/other.appspot.com/temples/other-temple/02.jpg";
  const temple = {
    id: "other-temple",
    images: [appspot, gcs],
    photos: [
      { url: appspot, licence: "CC0", credit: "", order: 0 },
      { url: gcs, licence: "CC0", credit: "", order: 1 },
    ],
  };
  const plans = planGalleryPhotos([temple]);
  assert.equal(plans[0].action, "skip");
  assert.equal(plans[0].reason, "other-bucket");
  assert.equal(plans[0].bucket, "temple-directory-india.appspot.com");
  assert.equal(plans[1].reason, "other-bucket");
  assert.equal(plans[1].bucket, "other.appspot.com");

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
  assert.equal(rows.every((row) => row.reason === "other-bucket"), true);
  const report = lines.join("\n");
  assert.match(report, /skip other-temple other-bucket/);
  assert.equal(report.includes("would-upload"), false);

  const calls = [];
  const forged = await applyGalleryPlans(
    [
      {
        id: "forged",
        index: 0,
        action: "upload",
        source: gcs,
        objectPath: "temples/other-temple/02.jpg",
        bucket: "other.appspot.com",
        temple,
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
});
