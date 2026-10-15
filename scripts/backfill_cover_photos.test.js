import assert from "node:assert/strict";
import http from "node:http";
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  PHOTO_LICENCES,
  placeholderAuthor,
  applyCoverPhotoPlans,
  authorizeApply,
  commitCoverPhoto,
  formatCoverPhotoReport,
  main,
  parseArgs,
  bestCreditableFrame,
  assertOneCoverOk,
  coverFrameForPack,
  assertFetchAvailable,
  fetchPublicUrl,
  PUBLIC_CHECK_TIMEOUT_MS,
  ensureCoverFrame,
  persistCoverPhoto,
  planCoverPhoto,
} from "./backfill_cover_photos.js";
import { mapPhotoLicence, photoCredit } from "./photo_licence.js";
import { MIRROR_TEMPLE_IDS } from "./patch_image_url_mirror.js";
import { entryFromTemple } from "./temple_index.js";
import { processPack, resolveSeedDocId } from "./upload_research_pack.js";
import {
  assertStorageAuth,
  STORAGE_AUTH_PREFLIGHT_ERROR,
  STORAGE_AUTH_PROBE,
  useNativeFetchForStorageAuth,
} from "./storage_auth.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..");
const storage =
  "https://storage.googleapis.com/temple-directory-india.firebasestorage.app/temples/virupaksha-temple/01_Hemakuta_Hills.jpg";
const wiki = "https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg";

const indexAdmin = {
  firestore: {
    FieldPath: class FieldPath {
      constructor(...parts) {
        this.parts = parts;
      }
    },
    FieldValue: {
      serverTimestamp: () => "SERVER_TIME",
      increment: (n) => ({ increment: n }),
      delete: () => "DELETE",
    },
  },
};

function memoryDb(read) {
  const ops = [];
  return {
    ops,
    collection(name) {
      return { doc: (id) => ({ path: `${name}/${id}`, id, collection: name }) };
    },
    async runTransaction(fn) {
      const writes = [];
      const result = await fn({
        get: async (ref) => read(ref),
        update: (ref, ...args) => writes.push({ op: "update", path: ref.path, args }),
        set: (ref, data, options) => writes.push({ op: "set", path: ref.path, data, options }),
      });
      if (!result || result.ok === false) {
        assert.equal(writes.length, 0);
        return result;
      }
      ops.push(writes);
      return result;
    },
  };
}

function temple(extra = {}) {
  return {
    id: "virupaksha-temple",
    name: "Virupaksha Temple",
    state: "Karnataka",
    city: "Hampi",
    deity: "Shiva",
    imageUrl: storage,
    images: [
      {
        url: storage,
        credit: "Arjun Dharne · CC BY-SA 4.0",
        licence: "CC-BY-SA",
      },
    ],
    photos: [
      {
        url: "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Hemakuta_Hills.jpg/1280px-Hemakuta_Hills.jpg",
        credit: "Someone else",
        licence: "CC-BY",
        order: 0,
      },
    ],
    ...extra,
  };
}

test("a storage cover copies the credit and licence already on the doc", () => {
  const plan = planCoverPhoto(temple());
  assert.equal(plan.action, "add");
  assert.deepEqual(plan.photo, {
    url: storage,
    credit: "Arjun Dharne · CC BY-SA 4.0",
    licence: "CC-BY-SA",
    order: 0,
  });
  assert.equal(plan.photos[0], plan.photo);
  assert.equal(plan.photos[1].url, temple().photos[0].url);
  assert.equal(plan.photos[1].credit, "Someone else");
  assert.equal(plan.photos[1].order, 1);
  assert.equal(plan.photos.length, 2);
});

test("a different file's credit is not copied onto the cover", () => {
  const unmatched =
    "https://storage.googleapis.com/temple-directory-india.firebasestorage.app/temples/virupaksha-temple/image_1.jpg";
  const plan = planCoverPhoto(
    temple({
      imageUrl: unmatched,
      photos: [{ url: wiki, credit: "Someone", licence: "CC-BY", order: 0 }],
      images: [{ url: wiki, credit: "Someone", licence: "CC-BY" }],
    }),
  );
  assert.equal(plan.action, "skip");
  assert.equal(plan.reason, "no-matching-credit");
  assert.equal(plan.photo, undefined);
  const unrelated = planCoverPhoto(
    temple({
      imageUrl: unmatched,
      photos: [],
      images: [
        {
          url: wiki,
          source: "https://example.com/not-the-cover.jpg",
          credit: "Someone",
          licence: "CC-BY",
        },
      ],
    }),
  );
  assert.equal(unrelated.reason, "no-matching-credit");
  assert.notEqual(unrelated.photo?.credit, "Someone");
});

test("a recorded mirror source can supply the cover's own credit", () => {
  const plan = planCoverPhoto(
    temple({
      photos: [{ url: wiki, credit: "Someone", licence: "CC-BY", order: 0 }],
      images: [
        {
          url: wiki,
          mirroredFrom: storage,
          credit: "Sanu",
          licence: "Own",
        },
      ],
    }),
  );
  assert.equal(plan.action, "add");
  assert.equal(plan.photo.url, storage);
  assert.equal(plan.photo.credit, "Sanu");
  assert.equal(plan.photo.licence, "Own");
  assert.notEqual(plan.photo.credit, "Someone");
});

function mirrorUrl(id, filename) {
  return `https://storage.googleapis.com/temple-directory-india.firebasestorage.app/temples/${id}/${filename}`;
}

function packCovers() {
  const root = resolve(repoRoot, "tools/photo-packs");
  const byId = new Map();
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const packDir = resolve(root, entry.name);
    const manifestPath = resolve(packDir, "manifest.json");
    if (!existsSync(manifestPath)) continue;
    const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    const id = resolveSeedDocId(packDir, manifest, null);
    const photos = Array.isArray(manifest.photos) ? manifest.photos : [];
    if (!id || photos.length === 0) continue;
    byId.set(id, photos);
  }
  return byId;
}

