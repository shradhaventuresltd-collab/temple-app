# Tamil Nadu sample enrichment (batch 1)

Research-backed copy for the **10 existing Tamil Nadu temples** in
`lib/data/sample_data.dart`. Names and slugs are unchanged so debug **Seed**
still targets the same Firestore documents (`templeDocumentId(name)`).

This file is **not** written to Firestore. Use it when reviewing CMS publish
and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer HR&CE / ASI / official temple sites
over tourist aggregators before pushing notifications or store copy.

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

No `pooja_schedule` / `festivals` collections were added.

## Images

Bundled covers remain `https://picsum.photos/seed/…` placeholders. Commons
`photo_candidates` below are file **pages** for later manual download,
attribution, upload to `temples/{docId}/…`, then CMS `images` / `imageUrl`.
Do **not** paste these Commons URLs into sample data as if they were Storage
paths.

## Verify before CMS / publish

Festival days often override ordinary hours (HR&CE pages say so). Re-check
near travel dates.

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Meenakshi Amman Temple | `meenakshi-amman-temple` | Chithirai can change pooja/close times — confirm HR&CE. |
| Brihadeeswarar Temple | `brihadeeswarar-temple` | Named pooja slots are **secondary-sourced** (Incredible India / visitor guides). Confirm on site. |
| Kapaleeshwarar Temple | `kapaleeshwarar-temple` | HR&CE pooja list; Rahu kala abhishekams scheduled separately. |
| Ramanathaswamy Temple | `ramanathaswamy-temple` | Evening close **8:00 PM** on HR&CE vs older 9:00 PM tourist listings — prefer HR&CE. |
| Murugan Temple, Thirupparankundram | `murugan-temple-thirupparankundram` | Festival schedules may differ from the named HR&CE list. |
| Shore Temple | `shore-temple` | **ASI / UNESCO heritage-first**, ticketed monument — not a typical HR&CE living-kovil clock. |
| Nataraja Temple | `nataraja-temple` | Prefer official `chidambaramnataraja.org` 5:00 PM evening opening over 4:30 PM tourist listings. |
| Ekambaranathar Temple | `ekambaranathar-temple` | Gate hours vs six-kala **ritual clock** conflict; named slots are secondary-sourced. Confirm HR&CE tid=1816. |
| Arunachaleswarar Temple | `arunachaleswarar-temple` | Public darshan windows **conflict across sources**. VERIFY on https://annamalaiyar.hrce.tn.gov.in/ before any push notification. |
| Sarangapani Temple | `sarangapani-temple` | Ritual clock and public gate hours are not always identical; confirm locally. |

Coordinates are approximate map pins (Wikipedia / OSM / Commons geotags).

## Ritual overflow (no schema field)

Visitor tips that did not fit `timings` / `story` / `specialities`:

- **Meenakshi:** Palliyarai evening procession of Sundareswarar toward Meenakshi’s shrine; phone/camera rules and modest dress are strictly enforced.
- **Ramanathaswamy:** Typical sequence Agni Theertham → 22 wells → sanctum; change facilities exist; crowding peaks before noon.
- **Shore Temple:** Flag as ASI heritage-first in UX (ticketed; limited active ritual calendar).
- **Ekambaranathar:** Sand linga — abhishekam to the pedestal; no separate Amman shrine inside (Kamakshi nearby is the traditional consort temple).
- **Arunachaleswarar:** Structured Deepam object (Bharani vs Maha Deepam) and Girivalam crowd advisories still belong in a future festival field, not invented precision here.

## Sources and photo candidates

### Meenakshi Amman Temple

Sources:

