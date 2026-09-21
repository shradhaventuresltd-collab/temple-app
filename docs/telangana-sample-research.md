# Telangana sample expansion (batch 5)

Research-backed copy for **10 new Telangana temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Telangana Endowments / ASI–UNESCO / district tourism pages over tourist aggregators. Re-check Yadadri, Bhadrachalam, and Keesaragutta Endowments portals, Ramappa ASI–UNESCO visitor rules, Basara Akshara Abhyasam windows, Chilkur notice boards, the Jogulamba district page, and the Kaleshwaram local board.

## Field mapping (Dart model ↔ Firestore)

| Research / sample Dart | Firestore (Seed + Admin CMS) |
| --- | --- |
| `name`, `state`, `city`, `deity` | same |
| `location` | `address` (`Temple.location`; `fromMap` also accepts legacy `location`) |
| `description`, `story`, `timings` | same |
| `specialities` (`List<String>`) | same |
| `latitude`, `longitude` | same |
| `imageUrl` / `images` | same — **picsum placeholders** in the app sample; gallery `images` stays empty until Storage upload |
| `sources`, `photo_candidates`, `rituals_notes` | **not in the Temple schema** — documented here only |

No `pooja_schedule`, `darshan_windows`, `festivals`, or `site_type` fields were added. Ritual detail stays in `timings`, `story`, and `specialities`.

## Images

The research payload left `imageUrl` empty and `images` as `[]`. The bundled sample follows the existing placeholder pattern: `https://picsum.photos/seed/{name-slug}/800/600`, with `images` left empty. Do **not** invent Firebase Storage paths.

Commons `photo_candidates` below are file **pages** for later manual download, attribution, upload to `temples/{docId}/…`, then CMS `images` / `imageUrl`. Do **not** paste these Commons URLs into sample data as if they were Storage paths.

## Honesty caveats kept in sample copy

Jogulamba is listed under Telangana (older Andhra border history is noted in the story). Bhadrakali and Kaleshwaram have thinner official English clocks and say so. Ramappa and the Thousand Pillar Temple are heritage sites with modest living-worship notes, not invented seva grids.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Sri Lakshmi Narasimha Swamy Temple | `sri-lakshmi-narasimha-swamy-temple` | OPTIONAL CMS: hill/complex walking distances after rebuild; Saturdays and holidays see long queues — prefer early general darshan; confirm live seva quota on official portal. Research payload id `sri-lakshmi-narasimha-swamy-yadagirigutta` is not the seed id. |
| Sita Ramachandra Swamy Temple | `sita-ramachandra-swamy-temple` | OPTIONAL CMS: approach often via ghat/steps; festival kalyanam ticketing only via official portal; midday break commonly closes garbha griha. Research payload id `sita-ramachandra-swamy-bhadrachalam` is not the seed id. |
| Thousand Pillar Temple | `thousand-pillar-temple` | OPTIONAL CMS: flag as ASI monument + living temple; structured entry/parking may apply; prioritize conservation rules over heavy ritual booking UX. |
| Ramappa Temple (Rudreshwara) | `ramappa-temple-rudreshwara` | OPTIONAL CMS: prioritize UNESCO/ASI visitor fields (tickets, photography, restricted zones) alongside brief living-temple pooja note. Research payload id `ramappa-temple` is not the seed id. |
| Gnana Saraswati Temple | `gnana-saraswati-temple` | OPTIONAL CMS: Akshara Abhyasam slot booking / age guidance; Godavari bathing steps nearby; expect school-holiday rushes. Research payload id `gnana-saraswati-temple-basara` is not the seed id. |
| Chilkur Balaji Temple | `chilkur-balaji-temple` | OPTIONAL CMS: model pradakshina counter UX (11 / 108); emphasize equal-access / no-VIP messaging; weekend parking queues from Mehdipatnam / Gandipet roads. |
| Keesaragutta Temple | `keesaragutta-temple` | OPTIONAL CMS: hill steps / alternate path; Kartika Monday and Shivaratri crowd warnings; Hanuman shrine visit order per local custom. |
| Bhadrakali Temple | `bhadrakali-temple` | OPTIONAL CMS: lake + temple paired POI; note thinner official English timing pages than Yadadri/Bhadrachalam — flag for local verification. Research payload id `bhadrakali-temple-warangal` is not the seed id. |
| Jogulamba Temple | `jogulamba-temple` | OPTIONAL CMS: state=Telangana, city=Alampur despite older AP-border listings; link related Navabrahma ASI POIs; midday break 1:00–2:00 PM per district page. Research payload id `jogulamba-temple-alampur` is not the seed id. |
| Kaleshwara Mukteswara Temple | `kaleshwara-mukteswara-temple` | OPTIONAL CMS: thin official English timing portal vs Wikipedia/tourism summaries — flag for local verification; photo Commons coverage is thin (older entrance shot). |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Sri Lakshmi Narasimha Swamy Temple

Seed slug: `sri-lakshmi-narasimha-swamy-temple`

Research payload id `sri-lakshmi-narasimha-swamy-yadagirigutta` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Yadagirigutta. Deity label: `Vishnu`. Map pin: 17.5892, 78.9446.

