import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import {
  assertIdsAbsent,
  firestoreWritePayload,
  main,
  parseArgs,
} from "./seed_state_batch.js";
import {
  STATE_BOUNDS,
  canonicalPhotoPackPath,
  distanceKm,
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
  assert.equal(result.temples[0].story, result.temples[0].description);
  assert.equal(payload.story, result.temples[0].description);
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

test("a Bihar batch with Delhi coordinates is a hard error", () => {
  const result = validateStateBatch(
    batch([temple({ latitude: 28.6139, longitude: 77.2091 })]),
    [],
  );
  assert.equal(result.ok, false);
  assert.equal(result.summary.new.length, 0);
  assert.ok(
    result.errors.some((error) => error.includes("outside the Bihar bounding box")),
    result.errors.join("\n"),
  );
  assert.equal(
    result.warnings.some((warning) => warning.message.includes("bounding box")),
    false,
  );
  assert.ok(STATE_BOUNDS.Bihar.latMax < 28.6139);
  assert.ok(STATE_BOUNDS.Delhi.latMin <= 28.6139 && STATE_BOUNDS.Delhi.latMax >= 28.6139);
  assert.ok(STATE_BOUNDS.Delhi.lngMin <= 77.2091 && STATE_BOUNDS.Delhi.lngMax >= 77.2091);
});

test("overlap warns only within 0.3 degrees of a box edge", () => {
  const border = validateStateBatch(
    batch([
      temple({
        slug: "border-temple",
        name: "Border Temple",
        city: "Ballia",
        latitude: 25.7584,
        longitude: 84.5501,
      }),
    ]),
    [],
  );
  assert.equal(border.ok, true, border.errors.join("\n"));
  assert.ok(
    border.warnings.some(
      (warning) => warning.message.includes("Uttar Pradesh") && warning.message.includes("Bihar"),
    ),
    JSON.stringify(border.warnings),
  );

  const ballia = validateStateBatch(
    batch([
      temple({
        slug: "ballia-temple",
        name: "Ballia Temple",
        city: "Ballia",
        latitude: 25.7584,
        longitude: 84.1487,
      }),
    ]),
    [],
  );
  assert.equal(ballia.ok, true, ballia.errors.join("\n"));
  assert.equal(
    ballia.warnings.some((warning) => warning.message.includes("bounding box")),
    false,
    JSON.stringify(ballia.warnings),
  );

  const tamreswari = validateStateBatch(
    batch(
      [
        temple({
          slug: "tamreswari-temple",
          name: "Tamreswari Temple",
          state: "Assam",
          city: "Sadiya",
          latitude: 27.9417,
          longitude: 95.8472,
        }),
      ],
      "Assam",
    ),
    [],
  );
  assert.equal(tamreswari.ok, true, tamreswari.errors.join("\n"));
  assert.ok(
    tamreswari.warnings.some(
      (warning) =>
        warning.message.includes("Assam") && warning.message.includes("Arunachal Pradesh"),
    ),
    JSON.stringify(tamreswari.warnings),
  );

  const jaimangla = validateStateBatch(
    batch([
      temple({
        slug: "jaimangla-garh-temple",
        name: "Jaimangla Garh Temple",
        city: "Begusarai",
        latitude: 25.5922,
        longitude: 86.1613,
      }),
    ]),
    [],
  );
  assert.equal(jaimangla.ok, true, jaimangla.errors.join("\n"));
  assert.equal(
    jaimangla.warnings.some((warning) => warning.message.includes("West Bengal")),
    false,
    JSON.stringify(jaimangla.warnings),
  );

  const telangana = validateStateBatch(
    batch(
      [
        temple({
          slug: "yadagirigutta-temple",
          name: "Yadagirigutta Temple",
          state: "Telangana",
          city: "Yadagirigutta",
          latitude: 17.5892,
          longitude: 78.9446,
        }),
      ],
      "Telangana",
    ),
    [],
  );
  assert.equal(telangana.ok, true, telangana.errors.join("\n"));
  assert.equal(telangana.warnings.length, 0, JSON.stringify(telangana.warnings));

  const haryana = validateStateBatch(
    batch(
      [
        temple({
          slug: "central-haryana-temple",
          name: "Central Haryana Temple",
          state: "Haryana",
          city: "Rohtak",
          latitude: 29.29,
          longitude: 76.04,
        }),
      ],
      "Haryana",
    ),
    [],
  );
  assert.equal(haryana.ok, false);
  assert.ok(haryana.errors.some((error) => error.includes("need 4 or more")));
  assert.equal(
    haryana.warnings.some((warning) => warning.message.includes("bounding box")),
    false,
    JSON.stringify(haryana.warnings),
  );

  const haryanaPrecise = validateStateBatch(
    batch(
      [
        temple({
          slug: "central-haryana-temple",
          name: "Central Haryana Temple",
          state: "Haryana",
          city: "Rohtak",
          latitude: 29.2911,
          longitude: 76.0411,
        }),
      ],
      "Haryana",
    ),
    [],
  );
  assert.equal(haryanaPrecise.ok, true, haryanaPrecise.errors.join("\n"));
  assert.equal(haryanaPrecise.warnings.length, 0, JSON.stringify(haryanaPrecise.warnings));
});

test("coordinates reject 2 or fewer decimals, warn on 3, and accept 4 or more", () => {
  for (const latitude of [26, 26.2, 26.09]) {
    const result = validateStateBatch(
      batch([temple({ latitude, longitude: 85.1372 })]),
      [],
    );
    assert.equal(result.ok, false, String(latitude));
    assert.ok(
      result.errors.some((error) => error.includes("need 4 or more")),
      result.errors.join("\n"),
    );
  }
  const three = validateStateBatch(
    batch([temple({ latitude: 26.095, longitude: 85.1372 })]),
    [],
  );
  assert.equal(three.ok, true, three.errors.join("\n"));
  assert.equal(three.summary.new.length, 1);
  assert.ok(
    three.warnings.some((warning) => warning.message.includes("has 3 decimal places")),
    JSON.stringify(three.warnings),
  );
  assert.match(three.warnings[0].reviewNote, /3 decimal places/);
  for (const latitude of [26.0951, 26.16645]) {
    const result = validateStateBatch(
      batch([temple({ latitude, longitude: 85.1372 })]),
      [],
    );
    assert.equal(result.ok, true, `${latitude}\n${result.errors.join("\n")}`);
    assert.equal(
      result.warnings.some((warning) => warning.message.includes("decimal")),
      false,
      `${latitude}\n${JSON.stringify(result.warnings)}`,
    );
  }

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
  assert.equal(
    inside.errors.some((error) => error.includes("outside")),
    false,
  );
  assert.ok(
    inside.warnings.some((warning) => warning.message.includes("Gujarat")),
    JSON.stringify(inside.warnings),
  );
  assert.match(inside.warnings[0].reviewNote, /Gujarat/);
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

test("a 1 km pair is accepted when dedupe.distinct_from lists the other slug", () => {
  const near = {
    slug: "other-temple",
    name: "Other Temple",
    latitude: 25.6151,
    longitude: 85.1372,
  };
  const blocked = validateStateBatch(batch([temple(), temple(near)]), []);
  assert.equal(blocked.ok, false);
  assert.ok(blocked.errors.some((error) => error.includes("within 1 km")));
  assert.equal(blocked.info.length, 0);

  const noted = temple();
  noted.review = { ...noted.review, notes: "distinct from other-temple" };
  const fromNotes = validateStateBatch(batch([noted, temple(near)]), []);
  assert.equal(fromNotes.ok, false);
  assert.ok(fromNotes.errors.some((error) => error.includes("within 1 km")));

  const left = temple();
  left.dedupe = { distinct_from: ["other-temple"] };
  const waived = validateStateBatch(batch([left, temple(near)]), []);
  assert.equal(waived.ok, true, waived.errors.join("\n"));
  assert.equal(waived.summary.new.length, 2);
  assert.equal(waived.info.length, 1);
  assert.match(waived.info[0].message, /dedupe\.distinct_from/);
  assert.equal(Object.hasOwn(waived.temples[0], "dedupe"), false);

  const right = temple(near);
  right.dedupe = { distinct_from: ["Example-Temple"] };
  const fromOther = validateStateBatch(batch([temple(), right]), []);
  assert.equal(fromOther.ok, true, fromOther.errors.join("\n"));
  assert.equal(fromOther.info.length, 1);

  const wrong = temple();
  wrong.dedupe = { distinct_from: "other-temple" };
  const notStructured = validateStateBatch(batch([wrong, temple(near)]), []);
  assert.equal(notStructured.ok, false);

  const existing = {
    id: "example-temple",
    name: "Example Temple",
    state: "Bihar",
    latitude: 25.6111,
    longitude: 85.1372,
    dedupe: { distinct_from: ["nearby-temple"] },
  };
  const nearby = temple({
    slug: "nearby-temple",
    name: "Nearby Temple",
    latitude: 25.6151,
    longitude: 85.1372,
  });
  nearby.review = {
    ...nearby.review,
    notes: "Different shrine from Example Temple, confirmed on the map.",
  };
  const notesOnly = validateStateBatch(batch([nearby]), [existing]);
  assert.equal(notesOnly.ok, false);
  assert.ok(
    notesOnly.errors.some((error) => error.includes("dedupe.reason")),
    notesOnly.errors.join("\n"),
  );

  nearby.dedupe = {
    distinct_from: ["example-temple"],
    reason: "Distinct from Example Temple in the same neighbourhood.",
  };
  const againstExisting = validateStateBatch(batch([nearby]), [existing]);
  assert.equal(againstExisting.ok, true, againstExisting.errors.join("\n"));
  assert.equal(againstExisting.info.length, 0);
  assert.equal(againstExisting.warnings.length, 1);
  assert.match(againstExisting.warnings[0].message, /existing example-temple/);
  assert.match(againstExisting.warnings[0].reviewNote, /Example Temple/);

  const incoming = temple({
    slug: "nearby-temple",
    name: "Nearby Temple",
    latitude: 25.6151,
    longitude: 85.1372,
  });
  incoming.dedupe = {
    distinct_from: ["example-temple"],
    reason: "Not the same temple as example-temple.",
  };
  incoming.review = {
    ...incoming.review,
    notes: "Photo shortfall: 0/5.",
  };
  const fromIncoming = validateStateBatch(batch([incoming]), [
    { ...existing, dedupe: undefined },
  ]);
  assert.equal(fromIncoming.ok, true, fromIncoming.errors.join("\n"));
  assert.equal(fromIncoming.info.length, 0);
  assert.equal(fromIncoming.warnings.length, 1);
  assert.match(fromIncoming.warnings[0].reviewNote, /example-temple/);

  const shortfall = temple({
    slug: "nearby-temple",
    name: "Nearby Temple",
    latitude: 25.6151,
    longitude: 85.1372,
  });
  shortfall.dedupe = {
    distinct_from: ["example-temple"],
    reason: "Photo shortfall: 0/5.",
  };
  shortfall.review = {
    ...shortfall.review,
    notes: "Approved by Research Pavi 2026-10-15.",
  };
  const generic = validateStateBatch(batch([shortfall]), [
    { ...existing, dedupe: undefined },
  ]);
  assert.equal(generic.ok, false);
  assert.ok(
    generic.errors.some((error) => error.includes("dedupe.reason")),
    generic.errors.join("\n"),
  );

  const sameName = temple({
    slug: "exampletemple",
    name: "ExampleTemple",
    latitude: 25.6151,
    longitude: 85.1372,
  });
  sameName.dedupe = {
    distinct_from: ["example-temple"],
    reason: "Same folded name as example-temple.",
  };
  const foldedName = validateStateBatch(batch([sameName]), [
    { ...existing, dedupe: undefined },
  ]);
  assert.equal(foldedName.ok, false);
  assert.ok(
    foldedName.errors.some((error) => error.includes("different normalised name")),
    foldedName.errors.join("\n"),
  );

  const noReason = temple({
    slug: "nearby-temple",
    name: "Nearby Temple",
    latitude: 25.6151,
    longitude: 85.1372,
  });
  noReason.dedupe = { distinct_from: ["example-temple"] };
  const missingReason = validateStateBatch(batch([noReason]), [
    { ...existing, dedupe: undefined },
  ]);
  assert.equal(missingReason.ok, false);
  assert.ok(
    missingReason.errors.some((error) => error.includes("dedupe.reason")),
    missingReason.errors.join("\n"),
  );
});

test("Odisha cluster pairs within 1 km of prod stay valid with a warning", () => {
  const cluster = [
    {
      id: "lingaraj-temple",
      name: "Lingaraj Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2383,
      longitude: 85.8336,
    },
    {
      id: "mukteshwar-temple",
      name: "Mukteshwar Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2427,
      longitude: 85.8404,
    },
    {
      id: "rajarani-temple",
      name: "Rajarani Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2434,
      longitude: 85.8435,
    },
    {
      id: "ananta-vasudeva-temple",
      name: "Ananta Vasudeva Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2406,
      longitude: 85.8358,
    },
  ];
  const rows = [
    temple({
      slug: "sidheswar-temple",
      name: "Sidheswar Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2393,
      longitude: 85.8336,
    }),
    temple({
      slug: "parasurameswar-temple",
      name: "Parasurameswar Temple",
      state: "Odisha",
      city: "Bhubaneswar",
      latitude: 20.2436,
      longitude: 85.8404,
    }),
  ];
  const kmToLingaraj = distanceKm(rows[0], cluster[0]);
  assert.ok(kmToLingaraj < 0.2 && kmToLingaraj > 0.05, String(kmToLingaraj));
  for (const row of rows) {
    const near = [];
    for (const other of cluster) {
      if (distanceKm(row, other) <= 1) near.push(other.id);
    }
    for (const other of rows) {
      if (other.slug !== row.slug && distanceKm(row, other) <= 1) near.push(other.slug);
    }
    row.dedupe = {
      distinct_from: near,
      reason: `Distinct shrines: ${near.join(", ")}.`,
    };
    row.review = {
      ...row.review,
      notes: "Approved by Research Pavi 2026-10-15.",
    };
  }
  const result = validateStateBatch(batch(rows, "Odisha"), cluster);
  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(result.summary.new.length, 2);
  assert.ok(
    result.warnings.some((warning) => warning.message.includes("existing lingaraj-temple")),
    JSON.stringify(result.warnings),
  );
  assert.ok(result.warnings.every((warning) => warning.reviewNote.trim() !== ""));
  assert.equal(
    result.info.some((item) => item.message.includes("existing ")),
    false,
  );
  assert.ok(
    result.info.some((item) => item.message.includes("parasurameswar-temple")),
    JSON.stringify(result.info),
  );

  const unmarked = temple({
    slug: "unmarked-temple",
    name: "Unmarked Temple",
    state: "Odisha",
    city: "Bhubaneswar",
    latitude: 20.2393,
    longitude: 85.8336,
  });
  const blocked = validateStateBatch(batch([unmarked], "Odisha"), cluster);
  assert.equal(blocked.ok, false);
  assert.ok(blocked.errors.some((error) => error.includes("within 1 km")));
});

test("photo_pack.path is photos/<slug>/ under temple-research", () => {
  assert.equal(
    canonicalPhotoPackPath("example-temple"),
    "/workspace/temple-research/photos/example-temple/",
  );
  const absolute = temple();
  absolute.photo_pack = {
    ...absolute.photo_pack,
    path: "/workspace/temple-research/photos/example-temple/",
  };
  const accepted = validateStateBatch(batch([absolute]), []);
  assert.equal(accepted.ok, true, accepted.errors.join("\n"));

  const elsewhere = temple();
  elsewhere.photo_pack = {
    ...elsewhere.photo_pack,
    path: "state-expansion/photos/example-temple/",
  };
  const rejected = validateStateBatch(batch([elsewhere]), []);
  assert.equal(rejected.ok, false);
  assert.ok(
    rejected.errors.some((error) => error.includes("/workspace/temple-research/photos/example-temple/")),
    rejected.errors.join("\n"),
  );
  assert.equal(rejected.errors.some((error) => error.includes("state-expansion/photos")), false);
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

test("apply omits image fields and refuses to overwrite an existing document", () => {
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

  const picsumLive = {
    imageUrl: "https://picsum.photos/seed/example/800/600",
    images: ["https://picsum.photos/seed/example/800/600"],
    photos: [],
  };
  assert.equal(hasVerifiedGallery(picsumLive), false);
  assert.throws(() => firestoreWritePayload(incoming, picsumLive), /will not be overwritten/);

  const created = firestoreWritePayload(incoming, null);
  assert.equal(Object.hasOwn(created, "imageUrl"), false);
  assert.equal(Object.hasOwn(created, "images"), false);
  assert.equal(Object.hasOwn(created, "photos"), false);
  assert.equal(Object.hasOwn(created, "timings_note"), false);
  assert.equal(created.timings, null);
  assert.equal(created.story, incoming.description);
  assert.equal(created.address, "Patna, Bihar");

  const source = readFileSync(join(here, "seed_state_batch.js"), "utf8");
  assert.match(source, /firestoreWritePayload\(temple, null\)/);
  assert.match(source, /getAll\(/);
  assert.match(source, /batch\.create\(db\.collection\("temples"\)\.doc\(temple\.id\)/);
  assert.match(source, /mergeFields/);
  assert.match(source, /planSeedIndexBatches/);
  assert.doesNotMatch(source, /batch\.create\(db\.collection\("temple_index"\)/);
  assert.doesNotMatch(source, /batch\.create\(meta/);
  assert.match(source, /assertIdsAbsent/);
  assert.doesNotMatch(source, /collection\("temples"\)[\s\S]{0,160}\.set\(/);
  assert.doesNotMatch(source, /collection\("temples"\)[\s\S]{0,160}\.update\(/);
  assert.doesNotMatch(source, /\.update\(/);
  assert.doesNotMatch(source, /--update/);
  assert.equal(Object.hasOwn(parseArgs(["batch.json"]), "update"), false);
  assert.throws(() => parseArgs(["batch.json", "--update"]), /Unknown argument/);

  const second = { ...incoming, id: "other-temple" };
  assert.throws(
    () => assertIdsAbsent([incoming, second], new Set(["other-temple"])),
    /other-temple/,
  );
  assert.throws(
    () => assertIdsAbsent([incoming, second], new Set(["example-temple", "other-temple"])),
    /example-temple, other-temple/,
  );
  assert.deepEqual(
    assertIdsAbsent([incoming], new Set()),
    undefined,
  );
});

test("an existing slug is rejected, including a case-only match", () => {
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
  const renamed = validateStateBatch(batch([rename]), [existing]);
  assert.equal(renamed.ok, false);
  assert.ok(
    renamed.errors.some((error) => error.includes("will not be overwritten or renamed")),
    renamed.errors.join("\n"),
  );

  const timingsChange = validateStateBatch(
    batch([temple({ timings: "6:00 AM–8:00 PM." })]),
    [existing],
  );
  assert.equal(timingsChange.ok, false);
  assert.equal(timingsChange.temples.length, 0);
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
  const rejected = validateStateBatch(
    batch([temple({ timings: "7:00 AM–7:00 PM." })]),
    parsed.map((row) => row.temple),
  );
  assert.equal(rejected.ok, false);
  assert.ok(
    rejected.errors.some((error) => error.includes("will not be overwritten or renamed")),
    rejected.errors.join("\n"),
  );

  const added = temple({
    slug: "other-temple",
    name: "Other Temple",
    latitude: 24.8111,
    longitude: 84.4111,
  });
  const validated = validateStateBatch(batch([added]), parsed.map((row) => row.temple));
  assert.equal(validated.ok, true, validated.errors.join("\n"));
  assert.equal(validated.temples[0].story, added.description);
  const once = mergeTemplesIntoSource(source, validated.temples);
  const twice = mergeTemplesIntoSource(once, validated.temples);
  assert.equal(once, twice);
  const after = parseSampleTemples(once);
  assert.equal(after.length, 2);
  const original = after.find((row) => row.id === "example-temple");
  assert.equal(original.temple.timings, "6:00 AM–8:00 PM.");
  assert.equal(original.temple.story, "One.\n\nTwo.\n\nThree.");
  assert.equal(original.temple.imageUrl, original.temple.images[0]);
  const created = after.find((row) => row.id === "other-temple");
  assert.equal(created.temple.story, added.description);
  assert.equal(created.temple.timings, null);
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
    assert.equal(approved[0].review.reviewer, "fixture", name);
    assert.equal(rejected[0].review.reviewer, "fixture", name);

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
  const row = temple();
  row.dedupe = { slug_clear: true, nearest_km: 4.2 };
  row.photo_pack = {
    ...row.photo_pack,
    photosShort: true,
    commons_category: null,
    photos: [],
  };
  const validated = validateStateBatch(batch([row]), []);
  assert.equal(validated.ok, true, validated.errors.join("\n"));
  assert.equal(validated.temples[0].timings, null);
  const seeded = validated.temples[0];
  for (const key of ["slug", "sources", "timings_note", "dedupe", "review", "photo_pack"]) {
    assert.equal(Object.hasOwn(seeded, key), false, key);
  }
  const payload = firestoreWritePayload(seeded, null);
  for (const key of [
    "slug",
    "sources",
    "timings_note",
    "dedupe",
    "review",
    "photo_pack",
    "added",
    "shortfall_note",
  ]) {
    assert.equal(Object.hasOwn(payload, key), false, key);
  }
  assert.deepEqual(
    Object.keys(payload).sort(),
    [
      "address",
      "city",
      "deity",
      "description",
      "id",
      "latitude",
      "longitude",
      "name",
      "specialities",
      "state",
      "story",
      "timings",
    ].sort(),
  );
  const source = `import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
];
`;
  const once = mergeTemplesIntoSource(source, validated.temples);
  assert.match(once, /timings: null,/);
  assert.match(once, /location: 'Patna, Bihar',/);
  assert.doesNotMatch(once, /timings_note/);
  assert.doesNotMatch(once, /Hours are not published/);
  assert.doesNotMatch(once, /photo_pack/);
  assert.doesNotMatch(once, /sources:/);
  assert.doesNotMatch(once, /dedupe/);
  assert.doesNotMatch(once, /shortfall_note/);
  const parsed = parseSampleTemples(once);
  assert.equal(parsed[0].temple.timings, null);
  assert.equal(parsed[0].temple.story, row.description);
  const twice = mergeTemplesIntoSource(once, validated.temples);
  assert.equal(once, twice);
});

const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const onEmulator = /^(127\.0\.0\.1|localhost):\d+$/.test(emulatorHost);

function applyBatchFile(slug, name) {
  const dir = mkdtempSync(join(tmpdir(), "seed-apply-"));
  const file = join(dir, "bihar.json");
  const payload = batch([
    temple({
      slug,
      name,
      city: "Gaya",
      latitude: 24.5123,
      longitude: 84.2345,
      description: `${name} is a Shiva shrine in Gaya used to check the batch shape. The description is two sentences so the research rule is met.`,
    }),
  ]);
  writeFileSync(file, JSON.stringify(payload));
  return file;
}

async function emulatorDb() {
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: "demo-temple-index" });
  }
  return admin.firestore();
}

async function applyOnEmulator(file) {
  await main([file, "--apply", "--project", "demo-temple-index"], {
    confirmProject: async (id) => id,
  });
}

test(
  "--apply merges entries into an existing meta and shard",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const db = await emulatorDb();
    const kept = {
      id: "kept-temple",
      name: "Kept Temple",
      state: "Bihar",
      city: "Patna",
      deity: "Devi",
      hasImage: false,
      coverThumb: "",
    };
    const keralaStamp = new Date("2020-06-01T00:00:00.000Z");
    await db.collection("temple_index").doc("bihar").set({
      entries: { "kept-temple": kept },
    });
    await db.collection("meta").doc("temple_index").set({
      indexVersion: 4,
      shards: {
        bihar: new Date("2020-05-01T00:00:00.000Z"),
        kerala: keralaStamp,
      },
      note: "keep me",
    });
    await db.collection("temples").doc("seed-apply-merge-temple").delete();

    const file = applyBatchFile("seed-apply-merge-temple", "Seed Apply Merge Temple");
    await applyOnEmulator(file);

    const shard = (await db.collection("temple_index").doc("bihar").get()).data();
    assert.equal(shard.entries["kept-temple"].name, "Kept Temple");
    assert.equal(shard.entries["seed-apply-merge-temple"].id, "seed-apply-merge-temple");
    assert.equal(shard.entries["seed-apply-merge-temple"].state, "Bihar");
    const meta = (await db.collection("meta").doc("temple_index").get()).data();
    assert.equal(meta.indexVersion, 5);
    assert.equal(meta.note, "keep me");
    assert.equal(meta.shards.kerala.toMillis(), keralaStamp.getTime());
    const created = await db.collection("temples").doc("seed-apply-merge-temple").get();
    assert.equal(created.exists, true);
    assert.equal(created.get("timings"), null);
    assert.equal(Object.hasOwn(created.data(), "imageUrl"), false);
  },
);

test(
  "--apply aborts before any write when a shard would pass 400 entries",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const db = await emulatorDb();
    const entries = {};
    for (let i = 0; i < 400; i += 1) {
      entries[`full-${i}`] = { id: `full-${i}`, name: `Full ${i}` };
    }
    await db.collection("temple_index").doc("bihar").set({ entries });
    await db.collection("meta").doc("temple_index").set({
      indexVersion: 2,
      shards: { bihar: new Date("2020-01-01T00:00:00.000Z") },
    });
    await db.collection("temples").doc("cap-abort-temple").delete();

    const file = applyBatchFile("cap-abort-temple", "Cap Abort Temple");
    await assert.rejects(() => applyOnEmulator(file), /would have 401 entries/);

    const created = await db.collection("temples").doc("cap-abort-temple").get();
    assert.equal(created.exists, false);
    const shard = (await db.collection("temple_index").doc("bihar").get()).data();
    assert.equal(Object.keys(shard.entries).length, 400);
    assert.equal(shard.entries["full-0"].name, "Full 0");
    assert.equal(Object.hasOwn(shard.entries, "cap-abort-temple"), false);
    const meta = (await db.collection("meta").doc("temple_index").get()).data();
    assert.equal(meta.indexVersion, 2);
  },
);

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
