import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { firestoreWritePayload } from "./seed_state_batch.js";
import {
  STATE_BOUNDS,
  formatSummary,
  hasVerifiedGallery,
  validateStateBatch,
} from "./state_batch.js";
import { loadSampleTemples, mergeTemplesIntoSource, parseSampleTemples } from "./temple_seed.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = resolve(here, "..");

function temple(overrides = {}) {
  const row = {
    slug: "example-temple",
    name: "Example Temple",
    state: "Bihar",
    city: "Patna",
    deity: "Shiva",
    description: "A temple.",
    timings: null,
    timings_note: "Hours are not published. Confirm locally.",
    specialities: ["Stone gateway"],
    latitude: 25.6,
    longitude: 85.1,
    sources: ["https://example.org/example-temple"],
    photo_pack: {
      status: "pending",
      images: ["https://example.com/a.jpg"],
      photos: [
        {
          url: "https://example.com/a.jpg",
          credit: "Ada · CC BY 4.0",
          licence: "CC-BY",
          order: 0,
        },
      ],
    },
    review: { status: "reviewed", note: "Checked against the directory." },
    ...overrides,
  };
  return row;
}

function batch(temples, state = "Bihar") {
  return { state, temples };
}

test("template matches the research schema and passes against an empty directory", () => {
  const raw = readFileSync(resolve(repoRoot, "docs/state-batch-template.json"), "utf8");
  assert.doesNotMatch(raw, /Provisional/);
  assert.doesNotMatch(raw, /"story"/);
  assert.doesNotMatch(raw, /"location"/);
  assert.doesNotMatch(raw, /"id"/);
  const template = JSON.parse(raw);
  assert.equal(template.temples[0].timings, null);
  assert.ok(template.temples[0].timings_note);
  assert.ok(template.temples[0].sources.length > 0);
  assert.ok(template.temples[0].photo_pack);
  assert.ok(template.temples[0].review);
  const result = validateStateBatch(template, []);
  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(result.summary.new.length, 1);
  assert.equal(result.summary.new[0].id, "example-temple");
  assert.equal(result.temples[0].timings, template.temples[0].timings_note);
  assert.equal(result.temples[0].story, "");
});

test("story, location, and id are forbidden; sources, photo_pack, and review are required", () => {
  for (const key of ["story", "location", "id"]) {
    const row = temple({ [key]: "nope" });
    const result = validateStateBatch(batch([row]), []);
    assert.equal(result.ok, false, key);
    assert.ok(result.errors.some((error) => error.includes(key)), result.errors.join("\n"));
  }
  for (const key of ["sources", "photo_pack", "review"]) {
    const row = temple();
    delete row[key];
    const result = validateStateBatch(batch([row]), []);
    assert.equal(result.ok, false, key);
    assert.ok(result.errors.some((error) => error.includes(key)), result.errors.join("\n"));
  }
  const missingNote = temple();
  delete missingNote.timings_note;
  const noNote = validateStateBatch(batch([missingNote]), []);
  assert.equal(noNote.ok, false);
  assert.ok(noNote.errors.some((error) => error.includes("timings_note")));

  const stated = temple({ timings: "6:00 AM–8:00 PM.", timings_note: undefined });
  delete stated.timings_note;
  const withClock = validateStateBatch(batch([stated]), []);
  assert.equal(withClock.ok, true, withClock.errors.join("\n"));
  assert.equal(withClock.temples[0].timings, "6:00 AM–8:00 PM.");
});

test("validator rejects picsum, placeholder, and stock URLs", () => {
  const urls = [
    "https://picsum.photos/seed/example/800/600",
    "https://fastly.picsum.photos/id/1/800/600.jpg",
    "https://placehold.co/800x600",
    "https://via.placeholder.com/800",
    "https://images.unsplash.com/photo-1",
    "https://www.shutterstock.com/image-photo/temple-1",
  ];
  for (const url of urls) {
    const row = temple({
      photo_pack: { status: "ready", images: [url] },
    });
    const result = validateStateBatch(batch([row]), []);
    assert.equal(result.ok, false, url);
    assert.ok(
      result.errors.some((error) => error.includes("placeholder or stock")),
      result.errors.join("\n"),
    );
  }
});

