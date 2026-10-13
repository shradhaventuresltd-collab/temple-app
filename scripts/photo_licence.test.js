import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

import { mapPhotoLicence, parseAttributionLicences } from "./photo_licence.js";

const here = dirname(fileURLToPath(import.meta.url));

test("CC0 source strings map to CC0", () => {
  for (const raw of [
    "CC0",
    "CC0 1.0",
    "cc0",
    "Creative Commons Zero",
    "CC0 1.0 Universal (Public Domain Dedication)",
    "https://creativecommons.org/publicdomain/zero/1.0/",
  ]) {
    assert.equal(mapPhotoLicence(raw), "CC0", raw);
  }
});

test("Public domain does not map to CC0", () => {
  for (const raw of ["Public domain", "Public Domain", "PD", "PDM"]) {
    assert.equal(mapPhotoLicence(raw), null, raw);
  }
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
});

test("ATTRIBUTION backfill accepts CC0 and leaves Public domain unmapped", () => {
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
  assert.equal(publicDomain.licence, null);
});
