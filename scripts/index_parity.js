/**
 * Prints index entries for a JSON list of temples on stdout.
 * The Dart sample-data parity test compares this with templeIndexEntryFromMap.
 *
 *   node scripts/index_parity.js /tmp/temples.json
 */
import { readFileSync } from "node:fs";

import { entryFromTemple } from "./temple_index.js";

const temples = JSON.parse(readFileSync(process.argv[2], "utf8"));
const out = temples.map((temple) => {
  const entry = entryFromTemple(temple);
  return {
    id: entry.id,
    framing: entry.framing,
    tradition: entry.tradition,
    living: entry.living,
    name: entry.name,
    city: entry.city,
    state: entry.state,
    deity: entry.deity,
    address: entry.address,
    coverThumb: entry.coverThumb,
    coverCaption: entry.coverCaption ?? null,
    lat: entry.lat,
    lng: entry.lng,
  };
});
process.stdout.write(JSON.stringify(out));
