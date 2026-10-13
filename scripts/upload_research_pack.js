import { existsSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { basename, dirname, resolve } from "path";
import { fileURLToPath } from "url";

import { mapPhotoLicence } from "./photo_licence.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");
const defaultPacksRoot = resolve(repoRoot, "tools/photo-packs");

// KAN-77 Wave B. --all-packs uploads every manifest under tools/photo-packs,
// and fails if any of these Karnataka packs are missing.
const WAVE_B_KARNATAKA_PACKS = [
  "anegudde-vinayaka-temple",
  "annapoorneshwari-temple-horanadu",
  "banashankari-temple-bengaluru",
  "chamundeshwari-temple",
  "cheluvanarayana-swamy-temple-melukote",
  "chennakeshava-temple-belur",
  "ghati-subramanya-temple",
  "hoysaleswara-temple-halebidu",
  "iskcon-temple-bangalore",
  "kateel-durga-parameshwari-temple",
  "kollur-mookambika-temple",
  "kukke-subramanya-temple",
  "mahabaleshwar-temple-gokarna",
  "murudeshwar-temple",
  "sri-krishna-matha-udupi",
  "sri-manjunatha-temple-dharmasthala",
  "srikanteshwara-temple-nanjangud",
  "sringeri-sharada-peetham",
  "talakaveri-temple",
  "virupaksha-temple",
];

// KAN-77 Wave A (Tamil Nadu + Kerala). --all-packs uploads every manifest
// under tools/photo-packs, and fails if any of these folders are missing.
const WAVE_A_TN_KL_PACKS = [
  "ambalappuzha-sri-krishna-temple",
  "arunachaleswarar-temple",
  "attukal-bhagavathy-temple",
  "brihadeeswarar-temple",
  "chengannur-mahadeva-temple",
  "chettikulangara-devi-temple",
  "chottanikkara-bhagavathy-temple",
  "dhandayuthapani-swamy-temple-palani",
  "ekambaranathar-temple",
  "ernakulathappan-temple",
  "ettumanoor-mahadeva-temple",
  "guruvayur-sri-krishna-temple",
  "jambukeswarar-temple-thiruvanaikaval",
  "kapaleeshwarar-temple",
  "kaviyoor-mahadeva-temple",
  "kodungallur-bhagavathy-temple",
  "murugan-temple-thirupparankundram",
  "nataraja-temple",
  "nellaiappar-temple-tirunelveli",
  "parassinikadavu-muthappan-temple",
  "ramanathaswamy-temple",
  "sabarimala-ayyappan-temple",
  "sarangapani-temple",
  "sree-padmanabhaswamy-temple",
  "sree-poornathrayeesa-temple",
  "sri-ranganathaswamy-temple-srirangam",
  "subramanya-swamy-temple-thiruchendur",
  "swamimalai-murugan-temple",
  "thirunelli-maha-vishnu-temple",
  "thiruvalla-sreevallabha-temple",
  "thyagaraja-temple-tiruvarur",
  "tiruttani-murugan-temple",
  "vadakkunnathan-temple",
  "vaikom-mahadeva-temple",
  "vaitheeswaran-koil",
];

