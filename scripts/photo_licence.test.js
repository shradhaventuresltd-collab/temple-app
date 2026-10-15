import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

import {
  MAX_PHOTO_CREDIT_LENGTH,
  cleanAuthor,
  mapPhotoLicence,
  parseAttributionLicences,
  photoCredit,
} from "./photo_licence.js";

const here = dirname(fileURLToPath(import.meta.url));

test("CC0 source strings map to CC0", () => {
  for (const raw of [
    "CC0",
    "CC0 1.0",
    "cc0",
    "Creative Commons Zero",
    "CC0 1.0 Universal (Public Domain Dedication)",
    "cc0-1.0",
    "https://creativecommons.org/publicdomain/zero/1.0/",
  ]) {
    assert.equal(mapPhotoLicence(raw), "CC0", raw);
  }
});

test("Public domain maps to CC0", () => {
  for (const raw of ["Public domain", "Public Domain", "PD", "PDM"]) {
    assert.equal(mapPhotoLicence(raw), "CC0", raw);
  }
});

test("CC BY-NC is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BY-NC 4.0"),
    /Rejected licence CC BY-NC:/,
  );
  assert.throws(
    () => mapPhotoLicence("https://creativecommons.org/licenses/by-nc/4.0/"),
    /Rejected licence CC BY-NC:/,
  );
});

test("CC BY-NC-SA is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("BY-NC-SA"),
    /Rejected licence CC BY-NC-SA:/,
  );
  assert.throws(
    () =>
      mapPhotoLicence("https://creativecommons.org/licenses/by-nc-sa/4.0/"),
    /Rejected licence CC BY-NC-SA:/,
  );
});

test("CC BY-ND is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BY-ND 4.0"),
    /Rejected licence CC BY-ND:/,
  );
  assert.throws(
    () => mapPhotoLicence("https://creativecommons.org/licenses/by-nd/4.0/"),
    /Rejected licence CC BY-ND:/,
  );
});

test("CC BY-NC-ND is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BY-NC-ND"),
    /Rejected licence CC BY-NC-ND:/,
  );
  assert.throws(
    () =>
      mapPhotoLicence("https://creativecommons.org/licenses/by-nc-nd/4.0/"),
    /Rejected licence CC BY-NC-ND:/,
  );
});

test("CC BY-SA-NC is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BY-SA-NC 4.0"),
    /Rejected licence CC BY-NC-SA:/,
  );
});

test("CC BY 4.0 NC is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BY 4.0 NC"),
    /Rejected licence CC BY-NC:/,
  );
});

test("CC-BY-NCSA is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC-BY-NCSA"),
    /Rejected licence CC BY-NC-SA:/,
  );
});

test("CC BYNC is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("CC BYNC"),
    /Rejected licence CC BY-NC:/,
  );
});

test("standalone nc is rejected", () => {
  assert.throws(() => mapPhotoLicence("nc"), /Rejected licence CC BY-NC:/);
  assert.throws(() => mapPhotoLicence("NC"), /Rejected licence CC BY-NC:/);
});

test("standalone nd is rejected", () => {
  assert.throws(() => mapPhotoLicence("nd"), /Rejected licence CC BY-ND:/);
  assert.throws(() => mapPhotoLicence("ND"), /Rejected licence CC BY-ND:/);
});

test("noncommercial is rejected", () => {
  assert.throws(
    () => mapPhotoLicence("noncommercial"),
    /Rejected licence CC BY-NC:/,
  );
  assert.throws(
    () => mapPhotoLicence("CC BY-NonCommercial 4.0"),
    /Rejected licence CC BY-NC:/,
  );
});

test("noderiv is rejected", () => {
  assert.throws(() => mapPhotoLicence("noderiv"), /Rejected licence CC BY-ND:/);
  assert.throws(
    () => mapPhotoLicence("CC BY-NoDerivs 4.0"),
    /Rejected licence CC BY-ND:/,
  );
});

test("US-only public domain is rejected", () => {
  for (const raw of [
    "public domain in the USA only",
    "Public domain in the USA only",
    "PD-US",
    "Public domain (US)",
    "public domain in the United States",
  ]) {
    assert.throws(
      () => mapPhotoLicence(raw),
      /Rejected licence US-only public domain:/,
      raw,
    );
  }
});

test("bare by does not map to CC-BY", () => {
  for (const raw of ["by", "BY", "by 4.0"]) {
    assert.equal(mapPhotoLicence(raw), null, raw);
  }
});

test("cc0.5 does not map to CC0", () => {
  assert.equal(mapPhotoLicence("cc0.5"), null);
});

test("CC BY and CC BY-SA stay distinct", () => {
  assert.equal(mapPhotoLicence("CC BY 4.0"), "CC-BY");
  assert.equal(mapPhotoLicence("CC BY-SA 4.0"), "CC-BY-SA");
  assert.equal(mapPhotoLicence("CC-BY-SA"), "CC-BY-SA");
  assert.equal(
    mapPhotoLicence("https://creativecommons.org/licenses/by-sa/3.0"),
    "CC-BY-SA",
  );
  assert.equal(
    mapPhotoLicence("https://creativecommons.org/licenses/by/4.0"),
    "CC-BY",
  );
  assert.equal(mapPhotoLicence("by-sa 4.0"), "CC-BY-SA");
});