test("a mirrored storage cover takes credit from that pack frame only", () => {
  const packs = packCovers();
  const hemakuta = mirrorUrl("virupaksha-temple", "01_Hemakuta_Hills.jpg");
  const mirrored = planCoverPhoto(
    temple({
      imageUrl: hemakuta,
      photos: [{ url: wiki, credit: "Someone", licence: "CC-BY", order: 0 }],
      images: [hemakuta],
    }),
  );
  assert.equal(mirrored.action, "add");
  assert.equal(mirrored.photo.url, hemakuta);
  assert.equal(mirrored.photo.credit, "Arjun Dharne · CC BY-SA 4.0");
  assert.equal(mirrored.photo.licence, "CC-BY-SA");
  assert.notEqual(mirrored.photo.credit, "Someone");
  assert.notEqual(mirrored.photo.credit, "Ingo Mehling · CC BY-SA 4.0");

  const second = planCoverPhoto(
    temple({
      imageUrl: mirrorUrl("virupaksha-temple", "02_Virupaksha_-_Hemakuta_Hill_-_1.jpg"),
      photos: [],
      images: [],
    }),
  );
  assert.equal(second.photo.credit, "Ingo Mehling · CC BY-SA 4.0");
  assert.notEqual(second.photo.credit, mirrored.photo.credit);

  const meenakshi = planCoverPhoto({
    id: "meenakshi-amman-temple",
    name: "Meenakshi Amman Temple",
    state: "Tamil Nadu",
    imageUrl: mirrorUrl(
      "meenakshi-amman-temple",
      "01_Meenakshi_Amman_Temple_-_Gateway_Tower_Madurai.jpg",
    ),
    photos: [],
    images: [],
  });
  assert.equal(meenakshi.action, "add");
  assert.equal(meenakshi.photo.credit, "Viswa2625 · CC BY-SA 3.0");
  assert.equal(meenakshi.photo.licence, "CC-BY-SA");

  const firebase = planCoverPhoto(
    temple({
      imageUrl:
        "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fvirupaksha-temple%2F01_Hemakuta_Hills.jpg?alt=media&token=abc",
      photos: [],
      images: [],
    }),
  );
  assert.equal(firebase.action, "add");
  assert.equal(firebase.photo.credit, "Arjun Dharne · CC BY-SA 4.0");
  assert.equal(firebase.photo.licence, "CC-BY-SA");

  const places = planCoverPhoto(
    temple({
      imageUrl: mirrorUrl("virupaksha-temple", "image_1.jpg"),
      photos: [],
      images: [],
    }),
  );
  assert.equal(places.reason, "no-matching-credit");

  const otherTemple = planCoverPhoto({
    id: "meenakshi-amman-temple",
    imageUrl: hemakuta,
    photos: [],
    images: [],
  });
  assert.equal(otherTemple.reason, "no-matching-credit");

  const stored = planCoverPhoto(
    temple({
      imageUrl: hemakuta,
      photos: [],
      images: [{ url: hemakuta, credit: "Stored", licence: "Permission" }],
    }),
  );
  assert.equal(stored.photo.credit, "Stored");
  assert.equal(stored.photo.licence, "Permission");

  const sourceUrl =
    "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Hemakuta_Hills.jpg/1280px-Hemakuta_Hills.jpg";
  const fromSource = planCoverPhoto(
    temple({
      imageUrl: hemakuta,
      photos: [{ url: wiki, credit: "Someone", licence: "CC-BY", order: 0 }],
      images: [{ url: `${sourceUrl}?utm_source=commons`, credit: "Sanu", licence: "Own" }],
    }),
  );
  assert.equal(fromSource.photo.credit, "Sanu");
  assert.equal(fromSource.photo.licence, "Own");
  const badSourceLicence = planCoverPhoto(
    temple({
      imageUrl: hemakuta,
      photos: [],
      images: [{ url: sourceUrl, credit: "Sanu", licence: "CC BY-SA 4.0" }],
    }),
  );
  assert.equal(badSourceLicence.reason, "licence");

  let added = 0;
  for (const id of MIRROR_TEMPLE_IDS) {
    const photos = packs.get(id);
    if (!photos) {
      const skipped = planCoverPhoto({
        id,
        imageUrl: mirrorUrl(id, "image_1.jpg"),
        photos: [],
        images: [],
      });
      assert.equal(skipped.reason, "no-matching-credit", id);
      continue;
    }
    const cover = photos[0];
    const plan = planCoverPhoto({
      id,
      state: "Karnataka",
      imageUrl: mirrorUrl(id, cover.filename),
      photos: [],
      images: [mirrorUrl(id, cover.filename)],
    });
    if (placeholderAuthor(cover.author)) {
      assert.equal(plan.action, "skip", id);
      assert.equal(plan.reason, "no-credit", id);
      assert.equal(plan.photo, undefined, id);
      continue;
    }
    assert.equal(plan.action, "add", id);
    assert.equal(plan.photo.credit, photoCredit(cover.author, cover.license), id);
    assert.equal(plan.photo.licence, mapPhotoLicence(cover.license), id);
    assert.ok(PHOTO_LICENCES.includes(plan.photo.licence), id);
    if (photos[1]) {
      const other = photoCredit(photos[1].author, photos[1].license);
      if (other !== plan.photo.credit) assert.notEqual(plan.photo.credit, other, id);
    }
    added += 1;
  }
  assert.equal(MIRROR_TEMPLE_IDS.length, 30);
  assert.equal(added, 28);
  assert.equal(packs.has("anjengo-sree-durga-devi-temple"), false);
});

test("a placeholder pack author is no-credit, and another bucket does not match", () => {
  assert.equal(placeholderAuthor(""), true);
  assert.equal(placeholderAuthor("   "), true);
  assert.equal(placeholderAuthor("Unknown author"), true);
  assert.equal(placeholderAuthor("Unknown authorUnknown author"), true);
  assert.equal(placeholderAuthor("Unknown authorUnknown authorUnknown author"), true);
  assert.equal(placeholderAuthor("UNKNOWN AUTHOR unknown author"), true);
  assert.equal(placeholderAuthor("Unknown"), true);
  assert.equal(placeholderAuthor("unknown"), true);
  assert.equal(placeholderAuthor("Unknown artist"), true);
  assert.equal(placeholderAuthor("Unknown artistUnknown artist"), true);
  assert.equal(placeholderAuthor("Unknown artist Unknown artist"), true);
  assert.equal(placeholderAuthor("unknown photographer"), true);
  assert.equal(placeholderAuthor("Unknown photographerUnknown photographer"), true);
  assert.equal(placeholderAuthor("Unknown (KW23 series on Commons)"), true);
  assert.equal(placeholderAuthor("unknown (note)"), true);
  assert.equal(placeholderAuthor("Ms Sarah Welch"), false);
  assert.equal(placeholderAuthor("Unknown author, Ms Sarah Welch"), false);
  assert.equal(placeholderAuthor("Anonymous0006"), false);
  assert.equal(placeholderAuthor("Rajesh Unknown"), false);

  const filename =
    "01_The_Temples_of_Raghunath_Jammu_India_ca.1875-ca.1940_imp-cswc-GB-237-C.jpg";
  const plan = planCoverPhoto({
    id: "raghunath-temple",
    imageUrl: mirrorUrl("raghunath-temple", filename),
    photos: [],
    images: [],
  });
  assert.equal(plan.action, "skip");
  assert.equal(plan.reason, "no-credit");
  assert.equal(plan.photo, undefined);

  const second = planCoverPhoto({
    id: "raghunath-temple",
    imageUrl: mirrorUrl(
      "raghunath-temple",
      "02_12th-century_Samaveda_samhita_and_brahmanam_Aranyaganam_Prapathaka_1-6.jpg",
    ),
    photos: [],
    images: [],
  });
  assert.equal(second.action, "add");
  assert.equal(second.photo.credit, "Ms Sarah Welch · CC BY-SA 4.0");
  assert.equal(second.photo.licence, "CC-BY-SA");

  const otherBucket = planCoverPhoto(
    temple({
      imageUrl:
        "https://storage.googleapis.com/bucket/temples/virupaksha-temple/01_Hemakuta_Hills.jpg",
      photos: [],
      images: [],
    }),
  );
  assert.equal(otherBucket.reason, "no-matching-credit");
  assert.equal(otherBucket.photo, undefined);

  const appspot = planCoverPhoto(
    temple({
      imageUrl:
        "https://storage.googleapis.com/temple-directory-india.appspot.com/temples/virupaksha-temple/01_Hemakuta_Hills.jpg",
      photos: [],
      images: [],
    }),
  );
  assert.equal(appspot.action, "add");
  assert.equal(appspot.photo.credit, "Arjun Dharne · CC BY-SA 4.0");
});

