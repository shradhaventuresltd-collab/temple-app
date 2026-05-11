import "dotenv/config";
import admin from "firebase-admin";
import axios from "axios";
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
      "   Download it from Firebase Console → Project Settings → Service Accounts → Generate New Private Key\n" +
      "   Place it in the project root or the scripts/ folder.\n"
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(saPath, "utf8"))),
  storageBucket: "temple-directory-india.firebasestorage.app",
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// ── Google Places API (New) — rotating keys ────────────────────────────────
const API_KEYS = [
  process.env.GOOGLE_API_KEY_1,
  process.env.GOOGLE_API_KEY_2,
  process.env.GOOGLE_API_KEY_3,
  process.env.GOOGLE_API_KEY_4,
].filter(Boolean);

if (API_KEYS.length === 0) {
  console.error("✖  At least one GOOGLE_API_KEY_N must be set in .env");
  process.exit(1);
}

let keyIndex = 0;
function getApiKey() {
  const key = API_KEYS[keyIndex % API_KEYS.length];
  keyIndex++;
  return key;
}

const MAX_PHOTOS = 4;
const SEARCH_TIMEOUT = 10_000;

// ── Temple data (mirrors seed_service.dart slug logic) ──────────────────────
function toSlug(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

const temples = [
  // Tamil Nadu
  { name: "Meenakshi Amman Temple", queries: ["Meenakshi Amman Temple Madurai", "Meenakshi Amman Temple", "Meenakshi Temple Madurai India"] },
  { name: "Brihadeeswarar Temple", queries: ["Brihadeeswarar Temple Thanjavur", "Brihadeeswarar Temple", "Big Temple Thanjavur India"] },
  { name: "Kapaleeshwarar Temple", queries: ["Kapaleeshwarar Temple Chennai", "Kapaleeshwarar Temple", "Kapaleeshwarar temple india"] },
  { name: "Ramanathaswamy Temple", queries: ["Ramanathaswamy Temple Rameswaram", "Ramanathaswamy Temple", "Ramanathaswamy temple india"] },
  { name: "Murugan Temple, Thirupparankundram", queries: ["Murugan Temple Thirupparankundram Madurai", "Thirupparankundram Murugan Temple", "Murugan temple india"] },
  { name: "Shore Temple", queries: ["Shore Temple Mahabalipuram", "Shore Temple", "Shore temple india"] },
  { name: "Nataraja Temple", queries: ["Thillai Nataraja Temple Chidambaram", "Nataraja Temple Chidambaram", "Nataraja temple india"] },
  { name: "Ekambaranathar Temple", queries: ["Ekambareswarar Temple Kanchipuram", "Ekambaranathar Temple Kanchipuram", "Ekambaranathar temple india"] },
  { name: "Arunachaleswarar Temple", queries: ["Annamalaiyar Temple Tiruvannamalai", "Arunachaleswarar Temple Tiruvannamalai", "Arunachaleswarar temple india"] },
  { name: "Sarangapani Temple", queries: ["Sarangapani Temple Kumbakonam Tamil Nadu", "Sarangapani Temple Kumbakonam", "Sarangapani temple india"] },
  // Kerala
  { name: "Guruvayur Sri Krishna Temple", queries: ["Guruvayur Temple Kerala", "Guruvayur Sri Krishna Temple", "Guruvayur temple india"] },
  { name: "Sree Padmanabhaswamy Temple", queries: ["Sree Padmanabhaswamy Temple Thiruvananthapuram", "Padmanabhaswamy Temple", "Padmanabhaswamy temple india"] },
  { name: "Sabarimala Ayyappan Temple", queries: ["Sabarimala Temple Kerala", "Sabarimala Ayyappan Temple", "Sabarimala temple india"] },
  { name: "Attukal Bhagavathy Temple", queries: ["Attukal Devi Temple Thiruvananthapuram", "Attukal Bhagavathy Temple", "Attukal temple india"] },
  { name: "Chottanikkara Bhagavathy Temple", queries: ["Chottanikkara Bhagavathy Temple Kerala", "Chottanikkara Devi Temple", "Chottanikkara temple india"] },
  { name: "Ernakulathappan Temple", queries: ["Ernakulathappan Temple Kochi", "Ernakulathappan Temple", "Ernakulathappan temple india"] },
  { name: "Vaikom Mahadeva Temple", queries: ["Vaikom Mahadeva Temple Kerala", "Vaikom Mahadeva Temple", "Vaikom temple india"] },
  { name: "Anjengo Sree Durga Devi Temple", queries: ["Anjengo Durga Temple Kerala", "Anjengo Sree Durga Devi Temple", "Anjengo temple india"] },
  { name: "Mannarsala Sree Nagaraja Temple", queries: ["Mannarsala Nagaraja Temple Kerala", "Mannarsala Sree Nagaraja Temple", "Mannarsala temple india"] },
  { name: "Thirunelli Maha Vishnu Temple", queries: ["Thirunelli Temple Wayanad Kerala", "Thirunelli Maha Vishnu Temple", "Thirunelli temple india"] },
  // Karnataka
  { name: "Sri Krishna Matha (Udupi)", queries: ["Udupi Sri Krishna Matha Temple", "Sri Krishna Matha Udupi", "Sri Krishna temple india"] },
  { name: "Sri Manjunatha Temple, Dharmasthala", queries: ["Dharmasthala Manjunatha Temple", "Sri Manjunatha Temple Dharmasthala", "Dharmasthala temple india"] },
  { name: "Kukke Subramanya Temple", queries: ["Kukke Subramanya Temple Karnataka", "Kukke Subramanya Temple", "Kukke Subramanya temple india"] },
  { name: "Sringeri Sharada Peetham", queries: ["Sringeri Sharada Peetham Temple", "Sringeri Sharada Peetham", "Sringeri temple india"] },
  { name: "Kollur Mookambika Temple", queries: ["Kollur Mookambika Temple Karnataka", "Kollur Mookambika Temple", "Kollur Mookambika temple india"] },
  { name: "Mahabaleshwar Temple, Gokarna", queries: ["Mahabaleshwar Temple Gokarna", "Mahabaleshwar Temple", "Mahabaleshwar temple india"] },
  { name: "Chamundeshwari Temple", queries: ["Chamundeshwari Temple Mysore", "Chamundeshwari Temple", "Chamundeshwari temple india"] },
  { name: "Virupaksha Temple", queries: ["Virupaksha Temple Hampi", "Virupaksha Temple", "Virupaksha temple india"] },
  { name: "Srikanteshwara Temple, Nanjangud", queries: ["Srikanteshwara Temple Nanjangud", "Srikanteshwara Temple", "Srikanteshwara temple india"] },
  { name: "ISKCON Temple, Bangalore", queries: ["ISKCON Temple Bangalore", "ISKCON Temple Bengaluru", "ISKCON temple india"] },
];

// ── Helpers ─────────────────────────────────────────────────────────────────
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Places API (New) — Text Search.
 * POST https://places.googleapis.com/v1/places:searchText
 * Returns the first place with photos, or null.
 */
async function searchPlaceSingle(query) {
  const key = getApiKey();
  const { data } = await axios.post(
    "https://places.googleapis.com/v1/places:searchText",
    { textQuery: query },
    {
      headers: {
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "places.id,places.displayName,places.photos",
        "Content-Type": "application/json",
      },
      timeout: SEARCH_TIMEOUT,
    }
  );

  if (!data.places?.length) return null;

  // Return the first place that has photos
  const match = data.places.find((p) => p.photos?.length > 0);
  return match || null;
}

/**
 * Try multiple search queries in order until one returns a place with photos.
 */
async function searchPlaceWithFallback(queries) {
  for (const query of queries) {
    try {
      const place = await searchPlaceSingle(query);
      if (place) return { place, matchedQuery: query };
    } catch (err) {
      console.log(`      ↳ Query "${query}" errored: ${err.response?.data?.error?.message || err.message}`);
    }
  }
  return { place: null, matchedQuery: null };
}

/**
 * Places API (New) — Download a photo by its resource name.
 * GET https://places.googleapis.com/v1/{photoName}/media?maxWidthPx=1200&key=API_KEY
 */
async function downloadPlacePhoto(photoName) {
  const key = getApiKey();
  const response = await axios.get(
    `https://places.googleapis.com/v1/${photoName}/media`,
    {
      params: { maxWidthPx: 1200, key },
      responseType: "arraybuffer",
      timeout: 20000,
      maxRedirects: 5,
    }
  );
  return Buffer.from(response.data);
}

/**
 * Upload a buffer to Firebase Storage and return its public URL.
 */
async function uploadToStorage(buffer, storagePath) {
  const file = bucket.file(storagePath);
  await file.save(buffer, { metadata: { contentType: "image/jpeg" } });
  await file.makePublic();
  return `https://storage.googleapis.com/${bucket.name}/${storagePath}`;
}

// ── Per-temple pipeline ─────────────────────────────────────────────────────
async function processTemple(temple, index) {
  const docId = toSlug(temple.name);
  const label = `[${index + 1}/${temples.length}] ${temple.name}`;

  console.log(`\n🛕  ${label}`);
  console.log(`   Firestore doc: ${docId}`);

  // Step 1 — Text Search (New) with fallback
  console.log(`   🔍 Searching (${temple.queries.length} variations)...`);
  for (const q of temple.queries) {
    console.log(`      • "${q}"`);
  }

  const { place, matchedQuery } = await searchPlaceWithFallback(temple.queries);
  if (!place) {
    console.log("   ⚠  Place not found after all variations, skipping.");
    return;
  }

  const displayName = place.displayName?.text || place.id;
  console.log(`   📍 Found: ${displayName}  (id: ${place.id})`);
  console.log(`   ✔  Matched on: "${matchedQuery}"`);

  // Step 2 — Collect photo resource names (up to MAX_PHOTOS)
  const photoNames = place.photos
    .slice(0, MAX_PHOTOS)
    .map((p) => p.name);

  console.log(`   📸 ${photoNames.length} photo(s) available`);

  // Steps 3 & 4 — Download each photo and upload to Storage
  const uploadedUrls = [];
  for (let i = 0; i < photoNames.length; i++) {
    try {
      console.log(`   ⬇  Downloading photo ${i + 1}/${photoNames.length}...`);
      const buffer = await downloadPlacePhoto(photoNames[i]);

      const storagePath = `temples/${docId}/image_${i + 1}.jpg`;
      console.log(`   ⬆  Uploading → ${storagePath}  (${(buffer.length / 1024).toFixed(0)} KB)`);
      const publicUrl = await uploadToStorage(buffer, storagePath);

      uploadedUrls.push(publicUrl);
      console.log(`   ✔  Photo ${i + 1} done`);
    } catch (err) {
      console.error(`   ✖  Photo ${i + 1} failed: ${err.message}`);
    }
  }

  // Step 5 — Update Firestore
  if (uploadedUrls.length > 0) {
    try {
      const docRef = db.collection("temples").doc(docId);
      const doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          images: uploadedUrls,
          imageUrl: uploadedUrls[0],
        });
        console.log(`   🔥 Firestore updated — ${uploadedUrls.length} image(s) saved`);
      } else {
        console.log(`   ⚠  Firestore doc "${docId}" not found — skipping update.`);
        console.log('      Run "Seed Data" from the app first.');
      }
    } catch (err) {
      console.error(`   ✖  Firestore update failed: ${err.message}`);
    }
  }
}

