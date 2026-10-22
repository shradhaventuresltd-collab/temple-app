/**
 * Rewrite legacy upload.wikimedia.org originals in temples.images[] to a
 * 1280px Commons thumb. SVG, a thumb already at or under 1280px, and any
 * host other than upload.wikimedia.org stay as stored. A URL that already
 * matches photos[].url is left alone so galleryUrl and credits stay paired.
 * The app caps those at render time when galleryUrl is missing.
 *
 * Dry-run is the default. It reads temple documents and prints which
 * images[] entries would change. It does not write.
 *
 *   node scripts/cap_wikimedia_images.js --project temple-directory-india
 *
 * --apply writes only images[]. imageUrl, photos, and the index are not
 * touched. --backup-dir is required. Each temple is copied there before
 * its images[] update. CI cannot apply. There is no default project.
 *
 *   node scripts/cap_wikimedia_images.js --apply --backup-dir <folder> --project <id>
 *
 * prod --apply is run only by the Deployer agent or Sanu, dry run first,
 * never from CI, and only after Architect sign-off. Do not run this
 * against production from an unattended agent.
 *
 * Apply prints a summary of written and skipped images, with a count per
 * skip reason. APPLY-FINISHED is printed only when every row succeeded.
 * A failed row prints APPLY-INCOMPLETE and the process exits non-zero.
 * If the run never reaches that summary, beforeExit prints
 * APPLY-INCOMPLETE and exits 1.
 *
 * Deferred, not this script: 28 older temples (Tamil Nadu 10, Karnataka 10,
 * Kerala 8) have 89 Firebase Storage URLs in images[] and no photos[] row.
 * Backfill photos[] only with a verified licence, author, and source from
 * the research packs or Pavi. Nothing may be inferred. KAN-175, 19 Oct 2026.
 */
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactDownloadToken, redactThrown } from "./redact_url.js";
import {
  DEFAULT_TIMEOUT_MS,
  beginRun,
  callBounded,
  chunk,
  failureText,
  finishRun,
  incompleteOnBeforeExit,
  logBatch,
  networkLimits,
  parseTimeoutMs,
  reportProcessFault,
} from "./run_guard.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const runTracker = { active: false, summarized: false, rows: [], started: 0 };

export const GALLERY_CAP_PX = 1280;