test("unknown, unknown artist, and Unknown (note) pack frames are no-credit", () => {
  const skipped = [
    ["shrinathji-temple", "02_Nathdwara_srinathji.jpg"],
    ["gnana-saraswati-temple", "05_Basara-ghat.jpg"],
    ["mahakaleshwar-temple", "04_Mahakaleshwar_Ujjain.jpg"],
    ["mehandipur-balaji-temple", "02_Mehandipur_Balaji_idol.jpg"],
    ["mahabaleshwar-temple-gokarna", "01_KW23-0751-Gokarna-AdiGokarna-Front1_3D.jpg"],
    ["mahabaleshwar-temple-gokarna", "02_KW23-0752-Gokarna-AdiGokarna-RightFront2_3D.jpg"],
    ["mahabaleshwar-temple-gokarna", "03_KW23-0754-Gokarna-AdiGokarna-FrontFull4_3D.jpg"],
  ];
  for (const [id, filename] of skipped) {
    const plan = planCoverPhoto({
      id,
      imageUrl: mirrorUrl(id, filename),
      photos: [],
      images: [],
    });
    assert.equal(plan.action, "skip", `${id} ${filename}`);
    assert.equal(plan.reason, "no-credit", `${id} ${filename}`);
    assert.equal(plan.photo, undefined, `${id} ${filename}`);
  }

  const painter = planCoverPhoto({
    id: "shrinathji-temple",
    imageUrl: mirrorUrl("shrinathji-temple", "01_Painter_at_work_Nathdwara.jpg"),
    photos: [],
    images: [],
  });
  assert.equal(painter.action, "add");
  assert.equal(painter.photo.credit, "Prakhar Amba · CC BY 2.0");

  const entry = planCoverPhoto({
    id: "mahabaleshwar-temple-gokarna",
    imageUrl: mirrorUrl(
      "mahabaleshwar-temple-gokarna",
      "04_Main_entry_to_the_Mahabaleshwar_Temple_at_Gokaran.jpg",
    ),
    photos: [],
    images: [],
  });
  assert.equal(entry.action, "add");
  assert.equal(entry.photo.credit, "Nvvchar · CC BY-SA 3.0");
  assert.equal(entry.photo.licence, "CC-BY-SA");
});

test("See Commons and other non-name authors are no-credit", () => {
  for (const author of [
    "See Commons file page",
    "see source",
    "SEE the file page",
    "See description",
    "See below",
    "Own work",
    "OWN WORK",
    "Self",
    "SELF",
    "Self-photographed",
    "self photographed",
    "N/A",
    "n/a",
    "-",
    "?",
    "various",
    "author",
    "Author",
    "Myself",
    "Wikimedia Commons",
    "Commons",
    "public domain",
    "https://commons.wikimedia.org/wiki/File:Example.jpg",
    "http://example.com/a.jpg",
    "www.example.com/a.jpg",
  ]) {
    assert.equal(placeholderAuthor(author), true, author);
  }
  assert.equal(placeholderAuthor("Seetharaman"), false);
  assert.equal(placeholderAuthor("See"), false);
  assert.equal(placeholderAuthor("See Kumar"), false);
  assert.equal(placeholderAuthor("Anonymous0006"), false);
  assert.equal(placeholderAuthor("Rajesh Unknown"), false);
  assert.equal(placeholderAuthor("Shanmugamp7"), false);
  assert.equal(placeholderAuthor("Government of Odisha"), false);

  const skipped = [
    ["talakaveri-temple", "01_Thala_Cauvery__18125847938_.jpg"],
    ["talakaveri-temple", "02_Thalakauvery-hillview-panorama.jpg"],
    ["talakaveri-temple", "03_Talacauvery_panorama.jpg"],
    ["talakaveri-temple", "06_Hills_surrounding_Thalakaveri.jpg"],
  ];
  for (const [id, filename] of skipped) {
    const plan = planCoverPhoto({
      id,
      imageUrl: mirrorUrl(id, filename),
      photos: [],
      images: [],
    });
    assert.equal(plan.action, "skip", `${id} ${filename}`);
    assert.equal(plan.reason, "no-credit", `${id} ${filename}`);
    assert.equal(plan.photo, undefined, `${id} ${filename}`);
  }

  const tank = planCoverPhoto({
    id: "talakaveri-temple",
    imageUrl: mirrorUrl("talakaveri-temple", "04_Talakaveri_temple_tank_01.jpg"),
    photos: [],
    images: [],
  });
  assert.equal(tank.action, "add");
  assert.equal(tank.photo.credit, "Shanmugamp7 · CC BY-SA 3.0");
});

test("bracket notes are stripped and the author name is kept", () => {
  const vaishno = planCoverPhoto({
    id: "vaishno-devi-temple",
    imageUrl: mirrorUrl("vaishno-devi-temple", "05_Vaishno_Devi_Bhabon_-_panoramio.jpg"),
    photos: [],
    images: [],
  });
  assert.equal(vaishno.action, "add");
  assert.equal(vaishno.photo.credit, "Tapan Kumar Debnath · CC BY-SA 3.0");
  assert.equal(vaishno.photo.credit.includes("…"), false);
  assert.equal(vaishno.photo.credit.includes("Panoramio"), false);

  const swamimalai = planCoverPhoto({
    id: "swamimalai-murugan-temple",
    imageUrl: mirrorUrl("swamimalai-murugan-temple", "01_Swamimalai_Murugan_Temple.jpg"),
    photos: [],
    images: [],
  });
  assert.equal(swamimalai.action, "add");
  assert.equal(swamimalai.photo.credit, "Ravichandar84 · CC BY-SA 3.0");
  assert.equal(swamimalai.photo.credit.includes("Wikipedia"), false);

  const khatushyam = planCoverPhoto({
    id: "khatushyam-temple",
    imageUrl: mirrorUrl("khatushyam-temple", "04_Khatushyamji_Pad_Yatra_from_Kota.jpg"),
    photos: [],
    images: [],
  });
  assert.equal(khatushyam.action, "add");
  assert.equal(khatushyam.photo.credit, "Shyam · CC BY-SA 2.5");

  const chaitra = planCoverPhoto({
    id: "annapoorneshwari-temple-horanadu",
    imageUrl: mirrorUrl(
      "annapoorneshwari-temple-horanadu",
      "02_Horanadu_Annapurneshwari_Temple.jpg",
    ),
    photos: [],
    images: [],
  });
  assert.equal(chaitra.action, "add");
  assert.equal(chaitra.photo.credit, "Chaitra. B. H. · CC BY-SA 4.0");
});

