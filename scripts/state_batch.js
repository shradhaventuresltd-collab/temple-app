/**
 * Validate a Research state batch and classify it against existing temples.
 * Pure: no Firestore, no file writes.
 *
 * Schema of record: the state-expansion README (Hybrid C).
 * Seeded fields: name, city, state, deity, latitude, longitude, timings,
 * description, specialities. Research-only keys, never written as their own
 * Firestore fields: slug, sources, timings_note, photo_pack, review.
 * story, location, festivals, pooja_schedule, and trip_planning are forbidden.
 */
import { changedKeys, templeDocumentId } from "./temple_seed.js";

export const MAX_TEMPLES_PER_BATCH = 100;
export const DUPLICATE_DISTANCE_KM = 1;

/** India, including island territories used by this directory. */
export const LATITUDE_RANGE = Object.freeze({ min: 6, max: 37.5 });
export const LONGITUDE_RANGE = Object.freeze({ min: 68, max: 97.5 });

/**
 * State and union-territory bounding boxes (latMin, latMax, lngMin, lngMax).
 * Boxes contain the directory's seeded temples and the state's own extent.
 * Delhi (about 28.6, 77.2) is outside Bihar.
 */
export const STATE_BOUNDS = Object.freeze({
  "Andaman and Nicobar Islands": box(6.7, 13.7, 92.2, 94.3),
  "Andhra Pradesh": box(12.6, 19.2, 76.7, 84.8),
  "Arunachal Pradesh": box(26.5, 29.5, 91.5, 97.5),
  Assam: box(24.0, 28.3, 89.6, 96.2),
  Bihar: box(24.2, 27.7, 83.3, 88.3),
  Chandigarh: box(30.6, 30.85, 76.65, 76.9),
  Chhattisgarh: box(17.7, 24.2, 80.2, 84.5),
  "Dadra and Nagar Haveli and Daman and Diu": box(20.0, 20.8, 72.7, 73.2),
  Delhi: box(28.4, 28.9, 76.8, 77.4),
  Goa: box(14.8, 15.9, 73.6, 74.4),
  Gujarat: box(20.1, 24.7, 68.2, 74.5),
  Haryana: box(27.6, 30.9, 74.4, 77.6),
  "Himachal Pradesh": box(30.3, 33.3, 75.5, 79.1),
  "Jammu and Kashmir": box(32.2, 34.8, 73.7, 76.8),
  Jharkhand: box(21.9, 25.4, 83.3, 87.9),
  Karnataka: box(11.5, 18.5, 74.0, 78.6),
  Kerala: box(8.2, 12.8, 74.8, 77.5),
  Ladakh: box(32.2, 36.0, 75.5, 80.0),
  Lakshadweep: box(8.2, 12.4, 71.6, 74.2),
  "Madhya Pradesh": box(21.0, 26.9, 74.0, 82.9),
  Maharashtra: box(15.6, 22.1, 72.6, 80.9),
  Manipur: box(23.8, 25.7, 93.0, 94.8),
  Meghalaya: box(25.0, 26.2, 89.7, 92.8),
  Mizoram: box(21.9, 24.6, 92.1, 93.5),
  Nagaland: box(25.1, 27.1, 93.2, 95.3),
  Odisha: box(17.7, 22.6, 81.3, 87.5),
  Puducherry: box(10.8, 16.8, 75.4, 82.3),
  Punjab: box(29.5, 32.6, 73.8, 76.9),
  Rajasthan: box(23.0, 30.2, 69.4, 78.3),
  Sikkim: box(27.0, 28.2, 88.0, 88.95),
  "Tamil Nadu": box(8.0, 13.6, 76.2, 80.4),
  Telangana: box(15.8, 19.9, 77.2, 81.4),
  Tripura: box(22.9, 24.6, 91.1, 92.4),
  "Uttar Pradesh": box(23.8, 30.5, 77.0, 84.7),
  Uttarakhand: box(28.7, 31.5, 77.5, 81.1),
  "West Bengal": box(21.5, 27.3, 85.8, 89.9),
});

const BATCH_KEYS = [
  "state",
  "owner",
  "generated",
  "existing_in_prod",
  "target",
  "temples",
];

const TEMPLE_KEYS = [
  "slug",
  "name",
  "city",
  "state",
  "deity",
  "latitude",
  "longitude",
  "timings",
  "timings_note",
  "description",
  "specialities",
  "sources",
  "photo_pack",
  "review",
];

const FORBIDDEN = [
  "id",
  "story",
  "location",
  "festivals",
  "pooja_schedule",
  "trip_planning",
];

