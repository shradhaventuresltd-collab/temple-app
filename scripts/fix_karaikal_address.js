/**
 * ONE-USE. Deployer only. Satyavrat (architect) signed off.
 * Research Pavi verified the places via English Wikipedia
 * (Rajacholeesvarar Temple, Thirumalairayanpattinam; Thanthondreeswarar
 * Temple, Nedungadu), karaikal.gov.in places-of-interest, and the
 * TN Temples Project.
 *
 * The earlier district/city script aborted in production: these three
 * documents have no `district` field, and `city` and `state` are already
 * correct. The address text is what is wrong. This script writes only
 * the Firestore `address` field. `district`, `city`, `state`, latitude,
 * and longitude are not written.
 *
 * Field name, looked up in the model and rules:
 *   address — Firestore `address`. Temple.location in
 *   lib/models/temple.dart is stored as `address`. firestore.rules
 *   requires a string of 1..500 characters. scripts/apply_field_patches.js
 *   ALLOWED_FIELDS is not changed.
 *
 * Hard allowlist, exactly these three documents. The current address
 * must equal the before string exactly. Any mismatch aborts the whole
 * run, and nothing is written:
 *   temples/rajacholeeswarar-temple-thirumalairayanpattinam
 *     "Thirumalairayanpattinam, Puducherry"
 *       -> "Thirumalairayanpattinam, Karaikal, Puducherry"
 *   temples/thanthondreeswarar-temple-nedungadu
 *     "Nedungadu, Puducherry"
 *       -> "Nedungadu, Karaikal, Puducherry"
 *   temples/yazhmoorinathar-temple-dharmapuram
 *     "Dharmapuram, Puducherry"
 *       -> "Dharmapuram, Karaikal, Puducherry"
 * A missing document aborts with no write.
 *
 * Dry-run is the default. It reads and prints a before/after diff per
 * document. It does not write Firestore. --backup-dir on a dry run
 * exports each current document to that folder and still does not write
 * Firestore. --apply is refused in CI. Prod apply asks you to type the
 * project id. --backup-dir is required with --apply. Each document is
 * written there before any Firestore write. A failed backup aborts.
 * Reads and writes for all three documents happen in one transaction.
 * APPLY-FINISHED is printed only after that transaction commits.
 *
 * This script does not call rebuild_index.js. After --apply, Deployer
 * runs a rebuild_index dry run. State is not written, so these three
 * stay on the puducherry shard. The index entry copies a short address,
 * so that dry run should show address drift for these 3 ids only and
 * no other drift. Then this script gets retired: delete
 * scripts/fix_karaikal_address.js. Do not run it again.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 *
 *   node fix_karaikal_address.js --project temple-directory-india
 *   node fix_karaikal_address.js --backup-dir <folder> --project temple-directory-india
 *   node fix_karaikal_address.js --apply --backup-dir <folder> --project temple-directory-india
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken, redactThrown } from "./redact_url.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const TEMPLES = "temples";
export const ADDRESS_FIELD = "address";
/** Same cap as firestore.rules validStringLength('address', 1, 500). */
export const ADDRESS_MAX = 500;

export const TARGETS = Object.freeze([
  Object.freeze({
    id: "rajacholeeswarar-temple-thirumalairayanpattinam",
    before: "Thirumalairayanpattinam, Puducherry",
    after: "Thirumalairayanpattinam, Karaikal, Puducherry",
  }),
  Object.freeze({
    id: "thanthondreeswarar-temple-nedungadu",
    before: "Nedungadu, Puducherry",
    after: "Nedungadu, Karaikal, Puducherry",
  }),
  Object.freeze({
    id: "yazhmoorinathar-temple-dharmapuram",
    before: "Dharmapuram, Puducherry",
    after: "Dharmapuram, Karaikal, Puducherry",
  }),
]);

const RETIRED_MARKER = resolve(__dirname, "data", "karaikal-address.retired");

