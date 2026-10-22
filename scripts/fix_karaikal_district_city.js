/**
 * ONE-USE. Deployer only. Satyavrat (architect) signed off.
 * Research Pavi verified the places via English Wikipedia
 * (Rajacholeesvarar Temple, Thirumalairayanpattinam; Thanthondreeswarar
 * Temple, Nedungadu), karaikal.gov.in places-of-interest, and the
 * TN Temples Project.
 *
 * Three Karaikal temples have the wrong district and city. This script
 * sets those two fields. When one of those documents has a state other
 * than Puducherry, it also sets state to Puducherry on that document
 * only, and the before/after diff shows that state line only there.
 *
 * Field names, looked up in the model and rules:
 *   city — Firestore `city`. Temple.city in lib/models/temple.dart.
 *     toFirestoreData writes `city`. firestore.rules requires a string
 *     of 1..100 characters.
 *   district — Firestore `district`. Temple and firestore.rules do not
 *     list this key (rules allowed fields stop at tradition). These
 *     three documents already store a string `district`, the same key
 *     photo-pack manifests use. This script updates that existing key.
 *     A missing `district` or `city` aborts with no write, so the key
 *     is not created and the rules allow list is not widened.
 *     scripts/apply_field_patches.js ALLOWED_FIELDS is not changed.
 *
 * Hard allowlist, exactly these three documents:
 *   temples/rajacholeeswarar-temple-thirumalairayanpattinam
 *     district Karaikal, city Thirumalairayanpattinam
 *   temples/thanthondreeswarar-temple-nedungadu
 *     district Karaikal, city Nedungadu
 *   temples/yazhmoorinathar-temple-dharmapuram
 *     district Karaikal, city Dharmapuram
 * A missing document aborts with no write. State is written only when
 * that document's state is not already Puducherry. Latitude, longitude,
 * and every other field stay untouched.
 *
 * Dry-run is the default. It reads and prints a before/after diff per
 * document. It does not write. --apply is refused in CI. Prod apply
 * asks you to type the project id. --backup-dir is required with
 * --apply. Each document is written there before any Firestore write.
 * A failed backup aborts. Reads and writes for all three documents
 * happen in one transaction. APPLY-FINISHED is printed only after that
 * transaction commits.
 *
 * This script does not call rebuild_index.js. After --apply, Deployer
 * runs a rebuild_index dry run, which should show only these 3 temples
 * moving into the right Puducherry/Karaikal shard and no other drift.
 * Then this script gets retired: delete
 * scripts/fix_karaikal_district_city.js. Do not run it again.
 *
 * The index shard id is the state slug (puducherry). State is written
 * only on a document whose state is not already Puducherry, so that
 * document can move onto the puducherry shard. A document that is
 * already Puducherry stays on that shard. The index entry copies
 * `city` and does not copy `district`, so the dry run should show
 * city drift for these three ids and no other drift. A move line is
 * printed only when an entry still sits on another shard.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 *
 *   node fix_karaikal_district_city.js --project temple-directory-india
 *   node fix_karaikal_district_city.js --apply --backup-dir <folder> --project temple-directory-india
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken, redactThrown } from "./redact_url.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const TEMPLES = "temples";
export const DISTRICT_FIELD = "district";
export const CITY_FIELD = "city";
export const STATE_FIELD = "state";
export const REQUIRED_STATE = "Puducherry";
export const DISTRICT_VALUE = "Karaikal";
/** Same cap as firestore.rules validStringLength('city', 1, 100). */
export const CITY_MAX = 100;

export const TARGETS = Object.freeze([
  Object.freeze({
    id: "rajacholeeswarar-temple-thirumalairayanpattinam",
    district: DISTRICT_VALUE,
    city: "Thirumalairayanpattinam",
  }),
  Object.freeze({
    id: "thanthondreeswarar-temple-nedungadu",
    district: DISTRICT_VALUE,
    city: "Nedungadu",
  }),
  Object.freeze({
    id: "yazhmoorinathar-temple-dharmapuram",
    district: DISTRICT_VALUE,
    city: "Dharmapuram",
  }),
]);

