/**
 * Write `_480` Storage thumbs for temple cover images.
 *
 * Dry-run is the default. It reads temple documents and prints which cover
 * objects would gain a `temples/{id}/{file}_480.{ext}` sibling. It does not
 * write.
 *
 *   node scripts/resize_cover_thumbs.js --project temple-directory-india
 *
 * Apply is hand-run only. CI cannot apply. A prod apply asks you to type
 * the project id. There is no default project. Apply uploads thumbs only.
 * It does not write Firestore and it does not deploy.
 *
 *   node scripts/resize_cover_thumbs.js --apply --project temple-directory-india
 *
 * After apply, rebuild the index so browse covers point at the new thumbs:
 *
 *   node scripts/rebuild_index.js --apply --project temple-directory-india
 *
 * Encoding uses sharp, installed by Deployer (`npm install --prefix scripts sharp`).
 * Tests inject an encoder and never import sharp. Do not run --apply from CI
 * or from an agent against production.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import {
  firstVerifiedGalleryUrl,
  storageObjectFromUrl,
  storageThumbUrl,
  thumbObjectPath,
} from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const THUMB_CACHE_CONTROL = "public, max-age=31536000, immutable";
export const THUMB_EDGE = 480;

function printUsage() {
  console.log(`
Usage:
  node resize_cover_thumbs.js [--dry-run] [--project <firebase-project-id>]
  node resize_cover_thumbs.js --apply --project <firebase-project-id>

Default is dry-run: list cover objects that still need a _480 sibling.
Nothing is written. --apply is for Deployer, in a terminal, after merge.
CI is refused. Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.

Apply writes Storage objects only. It does not update Firestore and it
does not deploy rules. Run rebuild_index.js --apply afterwards so
coverThumb points at the thumbs. Install sharp before apply:
  npm install --prefix scripts sharp
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
  const firestore = env.FIRESTORE_EMULATOR_HOST;
  const storage = env.FIREBASE_STORAGE_EMULATOR_HOST;
  return (
    (typeof firestore === "string" && firestore.trim() !== "") ||
    (typeof storage === "string" && storage.trim() !== "")
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

function extOf(objectPath) {
  const file = objectPath.split("/").pop() ?? "";
  const dot = file.lastIndexOf(".");
  return dot === -1 ? "" : file.slice(dot + 1);
}

export function contentTypeForExt(ext) {
  const lower = String(ext ?? "").toLowerCase();
  if (lower === "png") return "image/png";
  if (lower === "webp") return "image/webp";
  return "image/jpeg";
}

/**
 * One cover. `upload` means a full-size Storage object should gain a thumb.
 * Wikimedia and other non-Storage covers are `skip` (browse already rewrites
 * Wikimedia to 480px). An object that is already `_480` is `skip`.
 */
export function planCoverThumb(temple) {
  const id = String(temple?.id ?? "");
  const source = firstVerifiedGalleryUrl(temple);
  if (!source) return { id, action: "skip", reason: "no-cover" };
  const located = storageObjectFromUrl(source);
  if (!located) return { id, action: "skip", reason: "not-storage", source };
  const thumbPath = thumbObjectPath(located.objectPath);
  if (!thumbPath) return { id, action: "skip", reason: "already-thumb", source };
  const thumbUrl = storageThumbUrl(source);
  if (!thumbUrl) return { id, action: "skip", reason: "thumb-url", source };
  return {
    id,
    action: "upload",
    source,
    objectPath: located.objectPath,
    thumbPath,
    thumbUrl,
    contentType: contentTypeForExt(extOf(thumbPath)),
    cacheControl: THUMB_CACHE_CONTROL,
  };
}

export function planCoverThumbs(temples) {
  return (temples ?? []).map((temple) => planCoverThumb(temple));
}

/**
 * @param {object[]} plans from [planCoverThumbs]
 * @param {{
 *   dryRun: boolean,
 *   exists: (path: string) => Promise<boolean>,
 *   download?: (path: string) => Promise<Buffer>,
 *   encode?: (bytes: Buffer, ext: string) => Promise<Buffer>,
 *   upload?: (file: { path: string, bytes: Buffer, contentType: string, cacheControl: string }) => Promise<void>,
 * }} deps
 */