// ── Main ────────────────────────────────────────────────────────────────────
async function main() {
  console.log("╔════════════════════════════════════════════════════════════╗");
  console.log("║  🛕  Temple Image Uploader — Places API (New) Edition   ║");
  console.log("╚════════════════════════════════════════════════════════════╝");
  console.log(`\nFirebase project : temple-directory-india`);
  console.log(`Storage bucket   : ${bucket.name}`);
  console.log(`API keys loaded  : ${API_KEYS.length} (round-robin)`);
  console.log(`Temples          : ${temples.length}`);
  console.log(`Photos per temple: up to ${MAX_PHOTOS}`);
  console.log(`Search timeout   : ${SEARCH_TIMEOUT / 1000}s\n`);

  let succeeded = 0;
  let failed = 0;

  for (let i = 0; i < temples.length; i++) {
    try {
      await processTemple(temples[i], i);
      succeeded++;
    } catch (err) {
      console.error(`\n✖  Unexpected error for ${temples[i].name}: ${err.message}`);
      failed++;
    }

    if (i < temples.length - 1) {
      console.log("   ⏳ Waiting 2s...");
      await sleep(2000);
    }
  }

  console.log("\n╔════════════════════════════════════════════════════════════╗");
  console.log(`║  Done!  ✔ ${String(succeeded).padStart(2)} succeeded   ✖ ${String(failed).padStart(2)} failed                  ║`);
  console.log("╚════════════════════════════════════════════════════════════╝\n");

  process.exit(0);
}

main();
