/**
 * Remove uncredited Google Places mirrors from temple documents and Storage.
 *
 * Dry-run is the default. It reads temple documents and prints which covers
 * would become Photo pending. It does not write.
 *
 *   node scripts/purge_places_photos.js --project temple-directory-india
 *
 * A Places mirror is `temples/{id}/image_<n>.jpg` (jpeg, png, or webp), in
 * the public Storage URL or the Firebase download-token URL. Resized
 * siblings (`image_<n>_480_g<generation>.jpg`) are included. A photo or
 * images object with a real credit is kept. imageUrl, images, and photos
 * lose the uncredited mirrors. No new top-level field is added. An empty
 * gallery is the Photo pending state the app already shows.
 *
 * Apply re-reads each temple in its own transaction and skips it when the
 * planned imageUrl, images, or photos changed. The index entry is rewritten
 * from that fresh document. Each object is copied to
 * `backup/places-purge-<timestamp>/…` in the same bucket before it is
 * deleted. `--backup-dir <folder>` also writes that copy locally.
 * `--no-delete` does the Firestore switch and the backup, and does not
 * delete. If a backup fails, nothing is deleted. A later run lists
 * Places-pattern objects that nothing references and that are not under
 * `backup/`, and finishes those leftovers. One delete failure does not
 * skip the rest.
 *
 *   node scripts/purge_places_photos.js --apply --project temple-directory-india
 *   node scripts/purge_places_photos.js --no-delete --project temple-directory-india
 *
 * `--exclude id1,id2` skips those ids and warns when an id is not in the
 * read. `--only id1,id2` limits the purge to those ids and warns the same way.
 * prod --apply is run only by the Deployer agent or Sanu, after Architect
 * signs off on the dry-run, never from CI.
 *
 * After the 21-cover apply, Photo pending is expected for temples that still
 * have only an uncredited Places gallery: Anjengo, Meenakshi, Shore, and
 * Mannarsala, plus any that were not replaced, such as Dharmasthala,
 * Nanjangud, Chamundeshwari, Gokarna, and Sabarimala. The dry-run prints
 * the ids it actually found.
 */
