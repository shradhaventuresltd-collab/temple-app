/**
 * Validate a Research state batch and classify it against existing temples.
 * Pure: no Firestore, no file writes.
 *
 * Schema of record: the state-expansion README (Hybrid C).
 * Seeded fields match sampleTemples: name, city, state, deity, latitude,
 * longitude, timings, description, specialities, plus story and location
 * (stored as address). Research-only keys are ignored by Seed and keep the
 * README names: slug, sources, timings_note, dedupe, review, photo_pack,
 * and the batch keys added and shortfall_note.
 * When timings is null, the seeded timings value is null. timings_note is
 * never copied into timings or written as a field.
 * story, location, festivals, pooja_schedule, and trip_planning are forbidden.
 * Seed writes story from the description (2–4 sentences). The story length
 * rule is not relaxed.
 * A slug that already exists (case-insensitive) is always rejected. Nothing
 * is overwritten and nothing is renamed.
 * Only review.status "approved" is seedable. Other statuses are skipped.
 */
import { changedKeys, templeDocumentId } from "./temple_seed.js";

export const MAX_TEMPLES_PER_BATCH = 100;
export const DUPLICATE_DISTANCE_KM = 1;
/** Overlap warnings only when a point is this close to a box edge. */
export const BORDER_MARGIN_DEGREES = 0.3;

/** India, including island territories used by this directory. */
export const LATITUDE_RANGE = Object.freeze({ min: 6, max: 37.5 });
export const LONGITUDE_RANGE = Object.freeze({ min: 68, max: 97.5 });

/**
 * State and union-territory bounding boxes (latMin, latMax, lngMin, lngMax).
 *
 * Built from OpenStreetMap extents (Nominatim bounding boxes, 2026-10-15)
 * and expanded 0.1° outward. Dadra and Nagar Haveli and Daman and Diu is the
 * union of those three territories, so Diu (Gangeshwar 20.7135, 70.9264) is
 * inside. Puducherry is the union-territory relation (Pondicherry, Karaikal,
 * Mahe, Yanam). Boxes are coarse and overlap at some borders. A point outside
 * its padded box is a hard error. A point inside two boxes warns only when it
 * is within 0.3° of an edge of either box. Interior overlap, such as central
 * Telangana, central Haryana, or Jaimangla Garh (25.5922, 86.1613) inside the
 * West Bengal rectangle, does not warn. Tamreswari (27.9417, 95.8472) is near
 * the Assam edge and still warns. Delhi (28.6139, 77.2091) stays outside Bihar.
 */
export const STATE_BOUNDS = Object.freeze({
  "Andaman and Nicobar Islands": box(6.65, 13.78, 92.1, 94.38),
  "Andhra Pradesh": box(12.52, 19.27, 76.66, 84.87),
  "Arunachal Pradesh": box(26.55, 29.48, 91.46, 97.5),
  Assam: box(24.03, 28.08, 89.59, 96.12),
  Bihar: box(24.18, 27.63, 83.22, 88.4),
  Chandigarh: box(30.47, 31, 76.51, 77.04),
  Chhattisgarh: box(17.68, 24.21, 80.14, 84.5),
  "Dadra and Nagar Haveli and Daman and Diu": box(19.94, 20.86, 70.84, 73.32),
  Delhi: box(28.3, 28.99, 76.73, 77.45),
  Goa: box(14.65, 15.91, 73.57, 74.44),
  Gujarat: box(20.01, 24.82, 68.07, 74.58),
  Haryana: box(27.55, 31.03, 74.37, 77.71),
  "Himachal Pradesh": box(30.27, 33.36, 75.49, 79.12),
  "Jammu and Kashmir": box(32.17, 34.89, 73.65, 76.89),
  Jharkhand: box(21.87, 25.45, 83.22, 88.07),
  Karnataka: box(11.49, 18.58, 73.95, 78.69),
  Kerala: box(8.19, 12.9, 74.76, 77.52),
  Ladakh: box(32.23, 35.78, 75.22, 79.57),
  Lakshadweep: box(7.96, 12.71, 71.41, 74.01),
  "Madhya Pradesh": box(20.97, 26.97, 73.92, 82.92),
  Maharashtra: box(15.5, 22.14, 72.55, 81),
  Manipur: box(23.73, 25.8, 92.87, 94.85),
  Meghalaya: box(24.93, 26.22, 89.71, 92.91),
  Mizoram: box(21.84, 24.63, 92.16, 93.54),
  Nagaland: box(25.09, 27.14, 93.22, 95.35),
  Odisha: box(17.71, 22.67, 81.28, 87.59),
  Puducherry: box(10.72, 16.87, 75.42, 82.42),
  Punjab: box(29.44, 32.62, 73.77, 77.04),
  Rajasthan: box(22.95, 30.3, 69.38, 78.38),
  Sikkim: box(26.97, 28.23, 87.91, 89.03),
  "Tamil Nadu": box(7.97, 13.67, 76.13, 80.46),
  Telangana: box(15.73, 20.02, 77.13, 81.43),
  Tripura: box(22.83, 24.64, 91.05, 92.44),
  "Uttar Pradesh": box(23.77, 30.51, 76.98, 84.74),
  Uttarakhand: box(28.62, 31.56, 77.47, 81.15),
  "West Bengal": box(21.44, 27.33, 85.71, 89.99),
});

