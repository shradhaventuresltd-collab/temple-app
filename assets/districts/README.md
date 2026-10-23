# India district boundaries — not bundled

The Bharatlas LGD district file is **not** in this app. The publisher does
not name one licence for this version, so the geometry was not shipped.

Evaluated layer (local only, not committed):

- Source: Bharatlas LGD Districts (2024)
- Dataset version: LGD snapshot 2024
- Card updated: 2026-05-19
- Layer: https://bharatlas.com/view/lgd_districts
- Terms: https://bharatlas.com/terms (updated 2026-05-22)
- Download that was measured: https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson
- Upstream directory (codes, not a polygon licence): https://lgdirectory.gov.in/

What the source itself says, on the same page:

- Layer card and catalog field: `CC0-1.0 / CC-BY-4.0`
- schema.org Dataset `license`: https://creativecommons.org/publicdomain/zero/1.0/
- schema.org `creditText`: `Source: LGD. Published via bharatlas (bharatlas.com). Licence: CC0-1.0 / CC-BY-4.0.`
- The GeoJSON file has no licence property
- Terms say use follows the licence shown on the card, and the card shows both

Those statements do not pick one licence. This repo does not treat
`CC0-1.0 / CC-BY-4.0` as a pin, and it does not treat the schema.org URL
as a pin while the card disagrees.

Asset version that was encoded locally and then removed: `lgd-2024-dsb1-500m`.
That binary is not in git. `scripts/build_district_boundaries.mjs` refuses
to write it again until `--licence` is exactly `CC0-1.0` or `CC-BY-4.0`,
and only after the publisher itself names that single licence for this
version.

The lookup code still must not render a boundary asset. Only the district
lookup service may decode one, if a licensed file is added later.

Stored state wins. A pin is matched only to districts of that state. If it
is in none of them, the nearest district of that state is used within 2 km,
and beyond that the temple has no district. Two name-only overrides are
committed in `lib/district/district_overrides.dart`:
`sita-ramachandra-swamy-temple` is Bhadradri Kothagudem (Telangana), and
`malinithan` is Lower Siang (Arunachal Pradesh). They win over the lookup.
