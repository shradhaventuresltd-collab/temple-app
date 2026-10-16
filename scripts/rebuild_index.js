/**
 * Rebuild temple_index from every temples/* document.
 *
 * Dry-run is the default. It reads Firestore and prints a drift report.
 * It does not write.
 *
 *   node scripts/rebuild_index.js --project temple-directory-india
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/rebuild_index.js
 *
 * A prod apply asks you to type the project id. There is no default project.
 *
 *   node scripts/rebuild_index.js --apply --project temple-directory-india
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/rebuild_index.js --apply --project demo
 *
 * Deploy rules before the first apply:
 *   firebase deploy --only firestore:rules --project temple-directory-india
 *
 * Seed and scripts/seed_state_batch.js --apply write the index themselves.
 * This tool is a repair and backfill only. It is not a required step.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactThrown } from "./redact_url.js";
import {
  assertShardCaps,
  batchRounds,
  diffIndex,
  planOps,
  writeNeeded,
} from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function printUsage() {
  console.log(`
Usage:
  node rebuild_index.js [--dry-run] [--project <firebase-project-id>]
  node rebuild_index.js --apply --project <firebase-project-id>

Default is dry-run: print missing, stale, moved, and drifted entries.
Nothing is written. prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply uses prod_guard and prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.

Deploy firestore.rules before applying. This repairs drift and backfills
temples that were written before the index existed. It does not switch
the app read path. --apply plans from a read taken immediately before the writes, then
re-reads each shard again immediately before staging that shard.
`);
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    project: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--project") opts.project = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function usesEmulator(env) {
  return (
    typeof env.FIRESTORE_EMULATOR_HOST === "string" &&
    env.FIRESTORE_EMULATOR_HOST.trim() !== ""
  );
}

export function credentialMode(env) {
  return usesEmulator(env) ? "emulator" : "service-account";
}

export function resolveProject(opts, env = process.env) {
  if (typeof opts.project === "string" && opts.project.trim() !== "") {
    return assertExplicitProject(opts.project);
  }
  if (usesEmulator(env)) {
    return (
      env.GCLOUD_PROJECT ||
      env.GOOGLE_CLOUD_PROJECT ||
      "demo-temple-index"
    );
  }
  throw new Error(
    "Pass --project <firebase-project-id>. Dry-run reads Firestore and does not write. There is no default project.",
  );
}

/**
 * @param {string} project
 * @param {NodeJS.ProcessEnv} env
 * @param {{ confirm?: (project: string) => Promise<string> }} [deps]
 */
export async function authorizeApply(project, env = process.env, deps = {}) {
  assertNotCi(env);
  const id = assertExplicitProject(project);
  if (usesEmulator(env)) return id;
  const confirm = deps.confirm ?? confirmProject;
  return confirm(id);
}

