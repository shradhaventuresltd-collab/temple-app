# Temple photo packs (KAN-77)

Research-verified Wikimedia Commons images for sample/Seed honesty and Firebase
Storage upload. Each READY pack has `manifest.json`, `ATTRIBUTION.md`, the
files listed in the manifest, and `photo_candidates.json`.

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
`manifest.json`, and exits if any Karnataka Wave B pack or any Tamil Nadu +
Kerala Wave A pack below is missing. Only manifest filenames are uploaded.
`--patch-firestore` sets
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

## Reviewer wrong-site fix (Research site_verified)

Research replaced these three packs. Sample `imageUrl` / `images` use the
new manifest `downloaded_url` values. Do not set live Firestore `imageUrl`
from this branch.

| Pack | Removed | Now |
| --- | --- | --- |
| `banashankari-temple-bengaluru` | Badami / Cholachagudda frames | 6 Bengaluru / Kanakapura Road photos. `site_verified`. |
| `talakaveri-temple` | Brihadeeswara and Srirangam | 5 Talakaveri / Kodagu photos. `site_verified`. |
| `mahabaleshwar-temple-gokarna` | Kathmandu Gokarneshwor | 6 Gokarna, Karnataka photos. `site_verified`. |
| `sri-krishna-matha-udupi` | Parashurama temple, theatre, railway station, generic city frame | 8 Matha-only photos. `site_verified`. |

## Tamil Nadu + Kerala Wave A

Pack folders keep the research tar names. Storage and Firestore ids are Seed
`templeDocumentId(name)`.

| Pack folder | Seed `templeDocumentId` | Photos | Temple |
| --- | --- | --- | --- |
| `ambalappuzha-sri-krishna-temple` | same | 6 | Ambalappuzha Sri Krishna Temple |
| `arunachaleswarar-temple` | same | 6 | Arunachaleswarar Temple |
| `attukal-bhagavathy-temple` | same | 6 | Attukal Bhagavathy Temple |
| `brihadeeswarar-temple` | same | 6 | Brihadeeswarar Temple |
| `chengannur-mahadeva-temple` | same | 6 | Chengannur Mahadeva Temple |
| `chettikulangara-devi-temple` | same | 6 | Chettikulangara Devi Temple |
| `chottanikkara-bhagavathy-temple` | same | 6 | Chottanikkara Bhagavathy Temple |
| `dhandayuthapani-swamy-temple-palani` | `dhandayuthapani-swamy-temple` | 6 | Dhandayuthapani Swamy Temple |
| `ekambaranathar-temple` | same | 6 | Ekambaranathar Temple |
| `ernakulathappan-temple` | same | 6 | Ernakulathappan Temple |
| `ettumanoor-mahadeva-temple` | same | 6 | Ettumanoor Mahadeva Temple |
| `guruvayur-sri-krishna-temple` | same | 5 | Guruvayur Sri Krishna Temple |
| `jambukeswarar-temple-thiruvanaikaval` | `jambukeswarar-temple` | 6 | Jambukeswarar Temple |
| `kapaleeshwarar-temple` | same | 6 | Kapaleeshwarar Temple |
| `kaviyoor-mahadeva-temple` | same | 6 | Kaviyoor Mahadeva Temple |
| `kodungallur-bhagavathy-temple` | same | 6 | Kodungallur Bhagavathy Temple |
| `murugan-temple-thirupparankundram` | same | 6 | Murugan Temple, Thirupparankundram |
| `nataraja-temple` | same | 6 | Nataraja Temple |
| `nellaiappar-temple-tirunelveli` | `nellaiappar-temple` | 6 | Nellaiappar Temple |
| `parassinikadavu-muthappan-temple` | same | 6 | Parassinikadavu Muthappan Temple |
| `ramanathaswamy-temple` | same | 6 | Ramanathaswamy Temple |
| `sabarimala-ayyappan-temple` | same | 5 | Sabarimala Ayyappan Temple (living temple) |
| `sarangapani-temple` | same | 6 | Sarangapani Temple |
| `sree-padmanabhaswamy-temple` | same | 6 | Sree Padmanabhaswamy Temple (neutral chip) |
| `sree-poornathrayeesa-temple` | same | 6 | Sree Poornathrayeesa Temple |
| `sri-ranganathaswamy-temple-srirangam` | `sri-ranganathaswamy-temple` | 6 | Sri Ranganathaswamy Temple |
| `subramanya-swamy-temple-thiruchendur` | `subramanya-swamy-temple` | 0 | Subramanya Swamy Temple (held) |
| `swamimalai-murugan-temple` | same | 6 | Swamimalai Murugan Temple |
| `thirunelli-maha-vishnu-temple` | same | 6 | Thirunelli Maha Vishnu Temple |
| `thiruvalla-sreevallabha-temple` | same | 6 | Thiruvalla Sreevallabha Temple |
| `thyagaraja-temple-tiruvarur` | `thyagaraja-temple` | 6 | Thyagaraja Temple |
| `tiruttani-murugan-temple` | same | 6 | Tiruttani Murugan Temple |
| `vadakkunnathan-temple` | same | 6 | Vadakkunnathan Temple |
| `vaikom-mahadeva-temple` | same | 6 | Vaikom Mahadeva Temple |
| `vaitheeswaran-koil` | same | 6 | Vaitheeswaran Koil |

Six folders differ from Seed because the sample name has no city. The upload
script maps them. `manifest.json` also records `seed_document_id`.

Skipped shortfalls (no pack): Kanyakumari Bhagavathi Amman Temple,
Anjengo Sree Durga Devi Temple, Mannarsala Sree Nagaraja Temple.

## Wrong-site frames dropped

| Pack | Dropped | Why |
| --- | --- | --- |
| `subramanya-swamy-temple-thiruchendur` | all 6 | Every file is Elamkunnapuzha Subramanya Swamy Temple, Kerala, not Thiruchendur. Pack is held empty. Sample cover stays empty (Photo pending). |
| `guruvayur-sri-krishna-temple` | `06_Sree_krishna_Mural_Painting_by_Sujith_Nair_Pattoor.jpg` | Mural dedicated to Ulanadu Sree Krishna Temple and categorized under several other Krishna temples. Five Guruvayur photographs remain. |

`sabarimala-ayyappan-temple` / `05_Sabarimala_5.jpg` had a placeholder
`downloaded_url` in the research manifest (`(1280px Commons thumb)`). It was
replaced with the Commons 1280px thumb for `File:Sabarimala 5.jpg` (Sabarimala
temple complex).
