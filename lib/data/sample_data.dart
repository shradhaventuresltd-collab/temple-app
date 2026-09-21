import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
  // ═══════════════════════════════════════════════════════════════════════════
  //  TAMIL NADU
  // ═══════════════════════════════════════════════════════════════════════════
  // Research-enriched visitor copy for the existing 10 Tamil Nadu temples
  // (matched by name/slug — no new documents). Cover imageUrl values remain
  // the bundled picsum placeholders; do not treat Commons candidates as Storage
  // paths. Sources and photo_candidates: docs/tamil-nadu-sample-research.md.

  Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/meenakshi/800/600',
    description:
        'Historic Madurai temple dedicated to Goddess Meenakshi (Parvati) and Lord Sundareswarar '
        '(Shiva), famed for its towering Dravidian gopurams crowded with painted stucco '
        'sculptures and for the annual Meenakshi–Sundareswarar wedding festival.',
    story:
        'Meenakshi Amman Temple (Arulmigu Meenakshi Sundaraswarar Temple) stands at the ritual and civic heart of Madurai on the Vaigai. Literary references to the deities reach back to early medieval Tamil Shaiva tradition; the sprawling stone complex visitors see today was largely rebuilt and expanded under the Madurai Nayaks in the 16th–17th centuries, with continuous royal and mercantile patronage before and after.\n\n'
        'Temple legend identifies Meenakshi as a Pandyan princess born with three breasts; a prophecy said the third would vanish when she met her destined husband. When she encountered Shiva at Mount Kailash, the prophecy was fulfilled, and their divine wedding — Meenakshi Thirukalyanam — remains the emotional climax of the multi-day Chithirai festival that still draws vast crowds each Tamil month of Chithirai (April–May).\n\n'
        'Architecturally the precinct is ringed by fourteen gopurams; the southern tower rises about 51.9 m and is among the most photographed skylines in South India. Inside lie the Golden Lotus Tank (Potramarai Kulam), dual sanctums for Meenakshi and Sundareswarar, and the famed Thousand Pillar Hall with elaborately carved and musical pillars.\n\n'
        'Daily worship follows a classical six-pooja rhythm (abhisheka, alankaram, naivedyam, deepa aradanai) for both deities. Pilgrims customarily visit Meenakshi’s shrine before Sundareswarar’s, reflecting the goddess’s primacy in this complex. Fridays in Aadi and Thai, Navaratri, and Avani Moola (celebrating Shiva’s sacred sports) are especially busy; festival calendars can override ordinary closing hours.',
    location: 'Madurai Main, Madurai, Tamil Nadu 625001',
    timings:
        'Daily darshan (TN HR&CE): 5:00 AM–12:30 PM and 4:00 PM–10:00 PM; closed ~12:30–4:00 PM. '
        'Named poojas (official HR&CE list): Thiruvanandal / Mahasodashi 5:30–5:45 AM; Vilaa / '
        'Paalai 6:30–7:15 AM; Kalasandhi / Gauri 10:30–11:20 AM; Maalai / Panchadasi 4:30–5:15 '
        'PM; Ardhajama / Matangi 7:30–8:15 PM; Palliyarai / Sodashi 9:30–10:00 PM. Festival days '
        '(esp. Chithirai) often change pooja and closing times — confirm on '
        'maduraimeenakshi.hrce.tn.gov.in before travel.',
    latitude: 9.9195,
    longitude: 78.1193,
    specialities: [
      '14 gopurams; south tower ~51.9 m',
      'Potramarai Kulam (Golden Lotus Tank)',
      'Thousand Pillar Hall with carved/musical pillars',
      'Meenakshi Thirukalyanam / Chithirai festival',
      'Dual sanctums — Meenakshi visited before Sundareswarar',
      'Six daily poojas for both deities',
    ],
  ),
  Temple(
    name: 'Brihadeeswarar Temple',
    state: 'Tamil Nadu',
    city: 'Thanjavur',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/brihadeeswarar/800/600',
    description:
        'UNESCO World Heritage Chola masterpiece (Great Living Chola Temples), built by Raja Raja '
        'Chola I around 1003–1010 CE, crowned by a soaring granite vimana and a monumental '
        'monolithic Nandi.',
    story:
        'Brihadisvara / Brihadeeswarar Temple (Peruvudaiyar Kovil, historically Rajarajeswaram or Dakshina Meru) was inaugurated under Raja Raja Chola I, with construction traditionally dated from about his 19th regal year (c. 1003–04 CE) and consecration in his 25th year (c. 1009–10 CE). It anchors UNESCO’s Great Living Chola Temples serial property (inscribed 1987; extended 2004 with Gangaikonda Cholapuram and Darasuram).\n\n'
        'The temple’s vimana rises roughly 60 m over a high base and multi-storeyed elevation, capped by a massive granite sikhara/cupola whose emplacement remains an icon of Chola engineering. A huge colonnaded prakara with dikpala shrines and the Rajarajantiruvasal gateway frame the court; the sanctum houses an exceptionally large Shiva linga with ambulatory passages.\n\n'
        'Walls and upper tiers carry mural paintings and sculptural programmes, including dozens of Bharatanatyam karana poses among the classical 108. The freestanding Nandi pavilion holds one of India’s great monolithic bulls — often cited around 13 ft high and carved from a single rock.\n\n'
        'Popular lore claims the vimana’s noon shadow never falls on the ground; treat this as folklore rather than surveyed fact. As a living temple under ASI heritage oversight and local religious administration, it still hosts daily poojas and major Shaiva festivals such as Maha Shivaratri and Brahmotsavam seasons.',
    location: 'Membalam Rd, Balaganapathy Nagar, Thanjavur, Tamil Nadu 613007',
    timings:
        'Commonly listed visitor/darshan windows: 6:00 AM–12:30 PM and 4:00 PM–8:30 PM '
        '(Incredible India / visitor guides). Reported daily pooja markers include Kaala Sandhi '
        '~6:30 AM, Uchikalam ~12:00 PM, Sayarakshai ~5:30 PM, Arthajamam ~8:00 PM — confirm on '
        'site; festival days extend hours. Entry is generally free; photography rules vary by '
        'precinct. Midday closure for rituals is standard.',
    latitude: 10.7828,
    longitude: 79.1318,
    specialities: [
      'UNESCO Great Living Chola Temples (1987/2004)',
      'Vimana ~59–60 m with massive granite cupola',
      'Monolithic Nandi pavilion',
      'Chola murals and karana dance sculptures',
      'Consecrated c. 1010 CE by Raja Raja Chola I',
      'Living temple — not a museum-only monument',
    ],
  ),
  Temple(
    name: 'Kapaleeshwarar Temple',
    state: 'Tamil Nadu',
    city: 'Chennai',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/kapaleeshwarar/800/600',
    description:
        'Beloved Mylapore Shiva temple for Kapaleeshwarar and Karpagambal, known for its '
        'colourful rajagopuram, sacred tank, and the Panguni Peruvizha climaxed by the Arubathu '
        'Moovar procession of the 63 Nayanmars.',
    story:
        'Kapaleeshwarar Temple sits in historic Mylapore, long a cultural and mercantile quarter of the Coromandel coast. Shaiva tradition places early worship here in the Pallava centuries; the present Dravidian complex is largely a later rebuild after the original seaside shrine was lost — commonly linked to Portuguese-period destruction — with Vijayanagara and subsequent patronage shaping the towers and precincts visitors see today.\n\n'
        'The name Kapaleeshwarar evokes Shiva associated with the kapala (skull), while Karpagambal — ‘goddess of the wish-yielding tree’ — is Parvati. Local legend holds that Parvati worshipped Shiva here in the form of a peahen (mayil), giving Mylapore its name (‘town of the peacock’); a related narrative tells of her penance under a sacred punnai tree after a moment of distraction during Shiva’s teaching.\n\n'
        'The east-facing rajagopuram rises tens of metres above Kapaleeswarar Sannadhi Street and frames the temple tank processions that define festival season. Inside, dual shrines, mandapas, and continuous nadaswaram–tavil accompaniment mark a classic Tamil urban Shaiva rhythm.\n\n'
        'The ten-day Panguni Peruvizha (March–April) is Mylapore’s grandest public festival: flag-hoisting, vahana processions, the towering ther (chariot), and — on the eighth day — Arubathu Moovar, when bronze images of the sixty-three Nayanmar saints are carried through packed streets. Maha Shivaratri alone sees the temple remain open round the clock per HR&CE notice.',
    location: 'Kapaleeshwarar Sannadhi St, Mylapore, Chennai, Tamil Nadu 600004',
    timings:
        'TN HR&CE daily: 5:30 AM–12:30 PM and 4:00 PM–9:30 PM. Maha Shivaratri: open 24 hours '
        '(5:00 AM to next-day 5:00 AM). Named poojas (HR&CE): Ko Pooja 5:30–6:00 AM; Vaikarai '
        '6:00–7:00 AM; Kalasandhi 8:00–9:30 AM; Uchikkala 11:00 AM–12:30 PM; Sayaraksha 4:00–6:30 '
        'PM; Ushakala 6:30–7:00 PM; Ardhajama 9:00–9:30 PM. Rahu kala abhishekams are scheduled '
        'separately — check mylaikapaleeswarar.hrce.tn.gov.in.',
    latitude: 13.0339,
    longitude: 80.2695,
    specialities: [
      'Arubathu Moovar (63 Nayanmars) Panguni procession',
      'Panguni Peruvizha Brahmotsavam & chariot',
      'Peacock / Mylapore origin legend',
      'Colourful rajagopuram and temple tank',
      '24-hour opening on Maha Shivaratri',
    ],
  ),
  Temple(
    name: 'Ramanathaswamy Temple',
    state: 'Tamil Nadu',
    city: 'Rameswaram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ramanathaswamy/800/600',
    description:
        'Jyotirlinga and Char Dham pilgrimage temple on Pamban Island, celebrated for its vast '
        'pillared corridors, twenty-two sacred theerthams, and the legend of Rama’s worship of '
        'Shiva before and after the Lanka war.',
    story:
        'Ramanathaswamy Temple on Rameswaram island is one of the twelve Jyotirlinga sites and one of Hinduism’s Char Dham destinations, drawing Shaiva, Vaishnava, and Smarta pilgrims alike. It is also counted among the Paadal Petra Sthalams glorified by the Tamil Nayanars.\n\n'
        'Epic tradition holds that Rama installed and worshipped a Shiva linga here in connection with the campaign against Ravana — accounts vary on whether this was before crossing Rama Setu or as atonement afterward. When Hanuman’s journey to fetch a linga from Kailash was delayed, Sita is said to have fashioned a sand linga (Ramalingam) that remains the principal object of worship; a second linga brought by Hanuman (Viswalingam) is also venerated, with custom often giving first honour to Viswalingam.\n\n'
        'Architecturally the temple is famous for the longest corridor complex of any Hindu temple in India — outer colonnades commonly measured around 3,850 feet in total length with over a thousand pillars — largely associated with Sethupathi patronage (notably Muthuramalinga Sethupathy) atop earlier Pandya and later expansions, including renovations linked to Jaffna kingdom rulers.\n\n'
        'Pilgrims traditionally bathe at Agni Theertham on the seashore and then in the twenty-two temple wells/theerthams said to represent Rama’s twenty-two arrows, before sanctum darshan. The complex thus unites stala, murti, and theertham in a single pilgrimage circuit unique on the island.',
    location: 'Rameswaram, Ramanathapuram, Tamil Nadu 623526',
    timings:
        'TN HR&CE: temple opens 4:00 AM; devotees admitted from 5:00 AM. Spatika linga pooja '
        '5:00–6:00 AM; main sanctum darshan from ~6:10 AM until 1:00 PM. Reopens 3:00 PM; darshan '
        '~3:15 PM–8:00 PM. 22 theerthams for bathing: 5:30 AM–12:30 PM and 3:00 PM–7:00 PM. '
        'Evening close is earlier than some older tourist listings (which said 9:00 PM) — prefer '
        'HR&CE.',
    latitude: 9.2882,
    longitude: 79.3174,
    specialities: [
      'Southernmost Jyotirlinga & Char Dham site',
      'Longest temple corridor complex in India',
      '22 sacred theerthams + Agni Theertham sea bath',
      'Ramalingam (sand) and Viswalingam tradition',
      'Paadal Petra Sthalam',
    ],
  ),
  Temple(
    name: 'Murugan Temple, Thirupparankundram',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Murugan',
    imageUrl: 'https://picsum.photos/seed/thirupparankundram/800/600',
    description:
        'First of Murugan’s six Arupadai Veedu, a Pandya-era rock-cut cave temple in a Madurai '
        'hillside where tradition places Murugan’s marriage to Devasena after the defeat of '
        'Surapadman.',
    story:
        'Arulmigu Subramaniyaswamy Temple at Thirupparankundram (Tirupparankunram) is counted as the first of the Arupadai Veedu — the six foremost battle-abodes of Murugan in Tamil tradition. The shrine is carved into a rocky hillock on Madurai’s southwestern fringe and is administered by the Tamil Nadu HR&CE department.\n\n'
        'Early rock-cut work is attributed to the Pandyas from about the 6th century CE, with later structural additions including a tall rajagopuram and outer mandapas. Unusually, the cave complex also houses facing shrines that bring Shiva, Vishnu, Vinayaka, and Durga into the same sacred topography as Murugan, underscoring a syncretic local cult.\n\n'
        'Legend places Murugan’s victory over the asura Surapadman and his subsequent wedding to Devasena (Deivayanai), daughter of Indra, at this hill. The divine marriage is re-enacted in festival time; Skanda Shashti (Aipasi) dramatises the Surasamharam, while Panguni Brahmotsavam links processional images with Madurai’s Meenakshi wedding cycle.\n\n'
        'Karthigai Deepam sees a lamp lit atop the hill; Vaikasi Visakam marks Murugan’s birth star; a float festival in Thai and Vaikunta Ekadashi (owing to the Vishnu presence) broaden the calendar. Jain beds and carvings on parts of the hill speak to a longer multi-religious use of the rock.',
    location: 'Thirupparankundram, Madurai, Tamil Nadu 625005',
    timings:
        'TN HR&CE: 5:30 AM–1:00 PM and 4:00 PM–9:00 PM (closed ~1:00–4:00 PM). Named poojas '
        '(HR&CE list): Thiruvanandal 5:30–6:00 AM; Vilaa ~7:00–7:30 AM; Kalasandhi ~8:00–8:30 AM; '
        'Thirukalasanthi ~10:30–11:00 AM; Uchikkala ~12:30–1:00 PM; Sayaraksha ~5:30–6:00 PM; '
        'Ardhajama ~8:30–9:00 PM; Palliyarai ~9:00–9:15 PM. Festival schedules may differ.',
    latitude: 9.8798,
    longitude: 78.0711,
    specialities: [
      'Arupadai Veedu — first abode of Murugan',
      'Pandya rock-cut cave architecture',
      'Murugan–Devasena wedding legend',
      'Skanda Shashti Surasamharam',
      'Multi-deity cave (Shiva, Vishnu, Vinayaka, Durga)',
      'Hilltop Karthigai Deepam',
    ],
  ),
  Temple(
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/shoretemple/800/600',
    description:
        'UNESCO World Heritage Pallava structural temple (c. 725 CE) on the Bay of Bengal at '
        'Mahabalipuram, with twin Shiva shrines and a reclining Vishnu shrine — among the '
        'earliest major stone-built temples of South India.',
    story:
        'The Shore Temple complex was raised in granite under Pallava king Narasimhavarman II (Rajasimha), around the early 8th century CE (commonly c. 700–728), at the then-busy port of Mamallapuram. It forms part of the Group of Monuments at Mahabalipuram, inscribed on the UNESCO World Heritage List in 1984, and is protected by the Archaeological Survey of India.\n\n'
        'Unlike the site’s famous rock-cut caves and monolithic rathas, the Shore Temple is a structural temple of quarried granite blocks. Three shrines share one platform: a larger east-facing Shiva shrine, a smaller Shiva shrine behind, and a rectangular shrine to reclining Vishnu (Anantashayi) between them — inscriptions preserve Pallava royal titles for these houses of worship.\n\n'
        'European travellers knew the coast as the ‘Seven Pagodas’; local memory held that sister temples had been swallowed by the sea. The December 2004 Indian Ocean tsunami briefly exposed offshore structural remains and rock sculptures, renewing scholarly and public interest in the submerged-pagoda tradition, though the Shore Temple itself largely withstood the waves thanks to its granite foundation and protective groynes.\n\n'
        'Today the monument is primarily an ASI heritage site rather than a conventional living temple with dense daily pooja schedules; visitors come for architecture, sea light, and the Mamallapuram Dance Festival backdrop. Conservation includes breakwaters, chemical treatment against salt spray, and landscaped gardens maintained by ASI.',
    location: 'Mahabalipuram, Chengalpattu, Tamil Nadu 603104',
    timings:
        'ASI monument hours commonly 6:00 AM–6:00 PM daily (Incredible India / visitor listings '
        'also cite 6:00 AM–6:00 PM; ticket counters may close slightly earlier). This is a '
        'ticketed World Heritage monument, not a typical HR&CE darshan temple — no named daily '
        'pooja slots for public worship in the same sense as living kovils. Confirm current ASI '
        'ticket rates and any temporary closures before visit.',
    latitude: 12.6164,
    longitude: 80.1986,
    specialities: [
      'UNESCO Group of Monuments at Mahabalipuram (1984)',
      'Early Pallava structural granite temple',
      'Twin Shiva shrines + reclining Vishnu',
      'Seven Pagodas / submerged temples legend',
      'ASI conservation & seaside setting',
      'Mamallapuram Dance Festival backdrop',
    ],
  ),
  Temple(
    name: 'Nataraja Temple',
    state: 'Tamil Nadu',
    city: 'Chidambaram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/nataraja/800/600',
    description:
        'Thillai Nataraja Temple where Shiva is worshipped as the cosmic dancer; home of the '
        'Chidambara Rahasyam and the Akasha (space) linga among the Pancha Bootha Sthalams.',
    story:
        'Chidambaram’s Thillai Nataraja Temple is unique among major Shaiva centres for enshrining Shiva primarily as Nataraja — lord of the cosmic dance — in the golden Sabha, rather than solely as a stone linga. It is the Pancha Bootha Sthalam of Akasha (space/ether), completing the elemental set with earth (Kanchipuram), water (Tiruvanaikkaval), fire (Tiruvannamalai), and air (Srikalahasti).\n\n'
        'The Chidambara Rahasyam (‘secret of Chidambaram’) is revealed when priests draw aside a curtain in the sanctum to show empty space adorned with golden bilva leaves — a ritual pointer to the formless Absolute beyond icon and linga. A spatika (crystal) linga and other processional images also receive elaborate abhishekams through the day.\n\n'
        'Medieval Chola and later dynasties expanded the vast precinct with four towering gopurams whose tiers display the 108 karanas of Bharatanatyam — making the temple a living textbook of dance. The Dikshitar priestly tradition and continuous Agamic worship give Chidambaram a distinctive liturgical identity.\n\n'
        'Natyanjali, held around Maha Shivaratri, invites classical dancers to offer performance as worship on the temple premises, reinforcing the bond between Nataraja theology and South Indian performing arts.',
    location: 'Car Street, Chidambaram, Cuddalore, Tamil Nadu 608001',
    timings:
        'Official temple site (chidambaramnataraja.org): darshan 6:00 AM–12:00 noon and 5:00 '
        'PM–10:00 PM. Daily pooja markers from the same site: Paal Nivedhyam ~6:30 AM; Maha '
        'Aarthi ~7:00 AM; Kalasandhi 7:45–9:00 AM (includes spatika linga abhishekam); Irandaam '
        'Kaalam 10:00–11:00 AM; Uchikaalam 11:30 AM–12:00 noon (temple then closes); Sayarakshai '
        '5:15–6:00 PM; evening Irandaam Kaalam 7:00–8:00 PM (includes Chidambara Rahasya pooja); '
        'Ardhajaamam 9:00–10:00 PM. Note: some tourist listings open evenings at 4:30 PM — prefer '
        'the temple’s own 5:00 PM evening opening.',
    latitude: 11.3994,
    longitude: 79.6937,
    specialities: [
      'Nataraja — cosmic dancer form',
      'Chidambara Rahasyam (formless space)',
      'Pancha Bootha Sthalam — Akasha/Space',
      'Gopurams with 108 Bharatanatyam karanas',
      'Natyanjali dance festival at Shivaratri',
      'Spatika linga & Rathnasabhapathi abhishekams',
    ],
  ),
  Temple(
    name: 'Ekambaranathar Temple',
    state: 'Tamil Nadu',
    city: 'Kanchipuram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ekambaranathar/800/600',
    description:
        'Vast Kanchipuram Shaiva complex and Pancha Bootha Sthalam of Earth (Prithvi), famed for '
        'its ~59 m rajagopuram, thousand-pillared hall, and the sacred mango tree tied to '
        'Parvati’s penance legend.',
    story:
        'Ekambareswarar / Ekambaranathar Temple is Kanchipuram’s great Earth-element shrine among the Pancha Bootha Sthalams: Shiva as Prithvi Lingam, ‘Lord of the Mango Tree’ (Ekambaranathar). It is a Paadal Petra Sthalam praised in the Tevaram of the Nayanars and one of the city’s largest sacred precincts (on the order of 23–25 acres).\n\n'
        'Legend tells that Parvati performed penance under a mango tree by the Vegavati, fashioning a linga of sand. When floodwaters threatened the fragile linga, she embraced it; Shiva, moved, appeared and accepted her — hence titles such as Tazhuvakuzhainthaar (‘he who melted in her embrace’). The sthala vriksha — a venerable mango tree whose four branches are traditionally said to yield different fruit and to symbolise the four Vedas — still stands behind the sanctum in temple lore (ages of ‘3,500 years’ are traditional claims, not dendrochronology).\n\n'
        'Pallava origins and Chola rebuilding underlie a fabric later expanded by Vijayanagara rulers; the eleven-storey southern rajagopuram associated with Krishnadevaraya rises roughly 57–59 m. Inside are Vijayanagara halls including the Aayiram Kaal Mandapam, multiple prakaras, and — unusually — a Vishnu shrine (Nilathingal Thundam Perumal) counted among the 108 Divya Desams within the Shaiva complex.\n\n'
        'Because the linga is of sand, abhishekam is performed to the pedestal rather than directly on the fragile form. Panguni Uthiram / Panguni Brahmotsavam, culminating in Kalyanotsavam, is the town’s most prominent temple festival.',
    location: 'Ekambaranathar Koil St, Kanchipuram, Tamil Nadu 631502',
    timings:
        'Widely listed HR&CE/visitor windows: 6:00 AM–12:30 PM and 4:00 PM–8:30 PM (confirm on '
        'HR&CE tid=1816). Classical six-kala rhythm reported in secondary sources includes '
        'Ushathkalam ~5:30 AM through Ardha Jamam late evening — exact public access windows can '
        'differ from priestly ritual clocks. Festival days (esp. Panguni) extend processions into '
        'city streets.',
    latitude: 12.8475,
    longitude: 79.7,
    specialities: [
      'Pancha Bootha Sthalam — Earth/Prithvi',
      'Rajagopuram ~57–59 m (Vijayanagara)',
      'Sacred mango tree (sthala vriksha) legend',
      'Sand (Prithvi) linga — abhishekam to pedestal',
      'Thousand-pillared hall',
      'Nilathingal Thundam Perumal Divya Desam inside complex',
      'Panguni Brahmotsavam / Kalyanotsavam',
    ],
  ),
  Temple(
    name: 'Arunachaleswarar Temple',
    state: 'Tamil Nadu',
    city: 'Tiruvannamalai',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/arunachaleswarar/800/600',
    description:
        'Monumental Pancha Bootha Sthalam of Fire at the foot of Arunachala hill, centre of '
        'Girivalam circumambulation and the Karthigai Deepam beacon lit atop the mountain.',
    story:
        'Arunachaleswarar / Annamalaiyar Temple at Tiruvannamalai is the Agni (fire) shrine among the Pancha Bootha Sthalams. Shiva is worshipped as Annamalaiyar — identified with the sacred Arunachala hill itself — and Parvati as Unnamulai Amman. The complex, among India’s largest temple campuses, grew from Chola-period masonry with major Vijayanagara and Nayaka expansions; the eastern Rajagopuram rises about 66 m across eleven storeys.\n\n'
        'Puranic legend recounts the dispute between Brahma and Vishnu over supremacy. Shiva appeared as an endless column of fire (jyotirlinga). Vishnu as Varaha failed to find its base; Brahma as a swan falsely claimed to have found its summit and was cursed. The hill and temple re-present that pillar of light; Karthigai Deepam’s hilltop flame ritually renews the theophany each year.\n\n'
        'A related myth tells of Parvati’s penance at Tiruvannamalai after an episode that darkened the world, her victory over Mahishasura in Durga form, and Shiva’s acceptance of her on Karthigai pournami — themes woven into Deepam liturgy.\n\n'
        'Every full moon, lakhs of pilgrims walk Girivalam / Giripradakshina — roughly 14 km barefoot around Arunachala — considered a powerful act of atonement and wish-fulfilment. Modern spiritual history also links the hill to Ramana Maharshi, whose ashram and pathala lingam associations draw seekers alongside traditional Shaiva devotees. Tevaram, Tiruvempavai, and Tiruppugazh place the shrine firmly in classical Tamil sacred literature.',
    location: 'Tiruvannamalai, Tamil Nadu 606601',
    timings:
        'Living temple with six daily ritual cycles commonly spanning roughly 5:30 AM to ~10:00 '
        'PM (Wikipedia summary of temple practice). Public darshan windows reported on '
        'tourism/HR&CE-facing pages vary (sample app used 5:30 AM–12:30 PM & 3:30–9:30 PM; some '
        'HR&CE-facing notes mention longer midday continuity and earlier weekend/pournami '
        'cutoffs). VERIFY on official portal https://annamalaiyar.hrce.tn.gov.in/ before '
        'publishing push notifications — crowd and pournami days change access. Karthigai Deepam: '
        'Bharani Deepam in temple pre-dawn and Maha Deepam on the hill at evening — dates shift '
        'yearly with the Tamil calendar.',
    latitude: 12.2316,
    longitude: 79.0672,
    specialities: [
      'Pancha Bootha Sthalam — Fire/Agni',
      'Karthigai Deepam hilltop beacon',
      'Girivalam (~14 km) full-moon circumambulation',
      'Rajagopuram ~66 m / vast 25-acre campus',
      'Paadal Petra Sthalam',
      'Ramana Maharshi spiritual associations nearby',
    ],
  ),
  Temple(
    name: 'Sarangapani Temple',
    state: 'Tamil Nadu',
    city: 'Kumbakonam',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/sarangapani/800/600',
    description:
        'Largest Vishnu temple in Kumbakonam and a Divya Desam / Pancharanga Kshetram, with an '
        '11-tier ~173 ft rajagopuram and a chariot-shaped sanctum recalling Vishnu’s descent from '
        'Vaikuntha.',
    story:
        'Sarangapani Temple is Kumbakonam’s premier Vishnu shrine — one of the 108 Divya Desams sung by the Alvars and one of the Pancharanga Kshetrams along the Kaveri. ‘Sarangapani’ means the lord who holds the bow Saranga. Medieval Chola, Vijayanagara, and Madurai Nayaka layers shape the granite-walled complex.\n\n'
        'Temple legend says sage Hema Rishi performed penance on the banks of the Potramarai tank seeking Lakshmi as his daughter. Lakshmi emerged from the tank among lotuses as Komalavalli; Vishnu descended from Vaikuntha as Aravamudhan in a chariot drawn by horses and elephants, wooed her, and the divine marriage followed. The central shrine’s chariot form — with sculpted wheels and openings on either side — architecturally stages that descent.\n\n'
        'The eleven-tier rajagopuram rises about 173 ft (53 m), the tallest in town; five lesser gopurams and the Potramarai tank opposite the western entrance complete the skyline. Twin wooden temple chariots, among the heaviest in Tamil Nadu (often cited near 300 tonnes each), dominate the Chittirai Brahmotsavam.\n\n'
        'Worship follows Pancharatra Agama in the Vadakalai tradition, with six daily ritual services. Kumbakonam’s wider sacred geography — including the Mahamaham tank’s twelve-year festival — places Sarangapani within a dense Vaishnava–Shaiva pilgrimage mesh.',
    location: 'Sarangapani East Sannadhi St, Kumbakonam, Tamil Nadu 612001',
    timings:
        'Official temple history/pooja pages list six daily rituals: Tiruvanandal 8:00 AM; Kala '
        'Santhi 9:00 AM; Uchikalam 12:30 PM; Nithyanusandhanam 6:00 PM; Irandamkalam 7:30 PM; '
        'Ardha Jamam 9:00 PM (also mirrored at sarangapanitemple.org / related temple sites). '
        'Public visiting hours are commonly quoted around morning opening near 6:00–7:00 AM to '
        '~12:00/12:30 PM and evening ~4:00/4:30–9:00 PM — confirm locally; ritual clock and gate '
        'hours are not always identical. Festival chariot days override ordinary schedules.',
    latitude: 10.9617,
    longitude: 79.3881,
    specialities: [
      '108 Divya Desam',
      'Pancharanga Kshetram on the Kaveri',
      '11-tier rajagopuram ~173 ft',
      'Chariot-shaped sanctum (Vishnu’s descent)',
      'Twin ~300-tonne temple chariots',
      'Chittirai Brahmotsavam',
      'Potramarai temple tank legend',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  KERALA
  // ═══════════════════════════════════════════════════════════════════════════
  Temple(
    name: 'Guruvayur Sri Krishna Temple',
    state: 'Kerala',
    city: 'Guruvayur',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/guruvayur/800/600',
    description:
        'Often called the Dwarka of the South, this temple houses a four-armed Vishnu idol believed to have been worshipped by Guru (Brihaspati) and Vayu — hence the name Guruvayur.',
    story:
        'When Dwarka was submerged by the sea, Guru (Brihaspati) and Vayu carried the idol of Krishna and installed it at this sacred spot. The idol is said to represent Vishnu in the Chaturbhuja (four-armed) form as he appeared at the time of Krishna\'s birth.',
    location: 'East Nada, Guruvayur, Thrissur, Kerala 680101',
    timings: '3:00 AM – 1:00 PM, 4:30 PM – 10:00 PM',
    latitude: 10.5946,
    longitude: 76.0408,
    specialities: [
      'Elephant processions (Aanayottam)',
      'Krishna Janmashtami celebrations',
      'Guruvayur Ekadasi festival',
      'Strict dress code & non-Hindu restriction',
    ],
  ),
  Temple(
    name: 'Sree Padmanabhaswamy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/padmanabhaswamy/800/600',
    description:
        'A Dravidian-style Vishnu temple famous for its reclining Padmanabha idol visible through three doors, and its legendary treasure vaults estimated to hold over ₹1 lakh crore in assets.',
    story:
        'The Travancore royal family dedicated the kingdom to Lord Padmanabha and ruled as Padmanabha Dasa (servants of the Lord). In 2011, Vault B\'s unopened chambers generated worldwide intrigue about ancient treasures stored for centuries.',
    location: 'West Nada, Fort, Thiruvananthapuram, Kerala 695023',
    timings: '3:30 AM – 12:00 PM, 5:00 PM – 7:20 PM',
    latitude: 8.4826,
    longitude: 76.9443,
    specialities: [
      'Reclining Vishnu visible through 3 doors',
      'Legendary treasure vaults',
      'Strict traditional dress code',
      'Laksha Deepam (100,000 lamps) festival',
    ],
  ),
  Temple(
    name: 'Sabarimala Ayyappan Temple',
    state: 'Kerala',
    city: 'Pathanamthitta',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/sabarimala/800/600',
    description:
        'Perched at 914 metres in the Western Ghats, this temple dedicated to Lord Ayyappa receives over 50 million pilgrims annually during the Mandala-Makaravilakku season, making it one of the largest annual pilgrimages in the world.',
    story:
        'Ayyappa, born of Shiva and Vishnu (as Mohini), was adopted by the Pandalam king. He defeated the demoness Mahishi and chose this hilltop for meditation. Devotees undertake 41 days of austerity (Vratham) before trekking to the summit.',
    location: 'Sabarimala, Pathanamthitta, Kerala 689711',
    timings: 'Open during Mandalam (Nov–Jan) & Vishu seasons',
    latitude: 9.4358,
    longitude: 77.0763,
    specialities: [
      'Mandala Vratham (41-day penance)',
      'Makaravilakku divine light',
      '18 sacred steps (Pathinettam Padi)',
      '50 million+ annual pilgrims',
    ],
  ),
  Temple(
    name: 'Attukal Bhagavathy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/attukal/800/600',
    description:
        'Known as the Sabarimala of women, this temple hosts the Attukal Pongala — the largest gathering of women for a single religious event, holding a Guinness World Record with over 3.5 million women participants.',
    story:
        'The goddess is believed to be Kannaki from the Tamil epic Silappatikaram, who arrived in Kerala after burning Madurai in rage over her husband Kovalan\'s unjust execution. She settled here and is worshipped as Bhagavathy.',
    location: 'Attukal, Manacaud, Thiruvananthapuram, Kerala 695009',
    timings: '4:30 AM – 12:00 PM, 5:00 PM – 8:30 PM',
    latitude: 8.4770,
    longitude: 76.9553,
    specialities: [
      'Guinness Record Attukal Pongala',
      'Largest women-only religious gathering',
      'Kannaki legend from Silappatikaram',
      '10-day Pongala festival',
    ],
  ),
  Temple(
    name: 'Chottanikkara Bhagavathy Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chottanikkara/800/600',
    description:
        'A unique temple where the goddess is worshipped in three forms throughout the day — Saraswati in the morning, Lakshmi at noon, and Durga in the evening — each with a change of alankaram (decoration).',
    story:
        'The temple is famous for Guruthi Pooja performed at the Keezhkavu (lower temple) at night, believed to cure mental ailments and possession. Devotees suffering from psychological troubles have reported relief after the intense ritual.',
    location: 'Chottanikkara, Ernakulam, Kerala 682312',
    timings: '4:00 AM – 12:00 PM, 5:00 PM – 8:30 PM',
    latitude: 10.0055,
    longitude: 76.3786,
    specialities: [
      'Three-form goddess worship daily',
      'Guruthi Pooja healing ritual',
      'Makam Thozhal annual event',
      'Keezhkavu night ceremonies',
    ],
  ),
  Temple(
    name: 'Ernakulathappan Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ernakulathappan/800/600',
    description:
        'Dedicated to Lord Shiva, this temple in the heart of Kochi city gave Ernakulam its name and is known for the grand 8-day Ernakulathappan Uthsavam festival with caparisoned elephants.',
    story:
        'The city of Ernakulam derives its name from this temple — Eravankulam (the land of Lord Shiva). The temple\'s festival features Panchavadyam, Pandi Melam, and a spectacular display of fireworks that lights up the Kochi skyline.',
    location: 'Durbar Hall Road, Ernakulam, Kochi, Kerala 682011',
    timings: '4:00 AM – 11:00 AM, 5:00 PM – 8:00 PM',
    latitude: 9.9937,
    longitude: 76.2914,
    specialities: [
      'City gets its name from this temple',
      'Ernakulathappan Uthsavam (8 days)',
      'Caparisoned elephant procession',
      'Central Kochi lakeside location',
    ],
  ),
  Temple(
    name: 'Vaikom Mahadeva Temple',
    state: 'Kerala',
    city: 'Kottayam',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/vaikom/800/600',
    description:
        'One of the oldest Shiva temples in Kerala, historically significant for the Vaikom Satyagraha (1924–25), a landmark movement for lower-caste temple entry rights led by social reformers.',
    story:
        'The Vaikom Satyagraha was a mass movement against untouchability, supported by Mahatma Gandhi and led by T.K. Madhavan and others. It resulted in roads around the temple being opened to all castes, becoming a precursor to the Temple Entry Proclamation of 1936.',
    location: 'Vaikom, Kottayam, Kerala 686141',
    timings: '4:00 AM – 11:30 AM, 5:00 PM – 8:30 PM',
    latitude: 9.7486,
    longitude: 76.3952,
    specialities: [
      'Historic Vaikom Satyagraha site',
      'Vaikathashtami festival (12 days)',
      'Ancient laterite architecture',
      'Social reform landmark',
    ],
  ),
  Temple(
    name: 'Anjengo Sree Durga Devi Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/anjengo/800/600',
    description:
        'The Anjengo Sree Durga Devi Temple near the historic Anjengo Fort dates back centuries and stands as a guardian shrine at the site of Kerala\'s earliest European trade encounters.',
    story:
        'Anjengo (Anchuthengu) was the first English settlement in Kerala, established in 1684. The Durga temple near the fort served as a spiritual anchor for local fishermen and traders who navigated these coastal waters for generations.',
    location: 'Anchuthengu, Thiruvananthapuram, Kerala 695309',
    timings: '5:00 AM – 12:00 PM, 5:00 PM – 8:00 PM',
    latitude: 8.6833,
    longitude: 76.7667,
    specialities: [
      'Coastal heritage setting',
      'Adjacent Anjengo Fort ruins',
      'Ancient fishing village shrine',
      'European colonial history backdrop',
    ],
  ),
  Temple(
    name: 'Mannarsala Sree Nagaraja Temple',
    state: 'Kerala',
    city: 'Alappuzha',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/mannarsala/800/600',
    description:
        'The largest and most famous serpent temple in Kerala, set in a dense sacred grove with over 30,000 nagam (serpent) idols. Uniquely, the head priestess (Valia Amma) performs the daily pujas.',
    story:
        'Legend says Parashurama created Kerala by throwing his axe into the sea. The land that rose was infested with serpents. Vasuki\'s representative agreed to protect the land if serpents were worshipped. The Valia Amma (head priestess) tradition makes this one of the rare temples with a female chief priest.',
    location: 'Mannarsala, Haripad, Alappuzha, Kerala 690513',
    timings: '5:00 AM – 12:00 PM, 5:00 PM – 7:30 PM',
    latitude: 9.2760,
    longitude: 76.4350,
    specialities: [
      'Female head priestess tradition',
      '30,000+ serpent idols in sacred grove',
      'Ayilyam Pooja for fertility',
      'Uruli Kamazhthal offering ritual',
    ],
  ),
  Temple(
    name: 'Thirunelli Maha Vishnu Temple',
    state: 'Kerala',
    city: 'Wayanad',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/thirunelli/800/600',
    description:
        'Known as the Kashi of the South, this ancient Vishnu temple nestled in the Brahmagiri hills of Wayanad is surrounded by pristine forests and is a site for ancestral rites (Pitru Tharpanam).',
    story:
        'Brahma is said to have consecrated this temple atop the Brahmagiri hills. The Papanashini stream flowing nearby is believed to wash away all sins. Families perform last rites and ancestral ceremonies here, similar to Varanasi on the Ganges.',
    location: 'Thirunelli, Wayanad, Kerala 670646',
    timings: '5:30 AM – 12:00 PM, 5:00 PM – 7:30 PM',
    latitude: 11.9107,
    longitude: 75.9978,
    specialities: [
      'Kashi of the South',
      'Pitru Tharpanam ancestral rites',
      'Brahmagiri hills forest setting',
      'Papanashini sacred stream',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  KARNATAKA
  // ═══════════════════════════════════════════════════════════════════════════
  Temple(
    name: 'Sri Krishna Matha (Udupi)',
    state: 'Karnataka',
    city: 'Udupi',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/udupi/800/600',
    description:
        'Founded by Sri Madhvacharya in the 13th century, this Krishna temple is famous for darshan through a silver-plated window (Kanakana Kindi) and the unique Paryaya system of rotating pontiffs every two years.',
    story:
        'Madhvacharya found the idol of Krishna inside a lump of gopichandana clay from a shipwreck. A devoted low-caste saint named Kanakadasa was denied entry, so Krishna turned around to face the western window so Kanakadasa could see him — hence the Kanakana Kindi.',
    location: 'Car Street, Udupi, Karnataka 576101',
    timings: '5:30 AM – 1:00 PM, 4:00 PM – 8:30 PM',
    latitude: 13.3358,
    longitude: 74.7460,
    specialities: [
      'Kanakana Kindi silver window',
      'Paryaya biennial pontiff rotation',
      'Famous Udupi cuisine origin',
      'Madhvacharya\'s Dvaita Vedanta seat',
    ],
  ),
  Temple(
    name: 'Sri Manjunatha Temple, Dharmasthala',
    state: 'Karnataka',
    city: 'Dharmasthala',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/dharmasthala/800/600',
    description:
        'A rare temple where a Shiva lingam is worshipped by a Jain Heggade (administrator), symbolising religious harmony. The 39-foot Bahubali statue here is the tallest free-standing statue in the region.',
    story:
        'The Heggade family has administered this temple for over 800 years despite being Jains, while the priests are Vaishnavite Brahmins. This unique arrangement of interfaith administration is considered a model of dharmic coexistence.',
    location: 'Dharmasthala, Belthangady Taluk, Dakshina Kannada, Karnataka 574216',
    timings: '6:30 AM – 2:00 PM, 5:00 PM – 8:30 PM',
    latitude: 12.9623,
    longitude: 75.3724,
    specialities: [
      'Jain-Hindu interfaith administration',
      '39-foot Bahubali monolith',
      'Free Annadanam (mass feeding)',
      'Laksha Deepotsava festival',
    ],
  ),
  Temple(
    name: 'Kukke Subramanya Temple',
    state: 'Karnataka',
    city: 'Sullia',
    deity: 'Murugan',
    imageUrl: 'https://picsum.photos/seed/kukkesubramanya/800/600',
    description:
        'Nestled in the Western Ghats, this temple to Lord Subramanya (Murugan) is the most important centre for Sarpa Dosha Nivarana (remedies for serpent-related planetary afflictions) in South India.',
    story:
        'After Garuda pursued Vasuki and the serpents, they sought refuge with Lord Subramanya here. He granted them protection, and the site became the premier pilgrimage for Naga worship and Sarpa Dosha remedies.',
    location: 'Kukke Subramanya, Sullia Taluk, Dakshina Kannada, Karnataka 574238',
    timings: '6:30 AM – 1:30 PM, 4:00 PM – 8:30 PM',
    latitude: 12.6772,
    longitude: 75.6182,
    specialities: [
      'Sarpa Dosha Nivarana centre',
      'Adi Subramanya cave shrine',
      'Western Ghats rainforest setting',
      'Champa Shashti festival',
    ],
  ),
  Temple(
    name: 'Sringeri Sharada Peetham',
    state: 'Karnataka',
    city: 'Sringeri',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/sringeri/800/600',
    description:
        'The southern seat of the four mathas established by Adi Shankaracharya in the 8th century, set on the banks of the Tunga river amid lush Malnad forests with exquisite Hoysala and Vijayanagara art.',
    story:
        'Adi Shankara chose this spot after witnessing a cobra spread its hood to shade a frog in labour — a sign of supreme peace. The Sharadamba idol, carved from sandalwood, and the Vidyashankara temple with its 12 zodiac pillars are famed.',
    location: 'Sringeri, Chikkamagaluru, Karnataka 577139',
    timings: '6:00 AM – 2:00 PM, 4:00 PM – 9:00 PM',
    latitude: 13.4198,
    longitude: 75.2524,
    specialities: [
      'Adi Shankaracharya\'s southern matha',
      'Vidyashankara Temple (12 zodiac pillars)',
      'Sandalwood Sharadamba idol',
      'Tunga riverside Malnad setting',
    ],
  ),
  Temple(
    name: 'Kollur Mookambika Temple',
    state: 'Karnataka',
    city: 'Kollur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mookambika/800/600',
    description:
        'A revered Shakti temple at the foot of Kodachadri peak, where Goddess Mookambika vanquished the demon Mookasura. The Jyotirlinga-like Swayanmbhu Linga here has the unique feature of Shiva and Shakti united.',
    story:
        'The demon Mookasura performed severe penance to gain power. When Shiva was about to grant him a boon, Parvati struck him dumb (mooka) to prevent misuse. She then slayed him and took residence here as Mookambika — she who defeated Mooka.',
    location: 'Kollur, Udupi, Karnataka 576220',
    timings: '6:00 AM – 1:30 PM, 3:30 PM – 8:30 PM',
    latitude: 13.8627,
    longitude: 74.8137,
    specialities: [
      'Shakti-Shiva united Linga',
      'Kodachadri peak trek',
      'Navaratri grand celebrations',
      'Souparnika river sacred bath',
    ],
  ),
  Temple(
    name: 'Mahabaleshwar Temple, Gokarna',
    state: 'Karnataka',
    city: 'Gokarna',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/gokarna/800/600',
    description:
        'Home to the Pranalinga (Atmalinga), this ancient Shiva temple in the coastal pilgrimage town of Gokarna is considered as sacred as Varanasi and holds one of the original Shiva Lingas.',
    story:
        'Ravana obtained the Atmalinga from Shiva but was tricked by Ganesha (disguised as a boy) into placing it on the ground at Gokarna. Once grounded, the Linga could never be uprooted, and it remains enshrined here.',
    location: 'Gokarna, Uttara Kannada, Karnataka 581326',
    timings: '6:00 AM – 12:30 PM, 5:00 PM – 8:00 PM',
    latitude: 14.5479,
    longitude: 74.3188,
    specialities: [
      'Pranalinga (Atmalinga) shrine',
      'Beach town pilgrimage vibe',
      'Om Beach and Kudle Beach nearby',
      'Shivaratri grand celebration',
    ],
  ),
  Temple(
    name: 'Chamundeshwari Temple',
    state: 'Karnataka',
    city: 'Mysuru',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chamundeshwari/800/600',
    description:
        'Atop the 1000+ steps of Chamundi Hill, this temple is dedicated to Goddess Chamundeshwari, the fierce form of Durga who slayed the buffalo demon Mahishasura — the demon from whom Mysuru gets its name.',
    story:
        'The demon Mahishasura terrorised the gods until Goddess Chamundeshwari (Durga) battled him for nine days and slayed him on the tenth (Vijayadashami). The Mysuru Dasara festival commemorates this victory and is Karnataka\'s grandest celebration.',
    location: 'Chamundi Hill, Mysuru, Karnataka 570010',
    timings: '7:30 AM – 2:00 PM, 3:30 PM – 6:00 PM, 7:30 PM – 9:00 PM',
    latitude: 12.2724,
    longitude: 76.6703,
    specialities: [
      'Mysuru Dasara (Navaratri) festival',
      '5-metre Nandi bull on hillside',
      '1000+ steps hillclimb tradition',
      'Mahishasura statue at hilltop',
    ],
  ),
  Temple(
    name: 'Virupaksha Temple',
    state: 'Karnataka',
    city: 'Hampi',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/virupaksha/800/600',
    description:
        'A UNESCO World Heritage Site and the most ancient functioning temple in Hampi, dedicated to Lord Virupaksha (Shiva), serving as the principal deity of the Vijayanagara Empire for over 700 years.',
    story:
        'The temple has been in continuous worship since the 7th century, long before the Vijayanagara Empire made it their royal temple. Lakshmi, the temple elephant, blesses visitors with her trunk and is an iconic presence at the entrance.',
    location: 'Hampi Bazaar, Hampi, Ballari, Karnataka 583239',
    timings: '6:00 AM – 1:00 PM, 5:00 PM – 9:00 PM',
    latitude: 15.3350,
    longitude: 76.4600,
    specialities: [
      'UNESCO World Heritage Site',
      'Lakshmi the temple elephant',
      'Hampi bazaar ruins backdrop',
      'Vijaya Utsav (Hampi Festival)',
    ],
  ),
  Temple(
    name: 'Srikanteshwara Temple, Nanjangud',
    state: 'Karnataka',
    city: 'Nanjangud',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/nanjangud/800/600',
    description:
        'Known as the Dakshina Kashi (Varanasi of the South), this grand Shiva temple on the Kapila river bank features a 120-foot gopuram and Dravidian architecture spanning the Ganga, Chola, and Mysore periods.',
    story:
        'When the serpent Vasuki was exhausted from churning the ocean of milk and released deadly poison (Halahala), Shiva drank it. The poison burned his throat, and he came to this spot on the Kapila river to cool down — hence the name Nanjundeshwara (Lord who drank poison).',
    location: 'Nanjangud, Mysuru District, Karnataka 571301',
    timings: '6:00 AM – 1:00 PM, 4:00 PM – 8:30 PM',
    latitude: 12.1168,
    longitude: 76.6839,
    specialities: [
      'Dakshina Kashi (Southern Varanasi)',
      '120-foot gopuram',
      'Kapila river bank rituals',
      'Dodda Jathre annual chariot festival',
    ],
  ),
  Temple(
    name: 'ISKCON Temple, Bangalore',
    state: 'Karnataka',
    city: 'Bengaluru',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/iskconbangalore/800/600',
    description:
        'One of the largest ISKCON temples in the world, this modern temple complex on Hare Krishna Hill features Vedic architecture, the Akshaya Patra foundation kitchen feeding 1.8 million children daily, and a cultural centre.',
    story:
        'Built in 1997 on a 7-acre hilltop donated by the Karnataka government, the temple blends traditional Dravidian and modern architecture. Its Akshaya Patra midday meal programme, launched in 2000, became the world\'s largest school lunch programme.',
    location: 'Hare Krishna Hill, Chord Rd, Rajajinagar, Bengaluru, Karnataka 560010',
    timings: '4:15 AM – 1:00 PM, 4:00 PM – 8:30 PM',
    latitude: 13.0104,
    longitude: 77.5510,
    specialities: [
      'Akshaya Patra (1.8M meals/day)',
      'Vedic cultural centre',
      'Janmashtami grand celebrations',
      'Hare Krishna Hill panoramic views',
    ],
  ),
];
