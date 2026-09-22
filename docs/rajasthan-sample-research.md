# Rajasthan sample expansion (batch 11)

Research-backed copy for **10 new Rajasthan temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer Pushkar Brahma Devasthan, Nathdwara’s same-day jhanki board, Govind Dev Ji, and Mehandipur’s official FAQ over compilations. Re-check Karni Mata tourism hours, Dilwara’s devotee-morning / tourist-afternoon split, and thin or conflicting clocks for Eklingji, Birla Mandir Jaipur, Salasar Balaji, and Khatushyam.

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

Dilwara is a Jain marble tirtha, not a Hindu temple — the story says no Hindu garbha cult operates there. Nathdwara timings stay date-variable. Pushkar keeps the seasonal board and midday close. Salasar Balaji keeps conflicting site clocks. Eklingji, Birla Mandir Jaipur, and Khatushyam are labelled thin or provisional official English clocks. Mehandipur keeps the Monday/Wednesday/Friday chola close.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Brahma Temple | `brahma-temple` | Bathe or wash at the lake ghats before darshan if following local custom. Only ascetic priests enter the garbha griha — hand offerings through them. No photography in the inner... Research payload id `brahma-temple-pushkar` is not the seed id. |
| Eklingji Temple | `eklingji-temple` | Thin official English day-board — label timings provisional. Expect closed intervals between darshan windows. Remove leather footwear/belts if required at gate; follow on-site p... |
| Shrinathji Temple | `shrinathji-temple` | Arrive 20–30 minutes before a jhanki; queues move quickly once doors open. Phones/cameras usually not allowed inside the haveli. Festival and seasonal tippanis override the samp... Research payload id `shrinathji-temple-nathdwara` is not the seed id. |
| Karni Mata Temple | `karni-mata-temple` | Walk carefully — kabbas have right of way. Do not harm rats; follow local custom if an accident occurs. Shoes off at the gate; keep food offerings for rats/prasad channels as di... Research payload id `karni-mata-temple-deshnok` is not the seed id. |
| Govind Dev Ji Temple | `govind-dev-ji-temple` | Midday closure is for seva — do not expect continuous afternoon darshan. Festival clocks shift; use the temple’s advance timetable page. Palace-area security may restrict large... Research payload id `govind-dev-ji-temple-jaipur` is not the seed id. |
| Birla Mandir (Lakshmi Narayan Temple) | `birla-mandir-lakshmi-narayan-temple` | Thin official English clock — timings labelled provisional from tourism boards. Afternoon closure is standard on most listings. Decent dress; keep voice low in the marble halls. Research payload id `birla-mandir-jaipur` is not the seed id. |
| Dilwara Temples | `dilwara-temples` | NOTE: Dilwara is a Jain pilgrimage complex, not a Hindu temple — included as an iconic Rajasthan sacred site in this temple directory. Morning hours prioritize Jain worship; tou... Research payload id `dilwara-temples-mount-abu` is not the seed id. |
| Salasar Balaji | `salasar-balaji` | Thin / conflicting official English clocks across sites claiming authority — timings labelled provisional. Prefer the physical notice board at Salasar Dham. Expect heavy securit... Research payload id `salasar-balaji-temple` is not the seed id. |
| Khatushyam Temple | `khatushyam-temple` | Official English continuous darshan clock is thin — prefer temple-committee notices and Hindi boards on site. Phalguna Mela requires advance stay booking. Dupatta/shringar offer... |
| Mehandipur Balaji Temple | `mehandipur-balaji-temple` | No photography or mobile use inside (official FAQ). No dress code beyond modest attire; free wheelchair via temple office. Temple does not provide priestly medical treatment — F... |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Brahma Temple

Seed slug: `brahma-temple`

Research payload id `brahma-temple-pushkar` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Pushkar. Deity label: `Brahma`. Map pin: 26.4872, 74.5542.

Sources:

- [Temple Profile — Mandir Shri Brahma Ji (Devasthan Dept, Rajasthan)](https://devasthan.rajasthan.gov.in/images/Ajmer/brahmaji.htm)
- [Brahma Temple, Pushkar — Wikipedia](https://en.wikipedia.org/wiki/Brahma_Temple,_Pushkar)
- [Brahma Temple — Rajasthan Tourism](https://www.tourism.rajasthan.gov.in/brahma-temple.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Brahma_Temple,_Pushkar.jpg — CC BY 2.0, vasant_photography (Flickr) / Wikimedia Commons. Exterior with red shikhara; verified Commons license page

Ritual overflow (not a Firestore field): Bathe or wash at the lake ghats before darshan if following local custom. Only ascetic priests enter the garbha griha — hand offerings through them. No photography in the inner sanctum. Expect extreme crowds on Kartik Purnima.

### Eklingji Temple

Seed slug: `eklingji-temple`

City: Kailashpuri (near Udaipur). Deity label: `Shiva`. Map pin: 24.746, 73.7222.

Sources:

- [Devasthan Department, Rajasthan (official)](https://devasthan.rajasthan.gov.in/)
- [Eklingji — Wikipedia](https://en.wikipedia.org/wiki/Eklingji)
- [Eklingji Temple visitor guide (Udaipur tourism compilation)](https://udaipurtourism.co.in/eklingji-temple-udaipur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Eklingji_(2002)_01.jpg — CC BY-SA 4.0, LBM1948. Eklingji temple complex exterior (2002); verified Commons license page

Ritual overflow (not a Firestore field): Thin official English day-board — label timings provisional. Expect closed intervals between darshan windows. Remove leather footwear/belts if required at gate; follow on-site photo rules.

### Shrinathji Temple

Seed slug: `shrinathji-temple`

Research payload id `shrinathji-temple-nathdwara` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Nathdwara. Deity label: `Vishnu`. Map pin: 24.929, 73.8151.

Sources:

- [Shrinathji Temple Nathdwara — Daily Darshan Timing (official)](https://www.nathdwaratemple.org/DarshanTiming/Index?key=1)
- [Shrinathji Temple Nathdwara (official home)](https://www.nathdwaratemple.org/Home/Index)
- [Temple Profile — Shri Srinathji (Devasthan Dept)](https://devasthan.rajasthan.gov.in/images/Rajsamand/srinathji.htm)
- [Shrinathji Temple — Wikipedia](https://en.wikipedia.org/wiki/Shrinathji_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Gateway_To_Temple,_Nathdwara.jpg — Public domain, Papertree at English Wikipedia. Temple gateway / approach at Nathdwara; interior photography restricted — exterior candidate

Ritual overflow (not a Firestore field): Arrive 20–30 minutes before a jhanki; queues move quickly once doors open. Phones/cameras usually not allowed inside the haveli. Festival and seasonal tippanis override the sample clock — use only the official daily page.

### Karni Mata Temple

Seed slug: `karni-mata-temple`

Research payload id `karni-mata-temple-deshnok` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Deshnok. Deity label: `Devi`. Map pin: 27.7906, 73.3408.

Sources:

- [Karni Mata Temple — Rajasthan Tourism (official)](https://www.tourism.rajasthan.gov.in/karni-mata-temple.html)
- [Temple Profile — Karni Mataji (Devasthan Dept)](https://devasthan.rajasthan.gov.in/images/Bikaner/KarniMataji.htm)
- [Karni Mata Temple — Wikipedia](https://en.wikipedia.org/wiki/Karni_Mata_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:20191212_%C5%9Awi%C4%85tynia_Karni_Maty_w_De%C5%9Bnok_1031_8078_DxO.jpg — CC BY-SA 4.0, Jakub Hałun. Temple exterior at Deshnok (2019); verified Commons license page

Ritual overflow (not a Firestore field): Walk carefully — kabbas have right of way. Do not harm rats; follow local custom if an accident occurs. Shoes off at the gate; keep food offerings for rats/prasad channels as directed. Photography policy varies — obey posted boards.

### Govind Dev Ji Temple

Seed slug: `govind-dev-ji-temple`

Research payload id `govind-dev-ji-temple-jaipur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Jaipur. Deity label: `Vishnu`. Map pin: 26.926, 75.8236.

Sources:

- [Shri Radha-Govind Devji — Darshan timetable (official)](https://govinddevji.net/JHAKIA.HTM)
- [Govind Dev Ji live darshan (official)](https://govinddevji.net/live.htm)
- [Govind Dev Ji Temple — Wikipedia](https://en.wikipedia.org/wiki/Govind_Dev_Ji_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Govind_Dev_Ji_Temple,_Jaipur,_20191218_1059_9091.jpg — CC BY-SA 4.0, Jakub Hałun. Temple exterior in City Palace precinct (2019); verified Commons license page

Ritual overflow (not a Firestore field): Midday closure is for seva — do not expect continuous afternoon darshan. Festival clocks shift; use the temple’s advance timetable page. Palace-area security may restrict large bags.

### Birla Mandir (Lakshmi Narayan Temple)

Seed slug: `birla-mandir-lakshmi-narayan-temple`

Research payload id `birla-mandir-jaipur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Jaipur. Deity label: `Vishnu`. Map pin: 26.8922, 75.8155.

Sources:

- [Birla Mandir Jaipur visitor guide (Jaipur tourism compilation)](https://jaipurtourism.co.in/laxmi-narayan-temple-birla-mandir-jaipur)
- [Birla Mandir, Jaipur — Wikipedia](https://en.wikipedia.org/wiki/Birla_Mandir,_Jaipur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Birla_Mandir_Jaipur_(2022-07).jpg — CC BY-SA 4.0, Chainwit.. Marble exterior (July 2022); verified Commons license page

Ritual overflow (not a Firestore field): Thin official English clock — timings labelled provisional from tourism boards. Afternoon closure is standard on most listings. Decent dress; keep voice low in the marble halls.

### Dilwara Temples

Seed slug: `dilwara-temples`

Research payload id `dilwara-temples-mount-abu` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mount Abu. Deity label: `Jain Tirthankaras`. Map pin: 24.6093, 72.7231.

Sources:

- [Dilwara Jain Temples — Incredible India](https://www.incredibleindia.gov.in/en/rajasthan/mount-abu/dilwara-jain-temples)
- [Dilwara Temples — Wikipedia](https://en.wikipedia.org/wiki/Dilwara_Temples)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Dilwara_Temple_-_Luna_Vasahi.jpg — CC BY-SA 4.0, Akshat patni. Luna Vasahi marble interior detail; verified Commons license page — respect no-photo rules on site when visiting

Ritual overflow (not a Firestore field): NOTE: Dilwara is a Jain pilgrimage complex, not a Hindu temple — included as an iconic Rajasthan sacred site in this temple directory. Morning hours prioritize Jain worship; tourists usually afternoon only. Strict ban on leather, phones, and cameras; dress modestly. No Hindu aarti schedule applies.

### Salasar Balaji

Seed slug: `salasar-balaji`

Research payload id `salasar-balaji-temple` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Salasar. Deity label: `Hanuman`. Map pin: 27.7258, 74.7243.

Sources:

- [Shree Salasar Balaji Mandir — Temple timing page](https://shreesalasarbalajimandir.com/temple-timing-2/)
- [Shree Salasar Balaji Mandir (home)](https://shreesalasarbalajimandir.com/)
- [Salasar Balaji Temple — Wikipedia](https://en.wikipedia.org/wiki/Salasar_Balaji_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Salasar_balaji_02.jpg — CC BY-SA 4.0, Dausaanoop. Temple / complex view; verified Commons license page

Ritual overflow (not a Firestore field): Thin / conflicting official English clocks across sites claiming authority — timings labelled provisional. Prefer the physical notice board at Salasar Dham. Expect heavy security and long queues on fair Purnimas.

### Khatushyam Temple

Seed slug: `khatushyam-temple`

City: Khatu. Deity label: `Vishnu`. Map pin: 27.3644, 75.4036.

Sources:

- [Shri Shyam Mandir committee site (Khatu)](https://www.shrishyammandir.com/)
- [Khatu Shyam aarti timings (seasonal compilation)](https://www.khatu.in/en/aarti-timings)
- [Khatu Shyam Temple — Wikipedia](https://en.wikipedia.org/wiki/Khatu_Shyam_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Khatu_Shyam_Ji_-_panoramio.jpg — CC BY-SA 3.0, Indrapal Jangid. Temple complex exterior view; verified Commons license page

Ritual overflow (not a Firestore field): Official English continuous darshan clock is thin — prefer temple-committee notices and Hindi boards on site. Phalguna Mela requires advance stay booking. Dupatta/shringar offerings are popular; follow queue discipline.

### Mehandipur Balaji Temple

Seed slug: `mehandipur-balaji-temple`

City: Mehandipur (Dausa). Deity label: `Hanuman`. Map pin: 26.9483, 76.794.

Sources:

- [Mehandipur Balaji Temple — FAQs (official)](https://shribalajimehandipur.org/faqs/)
- [Mehandipur Balaji Temple (official home)](https://shribalajimehandipur.org/)
- [Mehandipur Balaji Temple — Wikipedia](https://en.wikipedia.org/wiki/Mehandipur_Balaji_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mehandipur_Balaji_idol.jpg — Public domain, Wikimedia Commons uploader (see file page). Historic/illustrative idol image on Commons (PD); interior photography prohibited on site — prefer exterior shots for CMS if a better Commons exterior appears

Ritual overflow (not a Firestore field): No photography or mobile use inside (official FAQ). No dress code beyond modest attire; free wheelchair via temple office. Temple does not provide priestly medical treatment — FAQ asks devotees to rely on devout darshan. Book sawamani in advance; cancellations not accepted per FAQ.
