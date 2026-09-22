# Andhra Pradesh sample expansion (batch 4)

Research-backed copy for **10 new Andhra Pradesh temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Andhra Pradesh Endowments / TTD / ASI pages over tourist aggregators. Re-check TTD live day programme (Tirumala / Tiruchanur), Srisaila Devasthanam, Kanaka Durga / Annavaram Endowments portals, Simhachalam Chandanotsavam, Lepakshi ASI hours, and Ahobilam trek advisories.

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

Timings that disagree across Incredible India, press, and Endowments pages stay labelled in the bundled text. Lepakshi is treated as ASI heritage hours. Ahobilam, Yaganti, and Kanipakam clocks are thin — the copy says so. Growing-Nandi (Yaganti) and growing-Vinayaka (Kanipakam) stay folklore.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Tirumala Venkateswara Temple | `tirumala-venkateswara-temple` | Weekly named sevas on TTD site: Ashtadala Pada Padmaradhana (Tue), Sahasra Kalasabhishekam (Wed), Tiruppavada & Poolangi (Thu), Abhishekam & Nijapada Darshanam (Fri). Dhanurmasa... |
| Sri Mallikarjuna Swamy Temple | `sri-mallikarjuna-swamy-temple` | Official site confirms darshan from 6 AM and traditional dress for sevas; detailed named pooja clock is thinner on the public home pages — prefer on-site boards / day’s seva lis... Research payload id `sri-mallikarjuna-swamy-temple-srisailam` is not the seed id. |
| Varaha Lakshmi Narasimha Temple | `varaha-lakshmi-narasimha-temple` | THIN/CONFLICTING TIMINGS: Incredible India vs local news schedules disagree on day structure. Pack only high-level windows in CMS until Devasthanam confirms. Chandanotsavam and ... Research payload id `varaha-lakshmi-narasimha-temple-simhachalam` is not the seed id. |
| Kanaka Durga Temple | `kanaka-durga-temple` | Timings primarily from tourism/seva aggregators cross-checked with official contact channels; homepage does not publish a full pooja timetable — flag for CMS refresh against kan... |
| Satyanarayana Swamy Temple | `satyanarayana-swamy-temple` | Official Devasthanam darshan page (annavaramdevasthanam.nic.in): Sarva Darshan free typically 06:00 AM–12:30 PM and 01:00 PM–09:00 PM; Seegra Darshan in the same windows. Temple... Research payload id `satyanarayana-swamy-temple-annavaram` is not the seed id. |
| Veerabhadra Temple | `veerabhadra-temple` | Heritage-first site: detailed named daily pooja clock is thinly published compared with Endowments temples — emphasise architecture and visiting hours over invented seva times. Research payload id `veerabhadra-temple-lepakshi` is not the seed id. |
| Ahobilam Narasimha Temples | `ahobilam-narasimha-temples` | Thin primary timing sources — do not invent precise pooja slots. Upper shrine access is trek-dependent; CMS should stress safety and Matha/Endowments advisories. |
| Padmavathi Temple | `padmavathi-temple` | Detailed free-darshan clock drawn from TTD seva pages and aggregator mirrors — re-check tirumala.org PAT seva listing near travel date. Research payload id `padmavathi-temple-tiruchanur` is not the seed id. |
| Varasidhi Vinayaka Temple | `varasidhi-vinayaka-temple` | THIN DETAIL: official darshanam page returned minimal public timetable in research pass — timings text kept cautious; refresh from Devasthanam before CMS publish. Research payload id `varasidhi-vinayaka-temple-kanipakam` is not the seed id. |
| Yaganti Uma Maheswara Temple | `yaganti-uma-maheswara-temple` | Thin official timing documentation — keep CMS timings provisional. Growing-Nandi claim should remain labelled folklore. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Tirumala Venkateswara Temple

Seed slug: `tirumala-venkateswara-temple`

City: Tirumala. Deity label: `Vishnu`. Map pin: 13.68325, 79.347194.

Sources:

- [TTD — Daily Sevas / temple programme (official)](https://www.tirumala.org/DailySevas.aspx)
- [TTD — Sarvadarshanam](https://www.tirumala.org/Sarvadarshanam.aspx)
- [Venkateswara Temple, Tirumala — Wikipedia](https://en.wikipedia.org/wiki/Venkateswara_Temple,_Tirumala)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Tirumala_Venkateswara_temple_entrance_09062015.JPG — CC BY-SA 4.0, Nikhilb239. Temple entrance; verified via Commons search API Sep 2026
- https://commons.wikimedia.org/wiki/File:Tirumala_gopurams.JPG — Public domain, Vimalkalyan. Gopuram view; PD on Commons

Ritual overflow (not a Firestore field): Weekly named sevas on TTD site: Ashtadala Pada Padmaradhana (Tue), Sahasra Kalasabhishekam (Wed), Tiruppavada & Poolangi (Thu), Abhishekam & Nijapada Darshanam (Fri). Dhanurmasam replaces Suprabhatam with Tiruppavai. Book only via official TTD channels.

### Sri Mallikarjuna Swamy Temple

Seed slug: `sri-mallikarjuna-swamy-temple`

Research payload id `sri-mallikarjuna-swamy-temple-srisailam` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Srisailam. Deity label: `Shiva`. Map pin: 16.07417, 78.86806.

Sources:

- [Srisaila Devasthanam (official)](https://www.srisailadevasthanam.org/)
- [Srisailam Darshanam — official sevas page](https://www.srisailadevasthanam.org/en-in/sevas-and-darshanam/darshanam)
- [Mallikarjuna Temple, Srisailam — Wikipedia](https://en.wikipedia.org/wiki/Mallikarjuna_Temple,_Srisailam)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Srisailam-temple-entrance.jpg — Public domain, Chintohere. Temple entrance; PD on Commons
- https://commons.wikimedia.org/wiki/File:Srisailam_Temple_view_noon.jpg — CC BY 2.5, Chavakiran. Complex view at noon

Ritual overflow (not a Firestore field): Official site confirms darshan from 6 AM and traditional dress for sevas; detailed named pooja clock is thinner on the public home pages — prefer on-site boards / day’s seva list over third-party blogs.

### Varaha Lakshmi Narasimha Temple

Seed slug: `varaha-lakshmi-narasimha-temple`

Research payload id `varaha-lakshmi-narasimha-temple-simhachalam` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Visakhapatnam. Deity label: `Vishnu`. Map pin: 17.7664, 83.2505.

Sources:

- [Varaha Lakshmi Narasimha Temple — Incredible India](https://www.incredibleindia.gov.in/en/andhra-pradesh/visakhapatnam/varaha-lakshmi-narasimha-temple)
- [Varaha Lakshmi Narasimha temple, Simhachalam — Wikipedia](https://en.wikipedia.org/wiki/Varaha_Lakshmi_Narasimha_temple,_Simhachalam)
- [AP Temples booking portal (Endowments)](https://www.aptemples.ap.gov.in)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Simhachalam_Temple_Frontview.jpg — CC0, Sree1959. Front view; CC0
- https://commons.wikimedia.org/wiki/File:Simhachalam_temple_front.jpg — CC BY-SA 4.0, Saiphani02. Front elevation

Ritual overflow (not a Firestore field): THIN/CONFLICTING TIMINGS: Incredible India vs local news schedules disagree on day structure. Pack only high-level windows in CMS until Devasthanam confirms. Chandanotsavam and Kalyanotsavam are the reliable festival anchors.

### Kanaka Durga Temple

Seed slug: `kanaka-durga-temple`

City: Vijayawada. Deity label: `Devi`. Map pin: 16.519028, 80.621494.

Sources:

- [Sri Durga Malleswara Swamy Varla Devasthanam (official)](https://kanakadurgamma.org/)
- [Kanaka Durga Temple — Wikipedia](https://en.wikipedia.org/wiki/Kanaka_Durga_Temple)
- [Kanaka Durga Temple timings — Vijayawada Tourism](https://vijayawadatourism.com/kanaka-durga-temple-vijayawada)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kanaka_Durga_Gopuram,_Vijayawada.jpg — CC BY-SA 4.0, Saishna96. Gopuram elevation
- https://commons.wikimedia.org/wiki/File:Bezawada_Kanaka_Durga_Temple.jpg — CC BY-SA 4.0, EnrichIndegi. Temple view

Ritual overflow (not a Firestore field): Timings primarily from tourism/seva aggregators cross-checked with official contact channels; homepage does not publish a full pooja timetable — flag for CMS refresh against kanakadurgamma.org.

### Satyanarayana Swamy Temple

Seed slug: `satyanarayana-swamy-temple`

Research payload id `satyanarayana-swamy-temple-annavaram` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Annavaram. Deity label: `Vishnu`. Map pin: 17.299972, 82.402389.

Sources:

- [Annavaram Devasthanam — Darshan (official NIC)](https://annavaramdevasthanam.nic.in/SideMenu/Darshan?Length=18)
- [Annavaram Devasthanam — Home (official)](https://annavaramdevasthanam.nic.in/Home/Index)
- [Satyanarayana Temple, Annavaram — Wikipedia](https://en.wikipedia.org/wiki/Annavaram_Satyanarayana_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Annavaram_Temple_complex_view_01.jpg — CC BY-SA 3.0, Adityamadhav83. Complex overview
- https://commons.wikimedia.org/wiki/File:East_gopuram_at_Annavaram_Temple_01.jpg — CC BY-SA 3.0, Adityamadhav83. East gopuram

### Veerabhadra Temple

Seed slug: `veerabhadra-temple`

Research payload id `veerabhadra-temple-lepakshi` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Lepakshi. Deity label: `Shiva`. Map pin: 13.801844, 77.609547.

Sources:

- [Lepakshi Temple — Incredible India](https://www.incredibleindia.gov.in/en/andhra-pradesh/anantapur/lepakshi-temple)
- [Sri Veerabhadra Temple and Monolithic Bull — UNESCO Tentative List](https://whc.unesco.org/en/tentativelists/6607)
- [Veerabhadra Temple, Lepakshi — Wikipedia](https://en.wikipedia.org/wiki/Veerabhadra_Temple,_Lepakshi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Veerabhadra_Temple_Tower.JPG — CC BY-SA 3.0, Magentic Manifestations. Temple tower/gopuram
- https://commons.wikimedia.org/wiki/File:LEPAKSHI_TEMPLE.jpg — CC BY-SA 4.0, Sharad iragonda patil. Complex exterior

Ritual overflow (not a Firestore field): Heritage-first site: detailed named daily pooja clock is thinly published compared with Endowments temples — emphasise architecture and visiting hours over invented seva times.

### Ahobilam Narasimha Temples

Seed slug: `ahobilam-narasimha-temples`

City: Ahobilam. Deity label: `Vishnu`. Map pin: 15.1333, 78.7167.

Sources:

- [Ahobilam Endowments TMS portal](https://tms.ap.gov.in/LNAHBM/cnt/index)
- [Visit Ahobilam — Ahobila Mutt](https://ahobilamutt.org/visit-ahobilam/)
- [Ahobilam — Wikipedia](https://en.wikipedia.org/wiki/Ahobilam)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Prahlada_Varada_Lakshmi_Narasimha_Temple,_Ahobilam_in_February_2024_(1).jpg — CC BY 4.0, Veera Narayana. Prahlada Varada temple, Lower Ahobilam
- https://commons.wikimedia.org/wiki/File:Lakshmi_Narasimha_idol_at_the_Prahlada_Varada_Lakshmi_Narasimha_Temple_in_Ahobilam,_February_2024.jpg — CC BY 4.0, Veera Narayana. Sanctum idol view — check Commons reuse rules for deity images before Storage upload

Ritual overflow (not a Firestore field): Thin primary timing sources — do not invent precise pooja slots. Upper shrine access is trek-dependent; CMS should stress safety and Matha/Endowments advisories.

### Padmavathi Temple

Seed slug: `padmavathi-temple`

Research payload id `padmavathi-temple-tiruchanur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Tiruchanur. Deity label: `Devi`. Map pin: 13.607806, 79.450111.

Sources:

- [TTD — Padmavathi Ammavari Temple sevas](https://www.tirumala.org/PatAtThiruchanoorSevas.aspx)
- [Padmavati Temple — Wikipedia](https://en.wikipedia.org/wiki/Padmavati_Temple)
- [TTD official portal](https://www.tirumala.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Padmavathi_Ammavari_Temple.JPG — CC BY-SA 3.0, Vedamurthy.j. Temple exterior
- https://commons.wikimedia.org/wiki/File:Tiruchanur_10.JPG — CC BY-SA 3.0, Malyadri. Tiruchanur temple precinct

Ritual overflow (not a Firestore field): Detailed free-darshan clock drawn from TTD seva pages and aggregator mirrors — re-check tirumala.org PAT seva listing near travel date.

### Varasidhi Vinayaka Temple

Seed slug: `varasidhi-vinayaka-temple`

Research payload id `varasidhi-vinayaka-temple-kanipakam` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Kanipakam. Deity label: `Ganesha`. Map pin: 13.217096, 79.100677.

Sources:

- [Kanipakam Devasthanam (official)](https://srikanipakadevasthanam.org/en-in/)
- [Kanipakam Darshanam — official sevas page](https://srikanipakadevasthanam.org/en-in/sevas-and-darshanam/darshanam)
- [Kanipakam — Wikipedia](https://en.wikipedia.org/wiki/Kanipakam)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kanipakam_Temple.jpg — CC BY-SA 4.0, Vin09. Temple exterior
- https://commons.wikimedia.org/wiki/File:Galipgopuram_of_Kanipakam_temple_(May_2019)_3.jpg — CC BY-SA 4.0, IM3847. Gali gopuram

Ritual overflow (not a Firestore field): THIN DETAIL: official darshanam page returned minimal public timetable in research pass — timings text kept cautious; refresh from Devasthanam before CMS publish.

### Yaganti Uma Maheswara Temple

Seed slug: `yaganti-uma-maheswara-temple`

City: Yaganti. Deity label: `Shiva`. Map pin: 15.350833, 78.139444.

Sources:

- [Yaganti temple — Wikipedia](https://en.wikipedia.org/wiki/Yaganti_temple)
- [Yaganti Uma Maheswara Temple — GoTirupati guide](https://gotirupati.com/yaganti-uma-maheswara-temple/)
- [AP Endowments / temples portal (general)](https://www.aptemples.ap.gov.in)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Yaganti_Temple_Nandi.jpg — CC BY-SA 4.0, PRATHIBA DEVIREDDY. Famous Nandi idol
- https://commons.wikimedia.org/wiki/File:Yaganti_Gopuram.JPG — CC BY-SA 3.0, Pusulurisudhakara. Gopuram

Ritual overflow (not a Firestore field): Thin official timing documentation — keep CMS timings provisional. Growing-Nandi claim should remain labelled folklore.
