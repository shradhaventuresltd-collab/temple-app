# Temple photo packs (KAN-77)

Research-verified Wikimedia Commons images for sample/Seed honesty and Firebase
Storage upload. Each READY pack has `manifest.json`, `ATTRIBUTION.md`, jpgs
listed in the manifest, and `photo_candidates.json`.

**Do not invent Storage URLs.** Sample uses Commons `downloaded_url` thumbs until
Sanu runs `scripts/upload_research_pack.js` with a local `service-account.json`.

| Slug | Temple | Photos | Notes |
|------|--------|--------|-------|
| `mahabodhi-temple` | Mahabodhi Temple (Bodh Gaya) | 7 | Buddhist UNESCO / living pilgrimage |
| `dilwara-temples` | Dilwara Temples (Mount Abu) | 6 | Jain tirtha |
| `martand-sun-temple` | Martand Sun Temple (Anantnag) | 6 | ASI ruins / heritage visit |
| `shore-temple` | Shore Temple (Mahabalipuram) | 6 | ASI UNESCO heritage |
| `meenakshi-amman-temple` | Meenakshi Amman Temple (Madurai) | 6 | Living Hindu HR&CE |

Upload all packs:

```bash
cd scripts
npm install
node upload_research_pack.js --all-packs --dry-run
node upload_research_pack.js --all-packs              # needs service-account.json
node upload_research_pack.js --all-packs --patch-firestore
```
