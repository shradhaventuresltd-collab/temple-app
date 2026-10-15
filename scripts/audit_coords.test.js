import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  applyCoordinatePlans,
  authorizeApply,
  coordinateIssue,
  formatCoordinateReport,
  main,
  parseArgs,
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
