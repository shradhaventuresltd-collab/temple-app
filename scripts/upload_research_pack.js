import { existsSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { basename, dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");
const defaultPacksRoot = resolve(repoRoot, "tools/photo-packs");

function printUsage() {
  console.log(`
Usage:
  node upload_research_pack.js --pack <folder> [options]
  node upload_research_pack.js --packs-dir <dir> [options]
  node upload_research_pack.js --all-packs [options]

Uploads Research-verified temple photos from pack folder(s) (manifest.json + jpgs)
to Firebase Storage under temples/{docId}/…

Options:
  --pack <path>          One pack folder (repeatable)
  --packs-dir <path>     Directory of pack folders (each with manifest.json)
  --all-packs            Upload every pack under tools/photo-packs/
  --doc-id <id>          Override Storage/Firestore id (single --pack only)
  --bucket <name>        Storage bucket (default: temple-directory-india.firebasestorage.app)
  --patch-firestore      Also set temples/{docId}.imageUrl + images in Firestore
  --dry-run              Parse packs and print planned uploads; do not touch Storage
  --write-urls <path>    Write a JSON summary of download URLs to this file
  --help                 Show this help

Requires service-account.json in the repo root or scripts/ (gitignored).
Does not use Google Places. Prefer only filenames listed in manifest.json.

Examples:
  node upload_research_pack.js --all-packs --dry-run
  node upload_research_pack.js --pack ../tools/photo-packs/mahabodhi-temple --dry-run
  node upload_research_pack.js --packs-dir ../tools/photo-packs --patch-firestore
`);
}

function parseArgs(argv) {
  const opts = {
    packs: [],
    packsDir: null,
    allPacks: false,
    docId: null,
    bucket: "temple-directory-india.firebasestorage.app",
    patchFirestore: false,
    dryRun: false,
    writeUrls: null,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--pack") opts.packs.push(argv[++i]);
    else if (arg === "--packs-dir") opts.packsDir = argv[++i];
    else if (arg === "--all-packs") opts.allPacks = true;
    else if (arg === "--doc-id") opts.docId = argv[++i];
    else if (arg === "--bucket") opts.bucket = argv[++i];
    else if (arg === "--patch-firestore") opts.patchFirestore = true;
    else if (arg === "--dry-run") opts.dryRun = true;
    else if (arg === "--write-urls") opts.writeUrls = argv[++i];
    else {
      console.error(`Unknown argument: ${arg}`);
      opts.help = true;
    }
  }
  return opts;
}

function loadServiceAccount() {
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(repoRoot, "service-account.json"),
  ];
  for (const path of candidates) {
    if (existsSync(path)) {
      return { path, json: JSON.parse(readFileSync(path, "utf8")) };
    }
  }
  return null;
}

function loadManifest(packDir) {
  const manifestPath = resolve(packDir, "manifest.json");
  if (!existsSync(manifestPath)) {
    throw new Error(`manifest.json not found in ${packDir}`);
  }
  return JSON.parse(readFileSync(manifestPath, "utf8"));
}

function resolvePhotos(packDir, manifest) {
  const photos = Array.isArray(manifest.photos) ? manifest.photos : [];
  if (photos.length === 0) {
    throw new Error("manifest.photos is empty");
  }

  const resolved = [];
  for (const photo of photos) {
    const filename = photo.filename;
    if (!filename || typeof filename !== "string") {
      throw new Error("manifest photo entry missing filename");
    }
    const localPath = resolve(packDir, filename);
    if (!existsSync(localPath)) {
      throw new Error(`Missing pack file listed in manifest: ${filename}`);
    }
    resolved.push({
      filename,
      localPath,
      author: photo.author || "",
      license: photo.license || "",
      sourceUrl: photo.source_url || "",
      downloadedUrl: photo.downloaded_url || "",
    });
  }
  return resolved;
}

function discoverPackDirs(packsDir) {
  if (!existsSync(packsDir)) {
    throw new Error(`Packs directory not found: ${packsDir}`);
  }
  return readdirSync(packsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => resolve(packsDir, entry.name))
    .filter((dir) => existsSync(resolve(dir, "manifest.json")))
    .sort();
}

function resolvePackDirs(opts) {
  const dirs = [];
  if (opts.allPacks) {
    dirs.push(...discoverPackDirs(defaultPacksRoot));
  }
  if (opts.packsDir) {
    dirs.push(...discoverPackDirs(resolve(process.cwd(), opts.packsDir)));
  }
  for (const pack of opts.packs) {
    dirs.push(resolve(process.cwd(), pack));
  }
  // De-dupe while preserving order
  return [...new Set(dirs)];
}

function publicUrl(bucketName, storagePath) {
  return `https://storage.googleapis.com/${bucketName}/${storagePath}`;
}

async function uploadFile(bucket, localPath, storagePath) {
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: "image/jpeg",
      cacheControl: "public, max-age=86400",
    },
  });
  const file = bucket.file(storagePath);
  await file.makePublic();
  return publicUrl(bucket.name, storagePath);
}

