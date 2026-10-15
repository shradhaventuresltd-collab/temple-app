import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { firestoreWritePayload } from "./seed_state_batch.js";
import {
  applyPlan,
  authorizeApply,
  credentialMode,
  formatReport,
  main,
  parseArgs,
  resolveProject,
} from "./rebuild_index.js";
import {
  batchRounds,
  changedFields,
  coverThumb,
  DOCUMENT_BYTE_LIMIT,
  diffIndex,
  entryFromTemple,
  entryListed,
  estimateShardBytes,
  framingOf,
  indexFlags,
  planOps,
  planSeedIndexBatches,
  stateSlug,
  writeNeeded,
} from "./temple_index.js";

const repoRoot = resolve(fileURLToPath(new URL(".", import.meta.url)), "..");

function flagsFixture() {
  return JSON.parse(
    readFileSync(resolve(repoRoot, "scripts/fixtures/temple_index_flags.json"), "utf8"),
  );
}

test("flag fixture matches the index projection", () => {
  for (const row of flagsFixture()) {
    const flags = indexFlags(row);
    assert.equal(flags.tradition, row.tradition, row.id);
    assert.equal(flags.living, row.living, row.id);
    assert.equal(flags.framing, row.framing, row.id);
  }
});

test("state-batch payload is a lean entry and is backfilled", () => {
  const payload = firestoreWritePayload(
    {
      id: "patan-devi-temple",
      name: "Patan Devi Temple",
      state: "Bihar",
      city: "Patna",
      deity: "Devi",
      description:
        "Patan Devi Temple is a Devi shrine in Patna. The second sentence keeps the research shape.",
      timings: null,
      specialities: ["Stone gateway", "River bank", "Morning bells"],
      latitude: 25.611,
      longitude: 85.137,
      story:
        "Patan Devi Temple is a Devi shrine in Patna. The second sentence keeps the research shape.",
      location: "Patna, Bihar",
    },
    null,
  );
  const entry = entryFromTemple(payload);
  assert.equal(entry.id, "patan-devi-temple");
  assert.equal(entry.slug, "patan-devi-temple");
  assert.equal(entry.address, "Patna, Bihar");
  assert.equal(entry.coverThumb, null);
  assert.equal(entry.lat, 25.611);
  assert.equal(entry.lng, 85.137);
  assert.equal(entry.v, 1);
  for (const forbidden of [
    "description",
    "story",
    "timings",
    "specialities",
    "photos",
    "images",
    "imageUrl",
    "latitude",
    "longitude",
  ]) {
    assert.equal(Object.hasOwn(entry, forbidden), false, forbidden);
  }

  const odisha = {
    ...payload,
    id: "lingaraj-temple",
    name: "Lingaraj Temple",
    state: "Odisha",
    city: "Bhubaneswar",
    address: "Bhubaneswar, Odisha",
  };
  const report = diffIndex([payload, odisha], {});
  const ids = report.missing.map((item) => item.id).sort();
  assert.deepEqual(ids, ["lingaraj-temple", "patan-devi-temple"]);
  assert.equal(report.missing.find((item) => item.id === "patan-devi-temple").shard, "bihar");
  assert.equal(report.missing.find((item) => item.id === "lingaraj-temple").shard, "odisha");
});

test("cover thumb matches the first verified gallery image and caps at 500", () => {
  const full = "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg";
  const thumb = "https://cdn.example/photos/shore_480.jpg";
  assert.equal(
    coverThumb({
      photos: [{ url: full, thumbUrl: thumb, licence: "CC0", order: 0 }],
      imageUrl: "https://example.com/cover.jpg",
      images: ["https://example.com/gallery.jpg"],
    }),
    "https://example.com/gallery.jpg",
  );
  const wide =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg";
  assert.equal(
    coverThumb({ imageUrl: wide }),
    "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/500px-File.jpg",
  );
  assert.equal(coverThumb({ imageUrl: full }), full);
  assert.equal(
    coverThumb({
      imageUrl: "https://picsum.photos/seed/temple/800/600",
      images: ["https://example.com/gallery.jpg"],
    }),
    "https://example.com/gallery.jpg",
  );
  assert.equal(coverThumb({ imageUrl: "https://picsum.photos/seed/temple/800/600" }), null);
  const tooLong = `https://example.com/${"a".repeat(500)}.jpg`;
  assert.ok(tooLong.length > 500);
  assert.equal(coverThumb({ imageUrl: tooLong, images: [full] }), full);
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fid%2F171000_480.jpg?alt=media";
  assert.equal(
    coverThumb({
      photos: [{ url: storage, licence: "CC0", order: 0 }],
      imageUrl: full,
    }),
    full,
  );
});

