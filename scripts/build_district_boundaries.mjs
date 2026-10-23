/**
 * Builds assets/districts/india_districts.dsb from the Bharatlas LGD
 * district layer.
 *
 *   node scripts/build_district_boundaries.mjs \
 *     --input /path/LGD_Districts.geojson \
 *     --simplified /path/simplified.geojson
 *
 * Omit --simplified to run mapshaper 0.6.113 (MAPSHAPER, or npx).
 * The 88 MB source is cached under scripts/.cache and is not committed.
 * Accuracy fixtures are written from the seed in lib/data/sample_data.dart.
 */
import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCALE = 10000;
const TOLERANCE_METRES = 500;
const ASSET_VERSION = 'lgd-2024-dsb1-500m';
const SOURCE_NAME = 'Bharatlas LGD Districts (2024)';
const LICENCE = 'CC0-1.0 / CC-BY-4.0';
const ATTRIBUTION =
  'Source: LGD. Published via bharatlas (bharatlas.com). Licence: CC0-1.0 / CC-BY-4.0.';
const DOWNLOAD =
  'https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson';
const SOURCE_PAGE = 'https://bharatlas.com/view/lgd_districts';
const UPSTREAM = 'https://lgdirectory.gov.in/';
const MAPSHAPER_VERSION = '0.6.113';
const MAPSHAPER_COMMAND = [
  `mapshaper@${MAPSHAPER_VERSION}`,
  'LGD_Districts.geojson',
  '-filter-fields',
  'dtname,stname,dist_lgd,state_lgd',
  '-proj',
  'aea',
  '-simplify',
  'visvalingam',
  'interval=500',
  'keep-shapes',
  'no-repair',
  '-proj',
  'wgs84',
  '-o',
  'precision=0.0001',
  'format=geojson',
  'simplified.geojson',
].join(' ');

const STATE_DISPLAY = {
  'ANDAMAN & NICOBAR': 'Andaman and Nicobar Islands',
  'ANDHRA PRADESH': 'Andhra Pradesh',
  'ARUNACHAL PRADESH': 'Arunachal Pradesh',
  ASSAM: 'Assam',
  BIHAR: 'Bihar',
  CHANDIGARH: 'Chandigarh',
  CHHATTISGARH: 'Chhattisgarh',
  'DADRA,NAGAR HAVELI,DAMAN & DIU':
    'Dadra and Nagar Haveli and Daman and Diu',
  DELHI: 'Delhi',
  GOA: 'Goa',
  GUJARAT: 'Gujarat',
  HARYANA: 'Haryana',
  'HIMACHAL PRADESH': 'Himachal Pradesh',
  'JAMMU & KASHMIR': 'Jammu and Kashmir',
  JHARKHAND: 'Jharkhand',
  KARNATAKA: 'Karnataka',
  KERALA: 'Kerala',
  LADAKH: 'Ladakh',
  LAKSHADWEEP: 'Lakshadweep',
  'MADHYA PRADESH': 'Madhya Pradesh',
  MAHARASHTRA: 'Maharashtra',
  MANIPUR: 'Manipur',
  MEGHALAYA: 'Meghalaya',
  MIZORAM: 'Mizoram',
  NAGALAND: 'Nagaland',
  ODISHA: 'Odisha',
  PUDUCHERRY: 'Puducherry',
  PUNJAB: 'Punjab',
  RAJASTHAN: 'Rajasthan',
  SIKKIM: 'Sikkim',
  'TAMIL NADU': 'Tamil Nadu',
  TELANGANA: 'Telangana',
  TRIPURA: 'Tripura',
  'UTTAR PRADESH': 'Uttar Pradesh',
  UTTARAKHAND: 'Uttarakhand',
  'WEST BENGAL': 'West Bengal',
};

function arg(name, fallback) {
  const index = process.argv.indexOf(name);
  if (index === -1) return fallback;
  const value = process.argv[index + 1];
  if (!value || value.startsWith('--')) {
    throw new Error(`${name} needs a value`);
  }
  return value;
}

function quantize(value) {
  return Math.round(value * SCALE);
}

function displayState(raw) {
  const mapped = STATE_DISPLAY[raw];
  if (!mapped) throw new Error(`No display name for LGD state "${raw}"`);
  return mapped;
}