function printUsage() {
  const lines = TARGETS.map(
    (target) =>
      `  ${TEMPLES}/${target.id}\n    ${JSON.stringify(target.before)} -> ${JSON.stringify(target.after)}`,
  );
  console.log(`
Usage:
  node fix_karaikal_address.js [--dry-run] [--backup-dir <folder>] --project <firebase-project-id>
  node fix_karaikal_address.js --apply --backup-dir <folder> --project <firebase-project-id>

ONE-USE. Sets only ${ADDRESS_FIELD} on exactly these three documents,
and only when the current ${ADDRESS_FIELD} equals the before string.
district, city, state, latitude, and longitude are not written.
Dry-run is the default and does not write Firestore. --backup-dir on a
dry run exports the current documents and still does not write Firestore.
--apply requires --backup-dir, refuses CI, and prompts for the project id
(the emulator does not).
After --apply, run rebuild_index.js yourself, then delete this file.

${lines.join("\n")}
`);
}

export function targetById(id) {
  return TARGETS.find((target) => target.id === id) ?? null;
}

export function assertAllowlistShape() {
  if (TARGETS.length !== 3) {
    throw new Error("Allowlist must be exactly 3 documents. No write.");
  }
  const ids = new Set(TARGETS.map((target) => target.id));
  if (ids.size !== TARGETS.length) {
    throw new Error("Allowlist document ids must be unique. No write.");
  }
  for (const target of TARGETS) {
    if (typeof target.before !== "string" || target.before.length === 0) {
      throw new Error(`Allowlist before address for ${target.id} is empty. No write.`);
    }
    if (typeof target.after !== "string" || target.after.trim() === "") {
      throw new Error(`Allowlist after address for ${target.id} is empty. No write.`);
    }
    if (target.after.length > ADDRESS_MAX) {
      throw new Error(`Allowlist address for ${target.id} is longer than ${ADDRESS_MAX}. No write.`);
    }
    if (target.before === target.after) {
      throw new Error(`Allowlist address for ${target.id} does not change. No write.`);
    }
    if (!target.after.includes("Karaikal, Puducherry")) {
      throw new Error(`Allowlist address for ${target.id} must name Karaikal, Puducherry. No write.`);
    }
  }
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    project: null,
    backupDir: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--backup-dir" || arg.startsWith("--backup-dir=")) {
      const raw = arg === "--backup-dir" ? argv[++i] : arg.slice("--backup-dir=".length);
      if (typeof raw !== "string" || raw.trim() === "" || raw.startsWith("--")) {
        throw new Error("--backup-dir needs a local folder. No write.");
      }
      opts.backupDir = raw.trim();
    } else if (arg === "--project" || arg.startsWith("--project=")) {
      const raw = arg === "--project" ? argv[++i] : arg.slice("--project=".length);
      if (typeof raw !== "string" || raw.trim() === "" || raw.startsWith("--")) {
        throw new Error("--project needs a firebase project id. No write.");
      }
      opts.project = raw.trim();
    } else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function usesEmulator(env) {
  return (
    typeof env.FIRESTORE_EMULATOR_HOST === "string" &&
    env.FIRESTORE_EMULATOR_HOST.trim() !== ""
  );
}

export function resolveProject(opts, env = process.env) {
  if (typeof opts.project === "string" && opts.project.trim() !== "") {
    return assertExplicitProject(opts.project);
  }
  if (usesEmulator(env)) {
    return env.GCLOUD_PROJECT || env.GOOGLE_CLOUD_PROJECT || "demo-temple-index";
  }
  throw new Error(
    "Pass --project <firebase-project-id>. Dry-run reads Firestore and does not write. There is no default project.",
  );
}

export async function authorizeApply(project, env = process.env, deps = {}) {
  assertNotCi(env);
  const id = assertExplicitProject(project);
  if (usesEmulator(env)) return id;
  const confirm = deps.confirm ?? confirmProject;
  return confirm(id);
}

export function assertNotRetired() {
  if (existsSync(RETIRED_MARKER)) {
    throw new Error("This one-use driver is retired. No write.");
  }
}

/** Firestore Timestamps become ISO strings. Other values pass through. */
export function toPlain(value) {
  return JSON.parse(
    JSON.stringify(value, (_key, current) => {
      if (
        current &&
        typeof current === "object" &&
        typeof current.toDate === "function"
      ) {
        const date = current.toDate();
        if (date instanceof Date && !Number.isNaN(date.getTime())) {
          return date.toISOString();
        }
      }
      return current;
    }),
  );
}

function stable(value) {
  return JSON.stringify(sortKeys(toPlain(value)));
}

