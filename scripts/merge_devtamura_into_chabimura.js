/**
 * ONE-USE. Deployer only. Satyavrat (architect) approved this merge.
 *
 * Tripura has two documents for one site. temples/devtamura is the wrong
 * pin (the Devtamura hill range). temples/chabimura keeps its coordinates
 * (23.542, 91.6057, Wikidata Q55606892). This script does not write
 * latitude or longitude.
 *
 * Allowlist: delete ONLY temples/devtamura, and set ONLY description on
 * temples/chabimura. The text is scripts/data/chabimura-description.txt.
 * Any other document or field is refused. The file must start with the
 * trimmed live chabimura description. The change is append-only. Dry-run
 * and apply both abort otherwise, including the transaction re-read.
 *
 * Dry-run is the default. It reads and prints the diff. It does not write.
 * --apply is refused in CI. Prod apply asks you to type the project id.
 * --backup-dir is required with --apply. Both documents are written there
 * before any Firestore write. A failed backup aborts.
 *
 * chabimura must already have a cover (imageUrl) and photos[]. Attach the
 * devtamura photo pack with upload_research_pack.js first. devtamura must
 * exist. Both states must be Tripura. The Tripura count must be 11.
 *
 * This script does not call rebuild_index.js. After --apply, run that
 * yourself. It should find 1 stale entry (devtamura) and remove it.
 *
 * Retire after that apply, the same way other one-off drivers leave the
 * tree: delete this file and scripts/data/chabimura-description.txt.
 * Do not run it again. A second run aborts because devtamura is gone.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 *
 *   node merge_devtamura_into_chabimura.js --project temple-directory-india
 *   node merge_devtamura_into_chabimura.js --apply --backup-dir <folder> --project temple-directory-india
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken, redactThrown } from "./redact_url.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const TEMPLES = "temples";
export const DELETE_ID = "devtamura";
export const UPDATE_ID = "chabimura";
export const UPDATE_FIELD = "description";
export const TRIPURA_BEFORE = 11;
export const TRIPURA_AFTER = 10;
export const DESCRIPTION_PATH = resolve(__dirname, "data", "chabimura-description.txt");
const RETIRED_MARKER = resolve(__dirname, "data", "chabimura-merge.retired");
const DESCRIPTION_MAX = 10000;

function printUsage() {
  console.log(`
Usage:
  node merge_devtamura_into_chabimura.js [--dry-run] --project <firebase-project-id>
  node merge_devtamura_into_chabimura.js --apply --backup-dir <folder> --project <firebase-project-id>

ONE-USE. Deletes only temples/${DELETE_ID}. Sets only ${UPDATE_FIELD} on
temples/${UPDATE_ID}, from scripts/data/chabimura-description.txt.
Dry-run is the default and does not write. --apply requires --backup-dir,
refuses CI, and prompts for the project id (the emulator does not).
Attach the photo pack to ${UPDATE_ID} first. Then run rebuild_index.js
yourself. Retire this file after the apply.
`);
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
    } else if (arg === "--project") {
      const project = argv[++i];
      if (typeof project !== "string" || project.trim() === "" || project.startsWith("--")) {
        throw new Error("--project needs a firebase project id. No write.");
      }
      opts.project = project;
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

export function loadDescription(file = DESCRIPTION_PATH) {
  const text = readFileSync(file, "utf8").replace(/\s+$/u, "");
  if (text === "") throw new Error("Description file is empty. No write.");
  if (text.length > DESCRIPTION_MAX) {
    throw new Error(`Description file is longer than ${DESCRIPTION_MAX} characters. No write.`);
  }
  if (!/devtamura/i.test(text)) {
    throw new Error("Description file must mention Devtamura. No write.");
  }
  return text;
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

export function assertAllowedDelete(id) {
  if (id !== DELETE_ID) {
    throw new Error(
      `Refusing to delete ${TEMPLES}/${id}. Only ${TEMPLES}/${DELETE_ID} may be deleted.`,
    );
  }
}

export function assertAllowedUpdate(id, fields) {
  if (id !== UPDATE_ID) {
    throw new Error(
      `Refusing to update ${TEMPLES}/${id}. Only ${TEMPLES}/${UPDATE_ID} may be updated.`,
    );
  }
  const keys = Object.keys(fields ?? {});
  if (keys.length !== 1 || keys[0] !== UPDATE_FIELD) {
    throw new Error(
      `Refusing to write ${keys.join(", ") || "(no fields)"} on ${TEMPLES}/${id}. Only ${UPDATE_FIELD} may be set.`,
    );
  }
  const text = fields[UPDATE_FIELD];
  if (typeof text !== "string" || text.trim() === "") {
    throw new Error("description must be a non-empty string.");
  }
  if (text.length > DESCRIPTION_MAX) {
    throw new Error(`description must be at most ${DESCRIPTION_MAX} characters.`);
  }
}

export function hasCover(data) {
  return typeof data?.imageUrl === "string" && data.imageUrl.trim() !== "";
}

/** photos[] entries that carry a url. Strings count as a url. */
export function photoCount(data) {
  if (!Array.isArray(data?.photos)) return 0;
  return data.photos.filter((photo) => {
    if (typeof photo === "string") return photo.trim() !== "";
    return Boolean(photo) && typeof photo.url === "string" && photo.url.trim() !== "";
  }).length;
}

