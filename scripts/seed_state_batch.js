/**
 * Merge a reviewed state batch into repo seed data.
 *
 *   node seed_state_batch.js path/to/<state>.json
 *   node seed_state_batch.js path/to/<state>.json --write
 *   node seed_state_batch.js path/to/<state>.json --apply --project <id>
 *
 * Default is --dry-run: validate and print new / changed / unchanged / skipped.
 * Nothing is written. --write updates lib/data/sample_data.dart only.
 * --apply writes Firestore after merge. This script never uploads Storage objects.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 *
 * A slug that already exists in the seed or in prod is always rejected.
 * Nothing is overwritten and nothing is renamed.
 *
 * timings null is stored as null. timings_note is never written.
 * story is the sourced description (2–4 sentences).
 * Only review.status "approved" is seeded. Image fields are never written.
 * --apply pre-checks every state before the first commit: temple ids are
 * absent, meta/temple_index and each target shard are read, and existing
 * plus new entry keys stay at or under 400. Any failure aborts with no
 * write, including other states in the same run. Only then does it
 * create() each temple and merge entries.{id}. An existing shard is not
 * replaced. The meta write sets indexVersion and only the touched shards'
 * timestamps. When the creates, shard merges, and that one meta write fit
 * in 500 operations, they commit together. A larger run is one batch per
 * state shard. Each of those later commits can succeed after an earlier
 * one has already landed, so a crash mid-run can leave the earlier states
 * written. The pre-check cannot roll back a commit that already succeeded.
 * rebuild_index.js is a repair tool, not a required follow-up.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { confirmProject } from "./prod_guard.js";
import { redactDownloadToken } from "./redact_url.js";
import {
  entryFromTemple,
  FIRESTORE_BATCH_LIMIT,
  MAX_ENTRIES,
  planSeedIndexBatches,
} from "./temple_index.js";
import {
  formatInfo,
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

Default is dry-run. Existing slugs are always rejected (no overwrite, no rename).
--write merges approved temples into lib/data/sample_data.dart (repo only).
--apply writes Firestore temples/{id}, plus a merged
entries.{id} on the matching temple_index shard and a meta increment.
prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
It prompts for the project id and does not run unless --project
is explicit. Only review.status "approved" is seeded. timings null stays null.
story is copied from the description. Deploy firestore.rules before writing
any null-timings document. --apply reads every temple id, meta, and each target shard first.
An existing id, or a shard whose existing plus new keys would pass 400,
aborts the whole run before the first commit. Nothing is written for the
other states either. It then creates the temple docs and merges the
entries. When those writes fit in 500 operations they commit as one
batch. A larger run is one batch per state shard. A later commit can
fail after an earlier one has landed.
Do not combine this with Seed or upload_research_pack.js --patch-firestore.
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
 * Research batches do not carry image URLs, so imageUrl, images, and photos
 * are never part of the payload. timings_note is never written. timings null
 * stays null. story is the description.
 * An existing document is always refused.
 * @param {object} temple normalised batch temple
 * @param {object | null} live existing Firestore document, or null to create
 */
