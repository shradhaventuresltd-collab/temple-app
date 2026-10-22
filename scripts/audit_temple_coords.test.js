import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { STATE_BOUNDS } from "./state_batch.js";
import {
  ISSUE_ORDER,
  PUDUCHERRY_ENCLAVES,
  STATE_BBOX,
  auditTemples,
  canonicalState,
  formatBboxTable,
  isSwappedLatLng,
  loadTemplesFromJson,
  main,
  parseArgs,
  puducherryEnclaveAt,
  readOnlyDb,
  urlCharacterFindings,
} from "./audit_temple_coords.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = resolve(here, "..");

function temple(overrides = {}) {
  return {
    id: "example",
    name: "Example Temple",
    state: "Tamil Nadu",
    city: "Madurai",
    address: "Madurai",
    latitude: 9.9195,
    longitude: 78.1193,
    ...overrides,
  };
}

test("state boxes match the directory table and Puducherry is enclaves", () => {
  assert.equal(STATE_BBOX.Puducherry, undefined);
  assert.equal(Object.keys(STATE_BBOX).length, Object.keys(STATE_BOUNDS).length - 1);
  for (const [name, bounds] of Object.entries(STATE_BOUNDS)) {
    if (name === "Puducherry") continue;
    assert.deepEqual(STATE_BBOX[name], bounds);
  }
  assert.match(formatBboxTable(), /Puducherry enclaves:/);
  assert.match(formatBboxTable(), /karaikal:/);
  assert.equal(puducherryEnclaveAt(11.9346, 79.8304), "puducherry");
  assert.equal(puducherryEnclaveAt(10.9254, 79.838), "karaikal");
  assert.equal(puducherryEnclaveAt(11.7011, 75.5364), "mahe");
  assert.equal(puducherryEnclaveAt(16.7333, 82.2167), "yanam");
  assert.equal(puducherryEnclaveAt(13.0827, 80.2707), null);
  const giant = STATE_BOUNDS.Puducherry;
  assert.ok(13.0827 >= giant.latMin && 13.0827 <= giant.latMax);
  assert.ok(80.2707 >= giant.lngMin && 80.2707 <= giant.lngMax);
  assert.equal(PUDUCHERRY_ENCLAVES.puducherry.latMax < 12.2, true);
});

