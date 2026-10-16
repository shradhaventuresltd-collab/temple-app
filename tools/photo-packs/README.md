# Temple photo packs (KAN-77)

Research-verified Wikimedia Commons images for sample/Seed honesty and Firebase
Storage upload. Each READY pack has `manifest.json`, `ATTRIBUTION.md`, the
files listed in the manifest, and `photo_candidates.json`.

**Do not invent Storage URLs.** Sample uses Commons `downloaded_url` thumbs until
Sanu runs `scripts/upload_research_pack.js` with a local `service-account.json`
(repo root or `scripts/`, gitignored).

Seven promoted galleries (Akshardham Gandhinagar, Chintaman Ganesh, Janaki
Sitamarhi, Kaleshwara Mukteswara, Mangala Gauri, Purmandal, Ugratara) have
`ATTRIBUTION.md` only. They have no `manifest.json` and no local jpgs, so
`--all-packs` ignores those folders and does not require the files.

## Sanu runbook

Debug Seed (or an existing `temples/{id}` doc) must exist before
`--patch-firestore`. The script does not create missing Firestore documents
and does not use a Places scraper. Uncredited `image_N` Places mirrors are not seeded. `scripts/purge_places_photos.js` removes them; it is dry-run unless Deployer passes `--apply` after Architect signs off.

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
| `pashupatinath-temple-mandsaur` | `The_Pashupatinath_Temple_27.jpg`, the Kathmandu Maha Shivaratri sadhu frame (Nabin K. Sapkota, Bijay Chaurasia), and the access-road arch with the bank advertisement | 6 photos from Category:Pashupatinath Temple, Mandsaur. Cover is 01. Kathmandu frames are not in the pack. |
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
| `sabarimala-ayyappan-temple` | same | 5 | Sabarimala Ayyappan Temple (living temple; cover is the temple complex) |
| `sarangapani-temple` | same | 6 | Sarangapani Temple |
| `sree-padmanabhaswamy-temple` | same | 6 | Sree Padmanabhaswamy Temple (neutral chip) |
| `sree-poornathrayeesa-temple` | same | 6 | Sree Poornathrayeesa Temple |
| `sri-ranganathaswamy-temple-srirangam` | `sri-ranganathaswamy-temple` | 6 | Sri Ranganathaswamy Temple |
| `subramanya-swamy-temple-thiruchendur` | `subramanya-swamy-temple` | 8 | Subramanya Swamy Temple (site_verified Tiruchendur) |
| `swamimalai-murugan-temple` | same | 6 | Swamimalai Murugan Temple |
| `thirunelli-maha-vishnu-temple` | same | 6 | Thirunelli Maha Vishnu Temple |
| `thiruvalla-sreevallabha-temple` | same | 6 | Thiruvalla Sreevallabha Temple (cover is the gopuram) |
| `thyagaraja-temple-tiruvarur` | `thyagaraja-temple` | 6 | Thyagaraja Temple |
| `tiruttani-murugan-temple` | same | 5 | Tiruttani Murugan Temple (parking frame dropped) |
| `vadakkunnathan-temple` | same | 6 | Vadakkunnathan Temple |
| `vaikom-mahadeva-temple` | same | 6 | Vaikom Mahadeva Temple |
| `vaitheeswaran-koil` | same | 6 | Vaitheeswaran Koil |

Six folders differ from Seed because the sample name has no city. The upload
script maps them. `manifest.json` also records `seed_document_id`.

Skipped shortfalls (no pack): Anjengo Sree Durga Devi Temple.
Kanyakumari Bhagavathi Amman Temple and Mannarsala Sree Nagaraja Temple
are wired in Wave D.

## Wrong-site frames dropped