const BATCH_KEYS = [
  "state",
  "owner",
  "generated",
  "existing_in_prod",
  "target",
  "temples",
  "added",
  "shortfall_note",
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
  "dedupe",
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
  "via.placeholder.com",
  "placehold.co",
  "placehold.it",
  "dummyimage.com",
  "loremflickr.com",
  "placekitten.com",
  "fakeimg.pl",
  "placeimg.com",
  "unsplash.com",
  "source.unsplash.com",
  "shutterstock.com",
  "istockphoto.com",
  "gettyimages.com",
  "pexels.com",
  "stock.adobe.com",
  "freepik.com",
  "dreamstime.com",
  "123rf.com",
  "depositphotos.com",
  "lorempixel.com",
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
  const warnings = [];
  const info = [];
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

  const existingById = new Map(
    existing.map((temple) => [String(temple.id).toLowerCase(), temple]),
  );
  const seenIds = new Set();
  const temples = [];
  const located = [];
  const skipped = [];

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
    const slug = raw.slug.trim();
    const id = slug.toLowerCase();
    const name = requireString(raw.name, `${label}.name`, errors);
    const templeState = requireString(raw.state, `${label}.state`, errors);
    if (typeof state === "string" && templeState && templeState !== state) {
      errors.push(`${label}.state is "${templeState}" but the batch state is "${state}".`);
    }
    if (name && id !== templeDocumentId(name)) {
      errors.push(
        `${label}.slug is "${slug}" but the name slug is "${templeDocumentId(name)}".`,
      );
    }
    if (seenIds.has(id)) errors.push(`${label}.slug "${slug}" is duplicated in this batch.`);
    seenIds.add(id);
    const prior = existingById.get(id);
    if (prior) {
      errors.push(
        `${label}.slug "${slug}" already exists in the directory and will not be overwritten or renamed.`,
      );
    }

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
    const timingsResult = readTimings(raw, label, errors);
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
    const reviewStatus = readReview(raw.review, label, errors);
    rejectPlaceholderUrls(raw, label, errors);

    const latitude = requireNumber(raw.latitude, `${label}.latitude`, errors);
    const longitude = requireNumber(raw.longitude, `${label}.longitude`, errors);
    noteCoordinatePrecision(latitude, `${label}.latitude`, id, errors, warnings);
    noteCoordinatePrecision(longitude, `${label}.longitude`, id, errors, warnings);
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
      } else {
        const overlaps = overlappingStates(latitude, longitude, templeState);
        if (overlaps.length > 0) {
          const others = overlaps.join(" and ");
          warnings.push({
            id,
            message:
              `${label} coordinates ${latitude}, ${longitude} fall inside both the ${templeState} bounding box and ${others}.`,
            reviewNote:
              `Map spot-check: ${latitude}, ${longitude} is inside the padded ${templeState} box and also inside ${others}. ` +
              `Overlapping boxes are a border case.`,
          });
        }
      }
    }

    if (name && latitude != null && longitude != null) {
      located.push({
        id,
        name,
        latitude,
        longitude,
        distinctFrom: distinctFromSlugs(raw.dedupe),
        dedupeReason: dedupeReasonText(raw.dedupe),
      });
    }
    if (reviewStatus && reviewStatus !== "approved") {
      skipped.push({
        id,
        name: name ?? id,
        reason: `review status is "${reviewStatus}", not approved`,
      });
    }

    if (
      !name ||
      !timingsResult.ok ||
      !sources ||
      latitude == null ||
      longitude == null ||
      errors.length > before ||
      reviewStatus !== "approved"
    ) {
      return;
    }

    temples.push({
      id,
      name,
      state: templeState,
      city: String(raw.city),
      deity: String(raw.deity),
      imageUrl: "",
      images: [],
      description,
      story: description,
      location: `${raw.city}, ${templeState}`,
      timings: timingsResult.value,
      specialities: specialities ?? [],
      latitude,
      longitude,
      photos: [],
    });
  });

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
      recordProximity(temple, other, errors, warnings, info, false);
    }
    const prior = existingById.get(temple.id);
    if (prior) {
      for (const other of existing) {
        if (String(other.id).toLowerCase() === temple.id) continue;
        recordProximity(temple, other, errors, warnings, info, true);
      }
      continue;
    }
    const owner = nameOwners.get(nameKey);
    if (owner && String(owner.id).toLowerCase() !== temple.id) {
      errors.push(
        `${temple.id} duplicates the normalised name of existing ${owner.id} ("${owner.name}").`,
      );
    }
    for (const other of existing) {
      if (String(other.id).toLowerCase() === temple.id) continue;
      recordProximity(temple, other, errors, warnings, info, true);
    }
  }

  if (errors.length > 0) {
    return {
      ok: false,
      errors,
      warnings,
      info,
      temples: [],
      summary: { ...emptySummary(), skipped },
    };
  }

  const summary = { ...emptySummary(), skipped };
  for (const temple of temples) {
    const prior = existingById.get(temple.id);
    if (!prior) {
      summary.new.push({ id: temple.id, name: temple.name });
      continue;
    }
    const locked = new Set([
      "name",
      "state",
      "imageUrl",
      "images",
      "photos",
      "story",
      "location",
    ]);
    const keys = changedKeys(prior, temple).filter((key) => !locked.has(key));
    if (keys.length === 0) {
      summary.unchanged.push({ id: temple.id, name: temple.name });
    } else {
      summary.changed.push({ id: temple.id, name: temple.name, fields: keys });
    }
  }

  return { ok: true, errors, warnings, info, temples, summary };
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

