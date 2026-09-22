# West Bengal sample expansion (batch 12)

Research-backed copy for **10 new West Bengal temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer Dakshineswar Trust, Belur Math seasonal campus/museum hours, and the ISKCON Mayapur worship board. Re-check Kalighat’s Incredible India split hours, Tarapith committee/app changes, and thin official clocks for Hangseshwari, Taraknath, Birla Mandir Kolkata, Kiriteswari, and Kapil Muni. Gangasagar access depends on ferry, tide, weather, and mela controls.

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

Dakshineswar, Belur Math, and ISKCON Mayapur keep official boards. Belur Math is the Ramakrishna–Vedanta tradition, not a conventional deity category. Mayapur is Gaudiya Vaishnava (Radha-Madhava / Pancha-tattva). Kalighat keeps Incredible India split hours. Hangseshwari, Taraknath, and Birla Mandir Kolkata are thin official clocks. Kapil Muni hours are thin-source and ferry/tide dependent. Kiriteswari’s clock is thin relative to a firm official board.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Kalighat Kali Temple | `kalighat-kali-temple` | General entry is through managed queues; expect long waits on Tuesdays, Saturdays, amavasya and Kali Puja. Treat unsolicited priest or fast-darshan offers cautiously and agree a... |
| Dakshineswar Kali Temple | `dakshineswar-kali-temple` | Security screening applies. Deposit shoes and large bags at designated counters; large luggage and leather articles are restricted near the sanctum, and sanctum photography is p... |
| Belur Math | `belur-math` | Maintain silence during aratrikam and follow monastic-campus instructions. Museum hours differ from campus hours and the museum has Monday/holiday closures. A ferry commonly lin... |
| Tarapith Temple | `tarapith-temple` | Phones must be deposited at the entrance under committee rules reported since December 2024. Devotees hand offerings to temple priests; direct sindoor application, coconut break... |
| Hangseshwari Temple | `hangseshwari-temple` | The structure is a protected historic monument as well as a living shrine. Follow local restrictions on entering upper/interior spaces and on photography; the nearby Ananta Basu... |
| Sri Mayapur Chandrodaya Mandir (ISKCON Mayapur) | `sri-mayapur-chandrodaya-mandir-iskcon-mayapur` | Official guidelines prohibit cameras, mobile phones, laptops and other electronics inside the temple; use designated luggage and shoe facilities. Clean modest clothing is requir... Research payload id `sri-mayapur-chandrodaya-mandir` is not the seed id. |
| Taraknath Temple | `taraknath-temple` | Shravan Mondays can involve very long, wet queues and special traffic controls. Follow official mela barricades, use authorised offering counters, and do not rely on an ordinary... Research payload id `taraknath-temple-tarakeswar` is not the seed id. |
| Birla Mandir | `birla-mandir` | Entry is generally free. Photography is commonly restricted inside; follow the posted bag, shoe and phone rules. Evening and Janmashtami queues can be substantial. Research payload id `birla-mandir-kolkata` is not the seed id. |
| Kiriteswari Temple | `kiriteswari-temple` | This is a village shrine with limited authoritative online visitor information. Carry cash for ordinary offerings, use local authorised counters/priests, and verify transport an... |
| Kapil Muni Temple | `kapil-muni-temple` | Plan around ferry status, tides, weather and district mela advisories. During Makar Sankranti use only official transport camps, marked bathing sectors and police routes; do not... Research payload id `kapil-muni-temple-gangasagar` is not the seed id. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Kalighat Kali Temple

Seed slug: `kalighat-kali-temple`

City: Kolkata. Deity label: `Devi (Kali)`. Map pin: 22.52, 88.34194.

Sources:

- [Incredible India — Kalighat Temple](https://www.incredibleindia.gov.in/en/west-bengal/kolkata/kalighat-temple)
- [Kalighat Temple — Wikipedia](https://en.wikipedia.org/wiki/Kalighat_Kali_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kalighat_Kali_Temple.jpg — CC BY-SA 3.0, Bernard Gagnon. Temple roof and spire; verified Commons file and license page

Ritual overflow (not a Firestore field): General entry is through managed queues; expect long waits on Tuesdays, Saturdays, amavasya and Kali Puja. Treat unsolicited priest or fast-darshan offers cautiously and agree any offering at authorised counters. Photography rules are strict near the sanctum.

### Dakshineswar Kali Temple

Seed slug: `dakshineswar-kali-temple`

City: Kolkata. Deity label: `Devi (Bhavatarini Kali)`. Map pin: 22.655, 88.35778.

Sources:

- [Dakshineswar Kali Temple — Official Website](https://dakshineswarkalitemple.org/)
- [Dakshineswar Kali Temple — Wikipedia](https://en.wikipedia.org/wiki/Dakshineswar_Kali_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Dakshineswar_Kali_Temple,_Dakshineswar,_North_24_Parganas_district,_India.jpg — CC BY-SA 4.0, Ravi Dwivedi. Main navaratna temple exterior; verified Commons file and license page

Ritual overflow (not a Firestore field): Security screening applies. Deposit shoes and large bags at designated counters; large luggage and leather articles are restricted near the sanctum, and sanctum photography is prohibited. The Trust board overrides third-party seasonal schedules.

### Belur Math

Seed slug: `belur-math`

City: Howrah. Deity label: `Sri Ramakrishna (Ramakrishna–Vedanta tradition)`. Map pin: 22.6325, 88.35639.

Sources:

- [Belur Math — Official Home](https://belurmath.org/)
- [Belur Math — Official Location and Opening Hours](https://belurmath.org/our-location/)
- [Belur Math — Wikipedia](https://en.wikipedia.org/wiki/Belur_Math)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Belur_Math_-_Ramakrishna_Math_and_around,_Howrah,_Kolkata-_IRCTC_2017_(22).jpg — CC BY-SA 4.0, Vinayaraj. Belur Math campus photograph; verified Commons file and license page

Ritual overflow (not a Firestore field): Maintain silence during aratrikam and follow monastic-campus instructions. Museum hours differ from campus hours and the museum has Monday/holiday closures. A ferry commonly links Belur with Dakshineswar, subject to river service conditions.

### Tarapith Temple

Seed slug: `tarapith-temple`

City: Tarapith. Deity label: `Devi (Tara)`. Map pin: 24.1167, 87.7903.

Sources:

- [Times of India — Tarapith Rules and Timing Change (December 2024)](https://timesofindia.indiatimes.com/city/kolkata/new-rules-change-in-timings-at-tarapith-kali-temple/articleshow/116406958.cms)
- [Times of India — Tarapith App Priority Booking Rollout (September 2026)](https://timesofindia.indiatimes.com/city/kolkata/now-book-tarapith-slot-via-app-as-temple-rolls-out-online-vip-booking/articleshow/133849135.cms)
- [Tarapith — Wikipedia](https://en.wikipedia.org/wiki/Tarapith)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Tarapith_Temple_04.jpg — CC BY-SA 4.0, Tarunsamanta. Tarapith temple exterior, Rampurhat; verified Commons file and license page

Ritual overflow (not a Firestore field): Phones must be deposited at the entrance under committee rules reported since December 2024. Devotees hand offerings to temple priests; direct sindoor application, coconut breaking inside the sanctum, and touching the image may be restricted. Priority booking is in transition—use only the committee-announced app/counter, never agents.

### Hangseshwari Temple

Seed slug: `hangseshwari-temple`

City: Bansberia. Deity label: `Devi (Hangseshwari Kali)`. Map pin: 22.96432, 88.39981.

Sources:

- [Hooghly District Administration — Hangseswari Temple](https://hooghly.nic.in/tourist-place/hangseswari-temple/)
- [Hangseshwari Temple — Wikipedia](https://en.wikipedia.org/wiki/Hangseshwari_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Hanseswari_Temple,Bansberia,_Hooghly.jpg — CC BY-SA 4.0, Rangan Datta Wiki. Full exterior of ASI monument N-WB-63; verified Commons file and license page

Ritual overflow (not a Firestore field): The structure is a protected historic monument as well as a living shrine. Follow local restrictions on entering upper/interior spaces and on photography; the nearby Ananta Basudeba temple merits separate time.

### Sri Mayapur Chandrodaya Mandir (ISKCON Mayapur)

Seed slug: `sri-mayapur-chandrodaya-mandir-iskcon-mayapur`

Research payload id `sri-mayapur-chandrodaya-mandir` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mayapur. Deity label: `Radha-Madhava / Pancha-tattva (Gaudiya Vaishnavism)`. Map pin: 23.43828, 88.39287.

Sources:

- [ISKCON Mayapur — Official Temple Timings](https://srimayapurdhama.com/iskconmayapur-templetimings/)
- [Mayapur — Wikipedia](https://en.wikipedia.org/wiki/Mayapur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Chandrodaya_Mandir_in_ISKCON_Campus_02.jpg — CC BY-SA 4.0, Pinakpani. Chandrodaya Mandir / ISKCON campus view from Nabadwip; verified Commons file and license page

Ritual overflow (not a Firestore field): Official guidelines prohibit cameras, mobile phones, laptops and other electronics inside the temple; use designated luggage and shoe facilities. Clean modest clothing is required; shorts, half-pants, three-quarter pants, nightwear and lungis are listed as not permitted.

### Taraknath Temple

Seed slug: `taraknath-temple`

Research payload id `taraknath-temple-tarakeswar` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Tarakeswar. Deity label: `Shiva (Taraknath)`. Map pin: 22.8854, 88.0176.

Sources:

- [Hooghly District Administration — Baba Taraknath Temple](https://hooghly.nic.in/tourist-place/baba-taraknath-temple/)
- [Taraknath Temple — Wikipedia](https://en.wikipedia.org/wiki/Taraknath_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Babataraknathtemple.jpg — CC BY-SA 3.0, Sankha Karfa. Taraknath Temple exterior at Tarakeswar; verified Commons file and license page

Ritual overflow (not a Firestore field): Shravan Mondays can involve very long, wet queues and special traffic controls. Follow official mela barricades, use authorised offering counters, and do not rely on an ordinary-day clock during festival periods.

### Birla Mandir

Seed slug: `birla-mandir`

Research payload id `birla-mandir-kolkata` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Kolkata. Deity label: `Vishnu (Radha-Krishna / Lakshminarayan)`. Map pin: 22.53056, 88.365.

Sources:

- [Birla Mandir, Kolkata — Wikipedia](https://en.wikipedia.org/wiki/Birla_Mandir,_Kolkata)
- [Kolkata Tourism — Birla Temple](https://kolkatatourism.travel/birla-temple-kolkata)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Birla_Temple_Kolkata_(24455112378).jpg — CC BY 2.0, Ankur P. Birla Mandir Kolkata exterior; Flickr license review verified on Commons file page

Ritual overflow (not a Firestore field): Entry is generally free. Photography is commonly restricted inside; follow the posted bag, shoe and phone rules. Evening and Janmashtami queues can be substantial.

### Kiriteswari Temple

Seed slug: `kiriteswari-temple`

City: Murshidabad. Deity label: `Devi (Kiriteswari / Mahishamardini)`. Map pin: 24.2, 88.21861.

Sources:

- [Murshidabad District Administration — Shaktipeeth Shri Kiriteswari Temple](https://murshidabad.gov.in/tourist-place/shaktipeeth-shri-kiriteswari-temple/)
- [Kiriteswari Temple — Wikipedia](https://en.wikipedia.org/wiki/Kiriteswari_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kiriteswari_Temple.jpg — CC BY-SA 4.0, Pinakpani. Kiriteswari Temple, Murshidabad exterior; verified Commons file and license page

Ritual overflow (not a Firestore field): This is a village shrine with limited authoritative online visitor information. Carry cash for ordinary offerings, use local authorised counters/priests, and verify transport and return timing; the nearest stations still require a road transfer.

### Kapil Muni Temple

Seed slug: `kapil-muni-temple`

Research payload id `kapil-muni-temple-gangasagar` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Gangasagar. Deity label: `Kapil Muni`. Map pin: 21.63654, 88.07334.

Sources:

- [Kapil Muni Temple — Wikipedia](https://en.wikipedia.org/wiki/Kapil_Muni_Temple)
- [Gangasagar — Wikipedia](https://en.wikipedia.org/wiki/Gangasagar)
- [Gangasagar Yatra — Kapil Muni Ashram Guide](https://gangasagaryatra.co.in/kapil-muni-ashram/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kapil_Muni_Ashram_Gangasagar_West_Bengal.jpg — CC BY-SA 4.0, Jordanrockwi. Kapil Muni Ashram / temple exterior at Gangasagar; verified Commons file and license page (embedded source date is unreliable, but authorship/license are clear)

Ritual overflow (not a Firestore field): Plan around ferry status, tides, weather and district mela advisories. During Makar Sankranti use only official transport camps, marked bathing sectors and police routes; do not enter the sea outside authorised zones. Cyclones or extreme tides can close access with little notice.
