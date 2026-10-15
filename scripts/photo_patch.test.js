import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { loadPatches } from "./apply_field_patches.js";
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