export function photosLength(data) {
  return Array.isArray(data?.photos) ? data.photos.length : 0;
}

export function assertPreconditions(pair) {
  if (!pair.devtamura?.exists) {
    throw new Error(`${TEMPLES}/${DELETE_ID} does not exist. No write.`);
  }
  if (!pair.chabimura?.exists) {
    throw new Error(`${TEMPLES}/${UPDATE_ID} does not exist. No write.`);
  }
  for (const id of [UPDATE_ID, DELETE_ID]) {
    const state = pair[id].data?.state;
    if (state !== "Tripura") {
      throw new Error(
        `${TEMPLES}/${id} state is ${JSON.stringify(state ?? null)}, not Tripura. No write.`,
      );
    }
  }
  if (!hasCover(pair.chabimura.data)) {
    throw new Error(
      `${TEMPLES}/${UPDATE_ID} has no cover. Attach the photo pack with upload_research_pack.js first. No write.`,
    );
  }
  if (photoCount(pair.chabimura.data) < 1) {
    throw new Error(
      `${TEMPLES}/${UPDATE_ID} has no photos. Attach the photo pack with upload_research_pack.js first. No write.`,
    );
  }
}

export function assertTripuraCount(count) {
  if (count !== TRIPURA_BEFORE) {
    throw new Error(
      `Expected ${TRIPURA_BEFORE} Tripura temples before this merge, found ${count}. No write.`,
    );
  }
}

/**
 * The committed file must start with the trimmed live description.
 * Anything else is a replacement, and the merge aborts.
 */
export function descriptionAppend(live, fileText) {
  const current = typeof live === "string" ? live.trim() : "";
  if (current === "" || !fileText.startsWith(current)) {
    throw new Error(
      `${TEMPLES}/${UPDATE_ID} description is not a prefix of scripts/data/chabimura-description.txt. The change must be append-only. No write.`,
    );
  }
  const suffix = fileText.slice(current.length);
  return {
    live: current,
    text: fileText,
    suffix,
    changed: suffix.length > 0,
    reason: suffix.length > 0 ? "append" : "already-appended",
  };
}

export function buildReport(pair, description) {
  const next = descriptionAppend(pair.chabimura.data?.description, description);
  const data = pair.devtamura.data ?? {};
  return {
    beforeDescription: next.live,
    afterDescription: next.text,
    appendedSuffix: next.suffix,
    descriptionChanged: next.changed,
    descriptionReason: next.reason,
    devtamuraFields: Object.keys(data).sort(),
    devtamuraPhotoCount: photosLength(data),
    tripuraBefore: TRIPURA_BEFORE,
    tripuraAfter: TRIPURA_AFTER,
  };
}

