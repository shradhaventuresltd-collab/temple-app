/**
 * Read-only audit of temple coordinates and Maps-destination text.
 *
 * Scans every document in the `temples` collection, or a local JSON export,
 * or the repo seed in lib/data/sample_data.dart. It prints counts and a CSV
 * of bad rows. It never writes Firestore, Storage, or Auth. The only file it
 * can create is the CSV from --out.
 *
 * Usage:
 *   node scripts/audit_temple_coords.js --seed
 *   node scripts/audit_temple_coords.js --seed lib/data/sample_data.dart --out report.csv
 *   node scripts/audit_temple_coords.js --json temples.json --out report.csv
 *   node scripts/audit_temple_coords.js --project <firebase-project-id> --out report.csv
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/audit_temple_coords.js --project demo
 *
 * --json accepts:
 *   - an array of temple objects
 *   - { temples: [ ... ] } or { temples: { id: doc } }
 *   - a map of id -> doc
 *   - a Firestore REST export { documents: [ { name, fields } ] }
 * Latitude/longitude may be numbers or numeric strings. `address` and
 * `location` are both read. A service-account JSON is refused.
 *
 * Cloud reads need GOOGLE_APPLICATION_CREDENTIALS or a gitignored
 * service-account.json in scripts/ or the repo root. There is no default
 * project. CI refuses cloud reads. Do not commit credentials.
 *
 * --apply, --write, --delete, --update, --set, --commit, and --merge are
 * refused. Firestore set/update/delete/batch/commit are refused even if a
 * caller reaches the client.
 *
 * India and the state boxes (except Puducherry) are the directory table in
 * scripts/state_batch.js. Puducherry is not that union rectangle: a point
 * must fall in one enclave below. Ranges are the UT government minute bounds
 * (DRDA / py.gov.in: Puducherry 11°46'–12°03'N, 79°36'–79°53'E; Karaikal
 * 10°49'–11°01'N, 79°43'–79°52'E; Mahe 11°42'–11°43'N, 75°31'–75°33'E; Yanam
 * 16°42'–16°46'N, 82°11'–82°19'E) plus a small pad. The broken "12°30'"
 * figure is not used: village fixes and the main-region north edge stop
 * near 12°03', and 12°30' would swallow Tamil Nadu.
 *
 * CSV columns: id, name, state, city, latitude, longitude, issues, detail.
 * Issue codes: missing-lat, missing-lng, zero-zero, swapped, outside-india,
 * outside-state, wrong-enclave, unknown-state, duplicate, name-url,
 * address-url, name-long, address-long.
 * name-long / address-long means longer than 180 characters.
 * duplicate matches latitude,longitude rounded to 5 decimal places.
 * (0, 0) is zero-zero and is not also outside-india.
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { LATITUDE_RANGE, LONGITUDE_RANGE, STATE_BOUNDS } from "./state_batch.js";
import { loadSampleTemples, templeDocumentId } from "./temple_seed.js";
import { redactThrown } from "./redact_url.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export { LATITUDE_RANGE, LONGITUDE_RANGE };

/** State boxes used by this audit. Puducherry is enclaves, not one rectangle. */
export const STATE_BBOX = Object.freeze(
  Object.fromEntries(
    Object.entries(STATE_BOUNDS).filter(([name]) => name !== "Puducherry"),
  ),
);

function box(latMin, latMax, lngMin, lngMax) {
  return Object.freeze({ latMin, latMax, lngMin, lngMax });
}

/** Puducherry town, Karaikal, Mahe, and Yanam. A point in the gaps is outside. */
export const PUDUCHERRY_ENCLAVES = Object.freeze({
  puducherry: box(11.755, 12.06, 79.58, 79.91),
  karaikal: box(10.8, 11.04, 79.7, 79.89),
  mahe: box(11.69, 11.73, 75.5, 75.57),
  yanam: box(16.68, 16.79, 82.16, 82.34),
});

export const NAME_LONG_LIMIT = 180;

export const ISSUE_ORDER = Object.freeze([
  "missing-lat",
  "missing-lng",
  "zero-zero",
  "swapped",
  "outside-india",
  "outside-state",
  "wrong-enclave",
  "unknown-state",
  "duplicate",
  "name-url",
  "address-url",
  "name-long",
  "address-long",
]);