const PLACEHOLDER_HOSTS = [
  "picsum.photos",
  "placeholder.com",
  "placehold.co",
  "placehold.it",
  "dummyimage.com",
  "loremflickr.com",
  "placekitten.com",
  "fakeimg.pl",
  "placeimg.com",
  "unsplash.com",
  "shutterstock.com",
  "istockphoto.com",
  "gettyimages.com",
  "pexels.com",
  "stock.adobe.com",
  "freepik.com",
  "dreamstime.com",
  "123rf.com",
  "depositphotos.com",
];

function box(latMin, latMax, lngMin, lngMax) {
  return Object.freeze({ latMin, latMax, lngMin, lngMax });
}

/**
 * @param {unknown} batch
 * @param {object[]} existing parsed seed temples ({id, name, latitude, ...})
 */
export function validateStateBatch(batch, existing = []) {
  const errors = [];
  if (!batch || typeof batch !== "object" || Array.isArray(batch)) {
    return fail(["Batch must be a JSON object with state and temples."]);
  }
  for (const key of Object.keys(batch)) {
    if (!BATCH_KEYS.includes(key)) {
      errors.push(`Batch key "${key}" is not in the research schema.`);
    }
  }
  const state = batch.state;
  if (typeof state !== "string" || state.trim() === "") {
    errors.push("Batch state is required.");
  } else if (!STATE_BOUNDS[state]) {
    errors.push(`Batch state "${state}" has no bounding box.`);
  }
  if (typeof batch.owner !== "string" || batch.owner.trim() === "") {
    errors.push("Batch owner is required.");
  }
  if (typeof batch.generated !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(batch.generated)) {
    errors.push("Batch generated must be a YYYY-MM-DD date.");
  }
  if (!Number.isInteger(batch.existing_in_prod) || batch.existing_in_prod < 0) {
    errors.push("Batch existing_in_prod must be a non-negative integer.");
  }
  if (!Number.isInteger(batch.target) || batch.target < 1) {
    errors.push("Batch target must be a positive integer.");
  }
  if (!Array.isArray(batch.temples)) {
    errors.push("Batch temples must be a list.");
    return fail(errors);
  }
  if (batch.temples.length === 0) {
    errors.push("Batch temples is empty.");
  }
  if (batch.temples.length > MAX_TEMPLES_PER_BATCH) {
    errors.push(
      `Batch has ${batch.temples.length} temples; the maximum is ${MAX_TEMPLES_PER_BATCH}.`,
    );
  }

  const existingById = new Map(existing.map((temple) => [temple.id, temple]));
  const seenIds = new Set();
  const temples = [];
  const located = [];

  batch.temples.forEach((raw, index) => {
    const label = `temples[${index}]`;
    const before = errors.length;
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
      errors.push(`${label} must be an object.`);
      return;
    }
    for (const key of Object.keys(raw)) {
      if (!TEMPLE_KEYS.includes(key)) {
        const banned = FORBIDDEN.includes(key) ? " It is not a seed field." : "";
        errors.push(`${label} must not include ${key}.${banned}`);
      }
    }
    if (typeof raw.slug !== "string" || raw.slug.trim() === "") {
      errors.push(`${label}.slug is required.`);
      return;
    }
    const id = raw.slug.trim();
    const name = requireString(raw.name, `${label}.name`, errors);
    const templeState = requireString(raw.state, `${label}.state`, errors);
    if (typeof state === "string" && templeState && templeState !== state) {
      errors.push(`${label}.state is "${templeState}" but the batch state is "${state}".`);
    }
    if (name && id !== templeDocumentId(name)) {
      errors.push(
        `${label}.slug is "${id}" but the name slug is "${templeDocumentId(name)}".`,
      );
    }
    if (seenIds.has(id)) errors.push(`${label}.slug "${id}" is duplicated in this batch.`);
    seenIds.add(id);

    requireString(raw.city, `${label}.city`, errors);
    requireString(raw.deity, `${label}.deity`, errors);
    const description = requireString(raw.description, `${label}.description`, errors);
    if (description) {
      const sentences = sentenceCount(description);
      if (sentences < 2 || sentences > 4) {
        errors.push(
          `${label}.description must be 2–4 sentences (found ${sentences}).`,
        );
      }
    }
    const timings = readTimings(raw, label, errors);
    const specialities = requireStringList(
      raw.specialities,
      `${label}.specialities`,
      errors,
    );
    if (specialities && (specialities.length < 3 || specialities.length > 5)) {
      errors.push(`${label}.specialities must have 3 to 5 entries.`);
    }
    for (const item of specialities ?? []) {
      if (item.length > 200) {
        errors.push(`${label}.specialities has an entry longer than 200 characters.`);
      }
    }

    const sources = readSources(raw.sources, label, errors);
    readPhotoPack(raw.photo_pack, id, label, errors);
    readReview(raw.review, label, errors);
    rejectPlaceholderUrls(raw, label, errors);

    const latitude = requireNumber(raw.latitude, `${label}.latitude`, errors);
    const longitude = requireNumber(raw.longitude, `${label}.longitude`, errors);
    if (latitude != null && decimalPlaces(latitude) !== 4) {
      errors.push(
        `${label}.latitude ${latitude} must be rounded to 4 decimal places.`,
      );
    }
    if (longitude != null && decimalPlaces(longitude) !== 4) {
      errors.push(
        `${label}.longitude ${longitude} must be rounded to 4 decimal places.`,
      );
    }
    if (latitude != null && (latitude < LATITUDE_RANGE.min || latitude > LATITUDE_RANGE.max)) {
      errors.push(
        `${label}.latitude ${latitude} is outside ${LATITUDE_RANGE.min}..${LATITUDE_RANGE.max}.`,
      );
    }
    if (
      longitude != null &&
      (longitude < LONGITUDE_RANGE.min || longitude > LONGITUDE_RANGE.max)
    ) {
      errors.push(
        `${label}.longitude ${longitude} is outside ${LONGITUDE_RANGE.min}..${LONGITUDE_RANGE.max}.`,
      );
    }
    if (templeState && latitude != null && longitude != null) {
      const bounds = STATE_BOUNDS[templeState];
      if (!bounds) {
        errors.push(`${label}.state "${templeState}" has no bounding box.`);
      } else if (!insideBox(latitude, longitude, bounds)) {
        errors.push(
          `${label} coordinates ${latitude}, ${longitude} are outside the ${templeState} bounding box ` +
            `(latitude ${bounds.latMin}..${bounds.latMax}, longitude ${bounds.lngMin}..${bounds.lngMax}).`,
        );
      }
    }

    if (name && latitude != null && longitude != null) {
      located.push({ id, name, latitude, longitude });
    }
    if (
      !name ||
      timings == null ||
      !sources ||
      latitude == null ||
      longitude == null ||
      errors.length > before
    ) {
      return;
    }

    const prior = existingById.get(id);
    const keptGallery = prior && hasVerifiedGallery(prior);
    temples.push({
      id,
      name,
      state: templeState,
      city: String(raw.city),
      deity: String(raw.deity),
      imageUrl: keptGallery ? String(prior.imageUrl ?? "") : "",
      images: keptGallery ? [...prior.images] : [],
      description,
      story: prior?.story ?? "",
      location: prior?.location ?? `${raw.city}, ${templeState}`,
      timings,
      specialities: specialities ?? [],
      latitude,
      longitude,
      photos: keptGallery ? prior.photos ?? [] : [],
      sources,
      photo_pack: raw.photo_pack,
      review: raw.review,
    });
  });

  const summary = { new: [], changed: [], unchanged: [] };
  const nameOwners = new Map();
  for (const prior of existing) {
    const key = normaliseName(prior.name);
    if (key) nameOwners.set(key, prior);
  }

  for (let i = 0; i < located.length; i += 1) {
    const temple = located[i];
    const nameKey = normaliseName(temple.name);
    for (let j = 0; j < i; j += 1) {
      const other = located[j];
      if (normaliseName(other.name) === nameKey) {
        errors.push(
          `${temple.id} duplicates the normalised name of ${other.id}.`,
        );
      }
      if (distanceKm(temple, other) <= DUPLICATE_DISTANCE_KM) {
        errors.push(
          `${temple.id} is within ${DUPLICATE_DISTANCE_KM} km of ${other.id} ` +
            `(${distanceKm(temple, other).toFixed(3)} km).`,
        );
      }
    }
    const prior = existingById.get(temple.id);
    if (prior) {
      if (normaliseName(prior.name) !== nameKey) {
        errors.push(
          `${temple.id} already exists as "${prior.name}" and cannot be reused for "${temple.name}".`,
        );
      }
      continue;
    }
    const owner = nameOwners.get(nameKey);
    if (owner && owner.id !== temple.id) {
      errors.push(
        `${temple.id} duplicates the normalised name of existing ${owner.id} ("${owner.name}").`,
      );
    }
    for (const other of existing) {
      if (other.id === temple.id) continue;
      if (
        Number.isFinite(other.latitude) &&
        Number.isFinite(other.longitude) &&
        distanceKm(temple, other) <= DUPLICATE_DISTANCE_KM
      ) {
        errors.push(
          `${temple.id} is within ${DUPLICATE_DISTANCE_KM} km of existing ${other.id} ` +
            `(${distanceKm(temple, other).toFixed(3)} km).`,
        );
      }
    }
  }

  if (errors.length > 0) return { ok: false, errors, temples: [], summary };

  for (const temple of temples) {
    const prior = existingById.get(temple.id);
    if (!prior) {
      summary.new.push({ id: temple.id, name: temple.name });
      continue;
    }
    const keys = changedKeys(prior, temple).filter(
      (key) => !(hasVerifiedGallery(prior) && ["imageUrl", "images", "photos"].includes(key)),
    );
    if (keys.length === 0) {
      summary.unchanged.push({ id: temple.id, name: temple.name });
    } else {
      summary.changed.push({ id: temple.id, name: temple.name, fields: keys });
    }
  }

  return { ok: true, errors, temples, summary };
}

