# Kerala sample enrichment (batch 2)

Research-backed copy for the **10 existing Kerala temples** in
`lib/data/sample_data.dart`. Names and slugs are unchanged so debug **Seed**
still targets the same Firestore documents (`templeDocumentId(name)`).

This file is **not** written to Firestore. Use it when reviewing CMS publish
and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Guruvayur Devaswom / SPST / Travancore
or Cochin Devaswom Board / Kerala Tourism pages over tourist aggregators and
over the older bundled sample envelopes where they conflict.

## Field mapping (Dart model ↔ Firestore)

| Research / sample Dart | Firestore (Seed + Admin CMS) |
| --- | --- |
| `name`, `state`, `city`, `deity` | same |
| `location` | `address` (`Temple.location`; `fromMap` also accepts legacy `location`) |
| `description`, `story`, `timings` | same |
| `specialities` (`List<String>`) | same |
| `latitude`, `longitude` | same |
| `imageUrl` / `images` | same — **picsum placeholders left as-is**; do not invent Storage URLs |
| `sources`, `photo_candidates`, `rituals_notes` | **not in the Temple schema** — documented here only |

No `pooja_schedule` / `festivals` collections were added. Deity strings stay
the bundled catalogue values (`Vishnu` for Sabarimala Ayyappa and Mannarsala
Nagaraja).

## Images

KAN-77 Wave A stores Commons 1280px `downloaded_url` thumbs in sample
`imageUrl` / `images` for the temples that have a pack under
`tools/photo-packs/`. Those are not Storage URLs. Anjengo and Mannarsala
have no READY pack (shortfall) and keep their picsum covers; Seed still
drops picsum. One Guruvayur frame (a mural also filed under Ulanadu and
other Krishna temples) was not downloaded. Sabarimala stays a living
temple (seasonal timings). Its cover is the temple-complex frame already in
the pack (`Sabarimala 5`); the forest frame stays in the gallery.
Thiruvalla’s cover is the temple gopuram already in the pack; the Kathakali
frame stays in the gallery. Padmanabhaswamy stays neutral: no living-temple
chip and no heritage-visit chip. Earlier notes below that say picsum or an
empty cover describe the pre-pack research pass. Do **not** invent Storage URLs.

Anjengo candidates are **Fort context** shots only — no license-safe photo of
the Durga shrine itself was verified in this pass.

## Verify before CMS / publish

Festival days and Mandala season often override ordinary hours. Re-check
near travel dates.

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Guruvayur Sri Krishna Temple | `guruvayur-sri-krishna-temple` | Prefer Guruvayur Devaswom over the coarse sample envelope; Udayasthamana days expand the clock. |
| Sree Padmanabhaswamy Temple | `sree-padmanabhaswamy-temple` | Use official SPST **slotted** windows (`spst.in/Timing`), not the old 3:30 AM–12:00 PM / 5:00 PM–7:20 PM envelope. |
| Sabarimala Ayyappan Temple | `sabarimala-ayyappan-temple` | Seasonal Mandala–Makaravilakku temple — confirm TDB / sabarimala.kerala.gov.in; not a daily urban schedule. |
| Attukal Bhagavathy Temple | `attukal-bhagavathy-temple` | Guinness certified 2.5 million (10 Mar 2009); later “3.5 million+” media figures are uncertified. Pongala week disrupts hours. |
| Chottanikkara Bhagavathy Temple | `chottanikkara-bhagavathy-temple` | Prefer Cochin Devaswom official clock; sample envelope understates evening length through Valiya Guruthi. |
| Ernakulathappan Temple | `ernakulathappan-temple` | No minute-grid official page located — treat named slots as unverified; confirm Cochin Devaswom / on site. |
| Vaikom Mahadeva Temple | `vaikom-mahadeva-temple` | Official vaikomtemple.org emphasises offerings more than a minute-clock; confirm TDB / on site. |
| Anjengo Sree Durga Devi Temple | `anjengo-sree-durga-devi-temple` | Timings are sample-derived only (no Devaswom portal found). Thin sources; Fort photos are context, not the shrine. |
| Mannarsala Sree Nagaraja Temple | `mannarsala-sree-nagaraja-temple` | Prefer mannarasala.org: weekday morning closes 11:00 AM; evening opens 5:30 PM (sample used Sunday-length morning). |
| Thirunelli Maha Vishnu Temple | `thirunelli-maha-vishnu-temple` | Prefer Kerala Tourism 5:30 AM–12:30 PM / 5:30 PM–8:30 PM over the shorter sample envelope. |

