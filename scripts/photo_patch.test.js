import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import {
  applyPatchSet,
  formatDryRunLine,
  galleryMatches,
  loadPatches,
  stripUtm,
} from "./apply_field_patches.js";
import { MIRROR_TEMPLE_IDS } from "./patch_image_url_mirror.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = resolve(here, "..");

test("mirror dry-run lists every audit id and apply refuses CI", () => {
  const dry = spawnSync(
    process.execPath,
    [join(here, "patch_image_url_mirror.js")],
    { encoding: "utf8" },
  );
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /Mode: dry-run/);
  assert.match(dry.stdout, /No Firestore connection/);
  for (const id of MIRROR_TEMPLE_IDS) {
    assert.match(dry.stdout, new RegExp(id));
  }
  assert.equal(MIRROR_TEMPLE_IDS.length, 30);

  const ci = spawnSync(
    process.execPath,
    [
      join(here, "patch_image_url_mirror.js"),
      "--apply",
      "--project",
      "temple-directory-india",
    ],
    { encoding: "utf8", env: { ...process.env, GITHUB_ACTIONS: "true" } },
  );
  assert.notEqual(ci.status, 0);
  assert.match(ci.stderr, /CI/);
});

test("field patch dry-run prints only the allowed fields and rejects extras", () => {
  const dir = mkdtempSync(join(tmpdir(), "field-patch-"));
  const file = join(dir, "patch.json");
  writeFileSync(
    file,
    JSON.stringify({
      temples: [
        { id: "amarnath-cave-temple", fields: { timings: "SEASONAL ONLY" } },
      ],
    }),
  );
  const loaded = loadPatches(file);
  assert.equal(loaded.temples[0].id, "amarnath-cave-temple");
  const dry = spawnSync(
    process.execPath,
    [join(here, "apply_field_patches.js"), "--patches", file],
    { encoding: "utf8" },
  );
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /fields: timings/);
  assert.match(dry.stdout, /No Firestore connection/);

  writeFileSync(
    file,
    JSON.stringify({
      temples: [{ id: "x", fields: { story: "nope" } }],
    }),
  );
  assert.throws(() => loadPatches(file), /not allowed/);

  const ci = spawnSync(
    process.execPath,
    [
      join(here, "apply_field_patches.js"),
      "--apply",
      "--project",
      "temple-directory-india",
      "--patches",
      file,
    ],
    { encoding: "utf8", env: { ...process.env, CI: "true" } },
  );
  assert.notEqual(ci.status, 0);
});

test("gallery writes require the audited gallery and dry-run names each doc", () => {
  const dir = mkdtempSync(join(tmpdir(), "field-patch-guard-"));
  const file = join(dir, "patch.json");
  writeFileSync(
    file,
    JSON.stringify({
      temples: [
        {
          id: "akshardham-temple",
          fields: { imageUrl: "https://example.com/a.jpg", images: ["https://example.com/a.jpg"] },
        },
      ],
    }),
  );
  assert.throws(() => loadPatches(file), /expect/);

  const patch = loadPatches(
    resolve(repoRoot, "tools/prod-patches/photo-field-patches.json"),
  );
  const byId = new Map(patch.temples.map((temple) => [temple.id, temple]));
  const empty = { imageUrl: "", images: [], photos: [] };
  for (const id of [
    "akshardham-temple",
    "chintaman-ganesh-temple",
    "janaki-temple-sitamarhi",
    "kaleshwara-mukteswara-temple",
    "mangala-gauri-temple",
    "purmandal-temple",
    "ugratara-temple",
  ]) {
    assert.deepEqual(byId.get(id).expect, empty, id);
  }
  const mandsaur = byId.get("pashupatinath-temple");
  assert.equal(mandsaur.expect.images.length, 5);
  assert.equal(mandsaur.expect.photos.length, 0);
  assert.equal(mandsaur.fields.images.length, 6);
  assert.equal(mandsaur.fields.photos.length, 6);
  assert.equal(mandsaur.fields.images[0], mandsaur.fields.imageUrl);
  assert.equal(
    mandsaur.fields.images.some((url) => url.includes("Madhya_Pradesh_001")),
    false,
  );
  const credited = mandsaur.fields.photos.filter(
    (photo) => photo.licence === "CC-BY-SA",
  );
  assert.deepEqual(
    credited.map((photo) => photo.order),
    [0, 4],
  );
  for (const photo of credited) {
    assert.equal(photo.credit, "Rohit MDS · CC BY-SA 4.0");
    assert.equal(Object.keys(photo).sort().join(","), "credit,licence,order,url");
  }
  assert.match(formatDryRunLine(mandsaur), /audited 5 images and empty photos/);
  assert.match(formatDryRunLine(byId.get("amarnath-cave-temple")), /timings only/);

  const withUtm = {
    imageUrl: `${mandsaur.expect.imageUrl}?utm_source=commons.wikimedia.org&utm_campaign=imageinfo`,
    images: mandsaur.expect.images.map(
      (url) => `${url}?utm_source=commons.wikimedia.org`,
    ),
  };
  assert.equal(galleryMatches(withUtm, mandsaur.expect), true);
  assert.equal(stripUtm(withUtm.imageUrl), mandsaur.expect.imageUrl);
  assert.equal(galleryMatches({}, empty), true);
  assert.equal(
    galleryMatches(
      {
        imageUrl: "https://firebasestorage.googleapis.com/v0/b/app/o/new.jpg",
        images: ["https://firebasestorage.googleapis.com/v0/b/app/o/new.jpg"],
        photos: [],
      },
      empty,
    ),
    false,
  );
  assert.equal(
    galleryMatches(
      { ...withUtm, images: withUtm.images.slice(0, 4) },
      mandsaur.expect,
    ),
    false,
  );

  const dry = spawnSync(
    process.execPath,
    [
      join(here, "apply_field_patches.js"),
      "--patches",
      resolve(repoRoot, "tools/prod-patches/photo-field-patches.json"),
    ],
    { encoding: "utf8" },
  );
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /akshardham-temple  would apply if live gallery matches audited empty/);
  assert.match(
    dry.stdout,
    /pashupatinath-temple  would apply if live gallery matches audited 5 images and empty photos/,
  );
  assert.match(dry.stdout, /amarnath-cave-temple  timings only/);
  assert.match(dry.stdout, /No Firestore connection/);
  const source = readFileSync(join(here, "apply_field_patches.js"), "utf8");
  assert.match(source, /--strict/);
  assert.match(source, /galleryMatches/);
  assert.match(source, /No write/);
});