| Pack | Dropped | Why |
| --- | --- | --- |
| `subramanya-swamy-temple-thiruchendur` | first research set (6) | Those files were Elamkunnapuzha Subramanya Swamy Temple, Kerala. They were not downloaded. The pack is now the site-verified Tiruchendur set (8). |
| `guruvayur-sri-krishna-temple` | `06_Sree_krishna_Mural_Painting_by_Sujith_Nair_Pattoor.jpg` | Mural dedicated to Ulanadu Sree Krishna Temple and categorized under several other Krishna temples. Five Guruvayur photographs remain. |
| `tiruttani-murugan-temple` | `05_Tiruthani_Murugan_Temple_parking_lot.jpg` | Parking lot at the Tiruttani temple. KAN-77 top-up 2 replaced it with `05_Thiruttani_Temple_Rajagopuram.jpg` (6 frames). |
| `thiruvalla-sreevallabha-temple` | `01_Kadhakali_-_Sreevallabha_Temple_Thiruvalla.jpg` | KAN-77 top-up 2: Kathakali performance frame replaced with temple exterior `02_Sree_Vallabha_Temple_Thiruvalla.jpg` (6 frames). |
| `sabarimala-ayyappan-temple` | `01_Sabarimala.jpg` | KAN-77 top-up 2: forest/tree frame replaced with `02_Sreekovil_at_sabarimala.jpg` (5 frames). |
| `manikaran-shiva-temple` | `02_Panorama_Manikaran_Ram_temple_16746684003.jpg` | KAN-77 top-up 2: Ram temple panorama, a different temple. |
| `manikaran-shiva-temple` | `01_Manikaran_view_from_Shiva_Temple.jpg` | KAN-77 review: view from the Shiva Temple, not the shrine (4 frames). |
| `vaishno-devi-temple` | `03_Vaishno_Devi_temple_in_katra.jpg` | KAN-77 top-up 2: Katra town, not the Bhawan (5 frames). Cover is the Bhawan frame `01_Shri_Mata_Vaishno_Devi_Bhawan_Katra_Jammu_Kashmir_INDIA.jpg`. |

`sabarimala-ayyappan-temple` / `01_Sabarimala_5.jpg` had a placeholder
`downloaded_url` in the research manifest (`(1280px Commons thumb)`). It was
replaced with the Commons 1280px thumb for `File:Sabarimala 5.jpg` (Sabarimala
temple complex). That temple-complex frame is the cover. Top-up 2 removed the
forest frame (Sreekovil added). Thiruvalla’s cover is the gopuram already in
`photo_candidates.json`; top-up 2 removed the Kathakali frame.

## KAN-76 Wave C (all-India photo-pending)

Pack folders keep the research names. Storage and Firestore ids are Seed
`templeDocumentId(name)` (mapped in `scripts/upload_research_pack.js`).

Photo counts below 5 are packs that lost off-topic or unsuitable frames
in review. Research still needs to add licensed temple photos there.
The optional Wave C pass also drops the Srisailam town-zoom frame, the
Jejuri city view, the Vaishno Devi Katra panorama, and the Manikaran
gurdwara interior. A later review also drops the Manikaran Gurdwara
exterior and makes `01_Manikaran_Temple.jpg` the cover (pack is 3), and
drops the 434px Banke Bihari frame (pack is 4). Taraknath’s cover is the
temple-front `File:Tarakeshwar temple entrance.jpg` (CC BY-SA 4.0,
K.vishnupranay).