// KAN-76/KAN-77 Wave C (all-India photo-pending temples). --all-packs fails
// if any of these folders are missing.
const WAVE_C_KAN76_PACKS = [
  "ahobilam-narasimha-temples",
  "ambaji-temple",
  "ananta-vasudeva-temple",
  "bahucharaji-temple",
  "baijnath-temple-himachal",
  "banke-bihari-temple",
  "belur-math",
  "bhadrakali-temple-warangal",
  "bhimakali-temple-sarahan",
  "bhimashankar-temple",
  "biraja-temple",
  "birla-mandir-jaipur",
  "birla-mandir-kolkata",
  "brahma-temple-pushkar",
  "chilkur-balaji-temple",
  "chintpurni-temple",
  "chotila-chamunda-mata-temple",
  "cuttack-chandi-temple",
  "dakshineswar-kali-temple",
  "deo-sun-temple",
  "dwarkadhish-temple",
  "eklingji-temple",
  "gnana-saraswati-temple-basara",
  "gorakhnath-temple",
  "govind-dev-ji-temple-jaipur",
  "grishneshwar-temple",
  "hadimba-devi-temple",
  "hangseshwari-temple",
  "harsiddhi-temple-ujjain",
  "jagannath-temple-puri",
  "jejuri-khandoba-temple",
  "jogulamba-temple-alampur",
  "jwalamukhi-temple",
  "kalighat-kali-temple",
  "kalika-mata-temple-pavagadh",
  "kandariya-mahadeva-temple",
  "kapil-muni-temple-gangasagar",
  "karni-mata-temple-deshnok",
  "khatushyam-temple",
  "kheer-bhawani-temple",
  "kiriteswari-temple",
  "konark-sun-temple",
  "lakshmana-temple-khajuraho",
  "lakshmi-narayan-temple-chamba",
  "lingaraj-temple",
  "mahakaleshwar-temple",
  "mahalakshmi-temple-mumbai",
  "mahavir-mandir-patna",
  "manikaran-shiva-temple",
  "mehandipur-balaji-temple",
  "modhera-sun-temple",
  "morgaon-mayureshwar-temple",
  "mukteshwar-temple",
  "mumba-devi-temple",
  "mundeshwari-devi-temple",
  "nageshwar-jyotirlinga-temple",
  "naina-devi-temple-bilaspur",
  "omkareshwar-temple",
  "panchvaktra-temple-mandi",
  "pashupatinath-temple-mandsaur",
  "patan-devi-temple",
  "prem-mandir-vrindavan",
  "raghunath-temple-jammu",
  "rajarani-temple",
  "ram-mandir-ayodhya",
  "ram-raja-temple-orchha",
  "ramappa-temple",
  "salasar-balaji-temple",
  "sankat-mochan-hanuman-temple",
  "satyanarayana-swamy-temple-annavaram",
  "shankaracharya-temple",
  "sharda-devi-temple-maihar",
  "shree-saibaba-samadhi-mandir",
  "shrinathji-temple-nathdwara",
  "siddhivinayak-temple-mumbai",
  "sita-ramachandra-swamy-bhadrachalam",
  "somnath-temple",
  "sri-lakshmi-narasimha-swamy-yadagirigutta",
  "sri-mallikarjuna-swamy-temple-srisailam",
  "sri-mayapur-chandrodaya-mandir",
  "taraknath-temple-tarakeswar",
  "tarapith-temple",
  "thousand-pillar-temple",
  "tirumala-venkateswara-temple",
  "trimbakeshwar-temple",
  "vaishno-devi-temple",
  "varaha-lakshmi-narasimha-temple-simhachalam",
  "varasidhi-vinayaka-temple-kanipakam",
  "veerabhadra-temple-lepakshi",
  "vindhyavasini-temple",
  "vishnupad-temple",
  "vitthal-rukmini-temple-pandharpur",
  "yaganti-uma-maheswara-temple",
];

// KAN-76 Wave D (16 more photo-pending temples). --all-packs fails if any
// of these folders are missing.
const WAVE_D_KAN76_PACKS = [
  "ajgaibinath-temple",
  "amarnath-cave-temple",
  "bade-hanuman-ji-temple-prayagraj",
  "chamunda-devi-temple-kangra",
  "hanuman-garhi-ayodhya",
  "kanaka-durga-temple",
  "kanyakumari-bhagavathi-amman-temple",
  "kashi-vishwanath-temple",
  "keesaragutta-temple",
  "krishna-janmabhoomi-temple",
  "maa-taratarini-temple",
  "mannarsala-sree-nagaraja-temple",
  "matangeshwar-temple",
  "padmavathi-temple-tiruchanur",
  "ranchhodraiji-temple-dakor",
  "sakshi-gopal-temple",
];

