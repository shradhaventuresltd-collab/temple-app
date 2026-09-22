# Jammu and Kashmir sample expansion (batch 9)

Research-backed copy for **10 new Jammu and Kashmir temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded. The state field is `Jammu and Kashmir`. This batch does not add a separate Ladakh row.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer SMVDSB, SASB, Incredible India, and ASI pages over tourist aggregators. Re-check Vaishno Devi live aarti and Yatra Parchi rules, the yearly Amarnath SASB board, Raghunath Incredible India hours, and Martand ASI visitor hours.

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

The bundled state label is **Jammu and Kashmir**. This batch does not add a separate Ladakh temple: no solid living Hindu temple in Ladakh with a verified Commons photo was found, so Sudh Mahadev (Udhampur) stays as the tenth row.

Thin official English clocks stay labelled provisional for **Mahamaya**, **Ranbireshwar**, **Purmandal**, **Sudh Mahadev**, and **Shankaracharya** (and Kheer Bhawani’s ordinary-day clock). **Martand** is an ASI ruin with no living cult — timings say so and do not invent aarti slots. **Amarnath** is seasonal (SASB yatra only), not a year-round temple.

Commons coverage: **Ranbireshwar** and **Sudh Mahadev** have empty `photo_candidates` (no file invented). Mahamaya’s candidate is a Bahu Fort precinct shot, not the forest shrine itself. Purmandal’s candidate is a public-domain historical festival plate.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Vaishno Devi Temple | `vaishno-devi-temple` | Carry the RFID Yatra Parchi and government photo ID. Queue by announced group number at Bhawan; do not crowd Gate No.1. Decent dress and Board security rules apply; confirm lock... |
| Amarnath Cave Temple | `amarnath-cave-temple` | Do not attempt off-season access. Carry permit, RFID, warm layers, and follow camp medical advice for altitude. Security and ecological rules are strict along both axes; ponies/... |
| Raghunath Temple | `raghunath-temple` | City-centre security can be heightened; follow local police/temple entry rules. Photography policies vary by shrine within the complex — ask staff. Research payload id `raghunath-temple-jammu` is not the seed id. |
| Shankaracharya Temple | `shankaracharya-temple` | Steep steps — allow time and water. Security frisking common; drones/restricted photography may apply near strategic hilltop. Combine with Boulevard / Dal circuit only if securi... |
| Kheer Bhawani Temple | `kheer-bhawani-temple` | Mela days require early arrival and patience at security. Offerings of kheer are customary; follow priest/trust guidance inside the spring precinct. Photography rules can tighte... |
| Mahamaya Temple | `mahamaya-temple` | Distinguish Mahamaya (city forest) from Bawe Wali Mata (inside Bahu Fort). Wear modest clothing; forest paths can be uneven after rain. Photo coverage on Commons is for the fort... Research payload id `mahamaya-temple-jammu` is not the seed id. |
| Ranbireshwar Temple | `ranbireshwar-temple` | City traffic around Secretariat/Parade can be heavy — plan parking. No verified Wikimedia Commons photograph of this temple was located this pass; photo_candidates left empty ra... |
| Martand Sun Temple | `martand-sun-temple` | Apply note for CMS: site_type equivalent is archaeological ruin — express only via story/timings/specialities (no new schema field). Do not list pooja slots. Respect ASI signage... |
| Purmandal Temple | `purmandal-temple` | Devak bathing spots can be slippery; follow local guidance. Modern temple-building photos are scarce on Commons — research pass found a public-domain 1847 festival lithograph only. |
| Sudh Mahadev Temple | `sudh-mahadev-temple` | Hill road from Chenani/Patnitop can close in bad weather. Sawan full-moon night is extremely crowded — arrive early. No Commons photo candidate found; do not invent URLs. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Vaishno Devi Temple

Seed slug: `vaishno-devi-temple`

City: Katra. Deity label: `Devi`. Map pin: 33.0297, 74.9484.

Sources:

- [Shri Mata Vaishno Devi Shrine Board — Aarti](http://www.maavaishnodevi.org/blog/aarti)
- [Shri Mata Vaishno Devi Shrine Board — Live Atka Aarti / Darshan](http://maavaishnodevi.org/live)
- [Shri Mata Vaishno Devi Shrine Board — FAQ / General Information](https://www.maavaishnodevi.org/faq)
- [Vaishno Devi — Wikipedia](https://en.wikipedia.org/wiki/Vaishno_Devi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mata_Vaishno_Devi_Bhawan,_Jammu._India.jpg — CC BY-SA 4.0, SUDEEP PRAMANIK. Bhawan surrounded by Trikuta Hills; verified Commons license page

Ritual overflow (not a Firestore field): Carry the RFID Yatra Parchi and government photo ID. Queue by announced group number at Bhawan; do not crowd Gate No.1. Decent dress and Board security rules apply; confirm locker/phone policy on site. Lean-season Prachin Gufa opening is Board-notified only.

### Amarnath Cave Temple

Seed slug: `amarnath-cave-temple`

City: Pahalgam / Anantnag (yatra). Deity label: `Shiva`. Map pin: 34.2149, 75.5008.

Sources:

- [Shri Amarnathji Shrine Board (official)](https://www.jksasb.nic.in/)
- [Shri Amarnathji Shrine Board — Yatra routes / info](https://www.jksasb.nic.in/yatra.html)
- [Amarnath Temple — Wikipedia](https://en.wikipedia.org/wiki/Amarnath_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Shri_Amarnath_Ji_Holy_Cave(GUFA).jpg — CC BY-SA 4.0, Itzseoprasoon. Exterior view of the holy cave (GUFA); verified Commons license page

Ritual overflow (not a Firestore field): Do not attempt off-season access. Carry permit, RFID, warm layers, and follow camp medical advice for altitude. Security and ecological rules are strict along both axes; ponies/palkis and community kitchens operate under Board licensing during the yatra.

### Raghunath Temple

Seed slug: `raghunath-temple`

Research payload id `raghunath-temple-jammu` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Jammu. Deity label: `Vishnu`. Map pin: 32.7304, 74.8623.

Sources:

- [District Jammu — Raghunath Temple](https://jammu.nic.in/tourist-place/raghunath-temple-jammu/)
- [Incredible India — Raghunath Temple](https://www.incredibleindia.gov.in/en/jammu-and-kashmir/jammu/raghunath-temple)
- [Raghunath Temple — Wikipedia](https://en.wikipedia.org/wiki/Raghunath_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Raghunath_Temple_Jammu.JPG — GFDL, Bhadani (English Wikipedia). Front view with shikhara (1988 photo); verified Commons file page — GFDL

Ritual overflow (not a Firestore field): City-centre security can be heightened; follow local police/temple entry rules. Photography policies vary by shrine within the complex — ask staff.

### Shankaracharya Temple

Seed slug: `shankaracharya-temple`

City: Srinagar. Deity label: `Shiva`. Map pin: 34.0789, 74.8436.

Sources:

- [Shankaracharya Temple — Wikipedia](https://en.wikipedia.org/wiki/Shankaracharya_Temple)
- [Commons category — Shankaracharya Temple](https://commons.wikimedia.org/wiki/Category:Shankaracharya_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:The_Ancient_Shankaracharya_Temple_(Srinagar,_Jammu_and_Kashmir).jpg — CC BY-SA 3.0, Divya Gupta. ASI monument photo of the stone temple; verified Commons license page

Ritual overflow (not a Firestore field): Steep steps — allow time and water. Security frisking common; drones/restricted photography may apply near strategic hilltop. Combine with Boulevard / Dal circuit only if security permits the same day.

### Kheer Bhawani Temple

Seed slug: `kheer-bhawani-temple`

City: Tulmulla. Deity label: `Devi`. Map pin: 34.2211, 74.73.

Sources:

- [Kheer Bhawani Temple — Wikipedia](https://en.wikipedia.org/wiki/Kheer_Bhawani_Temple)
- [Commons category — Kheer Bhawani](https://commons.wikimedia.org/wiki/Category:Kheer_Bhawani)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kheer_Bhawani.jpg — CC BY 3.0, Akshey25. Temple precinct photo (2011); verified Commons license page

Ritual overflow (not a Firestore field): Mela days require early arrival and patience at security. Offerings of kheer are customary; follow priest/trust guidance inside the spring precinct. Photography rules can tighten on festival days.

### Mahamaya Temple

Seed slug: `mahamaya-temple`

Research payload id `mahamaya-temple-jammu` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Jammu. Deity label: `Devi`. Map pin: 32.7304, 74.8905.

Sources:

- [District Jammu — Bahu Fort (mentions Maha Maya Temple)](https://jammu.nic.in/tourist-place/bahu-fort-jammu/)
- [Explore India — Temples in Jammu (Mahamaya / Ranbireshwar notes)](https://www.exploreindia.in/temples-in-jammu.htm)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Bahu_Fort,_Jammu.jpg — CC BY-SA 4.0, Vedant Sharma. Bahu Fort precinct overlooking the Tawi; Mahamaya lies in city forest behind the fort — no dedicated Commons sanctum file found

Ritual overflow (not a Firestore field): Distinguish Mahamaya (city forest) from Bawe Wali Mata (inside Bahu Fort). Wear modest clothing; forest paths can be uneven after rain. Photo coverage on Commons is for the fort precinct, not a dedicated Mahamaya sanctum file.

### Ranbireshwar Temple

Seed slug: `ranbireshwar-temple`

City: Jammu. Deity label: `Shiva`. Map pin: 32.7347, 74.8641.

Sources:

- [Explore India — Ranbireshwar Temple](https://www.exploreindia.in/temples-in-jammu.htm)
- [Holidify — Shree Ranbireshwar Temple (secondary timings)](https://www.holidify.com/places/jammu/shree-ranbireshwar-temple-sightseeing-120761.html)

Photo candidates (Commons file pages):

- None verified in this pass.

Ritual overflow (not a Firestore field): City traffic around Secretariat/Parade can be heavy — plan parking. No verified Wikimedia Commons photograph of this temple was located this pass; photo_candidates left empty rather than inventing URLs.

### Martand Sun Temple

Seed slug: `martand-sun-temple`

City: Mattan / Anantnag. Deity label: `Surya`. Map pin: 33.7456, 75.2203.

Sources:

- [Incredible India — Martand Sun Temple](https://www.incredibleindia.gov.in/en/jammu-and-kashmir/anantnag/martand-sun-temple)
- [Martand Sun Temple — Wikipedia](https://en.wikipedia.org/wiki/Martand_Sun_Temple)
- [Commons category — Sun Temple, Martand](https://commons.wikimedia.org/wiki/Category:Sun_Temple,_Martand)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Martand_Sun_Temple,_J%26K_01.jpg — CC BY-SA 4.0, Deepank Ranka. Ruins of Martand Sun Temple, Anantnag; verified Commons license page

Ritual overflow (not a Firestore field): Apply note for CMS: site_type equivalent is archaeological ruin — express only via story/timings/specialities (no new schema field). Do not list pooja slots. Respect ASI signage; do not climb unstable masonry.

### Purmandal Temple

Seed slug: `purmandal-temple`

City: Samba. Deity label: `Shiva`. Map pin: 32.6957, 75.0609.

Sources:

- [Jammu.com — Temples & Shrines (Purmandal / Sudh Mahadev)](https://www.jammu.com/jammu/temples-shrines.php)
- [SMVDSB Jammu itinerary PDF (lists Purmandal)](https://www.maavaishnodevi.org/sites/default/files/2023-12/Jammu_Itinerary_Full.pdf)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Plate_17._Festival_(male)_at_Poormandal,_near_Jammu_-_Part_2._Recollections_of_India_(FIRST_EDITION)_5588_017.jpg — Public domain, Charles Stewart Hardinge / J.D. Harding lithograph (1847). Historical PD festival scene at Poormandal — not a modern temple exterior; only verified Commons file tied to the site this pass

Ritual overflow (not a Firestore field): Devak bathing spots can be slippery; follow local guidance. Modern temple-building photos are scarce on Commons — research pass found a public-domain 1847 festival lithograph only.

### Sudh Mahadev Temple

Seed slug: `sudh-mahadev-temple`

City: Udhampur. Deity label: `Shiva`. Map pin: 33.0214, 75.3635.

Sources:

- [District Udhampur — Sudh Mahadev and Mantalai](https://udhampur.nic.in/tourist-place/sudh-mahadev-and-mantalai/)
- [Jammu.com — Sudh Mahadev](https://www.jammu.com/jammu/temples-shrines.php)

Photo candidates (Commons file pages):

- None verified in this pass.

Ritual overflow (not a Firestore field): Hill road from Chenani/Patnitop can close in bad weather. Sawan full-moon night is extremely crowded — arrive early. No Commons photo candidate found; do not invent URLs.
