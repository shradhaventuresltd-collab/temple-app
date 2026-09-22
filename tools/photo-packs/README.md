# Temple photo packs (KAN-77)

Research-verified Wikimedia Commons images for sample/Seed honesty and Firebase
Storage upload. Each READY pack has `manifest.json`, `ATTRIBUTION.md`, jpgs
listed in the manifest, and `photo_candidates.json`.

**Do not invent Storage URLs.** Sample uses Commons `downloaded_url` thumbs until
Sanu runs `scripts/upload_research_pack.js` with a local `service-account.json`
(repo root or `scripts/`, gitignored).

## Sanu runbook

Debug Seed (or an existing `temples/{id}` doc) must exist before
`--patch-firestore`. The script does not create missing Firestore documents
and does not use a Places scraper.

```bash
cd scripts
npm install
node upload_research_pack.js --all-packs --dry-run
node upload_research_pack.js --all-packs              # needs service-account.json
node upload_research_pack.js --all-packs --patch-firestore
```

`--all-packs` uploads every folder under `tools/photo-packs/` that has a
`manifest.json`, and exits if any Karnataka Wave B pack below is missing.
Only manifest filenames are uploaded. `--patch-firestore` sets
`imageUrl` (first file) and `images` (all files) to the printed Storage URLs
on `temples/{docId}` when that document already exists.

Seed keeps a non-empty verified live gallery, so a later debug Seed does not
replace admin or Storage uploads with the Commons pack. Picsum is never
written. The pack gallery is applied only when the live document has no
verified image URLs.

## Packs already on main (#19)

| Slug | Temple | Photos | Notes |
|------|--------|--------|-------|
| `mahabodhi-temple` | Mahabodhi Temple (Bodh Gaya) | 7 | Buddhist UNESCO / living pilgrimage |
| `dilwara-temples` | Dilwara Temples (Mount Abu) | 6 | Jain tirtha |
| `martand-sun-temple` | Martand Sun Temple (Anantnag) | 6 | ASI ruins / heritage visit |
| `shore-temple` | Shore Temple (Mahabalipuram) | 6 | ASI UNESCO heritage |
| `meenakshi-amman-temple` | Meenakshi Amman Temple (Madurai) | 6 | Living Hindu HR&CE |

## Karnataka Wave B

Pack folders keep the research tar names. Storage and Firestore ids are Seed
`templeDocumentId(name)`.

| Pack folder | Seed `templeDocumentId` | Temple |
| --- | --- | --- |
| `anegudde-vinayaka-temple` | same | Anegudde Vinayaka Temple |
| `annapoorneshwari-temple-horanadu` | same | Annapoorneshwari Temple, Horanadu |
| `banashankari-temple-bengaluru` | same | Banashankari Temple, Bengaluru |
| `chamundeshwari-temple` | same | Chamundeshwari Temple |
| `cheluvanarayana-swamy-temple-melukote` | `cheluvanarayana-swamy-temple` | Cheluvanarayana Swamy Temple |
| `chennakeshava-temple-belur` | same | Chennakeshava Temple, Belur |
| `ghati-subramanya-temple` | same | Ghati Subramanya Temple |
| `hoysaleswara-temple-halebidu` | same | Hoysaleswara Temple, Halebidu |
| `iskcon-temple-bangalore` | same | ISKCON Temple, Bangalore |
| `kateel-durga-parameshwari-temple` | same | Kateel Durga Parameshwari Temple |
| `kollur-mookambika-temple` | same | Kollur Mookambika Temple |
| `kukke-subramanya-temple` | same | Kukke Subramanya Temple |
| `mahabaleshwar-temple-gokarna` | same | Mahabaleshwar Temple, Gokarna |
| `murudeshwar-temple` | same | Murudeshwar Temple |
| `sri-krishna-matha-udupi` | same | Sri Krishna Matha (Udupi) |
| `sri-manjunatha-temple-dharmasthala` | same | Sri Manjunatha Temple, Dharmasthala |
| `srikanteshwara-temple-nanjangud` | same | Srikanteshwara Temple, Nanjangud |
| `sringeri-sharada-peetham` | same | Sringeri Sharada Peetham |
| `talakaveri-temple` | same | Talakaveri Temple |
| `virupaksha-temple` | same | Virupaksha Temple |

Cheluvanarayana is the only mismatch: the sample name has no city, so Seed
stays `cheluvanarayana-swamy-temple`. The pack folder keeps the Melukote
research slug. `manifest.json` records `seed_document_id`, and
`upload_research_pack.js` maps that folder onto the Seed id.

## Held for Research (not reviewer-ready)

Research is regenerating these three packs. Flagged wrong-site frames are
gone. No stand-in images were added. `--all-packs` skips an empty manifest
and does not patch Firestore for it.

| Pack | Dropped | Gallery now |
| --- | --- | --- |
| `banashankari-temple-bengaluru` | All six Badami / Cholachagudda frames | Empty. Sample is Photo pending. |
| `talakaveri-temple` | Brihadeeswara (Thanjavur) and Srirangam | Four remaining Talakaveri frames. |
| `mahabaleshwar-temple-gokarna` | Kathmandu Gokarneshwor | Five remaining Gokarna frames. |
