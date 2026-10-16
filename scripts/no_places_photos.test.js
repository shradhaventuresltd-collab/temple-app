import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const repo = dirname(dirname(fileURLToPath(import.meta.url)));
const placesHost = "places.googleapis" + ".com";
const mapsPlacePhoto = "maps.googleapis" + ".com/maps/api/place/photo";
const lh3Host = "lh3.googleusercontent" + ".com";
const placesFile = /image_\d+\.(?:jpe?g|png|webp)/i;

function filesUnder(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (name === "node_modules" || name === ".git") continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) filesUnder(path, out);
    else out.push(path);
  }
  return out;
}

test("seed and import paths cannot call the Places photo API", () => {
  const roots = ["lib", "scripts", "docs", "tools"].map((name) => join(repo, name));
  const hits = [];
  for (const root of roots) {
    for (const path of filesUnder(root)) {
      if (path.endsWith(".test.js") || path.endsWith(".test.dart")) continue;
      const text = readFileSync(path, "utf8");
      if (text.includes(placesHost) || text.includes(mapsPlacePhoto) || text.includes(lh3Host)) {
        hits.push(path);
      }
    }
  }
  assert.deepEqual(hits, []);
});

test("package.json does not run the removed Places uploader", () => {
  const pkg = JSON.parse(readFileSync(join(repo, "scripts/package.json"), "utf8"));
  assert.equal(pkg.scripts.upload, undefined);
  assert.equal(JSON.stringify(pkg.scripts).includes("upload_temple_images"), false);
});

test("sample data does not embed a Places mirror filename", () => {
  const sample = readFileSync(join(repo, "lib/data/sample_data.dart"), "utf8");
  assert.equal(placesFile.test(sample), false);
});

test("state-batch seed writes do not carry image fields", () => {
  const source = readFileSync(join(repo, "scripts/seed_state_batch.js"), "utf8");
  const start = source.indexOf("export function firestoreWritePayload");
  const end = source.indexOf("export function assertIdsAbsent");
  const body = source.slice(start, end);
  assert.equal(body.includes("imageUrl"), false);
  assert.equal(body.includes("photos"), false);
  assert.equal(body.includes("images"), false);
});