function canonicalState(raw) {
  let text = raw.toLowerCase().replaceAll('&', ' and ');
  text = text.replace(/[^a-z0-9]+/g, ' ');
  text = text.replace(/\band\b/g, ' ');
  text = text.replace(/\s+/g, ' ').trim();
  if (text === 'nct of delhi') return 'delhi';
  if (text === 'orissa') return 'odisha';
  if (text === 'pondicherry') return 'puducherry';
  if (text === 'andaman nicobar islands') return 'andaman nicobar';
  return text;
}

function polygonsOf(geometry) {
  if (geometry.type === 'Polygon') return [geometry.coordinates];
  if (geometry.type === 'MultiPolygon') return geometry.coordinates;
  throw new Error(`Unsupported geometry ${geometry.type}`);
}

function preparePolygons(geometry) {
  const polygons = [];
  let minLat = 1 << 30;
  let minLng = 1 << 30;
  let maxLat = -(1 << 30);
  let maxLng = -(1 << 30);
  for (const polygon of polygonsOf(geometry)) {
    const rings = [];
    for (const ring of polygon) {
      const coords = [];
      for (const pair of ring) {
        const lng = quantize(pair[0]);
        const lat = quantize(pair[1]);
        if (
          coords.length >= 2 &&
          coords[coords.length - 2] === lat &&
          coords[coords.length - 1] === lng
        ) {
          continue;
        }
        coords.push(lat, lng);
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
      if (
        coords.length >= 4 &&
        coords[0] === coords[coords.length - 2] &&
        coords[1] === coords[coords.length - 1]
      ) {
        coords.splice(coords.length - 2, 2);
      }
      if (coords.length >= 6) rings.push(coords);
    }
    if (rings.length > 0) polygons.push(rings);
  }
  if (polygons.length === 0) return null;
  return { polygons, minLat, minLng, maxLat, maxLng };
}

function ringAbsCross(ring) {
  const n = ring.length / 2;
  let sum = 0n;
  for (let i = 0; i < n; i++) {
    const y1 = BigInt(ring[i * 2]);
    const x1 = BigInt(ring[i * 2 + 1]);
    const j = (i + 1) % n;
    const y2 = BigInt(ring[j * 2]);
    const x2 = BigInt(ring[j * 2 + 1]);
    sum += x1 * y2 - x2 * y1;
  }
  return sum < 0n ? -sum : sum;
}

function polygonArea(polygons) {
  let area = 0n;
  for (const rings of polygons) {
    if (rings.length === 0) continue;
    let part = ringAbsCross(rings[0]);
    for (let h = 1; h < rings.length; h++) part -= ringAbsCross(rings[h]);
    if (part < 0n) part = -part;
    area += part;
  }
  return area;
}

function inRing(x, y, ring) {
  const n = ring.length / 2;
  let inside = false;
  for (let i = 0; i < n; i++) {
    const y1 = ring[i * 2];
    const x1 = ring[i * 2 + 1];
    const j = (i + 1) % n;
    const y2 = ring[j * 2];
    const x2 = ring[j * 2 + 1];
    const cross = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1);
    if (cross === 0) {
      const dot = (x - x1) * (x2 - x1) + (y - y1) * (y2 - y1);
      const len2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
      if (dot >= 0 && dot <= len2) return true;
    }
    if (y1 > y !== y2 > y) {
      const den = y2 - y1;
      const num = (x2 - x1) * (y - y1);
      const left = (x - x1) * den;
      if ((den > 0 && left < num) || (den < 0 && left > num)) inside = !inside;
    }
  }
  return inside;
}

function contains(district, latQ, lngQ) {
  for (const rings of district.polygons) {
    if (rings.length === 0 || !inRing(lngQ, latQ, rings[0])) continue;
    let hole = false;
    for (let r = 1; r < rings.length; r++) {
      if (inRing(lngQ, latQ, rings[r])) {
        hole = true;
        break;
      }
    }
    if (!hole) return true;
  }
  return false;
}

function bboxDistance(district, latitude, longitude) {
  const minLatitude = district.minLat / SCALE;
  const maxLatitude = district.maxLat / SCALE;
  const minLongitude = district.minLng / SCALE;
  const maxLongitude = district.maxLng / SCALE;
  const dLng =
    longitude < minLongitude
      ? minLongitude - longitude
      : longitude > maxLongitude
        ? longitude - maxLongitude
        : 0;
  const dLat =
    latitude < minLatitude
      ? minLatitude - latitude
      : latitude > maxLatitude
        ? latitude - maxLatitude
        : 0;
  const kx = 111320 * Math.cos((latitude * Math.PI) / 180);
  return Math.hypot(dLng * kx, dLat * 110540);
}

