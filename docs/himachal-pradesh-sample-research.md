# Himachal Pradesh sample expansion (batch 15)

Research-backed copy for **10 new Himachal Pradesh temples** added to `lib/data/sample_data.dart`. These are expansion rows, not enrichments of temples that were already seeded.

Debug **Seed** writes each temple under `templeDocumentId(name)` (lowercase kebab slug of the display name). Re-running Seed merges the same documents.

This file is **not** written to Firestore. Use it when reviewing CMS publish and when picking license-safe photos for Storage.

Research pass: 2026-09-22 (IST). Prefer the Naina Devi Trust board (normal versus Navratri), the Chintpurni snan/aarti/bhog/sayan board, and Chamunda’s summer/winter plus noon bhog close. Re-check Jwalamukhi’s two conflicting official Kangra portal clocks, Baijnath Incredible India hours, Hadimba Incredible India hours, and thin clocks for Bhimakali, Lakshmi Narayan Chamba, Panchvaktra, and Manikaran. Confirm hill-road access the same day.

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

Jwalamukhi keeps both conflicting official clocks from kangratemples.hp.gov.in. Naina Devi prefers the Trust’s normal 04:00–22:00 versus Navratri 02:00–midnight over the weaker Incredible India span. Chintpurni’s ritual board is solid, but seasonal open/close is partly secondary. Chamunda keeps summer/winter hours and the noon bhog close. Baijnath is an ASI living Shiva temple in Kangra; it is not the canonical Vaidyanath Jyotirlinga and is distinct from the Baijnath temple in Uttarakhand. Bhimakali, Lakshmi Narayan Chamba, Panchvaktra, and Manikaran are thin official clocks. Hadimba uses Incredible India 08:00–18:00.

## Verify before CMS / publish

Festival days often override ordinary hours. Re-check near travel dates.

| Temple | Seed slug | Notes |
| --- | --- | --- |
| Jwalamukhi Temple | `jwalamukhi-temple` | Darshan is suspended for aarti and the midday bhog interval. The two official Kangra portal pages conflict, so re-check the current notice board or Trust contact. Navratri queue... |
| Naina Devi Temple | `naina-devi-temple` | The official Trust clock overrides third-party listings. Navratri requires early arrival and managed queues. Ropeway operation is weather- and maintenance-dependent; do not assu... Research payload id `naina-devi-temple-bilaspur` is not the seed id. |
| Chintpurni Temple | `chintpurni-temple` | Obtain the required darshan parchi from authorised Temple Trust/security points, especially on mela days. Darshan stops for bhog 12:00–12:30 PM. Do not feed monkeys or use unaut... |
| Chamunda Devi Temple | `chamunda-devi-temple` | Darshan pauses 12:00–1:00 PM for bhog and may slow during aarti. Follow bathing-area barriers; the Baner River can rise rapidly in monsoon. The high-altitude Aadi Himani Chamund... Research payload id `chamunda-devi-temple-kangra` is not the seed id. |
| Baijnath Temple | `baijnath-temple` | This Kangra temple is not the Baijnath temple in Uttarakhand. Respect ASI barriers and temple photography rules. Maha Shivaratri and Shravan Mondays can produce long queues. Con... Research payload id `baijnath-temple-himachal` is not the seed id. |
| Bhimakali Temple | `bhimakali-temple` | Hours are provisional: verify on arrival or by Temple Trust phone. Follow posted dress, leather, head-covering, and photography rules; upper-sanctum access may be controlled. In... Research payload id `bhimakali-temple-sarahan` is not the seed id. |
| Hadimba Devi Temple | `hadimba-devi-temple` | The temple is in a living sacred cedar grove; avoid litter and commercial-animal interactions that violate local rules. Interior photography may be restricted. In winter use foo... |
| Lakshmi Narayan Temple | `lakshmi-narayan-temple` | Timings are provisional; verify locally. Each shrine may pause independently for worship. Respect photography and conservation signs. Chamba roads can be delayed by monsoon land... Research payload id `lakshmi-narayan-temple-chamba` is not the seed id. |
| Panchvaktra Temple | `panchvaktra-temple` | Hours are provisional. Visit in daylight and follow ASI/temple barriers. Do not enter closed riverbank areas: the Beas and Suketi can rise rapidly during monsoon or dam releases... Research payload id `panchvaktra-temple-mandi` is not the seed id. |
| Manikaran Shiva Temple | `manikaran-shiva-temple` | Timings are provisional and shrine-specific. Hot spring water can scald: use only designated baths/cooking areas and obey attendants. Remove footwear and follow separate temple/... |