test("classify missing, zero, swapped, india, state, duplicate, and url text", () => {
  assert.equal(isSwappedLatLng(79.8304, 11.9346), true);
  assert.equal(isSwappedLatLng(11.9346, 79.8304), false);
  assert.equal(isSwappedLatLng(0, 0), false);
  assert.equal(canonicalState("Pondicherry"), "Puducherry");
  assert.equal(canonicalState("orissa"), "Odisha");
  assert.deepEqual(urlCharacterFindings("A & B #1 / C, D's அ"), [
    "&",
    "#",
    "/",
    ",",
    "apostrophe",
    "non-ascii",
  ]);

  const report = auditTemples([
    temple({ id: "ok" }),
    temple({ id: "no-lat", latitude: undefined, longitude: 78 }),
    temple({ id: "no-lng", longitude: null }),
    temple({ id: "zero", latitude: 0, longitude: 0 }),
    temple({
      id: "swapped",
      name: "Manakula Vinayagar Temple",
      state: "Puducherry",
      city: "Puducherry",
      address: "M.G. Road, Puducherry",
      latitude: 79.8304,
      longitude: 11.9346,
    }),
    temple({
      id: "chennai-as-puducherry",
      state: "Puducherry",
      city: "Puducherry",
      address: "Puducherry",
      latitude: 13.0827,
      longitude: 80.2707,
    }),
    temple({
      id: "karaikal-pin",
      name: "Saneeswaran Temple",
      state: "Puducherry",
      city: "Karaikal",
      address: "Thirunallar, Karaikal",
      latitude: 10.9254,
      longitude: 79.838,
    }),
    temple({
      id: "karaikal-in-town",
      name: "Saneeswaran Temple",
      state: "Puducherry",
      city: "Karaikal",
      address: "Karaikal, Puducherry",
      latitude: 11.9346,
      longitude: 79.8304,
    }),
    temple({
      id: "mahe-pin",
      state: "Pondicherry",
      city: "Mahe",
      address: "Mahe",
      latitude: 11.7011,
      longitude: 75.5364,
    }),
    temple({
      id: "yanam-pin",
      state: "Puducherry",
      city: "Yanam",
      address: "Yanam",
      latitude: 16.7333,
      longitude: 82.2167,
    }),
    temple({
      id: "maheswara",
      name: "Yaganti Uma Maheswara Temple",
      state: "Andhra Pradesh",
      city: "Yaganti",
      address: "Yaganti, Andhra Pradesh",
      latitude: 15.350833,
      longitude: 78.138,
    }),
    temple({ id: "dup-a", latitude: 11.9346, longitude: 79.8304, state: "Tamil Nadu" }),
    temple({ id: "dup-b", name: "Other", latitude: 11.9346, longitude: 79.8304, state: "Tamil Nadu" }),
    temple({
      id: "tricky",
      name: "Sri Ayyappan & Parvati's Temple, Pondicherry #1 / Gopuram அ",
      address: "Road\nLane",
      latitude: 11.9346,
      longitude: 79.8304,
    }),
    temple({
      id: "long",
      name: "N".repeat(181),
      address: "A".repeat(181),
      latitude: 10.5,
      longitude: 78.5,
    }),
    temple({ id: "blank-state", state: "", latitude: 11.9346, longitude: 79.8304 }),
    { id: "strings", name: "String Coords", state: "Goa", city: "Panaji", latitude: "15.5", longitude: "73.8", address: "Panaji" },
  ]);

  const byId = Object.fromEntries(report.rows.map((row) => [row.id, row]));
  assert.deepEqual(byId.ok.issues, []);
  assert.deepEqual(byId["no-lat"].issues, ["missing-lat"]);
  assert.ok(byId["no-lng"].issues.includes("missing-lng"));
  assert.deepEqual(byId.zero.issues, ["zero-zero"]);
  assert.ok(byId.swapped.issues.includes("swapped"));
  assert.ok(byId.swapped.issues.includes("outside-india"));
  assert.ok(byId.swapped.issues.includes("outside-state"));
  assert.ok(byId["chennai-as-puducherry"].issues.includes("outside-state"));
  assert.equal(byId["chennai-as-puducherry"].issues.includes("wrong-enclave"), false);
  assert.equal(byId["karaikal-pin"].issues.includes("outside-state"), false);
  assert.equal(byId["karaikal-pin"].issues.includes("wrong-enclave"), false);
  assert.ok(byId["karaikal-in-town"].issues.includes("wrong-enclave"));
  assert.equal(byId["mahe-pin"].issues.includes("outside-state"), false);
  assert.equal(byId["yanam-pin"].issues.includes("outside-state"), false);
  assert.equal(byId.maheswara.issues.includes("wrong-enclave"), false);
  assert.equal(byId.maheswara.issues.includes("outside-state"), false);
  assert.ok(byId["dup-a"].issues.includes("duplicate"));
  assert.ok(byId["dup-b"].issues.includes("duplicate"));
  assert.match(byId["dup-a"].detail, /dup-b/);
  assert.ok(byId.tricky.issues.includes("name-url"));
  assert.ok(byId.tricky.issues.includes("address-url"));
  assert.match(byId.tricky.detail, /&/);
  assert.match(byId.tricky.detail, /non-ascii/);
  assert.ok(byId.long.issues.includes("name-long"));
  assert.ok(byId.long.issues.includes("address-long"));
  assert.ok(byId["blank-state"].issues.includes("unknown-state"));
  assert.deepEqual(byId.strings.issues, []);
  assert.equal(report.counts["duplicate-groups"], 1);
  assert.equal(report.counts.puducherry >= 4, true);
  assert.ok(report.csv.startsWith("id,name,state,city,latitude,longitude,issues,detail\n"));
  assert.match(report.csv, /chennai-as-puducherry/);
  assert.equal(report.csv.includes("\nok,"), false);
  for (const code of ISSUE_ORDER) assert.equal(typeof report.counts[code], "number");
});

