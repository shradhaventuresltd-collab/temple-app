/**
 * Map a Commons / ATTRIBUTION licence string onto the temple photo enum.
 *
 * Wire values: CC-BY | CC-BY-SA | CC0 | Own | Permission.
 *
 * CC0 (Creative Commons Zero), including "CC0 1.0" and
 * creativecommons.org/publicdomain/zero URLs, maps to "CC0".
 * A generic "Public domain" / PD string does not. CC0 is a specific
 * dedication; public-domain-style wording maps to CC0 only when the
 * source licence itself is CC0.
 *
 * @param {unknown} raw
 * @returns {"CC-BY"|"CC-BY-SA"|"CC0"|"Own"|"Permission"|null}
 */
export function mapPhotoLicence(raw) {
  const text = String(raw ?? "")
    .trim()
    .toLowerCase()
    .replace(/[_]+/g, " ")
    .replace(/\s+/g, " ");
  if (!text) return null;

  if (isCc0Source(text)) return "CC0";

  if (isCcBySa(text)) return "CC-BY-SA";
  if (isCcBy(text)) return "CC-BY";

  if (text === "own") return "Own";
  if (text === "permission") return "Permission";
  return null;
}

function isCc0Source(text) {
  if (text === "cc0" || text.startsWith("cc0 ") || text.startsWith("cc0-")) {
    return true;
  }
  if (text.includes("creative commons zero") || text.includes("cc-zero")) {
    return true;
  }
  if (
    text.includes("publicdomain/zero") ||
    text.includes("public-domain/zero")
  ) {
    return true;
  }
  // "CC0 1.0 Universal (Public Domain Dedication)" names CC0 first.
  return text.includes("cc0");
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
    text.includes("creativecommons.org/licenses/by ") ||
    /^by\b/.test(text)
  );
}

/**
 * Parse `**License:**` / `**Author:**` rows from an ATTRIBUTION.md file.
 * Does not write Firestore. Callers map [license] with [mapPhotoLicence].
 *
 * @param {string} markdown
 * @returns {{file: string, author: string, license: string, licence: string|null}[]}
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
  }));
}
