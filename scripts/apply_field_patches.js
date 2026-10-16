/**
 * Patch specific Firestore fields from a JSON file.
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 *
 *   node apply_field_patches.js --patches <file>
 *   node apply_field_patches.js --project <id> --patches <file>
 *   node apply_field_patches.js --apply --project <id> --patches <file>
 *   node apply_field_patches.js --apply --strict --project <id> --patches <file>
 *
 * Dry-run is the default and does not write. With no --project it does not
 * connect: it prints one line per document, then a before/after line per
 * field with the before side unread. With --project and without --apply it
 * reads each live document and prints that current value, then the patched
 * value. It still does not write, and it does not ask for the project id.
 * An entry note is printed in both modes and is never a Firestore field.
 * --apply reads each target document first. A gallery write runs only when
 * live imageUrl, images, and photos still match that audited state. A
 * mismatch is skipped and reported. --strict aborts the whole run before
 * any write. All targets are read inside one transaction before any update,
 * so --strict aborts before a write when a later document does not match.
 * It refuses CI and requires a confirm prompt plus an explicit --project.
 * It does not upload Storage objects and it does not run Seed.
 */
import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { redactThrown } from "./redact_url.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

const ALLOWED_FIELDS = new Set([
  "imageUrl",
  "images",
  "photos",
  "timings",
  "deity",
  "tradition",
]);

/** Same cap as firestore.rules validStringLength('deity', 1, 100). */
const DEITY_MAX = 100;

const TRADITION_VALUES = new Set(["jain", "buddhist", "sikh"]);

/** Patch value that --apply turns into FieldValue.delete(). */
export const FIELD_DELETE = Object.freeze({ op: "delete" });

const GALLERY_FIELDS = ["imageUrl", "images", "photos"];

function printUsage() {
  console.log(`
Usage:
  node apply_field_patches.js --patches <file>
  node apply_field_patches.js --project <id> --patches <file>
  node apply_field_patches.js --apply --project <id> --patches <file>
  node apply_field_patches.js --apply --strict --project <id> --patches <file>

Each temple entry is { "id", "fields": { ... }, "expect": { ... }, "note": "..." }.
Only imageUrl, images, photos, timings, deity, and tradition are accepted.
deity is a non-empty string of at most ${DEITY_MAX} characters. tradition is
jain, buddhist, or sikh, or null to unset it. note is printed and is not
written. A gallery write requires expect: the audited imageUrl, images,
and photos. --apply writes that document only when the live gallery still
matches. --strict aborts before any write when one document does not match.
Dry-run with --project reads live values and prints before -> after. It does
not write.
`);
}

