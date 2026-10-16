import { ensureDownloadToken } from "./download_token.js";
import { redactDownloadToken } from "./redact_url.js";
import { useNativeFetchForStorageAuth } from "./storage_auth.js";
import admin from "firebase-admin";
import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── Firebase setup ──────────────────────────────────────────────────────────
const saPath = [
  resolve(__dirname, "service-account.json"),
  resolve(__dirname, "..", "service-account.json"),
].find((p) => {
  try {
    readFileSync(p);
    return true;
  } catch {
    return false;
  }
});

if (!saPath) {
  console.error(
    "\n✖  service-account.json not found.\n" +
      "   Place it in the project root or the scripts/ folder.\n"
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(saPath, "utf8"))),
  storageBucket: "temple-directory-india.firebasestorage.app",
});

useNativeFetchForStorageAuth();
const db = admin.firestore();
const bucket = admin.storage().bucket();

// ── Main ────────────────────────────────────────────────────────────────────
async function main() {
  console.log("╔════════════════════════════════════════════════════════════╗");
  console.log("║  🔧  Fix Firestore URLs from Firebase Storage           ║");
  console.log("╚════════════════════════════════════════════════════════════╝\n");

  // 1. List all files under temples/
  console.log("📂 Listing all files in Storage under temples/...\n");
  const [files] = await bucket.getFiles({ prefix: "temples/" });

  // 2. Group files by temple folder (temples/{templeId}/image_X.jpg)
  const templeFiles = new Map();
  for (const file of files) {
    const parts = file.name.split("/");
    // Expect: temples / {templeId} / filename
    if (parts.length < 3 || !parts[2]) continue;
    const templeId = parts[1];
    if (!templeFiles.has(templeId)) templeFiles.set(templeId, []);
    templeFiles.get(templeId).push(file);
  }

  console.log(`Found ${templeFiles.size} temple folders in Storage.\n`);

  let updated = 0;
  let skipped = 0;
  let failed = 0;

  for (const [templeId, storageFiles] of templeFiles) {
    console.log(`🛕  ${templeId}  (${storageFiles.length} file(s))`);

    // 3. Download-token URL for each file. Reuse a token already on the object.
    const rows = [];
    for (const file of storageFiles) {
      try {
        const { url } = await ensureDownloadToken(file, bucket.name);
        rows.push({ name: file.name, url });
      } catch (err) {
        console.error(`   ✖  Could not get URL for ${file.name}: ${redactDownloadToken(err.message)}`);
      }
    }

    // Sort by object name so image_1 stays before image_2.
    rows.sort((a, b) => a.name.localeCompare(b.name));
    const urls = rows.map((row) => row.url);

    if (urls.length === 0) {
      console.log("   ⚠  No valid URLs, skipping.");
      skipped++;
      continue;
    }

    console.log(`   📸 URLs: ${urls.length}`);
    for (const u of urls) {
      console.log(`      • ${redactDownloadToken(u)}`);
    }

    // 4. Update Firestore
    const docRef = db.collection("temples").doc(templeId);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log(`   ⚠  Firestore doc "${templeId}" not found, skipping.`);
      skipped++;
      continue;
    }

    try {
      await docRef.update({
        imageUrl: urls[0],
        images: urls,
      });
      console.log(`   ✔  Firestore updated — imageUrl + images array set`);
      updated++;
    } catch (err) {
      console.error(`   ✖  Firestore update failed: ${redactDownloadToken(err.message)}`);
      failed++;
    }
  }

  console.log("\n╔════════════════════════════════════════════════════════════╗");
  console.log(`║  Done!  ✔ ${String(updated).padStart(2)} updated   ⏭ ${String(skipped).padStart(2)} skipped   ✖ ${String(failed).padStart(2)} failed    ║`);
  console.log("╚════════════════════════════════════════════════════════════╝\n");

  process.exit(0);
}

main();
