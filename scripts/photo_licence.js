/**
 * Map a Commons / ATTRIBUTION licence string onto the temple photo enum.
 *
 * Wire values: CC-BY | CC-BY-SA | CC0 | Own | Permission.
 *
 * CC0 (Creative Commons Zero) and public-domain sources map to "CC0"
 * (KAN-49). There is no separate PD value. CC0 matches only as a whole
 * token, so "cc0.5" does not.
 *
 * NC and ND licences are rejected, including fused forms such as
 * "CC-BY-NCSA" and "CC BYNC", and standalone nc / nd / noncommercial /
 * noderiv tokens. They are not stored as CC-BY.
 *
 * Public domain maps to CC0, except US-only claims such as
 * "public domain in the USA only" or "PD-US".
 *
 * @param {unknown} raw
 * @returns {"CC-BY"|"CC-BY-SA"|"CC0"|"Own"|"Permission"|null}
 * @throws {Error} when the source is NC, ND, or US-only public domain.
 */
export function mapPhotoLicence(raw) {
  const text = String(raw ?? "")
    .trim()
    .toLowerCase()
    .replace(/[_]+/g, " ")
    .replace(/\s+/g, " ");
  if (!text) return null;

  const restricted = restrictedLicence(text);
  if (restricted) {
    throw new Error(
      `Rejected licence ${restricted}: "${raw}". NC and ND licences are not accepted.`,
    );
  }

  if (isCc0Source(text)) return "CC0";

  if (isUsOnlyPublicDomain(text)) {
    throw new Error(
      `Rejected licence US-only public domain: "${raw}". A worldwide public-domain or CC0 dedication is required.`,
    );
  }

  if (isPublicDomain(text)) return "CC0";

  if (isCcBySa(text)) return "CC-BY-SA";
  if (isCcBy(text)) return "CC-BY";

  if (text === "own") return "Own";
  if (text === "permission") return "Permission";
  return null;
}

/**
 * Credit stored on a photo. CC-BY and CC-BY-SA keep the Commons version
 * in the credit string ("Author · CC BY-SA 3.0"). Other licences keep the
 * author. No licenceUrl field is added. The result is at most 200
 * characters, matching the Firestore credit cap. Commons usage notes
 * such as the Gonsalves "Feel free to use my photos" text are dropped.
 *
 * @param {unknown} author
 * @param {unknown} licenseRaw
 * @returns {string}
 */
export const MAX_PHOTO_CREDIT_LENGTH = 200;

export function photoCredit(author, licenseRaw) {
  const name = cleanAuthor(author);
  const licence = mapPhotoLicence(licenseRaw);
  if (licence !== "CC-BY" && licence !== "CC-BY-SA") return clampCredit(name);
  const label = ccVersionLabel(licence, licenseRaw);
  if (!name) return clampCredit(label);
  const suffix = ` · ${label}`;
  const full = `${name}${suffix}`;
  if (full.length <= MAX_PHOTO_CREDIT_LENGTH) return full;
  const room = MAX_PHOTO_CREDIT_LENGTH - suffix.length;
  if (room <= 0) return clampCredit(label);
  return `${name.slice(0, room).trimEnd()}${suffix}`;
}

function clampCredit(value) {
  const text = String(value ?? "").trim();
  if (text.length <= MAX_PHOTO_CREDIT_LENGTH) return text;
  return text.slice(0, MAX_PHOTO_CREDIT_LENGTH).trimEnd();
}

/**
 * Keep the person named in a Commons author field and drop the usage note
 * and any bracketed note, such as "(talk)" or a Panoramio user id.
 * A leading `User:` prefix is dropped, so User:Shyam is Shyam.
 * @param {unknown} author
 * @returns {string}
 */
export function cleanAuthor(author) {
  let name = String(author ?? "").replace(/\s+/g, " ").trim();
  if (!name) return "";

  const takenBy = name.match(
    /^(?:this (?:photo|image) was taken by|taken by)\s+(.+)$/i,
  );
      if (takenBy) name = takenBy[1].trim();

      const wikiUser = name.match(/^user:\s*(.+)$/i);
      if (wikiUser) name = wikiUser[1].trim();

      const note = name.search(
    /\.\s+(?:feel free|please\b|i would|otherwise|you may|for my information|contact me|do not)\b/i,
  );
  if (note !== -1) name = name.slice(0, note);

  name = name.replace(/\s*\([^)]*\)/g, " ").replace(/\s+/g, " ").trim();
  name = name.replace(/[,;:\s]+$/g, "").trim();
  // A final dot on an initial ("Chaitra. B. H.") is part of the name.
  if (/\.$/.test(name) && !/(?:^|\s)[A-Za-z]\.$/.test(name)) {
    name = name.replace(/\.+$/g, "").trim();
  }
  return name;
}

function ccVersionLabel(licence, licenseRaw) {
  const base = licence === "CC-BY-SA" ? "CC BY-SA" : "CC BY";
  const version = String(licenseRaw ?? "").match(/(\d+\.\d+)/);
  return version ? `${base} ${version[1]}` : base;
}