test("CC-BY and CC-BY-SA credits keep the version", () => {
  assert.equal(photoCredit("Ada", "CC BY-SA 3.0"), "Ada · CC BY-SA 3.0");
  assert.equal(
    photoCredit("Ada", "https://creativecommons.org/licenses/by-sa/2.0/"),
    "Ada · CC BY-SA 2.0",
  );
  assert.equal(photoCredit("Ada", "CC BY 4.0"), "Ada · CC BY 4.0");
  assert.equal(photoCredit("", "CC BY-SA 3.0"), "CC BY-SA 3.0");
  assert.equal(photoCredit("Ada", "Public domain"), "Ada");
});

test("photoCredit drops the Gonsalves usage note and stays within 200 characters", () => {
  const packs = [
    ["chamundeshwari-temple", "01_"],
    ["srikanteshwara-temple-nanjangud", "02_"],
  ];
  for (const [pack, prefix] of packs) {
    const manifest = JSON.parse(
      readFileSync(
        resolve(here, `../tools/photo-packs/${pack}/manifest.json`),
        "utf8",
      ),
    );
    const photo = manifest.photos.find((entry) =>
      entry.filename.startsWith(prefix),
    );
    assert.ok(photo, `${pack} ${prefix}`);
    assert.ok(photo.author.length > MAX_PHOTO_CREDIT_LENGTH, photo.filename);
    const credit = photoCredit(photo.author, photo.license);
    assert.equal(credit, "Timothy A. Gonsalves · CC BY-SA 4.0");
    assert.ok(credit.length <= MAX_PHOTO_CREDIT_LENGTH);
  }

  assert.equal(cleanAuthor("Chaitra. B. H."), "Chaitra. B. H.");
  assert.equal(photoCredit("Chaitra. B. H.", "CC BY-SA 4.0"), "Chaitra. B. H. · CC BY-SA 4.0");
  assert.equal(
    cleanAuthor("Tapan Kumar Debn… (Panoramio user 4004470, name truncated as on Commons)"),
    "Tapan Kumar Debn…",
  );
  assert.equal(
    photoCredit(
      "Tapan Kumar Debn… (Panoramio user 4004470, name truncated as on Commons)",
      "CC BY-SA 3.0",
    ),
    "Tapan Kumar Debn… · CC BY-SA 3.0",
  );
  assert.equal(
    cleanAuthor(
      "Ravichandar84 (The original uploader was Ravichandar84 at English Wikipedia.)",
    ),
    "Ravichandar84",
  );
  assert.equal(
    photoCredit(
      "Ravichandar84 (The original uploader was Ravichandar84 at English Wikipedia.)",
      "CC BY-SA 3.0",
    ),
    "Ravichandar84 · CC BY-SA 3.0",
  );

  const trimmed = photoCredit("A".repeat(500), "CC BY 4.0");
  assert.ok(trimmed.length <= MAX_PHOTO_CREDIT_LENGTH);
  assert.ok(trimmed.endsWith(" · CC BY 4.0"));
});

test("research pack cache is short because paths are fixed filenames", () => {
  const source = readFileSync(resolve(here, "upload_research_pack.js"), "utf8");
  const cacheLines = source
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("cacheControl:"));
  assert.deepEqual(cacheLines, ['cacheControl: "public, max-age=3600",']);
  const adminUpload = readFileSync(
    resolve(here, "../lib/services/temple_photo_upload.dart"),
    "utf8",
  );
  assert.match(
    adminUpload,
    /cacheControl: 'public, max-age=31536000, immutable'/,
  );
});

test("ATTRIBUTION backfill accepts CC0 and maps Public domain to CC0", () => {
  const cc0Pack = readFileSync(
    resolve(here, "../tools/photo-packs/nataraja-temple/ATTRIBUTION.md"),
    "utf8",
  );
  const cc0Entries = parseAttributionLicences(cc0Pack);
  assert.ok(cc0Entries.some((entry) => entry.licence === "CC0"));

  const mixed = readFileSync(
    resolve(
      here,
      "../tools/photo-packs/kanyakumari-bhagavathi-amman-temple/ATTRIBUTION.md",
    ),
    "utf8",
  );
  const mixedEntries = parseAttributionLicences(mixed);
  assert.ok(mixedEntries.some((entry) => entry.licence === "CC-BY-SA"));
  const publicDomain = mixedEntries.find((entry) =>
    /public domain/i.test(entry.license),
  );
  assert.ok(publicDomain);
  assert.equal(publicDomain.licence, "CC0");
  const bySa = mixedEntries.find((entry) => entry.author === "Parvathisri");
  assert.ok(bySa);
  assert.equal(bySa.credit, "Parvathisri · CC BY-SA 3.0");
});