test("a Bihar batch with Delhi coordinates fails the state bounding box", () => {
  const result = validateStateBatch(
    batch([temple({ latitude: 28.6, longitude: 77.2 })]),
    [],
  );
  assert.equal(result.ok, false);
  assert.ok(
    result.errors.some((error) => error.includes("outside the Bihar bounding box")),
    result.errors.join("\n"),
  );
  assert.ok(STATE_BOUNDS.Bihar.latMax < 28.6);
  assert.ok(STATE_BOUNDS.Delhi.latMin <= 28.6 && STATE_BOUNDS.Delhi.latMax >= 28.6);
});

test("duplicates are rejected by id, normalised name, and coordinates within 1 km", () => {
  const duplicatedId = validateStateBatch(batch([temple(), temple()]), []);
  assert.equal(duplicatedId.ok, false);
  assert.ok(duplicatedId.errors.some((error) => error.includes("duplicated")));

  const near = validateStateBatch(
    batch([
      temple(),
      temple({
        slug: "other-temple",
        name: "Other Temple",
        latitude: 25.604,
        longitude: 85.1,
      }),
    ]),
    [],
  );
  assert.equal(near.ok, false);
  assert.ok(near.errors.some((error) => error.includes("within 1 km")));

  const far = validateStateBatch(
    batch([
      temple(),
      temple({
        slug: "other-temple",
        name: "Other Temple",
        latitude: 25.62,
        longitude: 85.1,
      }),
    ]),
    [],
  );
  assert.equal(far.ok, true, far.errors.join("\n"));

  const folded = validateStateBatch(
    batch([
      temple({
        slug: "example-temple-2",
        name: "Example Temple 2",
        latitude: 25.2,
        longitude: 85.2,
      }),
      temple({
        slug: "example-temple2",
        name: "Example Temple2",
        latitude: 24.8,
        longitude: 84.4,
      }),
    ]),
    [],
  );
  assert.equal(folded.ok, false);
  assert.ok(folded.errors.some((error) => error.includes("normalised name")));

  const againstExisting = validateStateBatch(
    batch([
      temple({
        slug: "nearby-temple",
        name: "Nearby Temple",
        latitude: 25.604,
        longitude: 85.1,
      }),
    ]),
    [
      {
        id: "example-temple",
        name: "Example Temple",
        latitude: 25.6,
        longitude: 85.1,
        imageUrl: "",
        images: [],
        photos: [],
      },
    ],
  );
  assert.equal(againstExisting.ok, false);
  assert.ok(againstExisting.errors.some((error) => error.includes("existing example-temple")));
});

test("apply omits image fields when a verified gallery already exists", () => {
  const incoming = validateStateBatch(batch([temple()]), []).temples[0];
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fexample%2Fimage_0.jpg";
  const live = {
    imageUrl: storage,
    images: [storage],
    photos: [{ url: storage, credit: "Ada · CC BY 4.0", licence: "CC-BY", order: 0 }],
  };
  assert.equal(hasVerifiedGallery(live), true);
  const update = firestoreWritePayload(incoming, live);
  assert.equal(Object.hasOwn(update, "imageUrl"), false);
  assert.equal(Object.hasOwn(update, "images"), false);
  assert.equal(Object.hasOwn(update, "photos"), false);
  assert.equal(Object.hasOwn(update, "story"), false);
  assert.equal(Object.hasOwn(update, "address"), false);
  assert.equal(update.name, "Example Temple");
  assert.equal(update.timings, incoming.timings);

  const picsumLive = {
    imageUrl: "https://picsum.photos/seed/example/800/600",
    images: ["https://picsum.photos/seed/example/800/600"],
    photos: [],
  };
  assert.equal(hasVerifiedGallery(picsumLive), false);
  const replaced = firestoreWritePayload(incoming, picsumLive);
  assert.equal(replaced.imageUrl, "https://example.com/a.jpg");
  assert.deepEqual(replaced.images, ["https://example.com/a.jpg"]);
  assert.equal(replaced.photos[0].licence, "CC-BY");

  const created = firestoreWritePayload(incoming, null);
  assert.equal(created.imageUrl, "https://example.com/a.jpg");
  assert.equal(created.story, "");
  assert.equal(created.address, "Patna, Bihar");

  const source = readFileSync(join(here, "seed_state_batch.js"), "utf8");
  assert.match(source, /firestoreWritePayload\(temple, snap.exists \? snap.data\(\) : null\)/);
});

