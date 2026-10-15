import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  applyCoordinatePlans,
  authorizeApply,
  commitCoordinateNull,
  coordinateIssue,
  formatCoordinateReport,
  main,
  parseArgs,
  persistCoordinateNull,
  planCoordinateAudit,
} from "./audit_coords.js";

const here = dirname(fileURLToPath(import.meta.url));
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };

test("unpaired coordinates are planned and paired ones are not", () => {
  assert.equal(coordinateIssue({ latitude: 12, longitude: 80 }), null);
  assert.equal(coordinateIssue({ latitude: null, longitude: null }), null);
  assert.equal(coordinateIssue({}), null);
  assert.equal(coordinateIssue({ latitude: 0, longitude: 0 }), null);
  assert.equal(coordinateIssue({ latitude: 12.6 }), "latitude-only");
  assert.equal(coordinateIssue({ latitude: 12.6, longitude: null }), "latitude-only");
  assert.equal(coordinateIssue({ longitude: 80 }), "longitude-only");
  const plans = planCoordinateAudit([
    { id: "paired", latitude: 1, longitude: 2 },
    { id: "half", latitude: 12.6, longitude: null },
  ]);
  assert.equal(plans[0].action, "ok");
  assert.equal(plans[1].action, "null-both");
  assert.equal(plans[1].reason, "latitude-only");
  const missing = planCoordinateAudit([{ id: "open", latitude: 12.6 }]);
  assert.equal(missing[0].longitudePresent, false);
  assert.match(
    formatCoordinateReport([{ ...missing[0], result: "would-null" }]),
    /would-null open latitude-only latitude=12\.6 longitude=missing/,
  );
});

test("dry-run lists unpaired docs and does not write", async () => {
  const updates = [];
  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: emulator,
    log: (line) => lines.push(line),
    load: async () => [
      { id: "paired", latitude: 1, longitude: 2 },
      { id: "half", latitude: 12.6, longitude: null },
    ],
    update: async (id, data) => {
      updates.push({ id, data });
    },
  });
  assert.equal(updates.length, 0);
  assert.equal(rows.find((row) => row.id === "half").result, "would-null");
  assert.match(lines.join("\n"), /unpaired: 1/);
  assert.match(
    lines.join("\n"),
    /would-null half latitude-only latitude=12\.6 longitude=null/,
  );
  assert.match(formatCoordinateReport(rows), /Dry-run only/);
});

test("apply nulls both axes and refuses CI", async () => {
  const updates = [];
  const rows = await main(["--apply", "--project", "demo-temple-index"], {
    env: emulator,
    log: () => {},
    confirm: async () => {
      throw new Error("emulator apply must not prompt");
    },
    load: async () => [{ id: "half", latitude: null, longitude: 80 }],
    update: async (id, data) => {
      updates.push({ id, data });
    },
  });
  assert.deepEqual(updates, [{ id: "half", data: { latitude: null, longitude: null } }]);
  assert.equal(rows[0].result, "nulled");

  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: { CI: "true", ...emulator },
        log: () => {},
        load: async () => {
          throw new Error("load should not run");
        },
      }),
    /CI/,
  );
});

test("apply re-reads and skips a document that changed", async () => {
  const updates = [];
  const db = {
    collection() {
      return { doc(id) { return { id }; } };
    },
    async runTransaction(fn) {
      return fn({
        async get(ref) {
          return {
            exists: true,
            id: ref.id,
            data: () => ({ latitude: 12.6, longitude: null }),
          };
        },
        update(ref, data) {
          updates.push({ id: ref.id, data });
        },
      });
    },
  };
  const nulled = await persistCoordinateNull(db, "half");
  assert.equal(nulled.ok, true);
  assert.equal(nulled.latitude, 12.6);
  assert.equal(nulled.longitude, null);
  assert.deepEqual(updates, [{ id: "half", data: { latitude: null, longitude: null } }]);

  const paired = {
    collection() {
      return { doc(id) { return { id }; } };
    },
    async runTransaction(fn) {
      return fn({
        async get(ref) {
          return {
            exists: true,
            id: ref.id,
            data: () => ({ latitude: 12.6, longitude: 80 }),
          };
        },
        update() {
          throw new Error("a paired document must not be nulled");
        },
      });
    },
  };
  const skipped = await persistCoordinateNull(paired, "half");
  assert.equal(skipped.ok, false);
  assert.equal(skipped.reason, "paired");

  const changed = commitCoordinateNull(
    { latitude: 1, longitude: null, updateTime: "t2" },
    { updateTime: "t1" },
  );
  assert.equal(changed.ok, false);
  assert.equal(changed.reason, "changed");

  const rows = await applyCoordinatePlans(
    [
      {
        id: "half",
        action: "null-both",
        reason: "latitude-only",
        latitude: 12.6,
        longitude: null,
        latitudePresent: true,
        longitudePresent: true,
      },
    ],
    {
      dryRun: false,
      update: async () => ({ ok: false, reason: "paired" }),
    },
  );
  assert.equal(rows[0].result, "skipped");
  assert.equal(rows[0].reason, "paired");
});

test("prod apply without a project is refused", async () => {
  assert.throws(() => parseArgs(["--apply", "--nope"]), /Unknown argument/);
  await assert.rejects(() => authorizeApply("", {}), /project/);
});

test("apply plans do not deploy", async () => {
  const source = readFileSync(resolve(here, "audit_coords.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.doesNotMatch(source, /firebase deploy/);
  const updates = [];
  await applyCoordinatePlans(
    [{ id: "ok-temple", action: "ok" }],
    {
      dryRun: false,
      update: async (id) => updates.push(id),
    },
  );
  assert.equal(updates.length, 0);
});
