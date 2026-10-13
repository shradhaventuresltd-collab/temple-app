/**
 * Read tools/photo-packs ATTRIBUTION.md files and map each licence onto
 * CC-BY | CC-BY-SA | CC0 | Own | Permission.
 *
 * CC0 sources ("CC0", "CC0 1.0", Creative Commons Zero) map to CC0.
 * "Public domain" does not.
 *
 * This does not write Firestore and does not backfill existing temple
 * documents. It only prints the mapping so operators can review it.
 *
 *   node scripts/backfill_attribution.js
 *   node scripts/backfill_attribution.js --pack tools/photo-packs/nataraja-temple
 */
import { existsSync, readdirSync, readFileSync } from "fs";
import { basename, dirname, resolve } from "path";
import { fileURLToPath } from "url";

import { parseAttributionLicences } from "./photo_licence.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packsRoot = resolve(__dirname, "..", "tools", "photo-packs");

function packDirs(argv) {
  const packFlag = argv.indexOf("--pack");
  if (packFlag !== -1) {
    const dir = resolve(process.cwd(), argv[packFlag + 1] || "");
    return [dir];
  }
  return readdirSync(packsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => resolve(packsRoot, entry.name))
    .filter((dir) => existsSync(resolve(dir, "ATTRIBUTION.md")))
    .sort();
}

function main() {
  const dirs = packDirs(process.argv.slice(2));
  const counts = {};
  let unmapped = 0;
  let cc0 = 0;

  for (const dir of dirs) {
    const markdown = readFileSync(resolve(dir, "ATTRIBUTION.md"), "utf8");
    const entries = parseAttributionLicences(markdown);
    console.log(`${basename(dir)} (${entries.length})`);
    for (const entry of entries) {
      const label = entry.licence || "(unmapped)";
      counts[label] = (counts[label] || 0) + 1;
      if (entry.licence === "CC0") cc0 += 1;
      if (!entry.licence) unmapped += 1;
      console.log(`  ${entry.file}: ${entry.license || "(none)"} → ${label}`);
    }
  }

  console.log("\nSummary (no Firestore writes):");
  for (const [label, count] of Object.entries(counts).sort()) {
    console.log(`  ${label}: ${count}`);
  }
  console.log(`  CC0 accepted: ${cc0}`);
  console.log(`  unmapped (includes Public domain): ${unmapped}`);
}

main();