- [Arulmigu Meenakshi Sundaraswarar Temple — TN HR&CE](https://maduraimeenakshi.hrce.tn.gov.in/)
- [HR&CE pooja info (tid=31962)](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=31962)
- [Meenakshi Temple — Wikipedia](https://en.wikipedia.org/wiki/Meenakshi_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Meenakshi_Amman_Temple,_Madurai.jpg — CC BY-SA 4.0, DCSJ / Setu Jain
- https://commons.wikimedia.org/wiki/File:Golden_Lily_Pond_and_South_Gopuram_at_Meenakshi_Amman_Temple_,_Madurai.jpg — CC BY-SA 4.0, N. Vivekananthamoorthy (filename has a trailing space before the comma — use the exact Commons URL)

### Brihadeeswarar Temple

Sources:

- [Great Living Chola Temples — UNESCO WHC](https://whc.unesco.org/en/list/250/)
- [Brihadishvara Temple — Encyclopaedia Britannica](https://www.britannica.com/place/Brihadishvara-temple)
- [Brihadeeswarar Temple — Incredible India](https://www.incredibleindia.gov.in/en/tamil-nadu/thanjavur/brihadeeswarar-temple)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Brihadeeswara_Temple_-_Thanjavur.jpg — CC BY-SA 4.0, Jayadev Sai Challa

### Kapaleeshwarar Temple

Sources:

- [Arulmigu Kapaleeswarar Temple — TN HR&CE pooja info](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=1)
- [Kapaleeshwarar Temple — Wikipedia](https://en.wikipedia.org/wiki/Kapaleeshwarar_Temple)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Kapaleeshwarar_Temple,_Mylapore.JPG — CC BY-SA 3.0, Roehan Rengadurai

### Ramanathaswamy Temple

Sources:

- [Arulmigu Ramanathaswamy Temple — TN HR&CE](https://rameswaramramanathar.hrce.tn.gov.in/hrcehome/index_temple.php?action=temple_eo&tid=35671)
- [HR&CE pooja/timings info](https://rameswaramramanathar.hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=35671)
- [Ramanathaswamy Temple — Wikipedia](https://en.wikipedia.org/wiki/Ramanathaswamy_Temple)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Ramanathaswamy_temple_corridor.JPG — CC BY-SA 3.0, Vensatry

### Murugan Temple, Thirupparankundram

Sources:

- [Arulmigu Subramaniyaswamy Temple — TN HR&CE pooja info](https://thiruparankundrammurugan.hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=31985)
- [Tirupparankunram Murugan Temple — Wikipedia](https://en.wikipedia.org/wiki/Tirupparankunram_Murugan_Temple)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Tirupparamkunram_Murugan_Temple.JPG — CC BY-SA 3.0, Kramasundar

### Shore Temple

Sources:

- [Shore Temple — Wikipedia](https://en.wikipedia.org/wiki/Shore_Temple)
- [Group of Monuments at Mahabalipuram — UNESCO](https://whc.unesco.org/en/list/249/)
- [Shore Temple — Incredible India](https://www.incredibleindia.gov.in/en/tamil-nadu/mamallapuram/shore-temple)
- [ASI — World Heritage Mahabalipuram](https://asi.nic.in/pages/WorldHeritageMahabalipuram)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Shore_Temple_Mahabalipuram_Tamil-Nadu_India.jpg — CC BY-SA 4.0, N. Vivekananthamoorthy

### Nataraja Temple

Sources:

- [Chidambaram Temple — official darshan times](http://www.chidambaramnataraja.org/darshan_time.html)
- [Chidambaram Temple — official rituals page](http://chidambaramnataraja.org/rituals.html)
- [Nataraja Temple, Chidambaram — Wikipedia](https://en.wikipedia.org/wiki/Nataraja_Temple,_Chidambaram)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Chidambaram_Nataraja_temple_East_Gopuram.JPG — CC BY-SA 3.0 (also GFDL), BishkekRocks

### Ekambaranathar Temple

Sources:

- [Arulmigu Ekambaranathar Temple — TN HR&CE](https://hrce.tn.gov.in/hrcehome/index_temple.php?tid=1816)
- [Ekambareswarar Temple (Kanchipuram) — Wikipedia](https://en.wikipedia.org/wiki/Ekambareswarar_Temple_(Kanchipuram))

Photo candidates:

- https://commons.wikimedia.org/wiki/File:The_Raja_Gopuram_(_Temple_Tower_)_of_Ekambareshwara_Temple,_Kanchipuram.jpg — CC BY-SA 4.0, Krishna Chaitanya Chandolu

### Arunachaleswarar Temple

Sources:

- [Arulmigu Arunachaleswarar Temple — TN HR&CE](https://annamalaiyar.hrce.tn.gov.in/)
- [Arunachalesvara Temple — Wikipedia](https://en.wikipedia.org/wiki/Arunachalesvara_Temple)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Thiruvannamalai,_Arunachalesvara_Temple,_Annamalaiyar_Temple,_India.jpg — CC BY 4.0, Vyacheslav Argenberg

### Sarangapani Temple

Sources:

- [Sri Sarangapani Temple — official history](https://www.sarangapanitemple.org/Temple%20History.html)
- [Sarangapani Temple pooja timings](https://sarangapanitemple.org/Poojas.html)
- [Sarangapani temple, Kumbakonam — Wikipedia](https://en.wikipedia.org/wiki/Sarangapani_temple,_Kumbakonam)

Photo candidates:

- https://commons.wikimedia.org/wiki/File:Sarangapani_Temple_-_Kumbakonam.jpg — CC BY 2.0, B Balaji (via Flickr)