test("a prepended cover renumbers every photo from the array index", () => {
  const plan = planCoverPhoto(
    temple({
      photos: [
        {
          url: wiki,
          credit: "Arjun Dharne · CC BY-SA 4.0",
          licence: "CC-BY-SA",
          order: 0,
        },
        {
          url: `${wiki}?2`,
          credit: "Arjun Dharne · CC BY-SA 4.0",
          licence: "CC-BY-SA",
          order: 4,
        },
      ],
    }),
  );
  assert.equal(plan.action, "add");
  assert.deepEqual(
    plan.photos.map((photo) => photo.order),
    [0, 1, 2],
  );
  assert.equal(plan.photos[0].url, storage);
  assert.equal(plan.photos[2].url, `${wiki}?2`);
});

test("CC0 is already an allowed licence and is copied when the credit is real", () => {
  const rules = readFileSync(resolve(repoRoot, "firestore.rules"), "utf8");
  const model = readFileSync(resolve(repoRoot, "lib/models/photo_licence.dart"), "utf8");
  assert.match(rules, /'CC-BY', 'CC-BY-SA', 'CC0', 'Own', 'Permission'/);
  assert.match(model, /cc0\('CC0'\)/);
  assert.deepEqual(PHOTO_LICENCES, ["CC-BY", "CC-BY-SA", "CC0", "Own", "Permission"]);
  const plan = planCoverPhoto(
    temple({
      photos: [{ url: wiki, credit: "Someone", licence: "CC-BY", order: 0 }],
      images: [{ url: storage, credit: "Author", licence: "CC0" }],
    }),
  );
  assert.equal(plan.action, "add");
  assert.equal(plan.photo.licence, "CC0");
  assert.equal(plan.photo.credit, "Author");
});

test("missing, unmapped, or disagreeing image fields are skipped", () => {
  const stringGallery = planCoverPhoto(temple({ photos: [], images: [storage] }));
  assert.equal(stringGallery.action, "add");
  assert.equal(stringGallery.photo.credit, "Arjun Dharne · CC BY-SA 4.0");
  assert.equal(
    planCoverPhoto(
      temple({
        imageUrl: "https://storage.googleapis.com/bucket/temples/virupaksha-temple/image_9.jpg",
        photos: [],
        images: ["https://storage.googleapis.com/bucket/temples/virupaksha-temple/image_9.jpg"],
      }),
    ).reason,
    "no-matching-credit",
  );
  assert.equal(
    planCoverPhoto(
      temple({
        photos: [],
        images: [{ url: storage, credit: "  ", licence: "CC0" }],
      }),
    ).reason,
    "no-credit",
  );
  assert.equal(
    planCoverPhoto(
      temple({
        photos: [],
        images: [{ url: storage, credit: "Author", licence: "CC BY-SA 4.0" }],
      }),
    ).reason,
    "licence",
  );
  assert.equal(
    planCoverPhoto(
      temple({
        photos: [],
        images: [
          { url: storage, credit: "One", licence: "CC-BY" },
          { url: storage, sourceUrl: storage, credit: "Two", licence: "CC0" },
        ],
      }),
    ).reason,
    "ambiguous",
  );
  const agreed = planCoverPhoto(
    temple({
      photos: [
        { url: wiki, credit: "Other", licence: "CC-BY", order: 0 },
        { url: `${wiki}?2`, credit: "Other", licence: "CC-BY", order: 1 },
      ],
      images: [
        { url: storage, credit: "Author", licence: "Own" },
        { url: wiki, source_url: storage, credit: "Author", licence: "Own" },
      ],
    }),
  );
  assert.equal(agreed.action, "add");
  assert.equal(agreed.photo.licence, "Own");
  assert.equal(agreed.photo.credit, "Author");
});