test("cover caption is stored and is not drift when it matches", () => {
  const url =
    "https://thumb.wikimedia.org/wikipedia/commons/thumb/6/68/Plate.jpg/500px-Plate.jpg";
  const temple = {
    id: "purmandal-temple",
    name: "Purmandal Temple",
    state: "Jammu and Kashmir",
    city: "Samba",
    deity: "Shiva",
    address: "Purmandal, Samba",
    imageUrl: url,
    images: [url],
    photos: [
      {
        url,
        credit: "19th-century lithograph (1847 print). James Duffield Harding",
        licence: "CC0",
        order: 0,
      },
    ],
    latitude: 32.6957,
    longitude: 75.0609,
    description: "A riverside temple.",
    story: "A riverside temple.",
  };
  const entry = entryFromTemple(temple);
  assert.equal(entry.coverCaption, "Lithograph, 1847");
  assert.deepEqual(changedFields(entry, entry), []);
  const wiped = { ...entry };
  delete wiped.coverCaption;
  assert.ok(changedFields(entry, wiped).includes("coverCaption"));
});

test("state slugs match the shared fixture", () => {
  const rows = JSON.parse(
    readFileSync(resolve(repoRoot, "scripts/fixtures/temple_index_slugs.json"), "utf8"),
  );
  assert.ok(rows.length > 0);
  for (const row of rows) {
    assert.equal(stateSlug(row.state), row.slug, row.state);
  }
});

test("fort ruins do not label a living shrine as a monument", () => {
  const living = {
    name: "Fort Side Shrine",
    deity: "Devi",
    description:
      "Daily puja at the shrine beside the fort ruins. The former factory ceased.",
    story: "Historic fort ruins stand next to the temple.",
    timings: "5:00 AM – 8:00 PM",
    specialities: [],
  };
  assert.equal(framingOf(living), "living");
  const anjengo = {
    name: "Anjengo Sree Durga Devi Temple",
    deity: "Devi",
    description:
      "Local Durga Devi shrine at historic Anchuthengu (Anjengo), set beside the ruins of Anjengo Fort.",
    story:
      "The surviving laterite fort ruins still define the settlement. Unlike the major Devaswom-board pilgrimage temples, it remains a neighbourhood shrine.",
    timings: "5:00 AM – 12:00 PM",
    specialities: [],
  };
  assert.equal(framingOf(anjengo), "neutral");
});

test("longitude is numeric and a full shard stays under 1 MiB", () => {
  const entry = entryFromTemple({
    id: "whole-degree",
    name: "N".repeat(200),
    state: "S".repeat(80),
    city: "C".repeat(80),
    deity: "D".repeat(90),
    address: "Patna, Bihar",
    latitude: 12,
    longitude: 80,
  });
  assert.equal(typeof entry.lng, "number");
  assert.equal(entry.lng, 80);
  assert.equal(typeof entry.lat, "number");
  assert.equal(entry.name.length, 80);
  assert.equal(entry.city.length, 40);
  assert.equal(entry.state.length, 40);
  assert.equal(entry.deity.length, 60);
  assert.ok(estimateShardBytes(400) < DOCUMENT_BYTE_LIMIT);
});

test("hidden and published flags filter an index entry", () => {
  assert.equal(entryListed({ id: "a" }), true);
  assert.equal(entryListed({ id: "a", published: true, hidden: false }), true);
  assert.equal(entryListed({ id: "a", published: false }), false);
  assert.equal(entryListed({ id: "a", hidden: true }), false);
});

