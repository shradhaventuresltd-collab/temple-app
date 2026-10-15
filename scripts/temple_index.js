/**
 * Pure temple_index projection. No Firestore client.
 * Entry shape matches lib/models/temple_index.dart.
 * Tradition / living flags follow DetailHonesty for the cases in
 * scripts/fixtures/temple_index_flags.json.
 */

export const ENTRY_VERSION = 1;
export const MAX_ENTRIES = 400;
export const MAX_SHARDS = 48;
export const SHORT_ADDRESS_MAX = 120;
export const COVER_THUMB_MAX = 500;
export const FIRESTORE_BATCH_LIMIT = 500;

const INDEX_ID = /^[A-Za-z0-9_-]{1,200}$/;

const LIVING_PHRASES = [
  "living temple",
  "living shrine",
  "living pilgrimage",
  "living monument",
  "living asi",
  "living pooja",
  "living cult",
  "living peetha",
  "daily worship",
  "daily pooja",
  "daily puja",
  "daily darshan",
  "daily aarti",
  "daily observance",
  "six pooja",
  "active ritual",
  "active worship",
  "active jain",
  "worship continues",
  "pooja continues",
  "hr&ce",
  "hrce",
  "devaswom",
  "endowments",
];

const MONUMENT_PHRASES = [
  "not a living",
  "no living",
  "empty sanctum",
  "no installed deity",
  "no installed cult",
  "not a dependable living",
  "rather than a conventional living",
  "rather than a routine living",
  "heritage visit only",
  "monument visit",
  "archaeological site",
  "visitor monument",
  "no regular living",
  "no recurring public aarti",
  "not a typical hr&ce",
  "not a typical darshan",
];

const DENIAL_WORDS = new Set(["no", "not", "without", "never", "unlike"]);
const WORSHIP =
  /\b(?:widely worshipped|darshan time|darshans?|aartis?|artis?|poojas?|pujas?|abhisheks?)\b/g;
const CEASED_AFTER =
  /\b(?:discontinued|ceased|stopped|ended|abandoned|abolished)\b|\bno more\b|\bno longer\b|\bonce worshipped\b|\b(?:was|were)\b(?:\s+\w+){0,4}\s+once\b/;
const QUALIFIER_BEFORE = /\b(once|historic|historical|formerly|former|erstwhile)\b/;
const DENIED_AFTER =
  /\b(?:not|never|no)\b(?:\s+\w+){0,2}\s+(?:allowed|permitted|offered|held|performed|available|conducted)\b/;

export function stateSlug(state) {
  const slug = String(state ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return slug === "" ? "unknown" : slug;
}

export function assertIndexId(id) {
  if (!INDEX_ID.test(String(id ?? ""))) {
    throw new Error(`Temple id "${id}" cannot be used as an index entry key.`);
  }
}

export function shortAddress(raw) {
  const text = String(raw ?? "")
    .trim()
    .replace(/\s+/g, " ");
  if (text.length <= SHORT_ADDRESS_MAX) return text;
  const cut = text.slice(0, SHORT_ADDRESS_MAX);
  const comma = cut.lastIndexOf(",");
  if (comma >= 40) return cut.slice(0, comma).trimEnd();
  return cut.trimEnd();
}

function placeholder(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return true;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return true;
  const host = parsed.hostname.toLowerCase();
  if (!host) return true;
  const hosts = [
    "picsum.photos",
    "placeholder.com",
    "placehold.co",
    "placehold.it",
    "dummyimage.com",
    "loremflickr.com",
    "placekitten.com",
    "fakeimg.pl",
    "placeimg.com",
    "lorempixel.com",
  ];
  if (hosts.some((known) => host === known || host.endsWith(`.${known}`))) {
    return true;
  }
  if (host.includes("picsum.photos")) return true;
  const blob = `${parsed.pathname} ${parsed.search}`.toLowerCase();
  return blob.includes("placeholder") || blob.includes("picsum");
}

function httpUrl(raw) {
  const trimmed = String(raw ?? "").trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return null;
    return trimmed;
  } catch {
    return null;
  }
}

