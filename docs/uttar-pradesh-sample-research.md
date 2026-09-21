# Uttar Pradesh sample expansion (batch 8)

Research-backed copy for **10 new Uttar Pradesh temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-21 (IST). Prefer Kashi Vishwanath Trust, Ram Mandir Trust, and temple boards over tourist aggregators. Re-check Kashi Vishwanath aarti/darshan, Ram Mandir Trust free e-pass slots (seasonal), Krishna Janmasthan summer/winter clocks, Banke Bihari’s summer board, Prem Mandir sessions, Sankat Mochan, Vindhyavasini multi-window hours, and Gorakhnath named aartis.

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

Hanuman Garhi and Bade Hanuman Ji (Lete) Prayagraj have thin official clocks — timings stay provisional. Ayodhya and Mathura entries stay on architecture, pilgrimage practice, and public facts from the research payload.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Kashi Vishwanath Temple | `kashi-vishwanath-temple` | Mangala, Mid-Day Bhog, Sapta Rishi, and Shringar aartis are ticketed via the Trust portal/app; Shayan Aarti is listed free on the daily schedule page. Decent dress advised; no f... |
| Ram Mandir (Shri Ram Janmabhoomi Temple) | `ram-mandir-shri-ram-janmabhoomi-temple` | Book only at online.srjbtkshetra.org / srjbtkshetra.org — Trust states it does not authorise agents. Carry government photo ID matching the pass. Midday bhog often pauses darsha... Research payload id `ram-mandir-ayodhya` is not the seed id. |
| Krishna Janmabhoomi Temple | `krishna-janmabhoomi-temple` | Security frisking at entry; photography inside generally prohibited. Carry minimal belongings. Festival nights (esp. Janmashtami) require extra time for queues. |
| Banke Bihari Temple | `banke-bihari-temple` | Expect shoulder-to-shoulder queues on weekends and festival eves. Official FAQ: registration not required for darshan; no temple VIP lane. Modest dress; follow sewa adhikari ins... |
| Prem Mandir | `prem-mandir` | Photography rules differ by zone — follow on-site boards. Fountain show timing flips on 1 Apr / 1 Oct; arrive before evening Shayan if you want both darshan and the fountain. Research payload id `prem-mandir-vrindavan` is not the seed id. |
| Sankat Mochan Hanuman Temple | `sankat-mochan-hanuman-temple` | Phone/bag rules enforced at security. Tue/Sat evenings are the busiest; plan extra queue time. Music festival dates vary each winter — check Trust announcements. |
| Hanuman Garhi | `hanuman-garhi` | THIN OFFICIAL CLOCK — no crisp Trust English schedule found comparable to Ram Mandir or Kashi Vishwanath; timings text uses provisional visitor-guide consensus. Confirm on the l... Research payload id `hanuman-garhi-ayodhya` is not the seed id. |
| Vindhyavasini Temple | `vindhyavasini-temple` | Navaratri: expect long walks as vehicles are kept far from the temple. Ashtabhuja is the stair-climb shrine of the triad; Vindhyavasini itself is near ground level on ordinary d... |
| Gorakhnath Temple | `gorakhnath-temple` | THIN FULL DARSHAN CLOCK — official site is strong on Mangala/Bhog/Sandhya aartis and akhand bhandara, weaker on minute-by-minute open hours. Follow the campus notice board. Bhan... |
| Bade Hanuman Ji Temple (Lete Hanuman) | `bade-hanuman-ji-temple-lete-hanuman` | THIN SOURCES on exact aarti minutes — timings labelled provisional from secondary guides / Wikipedia summary. Monsoon flood days may restrict sanctum access; follow police/admin... Research payload id `bade-hanuman-ji-temple-prayagraj` is not the seed id. |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Kashi Vishwanath Temple

Seed slug: `kashi-vishwanath-temple`

City: Varanasi. Deity label: `Shiva`. Map pin: 25.3108, 83.0106.

Sources:

- [Shri Kashi Vishwanath — Rituals (official)](https://www.shrikashivishwanath.org/general/rituals)
- [Shri Kashi Vishwanath — Daily schedule / aarti tariffs](https://www.shrikashivishwanath.org/general/daily_schedule)
- [Shri Kashi Vishwanath Temple Trust FAQ (PDF)](https://shrikashivishwanath.org/pdffile/FAQ_SHRI_KASHI_VISHWANTH_TEMPLE_2_0_pdf.pdf)
- [Kashi Vishwanath Temple — Wikipedia](https://en.wikipedia.org/wiki/Kashi_Vishwanath_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ganga_Dwar,_Gateway_of_Corridor_of_Kashi_Vishwanath_Temple,_Varanasi.webp — CC BY-SA 4.0, Ashvin Kaitabhya (photo by Abhishek Pandey). Ganga Dwar corridor gateway (2019–21 corridor); verified Commons license page

Ritual overflow (not a Firestore field): Mangala, Mid-Day Bhog, Sapta Rishi, and Shringar aartis are ticketed via the Trust portal/app; Shayan Aarti is listed free on the daily schedule page. Decent dress advised; no formal dress code in Trust FAQ. Keep phones/bags per on-site security boards.

### Ram Mandir (Shri Ram Janmabhoomi Temple)

Seed slug: `ram-mandir-shri-ram-janmabhoomi-temple`

Research payload id `ram-mandir-ayodhya` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Ayodhya. Deity label: `Vishnu`. Map pin: 26.7956, 82.1943.

Sources:

- [Shri Ram Janmbhoomi Teerth Kshetra (official)](https://srjbtkshetra.org/)
- [Shri Ram Janmbhoomi Teerth Kshetra — online booking portal](https://online.srjbtkshetra.org/)
- [Ram Mandir — Wikipedia](https://en.wikipedia.org/wiki/Ram_Mandir)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Ram_Janmbhoomi_Mandir,_Ayodhya_Dham.jpg — GODL-India, Prime Minister's Office / Press Information Bureau (GODL-India). Temple exterior at prana pratishtha period; Government of India open licence — verify attribution line on Commons

Ritual overflow (not a Firestore field): Book only at online.srjbtkshetra.org / srjbtkshetra.org — Trust states it does not authorise agents. Carry government photo ID matching the pass. Midday bhog often pauses darshan; festival and seasonal boards override the default slot table.

### Krishna Janmabhoomi Temple

Seed slug: `krishna-janmabhoomi-temple`

City: Mathura. Deity label: `Vishnu`. Map pin: 27.5037, 77.6694.

Sources:

- [Shri Krishna Janmasthan — Mandir timing (official)](https://www.shrikrishnajanmasthan.com/mandirtiming-e.php)
- [Shri Krishna Janmasthan — Aarti timing (official)](https://www.shrikrishnajanmasthan.com/aartitiming-e.php)
- [Krishna Janmasthan Temple Complex — Wikipedia](https://en.wikipedia.org/wiki/Krishna_Janmasthan_Temple_Complex)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Mathura_India_(2).JPG — CC BY 3.0, Shahnoor Habib Munmun. Exterior/entrance view of Janmabhoomi–Keshav Deo area; photography not allowed inside — exterior only

Ritual overflow (not a Firestore field): Security frisking at entry; photography inside generally prohibited. Carry minimal belongings. Festival nights (esp. Janmashtami) require extra time for queues.

### Banke Bihari Temple

Seed slug: `banke-bihari-temple`

City: Vrindavan. Deity label: `Vishnu`. Map pin: 27.5797, 77.6964.

Sources:

- [Shri Banke Bihari Mandir — official home (darshan timings)](https://bihariji.org/)
- [Shri Banke Bihari Mandir — Visit Temple](https://www.bihariji.org/public/visitTemple.aspx)
- [Shri Banke Bihari Mandir — FAQ](https://bihariji.org/public/FAQ.aspx)
- [Banke Bihari Temple — Wikipedia](https://en.wikipedia.org/wiki/Banke_Bihari_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Bankebihari_temple_main_gate_Vrindavan.JPG — CC BY-SA 3.0, आशीष भटनागर (Ashish Bhatnagar). Main gate exterior; prefer exterior over murti shots (photography of deity restricted)

Ritual overflow (not a Firestore field): Expect shoulder-to-shoulder queues on weekends and festival eves. Official FAQ: registration not required for darshan; no temple VIP lane. Modest dress; follow sewa adhikari instructions inside.

### Prem Mandir

Seed slug: `prem-mandir`

Research payload id `prem-mandir-vrindavan` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Vrindavan. Deity label: `Vishnu`. Map pin: 27.5725, 77.6725.

Sources:

- [Prem Mandir — official](https://premmandir.org.in/)
- [Prem Mandir — Timings (official)](https://premmandir.org.in/timings/)
- [Prem Mandir — Wikipedia](https://en.wikipedia.org/wiki/Prem_Mandir,_Vrindavan)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Prem_Mandir,_Vrindavan.jpg — CC BY-SA 4.0, Uddalak Das. Illuminated exterior night view; verified Commons CC BY-SA 4.0
- https://commons.wikimedia.org/wiki/File:Prem_mandir_Braj_Mathura.jpg — CC BY-SA 4.0, Prijec31. Daytime exterior; verified Commons CC BY-SA 4.0

Ritual overflow (not a Firestore field): Photography rules differ by zone — follow on-site boards. Fountain show timing flips on 1 Apr / 1 Oct; arrive before evening Shayan if you want both darshan and the fountain.

### Sankat Mochan Hanuman Temple

Seed slug: `sankat-mochan-hanuman-temple`

City: Varanasi. Deity label: `Hanuman`. Map pin: 25.2821, 83.0.

Sources:

- [Sankat Mochan Mandir — Visitor information](https://sankatmochanmandirvaranasi.com/visitor-information/)
- [Sankat Mochan Hanuman Temple — Wikipedia](https://en.wikipedia.org/wiki/Sankat_Mochan_Hanuman_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Sankat_Mochan_temple_entrance,_Varanasi_-_IRCTC_2017.jpg — CC BY-SA 4.0, Vinayaraj. Temple entrance exterior; verified Commons CC BY-SA 4.0

Ritual overflow (not a Firestore field): Phone/bag rules enforced at security. Tue/Sat evenings are the busiest; plan extra queue time. Music festival dates vary each winter — check Trust announcements.

### Hanuman Garhi

Seed slug: `hanuman-garhi`

Research payload id `hanuman-garhi-ayodhya` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Ayodhya. Deity label: `Hanuman`. Map pin: 26.7956, 82.2016.

Sources:

- [Hanuman Garhi Temple — Wikipedia](https://en.wikipedia.org/wiki/Hanuman_Garhi_Temple)
- [UP Tourism / Ayodhya pilgrimage context (regional)](https://www.uptourism.gov.in/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Hanuman_Garhi_Temple,_a_major_religious_site_in_Ayodhya_utter_pradesh.jpg — CC BY-SA 4.0, Prashant Kharote. Wide exterior view; filename spelling 'utter' is exact Commons title — use URL as given

Ritual overflow (not a Firestore field): THIN OFFICIAL CLOCK — no crisp Trust English schedule found comparable to Ram Mandir or Kashi Vishwanath; timings text uses provisional visitor-guide consensus. Confirm on the local notice board. Stair climb is steep; elderly devotees may need assistance.

### Vindhyavasini Temple

Seed slug: `vindhyavasini-temple`

City: Vindhyachal. Deity label: `Devi`. Map pin: 25.165, 82.5025.

Sources:

- [UP Vindhya Dham Teerth Vikas Parishad — FAQ (darshan hours)](https://vindhyatirthparishad.org/faq.php)
- [Vindhyavasini Temple — Wikipedia](https://en.wikipedia.org/wiki/Vindhyavasini_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Maa_Vindhyavasini_temple,_Vindhyachal.jpg — CC BY-SA 3.0, Godric_ki_Kothri. Temple exterior; verified Commons CC BY-SA 3.0

Ritual overflow (not a Firestore field): Navaratri: expect long walks as vehicles are kept far from the temple. Ashtabhuja is the stair-climb shrine of the triad; Vindhyavasini itself is near ground level on ordinary days.

### Gorakhnath Temple

Seed slug: `gorakhnath-temple`

City: Gorakhpur. Deity label: `Gorakhnath`. Map pin: 26.7572, 83.3578.

Sources:

- [Gorakhnath Mandir — official](https://www.gorakhnathmandir.in/)
- [Gorakhnath Math — Wikipedia](https://en.wikipedia.org/wiki/Gorakhnath_Math)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Gorakhnath_Main_Temple.jpg — CC BY-SA 4.0, StarlordHarsh. Main temple exterior; verified Commons CC BY-SA 4.0

Ritual overflow (not a Firestore field): THIN FULL DARSHAN CLOCK — official site is strong on Mangala/Bhog/Sandhya aartis and akhand bhandara, weaker on minute-by-minute open hours. Follow the campus notice board. Bhandara is open to all devotees without distinction per temple description.

### Bade Hanuman Ji Temple (Lete Hanuman)

Seed slug: `bade-hanuman-ji-temple-lete-hanuman`

Research payload id `bade-hanuman-ji-temple-prayagraj` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Prayagraj. Deity label: `Hanuman`. Map pin: 25.4335, 81.882.

Sources:

- [Bade Hanuman Mandir — Wikipedia](https://en.wikipedia.org/wiki/Bade_Hanuman_Mandir)
- [UP Tourism — Prayagraj / Sangam context](https://www.uptourism.gov.in/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Lete_Hanuman_Ji_Mandir.jpg — CC0 1.0, Dsrprj. Temple view filed under Hanuman Mandir Prayagraj category; CC0 public domain dedication on Commons

Ritual overflow (not a Firestore field): THIN SOURCES on exact aarti minutes — timings labelled provisional from secondary guides / Wikipedia summary. Monsoon flood days may restrict sanctum access; follow police/administration advisories near Sangam.