test("seed batches are one shard each and stay under 500 ops", () => {
  const bihar = (id) => ({ id, state: "Bihar", name: id });
  const rounds = planSeedIndexBatches([
    bihar("patan-devi-temple"),
    bihar("mahavir-mandir-patna"),
    { id: "lingaraj-temple", state: "Odisha", name: "Lingaraj" },
  ]);
  assert.equal(rounds.length, 2);
  assert.equal(rounds[0].shard, "bihar");
  assert.deepEqual(
    rounds[0].temples.map((temple) => temple.id),
    ["patan-devi-temple", "mahavir-mandir-patna"],
  );
  assert.equal(rounds[0].ops, 4);
  assert.equal(rounds[1].shard, "odisha");
  assert.equal(rounds[1].ops, 3);
  assert.ok(rounds.every((round) => round.ops <= 500));
  const heavy = Array.from({ length: 401 }, (_, i) => bihar(`temple-${i}`));
  assert.throws(() => planSeedIndexBatches(heavy), /max is 400/);
});

test("coordinates are null when missing or 0,0", () => {
  const missing = entryFromTemple({
    id: "no-point",
    name: "No Point",
    state: "Goa",
    city: "Panaji",
    deity: "Shiva",
    address: "Panaji",
  });
  assert.equal(missing.lat, null);
  assert.equal(missing.lng, null);

  const zero = entryFromTemple({
    id: "zero-point",
    name: "Zero Point",
    state: "Goa",
    city: "Panaji",
    deity: "Shiva",
    address: "Panaji",
    latitude: 0,
    longitude: 0,
  });
  assert.equal(zero.lat, null);
  assert.equal(zero.lng, null);

  const kept = entryFromTemple({
    id: "axis",
    name: "Axis",
    state: "Goa",
    city: "Panaji",
    deity: "Shiva",
    address: "Panaji",
    latitude: 0,
    longitude: 80,
  });
  assert.equal(kept.lat, 0);
  assert.equal(kept.lng, 80);
});

test("optional fields are copied only when they already exist", () => {
  const plain = entryFromTemple({
    id: "plain",
    name: "Plain",
    state: "Goa",
    city: "Panaji",
    deity: "Shiva",
    address: "Panaji, Goa",
    latitude: 15.5,
    longitude: 73.8,
  });
  assert.equal(Object.hasOwn(plain, "altNames"), false);
  assert.equal(Object.hasOwn(plain, "published"), false);
  assert.equal(Object.hasOwn(plain, "hidden"), false);

  const flagged = entryFromTemple({
    id: "flagged",
    name: "Flagged",
    state: "Goa",
    city: "Panaji",
    deity: "Shiva",
    address: "Panaji, Goa",
    latitude: 15.5,
    longitude: 73.8,
    altNames: ["Alt Shrine"],
    published: false,
    hidden: true,
    publishedNote: "ignored",
  });
  assert.deepEqual(flagged.altNames, ["Alt Shrine"]);
  assert.equal(flagged.published, false);
  assert.equal(flagged.hidden, true);
  assert.equal(Object.hasOwn(flagged, "publishedNote"), false);
});

test("diff reports drift, moves, and stale entries", () => {
  const temple = {
    id: "city-temple",
    name: "City Temple",
    state: "Bihar",
    city: "Patna",
    deity: "Shiva",
    address: "Patna, Bihar",
    latitude: 25.6,
    longitude: 85.1,
  };
  const expected = entryFromTemple(temple);
  const report = diffIndex([temple], {
    odisha: {
      "city-temple": { ...expected, state: "Odisha" },
      "gone-temple": { ...expected, id: "gone-temple", slug: "gone-temple" },
    },
    bihar: {
      "city-temple": { ...expected, city: "Gaya" },
    },
  });
  assert.equal(report.moved.length, 1);
  assert.equal(report.moved[0].from, "odisha");
  assert.equal(report.moved[0].to, "bihar");
  assert.equal(report.drifted.length, 1);
  assert.deepEqual(report.drifted[0].fields, ["city"]);
  assert.deepEqual(
    report.stale.map((item) => item.id),
    ["gone-temple"],
  );
  const ops = planOps(report);
  assert.equal(ops.filter((op) => op.op === "set" && op.shard === "bihar").length, 1);
  assert.equal(
    ops.some((op) => op.op === "delete" && op.shard === "odisha" && op.id === "city-temple"),
    true,
  );
});

