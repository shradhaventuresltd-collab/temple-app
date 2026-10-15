/**
 * Patch specific Firestore fields from a JSON file. Deployer only.
 *
 *   node apply_field_patches.js --patches <file>
 *   node apply_field_patches.js --apply --project <id> --patches <file>
 *
 * Dry-run is the default and does not connect. --apply updates only the keys
 * listed under each temple's fields object. It refuses CI and requires a
 * confirm prompt plus an explicit --project. It does not upload Storage
 * objects and it does not run Seed.
 */
import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { confirmProject } from "./prod_guard.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

const ALLOWED_FIELDS = new Set([
  "imageUrl",
  "images",
  "photos",
  "timings",
]);

function printUsage() {
  console.log(`
Usage:
  node apply_field_patches.js --patches <file>
  node apply_field_patches.js --apply --project <id> --patches <file>

Each temple entry is { "id", "fields": { ... } }. Only imageUrl, images,
photos, and timings are accepted. Other keys are rejected so a patch cannot
rewrite the rest of the document.
`);
}

function parseArgs(argv) {
  const opts = {
    patches: null,
    apply: false,
    project: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.apply = false;
    else if (arg === "--apply") opts.apply = true;
    else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--patches") opts.patches = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function loadPatches(file) {
  const parsed = JSON.parse(readFileSync(file, "utf8"));
  if (!parsed || !Array.isArray(parsed.temples)) {
    throw new Error("Patch file must contain a temples list.");
  }
  const temples = parsed.temples.map((entry, index) => {
    if (!entry || typeof entry.id !== "string" || entry.id.trim() === "") {
      throw new Error(`temples[${index}].id is required.`);
    }
    if (!entry.fields || typeof entry.fields !== "object" || Array.isArray(entry.fields)) {
      throw new Error(`${entry.id} is missing fields.`);
    }
    const keys = Object.keys(entry.fields);
    if (keys.length === 0) throw new Error(`${entry.id} has no fields.`);
    for (const key of keys) {
      if (!ALLOWED_FIELDS.has(key)) {
        throw new Error(`${entry.id} field "${key}" is not allowed.`);
      }
    }
    return { id: entry.id.trim(), fields: entry.fields };
  });
  const ids = temples.map((temple) => temple.id);
  if (new Set(ids).size !== ids.length) throw new Error("Duplicate temple id in patch file.");
  return { description: parsed.description || "", temples };
}

function printPlan(patch) {
  console.log("Mode: dry-run");
  if (patch.description) console.log(patch.description);
  console.log(`Temples: ${patch.temples.length}`);
  for (const temple of patch.temples) {
    const keys = Object.keys(temple.fields).join(", ");
    console.log(`  temples/${temple.id}  fields: ${keys}`);
  }
  console.log("\nNo Firestore connection. No writes.");
}

async function applyPatches(project, patch) {
  const { existsSync } = await import("node:fs");
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) throw new Error("service-account.json was not found. No write.");
  const admin = (await import("firebase-admin")).default;
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
  const db = admin.firestore();
  for (const temple of patch.temples) {
    const ref = db.collection("temples").doc(temple.id);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new Error(`temples/${temple.id} does not exist. No partial create.`);
    }
    await ref.update(temple.fields);
    console.log(
      `updated temples/${temple.id} (${Object.keys(temple.fields).join(", ")})`,
    );
  }
}

async function main(argv = process.argv.slice(2)) {
  const opts = parseArgs(argv);
  if (opts.help || !opts.patches) {
    printUsage();
    process.exit(opts.help ? 0 : 1);
  }
  const patch = loadPatches(resolve(opts.patches));
  if (!opts.apply) {
    printPlan(patch);
    return patch;
  }
  const project = await confirmProject(opts.project);
  console.log(`Mode: apply project ${project}`);
  await applyPatches(project, patch);
  return patch;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}

export { main, parseArgs };
