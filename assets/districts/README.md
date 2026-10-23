# India district boundaries

Source: LGD. Published via bharatlas (bharatlas.com). Licence: CC0-1.0 / CC-BY-4.0.

Both CC0-1.0 and CC-BY-4.0 allow this geometry to be bundled in the app.
CC-BY-4.0 requires the credit line above.

- Source: Bharatlas LGD Districts (2024)
- Layer: https://bharatlas.com/view/lgd_districts
- Download: https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson
- Upstream: https://lgdirectory.gov.in/
- Licence: CC0-1.0 / CC-BY-4.0
- Asset version: `lgd-2024-dsb1-500m`
- Districts: 785 (LGD district code + canonical name)
- Points after quantizing to 4 decimal degrees: 138200
- Uncompressed: 1143600 bytes
- gzip -9 (the size Android deflates into the AAB): 473665 bytes
- Source SHA-256: `95829298abdd0e80fc514b8c70787bdeef9aaf0e63b348177493045e8b22bab5`
- Asset SHA-256: `28af9e9a8cb6e488da40461dd0d9558ade982a25a01b6301dd33944df3027991`

Simplification (mapshaper 0.6.113), Visvalingam effective area,
topology kept, intersection repair off so shared borders stay aligned and
concave districts keep their centroids:

```
mapshaper@0.6.113 LGD_Districts.geojson -filter-fields dtname,stname,dist_lgd,state_lgd -proj aea -simplify visvalingam interval=500 keep-shapes no-repair -proj wgs84 -o precision=0.0001 format=geojson simplified.geojson
```

`interval=500` is 500 metres in the Albers projection mapshaper builds from
the layer. The binary is delta-encoded int32 (`DSB1`), not GeoJSON.
District is computed in memory from this asset. It is not a Firestore field
and it is not part of the temple index shard.
