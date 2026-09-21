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
    location:
        'Kapaleeshwarar Sannadhi St, Mylapore, Chennai, Tamil Nadu 600004',
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
  // Research-enriched visitor copy for the existing 10 Kerala temples
  // (matched by name/slug — no new documents). Cover imageUrl values remain
  // the bundled picsum placeholders; do not treat Commons candidates as Storage
  // paths. Sources and photo_candidates: docs/kerala-sample-research.md.
  Temple(
    name: 'Guruvayur Sri Krishna Temple',
    state: 'Kerala',
    city: 'Guruvayur',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/guruvayur/800/600',
    description:
        'Often called Bhuloka Vaikuntha or the Dwarka of the South, Guruvayurappan’s Kerala-style '
        'shrine houses a standing Chaturbhuja Vishnu murti traditionally installed by Guru '
        '(Brihaspati) and Vayu — the namesake of Guruvayur.',
    story:
        'Temple tradition (Gurupavanapura Mahatmya) holds that the central shaligram idol was '
        'worshipped in Vaikuntha and later at Dwaraka. After the city’s submergence, Krishna’s '
        'disciple Uddhava is said to have entrusted the murti to Brihaspati (Guru) and Vayu, who '
        'installed it where Shiva indicated — giving the town its portmanteau name Guruvayur.\n\n'
        'Historically the place appears as “Kuruvayur” in the 14th-century Tamil Kokasandesam; by '
        'the late 16th century, with Melpathur Narayana Bhattathiri’s Narayaneeyam and sustained '
        'patronage, it had become one of Kerala’s foremost Vaishnava pilgrimages. The complex '
        'survived Dutch and Mysore-period shocks (including temporary relocation of the idol '
        'during Tipu’s campaigns) and a major fire in November 1970 that destroyed much of the '
        'chuttambalam while sparing the srikovil and principal murti.\n\n'
        'Architecturally it is classic Kerala temple form: east-facing rectangular two-storeyed '
        'srikovil with copper/gold-plated roof, nalambalam and chuttambalam, gold-plated '
        'dwajasthambham and deepastambham, twin gopurams (notably the eastern Kizhakke Nada), '
        'Vilakkumatam lamp galleries, and the Rudratheertham tank. The standing Chaturbhuja murti '
        '(~1.2 m) holds conch, discus, mace and lotus. Auxiliary shrines include Ganapathi, '
        'Ayyappa (Dhanvantari bhava), and Idatharikathu Kavu Bhagavathi.\n\n'
        'Daily worship follows five principal poojas and three seeveli (elephant-borne Thidambu '
        'processions), expanding on Udayasthamana days. Major festivals include the ten-day '
        'Kumbham Utsavam, Krishna Janmashtami, Guruvayur Ekadasi (Vrischikam bright fortnight), '
        'and Vishu. Nearby Punnathurkotta Anakotta houses temple elephants. Entry is restricted '
        'to Hindus; Guruvayur Devaswom dress code requires dhoti and angavastram for men and '
        'saree/churidar/half-saree for women.',
    location: 'East Nada, Guruvayur, Thrissur, Kerala 680101',
    timings:
        'Daily (Devaswom-aligned public schedule; confirm on guruvayurdevaswom.in before travel): '
        'opens ~3:00 AM; closed roughly 1:30–4:30 PM; evening session from ~4:30 PM with srikovil '
        'closed after Thrippuka ~9:15 PM (later on Vilakku nights). Named markers commonly '
        'listed: Nirmalyam 3:00–3:30 AM; Oilabhishekam / Vakacharthu / Sankhabhishekam ~3:20–3:30 '
        'AM; Malar Nivedyam & Alankaram 3:30–4:15 AM; Usha Nivedyam 4:15–4:30 AM; Ethirettu & '
        'Usha Pooja 4:30–6:15 AM; Seeveli / Palabhishekam / Navakam / Pantheeradi ~7:15–9:00 AM; '
        'Ucha Pooja 11:30 AM–12:30 PM; evening Seeveli ~4:30–5:00 PM; Deeparadhana ~6:00–6:45 PM; '
        'Athazha Nivedyam & Pooja ~7:30–8:15 PM; Athazha Seeveli ~8:45–9:00 PM; Thrippuka / '
        'Olavayana ~9:00–9:15 PM. Sample app envelope “3:00 AM – 1:00 PM, 4:30 PM – 10:00 PM” '
        'matches the coarse day. Udayasthamana days expand to ~21 poojas — treat minute slots as '
        'approximate.',
    latitude: 10.5946,
    longitude: 76.0408,
    specialities: [
      'Bhuloka Vaikuntha / Dwarka of the South pilgrimage',
      'Standing Chaturbhuja Guruvayurappan (shaligram) murti',
      'Five daily poojas + three Seeveli; Udayasthamana expands schedule',
      'Guruvayur Ekadasi, Kumbham Utsavam, Janmashtami, Vishu',
      'Punnathurkotta temple-elephant sanctuary (Anakotta)',
      'Hindu-only entry; traditional Kerala dress code enforced',
    ],
  ),
  Temple(
    name: 'Sree Padmanabhaswamy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/padmanabhaswamy/800/600',
    description:
        'A major Divya Desam Vishnu temple in Thiruvananthapuram’s East Fort, famous for the '
        'Ananthashayana (reclining Padmanabha) murti viewed through three doors and for historic '
        'treasure vaults under Travancore royal custodianship.',
    story:
        'Sree Padmanabhaswamy Temple is counted among the 108 Divya Desams of the Sri Vaishnava '
        'tradition. The principal murti shows Vishnu reclining on Ananta Shesha; darshan is '
        'characteristically through three doors that reveal the head, torso, and feet of the vast '
        'Ananthashayana form. Kerala and Dravidian architectural idioms meet in the soaring '
        'gopuram, stone corridors, and wood-and-copper Kerala roofs inside the Fort precinct.\n\n'
        'In 1750 CE, Maharaja Marthanda Varma of Travancore dedicated the kingdom to Padmanabha '
        'and ruled thereafter as Padmanabha Dasa — a political-theological arrangement that still '
        'shapes temple administration and royal ritual roles. The Travancore royal family remains '
        'closely associated with major festivals and custodial duties.\n\n'
        'Global attention surged after 2011 court-ordered inventory of subterranean vaults '
        '(kallaras), when enormous stores of gold, jewels, and ritual objects were documented; '
        'Vault B’s restricted status continues to fuel public debate. Media valuations should be '
        'treated as estimates, not audited appraisals.\n\n'
        'Daily worship is tightly scheduled around named morning and evening darshan windows '
        'published by the temple’s Executive Officer (SPST). Entry is restricted to Hindus. Dress '
        'code is among Kerala’s strictest: men must wear mundu/veshti with bare upper body; women '
        'saree or half-saree/pattu pavadai. Major festivals include Alpashy and Painkuni utsavams '
        'and the rare Laksha Deepam illumination cycle.',
    location: 'West Nada, Fort, Thiruvananthapuram, Kerala 695023',
    timings:
        'Official SPST darshan windows (www.spst.in/Timing; festival overrides apply, e.g. Aani '
        'Kalabham): Morning — 3:30–4:45 AM; 6:30–7:00 AM; 8:30–10:00 AM; 10:30–11:15 AM; 11:45 '
        'AM–12:00 PM. Evening — 4:30–6:15 PM; 6:45–7:20 PM. Midday closed between noon and '
        'evening opening. Sample app “3:30 AM – 12:00 PM, 5:00 PM – 7:20 PM” is a coarse '
        'envelope; use the slotted official list for planning.',
    latitude: 8.4826,
    longitude: 76.9443,
    specialities: [
      '108 Divya Desam — Ananthashayana Padmanabha via three doors',
      'Padmanabha Dasa Travancore royal dedication (1750)',
      'Historic kallara treasure vaults (post-2011 inventory fame)',
      'Strict Hindu-only entry; mundu/saree dress code enforced',
      'Laksha Deepam and Alpashy/Painkuni festival cycles',
      'East Fort civic-ritual landmark of Thiruvananthapuram',
    ],
  ),
  Temple(
    name: 'Sabarimala Ayyappan Temple',
    state: 'Kerala',
    city: 'Pathanamthitta',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/sabarimala/800/600',
    description:
        'Hill shrine of Lord Ayyappa (Dharmasastha / Hariharaputra) in the Periyar forests of '
        'Pathanamthitta, drawing tens of millions of pilgrims in the Mandala–Makaravilakku season '
        'after a traditional 41-day vratham and trek via Pampa.',
    story:
        'Sabarimala Sannidhanam sits high in the Western Ghats of Pathanamthitta district within '
        'the broader Periyar landscape. The deity Ayyappa — popularly understood as the son of '
        'Shiva and Vishnu-as-Mohini (Hariharaputra) — is worshipped as Dharmasastha. Local legend '
        'links the hills to Shabari of the Ramayana and to the Pandalam royal house, which '
        'traditionally adopts and later consecrates the boy-prince who defeats the demoness '
        'Mahishi and chooses this summit for tapas.\n\n'
        'Pilgrimage practice centres on a 41-day Mandala vratham of austerity, black/blue mundu, '
        'irumudi kettu (twin-compartment sacred bundle), and the climb from Pampa past Neelimala '
        'to the Pathinettam Padi — the eighteen sacred steps that only irumudi-bearing devotees '
        'ascend. At the sanctum, Neyyabhishekam (ghee abhishekam from the coconut carried in the '
        'irumudi) is the signature offering; emptied coconuts are consigned to the Aazhi '
        'fire.\n\n'
        'Unlike year-round urban temples, Sabarimala’s main public season is the '
        'Mandala–Makaravilakku Mahotsavam (typically mid-November to mid-January), plus shorter '
        'openings around Vishu and monthly first-of-Malayalam-month / festival slots announced by '
        'the Travancore Devaswom Board (TDB). Crowds during peak season make it one of the '
        'world’s largest annual pilgrimages; online queue/slot booking via sabarimalaonline.org '
        'is now standard.\n\n'
        'Note for data model: sample_data.dart stores deity as "Vishnu" (reflecting Ayyappa’s '
        'Vaishnava parentage / Hariharaputra identity in many catalogues). Ritual identity on the '
        'ground is Ayyappa/Dharmasastha; CMS may later add an alias field. Traditional customs '
        'around women’s entry of certain ages have been legally contested — follow current TDB / '
        'court-compliant notices rather than older folk summaries.',
    location: 'Sabarimala, Pathanamthitta, Kerala 689711',
    timings:
        'Seasonal temple — not a daily urban schedule. During Mandala–Makaravilakku Mahotsavam, '
        'official Kerala Sabarimala portal pooja clock (sabarimala.kerala.gov.in/pooja-timing): '
        'Morning — Nada opens / Nirmalyam Abhishekam 3:00 AM; Ganapati Homam 3:30 AM; '
        'Neyyabhishekam ~3:30–7:00 AM and again ~8:30–11:00 AM; Usha Pooja from ~7:30 AM; '
        'Ashtabhishekam ~11:00–11:30 AM; Ucha Pooja 12:30 PM; close 1:00 PM. Evening — reopen '
        '3:00 PM; Deeparadhana 6:30 PM; Pushpabhishekam ~7:00–9:30 PM; Athazha Pooja from 9:30 '
        'PM; Harivarasanam / close 11:00 PM. Typical pilgrim-facing darshan envelope in season '
        'coverage: ~3:00 AM–1:00 PM and 3:00 PM–11:00 PM. Exact Mandala open/close and '
        'Makaravilakku dates change yearly (e.g. 2025–26 season ran mid-Nov 2025 through ~20 Jan '
        '2026 with Mandala Pooja ~27 Dec and Makaravilakku ~14 Jan) — always confirm TDB / '
        'sabarimala.kerala.gov.in before travel. Shorter Vishu and monthly openings are '
        'separately notified.',
    latitude: 9.4358,
    longitude: 77.0763,
    specialities: [
      'Mandala vratham (41-day austerity) + irumudi pilgrimage',
      'Pathinettam Padi (18 sacred steps)',
      'Neyyabhishekam as principal offering; Harivarasanam lullaby at close',
      'Makaravilakku / Makara Jyothi seasonal climax',
      'Among the world’s largest annual pilgrimages (tens of millions in season)',
      'Administered by Travancore Devaswom Board; online slot booking',
    ],
  ),
  Temple(
    name: 'Attukal Bhagavathy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/attukal/800/600',
    description:
        'Known as the Sabarimala of women, this Bhagavathy shrine near East Fort is famed for '
        'Attukal Pongala — certified by Guinness World Records as the largest annual gathering of '
        'women (2.5 million participants on 10 March 2009).',
    story:
        'Attukal Bhagavathy Temple stands about two kilometres from Sree Padmanabhaswamy Temple '
        'in Thiruvananthapuram. The goddess is popularly identified with Bhadrakali and with '
        'Kannaki (Kannagi) of Ilango Adigal’s Tamil epic Cilappatikaram — the wronged wife who, '
        'after Madurai’s destruction, is said in Kerala tradition to have come west and settled '
        'as Bhagavathy at Attukal.\n\n'
        'The temple’s defining public ritual is Attukal Pongala (Pongal), a multi-day festival '
        'climaxed when women devotees cook sweetened rice offerings in earthen pots along roads '
        'radiating kilometres from the shrine. Guinness World Records certified 2.5 million women '
        'participants organised by the Attukal Bhagavathy Temple Trust on 10 March 2009 as the '
        'largest annual gathering of women; later local/media crowd estimates sometimes quote '
        'higher figures (including the sample app’s “over 3.5 million”) but the certified '
        'Guinness mark remains 2.5 million.\n\n'
        'Daily worship follows a classical Kerala Devi schedule from early Palliyunarthu through '
        'Ucha and Athazha poojas, with midday closure. The ten-day Pongala Mahotsavam (typically '
        'February–March, Malayalam Kumbham) transforms the capital; Kuthiyottam processions of '
        'young boys are another festival hallmark. The temple trust maintains an official site '
        '(attukal.org) and an online vazhipadu booking portal (booking.attukal.in).',
    location: 'Attukal, Manacaud, Thiruvananthapuram, Kerala 695009',
    timings:
        'Widely published daily envelope (confirm via attukal.org / booking.attukal.in; festival '
        'days override): morning session from Palliyunarthu ~4:30 AM through closing ~12:30 PM; '
        'afternoon closed; evening reopen ~5:00 PM through close ~8:30 PM. Named markers commonly '
        'listed in visitor guides: Nirmalyadarshan ~5:00 AM; Abhishekam ~5:35 AM; Ganapathi Homam '
        '~5:45 AM; Deeparadhana ~6:00 AM; Usha Pooja ~6:30 AM; Pantheeradi ~8:30 AM; Ucha Pooja / '
        'Deeparadhana ~12:00 PM; evening Deeparadhana ~6:45 PM; Athazha Pooja ~7:30 PM; Athazha '
        'Sreebali ~8:05 PM. Sample app “4:30 AM – 12:00 PM, 5:00 PM – 8:30 PM” is a close coarse '
        'summary. Pongala week disrupts ordinary traffic and hours citywide.',
    latitude: 8.4770,
    longitude: 76.9553,
    specialities: [
      'Guinness Record Attukal Pongala (2.5 million women, 10 Mar 2009)',
      'Called Sabarimala of women',
      'Kannaki / Cilappatikaram association',
      '10-day Pongala Mahotsavam with Kuthiyottam',
      'Near Padmanabhaswamy / East Fort pilgrim circuit',
    ],
  ),
  Temple(
    name: 'Chottanikkara Bhagavathy Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chottanikkara/800/600',
    description:
        'Major Cochin Devaswom Board Bhagavathy temple where the goddess is worshipped through '
        'the day as Saraswati (morning), Lakshmi (noon), and Durga (evening), famed for Keezhkavu '
        'Guruthi rituals associated with healing and protection.',
    story:
        'Chottanikkara Bhagavathy Temple, administered by the Cochin Devaswom Board, is among the '
        'Board’s foremost shrines. The Divine Mother — Rajarajeswari / Adiparasakthi — is '
        'worshipped in three sequential forms: Saraswati in the morning, Lakshmi at noon, and '
        'Durga in the evening, each marked by a change of alankaram. An idol of Mahavishnu shares '
        'the pedestal, so the deity is also invoked as Ammenarayana, Devinarayana, '
        'Lakshminarayana and Bhadrenarayana; Brahma, Shiva, Ganapathi, Subramanya and Sastha '
        'figures accompany the main group.\n\n'
        'The lower Keezhkavu (Kizhukkavu) Bhadrakali shrine is especially known for Guruthi '
        'Nivedyam and the night Valiya Guruthi, rituals long associated in popular devotion with '
        'relief from affliction, fear, and perceived spirit possession after periods of bhajanam. '
        'The main annual highlight is Makom Thozhal (Makam day in Kumbham, Feb/Mar), when '
        'tradition holds that Bhagavathy gave full-attire darshan to Vilwamangalam Swamiyar and '
        'continues to appear specially each year.\n\n'
        'The complex also includes Sastha, Shiva, Ganapathi and Naga shrines in a wooded '
        'Ernakulam-district setting west of Kochi. Official pooja timings and vazhipadu rate '
        'lists are published on chottanikkarabhagavathy.org; Fridays and Mandalam season open '
        'earlier (~3:30 AM).',
    location: 'Chottanikkara, Ernakulam, Kerala 682312',
    timings:
        'Official Cochin Devaswom / temple site (chottanikkarabhagavathy.org): Nada opens 4:00 AM '
        'for Nirmalya Darshan (3:30 AM on Fridays & Mandalam season). Morning markers — Shiva '
        'Dhara 5:00 AM & 10:45 AM; Ethruthu Pooja 5:00–5:45 AM; Seeveli ~5:45 AM; Pantheeradi '
        '7:00–8:00 AM; Keezhkavu Guruthi Nivedyam 7:30 AM; Ucha Pooja 11:00–11:30 AM; Ucha '
        'Seeveli 12:00 PM then midday close. Evening — Nada reopens 4:00 PM; Deeparadhana after '
        '~6:00 PM (sunset-based); Keezhkavu Guruthi 7:00 PM; Athazha Pooja 7:00–7:30 PM; Seeveli '
        'after 8:00 PM; Valiya Guruthi after 8:30 PM (often ~8:45 PM). Special days alter the '
        'clock. Sample app “4:00 AM – 12:00 PM, 5:00 PM – 8:30 PM” understates evening length '
        'through Valiya Guruthi.',
    latitude: 10.0055,
    longitude: 76.3786,
    specialities: [
      'Triple daily form — Saraswati / Lakshmi / Durga alankaram',
      'Ammenarayana pedestal with Vishnu and accompanying deities',
      'Keezhkavu Guruthi & Valiya Guruthi healing/protection rites',
      'Makom Thozhal (Kumbham) annual highlight',
      'Cochin Devaswom Board flagship shrine',
    ],
  ),
  Temple(
    name: 'Ernakulathappan Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ernakulathappan/800/600',
    description:
        'City temple of Kochi dedicated to Lord Shiva (Ernakulathappan — “Lord of Ernakulam”), '
        'historically one of the seven royal temples of the Kochi Maharajas and still the '
        'civic-ritual heart of Ernakulam’s Durbar Hall Ground.',
    story:
        'Ernakulam Shiva Temple — popularly Ernakulathappan Temple — sits on Durbar Hall Ground '
        'in the commercial heart of Kochi. Local etymology derives Ernakulam from Erayanarkulam / '
        'related forms linked to Shiva, and the deity is revered as the city’s protector. Under '
        'Kochi royal patronage the shrine ranked among seven royal temples; the present fabric is '
        'largely associated with Dewan Edakkunni Sankara Warrier’s mid-19th-century rebuilding '
        '(commonly dated 1846), after which its royal status was elevated.\n\n'
        'The architecture is classic Kerala temple style within a compact urban precinct of '
        'roughly an acre, with associated Murugan and Hanuman shrines in the wider complex. Daily '
        'worship follows Cochin Devaswom Board practice. The grand annual highlight is the '
        'multi-day Ernakulathappan Utsavam (often cited as about eight days), featuring '
        'caparisoned elephants, Panchavadyam and Pandi Melam ensembles, and firework displays '
        'that draw city crowds to the lakeside/ground setting.\n\n'
        'Administration today is under the Cochin Devaswom Board. As a living urban Shaiva temple '
        'it remains open year-round with morning and evening sessions; festival calendars '
        'override ordinary hours.',
    location: 'Durbar Hall Road, Ernakulam, Kochi, Kerala 682011',
    timings:
        'Commonly listed urban schedule (confirm locally / Cochin Devaswom Board; no single '
        'detailed official minute-clock page located comparable to Guruvayur/SPST): roughly '
        '3:30/4:00 AM–11:00 AM and 4:00/5:00 PM–8:00 PM. Sample app: 4:00 AM – 11:00 AM, 5:00 PM '
        '– 8:00 PM. Visitor guides mention Nirmalyam near opening, morning abhishekam, sunset '
        'Deeparadhana, and Athazha Pooja in the late evening — treat named minute-level slots as '
        'unverified unless confirmed on site. Utsavam days extend processions and public hours.',
    latitude: 9.9937,
    longitude: 76.2914,
    specialities: [
      'City namesake — Ernakulathappan as protector of Ernakulam',
      'Historic Kochi royal temple; mid-19th-c. rebuild under Dewan Sankara Warrier',
      'Ernakulathappan Utsavam with elephants, melam, fireworks',
      'Durbar Hall Ground / central Kochi lakeside setting',
      'Cochin Devaswom Board administration',
    ],
  ),
  Temple(
    name: 'Vaikom Mahadeva Temple',
    state: 'Kerala',
    city: 'Kottayam',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/vaikom/800/600',
    description:
        'Ancient Kerala-style Mahadeva temple at Vaikom (Vaikkathappan), renowned for unbroken '
        'Shaiva worship, the twelve-day Vaikathashtami festival, and as the ground of the 1924–25 '
        'Vaikom Satyagraha for temple-road access.',
    story:
        'Vaikom Sree Mahadeva Temple on the eastern shore of Vembanad in Kottayam district is '
        'among Kerala’s oldest living Shiva temples. The linga is traditionally ascribed to the '
        'Treta Yuga; local lore ties its installation to the demon Khara’s three lingas and to '
        'sage Vyaghrapada, with later consecration narratives involving Parashurama. Devotees '
        'fondly call the deity Vaikkathappan and often complete a same-morning circuit with '
        'Ettumanoor and Kaduthuruthy Shiva temples before Ucha Pooja.\n\n'
        'Architecturally the large compound (commonly described around eight acres) has four '
        'gopurams, copper-roofed oval/elliptical srikovil traditions associated with '
        'master-builder Perumthachan, muralled interiors, and a famous closed western door linked '
        'to a cautionary legend about disrupted naivedyam. Shiva is said to bless devotees in '
        'three aspects through the day — Dakshinamurthi in the morning, Kiratamurthi at noon, and '
        'Shakti Panchakshari in the evening.\n\n'
        'The temple’s modern historical fame rests equally on the Vaikom Satyagraha (1924–25), a '
        'non-violent mass movement against caste barriers on the roads around the temple, led by '
        'figures including T. K. Madhavan with support from Mahatma Gandhi and others. Opening of '
        'the roads to all castes foreshadowed the broader Temple Entry Proclamation of 1936 in '
        'Travancore.\n\n'
        'The principal festival is Vaikathashtami (Ashtami in Vrischikam, Nov–Dec), a roughly '
        'twelve-day celebration culminating on Ashtami with elephant processions and intensive '
        'poojas. Administration is under the Travancore Devaswom Board; the official site '
        'vaikomtemple.org documents origin, legends, architecture, and offerings.',
    location: 'Vaikom, Kottayam, Kerala 686141',
    timings:
        'Widely published daily schedule (secondary compilations; confirm on site / TDB — '
        'official vaikomtemple.org emphasises offerings more than a minute-clock): ~4:00 AM '
        'Nadathurappu / Nirmalya / Ethirthu–Usha sequence; Ethirthu Sribeli ~6:30 AM; Pantheeradi '
        '~7:30 AM; Navakam ~9:00 AM; Ucha Pooja & abhishekas ~10:00 AM; Ucha Sribeli ~11:30 AM; '
        'close ~12:00 PM; reopen ~5:00 PM; Deeparadhana ~6:30 PM; Athazha Pooja ~7:00 PM; Athazha '
        'Sribeli ~8:00 PM; close ~8:30–9:00 PM. Sample app: 4:00 AM – 11:30 AM, 5:00 PM – 8:30 '
        'PM. Annadanam often listed ~11:00 AM–1:00 PM. Vaikathashtami and Shivaratri override '
        'ordinary hours.',
    latitude: 9.7486,
    longitude: 76.3952,
    specialities: [
      'Vaikkathappan — among Kerala’s oldest continuous Shaiva shrines',
      'Vaikom Satyagraha (1924–25) social-reform landmark',
      'Vaikathashtami (~12 days, Vrischikam Ashtami)',
      'Tri-aspect daily blessing tradition (Dakshinamurthi / Kirata / Shakti Panchakshari)',
      'Oval srikovil / large prakara Kerala architecture',
      'Circuit with Ettumanoor & Kaduthuruthy before Ucha Pooja',
    ],
  ),
  Temple(
    name: 'Anjengo Sree Durga Devi Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/anjengo/800/600',
    description:
        'Local Durga Devi shrine at historic Anchuthengu (Anjengo) on the Thiruvananthapuram '
        'coast, set beside the ruins of Anjengo Fort — site of the English East India Company’s '
        'first lasting settlement on the Malabar coast (1684).',
    story:
        'Anchuthengu — Portuguese/English Anjengo, literally “five coconut palms” in Malayalam — '
        'is a coastal village southwest of Varkala in Thiruvananthapuram district. In 1684 the '
        'English East India Company established a factory and later a fort here, making it their '
        'earliest durable foothold in Kerala before the rise of Tellicherry and others. The '
        'surviving laterite fort ruins, cemetery, and colonial traces still define the '
        'settlement’s heritage landscape.\n\n'
        'Within this fishing-and-trading village, the Sree Durga Devi Temple functions as a '
        'community guardian shrine. Sample and local narrative present it as a centuries-old '
        'coastal Devi temple that oriented the spiritual life of fishermen and traders working '
        'the Arabian Sea lanes beside the fort. Unlike the major Devaswom-board pilgrimage '
        'temples in this batch, it remains a neighbourhood-scale Kerala Devi kovil rather than a '
        'statewide draw.\n\n'
        'Public web documentation specific to this temple’s architecture, founding inscriptions, '
        'and minute-level pooja clock is thin compared with Guruvayur, Padmanabhaswamy, or '
        'Sabarimala. Enrichment therefore leans on Anchuthengu’s well-attested colonial history '
        '(Wikipedia; The Hindu heritage features) plus the sample’s local framing, and flags '
        'timings as sample-derived pending field/official confirmation.\n\n'
        'Visitors typically combine the shrine with a walk around Anjengo Fort ruins and the '
        'fishing harbour. Dress and conduct follow ordinary Kerala temple norms (modest clothing; '
        'men often bare-chested with mundu inside many Kerala shrines — confirm locally).',
    location: 'Anchuthengu, Thiruvananthapuram, Kerala 695309',
    timings:
        'Sample_data only (not independently verified from an official temple portal during this '
        'research pass): 5:00 AM – 12:00 PM and 5:00 PM – 8:00 PM. No named pooja schedule '
        'located on a Devaswom or trust site. Treat as approximate local practice; confirm on '
        'arrival. Festival days (typical Kerala Devi calendar — Navaratri, Mandalam Fridays, '
        'local utsavam) likely extend or alter hours.',
    latitude: 8.6833,
    longitude: 76.7667,
    specialities: [
      'Coastal village Durga shrine at historic Anchuthengu / Anjengo',
      'Adjacent Anjengo Fort — first English EIC settlement in Kerala (1684)',
      'Fishing-community guardian temple setting',
      'European colonial / Malabar trade-history backdrop',
    ],
  ),
  Temple(
    name: 'Mannarsala Sree Nagaraja Temple',
    state: 'Kerala',
    city: 'Alappuzha',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/mannarsala/800/600',
    description:
        'Kerala’s foremost serpent (Nagaraja) temple in a dense sacred grove near Haripad, '
        'Alappuzha, with tens of thousands of naga idols and a rare living tradition in which the '
        'family matriarch (Mannarasala Amma / Valia Amma) leads key worship.',
    story:
        'Mannarasala Sree Nagaraja Temple at Haripad (Alappuzha) is set in a thick sarpa kavu '
        '(serpent grove). Popular counts speak of tens of thousands of stone and metal naga '
        'images lining paths and tree bases — Wikipedia cites “over 100,000”; the sample app’s '
        '“30,000+” is a conservative figure also seen in tourism copy. The principal deity is '
        'Nagaraja (serpent king), worshipped with Nurum Palum and related offerings.\n\n'
        'Origin legend links the grove to Parashurama’s reclaiming of Kerala from the sea: salty, '
        'infertile land was made habitable when Nagas agreed to dwell and protect it, with '
        'Nagaraja taking permanent seat at Mandarasala / Mannarasala. A later family legend of '
        'Vasudeva and Sreedevi nursing fire-scorched serpents culminates in Nagaraja’s birth as '
        'their five-hooded child and the perpetual priestly role of the Mannarasala Illom.\n\n'
        'Unusually among Kerala temples, the senior lady of the family — Mannarasala Amma (Valia '
        'Amma) — performs and leads major rites; Amma darshan windows are published separately '
        'from general temple hours. Couples seeking fertility famously offer uruli kamazhthal '
        '(placing a bronze uruli vessel) and return with thanksgiving naga pratimas after '
        'childbirth. The main festival is Mannarasala Ayilyam (Ayilyam asterism in Kanni and '
        'Thulam), when serpent idols are taken in procession to the Illom.\n\n'
        'Note for data model: sample_data.dart lists deity as "Vishnu" (Parashurama / Vaishnava '
        'framing in some catalogues). On-the-ground identity is Nagaraja / Naga deities; CMS may '
        'add an alias. Photography inside the compound is prohibited per official guidelines; '
        'sacred grove entry is forbidden.',
    location: 'Mannarsala, Haripad, Alappuzha, Kerala 690513',
    timings:
        'Official mannarasala.org devotee guide: Mon–Sat darshan 5:00–11:00 AM and 5:30–7:30 PM; '
        'Sunday 5:00 AM–12:00 noon and 5:30–7:30 PM. Mannarasala Amma darshan generally 11:00 '
        'AM–12:00 noon and 5:30–6:30 PM (changes on Pooyam, Ayilyam, and other important days). '
        'Prasadam distribution from ~7:00 AM. Sample app “5:00 AM – 12:00 PM, 5:00 PM – 7:30 PM” '
        'matches Sunday morning length more than weekday mornings (weekday morning closes 11:00 '
        'AM; evening opens 5:30 not 5:00). Festival/Ayilyam days override.',
    latitude: 9.2760,
    longitude: 76.4350,
    specialities: [
      'Largest / foremost Kerala Nagaraja (serpent) temple in a sacred grove',
      'Tens of thousands of naga idols (counts vary 30k–100k+)',
      'Female head-priestess tradition — Mannarasala Amma / Valia Amma',
      'Ayilyam festival processions; Uruli Kamazhthal fertility offering',
      'Nurum Palum and turmeric prasadam traditions',
      'No photography; sacred grove (Appoppan Kavu) off-limits to visitors',
    ],
  ),
  Temple(
    name: 'Thirunelli Maha Vishnu Temple',
    state: 'Kerala',
    city: 'Wayanad',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/thirunelli/800/600',
    description:
        'Ancient Maha Vishnu temple on Brahmagiri’s flank in Wayanad — called the Kashi of the '
        'South — famed for ancestral rites (Pitru Tharpanam) at the Papanashini stream amid dense '
        'Sahyadri forest.',
    story:
        'Thirunelli (Tirunelli) Temple stands in a forested valley of north Wayanad near the '
        'Karnataka border, on the side of Brahmagiri at roughly 900 m elevation (~32 km from '
        'Mananthavady). It is classed among the 108 Abhimana Kshetrams of the Vaishnava '
        'tradition. The name derives from nelli (Indian gooseberry / amla): Puranic references in '
        'Matsya, Skanda, Narasimha and Padma Puranas speak of Sahyamalaka Kshetra — a Vishnu '
        'shrine established by Brahma in the Sahya valley.\n\n'
        'Temple legend holds that Brahma, circling the universe on his hamsa, was drawn to '
        'Brahmagiri’s beauty, found a Vishnu idol set in an amla tree, recognised the spot as '
        'akin to Vaikuntha, and consecrated the murti. The mountain spring Papanashini '
        '(“destroyer of sins”) flowing from Brahmagiri is the ritual focus for bathers seeking '
        'purification; families come especially for Pitru Tharpanam and last-rite / ancestral '
        'ceremonies analogous in function (not geography) to Ganga-side rites at Kashi — hence '
        'the popular epithet “Kashi of the South.”\n\n'
        'Stone craftsmanship visible in the Vilakku Maadam (lamp pavilion) and Karingali / '
        'Karingal Paathi granite water channel is highlighted by Kerala Tourism’s Thalassery '
        'Heritage / Pazhassi circuit pages. The setting remains one of Kerala’s most atmospheric '
        'forest temples; monsoon and wildlife-reserve rules around Wayanad affect road access — '
        'check local advisories.\n\n'
        'Daily worship follows morning and evening sessions typical of Kerala Vishnu temples; '
        'ancestral-rite bookings and stream rituals have their own priestly schedules beyond '
        'ordinary darshan.',
    location: 'Thirunelli, Wayanad, Kerala 670646',
    timings:
        'Kerala Tourism (Thalassery Heritage / Pazhassi circuit) lists: 5:30 AM–12:30 PM and 5:30 '
        'PM–8:30 PM. Sample app: 5:30 AM – 12:00 PM, 5:00 PM – 7:30 PM — prefer the Tourism '
        'figures as the better-sourced public listing, but confirm locally (evening close quoted '
        '7:30–8:30 PM across guides). Named minute-level nithya-pooja slots were not found on a '
        'dedicated official temple portal during this pass. Pitru Tharpanam / Papanashini rites '
        'follow separate appointment practice with local priests.',
    latitude: 11.9107,
    longitude: 75.9978,
    specialities: [
      'Called Kashi of the South — Pitru Tharpanam ancestral rites',
      'Papanashini sacred mountain stream',
      'Brahmagiri / Sahyamalaka Puranic setting (~900 m)',
      '108 Abhimana Kshetram Vaishnava classification',
      'Vilakku Maadam and Karingal Paathi stone craftsmanship',
      'Dense Wayanad forest pilgrimage atmosphere',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  KARNATAKA
  // ═══════════════════════════════════════════════════════════════════════════
  // Research-enriched visitor copy for the existing 10 Karnataka temples
  // (matched by name/slug — no new documents). Cover imageUrl values remain
  // the bundled picsum placeholders; do not treat Commons candidates as Storage
  // paths. Sources and photo_candidates: docs/karnataka-sample-research.md.
  Temple(
    name: 'Sri Krishna Matha (Udupi)',
    state: 'Karnataka',
    city: 'Udupi',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/udupi/800/600',
    description:
        'Thirteenth-century Dvaita seat founded by Sri Madhvacharya, where Bala Krishna is viewed '
        'only through the nine-holed silver Navagraha / Kanakana Kindi, and temple administration '
        'rotates every two years among the Ashta Mathas under the Paryaya system.',
    story:
        'Sri Krishna Matha stands on Udupi’s Car Street as the living heart of Madhva '
        'Vaishnavism. Tradition holds that Madhvacharya (13th century) recovered a Krishna idol '
        'packed in gopichandana clay from a storm-struck ship off Malpe and installed it here, '
        'establishing both the shrine and the scholarly matha that still teaches Dvaita '
        'Vedanta.\n\n'
        'Darshan is unique: the murti faces west, and devotees see the Lord only through the '
        'silver-plated Navagraha Kindi (nine-holed window), popularly linked to Kanakana Kindi. '
        'Local lore says the bhakti saint Kanakadasa was denied entry; Krishna is said to have '
        'turned so the devotee could still receive darshan through the western window — a story '
        'that remains central to Udupi’s inclusive identity.\n\n'
        'Governance follows the Paryaya: the eight Ashta Mathas founded by Madhva’s disciples '
        'take biennial turns administering the Krishna Matha, culminating in a grand handover '
        'festival that draws huge crowds. The current 2026–2028 term is associated with Shiroor '
        'Matha after the January 2026 Paryaya (confirm serving matha on udipikrishnamutt.com '
        'before travel).\n\n'
        'Daily worship treats Bala Krishna with a long sequence of named poojas from early '
        'Nirmalya Visarjana through evening Ekanta / Thottilu seva. Free annadana and the town’s '
        'famous Udupi cuisine culture grew around the matha’s hospitality. Major observances '
        'include Krishna Janmashtami, Laksha Deepotsava, Madhwa Navami, and the biennial Paryaya '
        'Mahotsava.',
    location: 'Car Street, Udupi, Karnataka 576101',
    timings:
        'Public schedule varies by serving Paryaya matha and source — treat as approximate and '
        'confirm on temple notice board / official matha site. Common visitor envelope: opens '
        '~5:00 AM (some lists 4:30–5:00 AM) with midday break and evening close ~9:00–9:30 PM; '
        'sample app “5:30 AM – 1:00 PM, 4:00 PM – 8:30 PM” is a coarse envelope. Named pooja '
        'order commonly cited (times drift): Nirmalya Visarjana ~4:50–5:00 AM; Ushahkala ~5:30 '
        'AM; Panchamrita / Viswaroopa markers mid-morning; Mahapooja late morning (~9:45–11:00 AM '
        'depending on list); evening Ratri / Ranga / Chamara sevas ~7:00–7:45 PM; Ekanta / '
        'Thottilu closing ~8:15–8:50 PM. Fourteen traditional daily poojas; Paryaya and festival '
        'days override ordinary hours.',
    latitude: 13.3358,
    longitude: 74.7460,
    specialities: [
      'Kanakana Kindi / Navagraha silver window darshan',
      'Paryaya biennial Ashta Matha rotation',
      'Madhvacharya Dvaita Vedanta seat',
      'Bala Krishna gopichandana origin legend',
      'Daily annadana; Udupi cuisine heritage',
      'Fourteen named daily poojas including Ekanta seva',
    ],
  ),
  Temple(
    name: 'Sri Manjunatha Temple, Dharmasthala',
    state: 'Karnataka',
    city: 'Dharmasthala',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/dharmasthala/800/600',
    description:
        'Major Dakshina Kannada pilgrimage where Lord Manjunatha (Shiva) is administered by the '
        'Jain Heggade lineage with Vaishnava Brahmin priests — a long-running model of dharmic '
        'coexistence — alongside free annadanam and the 39-ft Bahubali monolith on Ratnagiri.',
    story:
        'Shri Kshetra Dharmasthala grew around the Manjunatha shrine on the Netravati–Kumaradhara '
        'landscape of coastal Karnataka. For centuries the hereditary Jain Heggade family has '
        'been the temple’s secular administrator (Dharmadhikari), while daily worship of the '
        'Shiva linga is performed by Vaishnava Brahmin priests — an arrangement pilgrims cite as '
        'living religious harmony rather than a modern experiment.\n\n'
        'The present Dharmadhikari, Dr D. Veerendra Heggade, continues a lineage of social and '
        'spiritual stewardship that includes mass feeding, education, and rural development '
        'institutions clustered around the kshetra. Free annadanam (prasada meals) is a defining '
        'daily practice and draws pilgrims independently of festival calendars.\n\n'
        'About a kilometre from the shrine, a 39-foot Bahubali (Gommateshwara) monolith stands on '
        'Ratnagiri Hill, sculpted by Renjala Gopalakrishna Shenoy and installed in 1982 under '
        'Heggade patronage; mahamastakabhisheka ceremonies have been held periodically since. '
        'Laksha Deepotsava illuminates the town with tens of thousands of lamps and is among the '
        'kshetra’s most photographed festivals.\n\n'
        'Daily routine begins with early gate opening for cleansing rituals; public darshan '
        'windows are interrupted for Mahapooja and Nithyabali. Shatharudra Abhisheka is a notable '
        'morning seva. Always reconfirm hours on shridharmasthala.org before travel, especially '
        'on crowded festival days.',
    location:
        'Dharmasthala, Belthangady Taluk, Dakshina Kannada, Karnataka 574216',
    timings:
        'Official Shri Kshetra Dharmasthala temple routine (shridharmasthala.org/temple-routine; '
        'festival overrides apply): gates open ~4:00 AM for rituals; public darshan roughly '
        '6:30–11:00 AM, 12:15–2:30 PM, and 5:00–8:30 PM. Named markers: Shatharudra Abhisheka & '
        'pooja ~8:30–10:30 AM (darshan continues); Shiva Sahasranamavali ~11:00 AM; Maha Naivedya '
        '~11:30 AM; Mahapooja ~12:00 PM and evening Mahapooja ~8:30 PM with Nithyabali shortly '
        'after (darshan paused during Mahapooja/Nithyabali). Sample app “6:30 AM – 2:00 PM, 5:00 '
        'PM – 8:30 PM” matches the coarse day. Helpline listed on official site: 08256-266666.',
    latitude: 12.9623,
    longitude: 75.3724,
    specialities: [
      'Jain Heggade administration with Vaishnava priests',
      '39-foot Bahubali monolith on Ratnagiri (1982 install)',
      'Large-scale free Annadanam',
      'Laksha Deepotsava lamp festival',
      'Shatharudra Abhisheka and thrice-daily Nithyabali',
      'Manjusha Museum / rural development complex nearby',
    ],
  ),
  Temple(
    name: 'Kukke Subramanya Temple',
    state: 'Karnataka',
    city: 'Sullia',
    deity: 'Murugan',
    imageUrl: 'https://picsum.photos/seed/kukkesubramanya/800/600',
    description:
        'Western Ghats pilgrimage to Lord Subrahmanya (Kartikeya) as protector of the nagas, '
        'famed across South India for Sarpa Dosha nivarana sevas such as Sarpa Samskara and '
        'Ashlesha Bali amid dense rainforest foothills.',
    story:
        'Kukke Subrahmanya sits where the Kumaradhara river meets the forested slopes of the '
        'Western Ghats in Dakshina Kannada. Temple tradition recounts that after Garuda pursued '
        'Vasuki and the serpent race, they took refuge with Lord Subrahmanya here; he granted '
        'them protection, and the kshetra became a premier centre of Naga worship.\n\n'
        'Pilgrims come especially for remedial sevas addressing Sarpa Dosha and related '
        'afflictions. Sarpa Samskara is a multi-day ritual typically begun at the Adi Subrahmanya '
        'cave/shrine precinct and completed at the main temple; Ashlesha Bali is widely booked '
        'for naga propitiation. Advance slots via the Karnataka HRCE ITMS portal (temple id '
        'TM000021) sell out weeks ahead on peak dates.\n\n'
        'The main shrine’s iconography emphasises Subrahmanya with the serpent; the surrounding '
        'ghats, cascades, and trek approaches give the pilgrimage a strong nature–bhakti '
        'character distinct from urban Murugan temples of Tamil Nadu.\n\n'
        'Champa Shashti (Subrahmanya Shashti) is the foremost annual festival. Dress norms on the '
        'HRCE portal ask men to remove shirts/banians before darshan. Confirm same-day hours and '
        'seva counters on itms.kar.nic.in before travel.',
    location:
        'Kukke Subramanya, Sullia Taluk, Dakshina Kannada, Karnataka 574238',
    timings:
        'Karnataka HRCE ITMS official (tid=21): temple open 6:30 AM–1:30 PM and 3:30 PM–9:00 PM; '
        'nadai closing window listed 9:00–9:30 PM. Sample app “6:30 AM – 1:30 PM, 4:00 PM – 8:30 '
        'PM” is close but evening open is earlier (3:30) and close later (9:00) on HRCE. '
        'Secondary compilations list early Nirmalya/abhisheka before general queues and Ashlesha '
        'Bali in morning/afternoon shifts — treat seva clock times as booking-dependent. Sarpa '
        'Samskara is a scheduled multi-day seva, not walk-in darshan. Confirm on itms.kar.nic.in '
        '/ temple EO before travel.',
    latitude: 12.6772,
    longitude: 75.6182,
    specialities: [
      'Premier South Indian Sarpa Dosha Nivarana centre',
      'Sarpa Samskara (multi-day) and Ashlesha Bali sevas',
      'Adi Subrahmanya cave / early shrine circuit',
      'Kumaradhara river and Western Ghats rainforest setting',
      'Champa Shashti (Subrahmanya Shashti) festival',
      'HRCE ITMS online seva booking (TM000021)',
    ],
  ),
  Temple(
    name: 'Sringeri Sharada Peetham',
    state: 'Karnataka',
    city: 'Sringeri',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/sringeri/800/600',
    description:
        'Dakshinamnaya Sri Sharada Peetham — the southern Amnaya matha of Adi Shankaracharya — on '
        'the Tunga river in Malnad Karnataka, centred on Goddess Sharadamba with the ornate '
        'Vidyashankara Temple and its famed zodiac pillars.',
    story:
        'Adi Shankaracharya is traditionally said to have chosen Sringeri after witnessing a '
        'cobra shade a labouring frog on the Tunga’s banks — a sign of extraordinary ahimsa — and '
        'established the southern seat of his four Amnaya peethams here in the early 8th century. '
        'Goddess Sharada (Saraswati) is the peetham’s presiding deity; the present Sharadamba '
        'shrine and matha complex remain among Advaita Vedanta’s most important living '
        'centres.\n\n'
        'Adjoining the peetham is the Sri Vidyashankara Temple, a striking fusion often dated to '
        'the 14th century and associated with the Vidyaranya period / Vijayanagara patronage. Its '
        'twelve sculpted zodiac pillars are popularly said to catch sunlight in month-linked '
        'patterns — treat precise astronomical claims as local lore unless independently '
        'surveyed. The temple is also noted by ASI heritage interest.\n\n'
        'Daily life at Sringeri revolves around Sharadamba darshan, Guru Darshanam when the '
        'Jagadguru is in residence, and evening Chandramoulishwara puja by the Acharya. '
        'Sharannavaratri is the grandest annual festival; Vidwat sabhas and Shankara Jayanti mark '
        'the scholarly calendar.\n\n'
        'Pilgrim facilities (guest houses, annadana) are organised by the matha. Timings shift '
        'when the Jagadguru is on camp — always check sringeri.net announcements before travel.',
    location: 'Sringeri, Chikkamagaluru, Karnataka 577139',
    timings:
        'Official Sringeri Sharada Peetham (sringeri.net/pilgrim-info/temple-timings): Sharadamba '
        'Temple normal days 6:00 AM–2:00 PM and 4:00 PM–9:00 PM; Maha-Mangalarati at 10:00 AM, '
        '12:00 PM, and 7:30 PM. Other temples generally 6:00 AM–1:00 PM and 5:00 PM–8:00 PM. '
        'Vidyashankara Temple darshan listed separately ~7:00 AM–1:00 PM and 5:00 PM–8:30 PM on '
        'the temple page. Guru Darshanam ~10:30–11:30 AM when scheduled. Chandramoulishwara Puja '
        'by Jagadguru ~9:00–10:00 PM (Fridays often 8:30–10:00 PM). Sample app “6:00 AM – 2:00 '
        'PM, 4:00 PM – 9:00 PM” matches Sharadamba. Subject to change for festivals and Jagadguru '
        'camps.',
    latitude: 13.4198,
    longitude: 75.2524,
    specialities: [
      'Adi Shankaracharya’s southern Amnaya peetham',
      'Sharadamba (Saraswati) as peetham deity',
      'Vidyashankara Temple with 12 zodiac pillars',
      'Tunga riverside Malnad setting; cobra–frog founding legend',
      'Sharannavaratri Mahotsava',
      'Guru Darshanam and Chandramoulishwara puja by Jagadguru',
    ],
  ),
  Temple(
    name: 'Kollur Mookambika Temple',
    state: 'Karnataka',
    city: 'Kollur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mookambika/800/600',
    description:
        'Powerful Shakti kshetra at the foot of Kodachadri in the Western Ghats, where Goddess '
        'Mookambika is worshipped with a swayambhu linga uniting Shiva–Shakti; a major Navaratri '
        'and vidyarambha pilgrimage for Kerala and Karnataka devotees.',
    story:
        'Kollur Mookambika Temple lies beside the Souparnika river under Kodachadri peak in Udupi '
        'district. Temple legend names the demon Mookasura; when he sought a boon that would '
        'endanger the worlds, the Goddess struck him dumb (mooka) and later destroyed him, taking '
        'residence here as Mookambika — she who defeated Mooka.\n\n'
        'The sanctum’s distinctive feature is a swayambhu (self-manifest) linga understood as '
        'Shiva and Shakti in one form, with the Goddess’s anthropomorphic image also worshipped. '
        'Adi Shankaracharya is traditionally associated with the shrine’s consecration and with '
        'the Goddess’s special grace for learning — vidyarambha (initiation into letters) remains '
        'a popular family seva.\n\n'
        'Architecturally the complex follows coastal Karnataka / Kerala-influenced temple idioms '
        'rather than soaring Tamil gopurams. Navaratri is the grandest festival; Fridays and the '
        'Sharad season see heavy Kerala pilgrim traffic. Treks to Kodachadri and baths in the '
        'Souparnika form part of many devotees’ circuit.\n\n'
        'Daily worship follows a dense named arati / abhisheka sequence published on Karnataka '
        'HRCE ITMS (tid=62) and the temple’s darshana-timing pages. Midday closure is standard; '
        'festival days extend or rearrange slots.',
    location: 'Kollur, Udupi, Karnataka 576220',
    timings:
        'Karnataka HRCE ITMS (tid=62): open 5:00 AM–1:30 PM and 3:00 PM–9:00 PM; closed 1:30–3:00 '
        'PM. Sample app “6:00 AM – 1:30 PM, 3:30 PM – 8:30 PM” understates the early open and '
        'evening close — prefer HRCE. Named markers commonly listed (HRCE / temple darshana '
        'pages; minutes approximate): Go-darshan ~5:15 AM; Go-pooja ~6:00 AM; Dantha Dhavana '
        'Mangalarathi ~7:15 AM; Panchamruta Abhisheka ~7:30 AM; Archana & Naivedya ~7:45 AM; '
        'morning Mangalarathi ~8:00 AM; noon Mahamangalarathi / Bali ~12:30 PM; Pradosha sequence '
        'from ~6:30 PM with evening Mangalarathis through Kashaya Mangalarathi ~9:00 PM. Darshan '
        'pauses during key aratis — see kollurmookambikatemple.org darshana-timing. Confirm '
        'before Navaratri travel.',
    latitude: 13.8627,
    longitude: 74.8137,
    specialities: [
      'Swayambhu Shiva–Shakti united linga',
      'Mookasura / Mookambika founding legend',
      'Kodachadri peak and Souparnika river circuit',
      'Navaratri grand celebrations; strong Kerala pilgrim base',
      'Vidyarambha (learning initiation) popularity',
      'HRCE ITMS online services (TM000062)',
    ],
  ),
  Temple(
    name: 'Mahabaleshwar Temple, Gokarna',
    state: 'Karnataka',
    city: 'Gokarna',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/gokarna/800/600',
    description:
        'Ancient coastal Shaiva kshetra enshrining the Atmalinga (Pranalinga) at Gokarna — '
        'counted among Karnataka’s Muktisthalas and often called a Dakshina Kashi — where '
        'devotees traditionally seek Sparsha Darshan of the embedded linga.',
    story:
        'Mahabaleshwar Temple anchors the pilgrimage town of Gokarna on Karnataka’s Uttara '
        'Kannada coast. Epic and puranic tradition holds that Ravana received the Atmalinga from '
        'Shiva on condition it not touch the ground before Lanka; Ganesha, appearing as a boy, '
        'set it down at Gokarna when Ravana was delayed, and the linga became immovably rooted — '
        'hence Mahabaleshwar, the Lord of great strength. Fragments from Ravana’s struggle are '
        'linked in lore to other coastal Panchalinga shrines.\n\n'
        'The temple is one of Karnataka’s seven Muktisthalas and is frequently styled Dakshina '
        'Kashi by devotees, though it is not among the canonical twelve Jyotirlingas; many texts '
        'instead exalt the Atmalinga as a singular class of shrine. Kadamba and later '
        'Vijayanagara patronage shaped the Dravidian gopura, navaranga, and prakara visitors see '
        'today.\n\n'
        'A distinctive practice is Sparsha Darshan: under customary conditions devotees may enter '
        'the garbhagriha and touch the Atmalinga — rarer than distance darshan elsewhere. '
        'Photography inside is prohibited. Beach hamlets (Om, Kudle) sit a short walk away, '
        'giving the town a dual pilgrim–traveller character.\n\n'
        'Maha Shivaratri is the greatest festival; Mondays, Pradosham, and Kartika lamps are '
        'especially busy. Karnataka Tourism notes current management via a court-appointed '
        'overseeing committee — confirm practical visitor rules locally.',
    location: 'Gokarna, Uttara Kannada, Karnataka 581326',
    timings:
        'Karnataka Tourism / common visitor schedule: morning 6:00 AM–12:30 PM; closed '
        '~12:30–5:00 PM; evening 5:00 PM–8:00 PM; Mangalarati often cited near evening close. '
        'Sample app matches this envelope. Extended or altered hours on Maha Shivaratri and busy '
        'Mondays. Rudrabhisheka, Sahasranama Archana, and ancestral rites (e.g. Narayan Bali) are '
        'booked via the temple office — exact pooja clock slots are not stably published online; '
        'confirm on site / srigokarna.org contacts before travel. Entry generally free; Sparsha '
        'Darshan access can pause with crowds or rituals.',
    latitude: 14.5479,
    longitude: 74.3188,
    specialities: [
      'Atmalinga / Pranalinga (Ravana–Ganesha legend)',
      'Sparsha Darshan tradition in the garbhagriha',
      'Karnataka Muktisthala; Dakshina Kashi epithet',
      'Dravidian rajagopuram and coastal Car Street setting',
      'Panchalinga yatra links along the coast',
      'Maha Shivaratri grand celebration; Om & Kudle beaches nearby',
    ],
  ),
  Temple(
    name: 'Chamundeshwari Temple',
    state: 'Karnataka',
    city: 'Mysuru',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chamundeshwari/800/600',
    description:
        'Hilltop Shakti temple of Goddess Chamundeshwari — fierce Durga who slew Mahishasura — '
        'tutelary deity of the Mysuru Wodeyars and ritual focus of the world-famous Mysuru '
        'Dasara, reached by a thousand-step climb or road.',
    story:
        'Chamundeshwari Temple crowns Chamundi Hill above Mysuru. The Goddess, a fierce form of '
        'Durga/Shakti, is celebrated as the slayer of the buffalo-demon Mahishasura (and of '
        'Chanda and Munda), giving Mysuru its name and its civic myth. A large Mahishasura statue '
        'near the summit dramatises the legend for visitors.\n\n'
        'For centuries the Wodeyar rulers of Mysore have held Chamundeshwari as their kuladevata. '
        'The hill was earlier known as Mahabaladri for the older Mahabaleswara Shiva shrine still '
        'present among the hill’s group of temples. The present Devi temple’s Dravidian gopuram '
        'and gold-embellished sanctum image are the focus of continuous royal and popular '
        'patronage.\n\n'
        'Mysuru Dasara (Navaratri culminating in Vijayadashami) is Karnataka’s grandest public '
        'festival: palace rituals, illuminated processions, and special hilltop worship '
        'commemorate the Goddess’s victory. A colossal stone Nandi on the hillside path and the '
        'traditional 1000+ step ascent remain pilgrimage signatures even when most visitors now '
        'arrive by road or KSRTC bus.\n\n'
        'Sri Chamundeshwari Development Authority publishes darshan, abhisheka, and dasoha (free '
        'meal) windows; Fridays shift morning abhisheka earlier. The hill is a declared '
        'no-plastic zone.',
    location: 'Chamundi Hill, Mysuru, Karnataka 570010',
    timings:
        'Official Sri Chamundeshwari Development Authority (chamundeshwaritemple.in): Darshana & '
        'pooja 7:30 AM–2:00 PM, 3:30 PM–6:00 PM, and 7:30 PM–9:00 PM. Abhisheka 6:00–7:30 AM and '
        '6:00–7:30 PM; Fridays morning abhisheka 5:00–6:30 AM. Sample app matches the '
        'three-window day. Dasoha (free meals) commonly listed morning ~7:30–10:00 AM, noon '
        '~12:00–3:30 PM, night ~7:30–9:00 PM. Dasara and Fridays are peak — expect queue changes. '
        'Confirm on chamundeshwaritemple.in / HRCE ITMS tid=58 before travel.',
    latitude: 12.2724,
    longitude: 76.6703,
    specialities: [
      'Mysuru Dasara / Navaratri state festival focus',
      'Mahishasura legend; Mysuru namesake',
      'Wodeyar kuladevata; gold-embellished Devi image',
      '1000+ step hillclimb tradition and giant hillside Nandi',
      'Mahishasura statue near summit',
      'Daily dasoha; no-plastic hill zone',
    ],
  ),
  Temple(
    name: 'Virupaksha Temple',
    state: 'Karnataka',
    city: 'Hampi',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/virupaksha/800/600',
    description:
        'Living Shiva temple at the heart of Hampi’s UNESCO World Heritage Group of Monuments — '
        'continuous worship since before the Vijayanagara Empire, which took Virupaksha as a '
        'principal royal deity amid the Tungabhadra boulder landscape.',
    story:
        'Virupaksha Temple on Hampi Bazaar Street is among the few Hampi monuments that never '
        'ceased to function as a living shrine. Worship here long predates the 14th–16th-century '
        'Vijayanagara capital; the empire elevated Virupaksha (a form of Shiva) as a state deity '
        'while expanding the gopurams, mandapas, and the long colonnaded bazaar street that still '
        'frames approaches to the sanctum.\n\n'
        'After the 1565 Battle of Talikota and the city’s sack, most of Hampi fell silent, yet '
        'Virupaksha’s cult persisted through local priestly continuity. Today the temple sits '
        'inside the UNESCO-inscribed Group of Monuments at Hampi (1986; boundary refinements '
        'later), balancing active ritual with ASI / Hampi World Heritage Area management '
        'pressures around shops, roads, and visitor infrastructure.\n\n'
        'Architecturally the complex shows mature Dravidian / Vijayanagara forms: towering east '
        'gopuram, multiple courts, and subsidiary shrines. The temple elephant traditionally '
        'blesses visitors near the entrance (names and presence change over time — confirm on '
        'site). Annual chariot festivals and the state-backed Hampi Utsav / Vijaya Utsav cultural '
        'season draw large crowds.\n\n'
        'Pampa (Parvati) is closely associated with the kshetra in local tradition, linking the '
        'shrine to the Tungabhadra’s sacred geography.',
    location: 'Hampi Bazaar, Hampi, Ballari, Karnataka 583239',
    timings:
        'Commonly listed living-temple darshan: ~6:00 AM–1:00 PM and 5:00 PM–9:00 PM (matches '
        'sample app). Incredible India / some guides cite slight variants (e.g. morning to noon, '
        'evening from ~4:30 PM) — confirm locally; festival and chariot days override. Monument '
        'precinct photography rules differ from inner sanctum rules. UNESCO/ASI context means '
        'visitor management can change during Hampi Utsav and peak winter tourism.',
    latitude: 15.3350,
    longitude: 76.4600,
    specialities: [
      'UNESCO Group of Monuments at Hampi (inscribed 1986)',
      'Continuous worship pre- and post-Vijayanagara',
      'Royal deity of the Vijayanagara Empire',
      'Hampi Bazaar colonnaded street backdrop',
      'Temple elephant blessing tradition (when present)',
      'Hampi Utsav / Vijaya Utsav cultural festival season',
    ],
  ),
  Temple(
    name: 'Srikanteshwara Temple, Nanjangud',
    state: 'Karnataka',
    city: 'Nanjangud',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/nanjangud/800/600',
    description:
        'Grand Kapila-bank Shaiva temple of Srikanteshwara / Nanjundeshwara — popularly Dakshina '
        'Kashi — with a towering Dravidian gopuram shaped by Ganga, Chola, Hoysala, and '
        'Mysore-period patronage and famous for healing vows and the Dodda Jathre chariot '
        'festival.',
    story:
        'Srikanteshwara Temple at Nanjangud (Garalapuri in puranic idiom) stands near the Kapila '
        '(Kabini) about 25 km from Mysuru. The deity is widely called Nanjundeshwara — “the Lord '
        'who consumed poison” — recalling Shiva’s drinking of Halahala during the ocean churning; '
        'local tradition places his cooling / healing presence on this riverbank. Srikanteshwara '
        '(“Lord of the blue/poison throat”) is the same identity under another epithet.\n\n'
        'Devotees style the kshetra Dakshina Kashi. Legends of demon Keshi’s destruction and of '
        'Parvati–Parameshwara’s praise of the Kapila–Kaundini sangam appear in local retellings '
        'of Skanda Purana material (summarised on the HRCE temple page). The vast stone complex '
        'and ~120-ft-class gopuram reflect layered Ganga, Chola, Hoysala, Vijayanagara, and '
        'Wodeyar building phases.\n\n'
        'Nanjangud Ayurveda and “healing Shiva” vows are part of modern pilgrimage culture; free '
        'or sponsored anna santarpana (mass feeding) is organised on many days. Dodda Jathre, the '
        'great annual chariot festival, fills the town with processional fervour.\n\n'
        'Administration falls under Karnataka HRCE (ITMS tid=7). Sundays, Mondays, and festival '
        'days may stay open with shorter midday breaks — confirm with the temple office.',
    location: 'Nanjangud, Mysuru District, Karnataka 571301',
    timings:
        'Karnataka HRCE ITMS (tid=7): open 6:00 AM–1:00 PM and 4:00 PM–8:30 PM (matches sample '
        'app). Secondary local guides often note continuous or extended hours on Sundays, '
        'Mondays, and special days (~6:00 AM–8:30 PM) and list multiple abhisheka markers '
        '(commonly cited around 6:45 AM, 9:30 AM, 11:00 AM, 12:00 PM, 6:30 PM, 8:00 PM — treat as '
        'indicative, confirm on site). Contact numbers commonly published via local temple info '
        'pages (e.g. 08221-226245). Festival / Dodda Jathre schedules override ordinary windows.',
    latitude: 12.1168,
    longitude: 76.6839,
    specialities: [
      'Dakshina Kashi (Southern Varanasi) epithet',
      'Nanjundeshwara / Srikanteshwara — Halahala poison legend',
      'Towering ~120-ft-class Dravidian gopuram',
      'Kapila riverbank rituals and sangam lore',
      'Dodda Jathre annual chariot festival',
      'Healing-vow and anna santarpana culture',
    ],
  ),
  Temple(
    name: 'ISKCON Temple, Bangalore',
    state: 'Karnataka',
    city: 'Bengaluru',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/iskconbangalore/800/600',
    description:
        'Sri Radha Krishna Temple of ISKCON on Hare Krishna Hill, Rajajinagar — a major modern '
        'Vaishnava complex opened in the late 1990s with elaborate arati schedule, cultural '
        'programmes, and the birthplace of the Akshaya Patra school-meal movement.',
    story:
        'ISKCON Sri Radha Krishna Temple occupies Hare Krishna Hill on Chord Road, Rajajinagar, '
        'Bengaluru. Built on land associated with state facilitation and opened to the public in '
        '1997, the complex blends Dravidian-inspired shikharas with contemporary pilgrimage '
        'amenities — prasadam halls, lecture spaces, guest house (Yatri Nivas), and panoramic '
        'city views from the hill.\n\n'
        'Deities of Sri Radha Krishnachandra and accompanying forms (including Krishna-Balarama '
        'and Nitai-Gauranga shrines within the wider campus narrative) receive a full ISKCON day '
        'cycle from brahma-muhurta Mangala Arati through night Shayana Arati. The temple '
        'popularised large-scale Janmashtami and Vaikuntha Ekadashi celebrations for Bengaluru’s '
        'urban devotees.\n\n'
        'From this campus emerged The Akshaya Patra Foundation’s mid-day meal work (pilot 2000 in '
        'Bengaluru schools), which grew into one of the world’s largest NGO-run school meal '
        'programmes — a social identity now as famous as the gopurams themselves. Exact '
        'contemporary meal counts change yearly; treat “millions of children daily” figures as '
        'order-of-magnitude, not a frozen statistic.\n\n'
        'Note there is a second major ISKCON centre on Kanakapura Road; this sample entry is the '
        'Rajajinagar hill temple. Photography is restricted inside; modest dress is requested.',
    location:
        'Hare Krishna Hill, Chord Rd, Rajajinagar, Bengaluru, Karnataka 560010',
    timings:
        'Official ISKCON Bangalore FAQ / temple schedule (iskconbangalore.org): Darshan morning '
        '4:15–5:15 AM and 7:15 AM–1:15 PM; evening 4:15–8:20 PM (FAQ) / programme runs through '
        'Shayana Arati ~8:15 PM. Weekends and public holidays: no afternoon break. Named '
        'programme markers: Mangala Arati 4:30 AM; Tulasi puja 4:45 AM; Narasimha Arati 5:00 AM; '
        'Shringara Darshana Arati & Guru Puja 7:15 AM; Srimad-Bhagavatam lecture 8:30 AM; Rajbhog '
        'Arati 12:30 PM; Dhupa Arati 4:15 PM; evening Tulasi 6:45 PM; Sandhya Arati 7:00 PM; '
        'Shayana Arati 8:15 PM. Friday Srinivasa Govinda abhisheka and Saturday Prahlada '
        'Narasimha abhisheka ~5:30 AM. Sample app “4:15 AM – 1:00 PM, 4:00 PM – 8:30 PM” is a '
        'coarse envelope. Confirm festival overrides on iskconbangalore.org/temple-schedule.',
    latitude: 13.0104,
    longitude: 77.5510,
    specialities: [
      'Hare Krishna Hill Sri Radha Krishna Temple (opened 1997)',
      'Full ISKCON arati cycle from Mangala to Shayana',
      'Birthplace of Akshaya Patra school-meal programme (2000 pilot)',
      'Janmashtami and major Vaishnava festival scale in Bengaluru',
      'Yatri Nivas guest house and free lunch prasadam windows',
      'Second ISKCON campus exists on Kanakapura Road — this entry is Rajajinagar',
    ],
  ),
];
