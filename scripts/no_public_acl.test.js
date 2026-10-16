import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

/** Split so this file does not itself contain the banned call names. */
const banned = ["make" + "Public", "public" + "Read"];

function scriptFiles(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (name === "node_modules") continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) scriptFiles(path, out);
    else if (name.endsWith(".js")) out.push(path);
  }
  return out;
}

test("scripts do not make a Storage object public", () => {
  const hits = [];
  for (const path of scriptFiles(here)) {
    const text = readFileSync(path, "utf8");
    for (const word of banned) {
      if (text.includes(word)) hits.push(`${path} contains ${word}`);
    }
  }
  assert.deepEqual(hits, []);
});