const RETIRED_MARKER = resolve(__dirname, "data", "karaikal-district-city.retired");

function printUsage() {
  const lines = TARGETS.map(
    (target) =>
      `  ${TEMPLES}/${target.id}  ${DISTRICT_FIELD}=${target.district}  ${CITY_FIELD}=${target.city}`,
  );
  console.log(`
Usage:
  node fix_karaikal_district_city.js [--dry-run] --project <firebase-project-id>
  node fix_karaikal_district_city.js --apply --backup-dir <folder> --project <firebase-project-id>

ONE-USE. Sets only ${DISTRICT_FIELD} and ${CITY_FIELD} on exactly these
three documents. ${STATE_FIELD} is set to ${REQUIRED_STATE} only on a
document whose ${STATE_FIELD} is not already ${REQUIRED_STATE}.
Coordinates are not written.
Dry-run is the default and does not write. --apply requires --backup-dir,
refuses CI, and prompts for the project id (the emulator does not).
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
    if (target.district !== DISTRICT_VALUE) {
      throw new Error("Allowlist district must be Karaikal. No write.");
    }
    if (typeof target.city !== "string" || target.city.trim() === "") {
      throw new Error(`Allowlist city for ${target.id} is empty. No write.`);
    }
    if (target.city.length > CITY_MAX) {
      throw new Error(`Allowlist city for ${target.id} is longer than ${CITY_MAX}. No write.`);
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

/**
 * district and city, plus state only when the live value is not already
 * Puducherry. Pass no data when building the district/city pair alone.
 */
export function correctionFields(target, data) {
  const fields = {
    [DISTRICT_FIELD]: target.district,
    [CITY_FIELD]: target.city,
  };
  if (data && data[STATE_FIELD] !== REQUIRED_STATE) {
    fields[STATE_FIELD] = REQUIRED_STATE;
  }
  return fields;
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
  const allowedKeys = new Set([DISTRICT_FIELD, CITY_FIELD, STATE_FIELD]);
  const hasPlace = keys.includes(DISTRICT_FIELD) && keys.includes(CITY_FIELD);
  const extra = keys.filter((key) => !allowedKeys.has(key));
  if (!hasPlace || extra.length > 0 || keys.length > 3) {
    throw new Error(
      `Refusing to write ${keys.join(", ") || "(no fields)"} on ${TEMPLES}/${id}. Only ${DISTRICT_FIELD} and ${CITY_FIELD} may be set, plus ${STATE_FIELD} when it is not already ${REQUIRED_STATE}.`,
    );
  }
  for (const key of [DISTRICT_FIELD, CITY_FIELD]) {
    const value = fields[key];
    if (typeof value !== "string" || value.trim() === "") {
      throw new Error(`${key} must be a non-empty string.`);
    }
    if (value.length > CITY_MAX) {
      throw new Error(`${key} must be at most ${CITY_MAX} characters.`);
    }
  }
  if (Object.prototype.hasOwnProperty.call(fields, STATE_FIELD)) {
    if (fields[STATE_FIELD] !== REQUIRED_STATE) {
      throw new Error(
        `Refusing state ${JSON.stringify(fields[STATE_FIELD] ?? null)} on ${TEMPLES}/${id}. Only ${REQUIRED_STATE} may be set.`,
      );
    }
  }
  if (fields[DISTRICT_FIELD] !== target.district || fields[CITY_FIELD] !== target.city) {
    throw new Error(
      `Refusing values on ${TEMPLES}/${id}. Only district ${JSON.stringify(target.district)} and city ${JSON.stringify(target.city)} may be set.`,
    );
  }
}

export function assertPreconditions(docs) {
  assertAllowlistShape();
  for (const target of TARGETS) {
    const doc = docs[target.id];
    const path = `${TEMPLES}/${target.id}`;
    if (!doc?.exists) {
      throw new Error(`${path} does not exist. No write.`);
    }
    if (!Object.prototype.hasOwnProperty.call(doc.data, DISTRICT_FIELD)) {
      throw new Error(
        `${path} has no existing ${DISTRICT_FIELD} field. No write.`,
      );
    }
    if (typeof doc.data[DISTRICT_FIELD] !== "string") {
      throw new Error(
        `${path} ${DISTRICT_FIELD} is not a string. No write.`,
      );
    }
    if (!Object.prototype.hasOwnProperty.call(doc.data, CITY_FIELD)) {
      throw new Error(`${path} has no existing ${CITY_FIELD} field. No write.`);
    }
    if (typeof doc.data[CITY_FIELD] !== "string") {
      throw new Error(`${path} ${CITY_FIELD} is not a string. No write.`);
    }
  }
}

export function buildReport(docs) {
  return TARGETS.map((target) => {
    const data = docs[target.id].data;
    const beforeDistrict = data[DISTRICT_FIELD];
    const beforeCity = data[CITY_FIELD];
    const beforeState = data[STATE_FIELD];
    return {
      id: target.id,
      path: `${TEMPLES}/${target.id}`,
      beforeDistrict,
      afterDistrict: target.district,
      beforeCity,
      afterCity: target.city,
      districtChanged: beforeDistrict !== target.district,
      cityChanged: beforeCity !== target.city,
      beforeState,
      afterState: REQUIRED_STATE,
      stateChanged: beforeState !== REQUIRED_STATE,
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
    lines.push(`  ${DISTRICT_FIELD}: ${show(row.beforeDistrict)} -> ${show(row.afterDistrict)}`);
    lines.push(`  ${CITY_FIELD}: ${show(row.beforeCity)} -> ${show(row.afterCity)}`);
    if (row.stateChanged) {
      lines.push(`  ${STATE_FIELD}: ${show(row.beforeState)} -> ${show(row.afterState)}`);
    }
  }
  lines.push("latitude and longitude are not written.");
  if (apply) {
    lines.push(`Backup: ${backupDir}`);
    for (const row of report) {
      const wrote = [];
      if (row.districtChanged || row.cityChanged) {
        wrote.push(`${DISTRICT_FIELD} and ${CITY_FIELD}`);
      }
      if (row.stateChanged) wrote.push(STATE_FIELD);
      if (wrote.length === 0) {
        lines.push(`Left ${row.path} ${DISTRICT_FIELD} and ${CITY_FIELD} unchanged.`);
      } else {
        lines.push(`Updated ${row.path} ${wrote.join(" and ")}.`);
      }
    }
  } else {
    lines.push("Dry-run only. No Firestore writes.");
  }
  lines.push(
    "Next: run node scripts/rebuild_index.js --project <id>. It should show only these 3 temples moving into the right Puducherry/Karaikal shard and no other drift. This script does not call rebuild_index.",
  );
  lines.push(
    "ONE-USE: after the apply and that dry run, delete scripts/fix_karaikal_district_city.js. Do not run this again.",
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
    throw new Error("--backup-dir is required with --apply.");
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
      const row = fresh[item.target.id].data;
      const fields = correctionFields(item.target, row);
      assertAllowedUpdate(item.target.id, fields);
      if (
        row[DISTRICT_FIELD] === item.target.district &&
        row[CITY_FIELD] === item.target.city &&
        row[STATE_FIELD] === REQUIRED_STATE
      ) {
        continue;
      }
      tx.update(item.ref, fields);
    }
  });
}

export async function inspectFix(db) {
  const docs = await readTargets(db);
  assertPreconditions(docs);
  return buildReport(docs);
}

export async function applyFix(db, { backupDir, log = () => {}, writeBackup = writeBackupFiles }) {
  const docs = await readTargets(db);
  assertPreconditions(docs);
  const report = buildReport(docs);
  let backup;
  try {
    backup = writeBackup(backupDir, docs);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Backup failed: ${message} No write.`);
  }
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
  if (!opts.apply) {
    const report = await inspectFix(db);
    log(formatReport(report, { apply: false }));
    return { report, wrote: false };
  }
  const applied = await applyFix(db, {
    backupDir: opts.backupDir,
    log,
    writeBackup: deps.writeBackup,
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
