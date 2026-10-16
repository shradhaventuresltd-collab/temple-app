import assert from "node:assert/strict";
import { mkdtempSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, extname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

/** Split so this file does not itself contain the banned call names. */
const banned = ["make" + "Public", "public" + "Read", "all" + "Users"];
const scriptExtensions = new Set([".js", ".mjs", ".cjs", ".ts"]);

function scriptFiles(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (name === "node_modules") continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) scriptFiles(path, out);
    else if (scriptExtensions.has(extname(name))) out.push(path);
  }
  return out;
}

function bannedHits(dir) {
  const hits = [];
  for (const path of scriptFiles(dir)) {
    const text = readFileSync(path, "utf8");
    for (const word of banned) {
      if (text.includes(word)) hits.push(`${path} contains ${word}`);
    }
  }
  return hits;
}

test("scripts do not make a Storage object public", () => {
  assert.deepEqual(bannedHits(here), []);
});

test("the public ACL guard scans module and typescript files", () => {
  const dir = mkdtempSync(join(tmpdir(), "no-public-acl-"));
  try {
    writeFileSync(join(dir, "note.txt"), banned.join(" "));
    writeFileSync(join(dir, "ok.js"), "download token only\n");
    writeFileSync(join(dir, "leak.mjs"), `file.${banned[0]}();\n`);
    writeFileSync(join(dir, "leak.cjs"), `acl = "${banned[1]}";\n`);
    writeFileSync(join(dir, "leak.ts"), `member = "${banned[2]}";\n`);
    const hits = bannedHits(dir).map((hit) => hit.replace(`${dir}/`, ""));
    assert.deepEqual(hits.sort(), [
      `leak.cjs contains ${banned[1]}`,
      `leak.mjs contains ${banned[0]}`,
      `leak.ts contains ${banned[2]}`,
    ].sort());
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
