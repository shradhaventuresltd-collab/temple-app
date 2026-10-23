/**
 * Builds assets/districts/india_districts.dsb from Bharatlas LGD
 * Districts (2024).
 *
 *   node scripts/build_district_boundaries.mjs --licence CC-BY-4.0
 *
 * The gate accepts CC-BY-4.0 only. CC0-1.0 is refused. An omitted or
 * unknown licence is refused. The source page states both CC0 and CC BY;
 * this build complies with CC BY 4.0 and records that in the NOTICE.
 *
 * Omit --simplified to run mapshaper 0.6.113 (MAPSHAPER, or npx).
 * The source GeoJSON is cached under scripts/.cache and is not committed.
 * Pass --tolerance <metres> to change the Visvalingam interval (default
 * 500). Deltas are int16 so the 500 m asset stays under 600 KB.
 * Accuracy fixtures are written from the seed in lib/data/sample_data.dart.
 * A production coordinate CSV, if passed with --temples-csv, is audited
 * in memory and is never written back.
 */
import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

import { loadSampleTemples } from './temple_seed.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCALE = 10000;
const PINNED_LICENCE = 'CC-BY-4.0';
const LICENCE_URL = 'https://creativecommons.org/licenses/by/4.0/';
let TOLERANCE_METRES = 500;
const SOURCE_NAME = 'Bharatlas LGD Districts (2024)';
const DATASET_VERSION = 'LGD snapshot 2024';
const SOURCE_UPDATED = '2026-05-19';
const FETCHED_ON = '2026-10-23';
const DOWNLOAD =
  'https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson';
const SOURCE_PAGE = 'https://bharatlas.com/view/lgd_districts';
const UPSTREAM = 'https://lgdirectory.gov.in/';
const SOURCE_SHA256 =
  '95829298abdd0e80fc514b8c70787bdeef9aaf0e63b348177493045e8b22bab5';
const MAPSHAPER_VERSION = '0.6.113';
const NEAREST_LIMIT_METRES = 2000;
const RAW_BYTE_LIMIT = 600 * 1024;

function assetVersion() {
  return `lgd-2024-dsb1-${TOLERANCE_METRES}m`;
}

function mapshaperCommand() {
  return [
    `mapshaper@${MAPSHAPER_VERSION}`,
    'LGD_Districts.geojson',
    '-filter-fields',
    'dtname,stname,dist_lgd,state_lgd',
    '-proj',
    'aea',
    '-simplify',
    'visvalingam',
    `interval=${TOLERANCE_METRES}`,
    'keep-shapes',
    'no-repair',
    '-proj',
    'wgs84',
    '-o',
    'precision=0.0001',
    'format=geojson',
    'simplified.geojson',
  ].join(' ');
}

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
        // First point is int32 lat/lng. Later points are int16 deltas.
        size += 2 + 8 + (count - 1) * 4;
      }
    }
  }
  if (rows.length > 65535) throw new Error('Too many districts');

  const buffer = Buffer.alloc(size);
  let offset = 0;
  buffer.write('DSB1', offset, 'ascii');
  offset += 4;
  buffer.writeUInt16LE(2, offset);
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
          const dLat = lat - prevLat;
          const dLng = lng - prevLng;
          if (dLat < -32768 || dLat > 32767 || dLng < -32768 || dLng > 32767) {
            throw new Error(`Delta does not fit in int16 in ${district.name}`);
          }
          buffer.writeInt16LE(dLat, offset);
          offset += 2;
          buffer.writeInt16LE(dLng, offset);
          offset += 2;
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
  if (version !== 1 && version !== 2) throw new Error(`Bad version ${version}`);
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
          if (version === 2) {
            lat += buffer.readInt16LE(offset);
            offset += 2;
            lng += buffer.readInt16LE(offset);
            offset += 2;
          } else {
            lat += buffer.readInt32LE(offset);
            offset += 4;
            lng += buffer.readInt32LE(offset);
            offset += 4;
          }
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

