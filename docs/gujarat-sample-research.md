# Gujarat sample expansion (batch 6)

Research-backed copy for **10 new Gujarat temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Somnath Trust, Dwarkadhish, Ranchhodraiji, Ambaji, and ASI pages over tourist aggregators. Re-check Somnath Trust FAQ, Dwarkadhish.org and Ranchhodraiji.org named bhog clocks, the Ambaji daily board, Pavagadh trust versus Incredible India hours, Modhera ASI tickets, and Akshardham Monday closure.

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

Modhera is an ASI ticketed sun temple with no living pooja. Akshardham Gandhinagar is closed Mondays. Bahucharaji, Nageshwar, and Chotila clocks are thinner — provisional wording is kept in timings. Pavagadh trust hours and Incredible India hours conflict in the timings text.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Somnath Temple | `somnath-temple` | Gadgets strictly prohibited in temple premises per Trust FAQ; photography banned inside — souvenir counter sells official images. Havan/yagna shala booking via Trust management. |
| Dwarkadhish Temple | `dwarkadhish-temple` | Detailed minute-by-minute bhog slots circulate on secondary guides; prefer the official site’s day’s programme over blogs. Dress modestly; expect security screening. |
| Ambaji Temple | `ambaji-temple` | Mobiles/cameras prohibited inside; lockers at gates. Light & sound at Gabbar temporarily on hold (trust notice Sep 2026 research pass) — verify before visit. |
| Kalika Mata Temple | `kalika-mata-temple` | Trust vs Incredible India opening times differ by ~1 hour at open/close — CMS should prefer trust board + on-site notice. Pair visit with UNESCO Champaner monuments (ASI tickets... Research payload id `kalika-mata-temple-pavagadh` is not the seed id. |
| Modhera Sun Temple | `modhera-sun-temple` | Not a living seva temple — do not invent aarti slots. CMS should label clearly as ASI heritage / ticketed. Photography usually allowed in outer complex subject to ASI rules. |
| Bahucharaji Temple | `bahucharaji-temple` | Official full pooja timetable is thin compared with Trust sites for Ambaji/Somnath — keep CMS timings provisional and labelled. City spelling: Becharaji / Bahucharaji both used. |
| Ranchhodraiji Temple | `ranchhodraiji-temple` | Donate only via official website or temple counters (trust anti-fraud notice). Live stream available on ranchhodraiji.org. Research payload id `ranchhodraiji-temple-dakor` is not the seed id. |
| Nageshwar Jyotirlinga Temple | `nageshwar-jyotirlinga-temple` | Official full named-pooja documentation thinner than Somnath/Dwarka — keep CMS timings provisional. Coordinates approx. near Dwarka hinterland. |
| Akshardham Temple | `akshardham-temple` | Deity string set to Swaminarayan (accurate to BAPS complex). Not a classical Agama Jyotirlinga/Shakti temple — experiential campus with arti at mandir. Mobiles/cameras/food rest... Research payload id `akshardham-temple-gandhinagar` is not the seed id. |
| Chotila Chamunda Mata Temple | `chotila-chamunda-mata-temple` | Prefer on-site boards for aarti; festival access to steps may be regulated. Funicular/ropeway status changes — do not promise operational rides without fresh confirmation. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Somnath Temple

Seed slug: `somnath-temple`

City: Somnath. Deity label: `Shiva`. Map pin: 20.8878, 70.4014.

Sources:

- [Shree Somnath Trust — FAQ (official darshan & aarti)](https://somnath.org/faq/)
- [Somnath Temple — Wikipedia](https://en.wikipedia.org/wiki/Somnath_temple)
- [Shree Somnath Trust (home)](https://somnath.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Shree_Somnath_Temple.jpg — GODL-India, Prime Minister's Office. Official-looking exterior; GODL-India verified Commons Sep 2026
- https://commons.wikimedia.org/wiki/File:Somnath_temple_Gujarat_India.jpg — CC BY-SA 4.0, Narendralohiya. Sea-facing Somnath elevation; verified Commons license Sep 2026

Ritual overflow (not a Firestore field): Gadgets strictly prohibited in temple premises per Trust FAQ; photography banned inside — souvenir counter sells official images. Havan/yagna shala booking via Trust management.

### Dwarkadhish Temple

Seed slug: `dwarkadhish-temple`

City: Dwarka. Deity label: `Vishnu`. Map pin: 22.2378, 68.9675.

Sources:

- [Dwarkadhish Temple Live Darshan — Utsav (MoT)](https://utsav.gov.in/view-darshan/dwarkadhish-temple-live-darshan-1)
- [Shree Dwarkadhish Temple (official)](https://www.dwarkadhish.org/)
- [Dwarakadheesh Temple — Wikipedia](https://en.wikipedia.org/wiki/Dwarakadheesh_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:N-GJ-126_Dwarkadhish_Temple,_Dwarka_Temple_Tower_Closeup.jpg — CC BY-SA 4.0, MADHURANTHAKAN JAGADEESAN. Temple tower close-up; verified Commons license
- https://commons.wikimedia.org/wiki/File:Dwarkadheesh_temple.jpg — CC BY-SA 3.0, Scalebelow. Exterior; CC BY-SA 3.0 from Commons search API Sep 2026 (detail fetch rate-limited)

Ritual overflow (not a Firestore field): Detailed minute-by-minute bhog slots circulate on secondary guides; prefer the official site’s day’s programme over blogs. Dress modestly; expect security screening.

### Ambaji Temple

Seed slug: `ambaji-temple`

City: Ambaji. Deity label: `Devi`. Map pin: 24.3357, 72.8497.

Sources:

- [Ambaji Temple Trust (official — daily darshan board)](https://ambajitemple.in/)
- [Ambaji — Wikipedia](https://en.wikipedia.org/wiki/Ambaji)
- [Ambaji Mata Temple — Wikipedia](https://en.wikipedia.org/wiki/Ambaji_Mata_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ambaji_Temple_at_Night.jpg — CC BY-SA 3.0, Viral A dave. Night view of Ambaji temple; verified Commons license

Ritual overflow (not a Firestore field): Mobiles/cameras prohibited inside; lockers at gates. Light & sound at Gabbar temporarily on hold (trust notice Sep 2026 research pass) — verify before visit.

### Kalika Mata Temple

Seed slug: `kalika-mata-temple`

Research payload id `kalika-mata-temple-pavagadh` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Pavagadh. Deity label: `Devi`. Map pin: 22.4611, 73.5117.

Sources:

- [Pavagadh Temple Trust (official timings)](https://www.pavagadhtemple.in/)
- [Champaner-Pavagadh Archaeological Park — UNESCO WHC](https://whc.unesco.org/en/list/1101/)
- [Mahakali Temple Pavagadh — Incredible India](https://www.incredibleindia.gov.in/en/gujarat/vadodara/mahakali-temple)
- [Kalika Mata Temple, Pavagadh — Wikipedia](https://en.wikipedia.org/wiki/Kalika_Mata_Temple,_Pavagadh)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Pavagadh,_Kalika_Mata_Temple_(9840241633).jpg — CC BY 2.0, Arian Zwegers. Kalika Mata Temple on Pavagadh; verified Commons license
- https://commons.wikimedia.org/wiki/File:Kalika-mata-temple.jpg — CC BY-SA 4.0, Abhishek199892. Temple view; verified Commons license

Ritual overflow (not a Firestore field): Trust vs Incredible India opening times differ by ~1 hour at open/close — CMS should prefer trust board + on-site notice. Pair visit with UNESCO Champaner monuments (ASI tickets may apply to park monuments separately from temple darshan).

### Modhera Sun Temple

Seed slug: `modhera-sun-temple`

City: Modhera. Deity label: `Surya`. Map pin: 23.5838, 72.1327.

Sources:

- [Sun Temple Modhera — ASI Must See (hours & tickets)](https://asimustsee.nic.in/sun-temple-modhera.php)
- [Modhera Sun Temple — Gujarat Tourism](https://gujarattourism.com/north-zone/mehsana/sun-temple-modhera.html)
- [Sun Temple, Modhera — Wikipedia](https://en.wikipedia.org/wiki/Sun_Temple,_Modhera)
- [Modhera — Incredible India](https://prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/ahmedabad/modhera.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sun_Temple,_Modhera_03.jpg — CC BY-SA 3.0, Bernard Gagnon. Temple complex view; verified Commons license
- https://commons.wikimedia.org/wiki/File:Sun_Temple_-_Modhera_-_Gujarat_-_DSC002.jpg — CC BY-SA 4.0, Snehrashmi. Modhera exterior; verified Commons license

Ritual overflow (not a Firestore field): Not a living seva temple — do not invent aarti slots. CMS should label clearly as ASI heritage / ticketed. Photography usually allowed in outer complex subject to ASI rules.

### Bahucharaji Temple

Seed slug: `bahucharaji-temple`

City: Bahucharaji. Deity label: `Devi`. Map pin: 23.50012, 72.04485.

Sources:

- [Bahuchar Mata Temple Becharaji — Gujarat Tourism](https://www.gujarattourism.com/north-zone/mehsana/bahuchar-mata-temple-becharaji.html)
- [Bahuchar Mata Temple, Becharaji — Wikipedia](https://en.wikipedia.org/wiki/Bahuchar_Mata_Temple,_Becharaji)
- [Bahuchara Mata — Wikipedia](https://en.wikipedia.org/wiki/Bahuchara_Mata)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Bahuchara_Mata_Temple_complex_in_Mehsana_district_P_20180121_142243.jpg — CC BY-SA 4.0, Sumita Roy Dutta. Temple complex, Mehsana district; verified Commons license

Ritual overflow (not a Firestore field): Official full pooja timetable is thin compared with Trust sites for Ambaji/Somnath — keep CMS timings provisional and labelled. City spelling: Becharaji / Bahucharaji both used.

### Ranchhodraiji Temple

Seed slug: `ranchhodraiji-temple`

Research payload id `ranchhodraiji-temple-dakor` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Dakor. Deity label: `Vishnu`. Map pin: 22.7544, 73.149.

Sources:

- [Ranchhodraiji Temple — Live Darshan & daily timings (official)](https://ranchhodraiji.org/LiveDarshan)
- [Daily Darshan Timings — ranchhodraiji.org](https://www.ranchhodraiji.org/daily-darshan-timings)
- [Dakor — Wikipedia](https://en.wikipedia.org/wiki/Dakor)
- [Ranchhodraiji Live Darshan — Utsav (MoT)](https://utsav.gov.in/view-darshan/shri-ranchhodraiji-live-darshan-2)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ranachhodrai_Temple,_Dakor,_Gujarat.jpg — CC BY-SA 4.0, Aditya Mahar. Ranchhodrai Temple exterior; verified Commons license
- https://commons.wikimedia.org/wiki/File:Dakor_Ranchhod_Ji_Mandir_and_Tirtha,_Gujarat_029.jpg — CC0, Ms Sarah Welch. Mandir and tirtha context; CC0

Ritual overflow (not a Firestore field): Donate only via official website or temple counters (trust anti-fraud notice). Live stream available on ranchhodraiji.org.

### Nageshwar Jyotirlinga Temple

Seed slug: `nageshwar-jyotirlinga-temple`

City: Dwarka. Deity label: `Shiva`. Map pin: 22.3359, 69.0869.

Sources:

- [Nageshwar Jyotirlinga — Wikipedia](https://en.wikipedia.org/wiki/Nageshwar_Jyotirlinga)
- [Nageshvara Jyotirlinga — Wikipedia (alt title)](https://en.wikipedia.org/wiki/Nageshvara_Jyotirlinga)
- [Dwarka Tourism — Nageshwar guide (secondary)](https://dwarkatourism.com/nageshwar-jyotirling-temple/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:%E0%A4%B6%E0%A5%8D%E0%A4%B0%E0%A5%80_%E0%A4%A8%E0%A4%BE%E0%A4%97%E0%A5%87%E0%A4%B6%E0%A5%8D%E0%A4%B5%E0%A4%B0_%E0%A4%9C%E0%A5%8D%E0%A4%AF%E0%A5%8B%E0%A4%A4%E0%A4%BF%E0%A4%B0%E0%A5%8D%E0%A4%B2%E0%A4%BF%E0%A4%82%E0%A4%97_%E0%A4%AE%E0%A4%82%E0%A4%A6%E0%A4%BF%E0%A4%B0.jpg — CC BY-SA 4.0, Shubham7517. Nageshwar Jyotirlinga temple view; verified Commons license (Devanagari filename)

Ritual overflow (not a Firestore field): Official full named-pooja documentation thinner than Somnath/Dwarka — keep CMS timings provisional. Coordinates approx. near Dwarka hinterland.

### Akshardham Temple

Seed slug: `akshardham-temple`

Research payload id `akshardham-temple-gandhinagar` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Gandhinagar. Deity label: `Swaminarayan`. Map pin: 23.2308, 72.6738.

Sources:

- [Swaminarayan Akshardham Gujarat — Visitor Info (official timings)](https://akshardham.com/gujarat/visitor-info/)
- [Swaminarayan Akshardham Temple — Incredible India](https://www.incredibleindia.gov.in/en/gujarat/gandhinagar/swaminarayan-akshardham-temple)
- [Akshardham (Gandhinagar) — Wikipedia](https://en.wikipedia.org/wiki/Akshardham_(Gandhinagar))

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Akshardham_Gandhinagar_Gujarat.jpg — CC BY-SA 3.0, Harsh4101991. Akshardham Gandhinagar exterior; CC BY-SA 3.0 from Commons search API Sep 2026 (detail fetch rate-limited)

Ritual overflow (not a Firestore field): Deity string set to Swaminarayan (accurate to BAPS complex). Not a classical Agama Jyotirlinga/Shakti temple — experiential campus with arti at mandir. Mobiles/cameras/food restricted per official security list.

### Chotila Chamunda Mata Temple

Seed slug: `chotila-chamunda-mata-temple`

City: Chotila. Deity label: `Devi`. Map pin: 22.4199, 71.2101.

Sources:

- [Chamunda Mata Temple, Chotila — Wikipedia](https://en.wikipedia.org/wiki/Chamunda_Mata_Temple,_Chotila)
- [Chotila — Wikipedia](https://en.wikipedia.org/wiki/Chotila)
- [YatraDham — Chamunda Mataji Temple Chotila (secondary timings)](https://temple.yatradham.org/temple/chamunda-mataji-temple-chotila)
- [Gujarat Darshan Guide — Chotila Chamunda timings (secondary)](https://gujaratdarshanguide.com/chamunda-mataji-temple-chotila/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Chamunda_Mataji_Dungar,_Chotila_-_panoramio.jpg — CC BY 3.0, Raman Patel. Hill temple panorama; CC BY 3.0 from Commons search API Sep 2026 (detail fetch rate-limited)
- https://commons.wikimedia.org/wiki/File:Chotila_chamunda.jpg — Public domain, Ashok. Chotila Chamunda view; Public domain per Commons search API Sep 2026 (detail fetch rate-limited)

Ritual overflow (not a Firestore field): Prefer on-site boards for aarti; festival access to steps may be regulated. Funicular/ropeway status changes — do not promise operational rides without fresh confirmation.
