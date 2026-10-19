/**
 * Read and update lib/data/sample_data.dart temple constructors.
 * Used by the state-batch seeder. Does not talk to Firestore.
 */
import { readFileSync, writeFileSync } from "node:fs";

export const SAMPLE_DATA_PATH = new URL(
  "../lib/data/sample_data.dart",
  import.meta.url,
);

/** Same slug rule as templeDocumentId in lib/services/seed_service.dart. */
export function templeDocumentId(name) {
  return String(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

const LICENCE_FROM_DART = {
  "PhotoLicence.ccBy": "CC-BY",
  "PhotoLicence.ccBySa": "CC-BY-SA",
  "PhotoLicence.cc0": "CC0",
  "PhotoLicence.own": "Own",
  "PhotoLicence.permission": "Permission",
};

const DART_FROM_LICENCE = Object.fromEntries(
  Object.entries(LICENCE_FROM_DART).map(([dart, wire]) => [wire, dart]),
);

export function parseSampleTemples(source) {
  const temples = [];
  const re = /(?:^|\n)([ \t]*)Temple\(/g;
  let match;
  while ((match = re.exec(source))) {
    const start = match.index + (match[0].startsWith("\n") ? 1 : 0);
    const open = source.indexOf("(", start);
    const parsed = parseCallBody(source, open);
    const fields = parsed.fields;
    const name = fields.name?.value;
    if (typeof name !== "string" || name === "") {
      throw new Error(`Temple at ${start} is missing name`);
    }
    temples.push({
      start,
      end: parsed.end,
      id: templeDocumentId(name),
      fields,
      temple: templeFromFields(fields, templeDocumentId(name)),
    });
    re.lastIndex = parsed.end;
  }
  return temples;
}

export function loadSampleTemples(path = SAMPLE_DATA_PATH) {
  const file = path instanceof URL ? path : path;
  const source = readFileSync(file, "utf8");
  return { source, temples: parseSampleTemples(source) };
}

function templeFromFields(fields, id) {
  const photos = fields.photos?.value ?? [];
  return {
    id,
    name: req(fields, "name"),
    state: req(fields, "state"),
    city: req(fields, "city"),
    deity: req(fields, "deity"),
    imageUrl: req(fields, "imageUrl"),
    images: fields.images?.value ?? [],
    description: req(fields, "description"),
    story: req(fields, "story"),
    location: req(fields, "location"),
    timings: req(fields, "timings"),
    specialities: fields.specialities?.value ?? [],
    latitude: req(fields, "latitude"),
    longitude: req(fields, "longitude"),
    photos,
  };
}

function req(fields, key) {
  if (!fields[key]) throw new Error(`Missing field ${key}`);
  return fields[key].value;
}

function parseCallBody(source, openIndex) {
  let i = openIndex + 1;
  const fields = {};
  let depth = 1;
  while (i < source.length && depth > 0) {
    i = skipTrivia(source, i);
    if (source[i] === ")") {
      depth -= 1;
      i += 1;
      break;
    }
    const name = readIdent(source, i);
    i = name.end;
    i = skipTrivia(source, i);
    if (source[i] !== ":") {
      throw new Error(`Expected ':' after ${name.value} at ${i}`);
    }
    i += 1;
    i = skipTrivia(source, i);
    const value = readValue(source, i);
    i = skipTrivia(source, value.end);
    let statementEnd = i;
    if (source[i] === ",") {
      statementEnd = i + 1;
      i += 1;
    }
    fields[name.value] = {
      value: value.value,
      valueStart: value.start,
      valueEnd: value.end,
      statementStart: name.start,
      statementEnd,
    };
  }
  return { end: i, fields };
}

function readValue(source, i) {
  const start = i;
  if (source.startsWith("const", i) && !/[A-Za-z0-9_]/.test(source[i + 5] ?? "")) {
    i = skipTrivia(source, i + 5);
  }
  if (source[i] === "'" || source[i] === '"') {
    return readConcatenatedString(source, i);
  }
  if (source[i] === "[") return readList(source, i);
  if (source[i] === "-" || (source[i] >= "0" && source[i] <= "9")) {
    return readNumber(source, i);
  }
  const ident = readDotted(source, i);
  if (ident.value === "null") {
    return { start, end: ident.end, value: null };
  }
  if (source[ident.end] === "(" || source[skipTrivia(source, ident.end)] === "(") {
    const open = source.indexOf("(", ident.end);
    const body = parseCallBody(source, open);
    return {
      start,
      end: body.end,
      value: { call: ident.value, fields: body.fields },
    };
  }
  if (LICENCE_FROM_DART[ident.value]) {
    return { start, end: ident.end, value: LICENCE_FROM_DART[ident.value] };
  }
  return { start, end: ident.end, value: ident.value };
}

function readList(source, openIndex) {
  let i = openIndex + 1;
  const items = [];
  while (i < source.length) {
    i = skipTrivia(source, i);
    if (source[i] === "]") {
      return { start: openIndex, end: i + 1, value: items };
    }
    const value = readValue(source, i);
    if (value.value && value.value.call === "TemplePhoto") {
      items.push(photoFromCall(value.value.fields));
    } else {
      items.push(value.value);
    }
    i = skipTrivia(source, value.end);
    if (source[i] === ",") i += 1;
  }
  throw new Error("Unterminated list");
}

function photoFromCall(fields) {
  return {
    url: fields.url?.value ?? "",
    credit: fields.credit?.value ?? "",
    licence: fields.licence?.value ?? "",
    order: fields.order?.value ?? 0,
  };
}

function readConcatenatedString(source, i) {
  const start = i;
  let value = "";
  while (i < source.length) {
    i = skipTrivia(source, i);
    if (source[i] !== "'" && source[i] !== '"') break;
    const part = readOneString(source, i);
    value += part.value;
    i = part.end;
  }
  return { start, end: i, value };
}

function readOneString(source, i) {
  const quote = source[i];
  let value = "";
  i += 1;
  while (i < source.length) {
    const c = source[i];
    if (c === "\\") {
      const n = source[i + 1];
      if (n === "n") value += "\n";
      else if (n === "t") value += "\t";
      else if (n === "r") value += "\r";
      else value += n ?? "";
      i += 2;
      continue;
    }
    if (c === quote) return { value, end: i + 1 };
    value += c;
    i += 1;
  }
  throw new Error("Unterminated string");
}

function readNumber(source, i) {
  const start = i;
  let j = i;
  if (source[j] === "-") j += 1;
  while (j < source.length && source[j] >= "0" && source[j] <= "9") j += 1;
  if (source[j] === ".") {
    j += 1;
    while (j < source.length && source[j] >= "0" && source[j] <= "9") j += 1;
  }
  return { start, end: j, value: Number(source.slice(start, j)) };
}

function readIdent(source, i) {
  const start = i;
  let j = i;
  while (j < source.length && /[A-Za-z0-9_]/.test(source[j])) j += 1;
  if (j === start) throw new Error(`Expected identifier at ${i}`);
  return { start, end: j, value: source.slice(start, j) };
}

function readDotted(source, i) {
  const start = i;
  let j = i;
  while (j < source.length && /[A-Za-z0-9_.]/.test(source[j])) j += 1;
  if (j === start) throw new Error(`Expected name at ${i}`);
  return { start, end: j, value: source.slice(start, j) };
}

function skipTrivia(source, i) {
  while (i < source.length) {
    const c = source[i];
    if (c === " " || c === "\n" || c === "\r" || c === "\t") {
      i += 1;
      continue;
    }
    if (c === "/" && source[i + 1] === "/") {
      i += 2;
      while (i < source.length && source[i] !== "\n") i += 1;
      continue;
    }
    break;
  }
  return i;
}

export function dartQuote(value) {
  const escaped = String(value)
    .replaceAll("\\", "\\\\")
    .replaceAll("'", "\\'")
    .replaceAll("\r", "")
    .replaceAll("\n", "\\n");
  return `'${escaped}'`;
}

function dartStringList(values, indent) {
  if (values.length === 0) return "const []";
  const inner = values
    .map((value) => `${indent}  ${dartQuote(value)},`)
    .join("\n");
  return `[\n${inner}\n${indent}]`;
}

function dartPhotos(photos, indent) {
  if (!photos || photos.length === 0) return "const []";
  const blocks = photos.map((photo) => {
    const licence = DART_FROM_LICENCE[photo.licence];
    if (!licence) throw new Error(`Unknown licence ${photo.licence}`);
    const lines = [
      `${indent}  TemplePhoto(`,
      `${indent}    url: ${dartQuote(photo.url)},`,
      `${indent}    credit: ${dartQuote(photo.credit ?? "")},`,
      `${indent}    licence: ${licence},`,
      `${indent}    order: ${photo.order},`,
    ];
    if (typeof photo.thumbUrl === "string" && photo.thumbUrl.startsWith("https://")) {
      lines.push(`${indent}    thumbUrl: ${dartQuote(photo.thumbUrl)},`);
    }
    if (typeof photo.galleryUrl === "string" && photo.galleryUrl.startsWith("https://")) {
      lines.push(`${indent}    galleryUrl: ${dartQuote(photo.galleryUrl)},`);
    }
    lines.push(`${indent}  ),`);
    return lines.join("\n");
  });
  return `[\n${blocks.join("\n")}\n${indent}]`;
}

function dartTemple(temple) {
  const pad = "    ";
  const lines = [
    "  Temple(",
    `${pad}name: ${dartQuote(temple.name)},`,
    `${pad}state: ${dartQuote(temple.state)},`,
    `${pad}city: ${dartQuote(temple.city)},`,
    `${pad}deity: ${dartQuote(temple.deity)},`,
    `${pad}imageUrl: ${dartQuote(temple.imageUrl)},`,
    `${pad}images: ${dartStringList(temple.images, pad)},`,
  ];
  if (temple.photos && temple.photos.length > 0) {
    lines.push(`${pad}photos: ${dartPhotos(temple.photos, pad)},`);
  }
  lines.push(
    `${pad}description: ${dartQuote(temple.description)},`,
    `${pad}story: ${dartQuote(temple.story)},`,
    `${pad}location: ${dartQuote(temple.location)},`,
    `${pad}timings: ${temple.timings == null ? "null" : dartQuote(temple.timings)},`,
    `${pad}latitude: ${temple.latitude},`,
    `${pad}longitude: ${temple.longitude},`,
    `${pad}specialities: ${dartStringList(temple.specialities, pad)},`,
    "  ),",
  );
  return lines.join("\n");
}

const COMPARE_KEYS = [
  "name",
  "state",
  "city",
  "deity",
  "imageUrl",
  "images",
  "description",
  "story",
  "location",
  "timings",
  "specialities",
  "latitude",
  "longitude",
  "photos",
];

export function sameTempleContent(left, right) {
  return changedKeys(left, right).length === 0;
}

export function changedKeys(left, right) {
  const keys = [];
  for (const key of COMPARE_KEYS) {
    if (!sameValue(left[key], right[key])) keys.push(key);
  }
  return keys;
}

function sameValue(left, right) {
  if (typeof left === "number" || typeof right === "number") {
    return Number(left) === Number(right);
  }
  return JSON.stringify(left ?? null) === JSON.stringify(right ?? null);
}

/**
 * Merge validated temples into sample_data source.
 * Existing ids are updated in place. New ids are appended.
 * @param {string} source
 * @param {object[]} incoming normalized temples
 */
export function mergeTemplesIntoSource(source, incoming) {
  let next = source;
  if (!next.includes("temple_photo.dart")) {
    next = next.replace(
      "import 'package:temple_app/models/temple.dart';\n",
      "import 'package:temple_app/models/photo_licence.dart';\n" +
        "import 'package:temple_app/models/temple.dart';\n" +
        "import 'package:temple_app/models/temple_photo.dart';\n",
    );
  }
  const parsed = parseSampleTemples(next);
  const byId = new Map(parsed.map((row) => [row.id, row]));
  const replacements = [];
  const appended = [];

  for (const temple of incoming) {
    const current = byId.get(temple.id);
    if (!current) {
      appended.push(temple);
      continue;
    }
    if (sameTempleContent(current.temple, temple)) continue;
    const keys = changedKeys(current.temple, temple);
    replacements.push(
      ...fieldReplacements(next, current, temple, keys),
    );
  }

  replacements.sort((a, b) => b.start - a.start);
  for (const replacement of replacements) {
    next =
      next.slice(0, replacement.start) +
      replacement.text +
      next.slice(replacement.end);
  }

  if (appended.length > 0) {
    const block = appended
      .map((temple) => `\n  // State batch: ${temple.id}\n${dartTemple(temple)}`)
      .join("\n");
    const close = next.lastIndexOf("];");
    if (close === -1) throw new Error("sample_data.dart is missing the list close");
    next = `${next.slice(0, close)}${block}\n${next.slice(close)}`;
  }
  return next;
}

function fieldReplacements(source, current, temple, keys) {
  const out = [];
  for (const key of keys) {
    const field = current.fields[key];
    const text = dartFieldValue(key, temple[key]);
    if (field) {
      out.push({ start: field.valueStart, end: field.valueEnd, text });
      continue;
    }
    const anchor = current.fields.imageUrl ?? current.fields.name;
    if (!anchor) throw new Error(`Cannot insert ${key} on ${temple.id}`);
    out.push({
      start: anchor.statementEnd,
      end: anchor.statementEnd,
      text: `\n    ${key}: ${text},`,
    });
  }
  return out;
}

function dartFieldValue(key, value) {
  if (key === "images" || key === "specialities") {
    return dartStringList(value ?? [], "    ");
  }
  if (key === "photos") return dartPhotos(value ?? [], "    ");
  if (key === "latitude" || key === "longitude") return String(value);
  if (key === "timings" && value == null) return "null";
  return dartQuote(value ?? "");
}

export function writeSampleSource(source, path = SAMPLE_DATA_PATH) {
  writeFileSync(path, source);
}