/**
 * Reject standalone nc, nd, noncommercial, and noderiv tokens, including
 * fused spellings ("bync", "ncsa", "by-sa-nc").
 * @param {string} text
 * @returns {string|null}
 */
function restrictedLicence(text) {
  const expanded = expandRestrictionTokens(text);
  const nc = /\bnc\b/.test(expanded) || /\bnon commercial\b/.test(expanded);
  const nd = /\bnd\b/.test(expanded) || /\bno deriv/.test(expanded);
  const sa = /\bsa\b/.test(expanded) || /\bshare alike\b/.test(expanded);
  if (nc && nd) return "CC BY-NC-ND";
  if (nc && sa) return "CC BY-NC-SA";
  if (nd) return "CC BY-ND";
  if (nc) return "CC BY-NC";
  return null;
}

function expandRestrictionTokens(text) {
  return text
    .replace(/byncnd/g, "by nc nd")
    .replace(/byndnc/g, "by nd nc")
    .replace(/byncsa/g, "by nc sa")
    .replace(/bynd/g, "by nd")
    .replace(/bync/g, "by nc")
    .replace(/ncnd/g, "nc nd")
    .replace(/ndnc/g, "nd nc")
    .replace(/ncsa/g, "nc sa")
    .replace(/noderivatives/g, "no derivatives")
    .replace(/noderivative/g, "no derivative")
    .replace(/noderivs/g, "no derivs")
    .replace(/noderiv/g, "no deriv")
    .replace(/noncommercial/g, "non commercial")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasCc0Token(text) {
  // A dot after the token is not a boundary, so "cc0.5" does not match.
  return /(?:^|[^a-z0-9])cc0(?=$|[^a-z0-9.])/.test(text);
}

function isCc0Source(text) {
  if (hasCc0Token(text)) return true;
  if (text.includes("creative commons zero") || text.includes("cc-zero")) {
    return true;
  }
  return (
    text.includes("publicdomain/zero") || text.includes("public-domain/zero")
  );
}

function isUsOnlyPublicDomain(text) {
  const spaced = text
    .replace(/[._]/g, " ")
    .replace(/-/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const claimsPd =
    spaced === "pd" ||
    spaced.startsWith("pd ") ||
    /(^|\s)pd(\s|$)/.test(spaced) ||
    spaced.includes("public domain");
  if (!claimsPd) return false;
  if (/\b(usa|us|united states) only\b/.test(spaced)) return true;
  if (/\bin the (usa|u s a|u s|us|united states)\b/.test(spaced)) return true;
  if (/\bpd (us|usa|united states)\b/.test(spaced)) return true;
  if (/\b(usa|us|united states)\b/.test(spaced) && /\bpublic domain\b/.test(spaced)) {
    return true;
  }
  return false;
}

function isPublicDomain(text) {
  const spaced = text.replace(/-/g, " ").replace(/\s+/g, " ").trim();
  if (spaced === "pd" || spaced === "pdm") return true;
  if (spaced.startsWith("pd ") || spaced.startsWith("pdm ")) return true;
  return spaced === "public domain" || spaced.startsWith("public domain ");
}

function isCcBySa(text) {
  return (
    text.includes("cc-by-sa") ||
    text.includes("cc by-sa") ||
    text.includes("cc by sa") ||
    text.includes("creativecommons.org/licenses/by-sa") ||
    /^by-sa\b/.test(text)
  );
}

function isCcBy(text) {
  return (
    text.includes("cc-by") ||
    text.includes("cc by") ||
    text.includes("creativecommons.org/licenses/by/") ||
    text.includes("creativecommons.org/licenses/by ")
  );
}

/**
 * Parse `**License:**` / `**Author:**` rows from an ATTRIBUTION.md file.
 * Does not write Firestore. [licence] is the enum value; [credit] carries
 * the CC version for CC-BY and CC-BY-SA.
 *
 * @param {string} markdown
 * @returns {{file: string, author: string, license: string, licence: string|null, credit: string}[]}
 */
export function parseAttributionLicences(markdown) {
  const entries = [];
  let current = null;
  for (const line of String(markdown).split(/\r?\n/)) {
    const heading = line.match(/^##\s+(.+?)\s*$/);
    if (heading) {
      if (current) entries.push(current);
      current = { file: heading[1], author: "", license: "" };
      continue;
    }
    if (!current) continue;
    const license = line.match(/^-\s+\*\*License:\*\*\s*(.+?)\s*$/i);
    if (license) current.license = license[1];
    const author = line.match(/^-\s+\*\*Author:\*\*\s*(.+?)\s*$/i);
    if (author) current.author = author[1];
  }
  if (current) entries.push(current);
  return entries.map((entry) => ({
    ...entry,
    licence: mapPhotoLicence(entry.license),
    credit: photoCredit(entry.author, entry.license),
  }));
}