test("an existing verified seed gallery is kept when the batch names other images", () => {
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fexample%2Fimage_0.jpg";
  const existing = validateStateBatch(batch([temple()]), []).temples[0];
  existing.imageUrl = storage;
  existing.images = [storage];
  existing.photos = [];
  const result = validateStateBatch(
    batch([
      temple({
        photo_pack: {
          status: "ready",
          images: ["https://upload.wikimedia.org/wikipedia/commons/other.jpg"],
        },
      }),
    ]),
    [existing],
  );
  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(result.temples[0].imageUrl, storage);
  assert.deepEqual(result.temples[0].images, [storage]);
  assert.equal(result.summary.unchanged.length, 1);
  assert.match(formatSummary(result.summary), /unchanged: 1/);
});

test("every seeded temple sits inside its state bounding box", () => {
  const { temples } = loadSampleTemples();
  assert.equal(temples.length, 180);
  for (const row of temples) {
    const bounds = STATE_BOUNDS[row.temple.state];
    assert.ok(bounds, row.temple.state);
    assert.ok(
      row.temple.latitude >= bounds.latMin && row.temple.latitude <= bounds.latMax,
      `${row.id} latitude ${row.temple.latitude}`,
    );
    assert.ok(
      row.temple.longitude >= bounds.lngMin && row.temple.longitude <= bounds.lngMax,
      `${row.id} longitude ${row.temple.longitude}`,
    );
  }
});

test("merge into a fixture is idempotent", () => {
  const source = `import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
  Temple(
    name: 'Example Temple',
    state: 'Bihar',
    city: 'Patna',
    deity: 'Shiva',
    imageUrl: 'https://example.com/a.jpg',
    images: [
      'https://example.com/a.jpg',
    ],
    description: 'A temple.',
    story: 'One.\\n\\nTwo.\\n\\nThree.',
    location: 'Patna',
    timings: '6:00 AM–8:00 PM.',
    latitude: 25.6,
    longitude: 85.1,
    specialities: [
      'Stone gateway',
    ],
  ),
];
`;
  const parsed = parseSampleTemples(source);
  assert.equal(parsed.length, 1);
  const validated = validateStateBatch(
    batch([temple({ timings: "7:00 AM–7:00 PM." })]),
    parsed.map((row) => row.temple),
  );
  assert.equal(validated.ok, true, validated.errors.join("\n"));
  const once = mergeTemplesIntoSource(source, validated.temples);
  const twice = mergeTemplesIntoSource(once, validated.temples);
  assert.equal(once, twice);
  const after = parseSampleTemples(once);
  assert.equal(after[0].temple.timings, "7:00 AM–7:00 PM.");
  assert.equal(after[0].temple.story, "One.\n\nTwo.\n\nThree.");
  assert.equal(after[0].temple.imageUrl, after[0].temple.images[0]);
});

test("seed_state_batch dry-run does not write and apply is refused in CI", () => {
  const dir = mkdtempSync(join(tmpdir(), "state-batch-"));
  const sample = join(dir, "sample.dart");
  const file = join(dir, "bihar.json");
  writeFileSync(
    sample,
    `import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
];
`,
  );
  writeFileSync(file, JSON.stringify(batch([temple()])));
  const dry = spawnSync(
    process.execPath,
    [join(here, "seed_state_batch.js"), file, "--sample", sample],
    { encoding: "utf8" },
  );
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, /Mode: dry-run/);
  assert.match(dry.stdout, /new example-temple/);
  assert.match(readFileSync(sample, "utf8"), /sampleTemples = \[\s*\];/);

  const ci = spawnSync(
    process.execPath,
    [
      join(here, "seed_state_batch.js"),
      file,
      "--apply",
      "--project",
      "temple-directory-india",
      "--sample",
      sample,
    ],
    { encoding: "utf8", env: { ...process.env, CI: "true" } },
  );
  assert.notEqual(ci.status, 0);
  assert.match(`${ci.stderr}\n${ci.stdout}`, /CI/);
});

test("CI workflows do not apply seed batches", () => {
  const ci = readFileSync(resolve(repoRoot, ".github/workflows/ci.yml"), "utf8");
  assert.doesNotMatch(ci, /--apply/);
  assert.doesNotMatch(ci, /--patch-firestore/);
  assert.doesNotMatch(ci, /seed_state_batch\.js/);
  const workflows = readFileSync(
    resolve(repoRoot, ".github/workflows/demo-seed-launch.yml"),
    "utf8",
  );
  assert.doesNotMatch(workflows, /--patch-firestore/);
  assert.doesNotMatch(workflows, /seed_state_batch/);
});