function safeDecode(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

/** MediaWiki path encoding. Commas stay literal so this matches Dart. */
function commonsEncode(name) {
  return encodeURIComponent(name).replace(
    /%(3B|40|24|21|2A|28|29|2C|7E|3A)/gi,
    (token) => String.fromCharCode(Number.parseInt(token.slice(1), 16)),
  );
}

function commonsMd5(filename) {
  return createHash("md5").update(filename, "utf8").digest("hex");
}

function isSvgName(name) {
  const lower = safeDecode(name).replace(/ /g, "_").toLowerCase();
  return lower.endsWith(".svg") || lower.endsWith(".svgz") || /\.svg\.(png|jpe?g)$/.test(lower);
}

function isUntouchable(decoded) {
  return /\.(pdf|djvu|webm|ogv)$/i.test(decoded);
}

function thumbFileName(decoded, encoded) {
  const lower = decoded.toLowerCase();
  const width = `${GALLERY_CAP_PX}px`;
  if (lower.endsWith(".svg") || lower.endsWith(".svgz")) return null;
  if (lower.endsWith(".tif") || lower.endsWith(".tiff")) return `${width}-${encoded}.jpg`;
  if (isUntouchable(decoded)) return null;
  if (!/\.[a-z0-9]+$/i.test(lower)) return null;
  return `${width}-${encoded}`;
}

function keep(url, reason) {
  return { url, reason };
}

/**
 * Pure images[] mapping. No network.
 * `reason` is null when `url` is the 1280px thumb that should replace the
 * input. Otherwise `url` is the trimmed input.
 */
export function classifyWikimediaImage(raw) {
  const trimmed = typeof raw === "string" ? raw.trim() : "";
  if (!trimmed.toLowerCase().startsWith("https://")) return keep(trimmed, "not-wikimedia");
  let parsed;
  try {
    parsed = new URL(trimmed);
  } catch {
    return keep(trimmed, "not-wikimedia");
  }
  if (parsed.hostname.toLowerCase() !== "upload.wikimedia.org") {
    return keep(trimmed, "not-wikimedia");
  }
  // Raw path, not URL.pathname, so `%2C` and `%2F` stay inside one segment.
  const pathMatch = /^[a-z][a-z0-9+.-]*:\/\/[^/?#]+([^?#]*)/i.exec(trimmed);
  const parts = (pathMatch ? pathMatch[1] : "").split("/");
  if (parts.length < 4 || parts[1].toLowerCase() !== "wikipedia") {
    return keep(trimmed, "unrecognized");
  }
  if (parts[2].toLowerCase() !== "commons") return keep(trimmed, "not-commons");
  if (parts[3].toLowerCase() === "thumb") return classifyThumb(trimmed, parts);
  return classifyOriginal(trimmed, parts);
}

function classifyThumb(trimmed, parts) {
  if (parts.length !== 8) return keep(trimmed, "unrecognized");
  const h = parts[4];
  const hh = parts[5];
  const file = parts[6];
  const last = parts[7];
  if (!/^[0-9a-f]$/i.test(h) || !/^[0-9a-f]{2}$/i.test(hh) || !file || !last) {
    return keep(trimmed, "unrecognized");
  }
  const sized = /^(\d+)px-(.+)$/i.exec(last);
  if (!sized) return keep(trimmed, "unrecognized");
  if (isSvgName(file) || isSvgName(sized[2])) return keep(trimmed, "svg");
  const width = Number(sized[1]);
  if (!Number.isFinite(width) || width <= GALLERY_CAP_PX) {
    return keep(trimmed, "at-or-under-1280");
  }
  return { url: narrowLastSegment(trimmed), reason: null };
}

function classifyOriginal(trimmed, parts) {
  if (parts.includes("thumb")) return keep(trimmed, "unrecognized");
  let rawName;
  let givenH = null;
  let givenHh = null;
  if (parts.length === 4) {
    rawName = parts[3];
  } else if (parts.length === 6) {
    givenH = parts[3];
    givenHh = parts[4];
    rawName = parts[5];
  } else {
    return keep(trimmed, "unrecognized");
  }
  if (!rawName) return keep(trimmed, "unrecognized");
  const decoded = safeDecode(rawName).replace(/ /g, "_");
  if (!decoded || decoded.includes("/") || decoded.includes("\\")) {
    return keep(trimmed, "unrecognized");
  }
  if (isSvgName(decoded)) return keep(trimmed, "svg");
  if (isUntouchable(decoded)) return keep(trimmed, "not-thumbnailable");
  const digest = commonsMd5(decoded);
  const h = digest[0];
  const hh = digest.slice(0, 2);
  if (givenH != null && (givenH.toLowerCase() !== h || givenHh.toLowerCase() !== hh)) {
    return keep(trimmed, "hash-mismatch");
  }
  const encoded = commonsEncode(decoded);
  const thumbFile = thumbFileName(decoded, encoded);
  if (!thumbFile) return keep(trimmed, "not-thumbnailable");
  return {
    url: `https://upload.wikimedia.org/wikipedia/commons/thumb/${h}/${hh}/${encoded}/${thumbFile}`,
    reason: null,
  };
}

function narrowLastSegment(trimmed) {
  const hashAt = trimmed.indexOf("#");
  const noHash = hashAt === -1 ? trimmed : trimmed.slice(0, hashAt);
  const queryAt = noHash.indexOf("?");
  const path = queryAt === -1 ? noHash : noHash.slice(0, queryAt);
  const suffix = trimmed.slice(path.length);
  const slash = path.lastIndexOf("/");
  const last = path.slice(slash + 1);
  const next = last.replace(/^\d+px-/i, `${GALLERY_CAP_PX}px-`);
  return `${path.slice(0, slash + 1)}${next}${suffix}`;
}

function printUsage() {
  console.log(`
Usage:
  node cap_wikimedia_images.js [--dry-run] [--project <id>]
  node cap_wikimedia_images.js --apply --backup-dir <folder> --project <id>

Default is dry-run: list images[] entries that would become a 1280px
Commons thumb. Nothing is written. SVG, thumbs already at or under
1280px, and URLs that are not https://upload.wikimedia.org are skipped.
An images[] entry that matches photos[].url is skipped so that photo
keeps galleryUrl. imageUrl, photos, and the index are never written.

--apply requires --backup-dir. The current images[] array is saved there
before the update. CI cannot apply. Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.
prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.

The 28 older temples whose images[] are Firebase Storage URLs with no
photos[] row are not backfilled here.
`);
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    project: null,
    backupDir: null,
    help: false,
    timeoutMs: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--timeout-ms") opts.timeoutMs = parseTimeoutMs(argv[++i]);
    else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--backup-dir") {
      const raw = argv[++i];
      if (typeof raw !== "string" || raw.trim() === "") {
        throw new Error("--backup-dir needs a local folder. No write.");
      }
      opts.backupDir = raw.trim();
    } else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

export function usesEmulator(env = process.env) {
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

export function requireBackupDir(backupDir) {
  if (typeof backupDir !== "string" || backupDir.trim() === "") {
    throw new Error("--apply needs --backup-dir <folder>. No write.");
  }
  return backupDir.trim();
}

function photoUrls(temple) {
  const urls = new Set();
  const photos = Array.isArray(temple?.photos) ? temple.photos : [];
  for (const photo of photos) {
    if (!photo || typeof photo !== "object") continue;
    if (typeof photo.url !== "string") continue;
    const trimmed = photo.url.trim();
    if (trimmed) urls.add(trimmed);
  }
  return urls;
}

/**
 * One row per images[] entry. `rewrite` is a 1280px thumb. Entries that
 * match photos[].url are `has-photo` and stay, so a later update does not
 * detach galleryUrl. Non-arrays are a single `not-list` row and are not written.
 */
export function planTemple(temple) {
  const id = String(temple?.id ?? "");
  const images = temple?.images;
  if (!Array.isArray(images)) {
    if (images == null) return { id, changed: false, images, rows: [] };
    return {
      id,
      changed: false,
      images,
      rows: [{ id, index: -1, action: "skip", reason: "not-list", source: "" }],
    };
  }
  const paired = photoUrls(temple);
  const rows = [];
  const next = images.slice();
  let changed = false;
  images.forEach((item, index) => {
    if (typeof item !== "string") {
      rows.push({ id, index, action: "skip", reason: "not-url", source: "" });
      return;
    }
    const source = item.trim();
    if (source && paired.has(source)) {
      rows.push({ id, index, action: "skip", reason: "has-photo", source });
      return;
    }
    const capped = classifyWikimediaImage(item);
    if (capped.reason || capped.url === item) {
      rows.push({
        id,
        index,
        action: "skip",
        reason: capped.reason || "unchanged",
        source,
      });
      return;
    }
    next[index] = capped.url;
    changed = true;
    rows.push({ id, index, action: "rewrite", source, url: capped.url });
  });
  return { id, changed, images: next, rows };
}

/**
 * Backup file for one temple. The name is the document id, so a slash or
 * other path character cannot leave [dir].
 */
export function backupPath(dir, id) {
  const name = String(id ?? "");
  if (!/^[A-Za-z0-9_-]{1,200}$/.test(name)) {
    throw new Error(`Temple id "${name}" cannot be used as a backup file name. No write.`);
  }
  return join(dir, `${name}.json`);
}

/** Write the images[] array that is about to be replaced. No other field. */
export function writeBackup(dir, id, images) {
  const path = backupPath(dir, id);
  const body = `${JSON.stringify({ id, images }, null, 2)}\n`;
  const tmp = `${path}.tmp`;
  writeFileSync(tmp, body);
  renameSync(tmp, path);
  return path;
}

/**
 * Transaction: re-read, refuse when images[] changed, back up that array,
 * then update images[] and nothing else.
 */
export async function persistCappedImages(db, assigned, backup) {
  const id = String(assigned?.id ?? "");
  if (!id) return { ok: false, reason: "missing" };
  if (typeof backup !== "function") {
    throw new Error("--apply needs a backup writer. No write.");
  }
  return db.runTransaction(async (tx) => {
    const ref = db.collection("temples").doc(id);
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false, reason: "missing" };
    const fresh = snap.data() || {};
    if (JSON.stringify(fresh.images) !== JSON.stringify(assigned.images)) {
      return { ok: false, reason: "changed" };
    }
    const planned = planTemple({ ...fresh, id, images: fresh.images });
    if (!planned.changed) return { ok: false, reason: "unchanged" };
    if (JSON.stringify(planned.images) !== JSON.stringify(assigned.next)) {
      return { ok: false, reason: "changed" };
    }
    await backup(id, fresh.images);
    const patch = { images: planned.images };
    const keys = Object.keys(patch);
    if (keys.length !== 1 || keys[0] !== "images") {
      throw new Error("Refusing to write a patch that is not images[]. No write.");
    }
    tx.update(ref, patch);
    return { ok: true, id, images: planned.images };
  });
}

function rowResult(row, result, reason) {
  if (row.action !== "rewrite") return { ...row, result: "skipped" };
  return { ...row, result, reason: reason ?? row.reason };
}

async function applyTemple(temple, deps) {
  const planned = planTemple(temple);
  if (!planned.changed) {
    return planned.rows.map((row) => ({ ...row, result: "skipped" }));
  }
  if (deps.dryRun) {
    return planned.rows.map((row) =>
      row.action === "rewrite" ? { ...row, result: "would-upload" } : { ...row, result: "skipped" },
    );
  }
  try {
    const written = await deps.writeImages({
      id: planned.id,
      images: temple.images,
      next: planned.images,
    });
    if (!written || written.ok === false) {
      const reason = written?.reason || "write";
      const failed = reason !== "changed" && reason !== "missing" && reason !== "unchanged";
      return planned.rows.map((row) => rowResult(row, failed ? "failed" : "skipped", reason));
    }
    return planned.rows.map((row) => rowResult(row, "uploaded"));
  } catch (error) {
    const reason = failureText(error);
    return planned.rows.map((row) => rowResult(row, "failed", reason));
  }
}

export function formatCapReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  let rewrite = 0;
  let skip = 0;
  for (const row of rows) {
    if (row.result === "would-upload" || row.result === "uploaded") rewrite += 1;
    else skip += 1;
  }
  lines.push(`images: ${rows.length}  rewrite: ${rewrite}  skip: ${skip}`);
  for (const row of rows) {
    if (row.result === "would-upload" || row.result === "uploaded") {
      lines.push(`${row.result} ${row.id} ${row.index}`);
    } else if (row.result === "failed") {
      lines.push(`failed ${row.id ?? ""} ${row.reason ?? ""}`.trimEnd());
    } else if (row.reason) {
      lines.push(`skip ${row.id} ${row.reason}`);
    }
  }
  if (!apply) lines.push("Dry-run only. No Firestore writes.");
  else lines.push("Wrote images[] only. imageUrl, photos, and the index were not written.");
  return redactDownloadToken(lines.join("\n"));
}

async function initAdmin(project, env) {
  const admin = (await import("firebase-admin")).default;
  if (usesEmulator(env)) {
    process.env.FIRESTORE_EMULATOR_HOST = env.FIRESTORE_EMULATOR_HOST;
    if (admin.apps.length > 0) return admin;
    admin.initializeApp({ projectId: project });
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
  if (admin.apps.length > 0) return admin;
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
  });
  return admin;
}

