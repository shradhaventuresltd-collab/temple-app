# Maharashtra sample expansion (batch 10)

Research-backed copy for **10 new Maharashtra temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer Shirdi SSST, Siddhivinayak Trust, Trimbakeshwar Trust, Bhimashankar’s live banner, Vitthal Rukmini Mandir Samiti, and Mahalakshmi Trust pages over tourist aggregators. Re-check Shirdi passes, Siddhivinayak weekday versus Tuesday/Chaturthi boards, Bhimashankar construction-hour cutbacks, and thin clocks at Grishneshwar, Mumba Devi, and Morgaon.

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

Shirdi, Siddhivinayak, Trimbakeshwar, Vitthal-Rukmini, and Mahalakshmi keep named official boards in timings. Bhimashankar’s full-day board is kept alongside the official construction notice that has cut darshan to 07:00–11:00. Grishneshwar is a thin official English clock: Incredible India open/close plus aarti markers, with the midday-break conflict labelled provisional. Mumba Devi’s continuous open/close span and Morgaon’s continuous darshan windows are marked thinner or provisional against Trust aarti markers.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Shree Saibaba Samadhi Mandir | `shree-saibaba-samadhi-mandir` | Book darshan/aarti only at online.sai.org.in — SSST states it does not authorise agents. Carry matching government photo ID. Dhoop Aarti follows sunset (clock shifts seasonally)... |
| Siddhivinayak Temple | `siddhivinayak-temple` | Ordinary darshan free. Tuesdays and Ganesh Chaturthi / Sankashti require much earlier arrival. During Maha Abhishekha windows on Vinayaki etc., main-temple access may pause whil... Research payload id `siddhivinayak-temple-mumbai` is not the seed id. |
| Trimbakeshwar Temple | `trimbakeshwar-temple` | Dress modestly; follow mahadware queue instructions. Sanctum is relatively small — expect managed viewing distance on crowded days. Online VIP/donation passes (when offered) req... |
| Bhimashankar Temple | `bhimashankar-temple` | Monsoon and Shravan Mondays bring extreme crowds and traffic on the ghat road. Abhishek rules and nijarup vs shringar windows cited on secondary boards can differ from the offic... |
| Grishneshwar Temple | `grishneshwar-temple` | Thin official English pooja clock — rely on Incredible India open/close and local board. Men: expect shirt-off rule for sanctum. Pair with Ellora carefully (Ellora closed Tuesda... |
| Vitthal Rukmini Temple | `vitthal-rukmini-temple` | Yatra weeks require multi-hour queue planning. Follow Samiti notices for temporary full closures (maintenance / special events). Modest dress; remove footwear at designated points. Research payload id `vitthal-rukmini-temple-pandharpur` is not the seed id. |
| Mumba Devi Temple | `mumba-devi-temple` | Narrow bazaar lanes — expect congestion near Zaveri Bazar. Photography rules follow Trust/security boards. Navratri nights are peak; arrive early for Mangal Aarti if seeking qui... |
| Mahalakshmi Temple | `mahalakshmi-temple` | Arrive before 6:45 AM for pre-aarti quiet darshan, or after 7:30 AM. Remove footwear; modest dress. Navratri wait times can exceed 2–3 hours — follow Trust queue marshals. Research payload id `mahalakshmi-temple-mumbai` is not the seed id. |
| Jejuri Khandoba Temple | `jejuri-khandoba-temple` | Carry Aadhaar matching e-pass. Expect turmeric on clothes/skin during festivals. Climb is steep — allow time and water. Prohibited items boards are enforced in the temple precinct. |
| Morgaon Mayureshwar Temple | `morgaon-mayureshwar-temple` | Trust phone listed on official Morgaon page for confirmations. Ashtavinayak circuit travellers should budget queue time before continuing to other vinayakas. Modest dress; follo... |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Shree Saibaba Samadhi Mandir

Seed slug: `shree-saibaba-samadhi-mandir`

City: Shirdi. Deity label: `Sai Baba`. Map pin: 19.7667, 74.4772.

Sources:

- [Shree Saibaba Sansthan Trust — Daily Programme (official)](https://sai.org.in/daily-programme)
- [Shree Saibaba Sansthan Trust (official home)](https://sai.org.in/)
- [Sai Baba of Shirdi — Wikipedia](https://en.wikipedia.org/wiki/Sai_Baba_of_Shirdi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sai_Temple_Shirdi_(tomb)_%2C2024.jpg — CC BY-SA 4.0, Kisna007. Samadhi Mandir exterior during Ram Navami 2024; verified Commons license page
- https://commons.wikimedia.org/wiki/File:PM_offers_prayers_at_Shri_Saibaba_Samadhi_Temple_in_Shirdi,_Maharashtra_on_October_26,_2023.jpg — GODL-India, Prime Minister's Office / Press Information Bureau (GODL-India). Interior/prayer view of Samadhi Temple Oct 2023; Government of India open licence — verify attribution line on Commons

Ritual overflow (not a Firestore field): Book darshan/aarti only at online.sai.org.in — SSST states it does not authorise agents. Carry matching government photo ID. Dhoop Aarti follows sunset (clock shifts seasonally). Peak days (Ram Navami, Punyatithi, weekends) require extra queue time.

### Siddhivinayak Temple

Seed slug: `siddhivinayak-temple`

Research payload id `siddhivinayak-temple-mumbai` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mumbai. Deity label: `Ganesha`. Map pin: 19.0169, 72.8304.

Sources:

- [Shree Siddhivinayak — Temple Schedule (official)](https://www.siddhivinayak.org/temple-schedule/)
- [Shree Siddhivinayak Ganapati Mandir Trust (official)](https://www.siddhivinayak.org/)
- [Siddhivinayak Temple, Mumbai — Wikipedia](https://en.wikipedia.org/wiki/Siddhivinayak_Temple,_Mumbai)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Shree_Siddhivinayak_Temple_Mumbai.jpg — CC BY-SA 3.0, Darwininan. Temple exterior elevation; verified Commons license page

Ritual overflow (not a Firestore field): Ordinary darshan free. Tuesdays and Ganesh Chaturthi / Sankashti require much earlier arrival. During Maha Abhishekha windows on Vinayaki etc., main-temple access may pause while far-distance darshan continues — follow Trust signs.

### Trimbakeshwar Temple

Seed slug: `trimbakeshwar-temple`

City: Trimbak. Deity label: `Shiva`. Map pin: 19.9322, 73.5308.

Sources:

- [Shri Trimbakeshwar Devasthan Trust (official)](https://www.trimbakeshwartrust.com/index.php)
- [Trimbakeshwar Trust — Daily Programme](https://trimbakeshwartrust.com/daily_programme)
- [Trimbakeshwar Temple — Wikipedia](https://en.wikipedia.org/wiki/Trimbakeshwar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Trimbakeshwar_Shiva_Temple,_Trimbak,_Nashik_district.jpg — CC BY-SA 3.0, World8115. Temple exterior / shikhara view; verified Commons license page

Ritual overflow (not a Firestore field): Dress modestly; follow mahadware queue instructions. Sanctum is relatively small — expect managed viewing distance on crowded days. Online VIP/donation passes (when offered) require ID — Trust pages are authoritative over third-party agents.

### Bhimashankar Temple

Seed slug: `bhimashankar-temple`

City: Bhimashankar. Deity label: `Shiva`. Map pin: 19.072, 73.535.

Sources:

- [Shree Bhimashankar — official (EN)](https://shreebhimashankar.com/en/)
- [Bhimashankar Temple — Wikipedia](https://en.wikipedia.org/wiki/Bhimashankar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Bhimashankar_temple.JPG — CC BY-SA 3.0, Pradeep245. Temple exterior in forested Sahyadri setting; verified Commons license page

Ritual overflow (not a Firestore field): Monsoon and Shravan Mondays bring extreme crowds and traffic on the ghat road. Abhishek rules and nijarup vs shringar windows cited on secondary boards can differ from the official table — prefer shreebhimashankar.com. Carry warm layers; sanctuary area is cooler than Pune plains.

### Grishneshwar Temple

Seed slug: `grishneshwar-temple`

City: Verul. Deity label: `Shiva`. Map pin: 20.0248, 75.1699.

Sources:

- [Grishneshwar Temple — Incredible India](https://www.incredibleindia.gov.in/en/maharashtra/chhatrapati-sambhaji-nagar/grishneshwar-temple)
- [Ghrishneshwar Temple — Wikipedia](https://en.wikipedia.org/wiki/Ghrishneshwar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Grishneshwar_Temple.jpg — CC BY 2.0, sowrirajan s (Flickr); reviewed on Commons. Temple exterior near Ellora/Verul; verified Commons CC BY 2.0 license page

Ritual overflow (not a Firestore field): Thin official English pooja clock — rely on Incredible India open/close and local board. Men: expect shirt-off rule for sanctum. Pair with Ellora carefully (Ellora closed Tuesdays; ASI tickets). Heavy Shravan Monday queues.

### Vitthal Rukmini Temple

Seed slug: `vitthal-rukmini-temple`

Research payload id `vitthal-rukmini-temple-pandharpur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Pandharpur. Deity label: `Vitthal`. Map pin: 17.6746, 75.3237.

Sources:

- [Shri Vitthal Rukmini Temple — Daily Schedule (official)](https://vitthalrukminimandir.org/daily_schedule.php)
- [Shri Vitthal Rukmini Mandir Samiti (official)](https://www.vitthalrukminimandir.org/)
- [Vithoba Temple, Pandharpur — Wikipedia](https://en.wikipedia.org/wiki/Vithoba_Temple,_Pandharpur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Pandharpur_Vithoba_temple.jpg — CC BY-SA 2.0, Parag Mahalley (Flickr); uploaded by Redtigerxyz. Main gate of Pandharpur Vitthal temple; verified Commons license page

Ritual overflow (not a Firestore field): Yatra weeks require multi-hour queue planning. Follow Samiti notices for temporary full closures (maintenance / special events). Modest dress; remove footwear at designated points.

### Mumba Devi Temple

Seed slug: `mumba-devi-temple`

City: Mumbai. Deity label: `Devi`. Map pin: 18.95, 72.83.

Sources:

- [Shree Mumbadevi Mandir Charities (official)](https://www.mumbadevi.org.in/)
- [Mumba Devi Temple — Wikipedia](https://en.wikipedia.org/wiki/Mumba_Devi_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mumbadevi_Sikhara.jpg — CC BY-SA 3.0, PHMS. Sikhara of Mumbadevi Temple; verified Commons license page

Ritual overflow (not a Firestore field): Narrow bazaar lanes — expect congestion near Zaveri Bazar. Photography rules follow Trust/security boards. Navratri nights are peak; arrive early for Mangal Aarti if seeking quieter darshan.

### Mahalakshmi Temple

Seed slug: `mahalakshmi-temple`

Research payload id `mahalakshmi-temple-mumbai` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mumbai. Deity label: `Devi`. Map pin: 18.9777, 72.8068.

Sources:

- [Shri Mahalakshmi Temple Mumbai — Darshan & Aarti (official)](https://mahalakshmi-temple.com/darshan)
- [Shri Mahalakshmi Temple Mumbai (official)](https://mahalakshmi-temple.com/)
- [Mahalakshmi Temple, Mumbai — Wikipedia](https://en.wikipedia.org/wiki/Mahalakshmi_Temple,_Mumbai)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mahalaxmi_temple_entrance.JPG — CC BY-SA 3.0, Karthik Nadar. Temple entrance exterior; verified Commons license page

Ritual overflow (not a Firestore field): Arrive before 6:45 AM for pre-aarti quiet darshan, or after 7:30 AM. Remove footwear; modest dress. Navratri wait times can exceed 2–3 hours — follow Trust queue marshals.

### Jejuri Khandoba Temple

Seed slug: `jejuri-khandoba-temple`

City: Jejuri. Deity label: `Khandoba`. Map pin: 18.2722, 74.1603.

Sources:

- [Shri Martand Dev Sansthan Jejuri — Online Darshan (official)](https://www.khandoba.com/front/on_darshan/home)
- [Khandoba Temple, Jejuri — Wikipedia](https://en.wikipedia.org/wiki/Khandoba_Temple,_Jejuri)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Jejuri_temple_(Sonyachi_Jejuri)_07.jpg — CC BY-SA 4.0, Shweta K. Kapoor. Jejuri Khandoba temple / Sonyachi Jejuri hill view; Wiki Loves Folklore; verified Commons license page

Ritual overflow (not a Firestore field): Carry Aadhaar matching e-pass. Expect turmeric on clothes/skin during festivals. Climb is steep — allow time and water. Prohibited items boards are enforced in the temple precinct.

### Morgaon Mayureshwar Temple

Seed slug: `morgaon-mayureshwar-temple`

City: Morgaon. Deity label: `Ganesha`. Map pin: 18.276, 74.321.

Sources:

- [Morgaon — Chinchwad Devasthan Trust (official)](https://morgaon.chinchwaddeosthan.org/morgaon/?lang=en)
- [Morgaon Ashtavinayak — Maharashtra Tourism](https://maharashtratourism.gov.in/ashtavinayak/morgaon/)
- [Ganesha Temple, Morgaon — Wikipedia](https://en.wikipedia.org/wiki/Ganesha_Temple,_Morgaon)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Morgaon_temple.jpg — CC BY-SA 3.0, Redtigerxyz. Morgaon Mayureshwar temple exterior; verified Commons license page

Ritual overflow (not a Firestore field): Trust phone listed on official Morgaon page for confirmations. Ashtavinayak circuit travellers should budget queue time before continuing to other vinayakas. Modest dress; follow Trust offering rules for abhishek if permitted.