// Pack folder / temple_slug → Seed templeDocumentId when the sample name
// omits the city.
const SEED_DOCUMENT_ID_BY_PACK_SLUG = {
  "cheluvanarayana-swamy-temple-melukote": "cheluvanarayana-swamy-temple",
  "sri-ranganathaswamy-temple-srirangam": "sri-ranganathaswamy-temple",
  "dhandayuthapani-swamy-temple-palani": "dhandayuthapani-swamy-temple",
  "subramanya-swamy-temple-thiruchendur": "subramanya-swamy-temple",
  "jambukeswarar-temple-thiruvanaikaval": "jambukeswarar-temple",
  "thyagaraja-temple-tiruvarur": "thyagaraja-temple",
  "nellaiappar-temple-tirunelveli": "nellaiappar-temple",
  // KAN-76 Wave C
  "baijnath-temple-himachal": "baijnath-temple",
  "bhadrakali-temple-warangal": "bhadrakali-temple",
  "bhimakali-temple-sarahan": "bhimakali-temple",
  "birla-mandir-jaipur": "birla-mandir-lakshmi-narayan-temple",
  "birla-mandir-kolkata": "birla-mandir",
  "brahma-temple-pushkar": "brahma-temple",
  "gnana-saraswati-temple-basara": "gnana-saraswati-temple",
  "govind-dev-ji-temple-jaipur": "govind-dev-ji-temple",
  "harsiddhi-temple-ujjain": "harsiddhi-temple",
  "jagannath-temple-puri": "jagannath-temple",
  "jogulamba-temple-alampur": "jogulamba-temple",
  "kalika-mata-temple-pavagadh": "kalika-mata-temple",
  "kapil-muni-temple-gangasagar": "kapil-muni-temple",
  "karni-mata-temple-deshnok": "karni-mata-temple",
  "lakshmana-temple-khajuraho": "lakshmana-temple",
  "lakshmi-narayan-temple-chamba": "lakshmi-narayan-temple",
  "mahalakshmi-temple-mumbai": "mahalakshmi-temple",
  "mahavir-mandir-patna": "mahavir-mandir",
  "naina-devi-temple-bilaspur": "naina-devi-temple",
  "panchvaktra-temple-mandi": "panchvaktra-temple",
  "pashupatinath-temple-mandsaur": "pashupatinath-temple",
  "prem-mandir-vrindavan": "prem-mandir",
  "raghunath-temple-jammu": "raghunath-temple",
  "ram-mandir-ayodhya": "ram-mandir-shri-ram-janmabhoomi-temple",
  "ram-raja-temple-orchha": "ram-raja-temple",
  "ramappa-temple": "ramappa-temple-rudreshwara",
  "salasar-balaji-temple": "salasar-balaji",
  "satyanarayana-swamy-temple-annavaram": "satyanarayana-swamy-temple",
  "shrinathji-temple-nathdwara": "shrinathji-temple",
  "siddhivinayak-temple-mumbai": "siddhivinayak-temple",
  "sita-ramachandra-swamy-bhadrachalam": "sita-ramachandra-swamy-temple",
  "sri-lakshmi-narasimha-swamy-yadagirigutta": "sri-lakshmi-narasimha-swamy-temple",
  "sri-mallikarjuna-swamy-temple-srisailam": "sri-mallikarjuna-swamy-temple",
  "sri-mayapur-chandrodaya-mandir": "sri-mayapur-chandrodaya-mandir-iskcon-mayapur",
  "taraknath-temple-tarakeswar": "taraknath-temple",
  "varaha-lakshmi-narasimha-temple-simhachalam": "varaha-lakshmi-narasimha-temple",
  "varasidhi-vinayaka-temple-kanipakam": "varasidhi-vinayaka-temple",
  "veerabhadra-temple-lepakshi": "veerabhadra-temple",
  "vitthal-rukmini-temple-pandharpur": "vitthal-rukmini-temple",
  // KAN-76 Wave D
  "bade-hanuman-ji-temple-prayagraj": "bade-hanuman-ji-temple-lete-hanuman",
  "chamunda-devi-temple-kangra": "chamunda-devi-temple",
  "hanuman-garhi-ayodhya": "hanuman-garhi",
  "padmavathi-temple-tiruchanur": "padmavathi-temple",
  "ranchhodraiji-temple-dakor": "ranchhodraiji-temple",
};