export function firestoreWritePayload(temple, live) {
  if (live) {
    throw new Error(
      `${temple.id} already exists and will not be overwritten or renamed.`,
    );
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

/**
 * Refuse the whole batch when any id is already present. No document is written.
 * @param {object[]} temples
 * @param {Set<string>} existingIds
 */
export function assertIdsAbsent(temples, existingIds) {
  const taken = [];
  for (const temple of temples) {
    if (existingIds.has(String(temple.id))) taken.push(temple.id);
  }
  if (taken.length > 0) {
    throw new Error(
      `Refusing to write. These ids already exist: ${taken.join(", ")}. No write.`,
    );
  }
}

async function openSeedFirestore(project, admin) {
  const { readFileSync: read, existsSync } = await import("node:fs");
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    if (admin.apps.length === 0) {
      admin.initializeApp({ projectId: project });
    }
    return admin.firestore();
  }
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
  return admin.firestore();
}

/**
 * Create temple docs and merge their index entries.
 *
 * Pre-checks every state before the first commit: temple ids are absent,
 * meta and each target shard are read, and existing plus new keys stay at
 * or under 400. Any failure throws with no write. Shard writes are
 * set(mergeFields) on entries.{id}. The meta write sends only the touched
 * shards' timestamps. Rounds that fit in 500 operations share one batch.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {object[]} temples normalised temples (id, name, state, ...)
 * @param {typeof import("firebase-admin")} admin
 */
export async function applySeedBatches(db, temples, admin) {
  if (temples.length === 0) return;
  const rounds = planSeedIndexBatches(temples);
  const metaRef = db.collection("meta").doc("temple_index");
  const metaSnap = await metaRef.get();

  const refs = temples.map((temple) => db.collection("temples").doc(temple.id));
  const snaps = refs.length === 0 ? [] : await db.getAll(...refs);
  const overCap = [];
  for (const round of rounds) {
    const snap = await db.collection("temple_index").doc(round.shard).get();
    const existing =
      snap.exists && snap.data()?.entries && typeof snap.data().entries === "object"
        ? snap.data().entries
        : {};
    const keys = new Set(Object.keys(existing));
    for (const temple of round.temples) keys.add(String(temple.id));
    if (keys.size > MAX_ENTRIES) {
      overCap.push(
        `Shard ${round.shard} would have ${keys.size} entries; max is ${MAX_ENTRIES}`,
      );
    }
  }
  const taken = snaps.filter((snap) => snap.exists).map((snap) => snap.id);
  if (taken.length > 0 || overCap.length > 0) {
    const reasons = [];
    if (taken.length > 0) reasons.push(`these ids already exist: ${taken.join(", ")}`);
    if (overCap.length > 0) reasons.push(overCap.join("; "));
    throw new Error(`Refusing to write. ${reasons.join(". ")}. No write.`);
  }

  const staged = [];
  for (const round of rounds) {
    const entries = {};
    const creates = [];
    for (const temple of round.temples) {
      const data = firestoreWritePayload(temple, null);
      const entry = entryFromTemple({ ...data, id: temple.id });
      entry.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      entries[temple.id] = entry;
      creates.push({ id: temple.id, data });
    }
    staged.push({ shard: round.shard, entries, creates });
  }

  let metaExists = metaSnap.exists;
  for (const group of planSeedCommits(staged)) {
    const batch = db.batch();
    const touched = [];
    for (const round of group) {
      for (const temple of round.creates) {
        batch.create(db.collection("temples").doc(temple.id), {
          ...temple.data,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      batch.set(
        db.collection("temple_index").doc(round.shard),
        { entries: round.entries },
        { mergeFields: Object.keys(round.entries).map((id) => `entries.${id}`) },
      );
      touched.push(round.shard);
    }
    writeSeedMeta(batch, metaRef, metaExists, touched, admin);
    await batch.commit();
    metaExists = true;
    for (const round of group) {
      for (const temple of round.creates) {
        console.log(`created temples/${temple.id}`);
      }
    }
  }
}

/**
 * One group when every create, shard merge, and the single meta write fit
 * in [maxOps]. Otherwise one group per state, which is several commits.
 * @param {{ shard: string, creates: object[] }[]} rounds
 * @param {number} [maxOps]
 */
export function planSeedCommits(rounds, maxOps = FIRESTORE_BATCH_LIMIT) {
  const ops = rounds.reduce((sum, round) => sum + round.creates.length + 1, 1);
  if (rounds.length <= 1 || ops <= maxOps) return [rounds];
  return rounds.map((round) => [round]);
}

function writeSeedMeta(batch, metaRef, exists, shards, admin) {
  const stamp = () => admin.firestore.FieldValue.serverTimestamp();
  if (!exists) {
    const map = {};
    for (const name of shards) map[name] = stamp();
    batch.set(metaRef, { indexVersion: 1, shards: map });
    return;
  }
  const patch = { indexVersion: admin.firestore.FieldValue.increment(1) };
  for (const name of shards) patch[`shards.${name}`] = stamp();
  batch.update(metaRef, patch);
}

async function applyToFirestore(project, temples) {
  const admin = (await import("firebase-admin")).default;
  const db = await openSeedFirestore(project, admin);
  await applySeedBatches(db, temples, admin);
}

async function main(argv = process.argv.slice(2), deps = {}) {
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
  const shortfall = targetShortfall(batch);
  if (shortfall) console.log(`Note: ${shortfall}`);
  if (result.info.length > 0) console.log(formatInfo(result.info));
  if (result.warnings.length > 0) console.log(formatWarnings(result.warnings));
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

  const project = await (deps.confirmProject ?? confirmProject)(opts.project);
  console.log(`Applying ${result.temples.length} temples to ${project}.`);
  await applyToFirestore(project, result.temples);
  return result;
}

const isDirect = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactDownloadToken(error.message || error));
    process.exit(1);
  });
}

export { main, parseArgs };