function is480File(raw) {
  const trimmed = httpUrl(raw);
  if (!trimmed) return false;
  let pathname = trimmed;
  try {
    pathname = decodeURIComponent(new URL(trimmed).pathname);
  } catch {
    return false;
  }
  return /[_-]480\.(jpe?g|png|webp)$/i.test(pathname);
}

function browseThumb(raw) {
  const trimmed = httpUrl(raw);
  if (!trimmed || placeholder(trimmed) || trimmed.length > COVER_THUMB_MAX) return null;
  let pathname = trimmed;
  try {
    pathname = decodeURIComponent(new URL(trimmed).pathname);
  } catch {
    return null;
  }
  if (/[_-]480\.(jpe?g|png|webp)$/i.test(pathname)) return trimmed;
  if (!pathname.includes("/thumb/")) return null;
  return trimmed.replace(/\/(\d+)px-([^/?#]+)/, (full, width, rest) => {
    const parsed = Number(width);
    if (!Number.isFinite(parsed) || parsed <= 480) return full;
    return `/480px-${rest}`;
  });
}

function usableCover(raw, { allowFull }) {
  const thumb = browseThumb(raw);
  if (thumb) return thumb;
  if (!allowFull) return null;
  const trimmed = httpUrl(raw);
  if (!trimmed || placeholder(trimmed) || trimmed.length > COVER_THUMB_MAX) return null;
  return trimmed;
}

function firstPhoto(raw) {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const first = raw[0];
  if (first && typeof first === "object") return first;
  if (typeof first === "string") return { url: first };
  return null;
}

/**
 * photos[0].thumbUrl, then a _480 file on photos[0], then imageUrl, then images[0].
 * TODO(KAN-146): thumbnails are not generated yet. Until they exist, a full-size
 * imageUrl or images[0] is stored instead of null. Result is at most 500 characters.
 */
export function coverThumb(data) {
  const photo = firstPhoto(data?.photos);
  const fromPhoto =
    usableCover(photo?.thumbUrl, { allowFull: true }) ||
    usableCover(is480File(photo?.url) ? photo.url : null, { allowFull: false });
  if (fromPhoto) return fromPhoto;
  const fromCover = usableCover(data?.imageUrl, { allowFull: true });
  if (fromCover) return fromCover;
  const gallery = Array.isArray(data?.images) ? data.images[0] : null;
  return usableCover(gallery, { allowFull: true });
}

/**
 * KAN-145 browse filter. hidden:true or published:false drops the entry.
 * Missing flags stay listed. The client does not apply this yet.
 */
export function entryListed(entry) {
  if (entry?.hidden === true) return false;
  if (entry?.published === false) return false;
  return true;
}

export function coordinates(data) {
  const lat = data?.latitude;
  const lng = data?.longitude;
  if (typeof lat !== "number" || typeof lng !== "number") {
    return { lat: null, lng: null };
  }
  if (lat === 0 && lng === 0) return { lat: null, lng: null };
  return { lat, lng };
}

function text(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalize(raw) {
  return String(raw ?? "")
    .toLowerCase()
    .replace(/[’‘]/g, "'")
    .replace(/[–—]/g, " ");
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function words(value) {
  const found = [];
  for (const part of String(value).split(/[^a-z0-9.'’-]+/)) {
    const word = part.replace(/^[.'’-]+|[.'’-]+$/g, "");
    if (word) found.push(word);
  }
  return found;
}

function clauseStart(corpus, index) {
  const floor = Math.max(0, index - 240);
  for (let i = index - 1; i >= floor; i -= 1) {
    const ch = corpus[i];
    if (ch === "\n" || ch === "!" || ch === "?" || ch === ";" || ch === ".") {
      return i + 1;
    }
    if (ch === ",") return i + 1;
  }
  return floor;
}

function clauseEnd(corpus, index) {
  const limit = Math.min(corpus.length, index + 120);
  for (let i = index; i < limit; i += 1) {
    const ch = corpus[i];
    if (ch === "\n" || ch === "!" || ch === "?" || ch === ";" || ch === "." || ch === ",") {
      return i;
    }
  }
  return limit;
}

function containsDenial(list) {
  for (let i = 0; i < list.length; i += 1) {
    if (DENIAL_WORDS.has(list[i])) return true;
    if (list[i] === "rather" && list[i + 1] === "than") return true;
  }
  return false;
}

function deniedBefore(before) {
  const list = words(before);
  if (list.length === 0) return false;
  const windowStart = Math.max(0, list.length - 3);
  if (containsDenial(list.slice(windowStart))) return true;
  let conjunct = 0;
  for (let i = 0; i < list.length; i += 1) {
    if (list[i] === "and" || list[i] === "but") conjunct = i + 1;
  }
  if (conjunct >= list.length) return false;
  return containsDenial(list.slice(conjunct));
}

function matchIsAffirmative(corpus, start, end) {
  const before = corpus.slice(clauseStart(corpus, start), start);
  const after = corpus.slice(end, clauseEnd(corpus, end));
  if (deniedBefore(before)) return false;
  const beforeWords = before.trim().split(/\s+/).filter(Boolean);
  const tail = beforeWords.slice(-4).join(" ");
  if (QUALIFIER_BEFORE.test(tail)) return false;
  const afterHead = after.trim().split(/\s+/).filter(Boolean).slice(0, 6).join(" ");
  if (CEASED_AFTER.test(afterHead)) return false;
  if (DENIED_AFTER.test(afterHead)) return false;
  return true;
}

function hasAffirmativePhrase(corpus, phrase) {
  const pattern = new RegExp(
    phrase.split(/\s+/).map(escapeRegExp).join("[\\s-]+"),
    "g",
  );
  for (const match of corpus.matchAll(pattern)) {
    if (matchIsAffirmative(corpus, match.index, match.index + match[0].length)) {
      return true;
    }
  }
  return false;
}

function hasBoundedPhrase(corpus, phrase) {
  return new RegExp(`${escapeRegExp(phrase)}(?![a-z0-9])`).test(corpus);
}

function festivalPujaTitle(corpus, pujaStart) {
  const previous = words(corpus.slice(0, pujaStart));
  if (previous.length === 0) return false;
  const title = previous[previous.length - 1];
  return title === "durga" || title === "kali";
}

function affirmativeWorship(data, corpus) {
  const text = normalize(`${textOf(data, "description")}\n${textOf(data, "timings")}`);
  for (const match of text.matchAll(WORSHIP)) {
    const word = match[0];
    if ((word === "puja" || word === "pujas") && festivalPujaTitle(text, match.index)) {
      continue;
    }
    if (matchIsAffirmative(text, match.index, match.index + word.length)) return true;
  }
  return corpus ? false : false;
}

function textOf(data, key) {
  const value = data?.[key];
  return typeof value === "string" ? value : "";
}

function corpusOf(data) {
  const specialities = Array.isArray(data?.specialities)
    ? data.specialities.join("\n")
    : "";
  return normalize(
    [textOf(data, "description"), textOf(data, "story"), textOf(data, "timings"), specialities].join(
      "\n",
    ),
  );
}

export function traditionOf(data) {
  const deity = textOf(data, "deity").toLowerCase();
  if (/\b(jain|tirthankaras?)\b/.test(deity)) return "jain";
  if (/\b(buddha|buddhist)\b/.test(deity)) return "buddhist";
  if (/\b(sikh|gurdwara|gurudwara|guru nanak)\b/.test(deity)) return "sikh";
  const name = textOf(data, "name").toLowerCase();
  if (name.includes("gurdwara") || name.includes("gurudwara")) return "sikh";
  const specialities = Array.isArray(data?.specialities)
    ? data.specialities.join("\n")
    : "";
  const brief = `${textOf(data, "name")}\n${textOf(data, "description")}\n${specialities}`.toLowerCase();
  if (/\bjain (temples?|tirtha|pilgrimage)\b/.test(brief)) return "jain";
  if (/\bbuddhist (temples?|pilgrimage|shrine)\b/.test(brief)) return "buddhist";
  return "unspecified";
}

export function framingOf(data) {
  const corpus = corpusOf(data);
  if (MONUMENT_PHRASES.some((phrase) => hasBoundedPhrase(corpus, phrase))) {
    return "monument";
  }
  const worship =
    LIVING_PHRASES.some((phrase) => hasAffirmativePhrase(corpus, phrase)) ||
    affirmativeWorship(data, corpus);
  const ruined = /\b(?:ruined|ruins?)\b/.test(corpus);
  const ceased =
    /\b(?:once|historic|historical|formerly|former|erstwhile|discontinued|ceased|stopped|ended|abandoned|abolished)\b/.test(
      corpus,
    );
  if (!worship && ruined && ceased) return "monument";
  if (traditionOf(data) !== "unspecified") return "neutral";
  if (worship) return "living";
  return "neutral";
}

export function indexFlags(data) {
  const framing = framingOf(data);
  return {
    tradition: traditionOf(data),
    living: framing === "living",
    framing,
  };
}

function altNames(data) {
  if (!Object.prototype.hasOwnProperty.call(data, "altNames")) return undefined;
  if (!Array.isArray(data.altNames)) return undefined;
  const names = [];
  for (const item of data.altNames) {
    if (typeof item !== "string") continue;
    const trimmed = item.trim();
    if (!trimmed) continue;
    names.push(trimmed.length <= 80 ? trimmed : trimmed.slice(0, 80));
    if (names.length === 8) break;
  }
  return names.length === 0 ? undefined : names;
}

/**
 * @param {object} data temple document fields, including id
 */
export function entryFromTemple(data) {
  const id = String(data?.id ?? "");
  assertIndexId(id);
  const flags = indexFlags(data);
  const point = coordinates(data);
  const address = shortAddress(
    text(data.address) || text(data.location),
  );
  const entry = {
    id,
    slug: id,
    name: text(data.name),
    city: text(data.city),
    state: text(data.state),
    deity: text(data.deity),
    address,
    coverThumb: coverThumb(data),
    lat: point.lat,
    lng: point.lng,
    updatedAt: null,
    v: ENTRY_VERSION,
    tradition: flags.tradition,
    living: flags.living,
    framing: flags.framing,
  };
  const names = altNames(data);
  if (names) entry.altNames = names;
  if (Object.prototype.hasOwnProperty.call(data, "published") && typeof data.published === "boolean") {
    entry.published = data.published;
  }
  if (Object.prototype.hasOwnProperty.call(data, "hidden") && typeof data.hidden === "boolean") {
    entry.hidden = data.hidden;
  }
  return entry;
}

function sameValue(stored, expected) {
  if (stored == null && expected == null) return true;
  if (typeof stored === "number" || typeof expected === "number") {
    return Number(stored) === Number(expected);
  }
  return JSON.stringify(stored) === JSON.stringify(expected);
}

export function changedFields(stored, expected) {
  const keys = new Set([...Object.keys(stored ?? {}), ...Object.keys(expected ?? {})]);
  keys.delete("updatedAt");
  const fields = [];
  for (const key of keys) {
    if (!sameValue(stored?.[key], expected?.[key])) fields.push(key);
  }
  fields.sort();
  return fields;
}

function shardMaps(shards) {
  const out = new Map();
  for (const [shard, value] of Object.entries(shards ?? {})) {
    const entries =
      value && typeof value === "object" && value.entries && !value.id
        ? value.entries
        : value;
    out.set(shard, entries && typeof entries === "object" ? entries : {});
  }
  return out;
}

/**
 * @param {object[]} temples documents with id
 * @param {object} shards stateSlug → entry map, or stateSlug → {entries}
 */
export function diffIndex(temples, shards) {
  const byShard = shardMaps(shards);
  const locations = new Map();
  for (const [shard, entries] of byShard) {
    for (const [id, entry] of Object.entries(entries)) {
      const list = locations.get(id) ?? [];
      list.push({ shard, entry });
      locations.set(id, list);
    }
  }

  const templeIds = new Set();
  const missing = [];
  const drifted = [];
  const moved = [];
  const upserts = [];
  const removals = [];
  let unchanged = 0;

  for (const temple of temples) {
    const id = String(temple.id);
    templeIds.add(id);
    const expected = entryFromTemple(temple);
    const shard = stateSlug(temple.state);
    const found = locations.get(id) ?? [];
    const inPlace = found.find((item) => item.shard === shard);
    for (const other of found) {
      if (other.shard === shard) continue;
      removals.push({ shard: other.shard, id });
      moved.push({ id, from: other.shard, to: shard });
    }
    if (!inPlace) {
      missing.push({ id, shard });
      upserts.push({ shard, id, entry: expected });
      continue;
    }
    const fields = changedFields(inPlace.entry, expected);
    if (fields.length === 0) {
      unchanged += 1;
      continue;
    }
    drifted.push({ id, shard, fields });
    upserts.push({ shard, id, entry: expected });
  }

  const stale = [];
  for (const [id, found] of locations) {
    if (templeIds.has(id)) continue;
    for (const item of found) {
      stale.push({ id, shard: item.shard });
      removals.push({ shard: item.shard, id });
    }
  }

  const counts = shardCounts(temples);
  const capViolations = [...counts.entries()]
    .filter(([, count]) => count > MAX_ENTRIES)
    .map(([shard, count]) => ({ shard, count }));

  return {
    missing,
    drifted,
    moved,
    stale,
    unchanged,
    upserts,
    removals,
    counts,
    capViolations,
  };
}

export function shardCounts(temples) {
  const counts = new Map();
  for (const temple of temples) {
    const shard = stateSlug(temple.state);
    counts.set(shard, (counts.get(shard) ?? 0) + 1);
  }
  return counts;
}

export function assertShardCaps(temples) {
  const over = [...shardCounts(temples).entries()].filter(([, count]) => count > MAX_ENTRIES);
  if (over.length === 0) return;
  const detail = over.map(([shard, count]) => `${shard}=${count}`).join(", ");
  throw new Error(
    `Shard cap ${MAX_ENTRIES} exceeded (${detail}). No write. Split the state before applying.`,
  );
}

/**
 * One Firestore batch per state shard for seed_state_batch --apply.
 * Each batch creates the temple docs, one shard doc whose `entries` map is
 * keyed by temple id, and the meta bump. Temple count + 2 stays under
 * [maxOps] (500). A shard over the 400-key cap is refused.
 */
export function planSeedIndexBatches(temples, maxOps = FIRESTORE_BATCH_LIMIT) {
  const byShard = new Map();
  for (const temple of temples) {
    const shard = stateSlug(temple?.state);
    const list = byShard.get(shard) ?? [];
    list.push(temple);
    byShard.set(shard, list);
  }
  const batches = [];
  for (const [shard, list] of byShard) {
    if (list.length > MAX_ENTRIES) {
      throw new Error(
        `Shard ${shard} has ${list.length} temples; max is ${MAX_ENTRIES}. No write.`,
      );
    }
    const ops = list.length + 2;
    if (ops > maxOps) {
      throw new Error(
        `Shard ${shard} needs ${ops} ops; a batch holds at most ${maxOps}. No write.`,
      );
    }
    batches.push({ shard, temples: list, ops });
  }
  return batches;
}

/** True when a fresh shard read still needs this field-path write. */
export function writeNeeded(op, freshEntries) {
  const current = freshEntries?.[op.id];
  if (op.op === "delete") return current != null;
  if (current == null) return true;
  return changedFields(current, op.entry).length > 0;
}

/** One write per shard document per round. Firestore allows one write per doc per batch. */
export function batchRounds(ops) {
  const queues = new Map();
  for (const op of ops) {
    const list = queues.get(op.shard) ?? [];
    list.push(op);
    queues.set(op.shard, list);
  }
  const rounds = [];
  while ([...queues.values()].some((queue) => queue.length > 0)) {
    const round = [];
    for (const queue of queues.values()) {
      if (queue.length > 0) round.push(queue.shift());
    }
    rounds.push(round);
  }
  return rounds;
}

export function planOps(report) {
  const ops = [];
  for (const item of report.removals) {
    ops.push({ op: "delete", shard: item.shard, id: item.id });
  }
  for (const item of report.upserts) {
    ops.push({
      op: "set",
      shard: item.shard,
      id: item.id,
      entry: item.entry,
    });
  }
  return ops;
}