export function formatReport(report, { apply = false } = {}) {
  const lines = [];
  lines.push(apply ? "Mode: apply" : "Mode: dry-run");
  const templeCount =
    report.unchanged +
    report.missing.length +
    report.drifted.length;
  lines.push(
    `temples: ${templeCount}  unchanged: ${report.unchanged}  missing: ${report.missing.length}  drifted: ${report.drifted.length}  moved: ${report.moved.length}  stale: ${report.stale.length}`,
  );
  const ranked = [...report.counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  if (ranked.length > 0) {
    const [shard, count] = ranked[0];
    lines.push(`largest shard: ${shard} (${count})`);
  }
  for (const item of report.capViolations) {
    lines.push(`cap: ${item.shard} has ${item.count} temples; max is 400`);
  }
  for (const item of report.missing) lines.push(`missing ${item.shard}/${item.id}`);
  for (const item of report.drifted) {
    lines.push(`drift ${item.shard}/${item.id} ${item.fields.join(",")}`);
  }
  for (const item of report.moved) {
    lines.push(`moved ${item.id} ${item.from} -> ${item.to}`);
  }
  for (const item of report.stale) lines.push(`stale ${item.shard}/${item.id}`);
  if (!apply) lines.push("Dry-run only. No Firestore writes.");
  return lines.join("\n");
}

async function openFirestore(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (usesEmulator(env)) {
    process.env.FIRESTORE_EMULATOR_HOST = env.FIRESTORE_EMULATOR_HOST;
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
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
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

export async function loadTemplesAndIndex(project, env = process.env) {
  const db = await openFirestore(project, env);
  const templesSnap = await db.collection("temples").get();
  const temples = templesSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const indexSnap = await db.collection("temple_index").get();
  const shards = {};
  for (const doc of indexSnap.docs) {
    const data = doc.data() ?? {};
    shards[doc.id] = data.entries ?? {};
  }
  return { temples, shards, db };
}

export async function applyPlan(db, report, deps = {}) {
  const admin = deps.admin ?? (await import("firebase-admin")).default;
  const ops = planOps(report);
  if (ops.length === 0) return 0;
  const rounds = batchRounds(ops);
  let written = 0;
  for (const round of rounds) {
    const batch = db.batch();
    const touched = [];
    for (const op of round) {
      const ref = db.collection("temple_index").doc(op.shard);
      // Re-read this shard immediately before staging its field path.
      // The batch commits after every shard in the round has been read.
      const snap = await ref.get();
      const fresh = snap.exists ? (snap.data()?.entries ?? {}) : {};
      if (!writeNeeded(op, fresh)) continue;
      if (op.op === "delete") {
        batch.update(ref, new admin.firestore.FieldPath("entries", op.id), admin.firestore.FieldValue.delete());
      } else {
        const entry = { ...op.entry, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        batch.set(
          ref,
          { entries: { [op.id]: entry } },
          { mergeFields: [new admin.firestore.FieldPath("entries", op.id)] },
        );
      }
      touched.push(op.shard);
      written += 1;
    }
    if (touched.length === 0) continue;
    const metaRef = db.collection("meta").doc("temple_index");
    const metaSnap = await metaRef.get();
    const uniqueTouched = [...new Set(touched)];
    if (!metaSnap.exists) {
      const stamps = {};
      for (const shard of uniqueTouched) {
        stamps[shard] = admin.firestore.FieldValue.serverTimestamp();
      }
      batch.set(metaRef, { indexVersion: 1, shards: stamps }, { merge: true });
    } else {
      // Only the shards this round changed. Sibling timestamps stay put.
      const patch = {
        indexVersion: admin.firestore.FieldValue.increment(1),
      };
      for (const shard of uniqueTouched) {
        patch[`shards.${shard}`] = admin.firestore.FieldValue.serverTimestamp();
      }
      batch.update(metaRef, patch);
    }
    await batch.commit();
  }
  return written;
}

/**
 * @param {string[]} argv
 * @param {{
 *   env?: NodeJS.ProcessEnv,
 *   load?: (project: string, env: NodeJS.ProcessEnv) => Promise<{temples: object[], shards: object}>,
 *   apply?: (project: string, report: object, env: NodeJS.ProcessEnv) => Promise<number>,
 *   confirm?: (project: string) => Promise<string>,
 *   log?: (line: string) => void,
 * }} [deps]
 */
export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const log = deps.log ?? ((line) => console.log(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  if (opts.apply) {
    await authorizeApply(project, env, { confirm: deps.confirm });
  }
  const load = deps.load ?? loadTemplesAndIndex;
  if (!opts.apply) {
    const snapshot = await load(project, env);
    const report = diffIndex(snapshot.temples ?? [], snapshot.shards ?? {});
    log(formatReport(report, { apply: false }));
    return report;
  }
  // The dry-run snapshot is not the plan. Read again immediately before
  // diffing, then applyPlan reads each shard once more before its write.
  const fresh = await load(project, env);
  const report = diffIndex(fresh.temples ?? [], fresh.shards ?? {});
  log(formatReport(report, { apply: true }));
  if (report.capViolations.length > 0) {
    assertShardCaps(fresh.temples ?? []);
  }
  const apply =
    deps.apply ??
    (async (_id, planned) => {
      if (!fresh.db) {
        throw new Error("Apply needs the Firestore handle from the fresh read.");
      }
      return applyPlan(fresh.db, planned);
    });
  const count = await apply(project, report, env);
  log(`Applied ${count} index field writes to ${project}.`);
  return report;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactThrown(error));
    process.exit(1);
  });
}