| Pack folder | Seed `templeDocumentId` | Temple | State | Photos |
| --- | --- | --- | --- | --- |
| `ahobilam-narasimha-temples` | same | Ahobilam Narasimha Temples | Andhra Pradesh | 5 |
| `ambaji-temple` | same | Ambaji Temple | Gujarat | 5 |
| `ananta-vasudeva-temple` | same | Ananta Vasudeva Temple | Odisha | 5 |
| `bahucharaji-temple` | same | Bahucharaji Temple | Gujarat | 5 |
| `baijnath-temple-himachal` | `baijnath-temple` | Baijnath Temple | Himachal Pradesh | 5 |
| `banke-bihari-temple` | same | Banke Bihari Temple | Uttar Pradesh | 4 |
| `belur-math` | same | Belur Math | West Bengal | 5 |
| `bhadrakali-temple-warangal` | `bhadrakali-temple` | Bhadrakali Temple | Telangana | 5 |
| `bhimakali-temple-sarahan` | `bhimakali-temple` | Bhimakali Temple | Himachal Pradesh | 5 |
| `bhimashankar-temple` | same | Bhimashankar Temple | Maharashtra | 5 |
| `biraja-temple` | same | Biraja Temple | Odisha | 5 |
| `birla-mandir-jaipur` | `birla-mandir-lakshmi-narayan-temple` | Birla Mandir (Lakshmi Narayan Temple) | Rajasthan | 5 |
| `birla-mandir-kolkata` | `birla-mandir` | Birla Mandir | West Bengal | 5 |
| `brahma-temple-pushkar` | `brahma-temple` | Brahma Temple | Rajasthan | 5 |
| `chilkur-balaji-temple` | same | Chilkur Balaji Temple | Telangana | 4 |
| `chintpurni-temple` | same | Chintpurni Temple | Himachal Pradesh | 5 |
| `chotila-chamunda-mata-temple` | same | Chotila Chamunda Mata Temple | Gujarat | 5 |
| `cuttack-chandi-temple` | same | Cuttack Chandi Temple | Odisha | 5 |
| `dakshineswar-kali-temple` | same | Dakshineswar Kali Temple | West Bengal | 5 |
| `deo-sun-temple` | same | Deo Sun Temple | Bihar | 5 |
| `dwarkadhish-temple` | same | Dwarkadhish Temple | Gujarat | 5 |
| `eklingji-temple` | same | Eklingji Temple | Rajasthan | 5 |
| `gnana-saraswati-temple-basara` | `gnana-saraswati-temple` | Gnana Saraswati Temple | Telangana | 5 |
| `gorakhnath-temple` | same | Gorakhnath Temple | Uttar Pradesh | 5 |
| `govind-dev-ji-temple-jaipur` | `govind-dev-ji-temple` | Govind Dev Ji Temple | Rajasthan | 5 |
| `grishneshwar-temple` | same | Grishneshwar Temple | Maharashtra | 5 |
| `hadimba-devi-temple` | same | Hadimba Devi Temple | Himachal Pradesh | 5 |
| `hangseshwari-temple` | same | Hangseshwari Temple | West Bengal | 5 |
| `harsiddhi-temple-ujjain` | `harsiddhi-temple` | Harsiddhi Temple | Madhya Pradesh | 5 |
| `jagannath-temple-puri` | `jagannath-temple` | Jagannath Temple | Odisha | 5 |
| `jejuri-khandoba-temple` | same | Jejuri Khandoba Temple | Maharashtra | 4 |
| `jogulamba-temple-alampur` | `jogulamba-temple` | Jogulamba Temple | Telangana | 5 |
| `jwalamukhi-temple` | same | Jwalamukhi Temple | Himachal Pradesh | 5 |
| `kalighat-kali-temple` | same | Kalighat Kali Temple | West Bengal | 5 |
| `kalika-mata-temple-pavagadh` | `kalika-mata-temple` | Kalika Mata Temple | Gujarat | 6 |
| `kandariya-mahadeva-temple` | same | Kandariya Mahadeva Temple | Madhya Pradesh | 5 |
| `kapil-muni-temple-gangasagar` | `kapil-muni-temple` | Kapil Muni Temple | West Bengal | 5 |
| `karni-mata-temple-deshnok` | `karni-mata-temple` | Karni Mata Temple | Rajasthan | 5 |
| `khatushyam-temple` | same | Khatushyam Temple | Rajasthan | 5 |
| `kheer-bhawani-temple` | same | Kheer Bhawani Temple | Jammu and Kashmir | 5 |
| `kiriteswari-temple` | same | Kiriteswari Temple | West Bengal | 5 |
| `konark-sun-temple` | same | Konark Sun Temple | Odisha | 5 |
| `lakshmana-temple-khajuraho` | `lakshmana-temple` | Lakshmana Temple | Madhya Pradesh | 6 |
| `lakshmi-narayan-temple-chamba` | `lakshmi-narayan-temple` | Lakshmi Narayan Temple | Himachal Pradesh | 5 |
| `lingaraj-temple` | same | Lingaraj Temple | Odisha | 5 |
| `mahakaleshwar-temple` | same | Mahakaleshwar Temple | Madhya Pradesh | 7 |
| `mahalakshmi-temple-mumbai` | `mahalakshmi-temple` | Mahalakshmi Temple | Maharashtra | 5 |
| `mahavir-mandir-patna` | `mahavir-mandir` | Mahavir Mandir | Bihar | 5 |
| `manikaran-shiva-temple` | same | Manikaran Shiva Temple | Himachal Pradesh | 3 |
| `mehandipur-balaji-temple` | same | Mehandipur Balaji Temple | Rajasthan | 5 |
| `modhera-sun-temple` | same | Modhera Sun Temple | Gujarat | 5 |
| `morgaon-mayureshwar-temple` | same | Morgaon Mayureshwar Temple | Maharashtra | 5 |
| `mukteshwar-temple` | same | Mukteshwar Temple | Odisha | 5 |
| `mumba-devi-temple` | same | Mumba Devi Temple | Maharashtra | 5 |
| `mundeshwari-devi-temple` | same | Mundeshwari Devi Temple | Bihar | 5 |
| `nageshwar-jyotirlinga-temple` | same | Nageshwar Jyotirlinga Temple | Gujarat | 5 |
| `naina-devi-temple-bilaspur` | `naina-devi-temple` | Naina Devi Temple | Himachal Pradesh | 5 |
| `omkareshwar-temple` | same | Omkareshwar Temple | Madhya Pradesh | 5 |
| `panchvaktra-temple-mandi` | `panchvaktra-temple` | Panchvaktra Temple | Himachal Pradesh | 5 |
| `pashupatinath-temple-mandsaur` | `pashupatinath-temple` | Pashupatinath Temple | Madhya Pradesh | 6 |
| `patan-devi-temple` | same | Patan Devi Temple | Bihar | 5 |
| `prem-mandir-vrindavan` | `prem-mandir` | Prem Mandir | Uttar Pradesh | 5 |
| `raghunath-temple-jammu` | `raghunath-temple` | Raghunath Temple | Jammu and Kashmir | 5 |
| `rajarani-temple` | same | Rajarani Temple | Odisha | 5 |
| `ram-mandir-ayodhya` | `ram-mandir-shri-ram-janmabhoomi-temple` | Ram Mandir (Shri Ram Janmabhoomi Temple) | Uttar Pradesh | 5 |
| `ram-raja-temple-orchha` | `ram-raja-temple` | Ram Raja Temple | Madhya Pradesh | 5 |
| `ramappa-temple` | `ramappa-temple-rudreshwara` | Ramappa Temple (Rudreshwara) | Telangana | 5 |
| `salasar-balaji-temple` | `salasar-balaji` | Salasar Balaji | Rajasthan | 5 |
| `sankat-mochan-hanuman-temple` | same | Sankat Mochan Hanuman Temple | Uttar Pradesh | 5 |
| `satyanarayana-swamy-temple-annavaram` | `satyanarayana-swamy-temple` | Satyanarayana Swamy Temple | Andhra Pradesh | 6 |
| `shankaracharya-temple` | same | Shankaracharya Temple | Jammu and Kashmir | 5 |
| `sharda-devi-temple-maihar` | same | Sharda Devi Temple Maihar | Madhya Pradesh | 5 |
| `shree-saibaba-samadhi-mandir` | same | Shree Saibaba Samadhi Mandir | Maharashtra | 6 |
| `shrinathji-temple-nathdwara` | `shrinathji-temple` | Shrinathji Temple | Rajasthan | 5 |
| `siddhivinayak-temple-mumbai` | `siddhivinayak-temple` | Siddhivinayak Temple | Maharashtra | 5 |
| `sita-ramachandra-swamy-bhadrachalam` | `sita-ramachandra-swamy-temple` | Sita Ramachandra Swamy Temple | Telangana | 5 |
| `somnath-temple` | same | Somnath Temple | Gujarat | 5 |
| `sri-lakshmi-narasimha-swamy-yadagirigutta` | `sri-lakshmi-narasimha-swamy-temple` | Sri Lakshmi Narasimha Swamy Temple | Telangana | 5 |
| `sri-mallikarjuna-swamy-temple-srisailam` | `sri-mallikarjuna-swamy-temple` | Sri Mallikarjuna Swamy Temple | Andhra Pradesh | 4 |
| `sri-mayapur-chandrodaya-mandir` | `sri-mayapur-chandrodaya-mandir-iskcon-mayapur` | Sri Mayapur Chandrodaya Mandir (ISKCON Mayapur) | West Bengal | 5 |
| `taraknath-temple-tarakeswar` | `taraknath-temple` | Taraknath Temple | West Bengal | 6 |
| `tarapith-temple` | same | Tarapith Temple | West Bengal | 5 |
| `thousand-pillar-temple` | same | Thousand Pillar Temple | Telangana | 5 |
| `tirumala-venkateswara-temple` | same | Tirumala Venkateswara Temple | Andhra Pradesh | 5 |
| `trimbakeshwar-temple` | same | Trimbakeshwar Temple | Maharashtra | 6 |
| `vaishno-devi-temple` | same | Vaishno Devi Temple | Jammu and Kashmir | 4 |
| `varaha-lakshmi-narasimha-temple-simhachalam` | `varaha-lakshmi-narasimha-temple` | Varaha Lakshmi Narasimha Temple | Andhra Pradesh | 5 |
| `varasidhi-vinayaka-temple-kanipakam` | `varasidhi-vinayaka-temple` | Varasidhi Vinayaka Temple | Andhra Pradesh | 5 |
| `veerabhadra-temple-lepakshi` | `veerabhadra-temple` | Veerabhadra Temple | Andhra Pradesh | 5 |
| `vindhyavasini-temple` | same | Vindhyavasini Temple | Uttar Pradesh | 5 |
| `vishnupad-temple` | same | Vishnupad Temple | Bihar | 6 |
| `vitthal-rukmini-temple-pandharpur` | `vitthal-rukmini-temple` | Vitthal Rukmini Temple | Maharashtra | 5 |
| `yaganti-uma-maheswara-temple` | same | Yaganti Uma Maheswara Temple | Andhra Pradesh | 5 |