const OVERRIDES = {
  'sita-ramachandra-swamy-temple': {
    name: 'Bhadradri Kothagudem',
    state: 'Telangana',
  },
  malinithan: { name: 'Lower Siang', state: 'Arunachal Pradesh' },
};

function segmentDistance(ax, ay, bx, by) {
  const dx = bx - ax;
  const dy = by - ay;
  const len2 = dx * dx + dy * dy;
  if (len2 === 0) return Math.hypot(ax, ay);
  const t = Math.min(1, Math.max(0, (-ax * dx - ay * dy) / len2));
  return Math.hypot(ax + t * dx, ay + t * dy);
}

function boundaryDistance(district, latitude, longitude) {
  const kx = 111320 * Math.cos((latitude * Math.PI) / 180);
  const ky = 110540;
  let best = Infinity;
  for (const rings of district.polygons) {
    for (const ring of rings) {
      const n = ring.length / 2;
      for (let i = 0; i < n; i++) {
        const j = (i + 1) % n;
        const ax = (ring[i * 2 + 1] / SCALE - longitude) * kx;
        const ay = (ring[i * 2] / SCALE - latitude) * ky;
        const bx = (ring[j * 2 + 1] / SCALE - longitude) * kx;
        const by = (ring[j * 2] / SCALE - latitude) * ky;
        const distance = segmentDistance(ax, ay, bx, by);
        if (distance < best) best = distance;
      }
    }
  }
  return best;
}

function locateInStoredState(districts, latitude, longitude, storedState) {
  const latQ = quantize(latitude);
  const lngQ = quantize(longitude);
  const hits = [];
  const pool = [];
  for (const district of districts) {
    if (canonicalState(storedState) !== canonicalState(district.stateName)) continue;
    pool.push(district);
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
    return { district: hits[0], kind: 'inside' };
  }
  let best = null;
  let bestKey = null;
  for (const district of pool) {
    if (bboxDistance(district, latitude, longitude) > NEAREST_LIMIT_METRES) {
      continue;
    }
    const distance = boundaryDistance(district, latitude, longitude);
    if (distance > NEAREST_LIMIT_METRES) continue;
    const key = {
      distance,
      area: district.area,
      lgd: district.lgd,
      name: district.name,
    };
    if (bestKey == null || nearer(key, bestKey)) {
      best = district;
      bestKey = key;
    }
  }
  if (!best) return { district: null, kind: 'none' };
  return { district: best, kind: 'nearest', distance: bestKey.distance };
}

