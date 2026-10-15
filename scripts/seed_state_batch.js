/**
 * Merge a reviewed state batch into repo seed data.
 *
 *   node seed_state_batch.js path/to/<state>.json
 *   node seed_state_batch.js path/to/<state>.json --write
 *   node seed_state_batch.js path/to/<state>.json --apply --project <id>
 *
 * Default is --dry-run: validate and print new / changed / unchanged.
 * Nothing is written. --write updates lib/data/sample_data.dart only.
 * --apply writes Firestore and is for Deployer, in a terminal, after merge.
 * CI must not pass --apply. This script never uploads Storage objects.
 *
 * On an existing temple, imageUrl, images, and photos are left untouched
 * when that document already has a verified gallery. Picsum, placeholder,
 * and stock URLs are not treated as a gallery.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { confirmProject } from "./prod_guard.js";
import {
  formatSummary,
  hasVerifiedGallery,
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

Default is dry-run. --write merges into lib/data/sample_data.dart (repo only).
--apply updates Firestore temples/{id} for Deployer only. It prompts for the
project id, refuses CI, and does not run unless --project is explicit.
A verified live gallery is not replaced. Do not combine this with Seed or
upload_research_pack.js --patch-firestore.
`);
}

function parseArgs(argv) {
  const opts = {
    file: null,
    dryRun: true,
    write: false,
    apply: false,
    project: null,
    help: false,
    samplePath: SAMPLE_DATA_PATH,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--write") opts.write = true;
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

/**
 * Firestore fields for one temple.
 * When [live] already has a verified gallery, imageUrl, images, and photos
 * are omitted so --apply cannot overwrite them. story and address are
 * omitted on update because research batches must not carry those fields.
 * @param {object} temple normalised batch temple
 * @param {object | null} live existing Firestore document, or null to create
 */
export function firestoreWritePayload(temple, live) {
  const data = {
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
  };
  if (!live) {
    data.story = temple.story ?? "";
    data.address = temple.location ?? `${temple.city}, ${temple.state}`;
  }
  if (!hasVerifiedGallery(live) && Array.isArray(temple.images) && temple.images.length > 0) {
    data.imageUrl = temple.images[0];
    data.images = temple.images;
    if (Array.isArray(temple.photos) && temple.photos.length > 0) {
      data.photos = temple.photos.map((photo) => ({
        url: photo.url,
        credit: photo.credit,
        licence: photo.licence,
        order: photo.order,
      }));
    }
  }
  return data;
}

async function applyToFirestore(project, temples) {
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
    const data = firestoreWritePayload(temple, snap.exists ? snap.data() : null);
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
  );
  if (!result.ok) {
    console.error("State batch is invalid:");
    for (const error of result.errors) console.error(`  - ${error}`);
    process.exit(1);
  }

  console.log(opts.apply ? "Mode: apply" : opts.write ? "Mode: write" : "Mode: dry-run");
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
  await applyToFirestore(project, result.temples);
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
