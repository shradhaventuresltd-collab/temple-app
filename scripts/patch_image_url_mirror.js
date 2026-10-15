/**
 * Point imageUrl at images[0] for the prod mirror set.
 *
 * Prod galleries for these temples are Storage objects under
 * temples/<id>/image_N.jpg, while imageUrl is a different Wikimedia URL
 * (anjengo's imageUrl is empty). This script updates only imageUrl.
 *
 *   node patch_image_url_mirror.js                 # dry-run, no network
 *   node patch_image_url_mirror.js --apply --project <id>
 *
 * --apply reads each live document and sets imageUrl to that document's
 * images[0]. It does not write images, photos, or any other field.
 * It requires a confirm prompt.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 * Do not run Seed or upload_research_pack.js --patch-firestore.
 */
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { confirmProject } from "./prod_guard.js";

/** Audit rows whose issues contain MIRROR. Repo seed ids, not pack folders. */
export const MIRROR_TEMPLE_IDS = [
  "anjengo-sree-durga-devi-temple",
  "arunachaleswarar-temple",
  "attukal-bhagavathy-temple",
  "brihadeeswarar-temple",
  "chamundeshwari-temple",
  "chottanikkara-bhagavathy-temple",
  "ekambaranathar-temple",
  "ernakulathappan-temple",
  "guruvayur-sri-krishna-temple",
  "iskcon-temple-bangalore",
  "kapaleeshwarar-temple",
  "kollur-mookambika-temple",
  "kukke-subramanya-temple",
  "mahabaleshwar-temple-gokarna",
  "mannarsala-sree-nagaraja-temple",
  "meenakshi-amman-temple",
  "murugan-temple-thirupparankundram",
  "nataraja-temple",
  "ramanathaswamy-temple",
  "sabarimala-ayyappan-temple",
  "sarangapani-temple",
  "shore-temple",
  "sree-padmanabhaswamy-temple",
  "sri-krishna-matha-udupi",
  "sri-manjunatha-temple-dharmasthala",
  "srikanteshwara-temple-nanjangud",
  "sringeri-sharada-peetham",
  "thirunelli-maha-vishnu-temple",
  "vaikom-mahadeva-temple",
  "virupaksha-temple",
];

function printUsage() {
  console.log(`
Usage:
  node patch_image_url_mirror.js
  node patch_image_url_mirror.js --apply --project <firebase-project-id>

Dry-run is the default. It prints the ${MIRROR_TEMPLE_IDS.length} document ids and
does not connect to Firestore. --apply sets temples/{id}.imageUrl = images[0]
and no other field. An empty images list is skipped.
`);
}

function parseArgs(argv) {
  const opts = { apply: false, project: null, help: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.apply = false;
    else if (arg === "--apply") opts.apply = true;
    else if (arg === "--project") opts.project = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

function dryRunPlan() {
  console.log("Mode: dry-run");
  console.log("Field: imageUrl only (set to the live document's images[0])");
  console.log(`Temples: ${MIRROR_TEMPLE_IDS.length}`);
  for (const id of MIRROR_TEMPLE_IDS) {
    console.log(`  temples/${id}  imageUrl = images[0]`);
  }
  console.log("\nNo Firestore connection. No writes.");
}

async function applyMirror(project) {
  const { readFileSync, existsSync } = await import("node:fs");
  const { dirname, resolve: resolvePath } = await import("node:path");
  const here = dirname(fileURLToPath(import.meta.url));
  const candidates = [
    resolvePath(here, "service-account.json"),
    resolvePath(here, "..", "service-account.json"),
  ];
  const saPath = candidates.find((path) => existsSync(path));
  if (!saPath) {
    throw new Error("service-account.json was not found. No write.");
  }
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
  let updated = 0;
  let unchanged = 0;
  let skipped = 0;
  for (const id of MIRROR_TEMPLE_IDS) {
    const ref = db.collection("temples").doc(id);
    const snap = await ref.get();
    if (!snap.exists) {
      console.log(`skip ${id}: document missing`);
      skipped += 1;
      continue;
    }
    const data = snap.data() || {};
    const images = Array.isArray(data.images)
      ? data.images.map((item) => String(item).trim()).filter(Boolean)
      : [];
    if (images.length === 0) {
      console.log(`skip ${id}: images is empty`);
      skipped += 1;
      continue;
    }
    const next = images[0];
    const current = typeof data.imageUrl === "string" ? data.imageUrl : "";
    if (current === next) {
      console.log(`unchanged ${id}`);
      unchanged += 1;
      continue;
    }
    await ref.update({ imageUrl: next });
    console.log(`updated ${id}`);
    console.log(`  imageUrl was: ${current || "(empty)"}`);
    console.log(`  imageUrl now: ${next}`);
    updated += 1;
  }
  console.log(
    `\nDone. updated ${updated}, unchanged ${unchanged}, skipped ${skipped}. images was not written.`,
  );
}

async function main(argv = process.argv.slice(2)) {
  const opts = parseArgs(argv);
  if (opts.help) {
    printUsage();
    return;
  }
  if (!opts.apply) {
    dryRunPlan();
    return;
  }
  const project = await confirmProject(opts.project);
  console.log(`Mode: apply project ${project}`);
  await applyMirror(project);
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