Coordinates are approximate map pins from the research payload.

## Sources and photo candidates

### Jwalamukhi Temple

Seed slug: `jwalamukhi-temple`

City: Jwalamukhi. Deity label: `Devi`. Map pin: 31.8752, 76.3243.

Sources:

- [Kangra Temples — Shri Jawala Mata Mandir (official)](http://kangratemples.hp.gov.in/shri-jawala-mata-mandir/)
- [Kangra Temples — Jawalamukhi Ji e-Puja information (official)](http://kangratemples.hp.gov.in/e_puja_management/jawaji/)
- [Jwalamukhi Temple, Himachal Pradesh — Wikipedia](https://en.wikipedia.org/wiki/Jwalamukhi_temple,_Himachal_Pradesh)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:0051223_Jwalamukhi_temple,_Jvala_ji_Himachal_Pradesh_030.jpg — CC0 1.0, Ms Sarah Welch. Recent temple-complex view; verified Commons CC0 file page

Ritual overflow (not a Firestore field): Darshan is suspended for aarti and the midday bhog interval. The two official Kangra portal pages conflict, so re-check the current notice board or Trust contact. Navratri queues can be many hours. Allow extra road time in heavy monsoon rain or fog; follow district advisories and do not approach restricted flame/sanctum areas.

### Naina Devi Temple

Seed slug: `naina-devi-temple`

Research payload id `naina-devi-temple-bilaspur` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Naina Devi. Deity label: `Devi`. Map pin: 31.30603, 76.53639.

Sources:

- [Shri Naina Devi Ji Temple Trust (official)](https://srinainadevi.com/)
- [Shree Naina Devi Temple — Incredible India](https://www.incredibleindia.gov.in/en/himachal-pradesh/bilaspur/shree-naina-devi-temple)
- [Naina Devi — Wikipedia](https://en.wikipedia.org/wiki/Naina_Devi)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Naina_Devi_Temple,_Himachal.jpg — CC BY 2.0, Raman Sharma (Flickr); reviewed on Commons. Temple exterior on the Bilaspur hill; verified Commons license page

Ritual overflow (not a Firestore field): The official Trust clock overrides third-party listings. Navratri requires early arrival and managed queues. Ropeway operation is weather- and maintenance-dependent; do not assume it is running. Hill roads can be slow in monsoon rain or fog.

### Chintpurni Temple

Seed slug: `chintpurni-temple`

City: Chintpurni. Deity label: `Devi`. Map pin: 31.80862, 76.10287.

Sources:

- [Mata Shri Chintpurni — Religious Activity (official)](https://www.matashrichintpurni.com/religious-activity.php)
- [Mata Shri Chintpurni — Do’s and Don’ts (official)](https://www.matashrichintpurni.com/dos_and_donts.php)
- [Chintpurni — Wikipedia](https://en.wikipedia.org/wiki/Chintpurni)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Jai_Mata_Di...Maa_Chintpurni%27s_Durbar_as_seen_from_the_ancient_havan_kund_on_left.jpg — CC BY 2.0, Gopal Aggarwal (Flickr); reviewed on Commons. Temple durbar viewed from the ancient havan kund; verified Commons license page

Ritual overflow (not a Firestore field): Obtain the required darshan parchi from authorised Temple Trust/security points, especially on mela days. Darshan stops for bhog 12:00–12:30 PM. Do not feed monkeys or use unauthorised agents. Monsoon and festival traffic may slow the final hill approach.

### Chamunda Devi Temple

Seed slug: `chamunda-devi-temple`

Research payload id `chamunda-devi-temple-kangra` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Dharamshala. Deity label: `Devi`. Map pin: 32.14833, 76.41917.

Sources:

- [Kangra Temples — Shri Chamunda Mata Temple (official)](https://kangratemples.hp.gov.in/shri-chamunda-mata-temple/)
- [Shri Chamunda Nandikeshwar Dham — District Kangra](https://hpkangra.nic.in/tourist-place/shri-chamunda-nandikeshwar-dham/)
- [Shri Chamunda Devi Mandir — Wikipedia](https://en.wikipedia.org/wiki/Shri_Chamunda_Devi_Mandir)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Front_View_of_Shri_Chamunda-Kangra_Ji_Temple.JPG — CC BY-SA 3.0, Er.ankushgarg. Front view of the Kangra Chamunda temple; verified Commons license page

Ritual overflow (not a Firestore field): Darshan pauses 12:00–1:00 PM for bhog and may slow during aarti. Follow bathing-area barriers; the Baner River can rise rapidly in monsoon. The high-altitude Aadi Himani Chamunda trek is a separate, much harder destination and should not be assumed accessible from this temple in poor weather.

### Baijnath Temple

Seed slug: `baijnath-temple`

Research payload id `baijnath-temple-himachal` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Baijnath. Deity label: `Shiva`. Map pin: 32.05095, 76.64553.

Sources:

- [Shiv Temple Baijnath — District Kangra](https://hpkangra.nic.in/tourist-place/shiv-temple-baijnath/)
- [Baijnath Temple — Incredible India](https://www.incredibleindia.gov.in/en/himachal-pradesh/kangra/baijnath-temple)
- [Baijnath Temple — Wikipedia](https://en.wikipedia.org/wiki/Baijnath_Temple)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Baijnath_Temple_Himachal.jpg — CC BY-SA 4.0, Nitinnn. Temple exterior in Baijnath, Kangra; verified Commons license page

Ritual overflow (not a Firestore field): This Kangra temple is not the Baijnath temple in Uttarakhand. Respect ASI barriers and temple photography rules. Maha Shivaratri and Shravan Mondays can produce long queues. Confirm any abhishek or close-sanctum access locally; do not infer it from general visiting hours.

### Bhimakali Temple

Seed slug: `bhimakali-temple`

Research payload id `bhimakali-temple-sarahan` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Sarahan. Deity label: `Devi`. Map pin: 31.44943, 77.63087.

Sources:

- [Bhimakali Temple — Wikipedia](https://en.wikipedia.org/wiki/Bhimakali_Temple)
- [Sarahan — Wikipedia](https://en.wikipedia.org/wiki/Sarahan)
- [Shrine for Shakti in the Land of the Shakthas — The Hindu](https://www.thehindu.com/society/history-and-culture/shrine-for-shakti-in-the-land-of-the-shakthas/article27899214.ece)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Bhimakali_Temple,_Himachal_Pradesh,_India.JPG — CC BY-SA 3.0, Tvtvtv. Wide exterior view of the Sarahan temple; verified Commons license page

Ritual overflow (not a Firestore field): Hours are provisional: verify on arrival or by Temple Trust phone. Follow posted dress, leather, head-covering, and photography rules; upper-sanctum access may be controlled. In monsoon or winter, check NH-5/Sarahan road status and avoid night driving in landslide, snow, or ice conditions.

### Hadimba Devi Temple

Seed slug: `hadimba-devi-temple`

City: Manali. Deity label: `Devi`. Map pin: 32.24228, 77.18737.

Sources:

- [Hidimba Temple Manali — Incredible India](https://www.incredibleindia.gov.in/en/himachal-pradesh/manali/hidimba-temple)
- [Hidimba Devi Temple — Wikipedia](https://en.wikipedia.org/wiki/Hidimba_Devi_Temple)
- [History — District Kullu (official)](https://hpkullu.nic.in/history/)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Hidimba_Devi_Temple.jpg — CC BY 2.0, Paul Evans (Flickr); reviewed on Commons. Pagoda temple framed by deodar trees; verified Commons license page

Ritual overflow (not a Firestore field): The temple is in a living sacred cedar grove; avoid litter and commercial-animal interactions that violate local rules. Interior photography may be restricted. In winter use footwear suited to ice and verify local roads/parking; in monsoon expect slippery paths.

### Lakshmi Narayan Temple

Seed slug: `lakshmi-narayan-temple`

Research payload id `lakshmi-narayan-temple-chamba` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Chamba. Deity label: `Vishnu`. Map pin: 32.55781, 76.1247.

Sources:

- [Places of Interest — District Chamba (official)](https://hpchamba.nic.in/places-of-interest/)
- [Laxmi Narayan Temple — Incredible India](https://prod.incredibleindia.gov.in/content/incredible-india-v2/en/destinations/chamba/laxmi-narayan-temple.html)
- [Chamba, Himachal Pradesh — Wikipedia](https://en.wikipedia.org/wiki/Chamba,_Himachal_Pradesh)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:0051723_Lakshmi_Narayan_group_of_temples,_Chamba,_Himachal_Pradesh_589.jpg — CC0 1.0, Ms Sarah Welch. Recent view of the six-temple group; verified Commons CC0 file page

Ritual overflow (not a Firestore field): Timings are provisional; verify locally. Each shrine may pause independently for worship. Respect photography and conservation signs. Chamba roads can be delayed by monsoon landslides and winter weather; check district advisories before long mountain drives.

### Panchvaktra Temple

Seed slug: `panchvaktra-temple`

Research payload id `panchvaktra-temple-mandi` includes a place disambiguator that is not part of the display name. Seed uses the name slug above.

City: Mandi. Deity label: `Shiva`. Map pin: 31.71131, 76.93563.

Sources:

- [Places of Interest — District Mandi (official)](https://hpmandi.nic.in/places-of-interest/)
- [Panchvaktra Temple, Mandi — Wikidata](https://www.wikidata.org/wiki/Q56988610)
- [Panchvaktra Temple, Mandi — Tour My India](https://www.tourmyindia.com/states/himachal/panchvaktra-temple-mandi.html)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Panchvaktra_Temple,_Mandi_(SIDE_VIEW).jpg — CC BY-SA 4.0, Aranya Kar. Side view of the ASI-protected riverside temple; verified Commons license page

Ritual overflow (not a Firestore field): Hours are provisional. Visit in daylight and follow ASI/temple barriers. Do not enter closed riverbank areas: the Beas and Suketi can rise rapidly during monsoon or dam releases. Mandi Shivaratri brings major traffic and processions.

### Manikaran Shiva Temple

Seed slug: `manikaran-shiva-temple`

City: Manikaran. Deity label: `Shiva`. Map pin: 32.02761, 77.34585.

Sources:

- [Manikaran — District Kullu (official)](https://hpkullu.nic.in/tourist-place/manikaran/)
- [Manikaran — Wikipedia](https://en.wikipedia.org/wiki/Manikaran)
- [Manikaran Hot Springs — Wikipedia](https://en.wikipedia.org/wiki/Manikaran_hot_springs)

Photo candidates (Commons file pages):

- https://commons.wikimedia.org/wiki/File:Manikaran_Temple.jpg — CC BY-SA 4.0, Prachurjya Biswas. Shiv–Parvati Temple with hot-spring precinct context; verified Commons license page
- https://commons.wikimedia.org/wiki/File:SHIV_TEMPLE_MANIKARAN.jpg — CC BY-SA 4.0, DPK70211. Exterior view of the Shiva temple; verified Commons license page

Ritual overflow (not a Firestore field): Timings are provisional and shrine-specific. Hot spring water can scald: use only designated baths/cooking areas and obey attendants. Remove footwear and follow separate temple/gurdwara etiquette. Check Kullu district weather and road alerts; never approach the river or closed bridges during flash-flood warnings.
