import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { firestoreWritePayload, parseArgs, UPDATE_FIELDS } from "./seed_state_batch.js";
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
    description:
      "Example Temple is a Shiva shrine in Patna used to check the batch shape. The description is two sentences so the research rule is met.",
    timings: null,
    timings_note: "Hours are not published. Confirm locally.",
    specialities: ["Stone gateway", "River bank", "Morning bells"],
    latitude: 25.6111,
    longitude: 85.1372,
    sources: [
      {
        field: "name,city,deity,description,specialities",
        title: "Example Temple",
        url: "https://example.org/example-temple",
      },
    ],
    photo_pack: {
      path: "photos/example-temple/",
      status: "SHORTFALL",
      count: 0,
    },
    review: {
      status: "approved",
      reviewer: "Research Pavi",
      notes: "",
    },
    ...overrides,
  };
  if (overrides.slug || overrides.name) {
    const slug = overrides.slug ?? row.slug;
    if (!overrides.photo_pack) row.photo_pack = { ...row.photo_pack, path: `photos/${slug}/` };
  }
  return row;
}

function batch(temples, state = "Bihar") {
  return {
    state,
    owner: "Architect",
    generated: "2026-10-15",
    existing_in_prod: 0,
    target: 50,
    temples,
  };
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
  const pending = validateStateBatch(template, []);
  assert.equal(pending.ok, true, pending.errors.join("\n"));
  assert.equal(pending.summary.new.length, 0);
  assert.equal(pending.summary.skipped.length, 1);
  assert.equal(pending.temples.length, 0);
  const approved = structuredClone(template);
  approved.temples[0].review.status = "approved";
  const result = validateStateBatch(approved, []);
  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(result.summary.new.length, 1);
  assert.equal(result.summary.new[0].id, "koodal-azhagar-temple");
  assert.equal(result.temples[0].timings, null);
  assert.equal(Object.hasOwn(result.temples[0], "timings_note"), false);
  const payload = firestoreWritePayload(result.temples[0], null);
  assert.equal(payload.timings, null);
  assert.equal(Object.hasOwn(payload, "timings_note"), false);
  assert.equal(result.temples[0].story, "");
  assert.equal(template.owner, "Research");
  assert.equal(template.temples[0].sources[0].url.startsWith("https://"), true);
  assert.equal(template.temples[0].photo_pack.status, "READY");
  assert.deepEqual(Object.keys(template.temples[0].review).sort(), ["notes", "reviewer", "status"]);
});

