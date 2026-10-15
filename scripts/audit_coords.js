/**
 * Find temples whose latitude and longitude are not both set or both empty.
 *
 * Dry-run is the default. It lists unpaired documents and writes nothing.
 *
 *   node scripts/audit_coords.js --project temple-directory-india
 *
 * Apply nulls both latitude and longitude on those documents. Deployer runs
 * this before deploying the paired-coordinate rules, so an existing unpaired
 * document is not locked. CI cannot apply. A prod apply asks you to type the
 * project id. There is no default project. Apply does not deploy rules.
 *
 *   node scripts/audit_coords.js --apply --project temple-directory-india
 *
 * An update that does not touch latitude or longitude is already allowed by
 * the rules. This script is how the stored documents become paired.
 * Do not run --apply from CI or from an agent against production.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function printUsage() {
  console.log(`
Usage:
  node audit_coords.js [--dry-run] [--project <firebase-project-id>]
  node audit_coords.js --apply --project <firebase-project-id>

Default is dry-run: list temples with only one of latitude or longitude.
Nothing is written. --apply sets both fields to null. CI is refused.
Prod apply prompts for the project id. Run this before deploying rules.
`);
}

export function parseArgs(argv) {
  const opts = { dryRun: true, apply: false, project: null, help: false };
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
  const firestore = env.FIRESTORE_EMULATOR_HOST;
  return typeof firestore === "string" && firestore.trim() !== "";
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

function axisSet(value, present) {
  return present && value !== null && value !== undefined;
}

/** `latitude-only`, `longitude-only`, or null when the pair is already clean. */
export function coordinateIssue(temple) {
  const hasLat = Object.prototype.hasOwnProperty.call(temple ?? {}, "latitude");
  const hasLng = Object.prototype.hasOwnProperty.call(temple ?? {}, "longitude");
  const latSet = axisSet(temple?.latitude, hasLat);
  const lngSet = axisSet(temple?.longitude, hasLng);
  if (latSet === lngSet) return null;
  return latSet ? "latitude-only" : "longitude-only";
}

export function planCoordinateAudit(temples) {
  return (temples ?? []).map((temple) => {
    const id = String(temple?.id ?? "");
    const reason = coordinateIssue(temple);
    if (!reason) return { id, action: "ok" };
    return {
      id,
      action: "null-both",
      reason,
      latitude: temple.latitude ?? null,
      longitude: temple.longitude ?? null,
    };
  });
}

export async function applyCoordinatePlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "null-both") {
      report.push({ ...plan, result: "ok" });
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...plan, result: "would-null" });
      continue;
    }
    await deps.update(plan.id, { latitude: null, longitude: null });
    report.push({ ...plan, result: "nulled" });
  }
  return report;
}

export function formatCoordinateReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const pending = rows.filter((row) => row.action === "null-both");
  lines.push(`temples: ${rows.length}  unpaired: ${pending.length}`);
  for (const row of pending) {
    lines.push(`${row.result} ${row.id} ${row.reason}`);
  }
  if (!apply) lines.push("Dry-run only. No Firestore writes.");
  else lines.push("Unpaired coordinates set to null. Rules were not deployed.");
  return lines.join("\n");
}

async function openAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length > 0) return admin;
  if (usesEmulator(env)) {
    admin.initializeApp({ projectId: project });
    return admin;
  }
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) {
    throw new Error("service-account.json was not found. No write.");
  }
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== project) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${project}. No write.`,
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
  });
  return admin;
}

async function loadTemples(project, env) {
  const admin = await openAdmin(project, env);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const log = deps.log ?? ((line) => console.log(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  if (opts.apply) await authorizeApply(project, env, { confirm: deps.confirm });
  const load = deps.load ?? loadTemples;
  const temples = await load(project, env);
  const plans = planCoordinateAudit(temples);
  let update = deps.update;
  if (opts.apply && !update) {
    const admin = await openAdmin(project, env);
    const db = admin.firestore();
    update = (id, data) => db.collection("temples").doc(id).update(data);
  }
  const rows = await applyCoordinatePlans(plans, {
    dryRun: !opts.apply,
    update: update ?? (async () => {}),
  });
  log(formatCoordinateReport(rows, { apply: opts.apply }));
  return rows;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}
