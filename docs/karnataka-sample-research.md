# Karnataka sample enrichment (batch 3)

Research-backed copy for the **10 existing Karnataka temples** in
`lib/data/sample_data.dart`. Names and slugs are unchanged so debug **Seed**
still targets the same Firestore documents (`templeDocumentId(name)`).

This file is **not** written to Firestore. Use it when reviewing CMS publish
and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Karnataka HRCE ITMS / official matha
or kshetra sites over tourist aggregators. Re-check hours near Navaratri /
Dasara, Paryaya, Shivaratri, and booked sevas (e.g. Kukke Sarpa Samskara).

## Field mapping (Dart model ↔ Firestore)

| Research / sample Dart | Firestore (Seed + Admin CMS) |
| --- | --- |
| `name`, `state`, `city`, `deity` | same |
| `location` | `address` (`Temple.location`; `fromMap` also accepts legacy `location`) |
| `description`, `story`, `timings` | same |
| `specialities` (`List<String>`) | same |
| `latitude`, `longitude` | same |
| `imageUrl` / `images` | same — KAN-77 Wave B uses Commons `downloaded_url` thumbs from `tools/photo-packs/`; do not invent Storage URLs |
| `sources`, `photo_candidates`, `rituals_notes` | **not in the Temple schema** — documented here only |

No `pooja_schedule` / `festivals` collections were added.

## Images

**KAN-77 Wave B:** all 20 Karnataka sample temples (this original 10 and the
batch-18 ten) use Wikimedia Commons 1280px `downloaded_url` thumbs for
`imageUrl` and `images`. Files and attribution live in
`tools/photo-packs/<slug>/`. Those URLs are Commons thumbs, not Firebase
Storage. Do **not** invent `storage.googleapis.com` URLs. Sanu uploads with
`scripts/upload_research_pack.js` (runbook: `tools/photo-packs/README.md`).

Seed ids are `templeDocumentId(name)`. Nineteen pack folders match that id.
**Cheluvanarayana Swamy Temple** does not: the sample name slugs to
`cheluvanarayana-swamy-temple`, while the research folder is
`cheluvanarayana-swamy-temple-melukote`. The upload script writes
`temples/cheluvanarayana-swamy-temple/`.

The Commons file-page lists below are the earlier research pass. The pack
`manifest.json` is the set actually bundled.

Reviewer correction (wrong-site frames removed from the packs): Bengaluru
Banashankari no longer uses the Badami / Cholachagudda sweep. Those slots now
use the Bengaluru candidates listed below (`Sri_Banashankari_Temple,_Bengaluru_(2024)`).
Talakaveri dropped Brihadeeswara and Srirangam and added the Talakaveri
candidates below. Gokarna dropped the Kathmandu Gokarneshwor file and added
the Gokarna gopura and entrance candidates below.

Photo coverage is thinner for **Dharmasthala** (gateway-only Commons candidate)
and **Nanjangud** (single modest Commons file).

