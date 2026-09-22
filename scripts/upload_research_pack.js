import { existsSync, readFileSync, writeFileSync } from "fs";
import { basename, dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");

function printUsage() {
  console.log(`
Usage:
  node upload_research_pack.js --pack <folder> [options]

Uploads Research-verified temple photos from a pack folder (manifest.json + jpgs)
to Firebase Storage under temples/{docId}/…

Options:
  --pack <path>          Pack folder with manifest.json + image files (required)
  --doc-id <id>          Firestore / Storage temple id (default: manifest.temple_slug
                         or manifest.doc_id_hint)
  --bucket <name>        Storage bucket (default: temple-directory-india.firebasestorage.app)
  --patch-firestore      Also set temples/{docId}.imageUrl + images in Firestore
  --dry-run              Parse pack and print planned uploads; do not touch Storage
  --write-urls <path>    Write a JSON summary of download URLs to this file
  --help                 Show this help

Requires service-account.json in the repo root or scripts/ (gitignored).
Does not use Google Places. Prefer only filenames listed in manifest.json.

Example (Mahabodhi):
  node upload_research_pack.js --pack ../tools/photo-packs/mahabodhi-temple --dry-run
  node upload_research_pack.js --pack ../tools/photo-packs/mahabodhi-temple --patch-firestore
`);
}

function parseArgs(argv) {
  const opts = {
    pack: null,
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
    else if (arg === "--pack") opts.pack = argv[++i];
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

function publicUrl(bucketName, storagePath) {
  return `https://storage.googleapis.com/${bucketName}/${storagePath}`;
}

async function uploadFile(bucket, localPath, storagePath) {
  const file = bucket.file(storagePath);
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: "image/jpeg",
      cacheControl: "public, max-age=86400",
    },
  });
  await file.makePublic();
  return publicUrl(bucket.name, storagePath);
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help || !opts.pack) {
    printUsage();
    process.exit(opts.help && !opts.pack ? 0 : 1);
  }

  const packDir = resolve(process.cwd(), opts.pack);
  if (!existsSync(packDir)) {
    console.error(`✖  Pack folder not found: ${packDir}`);
    process.exit(1);
  }

  const manifest = loadManifest(packDir);
  const docId =
    opts.docId ||
    manifest.temple_slug ||
    manifest.doc_id_hint ||
    basename(packDir);
  const photos = resolvePhotos(packDir, manifest);

  console.log("╔════════════════════════════════════════════════════════════╗");
  console.log("║  Research photo pack → Firebase Storage                    ║");
  console.log("╚════════════════════════════════════════════════════════════╝");
  console.log(`Pack       : ${packDir}`);
  console.log(`Temple     : ${manifest.temple_name || docId}`);
  console.log(`Doc id     : ${docId}`);
  console.log(`Photos     : ${photos.length} (from manifest.json only)`);
  console.log(`Bucket     : ${opts.bucket}`);
  console.log(`Firestore  : ${opts.patchFirestore ? "patch imageUrl + images" : "skip"}`);
  console.log(`Mode       : ${opts.dryRun ? "dry-run" : "upload"}\n`);

  if (opts.dryRun) {
    for (const photo of photos) {
      const storagePath = `temples/${docId}/${photo.filename}`;
      console.log(`• ${photo.filename}`);
      console.log(`    → gs://${opts.bucket}/${storagePath}`);
      console.log(`    license: ${photo.license || "(none)"} / ${photo.author || "(unknown)"}`);
    }
    console.log("\nDry run complete — no Storage or Firestore writes.");
    process.exit(0);
  }

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

  console.log(`Service account: ${sa.path}`);

  const { default: admin } = await import("firebase-admin");
  admin.initializeApp({
    credential: admin.credential.cert(sa.json),
    storageBucket: opts.bucket,
  });

  const bucket = admin.storage().bucket();
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
      console.error(`    ${err.message}`);
      process.exit(1);
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

  if (opts.patchFirestore) {
    const db = admin.firestore();
    const docRef = db.collection("temples").doc(docId);
    const snap = await docRef.get();
    if (!snap.exists) {
      console.log(
        `\n⚠  Firestore doc temples/${docId} not found — skipping patch.`
      );
      console.log('   Run debug Seed first, then re-run with --patch-firestore.');
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

  if (opts.writeUrls) {
    const outPath = resolve(process.cwd(), opts.writeUrls);
    const payload = {
      docId,
      bucket: opts.bucket,
      imageUrl: uploadedUrls[0],
      images: uploadedUrls,
      photos: photos.map((p, i) => ({
        filename: p.filename,
        storageUrl: uploadedUrls[i],
        author: p.author,
        license: p.license,
        source_url: p.sourceUrl,
      })),
    };
    writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`);
    console.log(`\nWrote URL summary → ${outPath}`);
  }

  console.log("\nDone.");
  process.exit(0);
}

main().catch((err) => {
  console.error(`\n✖  ${err.message}`);
  process.exit(1);
});