export function targetShortfall(batch) {
  if (!batch || typeof batch !== "object" || !Array.isArray(batch.temples)) return null;
  const existingCount = Number.isInteger(batch.existing_in_prod) ? batch.existing_in_prod : 0;
  const target = batch.target;
  if (!Number.isInteger(target)) return null;
  const have = existingCount + batch.temples.length;
  if (have >= target) return null;
  const state = typeof batch.state === "string" ? batch.state : "This batch";
  return (
    `${state} has ${batch.temples.length} temples in the file and ` +
    `existing_in_prod ${existingCount} (${have} toward target ${target}).`
  );
}

export function sentenceCount(text) {
  return String(text ?? "")
    .trim()
    .split(/(?<=[.!?])\s+/)
    .map((part) => part.trim())
    .filter(Boolean).length;
}

export function decimalPlaces(value) {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  const text = Object.is(value, -0) ? "0" : value.toString();
  if (/e/i.test(text)) return 99;
  const fraction = text.split(".")[1];
  return fraction ? fraction.length : 0;
}

export function normaliseName(name) {
  return String(name ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "");
}

export function hasVerifiedGallery(doc) {
  if (!doc || typeof doc !== "object") return false;
  const images = Array.isArray(doc.images) ? doc.images : [];
  if (images.some((url) => typeof url === "string" && !isPlaceholderImageUrl(url))) {
    return true;
  }
  if (typeof doc.imageUrl === "string" && !isPlaceholderImageUrl(doc.imageUrl)) {
    return true;
  }
  const photos = Array.isArray(doc.photos) ? doc.photos : [];
  return photos.some(
    (photo) =>
      photo &&
      typeof photo.url === "string" &&
      !isPlaceholderImageUrl(photo.url),
  );
}

