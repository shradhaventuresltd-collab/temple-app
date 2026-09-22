# Bihar sample expansion (batch 14)

Research-backed copy for **10 new Bihar temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer Mahavir Mandir’s official aarti board and the Mahabodhi BTMC chanting programme. Re-check Bihar Tourism pages for Vishnupad, Patan Devi, Mangala Gauri, Ajgaibinath, Deo, and Punaura, and thin clocks for Ugratara, Mundeshwari’s continuous span, Patan Devi, Vishnupad afternoon/evening, Mangala Gauri, and Deo’s ordinary-day edges.

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

Mahabodhi is a living Buddhist World Heritage site (UNESCO 2002), not a Hindu temple; timings use the BTMC chanting programme rather than Hindu pooja language. Mahavir Mandir keeps the official named aarti board, including the seasonal evening aarti. Mundeshwari is often called one of India’s oldest functioning shrines — the story does not treat 108 CE or “world’s oldest” as settled — and its continuous clock is thin. Patan Devi keeps the Bihar Tourism versus Incredible India conflict. Vishnupad, Mangala Gauri, Deo, and Ugratara clocks are thin or provisional where official boards are incomplete. Sitamarhi Janaki is Punaura Dham / Janaki Sthan.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Mahavir Mandir | `mahavir-mandir` | Use mahavirmandirpatna.org / mahavirmandir.org only for official notices and donations; the Trust warns of look-alike unauthorised sites. Queue planning is essential on Tuesdays... Research payload id `mahavir-mandir-patna` is not the seed id. |
| Mundeshwari Devi Temple | `mundeshwari-devi-temple` | “Oldest functioning temple” is a Bihar Tourism / living-tradition claim, not a universally settled superlative. The bloodless offering should be described without implying that... |
| Vishnupad Temple | `vishnupad-temple` | Hindu ancestor-rite centre. Phones, cameras, and electronic gadgets are prohibited per Bihar Tourism. Pitrapaksha requires district crowd-plan checks; priest-led ritual arrangem... |
| Mahabodhi Temple | `mahabodhi-temple` | Buddhist tradition: this is a living Buddhist Mahavihara / pilgrimage complex, not a Hindu temple. Ritual language should use chanting, meditation, circumambulation, offerings,... |
| Patan Devi Temple | `patan-devi-temple` | This record is Badi Patan Devi at Sadikpur, not Chhoti Patan Devi. Government tourism clocks conflict; confirm locally. Shakti Peetha body-part identifications vary by textual a... |
| Mangala Gauri Temple | `mangala-gauri-temple` | Official public detail is limited to a broad sunrise–sunset visitor span. Shravan Tuesdays are exceptionally busy; allow time for the hill steps. Shakti Peetha identifications a... |
| Ajgaibinath Temple | `ajgaibinath-temple` | The 24/7 tourism listing does not guarantee continuous garbha-griha or priest-service access. River level affects approach. Shravan visitors must follow Kanwar-route, traffic, a... |
| Deo Sun Temple | `deo-sun-temple` | Chhath is the defining ritual context; ordinary tourism hours do not apply during the festival. Do not state a precise construction year—the official district page gives only a... |
| Ugratara Temple | `ugratara-temple` | Thin official timings; the district source confirms the shrine and deity triad, not daily ritual minutes. Treat Shakti Peetha / siddha-site and Mandana Mishra associations as li... |
| Janaki Temple Sitamarhi | `janaki-temple-sitamarhi` | This record is Punaura Dham / Janaki Janmabhoomi near Sitamarhi. Its identification as Sita’s birthplace is a living sacred tradition. Festival programmes can override the gener... |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Mahavir Mandir

Seed slug: `mahavir-mandir`

Research payload id `mahavir-mandir-patna` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Patna. Deity label: `Hanuman`. Map pin: 25.60389, 85.13639.

Sources:

- [Mahavir Mandir Patna (official)](https://mahavirmandirpatna.org/)
- [Mahavir Mandir — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/patna/mahavir-mandir)
- [Mahavir Mandir — Wikipedia](https://en.wikipedia.org/wiki/Mahavir_Mandir)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mahavir_Mandir_from_Buddha_Smriti_Park.JPG — CC BY-SA 4.0, Shivamsetu. Temple and Patna Junction precinct viewed from Buddha Smriti Park; verified Commons file page

Ritual overflow (not a Firestore field): Use mahavirmandirpatna.org / mahavirmandir.org only for official notices and donations; the Trust warns of look-alike unauthorised sites. Queue planning is essential on Tuesdays and Saturdays.

### Mundeshwari Devi Temple

Seed slug: `mundeshwari-devi-temple`

City: Bhabua. Deity label: `Devi`. Map pin: 24.9834, 83.5647.

Sources:

- [Mundeshwari Devi Temple — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/kaimur/mundeshwari-devi-temple)
- [Maa Mundeshwari Temple — Kaimur District](https://kaimur.nic.in/tourist-place/maa-mundeshwari-temple-bhagwanpur/)
- [Maa Mundeshwari Trust](https://maamundeshwaritrust.org/)
- [Mundeshwari Temple — Wikipedia](https://en.wikipedia.org/wiki/Mundeshwari_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Maa_Mundeshwari_Devi.jpg — CC BY-SA 3.0, Lakshya. Exterior view of the hill temple in Kaimur; verified Commons file page

Ritual overflow (not a Firestore field): “Oldest functioning temple” is a Bihar Tourism / living-tradition claim, not a universally settled superlative. The bloodless offering should be described without implying that an animal is killed. Seasonal aarti times vary.

### Vishnupad Temple

Seed slug: `vishnupad-temple`

City: Gaya. Deity label: `Vishnu`. Map pin: 24.77736, 85.00934.

Sources:

- [Vishnupad Temple — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/gaya/vishnupad-temple)
- [Vishnupad — Government of Bihar Pinddaan portal](http://www.pinddaangaya.bihar.gov.in/?pg=vishnupad)
- [Vishnupad Temple — Wikipedia](https://en.wikipedia.org/wiki/Vishnupad_Temple,_Gaya)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Vishnupad_temple_gaya_bihar.jpg — CC BY-SA 4.0, Surajkumar12111. Temple exterior in Gaya; verified Commons file page

Ritual overflow (not a Firestore field): Hindu ancestor-rite centre. Phones, cameras, and electronic gadgets are prohibited per Bihar Tourism. Pitrapaksha requires district crowd-plan checks; priest-led ritual arrangements and prices should be agreed in advance.

### Mahabodhi Temple

Seed slug: `mahabodhi-temple`

City: Bodh Gaya. Deity label: `Buddha`. Map pin: 24.696, 84.9913.

Sources:

- [Bodhgaya Temple Management Committee (official)](https://bodhgayatemple.com/)
- [Mahabodhi Temple Complex — UNESCO World Heritage Centre](https://whc.unesco.org/en/list/1056/)
- [Mahabodhi Temple Complex — UNESCO](https://www.unesco.org/en/articles/mahabodhi-temple-complex)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mahabodhi_temple_complex,_Bodhgaya_23.jpg — CC BY-SA 4.0, Rohit Sharma. Mahabodhi Temple complex exterior; verified Commons file page

Ritual overflow (not a Firestore field): Buddhist tradition: this is a living Buddhist Mahavihara / pilgrimage complex, not a Hindu temple. Ritual language should use chanting, meditation, circumambulation, offerings, and Buddha Purnima rather than Hindu pooja terminology. Follow BTMC security rules.

### Patan Devi Temple

Seed slug: `patan-devi-temple`

City: Patna. Deity label: `Devi`. Map pin: 25.60531, 85.20629.

Sources:

- [Badi Patan Devi — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/patna/badi-patan-devi)
- [Patan Devi Mandir — Incredible India](https://www.incredibleindia.gov.in/en/bihar/patna/patan-devi-mandir)
- [Patan Devi — Wikipedia](https://en.wikipedia.org/wiki/Patan_Devi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Patan_Devi.jpg — CC BY 4.0, Shivam Setu (Flickr; reviewed on Commons). Captioned Badi Patan Devi, Patna; Flickr-reviewed CC BY 4.0 Commons file page

Ritual overflow (not a Firestore field): This record is Badi Patan Devi at Sadikpur, not Chhoti Patan Devi. Government tourism clocks conflict; confirm locally. Shakti Peetha body-part identifications vary by textual and regional tradition.

### Mangala Gauri Temple

Seed slug: `mangala-gauri-temple`

City: Gaya. Deity label: `Devi`. Map pin: 24.77514, 85.00231.

Sources:

- [Mangala Gauri — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/gaya/mangala-gauri)
- [Mangla Gauri Temple — Incredible India](https://www.incredibleindia.gov.in/en/bihar/gaya/mangla-gauri-temple)
- [Mangla Gauri Temple — Wikipedia](https://en.wikipedia.org/wiki/Mangla_Gauri_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mangala_Gauri_Temple_at_Gaya,_Bihar.jpg — CC BY-SA 4.0, Mumbaipsytrance. Exterior view of Mangala Gauri Temple in Gaya; verified Commons file page

Ritual overflow (not a Firestore field): Official public detail is limited to a broad sunrise–sunset visitor span. Shravan Tuesdays are exceptionally busy; allow time for the hill steps. Shakti Peetha identifications are matters of living tradition.

### Ajgaibinath Temple

Seed slug: `ajgaibinath-temple`

City: Sultanganj. Deity label: `Shiva`. Map pin: 25.25239, 86.73431.

Sources:

- [Ajgaibinath Mandir — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/bhagalpur/ajgaibinath-mandir)
- [Ajgaibinath Dham — Wikipedia](https://en.wikipedia.org/wiki/Ajgaibinath_Dham)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ajgaibinath_temple_Day-View.png — CC BY-SA 4.0, Biharpro7252. Daytime view of Ajgaibinath Temple at Sultanganj; verified Commons file page

Ritual overflow (not a Firestore field): The 24/7 tourism listing does not guarantee continuous garbha-griha or priest-service access. River level affects approach. Shravan visitors must follow Kanwar-route, traffic, and water-safety controls.

### Deo Sun Temple

Seed slug: `deo-sun-temple`

City: Deo. Deity label: `Surya`. Map pin: 24.65879, 84.43703.

Sources:

- [Deo Sun Temple — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/aurangabad/deo-sun-temple)
- [Deo Temple — Aurangabad District](https://aurangabad.bih.nic.in/tourist-place/deo-temple/)
- [Deo Surya Mandir — Wikipedia](https://en.wikipedia.org/wiki/Deo_Surya_Mandir)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sun-temple_DEO_Aurangabad_Bihar,India.jpg — CC BY-SA 4.0, Aurangabad district website; Commons upload by Ravi90it. Deo Surya Mandir exterior sourced from the district website; verified Commons license page

Ritual overflow (not a Firestore field): Chhath is the defining ritual context; ordinary tourism hours do not apply during the festival. Do not state a precise construction year—the official district page gives only a broad age / royal association.

### Ugratara Temple

Seed slug: `ugratara-temple`

City: Mahishi. Deity label: `Devi`. Map pin: 25.8483, 86.4728.

Sources:

- [Shri Ugratara Sthan, Mahishi — Saharsa District](https://saharsa.nic.in/tourist-place/shri-ugratara-sthan-mahishi/)
- [Shri Ugratara Sthan Mahishi — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/saharsa/shri-ugratara-sthan-mahishi)
- [Ugratara Sthan — Wikipedia](https://en.wikipedia.org/wiki/Ugratara_Sthan)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ugratara_Shakti_Peeth_(Temple)_in_Mahishi,_Near_Saharsa_Town.jpg — CC BY-SA 4.0, Varunesh Chandra. Ugratara temple exterior at Mahishi; verified Commons file page

Ritual overflow (not a Firestore field): Thin official timings; the district source confirms the shrine and deity triad, not daily ritual minutes. Treat Shakti Peetha / siddha-site and Mandana Mishra associations as living regional traditions unless a stronger historical source is added.

### Janaki Temple Sitamarhi

Seed slug: `janaki-temple-sitamarhi`

City: Sitamarhi. Deity label: `Sita (Devi)`. Map pin: 26.58645, 85.46676.

Sources:

- [Punaura Dham — Bihar Tourism](https://tourism.bihar.gov.in/en/destinations/sitamarhi/punaura-dham)
- [Punaura Dham — Sitamarhi District](https://sitamarhi.nic.in/tourist-place/punaura-dham/)
- [Punaura Math Shri Janaki Janmabhoomi Temple Trust](http://ssjpmtkshetra.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Punaura_Sitamarhi.jpg — CC0 1.0, Nepalopedia4u. Punaura site image captioned “Birthplace of Sita”; Commons description is minimal, so verify subject framing before CMS selection

Ritual overflow (not a Firestore field): This record is Punaura Dham / Janaki Janmabhoomi near Sitamarhi. Its identification as Sita’s birthplace is a living sacred tradition. Festival programmes can override the general tourism clock.
