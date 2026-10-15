/**
 * Merge a reviewed state batch into repo seed data.
 *
 *   node seed_state_batch.js path/to/<state>.json
 *   node seed_state_batch.js path/to/<state>.json --write
 *   node seed_state_batch.js path/to/<state>.json --apply --project <id>
 *
 * Default is --dry-run: validate and print new / changed / unchanged / skipped.
 * Nothing is written. --write updates lib/data/sample_data.dart only.
 * --apply writes Firestore and is for Deployer, in a terminal, after merge.
 * CI must not pass --apply. This script never uploads Storage objects.
 *
 * A slug that already exists in the seed or in prod is rejected. Nothing is
 * overwritten and nothing is renamed. --update is off by default. When it is
 * passed, an existing document may change only city, deity, description,
 * timings, specialities, latitude, and longitude.
 *
 * timings null is stored as null. timings_note is never written.
 * Only review.status "approved" is seeded. Image fields are never written.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { confirmProject } from "./prod_guard.js";
import {
  formatSummary,
  formatWarnings,
  targetShortfall,
  validateStateBatch,
} from "./state_batch.js";
import {
  SAMPLE_DATA_PATH,
  loadSampleTemples,
  mergeTemplesIntoSource,
} from "./temple_seed.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function printUsage() {
  console.log(`
Usage:
  node seed_state_batch.js <state.json> [--dry-run]
  node seed_state_batch.js <state.json> --write
  node seed_state_batch.js <state.json> --apply --project <firebase-project-id>
  node seed_state_batch.js <state.json> --update --write

Default is dry-run. Existing slugs are rejected (no overwrite, no rename).
--update is off unless you pass it. It may change city, deity, description,
timings, specialities, latitude, and longitude on an existing document.
It does not change the name, the state, or imageUrl / images / photos.
--write merges approved temples into lib/data/sample_data.dart (repo only).
--apply writes Firestore temples/{id} for Deployer only. It prompts for the
project id, refuses CI, and does not run unless --project is explicit.
Only review.status "approved" is seeded. timings null stays null.
Do not combine this with Seed or upload_research_pack.js --patch-firestore.
`);
}

function parseArgs(argv) {
  const opts = {
    file: null,
    dryRun: true,
    write: false,
    apply: false,
    update: false,
    project: null,
    help: false,
    samplePath: SAMPLE_DATA_PATH,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--write") opts.write = true;
    else if (arg === "--update") opts.update = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--sample") opts.samplePath = resolve(argv[++i]);
    else if (arg.startsWith("--")) {
      throw new Error(`Unknown argument: ${arg}`);
    } else if (!opts.file) opts.file = resolve(arg);
    else throw new Error(`Unexpected argument: ${arg}`);
  }
  return opts;
}

/** Fields an explicit --update may change. Name, state, and galleries are not included. */
export const UPDATE_FIELDS = Object.freeze([
  "city",
  "deity",
  "description",
  "timings",
  "specialities",
  "latitude",
  "longitude",
]);

/**
 * Firestore fields for one temple.
 * Research batches do not carry image URLs, so imageUrl, images, and photos
 * are never part of the payload. timings_note is never written. timings null
 * stays null.
 * An existing document is refused unless update is true, and then only
 * UPDATE_FIELDS are included.
 * @param {object} temple normalised batch temple
 * @param {object | null} live existing Firestore document, or null to create
 * @param {{ update?: boolean }} [options]
 */
export function firestoreWritePayload(temple, live, options = {}) {
  if (live && options.update !== true) {
    throw new Error(
      `${temple.id} already exists and will not be overwritten or renamed.`,
    );
  }
  if (live) {
    const data = {};
    for (const key of UPDATE_FIELDS) data[key] = temple[key];
    return data;
  }
  return {
    id: temple.id,
    name: temple.name,
    state: temple.state,
    city: temple.city,
    deity: temple.deity,
    description: temple.description,
    timings: temple.timings,
    specialities: temple.specialities,
    latitude: temple.latitude,
    longitude: temple.longitude,
    story: temple.story ?? "",
    address: temple.location ?? `${temple.city}, ${temple.state}`,
  };
}

async function applyToFirestore(project, temples, update) {
  const { readFileSync: read, existsSync } = await import("node:fs");
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) {
    throw new Error(
      "service-account.json was not found in scripts/ or the repo root. No write.",
    );
  }
  const admin = (await import("firebase-admin")).default;
  const serviceAccount = JSON.parse(read(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== project) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${project}. No write.`,
    );
  }
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: project,
    });
  }
  const db = admin.firestore();
  for (const temple of temples) {
    const ref = db.collection("temples").doc(temple.id);
    const snap = await ref.get();
    if (snap.exists && !update) {
      throw new Error(
        `temples/${temple.id} already exists. Refusing to overwrite. No write.`,
      );
    }
    const data = firestoreWritePayload(temple, snap.exists ? snap.data() : null, {
      update,
    });
    if (snap.exists) {
      await ref.update(data);
      console.log(`updated temples/${temple.id}`);
    } else {
      await ref.set({
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`created temples/${temple.id}`);
    }
  }
}

async function main(argv = process.argv.slice(2)) {
  const opts = parseArgs(argv);
  if (opts.help || !opts.file) {
    printUsage();
    process.exit(opts.help ? 0 : 1);
  }
  if (opts.apply && opts.write) {
    throw new Error("Pass either --write or --apply, not both.");
  }

  const batch = JSON.parse(readFileSync(opts.file, "utf8"));
  const { source, temples } = loadSampleTemples(opts.samplePath);
  const result = validateStateBatch(
    batch,
    temples.map((row) => row.temple),
    { update: opts.update },
  );
  const shortfall = targetShortfall(batch);
  if (shortfall) console.log(`Note: ${shortfall}`);
  if (result.warnings.length > 0) console.log(formatWarnings(result.warnings));
  if (!result.ok) {
    console.error("State batch is invalid:");
    for (const error of result.errors) console.error(`  - ${error}`);
    process.exit(1);
  }

  console.log(
    opts.apply
      ? opts.update
        ? "Mode: apply --update"
        : "Mode: apply"
      : opts.write
        ? opts.update
          ? "Mode: write --update"
          : "Mode: write"
        : opts.update
          ? "Mode: dry-run --update"
          : "Mode: dry-run",
  );
  console.log(formatSummary(result.summary));

  if (!opts.write && !opts.apply) {
    console.log("\nDry-run only. No seed file and no Firestore writes.");
    return result;
  }

  if (opts.write) {
    const merged = mergeTemplesIntoSource(source, result.temples);
    writeFileSync(opts.samplePath, merged);
    console.log(`\nWrote ${opts.samplePath}`);
    return result;
  }

  const project = await confirmProject(opts.project);
  console.log(`Applying ${result.temples.length} temples to ${project}.`);
  await applyToFirestore(project, result.temples, opts.update);
  return result;
}

const isDirect = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}

export { main, parseArgs };