function nearer(candidate, best) {
  if (candidate.distance < best.distance) return true;
  if (candidate.distance > best.distance) return false;
  if (candidate.area < best.area) return true;
  if (candidate.area > best.area) return false;
  if (candidate.lgd !== best.lgd) return candidate.lgd < best.lgd;
  return candidate.name < best.name;
}

function locate(districts, latitude, longitude) {
  const latQ = quantize(latitude);
  const lngQ = quantize(longitude);
  const hits = [];
  for (const district of districts) {
    if (
      lngQ < district.minLng ||
      lngQ > district.maxLng ||
      latQ < district.minLat ||
      latQ > district.maxLat
    ) {
      continue;
    }
    if (contains(district, latQ, lngQ)) hits.push(district);
  }
  if (hits.length > 0) {
    hits.sort((a, b) => {
      if (a.area < b.area) return -1;
      if (a.area > b.area) return 1;
      if (a.lgd !== b.lgd) return a.lgd - b.lgd;
      return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
    });
    return { district: hits[0], inside: true };
  }
  let best = districts[0];
  let bestKey = {
    distance: bboxDistance(best, latitude, longitude),
    area: best.area,
    lgd: best.lgd,
    name: best.name,
  };
  for (let i = 1; i < districts.length; i++) {
    const district = districts[i];
    const key = {
      distance: bboxDistance(district, latitude, longitude),
      area: district.area,
      lgd: district.lgd,
      name: district.name,
    };
    if (nearer(key, bestKey)) {
      best = district;
      bestKey = key;
    }
  }
  return { district: best, inside: false };
}

function hitsAt(districts, latitude, longitude) {
  const latQ = quantize(latitude);
  const lngQ = quantize(longitude);
  const hits = [];
  for (const district of districts) {
    if (
      lngQ < district.minLng ||
      lngQ > district.maxLng ||
      latQ < district.minLat ||
      latQ > district.maxLat
    ) {
      continue;
    }
    if (contains(district, latQ, lngQ)) {
      hits.push({
        lgd: district.lgd,
        name: district.name,
        state: district.stateName,
      });
    }
  }
  hits.sort((a, b) => a.lgd - b.lgd || (a.name < b.name ? -1 : 1));
  return hits;
}

