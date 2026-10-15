import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { firestoreWritePayload } from "./seed_state_batch.js";
import {
  authorizeApply,
  credentialMode,
  formatReport,
  main,
  parseArgs,
  resolveProject,
} from "./rebuild_index.js";
import {
  batchRounds,
  coverThumb,
  diffIndex,
  entryFromTemple,
  indexFlags,
  planOps,
  stateSlug,
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

test("cover thumb drops full image URLs and rewrites wide Wikimedia thumbs", () => {
  assert.equal(
    coverThumb({
      imageUrl: "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg",
    }),
    null,
  );
  assert.equal(
    coverThumb({
      imageUrl:
        "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg",
    }),
    "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/480px-File.jpg",
  );
  assert.equal(
    coverThumb({
      imageUrl: "https://picsum.photos/seed/temple/800/600",
    }),
    null,
  );
  const storage =
    "https://firebasestorage.googleapis.com/v0/b/app/o/temples%2Fid%2F171000_480.jpg?alt=media";
  assert.equal(coverThumb({ imageUrl: storage }), storage);
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

test("CI workflow runs the unit test and never the apply tool", () => {
  const ci = readFileSync(resolve(repoRoot, ".github/workflows/ci.yml"), "utf8");
  assert.match(ci, /rebuild_index\.test\.js/);
  assert.doesNotMatch(ci, /rebuild_index\.js/);
  assert.doesNotMatch(ci, /--apply/);
  const source = readFileSync(resolve(repoRoot, "scripts/rebuild_index.js"), "utf8");
  assert.match(source, /confirmProject/);
  assert.match(source, /assertNotCi/);
  assert.match(source, /FIRESTORE_EMULATOR_HOST/);
});
