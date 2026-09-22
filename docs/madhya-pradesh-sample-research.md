# Madhya Pradesh sample expansion (batch 13)

Research-backed copy for **10 new Madhya Pradesh temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer the Mahakaleshwar seasonal aarti board and Bhasma Aarti booking rules, the Omkareshwar Trust schedule, and ASI sunrise–sunset ticketing for Khajuraho. Re-check Ram Raja’s Hindu-calendar routine, Pashupatinath’s 20:00 versus 22:00 closing conflict, Sharda ropeway weather, and thin clocks for Harsiddhi, Chintaman Ganesh, Matangeshwar, and Sharda.

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

Mahakaleshwar and Omkareshwar keep official seasonal or daily boards. Kandariya Mahadeva and Lakshmana are ASI/UNESCO monuments with sunrise–sunset visitor hours, not living pooja schedules. Matangeshwar is the worshipped Khajuraho exception with a thin official English clock. Pashupatinath government listings conflict on a 20:00 versus 22:00 close. Harsiddhi, Chintaman Ganesh, and Sharda clocks are thin or provisional; Sharda ropeway access is weather-dependent. Ram Raja’s schedule changes by Hindu-calendar season.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Mahakaleshwar Temple | `mahakaleshwar-temple` | Bhasma Aarti is capacity-controlled and must be booked through shrimahakaleshwar.mp.gov.in; follow the booked reporting time, dress/ID rules and current prohibited-item notices.... |
| Omkareshwar Temple | `omkareshwar-temple` | Normal darshan does not require booking; optional Shighra Darshan is valid only for its booked slot. Garbhagriha offering restrictions can change, including bilva leaves, flower... |
| Kandariya Mahadeva Temple | `kandariya-mahadeva-temple` | Treat as an archaeological monument: use visitor hours only, respect barriers, and do not promise abhishek, aarti or sanctum worship. Matangeshwar nearby is the actively worship... |
| Lakshmana Temple | `lakshmana-temple` | Use ASI monument rules and current ticketing. Do not promise daily aarti, offerings or active-sanctum access; describe the deity and iconography historically. Research payload id `lakshmana-temple-khajuraho` is not the seed id. |
| Matangeshwar Temple | `matangeshwar-temple` | Thin official clock: treat 6:00 AM–6:00 PM as provisional and check locally. Remove footwear, dress modestly and follow priest/temple rules for offerings and photography. Do not... |
| Harsiddhi Temple | `harsiddhi-temple` | Thin/variable official clock: verify closing and lamp-lighting at the temple. Sponsoring full deepstambha lighting may require advance local arrangements. Arrive early during Na... Research payload id `harsiddhi-temple-ujjain` is not the seed id. |
| Chintaman Ganesh Temple | `chintaman-ganesh-temple` | Thin official ritual clock: confirm at the temple and do not guarantee secondary aarti minutes in booking flows. Wednesdays and Chaturthi need extra queue time; follow local rul... |
| Pashupatinath Temple | `pashupatinath-temple` | Official-source closing times conflict (8:00 PM versus 10:00 PM); confirm locally. Riverfront surfaces can be slippery in monsoon. Festival crowds may restrict close sanctum acc... Research payload id `pashupatinath-temple-mandsaur` is not the seed id. |
| Sharda Devi Temple Maihar | `sharda-devi-temple-maihar` | Official district and Ministry sources are stronger for site/access than for a detailed aarti board. Check same-day ropeway status, especially in high wind, rain or maintenance.... |
| Ram Raja Temple | `ram-raja-temple` | Do not use a continuous sunrise-to-sunset promise: the temple closes between Rajbhog and evening worship. Hindu-calendar transition dates vary (around 15 days before Holi/Diwali... Research payload id `ram-raja-temple-orchha` is not the seed id. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Mahakaleshwar Temple

Seed slug: `mahakaleshwar-temple`

City: Ujjain. Deity label: `Shiva`. Map pin: 23.18278, 75.76833.

Sources:

- [Shri Mahakaleshwar Jyotirlinga — Temple Timings (official)](https://www.shrimahakaleshwar.mp.gov.in/timing)
- [Shri Mahakaleshwar Jyotirlinga (official)](https://www.shrimahakaleshwar.mp.gov.in/)
- [Mahakaleshwar Temple — Incredible India](https://www.incredibleindia.gov.in/en/madhya-pradesh/ujjain/mahakaleshwar-temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mahakaleshwar_Temple,_Ujjain.jpg — CC BY-SA 4.0, Ashverse. Night exterior of temple; verified Commons license page
- https://commons.wikimedia.org/wiki/File:Shri_mahakaleshwar_jyotirlinga_temple_Ujjain_01.jpg — CC BY-SA 4.0, Anchal lilhare. Vertical temple exterior; verified Commons license page

Ritual overflow (not a Firestore field): Bhasma Aarti is capacity-controlled and must be booked through shrimahakaleshwar.mp.gov.in; follow the booked reporting time, dress/ID rules and current prohibited-item notices. Shravan and Mahashivaratri schedules can differ sharply from the ordinary board.

### Omkareshwar Temple

Seed slug: `omkareshwar-temple`

City: Omkareshwar. Deity label: `Shiva`. Map pin: 22.245583, 76.151056.

Sources:

- [Shri Omkareshwar Jyotirlinga — Daily Schedule (official)](https://shriomkareshwar.org/Schedules.aspx)
- [Shri Omkareshwar Jyotirlinga — Main Temple (official)](https://www.shriomkareshwar.org/MainTemple.aspx)
- [Omkareshwar Temple — Wikipedia](https://en.wikipedia.org/wiki/Omkareshwar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:0102621_Omkareswar_Jyothirlinga_temple,_Mandhata_Madhya_Pradesh_011.jpg — CC0 1.0, Ms Sarah Welch. Temple exterior at active pilgrimage site; verified Commons public-domain dedication

Ritual overflow (not a Firestore field): Normal darshan does not require booking; optional Shighra Darshan is valid only for its booked slot. Garbhagriha offering restrictions can change, including bilva leaves, flowers or coconuts; follow Trust notices.

### Kandariya Mahadeva Temple

Seed slug: `kandariya-mahadeva-temple`

City: Khajuraho. Deity label: `Shiva`. Map pin: 24.853, 79.9197.

Sources:

- [ASI — Group of Temples, Khajuraho](https://asi.nic.in/pages/WorldHeritageKhajuraho)
- [UNESCO World Heritage Centre — Khajuraho Group of Monuments](https://whc.unesco.org/en/list/240/)
- [Khajuraho — Incredible India](https://www.incredibleindia.gov.in/en/madhya-pradesh/khajuraho)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:The_Kandariya_Mahadeva_Temple,_Khajuraho,_Madhya_Pradesh.jpg — CC BY-SA 4.0, Taru23. South-side/evening exterior; ASI monument N-MP-15; verified Commons license page

Ritual overflow (not a Firestore field): Treat as an archaeological monument: use visitor hours only, respect barriers, and do not promise abhishek, aarti or sanctum worship. Matangeshwar nearby is the actively worshipped Khajuraho Shiva temple.

### Lakshmana Temple

Seed slug: `lakshmana-temple`

Research payload id `lakshmana-temple-khajuraho` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Khajuraho. Deity label: `Vishnu`. Map pin: 24.852139, 79.921694.

Sources:

- [ASI — Group of Temples, Khajuraho](https://asi.nic.in/pages/WorldHeritageKhajuraho)
- [UNESCO World Heritage Centre — Khajuraho Group of Monuments](https://whc.unesco.org/en/list/240/)
- [Lakshmana Temple, Khajuraho — Wikipedia](https://en.wikipedia.org/wiki/Lakshmana_Temple,_Khajuraho)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Khajuraho_-_Lakshmana_temple.jpg — CC BY 3.0 Poland, Radosław Botev / Fundacja Nomos. Temple exterior; verified Commons license and attribution page

Ritual overflow (not a Firestore field): Use ASI monument rules and current ticketing. Do not promise daily aarti, offerings or active-sanctum access; describe the deity and iconography historically.

### Matangeshwar Temple

Seed slug: `matangeshwar-temple`

City: Khajuraho. Deity label: `Shiva`. Map pin: 24.852092, 79.922244.

Sources:

- [UNESCO World Heritage Centre — Khajuraho Group of Monuments](https://whc.unesco.org/en/list/240/)
- [ASI — Group of Temples, Khajuraho](https://asi.nic.in/pages/WorldHeritageKhajuraho)
- [Matangeshvara Temple, Khajuraho — Wikipedia](https://en.wikipedia.org/wiki/Matangeshvara_Temple,_Khajuraho)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:0121821_Matangeshwar_Mahadev_Temple,_Khajuraho_Madhya_Pradesh_036.jpg — CC0 1.0, Ms Sarah Welch. Large Shiva linga and sanctum ceiling; verified Commons public-domain dedication

Ritual overflow (not a Firestore field): Thin official clock: treat 6:00 AM–6:00 PM as provisional and check locally. Remove footwear, dress modestly and follow priest/temple rules for offerings and photography. Do not apply the Western Group ticket assumptions to this living shrine.

### Harsiddhi Temple

Seed slug: `harsiddhi-temple`

Research payload id `harsiddhi-temple-ujjain` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Ujjain. Deity label: `Devi`. Map pin: 23.184478, 75.764581.

Sources:

- [Shri Mahakaleshwar official site — Other Religious Places in Ujjain](https://www.shrimahakaleshwar.mp.gov.in/)
- [District Ujjain — Places of Interest](https://ujjain.nic.in/en/places-of-interest/)
- [Harsidhhi — Wikipedia](https://en.wikipedia.org/wiki/Harsidhhi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Harsiddhi_Temple,_Ujjain_01.jpg — CC BY-SA 3.0 / GFDL 1.2+, Bernard Gagnon. Temple and deepstambhas; verified Commons multi-license page

Ritual overflow (not a Firestore field): Thin/variable official clock: verify closing and lamp-lighting at the temple. Sponsoring full deepstambha lighting may require advance local arrangements. Arrive early during Navaratri and keep clear of hot lamps and service paths.

### Chintaman Ganesh Temple

Seed slug: `chintaman-ganesh-temple`

City: Ujjain. Deity label: `Ganesha`. Map pin: 23.1467, 75.7391.

Sources:

- [Chintaman Ganesh — Incredible India](https://prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/ujjain/chintaman-ganesh.html)
- [Chintaman Ganeshji — District Ujjain](https://ujjain.nic.in/en/gallery/chintaman-ganeshji/)
- [Chintaman Ganesh Temple, Ujjain — Wikipedia](https://en.wikipedia.org/wiki/Chintaman_Ganesh_Temple,_Ujjain)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Chintamann_Ganesh_Temple_Ujjain_-_panoramio.jpg — CC BY 3.0, Gyanendra Singh Chau…. Temple exterior; Panoramio image license verified by Commons bot

Ritual overflow (not a Firestore field): Thin official ritual clock: confirm at the temple and do not guarantee secondary aarti minutes in booking flows. Wednesdays and Chaturthi need extra queue time; follow local rules for offerings and photography.

### Pashupatinath Temple

Seed slug: `pashupatinath-temple`

Research payload id `pashupatinath-temple-mandsaur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mandsaur. Deity label: `Shiva`. Map pin: 24.05472, 75.072917.

Sources:

- [Ministry of Tourism Utsav — Shri Pashupatinath Temple](https://utsav.gov.in/public/view-darshan/shri-pashupatinath-temple-1)
- [Pashupatinath Temple — Madhya Pradesh Tourism](https://www.madhya-pradesh-tourism.com/destination/Pashupatinath-Temple-144)
- [Pashupatinath Temple, Mandsaur — Wikipedia](https://en.wikipedia.org/wiki/Pashupatinath_Temple,_Mandsaur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Pashupatinath_Temple_Mandsaur.jpg — CC BY-SA 4.0, Rohit MDS. Temple exterior at night; verified Commons license page

Ritual overflow (not a Firestore field): Official-source closing times conflict (8:00 PM versus 10:00 PM); confirm locally. Riverfront surfaces can be slippery in monsoon. Festival crowds may restrict close sanctum access and offerings.

### Sharda Devi Temple Maihar

Seed slug: `sharda-devi-temple-maihar`

City: Maihar. Deity label: `Devi`. Map pin: 24.26123, 80.72307.

Sources:

- [Maa Sharda Mata — District Maihar, Government of Madhya Pradesh](https://maihar.nic.in/en/tourist-place/maa-sharda-mata/)
- [Ministry of Tourism Utsav — Maa Sharda Temple Live Darshan](https://utsav.gov.in/view-darshan/maa-sharda-temple-live-darshan)
- [Maa Sharda Mandir, Maihar — Wikipedia](https://en.wikipedia.org/wiki/Maa_Sharda_Mandir,_Maihar)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Maa_Sharda_Temple,_Maihar.jpg — CC0 1.0, RishiAgrahari95. Temple during Chaitra Navratri 2024; verified Commons public-domain dedication
- https://commons.wikimedia.org/wiki/File:Sharada_Temple_Maihar.JPG — CC BY-SA 3.0 / GFDL, LRBurdak. Back-side exterior view; verified Commons license page

Ritual overflow (not a Firestore field): Official district and Ministry sources are stronger for site/access than for a detailed aarti board. Check same-day ropeway status, especially in high wind, rain or maintenance. The stair ascent is strenuous; carry water and allow substantial Navaratri queue time.

### Ram Raja Temple

Seed slug: `ram-raja-temple`

Research payload id `ram-raja-temple-orchha` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Orchha. Deity label: `Vishnu/Rama`. Map pin: 25.350875, 78.639274.

Sources:

- [Ram Raja Temple — Daily Event / official schedule](https://ramrajatemple.mp.gov.in/)
- [Ram Raja Mandir — Incredible India](https://www.incredibleindia.gov.in/en/madhya-pradesh/orchha/ram-raja-mandir)
- [Ram Raja Temple — Wikipedia](https://en.wikipedia.org/wiki/Ram_Raja_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ram_Raja_Temple,_Orchha,_Madhya_Pradesh,_India.jpg — CC BY-SA 4.0, PRATYUSHMAURYA.ECOHUMAN. Temple exterior; verified Commons license page
- https://commons.wikimedia.org/wiki/File:Ram_raja_temple,_Orchha.jpg — CC BY-SA 4.0, Sudhanshusahu. Vertical temple view; verified Commons license page

Ritual overflow (not a Firestore field): Do not use a continuous sunrise-to-sunset promise: the temple closes between Rajbhog and evening worship. Hindu-calendar transition dates vary (around 15 days before Holi/Diwali), so verify the active season on the official site. Security and photography rules can tighten during guard-of-honour and festivals.