function resolveSeedDocId(packDir, manifest, docIdOverride) {
  if (docIdOverride) return docIdOverride;
  const packSlug = manifest.temple_slug || basename(packDir);
  if (SEED_DOCUMENT_ID_BY_PACK_SLUG[packSlug]) {
    return SEED_DOCUMENT_ID_BY_PACK_SLUG[packSlug];
  }
  if (manifest.seed_document_id) return manifest.seed_document_id;
  return manifest.temple_slug || manifest.doc_id_hint || basename(packDir);
}

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
                         (includes Karnataka Wave B and TN+Kerala Wave A;
                         fails if one is missing)
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
  // An empty manifest is a held pack (wrong-site frames removed, Research
  // regenerating). Do not invent files and do not fail --all-packs.
  if (photos.length === 0) return [];

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
    const license = photo.license || "";
    resolved.push({
      filename,
      localPath,
      author: photo.author || "",
      license,
      // Enum value. CC0 sources map to CC0. Public domain stays unmapped.
      licence: mapPhotoLicence(license),
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

function contentTypeFor(filename) {
  return filename.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
}

async function uploadFile(bucket, localPath, storagePath, filename) {
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: {
      contentType: contentTypeFor(filename),
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
  const packSlug = manifest.temple_slug || basename(packDir);
  const docId = resolveSeedDocId(packDir, manifest, docIdOverride);
  const photos = resolvePhotos(packDir, manifest);

  console.log("────────────────────────────────────────────────────────────");
  console.log(`Pack       : ${packDir}`);
  console.log(`Temple     : ${manifest.temple_name || docId}`);
  console.log(`Doc id     : ${docId}`);
  if (packSlug !== docId) {
    console.log(
      `Pack slug  : ${packSlug} → Seed temples/${docId} (folder name differs)`
    );
  }
  console.log(`Photos     : ${photos.length} (from manifest.json only)`);

  if (photos.length === 0) {
    console.log(
      "Skipped    : empty pack (wrong-site frames removed; awaiting Research). No upload and no Firestore patch."
    );
    return {
      docId,
      imageUrl: "",
      images: [],
      photos: [],
      uploaded: false,
      skipped: true,
    };
  }

  if (dryRun) {
    for (const photo of photos) {
      const storagePath = `temples/${docId}/${photo.filename}`;
      console.log(`• ${photo.filename}`);
      console.log(`    → gs://${bucketName}/${storagePath}`);
      console.log(
        `    license: ${photo.license || "(none)"} → ${photo.licence || "(unmapped)"} / ${photo.author || "(unknown)"}`
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
      const url = await uploadFile(
        bucket,
        photo.localPath,
        storagePath,
        photo.filename
      );
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
      // imageUrl + images only. photos[] is not backfilled onto existing docs.
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

  if (opts.allPacks) {
    const present = new Set(packDirs.map((dir) => basename(dir)));
    const missingWaveB = WAVE_B_KARNATAKA_PACKS.filter(
      (slug) => !present.has(slug)
    );
    const missingWaveA = WAVE_A_TN_KL_PACKS.filter((slug) => !present.has(slug));
    const missingWaveC = WAVE_C_KAN76_PACKS.filter((slug) => !present.has(slug));
    const missingWaveD = WAVE_D_KAN76_PACKS.filter((slug) => !present.has(slug));
    if (missingWaveD.length > 0) {
      console.error(
        "✖  --all-packs is missing KAN-76 Wave D packs:\n   " +
          missingWaveD.join("\n   ")
      );
    }
    if (missingWaveC.length > 0) {
      console.error(
        "✖  --all-packs is missing KAN-76 Wave C packs:\n   " +
          missingWaveC.join("\n   ")
      );
    }
    if (
      missingWaveB.length > 0 ||
      missingWaveA.length > 0 ||
      missingWaveC.length > 0 ||
      missingWaveD.length > 0
    ) {
      if (missingWaveB.length > 0) {
        console.error(
          "✖  --all-packs is missing Karnataka Wave B packs:\n   " +
            missingWaveB.join("\n   ")
        );
      }
      if (missingWaveA.length > 0) {
        console.error(
          "✖  --all-packs is missing Tamil Nadu + Kerala Wave A packs:\n   " +
            missingWaveA.join("\n   ")
        );
      }
      process.exit(1);
    }
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
          licence: p.licence || null,
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