test("story, location, and id are forbidden; sources, photo_pack, and review are required", () => {
  for (const key of ["story", "location", "id", "festivals", "pooja_schedule", "trip_planning"]) {
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

test("validator rejects placeholder image URLs and ignores sources and Stockholm", () => {
  const urls = [
    "https://picsum.photos/seed/example/800/600",
    "https://fastly.picsum.photos/id/1/800/600.jpg",
    "https://placehold.co/800x600",
    "https://via.placeholder.com/800",
    "https://images.unsplash.com/photo-1",
    "https://www.shutterstock.com/image-photo/temple-1",
    "https://lorempixel.com/800/600/city",
  ];
  for (const url of urls) {
    const row = temple();
    row.photo_pack = {
      ...row.photo_pack,
      photos: [{ url, credit: "Example" }],
    };
    const result = validateStateBatch(batch([row]), []);
    assert.equal(result.ok, false, url);
    assert.ok(
      result.errors.some((error) => error.includes("placeholder or stock")),
      result.errors.join("\n"),
    );
  }

  const cited = temple();
  cited.sources = [
    {
      field: "name",
      title: "Stockholm source",
      url: "https://picsum.photos/seed/example/800/600",
    },
  ];
  cited.photo_pack = {
    ...cited.photo_pack,
    photos: [
      {
        url: "https://upload.wikimedia.org/wikipedia/commons/Stockholm_temple.jpg",
      },
    ],
  };
  const allowed = validateStateBatch(batch([cited]), []);
  assert.equal(allowed.ok, true, allowed.errors.join("\n"));
});

test("a Bihar batch with Delhi coordinates warns and adds a review note", () => {
  const result = validateStateBatch(
    batch([temple({ latitude: 28.6139, longitude: 77.209 })]),
    [],
  );
  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(result.summary.new.length, 1);
  assert.equal(
    result.errors.some((error) => error.includes("outside the Bihar bounding box")),
    false,
  );
  assert.ok(
    result.warnings.some((warning) => warning.message.includes("outside the Bihar bounding box")),
    JSON.stringify(result.warnings),
  );
  assert.match(result.warnings[0].reviewNote, /Bihar/);
  assert.ok(STATE_BOUNDS.Bihar.latMax < 28.6139);
  assert.ok(STATE_BOUNDS.Delhi.latMin <= 28.6139 && STATE_BOUNDS.Delhi.latMax >= 28.6139);
});

test("coordinates may use up to 4 decimal places, and Diu is inside DNH and DD", () => {
  for (const latitude of [26, 26.2, 26.095, 26.0951]) {
    const result = validateStateBatch(
      batch([temple({ latitude, longitude: 85.1372 })]),
      [],
    );
    assert.equal(result.ok, true, `${latitude}\n${result.errors.join("\n")}`);
  }
  const tooFine = validateStateBatch(
    batch([temple({ latitude: 26.16645, longitude: 85.1372 })]),
    [],
  );
  assert.equal(tooFine.ok, false);
  assert.ok(tooFine.errors.some((error) => error.includes("at most 4 decimal places")));

  const diu = temple({
    state: "Dadra and Nagar Haveli and Daman and Diu",
    city: "Diu",
    latitude: 20.7135,
    longitude: 70.9264,
  });
  const inside = validateStateBatch(
    batch([diu], "Dadra and Nagar Haveli and Daman and Diu"),
    [],
  );
  assert.equal(inside.ok, true, inside.errors.join("\n"));
  assert.equal(inside.warnings.length, 0);
});

test("research-only file shapes are accepted and only approved temples are seeded", () => {
  const pending = temple();
  pending.review = { ...pending.review, status: "PENDING" };
  pending.photo_pack = { ...pending.photo_pack, status: "PENDING" };
  pending.dedupe = { slug_clear: true, nearest_km: 12.4 };
  const file = batch([pending]);
  file.added = 1;
  file.shortfall_note = "Photo pack still pending.";
  const held = validateStateBatch(file, []);
  assert.equal(held.ok, true, held.errors.join("\n"));
  assert.equal(held.summary.new.length, 0);
  assert.equal(held.summary.skipped.length, 1);
  assert.equal(held.temples.length, 0);

  const uncategorised = temple({
    slug: "other-temple",
    name: "Other Temple",
    latitude: 24.8111,
    longitude: 84.4111,
  });
  uncategorised.photo_pack = { ...uncategorised.photo_pack, status: "NO_CATEGORY" };
  const ready = validateStateBatch(batch([uncategorised]), []);
  assert.equal(ready.ok, true, ready.errors.join("\n"));
  assert.equal(ready.summary.new.length, 1);
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
        latitude: 25.6151,
        longitude: 85.1372,
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
        latitude: 25.6311,
        longitude: 85.1372,
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
        latitude: 25.2111,
        longitude: 85.2111,
      }),
      temple({
        slug: "example-temple2",
        name: "Example Temple2",
        latitude: 24.8111,
        longitude: 84.4111,
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
        latitude: 25.6151,
        longitude: 85.1372,
      }),
    ]),
    [
      {
        id: "example-temple",
        name: "Example Temple",
        latitude: 25.6111,
        longitude: 85.1372,
        imageUrl: "",
        images: [],
        photos: [],
      },
    ],
  );
  assert.equal(againstExisting.ok, false);
  assert.ok(againstExisting.errors.some((error) => error.includes("existing example-temple")));
});

