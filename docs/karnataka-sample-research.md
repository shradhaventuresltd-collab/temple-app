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
| `imageUrl` / `images` | same — **picsum placeholders left as-is**; do not invent Storage URLs |
| `sources`, `photo_candidates`, `rituals_notes` | **not in the Temple schema** — documented here only |

No `pooja_schedule` / `festivals` collections were added.

## Images

Bundled covers remain `https://picsum.photos/seed/…` placeholders. Commons
`photo_candidates` below are file **pages** for later manual download,
attribution, upload to `temples/{docId}/…`, then CMS `images` / `imageUrl`.
Do **not** paste these Commons URLs into sample data as if they were Storage
paths.

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