Sources:

- [Sri Lakshmi Narasimha Swamy vari Devasthanam — Timings (official)](https://yadagiriguttatemple.telangana.gov.in/timings/)
- [Yadadri Temple portal (official)](https://yadadritemple.telangana.gov.in/)
- [Telangana Endowments — Yadagiri history note](https://endowments.ts.nic.in/yadgiri.html)
- [Sri Lakshmi Narasimha Swamy Temple, Yadagirigutta — Wikipedia](https://en.wikipedia.org/wiki/Sri_Lakshmi_Narasimha_Swamy_Temple,_Yadagirigutta)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Yadagirigutta_temple_main_Gopuram.jpg — CC BY-SA 4.0, Adityamadhav83. Main gopuram view (2014, pre-/during-rebuild era); verify if CMS prefers post-reconstruction photography

Ritual overflow (not a Firestore field): OPTIONAL CMS: hill/complex walking distances after rebuild; Saturdays and holidays see long queues — prefer early general darshan; confirm live seva quota on official portal.

### Sita Ramachandra Swamy Temple

Seed slug: `sita-ramachandra-swamy-temple`

Research payload id `sita-ramachandra-swamy-bhadrachalam` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Bhadrachalam. Deity label: `Vishnu`. Map pin: 17.6669, 80.8828.

Sources:

- [Sree Seetha Ramachandra Swamy Devasthanam — Timings (official)](https://bhadradritemple.telangana.gov.in/timings/)
- [Bhadrachalam Devasthanam portal (official)](https://bhadradritemple.telangana.gov.in/)
- [Sita Ramachandraswamy Temple, Bhadrachalam — Wikipedia](https://en.wikipedia.org/wiki/Sita_Ramachandraswamy_Temple,_Bhadrachalam)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:A_view_of_Sree_Seetha_Ramachandraswamy_temple_from_a_nearby_hotel.jpg — CC BY-SA 4.0, iMahesh. Quality-image exterior view of the Godavari-side temple complex (2024)

Ritual overflow (not a Firestore field): OPTIONAL CMS: approach often via ghat/steps; festival kalyanam ticketing only via official portal; midday break commonly closes garbha griha.

### Thousand Pillar Temple

Seed slug: `thousand-pillar-temple`

City: Hanamkonda. Deity label: `Shiva`. Map pin: 18.0037, 79.5748.

Sources:

- [Thousand Pillar Temple — Wikipedia](https://en.wikipedia.org/wiki/Thousand_Pillar_Temple)
- [Thousand Pillar Temple — Hanumakonda District (Govt. of Telangana)](https://hanumakonda.telangana.gov.in/tourist-place/thousand-pillar-temple/)
- [Incredible India — Thousand Pillar Temple](https://www.incredibleindia.gov.in/en/telangana/warangal/thousand-pillar-temple)
- [UNESCO — The Glorious Kakatiya Temples and Gateways (tentative)](https://whc.unesco.org/en/tentativelists/5889/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Thousand_Pillar_Temple_at_Hanamakonda_near_Warangal_05.jpg — CC BY 4.0, Pinakpani. Wide exterior view of the Hanamkonda temple (2024)

Ritual overflow (not a Firestore field): OPTIONAL CMS: flag as ASI monument + living temple; structured entry/parking may apply; prioritize conservation rules over heavy ritual booking UX.

### Ramappa Temple (Rudreshwara)

Seed slug: `ramappa-temple-rudreshwara`

Research payload id `ramappa-temple` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Palampet. Deity label: `Shiva`. Map pin: 18.2592, 79.9433.

Sources:

- [Kakatiya Rudreshwara (Ramappa) Temple — UNESCO World Heritage Centre](https://whc.unesco.org/en/list/1570/)
- [Telangana Tourism — Ramappa](https://www.tourism.telangana.gov.in/page/ramappa)
- [Ramappa Temple — Wikipedia](https://en.wikipedia.org/wiki/Ramappa_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:WHS_Ramappa_Temple_1.jpg — CC BY-SA 4.0, Khushi Shah 280. Exterior view of the UNESCO-listed temple (2023)

Ritual overflow (not a Firestore field): OPTIONAL CMS: prioritize UNESCO/ASI visitor fields (tickets, photography, restricted zones) alongside brief living-temple pooja note.

### Gnana Saraswati Temple

Seed slug: `gnana-saraswati-temple`

Research payload id `gnana-saraswati-temple-basara` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Basara. Deity label: `Devi`. Map pin: 18.8778, 77.9564.

Sources:

- [Telangana Endowments — Basara](https://endowments.ts.nic.in/basara.html)
- [Basara temple content PDF (Endowments)](https://endowments.ts.nic.in/Temple-content/Basara/content.pdf)
- [Gnana Saraswati Temple — Wikipedia](https://en.wikipedia.org/wiki/Gnana_Saraswati_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Basara_Temple_view.jpg — CC BY 2.0, RameshSharma (Flickr: RameshSharma1); Flickr-reviewed. Modest resolution exterior view; Commons coverage of Basara is relatively thin

Ritual overflow (not a Firestore field): OPTIONAL CMS: Akshara Abhyasam slot booking / age guidance; Godavari bathing steps nearby; expect school-holiday rushes.

### Chilkur Balaji Temple

Seed slug: `chilkur-balaji-temple`

City: Chilkur. Deity label: `Vishnu`. Map pin: 17.3583, 78.2986.

Sources:

- [Chilkoor Balaji Temple — Wikipedia](https://en.wikipedia.org/wiki/Chilkoor_Balaji_Temple)
- [Chilkur Balaji Temple — history page](http://www.chilkurbalaji.com/history.html)
- [Chilkur Balaji Temple site (home)](http://www.chilkurbalaji.com/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Gopuram_at_Chilkur_Temple1.jpg — CC BY-SA 3.0, Adityamadhav83. Gopuram view; older modest-resolution Commons file

Ritual overflow (not a Firestore field): OPTIONAL CMS: model pradakshina counter UX (11 / 108); emphasize equal-access / no-VIP messaging; weekend parking queues from Mehdipatnam / Gandipet roads.

### Keesaragutta Temple

Seed slug: `keesaragutta-temple`

City: Keesara. Deity label: `Shiva`. Map pin: 17.5285, 78.6851.

Sources:

- [Sri RamaLingeshwara Swamy vari Devasthanam, Keesaragutta (official)](https://keesaragutta.telangana.gov.in/)
- [Keesaragutta Temple — Wikipedia](https://en.wikipedia.org/wiki/Keesaragutta_Temple)
- [Telangana Tourism (cross-check visitor context)](https://www.tourism.telangana.gov.in/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Keesaragutta_Temple.jpg — CC0 1.0, ప్రశాంతి. Hill/temple landscape view near the shrine (2024); CC0

Ritual overflow (not a Firestore field): OPTIONAL CMS: hill steps / alternate path; Kartika Monday and Shivaratri crowd warnings; Hanuman shrine visit order per local custom.

### Bhadrakali Temple

Seed slug: `bhadrakali-temple`

Research payload id `bhadrakali-temple-warangal` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Warangal. Deity label: `Devi`. Map pin: 17.9951, 79.5823.

Sources:

- [Bhadrakali Temple — Hanumakonda District (Govt. of Telangana)](https://hanumakonda.telangana.gov.in/tourist-place/badhrakali-temple/)
- [Bhadrakali Temple, Warangal — Wikipedia](https://en.wikipedia.org/wiki/Bhadrakali_Temple,_Warangal)
- [Telangana Tourism (cross-check)](https://www.tourism.telangana.gov.in/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Warangal_Bhadrakali_Temple_beside_Bhadrakali_lake,_Warangal,_Telangana,_India_(2017).jpg — CC BY-SA 4.0, Harsha8398. Temple with Bhadrakali Lake and evening sky (2017); GPS-tagged Commons file

Ritual overflow (not a Firestore field): OPTIONAL CMS: lake + temple paired POI; note thinner official English timing pages than Yadadri/Bhadrachalam — flag for local verification.

### Jogulamba Temple

Seed slug: `jogulamba-temple`

Research payload id `jogulamba-temple-alampur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Alampur. Deity label: `Devi`. Map pin: 15.877, 78.1346.

Sources:

- [Alampur Jogulamba Devi — Jogulamba Gadwal District (Govt. of Telangana)](https://gadwal.telangana.gov.in/tourist-place/jogulamba-devi/)
- [Alampur Jogulamba Temple — Wikipedia](https://en.wikipedia.org/wiki/Alampur_Jogulamba_Temple)
- [Alampur — Wikipedia (site / Navabrahma context)](https://en.wikipedia.org/wiki/Alampur,_Jogulamba_Gadwal_district)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Jogulamba_temple_alampur.JPG — CC BY-SA 3.0, రహ్మానుద్దీన్. Jogulamba temple exterior at Alampur (2012)

Ritual overflow (not a Firestore field): OPTIONAL CMS: state=Telangana, city=Alampur despite older AP-border listings; link related Navabrahma ASI POIs; midday break 1:00–2:00 PM per district page.

### Kaleshwara Mukteswara Temple

Seed slug: `kaleshwara-mukteswara-temple`

City: Kaleshwaram. Deity label: `Shiva`. Map pin: 18.8118, 79.904.

Sources:

- [Kaleshwara Mukteswara Swamy Temple — Wikipedia](https://en.wikipedia.org/wiki/Kaleshwara_Mukteswara_Swamy_Temple)
- [Telangana Tourism — Kaleshwaram](https://www.tourism.telangana.gov.in/page/kaleshwaram)
- [Incredible India — Telangana (cross-check)](https://www.incredibleindia.gov.in/en/telangana)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kaleswaram.jpg — Public domain, Tallamma. THIN COVERAGE: older temple-entrance photograph (2010); few license-safe Commons options for the shrine itself

Ritual overflow (not a Firestore field): OPTIONAL CMS: thin official English timing portal vs Wikipedia/tourism summaries — flag for local verification; photo Commons coverage is thin (older entrance shot).