## Verify before CMS / publish

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Sri Krishna Matha (Udupi) | `sri-krishna-matha-udupi` | Public clocks **vary by serving Paryaya matha**. Confirm on the notice board / serving matha site. 2026–2028 term associated with Shiroor Matha after January 2026 Paryaya. |
| Sri Manjunatha Temple, Dharmasthala | `sri-manjunatha-temple-dharmasthala` | Prefer official `shridharmasthala.org/temple-routine`. Jain Heggade administration + Vaishnava priests. Commons photo is gateway-only. |
| Kukke Subramanya Temple | `kukke-subramanya-temple` | Prefer HRCE ITMS tid=21 (open 6:30 AM–1:30 PM and 3:30 PM–9:00 PM) over the sample evening 4:00–8:30 PM. Book Sarpa Samskara via ITMS. |
| Sringeri Sharada Peetham | `sringeri-sharada-peetham` | Official sringeri.net Sharadamba windows match the sample envelope; other shrines and Jagadguru camps differ. |
| Kollur Mookambika Temple | `kollur-mookambika-temple` | Prefer HRCE ITMS tid=62 (5:00 AM–1:30 PM, 3:00 PM–9:00 PM) over the later sample open/close. |
| Mahabaleshwar Temple, Gokarna | `mahabaleshwar-temple-gokarna` | **No stable official minute grid.** Karnataka Tourism envelope matches the sample; Sparsha Darshan / Atmalinga is not a canonical Jyotirlinga. |
| Chamundeshwari Temple | `chamundeshwari-temple` | Official three-window day matches the sample; Fridays shift morning abhisheka earlier. Dasara queues change. |
| Virupaksha Temple | `virupaksha-temple` | Living temple inside UNESCO Hampi; **less official minute grid** than HRCE sites. Confirm locally; festival/chariot days override. |
| Srikanteshwara Temple, Nanjangud | `srikanteshwara-temple-nanjangud` | HRCE ITMS tid=7 matches the sample envelope. Named abhisheka markers are secondary; thinner Commons coverage. |
| ISKCON Temple, Bangalore | `iskcon-temple-bangalore` | This entry is **Rajajinagar / Hare Krishna Hill**, not the Kanakapura Road campus. Prefer iskconbangalore.org; Akshaya Patra meal counts are order-of-magnitude. |

Coordinates are approximate map pins retained from `sample_data.dart`.

## Ritual overflow (no schema field)

Visitor tips that did not fit `timings` / `story` / `specialities`:

- **Udupi:** Men often remove upper garments near inner areas; photography typically limited to exterior / kindi views; seva booking via the serving Paryaya matha.
- **Dharmasthala:** Guest-house booking only via official shridharmasthala.org — the home page flags fake WhatsApp/room-booking scams.
- **Kukke:** Men remove upper garments for darshan per HRCE notice; Sarpa Samskara is multi-day, not walk-in darshan.
- **Gokarna:** Start at adjacent Maha Ganapati; no photography inside; vehicles stop short of Car Street.
- **ISKCON Rajajinagar:** Free lunch prasadam windows, paid parking, wheelchair/lift via reception; no interior photography.

## Sources and photo candidates

### Sri Krishna Matha (Udupi)

Seed slug: `sri-krishna-matha-udupi`

Sources:

- [Udupi Sri Krishna Matha — Wikipedia](https://en.wikipedia.org/wiki/Udupi_Sri_Krishna_Matha)
- [Udupi Krishna Temple timings / pooja order (secondary; confirm vs serving matha)](https://gokshetra.com/udupi-krishna-temple-timings/)
- [Karnataka Tourism / visitor context (cross-check)](https://www.karnatakatourism.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Udupi_Sri_Krishna_Matha_Temple.jpg — CC BY-SA 2.0, Ashok Prabhakaran. Car Street / matha exterior; Flickr-reviewed Commons file

Ritual overflow: OPTIONAL CMS: men often remove upper garments near inner areas; photography typically limited to exterior / kindi views; seva booking only via serving Paryaya matha portal.

### Sri Manjunatha Temple, Dharmasthala

Seed slug: `sri-manjunatha-temple-dharmasthala`

Sources:

- [Shri Kshetra Dharmasthala — official portal](https://www.shridharmasthala.org/)
- [Temple Routine — official darshan/pooja schedule](https://www.shridharmasthala.org/temple-routine/)
- [Lord Bahubali Statue — official page](https://www.shridharmasthala.org/lord-bahubali-statue/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Gateway_of_Dharmasthala.jpg — CC BY-SA 3.0, Gnanapiti. Temple-town gateway context; older low-res transfer from en.wikipedia

Ritual overflow: OPTIONAL CMS: guest-house booking only via official www.shridharmasthala.org — warn users about fake WhatsApp/room-booking scams flagged on the official home page.

### Kukke Subramanya Temple

Seed slug: `kukke-subramanya-temple`

Sources:

- [Kukke Shree Subrahmanya — Karnataka HRCE ITMS (tid=21)](https://itms.kar.nic.in/hrcehome/index_temple.php?tid=21)
- [HRCE pooja / opening info (tid=21)](https://itms.kar.nic.in/hrcehome/index_temple.php?action=pooja_info&tid=21)
- [Kukke Subramanya Temple — Wikipedia](https://en.wikipedia.org/wiki/Kukke_Subramanya_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Subramanya_temple.jpg — CC BY-SA 2.5, Shiva shankar / Shivanayak. Kukke Subramanya temple elevation; verified Commons license

Ritual overflow: OPTIONAL CMS: men remove upper garments for darshan per HRCE notice; book Sarpa Samskara well in advance; general darshan remains free/unbooked.

### Sringeri Sharada Peetham

Seed slug: `sringeri-sharada-peetham`

Sources:

- [Temple Timings — Sri Sringeri Sharada Peetham (official)](https://www.sringeri.net/pilgrim-info/temple-timings)
- [Sri Vidyashankara — official temple page](https://www.sringeri.net/temples/sri-vidyashankara)
- [Sringeri Sharada Peetham — Wikipedia](https://en.wikipedia.org/wiki/Sringeri_Sharada_Peetham)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sringeri_Sharada_Peetham,_Sringeri,_Karnataka,_India_(2024).jpg — CC BY-SA 4.0, Sangeetha N shet. 2024 peetham/temple view; verified Commons license

### Kollur Mookambika Temple

Seed slug: `kollur-mookambika-temple`

Sources:

- [Sri Mookambika Temple Kollur — Karnataka HRCE ITMS (tid=62)](https://itms.kar.nic.in/hrcehome/index_temple.php?tid=62)
- [HRCE pooja info (tid=62)](https://itms.kar.nic.in/hrcehome/index_temple.php?action=pooja_info&tid=62)
- [Darshana Timing — Kollur Mookambika (temple site)](https://kollurmookambikatemple.org/index.php/darshana-timing/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sri_Mookambika_Temple,_Kollur.jpg — CC BY-SA 3.0, Yogesa. Temple exterior; verified Commons license

### Mahabaleshwar Temple, Gokarna

Seed slug: `mahabaleshwar-temple-gokarna`

Sources:

- [Mahabaleshwar Temple, Gokarna — Karnataka Tourism](https://karnatakatourism.org/en/attractions/mahabaleshwar-temple-gokarna)
- [Mahabaleshwar Temple, Gokarna — Wikipedia](https://en.wikipedia.org/wiki/Mahabaleshwar_Temple,_Gokarna)
- [Sri Gokarna Mahabala — temple site (confirm contacts/timings)](https://www.srigokarna.org/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Dravidian_style_Gopura_of_Mahabaleshwar_temple_at_Gokaran.jpg — CC BY-SA 3.0, Nvvchar. Rajagopuram elevation at Gokarna; verified Commons license
- https://commons.wikimedia.org/wiki/File:Entrance_to_Gokarna_Mahabaleshwar_Temple_-_panoramio.jpg — CC BY-SA 3.0, Deepak Patil. Entrance context from Panoramio; watermarked timestamp on image

Ritual overflow: OPTIONAL CMS: start at adjacent Maha Ganapati before main shrine; modest traditional dress for sanctum; no photography inside; vehicles stop short of Car Street.

### Chamundeshwari Temple

Seed slug: `chamundeshwari-temple`

Sources:

- [Sri Chamundeshwari Development Authority — official](https://chamundeshwaritemple.in/)
- [Sri Chamundeshwari Temple — Karnataka HRCE ITMS (tid=58)](https://itms.kar.nic.in/hrcehome/index_temple.php?tid=58)
- [Chamundeshwari Temple — Wikipedia](https://en.wikipedia.org/wiki/Chamundeshwari_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Chamundeshwari_Temple.jpg — CC BY-SA 3.0, Sanjay Acharya. Gopuram / hilltop temple view; verified Commons license

### Virupaksha Temple

Seed slug: `virupaksha-temple`

Sources:

- [Group of Monuments at Hampi — UNESCO WHC](https://whc.unesco.org/en/list/241/)
- [Virupaksha Temple, Hampi — Incredible India](https://www.incredibleindia.gov.in/en/karnataka/hampi/virupaksha-temple)
- [Virupaksha Temple, Hampi — Wikipedia](https://en.wikipedia.org/wiki/Virupaksha_Temple,_Hampi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Virupaksha_Temple_Hampi.jpg — CC BY-SA 3.0, Jirijindra. Temple complex / gopuram view; verified Commons license

### Srikanteshwara Temple, Nanjangud

Seed slug: `srikanteshwara-temple-nanjangud`

Sources:

- [Sri Srikanteshwara Temple Nanjangud — Karnataka HRCE ITMS (tid=7)](https://itms.kar.nic.in/hrcehome/index_temple.php?tid=7)
- [Nanjundeshwara Temple — Wikipedia](https://en.wikipedia.org/wiki/Nanjundeshwara_Temple)
- [Nanjangud temple seva / abhisheka notes (secondary local)](https://nanjangud.info/spiritual/nanjangud-temple-seva-list.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Nanjangud_temple.jpg — CC BY-SA 4.0, Akshatha Inamdar. Temple exterior; verified Commons license (limited description on file page)

### ISKCON Temple, Bangalore

Seed slug: `iskcon-temple-bangalore`

Sources:

- [Temple Schedule — ISKCON Bangalore (official)](https://www.iskconbangalore.org/temple-schedule/)
- [FAQ — darshan timings (official)](https://www.iskconbangalore.org/frequently-asked-questions/)
- [Akshaya Patra — ISKCON Bangalore page](https://www.iskconbangalore.org/akshaya-patra/)
- [History of The Akshaya Patra Foundation](https://www.akshayapatra.org/history)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Iscon_Temple,_Bangalore.jpg — CC BY-SA 4.0, Mahesh Prasad 1992. Side view of Rajajinagar ISKCON complex; filename spelling Iscon; verified Commons license

Ritual overflow: OPTIONAL CMS: free lunch prasadam often ~11:30 AM–2:00 PM; parking paid; wheelchair/lift available via reception; no interior photography.

---

# KAN-64 / KAN-74 expansion (batch 18) — +10 additional Karnataka temples

Research-backed **new** temples applied into `lib/data/sample_data.dart` under
[KAN-74](https://shradhaventuresltd.atlassian.net/browse/KAN-74) (Hybrid C).

These are **additional** rows — they do not replace or re-enrich the original
batch 1–3 Karnataka temples.

## Hybrid C / schema lock

- Core Temple / Seed fields only (`name`, `state`, `city`, `deity`, `description`,
  `story`, `location`→`address`, `timings`, `specialities`, `latitude`, `longitude`,
  `imageUrl`, `images`).
- **`trip_planning` is research-JSON-only** — not added to the Dart model, sample
  data, or Seed writes.
- `sources`, `photo_candidates`, and `rituals_notes` stay out of Firestore; useful
  ritual tips were folded into `timings` / `story` / `specialities` free text where room.
- Cover **`imageUrl` / `images`** are KAN-77 Wave B Commons thumbs from
  `tools/photo-packs/<slug>/`. Do **not** invent picsum or Storage URLs.
  Cheluvanarayana’s pack folder is `cheluvanarayana-swamy-temple-melukote`;
  the Seed document id stays `cheluvanarayana-swamy-temple`.

## Verify before CMS / publish

| Temple | Seed slug | Caveat |
| --- | --- | --- |
| Cheluvanarayana Swamy Temple | `cheluvanarayana-swamy-temple` | Modest dress; footwear outside. Vairamudi week needs early arrival. Yoga Narasimha involves a hill climb/drive. Timings labelled… |
| Murudeshwar Temple | `murudeshwar-temple` | Modest dress for sanctum (tourism: dhoti/formal trousers for men; saree/chudidar with dupatta for women). Footwear outside. Heavy queues… |
| Annapoorneshwari Temple, Horanadu | `annapoorneshwari-temple-horanadu` | Official dress code enforced. Photography rules are strict inside—follow staff. Mountain roads can be slow in monsoon. |
| Kateel Durga Parameshwari Temple | `kateel-durga-parameshwari-temple` | Follow kateeldevi.in do’s/don’ts: bath before entry; no footwear, phones, or photography inside; observe published gender/health… |
| Ghati Subramanya Temple | `ghati-subramanya-temple` | Vehicle fee may apply on the ghat approach. Midday-break conflict means do not assume continuous darshan without checking. Naga sevas… |
| Banashankari Temple, Bengaluru | `banashankari-temple-bengaluru` | Urban temple—expect traffic on Kanakapura Road. Prefer ITMS/HRCE board over blog clocks. Distinct from Banashankari Badami. |
| Chennakeshava Temple, Belur | `chennakeshava-temple-belur` | Living garbha cult — expect puja pauses. Outer sculpture circuit is heritage-focused. Do not confuse Belur’s living status with… |
| Hoysaleswara Temple, Halebidu | `hoysaleswara-temple-halebidu` | Honesty framing: primarily an ASI/UNESCO monument experience. Any symbolic worship is limited; do not expect Belur-style daily utsavas.… |
| Anegudde Vinayaka Temple | `anegudde-vinayaka-temple` | Follow official seva counters for Ganahoma / Mooduganapathi. Ekadashi changes apply. Modest coastal temple dress norms. |
| Talakaveri Temple | `talakaveri-temple` | Primary living focus is Kaveramma / tirtha; Brahma Kundike is the Brahma-linked sacred spring. Monsoon road risk is real—tourism advises… |

## Sources and photo candidates

### Cheluvanarayana Swamy Temple

Seed slug: `cheluvanarayana-swamy-temple` (research id `cheluvanarayana-swamy-temple-melukote`).

Sources:

- [Melukote — Wikipedia](https://en.wikipedia.org/wiki/Melukote)
- [Mandya district (Govt. of Karnataka)](https://mandya.nic.in/)
- [Cheluvanarayana Swamy Temple — secondary guide](https://www.bharattemples.com/cheluvanarayana-swamy-temple-mandya-karnataka/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Melukotetemple.jpg — CC BY-SA 3.0; Philanthropist 1
- https://commons.wikimedia.org/wiki/File:Cheluv_Narayanaswamy.JPG — Public domain; Bharath12345

Ritual overflow (folded into timings where length allowed):

- Modest dress; footwear outside. Vairamudi week needs early arrival. Yoga Narasimha involves a hill climb/drive. Timings labelled provisional.

### Murudeshwar Temple

Seed slug: `murudeshwar-temple` (research id `murudeshwar-temple`).

Sources:

- [Murudeshwara — Karnataka Tourism (official)](https://karnatakatourism.org/en/destinations/murudeshwara)
- [Murdeshwar — Wikipedia](https://en.wikipedia.org/wiki/Murdeshwar)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Lord_Shiva_statue_at_Murudeshwara.jpg — CC BY-SA 3.0; Vivek Shrivastava
- https://commons.wikimedia.org/wiki/File:Murdeshwar_temple_gopuram.jpg — CC BY 3.0; Nilesh Kodikal
- https://commons.wikimedia.org/wiki/File:Shiva_Statue_Murdeshwara_Temple.jpg — CC BY 3.0; Nkodikal

Ritual overflow (folded into timings where length allowed):

- Modest dress for sanctum (tourism: dhoti/formal trousers for men; saree/chudidar with dupatta for women). Footwear outside. Heavy queues on Mondays, Pradosham, Shivaratri.

### Annapoorneshwari Temple, Horanadu

Seed slug: `annapoorneshwari-temple-horanadu` (research id `annapoorneshwari-temple-horanadu`).

Sources:

- [Sri Kshetra Horanadu (official)](https://srikshetrahoranadu.com/)
- [Horanadu — Wikipedia](https://en.wikipedia.org/wiki/Horanadu)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Horanadu_Temple_Entrance.jpg — CC BY-SA 3.0; Gnanapiti at en.wikipedia
- https://commons.wikimedia.org/wiki/File:Horanadu_Temple.jpg — CC BY-SA 4.0; Kgpramod2
- https://commons.wikimedia.org/wiki/File:Horanadu.jpg — CC BY-SA 4.0; SWE-Yaatrik

Ritual overflow (folded into timings where length allowed):

- Official dress code enforced. Photography rules are strict inside—follow staff. Mountain roads can be slow in monsoon.

### Kateel Durga Parameshwari Temple

Seed slug: `kateel-durga-parameshwari-temple` (research id `kateel-durga-parameshwari-temple`).

Sources:

- [Kateel Devi — official site](http://www.kateeldevi.in/)
- [Kateel — Wikipedia](https://en.wikipedia.org/wiki/Kateel)
- [Kateel temple visitor notes (secondary tourism)](https://www.mangaloretourism.in/shree-durgaparameshwari-temple-kateel-mangalore)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Kateel_Durga_Parameshwari_0145.JPG — CC BY-SA 3.0; Premnath Kudva

Ritual overflow (folded into timings where length allowed):

- Follow kateeldevi.in do’s/don’ts: bath before entry; no footwear, phones, or photography inside; observe published gender/health restrictions. Queues spike Fridays and Brahmakalashotsava.

### Ghati Subramanya Temple

Seed slug: `ghati-subramanya-temple` (research id `ghati-subramanya-temple`).

Sources:

- [Ghati Subramanya — Wikipedia](https://en.wikipedia.org/wiki/Ghati_Subramanya)
- [Ghati Subramanya visitor overview (secondary)](https://xploreall.com/ghati-subramanya-temple/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ghati_Subramanya_Temple.JPG — CC BY 3.0; Vedamurthy J

Ritual overflow (folded into timings where length allowed):

- Vehicle fee may apply on the ghat approach. Midday-break conflict means do not assume continuous darshan without checking. Naga sevas need advance counter planning on busy days.

### Banashankari Temple, Bengaluru

Seed slug: `banashankari-temple-bengaluru` (research id `banashankari-temple-bengaluru`).

Sources:

- [Sri Banashankari Temple — HRCE ITMS](https://itms.kar.nic.in/hrcehome/index_temple.php?tid=25)
- [Sri Banashankari Temple (temple site)](https://banashankaritemple.com/)
- [Banashankari (Bengaluru locality) — Wikipedia](https://en.wikipedia.org/wiki/Banashankari)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sri_Banashankari_Temple,_Bengaluru_(2024)_01.jpg — CC BY-SA 4.0; Gpkp
- https://commons.wikimedia.org/wiki/File:Sri_Banashankari_Temple,_Bengaluru_(2024)_05.jpg — CC BY-SA 4.0; Gpkp

Ritual overflow (folded into timings where length allowed):

- Urban temple—expect traffic on Kanakapura Road. Prefer ITMS/HRCE board over blog clocks. Distinct from Banashankari Badami.

### Chennakeshava Temple, Belur

Seed slug: `chennakeshava-temple-belur` (research id `chennakeshava-temple-belur`).

Sources:

- [Sacred Ensembles of the Hoysalas — UNESCO WHC](https://whc.unesco.org/en/list/1670/)
- [UNESCO Decision 45 COM 8B.38 (living worship note)](https://whc.unesco.org/en/decisions/8419/)
- [Chennakeshava Temple, Belur — Wikipedia](https://en.wikipedia.org/wiki/Chennakeshava_Temple,_Belur)
- [Hassan district — Chennakeshava Temple page](https://hassan.nic.in/en/tourist-place/chennakeshava-temple-belur/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:The_Courtyard_of_Chennakesava_Temple_-_Belur.jpg — CC BY-SA 4.0; Bikashrd
- https://commons.wikimedia.org/wiki/File:BelurChennakeshavaTempel.jpg — CC BY-SA 3.0; Ziegler175
- https://commons.wikimedia.org/wiki/File:Belur_Main_Temple_3.jpg — CC BY-SA 4.0; Pavvu kk

Ritual overflow (folded into timings where length allowed):

- Living garbha cult — expect puja pauses. Outer sculpture circuit is heritage-focused. Do not confuse Belur’s living status with Halebidu’s ASI symbolic-worship rule.

### Hoysaleswara Temple, Halebidu

Seed slug: `hoysaleswara-temple-halebidu` (research id `hoysaleswara-temple-halebidu`).

Sources:

- [Sacred Ensembles of the Hoysalas — UNESCO WHC](https://whc.unesco.org/en/list/1670/)
- [UNESCO Decision 45 COM 8B.38 (Halebidu symbolic worship)](https://whc.unesco.org/en/decisions/8419/)
- [Hoysaleswara Temple — Wikipedia](https://en.wikipedia.org/wiki/Hoysaleswara_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Hoysaleshwara_temple_in_Monsoon.JPG — CC BY-SA 3.0; Karthikbs23

Ritual overflow (folded into timings where length allowed):

- Honesty framing: primarily an ASI/UNESCO monument experience. Any symbolic worship is limited; do not expect Belur-style daily utsavas. Follow ASI photography and circulation rules.

### Anegudde Vinayaka Temple

Seed slug: `anegudde-vinayaka-temple` (research id `anegudde-vinayaka-temple`).

Sources:

- [Anegudde Sri Vinayaka Temple (official)](https://aneguddetemple.in/)
- [Anegudde — Wikipedia](https://en.wikipedia.org/wiki/Anegudde)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Anegudde.jpg — CC BY 3.0; Raghavendra Nayak Muddur
- https://commons.wikimedia.org/wiki/File:Anegudde_Sri_Vinayaka_Temple.jpeg — CC BY-SA 4.0; Yakshitha

Ritual overflow (folded into timings where length allowed):

- Follow official seva counters for Ganahoma / Mooduganapathi. Ekadashi changes apply. Modest coastal temple dress norms.

### Talakaveri Temple

Seed slug: `talakaveri-temple` (research id `talakaveri-temple`).

Sources:

- [Tala Kaveri / Talacauvery — Karnataka Tourism](https://karnatakatourism.org/en/destinations/tala-kaveri)
- [Talakaveri — Wikipedia](https://en.wikipedia.org/wiki/Talakaveri)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Thalakkaveri_Temple,_Karnataka.jpg — CC BY-SA 3.0; Pranchiyettan
- https://commons.wikimedia.org/wiki/File:View_of_Talacauvery_temple_from_Talacauvery_mountain.jpg — CC BY-SA 3.0; Vinayaraj
- https://commons.wikimedia.org/wiki/File:Talakaveri_Temple,_Talacauvery_and_surroundings_(34).jpg — CC BY-SA 4.0; Vinayaraj

Ritual overflow (folded into timings where length allowed):

- Primary living focus is Kaveramma / tirtha; Brahma Kundike is the Brahma-linked sacred spring. Monsoon road risk is real—tourism advises avoiding heavy-rain travel. Modest dress at the Kundike.