async function processPack({
  packDir,
  docIdOverride,
  bucketName,
  patchFirestore,
  dryRun,
  adminApp,
}) {
  if (!existsSync(packDir)) {
    throw new Error(`Pack folder not found: ${packDir}`);
  }

  const manifest = loadManifest(packDir);
  const docId =
    docIdOverride ||
    manifest.temple_slug ||
    manifest.doc_id_hint ||
    basename(packDir);
  const photos = resolvePhotos(packDir, manifest);

  console.log("────────────────────────────────────────────────────────────");
  console.log(`Pack       : ${packDir}`);
  console.log(`Temple     : ${manifest.temple_name || docId}`);
  console.log(`Doc id     : ${docId}`);
  console.log(`Photos     : ${photos.length} (from manifest.json only)`);

  if (dryRun) {
    for (const photo of photos) {
      const storagePath = `temples/${docId}/${photo.filename}`;
      console.log(`• ${photo.filename}`);
      console.log(`    → gs://${bucketName}/${storagePath}`);
      console.log(
        `    license: ${photo.license || "(none)"} / ${photo.author || "(unknown)"}`
      );
    }
    return {
      docId,
      imageUrl: photos[0]?.downloadedUrl || "",
      images: photos.map((p) => p.downloadedUrl).filter(Boolean),
      photos,
      uploaded: false,
    };
  }

  const bucket = adminApp.storage().bucket();
  const uploadedUrls = [];

  for (let i = 0; i < photos.length; i++) {
    const photo = photos[i];
    const storagePath = `temples/${docId}/${photo.filename}`;
    process.stdout.write(
      `[${i + 1}/${photos.length}] Uploading ${photo.filename} … `
    );
    try {
      const url = await uploadFile(bucket, photo.localPath, storagePath);
      uploadedUrls.push(url);
      console.log("ok");
      console.log(`    ${url}`);
    } catch (err) {
      console.log("FAILED");
      throw new Error(`${photo.filename}: ${err.message}`);
    }
  }

  console.log("\n── Download URLs ─────────────────────────────────────────────");
  for (const url of uploadedUrls) {
    console.log(url);
  }

  console.log("\n── Suggested sample_data / Firestore fields ──────────────────");
  console.log(`imageUrl: '${uploadedUrls[0]}',`);
  console.log("images: [");
  for (const url of uploadedUrls) {
    console.log(`  '${url}',`);
  }
  console.log("],");

  if (patchFirestore) {
    const db = adminApp.firestore();
    const docRef = db.collection("temples").doc(docId);
    const snap = await docRef.get();
    if (!snap.exists) {
      console.log(
        `\n⚠  Firestore doc temples/${docId} not found — skipping patch.`
      );
      console.log(
        "   Run debug Seed first, then re-run with --patch-firestore."
      );
    } else {
      await docRef.update({
        imageUrl: uploadedUrls[0],
        images: uploadedUrls,
      });
      console.log(`\n🔥 Firestore temples/${docId} updated (imageUrl + images).`);
    }
  } else {
    console.log(
      "\nFirestore left unchanged. Pass --patch-firestore to write imageUrl/images."
    );
  }

  return {
    docId,
    imageUrl: uploadedUrls[0],
    images: uploadedUrls,
    photos,
    uploaded: true,
  };
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const packDirs = resolvePackDirs(opts);

  if (opts.help || packDirs.length === 0) {
    printUsage();
    process.exit(opts.help && packDirs.length === 0 ? 0 : 1);
  }

  if (opts.docId && packDirs.length > 1) {
    console.error("✖  --doc-id can only be used with a single --pack");
    process.exit(1);
  }

  console.log("╔════════════════════════════════════════════════════════════╗");
  console.log("║  Research photo pack → Firebase Storage                    ║");
  console.log("╚════════════════════════════════════════════════════════════╝");
  console.log(`Packs      : ${packDirs.length}`);
  console.log(`Bucket     : ${opts.bucket}`);
  console.log(
    `Firestore  : ${opts.patchFirestore ? "patch imageUrl + images" : "skip"}`
  );
  console.log(`Mode       : ${opts.dryRun ? "dry-run" : "upload"}\n`);

  let adminApp = null;
  if (!opts.dryRun) {
    const sa = loadServiceAccount();
    if (!sa) {
      console.error(
        "\n✖  service-account.json not found.\n" +
          "   Download it from Firebase Console → Project Settings → Service Accounts\n" +
          "   → Generate New Private Key. Place it in the project root or scripts/.\n" +
          "   Do not commit the key.\n"
      );
      process.exit(1);
    }
    console.log(`Service account: ${sa.path}\n`);
    const { default: admin } = await import("firebase-admin");
    adminApp = admin.initializeApp({
      credential: admin.credential.cert(sa.json),
      storageBucket: opts.bucket,
    });
  }

  const summaries = [];
  for (const packDir of packDirs) {
    const summary = await processPack({
      packDir,
      docIdOverride: opts.docId,
      bucketName: opts.bucket,
      patchFirestore: opts.patchFirestore,
      dryRun: opts.dryRun,
      adminApp,
    });
    summaries.push(summary);
    console.log("");
  }

  if (opts.dryRun) {
    console.log(`Dry run complete — ${summaries.length} pack(s), no Storage writes.`);
  } else {
    console.log(`Done — ${summaries.length} pack(s) processed.`);
  }

  if (opts.writeUrls) {
    const outPath = resolve(process.cwd(), opts.writeUrls);
    const payload = {
      bucket: opts.bucket,
      dryRun: opts.dryRun,
      packs: summaries.map((s) => ({
        docId: s.docId,
        imageUrl: s.imageUrl,
        images: s.images,
        uploaded: s.uploaded,
        photos: s.photos.map((p, i) => ({
          filename: p.filename,
          storageUrl: s.uploaded ? s.images[i] : null,
          downloaded_url: p.downloadedUrl,
          author: p.author,
          license: p.license,
          source_url: p.sourceUrl,
        })),
      })),
    };
    writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`);
    console.log(`Wrote URL summary → ${outPath}`);
  }

  process.exit(0);
}

main().catch((err) => {
  console.error(`\n✖  ${err.message}`);
  process.exit(1);
});
