/**
 * Clear placeholder-host URLs from temple image fields.
 *
 * Dry-run is the default. It reads temple documents and prints which covers
 * would lose an exact placeholder-host URL. It does not write.
 * The app then shows Photo pending for that temple.
 *
 *   node scripts/clear_placeholder_covers.js --project temple-directory-india
 *
 * imageUrl is set to an empty string when it is a placeholder host. Matching
 * strings are removed from images. photos entries whose url is a placeholder
 * host are removed. A placeholder thumbUrl is removed and the photo stays.
 *
 * Apply re-reads each document in its own transaction, skips it when the
 * placeholder set changed, and writes the cleared fields plus that temple's
 * index entry from the fresh document.
 *
 *   node scripts/clear_placeholder_covers.js --apply --project temple-directory-india
 *
 * prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { assertExplicitProject, assertNotCi, confirmProject } from "./prod_guard.js";
import { isPlaceholderImageUrl } from "./state_batch.js";
import { entryFromTemple, stateSlug } from "./temple_index.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function printUsage() {
  console.log(`
Usage:
  node clear_placeholder_covers.js [--dry-run] [--project <firebase-project-id>]
  node clear_placeholder_covers.js --apply --project <firebase-project-id>

Default is dry-run: list temples whose imageUrl, images, or photos use an
exact placeholder host (picsum.photos, placeholder.com, via.placeholder.com,
placehold.co, placehold.it, dummyimage.com, lorempixel.com,
source.unsplash.com). A path containing "placeholder" or "picsum" is kept.
images.unsplash.com and shutterstock are kept. Nothing is written.
prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI.
Prod apply prompts for the project id.
Set FIRESTORE_EMULATOR_HOST to use the emulator without that prompt.
--project is required against prod. The emulator falls back to
demo-temple-index when --project is omitted.
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

/** http(s) URL on a placeholder host. Empty and non-URL strings stay put. */
export function placeholderHostUrl(raw) {
  const url = String(raw ?? "").trim();
  if (!url.startsWith("http://") && !url.startsWith("https://")) return false;
  return isPlaceholderImageUrl(url);
}

/**
 * Fields to clear on one temple. `ready` means no placeholder host URL.
 */
export function planClearCover(temple) {
  const id = String(temple?.id ?? "");
  const removed = [];
  const patch = {};
  const imageUrl = temple?.imageUrl;
  if (typeof imageUrl === "string" && placeholderHostUrl(imageUrl)) {
    removed.push(imageUrl.trim());
    patch.imageUrl = "";
  }
  if (Array.isArray(temple?.images)) {
    let changed = false;
    const next = [];
    for (const item of temple.images) {
      if (typeof item === "string" && placeholderHostUrl(item)) {
        removed.push(item.trim());
        changed = true;
        continue;
      }
      if (
        item &&
        typeof item === "object" &&
        !Array.isArray(item) &&
        typeof item.url === "string" &&
        placeholderHostUrl(item.url)
      ) {
        removed.push(item.url.trim());
        changed = true;
        continue;
      }
      next.push(item);
    }
    if (changed) patch.images = next;
  }
  if (Array.isArray(temple?.photos)) {
    let changed = false;
    const next = [];
    for (const photo of temple.photos) {
      if (
        photo &&
        typeof photo === "object" &&
        typeof photo.url === "string" &&
        placeholderHostUrl(photo.url)
      ) {
        removed.push(photo.url.trim());
        changed = true;
        continue;
      }
      if (
        photo &&
        typeof photo === "object" &&
        typeof photo.thumbUrl === "string" &&
        placeholderHostUrl(photo.thumbUrl)
      ) {
        removed.push(photo.thumbUrl.trim());
        const copy = { ...photo };
        delete copy.thumbUrl;
        next.push(copy);
        changed = true;
        continue;
      }
      next.push(photo);
    }
    if (changed) patch.photos = next;
  }
  if (removed.length === 0) return { id, action: "ready" };
  return {
    id,
    action: "clear",
    removed,
    patch,
    plannedState: typeof temple?.state === "string" ? temple.state : "",
    temple: { ...temple, id, ...patch },
  };
}

export function planClearCovers(temples) {
  return (temples ?? []).map((temple) => planClearCover(temple));
}

/**
 * Re-read check. A doc whose placeholder set is no longer the same is not written.
 */
export function commitClearCover(fresh, plan) {
  const again = planClearCover({ ...fresh, id: fresh?.id ?? plan.id });
  if (again.action !== "clear") return { ok: false, reason: "already" };
  if (JSON.stringify(again.removed) !== JSON.stringify(plan.removed)) {
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

export function formatClearReport(rows, { apply = false } = {}) {
  const lines = [apply ? "Mode: apply" : "Mode: dry-run"];
  const cleared = rows.filter((row) => row.action === "clear" && row.result !== "skipped");
  const skipped = rows.filter((row) => row.result === "skipped");
  lines.push(`cleared: ${cleared.length}`);
  for (const row of cleared) lines.push(`${row.result ?? "would-clear"} ${row.id}`);
  lines.push(`skipped: ${skipped.length}`);
  for (const row of skipped) lines.push(`skip ${row.id} ${row.reason}`);
  if (!apply) lines.push("Dry-run only. No Firestore writes.");
  else lines.push("Cleared fields plus that temple's index entry. Rules were not deployed.");
  return lines.join("\n");
}

/**
 * One transaction per temple. Re-read, skip when the plan no longer matches,
 * then set the cleared fields and that temple's index entry from the fresh document.
 */
export async function persistClearCover(db, plan, deps = {}) {
  const admin = deps.admin ?? (await import("firebase-admin")).default;
  const id = String(plan.id ?? "");
  if (!id) return { ok: false, reason: "missing" };
  const plannedState = plan.plannedState ?? plan.temple?.state;
  return db.runTransaction(async (tx) => {
    const templeRef = db.collection("temples").doc(id);
    const templeSnap = await tx.get(templeRef);
    if (!templeSnap.exists) return { ok: false, reason: "missing" };
    const fresh = { ...templeSnap.data(), id: templeSnap.id };
    const committed = commitClearCover(fresh, plan);
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

export async function applyClearPlans(plans, deps) {
  const report = [];
  for (const plan of plans) {
    if (plan.action !== "clear") {
      report.push(plan);
      continue;
    }
    if (deps.dryRun) {
      report.push({ ...plan, result: "would-clear" });
      continue;
    }
    const written = await deps.write(plan);
    if (written && written.ok === false) {
      report.push({ ...plan, action: "skip", result: "skipped", reason: written.reason });
      continue;
    }
    report.push({ ...plan, result: "cleared" });
  }
  return report;
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
  temples.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  const plans = planClearCovers(temples);
  const rows = await applyClearPlans(plans, {
    dryRun: !opts.apply,
    write:
      deps.write ??
      (async (plan) => {
        const admin = await openAdmin(project, env);
        return persistClearCover(admin.firestore(), plan);
      }),
  });
  log(formatClearReport(rows, { apply: opts.apply }));
  return rows;
}

const invoked = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invoked) {
  main().catch((error) => {
    console.error(error?.message || error);
    process.exitCode = 1;
  });
}