test("one shard is not written twice in the same batch round", () => {
  const temples = ["a", "b", "c"].map((id) => ({
    id,
    name: id,
    state: id === "c" ? "Odisha" : "Bihar",
    city: "City",
    deity: "Shiva",
    address: "City",
    latitude: 20,
    longitude: 80,
  }));
  const rounds = batchRounds(planOps(diffIndex(temples, {})));
  for (const round of rounds) {
    const shards = round.map((op) => op.shard);
    assert.equal(new Set(shards).size, shards.length);
  }
  assert.equal(rounds.length, 2);
  assert.equal(rounds[0].length, 2);
  assert.equal(stateSlug("Tamil Nadu"), "tamil-nadu");
});

test("parse and guards: dry-run by default, apply needs a project, CI never writes", async () => {
  assert.equal(parseArgs([]).apply, false);
  assert.equal(parseArgs([]).dryRun, true);
  assert.equal(parseArgs(["--apply", "--project", "temple-directory-india"]).apply, true);
  assert.equal(credentialMode({}), "service-account");
  assert.equal(
    credentialMode({ FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" }),
    "emulator",
  );

  assert.throws(
    () => resolveProject({ project: null }, {}),
    /no default project/,
  );
  assert.equal(
    resolveProject({ project: null }, { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" }),
    "demo-temple-index",
  );

  await assert.rejects(
    () => authorizeApply("temple-directory-india", { CI: "true" }),
    /CI/,
  );
  await assert.rejects(
    () =>
      authorizeApply("demo", {
        CI: "true",
        FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080",
      }),
    /CI/,
  );

  let confirmed = false;
  const emulatorId = await authorizeApply(
    "demo",
    { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    {
      confirm: async () => {
        confirmed = true;
        return "should-not-run";
      },
    },
  );
  assert.equal(emulatorId, "demo");
  assert.equal(confirmed, false);

  let prodProject = null;
  const prodId = await authorizeApply("temple-directory-india", {}, {
    confirm: async (project) => {
      prodProject = project;
      return project;
    },
  });
  assert.equal(prodId, "temple-directory-india");
  assert.equal(prodProject, "temple-directory-india");
});

test("dry-run prints the drift report and does not apply", async () => {
  let applied = false;
  let loaded = false;
  const report = await main(["--project", "demo"], {
    env: {},
    load: async () => {
      loaded = true;
      return {
        temples: [
          {
            id: "patan-devi-temple",
            name: "Patan Devi Temple",
            state: "Bihar",
            city: "Patna",
            deity: "Devi",
            address: "Patna, Bihar",
            latitude: 25.6,
            longitude: 85.1,
          },
        ],
        shards: {},
      };
    },
    apply: async () => {
      applied = true;
      return 1;
    },
    log: () => {},
  });
  assert.equal(loaded, true);
  assert.equal(applied, false);
  assert.equal(report.missing.length, 1);
  assert.match(formatReport(report), /Dry-run only/);
  assert.match(formatReport(report), /patan-devi-temple/);
});

test("apply in CI does not load or write", async () => {
  await assert.rejects(
    () =>
      main(["--apply", "--project", "temple-directory-india"], {
        env: { CI: "true" },
        load: async () => {
          throw new Error("loaded");
        },
        apply: async () => {
          throw new Error("applied");
        },
      }),
    /CI/,
  );
});

test("apply re-reads each shard before writing and skips a fresh match", async () => {
  const gets = [];
  const commits = [];
  class FieldPath {
    constructor(...parts) {
      this.parts = parts;
    }
  }
  const admin = {
    firestore: {
      FieldPath,
      FieldValue: {
        delete: () => "delete",
        serverTimestamp: () => "server",
        increment: (n) => ({ increment: n }),
      },
    },
  };
  const shards = {
    bihar: { "patan-devi-temple": { id: "patan-devi-temple", name: "Old" } },
  };
  function db() {
    return {
      collection(name) {
        return {
          doc(id) {
            const ref = {
              path: `${name}/${id}`,
              async get() {
                gets.push(ref.path);
                const entries = shards[id];
                return {
                  exists: entries != null,
                  data: () => ({ entries }),
                };
              },
            };
            return ref;
          },
        };
      },
      batch() {
        const ops = [];
        return {
          set(ref, data, opts) {
            ops.push({ op: "set", path: ref.path, data, opts });
          },
          update(ref, field, value) {
            ops.push({ op: "update", path: ref.path, field, value });
          },
          async commit() {
            commits.push(ops);
          },
        };
      },
    };
  }
  const entry = { id: "patan-devi-temple", name: "Patan Devi", v: 1 };
  const report = {
    removals: [],
    upserts: [{ shard: "bihar", id: "patan-devi-temple", entry }],
  };
  const count = await applyPlan(db(), report, { admin });
  assert.equal(count, 1);
  assert.deepEqual(gets, ["temple_index/bihar", "meta/temple_index"]);
  assert.deepEqual(commits[0][1].opts, { merge: true });
  assert.deepEqual(Object.keys(commits[0][1].data.shards), ["bihar"]);
  assert.equal(commits.length, 1);
  assert.equal(commits[0][0].path, "temple_index/bihar");
  assert.deepEqual(commits[0][0].opts.mergeFields[0].parts, ["entries", "patan-devi-temple"]);
  assert.equal(commits[0][1].path, "meta/temple_index");

  gets.length = 0;
  commits.length = 0;
  shards.bihar["patan-devi-temple"] = { ...entry, updatedAt: "already" };
  const skipped = await applyPlan(db(), report, { admin });
  assert.equal(skipped, 0);
  assert.deepEqual(gets, ["temple_index/bihar"]);
  assert.equal(commits.length, 0);
  assert.equal(writeNeeded({ op: "delete", id: "gone" }, shards.bihar), false);
  assert.equal(writeNeeded({ op: "delete", id: "patan-devi-temple" }, shards.bihar), true);
});

test("apply plans from the read taken immediately before writing", async () => {
  const seen = [];
  await main(["--apply", "--project", "demo"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    load: async () => ({
      temples: [
        {
          id: "fresh-temple",
          name: "Fresh Temple",
          state: "Bihar",
          city: "Patna",
          deity: "Devi",
        },
      ],
      shards: {},
      db: {},
    }),
    apply: async (_id, planned) => {
      seen.push(...planned.missing.map((item) => item.id));
      return planned.missing.length;
    },
    log: () => {},
  });
  assert.deepEqual(seen, ["fresh-temple"]);
});

test("CI workflow runs the unit test and never the apply tool", () => {
  const ci = readFileSync(resolve(repoRoot, ".github/workflows/ci.yml"), "utf8");
  assert.match(ci, /rebuild_index\.test\.js/);
  assert.match(ci, /temple_index_rules\.test\.js/);
  assert.match(ci, /emulators:exec --only firestore --project demo-temple-index/);
  assert.doesNotMatch(ci, /rebuild_index\.js/);
  assert.doesNotMatch(ci, /--apply/);
  assert.doesNotMatch(ci, /temple-directory-india/);
  const source = readFileSync(resolve(repoRoot, "scripts/rebuild_index.js"), "utf8");
  assert.match(source, /confirmProject/);
  assert.match(source, /assertNotCi/);
  assert.match(source, /FIRESTORE_EMULATOR_HOST/);
  const policy =
    "prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI";
  for (const file of [
    "scripts/rebuild_index.js",
    "scripts/resize_cover_thumbs.js",
    "scripts/audit_coords.js",
    "scripts/patch_image_url_mirror.js",
    "scripts/apply_field_patches.js",
    "scripts/seed_state_batch.js",
    "scripts/backfill_cover_photos.js",
    "scripts/clear_placeholder_covers.js",
  ]) {
    const text = readFileSync(resolve(repoRoot, file), "utf8");
    assert.ok(text.includes(policy), file);
    assert.doesNotMatch(text, /from an agent/);
  }
});