function sortKeys(value) {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === "object") {
    const out = {};
    for (const key of Object.keys(value).sort()) out[key] = sortKeys(value[key]);
    return out;
  }
  return value;
}

/** The only field this script may write. */
export function correctionFields(target) {
  return { [ADDRESS_FIELD]: target.after };
}

export function assertAllowedUpdate(id, fields) {
  assertAllowlistShape();
  const target = targetById(id);
  if (!target) {
    const allowed = TARGETS.map((item) => `${TEMPLES}/${item.id}`).join(", ");
    throw new Error(
      `Refusing to update ${TEMPLES}/${id}. Only ${allowed} may be updated.`,
    );
  }
  const keys = Object.keys(fields ?? {}).sort();
  if (keys.length !== 1 || keys[0] !== ADDRESS_FIELD) {
    throw new Error(
      `Refusing to write ${keys.join(", ") || "(no fields)"} on ${TEMPLES}/${id}. Only ${ADDRESS_FIELD} may be set.`,
    );
  }
  const value = fields[ADDRESS_FIELD];
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${ADDRESS_FIELD} must be a non-empty string.`);
  }
  if (value.length > ADDRESS_MAX) {
    throw new Error(`${ADDRESS_FIELD} must be at most ${ADDRESS_MAX} characters.`);
  }
  if (value !== target.after) {
    throw new Error(
      `Refusing address ${JSON.stringify(value)} on ${TEMPLES}/${id}. Only ${JSON.stringify(target.after)} may be set.`,
    );
  }
}

function showAddress(value) {
  return JSON.stringify(value === undefined ? null : value);
}

export function assertPreconditions(docs) {
  assertAllowlistShape();
  const problems = [];
  for (const target of TARGETS) {
    const doc = docs[target.id];
    const path = `${TEMPLES}/${target.id}`;
    if (!doc?.exists) {
      problems.push(`${path} does not exist.`);
      continue;
    }
    const address = doc.data?.[ADDRESS_FIELD];
    if (address !== target.before) {
      problems.push(
        `${path} address is ${showAddress(address)}, expected ${JSON.stringify(target.before)}.`,
      );
    }
  }
  if (problems.length > 0) {
    throw new Error(`${problems.join(" ")} No write.`);
  }
}

export function buildReport(docs) {
  return TARGETS.map((target) => {
    const data = docs[target.id].data;
    const before = data[ADDRESS_FIELD];
    return {
      id: target.id,
      path: `${TEMPLES}/${target.id}`,
      before,
      after: target.after,
    };
  });
}

function show(value) {
  return redactDownloadToken(JSON.stringify(value === undefined ? null : value));
}

export function formatReport(report, { apply = false, backupDir = null } = {}) {
  const lines = [];
  lines.push(apply ? "Mode: apply" : "Mode: dry-run");
  for (const row of report) {
    lines.push(row.path);
    lines.push(`  ${ADDRESS_FIELD}: ${show(row.before)} -> ${show(row.after)}`);
  }
  lines.push("district, city, state, latitude, and longitude are not written.");
  if (backupDir) lines.push(`Backup: ${backupDir}`);
  if (apply) {
    for (const row of report) {
      lines.push(`Updated ${row.path} ${ADDRESS_FIELD}.`);
    }
  } else {
    lines.push("Dry-run only. No Firestore writes.");
    if (backupDir) {
      lines.push("Backup export is read-only. No Firestore writes.");
    }
  }
  lines.push(
    "Next: run node scripts/rebuild_index.js --project <id>. State is not written, so these 3 stay on the puducherry shard. It should show address drift for these 3 ids only and no other drift. This script does not call rebuild_index.",
  );
  lines.push(
    "ONE-USE: after the apply and that dry run, delete scripts/fix_karaikal_address.js. Do not run this again.",
  );
  return lines.join("\n");
}

async function readDoc(db, id) {
  const snap = await db.collection(TEMPLES).doc(id).get();
  return {
    id,
    exists: Boolean(snap.exists),
    data: snap.exists ? snap.data() ?? {} : null,
  };
}

export async function readTargets(db) {
  const docs = {};
  await Promise.all(
    TARGETS.map(async (target) => {
      docs[target.id] = await readDoc(db, target.id);
    }),
  );
  return docs;
}

export function writeBackupFiles(dir, docs) {
  if (typeof dir !== "string" || dir.trim() === "") {
    throw new Error("--backup-dir needs a local folder. No write.");
  }
  const folder = resolve(dir);
  mkdirSync(folder, { recursive: true });
  const files = [];
  for (const target of TARGETS) {
    const body = `${JSON.stringify(
      {
        id: target.id,
        path: `${TEMPLES}/${target.id}`,
        data: toPlain(docs[target.id].data),
      },
      null,
      2,
    )}\n`;
    const path = join(folder, `${target.id}.json`);
    writeFileSync(path, body, { encoding: "utf8" });
    const back = readFileSync(path, "utf8");
    if (back !== body) {
      throw new Error(`Backup read-back failed for ${path}.`);
    }
    files.push(path);
  }
  return { dir: folder, files };
}

function sameDocs(left, right) {
  return TARGETS.every(
    (target) => stable(left[target.id].data) === stable(right[target.id].data),
  );
}

async function commitFix(db, docs) {
  const refs = TARGETS.map((target) => ({
    target,
    ref: db.collection(TEMPLES).doc(target.id),
  }));
  await db.runTransaction(async (tx) => {
    const fresh = {};
    for (const item of refs) {
      const snap = await tx.get(item.ref);
      fresh[item.target.id] = {
        id: item.target.id,
        exists: Boolean(snap.exists),
        data: snap.exists ? snap.data() ?? {} : null,
      };
    }
    assertPreconditions(fresh);
    if (!sameDocs(docs, fresh)) {
      throw new Error("Documents changed after the backup. No write.");
    }
    for (const item of refs) {
      const fields = correctionFields(item.target);
      assertAllowedUpdate(item.target.id, fields);
      tx.update(item.ref, fields);
    }
  });
}

export async function inspectFix(db) {
  const docs = await readTargets(db);
  assertPreconditions(docs);
  return buildReport(docs);
}

function backupOrThrow(writeBackup, backupDir, docs) {
  try {
    return writeBackup(backupDir, docs);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Backup failed: ${message} No write.`);
  }
}