test("apply omits image fields and refuses to overwrite unless --update", () => {
  const incoming = validateStateBatch(batch([temple()]), []).temples[0];
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fexample%2Fimage_0.jpg";
  const live = {
    imageUrl: storage,
    images: [storage],
    photos: [{ url: storage, credit: "Ada · CC BY 4.0", licence: "CC-BY", order: 0 }],
  };
  assert.equal(hasVerifiedGallery(live), true);
  assert.throws(() => firestoreWritePayload(incoming, live), /will not be overwritten/);
  const update = firestoreWritePayload(incoming, live, { update: true });
  assert.deepEqual(Object.keys(update).sort(), [...UPDATE_FIELDS].sort());
  assert.equal(Object.hasOwn(update, "imageUrl"), false);
  assert.equal(Object.hasOwn(update, "images"), false);
  assert.equal(Object.hasOwn(update, "photos"), false);
  assert.equal(Object.hasOwn(update, "name"), false);
  assert.equal(Object.hasOwn(update, "story"), false);
  assert.equal(Object.hasOwn(update, "address"), false);
  assert.equal(Object.hasOwn(update, "timings_note"), false);
  assert.equal(update.timings, null);

  const picsumLive = {
    imageUrl: "https://picsum.photos/seed/example/800/600",
    images: ["https://picsum.photos/seed/example/800/600"],
    photos: [],
  };
  assert.equal(hasVerifiedGallery(picsumLive), false);
  const leftAlone = firestoreWritePayload(incoming, picsumLive, { update: true });
  assert.equal(Object.hasOwn(leftAlone, "imageUrl"), false);
  assert.equal(Object.hasOwn(leftAlone, "images"), false);
  assert.equal(Object.hasOwn(leftAlone, "photos"), false);

  const created = firestoreWritePayload(incoming, null);
  assert.equal(Object.hasOwn(created, "imageUrl"), false);
  assert.equal(created.story, "");
  assert.equal(created.address, "Patna, Bihar");

  const source = readFileSync(join(here, "seed_state_batch.js"), "utf8");
  assert.match(source, /firestoreWritePayload\(temple, snap.exists \? snap.data\(\) : null/);
  assert.match(source, /already exists. Refusing to overwrite/);
  assert.equal(parseArgs(["batch.json"]).update, false);
  assert.equal(parseArgs(["batch.json", "--update"]).update, true);
});

test("an existing slug is rejected, including a case-only match, unless --update", () => {
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fexample%2Fimage_0.jpg";
  const existing = {
    id: "example-temple",
    name: "Example Temple",
    state: "Bihar",
    city: "Patna",
    deity: "Shiva",
    description: "Kept.",
    story: "Kept story.",
    location: "Patna",
    timings: "5:00 AM doors open.",
    specialities: ["Stone gateway"],
    latitude: 25.6111,
    longitude: 85.1372,
    imageUrl: storage,
    images: [storage],
    photos: [],
  };
  const rejected = validateStateBatch(batch([temple()]), [existing]);
  assert.equal(rejected.ok, false);
  assert.ok(
    rejected.errors.some((error) => error.includes("will not be overwritten or renamed")),
    rejected.errors.join("\n"),
  );

  const mixedCase = temple({ slug: "Example-Temple" });
  const folded = validateStateBatch(batch([mixedCase]), [existing]);
  assert.equal(folded.ok, false);
  assert.ok(
    folded.errors.some((error) => error.includes("will not be overwritten or renamed")),
    folded.errors.join("\n"),
  );

  const rename = temple({ slug: "example-temple", name: "Example-Temple" });
  const renamed = validateStateBatch(batch([rename]), [existing], { update: true });
  assert.equal(renamed.ok, false);
  assert.ok(renamed.errors.some((error) => error.includes("would rename")), renamed.errors.join("\n"));

  const updated = validateStateBatch(
    batch([temple({ timings: "6:00 AM–8:00 PM." })]),
    [existing],
    { update: true },
  );
  assert.equal(updated.ok, true, updated.errors.join("\n"));
  assert.equal(updated.temples[0].imageUrl, storage);
  assert.deepEqual(updated.temples[0].images, [storage]);
  assert.equal(updated.temples[0].name, "Example Temple");
  assert.equal(updated.temples[0].story, "Kept story.");
  assert.equal(updated.summary.changed.length, 1);
  assert.equal(updated.summary.changed[0].fields.includes("imageUrl"), false);
  assert.equal(updated.summary.changed[0].fields.includes("name"), false);
  assert.match(formatSummary(updated.summary), /changed: 1/);
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
    { update: true },
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

test("trimmed research batches validate against the seeded directory", () => {
  const { temples } = loadSampleTemples();
  const existing = temples.map((row) => row.temple);
  for (const name of ["assam", "sikkim", "tripura", "bihar"]) {
    const file = resolve(repoRoot, "scripts/fixtures/state-batches", `${name}.json`);
    const batch = JSON.parse(readFileSync(file, "utf8"));
    assert.ok(batch.temples.length >= 1 && batch.temples.length <= 2, name);
    assert.ok(batch.owner && batch.generated && batch.target, name);
    const result = validateStateBatch(batch, existing);
    assert.equal(result.ok, true, `${name}\n${result.errors.join("\n")}`);
    assert.equal(result.summary.new.length, 1, name);
    assert.equal(result.summary.skipped.length, 1, name);
    const approved = batch.temples.filter((row) => row.review.status === "approved");
    const rejected = batch.temples.filter((row) => row.review.status !== "approved");
    assert.equal(approved.length, 1, name);
    assert.equal(rejected.length, 1, name);

    const dry = spawnSync(
      process.execPath,
      [join(here, "seed_state_batch.js"), file],
      { encoding: "utf8" },
    );
    assert.equal(dry.status, 0, `${name}\n${dry.stderr}`);
    assert.match(dry.stdout, /Mode: dry-run/);
    assert.match(dry.stdout, /new: 1/);
    assert.match(dry.stdout, /skipped: 1/);
    if (name === "sikkim") {
      const rumtek = batch.temples.find((row) => row.slug === "rumtek-monastery");
      assert.match(`${rumtek.description}\n${rumtek.review.notes}`, /[Nn]on-Hindu/);
      assert.notEqual(rumtek.review.status, "approved");
    }
  }
});

test("null timings round-trip as null in sample_data and are not the note", () => {
  const validated = validateStateBatch(batch([temple()]), []);
  assert.equal(validated.temples[0].timings, null);
  const source = `import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
];
`;
  const once = mergeTemplesIntoSource(source, validated.temples);
  assert.match(once, /timings: null,/);
  assert.doesNotMatch(once, /timings_note/);
  assert.doesNotMatch(once, /Hours are not published/);
  const parsed = parseSampleTemples(once);
  assert.equal(parsed[0].temple.timings, null);
  const twice = mergeTemplesIntoSource(once, validated.temples);
  assert.equal(once, twice);
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
