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

---

# KAN-64 / KAN-74 expansion (batch 16) — +10 additional Tamil Nadu temples

Research-backed **new** temples applied into `lib/data/sample_data.dart` under
[KAN-74](https://shradhaventuresltd.atlassian.net/browse/KAN-74) (Hybrid C).

These are **additional** rows — they do not replace or re-enrich the original
batch 1–3 Tamil Nadu temples.

## Hybrid C / schema lock

- Core Temple / Seed fields only (`name`, `state`, `city`, `deity`, `description`,
  `story`, `location`→`address`, `timings`, `specialities`, `latitude`, `longitude`,
  `imageUrl`, `images`).
- **`trip_planning` is research-JSON-only** — not added to the Dart model, sample
  data, or Seed writes.
- `sources`, `photo_candidates`, and `rituals_notes` stay out of Firestore; useful
  ritual tips were folded into `timings` / `story` / `specialities` free text where room.
- Cover **`imageUrl` is empty** and `images` is `[]` (photo-pending honesty). Do **not**
  invent picsum or Storage URLs for this wave.

## Verify before CMS / publish

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Sri Ranganathaswamy Temple | `sri-ranganathaswamy-temple` | Dress code for inner prakarams is traditionally strict (dhoti/saree norms commonly enforced). Free and paid/VIP darshan options appear… |
| Dhandayuthapani Swamy Temple | `dhandayuthapani-swamy-temple` | Hill climb involves many steps; elders and differently abled pilgrims should check winch/ropeway and special queues. Hair-tonsure… |
| Subramanya Swamy Temple | `subramanya-swamy-temple` | Seashore location — monsoon swell and crowd control can affect access paths. Follow Devasthanam notices for Naazhi Kinaru / special… |
| Swamimalai Murugan Temple | `swamimalai-murugan-temple` | Carry water for the climb; footwear rules apply on the hill. Thursday diamond-Vel darshan is a popular local highlight — expect slightly… |
| Jambukeswarar Temple | `jambukeswarar-temple` | Photographing inside sanctum areas is often restricted — follow posted rules. Midday close Mon–Thu is easy to miss if relying on… |
| Thyagaraja Temple | `thyagaraja-temple` | Car-festival days bring extreme crowds and road closures — arrive early and follow police/temple routing. Feet-darshan days are limited;… |
| Nellaiappar Temple | `nellaiappar-temple` | Plan time for both sanctums; paid special-entry queues may be available. Musical pillars are a heritage highlight — follow staff… |
| Kanyakumari Bhagavathi Amman Temple | `kanyakumari-bhagavathi-amman-temple` | Inner temple photography is typically restricted. Tourist crowds around the cape do not equal temple entry rules — follow HR&CE dress… |
| Vaitheeswaran Koil | `vaitheeswaran-koil` | THIN SOURCES on full official English pooja clock — do not treat aggregator times as definitive. Oil offerings and Angaraka-related… |
| Tiruttani Murugan Temple | `tiruttani-murugan-temple` | Step climb is significant in heat — carry water and start early. Road/jeep access patterns to higher points can change; follow on-site… |

## Sources and photo candidates

### Sri Ranganathaswamy Temple

Seed slug: `sri-ranganathaswamy-temple` (research id `sri-ranganathaswamy-temple-srirangam`).

Sources:

- [Arulmigu Aranganatha Swamy Temple, Srirangam — TN HR&CE (official)](https://srirangamranganathar.hrce.tn.gov.in/)
- [HR&CE pooja / nadai info (tid=25700)](https://srirangamranganathar.hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=25700)
- [Sri Ranganathaswamy Temple, Srirangam — UNESCO Tentative List](https://whc.unesco.org/en/tentativelists/5894/)
- [Ranganathaswamy Temple, Srirangam — Wikipedia](https://en.wikipedia.org/wiki/Ranganathaswamy_Temple,_Srirangam)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Srirangam-Rajagopuram-1.jpg — CC BY-SA 4.0; N. Vivekananthamoorthy

Ritual overflow (folded into timings where length allowed):

- Dress code for inner prakarams is traditionally strict (dhoti/saree norms commonly enforced). Free and paid/VIP darshan options appear on the HR&CE ticketing flow — prefer official portal over street agents. Annadhanam schemes operate under HR&CE; confirm current counters on site.

### Dhandayuthapani Swamy Temple

Seed slug: `dhandayuthapani-swamy-temple` (research id `dhandayuthapani-swamy-temple-palani`).

Sources:

- [Arulmigu Dhandayuthapaniswamy Temple, Palani — TN HR&CE (official)](https://palanimurugan.hrce.tn.gov.in/)
- [HR&CE pooja / nadai info (tid=32203)](https://palanimurugan.hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=32203)
- [Dhandayuthapani Swamy Temple — Wikipedia](https://en.wikipedia.org/wiki/Palani_Murugan_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Arulmigu_Dhandayuthapani_Swamy_Temple_in_Palany_hill.jpg — CC BY-SA 4.0; Challiyan
- https://commons.wikimedia.org/wiki/File:Palani_Murugan_Hill_Temple.jpg — CC BY-SA 4.0; Spsarvana

Ritual overflow (folded into timings where length allowed):

- Hill climb involves many steps; elders and differently abled pilgrims should check winch/ropeway and special queues. Hair-tonsure facilities are common — follow hygiene and waste rules posted on site.

### Subramanya Swamy Temple

Seed slug: `subramanya-swamy-temple` (research id `subramanya-swamy-temple-thiruchendur`).

Sources:

- [Arulmigu Subramania Swamy Temple, Tiruchendur — TN HR&CE (official)](https://tiruchendurmurugan.hrce.tn.gov.in/)
- [HR&CE pooja / nadai info (tid=38271)](https://tiruchendurmurugan.hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=38271)
- [Tiruchendur Devasthanam — Puja Timings](https://tiruchendur.org/puja-timings/)
- [Subramaniya Swamy Temple, Tiruchendur — Wikipedia](https://en.wikipedia.org/wiki/Subramaniya_Swamy_Temple,_Tiruchendur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Arulmigu_Subramaniya_Swamy_Temple,_Tiruchendur.jpg — CC BY-SA 4.0; Gayathri Dakshinamoorthy

Ritual overflow (folded into timings where length allowed):

- Seashore location — monsoon swell and crowd control can affect access paths. Follow Devasthanam notices for Naazhi Kinaru / special abhishekam queues.

### Swamimalai Murugan Temple

Seed slug: `swamimalai-murugan-temple` (research id `swamimalai-murugan-temple`).

Sources:

- [Arulmigu Swaminatha Swamy Temple, Swamimalai — TN HR&CE (official)](https://swamimalaiswaminathar.hrce.tn.gov.in/hrcehome/index_temple.php?tid=18002)
- [Swaminatha Swamy Temple — Wikipedia](https://en.wikipedia.org/wiki/Swaminatha_Swamy_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Swamimalai_Murugan_Temple.jpg — CC BY-SA 3.0; Ravichandar84

Ritual overflow (folded into timings where length allowed):

- Carry water for the climb; footwear rules apply on the hill. Thursday diamond-Vel darshan is a popular local highlight — expect slightly longer queues.

### Jambukeswarar Temple

Seed slug: `jambukeswarar-temple` (research id `jambukeswarar-temple-thiruvanaikaval`).

Sources:

- [Arulmigu Jambukeswarar Akilandeswari Temple — TN HR&CE (official)](https://thiruvanaikavaljambukeswarar.hrce.tn.gov.in/hrcehome/index_temple.php?tid=25706&action=pooja_info)
- [HR&CE pooja info (tid=25706)](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=25706)
- [Jambukeswarar Temple, Thiruvanaikaval — Wikipedia](https://en.wikipedia.org/wiki/Jambukeswarar_Temple,_Thiruvanaikaval)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Jambukeswarar_Temple_surroundings,_Thiruvanaikaval_ttkcvrvb122k23pxl_(52).jpg — CC BY-SA 4.0; Vinayaraj

Ritual overflow (folded into timings where length allowed):

- Photographing inside sanctum areas is often restricted — follow posted rules. Midday close Mon–Thu is easy to miss if relying on outdated aggregator clocks that still say 5:30–8:30.

### Thyagaraja Temple

Seed slug: `thyagaraja-temple` (research id `thyagaraja-temple-tiruvarur`).

Sources:

- [Arulmigu Thiyagaraswamy Temple, Thiruvarur — TN HR&CE (official)](https://hrce.tn.gov.in/hrcehome/index_temple.php?tid=14254)
- [HR&CE pooja info (tid=14254)](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=14254)
- [Thyagaraja Temple, Tiruvarur — Wikipedia](https://en.wikipedia.org/wiki/Thyagaraja_Temple,_Tiruvarur)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Tiruvarur_temple,_tank,_car.jpg — CC BY-SA 3.0; SriniG

Ritual overflow (folded into timings where length allowed):

- Car-festival days bring extreme crowds and road closures — arrive early and follow police/temple routing. Feet-darshan days are limited; do not assume daily access.

### Nellaiappar Temple

Seed slug: `nellaiappar-temple` (research id `nellaiappar-temple-tirunelveli`).

Sources:

- [Arulmigu Nellaiyappar Kanthimathi Amman Temple — TN HR&CE (official)](https://tvlnellaiapparkanthimathiamman.hrce.tn.gov.in/)
- [HR&CE pooja info (tid=37881)](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=37881)
- [Nellaiappar Temple — Wikipedia](https://en.wikipedia.org/wiki/Nellaiappar_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Thamira_saba-Nellaiappar_Temple.jpg — CC BY-SA 4.0; Booradleyp1

Ritual overflow (folded into timings where length allowed):

- Plan time for both sanctums; paid special-entry queues may be available. Musical pillars are a heritage highlight — follow staff guidance on touching.

### Kanyakumari Bhagavathi Amman Temple

Seed slug: `kanyakumari-bhagavathi-amman-temple` (research id `kanyakumari-bhagavathi-amman-temple`).

Sources:

- [Arulmigu Bagavathiamman Temple, Kanyakumari — TN HR&CE (official)](https://hrce.tn.gov.in/hrcehome/index_temple.php?tid=38360)
- [Tamil Nadu Tourism info — Bhagavathy Amman Temple](https://tamilnadutourisminfo.com/bhagavathy-amman-temple-kanyakumari/)
- [Kanyakumari — Wikipedia (temple context)](https://en.wikipedia.org/wiki/Kanniyakumari)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:The_Kanyakumari_temple.jpg — CC BY 4.0; Prashant Kharote

Ritual overflow (folded into timings where length allowed):

- Inner temple photography is typically restricted. Tourist crowds around the cape do not equal temple entry rules — follow HR&CE dress and queue notices.

### Vaitheeswaran Koil

Seed slug: `vaitheeswaran-koil` (research id `vaitheeswaran-koil`).

Sources:

- [Vaitheeswaran Koil — Wikipedia](https://en.wikipedia.org/wiki/Vaitheeswaran_Kovil)
- [TN HR&CE home (search temple services)](https://hrce.tn.gov.in/)
- [Tamil Nadu Tourism](https://www.tamilnadutourism.tn.gov.in/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Vaitheeswaran_Koil.JPG — CC BY-SA 3.0; வணக்கம்

Ritual overflow (folded into timings where length allowed):

- THIN SOURCES on full official English pooja clock — do not treat aggregator times as definitive. Oil offerings and Angaraka-related practices follow local priest guidance; keep expectations modest on queue times Tuesdays.

### Tiruttani Murugan Temple

Seed slug: `tiruttani-murugan-temple` (research id `tiruttani-murugan-temple`).

Sources:

- [Arulmigu Subramanyaswamy Temple, Tiruttani — TN HR&CE (official)](https://tiruttanimurugan.hrce.tn.gov.in/hrcehome/index_temple.php?tid=1506)
- [HR&CE pooja info (tid=1506)](https://hrce.tn.gov.in/hrcehome/index_temple.php?action=pooja_info&tid=1506)
- [Tiruttani — Wikipedia (temple town context)](https://en.wikipedia.org/wiki/Tiruttani)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Thiruthani_Murugan_Temple.jpg — CC BY-SA 4.0; Srithern
- https://commons.wikimedia.org/wiki/File:Arulmigu_Subramaniya_Swami_Temple,_Tiruttani_2.jpg — CC BY-SA 4.0; Muralikrishna m

Ritual overflow (folded into timings where length allowed):

- Step climb is significant in heat — carry water and start early. Road/jeep access patterns to higher points can change; follow on-site instructions.
