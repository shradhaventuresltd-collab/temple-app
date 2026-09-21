# Odisha sample expansion (batch 7)

Research-backed copy for **10 new Odisha temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer SJTA, ASI/UNESCO, and temple boards over tourist aggregators. Re-check SJTA visitor-services (Puri entry, dress, and phone rules), Lingaraj entry rules, Konark ASI/UNESCO sunrise–sunset tickets, Rajarani’s empty sanctum, Tara Tarini and Biraja Shakti Peetha hours.

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

Puri and Lingaraj keep Hindus-only / dress / phone notes inside story or timings where the research payload put them. Konark is ticketed heritage without a living garbha cult. Rajarani is an ASI monument with an empty sanctum. Sakshi Gopal and Cuttack Chandi full pooja clocks are thin and labelled provisional.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Jagannath Temple | `jagannath-temple` | ENTRY / DRESS (free-text only — no new schema fields): Inner temple traditionally open to Hindus only; non-Hindus view from outside. Modest clothing expected (SJTA has discourag... Research payload id `jagannath-temple-puri` is not the seed id. |
| Lingaraj Temple | `lingaraj-temple` | Hindus-only inner compound (strictly enforced); non-Hindus use northern raised platform. No phones/cameras inside. Modest dress; head covering for women often expected near sanc... |
| Konark Sun Temple | `konark-sun-temple` | ASI/UNESCO ticketed heritage site — no living garbha-griha cult comparable to active Odisha temples. Follow monument rules (no offerings on carved surfaces). Pair museum hours s... |
| Mukteshwar Temple | `mukteshwar-temple` | Small active shrine + heritage monument. Photo rules can be stricter near sanctum — follow board. Pair with nearby Rajarani and Siddheshvara on an Old Town walk. |
| Rajarani Temple | `rajarani-temple` | IMPORTANT: Often no living cult image in the sanctum — visit as ASI heritage architecture, not for routine deity darshan. Ticketed entry; landscaped grounds popular for photogra... |
| Ananta Vasudeva Temple | `ananta-vasudeva-temple` | Active living Vaishnava temple; pair Bindusagar circumambulation with Lingaraj visit. Timings vary slightly by source (7 PM vs 8 PM close) — prefer on-site board. |
| Sakshi Gopal Temple | `sakshi-gopal-temple` | THIN OFFICIAL CLOCK: rely on secondary guides + on-site board. Anla Navami is the peak festival — arrive very early. Highway stop; combine with Puri day trip. |
| Maa Taratarini Temple | `maa-taratarini-temple` | Hill shrine — allow time for ropeway queues or climb. Festival densification in Chaitra. Official portal: taratarini.nic.in; English timing detail partly secondary. |
| Cuttack Chandi Temple | `cuttack-chandi-temple` | THIN SOURCES on full named daily niti in English. Festival (Durga Puja) is the defining visit window — expect heavy queues. Modest dress; follow local queue discipline. |
| Biraja Temple | `biraja-temple` | Major Shakta + pitri centre. Use official maabiraja.com for timetable; secondary clocks differ slightly on evening close (9 vs 10 PM). Animal sacrifice traditions on certain Ash... |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Jagannath Temple

Seed slug: `jagannath-temple`

Research payload id `jagannath-temple-puri` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Puri. Deity label: `Vishnu`. Map pin: 19.8047, 85.8183.

Sources:

- [Shree Jagannatha Temple Administration — official](https://shreejagannatha.in/)
- [SJTA — Visitor services / darshan windows](https://www.shreejagannatha.in/visitor-services/)
- [Jagannath Temple, Puri — Wikipedia](https://en.wikipedia.org/wiki/Jagannath_Temple,_Puri)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Jagannath_Temple,_Puri.jpg — CC BY-SA 3.0, Amartyabag. Temple exterior / skyline; verified Commons license page
- https://commons.wikimedia.org/wiki/File:Jagannath_Temple,_Puri_04.jpg — CC BY-SA 3.0, Bernard Gagnon. Additional exterior view; verified Commons

Ritual overflow (not a Firestore field): ENTRY / DRESS (free-text only — no new schema fields): Inner temple traditionally open to Hindus only; non-Hindus view from outside. Modest clothing expected (SJTA has discouraged shorts, torn jeans, transparent/revealing wear — prefer dhoti/kurta or trousers & shirt for men; saree/salwar for women). Deposit phones, cameras, smartwatches, leather belts/wallets/bags, umbrellas and footwear at Lion’s Gate cloakrooms. Singhadwara is the main pilgrim entry; other gates usually exit. No official paid VIP darshan — ignore third-party ticket sellers. Confirm day’s niti and Parikrama/corridor notices on shreejagannatha.in.

### Lingaraj Temple

Seed slug: `lingaraj-temple`

City: Bhubaneswar. Deity label: `Shiva`. Map pin: 20.2383, 85.8336.

Sources:

- [Lingaraja Temple — Wikipedia](https://en.wikipedia.org/wiki/Lingaraja_Temple)
- [Mukteswara Temple — Incredible India (Ekamra cluster context)](https://www.incredibleindia.gov.in/en/odisha/bhubaneswar/mukteswara-temple)
- [Odisha Tourism (official portal)](https://odishatourism.gov.in/content/tourism/en.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Lingaraj_temple_Bhubaneswar.jpg — CC BY-SA 4.0, Pattnaik.chandan. Vimana exterior; verified Commons
- https://commons.wikimedia.org/wiki/File:Lingaraj_Temple,_Bhubaneswar,_Odisha_2.jpg — CC BY-SA 4.0, Athulvis. Alternate exterior angle; verified Commons

Ritual overflow (not a Firestore field): Hindus-only inner compound (strictly enforced); non-Hindus use northern raised platform. No phones/cameras inside. Modest dress; head covering for women often expected near sanctum. Timings shift on Shivaratri and Ratha days — verify locally.

### Konark Sun Temple

Seed slug: `konark-sun-temple`

City: Konark. Deity label: `Surya`. Map pin: 19.8874, 86.0946.

Sources:

- [Sun Temple, Konârak — UNESCO WHC](https://whc.unesco.org/en/list/246/)
- [ASI — World Heritage Konarak](https://asi.nic.in/pages/WorldHeritageKonarak)
- [Konark Sun Temple — Wikipedia](https://en.wikipedia.org/wiki/Konark_Sun_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:KONARK_Sun_Temple.jpg — CC BY-SA 4.0, Arpan Mahajan. Main structure view; verified Commons
- https://commons.wikimedia.org/wiki/File:Sun_Temple_Main_Structure,_Konark,_Orissa.jpg — CC BY-SA 4.0, Subhrajyoti07. Alternate main-structure shot; verified Commons

Ritual overflow (not a Firestore field): ASI/UNESCO ticketed heritage site — no living garbha-griha cult comparable to active Odisha temples. Follow monument rules (no offerings on carved surfaces). Pair museum hours separately; Fridays museum often closed.

### Mukteshwar Temple

Seed slug: `mukteshwar-temple`

City: Bhubaneswar. Deity label: `Shiva`. Map pin: 20.2427, 85.8404.

Sources:

- [Mukteswara Temple — Incredible India](https://www.incredibleindia.gov.in/en/odisha/bhubaneswar/mukteswara-temple)
- [Mukteshvara Temple, Bhubaneswar — Wikipedia](https://en.wikipedia.org/wiki/Mukteshvara_Temple,_Bhubaneswar)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mukteshvara_Temple,_Bhubaneswar.jpg — CC BY-SA 3.0, Bernard Gagnon. Temple / torana context; verified Commons
- https://commons.wikimedia.org/wiki/File:Torana_of_the_Mukteshvara_Temple,_Bhubaneswar_03.jpg — CC BY-SA 4.0, Kritzolina. Detail of signature torana; verified Commons

Ritual overflow (not a Firestore field): Small active shrine + heritage monument. Photo rules can be stricter near sanctum — follow board. Pair with nearby Rajarani and Siddheshvara on an Old Town walk.

### Rajarani Temple

Seed slug: `rajarani-temple`

City: Bhubaneswar. Deity label: `Shiva`. Map pin: 20.2434, 85.8435.

Sources:

- [Rajarani Temple — Wikipedia](https://en.wikipedia.org/wiki/Rajarani_Temple)
- [Rajarani Temple visitor page — Bhubaneswar Tourism](https://bhubaneswartourism.in/raja-rani-temple-bhubaneswar)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Rajarani_Temple.jpg — CC BY-SA 3.0, Amartyabag. Exterior vimana; verified Commons
- https://commons.wikimedia.org/wiki/File:Rajarani_Temple_01.jpg — CC BY-SA 3.0, Bernard Gagnon. Alternate exterior; verified Commons

Ritual overflow (not a Firestore field): IMPORTANT: Often no living cult image in the sanctum — visit as ASI heritage architecture, not for routine deity darshan. Ticketed entry; landscaped grounds popular for photography (follow ASI rules). Shaivite attribution is art-historical, not an active daily niti programme.

### Ananta Vasudeva Temple

Seed slug: `ananta-vasudeva-temple`

City: Bhubaneswar. Deity label: `Vishnu`. Map pin: 20.2406, 85.8358.

Sources:

- [Ananta-Vasudeva Temple — Incredible India](https://www.incredibleindia.gov.in/en/odisha/bhubaneswar/ananta-vasudeva-temple)
- [Ananta Vasudeva Temple — Wikipedia](https://en.wikipedia.org/wiki/Ananta_Vasudeva_Temple)
- [Ananta Vasudeva visitor page — Bhubaneswar Tourism](https://bhubaneswartourism.in/ananta-vasudeva-temple-bhubaneswar)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ananta_Vasudeva_Temple.jpg — CC BY 3.0, Nayansatya. Temple exterior; verified Commons
- https://commons.wikimedia.org/wiki/File:Court_of_Ananta_Vasudeva_Temple_01.jpg — CC BY-SA 4.0, Kritzolina. Court / precinct view; verified Commons

Ritual overflow (not a Firestore field): Active living Vaishnava temple; pair Bindusagar circumambulation with Lingaraj visit. Timings vary slightly by source (7 PM vs 8 PM close) — prefer on-site board.

### Sakshi Gopal Temple

Seed slug: `sakshi-gopal-temple`

City: Sakshigopal. Deity label: `Vishnu`. Map pin: 19.9357, 85.8298.

Sources:

- [Sakhigopal Temple — Wikipedia](https://en.wikipedia.org/wiki/Sakhigopal_Temple)
- [Sakshi Gopal Temple visitor page — Bhubaneswar Tourism](https://bhubaneswartourism.in/sakshi-gopal-temple-puri)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sakshigopal_Temple.jpg — CC BY-SA 4.0, Sidsahu. Temple exterior; verified Commons

Ritual overflow (not a Firestore field): THIN OFFICIAL CLOCK: rely on secondary guides + on-site board. Anla Navami is the peak festival — arrive very early. Highway stop; combine with Puri day trip.

### Maa Taratarini Temple

Seed slug: `maa-taratarini-temple`

City: Purushottapur. Deity label: `Devi`. Map pin: 19.4897, 84.8998.

Sources:

- [Tara Tarini Development Board — official](https://taratarini.nic.in/)
- [Tara Tarini Temple — Wikipedia](https://en.wikipedia.org/wiki/Tara_Tarini_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Taratarini_Temple,_Odisha.jpg — CC BY-SA 3.0, Nibedit. Temple on hill; verified Commons
- https://commons.wikimedia.org/wiki/File:Taratarini_Lower_Gate.jpg — CC BY-SA 3.0, SANTOSH.NAHAK12. Lower gate approach; verified Commons

Ritual overflow (not a Firestore field): Hill shrine — allow time for ropeway queues or climb. Festival densification in Chaitra. Official portal: taratarini.nic.in; English timing detail partly secondary.

### Cuttack Chandi Temple

Seed slug: `cuttack-chandi-temple`

City: Cuttack. Deity label: `Devi`. Map pin: 20.4772, 85.8626.

Sources:

- [Cuttack Chandi Temple — Wikipedia](https://en.wikipedia.org/wiki/Cuttack_Chandi_Temple)
- [Cuttack Chandi overview — Explore Our India](https://www.exploreourindia.com/cuttack-chandi-temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Katak_Chandi_temple.jpg — CC BY-SA 3.0, Sidsahu. Temple exterior; verified Commons

Ritual overflow (not a Firestore field): THIN SOURCES on full named daily niti in English. Festival (Durga Puja) is the defining visit window — expect heavy queues. Modest dress; follow local queue discipline.

### Biraja Temple

Seed slug: `biraja-temple`

City: Jajpur. Deity label: `Devi`. Map pin: 20.8338, 86.3381.

Sources:

- [Maa Biraja — official temple site](https://maabiraja.com/)
- [Biraja Temple — Wikipedia](https://en.wikipedia.org/wiki/Biraja_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Maa_Biraja_Temple.jpg — CC BY-SA 3.0, Krupasindhu Muduli. Temple view; verified Commons
- https://commons.wikimedia.org/wiki/File:Biraja_Temple,_Jajpur,_Odisha,_India,_13th_century.jpg — CC BY-SA 3.0, Odisha1. Historic fabric view; verified Commons

Ritual overflow (not a Firestore field): Major Shakta + pitri centre. Use official maabiraja.com for timetable; secondary clocks differ slightly on evening close (9 vs 10 PM). Animal sacrifice traditions on certain Ashtami–Navami rites — pilgrims should inquire if relevant to their practice.