import { existsSync, readFileSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  isDirectoryBucket,
  isPlacesMirrorUrl,
  isPlacesObjectPath,
  photoHasCredit,
  placesObjectFromUrl,
} from "./places_mirror.js";
import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { hasVerifiedGallery } from "./state_batch.js";
import { assertStorageAuth, STORAGE_AUTH_BUCKET, useNativeFetchForStorageAuth } from "./storage_auth.js";
import { entryFromTemple, stateSlug, storageObjectFromUrl } from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function redactDownloadToken(value) {
  return String(value ?? "").replace(/([?&]token=)[^&#\s'"]*/g, "$1<redacted>");
}

function printUsage() {
  console.log(`
Usage:
  node purge_places_photos.js [--dry-run] [--exclude id1,id2] [--only id1,id2] [--project <id>]
  node purge_places_photos.js --apply [--backup-dir <folder>] --project <firebase-project-id>
  node purge_places_photos.js --no-delete [--backup-dir <folder>] --project <firebase-project-id>

Default is dry-run. Uncredited Places mirrors (temples/{id}/image_N.jpg and
their _480 thumbs, public URL or download-token URL) are removed from
imageUrl, images, and photos. Only the temple-directory-india bucket matches.
A credited photo stays and becomes the cover when the old cover is removed.
Empty galleries are Photo pending. Nothing is written.
--apply copies each object to backup/places-purge-<timestamp>/ in the same
bucket, then deletes it. A failed backup deletes nothing.
--no-delete writes Firestore and the backup, and does not delete.
--backup-dir also saves that copy under the local folder.
--exclude and --only take comma-separated temple ids. Unknown ids are warned.
prod --apply is run only by the Deployer agent or Sanu, after Architect
signs off, dry run first, never from CI. Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.
`);
}

function readIdList(argv, index, flag) {
  const arg = argv[index];
  const raw = arg === flag ? argv[index + 1] : arg.slice(`${flag}=`.length);
  if (typeof raw !== "string" || raw.trim() === "" || raw.startsWith("--")) {
    throw new Error(`${flag} needs a comma-separated list of temple ids`);
  }
  const ids = new Set();
  for (const id of raw.split(",")) {
    const trimmed = id.trim();
    if (trimmed) ids.add(trimmed);
  }
  if (ids.size === 0) throw new Error(`${flag} needs a comma-separated list of temple ids`);
  return { ids, consumed: arg === flag ? 1 : 0 };
}

export function parseArgs(argv) {
  const opts = {
    dryRun: true,
    apply: false,
    exclude: new Set(),
    only: new Set(),
    project: null,
    help: false,
    noDelete: false,
    backupDir: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--apply") {
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--no-delete") {
      opts.noDelete = true;
      opts.apply = true;
      opts.dryRun = false;
    } else if (arg === "--backup-dir" || arg.startsWith("--backup-dir=")) {
      const raw = arg === "--backup-dir" ? argv[++i] : arg.slice("--backup-dir=".length);
      if (typeof raw !== "string" || raw.trim() === "" || raw.startsWith("--")) {
        throw new Error("--backup-dir needs a local folder");
      }
      opts.backupDir = raw.trim();
    } else if (arg === "--exclude" || arg.startsWith("--exclude=")) {
      const parsed = readIdList(argv, i, "--exclude");
      for (const id of parsed.ids) opts.exclude.add(id);
      i += parsed.consumed;
    } else if (arg === "--only" || arg.startsWith("--only=")) {
      const parsed = readIdList(argv, i, "--only");
      for (const id of parsed.ids) opts.only.add(id);
      i += parsed.consumed;
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

function placesStem(objectPath) {
  const file = String(objectPath ?? "").split("/").pop() ?? "";
  const match = /^(image_\d+)/i.exec(file);
  return match ? match[1].toLowerCase() : "";
}

function samePlacesObject(left, right) {
  if (!left || !right) return false;
  return left.split("/")[1] === right.split("/")[1] && placesStem(left) === placesStem(right) && placesStem(left) !== "";
}

function creditedPlacesPaths(temple) {
  const paths = new Set();
  const consider = [];
  if (Array.isArray(temple?.photos)) consider.push(...temple.photos);
  if (Array.isArray(temple?.images)) consider.push(...temple.images);
  for (const item of consider) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    if (!photoHasCredit(item)) continue;
    const located = placesObjectFromUrl(item.url);
    if (located) paths.add(located.objectPath);
  }
  return paths;
}

function urlText(value) {
  return typeof value === "string" ? value.trim() : "";
}

export function referencedObjectPaths(temples) {
  const paths = new Set();
  for (const temple of temples ?? []) {
    const urls = [];
    const imageUrl = urlText(temple?.imageUrl);
    if (imageUrl) urls.push(imageUrl);
    if (Array.isArray(temple?.images)) {
      for (const item of temple.images) {
        if (typeof item === "string" && item.trim()) urls.push(item.trim());
        else if (item && typeof item === "object" && urlText(item.url)) urls.push(item.url.trim());
      }
    }
    if (Array.isArray(temple?.photos)) {
      for (const photo of temple.photos) {
        if (!photo || typeof photo !== "object") continue;
        if (urlText(photo.url)) urls.push(photo.url.trim());
        if (urlText(photo.thumbUrl)) urls.push(photo.thumbUrl.trim());
      }
    }
    for (const url of urls) {
      const located = storageObjectFromUrl(url);
      if (located?.objectPath && isDirectoryBucket(located.bucket)) paths.add(located.objectPath);
    }
  }
  return paths;
}

/**
 * Fields to clear on one temple. `ready` means no uncredited Places mirror.
 */
export function planPurgePlaces(temple) {
  const id = String(temple?.id ?? "");
  const credits = creditedPlacesPaths(temple);
  const objectPaths = new Set();
  const patch = {};
  const changes = [];
  const uncredited = (url) => {
    const located = placesObjectFromUrl(url);
    if (!located) return null;
    if (credits.has(located.objectPath)) return null;
    return located.objectPath;
  };

  const imageUrl = urlText(temple?.imageUrl);
  const clearedImage = imageUrl ? uncredited(imageUrl) : null;
  if (clearedImage) {
    objectPaths.add(clearedImage);
    patch.imageUrl = "";
    changes.push(`imageUrl cleared ${imageUrl}`);
  }

  if (Array.isArray(temple?.images)) {
    let removed = 0;
    const next = [];
    for (const item of temple.images) {
      const url = typeof item === "string" ? item : item?.url;
      const path = uncredited(url);
      if (path) {
        objectPaths.add(path);
        removed += 1;
        continue;
      }
      next.push(item);
    }
    if (removed > 0) {
      patch.images = next;
      changes.push(`images remove ${removed}`);
    }
  }

  if (Array.isArray(temple?.photos)) {
    let removed = 0;
    let thumbs = 0;
    const next = [];
    for (const photo of temple.photos) {
      if (!photo || typeof photo !== "object" || Array.isArray(photo)) {
        next.push(photo);
        continue;
      }
      const path = uncredited(photo.url);
      if (path) {
        objectPaths.add(path);
        const thumb = placesObjectFromUrl(photo.thumbUrl);
        if (thumb) objectPaths.add(thumb.objectPath);
        removed += 1;
        continue;
      }
      const thumb = placesObjectFromUrl(photo.thumbUrl);
      const source = placesObjectFromUrl(photo.url);
      const keepThumb =
        thumb &&
        source &&
        credits.has(source.objectPath) &&
        samePlacesObject(source.objectPath, thumb.objectPath);
      if (thumb && !keepThumb) {
        objectPaths.add(thumb.objectPath);
        const copy = { ...photo };
        delete copy.thumbUrl;
        next.push(copy);
        thumbs += 1;
        continue;
      }
      next.push(photo);
    }
    if (removed > 0 || thumbs > 0) patch.photos = next;
    if (removed > 0) changes.push(`photos remove ${removed}`);
    if (thumbs > 0) changes.push(`thumbUrl cleared on ${thumbs} photo${thumbs === 1 ? "" : "s"}`);
  }

  if (clearedImage && !Object.prototype.hasOwnProperty.call(patch, "images")) {
    const images = Array.isArray(temple?.images) ? temple.images : [];
    const still = images.some((item) => {
      const url = typeof item === "string" ? item.trim() : urlText(item?.url);
      return url && url === imageUrl;
    });
    if (still) {
      patch.images = images.filter((item) => {
        const url = typeof item === "string" ? item.trim() : urlText(item?.url);
        return url !== imageUrl;
      });
    }
  }

  if (changes.length === 0) return { id, action: "ready" };
  promoteCreditedCover(temple, patch);
  const nextTemple = { ...temple, id, ...patch };
  return {
    id,
    action: "purge",
    patch,
    changes,
    objectPaths: [...objectPaths].sort(),
    photoPending: !hasVerifiedGallery(nextTemple),
    before: {
      imageUrl: temple?.imageUrl ?? null,
      images: temple?.images ?? null,
      photos: temple?.photos ?? null,
    },
    plannedState: typeof temple?.state === "string" ? temple.state : "",
    temple: nextTemple,
  };
}

function photoOrder(photo, index) {
  const order = photo?.order;
  return typeof order === "number" && Number.isFinite(order) ? order : index;
}

function itemUrl(item) {
  if (typeof item === "string") return item.trim();
  return urlText(item?.url);
}

/**
 * When a mixed gallery loses its uncredited Places cover, the first credited
 * photo becomes imageUrl and photos[0]. Galleries with nothing credited left
 * stay empty. A non-Places image that remains is kept.
 */
function promoteCreditedCover(temple, patch) {
  const photos = Object.prototype.hasOwnProperty.call(patch, "photos")
    ? patch.photos
    : Array.isArray(temple?.photos)
      ? temple.photos.map((photo) => (photo && typeof photo === "object" ? { ...photo } : photo))
      : [];
  const images = Object.prototype.hasOwnProperty.call(patch, "images")
    ? patch.images
    : Array.isArray(temple?.images)
      ? [...temple.images]
      : [];
  const credited = [];
  if (Array.isArray(photos)) {
    photos.forEach((photo, index) => {
      if (!photo || typeof photo !== "object" || Array.isArray(photo)) return;
      if (!photoHasCredit(photo) || !itemUrl(photo)) return;
      credited.push({ photo, index, order: photoOrder(photo, index), url: itemUrl(photo) });
    });
  }
  if (Array.isArray(images)) {
    images.forEach((item, index) => {
      if (!item || typeof item !== "object" || Array.isArray(item)) return;
      if (!photoHasCredit(item) || !itemUrl(item)) return;
      const url = itemUrl(item);
      if (credited.some((entry) => entry.url === url)) return;
      credited.push({
        photo: { url, credit: item.credit, licence: item.licence, order: photoOrder(item, index) },
        index,
        order: photoOrder(item, index),
        url,
        fromImages: true,
      });
    });
  }
  if (credited.length === 0) return;
  credited.sort((a, b) => a.order - b.order || a.index - b.index);
  const cover = credited[0];
  const currentCover = Object.prototype.hasOwnProperty.call(patch, "imageUrl")
    ? urlText(patch.imageUrl)
    : urlText(temple?.imageUrl);
  const replaceCover =
    currentCover === "" || (currentCover !== "" && placesObjectFromUrl(currentCover) !== null);
  if (replaceCover) {
    patch.imageUrl = cover.url;
  }
  if (Array.isArray(photos)) {
    const rest = [];
    const seen = new Set([cover.url]);
    for (const photo of photos) {
      if (!photo || typeof photo !== "object" || Array.isArray(photo)) {
        rest.push(photo);
        continue;
      }
      if (itemUrl(photo) === cover.url) continue;
      rest.push(photo);
    }
    if (cover.fromImages && !photos.some((photo) => itemUrl(photo) === cover.url)) {
      rest.unshift({ url: cover.url, credit: cover.photo.credit, licence: cover.photo.licence });
    }
    const ordered = [
      photos.find((photo) => itemUrl(photo) === cover.url) ?? {
        url: cover.url,
        credit: cover.photo.credit,
        licence: cover.photo.licence,
      },
      ...rest.filter((photo) => !photo || typeof photo !== "object" || !seen.has(itemUrl(photo))),
    ];
    const next = ordered.map((photo, index) =>
      photo && typeof photo === "object" && !Array.isArray(photo) ? { ...photo, order: index } : photo,
    );
    if (JSON.stringify(next) !== JSON.stringify(temple?.photos ?? null)) patch.photos = next;
  }
  if (Array.isArray(images)) {
    const without = images.filter((item) => itemUrl(item) !== cover.url);
    const coverItem =
      images.find((item) => itemUrl(item) === cover.url) ?? cover.url;
    const nextImages = [coverItem, ...without];
    if (JSON.stringify(nextImages) !== JSON.stringify(temple?.images ?? null)) patch.images = nextImages;
  }
}

export function selectTemples(temples, { exclude = new Set(), only = new Set() } = {}) {
  return (temples ?? []).filter((temple) => {
    const id = String(temple?.id ?? "");
    if (only.size > 0 && !only.has(id)) return false;
    if (exclude.has(id)) return false;
    return true;
  });
}

export function planPurgePlacesPhotos(temples) {
  return (temples ?? []).map((temple) => planPurgePlaces(temple));
}

export function commitPurgePlaces(fresh, plan) {
  const again = planPurgePlaces({ ...fresh, id: fresh?.id ?? plan.id });
  if (again.action !== "purge") return { ok: false, reason: "already" };
  if (JSON.stringify(again.before) !== JSON.stringify(plan.before)) {
    return { ok: false, reason: "changed" };
  }
  if (JSON.stringify(again.patch) !== JSON.stringify(plan.patch)) {
    return { ok: false, reason: "changed" };
  }
  const id = String(fresh?.id ?? plan.id);
  return {
    ok: true,
    patch: again.patch,
    temple: { ...fresh, id, ...again.patch },
  };
}

export function templesAfterPurge(temples, rows) {
  const byId = new Map((temples ?? []).map((temple) => [String(temple?.id ?? ""), temple]));
  for (const row of rows ?? []) {
    if (row.result !== "would-purge" && row.result !== "purged") continue;
    const current = byId.get(row.id) ?? { id: row.id };
    byId.set(row.id, { ...current, ...row.patch });
  }
  return [...byId.values()];
}

export function placesBackupStamp(date = new Date()) {
  return date.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}

export function backupObjectPath(objectPath, stamp) {
  return `backup/places-purge-${stamp}/${objectPath}`;
}

/** Storage object paths named by any string in [value]. Other buckets are ignored. */
export function collectReferencedObjectPaths(value, paths = new Set()) {
  if (typeof value === "string") {
    const located = storageObjectFromUrl(value);
    if (located?.objectPath && isDirectoryBucket(located.bucket)) paths.add(located.objectPath);
    return paths;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectReferencedObjectPaths(item, paths);
    return paths;
  }
  if (value && typeof value === "object") {
    for (const item of Object.values(value)) collectReferencedObjectPaths(item, paths);
  }
  return paths;
}

/** Storage object paths named by URLs in a source file, such as sample_data.dart. */
export function referencedPathsInText(text, paths = new Set()) {
  const matches = String(text ?? "").match(/https?:\/\/[^\s'")\]]+|gs:\/\/[^\s'")\]]+/g) ?? [];
  for (const raw of matches) collectReferencedObjectPaths(raw.replace(/[),.;]+$/, ""), paths);
  return paths;
}

function failureMessage(error) {
  return error?.message || String(error);
}

/**
 * Objects to delete. [templesAfter] is the gallery after the Firestore write
 * (or the dry-run equivalent). A path any temple still names is kept.
 * [listPrefix] adds resized siblings that the documents did not name.
 * [includeLeftovers] also takes Places-pattern objects under `temples/` that
 * nothing references and that are not under `backup/`.
 * Apply copies each object to `backup/places-purge-<timestamp>/` first.
 * A backup failure deletes nothing. Each delete is checked again and a
 * single failure does not skip the rest.
 */
export async function placesDeletePlan(rows, templesAfter, deps = {}) {
  const remove = new Set();
  const prefixes = new Set();
  for (const row of rows ?? []) {
    if (row.result !== "would-purge" && row.result !== "purged") continue;
    for (const path of row.objectPaths ?? []) {
      if (!isPlacesObjectPath(path) || String(path).startsWith("backup/")) continue;
      remove.add(path);
      const id = path.split("/")[1];
      if (id) prefixes.add(`temples/${id}/`);
    }
  }
  if (typeof deps.listPrefix === "function") {
    const prefixesToList = [...prefixes].sort();
    if (deps.includeLeftovers) prefixesToList.push("temples/");
    for (const prefix of prefixesToList) {
      const names = await deps.listPrefix(prefix);
      for (const name of names ?? []) {
        if (String(name).startsWith("backup/")) continue;
        if (isPlacesObjectPath(name)) remove.add(name);
      }
    }
  }
  const referenced = referencedObjectPaths(templesAfter);
  const planned = [];
  const kept = [];
  for (const path of [...remove].sort()) {
    if (referenced.has(path)) kept.push(path);
    else planned.push(path);
  }
  const stamp = deps.backupStamp ?? placesBackupStamp(deps.now?.() ?? new Date());
  const backedUp = [];
  const failures = [];
  const shouldBackup = Boolean(deps.performBackup || deps.performDelete);
  if (!shouldBackup) {
    return { deleted: planned, kept, failures, backedUp, backupStamp: stamp };
  }
  if (typeof deps.copyObject !== "function") {
    for (const path of planned) {
      failures.push({ path, phase: "backup", message: "backup copy is not configured" });
    }
    return { deleted: [], kept, failures, backedUp, backupStamp: stamp };
  }
  if (deps.backupDir && typeof deps.downloadObject !== "function") {
    for (const path of planned) {
      failures.push({ path, phase: "backup", message: "local backup is not configured" });
    }
    return { deleted: [], kept, failures, backedUp, backupStamp: stamp };
  }
  for (const path of planned) {
    const dest = backupObjectPath(path, stamp);
    try {
      await deps.copyObject(path, dest);
      if (deps.backupDir) {
        const local = join(deps.backupDir, `places-purge-${stamp}`, path);
        await deps.downloadObject(path, local);
      }
      backedUp.push(path);
    } catch (error) {
      failures.push({ path, phase: "backup", message: failureMessage(error) });
    }
  }
  if (deps.noDelete || !deps.performDelete || failures.length > 0) {
    return { deleted: [], kept, failures, backedUp, backupStamp: stamp };
  }
  const deleted = [];
  for (const path of planned) {
    try {
      if (typeof deps.referencesObject === "function" && (await deps.referencesObject(path))) {
        kept.push(path);
        continue;
      }
    } catch (error) {
      failures.push({ path, phase: "reference", message: failureMessage(error) });
      continue;
    }
    try {
      if (typeof deps.deleteObject === "function") await deps.deleteObject(path);
      deleted.push(path);
    } catch (error) {
      failures.push({ path, phase: "delete", message: failureMessage(error) });
    }
  }
  return { deleted, kept, failures, backedUp, backupStamp: stamp };
}

export function formatPurgeReport(
  rows,
  objects = { deleted: [], kept: [] },
  { apply = false, noDelete = false } = {},
) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const purges = (rows ?? []).filter((row) => row.result === "would-purge" || row.result === "purged");
  const pending = purges.filter((row) => row.photoPending);
  const skipped = (rows ?? []).filter((row) => row.result === "skipped");
  lines.push(`places temples: ${purges.length}`);
  lines.push(`photo pending: ${pending.length}`);
  lines.push(`objects: ${(objects.deleted ?? []).length}`);
  lines.push(`kept objects: ${(objects.kept ?? []).length}`);
  for (const row of purges) {
    lines.push(`${row.result} ${row.id}`);
    for (const change of row.changes ?? []) lines.push(`  ${change}`);
    lines.push(`  objects: ${(row.objectPaths ?? []).length}`);
    if (row.photoPending) lines.push("  photo pending");
  }
  if (skipped.length > 0) {
    lines.push(`skipped: ${skipped.length}`);
    for (const row of skipped) lines.push(`skip ${row.id} ${row.reason}`);
  }
  lines.push("Photo pending:");
  for (const row of pending) lines.push(`  ${row.id}`);
  const failures = objects.failures ?? [];
  if (failures.length > 0) {
    lines.push(`failures: ${failures.length}`);
    for (const failure of failures) {
      lines.push(`  ${failure.phase} ${failure.path} ${failure.message}`);
    }
  }
  if ((objects.backedUp ?? []).length > 0) {
    lines.push(`backed up: ${objects.backedUp.length}`);
  }
  if (!apply) lines.push("Dry-run only. No Firestore writes. No Storage deletes.");
  else if (noDelete) {
    lines.push(
      "Firestore fields were written and objects were copied to backup/. Nothing was deleted. Rules were not deployed.",
    );
  } else if (failures.some((failure) => failure.phase === "backup")) {
    lines.push("Backup failed. Nothing was deleted. Rules were not deployed.");
  } else {
    lines.push(
      "Firestore fields and that temple's index entry were written, then each object was copied to backup/ before delete. Rules were not deployed.",
    );
  }
  return redactDownloadToken(lines.join("\n"));
}

export async function persistPurgePlaces(db, plan, deps = {}) {
  const admin = deps.admin ?? (await import("firebase-admin")).default;
  const id = String(plan.id ?? "");
  if (!id) return { ok: false, reason: "missing" };
  const plannedState = plan.plannedState ?? plan.temple?.state;
  return db.runTransaction(async (tx) => {
    const templeRef = db.collection("temples").doc(id);
    const templeSnap = await tx.get(templeRef);
    if (!templeSnap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...templeSnap.data(), id: templeSnap.id };
    const committed = commitPurgePlaces(fresh, plan);
    if (!committed.ok) return committed;
    const shard = stateSlug(committed.temple.state);
    const previous =
      typeof plannedState === "string" && plannedState !== "" ? stateSlug(plannedState) : null;
    const indexRef = db.collection("temple_index").doc(shard);
    const metaRef = db.collection("meta").doc("temple_index");
    await tx.get(indexRef);
    const metaSnap = await tx.get(metaRef);
    const oldRef = previous && previous !== shard ? db.collection("temple_index").doc(previous) : null;
    const oldSnap = oldRef ? await tx.get(oldRef) : null;
    tx.update(templeRef, committed.patch);
    const entry = {
      ...entryFromTemple(committed.temple),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.set(
      indexRef,
      { entries: { [id]: entry } },
      { mergeFields: [new admin.firestore.FieldPath("entries", id)] },
    );
    if (oldRef && oldSnap?.exists) {
      tx.update(
        oldRef,
        new admin.firestore.FieldPath("entries", id),
        admin.firestore.FieldValue.delete(),
      );
    }
    const touched = oldRef && oldSnap?.exists ? [shard, previous] : [shard];
    if (!metaSnap.exists) {
      const stamps = {};
      for (const name of touched) stamps[name] = admin.firestore.FieldValue.serverTimestamp();
      tx.set(metaRef, { indexVersion: 1, shards: stamps }, { merge: true });
    } else {
      const patch = { indexVersion: admin.firestore.FieldValue.increment(1) };
      for (const name of touched) {
        patch[`shards.${name}`] = admin.firestore.FieldValue.serverTimestamp();
      }
      tx.update(metaRef, patch);
    }
    return { ...committed, shard, entry };
  });
}

export async function applyPurgePlans(plans, deps) {
  const rows = [];
  for (const plan of plans) {
    if (plan.action !== "purge") {
      rows.push(plan);
      continue;
    }
    if (deps.dryRun) {
      rows.push({ ...plan, result: "would-purge" });
      continue;
    }
    const written = await deps.write(plan);
    if (!written || written.ok === false) {
      rows.push({
        ...plan,
        action: "skip",
        result: "skipped",
        reason: written?.reason ?? "write",
        objectPaths: [],
      });
      continue;
    }
    rows.push({ ...plan, result: "purged" });
  }
  return rows;
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
  if (!saPath) throw new Error("service-account.json was not found. No write.");
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== project) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${project}. No write.`,
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: project,
    storageBucket: STORAGE_AUTH_BUCKET,
  });
  return admin;
}

async function loadTemples(project, env) {
  const admin = await openAdmin(project, env);
  const snap = await admin.firestore().collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

const sampleDataPath = resolve(__dirname, "../lib/data/sample_data.dart");

export function referenceSet({ temples = [], shards = [], sampleText = "" } = {}) {
  const paths = referencedObjectPaths(temples);
  for (const shard of shards) collectReferencedObjectPaths(shard, paths);
  referencedPathsInText(sampleText, paths);
  return paths;
}

async function referencedPathsNow(admin) {
  const templesSnap = await admin.firestore().collection("temples").get();
  const temples = templesSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const indexSnap = await admin.firestore().collection("temple_index").get();
  const sample = existsSync(sampleDataPath) ? readFileSync(sampleDataPath, "utf8") : "";
  return referenceSet({
    temples,
    shards: indexSnap.docs.map((doc) => doc.data()),
    sampleText: sample,
  });
}

function bucketStorage(admin) {
  const bucket = admin.storage().bucket(STORAGE_AUTH_BUCKET);
  return {
    listPrefix: async (prefix) => {
      const [files] = await bucket.getFiles({ prefix, autoPaginate: true });
      return files.map((file) => file.name);
    },
    deleteObject: async (path) => {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
    copyObject: async (from, to) => {
      await bucket.file(from).copy(bucket.file(to));
    },
    downloadObject: async (from, dest) => {
      await mkdir(dirname(dest), { recursive: true });
      await bucket.file(from).download({ destination: dest });
    },
  };
}

export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const writeLog = deps.log ?? ((line) => console.log(line));
  const writeWarn = deps.warn ?? ((line) => console.warn(line));
  const log = (line) => writeLog(redactDownloadToken(line));
  const warn = (line) => writeWarn(redactDownloadToken(line));
  if (opts.help) {
    printUsage();
    return null;
  }
  const env = deps.env ?? process.env;
  const project = resolveProject(opts, env);
  useNativeFetchForStorageAuth();
  if (opts.apply) await authorizeApply(project, env, { confirm: deps.confirm });
  if (opts.apply) {
    if (deps.storagePreflight) await deps.storagePreflight();
    else if (!usesEmulator(env)) {
      const admin = await openAdmin(project, env);
      await assertStorageAuth(admin.storage().bucket(STORAGE_AUTH_BUCKET));
    }
  }
  const load = deps.load ?? loadTemples;
  const temples = await load(project, env);
  temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  const knownIds = new Set(temples.map((temple) => String(temple?.id ?? "")));
  for (const id of [...opts.exclude].sort()) {
    if (!knownIds.has(id)) warn(`exclude: unknown temple id ${id}`);
  }
  for (const id of [...opts.only].sort()) {
    if (!knownIds.has(id)) warn(`only: unknown temple id ${id}`);
  }
  const selected = selectTemples(temples, opts);
  const plans = planPurgePlacesPhotos(selected);
  let storage = null;
  const needsBucket =
    !usesEmulator(env) &&
    typeof deps.listPrefix !== "function" &&
    (opts.apply || plans.some((plan) => plan.action === "purge"));
  if (needsBucket && existsSync(resolve(__dirname, "service-account.json")) === false &&
      existsSync(resolve(__dirname, "..", "service-account.json")) === false) {
    if (opts.apply) throw new Error("service-account.json was not found. No write.");
  } else if (needsBucket) {
    const admin = await openAdmin(project, env);
    storage = bucketStorage(admin);
  }
  const listPrefix = deps.listPrefix ?? storage?.listPrefix;
  const deleteObject = deps.deleteObject ?? storage?.deleteObject;
  const copyObject = deps.copyObject ?? storage?.copyObject;
  const downloadObject = deps.downloadObject ?? storage?.downloadObject;
  const rows = await applyPurgePlans(plans, {
    dryRun: !opts.apply,
    write:
      deps.write ??
      (async (plan) => {
        const admin = await openAdmin(project, env);
        return persistPurgePlaces(admin.firestore(), plan);
      }),
  });
  const after = opts.apply ? await load(project, env) : templesAfterPurge(temples, rows);
  const referencesObject =
    deps.referencesObject ??
    (opts.apply
      ? async (path) => {
          const admin = await openAdmin(project, env);
          const paths = await referencedPathsNow(admin);
          return paths.has(path);
        }
      : undefined);
  const objects = await placesDeletePlan(rows, after, {
    listPrefix,
    deleteObject,
    copyObject,
    downloadObject,
    performDelete: opts.apply && !opts.noDelete,
    performBackup: opts.apply,
    noDelete: opts.noDelete,
    includeLeftovers: opts.apply,
    backupDir: deps.backupDir ?? opts.backupDir,
    backupStamp: deps.backupStamp,
    referencesObject,
  });
  log(formatPurgeReport(rows, objects, { apply: opts.apply, noDelete: opts.noDelete }));
  return { rows, objects };
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  main().catch((error) => {
    console.error(redactDownloadToken(error?.message || error));
    process.exitCode = 1;
  });
}

export { isPlacesMirrorUrl, redactDownloadToken };