export function formatReport(report, { apply = false, backupDir = null } = {}) {
  const lines = [];
  lines.push(apply ? "Mode: apply" : "Mode: dry-run");
  lines.push("chabimura description live:");
  lines.push(redactDownloadToken(report.beforeDescription));
  lines.push("chabimura description new:");
  lines.push(redactDownloadToken(report.afterDescription));
  lines.push("appended suffix:");
  lines.push(redactDownloadToken(report.appendedSuffix));
  if (!report.descriptionChanged) {
    lines.push("chabimura description already matches the file. Left unchanged.");
  }
  lines.push(
    `delete temples/${DELETE_ID} fields: ${report.devtamuraFields.join(", ")}`,
  );
  lines.push(
    `delete temples/${DELETE_ID} photos[]: ${report.devtamuraPhotoCount}`,
  );
  lines.push(`Tripura count: ${report.tripuraBefore} to ${report.tripuraAfter}`);
  lines.push("chabimura latitude and longitude are not written.");
  if (apply) {
    lines.push(`Backup: ${backupDir}`);
    lines.push(
      report.descriptionChanged
        ? `Updated temples/${UPDATE_ID} description.`
        : `Left temples/${UPDATE_ID} description unchanged.`,
    );
    lines.push(`Deleted temples/${DELETE_ID}.`);
  } else {
    lines.push("Dry-run only. No Firestore writes.");
  }
  lines.push(
    "Next: run node scripts/rebuild_index.js --project <id>. It should find 1 stale entry (devtamura) and remove it. This script does not call rebuild_index.",
  );
  lines.push(
    "ONE-USE: after the apply, delete scripts/merge_devtamura_into_chabimura.js and scripts/data/chabimura-description.txt. Do not run this again.",
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

export async function readPair(db) {
  const [chabimura, devtamura] = await Promise.all([
    readDoc(db, UPDATE_ID),
    readDoc(db, DELETE_ID),
  ]);
  return { chabimura, devtamura };
}

export async function countTripura(db) {
  const snap = await db.collection(TEMPLES).where("state", "==", "Tripura").get();
  return snap.size;
}

export function writeBackupFiles(dir, pair) {
  if (typeof dir !== "string" || dir.trim() === "") {
    throw new Error("--backup-dir is required with --apply.");
  }
  const folder = resolve(dir);
  mkdirSync(folder, { recursive: true });
  const files = [];
  for (const id of [UPDATE_ID, DELETE_ID]) {
    const body = `${JSON.stringify(
      {
        id,
        path: `${TEMPLES}/${id}`,
        data: toPlain(pair[id].data),
      },
      null,
      2,
    )}\n`;
    const path = join(folder, `${id}.json`);
    writeFileSync(path, body, { encoding: "utf8" });
    const back = readFileSync(path, "utf8");
    if (back !== body) {
      throw new Error(`Backup read-back failed for ${path}.`);
    }
    files.push(path);
  }
  return { dir: folder, files };
}

async function commitMerge(db, pair, description) {
  const chabiRef = db.collection(TEMPLES).doc(UPDATE_ID);
  const devRef = db.collection(TEMPLES).doc(DELETE_ID);
  const query = db.collection(TEMPLES).where("state", "==", "Tripura");
  await db.runTransaction(async (tx) => {
    const chabiSnap = await tx.get(chabiRef);
    const devSnap = await tx.get(devRef);
    const counted = await tx.get(query);
    const fresh = {
      chabimura: {
        id: UPDATE_ID,
        exists: Boolean(chabiSnap.exists),
        data: chabiSnap.exists ? chabiSnap.data() ?? {} : null,
      },
      devtamura: {
        id: DELETE_ID,
        exists: Boolean(devSnap.exists),
        data: devSnap.exists ? devSnap.data() ?? {} : null,
      },
    };
    assertPreconditions(fresh);
    assertTripuraCount(counted.size);
    const next = descriptionAppend(fresh.chabimura.data?.description, description);
    if (!samePair(pair, fresh)) {
      throw new Error("Documents changed after the backup. No write.");
    }
    if (next.changed) {
      const fields = { [UPDATE_FIELD]: next.text };
      assertAllowedUpdate(UPDATE_ID, fields);
      tx.update(chabiRef, fields);
    }
    assertAllowedDelete(DELETE_ID);
    tx.delete(devRef);
  });
}

function samePair(left, right) {
  return (
    stable(left.chabimura.data) === stable(right.chabimura.data) &&
    stable(left.devtamura.data) === stable(right.devtamura.data)
  );
}

export async function inspectMerge(db, description) {
  const pair = await readPair(db);
  assertPreconditions(pair);
  assertTripuraCount(await countTripura(db));
  return buildReport(pair, description);
}

export async function applyMerge(
  db,
  { backupDir, description, log = () => {}, writeBackup = writeBackupFiles },
) {
  const pair = await readPair(db);
  assertPreconditions(pair);
  assertTripuraCount(await countTripura(db));
  const report = buildReport(pair, description);
  let backup;
  try {
    backup = writeBackup(backupDir, pair);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Backup failed: ${message} No write.`);
  }
  log(`Backup: ${backup.dir}`);
  await commitMerge(db, pair, description);
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
 *   descriptionPath?: string,
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
  const env = deps.env ?? process.env;
  if (opts.apply && !opts.backupDir) {
    throw new Error("--backup-dir is required with --apply. No write.");
  }
  const project = resolveProject(opts, env);
  const description = loadDescription(deps.descriptionPath);
  if (opts.apply) {
    await authorizeApply(project, env, { confirm: deps.confirm });
  }
  const db = deps.db ?? (await openFirestore(project, env));
  if (!opts.apply) {
    const report = await inspectMerge(db, description);
    log(formatReport(report, { apply: false }));
    return { report, wrote: false };
  }
  const applied = await applyMerge(db, {
    backupDir: opts.backupDir,
    description,
    log,
    writeBackup: deps.writeBackup,
  });
  log(formatReport(applied.report, { apply: true, backupDir: applied.backupDir }));
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