function fakeDb(docs, { onTransactionRead } = {}) {
  const updates = [];
  let inTransaction = false;
  const db = {
    updates,
    collection() {
      return {
        doc(id) {
          return {
            id,
            async get() {
              if (inTransaction && onTransactionRead) return onTransactionRead(id);
              if (!Object.prototype.hasOwnProperty.call(docs, id)) {
                return { exists: false, data: () => undefined };
              }
              return { exists: true, data: () => docs[id] };
            },
          };
        },
      };
    },
    async runTransaction(fn) {
      inTransaction = true;
      try {
        const tx = {
          async get(ref) {
            return ref.get();
          },
          update(ref, fields) {
            updates.push({ id: ref.id, fields });
          },
        };
        return await fn(tx);
      } finally {
        inTransaction = false;
      }
    },
  };
  return db;
}

test("a live photos entry is skipped by default and aborts under --strict", async () => {
  const empty = { imageUrl: "", images: [], photos: [] };
  const liveObject = {
    imageUrl: "",
    images: [],
    photos: [{ url: "https://x/a.jpg", credit: "me", licence: "Own", order: 0 }],
  };
  const liveString = {
    imageUrl: "",
    images: [],
    photos: ["https://x/a.jpg"],
  };
  assert.equal(galleryMatches(liveObject, empty), false);
  assert.equal(galleryMatches(liveString, empty), false);
  assert.equal(
    galleryMatches(
      {
        imageUrl: "",
        images: [],
        photos: [{ url: " https://x/a.jpg ", credit: " me ", licence: " Own ", order: 0 }],
      },
      {
        imageUrl: "",
        images: [],
        photos: [{ url: "https://x/a.jpg", credit: "me", licence: "Own", order: 0 }],
      },
    ),
    true,
  );

  const patch = {
    temples: [
      {
        id: "akshardham-temple",
        fields: {
          imageUrl: "https://example.com/a.jpg",
          images: ["https://example.com/a.jpg"],
          photos: [],
        },
        expect: empty,
      },
    ],
  };

  const lines = [];
  const original = console.log;
  console.log = (...args) => lines.push(args.join(" "));
  try {
    const skipped = fakeDb({ "akshardham-temple": liveObject });
    await applyPatchSet(skipped, patch, { strict: false });
    assert.deepEqual(skipped.updates, []);
    assert.match(lines.join("\n"), /skipped temples\/akshardham-temple/);

    lines.length = 0;
    const skippedString = fakeDb({ "akshardham-temple": liveString });
    await applyPatchSet(skippedString, patch, { strict: false });
    assert.deepEqual(skippedString.updates, []);

    await assert.rejects(
      () => applyPatchSet(fakeDb({ "akshardham-temple": liveObject }), patch, { strict: true }),
      /Live gallery does not match the audited state: akshardham-temple[\s\S]*No write/,
    );
    await assert.rejects(
      () => applyPatchSet(fakeDb({ "akshardham-temple": liveString }), patch, { strict: true }),
      /No write/,
    );

    const matched = fakeDb({ "akshardham-temple": { ...empty } });
    await applyPatchSet(matched, patch, { strict: false });
    assert.equal(matched.updates.length, 1);
    assert.equal(matched.updates[0].id, "akshardham-temple");

    const raced = fakeDb(
      { "akshardham-temple": { ...empty } },
      {
        onTransactionRead: () => ({
          exists: true,
          data: () => liveObject,
        }),
      },
    );
    lines.length = 0;
    await applyPatchSet(raced, patch, { strict: false });
    assert.deepEqual(raced.updates, []);
    assert.match(lines.join("\n"), /skipped temples\/akshardham-temple/);

    await assert.rejects(
      () =>
        applyPatchSet(
          fakeDb(
            { "akshardham-temple": { ...empty } },
            {
              onTransactionRead: () => ({
                exists: true,
                data: () => liveObject,
              }),
            },
          ),
          patch,
          { strict: true },
        ),
      /No write/,
    );
  } finally {
    console.log = original;
  }

  const source = readFileSync(join(here, "apply_field_patches.js"), "utf8");
  assert.match(source, /typeof item === "string"/);
  assert.match(source, /item\.url\.trim\(\)/);
  assert.match(source, /runTransaction/);
});

test("CI workflows do not patch production", () => {
  const ci = readFileSync(resolve(repoRoot, ".github/workflows/ci.yml"), "utf8");
  assert.doesNotMatch(ci, /--apply/);
  assert.doesNotMatch(ci, /--patch-firestore/);
  assert.doesNotMatch(ci, /patch_image_url_mirror\.js --apply/);
  const workflows = readFileSync(
    resolve(repoRoot, ".github/workflows/demo-seed-launch.yml"),
    "utf8",
  );
  assert.doesNotMatch(workflows, /--patch-firestore/);
});