export function isPlaceholderImageUrl(raw) {
  const url = String(raw ?? "").trim();
  if (url === "") return true;
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return true;
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return true;
  const host = parsed.hostname.toLowerCase();
  if (host === "") return true;
  for (const known of PLACEHOLDER_HOSTS) {
    if (host === known || host.endsWith(`.${known}`) || host.includes("picsum.photos")) {
      return true;
    }
  }
  const blob = `${parsed.pathname} ${parsed.search}`.toLowerCase();
  if (blob.includes("placeholder") || blob.includes("picsum") || blob.includes("stock")) {
    return true;
  }
  return false;
}

export function distanceKm(left, right) {
  const earthKm = 6371;
  const toRad = (degrees) => (degrees * Math.PI) / 180;
  const dLat = toRad(right.latitude - left.latitude);
  const dLng = toRad(right.longitude - left.longitude);
  const lat1 = toRad(left.latitude);
  const lat2 = toRad(right.latitude);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * earthKm * Math.asin(Math.min(1, Math.sqrt(a)));
}

function insideBox(latitude, longitude, bounds) {
  return (
    latitude >= bounds.latMin &&
    latitude <= bounds.latMax &&
    longitude >= bounds.lngMin &&
    longitude <= bounds.lngMax
  );
}

function readTimings(raw, label, errors) {
  if (!Object.prototype.hasOwnProperty.call(raw, "timings")) {
    errors.push(`${label}.timings is required (a string, or null with timings_note).`);
    return null;
  }
  if (raw.timings === null) {
    if (typeof raw.timings_note !== "string" || raw.timings_note.trim() === "") {
      errors.push(`${label}.timings is null and needs a timings_note.`);
      return null;
    }
    if (raw.timings_note.length > 1000) {
      errors.push(`${label}.timings_note is longer than 1000 characters.`);
    }
    return raw.timings_note;
  }
  if (typeof raw.timings !== "string" || raw.timings.trim() === "") {
    errors.push(`${label}.timings must be a non-empty string or null.`);
    return null;
  }
  if (raw.timings.length > 1000) {
    errors.push(`${label}.timings is longer than 1000 characters.`);
  }
  return raw.timings;
}