/**
 * 2 or fewer decimal places is a hard error. Exactly 3 is a warning.
 * 4 or more are accepted. JSON numbers drop trailing zeros, so a 4-decimal
 * value can arrive with fewer places.
 */
function noteCoordinatePrecision(value, label, id, errors, warnings) {
  if (value == null) return;
  const places = decimalPlaces(value);
  if (places == null || places >= 4) return;
  if (places <= 2) {
    const noun = places === 1 ? "place" : "places";
    errors.push(
      `${label} ${value} has ${places} decimal ${noun}; coordinates need 4 or more.`,
    );
    return;
  }
  warnings.push({
    id,
    message: `${label} ${value} has 3 decimal places.`,
    reviewNote:
      `${label} ${value} has 3 decimal places. Four or more are accepted. ` +
      `JSON drops trailing zeros, so confirm the cited source was not rounded further.`,
  });
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
  if (blob.includes("placeholder") || blob.includes("picsum")) {
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

function distanceToBoxEdge(latitude, longitude, bounds) {
  return Math.min(
    latitude - bounds.latMin,
    bounds.latMax - latitude,
    longitude - bounds.lngMin,
    bounds.lngMax - longitude,
  );
}

function overlappingStates(latitude, longitude, templeState) {
  const own = STATE_BOUNDS[templeState];
  const ownEdge = distanceToBoxEdge(latitude, longitude, own);
  const names = [];
  for (const [name, bounds] of Object.entries(STATE_BOUNDS)) {
    if (name === templeState) continue;
    if (!insideBox(latitude, longitude, bounds)) continue;
    const otherEdge = distanceToBoxEdge(latitude, longitude, bounds);
    if (ownEdge <= BORDER_MARGIN_DEGREES || otherEdge <= BORDER_MARGIN_DEGREES) {
      names.push(name);
    }
  }
  return names;
}

function readTimings(raw, label, errors) {
  if (!Object.prototype.hasOwnProperty.call(raw, "timings")) {
    errors.push(`${label}.timings is required (a string, or null with timings_note).`);
    return { ok: false, value: null };
  }
  if (raw.timings === null) {
    if (typeof raw.timings_note !== "string" || raw.timings_note.trim() === "") {
      errors.push(`${label}.timings is null and needs a timings_note.`);
      return { ok: false, value: null };
    }
    if (raw.timings_note.length > 1000) {
      errors.push(`${label}.timings_note is longer than 1000 characters.`);
    }
    return { ok: true, value: null };
  }
  if (typeof raw.timings !== "string" || raw.timings.trim() === "") {
    errors.push(`${label}.timings must be a non-empty string or null.`);
    return { ok: false, value: null };
  }
  if (raw.timings.length > 1000) {
    errors.push(`${label}.timings is longer than 1000 characters.`);
  }
  return { ok: true, value: raw.timings };
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

/** On-disk root for research photo packs. photo_pack.path is photos/<slug>/ under this root. */
export const TEMPLE_RESEARCH_ROOT = "/workspace/temple-research";

/**
 * Canonical pack directory. In a batch file this is `photo_pack.path`
 * `photos/<slug>/`, rooted at TEMPLE_RESEARCH_ROOT.
 */
export function canonicalPhotoPackPath(slug) {
  return `${TEMPLE_RESEARCH_ROOT}/photos/${slug}/`;
}

function photoPackPathAccepted(path, slug) {
  const value = String(path).toLowerCase();
  return value === `photos/${slug}/` || value === canonicalPhotoPackPath(slug).toLowerCase();
}

function readPhotoPack(raw, slug, label, errors) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    errors.push(`${label}.photo_pack is required and must be an object.`);
    return;
  }
  const path = requireString(raw.path, `${label}.photo_pack.path`, errors);
  if (path && !photoPackPathAccepted(path, slug)) {
    errors.push(
      `${label}.photo_pack.path must be photos/${slug}/ ` +
        `(${canonicalPhotoPackPath(slug)}).`,
    );
  }
  // Extra photo_pack keys (photos, photosShort, commons_category, …) are
  // research-only. Seed does not read them.
  const statuses = ["READY", "SHORTFALL", "PENDING", "NO_CATEGORY"];
  if (!statuses.includes(raw.status)) {
    errors.push(
      `${label}.photo_pack.status must be READY, SHORTFALL, PENDING, or NO_CATEGORY.`,
    );
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
    return null;
  }
  for (const key of Object.keys(raw)) {
    if (!["status", "reviewer", "notes"].includes(key)) {
      errors.push(`${label}.review must not include ${key}.`);
    }
  }
  const status = requireString(raw.status, `${label}.review.status`, errors);
  requireString(raw.reviewer, `${label}.review.reviewer`, errors);
  if (typeof raw.notes !== "string") {
    errors.push(`${label}.review.notes must be a string.`);
  }
  return status;
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
    for (const [key, nested] of Object.entries(value)) {
      if (key === "sources") continue;
      collectUrls(nested, urls);
    }
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

function emptySummary() {
  return { new: [], changed: [], unchanged: [], skipped: [] };
}

function distinctFromSlugs(dedupe) {
  if (!dedupe || typeof dedupe !== "object" || Array.isArray(dedupe)) return [];
  const list = dedupe.distinct_from;
  if (!Array.isArray(list)) return [];
  return list
    .filter((item) => typeof item === "string" && item.trim() !== "")
    .map((item) => item.trim().toLowerCase());
}

function listsDistinct(record, otherId) {
  const list = record.distinctFrom ?? distinctFromSlugs(record.dedupe);
  return list.includes(String(otherId).toLowerCase());
}

function dedupeReasonText(dedupe) {
  if (!dedupe || typeof dedupe !== "object" || Array.isArray(dedupe)) return "";
  return typeof dedupe.reason === "string" ? dedupe.reason.trim() : "";
}

function reasonNamesTemple(reason, temple) {
  const text = String(reason ?? "").toLowerCase();
  if (text === "") return false;
  const slug = String(temple.id ?? "").trim().toLowerCase();
  if (slug && text.includes(slug)) return true;
  const name = String(temple.name ?? "").trim().toLowerCase();
  return name !== "" && text.includes(name);
}

function recordProximity(left, right, errors, warnings, info, existing) {
  if (!Number.isFinite(right.latitude) || !Number.isFinite(right.longitude)) return;
  const km = distanceKm(left, right);
  if (km > DUPLICATE_DISTANCE_KM) return;
  const otherLabel = existing ? `existing ${right.id}` : right.id;
  const detail =
    `${left.id} is within ${DUPLICATE_DISTANCE_KM} km of ${otherLabel} (${km.toFixed(3)} km)`;
  const waived = listsDistinct(left, right.id) || listsDistinct(right, left.id);
  if (!waived) {
    errors.push(`${detail}.`);
    return;
  }
  if (!existing) {
    info.push({
      id: left.id,
      message: `${detail}. dedupe.distinct_from lists the other slug.`,
    });
    return;
  }
  const namesDiffer = normaliseName(left.name) !== normaliseName(right.name);
  const reason = typeof left.dedupeReason === "string" ? left.dedupeReason.trim() : "";
  if (!namesDiffer || !reasonNamesTemple(reason, right)) {
    errors.push(
      `${detail}. A distinct_from pair with an existing temple needs a different normalised name and a dedupe.reason that names the other temple by slug or name.`,
    );
    return;
  }
  warnings.push({
    id: left.id,
    message: `${detail}. dedupe.distinct_from lists the other slug.`,
    reviewNote: reason,
  });
}

function fail(errors) {
  return {
    ok: false,
    errors,
    warnings: [],
    info: [],
    temples: [],
    summary: emptySummary(),
  };
}

export function formatSummary(summary) {
  const skipped = summary.skipped ?? [];
  const lines = [
    `new: ${summary.new.length}`,
    `changed: ${summary.changed.length}`,
    `unchanged: ${summary.unchanged.length}`,
    `skipped: ${skipped.length}`,
  ];
  for (const row of summary.new) lines.push(`  new ${row.id}`);
  for (const row of summary.changed) {
    lines.push(`  changed ${row.id} (${row.fields.join(", ")})`);
  }
  for (const row of summary.unchanged) lines.push(`  unchanged ${row.id}`);
  for (const row of skipped) lines.push(`  skipped ${row.id} (${row.reason})`);
  return lines.join("\n");
}

export function formatWarnings(warnings) {
  return (warnings ?? [])
    .map((warning) => `Warning: ${warning.message}\nReview note: ${warning.reviewNote}`)
    .join("\n");
}

export function formatInfo(info) {
  return (info ?? []).map((item) => `Info: ${item.message}`).join("\n");
}