## KAN-76 Wave D

Built on Wave C (#25). Fresh Research manifests; URLs are Commons
`upload.wikimedia.org` 1280px thumbs (or the original when it is narrower than
1280px). Storage and Firestore ids are Seed `templeDocumentId(name)`.

| Pack folder | Seed `templeDocumentId` | Temple | State | Photos |
| --- | --- | --- | --- | --- |
| `ajgaibinath-temple` | same | Ajgaibinath Temple | Bihar | 5 |
| `amarnath-cave-temple` | same | Amarnath Cave Temple | Jammu and Kashmir | 7 |
| `bade-hanuman-ji-temple-prayagraj` | `bade-hanuman-ji-temple-lete-hanuman` | Bade Hanuman Ji Temple (Lete Hanuman) | Uttar Pradesh | 7 |
| `chamunda-devi-temple-kangra` | `chamunda-devi-temple` | Chamunda Devi Temple | Himachal Pradesh | 6 |
| `hanuman-garhi-ayodhya` | `hanuman-garhi` | Hanuman Garhi | Uttar Pradesh | 6 |
| `kanaka-durga-temple` | same | Kanaka Durga Temple | Andhra Pradesh | 6 |
| `kanyakumari-bhagavathi-amman-temple` | same | Kanyakumari Bhagavathi Amman Temple | Tamil Nadu | 6 |
| `kashi-vishwanath-temple` | same | Kashi Vishwanath Temple | Uttar Pradesh | 6 |
| `keesaragutta-temple` | same | Keesaragutta Temple | Telangana | 6 |
| `krishna-janmabhoomi-temple` | same | Krishna Janmabhoomi Temple | Uttar Pradesh | 5 |
| `maa-taratarini-temple` | same | Maa Taratarini Temple | Odisha | 6 |
| `mannarsala-sree-nagaraja-temple` | same | Mannarsala Sree Nagaraja Temple | Kerala | 5 |
| `matangeshwar-temple` | same | Matangeshwar Temple | Madhya Pradesh | 6 |
| `padmavathi-temple-tiruchanur` | `padmavathi-temple` | Padmavathi Temple | Andhra Pradesh | 7 |
| `ranchhodraiji-temple-dakor` | `ranchhodraiji-temple` | Ranchhodraiji Temple | Gujarat | 7 |
| `sakshi-gopal-temple` | same | Sakshi Gopal Temple | Odisha | 6 |

Dropped in review: `krishna-janmabhoomi-temple` / `05_*` (`File:Krishnajanmabhoomi 1988A.jpg`) shows the adjoining Shahi Idgah, not the temple.
Kashi Vishwanath’s cover is `File:Kashi Vishwanath Temple in 2025.jpg` (CC BY 4.0, Pradum Shukla, own work). The original is 1153px wide, so the pack keeps the unscaled file.

## KAN-76 top-up (Research new_in_topup frames)

| Pack | Photos | Change |
| --- | --- | --- |
| `hanuman-garhi-ayodhya` | 6 | dropped 05 `(60)` and 06 `Ancient Temple Ayodhya` (not site-verified), added 08; 04 confirmed by Research (श्री हनुमानगढ़ी signboard visible) |
| `krishna-janmabhoomi-temple` | 5 | added Research top-up frames |
| `lakshmana-temple-khajuraho` | 6 | added Research top-up frames |
| `satyanarayana-swamy-temple-annavaram` | 6 | added Research top-up frames |
| `kalika-mata-temple-pavagadh` | 6 | added Research top-up frames |
| `trimbakeshwar-temple` | 6 | added Research top-up frames |
| `mahakaleshwar-temple` | 7 | added Research top-up frames |
| `vishnupad-temple` | 6 | added Research top-up frames |
| `somnath-temple` | 5 | dropped 02 floor-plan drawing and 03 night aerial (near-duplicate of 04), added 05–07 |
| `banke-bihari-temple` | 4 | added Research top-up frames, then dropped the 434px `05_Banke-Bihari-Mandir-Vrindavan.jpg` |
| `morgaon-mayureshwar-temple` | 5 | added Research top-up frames |
| `chilkur-balaji-temple` | 4 | added Research top-up frames |