export async function applyCoverThumbPlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "upload") {
      report.push({ ...plan, result: "skipped" });
      continue;
    }
    const already = await deps.exists(plan.thumbPath);
    if (already) {
      report.push({ ...plan, result: "exists" });
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...plan, result: "would-upload" });
      continue;
    }
    const bytes = await deps.download(plan.objectPath);
    const thumb = await deps.encode(bytes, extOf(plan.thumbPath));
    if (!thumb || thumb.length === 0) {
      throw new Error(`Encoder returned an empty thumb for ${plan.thumbPath}. No write.`);
    }
    await deps.upload({
      path: plan.thumbPath,
      bytes: thumb,
      contentType: plan.contentType,
      cacheControl: plan.cacheControl,
    });
    report.push({ ...plan, result: "uploaded", bytes: thumb.length });
  }
  return report;
}

export function formatThumbReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const counts = { upload: 0, exists: 0, skip: 0, uploaded: 0 };
  for (const row of rows) {
    if (row.result === "would-upload" || row.result === "uploaded") counts.upload += 1;
    else if (row.result === "exists") counts.exists += 1;
    else counts.skip += 1;
    if (row.result === "uploaded") counts.uploaded += 1;
  }
  lines.push(
    `covers: ${rows.length}  thumbs: ${counts.upload}  exists: ${counts.exists}  skip: ${counts.skip}`,
  );
  for (const row of rows) {
    if (row.result === "would-upload" || row.result === "uploaded") {
      lines.push(`${row.result} ${row.id} ${row.thumbPath}`);
    } else if (row.result === "exists") {
      lines.push(`exists ${row.id} ${row.thumbPath}`);
    } else if (row.reason) {
      lines.push(`skip ${row.id} ${row.reason}`);
    }
  }
  if (!apply) lines.push("Dry-run only. No Storage writes.");
  else lines.push("Storage thumbs only. Firestore was not written. Run rebuild_index.js --apply next.");
  return lines.join("\n");
}

/**
 * sharp resize. Imported only when Deployer applies. Tests never call this.
 * Width is [THUMB_EDGE]. Smaller frames are not enlarged.
 */
export async function encodeWithSharp(bytes, ext) {
  let sharp;
  try {
    ({ default: sharp } = await import("sharp"));
  } catch {
    throw new Error(
      "Thumbnail encoding needs sharp. From the repo: npm install --prefix scripts sharp. No write.",
    );
  }
  const input = sharp(bytes, { failOn: "none" }).rotate();
  const meta = await input.metadata();
  const width = meta.width ?? 0;
  const pipeline = width > THUMB_EDGE ? input.resize({ width: THUMB_EDGE, withoutEnlargement: true }) : input;
  const lower = String(ext ?? "").toLowerCase();
  if (lower === "png") return pipeline.png().toBuffer();
  if (lower === "webp") return pipeline.webp({ quality: 80 }).toBuffer();
  return pipeline.jpeg({ quality: 80 }).toBuffer();
}

async function openAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length > 0) return admin;
  if (usesEmulator(env)) {
    admin.initializeApp({ projectId: project, storageBucket: `${project}.appspot.com` });
    return admin;
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
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
    storageBucket:
      env.STORAGE_BUCKET || `${project}.firebasestorage.app`,
  });
  return admin;
}

async function loadTemples(project, env) {
  const admin = await openAdmin(project, env);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

function storageDeps(bucket, env) {
  return {
    exists: async (path) => {
      const [found] = await bucket.file(path).exists();
      return found;
    },
    download: async (path) => {
      const [bytes] = await bucket.file(path).download();
      return bytes;
    },
    encode: encodeWithSharp,
    upload: async (file) => {
      await bucket.file(file.path).save(file.bytes, {
        resumable: false,
        metadata: {
          contentType: file.contentType,
          cacheControl: file.cacheControl,
        },
      });
    },
    env,
  };
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
  const plans = planCoverThumbs(temples);
  let storage = deps.storage ?? null;
  const needsBucket = !deps.exists || (opts.apply && !deps.upload);
  if (needsBucket && !storage) {
    const admin = await openAdmin(project, env);
    storage = storageDeps(admin.storage().bucket(), env);
  }
  const rows = await applyCoverThumbPlans(plans, {
    dryRun: !opts.apply,
    exists: deps.exists ?? storage.exists,
    download: deps.download ?? storage?.download,
    encode: deps.encode ?? storage?.encode,
    upload: deps.upload ?? storage?.upload,
  });
  log(formatThumbReport(rows, { apply: opts.apply }));
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