function foldDistrictName(name) {
  return String(name)
    .toLowerCase()
    .replace(/[–—-]/g, ' ')
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\bdistrict\b/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function addressDistrict(location) {
  if (!location) return null;
  const match = String(location).match(/([A-Za-z][^,\n]{0,80}?) District\b/i);
  if (!match) return null;
  return match[1].replace(/\s+/g, ' ').trim();
}

function overrideFor(temple) {
  const fixed = OVERRIDES[temple.id];
  if (!fixed) return null;
  if (canonicalState(fixed.state) !== canonicalState(temple.state)) return null;
  return fixed;
}

function loadTemples() {
  const { temples } = loadSampleTemples();
  const rows = temples.map((row) => ({
    id: row.id,
    name: row.temple.name,
    state: row.temple.state,
    city: row.temple.city,
    location: row.temple.location,
    latitude: row.temple.latitude,
    longitude: row.temple.longitude,
  }));
  if (rows.length < 100) throw new Error(`Only parsed ${rows.length} temples`);
  return rows;
}

function parseTempleCsv(csvPath) {
  const text = fs.readFileSync(csvPath, 'utf8');
  const lines = text.split(/\r?\n/).filter((line) => line.trim().length > 0);
  const header = lines[0].split(',').map((cell) => cell.trim());
  const index = Object.fromEntries(header.map((name, i) => [name, i]));
  for (const required of ['id', 'name', 'state', 'latitude', 'longitude']) {
    if (index[required] == null) throw new Error(`CSV is missing ${required}`);
  }
  return lines.slice(1).map((line) => {
    const cells = [];
    let current = '';
    let quoted = false;
    for (const ch of line) {
      if (ch === '"') {
        quoted = !quoted;
        continue;
      }
      if (ch === ',' && !quoted) {
        cells.push(current);
        current = '';
        continue;
      }
      current += ch;
    }
    cells.push(current);
    const at = (name) => cells[index[name]] ?? '';
    return {
      id: at('id').trim(),
      name: at('name').trim(),
      state: at('state').trim(),
      city: index.city == null ? '' : at('city').trim(),
      location: index.location == null ? at('address') : at('location'),
      latitude: Number(at('latitude')),
      longitude: Number(at('longitude')),
    };
  });
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
    `interval=${TOLERANCE_METRES}`,
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

function classifyTemples(districts, temples) {
  const counts = { inside: 0, nearest: 0, none: 0, override: 0, cross: 0 };
  const rows = [];
  const addressMismatches = [];
  let addressCompared = 0;
  for (const temple of temples) {
    const fixed = overrideFor(temple);
    const located = locateInStoredState(
      districts,
      temple.latitude,
      temple.longitude,
      temple.state,
    );
    let kind = located.kind;
    let name = located.district?.name ?? '';
    let state = located.district?.stateName ?? '';
    let lgd = located.district?.lgd ?? 0;
    if (fixed) {
      kind = 'override';
      name = fixed.name;
      state = fixed.state;
      lgd = 0;
    }
    if (kind === 'inside') counts.inside += 1;
    else if (kind === 'nearest') counts.nearest += 1;
    else if (kind === 'none') counts.none += 1;
    else if (kind === 'override') counts.override += 1;
    const cross =
      kind !== 'none' && canonicalState(temple.state) !== canonicalState(state);
    if (cross) counts.cross += 1;
    const storedAddressDistrict = addressDistrict(temple.location);
    let addressMatch = null;
    if (storedAddressDistrict && kind !== 'none') {
      addressCompared += 1;
      addressMatch = foldDistrictName(storedAddressDistrict) === foldDistrictName(name);
      if (!addressMatch) {
        addressMismatches.push({
          id: temple.id,
          name: temple.name,
          state: temple.state,
          addressDistrict: storedAddressDistrict,
          assigned: name,
          kind,
        });
      }
    }
    rows.push({
      id: temple.id,
      name: temple.name,
      state: temple.state,
      kind,
      district: name,
      districtState: state,
      lgd,
      polygonDistrict: located.district?.name ?? '',
      polygonState: located.district?.stateName ?? '',
      polygonKind: located.kind,
      addressDistrict: storedAddressDistrict,
      addressMatch,
      cross,
    });
  }
  return { counts, rows, addressCompared, addressMismatches };
}

function main() {
  const pinnedLicence = arg('--licence', '');
  if (pinnedLicence !== PINNED_LICENCE) {
    throw new Error(
      'Refusing to write assets/districts. Pass --licence CC-BY-4.0. ' +
        'CC0-1.0 is not accepted. An omitted or unknown licence is refused.',
    );
  }
  const requestedTolerance = Number(arg('--tolerance', String(TOLERANCE_METRES)));
  if (!Number.isInteger(requestedTolerance) || requestedTolerance < 100) {
    throw new Error('--tolerance must be an integer number of metres, at least 100');
  }
  TOLERANCE_METRES = requestedTolerance;
  const input = ensureInput(arg('--input', ''));
  const sourceSha = sha256(input);
  if (sourceSha !== SOURCE_SHA256) {
    throw new Error(
      `Source SHA-256 ${sourceSha} does not match the pinned Bharatlas file ${SOURCE_SHA256}`,
    );
  }
  let simplified = arg('--simplified', '');
  if (!simplified) {
    simplified = path.join(
      root,
      `scripts/.cache/simplified_${TOLERANCE_METRES}_norepair.geojson`,
    );
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
  const polygonMismatches = [];
  for (const temple of temples) {
    const fullHits = hitsAt(fullDistricts, temple.latitude, temple.longitude);
    const located = locate(decoded.districts, temple.latitude, temple.longitude);
    const computed = {
      lgd: located.district.lgd,
      name: located.district.name,
      state: located.district.stateName,
    };
    if (!fullHits.some((hit) => sameDistrict(hit, computed))) {
      polygonMismatches.push({
        id: temple.id,
        name: temple.name,
        state: temple.state,
        simplified: computed.name,
        full: fullHits.map((hit) => hit.name),
      });
    }
  }

  const fullAudit = classifyTemples(fullDistricts, temples);
  const simpleAudit = classifyTemples(decoded.districts, temples);
  if (simpleAudit.counts.cross !== 0 || fullAudit.counts.cross !== 0) {
    throw new Error(
      `Cross-state assignments: simplified ${simpleAudit.counts.cross}, full ${fullAudit.counts.cross}`,
    );
  }
  const assignmentMismatches = [];
  for (let i = 0; i < temples.length; i++) {
    const fullRow = fullAudit.rows[i];
    const simpleRow = simpleAudit.rows[i];
    if (fullRow.district === simpleRow.district) continue;
    assignmentMismatches.push({
      id: simpleRow.id,
      name: simpleRow.name,
      state: simpleRow.state,
      full: fullRow.district,
      simplified: simpleRow.district,
      fullKind: fullRow.kind,
      simplifiedKind: simpleRow.kind,
    });
  }
  const assignmentRate = assignmentMismatches.length / temples.length;
  const polygonRate = polygonMismatches.length / temples.length;
  if (assignmentRate > 0.02 || polygonRate > 0.02) {
    throw new Error(
      `Simplification mismatch exceeds 2% (assignment ${(assignmentRate * 100).toFixed(2)}%, polygon ${(polygonRate * 100).toFixed(2)}%)`,
    );
  }
  console.log(
    `seed ${temples.length} simplified in-state ${simpleAudit.counts.inside} nearest ${simpleAudit.counts.nearest} none ${simpleAudit.counts.none} overrides ${simpleAudit.counts.override} cross ${simpleAudit.counts.cross}`,
  );
  console.log(
    `assignment mismatches ${assignmentMismatches.length} (${(assignmentRate * 100).toFixed(2)}%), polygon mismatches ${polygonMismatches.length} (${(polygonRate * 100).toFixed(2)}%)`,
  );
  console.log(
    `address districts compared ${simpleAudit.addressCompared}, mismatches ${simpleAudit.addressMismatches.length}`,
  );
  for (const row of simpleAudit.rows.filter((item) => item.kind === 'override')) {
    console.log(
      `override ${row.id} -> ${row.district}; polygon would say ${row.polygonKind} ${row.polygonDistrict || '(none)'} / ${row.polygonState || '(none)'}`,
    );
  }

  const borderProbes = [
    {
      id: 'sita-ramachandra-swamy-temple',
      state: 'Telangana',
      latitude: 17.6669,
      longitude: 80.8828,
    },
    {
      id: 'malinithan',
      state: 'Arunachal Pradesh',
      latitude: 27.6567,
      longitude: 94.7058,
    },
  ];
  const overrideProbes = borderProbes.map((probe) => {
    const located = locateInStoredState(
      decoded.districts,
      probe.latitude,
      probe.longitude,
      probe.state,
    );
    const fixed = OVERRIDES[probe.id];
    const disagrees = (located.district?.name ?? '') !== fixed.name;
    console.log(
      `border ${probe.id} polygon ${located.kind} ${located.district?.name ?? '(none)'} disagrees=${disagrees}`,
    );
    return {
      id: probe.id,
      override: fixed.name,
      polygonKind: located.kind,
      polygonDistrict: located.district?.name ?? '',
      polygonState: located.district?.stateName ?? '',
      disagrees,
    };
  });

  let production = null;
  const templesCsv = arg('--temples-csv', '');
  if (templesCsv) {
    const prodRows = parseTempleCsv(templesCsv);
    const prodFull = classifyTemples(fullDistricts, prodRows);
    const prodSimple = classifyTemples(decoded.districts, prodRows);
    if (prodSimple.counts.cross !== 0 || prodFull.counts.cross !== 0) {
      throw new Error('Production coordinate audit assigned a cross-state district');
    }
    let prodMismatch = 0;
    for (let i = 0; i < prodRows.length; i++) {
      if (prodFull.rows[i].district !== prodSimple.rows[i].district) prodMismatch += 1;
    }
    production = {
      templeCount: prodRows.length,
      simplified: prodSimple.counts,
      full: prodFull.counts,
      assignmentMismatchCount: prodMismatch,
      assignmentMismatchPercent: (prodMismatch / prodRows.length) * 100,
      addressCompared: prodSimple.addressCompared,
      addressMismatchCount: prodSimple.addressMismatches.length,
      addressMismatches: prodSimple.addressMismatches,
    };
    console.log('production csv', JSON.stringify(production.simplified), 'mismatches', prodMismatch);
  }

  const assetDir = path.join(root, 'assets/districts');
  fs.mkdirSync(assetDir, { recursive: true });
  const assetPath = path.join(assetDir, 'india_districts.dsb');
  fs.writeFileSync(assetPath, encoded.buffer);
  const gzipBytes = zlib.gzipSync(encoded.buffer, { level: 9 }).length;
  if (encoded.buffer.length >= RAW_BYTE_LIMIT) {
    throw new Error(
      `Asset is ${encoded.buffer.length} bytes, which is not under 600 KB`,
    );
  }
  const assetSha = crypto.createHash('sha256').update(encoded.buffer).digest('hex');
  const attribution =
    'District boundaries © Bharatlas (LGD 2024), licensed CC BY 4.0, simplified for this app.';
  const manifest = {
    bundled: true,
    allowsBundling: true,
    assetVersion: assetVersion(),
    datasetVersion: DATASET_VERSION,
    sourceUpdated: SOURCE_UPDATED,
    fetchedOn: FETCHED_ON,
    sha256: assetSha,
    bytes: encoded.buffer.length,
    gzipBytes,
    districts: decoded.districts.length,
    points: encoded.points,
    toleranceMetres: TOLERANCE_METRES,
    coordinateDecimals: 4,
    source: SOURCE_NAME,
    sourcePage: SOURCE_PAGE,
    sourceUrl: DOWNLOAD,
    upstream: UPSTREAM,
    sourceSha256: sourceSha,
    licence: pinnedLicence,
    licenceUrl: LICENCE_URL,
    attribution,
    mapshaper: mapshaperCommand(),
  };
  fs.writeFileSync(
    path.join(assetDir, 'manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`,
  );
  const notice = `India district boundaries
=========================

These polygons are a simplified, quantised, delta-encoded derivative of the
Bharatlas LGD Districts (2024) layer.

Source page: ${SOURCE_PAGE}
Download: ${DOWNLOAD}
Upstream codes: ${UPSTREAM}
Dataset: ${DATASET_VERSION} (card updated ${SOURCE_UPDATED})
Fetched: ${FETCHED_ON}
Source SHA-256: ${sourceSha}

The source page states both CC0-1.0 and CC-BY-4.0. This copy complies with
CC BY 4.0: ${LICENCE_URL}

© Bharatlas. Source: Local Government Directory.

Credit Bharatlas, link the licence, and indicate that changes were made.
Changes: Visvalingam simplification at ${TOLERANCE_METRES} metres (mapshaper
${MAPSHAPER_VERSION}, topology kept, intersection repair off), coordinates
quantised to 4 decimal degrees, rings stored as DSB1 version 2 (int32
anchor, int16 deltas) in india_districts.dsb (${assetVersion()}).
`;
  fs.writeFileSync(path.join(assetDir, 'LICENSE'), notice);
  const readme = `# India district boundaries

This asset is **derived**. It is not the publisher's GeoJSON. Mapshaper
simplified the rings, coordinates were quantised to 4 decimal degrees, and
the rings were delta-encoded into \`india_districts.dsb\`.

- Source: ${SOURCE_NAME}
- Dataset: ${DATASET_VERSION} (card updated ${SOURCE_UPDATED}, fetched ${FETCHED_ON})
- Layer: ${SOURCE_PAGE}
- Download: ${DOWNLOAD}
- Upstream: ${UPSTREAM}
- Licence pinned for this build: ${pinnedLicence} (${LICENCE_URL})
- The source page states both CC0-1.0 and CC-BY-4.0. This repository complies with CC BY 4.0. CC0 is not the licence recorded for the asset.
- Asset version: \`${assetVersion()}\`
- Districts: ${decoded.districts.length} (LGD district code and name)
- Points after quantising to 4 decimal degrees: ${encoded.points}
- Uncompressed: ${encoded.buffer.length} bytes (must stay under 600 KB)
- gzip -9: ${gzipBytes} bytes
- Source SHA-256: \`${sourceSha}\`
- Asset SHA-256: \`${assetSha}\`

Simplification (mapshaper ${MAPSHAPER_VERSION}). \`interval=${TOLERANCE_METRES}\`
is ${TOLERANCE_METRES} metres in the Albers projection mapshaper builds from
the layer. Topology is kept and intersection repair is off so shared borders
stay aligned:

\`\`\`
${mapshaperCommand()}
\`\`\`

The binary is DSB1 version 2: the first point of each ring is int32 and
later points are int16 deltas (every simplified step fits). It is not
GeoJSON. District is
computed in memory from this asset. It is not a Firestore field and it is
not part of the temple index shard. The file is loaded only when a district
filter or the near-me district button needs it.

Stored state wins. A pin is matched only to districts of that state. If it
is in none of them, the nearest district of that state within 2 km is used.
Beyond that the temple has no district. The result is never a district of
another state.

Two id-keyed overrides stay in \`lib/district/district_overrides.dart\`.
They fix border pins and win over the polygon lookup when the stored state
matches:

- \`sita-ramachandra-swamy-temple\` → Bhadradri Kothagudem (Telangana)
- \`malinithan\` → Lower Siang (Arunachal Pradesh)
`;
  fs.writeFileSync(path.join(assetDir, 'README.md'), readme);

  const fixtureDir = path.join(root, 'test/fixtures');
  fs.mkdirSync(fixtureDir, { recursive: true });
  fs.writeFileSync(
    path.join(fixtureDir, 'district_full_assignments.json'),
    `${JSON.stringify({ temples: simpleAudit.rows }, null, 2)}\n`,
  );
  const report = {
    templeCount: temples.length,
    toleranceMetres: TOLERANCE_METRES,
    bytes: encoded.buffer.length,
    gzipBytes,
    simplified: simpleAudit.counts,
    full: fullAudit.counts,
    assignmentMismatchCount: assignmentMismatches.length,
    assignmentMismatchPercent: Number((assignmentRate * 100).toFixed(2)),
    polygonMismatchCount: polygonMismatches.length,
    polygonMismatchPercent: Number((polygonRate * 100).toFixed(2)),
    assignmentMismatches,
    polygonMismatches,
    addressCompared: simpleAudit.addressCompared,
    addressMismatchCount: simpleAudit.addressMismatches.length,
    addressMismatches: simpleAudit.addressMismatches,
    overrideProbes,
    crossState: simpleAudit.counts.cross,
    probes: probes.map((probe) => ({
      label: probe.label,
      latitude: probe.latitude,
      longitude: probe.longitude,
      name: probe.resolvedName,
      state: probe.resolvedState,
      lgd: probe.resolvedLgd,
      inside: probe.resolvedInside,
    })),
    production,
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
