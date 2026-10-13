/**
 * Map a Commons / ATTRIBUTION licence string onto the temple photo enum.
 *
 * Wire values: CC-BY | CC-BY-SA | CC0 | Own | Permission.
 *
 * CC0 (Creative Commons Zero) and public-domain sources map to "CC0"
 * (KAN-49). There is no separate PD value. CC0 matches only as a whole
 * token, so "cc0.5" does not.
 *
 * CC BY-NC, CC BY-NC-SA, CC BY-ND, and CC BY-NC-ND are rejected. They are
 * not stored as CC-BY.
 *
 * @param {unknown} raw
 * @returns {"CC-BY"|"CC-BY-SA"|"CC0"|"Own"|"Permission"|null}
 * @throws {Error} when the source is an NC or ND Creative Commons licence.
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

  if (isCc0Source(text) || isPublicDomain(text)) return "CC0";

  if (isCcBySa(text)) return "CC-BY-SA";
  if (isCcBy(text)) return "CC-BY";

  if (text === "own") return "Own";
  if (text === "permission") return "Permission";
  return null;
}

/**
 * Credit stored on a photo. CC-BY and CC-BY-SA keep the Commons version
 * in the credit string ("Author · CC BY-SA 3.0"). Other licences keep the
 * author. No licenceUrl field is added.
 *
 * @param {unknown} author
 * @param {unknown} licenseRaw
 * @returns {string}
 */
export function photoCredit(author, licenseRaw) {
  const name = String(author ?? "").trim();
  const licence = mapPhotoLicence(licenseRaw);
  if (licence !== "CC-BY" && licence !== "CC-BY-SA") return name;
  const label = ccVersionLabel(licence, licenseRaw);
  return name ? `${name} · ${label}` : label;
}

function ccVersionLabel(licence, licenseRaw) {
  const base = licence === "CC-BY-SA" ? "CC BY-SA" : "CC BY";
  const version = String(licenseRaw ?? "").match(/(\d+\.\d+)/);
  return version ? `${base} ${version[1]}` : base;
}

/** Longer NC/ND names first so "by-nc-sa" is not reported as "by-nc". */
function restrictedLicence(text) {
  const checks = [
    ["CC BY-NC-ND", [/\bby-nc-nd\b/, /\bby nc nd\b/]],
    ["CC BY-NC-SA", [/\bby-nc-sa\b/, /\bby nc sa\b/]],
    ["CC BY-ND", [/\bby-nd\b/, /\bby nd\b/]],
    ["CC BY-NC", [/\bby-nc\b/, /\bby nc\b/]],
  ];
  for (const [label, patterns] of checks) {
    if (patterns.some((pattern) => pattern.test(text))) return label;
  }
  return null;
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
