/**
 * Validate a Research state batch and classify it against existing temples.
 * Pure: no Firestore, no file writes.
 *
 * Research files use slug (not id). timings may be null when timings_note is
 * set. story and location are forbidden. sources, photo_pack, and review are
 * required. The NE research README was not in this repo; this is that
 * contract plus the directory fields a seed document still needs.
 */
import { changedKeys, templeDocumentId } from "./temple_seed.js";

export const MAX_TEMPLES_PER_BATCH = 50;
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

const FORBIDDEN = ["id", "story", "location"];

const CC_LICENCES = new Set(["CC-BY", "CC-BY-SA"]);
const LICENCES = new Set(["CC-BY", "CC-BY-SA", "CC0", "Own", "Permission"]);

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
  const state = batch.state;
  if (typeof state !== "string" || state.trim() === "") {
    errors.push("Batch state is required.");
  } else if (!STATE_BOUNDS[state]) {
    errors.push(`Batch state "${state}" has no bounding box.`);
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

  batch.temples.forEach((raw, index) => {
    const label = `temples[${index}]`;
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
      errors.push(`${label} must be an object.`);
      return;
    }
    for (const key of FORBIDDEN) {
      if (Object.prototype.hasOwnProperty.call(raw, key)) {
        errors.push(`${label} must not include ${key}. Use slug, and omit story and location.`);
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
    requireString(raw.description, `${label}.description`, errors);
    const timings = readTimings(raw, label, errors);
    const specialities = requireStringList(
      raw.specialities,
      `${label}.specialities`,
      errors,
    );
    if (specialities && (specialities.length === 0 || specialities.length > 20)) {
      errors.push(`${label}.specialities must have 1 to 20 entries.`);
    }
    for (const item of specialities ?? []) {
      if (item.length > 200) {
        errors.push(`${label}.specialities has an entry longer than 200 characters.`);
      }
    }

    const sources = requireStringList(raw.sources, `${label}.sources`, errors);
    if (sources && sources.length === 0) {
      errors.push(`${label}.sources must list at least one source.`);
    }
    for (const source of sources ?? []) {
      if (source.trim() === "") errors.push(`${label}.sources has an empty entry.`);
    }
    if (!raw.photo_pack || typeof raw.photo_pack !== "object" || Array.isArray(raw.photo_pack)) {
      errors.push(`${label}.photo_pack is required and must be an object.`);
    }
    if (!raw.review || typeof raw.review !== "object" || Array.isArray(raw.review)) {
      errors.push(`${label}.review is required and must be an object.`);
    } else if (!reviewHasContent(raw.review)) {
      errors.push(`${label}.review needs a status, reviewer, or note.`);
    }

    const images = readImages(raw, label, errors);
    const photos = readPhotos(raw, images, label, errors);
    rejectPlaceholderUrls(raw, label, errors);

    const latitude = requireNumber(raw.latitude, `${label}.latitude`, errors);
    const longitude = requireNumber(raw.longitude, `${label}.longitude`, errors);
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

    if (!name || timings == null || !images || !photos || latitude == null || longitude == null) {
      return;
    }

    const prior = existingById.get(id);
    const keptGallery = prior && hasVerifiedGallery(prior);
    const imageUrl = keptGallery
      ? String(prior.imageUrl ?? "")
      : images.length > 0
        ? images[0]
        : "";
    const keptImages = keptGallery ? [...prior.images] : images;
    const keptPhotos = keptGallery ? prior.photos ?? [] : photos;

    temples.push({
      id,
      name,
      state: templeState,
      city: String(raw.city),
      deity: String(raw.deity),
      imageUrl,
      images: keptImages,
      description: String(raw.description),
      story: prior?.story ?? "",
      location: prior?.location ?? `${raw.city}, ${templeState}`,
      timings,
      specialities: specialities ?? [],
      latitude,
      longitude,
      photos: keptPhotos,
      sources,
      photo_pack: raw.photo_pack,
      review: raw.review,
    });
  });

  const summary = { new: [], changed: [], unchanged: [] };
  if (errors.length > 0) return { ok: false, errors, temples: [], summary };

  const nameOwners = new Map();
  for (const prior of existing) {
    const key = normaliseName(prior.name);
    if (key) nameOwners.set(key, prior);
  }

  for (let i = 0; i < temples.length; i += 1) {
    const temple = temples[i];
    const nameKey = normaliseName(temple.name);
    for (let j = 0; j < i; j += 1) {
      const other = temples[j];
      if (normaliseName(other.name) === nameKey) {
        errors.push(
          `${temple.id} duplicates the normalised name of ${other.id}.`,
        );
      }
      if (distanceKm(temple, other) <= DUPLICATE_DISTANCE_KM) {
        errors.push(
          `${temple.id} is within ${DUPLICATE_DISTANCE_KM} km of ${other.id}.`,
        );
      }
    }
    const prior = existingById.get(temple.id);
    if (!prior) {
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
            `${temple.id} is within ${DUPLICATE_DISTANCE_KM} km of existing ${other.id}.`,
          );
        }
      }
      if (!errors.some((error) => error.startsWith(temple.id))) {
        summary.new.push({ id: temple.id, name: temple.name });
      }
      continue;
    }
    if (normaliseName(prior.name) !== nameKey) {
      errors.push(
        `${temple.id} already exists as "${prior.name}" and cannot be reused for "${temple.name}".`,
      );
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

  return { ok: errors.length === 0, errors, temples, summary };
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

function readImages(raw, label, errors) {
  const pack = raw.photo_pack;
  const fromPack =
    pack && typeof pack === "object" && Array.isArray(pack.images) ? pack.images : null;
  const fromTop = Array.isArray(raw.images) ? raw.images : null;
  const chosen = fromPack ?? fromTop ?? [];
  if (!Array.isArray(chosen) || chosen.some((item) => typeof item !== "string")) {
    errors.push(`${label} image list must be strings.`);
    return null;
  }
  for (const url of chosen) {
    if (!url.startsWith("https://")) {
      errors.push(`${label} image URL must start with https://.`);
    }
  }
  if (fromPack && fromTop && fromPack.length > 0 && fromTop.length > 0) {
    if (fromPack.length !== fromTop.length || fromPack.some((url, i) => url !== fromTop[i])) {
      errors.push(`${label}.images must match photo_pack.images.`);
    }
  }
  return chosen;
}

function readPhotos(raw, images, label, errors) {
  const pack = raw.photo_pack;
  const rawPhotos =
    pack && typeof pack === "object" && Array.isArray(pack.photos)
      ? pack.photos
      : Array.isArray(raw.photos)
        ? raw.photos
        : [];
  if (!Array.isArray(rawPhotos)) {
    errors.push(`${label}.photos must be a list.`);
    return null;
  }
  if (images && rawPhotos.length > 0 && rawPhotos.length !== images.length) {
    errors.push(`${label} photos must have one entry per image URL.`);
  }
  const photos = [];
  rawPhotos.forEach((photo, index) => {
    const where = `${label}.photos[${index}]`;
    if (!photo || typeof photo !== "object") {
      errors.push(`${where} must be an object.`);
      return;
    }
    const url = typeof photo.url === "string" ? photo.url : "";
    const credit = typeof photo.credit === "string" ? photo.credit : "";
    const licence = typeof photo.licence === "string" ? photo.licence : "";
    const order = photo.order;
    if (!url.startsWith("https://")) errors.push(`${where}.url must start with https://.`);
    if (images && images[index] && url !== images[index]) {
      errors.push(`${where}.url must match the image URL at ${index}.`);
    }
    if (!LICENCES.has(licence)) {
      errors.push(`${where}.licence must be CC-BY, CC-BY-SA, CC0, Own, or Permission.`);
    }
    if (CC_LICENCES.has(licence) && credit.trim() === "") {
      errors.push(`${where} needs a credit because ${licence} requires attribution.`);
    }
    if (credit.length > 200) errors.push(`${where}.credit is longer than 200 characters.`);
    if (!Number.isInteger(order) || order < 0 || order > 11) {
      errors.push(`${where}.order must be an integer from 0 to 11.`);
    } else if (order !== index) {
      errors.push(`${where}.order must be ${index}.`);
    }
    photos.push({ url, credit, licence, order: Number(order) });
  });
  return photos;
}

function rejectPlaceholderUrls(raw, label, errors) {
  const urls = [];
  collectUrls(raw.imageUrl, urls);
  collectUrls(raw.images, urls);
  collectUrls(raw.photos, urls);
  collectUrls(raw.photo_pack, urls);
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

function reviewHasContent(review) {
  return Object.values(review).some(
    (value) => typeof value === "string" && value.trim() !== "",
  );
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
