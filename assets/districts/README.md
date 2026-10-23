# India district boundaries

This asset is **derived**. It is not the publisher's GeoJSON. Mapshaper
simplified the rings, coordinates were quantised to 4 decimal degrees, and
the rings were delta-encoded into `india_districts.dsb`.

- Source: Bharatlas LGD Districts (2024)
- Dataset: LGD snapshot 2024 (card updated 2026-05-19, fetched 2026-10-23)
- Layer: https://bharatlas.com/view/lgd_districts
- Download: https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson
- Upstream: https://lgdirectory.gov.in/
- Licence pinned for this build: CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/)
- The source page states both CC0-1.0 and CC-BY-4.0. This repository complies with CC BY 4.0. CC0 is not the licence recorded for the asset.
- Asset version: `lgd-2024-dsb1-500m`
- Districts: 785 (LGD district code and name)
- Points after quantising to 4 decimal degrees: 138200
- Uncompressed: 595044 bytes (must stay under 600 KB)
- gzip -9: 430581 bytes
- Source SHA-256: `95829298abdd0e80fc514b8c70787bdeef9aaf0e63b348177493045e8b22bab5`
- Asset SHA-256: `1d006ce0ba56bd804ca0cf5f0241eb27ce7c87fe702be832fcb2d23b95daac62`

Simplification (mapshaper 0.6.113). `interval=500`
is 500 metres in the Albers projection mapshaper builds from
the layer. Topology is kept and intersection repair is off so shared borders
stay aligned:

```
mapshaper@0.6.113 LGD_Districts.geojson -filter-fields dtname,stname,dist_lgd,state_lgd -proj aea -simplify visvalingam interval=500 keep-shapes no-repair -proj wgs84 -o precision=0.0001 format=geojson simplified.geojson
```

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

Two id-keyed overrides stay in `lib/district/district_overrides.dart`.
They fix border pins and win over the polygon lookup when the stored state
matches:

- `sita-ramachandra-swamy-temple` → Bhadradri Kothagudem (Telangana)
- `malinithan` → Lower Siang (Arunachal Pradesh)