function parseArgs(argv) {
  const opts = {
    patches: null,
    apply: false,
    strict: false,
    project: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.apply = false;
    else if (arg === "--apply") opts.apply = true;
    else if (arg === "--strict") opts.strict = true;
    else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--patches") opts.patches = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return opts;
}

function writesGallery(fields) {
  return GALLERY_FIELDS.some((key) =>
    Object.prototype.hasOwnProperty.call(fields, key),
  );
}

/** Drop utm_* query parameters so a seeded audit URL matches the stripped form. */
export function stripUtm(url) {
  const trimmed = String(url ?? "").trim();
  const queryAt = trimmed.indexOf("?");
  if (queryAt < 0) return trimmed;
  const base = trimmed.slice(0, queryAt);
  const params = trimmed
    .slice(queryAt + 1)
    .split("&")
    .filter((part) => part !== "" && !part.toLowerCase().startsWith("utm_"));
  return params.length === 0 ? base : `${base}?${params.join("&")}`;
}

function asUrlList(value) {
  if (!Array.isArray(value)) return [];
  return value.map((item) => (typeof item === "string" ? item.trim() : ""));
}

function emptyPhoto() {
  return { url: "", credit: "", licence: "", order: null };
}

/** photos[] entries are {url, credit, licence, order} objects, or a bare URL string. */
function asPhotos(value) {
  if (!Array.isArray(value)) return [];
  return value.map((item) => {
    if (typeof item === "string") {
      return { url: item.trim(), credit: "", licence: "", order: null };
    }
    if (!item || typeof item !== "object" || Array.isArray(item)) {
      return emptyPhoto();
    }
    return {
      url: typeof item.url === "string" ? item.url.trim() : "",
      credit: typeof item.credit === "string" ? item.credit.trim() : "",
      licence: typeof item.licence === "string" ? item.licence.trim() : "",
      order: Number.isInteger(item.order) ? item.order : null,
    };
  });
}

function readDeity(id, value) {
  if (typeof value !== "string") {
    throw new Error(`${id} deity must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed === "") {
    throw new Error(`${id} deity must be non-empty.`);
  }
  if (trimmed.length > DEITY_MAX) {
    throw new Error(`${id} deity must be at most ${DEITY_MAX} characters.`);
  }
  return trimmed;
}

function readNote(id, entry) {
  if (!Object.prototype.hasOwnProperty.call(entry, "note")) return "";
  if (typeof entry.note !== "string") {
    throw new Error(`${id} note must be a string.`);
  }
  return entry.note;
}

function readTradition(id, value) {
  if (value === null) return FIELD_DELETE;
  if (typeof value !== "string" || !TRADITION_VALUES.has(value)) {
    throw new Error(
      `${id} tradition must be jain, buddhist, or sikh, or null to unset it.`,
    );
  }
  return value;
}

function readFields(id, raw) {
  const fields = {};
  for (const key of Object.keys(raw)) {
    if (key === "deity") fields.deity = readDeity(id, raw.deity);
    else if (key === "tradition") fields.tradition = readTradition(id, raw.tradition);
    else fields[key] = raw[key];
  }
  return fields;
}

export function patchWritePayload(fields, deleteValue = FIELD_DELETE) {
  const payload = {};
  for (const [key, value] of Object.entries(fields)) {
    payload[key] = value === FIELD_DELETE ? deleteValue : value;
  }
  return payload;
}

function readExpect(raw, id) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error(
      `${id} writes a gallery and needs expect.imageUrl, expect.images, and expect.photos.`,
    );
  }
  if (typeof raw.imageUrl !== "string") {
    throw new Error(`${id} expect.imageUrl must be a string.`);
  }
  if (!Array.isArray(raw.images) || raw.images.some((item) => typeof item !== "string")) {
    throw new Error(`${id} expect.images must be a list of strings.`);
  }
  if (!Array.isArray(raw.photos)) {
    throw new Error(`${id} expect.photos must be a list.`);
  }
  return {
    imageUrl: raw.imageUrl,
    images: raw.images,
    photos: raw.photos,
  };
}

/**
 * True when the live document still has the audited gallery.
 * Missing imageUrl, images, and photos count as empty.
 * utm_* query parameters are ignored.
 */
export function galleryMatches(live, expected) {
  const current = live && typeof live === "object" ? live : {};
  const liveUrl = stripUtm(
    typeof current.imageUrl === "string" ? current.imageUrl : "",
  );
  if (liveUrl !== stripUtm(expected.imageUrl)) return false;
  const liveImages = asUrlList(current.images).map(stripUtm);
  const expectedImages = asUrlList(expected.images).map(stripUtm);
  if (liveImages.length !== expectedImages.length) return false;
  for (let i = 0; i < liveImages.length; i += 1) {
    if (liveImages[i] !== expectedImages[i]) return false;
  }
  const livePhotos = asPhotos(current.photos);
  const expectedPhotos = asPhotos(expected.photos);
  if (livePhotos.length !== expectedPhotos.length) return false;
  for (let i = 0; i < livePhotos.length; i += 1) {
    const left = livePhotos[i];
    const right = expectedPhotos[i];
    if (stripUtm(left.url) !== stripUtm(right.url)) return false;
    if (left.credit !== right.credit) return false;
    if (left.licence !== right.licence) return false;
    if (left.order !== right.order) return false;
  }
  return true;
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
    const id = entry.id.trim();
    if (!entry.fields || typeof entry.fields !== "object" || Array.isArray(entry.fields)) {
      throw new Error(`${id} is missing fields.`);
    }
    const keys = Object.keys(entry.fields);
    if (keys.length === 0) throw new Error(`${id} has no fields.`);
    for (const key of keys) {
      if (!ALLOWED_FIELDS.has(key)) {
        throw new Error(`${id} field "${key}" is not allowed.`);
      }
    }
    const fields = readFields(id, entry.fields);
    const gallery = writesGallery(fields);
    return {
      id,
      fields,
      note: readNote(id, entry),
      expect: gallery ? readExpect(entry.expect, id) : null,
    };
  });
  const ids = temples.map((temple) => temple.id);
  if (new Set(ids).size !== ids.length) throw new Error("Duplicate temple id in patch file.");
  return { description: parsed.description || "", temples };
}

function auditedLabel(expected) {
  const images = expected.images.length;
  const photos = expected.photos.length;
  const cover = stripUtm(expected.imageUrl);
  if (images === 0 && photos === 0 && cover === "") {
    return "audited empty imageUrl, images, and photos";
  }
  const photoLabel = photos === 0 ? "empty photos" : `${photos} photos`;
  return `audited ${images} image${images === 1 ? "" : "s"} and ${photoLabel}`;
}

export function formatDryRunLine(temple) {
  const keys = Object.keys(temple.fields).join(", ");
  if (!temple.expect) {
    const scope = keys === "timings"
      ? "timings only; gallery is not written"
      : "gallery is not written";
    return `  temples/${temple.id}  ${scope}  fields: ${keys}`;
  }
  return (
    `  temples/${temple.id}  would apply if live gallery matches ` +
    `${auditedLabel(temple.expect)}  fields: ${keys}`
  );
}

function formatFieldValue(value) {
  if (value === FIELD_DELETE) return "(unset)";
  return JSON.stringify(value);
}

function fieldBefore(live, key) {
  if (!live || typeof live !== "object") return "(missing)";
  if (!Object.prototype.hasOwnProperty.call(live, key)) return "(missing)";
  return formatFieldValue(live[key]);
}

/** One line per patched field: current JSON value, then the value to write. */
export function formatLiveDiff(temple, live) {
  const lines = [`  temples/${temple.id}`];
  if (temple.note) lines.push(`    note: ${temple.note}`);
  for (const key of Object.keys(temple.fields)) {
    lines.push(
      `    ${key}: ${fieldBefore(live, key)} -> ${formatFieldValue(temple.fields[key])}`,
    );
  }
  return lines.join("\n");
}

/** Same shape when the dry-run has not read Firestore. */
export function formatOfflineDiff(temple) {
  const lines = [];
  if (temple.note) lines.push(`    note: ${temple.note}`);
  for (const key of Object.keys(temple.fields)) {
    lines.push(
      `    ${key}: (live not read) -> ${formatFieldValue(temple.fields[key])}`,
    );
  }
  return lines.join("\n");
}

function printPlan(patch) {
  console.log("Mode: dry-run");
  if (patch.description) console.log(patch.description);
  console.log(`Temples: ${patch.temples.length}`);
  for (const temple of patch.temples) {
    console.log(formatDryRunLine(temple));
    const diff = formatOfflineDiff(temple);
    if (diff) console.log(diff);
  }
  console.log("\nNo Firestore connection. No writes.");
}

/**
 * Read each target and print before -> after. Does not update.
 */
export async function previewPatchSet(db, patch) {
  await db.runTransaction(async (tx) => {
    for (const temple of patch.temples) {
      const ref = db.collection("temples").doc(temple.id);
      const snap = await tx.get(ref);
      if (!snap.exists) {
        console.log(`  temples/${temple.id}  missing`);
        if (temple.note) console.log(`    note: ${temple.note}`);
        continue;
      }
      console.log(formatLiveDiff(temple, snap.data() || {}));
    }
  });
  console.log("\nNo writes.");
}

/**
 * Read every target, then write only the matches, inside one transaction.
 *
 * A missing document aborts before any update. --strict does the same when
 * any live gallery differs from the audit, including a later document, so
 * no earlier document is written. Otherwise mismatches are skipped and the
 * matches are updated in that same transaction.
 */
export async function applyPatchSet(db, patch, { strict, deleteValue = FIELD_DELETE }) {
  await db.runTransaction(async (tx) => {
    const planned = [];
    for (const temple of patch.temples) {
      const ref = db.collection("temples").doc(temple.id);
      const snap = await tx.get(ref);
      if (!snap.exists) {
        planned.push({ temple, ref, action: "missing" });
        continue;
      }
      const data = snap.data() || {};
      if (temple.expect && !galleryMatches(data, temple.expect)) {
        planned.push({ temple, ref, action: "skip" });
        continue;
      }
      planned.push({ temple, ref, action: "write" });
    }

    const missing = planned.filter((row) => row.action === "missing").map((row) => row.temple.id);
    if (missing.length > 0) {
      throw new Error(
        `Refusing to write. These documents do not exist: ${missing.join(", ")}. No write.`,
      );
    }
    const skipped = planned.filter((row) => row.action === "skip").map((row) => row.temple.id);
    if (strict && skipped.length > 0) {
      throw new Error(
        `Refusing to write. Live gallery does not match the audited state: ${skipped.join(", ")}. No write.`,
      );
    }

    for (const row of planned) {
      if (row.action === "skip") {
        console.log(
          `skipped temples/${row.temple.id}  live gallery does not match the audited state`,
        );
        continue;
      }
      if (row.temple.note) {
        console.log(`note temples/${row.temple.id}  ${row.temple.note}`);
      }
      tx.update(row.ref, patchWritePayload(row.temple.fields, deleteValue));
      console.log(
        `updated temples/${row.temple.id} (${Object.keys(row.temple.fields).join(", ")})`,
      );
    }
  });
}

async function openFirestore(project) {
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
  return admin.firestore();
}

async function applyPatches(project, patch, { strict }) {
  const admin = (await import("firebase-admin")).default;
  const db = await openFirestore(project);
  await applyPatchSet(db, patch, {
    strict,
    deleteValue: admin.firestore.FieldValue.delete(),
  });
}

async function previewPatches(project, patch) {
  const db = await openFirestore(project);
  console.log(`Live read project ${project}. No writes.`);
  await previewPatchSet(db, patch);
}

async function main(argv = process.argv.slice(2)) {
  const opts = parseArgs(argv);
  if (opts.help || !opts.patches) {
    printUsage();
    process.exit(opts.help ? 0 : 1);
  }
  const patch = loadPatches(resolve(opts.patches));
  if (!opts.apply) {
    if (opts.project) {
      assertNotCi();
      const project = assertExplicitProject(opts.project);
      console.log("Mode: dry-run");
      if (patch.description) console.log(patch.description);
      console.log(`Temples: ${patch.temples.length}`);
      await previewPatches(project, patch);
      return patch;
    }
    printPlan(patch);
    return patch;
  }
  const project = await confirmProject(opts.project);
  console.log(`Mode: apply project ${project}${opts.strict ? " strict" : ""}`);
  await applyPatches(project, patch, { strict: opts.strict });
  return patch;
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactThrown(error));
    process.exit(1);
  });
}

export { main, parseArgs };