function readSources(raw, label, errors) {
  if (!Array.isArray(raw) || raw.length === 0) {
    errors.push(`${label}.sources must list at least one {field, title, url}.`);
    return null;
  }
  const sources = [];
  raw.forEach((source, index) => {
    const where = `${label}.sources[${index}]`;
    if (!source || typeof source !== "object" || Array.isArray(source)) {
      errors.push(`${where} must be an object with field, title, and url.`);
      return;
    }
    for (const key of Object.keys(source)) {
      if (!["field", "title", "url"].includes(key)) {
        errors.push(`${where} must not include ${key}.`);
      }
    }
    const field = requireString(source.field, `${where}.field`, errors);
    const title = requireString(source.title, `${where}.title`, errors);
    const url = requireString(source.url, `${where}.url`, errors);
    if (url && !url.startsWith("https://")) {
      errors.push(`${where}.url must start with https://.`);
    }
    if (field && title && url) sources.push({ field, title, url });
  });
  return sources;
}

function readPhotoPack(raw, slug, label, errors) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    errors.push(`${label}.photo_pack is required and must be an object.`);
    return;
  }
  const path = requireString(raw.path, `${label}.photo_pack.path`, errors);
  if (path && path !== `photos/${slug}/`) {
    errors.push(`${label}.photo_pack.path must be photos/${slug}/.`);
  }
  if (raw.status !== "READY" && raw.status !== "SHORTFALL") {
    errors.push(`${label}.photo_pack.status must be READY or SHORTFALL.`);
  }
  if (!Number.isInteger(raw.count) || raw.count < 0) {
    errors.push(`${label}.photo_pack.count must be a non-negative integer.`);
  } else if (raw.status === "READY" && raw.count < 5) {
    errors.push(`${label}.photo_pack.status is READY but count is ${raw.count} (need at least 5).`);
  }
}

function readReview(raw, label, errors) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    errors.push(`${label}.review is required and must be an object.`);
    return;
  }
  for (const key of Object.keys(raw)) {
    if (!["status", "reviewer", "notes"].includes(key)) {
      errors.push(`${label}.review must not include ${key}.`);
    }
  }
  requireString(raw.status, `${label}.review.status`, errors);
  requireString(raw.reviewer, `${label}.review.reviewer`, errors);
  if (typeof raw.notes !== "string") {
    errors.push(`${label}.review.notes must be a string.`);
  }
}

function rejectPlaceholderUrls(raw, label, errors) {
  const urls = [];
  collectUrls(raw, urls);
  for (const url of urls) {
    if (isPlaceholderImageUrl(url)) {
      errors.push(`${label} rejects placeholder or stock image URL ${url}.`);
    }
  }
}

function collectUrls(value, urls) {
  if (typeof value === "string") {
    if (value.startsWith("http://") || value.startsWith("https://")) urls.push(value);
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectUrls(item, urls);
    return;
  }
  if (value && typeof value === "object") {
    for (const nested of Object.values(value)) collectUrls(nested, urls);
  }
}

function requireString(value, label, errors) {
  if (typeof value !== "string" || value.trim() === "") {
    errors.push(`${label} must be a non-empty string.`);
    return null;
  }
  return value;
}

function requireStringList(value, label, errors) {
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
    errors.push(`${label} must be a list of strings.`);
    return null;
  }
  return value;
}

function requireNumber(value, label, errors) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    errors.push(`${label} must be a finite number.`);
    return null;
  }
  return value;
}

function fail(errors) {
  return {
    ok: false,
    errors,
    temples: [],
    summary: { new: [], changed: [], unchanged: [] },
  };
}

export function formatSummary(summary) {
  const lines = [
    `new: ${summary.new.length}`,
    `changed: ${summary.changed.length}`,
    `unchanged: ${summary.unchanged.length}`,
  ];
  for (const row of summary.new) lines.push(`  new ${row.id}`);
  for (const row of summary.changed) {
    lines.push(`  changed ${row.id} (${row.fields.join(", ")})`);
  }
  for (const row of summary.unchanged) lines.push(`  unchanged ${row.id}`);
  return lines.join("\n");
}