export async function applyFix(db, { backupDir, log = () => {}, writeBackup = writeBackupFiles }) {
  const docs = await readTargets(db);
  assertPreconditions(docs);
  const report = buildReport(docs);
  const backup = backupOrThrow(writeBackup, backupDir, docs);
  log(`Backup: ${backup.dir}`);
  await commitFix(db, docs);
  return { report, backupDir: backup.dir };
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

/**
 * @param {string[]} argv
 * @param {{
 *   env?: NodeJS.ProcessEnv,
 *   db?: object,
 *   confirm?: (project: string) => Promise<string>,
 *   log?: (line: string) => void,
 *   writeBackup?: typeof writeBackupFiles,
 * }} [deps]
 */
export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const log = deps.log ?? ((line) => console.log(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  assertNotRetired();
  assertAllowlistShape();
  const env = deps.env ?? process.env;
  if (opts.apply && !opts.backupDir) {
    throw new Error("--backup-dir is required with --apply. No write.");
  }
  const project = resolveProject(opts, env);
  if (opts.apply) {
    await authorizeApply(project, env, { confirm: deps.confirm });
  }
  const db = deps.db ?? (await openFirestore(project, env));
  const writeBackup = deps.writeBackup ?? writeBackupFiles;
  if (!opts.apply) {
    const docs = await readTargets(db);
    assertPreconditions(docs);
    let backupDir = null;
    if (opts.backupDir) {
      const backup = backupOrThrow(writeBackup, opts.backupDir, docs);
      backupDir = backup.dir;
      log(`Backup: ${backup.dir}`);
    }
    const report = buildReport(docs);
    log(formatReport(report, { apply: false, backupDir }));
    return { report, wrote: false, backupDir };
  }
  const applied = await applyFix(db, {
    backupDir: opts.backupDir,
    log,
    writeBackup,
  });
  log(formatReport(applied.report, { apply: true, backupDir: applied.backupDir }));
  log("APPLY-FINISHED");
  return { report: applied.report, wrote: true, backupDir: applied.backupDir };
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactThrown(error));
    process.exit(1);
  });
}