async function loadTemples(project, env, limits) {
  const admin = await callBounded(() => initAdmin(project, env), {
    ...limits,
    label: "admin init",
  });
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const writeLog = deps.log ?? ((line) => console.log(line));
  const log = (line) => writeLog(redactDownloadToken(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  if (opts.apply) {
    assertNotCi(env);
    requireBackupDir(opts.backupDir);
    await authorizeApply(project, env, { confirm: deps.confirm });
    if (!deps.writeImages) mkdirSync(opts.backupDir, { recursive: true });
  }
  const limits = networkLimits({
    timeoutMs: opts.timeoutMs ?? deps.timeoutMs ?? DEFAULT_TIMEOUT_MS,
    attempts: deps.attempts,
    backoffMs: deps.backoffMs,
    sleep: deps.sleep,
  });
  const tracker =
    deps.tracker ?? (isDirect ? runTracker : { active: false, summarized: false, rows: [], started: 0 });
  beginRun(tracker);
  let rows = [];
  try {
    const load = deps.load ?? ((id, loadEnv) => loadTemples(id, loadEnv, limits));
    const temples = await callBounded(() => load(project, env), { ...limits, label: "firestore read" });
    temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
    const writeImages =
      deps.writeImages ??
      (async (assigned) => {
        const admin = await initAdmin(project, env);
        return persistCappedImages(admin.firestore(), assigned, (id, images) =>
          writeBackup(opts.backupDir, id, images),
        );
      });
    const boundedWrite = (assigned) =>
      callBounded(() => writeImages(assigned), { ...limits, label: "firestore write" });
    const batches = chunk(temples, deps.batchSize);
    for (let index = 0; index < batches.length; index += 1) {
      const batch = batches[index];
      for (const temple of batch) {
        const templeRows = await applyTemple(temple, {
          dryRun: !opts.apply,
          writeImages: boundedWrite,
        });
        rows.push(...templeRows);
      }
      logBatch(log, {
        batch: index + 1,
        batches: batches.length,
        temples: batch.length,
        rows,
        noun: "images",
      });
    }
    if (tracker) tracker.rows = rows;
    log(formatCapReport(rows, { apply: opts.apply }));
  } catch (error) {
    log(`failed ${failureText(error)}`);
    rows = [{ result: "failed", reason: failureText(error) }];
  }
  return finishRun({
    log,
    rows,
    elapsedMs: Date.now() - tracker.started,
    exit: deps.exit,
    tracker,
  });
}

const isDirect = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  process.on("beforeExit", () => {
    const reported = incompleteOnBeforeExit(runTracker, (line) => console.log(redactDownloadToken(line)));
    if (!reported) return;
    process.exit(1);
  });
  process.on("unhandledRejection", (reason) => {
    reportProcessFault("unhandledRejection", reason);
  });
  process.on("uncaughtException", (error) => {
    reportProcessFault("uncaughtException", error);
  });
  main()
    .catch((error) => {
      if (!error?.alreadyReported) console.error(redactThrown(error));
      process.exitCode = error?.exitCode || 1;
    })
    .finally(() => {
      process.exit(process.exitCode ?? 0);
    });
}