const WRITE_FLAGS = new Set([
  "--apply",
  "--write",
  "--delete",
  "--update",
  "--set",
  "--commit",
  "--merge",
]);

const WRITE_METHODS = new Set([
  "set",
  "update",
  "delete",
  "create",
  "add",
  "batch",
  "bulkWriter",
  "runTransaction",
  "recursiveDelete",
  "commit",
]);

const STATE_ALIASES = Object.freeze({
  pondicherry: "Puducherry",
  puducherry: "Puducherry",
  "pondicherry ut": "Puducherry",
  orissa: "Odisha",
  uttaranchal: "Uttarakhand",
  tamilnadu: "Tamil Nadu",
  "jammu & kashmir": "Jammu and Kashmir",
  "nct of delhi": "Delhi",
  "new delhi": "Delhi",
  "dadra and nagar haveli": "Dadra and Nagar Haveli and Daman and Diu",
  "daman and diu": "Dadra and Nagar Haveli and Daman and Diu",
  "andaman and nicobar": "Andaman and Nicobar Islands",
  "andaman & nicobar islands": "Andaman and Nicobar Islands",
});

const STATE_KEYS = Object.freeze(["Puducherry", ...Object.keys(STATE_BBOX)]);

function fold(text) {
  return String(text ?? "")
    .normalize("NFKD")
    .replace(/\p{M}/gu, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

export function formatBboxTable() {
  const lines = [
    `India: lat ${LATITUDE_RANGE.min}..${LATITUDE_RANGE.max}  lng ${LONGITUDE_RANGE.min}..${LONGITUDE_RANGE.max}`,
    "States (latMin latMax lngMin lngMax). Puducherry uses enclaves, not one box:",
  ];
  for (const name of Object.keys(STATE_BBOX).sort((a, b) => a.localeCompare(b))) {
    const bounds = STATE_BBOX[name];
    lines.push(
      `  ${name}: ${bounds.latMin} ${bounds.latMax} ${bounds.lngMin} ${bounds.lngMax}`,
    );
  }
  lines.push("Puducherry enclaves:");
  for (const [name, bounds] of Object.entries(PUDUCHERRY_ENCLAVES)) {
    lines.push(
      `  ${name}: ${bounds.latMin} ${bounds.latMax} ${bounds.lngMin} ${bounds.lngMax}`,
    );
  }
  return lines.join("\n");
}

function printUsage() {
  return `Usage:
  node scripts/audit_temple_coords.js --seed [lib/data/sample_data.dart] [--out report.csv]
  node scripts/audit_temple_coords.js --json <temples.json> [--out report.csv]
  node scripts/audit_temple_coords.js --project <firebase-project-id> [--out report.csv]

Read-only. Refuses --apply and every Firestore write. Nothing in temples is
updated. --out writes a local CSV only. There is no default project.
CI refuses cloud reads. --seed and --json do not contact Google.
Do not commit service-account.json.

${formatBboxTable()}
`;
}

export function parseArgs(argv) {
  const opts = {
    help: false,
    seed: false,
    seedPath: null,
    json: null,
    project: null,
    out: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (WRITE_FLAGS.has(arg)) {
      throw new Error(
        `Refusing ${arg}. audit_temple_coords.js is read-only and never writes Firestore.`,
      );
    }
    if (arg === "--help" || arg === "-h") opts.help = true;
    else if (arg === "--seed") {
      opts.seed = true;
      const next = argv[i + 1];
      if (typeof next === "string" && !next.startsWith("-")) {
        opts.seedPath = next;
        i += 1;
      }
    } else if (arg === "--json") opts.json = argv[++i];
    else if (arg === "--project") opts.project = argv[++i];
    else if (arg === "--out") opts.out = argv[++i];
    else if (arg === "--dry-run") {
      // Accepted and ignored. The script is always a dry read.
    } else throw new Error(`Unknown argument: ${arg}`);
  }
  if (opts.json === undefined || opts.project === undefined || opts.out === undefined) {
    throw new Error("Missing value for a flag.");
  }
  return opts;
}

export function usesEmulator(env) {
  return (
    typeof env.FIRESTORE_EMULATOR_HOST === "string" &&
    env.FIRESTORE_EMULATOR_HOST.trim() !== ""
  );
}

function assertCloudReadAllowed(env) {
  if (usesEmulator(env)) return;
  if (env.CI || env.GITHUB_ACTIONS || env.GITHUB_WORKFLOW) {
    throw new Error(
      "Refusing a cloud Firestore read from CI. Use --seed or --json. This script never writes.",
    );
  }
}

export function refuseWrite(label, method) {
  throw new Error(
    `Refusing ${label}.${method}. audit_temple_coords.js is read-only and never writes.`,
  );
}

/** Proxy that allows reads and throws on every Firestore write method. */
export function readOnlyDb(target, label = "firestore") {
  if (target == null || typeof target !== "object") return target;
  if (typeof target.then === "function") return target;
  return new Proxy(target, {
    get(obj, prop, receiver) {
      if (typeof prop !== "string") return Reflect.get(obj, prop, receiver);
      if (WRITE_METHODS.has(prop)) {
        return () => refuseWrite(label, prop);
      }
      const value = Reflect.get(obj, prop, receiver);
      if (typeof value !== "function") return value;
      return (...args) => {
        const out = value.apply(obj, args);
        if (out && typeof out === "object" && typeof out.then !== "function") {
          return readOnlyDb(out, `${label}.${prop}`);
        }
        return out;
      };
    },
  });
}

export function canonicalState(state) {
  const folded = fold(state);
  if (!folded) return null;
  if (STATE_ALIASES[folded]) return STATE_ALIASES[folded];
  for (const key of STATE_KEYS) {
    if (fold(key) === folded) return key;
  }
  return null;
}

function inBox(bounds, lat, lng) {
  return (
    lat >= bounds.latMin &&
    lat <= bounds.latMax &&
    lng >= bounds.lngMin &&
    lng <= bounds.lngMax
  );
}

export function puducherryEnclaveAt(lat, lng) {
  for (const [name, bounds] of Object.entries(PUDUCHERRY_ENCLAVES)) {
    if (inBox(bounds, lat, lng)) return name;
  }
  return null;
}

function claimedPuducherryEnclaves(temple) {
  const text = fold(`${temple.city ?? ""}\n${temple.name ?? ""}\n${temple.address ?? ""}`);
  const specific = [];
  if (/\bkaraikal\b|\bthirunallar\b|\btirunallar\b/.test(text)) specific.push("karaikal");
  if (/\bmahe\b/.test(text)) specific.push("mahe");
  if (/\byanam\b/.test(text)) specific.push("yanam");
  if (specific.length > 0) return specific;
  if (/\bpuducherry\b|\bpondicherry\b|\bpuduchcheri\b/.test(text)) return ["puducherry"];
  return [];
}

function puducherryIssues(temple, lat, lng) {
  const at = puducherryEnclaveAt(lat, lng);
  const claimed = claimedPuducherryEnclaves(temple);
  if (claimed.length > 0) {
    if (at && claimed.includes(at)) return [];
    if (at) {
      return [
        {
          code: "wrong-enclave",
          detail: `named ${claimed.join("|")} but coordinates are in ${at}`,
        },
      ];
    }
    return [
      {
        code: "outside-state",
        detail: `named ${claimed.join("|")} but coordinates are outside every Puducherry enclave`,
      },
    ];
  }
  if (at) return [];
  return [
    {
      code: "outside-state",
      detail: "outside the Puducherry, Karaikal, Mahe, and Yanam enclaves",
    },
  ];
}

export function isSwappedLatLng(lat, lng) {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  if (lat === 0 && lng === 0) return false;
  const latInIndiaLng = lat >= LONGITUDE_RANGE.min && lat <= LONGITUDE_RANGE.max;
  const lngInIndiaLat = lng >= LATITUDE_RANGE.min && lng <= LATITUDE_RANGE.max;
  const latInIndiaLat = lat >= LATITUDE_RANGE.min && lat <= LATITUDE_RANGE.max;
  const lngInIndiaLng = lng >= LONGITUDE_RANGE.min && lng <= LONGITUDE_RANGE.max;
  return latInIndiaLng && lngInIndiaLat && !latInIndiaLat && !lngInIndiaLng;
}

function outsideIndia(lat, lng) {
  return (
    lat < LATITUDE_RANGE.min ||
    lat > LATITUDE_RANGE.max ||
    lng < LONGITUDE_RANGE.min ||
    lng > LONGITUDE_RANGE.max
  );
}

function finiteNumber(value) {
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function readAxis(source, key) {
  if (!source || !Object.prototype.hasOwnProperty.call(source, key)) {
    return { status: "absent", value: null };
  }
  const raw = source[key];
  if (raw == null || raw === "") return { status: "absent", value: null };
  const value = finiteNumber(raw);
  if (value == null) return { status: "invalid", value: null };
  return { status: "ok", value };
}

export function urlCharacterFindings(text) {
  if (typeof text !== "string" || text === "") return [];
  const found = [];
  if (text.includes("&")) found.push("&");
  if (text.includes("#")) found.push("#");
  if (text.includes("?")) found.push("?");
  if (text.includes("%")) found.push("%");
  if (text.includes("/")) found.push("/");
  if (text.includes("\\")) found.push("\\");
  if (text.includes(",")) found.push(",");
  if (/['’‘ʼ]/.test(text)) found.push("apostrophe");
  if (text.includes('"')) found.push("quote");
  if (/[\n\r]/.test(text)) found.push("newline");
  if (text.includes("\t")) found.push("tab");
  const withoutCurly = text.replace(/[’‘ʼ]/g, "");
  if (/[^\u0000-\u007F]/.test(withoutCurly)) found.push("non-ascii");
  return found;
}

function coordKey(lat, lng) {
  return `${lat.toFixed(5)},${lng.toFixed(5)}`;
}

function unwrapFirestoreValue(value) {
  if (value == null || typeof value !== "object" || Array.isArray(value)) return value;
  if ("nullValue" in value) return null;
  if ("stringValue" in value) return value.stringValue;
  if ("doubleValue" in value) return Number(value.doubleValue);
  if ("integerValue" in value) return Number(value.integerValue);
  if ("booleanValue" in value) return value.booleanValue;
  if ("mapValue" in value) return unwrapFirestoreFields(value.mapValue?.fields ?? {});
  return value;
}

function unwrapFirestoreFields(fields) {
  const out = {};
  for (const [key, value] of Object.entries(fields ?? {})) {
    out[key] = unwrapFirestoreValue(value);
  }
  return out;
}

function documentIdFromName(name) {
  if (typeof name !== "string" || name === "") return "";
  const parts = name.split("/");
  return parts[parts.length - 1] ?? "";
}

function looksLikeTemple(value) {
  return Boolean(
    value &&
      typeof value === "object" &&
      !Array.isArray(value) &&
      ("name" in value ||
        "latitude" in value ||
        "longitude" in value ||
        "lat" in value ||
        "lng" in value ||
        "state" in value ||
        "fields" in value),
  );
}

function asTempleRecord(raw, fallbackId) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  let source = raw;
  if (raw.fields && typeof raw.fields === "object") {
    source = { ...unwrapFirestoreFields(raw.fields), id: documentIdFromName(raw.name) || raw.id };
  }
  const latitude = Object.prototype.hasOwnProperty.call(source, "latitude")
    ? source.latitude
    : source.lat;
  const longitude = Object.prototype.hasOwnProperty.call(source, "longitude")
    ? source.longitude
    : source.lng;
  const name = typeof source.name === "string" ? source.name : "";
  const id =
    (typeof source.id === "string" && source.id.trim() !== "" && source.id) ||
    (typeof source.slug === "string" && source.slug.trim() !== "" && source.slug) ||
    (name ? templeDocumentId(name) : "") ||
    fallbackId;
  return {
    id: String(id),
    name,
    state: typeof source.state === "string" ? source.state : "",
    city: typeof source.city === "string" ? source.city : "",
    address:
      typeof source.address === "string"
        ? source.address
        : typeof source.location === "string"
          ? source.location
          : "",
    latitude,
    longitude,
    _hasLatitude:
      Object.prototype.hasOwnProperty.call(source, "latitude") ||
      Object.prototype.hasOwnProperty.call(source, "lat"),
    _hasLongitude:
      Object.prototype.hasOwnProperty.call(source, "longitude") ||
      Object.prototype.hasOwnProperty.call(source, "lng"),
  };
}

export function loadTemplesFromJson(value) {
  if (value && typeof value === "object" && (value.private_key || value.type === "service_account")) {
    throw new Error("Refusing to read a service-account JSON. Pass a temple export.");
  }
  let records = [];
  if (Array.isArray(value)) {
    records = value.map((row, index) => asTempleRecord(row, `row-${index + 1}`));
  } else if (value && Array.isArray(value.documents)) {
    records = value.documents.map((row, index) => asTempleRecord(row, `row-${index + 1}`));
  } else if (value && Array.isArray(value.temples)) {
    records = value.temples.map((row, index) => asTempleRecord(row, `row-${index + 1}`));
  } else if (value && value.temples && typeof value.temples === "object") {
    records = Object.entries(value.temples).map(([id, row]) =>
      asTempleRecord({ ...row, id: row?.id ?? id }, id),
    );
  } else if (value && typeof value === "object") {
    const entries = Object.entries(value);
    const mapOfTemples =
      entries.length > 0 && entries.every(([, row]) => looksLikeTemple(row));
    if (mapOfTemples) {
      records = entries.map(([id, row]) => asTempleRecord({ ...row, id: row?.id ?? id }, id));
    } else if (looksLikeTemple(value)) {
      records = [asTempleRecord(value, "row-1")];
    } else {
      throw new Error("JSON must be a temple array or an object with temples.");
    }
  } else {
    throw new Error("JSON must be a temple array or an object with temples.");
  }
  return records.filter(Boolean);
}

export function templesFromSeedRecords(records) {
  return records.map((row) => ({
    id: row.temple?.id ?? row.id,
    name: row.temple?.name ?? row.name,
    state: row.temple?.state ?? row.state,
    city: row.temple?.city ?? row.city,
    latitude: row.temple?.latitude ?? row.latitude,
    longitude: row.temple?.longitude ?? row.longitude,
    address: row.temple?.location ?? row.location ?? row.address ?? "",
  }));
}

function axisSource(temple) {
  const source = {};
  if (temple._hasLatitude || Object.prototype.hasOwnProperty.call(temple, "latitude")) {
    source.latitude = temple.latitude;
  }
  if (temple._hasLongitude || Object.prototype.hasOwnProperty.call(temple, "longitude")) {
    source.longitude = temple.longitude;
  }
  return source;
}

function classifyOne(temple, duplicateIds) {
  const source = axisSource(temple);
  const latAxis = readAxis(source, "latitude");
  const lngAxis = readAxis(source, "longitude");
  const issues = [];
  const details = [];
  const add = (code, detail) => {
    issues.push(code);
    if (detail) details.push(detail);
  };
  if (latAxis.status !== "ok") {
    add("missing-lat", latAxis.status === "invalid" ? "latitude is not a finite number" : "latitude is absent");
  }
  if (lngAxis.status !== "ok") {
    add(
      "missing-lng",
      lngAxis.status === "invalid" ? "longitude is not a finite number" : "longitude is absent",
    );
  }
  const lat = latAxis.value;
  const lng = lngAxis.value;
  let enclave = null;
  if (latAxis.status === "ok" && lngAxis.status === "ok") {
    if (lat === 0 && lng === 0) {
      add("zero-zero", "latitude and longitude are 0,0");
    } else {
      if (isSwappedLatLng(lat, lng)) {
        add(
          "swapped",
          `latitude ${lat} is in the Indian longitude band and longitude ${lng} is in the Indian latitude band`,
        );
      }
      if (outsideIndia(lat, lng)) {
        add(
          "outside-india",
          `outside lat ${LATITUDE_RANGE.min}..${LATITUDE_RANGE.max} lng ${LONGITUDE_RANGE.min}..${LONGITUDE_RANGE.max}`,
        );
      }
      const state = canonicalState(temple.state);
      if (!state) {
        add("unknown-state", `state ${JSON.stringify(temple.state ?? "")} has no bounding box`);
      } else if (state === "Puducherry") {
        enclave = puducherryEnclaveAt(lat, lng);
        for (const issue of puducherryIssues(temple, lat, lng)) add(issue.code, issue.detail);
      } else {
        const bounds = STATE_BBOX[state];
        if (!inBox(bounds, lat, lng)) {
          add(
            "outside-state",
            `${state} box lat ${bounds.latMin}..${bounds.latMax} lng ${bounds.lngMin}..${bounds.lngMax}`,
          );
        }
      }
      if (duplicateIds[temple.id]) {
        const others = duplicateIds[temple.id].filter((id) => id !== temple.id).sort();
        add("duplicate", `same coordinates as ${others.join("|")}`);
      }
    }
  }
  const nameFindings = urlCharacterFindings(temple.name);
  if (nameFindings.length > 0) add("name-url", `name contains ${nameFindings.join(" ")}`);
  if (typeof temple.name === "string" && temple.name.length > NAME_LONG_LIMIT) {
    add("name-long", `name length ${temple.name.length}`);
  }
  const addressFindings = urlCharacterFindings(temple.address);
  if (addressFindings.length > 0) {
    add("address-url", `address contains ${addressFindings.join(" ")}`);
  }
  if (typeof temple.address === "string" && temple.address.length > NAME_LONG_LIMIT) {
    add("address-long", `address length ${temple.address.length}`);
  }
  const ordered = ISSUE_ORDER.filter((code) => issues.includes(code));
  return {
    id: temple.id,
    name: temple.name ?? "",
    state: temple.state ?? "",
    city: temple.city ?? "",
    latitude: latAxis.status === "ok" ? lat : "",
    longitude: lngAxis.status === "ok" ? lng : "",
    issues: ordered,
    detail: details.join("; "),
    enclave,
  };
}

function duplicateIndex(temples) {
  const groups = {};
  for (const temple of temples) {
    const source = axisSource(temple);
    const latAxis = readAxis(source, "latitude");
    const lngAxis = readAxis(source, "longitude");
    if (latAxis.status !== "ok" || lngAxis.status !== "ok") continue;
    if (latAxis.value === 0 && lngAxis.value === 0) continue;
    const key = coordKey(latAxis.value, lngAxis.value);
    if (groups[key] == null) groups[key] = [];
    groups[key].push(temple.id);
  }
  const byId = {};
  let groupCount = 0;
  for (const ids of Object.values(groups)) {
    if (ids.length < 2) continue;
    groupCount += 1;
    for (const id of ids) byId[id] = ids;
  }
  return { byId, groupCount };
}

export function auditTemples(rawTemples) {
  const temples = (rawTemples ?? []).map((row, index) => {
    const record = asTempleRecord(row, `row-${index + 1}`);
    return record ?? {
      id: `row-${index + 1}`,
      name: "",
      state: "",
      city: "",
      address: "",
      latitude: undefined,
      longitude: undefined,
    };
  });
  const duplicates = duplicateIndex(temples);
  const rows = temples.map((temple) => classifyOne(temple, duplicates.byId));
  const counts = { temples: rows.length, flagged: 0, clean: 0, "duplicate-groups": duplicates.groupCount };
  for (const code of ISSUE_ORDER) counts[code] = 0;
  counts.puducherry = 0;
  for (const name of Object.keys(PUDUCHERRY_ENCLAVES)) counts[`enclave-${name}`] = 0;
  for (const row of rows) {
    if (row.issues.length === 0) counts.clean += 1;
    else counts.flagged += 1;
    for (const code of new Set(row.issues)) counts[code] += 1;
    if (canonicalState(row.state) === "Puducherry") {
      counts.puducherry += 1;
      if (row.enclave) counts[`enclave-${row.enclave}`] += 1;
    }
  }
  const flagged = rows
    .filter((row) => row.issues.length > 0)
    .sort((a, b) => a.id.localeCompare(b.id));
  return { rows, counts, csv: toCsv(flagged) };
}

function csvField(value) {
  const text = value == null ? "" : String(value);
  if (/[",\n\r]/.test(text)) return `"${text.replace(/"/g, '""')}"`;
  return text;
}

export function toCsv(rows) {
  const header = ["id", "name", "state", "city", "latitude", "longitude", "issues", "detail"];
  const lines = [header.join(",")];
  for (const row of rows) {
    lines.push(
      [
        row.id,
        row.name,
        row.state,
        row.city,
        row.latitude,
        row.longitude,
        row.issues.join("|"),
        row.detail,
      ]
        .map(csvField)
        .join(","),
    );
  }
  return `${lines.join("\n")}\n`;
}

export function formatSummary(counts) {
  const lines = [
    "Mode: read-only",
    `temples: ${counts.temples}  flagged: ${counts.flagged}  clean: ${counts.clean}`,
  ];
  for (const code of ISSUE_ORDER) lines.push(`${code}: ${counts[code]}`);
  lines.push(`duplicate-groups: ${counts["duplicate-groups"]}`);
  lines.push(`puducherry: ${counts.puducherry}`);
  for (const name of Object.keys(PUDUCHERRY_ENCLAVES)) {
    lines.push(`puducherry-enclave ${name}: ${counts[`enclave-${name}`]}`);
  }
  lines.push("No Firestore writes.");
  return lines.join("\n");
}

function requireMode(opts) {
  const modes = [opts.seed, Boolean(opts.json), Boolean(opts.project)].filter(Boolean);
  if (modes.length !== 1) {
    throw new Error("Pass exactly one of --seed, --json <file>, or --project <id>.");
  }
}

export function templesFromSeed(path) {
  const loaded = path ? loadSampleTemples(path) : loadSampleTemples();
  return templesFromSeedRecords(loaded.temples);
}

export function templesFromJsonFile(path) {
  const parsed = JSON.parse(readFileSync(path, "utf8"));
  return loadTemplesFromJson(parsed);
}

async function openFirestore(project, env) {
  assertCloudReadAllowed(env);
  const id = String(project ?? "").trim();
  if (!id) {
    throw new Error(
      "Pass --project <firebase-project-id>. This read has no default project and never writes.",
    );
  }
  const admin = (await import("firebase-admin")).default;
  if (usesEmulator(env)) {
    process.env.FIRESTORE_EMULATOR_HOST = env.FIRESTORE_EMULATOR_HOST;
    if (admin.apps.length === 0) admin.initializeApp({ projectId: id });
    return readOnlyDb(admin.firestore());
  }
  const credentials = env.GOOGLE_APPLICATION_CREDENTIALS;
  if (typeof credentials === "string" && credentials.trim() !== "") {
    if (admin.apps.length === 0) {
      admin.initializeApp({ projectId: id });
    }
    return readOnlyDb(admin.firestore());
  }
  const candidates = [
    resolve(__dirname, "service-account.json"),
    resolve(__dirname, "..", "service-account.json"),
  ];
  const saPath = candidates.find((candidate) => existsSync(candidate));
  if (!saPath) {
    throw new Error(
      "No GOOGLE_APPLICATION_CREDENTIALS or service-account.json. No read. Do not commit a service account.",
    );
  }
  const serviceAccount = JSON.parse(readFileSync(saPath, "utf8"));
  if (serviceAccount.project_id && serviceAccount.project_id !== id) {
    throw new Error(
      `Service account project_id is ${serviceAccount.project_id}, not ${id}. No read.`,
    );
  }
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: id,
    });
  }
  return readOnlyDb(admin.firestore());
}

export async function loadFirestoreTemples(project, env = process.env) {
  const db = await openFirestore(project, env);
  const snap = await db.collection("temples").get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function loadRequested(opts, deps, env) {
  if (opts.seed) {
    return deps.loadSeed ? deps.loadSeed(opts.seedPath) : templesFromSeed(opts.seedPath);
  }
  if (opts.json) {
    return deps.loadJson ? deps.loadJson(opts.json) : templesFromJsonFile(opts.json);
  }
  if (deps.loadFirestore) return deps.loadFirestore(opts.project, env);
  return loadFirestoreTemples(opts.project, env);
}

export async function main(argv = process.argv.slice(2), deps = {}) {
  const opts = parseArgs(argv);
  const log = deps.log ?? ((line) => console.log(line));
  if (opts.help) {
    log(printUsage());
    return null;
  }
  requireMode(opts);
  const env = deps.env ?? process.env;
  if (opts.project) assertCloudReadAllowed(env);
  const temples = await loadRequested(opts, deps, env);
  const report = auditTemples(temples);
  const summary = formatSummary(report.counts);
  log(summary);
  if (opts.out) {
    writeFileSync(opts.out, report.csv);
    log(`csv: ${opts.out}`);
  } else {
    log(report.csv);
  }
  return { ...report, summary };
}

const isDirect =
  process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isDirect) {
  main().catch((error) => {
    console.error(redactThrown(error));
    process.exit(1);
  });
}