test("Puducherry names the union territory and is valid in every enclave", () => {
  function issues(id, extra) {
    const report = auditTemples([
      temple({
        id,
        state: "Puducherry",
        city: "Puducherry",
        address: "Puducherry",
        ...extra,
      }),
    ]);
    return report.rows[0];
  }

  const before = issues("before-address", {
    name: "Rajacholeeswarar Temple",
    city: "Thirumalairayanpattinam",
    address: "Thirumalairayanpattinam, Puducherry",
    latitude: 10.87,
    longitude: 79.83,
  });
  assert.equal(before.issues.includes("wrong-enclave"), false);
  assert.equal(before.issues.includes("outside-state"), false);
  assert.ok(before.issues.includes("address-url"));

  const after = issues("after-address", {
    city: "Thirumalairayanpattinam",
    address: "Thirumalairayanpattinam, Karaikal, Puducherry",
    latitude: 10.9,
    longitude: 79.82,
  });
  assert.equal(after.issues.includes("wrong-enclave"), false);
  assert.equal(after.issues.includes("outside-state"), false);

  const nedungadu = issues("nedungadu", {
    city: "Nedungadu",
    address: "Nedungadu, Karaikal, Puducherry",
    latitude: 10.91,
    longitude: 79.81,
  });
  assert.equal(nedungadu.issues.includes("wrong-enclave"), false);

  const dharmapuram = issues("dharmapuram", {
    city: "Dharmapuram",
    address: "Dharmapuram, Karaikal, Puducherry",
    latitude: 10.88,
    longitude: 79.84,
  });
  assert.equal(dharmapuram.issues.includes("wrong-enclave"), false);

  const utOnly = issues("ut-only", {
    city: "Puducherry",
    address: "Thirumalairayanpattinam, Puducherry",
    latitude: 10.86,
    longitude: 79.85,
  });
  assert.equal(utOnly.issues.includes("wrong-enclave"), false);

  const maheNamed = issues("mahe-named", {
    city: "Mahe",
    address: "Mahe, Puducherry",
    latitude: 10.87,
    longitude: 79.83,
  });
  assert.ok(maheNamed.issues.includes("wrong-enclave"));
  assert.match(maheNamed.detail, /named mahe but coordinates are in karaikal/);
  assert.equal(maheNamed.issues.includes("outside-state"), false);

  const utAtMahe = issues("ut-at-mahe", {
    address: "Puducherry",
    latitude: 11.701,
    longitude: 75.536,
  });
  assert.equal(utAtMahe.issues.includes("wrong-enclave"), false);
  assert.equal(utAtMahe.issues.includes("outside-state"), false);

  const utAtYanam = issues("ut-at-yanam", {
    city: "Puducherry",
    address: "Pondicherry",
    latitude: 16.73,
    longitude: 82.22,
  });
  assert.equal(utAtYanam.issues.includes("wrong-enclave"), false);
  assert.equal(utAtYanam.issues.includes("outside-state"), false);

  const stillWrong = issues("still-wrong", {
    city: "Karaikal",
    address: "Karaikal, Puducherry",
    latitude: 11.94,
    longitude: 79.83,
  });
  assert.ok(stillWrong.issues.includes("wrong-enclave"));
  assert.match(stillWrong.detail, /named karaikal but coordinates are in puducherry/);

  const namedOutside = issues("karaikal-outside", {
    city: "Karaikal",
    address: "Karaikal, Puducherry",
    latitude: 13.0827,
    longitude: 80.2707,
  });
  assert.ok(namedOutside.issues.includes("outside-state"));
  assert.equal(namedOutside.issues.includes("wrong-enclave"), false);

  const mixed = issues("mixed-enclaves", {
    city: "Karaikal",
    address: "Karaikal and Mahe, Puducherry",
    latitude: 10.89,
    longitude: 79.8,
  });
  assert.ok(mixed.issues.includes("wrong-enclave"));
  assert.match(mixed.detail, /named mahe but coordinates are in karaikal/);
});