Coordinates are approximate map pins retained from `sample_data.dart`.

## Ritual overflow (no schema field)

Visitor tips that did not fit `timings` / `story` / `specialities`:

- **Guruvayur:** Krishnanattam on specified nights after closing; wedding halls outside East Nada; vazhipadu via Devaswom portal.
- **Sabarimala:** Malikappuram Devi is part of the Sannidhanam circuit; Padi Pooja / Udayasthamana / Sahasrakalasam are bookable TDB specials. Traditional customs around women’s entry of certain ages have been legally contested — follow current TDB / court-compliant notices.
- **Anjengo:** No dedicated official temple website; enrichment leans on Anchuthengu colonial history plus the sample’s local framing.
- **Mannarsala:** Photography inside the compound is prohibited; sacred grove entry is forbidden. Consider a Nagaraja deity alias in a future CMS field.

## Sources and photo candidates

### Guruvayur Sri Krishna Temple

Seed slug: `guruvayur-sri-krishna-temple`

Sources:

- [Guruvayur Devaswom — official portal](https://guruvayurdevaswom.in/)
- [Guruvayur Temple — Wikipedia](https://en.wikipedia.org/wiki/Guruvayur_Temple)
- [Daily pooja schedule (secondary compilation; confirm vs Devaswom)](https://guruvayooronline.com/2023/04/01/daily-pooja/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Guruvayur_Sree_Krishna_Temple.jpg — CC BY 2.0, Pyngodan. Temple exterior; verified Commons license
- https://commons.wikimedia.org/wiki/File:009392022_Guruvayur_temple,_Kerala_024.jpg — CC0, Ms Sarah Welch. Complex/context shot; CC0 public-domain dedication
- https://commons.wikimedia.org/wiki/File:Garuda_statue_at_Guruvayur_Sri_Krishna_Temple.jpg — CC BY-SA 3.0, Vinayaraj. Garuda statue within precinct

Ritual overflow: OPTIONAL CMS: Krishnanattam on specified nights after closing; wedding halls outside East Nada are among Kerala’s busiest; free-darshan / vazhipadu booking via Guruvayur Devaswom portal.

### Sree Padmanabhaswamy Temple

Seed slug: `sree-padmanabhaswamy-temple`

Sources:

- [Sree Padmanabha Swami Temple — official timings (SPST)](https://www.spst.in/Timing)
- [SPST official home — dress code guidelines](https://www.spst.in/)
- [Padmanabhaswamy Temple — Wikipedia](https://en.wikipedia.org/wiki/Padmanabhaswamy_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sree_Padmanabhaswamy_Temple,.jpg — CC BY 4.0, Shots by Karthik S.P. Gopuram/exterior; filename has trailing comma — use exact Commons URL
- https://commons.wikimedia.org/wiki/File:Sree_Padmanabhaswamy_Temple_Lakshadeepam.jpg — CC BY-SA 4.0, Arun RJ. Lakshadeepam festival illumination
- https://commons.wikimedia.org/wiki/File:Padmanabhaswamy_Temple_(78808).jpg — CC BY-SA 4.0, Manukrishnan80. Temple precinct view; geotagged near Fort

### Sabarimala Ayyappan Temple

Seed slug: `sabarimala-ayyappan-temple`

Sources:

- [Sabarimala — official pooja timing (Kerala / TDB portal)](https://sabarimala.kerala.gov.in/pooja-timing)
- [Sabarimala Temple — Wikipedia](https://en.wikipedia.org/wiki/Sabarimala_Temple)
- [Sabarimala place / district context — Wikipedia](https://en.wikipedia.org/wiki/Sabarimala)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Shabarimala.JPG — CC BY-SA 3.0, AnjanaMenon (ml.wikipedia). Sabarimala hill/temple context
- https://commons.wikimedia.org/wiki/File:Sabarimala_5.jpg — CC BY-SA 4.0, Dhinakar01. Temple/environs series — verify exact framing on Commons file page

Ritual overflow: OPTIONAL CMS: Malikappuram Devi shrine is part of the Sannidhanam circuit; Padi Pooja, Udayasthamana, Sahasrakalasam, and Pushpabhishekam are bookable specials via TDB. Elevation figures vary by source (~900–1,260 m depending on reference point).

### Attukal Bhagavathy Temple

Seed slug: `attukal-bhagavathy-temple`

Sources:

- [Attukal Bhagavathy Temple — official site](https://www.attukal.org/)
- [Attukal online vazhipadu booking portal](https://booking.attukal.in/)
- [Largest annual gathering of women — Guinness World Records](https://www.guinnessworldrecords.com/world-records/largest-annual-gathering-of-women)
- [Attukal Temple — Wikipedia](https://en.wikipedia.org/wiki/Attukal_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Attukal_Bhagavathy_temple_1.jpg — CC BY-SA 4.0, Ms Sarah Welch. Temple exterior series
- https://commons.wikimedia.org/wiki/File:Attukal_Bhagavathytemple.jpg — CC0, பா.ஜம்புலிங்கம். Temple view; CC0

### Chottanikkara Bhagavathy Temple

Seed slug: `chottanikkara-bhagavathy-temple`

Sources:

- [Chottanikkara Bhagavathy — official (Cochin Devaswom Board)](https://chottanikkarabhagavathy.org/)
- [Official pooja / vazhipadu rate list page](https://www.chottanikkarabhagavathy.org/poojas.php)
- [Chottanikkara Temple — Wikipedia](https://en.wikipedia.org/wiki/Chottanikkara_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Chottanikkara_Temple.jpg — CC BY 2.0, Roney Maxwell. Temple exterior
- https://commons.wikimedia.org/wiki/File:Chottanikkara_Temple_2024.jpg — CC BY-SA 4.0, Vis M. 2024 exterior view
- https://commons.wikimedia.org/wiki/File:Chottanikkara_temple_pond.jpg — CC BY-SA 3.0, Vinayaraj. Temple pond

### Ernakulathappan Temple

Seed slug: `ernakulathappan-temple`

Sources:

- [Ernakulam Shiva Temple — Wikipedia](https://en.wikipedia.org/wiki/Ernakulam_Shiva_Temple)
- [Chottanikkara / Cochin Devaswom context (sibling CDB shrine portal)](https://chottanikkarabhagavathy.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ernakulam_Shiva_Temple_Front.jpg — CC BY-SA 3.0, Dileep Kumar. Front elevation — classic Kerala temple form
- https://commons.wikimedia.org/wiki/File:Ernakulathappan_Temple_West_Gopuram.jpg — CC BY-SA 3.0, Dileep Kumar. West gopuram / main gate
- https://commons.wikimedia.org/wiki/File:Ernakulam_Shiva_Temple_during_one_of_its_festival_days.jpg — CC BY-SA 4.0, Akhilraj0724. Festival-day atmosphere

### Vaikom Mahadeva Temple

Seed slug: `vaikom-mahadeva-temple`

Sources:

- [Vaikom Sree Mahadeva Temple — official](https://www.vaikomtemple.org/)
- [Vaikom Temple — Wikipedia](https://en.wikipedia.org/wiki/Vaikom_Temple)
- [Vaikom Mahadeva Temple timings (secondary compilation)](https://gotirupati.com/vaikom-mahadeva-temple-timings/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Vaikom_Mahadeva_Temple_entrance.jpg — CC BY-SA 4.0, Vijayanrajapuram. Entrance elevation
- https://commons.wikimedia.org/wiki/File:Vaikom_Mahadeva_temple_01.jpg — CC BY-SA 4.0, Ganesh Mohan T. Temple complex view
- https://commons.wikimedia.org/wiki/File:Vaikom_Temple.JPG — Public domain, Georgekutty. Older exterior photo; PD on Commons

### Anjengo Sree Durga Devi Temple

Seed slug: `anjengo-sree-durga-devi-temple`

Sources:

- [Anchuthengu — Wikipedia (Anjengo Fort / settlement history)](https://en.wikipedia.org/wiki/Anchuthengu)
- [Hidden 100: In the land of five coconut palms — The Hindu](https://www.thehindu.com/features/friday-review/history-and-culture/Hidden-100-In-the-land-of-five-coconut-palms/article13381929.ece)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Anchuthengu_Fort_2024_01.jpg — CC BY-SA 4.0, Athulvis. CONTEXT ONLY — Anjengo/Anchuthengu Fort ruins adjacent to village; not the Durga temple building. Use until a temple-specific Commons file is available.
- https://commons.wikimedia.org/wiki/File:Anchuthengu_Fort_2024_06.jpg — CC BY-SA 4.0, Athulvis. CONTEXT ONLY — Fort exterior; same caveat as above

Ritual overflow: THIN SOURCES: No dedicated official temple website, Devaswom page, or Commons photo clearly labelled as this Durga temple was found. Photo candidates below are Anchuthengu Fort (context), not the shrine itself — replace when a license-safe temple photo is available.

### Mannarsala Sree Nagaraja Temple

Seed slug: `mannarsala-sree-nagaraja-temple`

Sources:

- [Mannarasala Sree Nagaraja Temple — official general information / timings](https://mannarasala.org/devotee/general/)
- [Mannarasala official home](https://mannarasala.org/)
- [Mannarasala Temple — Wikipedia](https://en.wikipedia.org/wiki/Mannarasala_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mannarasala_temple.jpg — CC BY-SA 3.0, Vibitha vijay. Temple/grove exterior — only clear Commons hit in this pass; verify framing on file page

Ritual overflow: OPTIONAL: Official contact numbers on mannarasala.org. Deity string kept as sample "Vishnu" — consider Nagaraja alias in CMS.

### Thirunelli Maha Vishnu Temple

Seed slug: `thirunelli-maha-vishnu-temple`

Sources:

- [Thirunelli Maha Vishnu Temple — Kerala Tourism (Thalassery Heritage)](https://www.keralatourism.org/thalassery/tourist-circuits/pazhassi/tirunelli-temple)
- [Thirunelli Temple — Wikipedia](https://en.wikipedia.org/wiki/Thirunelli_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Thirunelli_temple.JPG — CC BY-SA 3.0, Vijayakumarblathur. Temple front/context
- https://commons.wikimedia.org/wiki/File:Thirunelli_Temple.JPG — CC0, RajeshUnuppally. Temple view; CC0
- https://commons.wikimedia.org/wiki/File:Wayanad_-_Thirunelli_Temple_Relief.jpg — CC BY-SA 4.0, Ingo Mehling. Stone relief detail

---

# KAN-64 / KAN-74 expansion (batch 17) — +10 additional Kerala temples

Research-backed **new** temples applied into `lib/data/sample_data.dart` under
[KAN-74](https://shradhaventuresltd.atlassian.net/browse/KAN-74) (Hybrid C).

These are **additional** rows — they do not replace or re-enrich the original
batch 1–3 Kerala temples.

## Hybrid C / schema lock

- Core Temple / Seed fields only (`name`, `state`, `city`, `deity`, `description`,
  `story`, `location`→`address`, `timings`, `specialities`, `latitude`, `longitude`,
  `imageUrl`, `images`).
- **`trip_planning` is research-JSON-only** — not added to the Dart model, sample
  data, or Seed writes.
- `sources`, `photo_candidates`, and `rituals_notes` stay out of Firestore; useful
  ritual tips were folded into `timings` / `story` / `specialities` free text where room.
- KAN-74 left cover **`imageUrl` empty**. KAN-77 Wave A fills Commons thumbs
  for all ten batch-17 temples. Do **not** invent Storage URLs.

## Verify before CMS / publish

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Vadakkunnathan Temple | `vadakkunnathan-temple` | Hindu-only entry commonly enforced; men typically mundu with bare upper body inside, women saree/churidar with dupatta — confirm live… |
| Sree Poornathrayeesa Temple | `sree-poornathrayeesa-temple` | Traditional Kerala dress expected; photography usually banned inside. Elephant-festival crowd and safety rules have been under Kerala… |
| Ambalappuzha Sri Krishna Temple | `ambalappuzha-sri-krishna-temple` | Traditional dress expected. Palpayasam: offline counter only per 2026 pilgrim notices — no invented online booking claims. Thin official… |
| Ettumanoor Mahadeva Temple | `ettumanoor-mahadeva-temple` | Contact on temple site includes ettumanoordevaswom@gmail.com — useful for festival-night crowd planning. Confirm Ezharaponnana midnight… |
| Chettikulangara Devi Temple | `chettikulangara-devi-temple` | THIN OFFICIAL CLOCK for ordinary days — timings labelled provisional. Photo coverage on Commons is festival-kuthira heavy rather than… |
| Kodungallur Bhagavathy Temple | `kodungallur-bhagavathy-temple` | THIN official English ordinary-day clock. Bharani is culturally intense — follow local advisories; not a casual photo-tourism event.… |
| Parassinikadavu Muthappan Temple | `parassinikadavu-muthappan-temple` | Accurate deity label is Muthappan (not simply Shiva or Vishnu alone). Theyyam pause mid-Oct–mid-Nov is critical trip planning.… |
| Thiruvalla Sreevallabha Temple | `thiruvalla-sreevallabha-temple` | Dress code typical of Kerala Vishnu temples; ask before photographing inside. Kathakali–puja calendar is seasonal — check local notice… |
| Chengannur Mahadeva Temple | `chengannur-mahadeva-temple` | THIN official English named-pooja clock. Thriputharattu closures are irregular — always verify same-week status. Treat fertility rite… |
| Kaviyoor Mahadeva Temple | `kaviyoor-mahadeva-temple` | THIN/conflicting official English clocks. Keep rock-cut cave temple as a separate optional heritage stop — not this doc’s primary sanctum. |

## Sources and photo candidates

### Vadakkunnathan Temple

Seed slug: `vadakkunnathan-temple` (research id `vadakkunnathan-temple`).

Sources:

- [Sree Wadakkunathan Temple — daily pooja (official-aligned)](https://sreewadakkunathantemple.org/daily_pooja)
- [Vadakkunnathan Temple — Wikipedia](https://en.wikipedia.org/wiki/Vadakkunnathan_Temple)
- [Kerala Tourism — Thrissur / Pooram context](https://www.keralatourism.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Vadakkumnathan_Temple.jpg — CC BY 3.0; Adarsh Padmanabhan
- https://commons.wikimedia.org/wiki/File:Vadakkunnathan_temple_at_night_-_December_2019.jpg — CC BY-SA 4.0; Ajay090

Ritual overflow (folded into timings where length allowed):

- Hindu-only entry commonly enforced; men typically mundu with bare upper body inside, women saree/churidar with dupatta — confirm live board. Children under one often restricted per secondary notices.

### Sree Poornathrayeesa Temple

Seed slug: `sree-poornathrayeesa-temple` (research id `sree-poornathrayeesa-temple`).

Sources:

- [Sree Poornathrayeesa Temple — official about](https://sreepoornathrayeesatemple.org/index.php/welcome/aboutUs)
- [Sree Poornathrayeesa Temple — Wikipedia](https://en.wikipedia.org/wiki/Sree_Poornathrayeesa_Temple)
- [Sahapedia — major festivals (secondary)](https://www.sahapedia.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sree_Poornathrayeesa_Temple.jpg — CC BY-SA 4.0; Ashok.tcr

Ritual overflow (folded into timings where length allowed):

- Traditional Kerala dress expected; photography usually banned inside. Elephant-festival crowd and safety rules have been under Kerala High Court scrutiny — follow current Devaswom advisories.

### Ambalappuzha Sri Krishna Temple

Seed slug: `ambalappuzha-sri-krishna-temple` (research id `ambalappuzha-sri-krishna-temple`).

Sources:

- [Ambalappuzha Temple — Wikipedia](https://en.wikipedia.org/wiki/Ambalappuzha_Temple)
- [Incredible India / Kerala Tourism context (secondary for hours)](https://www.incredibleindia.gov.in/)
- [Kerala Tourism](https://www.keralatourism.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:009232022_Ambalaphuzha_Shri_Krishna_Swamy_Temple_Kerala_08.jpg — CC0; Ms Sarah Welch

Ritual overflow (folded into timings where length allowed):

- Traditional dress expected. Palpayasam: offline counter only per 2026 pilgrim notices — no invented online booking claims. Thin official English timetable — re-check Devaswom/local board.

### Ettumanoor Mahadeva Temple

Seed slug: `ettumanoor-mahadeva-temple` (research id `ettumanoor-mahadeva-temple`).

Sources:

- [Ettumanoor Mahadeva Temple — puja timings](https://ettumanoormahadevatemple.com/puja/)
- [Kerala Tourism — Ezhara Ponnana festival](https://www.keralatourism.org/event/ezhara-ponnana/101/)
- [Ettumanoor Mahadevar Temple — Wikipedia](https://en.wikipedia.org/wiki/Ettumanoor_Mahadevar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ettumanoor_Temple_Front_Arch.JPG — CC BY-SA 3.0; Ranjithsiji
- https://commons.wikimedia.org/wiki/File:Shiva_Nataraja_at_Hindu_Mahadeva_Temple_entrance,_Ettumanoor_Kerala.jpg — CC BY-SA 4.0; Ms Sarah Welch

Ritual overflow (folded into timings where length allowed):

- Contact on temple site includes ettumanoordevaswom@gmail.com — useful for festival-night crowd planning. Confirm Ezharaponnana midnight opening annually.

### Chettikulangara Devi Temple

Seed slug: `chettikulangara-devi-temple` (research id `chettikulangara-devi-temple`).

Sources:

- [Chettikulangara Devi Temple — major festivals (official site)](https://www.chettikulangara.org/chettikulangaradevitemple/major-festivals.php)
- [Kerala Tourism — Chettikulangara Bhagavathy Temple](https://www.keralatourism.org/destination/chettikulangara-bhagavathy-temple-mavelikkara/68/)
- [Chettikulangara Devi Temple — Wikipedia](https://en.wikipedia.org/wiki/Chettikulangara_Devi_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kuthira.JPG — CC BY-SA 3.0; Hellblazzer

Ritual overflow (folded into timings where length allowed):

- THIN OFFICIAL CLOCK for ordinary days — timings labelled provisional. Photo coverage on Commons is festival-kuthira heavy rather than main gopuram exteriors.

### Kodungallur Bhagavathy Temple

Seed slug: `kodungallur-bhagavathy-temple` (research id `kodungallur-bhagavathy-temple`).

Sources:

- [Kerala Tourism — Kodungalloor Bharani / Kaavutheendal](https://www.keralatourism.org/event/kodungalloor-bharani/56/)
- [Kodungallur Bhagavathy Temple — Wikipedia](https://en.wikipedia.org/wiki/Kodungallur_Bhagavathy_Temple)
- [Commons category — Kodungallur Bhagavathy Temple](https://commons.wikimedia.org/wiki/Category:Kodungallur_Bhagavathy_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:0092122_Shri_Kurumbha_Bhagavathi_temple,_Chera_dynasty,_Kodungallur_Kerala_026.jpg — CC0; Ms Sarah Welch

Ritual overflow (folded into timings where length allowed):

- THIN official English ordinary-day clock. Bharani is culturally intense — follow local advisories; not a casual photo-tourism event. Photo candidate is verified Commons temple exterior (Ms Sarah Welch CC0).

### Parassinikadavu Muthappan Temple

Seed slug: `parassinikadavu-muthappan-temple` (research id `parassinikadavu-muthappan-temple`).

Sources:

- [Parassinikadavu Muthappan Temple — Wikipedia](https://en.wikipedia.org/wiki/Parassinikadavu_Muthappan_Temple)
- [Kerala Tourism — Theyyam / Kannur context](https://www.keralatourism.org/)
- [Temples of Kerala — Parassinikadavu page (secondary)](https://templesofkerala.org/kannur/parassinikadavutemple.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Parassini_Madappura_Sree_MuthappanTemple.jpg — CC BY 3.0; Dexsolutions

Ritual overflow (folded into timings where length allowed):

- Accurate deity label is Muthappan (not simply Shiva or Vishnu alone). Theyyam pause mid-Oct–mid-Nov is critical trip planning. Photography rules during performance vary — ask locally.

### Thiruvalla Sreevallabha Temple

Seed slug: `thiruvalla-sreevallabha-temple` (research id `thiruvalla-sreevallabha-temple`).

Sources:

- [Sreevallabha Temple — Wikipedia](https://en.wikipedia.org/wiki/Sreevallabha_Temple)
- [Commons category — Sreevallabha Temple](https://commons.wikimedia.org/wiki/Category:Sreevallabha_Temple)
- [Kerala Tourism](https://www.keralatourism.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:009242022_Shri_Vallabha_temple,_Thiruvalla_Kerala_145.jpg — CC0; Ms Sarah Welch

Ritual overflow (folded into timings where length allowed):

- Dress code typical of Kerala Vishnu temples; ask before photographing inside. Kathakali–puja calendar is seasonal — check local notice boards.

### Chengannur Mahadeva Temple

Seed slug: `chengannur-mahadeva-temple` (research id `chengannur-mahadeva-temple`).

Sources:

- [Chengannur Mahadeva Temple — Wikipedia](https://en.wikipedia.org/wiki/Chengannur_Mahadeva_Temple)
- [Commons category — Chengannur Mahadeva temple](https://commons.wikimedia.org/wiki/Category:Chengannur_Mahadeva_temple)
- [Kerala Tourism](https://www.keralatourism.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_156.jpg — CC0; Ms Sarah Welch

Ritual overflow (folded into timings where length allowed):

- THIN official English named-pooja clock. Thriputharattu closures are irregular — always verify same-week status. Treat fertility rite with cultural respect.

### Kaviyoor Mahadeva Temple

Seed slug: `kaviyoor-mahadeva-temple` (research id `kaviyoor-mahadeva-temple`).

Sources:

- [Kaviyoor Mahadevar Temple — Wikipedia](https://en.wikipedia.org/wiki/Kaviyoor_Mahadevar_Temple)
- [Commons category — Kaviyoor Mahadevar Temple](https://commons.wikimedia.org/wiki/Category:Kaviyoor_Mahadevar_Temple)
- [Temple site (if reachable) — thrikaviyoormahadevartemple.com](http://www.thrikaviyoormahadevartemple.com)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:009242022_Kaviyur_Mahadeva_Temple_Kerala_004.jpg — CC0; Ms Sarah Welch
- https://commons.wikimedia.org/wiki/File:Kaviyoor_mahadeva_temple_01.jpg — CC BY-SA 4.0; Dvellakat

Ritual overflow (folded into timings where length allowed):

- THIN/conflicting official English clocks. Keep rock-cut cave temple as a separate optional heritage stop — not this doc’s primary sanctum.