function loadDistricts(geojsonPath) {
  const collection = JSON.parse(fs.readFileSync(geojsonPath, 'utf8'));
  const districts = [];
  for (const feature of collection.features) {
    const props = feature.properties ?? {};
    const name = String(props.dtname ?? '');
    const rawState = String(props.stname ?? '');
    const lgd = Number(props.dist_lgd);
    const stateLgd = Number(props.state_lgd);
    if (!name || !rawState || !Number.isFinite(lgd) || !Number.isFinite(stateLgd)) {
      throw new Error(`District feature is missing LGD fields: ${name}`);
    }
    const prepared = preparePolygons(feature.geometry);
    if (!prepared) throw new Error(`District ${name} has no rings`);
    districts.push({
      lgd,
      stateLgd,
      name,
      stateName: displayState(rawState),
      rawState,
      ...prepared,
      area: polygonArea(prepared.polygons),
    });
  }
  districts.sort((a, b) => a.lgd - b.lgd || (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  return districts;
}

function encode(districts) {
  const strings = [];
  const interned = new Map();
  function intern(text) {
    const existing = interned.get(text);
    if (existing) return existing;
    const offset = strings.reduce((sum, item) => sum + Buffer.byteLength(item), 0);
    const len = Buffer.byteLength(text);
    if (offset > 65535 || len > 65535) {
      throw new Error(`String table exceeds uint16 (${text})`);
    }
    const ref = { offset, len };
    interned.set(text, ref);
    strings.push(text);
    return ref;
  }

  const rows = districts.map((district) => ({
    ...district,
    nameRef: intern(district.name),
    stateRef: intern(district.stateName),
  }));
  const table = Buffer.concat(strings.map((item) => Buffer.from(item, 'utf8')));
  if (table.length > 65535) {
    throw new Error(`String table is ${table.length} bytes`);
  }

  let points = 0;
  let size = 20 + table.length;
  for (const district of rows) {
    // lgd, state lgd, four uint16 string refs, four int32 bbox, polygon count.
    size += 34;
    for (const rings of district.polygons) {
      size += 2;
      for (const ring of rings) {
        const count = ring.length / 2;
        if (count > 65535) throw new Error(`Ring too long in ${district.name}`);
        points += count;
        size += 2 + count * 8;
      }
    }
  }
  if (rows.length > 65535) throw new Error('Too many districts');

  const buffer = Buffer.alloc(size);
  let offset = 0;
  buffer.write('DSB1', offset, 'ascii');
  offset += 4;
  buffer.writeUInt16LE(1, offset);
  offset += 2;
  buffer.writeUInt16LE(rows.length, offset);
  offset += 2;
  buffer.writeUInt32LE(table.length, offset);
  offset += 4;
  buffer.writeUInt32LE(points, offset);
  offset += 4;
  buffer.writeUInt32LE(TOLERANCE_METRES, offset);
  offset += 4;
  table.copy(buffer, offset);
  offset += table.length;

  for (const district of rows) {
    buffer.writeUInt32LE(district.lgd, offset);
    offset += 4;
    buffer.writeUInt32LE(district.stateLgd, offset);
    offset += 4;
    buffer.writeUInt16LE(district.nameRef.offset, offset);
    offset += 2;
    buffer.writeUInt16LE(district.nameRef.len, offset);
    offset += 2;
    buffer.writeUInt16LE(district.stateRef.offset, offset);
    offset += 2;
    buffer.writeUInt16LE(district.stateRef.len, offset);
    offset += 2;
    buffer.writeInt32LE(district.minLat, offset);
    offset += 4;
    buffer.writeInt32LE(district.minLng, offset);
    offset += 4;
    buffer.writeInt32LE(district.maxLat, offset);
    offset += 4;
    buffer.writeInt32LE(district.maxLng, offset);
    offset += 4;
    buffer.writeUInt16LE(district.polygons.length, offset);
    offset += 2;
    for (const rings of district.polygons) {
      buffer.writeUInt16LE(rings.length, offset);
      offset += 2;
      for (const ring of rings) {
        const count = ring.length / 2;
        buffer.writeUInt16LE(count, offset);
        offset += 2;
        buffer.writeInt32LE(ring[0], offset);
        offset += 4;
        buffer.writeInt32LE(ring[1], offset);
        offset += 4;
        let prevLat = ring[0];
        let prevLng = ring[1];
        for (let n = 1; n < count; n++) {
          const lat = ring[n * 2];
          const lng = ring[n * 2 + 1];
          buffer.writeInt32LE(lat - prevLat, offset);
          offset += 4;
          buffer.writeInt32LE(lng - prevLng, offset);
          offset += 4;
          prevLat = lat;
          prevLng = lng;
        }
      }
    }
  }
  if (offset !== size) throw new Error(`Encoder wrote ${offset} of ${size}`);
  return { buffer, points };
}

function decode(buffer) {
  let offset = 0;
  const magic = buffer.toString('ascii', offset, offset + 4);
  offset += 4;
  if (magic !== 'DSB1') throw new Error(`Bad magic ${magic}`);
  const version = buffer.readUInt16LE(offset);
  offset += 2;
  if (version !== 1) throw new Error(`Bad version ${version}`);
  const count = buffer.readUInt16LE(offset);
  offset += 2;
  const stringBytes = buffer.readUInt32LE(offset);
  offset += 4;
  const pointCount = buffer.readUInt32LE(offset);
  offset += 4;
  const tolerance = buffer.readUInt32LE(offset);
  offset += 4;
  const table = buffer.subarray(offset, offset + stringBytes);
  offset += stringBytes;
  const districts = [];
  for (let i = 0; i < count; i++) {
    const lgd = buffer.readUInt32LE(offset);
    offset += 4;
    const stateLgd = buffer.readUInt32LE(offset);
    offset += 4;
    const nameOff = buffer.readUInt16LE(offset);
    offset += 2;
    const nameLen = buffer.readUInt16LE(offset);
    offset += 2;
    const stateOff = buffer.readUInt16LE(offset);
    offset += 2;
    const stateLen = buffer.readUInt16LE(offset);
    offset += 2;
    const minLat = buffer.readInt32LE(offset);
    offset += 4;
    const minLng = buffer.readInt32LE(offset);
    offset += 4;
    const maxLat = buffer.readInt32LE(offset);
    offset += 4;
    const maxLng = buffer.readInt32LE(offset);
    offset += 4;
    const polygonCount = buffer.readUInt16LE(offset);
    offset += 2;
    const polygons = [];
    for (let p = 0; p < polygonCount; p++) {
      const ringCount = buffer.readUInt16LE(offset);
      offset += 2;
      const rings = [];
      for (let r = 0; r < ringCount; r++) {
        const pointCountRing = buffer.readUInt16LE(offset);
        offset += 2;
        const coords = [];
        let lat = buffer.readInt32LE(offset);
        offset += 4;
        let lng = buffer.readInt32LE(offset);
        offset += 4;
        coords.push(lat, lng);
        for (let n = 1; n < pointCountRing; n++) {
          lat += buffer.readInt32LE(offset);
          offset += 4;
          lng += buffer.readInt32LE(offset);
          offset += 4;
          coords.push(lat, lng);
        }
        rings.push(coords);
      }
      polygons.push(rings);
    }
    const name = table.subarray(nameOff, nameOff + nameLen).toString('utf8');
    const stateName = table.subarray(stateOff, stateOff + stateLen).toString('utf8');
    districts.push({
      lgd,
      stateLgd,
      name,
      stateName,
      minLat,
      minLng,
      maxLat,
      maxLng,
      polygons,
      area: polygonArea(polygons),
    });
  }
  if (offset !== buffer.length) throw new Error('Decoder did not consume the asset');
  return { districts, pointCount, tolerance };
}

function largestRingCentroid(geometry) {
  let best = null;
  let bestArea = 0;
  for (const polygon of polygonsOf(geometry)) {
    const ring = polygon[0];
    const closed =
      ring.length > 1 &&
      ring[0][0] === ring[ring.length - 1][0] &&
      ring[0][1] === ring[ring.length - 1][1];
    const count = closed ? ring.length - 1 : ring.length;
    let twice = 0;
    let cx = 0;
    let cy = 0;
    for (let i = 0; i < count; i++) {
      const x1 = ring[i][0];
      const y1 = ring[i][1];
      const next = ring[(i + 1) % count];
      const cross = x1 * next[1] - next[0] * y1;
      twice += cross;
      cx += (x1 + next[0]) * cross;
      cy += (y1 + next[1]) * cross;
    }
    const area = Math.abs(twice) / 2;
    if (area <= bestArea) continue;
    bestArea = area;
    if (Math.abs(twice) < 1e-14) {
      let sx = 0;
      let sy = 0;
      for (let i = 0; i < count; i++) {
        sx += ring[i][0];
        sy += ring[i][1];
      }
      best = [sx / count, sy / count];
    } else {
      best = [cx / (3 * twice), cy / (3 * twice)];
    }
  }
  return best;
}

function assertCentroids(fullCollection, fullDistricts, simplified) {
  const byKey = new Map(simplified.map((district) => [`${district.lgd}|${district.name}`, district]));
  const fullByKey = new Map(fullDistricts.map((district) => [`${district.lgd}|${district.name}`, district]));
  let skipped = 0;
  let checked = 0;
  const failures = [];
  for (const feature of fullCollection.features) {
    const name = String(feature.properties.dtname);
    const lgd = Number(feature.properties.dist_lgd);
    const key = `${lgd}|${name}`;
    const centroid = largestRingCentroid(feature.geometry);
    if (!centroid) throw new Error(`No centroid for ${name}`);
    const [lng, lat] = centroid;
    const source = fullByKey.get(key);
    const simple = byKey.get(key);
    if (!source || !simple) throw new Error(`Missing district ${key}`);
    const latQ = quantize(lat);
    const lngQ = quantize(lng);
    if (!contains(source, latQ, lngQ)) {
      skipped += 1;
      continue;
    }
    checked += 1;
    if (!contains(simple, latQ, lngQ)) {
      failures.push(`${name} (${lgd})`);
    }
  }
  if (failures.length > 0) {
    throw new Error(
      `${failures.length} centroids left their district: ${failures.slice(0, 8).join(', ')}`,
    );
  }
  console.log(`centroids kept ${checked}, skipped non-interior ${skipped}`);
}

function loadTemples() {
  const text = fs.readFileSync(path.join(root, 'lib/data/sample_data.dart'), 'utf8');
  const parts = text.split(/\n  Temple\(/).slice(1);
  const temples = [];
  for (const part of parts) {
    const name = part.match(/name:\s*'((?:\\'|[^'])*)'/)?.[1]?.replace(/\\'/g, "'");
    const state = part.match(/state:\s*'((?:\\'|[^'])*)'/)?.[1];
    const latitude = part.match(/latitude:\s*([-+0-9.]+)/)?.[1];
    const longitude = part.match(/longitude:\s*([-+0-9.]+)/)?.[1];
    if (!name || !state || latitude == null || longitude == null) {
      throw new Error(`Could not read a seed temple near: ${part.slice(0, 120)}`);
    }
    temples.push({
      name,
      state,
      latitude: Number(latitude),
      longitude: Number(longitude),
    });
  }
  if (temples.length < 100) throw new Error(`Only parsed ${temples.length} temples`);
  return temples;
}

function sameDistrict(a, b) {
  return a.lgd === b.lgd && a.name === b.name;
}

function runMapshaper(input, output) {
  const configured = process.env.MAPSHAPER;
  const command = configured ?? 'npx';
  const args = configured
    ? []
    : ['--yes', `mapshaper@${MAPSHAPER_VERSION}`];
  args.push(
    input,
    '-filter-fields',
    'dtname,stname,dist_lgd,state_lgd',
    '-proj',
    'aea',
    '-simplify',
    'visvalingam',
    'interval=500',
    'keep-shapes',
    'no-repair',
    '-proj',
    'wgs84',
    '-o',
    'precision=0.0001',
    'format=geojson',
    output,
  );
  const result = spawnSync(command, args, { stdio: 'inherit' });
  if (result.status !== 0) {
    throw new Error(`mapshaper exited ${result.status}`);
  }
}

function ensureInput(input) {
  if (input && fs.existsSync(input)) return input;
  const cached = path.join(root, 'scripts/.cache/LGD_Districts.geojson');
  if (fs.existsSync(cached)) return cached;
  fs.mkdirSync(path.dirname(cached), { recursive: true });
  console.log(`downloading ${DOWNLOAD}`);
  const result = spawnSync('curl', ['-L', '--fail', '-o', cached, DOWNLOAD], {
    stdio: 'inherit',
  });
  if (result.status !== 0) throw new Error('District download failed');
  return cached;
}

function sha256(file) {
  const hash = crypto.createHash('sha256');
  hash.update(fs.readFileSync(file));
  return hash.digest('hex');
}

function main() {
  const input = ensureInput(arg('--input', ''));
  let simplified = arg('--simplified', '');
  if (!simplified) {
    simplified = path.join(root, 'scripts/.cache/simplified_500_norepair.geojson');
    fs.mkdirSync(path.dirname(simplified), { recursive: true });
    console.log(`simplifying with mapshaper ${MAPSHAPER_VERSION}`);
    runMapshaper(input, simplified);
  }

  console.log('reading simplified districts');
  const simplifiedDistricts = loadDistricts(simplified);
  console.log('reading full districts');
  const fullCollection = JSON.parse(fs.readFileSync(input, 'utf8'));
  const fullDistricts = [];
  for (const feature of fullCollection.features) {
    const name = String(feature.properties.dtname);
    const lgd = Number(feature.properties.dist_lgd);
    const stateLgd = Number(feature.properties.state_lgd);
    const prepared = preparePolygons(feature.geometry);
    if (!prepared) throw new Error(`Full district ${name} has no rings`);
    fullDistricts.push({
      lgd,
      stateLgd,
      name,
      stateName: displayState(String(feature.properties.stname)),
      ...prepared,
      area: polygonArea(prepared.polygons),
    });
  }
  if (simplifiedDistricts.length !== 785 || fullDistricts.length !== 785) {
    throw new Error(
      `Expected 785 districts, got simplified ${simplifiedDistricts.length} full ${fullDistricts.length}`,
    );
  }
  assertCentroids(fullCollection, fullDistricts, simplifiedDistricts);

  const encoded = encode(simplifiedDistricts);
  const decoded = decode(encoded.buffer);
  if (decoded.districts.length !== simplifiedDistricts.length) {
    throw new Error('Round-trip district count mismatch');
  }
  if (decoded.pointCount !== encoded.points) {
    throw new Error('Round-trip point count mismatch');
  }
  if (decoded.tolerance !== TOLERANCE_METRES) throw new Error('Tolerance mismatch');
  for (let i = 0; i < simplifiedDistricts.length; i++) {
    const source = simplifiedDistricts[i];
    const back = decoded.districts[i];
    if (
      source.lgd !== back.lgd ||
      source.name !== back.name ||
      source.stateName !== back.stateName ||
      source.area !== back.area
    ) {
      throw new Error(`Round-trip mismatch at ${source.name}`);
    }
  }

  const probes = [
    { label: 'karaikal', latitude: 10.92, longitude: 79.83, name: 'Karaikal', state: 'Puducherry', inside: true },
    { label: 'mahe-gap', latitude: 11.7, longitude: 75.53, name: 'Mahe', state: 'Puducherry', inside: false },
    { label: 'mahe-interior', latitude: 11.701, longitude: 75.532, name: 'Mahe', state: 'Puducherry', inside: true },
    { label: 'yanam', latitude: 16.73, longitude: 82.21, name: 'Yanam', state: 'Puducherry', inside: true },
    { label: 'meenakshi', latitude: 9.9195, longitude: 78.1193, name: 'Madurai', state: 'Tamil Nadu', inside: true },
    { label: 'sea', latitude: 13, longitude: 81, name: null, state: null, inside: false },
  ];
  for (const probe of probes) {
    const hit = locate(decoded.districts, probe.latitude, probe.longitude);
    probe.resolvedName = hit.district.name;
    probe.resolvedState = hit.district.stateName;
    probe.resolvedInside = hit.inside;
    probe.resolvedLgd = hit.district.lgd;
    if (probe.name && (hit.district.name !== probe.name || hit.district.stateName !== probe.state || hit.inside !== probe.inside)) {
      throw new Error(
        `${probe.label} resolved ${hit.district.name} / ${hit.district.stateName} inside=${hit.inside}`,
      );
    }
    if (!hit.district.name) throw new Error(`${probe.label} was blank`);
    console.log(
      `${probe.label} -> ${hit.district.name} / ${hit.district.stateName} inside=${hit.inside}`,
    );
  }

  const vertex = decoded.districts.find((district) => district.name === 'Madurai');
  const vertexLat = vertex.polygons[0][0][0] / SCALE;
  const vertexLng = vertex.polygons[0][0][1] / SCALE;
  const vertexHit = locate(decoded.districts, vertexLat, vertexLng);
  if (!vertexHit.inside || vertexHit.district.name !== 'Madurai') {
    throw new Error('Madurai boundary vertex is not inside Madurai');
  }

  const temples = loadTemples();
  const assignments = [];
  const simplificationMismatches = [];
  const stateMismatches = [];
  const perState = {};
  for (const temple of temples) {
    const fullHits = hitsAt(fullDistricts, temple.latitude, temple.longitude);
    const located = locate(decoded.districts, temple.latitude, temple.longitude);
    const computed = {
      lgd: located.district.lgd,
      name: located.district.name,
      state: located.district.stateName,
      inside: located.inside,
    };
    const inSet = fullHits.some((hit) => sameDistrict(hit, computed));
    if (!inSet) {
      simplificationMismatches.push({
        name: temple.name,
        state: temple.state,
        latitude: temple.latitude,
        longitude: temple.longitude,
        computed,
        fullHits,
      });
    }
    const stateOk = canonicalState(temple.state) === canonicalState(computed.state);
    if (!stateOk) {
      stateMismatches.push({
        name: temple.name,
        templeState: temple.state,
        district: computed.name,
        districtState: computed.state,
        lgd: computed.lgd,
      });
    }
    const bucket = perState[temple.state] ?? {
      temples: 0,
      resolved: 0,
      stateMismatches: 0,
    };
    bucket.temples += 1;
    bucket.resolved += 1;
    if (!stateOk) bucket.stateMismatches += 1;
    perState[temple.state] = bucket;
    assignments.push({ ...temple, hits: fullHits });
  }
  const rate = simplificationMismatches.length / temples.length;
  if (rate > 0.02) {
    throw new Error(
      `Simplification mismatch rate ${rate} exceeds 2%: ${simplificationMismatches.map((row) => row.name).join(', ')}`,
    );
  }
  console.log(
    `temples ${temples.length}, simplification mismatches ${simplificationMismatches.length} (${(rate * 100).toFixed(2)}%), state mismatches ${stateMismatches.length}`,
  );

  const assetDir = path.join(root, 'assets/districts');
  fs.mkdirSync(assetDir, { recursive: true });
  const assetPath = path.join(assetDir, 'india_districts.dsb');
  fs.writeFileSync(assetPath, encoded.buffer);
  const gzipBytes = zlib.gzipSync(encoded.buffer, { level: 9 }).length;
  if (gzipBytes >= 600 * 1024) {
    throw new Error(`Gzip size ${gzipBytes} is not under 600 KB`);
  }
  const assetSha = crypto.createHash('sha256').update(encoded.buffer).digest('hex');
  const sourceSha = sha256(input);
  const manifest = {
    assetVersion: ASSET_VERSION,
    sha256: assetSha,
    bytes: encoded.buffer.length,
    gzipBytes,
    districts: decoded.districts.length,
    points: encoded.points,
    toleranceMetres: TOLERANCE_METRES,
    source: SOURCE_NAME,
    sourceSha256: sourceSha,
    licence: LICENCE,
    attribution: ATTRIBUTION,
    allowsBundling: true,
  };
  fs.writeFileSync(
    path.join(assetDir, 'manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`,
  );
  const readme = `# India district boundaries

${ATTRIBUTION}

Both CC0-1.0 and CC-BY-4.0 allow this geometry to be bundled in the app.
CC-BY-4.0 requires the credit line above.

- Source: ${SOURCE_NAME}
- Layer: ${SOURCE_PAGE}
- Download: ${DOWNLOAD}
- Upstream: ${UPSTREAM}
- Licence: ${LICENCE}
- Asset version: \`${ASSET_VERSION}\`
- Districts: ${decoded.districts.length} (LGD district code + canonical name)
- Points after quantizing to 4 decimal degrees: ${encoded.points}
- Uncompressed: ${encoded.buffer.length} bytes
- gzip -9 (the size Android deflates into the AAB): ${gzipBytes} bytes
- Source SHA-256: \`${sourceSha}\`
- Asset SHA-256: \`${assetSha}\`

Simplification (mapshaper ${MAPSHAPER_VERSION}), Visvalingam effective area,
topology kept, intersection repair off so shared borders stay aligned and
concave districts keep their centroids:

\`\`\`
${MAPSHAPER_COMMAND}
\`\`\`

\`interval=500\` is 500 metres in the Albers projection mapshaper builds from
the layer. The binary is delta-encoded int32 (\`DSB1\`), not GeoJSON.
District is computed in memory from this asset. It is not a Firestore field
and it is not part of the temple index shard.
`;
  fs.writeFileSync(path.join(assetDir, 'README.md'), readme);

  const fixtureDir = path.join(root, 'test/fixtures');
  fs.mkdirSync(fixtureDir, { recursive: true });
  fs.writeFileSync(
    path.join(fixtureDir, 'district_full_assignments.json'),
    `${JSON.stringify({ temples: assignments }, null, 2)}\n`,
  );
  const report = {
    templeCount: temples.length,
    unresolved: 0,
    simplificationMismatchCount: simplificationMismatches.length,
    simplificationMismatches: simplificationMismatches.map((row) => ({
      name: row.name,
      state: row.state,
      computedName: row.computed.name,
      computedState: row.computed.state,
      computedLgd: row.computed.lgd,
      fullHits: row.fullHits,
    })),
    stateMismatchCount: stateMismatches.length,
    stateMismatches,
    perState,
    probes: probes.map((probe) => ({
      label: probe.label,
      latitude: probe.latitude,
      longitude: probe.longitude,
      name: probe.resolvedName,
      state: probe.resolvedState,
      lgd: probe.resolvedLgd,
      inside: probe.resolvedInside,
    })),
  };
  fs.writeFileSync(
    path.join(fixtureDir, 'district_accuracy_report.json'),
    `${JSON.stringify(report, null, 2)}\n`,
  );
  console.log(
    `wrote ${assetPath} bytes=${encoded.buffer.length} gzip=${gzipBytes} sha256=${assetSha}`,
  );
}

main();