test("json exports and service accounts", () => {
  const fromArray = loadTemplesFromJson([
    { slug: "one", name: "One", state: "Goa", latitude: 15.5, longitude: 73.8 },
  ]);
  assert.equal(fromArray[0].id, "one");
  const fromMap = loadTemplesFromJson({
    temples: { two: { name: "Two", state: "Goa", lat: 15.5, lng: 73.8 } },
  });
  assert.equal(fromMap[0].id, "two");
  assert.equal(fromMap[0].latitude, 15.5);
  const fromRest = loadTemplesFromJson({
    documents: [
      {
        name: "projects/p/databases/(default)/documents/temples/three",
        fields: {
          name: { stringValue: "Three" },
          state: { stringValue: "Goa" },
          latitude: { doubleValue: "15.5" },
          longitude: { integerValue: "74" },
          address: { nullValue: null },
        },
      },
    ],
  });
  assert.equal(fromRest[0].id, "three");
  assert.equal(fromRest[0].latitude, 15.5);
  assert.equal(fromRest[0].longitude, 74);
  assert.throws(
    () => loadTemplesFromJson({ type: "service_account", private_key: "secret" }),
    /service-account/,
  );
});

test("read-only client and flags refuse writes", async () => {
  let wrote = false;
  const db = readOnlyDb({
    collection(name) {
      return {
        name,
        async get() {
          return { docs: [] };
        },
        doc() {
          return {
            set() {
              wrote = true;
            },
          };
        },
      };
    },
    batch() {
      wrote = true;
      return { commit() { wrote = true; } };
    },
  });
  await db.collection("temples").get();
  assert.throws(() => db.batch(), /read-only/);
  assert.throws(() => db.collection("temples").doc("x").set({ a: 1 }), /read-only/);
  assert.equal(wrote, false);
  assert.throws(() => parseArgs(["--apply", "--seed"]), /read-only/);
  assert.throws(() => parseArgs(["--write"]), /read-only/);
  assert.throws(() => parseArgs(["--delete", "--json", "x"]), /read-only/);

  const source = readFileSync(new URL("./audit_temple_coords.js", import.meta.url), "utf8");
  assert.doesNotMatch(
    source,
    /\.(set|update|delete|create|add|batch|commit|bulkWriter|runTransaction|recursiveDelete)\s*\(/,
  );
});

test("cli refuses apply and cloud reads from CI", async () => {
  const cli = spawnSync(
    process.execPath,
    [resolve(repoRoot, "scripts/audit_temple_coords.js"), "--apply", "--seed"],
    { cwd: repoRoot, encoding: "utf8" },
  );
  assert.notEqual(cli.status, 0);
  assert.match(cli.stderr, /read-only/);

  let loaded = false;
  await assert.rejects(
    () =>
      main(["--project", "temple-directory-india"], {
        env: { CI: "true" },
        log: () => {},
        loadFirestore: async () => {
          loaded = true;
          return [];
        },
      }),
    /CI/,
  );
  assert.equal(loaded, false);
});

test("seed audit runs locally and finds no Puducherry rows", async () => {
  const dir = mkdtempSync(join(tmpdir(), "temple-audit-"));
  const out = join(dir, "audit.csv");
  const lines = [];
  const report = await main(["--seed", "--out", out], { log: (line) => lines.push(line) });
  assert.equal(report.counts.puducherry, 0);
  assert.equal(report.counts["zero-zero"], 0);
  assert.equal(report.counts.swapped, 0);
  assert.equal(report.counts["missing-lat"], 0);
  assert.equal(report.counts["missing-lng"], 0);
  assert.equal(report.counts["outside-india"], 0);
  assert.equal(report.counts["outside-state"], 0);
  assert.equal(report.counts["wrong-enclave"], 0);
  assert.equal(report.counts.duplicate, 0);
  assert.ok(report.counts.temples > 100);
  assert.ok(report.counts["name-url"] > 0);
  assert.ok(report.counts["address-url"] > 0);
  const csv = readFileSync(out, "utf8");
  assert.equal(csv, report.csv);
  assert.match(lines.join("\n"), /Mode: read-only/);
  assert.match(lines.join("\n"), /No Firestore writes/);

  const jsonOut = join(dir, "from-json.csv");
  const exported = report.rows.map((row) => ({
    id: row.id,
    name: row.name,
    state: row.state,
    city: row.city,
    latitude: row.latitude === "" ? null : row.latitude,
    longitude: row.longitude === "" ? null : row.longitude,
  }));
  const jsonPath = join(dir, "seed.json");
  writeFileSync(jsonPath, JSON.stringify(exported));
  const again = await main(["--json", jsonPath, "--out", jsonOut], { log: () => {} });
  assert.equal(again.counts.temples, report.counts.temples);
  assert.equal(again.counts.swapped, 0);
  assert.equal(again.counts.puducherry, 0);
});