test("attribution can come from an images object and is not invented", () => {
  const plan = planCoverPhoto(
    temple({
      photos: [],
      images: [{ url: storage, credit: "Sanu", licence: "Permission" }],
    }),
  );
  assert.equal(plan.action, "add");
  assert.equal(plan.photo.credit, "Sanu");
  assert.equal(plan.photo.licence, "Permission");
  const source = readFileSync(resolve(here, "backfill_cover_photos.js"), "utf8");
  assert.match(source, /PHOTO_LICENCES\.includes\(licence\)/);
  assert.doesNotMatch(source, /licence \|\| ["']CC/);
  assert.doesNotMatch(source, /credit \|\| ["']/);
});

test("a matching photo, a full list, and a non-https storage url are not added", () => {
  assert.equal(planCoverPhoto(temple({ photos: [{ url: storage, credit: "A", licence: "CC0", order: 0 }] })).action, "ready");
  assert.equal(planCoverPhoto(temple({ imageUrl: wiki, photos: [] })).action, "ready");
  const full = Array.from({ length: 12 }, (_, order) => ({
    url: `https://example.com/${order}.jpg`,
    credit: "A",
    licence: "CC0",
    order,
  }));
  assert.equal(planCoverPhoto(temple({ photos: full })).reason, "photos-full");
  assert.equal(
    planCoverPhoto(
      temple({
        imageUrl: "gs://bucket/temples/virupaksha-temple/01.jpg",
        photos: [{ url: wiki, credit: "A", licence: "CC0", order: 0 }],
      }),
    ).reason,
    "not-https",
  );
  assert.equal(
    planCoverPhoto(temple({ photos: ["https://example.com/a.jpg"] })).reason,
    "photos-shape",
  );
});

test("dry-run lists ids and does not write", async () => {
  let writes = 0;
  const lines = [];
  const rows = await main(["--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => lines.push(line),
    load: async () => [
      temple(),
      temple({
        id: "vaikom-mahadeva-temple",
        name: "Vaikom",
        photos: [],
        images: [storage],
      }),
      temple({
        id: "sringeri-sharada-peetham",
        photos: [],
        images: [{ url: storage, credit: "A", licence: "CC BY" }],
      }),
    ],
    write: async () => {
      writes += 1;
    },
  });
  assert.equal(writes, 0);
  assert.equal(rows.find((row) => row.id === "virupaksha-temple").result, "would-add");
  assert.equal(rows.find((row) => row.id === "vaikom-mahadeva-temple").reason, "no-matching-credit");
  assert.equal(rows.find((row) => row.id === "sringeri-sharada-peetham").reason, "licence");
  const report = lines.join("\n");
  assert.match(report, /added: 1/);
  assert.match(report, /would-add virupaksha-temple/);
  assert.match(report, /skipped: 2/);
  assert.match(report, /skip vaikom-mahadeva-temple no-matching-credit/);
  assert.match(report, /skip sringeri-sharada-peetham licence/);
  assert.match(report, /Dry-run only/);
  assert.equal(formatCoverPhotoReport(rows).includes("https://"), false);
});

test("apply writes photos and the index from the fresh doc, and skips a changed doc", async () => {
  const fresh = temple({ name: "Fresh Name" });
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const plan = planCoverPhoto(temple());
  const rows = await applyCoverPhotoPlans([plan], {
    dryRun: false,
    write: (item) => persistCoverPhoto(db, item, { admin: indexAdmin }),
  });
  assert.equal(rows[0].result, "added");
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const photos = writes.find((write) => write.path === "temples/virupaksha-temple");
  assert.equal(photos.args[0].photos[0].url, storage);
  assert.equal(photos.args[0].photos[0].licence, "CC-BY-SA");
  assert.equal(photos.args[0].photos[1].credit, "Someone else");
  assert.equal(Object.keys(photos.args[0]).length, 1);
  const index = writes.find((write) => write.path === "temple_index/karnataka");
  assert.equal(index.data.entries["virupaksha-temple"].name, "Fresh Name");
  assert.equal(index.data.entries["virupaksha-temple"].coverThumb, storage);
  assert.equal(index.data.entries["virupaksha-temple"].updatedAt, "SERVER_TIME");
  assert.deepEqual(index.options.mergeFields[0].parts, ["entries", "virupaksha-temple"]);
  const meta = writes.find((write) => write.path === "meta/temple_index");
  assert.equal(meta.data.indexVersion, 1);

  const moved = memoryDb(() => ({
    exists: true,
    id: "virupaksha-temple",
    data: () => ({ ...fresh, imageUrl: wiki }),
  }));
  const skipped = await persistCoverPhoto(moved, plan, { admin: indexAdmin });
  assert.equal(skipped.ok, false);
  assert.equal(skipped.reason, "changed");
  assert.equal(moved.ops.length, 0);
  assert.equal(commitCoverPhoto({ ...fresh, photos: [{ url: storage, credit: "A", licence: "CC0", order: 0 }] }, plan).reason, "already");
});

test("apply leaves meta alone when the index entry did not change", async () => {
  const fresh = temple({ name: "Fresh Name" });
  const plan = planCoverPhoto(temple());
  const committed = commitCoverPhoto(fresh, plan);
  assert.equal(committed.ok, true);
  const expected = entryFromTemple(committed.temple);
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "temple_index") {
      return {
        exists: true,
        id: ref.id,
        data: () => ({ entries: { [fresh.id]: { ...expected, updatedAt: "OLD" } } }),
      };
    }
    if (ref.collection === "meta") {
      return { exists: true, id: ref.id, data: () => ({ indexVersion: 4, shards: {} }) };
    }
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const written = await persistCoverPhoto(db, plan, { admin: indexAdmin });
  assert.equal(written.ok, true);
  assert.equal(written.entryChanged, false);
  const [writes] = db.ops;
  assert.equal(writes.some((write) => write.path.startsWith("meta/")), false);
  assert.equal(writes.some((write) => write.path.startsWith("temple_index/")), false);
  const photos = writes.find((write) => write.path === "temples/virupaksha-temple");
  assert.deepEqual(
    photos.args[0].photos.map((photo) => photo.order),
    [0, 1],
  );
});

test("prod apply is refused in CI and without a project", async () => {
  assert.throws(() => parseArgs(["--nope"]), /Unknown argument/);
  await assert.rejects(() => authorizeApply("temple-directory-india", { CI: "true" }), /CI/);
  await assert.rejects(
    () => main(["--apply"], { env: {}, load: async () => [], write: async () => {} }),
    /project/,
  );
  const source = readFileSync(resolve(here, "backfill_cover_photos.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.match(
    source,
    /prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI/,
  );
  assert.doesNotMatch(source, /from an agent/);
});

const replaceOpts = { replaceUncreditedCover: true };

test("replacement is opt-in and only an uncredited image_N cover uses frame 01", async () => {
  const placesUrl = mirrorUrl("virupaksha-temple", "image_1.jpg");
  const placesDoc = {
    id: "virupaksha-temple",
    state: "Karnataka",
    imageUrl: placesUrl,
    photos: [],
    images: [placesUrl],
  };
  const plain = planCoverPhoto(placesDoc);
  assert.equal(plain.action, "skip");
  assert.equal(plain.reason, "no-matching-credit");
  assert.equal(parseArgs(["--dry-run"]).replaceUncreditedCover, false);
  assert.equal(parseArgs(["--apply", "--project", "demo"]).replaceUncreditedCover, false);
  assert.equal(parseArgs(["--replace-uncredited-cover"]).replaceUncreditedCover, true);

  const opted = planCoverPhoto(placesDoc, replaceOpts);
  assert.equal(opted.action, "replace");
  assert.equal(opted.filename, "04_Virupaksha_Temple_Tower.jpg");
  assert.equal(opted.oldImageUrl, placesUrl);

  const excluded = planCoverPhoto(placesDoc, {
    ...replaceOpts,
    exclude: new Set(["virupaksha-temple"]),
  });
  assert.equal(excluded.action, "skip");
  assert.equal(excluded.reason, "excluded");
  assert.equal(excluded.photo, undefined);
  const excludeIds = [
    ...parseArgs(["--exclude", "iskcon-temple-bangalore, virupaksha-temple"]).exclude,
  ].sort();
  assert.deepEqual(excludeIds, ["iskcon-temple-bangalore", "virupaksha-temple"]);
  assert.throws(() => parseArgs(["--exclude"]), /--exclude needs/);

  const credited = planCoverPhoto(
    {
      ...placesDoc,
      photos: [{ url: placesUrl, credit: "Sanu", licence: "CC-BY", order: 0 }],
    },
    replaceOpts,
  );
  assert.equal(credited.action, "ready");
  assert.equal(credited.reason, "already");

  const reported = {
    "1739462400000000.jpg": "not-places-cover",
    "image_1_480.jpg": "not-places-cover",
    "01_Hemakuta_Hills_480.jpg": "not-places-cover",
    "custom-cover.jpg": "not-places-cover",
  };
  for (const [filename, reason] of Object.entries(reported)) {
    const url = mirrorUrl("chamundeshwari-temple", filename);
    const plan = planCoverPhoto(
      {
        id: "chamundeshwari-temple",
        imageUrl: url,
        photos: [],
        images: [url],
      },
      replaceOpts,
    );
    assert.equal(plan.action, "skip", filename);
    assert.equal(plan.reason, reason, filename);
    assert.equal(plan.photo, undefined, filename);
  }

  const gokarnaUrl = mirrorUrl("mahabaleshwar-temple-gokarna", "image_1.jpg");
  const gokarna = planCoverPhoto(
    {
      id: "mahabaleshwar-temple-gokarna",
      imageUrl: gokarnaUrl,
      photos: [],
      images: [gokarnaUrl],
    },
    replaceOpts,
  );
  assert.equal(gokarna.action, "skip");
  assert.equal(gokarna.reason, "no-creditable-frame");
  assert.equal(gokarna.filename, undefined);

  assert.equal(
    bestCreditableFrame([
      { filename: "01_a.jpg", pair: null, coverOk: false },
      { filename: "04_b.jpg", pair: { credit: "N", licence: "CC-BY" }, coverOk: false },
    ]),
    null,
  );
  assert.equal(
    bestCreditableFrame([
      { filename: "01_a.jpg", pair: null, coverOk: false },
      { filename: "04_b.jpg", pair: { credit: "N", licence: "CC-BY" }, coverOk: true },
    ]).filename,
    "04_b.jpg",
  );
  assert.equal(
    bestCreditableFrame(
      [
        { filename: "01_a.jpg", pair: { credit: "N", licence: "CC-BY" }, coverOk: false },
        { filename: "02_b.jpg", pair: { credit: "N", licence: "CC-BY" }, coverOk: false },
      ],
      { noCoverFrame: true },
    ),
    null,
  );
  assert.equal(
    coverFrameForPack({
      temple_slug: "both-flags",
      no_cover_frame: true,
      photos: [
        {
          filename: "01_laundry.jpg",
          author: "Ada Lovelace",
          license: "CC BY 4.0",
        },
        {
          filename: "03_south_side.jpg",
          author: "Ada Lovelace",
          license: "CC BY-SA 4.0",
          cover_ok: true,
        },
      ],
    }),
    null,
  );
  assert.throws(
    () =>
      assertOneCoverOk("two-covers", [
        { filename: "02_a.jpg", cover_ok: true },
        { filename: "04_b.jpg", cover_ok: true },
      ]),
    /two-covers has 2 cover_ok photos \(02_a.jpg, 04_b.jpg\)/,
  );
  assert.throws(
    () =>
      coverFrameForPack({
        temple_slug: "two-covers",
        photos: [
          { filename: "02_a.jpg", author: "Ada Lovelace", license: "CC BY 4.0", cover_ok: true },
          { filename: "04_b.jpg", author: "Ada Lovelace", license: "CC BY 4.0", cover_ok: true },
        ],
      }),
    /two-covers has 2 cover_ok photos/,
  );

  const packDir = mkdtempSync(join(tmpdir(), "two-cover-ok-"));
  try {
    writeFileSync(
      join(packDir, "manifest.json"),
      JSON.stringify({
        temple_slug: "two-covers",
        photos: [
          { filename: "02_a.jpg", cover_ok: true },
          { filename: "04_b.jpg", cover_ok: true },
        ],
      }),
    );
    await assert.rejects(
      () => processPack({ packDir, dryRun: true, bucketName: "temple-directory-india.firebasestorage.app" }),
      /two-covers has 2 cover_ok photos \(02_a.jpg, 04_b.jpg\)/,
    );
  } finally {
    rmSync(packDir, { recursive: true, force: true });
  }
});

test("an uncredited image_N cover is replaced only by a creditable frame 01", () => {
  const stay = {
    "anjengo-sree-durga-devi-temple": "no-wave-pack",
    "mannarsala-sree-nagaraja-temple": "no-wave-pack",
    "meenakshi-amman-temple": "no-wave-pack",
    "shore-temple": "no-wave-pack",
    "mahabaleshwar-temple-gokarna": "no-creditable-frame",
    "chamundeshwari-temple": "not-places-cover",
    "sri-manjunatha-temple-dharmasthala": "no-cover-frame",
    "srikanteshwara-temple-nanjangud": "no-cover-frame",
  };
  const coverFrame = {
    "iskcon-temple-bangalore": "04_ISKON_temple_in_Bengaluru.jpg",
    "guruvayur-sri-krishna-temple": "03_009392022_Guruvayur_temple_Kerala_024.jpg",
    "virupaksha-temple": "04_Virupaksha_Temple_Tower.jpg",
  };
  const plans = [];
  let replaced = 0;
  for (const id of MIRROR_TEMPLE_IDS) {
    const filename = id === "chamundeshwari-temple" ? "1739462400000000.jpg" : "image_1.jpg";
    const url = mirrorUrl(id, filename);
    const plain = planCoverPhoto({
      id,
      imageUrl: url,
      photos: [],
      images: [url],
    });
    assert.notEqual(plain.action, "replace", id);
    const plan = planCoverPhoto(
      {
        id,
        state: "Karnataka",
        imageUrl: url,
        photos: [],
        images: [url, mirrorUrl(id, "image_2.jpg")],
      },
      replaceOpts,
    );
    plans.push(plan);
    if (stay[id]) {
      assert.equal(plan.action, "skip", id);
      assert.equal(plan.reason, stay[id], id);
      assert.equal(plan.photo, undefined, id);
      continue;
    }
    assert.equal(plan.action, "replace", id);
    if (coverFrame[id]) assert.equal(plan.filename, coverFrame[id], id);
    else assert.match(plan.filename, /^01(?:_|\.|$)/, id);
    assert.equal(plan.oldObject, `temples/${id}/${filename}`, id);
    assert.equal(plan.oldImageUrl, url, id);
    assert.equal(plan.imageUrl, mirrorUrl(id, plan.filename), id);
    assert.equal(plan.objectPath, `temples/${id}/${plan.filename}`, id);
    assert.notEqual(plan.objectPath, plan.oldObject, id);
    assert.equal(plan.photos[0].url, plan.imageUrl, id);
    assert.equal(plan.photos[0].order, 0, id);
    assert.ok(plan.photo.credit.length > 0 && plan.photo.credit.length <= 200, id);
    assert.ok(PHOTO_LICENCES.includes(plan.photo.licence), id);
    assert.equal(plan.images[0], plan.imageUrl, id);
    assert.equal(plan.images[1], mirrorUrl(id, "image_2.jpg"), id);
    assert.equal(plan.images.includes(url), false, id);
    assert.equal(plan.upload, "if-missing", id);
    const again = planCoverPhoto({
      id,
      imageUrl: plan.imageUrl,
      photos: plan.photos,
      images: plan.images,
    });
    assert.equal(again.action, "ready", id);
    replaced += 1;
  }
  assert.equal(replaced, 22);
  assert.equal(MIRROR_TEMPLE_IDS.length, 30);

  const otherBucket = planCoverPhoto(
    {
      id: "virupaksha-temple",
      imageUrl: "https://storage.googleapis.com/bucket/temples/virupaksha-temple/image_1.jpg",
      photos: [],
      images: [],
    },
    replaceOpts,
  );
  assert.equal(otherBucket.reason, "no-matching-credit");

  const waveC = planCoverPhoto(
    {
      id: "dwarkadhish-temple",
      imageUrl: mirrorUrl("dwarkadhish-temple", "image_1.jpg"),
      photos: [],
      images: [],
    },
    replaceOpts,
  );
  assert.equal(waveC.action, "skip");
  assert.equal(waveC.reason, "no-wave-pack");

  const report = formatCoverPhotoReport(plans);
  assert.equal(report.includes("https://"), false);
  assert.match(report, /replaced: 22/);
  assert.match(report, /would-replace virupaksha-temple/);
  assert.match(report, /old: temples\/virupaksha-temple\/image_1.jpg/);
  assert.match(report, /new: 04_Virupaksha_Temple_Tower.jpg/);
  assert.match(report, /credit: Krishnakulkarni36 · CC BY-SA 4.0/);
  assert.match(report, /skip sri-manjunatha-temple-dharmasthala no-cover-frame/);
  assert.match(report, /skip srikanteshwara-temple-nanjangud no-cover-frame/);
  assert.match(report, /licence: CC-BY-SA/);
  assert.match(report, /upload: if-missing/);
  assert.match(report, /skip anjengo-sree-durga-devi-temple no-wave-pack/);
  assert.match(report, /skip chamundeshwari-temple not-places-cover/);
  assert.match(report, /skip mahabaleshwar-temple-gokarna no-creditable-frame/);
  assert.match(report, /No Storage uploads/);
});

test("apply uploads a missing frame, writes the cover once, and keeps the old object", async () => {
  const placesUrl = mirrorUrl("virupaksha-temple", "image_1.jpg");
  const fresh = temple({
    imageUrl: placesUrl,
    photos: [],
    images: [placesUrl, mirrorUrl("virupaksha-temple", "image_2.jpg")],
  });
  const plan = planCoverPhoto(fresh, replaceOpts);
  assert.equal(plan.action, "replace");
  assert.equal(planCoverPhoto(fresh).action, "skip");
  const uploads = [];
  const db = memoryDb((ref) => {
    if (ref.collection === "temples") {
      return { exists: true, id: ref.id, data: () => structuredClone(fresh) };
    }
    if (ref.collection === "meta") return { exists: false, id: ref.id, data: () => undefined };
    return { exists: false, id: ref.id, data: () => undefined };
  });
  const rows = await applyCoverPhotoPlans([plan], {
    dryRun: false,
    ensureUploaded: async (item) => {
      uploads.push(item.objectPath);
      return { ok: true, uploaded: true };
    },
    write: (item) => persistCoverPhoto(db, item, { admin: indexAdmin }),
  });
  assert.equal(rows[0].result, "replaced");
  assert.deepEqual(uploads, ["temples/virupaksha-temple/04_Virupaksha_Temple_Tower.jpg"]);
  assert.equal(uploads.includes(plan.oldObject), false);
  assert.equal(db.ops.length, 1);
  const [writes] = db.ops;
  const templeWrite = writes.find((write) => write.path === "temples/virupaksha-temple");
  assert.deepEqual(Object.keys(templeWrite.args[0]).sort(), ["imageUrl", "images", "photos"]);
  assert.equal(templeWrite.args[0].imageUrl, plan.imageUrl);
  assert.deepEqual(templeWrite.args[0].images, plan.images);
  assert.equal(templeWrite.args[0].photos[0].credit, "Krishnakulkarni36 · CC BY-SA 4.0");
  assert.equal(templeWrite.args[0].photos[0].licence, "CC-BY-SA");
  const index = writes.find((write) => write.path === "temple_index/karnataka");
  assert.equal(index.data.entries["virupaksha-temple"].coverThumb, plan.imageUrl);

  const missing = await applyCoverPhotoPlans([plan], {
    dryRun: false,
    ensureUploaded: async () => ({ ok: false, reason: "missing-file" }),
    write: () => {
      throw new Error("write");
    },
  });
  assert.equal(missing[0].result, "skipped");
  assert.equal(missing[0].reason, "missing-file");

  const movedUrl = mirrorUrl("virupaksha-temple", "image_9.jpg");
  const moved = memoryDb(() => ({
    exists: true,
    id: "virupaksha-temple",
    data: () => ({ ...fresh, imageUrl: movedUrl }),
  }));
  const changed = await persistCoverPhoto(moved, plan, { admin: indexAdmin });
  assert.equal(changed.ok, false);
  assert.equal(changed.reason, "changed");
  assert.equal(moved.ops.length, 0);
  assert.equal(commitCoverPhoto({ ...fresh, imageUrl: movedUrl }, plan).reason, "changed");

  assert.equal(plan.imageUrl, plan.photo.url);
  assert.match(plan.imageUrl, /^https:\/\/storage\.googleapis\.com\//);
  const calls = [];
  const checks = [];
  const bucket = {
    file() {
      return {
        async exists() {
          calls.push("exists");
          return [true];
        },
        async getMetadata() {
          calls.push("metadata");
          return [{ metadata: {} }];
        },
        async makePublic() {
          calls.push("public");
        },
        async delete() {
          calls.push("delete");
        },
      };
    },
    async upload() {
      calls.push("upload");
    },
  };
  const present = await ensureCoverFrame(plan, {
    bucket,
    verifyPublic: async (url) => {
      checks.push(url);
      return url === plan.imageUrl;
    },
  });
  assert.equal(present.ok, true);
  assert.equal(present.uploaded, false);
  assert.deepEqual(calls, ["exists"]);
  assert.deepEqual(checks, [plan.imageUrl]);
  assert.equal(checks[0].includes("token="), false);

  const hidden = await ensureCoverFrame(plan, {
    bucket: {
      file() {
        return {
          async exists() {
            return [true];
          },
          async delete() {
            calls.push("delete");
          },
        };
      },
    },
    verifyPublic: async (url) => {
      assert.equal(url, plan.imageUrl);
      return false;
    },
  });
  assert.equal(hidden.ok, false);
  assert.equal(hidden.reason, "not-public");

  const absent = {
    file() {
      return {
        async exists() {
          return [false];
        },
        async makePublic() {
          calls.push("public");
        },
        async delete() {
          calls.push("delete");
        },
      };
    },
    async upload(_local, options) {
      calls.push(`upload:${options.destination}`);
      assert.equal(options.metadata.metadata, undefined);
    },
  };
  const uploaded = await ensureCoverFrame(plan, {
    bucket: absent,
    verifyPublic: async (url) => url === plan.imageUrl,
  });
  assert.equal(uploaded.uploaded, true);
  assert.equal(calls.includes("delete"), false);
  assert.equal(calls.includes(`upload:${plan.objectPath}`), true);
  assert.equal(calls.includes(`upload:${plan.oldObject}`), false);
  assert.equal(calls.includes("public"), true);

  let dryUploads = 0;
  const lines = [];
  await main(["--replace-uncredited-cover", "--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => lines.push(line),
    load: async () => [fresh],
    ensureUploaded: async () => {
      dryUploads += 1;
      return { ok: true };
    },
    write: async () => {
      throw new Error("write");
    },
  });
  assert.equal(dryUploads, 0);
  const report = lines.join("\n");
  assert.match(report, /would-replace virupaksha-temple/);
  assert.match(report, /old: temples\/virupaksha-temple\/image_1.jpg/);
  assert.match(report, /new: 04_Virupaksha_Temple_Tower.jpg/);
  assert.match(report, /credit: Krishnakulkarni36 · CC BY-SA 4.0/);
  assert.match(report, /licence: CC-BY-SA/);
  assert.equal(report.includes("https://"), false);

  let plainWrites = 0;
  const plainLines = [];
  await main(["--apply", "--project", "demo-temple-index"], {
    env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
    log: (line) => plainLines.push(line),
    load: async () => [fresh],
    ensureUploaded: async () => {
      throw new Error("upload");
    },
    write: async () => {
      plainWrites += 1;
    },
  });
  assert.equal(plainWrites, 0);
  assert.match(plainLines.join("\n"), /replaced: 0/);
  assert.match(plainLines.join("\n"), /skip virupaksha-temple no-matching-credit/);
});

test("a public-check network error skips that temple and the next one is still written", async () => {
  const firstUrl = mirrorUrl("virupaksha-temple", "image_1.jpg");
  const secondUrl = mirrorUrl("iskcon-temple-bangalore", "image_1.jpg");
  const first = planCoverPhoto(
    {
      id: "virupaksha-temple",
      state: "Karnataka",
      imageUrl: firstUrl,
      photos: [],
      images: [firstUrl],
    },
    replaceOpts,
  );
  const second = planCoverPhoto(
    {
      id: "iskcon-temple-bangalore",
      state: "Karnataka",
      imageUrl: secondUrl,
      photos: [],
      images: [secondUrl],
    },
    replaceOpts,
  );
  assert.equal(first.action, "replace");
  assert.equal(second.action, "replace");
  const written = [];
  const bucket = {
    file() {
      return {
        async exists() {
          return [true];
        },
        async delete() {
          throw new Error("delete");
        },
      };
    },
  };
  const rows = await applyCoverPhotoPlans([first, second], {
    dryRun: false,
    ensureUploaded: (plan) =>
      ensureCoverFrame(plan, {
        bucket,
        verifyPublic: async (url) => {
          if (url === first.imageUrl) {
            throw new Error("getaddrinfo ENOTFOUND storage.googleapis.com");
          }
          return url === second.imageUrl;
        },
      }),
    write: async (plan) => {
      written.push(plan.id);
      return { ok: true };
    },
  });
  assert.equal(rows[0].id, "virupaksha-temple");
  assert.equal(rows[0].result, "skipped");
  assert.equal(rows[0].reason, "public-check-failed");
  assert.equal(rows[1].id, "iskcon-temple-bangalore");
  assert.equal(rows[1].result, "replaced");
  assert.deepEqual(written, ["iskcon-temple-bangalore"]);
  assert.match(formatCoverPhotoReport(rows, { apply: true }), /skip virupaksha-temple public-check-failed/);
  assert.match(formatCoverPhotoReport(rows, { apply: true }), /replaced iskcon-temple-bangalore/);
});

test("a missing fetch fails before any write, and a hung public check times out", async () => {
  assert.equal(PUBLIC_CHECK_TIMEOUT_MS, 10_000);
  assert.throws(() => assertFetchAvailable(undefined), /no fetch/);
  let loaded = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--replace-uncredited-cover", "--project", "demo-temple-index"], {
        env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
        fetchImpl: undefined,
        load: async () => {
          loaded += 1;
          return [];
        },
        write: async () => {
          throw new Error("write");
        },
      }),
    /no fetch/,
  );
  assert.equal(loaded, 0);

  const placesUrl = mirrorUrl("virupaksha-temple", "image_1.jpg");
  const plan = planCoverPhoto(
    { id: "virupaksha-temple", imageUrl: placesUrl, photos: [], images: [placesUrl] },
    replaceOpts,
  );
  assert.equal(plan.action, "replace");
  let signal;
  const timedOutPromise = applyCoverPhotoPlans([plan], {
    dryRun: false,
    ensureUploaded: (item) =>
      ensureCoverFrame(item, {
        bucket: {
          file() {
            return {
              async exists() {
                return [true];
              },
            };
          },
        },
        fetchImpl: (_url, init) =>
          new Promise((_resolve, reject) => {
            signal = init.signal;
            init.signal.addEventListener("abort", () => {
              const error = new Error("The operation was aborted due to timeout");
              error.name = "TimeoutError";
              reject(error);
            });
          }),
        timeoutMs: 30,
      }),
    write: async () => {
      throw new Error("write");
    },
  });
  await new Promise((resolve) => setTimeout(resolve, 80));
  const timedOut = await timedOutPromise;
  assert.equal(timedOut[0].reason, "public-check-failed");
  assert.equal(signal?.aborted, true);

  const dry = [];
  const warnings = [];
  await main(
    ["--replace-uncredited-cover", "--exclude", "virupaksha-temple,not-a-temple", "--project", "demo"],
    {
      env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
      fetchImpl: undefined,
      log: (line) => dry.push(line),
      warn: (line) => warnings.push(line),
      load: async () => [
        { id: "virupaksha-temple", imageUrl: placesUrl, photos: [], images: [placesUrl] },
      ],
      write: async () => {
        throw new Error("write");
      },
    },
  );
  assert.match(dry.join("\n"), /skip virupaksha-temple excluded/);
  assert.deepEqual(warnings, ["exclude: unknown temple id not-a-temple"]);
});

test("the Storage token request uses native fetch, and a failed exists() stops apply", async () => {
  let Gaxios;
  try {
    Gaxios = createRequire(import.meta.url)("gaxios").Gaxios;
  } catch (error) {
    if (error?.code !== "MODULE_NOT_FOUND") throw error;
  }
  if (Gaxios) {
    assert.equal(useNativeFetchForStorageAuth(), true);
    const calls = [];
    const original = globalThis.fetch;
    globalThis.fetch = async (input) => {
      calls.push(String(input));
      return new Response(JSON.stringify({ access_token: "ya29.test" }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    };
    const server = http.createServer((_req, res) => {
      res.writeHead(200, { "content-type": "application/json" });
      res.end('{"ok":true}');
    });
    await new Promise((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));
    const port = server.address().port;
    try {
      const client = new Gaxios();
      const token = await client.request({
        url: "https://www.googleapis.com/oauth2/v4/token",
        method: "POST",
        responseType: "json",
      });
      assert.equal(token.data.access_token, "ya29.test");
      assert.deepEqual(calls, ["https://www.googleapis.com/oauth2/v4/token"]);
      const local = await client.request({
        url: `http://127.0.0.1:${port}/object`,
        responseType: "json",
      });
      assert.equal(local.data.ok, true);
      assert.deepEqual(calls, ["https://www.googleapis.com/oauth2/v4/token"]);
    } finally {
      globalThis.fetch = original;
      await new Promise((resolveClose) => server.close(resolveClose));
    }
  }

  const seen = [];
  await assertStorageAuth({
    file(path) {
      seen.push(path);
      return { async exists() { return [false]; } };
    },
  });
  assert.deepEqual(seen, [STORAGE_AUTH_PROBE]);
  await assert.rejects(
    () =>
      assertStorageAuth({
        file() {
          return {
            async exists() {
              throw new Error("Premature close");
            },
          };
        },
      }),
    new RegExp(STORAGE_AUTH_PREFLIGHT_ERROR.replace(/[.]/g, "\\.")),
  );

  let writes = 0;
  let loads = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--replace-uncredited-cover", "--project", "demo-temple-index"], {
        env: { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
        storagePreflight: async () => {
          throw new Error(STORAGE_AUTH_PREFLIGHT_ERROR);
        },
        load: async () => {
          loads += 1;
          return [];
        },
        write: async () => {
          writes += 1;
        },
      }),
    /Storage auth preflight failed\. No Firestore write\./,
  );
  assert.equal(writes, 0);
  assert.equal(loads, 0);
});
