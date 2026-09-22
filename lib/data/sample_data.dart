import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
  // ═══════════════════════════════════════════════════════════════════════════
  //  TAMIL NADU
  // ═══════════════════════════════════════════════════════════════════════════
  // Research-enriched visitor copy for the existing 10 Tamil Nadu temples
  // (matched by name/slug — no new documents). KAN-77 Wave A covers are
  // Commons downloaded_url thumbs (not Storage paths). Sources:
  // docs/tamil-nadu-sample-research.md.

  // KAN-77: verified Commons thumbs — tools/photo-packs/meenakshi-amman-temple/
  Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Meenakshi_Amman_Temple_-_Gateway_Tower%2C_Madurai.jpg/1280px-Meenakshi_Amman_Temple_-_Gateway_Tower%2C_Madurai.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Meenakshi_Amman_Temple_-_Gateway_Tower%2C_Madurai.jpg/1280px-Meenakshi_Amman_Temple_-_Gateway_Tower%2C_Madurai.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/03_sunrise_view_of_Meenakshi_temple_gopuram.jpg/1280px-03_sunrise_view_of_Meenakshi_temple_gopuram.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Madurai_Meenakshi_temple_gopuram.jpg/1280px-Madurai_Meenakshi_temple_gopuram.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Madurai_Meenakshi_temple_1.jpg/1280px-Madurai_Meenakshi_temple_1.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Madurai_Meenakshi_Amman_Gopuram.jpg/1280px-Madurai_Meenakshi_Amman_Gopuram.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/MDU_Meenakshi_Amman_Temple.jpg/1280px-MDU_Meenakshi_Amman_Temple.jpg',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/brihadeeswarar-temple/
  Temple(
    name: 'Brihadeeswarar Temple',
    state: 'Tamil Nadu',
    city: 'Thanjavur',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/13/Ancient_Thanjavur_Brihadeeswarar_Temple_photos.jpg/1280px-Ancient_Thanjavur_Brihadeeswarar_Temple_photos.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/13/Ancient_Thanjavur_Brihadeeswarar_Temple_photos.jpg/1280px-Ancient_Thanjavur_Brihadeeswarar_Temple_photos.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b2/Thanjavur_Brihadeeswarar_temple.JPG/1280px-Thanjavur_Brihadeeswarar_temple.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ce/Brihadeeswarar_Temple_Entrance_in_Thanjavur.jpg/1280px-Brihadeeswarar_Temple_Entrance_in_Thanjavur.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1b/Brihadeeswarar_temple_evening%2C_Thanjavur%2C_Tamilnadu.jpg/1280px-Brihadeeswarar_temple_evening%2C_Thanjavur%2C_Tamilnadu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/Brihadeeswarar_temple_late_night%2C_Thanjavur%2C_Tamilnadu.jpg/1280px-Brihadeeswarar_temple_late_night%2C_Thanjavur%2C_Tamilnadu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/37/Brihadeeswarar_temple_night%2C_Thanjavur%2C_Tamilnadu.jpg/1280px-Brihadeeswarar_temple_night%2C_Thanjavur%2C_Tamilnadu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/kapaleeshwarar-temple/
  Temple(
    name: 'Kapaleeshwarar Temple',
    state: 'Tamil Nadu',
    city: 'Chennai',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/Chennai-Kapaleeshwarar_Temple-IMG_20250219_114340.jpg/1280px-Chennai-Kapaleeshwarar_Temple-IMG_20250219_114340.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/Chennai-Kapaleeshwarar_Temple-IMG_20250219_114340.jpg/1280px-Chennai-Kapaleeshwarar_Temple-IMG_20250219_114340.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b1/Chennai-Kapaleeshwarar_Temple-IMG_20250219_114343.jpg/1280px-Chennai-Kapaleeshwarar_Temple-IMG_20250219_114343.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9e/Chennai-Kapaleeshwarar_Temple-WUS01436.jpg/1280px-Chennai-Kapaleeshwarar_Temple-WUS01436.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/66/A_down_angle_view_of_the_Kapaleeshwarar_Temple_in_Chennai.jpg/1280px-A_down_angle_view_of_the_Kapaleeshwarar_Temple_in_Chennai.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/The_Kapaleeshwarar_Temple_in_Chennai.jpg/1280px-The_Kapaleeshwarar_Temple_in_Chennai.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/TNC25-4_Chariot_festival_Kapaleeshwarar_temple_Chennai.jpg/1280px-TNC25-4_Chariot_festival_Kapaleeshwarar_temple_Chennai.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/ramanathaswamy-temple/
  Temple(
    name: 'Ramanathaswamy Temple',
    state: 'Tamil Nadu',
    city: 'Rameswaram',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/85/Ramanathaswamy_Temple%2C_Rameswaram.jpg/1280px-Ramanathaswamy_Temple%2C_Rameswaram.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/85/Ramanathaswamy_Temple%2C_Rameswaram.jpg/1280px-Ramanathaswamy_Temple%2C_Rameswaram.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c4/Ramanathaswamy_Temple_Rameswaram_%281%29.jpg/1280px-Ramanathaswamy_Temple_Rameswaram_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Ramanathaswamy_Temple_Rameswaram_%282%29.jpg/1280px-Ramanathaswamy_Temple_Rameswaram_%282%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/46/Ramanathaswamy_Temple_Rameswaram_%283%29.jpg/1280px-Ramanathaswamy_Temple_Rameswaram_%283%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/The_great_corridor_at_Rameswaram_Ramanathaswamy_Temple.jpg/1280px-The_great_corridor_at_Rameswaram_Ramanathaswamy_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/25/Ramanathaswamy_temple_corridor.JPG/1280px-Ramanathaswamy_temple_corridor.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/murugan-temple-thirupparankundram/
  Temple(
    name: 'Murugan Temple, Thirupparankundram',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Murugan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_2.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_2.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a4/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_6.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_6.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0c/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_4.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/68/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_7.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_7.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_1.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6a/8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_5.jpg/1280px-8th_century_Thirupparankundram_cave_temple%2C_Madurai_district%2C_Tamil_Nadu_India_-_5.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/shore-temple/
  Temple(
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Shore_Temple_view_2_-_Mahabalipuram.jpg/1280px-Shore_Temple_view_2_-_Mahabalipuram.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Shore_Temple_view_2_-_Mahabalipuram.jpg/1280px-Shore_Temple_view_2_-_Mahabalipuram.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Shore_Temple_Mahabalipuram_Tamil-Nadu_India.jpg/1280px-Shore_Temple_Mahabalipuram_Tamil-Nadu_India.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/The_Shore_Temple_Mahabalipuram.jpg/1280px-The_Shore_Temple_Mahabalipuram.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Inside_Shore_Temple_facing_West.jpg/1280px-Inside_Shore_Temple_facing_West.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Beautiful_Shore_Temple%2C_Mamallapuram%2C_Tamil_Nadu.jpg/1280px-Beautiful_Shore_Temple%2C_Mamallapuram%2C_Tamil_Nadu.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Front_View_of_Shore_Temple.jpg/1280px-Front_View_of_Shore_Temple.jpg',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/nataraja-temple/
  Temple(
    name: 'Nataraja Temple',
    state: 'Tamil Nadu',
    city: 'Chidambaram',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/83/A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2812%29.jpg/1280px-A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2812%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/83/A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2812%29.jpg/1280px-A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2812%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/20/A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2814%29.jpg/1280px-A_view_of_Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_%2814%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/87/Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_2017_%2811%29.jpg/1280px-Nataraja_Shiva_Temple_at_Chidambaram%2C_Tamil_Nadu_2017_%2811%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b3/Nataraja_temple%2C_chidambaram_view_from_inside.jpg/1280px-Nataraja_temple%2C_chidambaram_view_from_inside.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Thillai_Nataraja_Temple_%28Chidambaram_Nataraja_Temple%29.jpg/1280px-Thillai_Nataraja_Temple_%28Chidambaram_Nataraja_Temple%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Courtyard%2C_Nataraja_Temple%2C_Chidambaram.jpg/1280px-Courtyard%2C_Nataraja_Temple%2C_Chidambaram.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/ekambaranathar-temple/
  Temple(
    name: 'Ekambaranathar Temple',
    state: 'Tamil Nadu',
    city: 'Kanchipuram',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/Kanchipuram%2C_Sri_Ekambaranathar_Temple_%286846490776%29.jpg/1280px-Kanchipuram%2C_Sri_Ekambaranathar_Temple_%286846490776%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/Kanchipuram%2C_Sri_Ekambaranathar_Temple_%286846490776%29.jpg/1280px-Kanchipuram%2C_Sri_Ekambaranathar_Temple_%286846490776%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8e/Ekambaranathar_Temple%2C_Kanchipuram_%2850065027238%29.jpg/1280px-Ekambaranathar_Temple%2C_Kanchipuram_%2850065027238%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/Ekambaranathar_Temple%2C_Kanchipuram_%2850065027343%29.jpg/1280px-Ekambaranathar_Temple%2C_Kanchipuram_%2850065027343%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/18/Ekambaranathar_Temple%2C_Kanchipuram_%2850065027493%29.jpg/1280px-Ekambaranathar_Temple%2C_Kanchipuram_%2850065027493%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Ekambaranathar_Temple%2C_Kanchipuram_%2850065027528%29.jpg/1280px-Ekambaranathar_Temple%2C_Kanchipuram_%2850065027528%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/88/Ekambaranathar_Temple%2C_Kanchipuram_%2850065842317%29.jpg/1280px-Ekambaranathar_Temple%2C_Kanchipuram_%2850065842317%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/arunachaleswarar-temple/
  Temple(
    name: 'Arunachaleswarar Temple',
    state: 'Tamil Nadu',
    city: 'Tiruvannamalai',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/Arulmigu_Arunachaleswarar_Temple%2C_Thiruvannamalai_%2842492949895%29.jpg/1280px-Arulmigu_Arunachaleswarar_Temple%2C_Thiruvannamalai_%2842492949895%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/Arulmigu_Arunachaleswarar_Temple%2C_Thiruvannamalai_%2842492949895%29.jpg/1280px-Arulmigu_Arunachaleswarar_Temple%2C_Thiruvannamalai_%2842492949895%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Thiruvannamalai_Arunachaleswarar_Temple_Rajagopuram.jpg/1280px-Thiruvannamalai_Arunachaleswarar_Temple_Rajagopuram.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/78/Tiruvannamalai_arunachaleswarar_kovil.jpg/1280px-Tiruvannamalai_arunachaleswarar_kovil.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2d/Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_India.jpg/1280px-Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/db/Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_Night_2%2C_India.jpg/1280px-Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_Night_2%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/aa/Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_Panoramic_view%2C_India.jpg/1280px-Thiruvannamalai%2C_Arunachalesvara_Temple%2C_Annamalaiyar_Temple%2C_Panoramic_view%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/sarangapani-temple/
  Temple(
    name: 'Sarangapani Temple',
    state: 'Tamil Nadu',
    city: 'Kumbakonam',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3b/Kumbakonam-Sarangapani_Temple-WUS03048.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03048.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3b/Kumbakonam-Sarangapani_Temple-WUS03048.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03048.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/54/Kumbakonam-Sarangapani_Temple-WUS03052.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03052.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7e/Kumbakonam-Sarangapani_Temple-WUS03053.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03053.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/90/Kumbakonam-Sarangapani_Temple-WUS03055.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03055.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/32/Kumbakonam-Sarangapani_Temple-WUS03057.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03057.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fc/Kumbakonam-Sarangapani_Temple-WUS03059.jpg/1280px-Kumbakonam-Sarangapani_Temple-WUS03059.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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

  // ── KAN-64 / KAN-74 expansion batch 16 — +10 additional Tamil Nadu temples
  // Core Temple fields only (Hybrid C): trip_planning stripped / not seeded.
  // KAN-77 Wave A fills Commons thumbs where a pack is on file. Kanyakumari
  // stays empty (shortfall). Thiruchendur uses the site-verified Tiruchendur
  // pack (the earlier Elamkunnapuzha frames were not used).
  // KAN-77: verified Commons thumbs — tools/photo-packs/sri-ranganathaswamy-temple-srirangam/
  Temple(
    name: 'Sri Ranganathaswamy Temple',
    state: 'Tamil Nadu',
    city: 'Srirangam',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28105%29_%2836802865564%29.jpg/1280px-Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28105%29_%2836802865564%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28105%29_%2836802865564%29.jpg/1280px-Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28105%29_%2836802865564%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/44/Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28151%29_%2837465657406%29.jpg/1280px-Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%28151%29_%2837465657406%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%2816%29_%2836842412443%29.jpg/1280px-Sri_Ranganathaswamy_Temple%2C_dedicated_to_Vishnu%2C_in_Srirangam%2C_near_Tiruchirappali_%2816%29_%2836842412443%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/36/Sri_Ranganathaswamy_Temple_in_Srirangam%2C_Tamil_Nadu.jpg/1280px-Sri_Ranganathaswamy_Temple_in_Srirangam%2C_Tamil_Nadu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Ranganathaswamy_Temple%2C_Srirangam_ttkcvrvb122k23iph_%281%29.jpg/1280px-Ranganathaswamy_Temple%2C_Srirangam_ttkcvrvb122k23iph_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Ranganathaswamy_Temple%2C_Srirangam_ttkcvrvb122k23iph_%2813%29.jpg/1280px-Ranganathaswamy_Temple%2C_Srirangam_ttkcvrvb122k23iph_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Foremost among the 108 Divya Desams — a vast island temple town '
        'dedicated to reclining Vishnu as Ranganatha, with concentric '
        'prakarams, many gopurams including the ~73 m Rajagopuram, and living '
        'Thenkalai Sri Vaishnava worship.',
    story:
        'Sri Ranganathaswamy Temple stands on the island of Srirangam between '
        'the Kaveri and Kollidam rivers north of Tiruchirappalli. It is counted '
        'as the first of the 108 Divya Desams and is praised across the '
        'Naalayira Divya Prabandham; tradition and UNESCO’s tentative-list '
        'description treat it as one of the world’s largest functioning Hindu '
        'temple complexes still in continuous active worship.\n\n'
        'Temple legend links the south-facing reclining Ranganatha (on '
        'Adishesha) to Vibhishana’s gift of the Sriranga vimana after Rama’s '
        'victory; historically the site grew under Chola, Pandya, Hoysala, '
        'Vijayanagara and Nayaka patronage, was devastated in '
        'early-14th-century invasions, and was restored from the late 14th '
        'century. Ramanuja’s long association made Srirangam a hub of Sri '
        'Vaishnava theology (Thenkalai practice continues).\n\n'
        'Architecturally the complex uses a sapta-prakaram plan with dozens of '
        'shrines, mandapas (including the thousand-pillar hall), tanks, and 21 '
        'gopurams. The outer Rajagopuram — base from the Vijayanagara era, '
        'completed in 1987 with Ahobila Matha support — rises about 73 m and '
        'dominates the skyline. Dual foci are Ranganatha’s gold-plated vimana '
        'sanctum and Goddess Ranganayaki’s shrine; Serthi Sevai on Panguni '
        'Uthiram is the rare annual joint darshan.\n\n'
        'Daily worship follows classic Sri Vaishnava seva rhythm with '
        'Viswaroopa and multiple ritual closures for Thirumanjanam / Naivedyam '
        '/ Sayaratchai. Vaikunta Ekadasi (Margazhi Pagal Pathu / Ra Pathu) '
        'draws enormous crowds when the Paramapada Vasal opens. Modest dress '
        'and queue discipline are enforced; festival calendars override '
        'ordinary hours — confirm on the official HR&CE portal before travel.',
    location: 'Srirangam, Tiruchirappalli, Tamil Nadu 620006',
    timings:
        'OFFICIAL HR&CE (srirangamranganathar.hrce.tn.gov.in): nadai open '
        'broadly 06:00 AM–12:00 PM and 12:00 PM–09:00 PM, with daily closures '
        '07:15–09:00 AM, 12:30–02:15 PM, and 05:30–07:00 PM for rituals (no '
        'general darshan in those windows). Arrive ≥1 hour before session end. '
        'Viswaroopa / early morning seva is typically in the first open window '
        '(secondary guides cite ~06:15–07:15 AM; no Viswaroopa in Margazhi / '
        'some festival days). Festival calendars (esp. Vaikunta Ekadasi, '
        'Brahmotsavam) change times — confirm same day on the portal. Visitor '
        'tip: Dress code for inner prakarams is traditionally strict '
        '(dhoti/saree norms commonly enforced). Free and paid/VIP darshan '
        'options appear on the HR&CE ticketing flow — prefer official portal '
        'over street agents. Annadhanam schemes operate under HR&CE; confirm '
        'current counters on site.',
    latitude: 10.8625,
    longitude: 78.68972,
    specialities: [
      'Foremost of 108 Divya Desams; Thenkalai Sri Vaishnava living temple',
      'Seven concentric prakarams; ~73 m Rajagopuram (completed 1987)',
      'Reclining Ranganatha on Adishesha; Ranganayaki shrine',
      'Vaikunta Ekadasi / Paramapada Vasal; Panguni Uthiram Serthi Sevai',
      'UNESCO Tentative List; 2017 UNESCO Asia-Pacific conservation award',
      'Nearest airport: Tiruchirappalli (TRZ) — ~15 km',
      'Veg food: dense pure-veg / sattvic options in Srirangam temple streets',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/dhandayuthapani-swamy-temple-palani/
  Temple(
    name: 'Dhandayuthapani Swamy Temple',
    state: 'Tamil Nadu',
    city: 'Palani',
    deity: 'Murugan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c4/Arulmigu_Dhandayuthapani_Swamy_Temple_in_Palany_hill.jpg/1280px-Arulmigu_Dhandayuthapani_Swamy_Temple_in_Palany_hill.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c4/Arulmigu_Dhandayuthapani_Swamy_Temple_in_Palany_hill.jpg/1280px-Arulmigu_Dhandayuthapani_Swamy_Temple_in_Palany_hill.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Palani_Temple-WUS05301.jpg/1280px-Palani_Temple-WUS05301.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/48/Palani_Temple-WUS05302.jpg/1280px-Palani_Temple-WUS05302.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7c/Palani_Temple-WUS05303.jpg/1280px-Palani_Temple-WUS05303.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b4/Palani_Murugan_Hill_Temple.jpg/1280px-Palani_Murugan_Hill_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a8/Gopuram_in_the_way_to_palani_temple.jpg/1280px-Gopuram_in_the_way_to_palani_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'One of the Six Abodes of Murugan (Arupadai Veedu) — the hill shrine of '
        'Dhandayuthapani atop Sivagiri at Palani, famed for the standing '
        'Murugan with staff and for massive Thaipusam / Panguni Uthiram pilgrim '
        'crowds.',
    story:
        'Arulmigu Dhandayuthapani Swamy Temple crowns Sivagiri hill in Palani, '
        'Dindigul district — one of Murugan’s six primary abodes. Legend holds '
        'that after the contest for the celestial fruit, Murugan withdrew here '
        'as a renunciant youth holding a staff (dandam), and sage Bhogar is '
        'traditionally credited with fashioning the navapashana idol still '
        'worshipped in the sanctum.\n\n'
        'The hill complex combines Pandya- and later-period stone work with a '
        'gold-plated vimana; lower shrines and the long stepped climb (plus '
        'winch / ropeway options when operating) structure the pilgrim path. '
        'Tonsure halls, kavadi processions, and panchamirutham offerings '
        'dominate the lived ritual culture.\n\n'
        'Daily worship follows HR&CE nadai windows from early morning through '
        'evening, with Viswaroopa and other named sevas on the official board. '
        'Major surge days — Thaipusam, Panguni Uthiram, Kandhar Sashti, monthly '
        'Karthigai, Margazhi, Deepavali — open earlier (often 04:00 AM) and may '
        'close late depending on footfall.\n\n'
        'Palani is a classic Murugan pilgrimage town: combine hill darshan with '
        'foothill shrines if time allows, and expect stairs, queues, and modest '
        'dress enforcement. Confirm winch/ropeway status and special-entry '
        'tickets on palanimurugan.hrce.tn.gov.in before climbing.',
    location: 'Sivagiri Hill, Palani, Dindigul District, Tamil Nadu 624601',
    timings:
        'OFFICIAL HR&CE (palanimurugan.hrce.tn.gov.in, tid=32203): ordinary '
        'days nadai 05:45 AM–01:00 PM and 01:00 PM–08:00 PM. Festival / special '
        'days (Thaipusam 10 days, Panguni Uthiram 10 days, Kandhar Sashti 10 '
        'days, monthly Karthigai, Maha Deepa Karthigai, Thai Pongal, Tamil & '
        'English New Year, all Margazhi days, Deepavali) open ~04:00 AM and may '
        'remain open past 09:00 PM depending on devotee inflow. Confirm '
        'same-day board and online tickets on the portal. Visitor tip: Hill '
        'climb involves many steps; elders and differently abled pilgrims '
        'should check winch/ropeway and special queues. Hair-tonsure facilities '
        'are common — follow hygiene and waste rules posted on site.',
    latitude: 10.438805,
    longitude: 77.520261,
    specialities: [
      'Arupadai Veedu — Sivagiri hill shrine of Dhandayuthapani',
      'Navapashana idol tradition associated with sage Bhogar',
      'Thaipusam, Panguni Uthiram, Kandhar Sashti pilgrim peaks',
      'Steps / winch / ropeway access options (confirm operating status)',
      'Tonsure and panchamirutham offering culture',
      'Nearest airport: Coimbatore (CJB) — roughly 100+ km by road',
      'Veg food: dense pure-veg pilgrim messes around Adivaram / town',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/subramanya-swamy-temple-thiruchendur/
  Temple(
    name: 'Subramanya Swamy Temple',
    state: 'Tamil Nadu',
    city: 'Thiruchendur',
    deity: 'Murugan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fd/The_Raja_Gopuram_at_Thiruchendur_Murugan_Temple.JPG/1280px-The_Raja_Gopuram_at_Thiruchendur_Murugan_Temple.JPG',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fd/The_Raja_Gopuram_at_Thiruchendur_Murugan_Temple.JPG/1280px-The_Raja_Gopuram_at_Thiruchendur_Murugan_Temple.JPG',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bf/Arulmigu_Subramaniya_Swamy_Temple%2C_Tiruchendur.jpg/1280px-Arulmigu_Subramaniya_Swamy_Temple%2C_Tiruchendur.jpg',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/38/Murugan_temple_at_Thiruchendur.jpg/1280px-Murugan_temple_at_Thiruchendur.jpg',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5e/Thiruchendur_Temple_Rajagopuram.JPG/1280px-Thiruchendur_Temple_Rajagopuram.JPG',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/92/Thiruchendur_Murugan_Temple_Thiruchendur_Tamil_Nadu.jpg/1280px-Thiruchendur_Murugan_Temple_Thiruchendur_Tamil_Nadu.jpg',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0d/Thiruchendur_Temple_from_seashore.jpg/1280px-Thiruchendur_Temple_from_seashore.jpg',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e2/Naazhikinaru_entrance_at_the_Thiruchendur_Murugan_Temple.JPG/1280px-Naazhikinaru_entrance_at_the_Thiruchendur_Murugan_Temple.JPG',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/51/Thiruchendur_Sri_Subramaniya_Swamy_Temple_2014_%288%29.jpg/1280px-Thiruchendur_Sri_Subramaniya_Swamy_Temple_2014_%288%29.jpg',
    ],
    description:
        'Seaside Arupadai Veedu of Murugan at Tiruchendur on the Bay of Bengal '
        '— the only one of the six abodes on the shore, celebrated for '
        'Surasamharam and continuous Kumara Thanthiram worship.',
    story:
        'Arulmigu Subramania Swamy Temple at Tiruchendur (Thiruchendur) stands '
        'on the Bay of Bengal shore in Thoothukudi district — unique among the '
        'Six Abodes of Murugan for its coastal setting. Tradition identifies '
        'this as the place where Murugan camped before defeating Surapadman; '
        'the annual Surasamharam reenactment draws huge crowds.\n\n'
        'The complex features a tall multi-tiered rajagopuram facing the sea, '
        'rock-cut and later Dravidian fabric, and a sanctum tradition that sits '
        'notably close to the shoreline. The temple is administered by TN HR&CE '
        'and has public online ticketing for selected sevas and pilgrim rooms.\n\n'
        'Worship follows the Kumara Thanthiram Murai with a dense daily pooja '
        'board published by the Devasthanam (Subrapadam through Palliarai). '
        'Ordinary days run roughly sunrise-to-night; Margazhi, Vaikasi Visakam, '
        'Masi/Avani festival peaks, Kandhar Sashti, Thai Poosam and Panguni '
        'Uthiram shift opening as early as 01:00–04:00 AM per the HR&CE '
        'festival note.\n\n'
        'Combine darshan with the seashore walk, but respect restricted zones '
        'and weather advisories. Confirm current nadai and abhisheka tickets on '
        'tiruchendurmurugan.hrce.tn.gov.in.',
    location: 'Tiruchendur, Thoothukudi District, Tamil Nadu 628215',
    timings:
        'OFFICIAL HR&CE (tiruchendurmurugan.hrce.tn.gov.in, tid=38271): '
        'ordinary listed spans include 04:00 AM–12:00 PM and 12:00 PM–09:00 PM '
        '(Devasthanam / tourism boards commonly summarise as ~05:00 AM–09:00 PM '
        'with nine daily pooja kalams). Named Devasthanam poojas '
        '(tiruchendur.org): Subrapadam ~05:10 AM through Palliarai ~08:45 PM / '
        'nadai close ~09:00 PM. Festival overrides: Margazhi often 03:00 '
        'AM–08:00 PM; Vaikasi Visakam, Thai Poosam, selected Masi/Avani/Kandhar '
        'Sashti days may open ~01:00 AM — confirm Tamil notes on HR&CE pooja '
        'page same day. Visitor tip: Seashore location — monsoon swell and '
        'crowd control can affect access paths. Follow Devasthanam notices for '
        'Naazhi Kinaru / special abhishekam queues.',
    latitude: 8.49583,
    longitude: 78.12917,
    specialities: [
      'Arupadai Veedu — only seaside Murugan abode among the six',
      'Surasamharam / Kandhar Sashti victory festival',
      'Kumara Thanthiram Murai — dense daily pooja board',
      'Tall shore-facing rajagopuram and beachfront setting',
      'HR&CE online seva and pilgrim-room ticketing',
      'Nearest airport: Tuticorin (TCR) — closer than Madurai for many itineraries',
      'Veg food: pure-veg pilgrim eateries in temple town',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/swamimalai-murugan-temple/
  Temple(
    name: 'Swamimalai Murugan Temple',
    state: 'Tamil Nadu',
    city: 'Swamimalai',
    deity: 'Murugan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/77/Swamimalai_Murugan_Temple.jpg/1280px-Swamimalai_Murugan_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/77/Swamimalai_Murugan_Temple.jpg/1280px-Swamimalai_Murugan_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ca/Swaminathan_Temple_-_Swamimalai_%281%29.jpg/1280px-Swaminathan_Temple_-_Swamimalai_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/68/Swaminathan_Temple_-_Swamimalai_%282%29.jpg/1280px-Swaminathan_Temple_-_Swamimalai_%282%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b3/Swaminathan_Temple_-_Swamimalai_%283%29.jpg/1280px-Swaminathan_Temple_-_Swamimalai_%283%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/96/Swamimalai_temple.jpg/1280px-Swamimalai_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9e/Swamimalai%2C_Kumbakonam%2C_Tamil_Nadu%2C_India_-_panoramio_%281%29.jpg/1280px-Swamimalai%2C_Kumbakonam%2C_Tamil_Nadu%2C_India_-_panoramio_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Arupadai Veedu where Murugan as Swaminatha taught the Pranava mantra '
        'to Shiva — a hillock shrine near Kumbakonam with sixty steps named for '
        'the Tamil years.',
    story:
        'Swaminatha Swamy Temple at Swamimalai, near Kumbakonam on a Kaveri '
        'tributary, is one of Murugan’s Six Abodes. Core legend: Murugan '
        'instructs his father Shiva in the meaning of Om (Pranava), earning the '
        'name Swaminatha — “teacher of the Lord.” The Murugan sanctum sits atop '
        'the hillock while Shiva–Parvati shrines stand at the base, encoding '
        'the student–teacher hierarchy in plan.\n\n'
        'Sixty steps — each named for a year of the Tamil calendar — climb the '
        '~60 ft hillock through three precincts and multiple gopurams. '
        'Iconography here notably pairs Murugan with an elephant mount (shared '
        'only with Tiruttani among major Murugan sites). The temple is sung in '
        'Tirumurukāṟṟuppaṭai and later Tiruppugazh traditions.\n\n'
        'HR&CE lists ordinary nadai roughly 06:00 AM–01:00 PM and 04:00 '
        'PM–09:00 PM with a midday close; monthly Krithigai and major festivals '
        'often keep the sanctum open through the day to Ardhajama. Six-kala '
        'pooja rhythm is traditional; Thursdays feature diamond Vel alankaram '
        'in local practice.\n\n'
        'Pair with a Kumbakonam temple circuit if time allows. Confirm festival '
        'continuity and special-entry tickets on '
        'swamimalaiswaminathar.hrce.tn.gov.in.',
    location:
        'Swamimalai, near Kumbakonam, Thanjavur District, Tamil Nadu 612302',
    timings:
        'OFFICIAL HR&CE (swamimalaiswaminathar.hrce.tn.gov.in, tid=18002): '
        '06:00 AM–01:00 PM and 04:00 PM–09:00 PM; closed 01:00–04:00 PM on '
        'ordinary days. Monthly Krithigai and other major festival days: '
        'sanctum often remains open from morning through night Ardhajama pooja '
        '(no midday close) — confirm Tamil note on portal. Secondary guides '
        'list six-kala markers '
        '(Usha/Kalasandhi/Uchi/Sayaratchai/Irandam/Ardhajama); treat named '
        'minutes as provisional vs official open/close. Visitor tip: Carry '
        'water for the climb; footwear rules apply on the hill. Thursday '
        'diamond-Vel darshan is a popular local highlight — expect slightly '
        'longer queues.',
    latitude: 10.956844,
    longitude: 79.325776,
    specialities: [
      'Arupadai Veedu — Murugan as Swaminatha (teacher of Pranava to Shiva)',
      'Sixty steps named for Tamil calendar years',
      'Elephant mount iconography (with Tiruttani)',
      'Base Shiva–Meenakshi shrines + hilltop Murugan sanctum',
      'Vaikasi Visakam and monthly Krithigai peaks',
      'Nearest airport: Tiruchirappalli (TRZ) — ~90 km class road transfer',
      'Veg food: easy pure-veg options via Kumbakonam / Swamimalai pilgrim belt',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/jambukeswarar-temple-thiruvanaikaval/
  Temple(
    name: 'Jambukeswarar Temple',
    state: 'Tamil Nadu',
    city: 'Thiruvanaikaval',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2852%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2852%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2852%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2852%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/69/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%281%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2815%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2815%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2816%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2816%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/57/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2817%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2817%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b4/Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2818%29.jpg/1280px-Jambukeswarar_Temple_surroundings%2C_Thiruvanaikaval_ttkcvrvb122k23pxl_%2818%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Pancha Bhoota Stalam for water (Appu Lingam) at Thiruvanaikaval on '
        'Srirangam island — Shiva as Jambukeswarar with Goddess Akilandeswari, '
        'famed for the underground stream in the sanctum.',
    story:
        'Jambukeswarar Temple at Thiruvanaikaval (also Thiruvanaikoil) sits on '
        'the same Kaveri island as Srirangam, a short distance from the '
        'Ranganathaswamy complex. It is the water element (Appu Lingam) among '
        'Tamil Nadu’s five Pancha Bhoota Shiva temples; an underground stream '
        'is traditionally said to feed the sanctum even in dry seasons.\n\n'
        'Legend centres on Goddess Parvati as Akilandeswari worshipping Shiva '
        'under a jambu (rose-apple) tree, and on the Chola king Kochengat '
        'Cholan’s early stone temple patronage. The living complex pairs '
        'Jambukeswarar’s watery lingam with a powerful Amman shrine; a '
        'distinctive noon ritual tradition has a priest in goddess attire '
        'performing worship — often cited by visitors as a unique local '
        'practice.\n\n'
        'HR&CE publishes weekday split hours (06:00–13:00 and 15:00–21:00 '
        'Mon–Thu) and continuous 06:00–21:00 Fri–Sun, plus a five-pooja board '
        '(Ushakkala through Ardhajama). Pairing Srirangam Vaishnava and '
        'Thiruvanaikaval Shaiva darshan in one island day is a classic Trichy '
        'pilgrimage pattern.\n\n'
        'Confirm festival overrides and special abhishekams on '
        'thiruvanaikavaljambukeswarar.hrce.tn.gov.in.',
    location:
        'Thiruvanaikaval (Thiruvanaikoil), Tiruchirappalli, Tamil Nadu 620005',
    timings:
        'OFFICIAL HR&CE (thiruvanaikavaljambukeswarar.hrce.tn.gov.in / '
        'tid=25706): Mon–Thu 06:00 AM–01:00 PM and 03:00 PM–09:00 PM (midday '
        'close 01:00–03:00 PM); Fri–Sun continuous 06:00 AM–09:00 PM. Named '
        'poojas: Ushakkala 06:30–07:30 AM; Kalasandhi 08:00–09:00 AM; Uchikala '
        '11:00 AM–12:00 PM; Sayaraksha 05:00–06:00 PM; Ardhajama 08:30–09:00 '
        'PM. Festival days may change — confirm portal. Visitor tip: '
        'Photographing inside sanctum areas is often restricted — follow posted '
        'rules. Midday close Mon–Thu is easy to miss if relying on outdated '
        'aggregator clocks that still say 5:30–8:30.',
    latitude: 10.85333,
    longitude: 78.70556,
    specialities: [
      'Pancha Bhoota Stalam — water / Appu Lingam',
      'Underground stream tradition in the sanctum',
      'Akilandeswari shrine; noon goddess-attire priest ritual tradition',
      'Paadal Petra Sthalam / early Chola associations',
      'Same island as Srirangam — easy dual-darshan circuit',
      'Nearest airport: Tiruchirappalli (TRZ)',
      'Veg food: shared Srirangam / Trichy pure-veg corridor',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/thyagaraja-temple-tiruvarur/
  Temple(
    name: 'Thyagaraja Temple',
    state: 'Tamil Nadu',
    city: 'Tiruvarur',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Thyagarajar_temple%2C_Tiruvarur_%2813%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Thyagarajar_temple%2C_Tiruvarur_%2813%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/18/Thyagarajar_temple%2C_Tiruvarur_%2814%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2814%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/95/Thyagarajar_temple%2C_Tiruvarur_%2826%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2826%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Thyagarajar_temple%2C_Tiruvarur_%2827%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2827%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7d/Thyagarajar_temple%2C_Tiruvarur_%2828%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2828%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/Thyagarajar_temple%2C_Tiruvarur_%2834%29.jpg/1280px-Thyagarajar_temple%2C_Tiruvarur_%2834%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Paadal Petra Shiva temple of Thyagarajaswami and Neelotpalambika at '
        'Tiruvarur — Chola-era complex famed for the massive temple car, '
        'Kamalalayam tank, and deep links to Carnatic music heritage.',
    story:
        'Thyagaraja Temple (Arulmigu Thiyagaraswamy Temple) at Tiruvarur is a '
        'major Chola-period Shaiva complex where Shiva is worshipped as '
        'Thyagarajaswami (Putridankondar) and Parvati as Neelotpalambika, with '
        'a significant separate Kamalambika shrine important to Shakta–Tantra '
        'traditions. It is a Paadal Petra Sthalam sung by the Nayanars.\n\n'
        'The town and temple are inseparable from South Indian music history: '
        'Tyagaraja of the Carnatic trinity took his name association from this '
        'deity tradition, and Tiruvarur remains a pilgrimage and festival '
        'centre for musicians and Shaiva devotees alike. Architecturally the '
        'precinct is vast, with multiple gopurams, numerous sub-shrines, a huge '
        'temple car, and the broad Kamalalayam tank.\n\n'
        'Distinctive ritual lore includes rare public display of Thyagaraja’s '
        'feet on selected festival days and the unusual standing Nandi facing '
        'the sanctum. Navagraha shrines aligned in a straight line are another '
        'oft-cited feature.\n\n'
        'HR&CE lists ordinary open windows around 06:00 AM–12:00 PM and 04:00 '
        'PM–09:00 PM; festival car processions and major utsavams override — '
        'confirm tid=14254 pooja page before travel.',
    location: 'Tiruvarur, Tiruvarur District, Tamil Nadu 610003',
    timings:
        'OFFICIAL HR&CE (tid=14254): commonly listed ordinary nadai ~06:00 '
        'AM–12:00 PM and 04:00 PM–09:00 PM (confirm live board — some secondary '
        'guides cite 05:30 AM opens). Named daily pooja minutes are thinner on '
        'English portal extracts — treat detailed kala times as provisional and '
        'verify on site or Tamil HR&CE pages. Major car-festival and '
        'Brahmotsavam days change everything. Visitor tip: Car-festival days '
        'bring extreme crowds and road closures — arrive early and follow '
        'police/temple routing. Feet-darshan days are limited; do not assume '
        'daily access.',
    latitude: 10.7761,
    longitude: 79.6335,
    specialities: [
      'Paadal Petra Sthalam — Thyagarajaswami / Neelotpalambika',
      'Kamalambika shrine (Shakta importance) and Kamalalayam tank',
      'Among India’s largest temple cars; famous car festival',
      'Carnatic music / Tyagaraja heritage associations',
      'Standing Nandi; rare feet-darshan festival days',
      'Nearest airport: Tiruchirappalli (TRZ)',
      'Veg food: temple-town pure-veg messes',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/nellaiappar-temple-tirunelveli/
  Temple(
    name: 'Nellaiappar Temple',
    state: 'Tamil Nadu',
    city: 'Tirunelveli',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/Nellaiappar_Temple_%2848410%29.jpg/1280px-Nellaiappar_Temple_%2848410%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/Nellaiappar_Temple_%2848410%29.jpg/1280px-Nellaiappar_Temple_%2848410%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c5/NELLAIAPPAR_TEMPLE_02.jpg/1280px-NELLAIAPPAR_TEMPLE_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Thamira_saba-Nellaiappar_Temple.jpg/1280px-Thamira_saba-Nellaiappar_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0d/Natarajar_Sannithi%2C_Nellaiappar_Temple.jpg/1280px-Natarajar_Sannithi%2C_Nellaiappar_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Nellaiappar_temple_tower.jpg/1280px-Nellaiappar_temple_tower.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f0/Nellaiappar_Temple10.jpg/1280px-Nellaiappar_Temple10.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Twin Shaiva complex of Nellaiappar and Kanthimathi Amman in '
        'Tirunelveli — a Paadal Petra Sthalam on the Tamiraparani with musical '
        'pillars, Chain Mandapam, and a rich dual-sanctum pooja board.',
    story:
        'Nellaiappar Temple (Arulmigu Nellaiyappar Arultharum Kanthimathi '
        'Amman) is the civic-religious heart of Tirunelveli on the northern '
        'banks of the Tamiraparani. Shiva as Nellaiappar (Venuvananathar) and '
        'Goddess Kanthimathi form a twin-temple complex historically linked by '
        'the Chain Mandapam; Vishnu is also associated with the divine wedding '
        'lore, giving the site abhimana importance for some Vaishnava pilgrims.\n\n'
        'Classified among the Paadal Petra Sthalams of the Tevaram saints, the '
        'fabric shows early Pandya and later Chola–Nayaka layers. Visitor '
        'highlights include the Mani Mandapam musical pillars, flower garden '
        'with pillared Vasantha Mandapam, and large festival cars including a '
        'golden car used on select utsavam days.\n\n'
        'HR&CE publishes a clear ordinary clock — 05:30 AM–12:30 PM and 04:00 '
        'PM–09:05 PM — with a detailed named pooja sequence from Thiruvananthal '
        'through Palliyarai. Dual sanctums mean Amman and Swami boards can '
        'differ by minutes; follow on-site notices.\n\n'
        'Tirunelveli is a natural base for southern TN temple circuits '
        '(including Tiruchendur). Confirm festival calendars on '
        'tvlnellaiapparkanthimathiamman.hrce.tn.gov.in.',
    location: 'Tirunelveli Town, Tirunelveli District, Tamil Nadu 627006',
    timings:
        'OFFICIAL HR&CE (tid=37881 / '
        'tvlnellaiapparkanthimathiamman.hrce.tn.gov.in): 05:30 AM–12:30 PM and '
        '04:00 PM–09:05 PM. Named poojas (portal): Thiruvananthal 06:00–06:30 '
        'AM; Vila 07:00–07:30 AM; Sirukala Sandhi 08:00–08:30 AM; Kalasandhi '
        '(special alankaram) 09:00–09:30 AM; Uchikala 12:00–12:30 PM; '
        'Sayaratchai (special alankaram) 05:30–06:00 PM; Ardhajama 08:15–08:30 '
        'PM; Palliyarai 09:00 PM. Dual Amman/Swami boards may differ slightly — '
        'confirm on site. Festivals override. Visitor tip: Plan time for both '
        'sanctums; paid special-entry queues may be available. Musical pillars '
        'are a heritage highlight — follow staff guidance on touching.',
    latitude: 8.728444,
    longitude: 77.688722,
    specialities: [
      'Paadal Petra Sthalam — Nellaiappar & Kanthimathi twin complex',
      'Chain Mandapam linking the two sanctums',
      'Musical pillars in Mani Mandapam',
      'Tamiraparani riverside temple-town setting',
      'Major Brahmotsavam / Tirukalyanam / car festivals',
      'Nearest airport: Tuticorin (TCR) or Madurai (IXM)',
      'Veg food: Tirunelveli town pure-veg messes (halwa is famous but check eggless/veg status)',
    ],
  ),
  Temple(
    name: 'Kanyakumari Bhagavathi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Kanyakumari',
    deity: 'Devi',
    imageUrl: '',
    description:
        'Coastal Devi temple of Kumari Amman (Bhagavathi) at India’s southern '
        'tip — a living HR&CE shrine where the virgin goddess faces the '
        'confluence of three seas.',
    story:
        'Arulmigu Bagavathi Amman Temple at Kanyakumari is dedicated to the '
        'virgin goddess Kumari (an aspect of Devi/Parvati), standing near the '
        'famous confluence of the Bay of Bengal, Arabian Sea and Indian Ocean. '
        'Pilgrimage tradition intertwines the temple with the wider Cape '
        'Comorin sacred geography of sunrise/sunset viewpoints and coastal '
        'shrines.\n\n'
        'Legend narrates the goddess’s penance and interrupted wedding with '
        'Shiva, leaving her as the eternal kanya (virgin) protector of the '
        'southern shore. The temple remains an active Devi worship centre under '
        'TN HR&CE administration, distinct from the modern Vivekananda Rock / '
        'statue tourism layer around it.\n\n'
        'Daily rhythm emphasises early abhishekam and deeparadhana cycles with '
        'an evening Sayaratchai and closing Yeganda / Sribali sequence. Tourist '
        'footfall is high year-round; temple queues intensify around sunrise, '
        'Navaratri, and full-moon evenings.\n\n'
        'Combine respectful darshan with the cape’s natural spectacle, but '
        'treat dress code and camera rules inside the temple as stricter than '
        'the surrounding tourist zone. Confirm hours on HR&CE tid=38360 pages.',
    location: 'Kanyakumari, Kanyakumari District, Tamil Nadu 629702',
    timings:
        'HR&CE (tid=38360) / widely cited official-aligned board: ordinary '
        'darshan ~04:30 AM–12:30 PM and 04:00 PM–08:30 PM. Commonly listed '
        'ritual markers: Abhishekam ~05:00 AM & ~10:00 AM; Deeparadhana ~06:00 '
        'AM & ~11:30 AM; Sayaratchai Deeparadhana ~06:30 PM; Sribali ~08:15 PM; '
        'Yeganda Deeparadhana ~08:25 PM; close ~08:30 PM. Named minutes partly '
        'from secondary compilations of the HR&CE board — confirm live notice. '
        'Festivals/Navaratri may extend or shift. Visitor tip: Inner temple '
        'photography is typically restricted. Tourist crowds around the cape do '
        'not equal temple entry rules — follow HR&CE dress and queue notices.',
    latitude: 8.0883,
    longitude: 77.5385,
    specialities: [
      'Devi as Kumari Amman at India’s southern tip',
      'Sea-confluence pilgrimage geography',
      'Living HR&CE Devi temple amid cape tourism',
      'Sunrise / full-moon evening pilgrim peaks',
      'Navaratri and Tamil calendar festivals',
      'Nearest airport: Trivandrum (TRV) — common gateway',
      'Veg food: mixed tourist town — seek labelled pure-veg near temple',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/vaitheeswaran-koil/
  Temple(
    name: 'Vaitheeswaran Koil',
    state: 'Tamil Nadu',
    city: 'Vaitheeswaran Koil',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/VAITHEESWARAN_KOIL_-_panoramio.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/VAITHEESWARAN_KOIL_-_panoramio.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c4/VAITHEESWARAN_KOIL_-_panoramio_%2810%29.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio_%2810%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/29/VAITHEESWARAN_KOIL_-_panoramio_%2811%29.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio_%2811%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/71/VAITHEESWARAN_KOIL_-_panoramio_%2812%29.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio_%2812%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f8/VAITHEESWARAN_KOIL_-_panoramio_%2813%29.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/51/VAITHEESWARAN_KOIL_-_panoramio_%2814%29.jpg/1280px-VAITHEESWARAN_KOIL_-_panoramio_%2814%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Shaiva healing shrine of Vaidyanathaswamy (Vaitheeswaran) with '
        'Thaiyalnayaki — a Navagraha (Angaraka/Mars) associated Paadal Petra '
        'temple also known for Siddhamirtham tank and nadi astrology traditions '
        'in the town.',
    story:
        'Vaitheeswaran Koil (Pullirukkuvelur) in Mayiladuthurai district is '
        'dedicated to Shiva as Vaidyanatha — the divine physician — with '
        'Goddess Thaiyalnayaki. Devotees traditionally seek relief from illness '
        'here; the Siddhamirtham temple tank and neem (sthala vriksha) are part '
        'of the healing lore, alongside shrines to Dhanvantari and Angaraka '
        '(Mars).\n\n'
        'The site is counted among the Navagraha temples of the Tamil belt for '
        'Angaraka worship and is a Paadal Petra Sthalam in Tevaram tradition. '
        'Selvamuthukumarasamy (Murugan) and other parivara shrines enrich the '
        'precinct. The surrounding town is also widely known for nadi '
        '(palm-leaf) astrology centres — a cultural adjunct distinct from the '
        'temple’s own ritual board.\n\n'
        'Architecture follows classic Tamil Dravidian prakaram planning with '
        'multiple gopurams and a large tank. Tuesdays draw heavier '
        'Angaraka-related footfall in local practice.\n\n'
        'THIN OFFICIAL ENGLISH CLOCK: a dedicated stable public HR&CE English '
        'timetable was not firmly extracted in this research pass; ordinary '
        'listings commonly cite ~06:00 AM–01:00 PM and 04:00 PM–09:00 PM '
        '(sometimes later on Sundays). Treat as provisional — confirm on-site '
        'board or HR&CE Tamil pages before travel.',
    location: 'Vaitheeswarankoil, Mayiladuthurai District, Tamil Nadu 609117',
    timings:
        'PROVISIONAL / THIN OFFICIAL ENGLISH SOURCE — confirm on-site or HR&CE '
        'Tamil board before travel. Widely repeated ordinary pattern: ~06:00 '
        'AM–01:00 PM and 04:00 PM–09:00 PM (some secondary guides extend Sunday '
        'evenings ~09:30 PM). Named niti minutes not verified from a stable '
        'official English page in this pass. Tuesdays and festival days are '
        'busier and may shift closures. Visitor tip: THIN SOURCES on full '
        'official English pooja clock — do not treat aggregator times as '
        'definitive. Oil offerings and Angaraka-related practices follow local '
        'priest guidance; keep expectations modest on queue times Tuesdays.',
    latitude: 11.195,
    longitude: 79.71417,
    specialities: [
      'Vaidyanathaswamy — Shiva as divine physician',
      'Navagraha association — Angaraka (Mars)',
      'Siddhamirtham tank and healing pilgrimage lore',
      'Paadal Petra Sthalam; Thaiyalnayaki shrine',
      'Town known for nadi astrology centres (adjacent culture)',
      'Nearest airport: Tiruchirappalli (TRZ) or Pondicherry (PNY) as region options',
      'Veg food: pilgrim-town pure-veg messes',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/tiruttani-murugan-temple/
  Temple(
    name: 'Tiruttani Murugan Temple',
    state: 'Tamil Nadu',
    city: 'Tiruttani',
    deity: 'Murugan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/Tiruttani_Murugan_temple.jpg/1280px-Tiruttani_Murugan_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/Tiruttani_Murugan_temple.jpg/1280px-Tiruttani_Murugan_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/35/Arulmigu_Subramaniya_Swami_Temple%2C_Tiruttani_2.jpg/1280px-Arulmigu_Subramaniya_Swami_Temple%2C_Tiruttani_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/65/Arulmigu_Subramaniya_Swami_Temple%2C_Tiruttani.jpg/1280px-Arulmigu_Subramaniya_Swami_Temple%2C_Tiruttani.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e2/Subramaniya_Swamy_Temple%2C_Tiruttani.jpg/1280px-Subramaniya_Swamy_Temple%2C_Tiruttani.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Thiruthani_Murugan_Temple_.jpg/1280px-Thiruthani_Murugan_Temple_.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Northernmost of Murugan’s Six Abodes — the hill shrine of '
        'Subramanyaswamy at Tiruttani, associated with peace after Surasamharam '
        'and with elephant-mount iconography shared with Swamimalai.',
    story:
        'Arulmigu Subramanyaswamy Temple at Tiruttani (Thanigai Malai) in '
        'Tiruvallur district is the northern Arupadai Veedu. Tradition holds '
        'that Murugan rested and regained calm here after the Surasamharam war; '
        'the hill remains a major Murugan pilgrimage for northern Tamil Nadu '
        'and neighbouring Andhra devotees.\n\n'
        'The hill temple is reached by a long flight of steps (and road access '
        'to higher points when open). Like Swamimalai, Tiruttani preserves '
        'elephant-mount associations in Murugan iconography. The complex is '
        'administered by TN HR&CE with online ticketing for selected services.\n\n'
        'Official pooja board markers include Viswaroopa in the early morning '
        'and a sequence through Palliyarai in the evening, with ordinary access '
        'running from morning into late evening. Festival days (Krithigai, Thai '
        'Poosam, Panguni Uthiram) intensify queues on the steps.\n\n'
        'Accessible as a day trip from Chennai for many pilgrims. Confirm '
        'current nadai and special darshan on tiruttanimurugan.hrce.tn.gov.in.',
    location: 'Malaikoil, Tiruttani, Tiruvallur District, Tamil Nadu 631209',
    timings:
        'OFFICIAL HR&CE (tiruttanimurugan.hrce.tn.gov.in / tid=1506): ordinary '
        'access commonly summarised ~06:00 AM–08:45 PM with Viswaroopa ~05:45 '
        'AM and Palliyarai ~08:45 PM; other named markers on portal include '
        'Kalasandhi ~08:00 AM, Uchikkala ~12:00 PM, Sayaraksha ~05:00 PM, '
        'Ardhajama ~06:00 PM (confirm live board — festival days override). '
        'Prefer portal over third-party apps. Visitor tip: Step climb is '
        'significant in heat — carry water and start early. Road/jeep access '
        'patterns to higher points can change; follow on-site instructions.',
    latitude: 13.1758,
    longitude: 79.6106,
    specialities: [
      'Arupadai Veedu — northernmost Murugan abode',
      'Hill shrine (Thanigai Malai) with long stepped approach',
      'Peace-after-war Murugan lore; elephant-mount link with Swamimalai',
      'Popular Chennai / northern TN day-trip pilgrimage',
      'HR&CE online ticketing for selected sevas',
      'Nearest airport: Chennai (MAA)',
      'Veg food: pilgrim messes at foothill and town',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  KERALA
  // ═══════════════════════════════════════════════════════════════════════════
  // Research-enriched visitor copy for the existing 10 Kerala temples
  // (matched by name/slug — no new documents). KAN-77 Wave A covers are
  // Commons downloaded_url thumbs (not Storage paths). Anjengo and Mannarsala
  // stay picsum (shortfall, no pack). Sources: docs/kerala-sample-research.md.
  // KAN-77: verified Commons thumbs — tools/photo-packs/guruvayur-sri-krishna-temple/
  Temple(
    name: 'Guruvayur Sri Krishna Temple',
    state: 'Kerala',
    city: 'Guruvayur',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d2/Garuda_statue_at_Guruvayur_Sri_Krishna_Temple.jpg/1280px-Garuda_statue_at_Guruvayur_Sri_Krishna_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d2/Garuda_statue_at_Guruvayur_Sri_Krishna_Temple.jpg/1280px-Garuda_statue_at_Guruvayur_Sri_Krishna_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://upload.wikimedia.org/wikipedia/commons/e/eb/Guruvayur_Sree_Krishna_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/62/009392022_Guruvayur_temple%2C_Kerala_024.jpg/1280px-009392022_Guruvayur_temple%2C_Kerala_024.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Sabarimala_pilgrims_at_Guruvayur_Temple.JPG/1280px-Sabarimala_pilgrims_at_Guruvayur_Temple.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2a/Sadhu_at_Guruvayur_Temple.JPG/1280px-Sadhu_at_Guruvayur_Temple.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/sree-padmanabhaswamy-temple/
  Temple(
    name: 'Sree Padmanabhaswamy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Sree_Padmanabhaswamy_Temple_Gopuram_Thiruvananthapuram_Kerala_India.jpg/1280px-Sree_Padmanabhaswamy_Temple_Gopuram_Thiruvananthapuram_Kerala_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Sree_Padmanabhaswamy_Temple_Gopuram_Thiruvananthapuram_Kerala_India.jpg/1280px-Sree_Padmanabhaswamy_Temple_Gopuram_Thiruvananthapuram_Kerala_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6e/Sree_Padmanabhaswamy_Temple%2C_Thiruvananthapuram.jpg/1280px-Sree_Padmanabhaswamy_Temple%2C_Thiruvananthapuram.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Sree_Padmanabhaswamy_Temple_2.jpg/1280px-Sree_Padmanabhaswamy_Temple_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/aa/Sree_Padmanabhaswamy_Temple_at_night.jpg/1280px-Sree_Padmanabhaswamy_Temple_at_night.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Sree_Padmanabhaswamy_Temple_3.jpg/1280px-Sree_Padmanabhaswamy_Temple_3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2d/Sree_Padmanabhaswamy_Temple_Lakshadeepam.jpg/1280px-Sree_Padmanabhaswamy_Temple_Lakshadeepam.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/sabarimala-ayyappan-temple/
  Temple(
    name: 'Sabarimala Ayyappan Temple',
    state: 'Kerala',
    city: 'Pathanamthitta',
    deity: 'Vishnu',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Sabarimala_5.jpg/1280px-Sabarimala_5.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Sabarimala_5.jpg/1280px-Sabarimala_5.jpg',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/05/Sabarimala.jpg/1280px-Sabarimala.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/65/Sabarimala_Garbhagudi.jpg/1280px-Sabarimala_Garbhagudi.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5e/Sabarimala_3.jpg/1280px-Sabarimala_3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Sabarimala_4.jpg/1280px-Sabarimala_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/attukal-bhagavathy-temple/
  Temple(
    name: 'Attukal Bhagavathy Temple',
    state: 'Kerala',
    city: 'Thiruvananthapuram',
    deity: 'Devi',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Attukal_Bhagavathy_temple_1.jpg/1280px-Attukal_Bhagavathy_temple_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Attukal_Bhagavathy_temple_1.jpg/1280px-Attukal_Bhagavathy_temple_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fc/Attukal_Bhagavathy_temple_2.jpg/1280px-Attukal_Bhagavathy_temple_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/61/Attukal_Bhagavathy_temple_3.jpg/1280px-Attukal_Bhagavathy_temple_3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6e/Attukal_Bhagavathy_temple_4.jpg/1280px-Attukal_Bhagavathy_temple_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a3/Attukal_Bhagavathy_temple_5.jpg/1280px-Attukal_Bhagavathy_temple_5.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ce/Attukal_Bhagavathytemple.jpg/1280px-Attukal_Bhagavathytemple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/chottanikkara-bhagavathy-temple/
  Temple(
    name: 'Chottanikkara Bhagavathy Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Devi',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ee/Chottanikkara_Temple_2024.jpg/1280px-Chottanikkara_Temple_2024.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ee/Chottanikkara_Temple_2024.jpg/1280px-Chottanikkara_Temple_2024.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5b/Chottanikkara_Bhagavathy_Temple_and_surroundings_%281%29.jpg/1280px-Chottanikkara_Bhagavathy_Temple_and_surroundings_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/49/Chottanikkara_Bhagavathy_Temple_and_surroundings_%2810%29.jpg/1280px-Chottanikkara_Bhagavathy_Temple_and_surroundings_%2810%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Chottanikkara_Bhagavathy_Temple_and_surroundings_%2811%29.jpg/1280px-Chottanikkara_Bhagavathy_Temple_and_surroundings_%2811%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d6/Chottanikkara_Bhagavathy_Temple_and_surroundings_%2812%29.jpg/1280px-Chottanikkara_Bhagavathy_Temple_and_surroundings_%2812%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3b/Chottanikkara_Bhagavathy_Temple_and_surroundings_%2813%29.jpg/1280px-Chottanikkara_Bhagavathy_Temple_and_surroundings_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/ernakulathappan-temple/
  Temple(
    name: 'Ernakulathappan Temple',
    state: 'Kerala',
    city: 'Ernakulam',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c6/Ernakulathappan_temple1.jpg/1280px-Ernakulathappan_temple1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c6/Ernakulathappan_temple1.jpg/1280px-Ernakulathappan_temple1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/96/Ernakulathappan_temple2.jpg/1280px-Ernakulathappan_temple2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/eb/Ernakulathappan_temple3.jpg/1280px-Ernakulathappan_temple3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/13/Ernakulathappan_temple4.jpg/1280px-Ernakulathappan_temple4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4f/Ernakulathappan_temple5.jpg/1280px-Ernakulathappan_temple5.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/Ernakulathappan_temple8.jpg/1280px-Ernakulathappan_temple8.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/vaikom-mahadeva-temple/
  Temple(
    name: 'Vaikom Mahadeva Temple',
    state: 'Kerala',
    city: 'Kottayam',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Vaikom_Mahadeva_Temple%2C_Kottayam%2C_Kerala_state%2C_India.jpg/1280px-Vaikom_Mahadeva_Temple%2C_Kottayam%2C_Kerala_state%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Vaikom_Mahadeva_Temple%2C_Kottayam%2C_Kerala_state%2C_India.jpg/1280px-Vaikom_Mahadeva_Temple%2C_Kottayam%2C_Kerala_state%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/21/009262022_Vaikom_Mahadeva_temple_aerial_view%2C_Kottayam_Kerala_012.jpg/1280px-009262022_Vaikom_Mahadeva_temple_aerial_view%2C_Kottayam_Kerala_012.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/54/Pambady_Rajan_carrying_Idol_of_vaikom_mahadeva_temple.jpg/1280px-Pambady_Rajan_carrying_Idol_of_vaikom_mahadeva_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/Vaikom_Mahadeva_Temple_entrance.jpg/1280px-Vaikom_Mahadeva_Temple_entrance.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/Vaikom_Mahadeva_Temple-_Front_view.jpg/1280px-Vaikom_Mahadeva_Temple-_Front_view.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/15/Vaikom_Mahadeva_Temple-_an_evening_view.jpg/1280px-Vaikom_Mahadeva_Temple-_an_evening_view.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
  // KAN-77: verified Commons thumbs — tools/photo-packs/thirunelli-maha-vishnu-temple/
  Temple(
    name: 'Thirunelli Maha Vishnu Temple',
    state: 'Kerala',
    city: 'Wayanad',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Thirunelli_Maha_Vishnu_temple_in_Wayanad_region_Kerala_India.jpg/1280px-Thirunelli_Maha_Vishnu_temple_in_Wayanad_region_Kerala_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/34/Thirunelli_Maha_Vishnu_temple_in_Wayanad_region_Kerala_India.jpg/1280px-Thirunelli_Maha_Vishnu_temple_in_Wayanad_region_Kerala_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2a/Thirunelli_Maha_Vishnu_Temple.JPG/1280px-Thirunelli_Maha_Vishnu_Temple.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a7/A_Namaste_relief_at_Thirunelli_Maha_Vishnu_temple_Kerala_India.jpg/1280px-A_Namaste_relief_at_Thirunelli_Maha_Vishnu_temple_Kerala_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3f/Nadini_and_other_icons_near_Shiva_shrine_at_Maha_Vishnu_Thirunelli_temple.jpg/1280px-Nadini_and_other_icons_near_Shiva_shrine_at_Maha_Vishnu_Thirunelli_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Thirunelli_Maha_Vishnu_temple_walkway_and_parking_lot.jpg/1280px-Thirunelli_Maha_Vishnu_temple_walkway_and_parking_lot.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/53/Thirunelli_Maha_Vishnu_temple_water_tank_square_and_circle_icons.jpg/1280px-Thirunelli_Maha_Vishnu_temple_water_tank_square_and_circle_icons.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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

  // ── KAN-64 / KAN-74 expansion batch 17 — +10 additional Kerala temples
  // Core Temple fields only (Hybrid C): trip_planning stripped / not seeded.
  // KAN-77 Wave A fills Commons thumbs for these ten. No Storage URLs.
  // KAN-77: verified Commons thumbs — tools/photo-packs/vadakkunnathan-temple/
  Temple(
    name: 'Vadakkunnathan Temple',
    state: 'Kerala',
    city: 'Thrissur',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/ff/Vadakkunnathan_Temple_Trichur_Keral_India1.jpg/1280px-Vadakkunnathan_Temple_Trichur_Keral_India1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/ff/Vadakkunnathan_Temple_Trichur_Keral_India1.jpg/1280px-Vadakkunnathan_Temple_Trichur_Keral_India1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/13/Vadakkunnathan_Temple_Thrissur_BN3Q3984.jpg/1280px-Vadakkunnathan_Temple_Thrissur_BN3Q3984.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/Grand_Onam_Pookkalam_in_front_of_Vadakkunnathan_Temple%2C_Thrissur.jpg/1280px-Grand_Onam_Pookkalam_in_front_of_Vadakkunnathan_Temple%2C_Thrissur.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c5/Vadakkunnathan_Temple%2C_Thrissur.jpg/1280px-Vadakkunnathan_Temple%2C_Thrissur.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/Vadakkunnathan_Temple_Trichur_Keral_India2.jpg/1280px-Vadakkunnathan_Temple_Trichur_Keral_India2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/23/Sri_Vadakkunnathan_Temple%2C_Thrissur_-_%E0%B4%B6%E0%B5%8D%E0%B4%B0%E0%B5%80_%E0%B4%B5%E0%B4%9F%E0%B4%95%E0%B5%8D%E0%B4%95%E0%B5%81%E0%B4%A8%E0%B4%BE%E0%B4%A5%E0%B5%BB_%E0%B4%95%E0%B5%8D%E0%B4%B7%E0%B5%87%E0%B4%A4%E0%B5%8D%E0%B4%B0%E0%B4%82%2C_%E0%B4%A4%E0%B5%83%E0%B4%B6%E0%B5%82%E0%B5%BC_01.jpg/1280px-Sri_Vadakkunnathan_Temple%2C_Thrissur_-_%E0%B4%B6%E0%B5%8D%E0%B4%B0%E0%B5%80_%E0%B4%B5%E0%B4%9F%E0%B4%95%E0%B5%8D%E0%B4%95%E0%B5%81%E0%B4%A8%E0%B4%BE%E0%B4%A5%E0%B5%BB_%E0%B4%95%E0%B5%8D%E0%B4%B7%E0%B5%87%E0%B4%A4%E0%B5%8D%E0%B4%B0%E0%B4%82%2C_%E0%B4%A4%E0%B5%83%E0%B4%B6%E0%B5%82%E0%B5%BC_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Ancient circular-plan Shiva temple at the heart of Thrissur’s '
        'Thekkinkadu Maidan, celebrated for Kerala murals, multi-shrine layout, '
        'and as the sacred centrepiece of the world-famous Thrissur Pooram.',
    story:
        'Vadakkunnathan (Vadakkumnathan) Temple sits inside the Thekkinkadu '
        'Maidan in the civic and ritual centre of Thrissur. Temple tradition '
        'links its founding to Parasurama; historically it is among Kerala’s '
        'oldest living Shaiva complexes and an Archaeological Survey of '
        'India–protected monument. The sprawling wood-and-laterite Kerala '
        'precinct is known for circular vimanas, multi-storeyed gopurams, and '
        'celebrated murals depicting Mahabharata and Shaiva themes.\n\n'
        'The main west-facing shrine houses Shiva as Vadakkunnathan; the '
        'complex also includes important shrines traditionally associated with '
        'Rama and Harihara/Sankaranarayana, plus Ganapathi and Devi shrines. A '
        'distinctive local custom is an anti-clockwise (apradakshina) circuit '
        'for some devotee paths — unusual among Hindu temples and widely noted '
        'by visitors.\n\n'
        'Daily worship centres on abhishekam with ghee (neyyattam) that has, '
        'over centuries, built a mound over the linga; scrapings of this ghee '
        'prasadam are prized by devotees. Named markers on the temple’s own '
        'daily-pooja page include morning Neyyatam/Usha/Ucha and evening '
        'Deeparadhana, Athazha Pooja, and Trippuka before close.\n\n'
        'Thrissur Pooram (Medam / April–May) — often called the mother of '
        'Kerala Poorams — unfolds around the maidan with rival gopuram '
        'processions, percussion (panchavadyam/pandimelam), and firework '
        'displays, though the deity itself does not leave the sanctum in the '
        'same way as many festival temples. Maha Shivaratri is the other major '
        'draw. Entry is typically restricted to Hindus; traditional Kerala '
        'dress is enforced.',
    location: 'Thekkinkadu Maidan, Thrissur, Kerala 680001',
    timings:
        'Official-aligned board (sreewadakkunathantemple.org/daily_pooja; '
        'confirm before travel): morning open 4:00 AM; Neyyatam ~4:15 AM; Usha '
        'Pooja 6:00–6:30 AM; Ucha Pooja 10:00–10:45 AM; morning close 11:00 AM '
        'weekdays / ~11:30 AM Sat–Sun & holidays. Evening open 5:00 PM; '
        'Deeparadhana ~6:15 PM; Athazha Pooja 7:00–7:45 PM; Trippuka 8:00–8:20 '
        'PM; close 8:30 PM. Secondary tourism pages sometimes list 4:00–10:00 '
        'AM morning envelopes — prefer the temple pooja page. Festival days '
        '(esp. Thrissur Pooram, Shivaratri) override. Visitor tip: Hindu-only '
        'entry commonly enforced; men typically mundu with bare upper body '
        'inside, women saree/churidar with dupatta — confirm live board. '
        'Children under one often restricted per secondary notices.',
    latitude: 10.5245,
    longitude: 76.2144,
    specialities: [
      'Thrissur Pooram centrepiece on Thekkinkadu Maidan',
      'Circular Kerala vimanas; ASI-protected complex',
      'Historic murals; multi-shrine Shaiva–Vaishnava layout',
      'Ghee abhishekam (neyyattam) prasadam tradition',
      'Unusual anti-clockwise devotee circuit noted locally',
      'Nearest airport: COK (Cochin International); Thrissur Junction railhead',
      'Veg/pilgrim food plentiful in Thrissur temple-town belt',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/sree-poornathrayeesa-temple/
  Temple(
    name: 'Sree Poornathrayeesa Temple',
    state: 'Kerala',
    city: 'Tripunithura',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Pampadi_Rajan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg/1280px-Pampadi_Rajan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Pampadi_Rajan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg/1280px-Pampadi_Rajan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/Thiruvambadi_Chandrasekharan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg/1280px-Thiruvambadi_Chandrasekharan_at_Sree_Poornathrayeesa_Temple_Thrippunithura.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://upload.wikimedia.org/wikipedia/commons/3/3f/Sree_Poornathrayeesa_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/38/Sree_Poornathrayesa_Temple%2C_Tripunithura%2C_Kochi%2C_India_-_20080427.jpg/1280px-Sree_Poornathrayesa_Temple%2C_Tripunithura%2C_Kochi%2C_India_-_20080427.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d7/Thrippunithara%40Temple.jpg/1280px-Thrippunithara%40Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/61/Thrippunithura-Elephant-Entering-Temple-1_crop.jpg/1280px-Thrippunithura-Elephant-Entering-Temple-1_crop.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Royal Cochin Vishnu temple at Tripunithura where Poornathrayeesa is '
        'worshipped as Santhanagopala Murthy — famed for elephant-rich '
        'Vrischikotsavam and blessings sought by childless couples.',
    story:
        'Sree Poornathrayeesa Temple in Thrippunithura (Tripunithura), about 10 '
        'km southeast of Ernakulam, was the foremost of the eight royal temples '
        'of the former Kingdom of Cochin and the family deity of the Cochin '
        'dynasty. Vishnu is worshipped here as Poornathrayeesa / Santhanagopala '
        'Murthy — traditionally the ‘saviour of infants’ — seated under the '
        'five hoods of Ananta, a posture uncommon among Kerala Vishnu shrines '
        'that more often show reclining Ananthashayana forms.\n\n'
        'Temple legend holds that Vishnu gave the idol to Arjuna, who installed '
        'it after recovering a Brahmin’s children; Ganapathi’s south-facing '
        'placement beside the sanctum is explained in the same narrative. A '
        'major fire in 1920 destroyed much of the wooden sanctum; the rebuilt '
        'concrete-faced srikovil (often cited as among Kerala’s first concrete '
        'temple structures) was designed with copper, wood, and granite '
        'detailing still visible today.\n\n'
        'The eight-day Vrischikotsavam (Vrischikam / November–December) opens '
        'Kerala’s festival season for many locals and is known for large '
        'elephant processions, melam, Kathakali, and music. Other observances '
        'include Ambalam Kathi Utsavam (Thulam), Mooshari Utsavam, and '
        'Uthram-related celebrations. Cochin Devaswom Board administers the '
        'temple; photography inside is typically prohibited.',
    location: 'Thrippunithura, Ernakulam, Kerala 682301',
    timings:
        'Commonly listed public envelope (secondary compilations + '
        'temple-associated pages; confirm on sreepoornathrayeesatemple.org / '
        'Cochin Devaswom board before travel): morning ~4:00 AM–11:15 AM; '
        'evening ~4:00 PM–8:15 PM. Named markers often cited: Palliunarthal '
        '~3:45 AM; Usha Pooja ~5:00 AM; Kalabha Abhishekam ~6:00–6:30 AM; '
        'Pantheeradi ~7:30 AM; Ucha Pooja ~11:00 AM; evening Deeparadhana '
        '~6:00–6:30 PM; Athazha Pooja ~7:30 PM; Athazha Seeveli ~8:00 PM. '
        'Festival days (Vrischikotsavam) extend and crowd-control override — '
        'treat minute slots as approximate. Visitor tip: Traditional Kerala '
        'dress expected; photography usually banned inside. Elephant-festival '
        'crowd and safety rules have been under Kerala High Court scrutiny — '
        'follow current Devaswom advisories.',
    latitude: 9.945,
    longitude: 76.3422,
    specialities: [
      'Santhanagopala Murthy — child-blessing Vaishnava focus',
      'Former royal temple of Cochin kingdom',
      'Vrischikotsavam elephant processions (Nov–Dec)',
      'Unique seated Vishnu under Ananta’s hoods',
      'Ambalam Kathi and Mooshari festival traditions',
      'Nearest airport: COK; Ernakulam / Tripunithura rail access',
      'Veg hotels common around Tripunithura temple street',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/ambalappuzha-sri-krishna-temple/
  Temple(
    name: 'Ambalappuzha Sri Krishna Temple',
    state: 'Kerala',
    city: 'Ambalappuzha',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Ambalappuzha_Sree_Krishna_Temple_07.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_07.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Ambalappuzha_Sree_Krishna_Temple_07.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_07.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/80/Ambalappuzha_Sree_Krishna_Temple_08.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_08.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7a/Ambalappuzha_Sree_Krishna_Temple_17.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_17.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/14/Ambalappuzha_Sree_Krishna_Temple_Ficus_religiosa.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_Ficus_religiosa.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2b/Ambalappuzha_Sree_Krishna_Temple_Pond.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_Pond.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e5/Ambalappuzha_Sree_Krishna_Temple_Pond_iide_view.jpg/1280px-Ambalappuzha_Sree_Krishna_Temple_Pond_iide_view.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Historic Alappuzha Krishna (Parthasarathy) temple renowned statewide '
        'for its daily Palpayasam milk-payasam offering and classical Kerala '
        'architecture beside a temple tank.',
    story:
        'Ambalappuzha Sree Krishna Swamy Temple in Alappuzha district is one of '
        'Travancore’s great Vaishnava shrines, dedicated to Krishna in '
        'Parthasarathy form. Tradition and local histories place major building '
        'phases between the 15th and 17th centuries under Chembakassery rulers, '
        'atop an older sacred site. The Kerala-style complex includes murals, '
        'Dasavatara themes, and a tank-side setting familiar from pilgrim '
        'photographs.\n\n'
        'The temple’s fame rests on Ambalappuzha Palpayasam — a sweet '
        'rice-and-milk payasam offered daily as naivedyam. Legend recounts '
        'Krishna, disguised as a sage, defeating a local king at chess and '
        'securing an unending debt repaid as this perpetual offering; devotees '
        'also hold that Guruvayurappan partakes of the payasam. During Tipu-era '
        'turmoil, the Guruvayur idol was traditionally sheltered here for a '
        'period — a memory that still links the two temples in popular '
        'devotion.\n\n'
        'Poet Kunchan Nambiar is associated with the birth of Ottamthullal '
        'performance traditions in this cultural landscape. Daily schedule '
        'centres on early Nirmalya through Ucha Pooja, with evening '
        'Deeparadhana and Athazha Pooja. Palpayasam is typically collected near '
        'midday at the prasadam counter; as of recent pilgrim notices there is '
        'no reliable public online booking — queue on site.',
    location: 'Ambalappuzha, Alappuzha, Kerala 688561',
    timings:
        'Widely listed public envelope (secondary pilgrim guides; thin single '
        'official English clock — confirm locally / Travancore Devaswom '
        'channels): morning ~3:00 AM–12:00/12:30 PM; evening ~5:00 PM–8:00 PM '
        '(some lists close ~7:45 PM). Named markers commonly cited: Nirmalya '
        '~3:00–3:30 AM; Usha Pooja ~7:00–7:30 AM; Ucha Pooja ~11:30 AM–12:00 '
        'PM; Deeparadhana ~6:30–7:00 PM; Athazha Pooja ~7:30–8:00 PM. '
        'Palpayasam distribution often ~12:00–1:00 PM at prasadam counter — '
        'arrive earlier on weekends. Festival days override. Visitor tip: '
        'Traditional dress expected. Palpayasam: offline counter only per 2026 '
        'pilgrim notices — no invented online booking claims. Thin official '
        'English timetable — re-check Devaswom/local board.',
    latitude: 9.383,
    longitude: 76.37,
    specialities: [
      'Famous daily Ambalappuzha Palpayasam prasadam',
      'Parthasarathy Krishna; Dasavatara mural traditions',
      'Historic link with Guruvayur idol refuge lore',
      'Ottamthullal cultural association (Kunchan Nambiar)',
      'Tank-side Kerala temple architecture',
      'Nearest airport: COK; Ambalappuzha / Alappuzha rail access',
      'Plan midday if collecting Palpayasam (queue)',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/ettumanoor-mahadeva-temple/
  Temple(
    name: 'Ettumanoor Mahadeva Temple',
    state: 'Kerala',
    city: 'Ettumanoor',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_005.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_005.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_005.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_005.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3c/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_010.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_010.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b4/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_017.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_017.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_028.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_028.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2c/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_051.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_051.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/49/009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_058.jpg/1280px-009242022_Ettumanoor_Mahadeva_temple%2C_Kottayam_Kerala_058.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Major Travancore Devaswom Shiva temple in Kottayam district, famed for '
        'its Pradosha Nritham mural, golden Ezharaponnana elephants, and '
        'ten-day Kumbham arattu festival.',
    story:
        'Ettumanoor Mahadeva Temple is one of central Kerala’s foremost Shaiva '
        'pilgrimages, administered by the Travancore Devaswom Board. The '
        'east-facing Kerala complex is celebrated for mural painting — '
        'especially the dynamic Pradosha Nritham (Nataraja) composition at the '
        'entrance/gopuram zone — and for rich woodwork and metalwork '
        'traditions.\n\n'
        'Legend associates worship here with the Pandavas and sage Vyasa. The '
        'annual ten-day festival in Kumbham (February–March) culminates in '
        'arattu on Thiruvathira; its iconic midnight Ezharaponnana Darshanam on '
        'the eighth night displays seven-and-a-half golden elephant figures '
        '(jackfruit-wood cores clad in gold plate, traditionally linked to '
        'offerings by Travancore’s Marthanda Varma). Caparisoned live elephants '
        'and panchari melam accompany processions.\n\n'
        'The temple’s own puja page lists a full morning-to-evening rhythm from '
        'Nirmalyam through Athazha Sreebali. Thulabharam and other vazhipadu '
        'remain popular. Dress and entry follow typical Kerala Devaswom norms.',
    location: 'Ettumanoor PO, Kottayam, Kerala 686631',
    timings:
        'Temple-associated puja board (ettumanoormahadevatemple.com/puja; '
        'confirm before travel): Morning — Nirmalyam 4:00 AM; Abhishekam ~4:20 '
        'AM; Madhava Pallipooja ~5:45 AM; Ethirthu Pooja ~6:15 AM; Sreebali '
        '~6:45 AM; Dhaara/Kalasham ~10:30 AM; Uchapooja ~11:15 AM; Ucha '
        'Sreebali ~11:45 AM. Evening — open 5:00 PM; Deeparadhana ~6:20 PM; '
        'Athazha Pooja ~7:15 PM; Athazha Sreebali ~7:45 PM. Public visitor '
        'envelopes of 4:00 AM–12:00 PM and 5:00–8:30 PM appear in secondary '
        'listings and roughly match. Festival nights (Ezharaponnana) run to '
        'midnight+. Visitor tip: Contact on temple site includes '
        'ettumanoordevaswom@gmail.com — useful for festival-night crowd '
        'planning. Confirm Ezharaponnana midnight opening annually.',
    latitude: 9.67,
    longitude: 76.56,
    specialities: [
      'Ezharaponnana — seven-and-a-half golden elephants (Kumbham festival)',
      'Acclaimed Pradosha Nritham / Nataraja mural',
      'Travancore Devaswom Board major Shiva shrine',
      'Ten-day arattu festival ending on Thiruvathira',
      'Thulabharam and classical Kerala vazhipadu',
      'Nearest airport: COK; Ettumanoor / Kottayam rail',
      'Veg pilgrim eateries around Ettumanoor junction',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/chettikulangara-devi-temple/
  Temple(
    name: 'Chettikulangara Devi Temple',
    state: 'Kerala',
    city: 'Chettikulangara',
    deity: 'Devi',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7a/Kettukazhcha_at_Chettikulangara_Devi_temple.jpg/1280px-Kettukazhcha_at_Chettikulangara_Devi_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7a/Kettukazhcha_at_Chettikulangara_Devi_temple.jpg/1280px-Kettukazhcha_at_Chettikulangara_Devi_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/07/CHETTIKULANGARA_TEMPLE.jpg/1280px-CHETTIKULANGARA_TEMPLE.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bc/Chettikulangara_Kettukazcha_panorama.jpg/1280px-Chettikulangara_Kettukazcha_panorama.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4d/Chettikulangara_kumbha_bharani_captured_in_realme_15pro.jpg/1280px-Chettikulangara_kumbha_bharani_captured_in_realme_15pro.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/73/Kuthira.JPG/1280px-Kuthira.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f5/Theru.JPG/1280px-Theru.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Prominent Bhadrakali temple near Mavelikkara, famous across central '
        'Travancore for Kumbha Bharani’s towering Kettukazhcha effigies and '
        'Kuthiyottam ritual offerings.',
    story:
        'Chettikulangara Sree Bhagavathy Temple near Mavelikkara (Alappuzha '
        'district) enshrines Bhadrakali with strong local identity as '
        'Chettikulangara Amma. Origin lore ties the shrine to devotees who '
        'sought Kodungallur Bhagavathi’s grace after a slight at another temple '
        'and established worship when the goddess was believed to arrive in the '
        'village.\n\n'
        'The temple’s defining public culture is Kumbha Bharani (Kumbham / '
        'February–March), sometimes called the Kumbhamela of the South. '
        'Kuthiyottam — a ritual dance offering traditionally performed by boys '
        'after days of preparation — and Kettukazhcha — towering decorated '
        'wooden horse (kuthira) and chariot (theru) effigies hauled into the '
        'eastern fields — draw lakhs of visitors. Devi is carried in night '
        'procession to the lined-up effigies.\n\n'
        'Daily worship follows a classic Devi schedule (Nirmalyam through '
        'Athazha). Secondary sources note form-varied emphasis across the day '
        '(Saraswati/Lakshmi/Durga–Kali moods in popular telling). Official '
        'festival narrative is well documented on chettikulangara.org; '
        'ordinary-day English clocks remain thinner and should be re-checked on '
        'the live board.',
    location: 'Chettikulangara, Mavelikkara, Alappuzha, Kerala 690106',
    timings:
        'Provisional public envelope (secondary compilations / apps; thin '
        'single official English clock — confirm chettikulangara.org or on-site '
        'board): ~5:00 AM–12:00/12:30 PM and ~5:00 PM–8:00 PM. Named markers '
        'often listed: Nirmalyam ~5:00 AM; Ganapathy Homam ~6:00 AM; Usha Pooja '
        '~6:30 AM; Ucha Pooja ~12:00 PM; Deeparadhana ~6:30 PM; Bhagavathy Seva '
        '~7:00 PM; Athazha ~7:30 PM. Kumbha Bharani festival days fully '
        'override — expect all-day crowds and night Kettukazhcha. Visitor tip: '
        'THIN OFFICIAL CLOCK for ordinary days — timings labelled provisional. '
        'Photo coverage on Commons is festival-kuthira heavy rather than main '
        'gopuram exteriors.',
    latitude: 9.227,
    longitude: 76.515,
    specialities: [
      'Kumbha Bharani Kettukazhcha giant horse/chariot effigies',
      'Kuthiyottam ritual dance offering',
      'Bhadrakali / Chettikulangara Amma pilgrimage',
      'Central Travancore Devi circuit landmark',
      'Official festival pages on chettikulangara.org',
      'Nearest airport: COK; Kayamkulam / Mavelikkara rail',
      'Book lodging early for Bharani week',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/kodungallur-bhagavathy-temple/
  Temple(
    name: 'Kodungallur Bhagavathy Temple',
    state: 'Kerala',
    city: 'Kodungallur',
    deity: 'Devi',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8b/Kodungallur_Bhagavathy_Temple_02.jpg/1280px-Kodungallur_Bhagavathy_Temple_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8b/Kodungallur_Bhagavathy_Temple_02.jpg/1280px-Kodungallur_Bhagavathy_Temple_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/Kodungallur_Bhagavathy_Temple_03.jpg/1280px-Kodungallur_Bhagavathy_Temple_03.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/22/Kodungallur_Bhagavathy_Temple_03_bnr.png/1280px-Kodungallur_Bhagavathy_Temple_03_bnr.png?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9d/Kodungallur_Bhagavathy_Temple_04.jpg/1280px-Kodungallur_Bhagavathy_Temple_04.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d4/Kodungallur_Bhagavathy_Temple_05.jpg/1280px-Kodungallur_Bhagavathy_Temple_05.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/92/Kodungallur_Bhagavathy_Temple_06.jpg/1280px-Kodungallur_Bhagavathy_Temple_06.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Ancient Sree Kurumba Bhagavathy (Bhadrakali) temple of the Chera '
        'Mahodayapuram landscape, renowned for the intense Kodungallur Bharani '
        'festival and Kannagi–Bhadrakali cultural memory.',
    story:
        'Kodungallur Sree Kurumba Bhagavathy Temple (Bhagavathy Kavu) is among '
        'Kerala’s most powerful Devi pilgrimages, rooted in the historic Chera '
        'capital region of Mahodayapuram / Kodungallur. The principal deity is '
        'Bhadrakali (Kurumba), with a complex layered through centuries of '
        'rebuilding atop early medieval foundations; scholarship also notes '
        'Saptamatrika / Chamunda associations in the wider sacred landscape.\n\n'
        'Popular and literary memory links the goddess to Kannagi of the Tamil '
        'epic Silappatikaram, whose righteous wrath is mapped onto Bhadrakali’s '
        'fierce grace. The annual Kodungallur Bharani (Meenam / March–April) — '
        'including Kaavutheendal and related rites — is among Kerala’s most '
        'intense festival cycles, drawing huge crowds and distinctive '
        'vernacular ritual expression that visitors should approach with '
        'cultural respect rather than spectacle-seeking.\n\n'
        'Ordinary-day worship follows morning and evening Kerala Devi rhythms. '
        'Tourism and secondary pages commonly list ~4:00 AM–12:00 PM and '
        '~4:00–8:00/8:30 PM envelopes, with Sunday/Tuesday/Friday morning '
        'extensions in some compilations — treat as provisional pending the '
        'live board.',
    location: 'Kodungallur, Thrissur, Kerala 680664',
    timings:
        'Provisional public envelope (Kerala Tourism event pages + secondary '
        'guides; thin single official English daily clock — confirm on site): '
        'morning ~4:00 AM–12:00 PM (some lists to 12:30 PM on Sun/Tue/Fri); '
        'evening ~4:00 PM–8:00/8:30 PM. Bharani festival period massively '
        'overrides ordinary hours and access patterns — follow police/Devaswom '
        'crowd control. Named pooja minutes are not stably published in English '
        '— do not invent. Visitor tip: THIN official English ordinary-day '
        'clock. Bharani is culturally intense — follow local advisories; not a '
        'casual photo-tourism event. Photo candidate is verified Commons temple '
        'exterior (Ms Sarah Welch CC0).',
    latitude: 10.227,
    longitude: 76.199,
    specialities: [
      'Sree Kurumba Bhadrakali of historic Kodungallur',
      'Kodungallur Bharani / Kaavutheendal festival cycle',
      'Chera Mahodayapuram sacred landscape',
      'Kannagi–Bhadrakali cultural association',
      'Major central-Kerala Devi pilgrimage',
      'Nearest airport: COK; Irinjalakuda / Chalakudy rail options',
      'Respectful conduct essential during Bharani',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/parassinikadavu-muthappan-temple/
  Temple(
    name: 'Parassinikadavu Muthappan Temple',
    state: 'Kerala',
    city: 'Parassinikadavu',
    deity: 'Muthappan',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c2/Parassinikadavu_Sri_Muthappan_Temple.png/1280px-Parassinikadavu_Sri_Muthappan_Temple.png?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c2/Parassinikadavu_Sri_Muthappan_Temple.png/1280px-Parassinikadavu_Sri_Muthappan_Temple.png?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/17/Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072159.jpg/1280px-Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072159.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7f/Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072221.jpg/1280px-Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072221.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d0/Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072231.jpg/1280px-Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072231.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/41/Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072245.jpg/1280px-Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072245.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072251.jpg/1280px-Parassini_Madappura_Sree_Muthappan_Parassinikadavu_2026_0224_072251.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'North Malabar riverside madappura where Sree Muthappan is worshipped '
        'through daily Theyyam enactments (Thiruvappana and Vellattam), with '
        'distinctive non-sattvic offerings and open social devotion.',
    story:
        'Parassinikadavu Sree Muthappan Temple (Parassini Madappura) stands on '
        'the banks of the Valapattanam river near Kannur. The lived deity is '
        'Sree Muthappan — popularly understood as a unified or paired '
        'manifestation associated with Vishnu (Thiruvappana / Valiya Muthappan) '
        'and Shiva (Vellattam / Cheriya Muthappan) — encountered not primarily '
        'as a silent sanctum murti but through Theyyam ritual performance.\n\n'
        'Daily morning Thiruvappana and Vellattam (commonly ~5:45–8:00 AM) and '
        'evening Vellattam (~6:30 PM) form the heart of worship. Offerings '
        'historically include toddy and fish alongside vegetarian items — a '
        'deliberate contrast with sattvic Brahminical temple norms elsewhere in '
        'Kerala — and the shrine is widely noted for welcoming devotees across '
        'community lines. Free meals are part of the madappura’s social ethos '
        'in many visitor accounts.\n\n'
        'Ritual calendar notes: Theyyam performances are generally paused from '
        'Thulam 1 to Vrischikam 15 (mid-October to mid-November); Puthari '
        'Thiruvappana around Vrischikam 16 reopens the cycle; Muthappan '
        'Thiruvoppana Mahotsavam falls in Kumbham. Treat performance clocks as '
        'living tradition subject to local announcement.',
    location: 'Parassinikadavu, Kannur, Kerala 670563',
    timings:
        'Widely reported ritual windows (pilgrim guides / compilations; confirm '
        'locally — no single stable English Trust clock found): morning '
        'Thiruvappana & Vellattam ~5:45 AM–8:00 AM; evening Vellattam ~6:30 PM. '
        'General madappura access often described from early morning into '
        'evening (~5:00 AM–8:00 PM in secondary lists). IMPORTANT seasonal '
        'pause: Theyyam typically not performed Thulam 1–Vrischikam 15 (approx. '
        'mid-Oct to mid-Nov). Festival days in Kumbham override. Visitor tip: '
        'Accurate deity label is Muthappan (not simply Shiva or Vishnu alone). '
        'Theyyam pause mid-Oct–mid-Nov is critical trip planning. Photography '
        'rules during performance vary — ask locally.',
    latitude: 11.982,
    longitude: 75.395,
    specialities: [
      'Daily Muthappan Theyyam — Thiruvappana & Vellattam',
      'Deity string: Muthappan (Shiva–Vishnu Theyyam identity)',
      'Non-sattvic offering tradition (toddy/fish lore) with broad social access',
      'Valapattanam riverbank madappura setting',
      'Puthari Thiruvappana & Kumbham Mahotsavam cycle',
      'Nearest airport: CNN (Kannur International)',
      'Arrive before 5:45 AM for morning Theyyam',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/thiruvalla-sreevallabha-temple/
  Temple(
    name: 'Thiruvalla Sreevallabha Temple',
    state: 'Kerala',
    city: 'Thiruvalla',
    deity: 'Vishnu',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Sreevallabha_temple%2C_thiruvalla.JPG/1280px-Sreevallabha_temple%2C_thiruvalla.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Sreevallabha_temple%2C_thiruvalla.JPG/1280px-Sreevallabha_temple%2C_thiruvalla.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Kadhakali_-_Sreevallabha_Temple%2C_Thiruvalla.jpg/1280px-Kadhakali_-_Sreevallabha_Temple%2C_Thiruvalla.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2f/Lakshmi_vilakku_sreevallabha_temple%2C_thiruvalla.JPG/1280px-Lakshmi_vilakku_sreevallabha_temple%2C_thiruvalla.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Nammalvar_phalakam_at_sreevallabha_temple%2C_thiruvalla.JPG/1280px-Nammalvar_phalakam_at_sreevallabha_temple%2C_thiruvalla.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7b/Shangh_sreevallabha_temple%2C_thiruvalla.JPG/1280px-Shangh_sreevallabha_temple%2C_thiruvalla.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/45/009242022_Shri_Vallabha_temple%2C_Thiruvalla_Kerala_004.jpg/1280px-009242022_Shri_Vallabha_temple%2C_Thiruvalla_Kerala_004.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'One of the 108 Divya Desams — Sreevallabha (Kolapira Perumal) at '
        'Thiruvalla — noted for a towering granite Garuda pillar, '
        'Kathakali-linked worship traditions, and a vast historic prakara.',
    story:
        'Sreevallabha Temple in Thiruvalla (Pathanamthitta) is a celebrated Sri '
        'Vaishnava Divya Desam where Vishnu is worshipped as Sreevallabha / '
        'Kolapira Perumal. The fortified complex preserves layers of Ay, Chera, '
        'and Travancore-period patronage; inscriptions speak to an earlier '
        'landscape that included Vedic learning and performance sponsorship.\n\n'
        'Architecturally the site is striking for high prakara walls, four '
        'gopuram gateways, and a granite Garuda-madam often cited around 50+ '
        'feet — among the tallest of its kind in the region. Subsidiary shrines '
        'and a classical daily pancharatra-influenced rhythm structure worship. '
        'A distinctive living tradition links Kathakali performance with temple '
        'ritual calendar — unique among many Kerala Vishnu temples.\n\n'
        'Pilgrim guides commonly list morning and evening darshan envelopes '
        'with five principal poojas from Palli Unarthal/Nirmalyam through '
        'Athazha. As a Divya Desam it draws Tamil and Malayalam Srivaishnava '
        'circuits alongside local devotees.',
    location: 'Thiruvalla, Pathanamthitta, Kerala 689101',
    timings:
        'Commonly listed public envelope (secondary Divya Desam / pilgrim '
        'guides; confirm Travancore Devaswom / local board): ~4:30 AM–11:30 AM '
        'and ~5:00 PM–8:00 PM. Named markers often cited: Palli Unarthal ~4:00 '
        'AM; Nirmalyam ~4:30 AM; Usha Pooja ~6:00–7:00 AM; Pantheeradi '
        '~8:00–9:00 AM; Ucha Pooja ~10:30–11:00 AM; Athazha ~7:30–8:00 PM. '
        'Festival days and Kathakali-puja nights may extend — treat minutes as '
        'approximate. Visitor tip: Dress code typical of Kerala Vishnu temples; '
        'ask before photographing inside. Kathakali–puja calendar is seasonal — '
        'check local notice boards.',
    latitude: 9.3735,
    longitude: 76.5626,
    specialities: [
      '108 Divya Desam — Sreevallabha / Kolapira Perumal',
      'Towering granite Garuda-madam',
      'Kathakali associated with temple worship tradition',
      'High prakara walls and classical Kerala–Dravida mix',
      'Pancharatra-linked daily ritual rhythm',
      'Nearest airport: COK; Thiruvalla railway station',
      'Veg hotels plentiful in Thiruvalla town',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/chengannur-mahadeva-temple/
  Temple(
    name: 'Chengannur Mahadeva Temple',
    state: 'Kerala',
    city: 'Chengannur',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3e/Chengannur_Mahadeva_Temple_2022_September.jpg/1280px-Chengannur_Mahadeva_Temple_2022_September.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3e/Chengannur_Mahadeva_Temple_2022_September.jpg/1280px-Chengannur_Mahadeva_Temple_2022_September.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b7/009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_156.jpg/1280px-009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_156.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f7/009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_002.jpg/1280px-009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_002.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a9/009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_009.jpg/1280px-009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_009.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ab/009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_024.jpg/1280px-009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_024.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0c/009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_036.jpg/1280px-009232022_Thiru_Chengannur_Mahadeva_Temple_Kerala_036.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Ancient Pamba-side Shiva–Bhagavathy complex with a circular Kerala '
        'vimana, dual sanctums, and the rare Thriputharattu fertility rite when '
        'the goddess’s menstrual sign is observed.',
    story:
        'Chengannur Mahadeva Temple near the Pamba river is one of Kerala’s '
        'important Shiva–Devi complexes and a traditional gateway node for '
        'Sabarimala pilgrims. Shiva (Mahadeva) and Bhagavathy '
        '(Parvati/Bhadrakali traditions in local telling) are worshipped with '
        'paired importance — Shiva facing east and the goddess shrine arranged '
        'in the classic dual layout; the linga tradition includes '
        'Ardhanarishwara associations in popular description.\n\n'
        'Architecturally the copper-clad circular-plan vimana, gopuram, and '
        'nalambalam exemplify mature Kerala temple form. Tantric worship '
        'traditions are associated with the Thazhamon family lineage in temple '
        'histories.\n\n'
        'The temple is uniquely known for Thriputharattu (Thripputhu): when '
        'menstrual signs are observed on the goddess’s vesture, the sanctum '
        'observes seclusion for three days and reopens after purification '
        'rites, with related processional bath traditions toward the Pamba. In '
        'modern practice the event is irregular (often cited every few months '
        'rather than monthly). Annual utsavam spans Dhanu–Makaram cycles with '
        'lengthy festival programming. Approach Thriputharattu as living sacred '
        'practice, not spectacle.',
    location: 'Chengannur, Alappuzha, Kerala 689121',
    timings:
        'Commonly listed public envelope (secondary guides; confirm Travancore '
        'Devaswom / local board): roughly 4:00/4:30 AM–11:30 AM and 5:00 '
        'PM–8:00 PM (some lists note opening near 3:50 AM). Five daily pujas '
        'for the dual shrines are described in temple histories — exact English '
        'minute boards are thin. CRITICAL: during Thriputharattu seclusion the '
        'relevant shrine remains closed ~3 days — do not plan fixed dates; '
        'watch local announcements. Annual festival (Dhanu–Makaram) overrides '
        'ordinary hours. Visitor tip: THIN official English named-pooja clock. '
        'Thriputharattu closures are irregular — always verify same-week '
        'status. Treat fertility rite with cultural respect.',
    latitude: 9.3243,
    longitude: 76.6114,
    specialities: [
      'Thriputharattu — rare goddess menstruation rite & Pamba arattu',
      'Circular copper-clad Kerala vimana',
      'Dual Shiva–Bhagavathy sanctum importance',
      'Sabarimala pilgrim gateway town association',
      'Lengthy Dhanu–Makaram annual festival cycle',
      'Nearest airport: COK; Chengannur railway station',
      'Confirm Thriputharattu status before travel',
    ],
  ),
  // KAN-77: verified Commons thumbs — tools/photo-packs/kaviyoor-mahadeva-temple/
  Temple(
    name: 'Kaviyoor Mahadeva Temple',
    state: 'Kerala',
    city: 'Kaviyoor',
    deity: 'Shiva',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/RoudraBhima_and_Draupadi%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG/1280px-RoudraBhima_and_Draupadi%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: const [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/RoudraBhima_and_Draupadi%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG/1280px-RoudraBhima_and_Draupadi%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Sree_Krishna_Leela%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG/1280px-Sree_Krishna_Leela%2C_Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a3/Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG/1280px-Wood_Carving%2C_Kaviyoor_Mahadevar_Temple..JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e5/Kaviyoor_mahadeva_temple_01.jpg/1280px-Kaviyoor_mahadeva_temple_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1a/Kaviyoor_mahadeva_temple_02.jpg/1280px-Kaviyoor_mahadeva_temple_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/Kaviyoor_mahadeva_temple_03.jpg/1280px-Kaviyoor_mahadeva_temple_03.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Tenth-century circular-plan Mahadeva temple near Thiruvalla, noted for '
        'early inscriptions (c. 950–951 CE), exquisite wood carvings, and a '
        'highly popular Hanuman shrine within the complex.',
    story:
        'Kaviyoor Mahadeva Temple (Thrikkaviyoor / Thrikkaviyoorappan) crowns a '
        'hillock near Thiruvalla in Pathanamthitta district. It is a Travancore '
        'Devaswom Board Special Grade temple whose granite adhisthana carries '
        'two early inscriptions dated Kali 4051–4052 (about 950–951 CE), '
        'placing the living shrine among Kerala’s securely early structural '
        'temples. The circular vimana with square sanctum, double pradakshina '
        'path, and later wooden superstructure restored in the 19th century '
        'make it an architectural study site as well as a living pilgrimage.\n\n'
        'Though Shiva with Parvati is the principal focus, the Hanuman shrine '
        'inside the complex often draws equal or greater popular devotion — '
        'local tradition links Hanuman’s presence to the Rama–Setu return '
        'narrative in which an earthen linga consecrated by Rama could not be '
        'displaced for Hanuman’s Himalayan linga. A separate Keezhthrikkovil '
        'Vishnu temple sits below the main complex.\n\n'
        'Distinguish this living Mahadeva temple from the nearby Kaviyoor / '
        'Thrikkakkudi rock-cut cave shrine (often listed separately). Festivals '
        'include Dhanu utsavam, Hanumath Jayanthi, Shivaratri lighting of '
        'thousands of lamps, Sahasrakalasam, and Panthrantu Kalabham for '
        'Hanuman. Wood-carved Ramayana and Puranic panels adorn mandapas.',
    location: 'Kaviyoor, Thiruvalla, Pathanamthitta, Kerala 689582',
    timings:
        'Provisional (secondary compilations conflict — Oneindia-style named '
        'poojas vs trip sites listing 5:00–11:00 AM & 5:00–7:30 PM). Prefer '
        'on-site / Devaswom board. Named markers often cited: Nirmalyam ~4:00 '
        'AM; Usha Pooja ~6:00 AM; Ucha Pooja ~12:00 PM; Athazha Pooja ~7:30 PM. '
        'Festival days (Dhanu utsavam, Shivaratri, Hanumath Jayanthi) override. '
        'Do not confuse hours with the separate rock-cut cave temple nearby. '
        'Visitor tip: THIN/conflicting official English clocks. Keep rock-cut '
        'cave temple as a separate optional heritage stop — not this doc’s '
        'primary sanctum.',
    latitude: 9.3964,
    longitude: 76.6106,
    specialities: [
      'Early 10th-c. inscriptions (c. 950–951 CE) on granite base',
      'Circular vimana; double pradakshina; fine wood carvings',
      'Popular Hanuman shrine within Shiva complex',
      'Distinct from nearby Kaviyoor rock-cut cave temple',
      'Dhanu utsavam, Shivaratri lamp festival, Sahasrakalasam',
      'Nearest airport: COK; Thiruvalla rail + short road',
      'THIN / conflicting published clocks — confirm locally',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  KARNATAKA
  // ═══════════════════════════════════════════════════════════════════════════
  // Research-enriched visitor copy for the existing 10 Karnataka temples
  // (matched by name/slug — no new documents). KAN-77 Wave B replaces picsum
  // covers with Commons downloaded_url thumbs from tools/photo-packs/<slug>/
  // (not Storage). Sources: docs/karnataka-sample-research.md.
  Temple(
    name: 'Sri Krishna Matha (Udupi)',
    state: 'Karnataka',
    city: 'Udupi',
    deity: 'Vishnu',
    // KAN-77: Research site_verified Matha-only Commons downloaded_url thumbs —
    // tools/photo-packs/sri-krishna-matha-udupi/ (not Storage).
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Udupi_Sri_Krishna_Matha_Temple.jpg/1280px-Udupi_Sri_Krishna_Matha_Temple.jpg',
    images: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Udupi_Sri_Krishna_Matha_Temple.jpg/1280px-Udupi_Sri_Krishna_Matha_Temple.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Udupi_Sri_krishna_matha_Temple_pond.jpg/1280px-Udupi_Sri_krishna_matha_Temple_pond.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Krishna_Math_Gopura_Udupi.JPG/1280px-Krishna_Math_Gopura_Udupi.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Madhvacharya_Krishna_Matha_Udupi_Karnataka.jpg/1280px-Madhvacharya_Krishna_Matha_Udupi_Karnataka.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Sri_Krishna_Math_Udupi.JPG/1280px-Sri_Krishna_Math_Udupi.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Sri_Krishna_Matha_%28Monastery%29_and_temple%2C_Udupi_Karnataka.jpg/1280px-Sri_Krishna_Matha_%28Monastery%29_and_temple%2C_Udupi_Karnataka.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Udupi_Krishna_Temple_gopuram_and_Kankana_kindi.jpg/1280px-Udupi_Krishna_Temple_gopuram_and_Kankana_kindi.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Udupi_Krishna_Temple_gopuram_from_the_west.jpg/1280px-Udupi_Krishna_Temple_gopuram_from_the_west.jpg',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/sri-manjunatha-temple-dharmasthala/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/90/KASHDK_21_Dharmasthala_Sculptures_inPark.jpg/1280px-KASHDK_21_Dharmasthala_Sculptures_inPark.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/90/KASHDK_21_Dharmasthala_Sculptures_inPark.jpg/1280px-KASHDK_21_Dharmasthala_Sculptures_inPark.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/KASHDK_25_Dharmasthala_SaraswatiMandapam_inPark.jpg/1280px-KASHDK_25_Dharmasthala_SaraswatiMandapam_inPark.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/de/KASHDK_24_Dharmasthala_SaraswatiMandapam_in_Park.jpg/1280px-KASHDK_24_Dharmasthala_SaraswatiMandapam_in_Park.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6b/KASHDK_22_Dharmasthala_Bhadrakali_inPark_3D.jpg/1280px-KASHDK_22_Dharmasthala_Bhadrakali_inPark_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fb/KASHDK_23_Dharmasthala_Bhairavi_inPark_3D.jpg/1280px-KASHDK_23_Dharmasthala_Bhairavi_inPark_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/93/Jungle_Babbler_perched.jpg/1280px-Jungle_Babbler_perched.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/kukke-subramanya-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d4/Kukke_Shree_Subrahmanya_Temple_%281%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d4/Kukke_Shree_Subrahmanya_Temple_%281%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/35/Kukke_Shree_Subrahmanya_Temple_%2810%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%2810%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/97/Kukke_Shree_Subrahmanya_Temple_%2811%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%2811%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ca/Kukke_Shree_Subrahmanya_Temple_%2812%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%2812%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/Kukke_Shree_Subrahmanya_Temple_%2813%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%2813%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e9/Kukke_Shree_Subrahmanya_Temple_%2814%29.jpg/1280px-Kukke_Shree_Subrahmanya_Temple_%2814%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/sringeri-sharada-peetham/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/A_distant_view_of_the_Sringeri_Sharada_Peetham.jpg/1280px-A_distant_view_of_the_Sringeri_Sharada_Peetham.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/A_distant_view_of_the_Sringeri_Sharada_Peetham.jpg/1280px-A_distant_view_of_the_Sringeri_Sharada_Peetham.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7e/Rajagopuram_of_the_Sringeri_Sarada_peetham.jpg/1280px-Rajagopuram_of_the_Sringeri_Sarada_peetham.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/be/Shringeri_Sharadamba_Temple_-_1.jpg/1280px-Shringeri_Sharadamba_Temple_-_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e8/Shringeri_Sharadamba_Temple_-_2.jpg/1280px-Shringeri_Sharadamba_Temple_-_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Shringeri_Sharadamba_Temple_-_3.jpg/1280px-Shringeri_Sharadamba_Temple_-_3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a3/Sri_Vidyashankara_Temple%281342_AD%29_at_Sringeri%2C_Karnataka.jpg/1280px-Sri_Vidyashankara_Temple%281342_AD%29_at_Sringeri%2C_Karnataka.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/kollur-mookambika-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d8/Kollur_Mookambika_Temple_main_shrine.jpg/1280px-Kollur_Mookambika_Temple_main_shrine.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d8/Kollur_Mookambika_Temple_main_shrine.jpg/1280px-Kollur_Mookambika_Temple_main_shrine.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f7/Kollur_Mookambika_temple_east_entrance_gate.jpg/1280px-Kollur_Mookambika_temple_east_entrance_gate.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/57/Kollur_Mookambika_temple_entrance_gate.jpg/1280px-Kollur_Mookambika_temple_entrance_gate.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2b/Vimana_of_the_Kollur_Mookambika_Temple.jpg/1280px-Vimana_of_the_Kollur_Mookambika_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/28/Kollur_Mookambika_Temple_20080123.JPG/1280px-Kollur_Mookambika_Temple_20080123.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/15/Walking_through_Kollur_misty_forest_path.jpg/1280px-Walking_through_Kollur_misty_forest_path.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77: Research site_verified Commons downloaded_url thumbs —
    // tools/photo-packs/mahabaleshwar-temple-gokarna/ (not Storage).
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/KW23-0751-Gokarna-AdiGokarna-Front1_3D.jpg/1280px-KW23-0751-Gokarna-AdiGokarna-Front1_3D.jpg',
    images: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/KW23-0751-Gokarna-AdiGokarna-Front1_3D.jpg/1280px-KW23-0751-Gokarna-AdiGokarna-Front1_3D.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/KW23-0752-Gokarna-AdiGokarna-RightFront2_3D.jpg/1280px-KW23-0752-Gokarna-AdiGokarna-RightFront2_3D.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/KW23-0754-Gokarna-AdiGokarna-FrontFull4_3D.jpg/1280px-KW23-0754-Gokarna-AdiGokarna-FrontFull4_3D.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Main_entry_to_the_Mahabaleshwar_Temple_at_Gokaran.jpg/1280px-Main_entry_to_the_Mahabaleshwar_Temple_at_Gokaran.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Entrance_to_Gokarna_Mahabaleshwar_Temple_-_panoramio.jpg/1280px-Entrance_to_Gokarna_Mahabaleshwar_Temple_-_panoramio.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Dravidian_style_Gopura_of_Mahabaleshwar_temple_at_Gokaran.jpg/1280px-Dravidian_style_Gopura_of_Mahabaleshwar_temple_at_Gokaran.jpg',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/chamundeshwari-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Chamundi_From_Karanji_Mysore_Nov23_A7C_08173.jpg/1280px-Chamundi_From_Karanji_Mysore_Nov23_A7C_08173.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Chamundi_From_Karanji_Mysore_Nov23_A7C_08173.jpg/1280px-Chamundi_From_Karanji_Mysore_Nov23_A7C_08173.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d1/Chamundeshwari_Temple%2C_Mysuru%2C_Karnataka%2C_India_Temple.jpg/1280px-Chamundeshwari_Temple%2C_Mysuru%2C_Karnataka%2C_India_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2830%29.jpg/1280px-Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2830%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/Mysore_-_Race_Course_From_Chamundi_Hill.jpg/1280px-Mysore_-_Race_Course_From_Chamundi_Hill.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e1/Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2833%29.jpg/1280px-Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2833%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/eb/Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2834%29.jpg/1280px-Chamundeshwari_Devi_Temple-Dr._Murali_Mohan_Gurram_%2834%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/virupaksha-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Hemakuta_Hills.jpg/1280px-Hemakuta_Hills.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/03/Hemakuta_Hills.jpg/1280px-Hemakuta_Hills.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d4/Virupaksha_-_Hemakuta_Hill_-_1.jpg/1280px-Virupaksha_-_Hemakuta_Hill_-_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fc/Virupaksha_-_Hemakuta_Hill_-_3.jpg/1280px-Virupaksha_-_Hemakuta_Hill_-_3.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/53/Virupaksha_Temple_Tower.jpg/1280px-Virupaksha_Temple_Tower.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cf/Hampi_-_Hemakuta_Hill_-_Sri_Guddada_Moola_Virupaksha_Temple.jpg/1280px-Hampi_-_Hemakuta_Hill_-_Sri_Guddada_Moola_Virupaksha_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/29/Hampi_-_Underground_Shive_Temple_-_Columns.jpg/1280px-Hampi_-_Underground_Shive_Temple_-_Columns.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/srikanteshwara-temple-nanjangud/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8a/Laundry_Upstream_Kabini_Nanjangud_Sep24_A7CR_02967.jpg/1280px-Laundry_Upstream_Kabini_Nanjangud_Sep24_A7CR_02967.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8a/Laundry_Upstream_Kabini_Nanjangud_Sep24_A7CR_02967.jpg/1280px-Laundry_Upstream_Kabini_Nanjangud_Sep24_A7CR_02967.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/77/Upstream_Kabini_Bridge_Nanjangud_Sep24_A7CR_02971.jpg/1280px-Upstream_Kabini_Bridge_Nanjangud_Sep24_A7CR_02971.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f7/KAM22_Nanjangud_01_SriKanteshwara_Temple_South_Side.jpg/1280px-KAM22_Nanjangud_01_SriKanteshwara_Temple_South_Side.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/Upstream_Kabini_Southbound_Bridge_Nanjangud_Sep24_A7CR_02976.jpg/1280px-Upstream_Kabini_Southbound_Bridge_Nanjangud_Sep24_A7CR_02976.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/eb/Upstream_Kabini_Southbound_Bridge_Nanjangud_Sep24_A7CR_02974.jpg/1280px-Upstream_Kabini_Southbound_Bridge_Nanjangud_Sep24_A7CR_02974.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/65/Upstream_Kabini_Northbound_Bridge_Nanjangud_Sep24_A7CR_02966.jpg/1280px-Upstream_Kabini_Northbound_Bridge_Nanjangud_Sep24_A7CR_02966.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/iskcon-temple-bangalore/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/Clothes_for_drying_in_Iskcon_temple%2C_Bangalore.JPG/1280px-Clothes_for_drying_in_Iskcon_temple%2C_Bangalore.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/Clothes_for_drying_in_Iskcon_temple%2C_Bangalore.JPG/1280px-Clothes_for_drying_in_Iskcon_temple%2C_Bangalore.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4d/ISKCON_Temple_-_Bangalore_-_Karnataka_-_DSCN0101.jpg/1280px-ISKCON_Temple_-_Bangalore_-_Karnataka_-_DSCN0101.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ce/Iskcon_bengaluru.jpg/1280px-Iskcon_bengaluru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2f/ISKON_temple_in_Bengaluru.jpg/1280px-ISKON_temple_in_Bengaluru.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/Iskcon_Temple_from_Bengaluru_City%2C_May_2026.jpg/1280px-Iskcon_Temple_from_Bengaluru_City%2C_May_2026.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/ISKCON_Vaikunta_hill%2C_Vasanthpura%2C_Bangalore_%282024%29_150.jpg/1280px-ISKCON_Vaikunta_hill%2C_Vasanthpura%2C_Bangalore_%282024%29_150.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
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

  // ── KAN-64 / KAN-74 expansion batch 18 — +10 additional Karnataka temples
  // Core Temple fields only (Hybrid C): trip_planning stripped / not seeded.
  // KAN-77 Wave B: imageUrl/images are Commons downloaded_url thumbs from
  // tools/photo-packs/<slug>/ (not Storage). Cheluvanarayana's pack folder is
  // cheluvanarayana-swamy-temple-melukote; Seed id stays
  // cheluvanarayana-swamy-temple. See docs/karnataka-sample-research.md.
  Temple(
    name: 'Cheluvanarayana Swamy Temple',
    state: 'Karnataka',
    city: 'Melukote',
    deity: 'Vishnu',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/cheluvanarayana-swamy-temple-melukote/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/Melukote_mantap.jpg/1280px-Melukote_mantap.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/19/Melukote_mantap.jpg/1280px-Melukote_mantap.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b8/Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%281%29.jpg/1280px-Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%281%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/09/Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%2810%29.jpg/1280px-Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%2810%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5a/Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%2811%29.jpg/1280px-Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%2811%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/66/Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%28111%29.jpg/1280px-Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%28111%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a9/Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%28118%29.jpg/1280px-Cheluvanarayana_Swamy_Temple%2C_Melkote_-_during_PHMSTBGP-2020_%28118%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Sri Vaishnava Vishnu temple of Cheluva Narayana at Melukote '
        '(Thirunarayanapura), linked to Ramanujacharya’s stay and famed for the '
        'Vairamudi crown festival, with Yoga Narasimha on the hill above.',
    story:
        'Melukote sits on the rocky Yadugiri ridge in Mandya district, looking '
        'over the Cauvery country. Cheluvanarayana Swamy Temple is the town’s '
        'principal Vishnu shrine; the Yoga Narasimha temple crowns the hill, '
        'and the two form a paired pilgrimage.\n\n'
        'Sri Vaishnava tradition credits Sri Ramanujacharya’s '
        'early-12th-century residence here with restoring worship under Hoysala '
        'patronage. The metallic processional image and the Vairamudi (diamond '
        'crown) used at the annual Vairamudi Brahmotsavam are Melukote’s '
        'best-known ritual treasures; later Mysore Wodeyar endowments expanded '
        'the complex.\n\n'
        'The precinct combines earlier fabric with royal-period halls and a '
        'strong festival processional culture. Melukote also hosts a long '
        'Sanskrit scholarly tradition.\n\n'
        'Daily worship follows Sri Vaishnava nitya-puja patterns with a midday '
        'rest. Vairamudi and other utsavas override ordinary hours and draw '
        'very large crowds—confirm the live notice board before travel.',
    location:
        'Melukote (Thirunarayanapura), Pandavapura Taluk, Mandya District, '
        'Karnataka 571431',
    timings:
        'PROVISIONAL (secondary compilations; no stable English Devasthanam '
        'live board confirmed in this pass): weekday darshan often listed ~7:30 '
        'AM–1:00 PM & ~4:00–8:00 PM (some lists split evening ~4:00–6:00 & '
        '~7:00–8:00 PM); weekends/holidays often ~7:30 AM–1:30 PM, ~3:30–6:00 '
        'PM & ~7:00–8:00 PM. Vairamudi / Brahmotsavam commonly extends late. '
        'Re-check Melukote temple board—festival and seasonal change risk is '
        'high. Visitor tip: Modest dress; footwear outside. Vairamudi week '
        'needs early arrival. Yoga Narasimha involves a hill climb/drive. '
        'Timings labelled provisional.',
    latitude: 12.6594,
    longitude: 76.6483,
    specialities: [
      'Sri Vaishnava Melukote / Thirunarayanapura — Ramanujacharya association',
      'Vairamudi Brahmotsavam (diamond crown procession)',
      'Paired hill pilgrimage with Yoga Narasimha',
      'Historic Wodeyar endowments',
      'Nearest airport: Mysuru (MYQ) or Bengaluru (BLR)',
      'Veg / pilgrim food: Melukote town vegetarian eateries (generic)',
    ],
  ),
  Temple(
    name: 'Murudeshwar Temple',
    state: 'Karnataka',
    city: 'Murudeshwar',
    deity: 'Shiva',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/murudeshwar-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/78/KW23-0422-Murdeshwar-Shani-Bhagvan-Temple_3D.jpg/1280px-KW23-0422-Murdeshwar-Shani-Bhagvan-Temple_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/78/KW23-0422-Murdeshwar-Shani-Bhagvan-Temple_3D.jpg/1280px-KW23-0422-Murdeshwar-Shani-Bhagvan-Temple_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/04/KW23-0424-Murdeshwar-Krishna-Arjuna-with-ShivaBackground_3D.jpg/1280px-KW23-0424-Murdeshwar-Krishna-Arjuna-with-ShivaBackground_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/85/KW23-0421-Murdeshwar-ShivaStatue-RightView_3D.jpg/1280px-KW23-0421-Murdeshwar-ShivaStatue-RightView_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/97/KW23-0423-Murdeshwar-Temple-Gopuram_3D.jpg/1280px-KW23-0423-Murdeshwar-Temple-Gopuram_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e4/KW23-0420-Murdeshwar-ShivaStatue-LeftView_3D.jpg/1280px-KW23-0420-Murdeshwar-ShivaStatue-LeftView_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/12/Murdeshwara_Temple_beach_22_30_36_747000.jpeg/1280px-Murdeshwara_Temple_beach_22_30_36_747000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Coastal Shiva temple on Kanduka Hill at Murudeshwar, known for its '
        'towering Raja Gopura, ~123 ft Shiva statue, Arabian Sea setting, and '
        'the Atmalinga legend shared with Gokarna.',
    story:
        'Murudeshwar stands where the Arabian Sea wraps Kanduka Hill in Uttara '
        'Kannada. The living Murudeshwara (Shiva) shrine is paired with a '
        'modern monumental skyline: a multi-storey Raja Gopura with lift '
        'viewpoint and one of the world’s tallest Shiva statues.\n\n'
        'Tradition ties the site to the Ravana–Atmalinga narrative also told at '
        'Gokarna—after the linga was fixed at Gokarna, coverings or fragments '
        'associated with it are said to have fallen at coastal sacred spots '
        'including Murudeshwar. State tourism notes it is popularly revered but '
        'is not one of the twelve canonical Jyotirlingas.\n\n'
        'Pilgrims combine darshan with beach walks and dusk views of the '
        'illuminated statue and gopuram. Dress code is enforced for sanctum '
        'entry; outer complex photography is freer.\n\n'
        'Karnataka Tourism publishes a split darshan day with a midday break. '
        'Maha Shivaratri and weekends are peak—confirm same-day boards.',
    location:
        'Kanduka Hill, Murudeshwar, Bhatkal Taluk, Uttara Kannada, Karnataka '
        '581350',
    timings:
        'Karnataka Tourism visitor table (confirm locally; festival change '
        'risk): morning darshan 6:00 AM–1:00 PM; evening darshan 3:00 PM–8:30 '
        'PM; abhisheka commonly from ~6:30 AM; midday break ~1:00–3:00 PM. '
        'Named minute-level pooja slots on secondary sites are PROVISIONAL '
        'unless confirmed on the temple board. Raja Gopuram lift ticketed '
        'separately (tourism lists a small fee). Visitor tip: Modest dress for '
        'sanctum (tourism: dhoti/formal trousers for men; saree/chudidar with '
        'dupatta for women). Footwear outside. Heavy queues on Mondays, '
        'Pradosham, Shivaratri.',
    latitude: 14.0943,
    longitude: 74.4844,
    specialities: [
      '~123 ft coastal Shiva statue and multi-storey Raja Gopura',
      'Atmalinga-legend link with Gokarna (not a canonical Jyotirlinga)',
      'Arabian Sea setting on Kanduka Hill',
      'Nearest airport: Mangaluru (IXE)',
      'Veg food: temple-town vegetarian hotels (generic)',
      'Afternoon anna prasada subject to availability (tourism-listed)',
    ],
  ),
  Temple(
    name: 'Annapoorneshwari Temple, Horanadu',
    state: 'Karnataka',
    city: 'Horanadu',
    deity: 'Devi',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/annapoorneshwari-temple-horanadu/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a8/Horanadu_Temple_Entrance_%2832965363862%29.jpg/1280px-Horanadu_Temple_Entrance_%2832965363862%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a8/Horanadu_Temple_Entrance_%2832965363862%29.jpg/1280px-Horanadu_Temple_Entrance_%2832965363862%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ac/Horanadu_Annapurneshwari_Temple.jpg/1280px-Horanadu_Annapurneshwari_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0c/Horanadu_Jaatre.jpg/1280px-Horanadu_Jaatre.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cc/Horanadu.jpg/1280px-Horanadu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/27/Hills_2.jpg/1280px-Hills_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3e/Santhana_Priya_Naga_Kshetra.jpg/1280px-Santhana_Priya_Naga_Kshetra.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Western Ghats shrine of Adishakti Annapoorneshwari at Horanadu (Sri '
        'Kshetra Horanadu), known for continuous annadana and a gold-clad '
        'goddess image in a forested Bhadra-country setting.',
    story:
        'Horanadu (Hornadu) lies in the forested hills of Chikkamagaluru on the '
        'Bhadra country, reached through winding Ghats roads. Sri Kshetra '
        'Horanadu’s official site identifies the deity as Adishakthyathmaka Sri '
        'Annapoorneshwari and credits Agastya with the ancient pratishta.\n\n'
        'Hereditary Dharmakartharu administration is described as '
        'multi-century; the temple grew from a small forest shrine into a major '
        'Malnad Devi pilgrimage. Annadana (free meals) and shelter for visitors '
        'are emphasised as living continuity of the Annapoorna ideal.\n\n'
        'The present complex includes a gold-finished goddess image in a green '
        'valley setting. Dress rules are published on the official site.\n\n'
        'Official darshan span is stated as 6:00 AM–9:00 PM; secondary sites '
        'disagree on midday breaks and named aarti minutes—prefer the official '
        'board/site and treat detailed pooja clocks as provisional unless '
        'confirmed on arrival.',
    location:
        'Sri Kshetra Horanadu, Kalasa Taluk, Chikkamagaluru District, Karnataka '
        '577181',
    timings:
        'OFFICIAL (srikshetrahoranadu.com Darshana Rules): darshan 6:00 AM to '
        '9:00 PM. Named mahamangalarati / split-session clocks on secondary '
        'travel sites CONFLICT and are PROVISIONAL—confirm on-site board. '
        'Annadana / prasada meal windows are published variously; verify same '
        'day. Festival days may alter queues. Visitor tip: Official dress code '
        'enforced. Photography rules are strict inside—follow staff. Mountain '
        'roads can be slow in monsoon.',
    latitude: 13.2767,
    longitude: 75.3438,
    specialities: [
      'Adishakti Annapoorneshwari — Agastya pratishta tradition',
      'Continuous annadana / pilgrim feeding culture',
      'Western Ghats / Malnad forest setting near Kalasa',
      'Official dress code for darshan',
      'Nearest airport: Mangaluru (IXE) or Bengaluru (BLR) via Chikkamagaluru roads',
      'Temple guest rooms / pilgrim stays (enquire via official channels)',
      'Veg food: pilgrim-area vegetarian eateries (generic)',
    ],
  ),
  Temple(
    name: 'Kateel Durga Parameshwari Temple',
    state: 'Karnataka',
    city: 'Kateel',
    deity: 'Devi',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/kateel-durga-parameshwari-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/Kateelu_Durgaparameshwari_Temple_10_55_15_890000.jpeg/1280px-Kateelu_Durgaparameshwari_Temple_10_55_15_890000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/Kateelu_Durgaparameshwari_Temple_10_55_15_890000.jpeg/1280px-Kateelu_Durgaparameshwari_Temple_10_55_15_890000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/de/Kateelu.jpg/1280px-Kateelu.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/KATEEL_TEMPLE.jpg/1280px-KATEEL_TEMPLE.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c3/Shri_durgaparameshwari_temple.jpg/1280px-Shri_durgaparameshwari_temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/83/Shree_Durga_parameshwari_Temple%2C_Kateel_01.jpg/1280px-Shree_Durga_parameshwari_Temple%2C_Kateel_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fd/Shree_Durga_parameshwari_Temple%2C_Kateel_02.jpg/1280px-Shree_Durga_parameshwari_Temple%2C_Kateel_02.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'River-island Devi temple of Durga Parameshwari at Kateel on the '
        'Nandini, a major Tulunadu Shakti pilgrimage known for Yakshagana '
        'patronage and dense coastal ritual life.',
    story:
        'Kateel (Kateelu) sits on the Nandini river about 20–25 km from '
        'Mangaluru. The name is popularly explained from ‘kati’ (waist/middle) '
        'and ‘ila’ (earth)—the shrine as mid-earth—matching its position amid '
        'the river course.\n\n'
        'Temple lore narrates Adishakti’s victory over the demon Arunasura '
        'through a swarm of bees after he could not be slain by ordinary two- '
        'or four-legged beings; the goddess then manifested in the river, '
        'around which the temple grew. The complex remains a living Tulunadu '
        'Shakti centre with strong annadana and Yakshagana patronage.\n\n'
        'Official kateeldevi.in publishes devotee rules (bath before entry, no '
        'footwear, no phones/photography inside, menstrual and late-pregnancy '
        'restrictions, etc.) more clearly than a fixed English clock.\n\n'
        'Published darshan spans on tourism/secondary pages commonly run '
        'roughly early morning to late evening with Friday late close, but '
        'midday-break claims conflict—treat detailed clocks as provisional and '
        'confirm the temple board.',
    location:
        'Kateel (Kateelu), Mangaluru Taluk, Dakshina Kannada, Karnataka 574148',
    timings:
        'PROVISIONAL / secondary tourism compilations (official English full '
        'clock thin): often listed ~5:30 AM–9:30 PM daily, Fridays ~5:30 '
        'AM–10:30 PM; some apps instead list split 5:00 AM–1:00 PM & 3:00 '
        'PM–9:00 PM. Early abhisheka sequences from ~3:00 AM and mahapooja '
        '~noon appear on secondary ritual tables. Confirm kateeldevi.in / '
        'notice board before travel—festival and Friday patterns change queues '
        'and close. Visitor tip: Follow kateeldevi.in do’s/don’ts: bath before '
        'entry; no footwear, phones, or photography inside; observe published '
        'gender/health restrictions. Queues spike Fridays and '
        'Brahmakalashotsava.',
    latitude: 13.0438,
    longitude: 74.8701,
    specialities: [
      'Nandini river-island Shakti shrine (Tulunadu)',
      'Arunasura / bee-swarm Devi legend',
      'Yakshagana cultural patronage',
      'Temple-managed pilgrim guest houses (enquire officially)',
      'Nearest airport: Mangaluru (IXE)',
      'Veg / annadana: temple meals subject to crowd-day variation',
    ],
  ),
  Temple(
    name: 'Ghati Subramanya Temple',
    state: 'Karnataka',
    city: 'Doddaballapur',
    deity: 'Murugan',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/ghati-subramanya-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/Ghati_Subramanya_08.jpg/1280px-Ghati_Subramanya_08.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/da/Ghati_Subramanya_08.jpg/1280px-Ghati_Subramanya_08.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/02/Ghati_Subramanya_09.jpg/1280px-Ghati_Subramanya_09.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ea/Ghati_Subramanya_10.jpg/1280px-Ghati_Subramanya_10.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/Ghati_Subramanya_11.jpg/1280px-Ghati_Subramanya_11.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/Ghati_Subramanya_16.jpg/1280px-Ghati_Subramanya_16.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/Ghati_Subramanya_24.jpg/1280px-Ghati_Subramanya_24.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Unique Subrahmanya–Narasimha swayambhu shrine near Doddaballapur (~60 '
        'km from Bengaluru), a major regional Subrahmanya kshetra known for '
        'Ashlesha Bali and other naga-related rites.',
    story:
        'Ghati Subramanya lies near Doddaballapur in Bengaluru Rural district, '
        'about 60 km from Bengaluru. The sanctum is distinctive: Subrahmanya '
        '(Kartikeya) faces east with a seven-hooded serpent form on the front '
        'of a swayambhu stone, while Narasimha is on the reverse and viewed via '
        'a mirror.\n\n'
        'Local tradition credits Ghorpade rulers of Sandur with building the '
        'garbhagriha after a dream-led discovery of the idols; folklore treats '
        'the sacred site as older. Purāṇic tellings speak of Subrahmanya’s '
        'penance and protection of naga beings, with Narasimha as '
        'guardian—hence the dual presence.\n\n'
        'The temple is an important centre for Ashlesha Bali and related naga '
        'rites, drawing devotees seeking relief from naga dosha and childless '
        'couples. Brahmarathotsava on Pushya Shuddha Shashti and Narasimha '
        'Jayanti are major festivals.\n\n'
        'Published hours disagree: some sources say continuous ~6:00 '
        'AM–8:30/9:00 PM; others insert a midday break ~12:00–4:00 PM. '
        'Abhishekam ~8:30 AM and mahamangalarati ~10:30 AM & ~8:30 PM recur '
        'across secondary lists—confirm by phone/board before travel.',
    location:
        'Sri Ghati Subramanya, S.S. Ghati Post, Doddaballapur Taluk, Bengaluru '
        'Rural District, Karnataka 561203',
    timings:
        'PROVISIONAL (no strong official English live board found): commonly '
        '6:00 AM–8:30/9:00 PM; CONFLICTING midday-break claims (none vs '
        '~12:00–4:00 PM). Secondary ritual markers: abhishekam ~8:30 AM; '
        'mahamangalarati ~10:30 AM & ~8:30 PM. Shashti / festival days alter '
        'queues. Re-confirm with temple office numbers on visitor guides before '
        'same-day travel. Visitor tip: Vehicle fee may apply on the ghat '
        'approach. Midday-break conflict means do not assume continuous darshan '
        'without checking. Naga sevas need advance counter planning on busy '
        'days.',
    latitude: 13.4086,
    longitude: 77.5286,
    specialities: [
      'Swayambhu Subrahmanya + Narasimha on one stone (mirror darshan)',
      'Ashlesha Bali / naga-related sevas',
      'Pushya Shuddha Shashti Brahmarathotsava',
      'Day-trip distance from Bengaluru via Doddaballapur',
      'Nearest airport: Kempegowda International (BLR)',
      'Veg food: temple annadana hall / pilgrim eateries (generic)',
    ],
  ),
  Temple(
    name: 'Banashankari Temple, Bengaluru',
    state: 'Karnataka',
    city: 'Bengaluru',
    deity: 'Devi',
    // KAN-77: Research site_verified Commons downloaded_url thumbs —
    // tools/photo-packs/banashankari-temple-bengaluru/ (Bengaluru, not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/Sri_Banashankri_Temple%2C_Bangalore_%282024%29.jpg/1280px-Sri_Banashankri_Temple%2C_Bangalore_%282024%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/00/Sri_Banashankri_Temple%2C_Bangalore_%282024%29.jpg/1280px-Sri_Banashankri_Temple%2C_Bangalore_%282024%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_01.jpg/1280px-Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4f/Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_03.jpg/1280px-Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_03.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1a/Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_06.jpg/1280px-Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_06.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_10.jpg/1280px-Sri_Banashankari_Temple%2C_Bengaluru_%282024%29_10.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/Banashankari_temple_inside_ome_small_plant.jpg/1280px-Banashankari_temple_inside_ome_small_plant.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Popular early-20th-century Banashankari Amma (Shakambari) temple on S. '
        'Kariyappa / Kanakapura Road that gives South Bengaluru’s Banashankari '
        'locality its name; HRCE-managed urban Devi shrine known for Rahukala '
        'worship.',
    story:
        'Banashankari Temple on S. Kariyappa Road is the urban Devi shrine '
        'after which much of South Bengaluru’s Banashankari locality is named. '
        'HRCE / ITMS materials describe a roughly century-old manusha-pratishta '
        'of Banashankari Amma (also Shakambari / Banadamma), with an associated '
        'Anjaneya image regarded as swayambhu on rock.\n\n'
        'Government takeover and later renovation turned a neighbourhood shrine '
        'into one of Bengaluru’s busiest Devi temples. A temple well whose '
        'water is used for daily abhisheka is part of local lore.\n\n'
        'Devotees especially visit during Rahukala on Tuesdays, Fridays, and '
        'Sundays. This entry is Banashankari, Bengaluru—not the historic '
        'Banashankari temple at Badami / Cholachagudd.\n\n'
        'HRCE ITMS lists opening windows; named pooja minutes remain thinner '
        'than the open/close board—confirm on-site.',
    location:
        'S. Kariyappa Road (Kanakapura Road side), Banashankari, Bengaluru '
        'South, Karnataka 560071',
    timings:
        'HRCE / ITMS temple page opening windows (confirm board): 6:30 AM–1:00 '
        'PM and 4:30 PM–8:30 PM (IST). Secondary city guides sometimes extend '
        'Friday/Sunday evenings or shift Tuesday afternoon open—treat those as '
        'PROVISIONAL vs the ITMS board. Rahukala days (esp. Tue/Fri/Sun) are '
        'crowded; Navaratri extends hours. Visitor tip: Urban temple—expect '
        'traffic on Kanakapura Road. Prefer ITMS/HRCE board over blog clocks. '
        'Distinct from Banashankari Badami.',
    latitude: 12.9252,
    longitude: 77.5465,
    specialities: [
      'Banashankari Amma / Shakambari — namesake of Banashankari locality',
      'HRCE-managed Bengaluru South urban temple',
      'Popular Rahukala worship (Tue/Fri/Sun peaks)',
      'Associated swayambhu Anjaneya tradition',
      'Nearest airport: Kempegowda International (BLR)',
      'Veg food: Banashankari / South Bengaluru vegetarian restaurants (generic area)',
    ],
  ),
  Temple(
    name: 'Chennakeshava Temple, Belur',
    state: 'Karnataka',
    city: 'Belur',
    deity: 'Vishnu',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/chennakeshava-temple-belur/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1e/KA_052_Belur_Hoysala_Emblem_Left_small.jpg/1280px-KA_052_Belur_Hoysala_Emblem_Left_small.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1e/KA_052_Belur_Hoysala_Emblem_Left_small.jpg/1280px-KA_052_Belur_Hoysala_Emblem_Left_small.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/37/Belur_1_4.jpg/1280px-Belur_1_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3f/Relief_work%CC%9E_Chennakeshava_temple%2C_Belur_%283%29.jpg/1280px-Relief_work%CC%9E_Chennakeshava_temple%2C_Belur_%283%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f4/Belloor_-_Temple_of_Vishnu%2C_Ddweepastumbum_and_Culyana_Munduppum.jpg/1280px-Belloor_-_Temple_of_Vishnu%2C_Ddweepastumbum_and_Culyana_Munduppum.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/75/Belloor_-_Temple_of_Vishnu%2C_Nagarcana_Gopuram_and_Tharomootee.jpg/1280px-Belloor_-_Temple_of_Vishnu%2C_Nagarcana_Gopuram_and_Tharomootee.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c8/Belloor_-_Temple_of_Vishnu%2C_Gateway.jpg/1280px-Belloor_-_Temple_of_Vishnu%2C_Gateway.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Living 12th-century Hoysala Vishnu temple of Chennakeshava at Belur '
        '(commissioned 1117 CE), combining continuous worship with '
        'ASI-protected fabric inside the UNESCO Sacred Ensembles of the '
        'Hoysalas.',
    story:
        'Chennakeshava (Vijayanarayana) Temple at Belur on the Yagachi was '
        'commissioned by Hoysala king Vishnuvardhana in 1117 CE and built over '
        'generations. Soft soapstone carries the signature Hoysala stellate '
        'plan, bracket figures, and narrative friezes that make Belur a '
        'landmark of South Indian temple art.\n\n'
        'UNESCO’s 2023 inscription of the Sacred Ensembles of the Hoysalas '
        'explicitly treats Belur’s Channakeshava as a living temple with '
        'continuity of worship, rituals, and festivals since inception, while '
        'the monument fabric is nationally protected. The main shikhara was '
        'lost in the 19th century and not rebuilt, yet living cult practice '
        'continues.\n\n'
        'Pilgrims come for Kesava darshan; heritage visitors come for sculpture '
        'walks in the courtyard and outer walls. Hassan district pages and '
        'secondary guides publish split darshan-style hours—confirm locally '
        'because living-temple ritual closes and ASI visitor rules can both '
        'apply.\n\n'
        'Dress and photography rules may differ between sanctum and outer '
        'monument zones—follow on-site ASI/temple staff.',
    location: 'Belur, Hassan District, Karnataka 573115',
    timings:
        'PROVISIONAL living-temple / visitor compilations (confirm board): '
        'commonly cited ~7:00 AM–1:00 PM & ~2:00/3:00 PM–8:00 PM style splits, '
        'with some continuous-day lists. Festival days and ASI conservation '
        'work can alter access. Prefer Belur temple / Hassan district / ASI '
        'on-site notice over blogs. UNESCO context: living worship continues at '
        'Belur (unlike Halebidu’s symbolic-only rule). Visitor tip: Living '
        'garbha cult — expect puja pauses. Outer sculpture circuit is '
        'heritage-focused. Do not confuse Belur’s living status with Halebidu’s '
        'ASI symbolic-worship rule.',
    latitude: 13.1629,
    longitude: 75.8606,
    specialities: [
      'Hoysala masterpiece — Vishnuvardhana 1117 CE commission',
      'UNESCO Sacred Ensembles of the Hoysalas (2023) — living temple component',
      'ASI-protected fabric + continuous Vaishnava worship',
      'Soapstone bracket figures and stellate plan',
      'Nearest airport: Bengaluru (BLR) / Mangaluru (IXE)',
      'Pair with Halebidu (~15–20 km) as heritage circuit',
      'Veg food: pilgrim-area vegetarian eateries (generic)',
    ],
  ),
  Temple(
    name: 'Hoysaleswara Temple, Halebidu',
    state: 'Karnataka',
    city: 'Halebidu',
    deity: 'Shiva',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/hoysaleswara-temple-halebidu/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_6.jpg/1280px-Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_6.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_6.jpg/1280px-Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_6.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka.jpg/1280px-Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/30/Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_5.jpg/1280px-Hoysaleswara_Temple_Sculptures_Halebid_Hassan_Karnataka_5.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/77/Pillared_Hall_Hoysaleswara_Temple_Halebid.jpg/1280px-Pillared_Hall_Hoysaleswara_Temple_Halebid.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/38/Artwork_at_Hoysaleswara_Temple_Halebid_%282%29.jpg/1280px-Artwork_at_Hoysaleswara_Temple_Halebid_%282%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/16/Artwork_at_Hoysaleswara_Temple_Halebid_%283%29.jpg/1280px-Artwork_at_Hoysaleswara_Temple_Halebid_%283%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        '12th-century Hoysala twin-Shiva masterpiece at Halebidu (Hoysalesvara '
        '& Shantalesvara), an ASI-protected monument in the UNESCO Sacred '
        'Ensembles—heritage visit with only symbolic worship permitted, not a '
        'full living festival temple.',
    story:
        'Hoysaleswara Temple at Halebidu (medieval Dorasamudra), the former '
        'Hoysala capital, is a dvikuta (twin-shrine) Shiva temple begun in the '
        'early 12th century under Vishnuvardhana’s era patronage and completed '
        'mid-century. Twin lingas Hoysalesvara and Shantalesvara face large '
        'Nandis across a richly carved jagati and multi-tier friezes of epics '
        'and deities.\n\n'
        'The monument is nationally protected by ASI and forms part of UNESCO’s '
        '2023 Sacred Ensembles of the Hoysalas. UNESCO decision text states '
        'that at Halebidu worship has long been discontinued and only symbolic '
        'worship is allowed—no rituals or festivals—contrasting with living '
        'Belur.\n\n'
        'Visitors should therefore plan a heritage monument visit: '
        'sunrise–sunset style ASI hours, ticketed entry as applicable, '
        'sculpture study, and respectful quiet—not a full nitya-puja pilgrimage '
        'like neighbouring Belur.\n\n'
        'Secondary sites that list daily aarti schedules conflict with '
        'UNESCO/ASI living-status framing; prefer monument visitor rules '
        'on-site.',
    location: 'Halebidu (Dorasamudra), Hassan District, Karnataka 573121',
    timings:
        'ASI / monument visitor framing (confirm on-site ticket counter): '
        'commonly sunrise–sunset / ~6:00 AM–6:00 PM style visitor hours in '
        'secondary guides. NOT a living full-ritual schedule. UNESCO (45 COM '
        '8B.38): only symbolic worship allowed; no rituals or festivals. Do not '
        'publish invented aarti clocks. Pair timing expectations with Belur’s '
        'living temple if combining the circuit. Visitor tip: Honesty framing: '
        'primarily an ASI/UNESCO monument experience. Any symbolic worship is '
        'limited; do not expect Belur-style daily utsavas. Follow ASI '
        'photography and circulation rules.',
    latitude: 13.2132,
    longitude: 75.995,
    specialities: [
      'Hoysala dvikuta Shiva temple — Hoysalesvara & Shantalesvara',
      'UNESCO Sacred Ensembles of the Hoysalas (2023) — Halebidu component',
      'ASI nationally protected monument',
      'Living status: symbolic worship only (UNESCO) — not full festival cult',
      'Epic frieze galleries and twin Nandi pavilions',
      'Circuit with living Belur Chennakeshava (~15–20 km)',
      'Nearest airport: Kempegowda International, Bengaluru / Mangaluru (BLR)',
      'Veg food: pilgrim-area vegetarian eateries (generic)',
    ],
  ),
  Temple(
    name: 'Anegudde Vinayaka Temple',
    state: 'Karnataka',
    city: 'Kumbhashi',
    deity: 'Ganesha',
    // KAN-77 Wave B: Commons downloaded_url thumbs —
    // tools/photo-packs/anegudde-vinayaka-temple/ (not Storage).
    imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2e/KW23-0310-AneguddeVinayaka-TempleChariot_3D.jpg/1280px-KW23-0310-AneguddeVinayaka-TempleChariot_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    images: [
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2e/KW23-0310-AneguddeVinayaka-TempleChariot_3D.jpg/1280px-KW23-0310-AneguddeVinayaka-TempleChariot_3D.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/37/Anegudde_Sri_Vinayaka_Temple_22_08_26_260000.jpeg/1280px-Anegudde_Sri_Vinayaka_Temple_22_08_26_260000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Anegudde_Sri_Vinayaka_Temple_22_08_37_641000.jpeg/1280px-Anegudde_Sri_Vinayaka_Temple_22_08_37_641000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/80/Anegudde_Sri_Vinayaka_Temple_22_08_46_945000.jpeg/1280px-Anegudde_Sri_Vinayaka_Temple_22_08_46_945000.jpeg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a7/Sri_Vinayaka_Temple.jpg/1280px-Sri_Vinayaka_Temple.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/71/Sri_Vinayaka_Temple_2.jpg/1280px-Sri_Vinayaka_Temple_2.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
    ],
    description:
        'Hillock Ganesha temple at Anegudde (Kumbhashi) on the Udupi–Kundapura '
        'NH66 belt, one of coastal Karnataka’s foremost Vinayaka kshetras, with '
        'an official daily pooja board and annadana.',
    story:
        'Anegudde (‘elephant hillock’) rises beside Kumbhashi on NH66 between '
        'Udupi and Kundapura. The Vinayaka temple on the knoll is among coastal '
        'Karnataka’s best-known Ganesha shrines; the official site publishes '
        'geo coordinates, opening hours, and a named daily pooja sequence.\n\n'
        'Local legend links the place to sage Agastya’s yajna disrupted by the '
        'demon Kumbhasura, with Ganesha’s grace aiding Bhima to slay the '
        'demon—hence Kumbhashi—and a swayambhu elephant-form Vinayaka. The '
        'imposing standing four-armed image is central to devotee experience.\n\n'
        'Official schema and FAQ list darshan roughly 6:00 AM–8:30 PM with '
        'Ushakala, Kalashabhisheka, Mahapooja & Annadana, Rangapooja, and night '
        'pooja markers. Special sevas (Ganahoma, Mooduganapathi, Tulabhara, '
        'Aksharabhyasa) have their own windows; Ekadashi reschedules some '
        'sevas.\n\n'
        'Pilgrim rooms are mentioned on temple information channels—confirm '
        'current booking practice on the official site.',
    location:
        'Anegudde, Kumbhashi (Kumbashi), Kundapura Taluk, Udupi District, '
        'Karnataka 576257',
    timings:
        'OFFICIAL (aneguddetemple.in): temple open daily 6:00 AM–8:30 PM. Daily '
        'pooja markers: Ushakala ~6:00 AM; Panchamrutha Kalashabhisheka ~11:00 '
        'AM; Mahapooja & Annadana ~1:00 PM; Rangapooja ~6:00 PM; Night pooja '
        '~8:30 PM. Special sevas (Ganahoma, Mooduganapathi slots, etc.) per '
        'official FAQ; Ganahoma-type sevas not held on Ekadashi (shift to '
        'Dwadashi). Festival days may alter queues—confirm site/board. Visitor '
        'tip: Follow official seva counters for Ganahoma / Mooduganapathi. '
        'Ekadashi changes apply. Modest coastal temple dress norms.',
    latitude: 13.5485,
    longitude: 74.7072,
    specialities: [
      'Coastal Karnataka Vinayaka kshetra on elephant hillock (Anegudde)',
      'Swayambhu Ganesha / Kumbhasura–Agastya legend',
      'Official named daily pooja + annadana board',
      'NH66 location between Udupi and Kundapura',
      'Nearest airport: Mangaluru (IXE)',
      'Temple pilgrim rooms (confirm official booking)',
      'Veg food: pilgrim-area vegetarian eateries (generic)',
    ],
  ),
  Temple(
    name: 'Talakaveri Temple',
    state: 'Karnataka',
    city: 'Bhagamandala',
    deity: 'Devi',
    // KAN-77: Research site_verified Commons downloaded_url thumbs —
    // tools/photo-packs/talakaveri-temple/ (Kodagu only, not Storage).
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Thala_Cauvery_%2818125847938%29.jpg/1280px-Thala_Cauvery_%2818125847938%29.jpg',
    images: [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Thala_Cauvery_%2818125847938%29.jpg/1280px-Thala_Cauvery_%2818125847938%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/16/Thalakauvery-hillview-panorama.jpg/1280px-Thalakauvery-hillview-panorama.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Talacauvery_panorama.jpg/1280px-Talacauvery_panorama.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Talakaveri_temple_tank_01.jpg/1280px-Talakaveri_temple_tank_01.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Hills_surrounding_Thalakaveri.jpg/1280px-Hills_surrounding_Thalakaveri.jpg',
    ],
    description:
        'Sacred source shrine of the Kaveri on Brahmagiri at Talakaveri, '
        'centred on the Brahma Kundike spring and Kaveramma worship, with '
        'Agastheeshwara and Vinayaka shrines—pilgrimage and landscape '
        'sacredness more than a single-deity urban temple.',
    story:
        'Talakaveri (Talacauvery) on the Brahmagiri hills near Bhagamandala is '
        'traditionally held as the source of the river Kaveri, at about 1,276 m '
        'elevation near the Kerala border. Karnataka Tourism describes the holy '
        'Kundike (tank) and shrines of Goddess Kaveramma, Lord Agastheeshwara, '
        'and Lord Vinayaka.\n\n'
        'The sacred spring is called Brahma Kundike—linked in tradition to '
        'Brahma’s worship and the river’s birth—not a primary free-standing '
        'Brahma temple like Pushkar. Living devotion centres on Kaveramma '
        '(Devi) and the tirtha; Shiva (Agastheeshwara) and Ganesha shrines '
        'complete the cluster. Permanent surface flow from the kundike to the '
        'main rivercourse is not always visible except in monsoon, as '
        'geographic notes acknowledge.\n\n'
        'Tula Sankramana (usually mid-October) is the peak ritual moment when '
        'the spring is believed to gush, drawing huge Kodagu–Kaveri pilgrim '
        'crowds. Ordinary days are quieter landscape pilgrimage.\n\n'
        'Karnataka Tourism lists temple hours roughly 6:00 AM–6:00 PM and warns '
        'that Madikeri–Talacauvery roads can be difficult in heavy monsoon. '
        'Dress modestly at the Kundike.',
    location:
        'Talakaveri (Talacauvery), Brahmagiri Hills near Bhagamandala, Kodagu '
        '(Coorg) District, Karnataka 571247',
    timings:
        'Karnataka Tourism (confirm locally; seasonal/monsoon risk): temple '
        'usually open ~6:00 AM–6:00 PM. Some secondary apps list an afternoon '
        'break (~1:30–4:00 PM)—PROVISIONAL vs tourism’s continuous span. Tula '
        'Sankramana day overrides ordinary patterns with mass crowds. Re-check '
        'district/tourism advisories for road closures in heavy rain. Visitor '
        'tip: Primary living focus is Kaveramma / tirtha; Brahma Kundike is the '
        'Brahma-linked sacred spring. Monsoon road risk is real—tourism advises '
        'avoiding heavy-rain travel. Modest dress at the Kundike.',
    latitude: 12.3855,
    longitude: 75.4914,
    specialities: [
      'Traditional source of River Kaveri on Brahmagiri',
      'Brahma Kundike sacred spring (Brahma-linked tirtha, not Pushkar-style Brahma temple)',
      'Kaveramma + Agastheeshwara + Vinayaka shrine cluster',
      'Tula Sankramana peak pilgrimage (usually mid-October)',
      'Nearest airport: Mangaluru (IXE) / Bengaluru (BLR) via Madikeri',
      'Veg / pilgrim food: Bhagamandala–Madikeri vegetarian options (generic)',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  ANDHRA PRADESH
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 4 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders (same pattern as the
  // original sample). Commons photo_candidates are not Storage paths.
  // Sources and photo candidates: docs/andhra-pradesh-sample-research.md
  Temple(
    name: 'Tirumala Venkateswara Temple',
    state: 'Andhra Pradesh',
    city: 'Tirumala',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/tirumala-venkateswara-temple/800/600',
    description:
        'World-famous Divya Desam and Swayambhu Vishnu shrine of Venkateswara '
        '(Balaji/Srinivasa) on the seven peaks of Tirumala, administered by '
        'Tirumala Tirupati Devasthanams (TTD).',
    story:
        'The Venkateswara Temple crowns Venkatadri, the seventh of the '
        'Seshachalam (Tirumala) hills traditionally identified with the seven '
        'hoods of Adisesha. Pilgrims call the hill Kaliyuga Vaikuntha and the '
        'deity Kaliyuga Prathyaksha Daivam — Vishnu who remains on earth through '
        'the present age. The complex is one of the 108 Divya Desams glorified '
        'by the Alvars and one of the eight Vishnu Swayambhu '
        'kshetras.\n\nPuranic cycles explain the Lord’s presence here: after '
        'Lakshmi left Vaikuntha following sage Bhrigu’s insult, Vishnu sought '
        'Sheshachalam; another strand links Varaha’s rescue of the Earth to this '
        'Varaha Kshetra, with Bhuvaraha still worshipped on the northern bank of '
        'Swami Pushkarini before main-temple darshan. Historical endowments '
        'begin with Pallava queen Samavai (966 CE); Cholas, Pandyas, Reddis and '
        'especially the Vijayanagara emperors — notably Krishnadevaraya — '
        'expanded the Ananda Nilayam and its wealth. Ramanuja is credited with '
        'settling Vaikhanasa ritual order and installing Govindaraja in the town '
        'below.\n\nArchitecture follows Dravidian forms with concentric prakaras '
        '(Sampangi and Vimana pradakshinas), the Maha Dwaram, silver and gold '
        'vakilis, and the gold-plated Ananda Nilayam vimana over the standing '
        'Moolavirat. Vaikhanasa worship centres on the Pancha Berams (Dhruva, '
        'Bhoga, Ugra, Malayappa, Koluvu Srinivasa). Daily rhythm opens with '
        'Suprabhatam before dawn and closes with Ekanta Seva; weekly specials '
        'include Friday Abhishekam, Thursday Tiruppavada/Poolangi, and Wednesday '
        'Sahasra Kalasabhishekam.\n\nToday TTD manages vast pilgrim '
        'infrastructure — Vaikuntam queue complexes, free annaprasadam, tonsure '
        'halls, and slotted Sarva Darshan — for tens of thousands of visitors on '
        'ordinary days and far more during Srivari Brahmotsavam, Vaikunta '
        'Ekadasi and Rathasapthami. The GI-tagged Tirupati laddu remains the '
        'signature prasadam.',
    location: 'Tirumala, Tirupati district, Andhra Pradesh 517504',
    timings:
        'Official TTD weekday programme (tirumala.org Daily Sevas; subject to '
        'live day schedule): Suprabhatam typically 03:00–03:30; Thomala & '
        'Archana in early morning (often ekantam). Public Darshanam windows '
        'commonly Mon/Tue ~07:00–19:00 and 20:00–01:00; Wed ~09:30–19:00 and '
        '20:00–01:00; Thu ~08:00–19:00 then Poolangi darshan into night; Fri '
        '(Abhishekam morning) darshan often ~09:00–20:00 then evening slot; '
        'Sat–Sun ~07:30–19:00 and 20:00–01:00. Midday arjitha sevas '
        '(Kalyanotsavam, Brahmotsavam, Unjal) ~12:00–17:00; Sahasra '
        'Deepalankarana ~17:00–17:30; Ekanta Seva ~01:30 (earlier on some '
        'Fridays). Free Sarva Darshan via Vaikuntam Queue Complex — timings vary '
        'by crowd/festival. ALWAYS confirm the day’s programme on tirumala.org '
        'before travel; Brahmotsavam and Vaikunta Ekadasi override ordinary '
        'hours.',
    latitude: 13.68325,
    longitude: 79.347194,
    specialities: [
      '108 Divya Desam; Vishnu Swayambhu kshetra',
      'Ananda Nilayam gold vimana over Moolavirat',
      'Vaikhanasa Agama; Pancha Beram worship',
      'Srivari Brahmotsavam & Vaikunta Ekadasi',
      'GI-tagged Tirupati laddu prasadam',
      'Hair tonsure (mokku) and massive hundi tradition',
      'Bhuvaraha darshan custom before main shrine',
    ],
  ),

  Temple(
    name: 'Sri Mallikarjuna Swamy Temple',
    state: 'Andhra Pradesh',
    city: 'Srisailam',
    deity: 'Shiva',
    imageUrl:
        'https://picsum.photos/seed/sri-mallikarjuna-swamy-temple/800/600',
    description:
        'One of the twelve Jyotirlingas and a major Shakti Peetha, where Shiva '
        'as Mallikarjuna and Parvati as Bhramaramba are worshipped together in '
        'the Nallamala hills above the Krishna.',
    story:
        'Srisailam’s Sri Bhramaramba Mallikarjuna Swamy Devasthanam is rare in '
        'uniting a Jyotirlinga with a Shakta pitha in one complex. Shiva is '
        'worshipped as the Mallikarjuna linga — tradition links the name to '
        'jasmine (mallika) offerings — while Bhramaramba Devi represents the '
        'goddess associated with the fallen neck of Sati in Shakta geography. '
        'The site is also counted among the Paadal Petra Sthalams of Tamil '
        'Shaiva hymnists.\n\nLocal legend places Shiva and Parvati here in '
        'connection with Kartikeya’s departure after the divine marriages of '
        'Ganesha; the hill where the parents stayed became Srisailam. '
        'Inscriptional hints reach to Satavahana times; the Veerasiro mandapa '
        'and Pathalaganga steps are linked to the Reddi kings, with major '
        'Vijayanagara-era additions under Harihara I and later patrons. Tall '
        'prakara walls, multiple gopurams, and a richly pillared Mukha Mandapa '
        'frame the dual sanctums.\n\nPilgrims bathe at Pathalaganga (Krishna) '
        'via a long stair flight before linga darshan. Subsidiary traditions '
        'include Sahasra Linga and Pandava lingas, Shikhareswaram on the '
        'approach, and the forest setting of the Nagarjuna Sagar–Srisailam Tiger '
        'Reserve landscape. Maha Shivaratri and Karthika celebrations draw huge '
        'crowds to this remote hill shrine.\n\nAdministration is under Andhra '
        'Pradesh Endowments through Srisaila Devasthanam (official portal '
        'srisailadevasthanam.org), which publishes darshan and seva booking. '
        'Dress codes for sevas emphasise traditional Hindu attire.',
    location: 'Srisailam, Nandyal district, Andhra Pradesh 518101',
    timings:
        'Official Devasthanam FAQ: darshanam starts from 6:00 AM onwards '
        '(confirm live schedule on srisailadevasthanam.org). Widely published '
        'visitor guides list general darshan roughly 4:30 AM–1:00 PM and 6:00 '
        'PM–9:00 PM with afternoon alankara/ritual windows — treat secondary '
        'schedules as approximate; festival and Sparsha/Abhisheka days differ. '
        'Seeghra Darshan tickets are sold via the official site (commonly cited '
        '~₹150). Maha Shivaratri and Karthika override ordinary hours — check '
        'Endowments notices before travel.',
    latitude: 16.07417,
    longitude: 78.86806,
    specialities: [
      'One of 12 Jyotirlingas',
      'Bhramaramba Shakti Peetha in same complex',
      'Paadal Petra Sthalam',
      'Pathalaganga (Krishna) theertham stairs',
      'Vijayanagara / Reddi architectural layers',
      'Nallamala forest pilgrimage setting',
    ],
  ),

  Temple(
    name: 'Varaha Lakshmi Narasimha Temple',
    state: 'Andhra Pradesh',
    city: 'Visakhapatnam',
    deity: 'Vishnu',
    imageUrl:
        'https://picsum.photos/seed/varaha-lakshmi-narasimha-temple/800/600',
    description:
        'Hilltop Vaishnava temple of Varaha Narasimha (Appanna) at Simhachalam, '
        'Visakhapatnam — famed for year-round sandalwood covering of the '
        'moolavar and the annual Chandanotsavam Nijaroopa darshan on Akshaya '
        'Tritiya.',
    story:
        'Simhachalam (lion’s hill) houses Sri Varaha Lakshmi Narasimha, the '
        'combined Varaha–Narasimha form that local sthala purana ties to '
        'Prahlada’s rescue. Tradition holds Prahlada first built a shrine here; '
        'later Pururava rediscovered the buried murti and was instructed that '
        'the idol should remain coated in sandalwood paste all year except on '
        'Vaisakha Shukla Tritiya (Akshaya Tritiya), when devotees briefly see '
        'the original form.\n\nEpigraphy from Kulottunga I (1087 CE) onwards '
        'records Chola, Eastern Ganga, Reddi, Gajapati and Vijayanagara '
        'patronage. The present west-facing temple, consecrated under Eastern '
        'Ganga king Narasingha Deva I’s lineage in 1268 CE, blends Kalinga '
        'pidha-deula vimana with Dravidian and Chalukya elements — a '
        'fortress-like prakara, five-tier rajagopuram, and a 96-pillar Kalyana '
        'mandapa carved with thirty-two Narasimha forms.\n\nRamanuja’s visit is '
        'remembered in debates that affirmed Vaishnava identity even while the '
        'sandal-coated murti resembles a linga. Daily Pancharatra-style worship '
        'runs from early Suprabhata through Rajabhoga and evening sayana seva. '
        'Flagship festivals are Kalyanotsavam (Chaitra) and Chandanotsavam; '
        'Narasimha Jayanti, Navaratrotsava, Kamadahana and Giripradakshina also '
        'mark the calendar.\n\nThe complex is among Andhra’s highest-income '
        'temples after Tirumala, administered under AP Endowments with '
        'hereditary trusteeship links to the Vizianagaram Pusapati family. '
        'Approach options include the thousand-step Bhairava Dwaram path and '
        'motorable ghat roads.',
    location: 'Simhachalam, Visakhapatnam, Andhra Pradesh 530028',
    timings:
        'Sources differ — verify before travel. Incredible India lists visitor '
        'windows 07:00 AM–04:00 PM and 06:00 PM–09:00 PM. Recent Telugu press '
        'summaries of temple schedule cite Suprabhata Seva ~04:00–04:30; general '
        'darshan blocks ~06:30–11:30, 12:15–14:30, 15:00–19:00; ritual breaks '
        'for Rajabhogam; evening aradhana ~19:00–20:30 (paid); final darshan '
        '~20:30–21:00. Chandanotsavam (Akshaya Tritiya) opens Nijaroopa darshan '
        'from early morning with special abhishekas. Prefer aptemples.ap.gov.in '
        '/ Simhachalam Devasthanam notices over secondary blogs.',
    latitude: 17.7664,
    longitude: 83.2505,
    specialities: [
      'Year-round sandalwood (chandanam) covering of moolavar',
      'Nijaroopa darshan only on Akshaya Tritiya (Chandanotsavam)',
      'Eastern Ganga / Kalinga–Dravidian hybrid architecture (1268 CE)',
      '96-pillar Kalyana mandapa with 32 Narasimha forms',
      'Kalyanotsavam Brahmotsavam cycle',
      'Kappam Stambham (wish pillar) tradition',
    ],
  ),

  Temple(
    name: 'Kanaka Durga Temple',
    state: 'Andhra Pradesh',
    city: 'Vijayawada',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/kanaka-durga-temple/800/600',
    description:
        'Vijayawada’s guardian shrine of Kanaka Durga on Indrakeeladri above the '
        'Krishna, officially Sri Durga Malleswara Swamy Varla Devasthanam, famed '
        'for Dasara alankarams and riverbank pilgrim throngs.',
    story:
        'Kanaka Durga Temple crowns Indrakeeladri hill on the Krishna’s banks at '
        'the heart of Vijayawada. Tradition recalls sage Indrakila’s penance and '
        'the goddess’s victory over Mahishasura; the four-foot, eight-armed '
        'standing murti pierces the demon with her trident and is treated as a '
        'powerful swayambhu presence in local and Puranic references.\n\nThe '
        'complex also houses Malleswara Swamy (Shiva), Nataraja, and Subrahmanya '
        'with Valli–Devasena, making it a combined Shakta–Shaiva pilgrimage '
        'stop. Medieval inscriptions and later Endowments administration frame '
        'continuous worship; the official trust is Sri Durga Malleswara Swamy '
        'Varla Devasthanam (kanakadurgamma.org).\n\nDaily rhythm (per '
        'temple-related reporting) begins very early with Suprabhata Seva '
        '(introduced 2018), followed by abhishekam, khadgamala, '
        'vastram/alankaram, archana (Sahasranama/Ashtottara), and multiple '
        'naivedyam services with the principal noon offering. Periodical sevas '
        'include Pournami Maha Pooja, Saraswati Yagam, and Laksha '
        'Kumkumarchana.\n\nDasara/Navaratri is the great public festival: ten '
        'sequential alankarams of the goddess (from Swarna Kavachalankrita Durga '
        'through Rajarajeswari), Chandi homam, processions, and Teppotsavam on '
        'the Krishna. Sravana Fridays (Varalakshmi) and Sakambhari in Ashadha '
        'also draw large crowds who often bathe in the river before ascent.',
    location: 'Indrakeeladri, Vijayawada, NTR district, Andhra Pradesh 520001',
    timings:
        'Official site (kanakadurgamma.org) lists sevas but not a full clock on '
        'the homepage — confirm helpline 1800-425-0999 / (0866) 2423500. '
        'Commonly published darshan windows: morning ~06:00 AM–03:30 PM and '
        'evening ~06:00 PM–10:00 PM (temple activity from ~04:00 AM; afternoon '
        'ritual closure). Named daily markers reported by seva guides: '
        'Suprabhata ~03:00 AM; abhishekam/archana morning; main naivedyam ~12:15 '
        'PM. Dasara and eclipse days change hours — verify on the Devasthanam '
        'site or AP TMS before travel.',
    latitude: 16.519028,
    longitude: 80.621494,
    specialities: [
      'Indrakeeladri hill shrine above Krishna River',
      'Eight-armed Mahishasuramardini murti',
      'Companion Malleswara Swamy shrine',
      'Dasara ten-day alankaram cycle & Teppotsavam',
      'Sravana Varalakshmi Fridays',
      'Sakambhari festival (Ashadha)',
    ],
  ),

  Temple(
    name: 'Satyanarayana Swamy Temple',
    state: 'Andhra Pradesh',
    city: 'Annavaram',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/satyanarayana-swamy-temple/800/600',
    description:
        'Major Vaishnava hill temple of Sri Veera Venkata Satyanarayana Swamy on '
        'Ratnagiri, renowned statewide for continuous Satyanarayana Vratham and '
        'a chariot-shaped sanctum uniting Trimurti symbolism.',
    story:
        'Annavaram’s temple on Ratnagiri Hill is dedicated to Veera Venkata '
        'Satyanarayana, a form of Vishnu widely approached through the '
        'Satyanarayana Vratham for prosperity and household well-being. Sthala '
        'tradition links the hill to Ratnakara, son of Meru, whose penance '
        'brought Vishnu to dwell here as Satyanarayana — paralleling '
        'Bhadrachalam’s Bhadra legend.\n\nConsecration is dated to 6 August 1891 '
        'after a shared vision of local devotee Eeranki Prakasa Rao and the then '
        'zamindar; the murti was found under a Krishna Kutaja tree and installed '
        'with a Maha Narayana yantra brought from Kashi. The present stone '
        'complex (major rebuild 1933–34) is conceived as a chariot with four '
        'wheels, gold-plated main entrance, and a distinctive cylindrical murti '
        'expressing Brahma–Shiva–Vishnu unity across tiers, with Anantha Lakshmi '
        'and Shiva on the upper level.\n\nGround-floor panchayatana arrangements '
        'and extensive vratham mandapas support thousands of daily pilgrims. The '
        'shrine ranks among Andhra’s wealthiest Endowments temples after '
        'Tirumala. Festivals include the Lord’s Jayanti in Sravana, Krishna '
        'Janmashtami, Navaratri, Giripradakshinam on Karthika Purnima, and '
        'Telugu New Year observances.\n\nAccess is via NH16 corridor between '
        'Visakhapatnam and Rajahmundry/Kakinada, with ghat road and pedestrian '
        'path to the hilltop; Annavaram railway station lies a few kilometres '
        'away.',
    location:
        'Ratnagiri Hill, Annavaram, Kakinada district, Andhra Pradesh 533406',
    timings:
        'Official Devasthanam darshan page (annavaramdevasthanam.nic.in): Sarva '
        'Darshan free typically 06:00 AM–12:30 PM and 01:00 PM–09:00 PM; Seegra '
        'Darshan in the same windows. Temple ritual day commonly begins with '
        'early Suprabhata (guides cite ~03:30 AM) and closes ~09:00 PM. '
        'Satyanarayana Vratham generally offered through the day (often cited '
        '~06:00 AM–06:00 PM) — confirm seva slots on the official site. Festival '
        'days alter queues and hours.',
    latitude: 17.299972,
    longitude: 82.402389,
    specialities: [
      'Statewide centre for Satyanarayana Vratham',
      'Chariot-form sanctum with four symbolic wheels',
      'Trimurti-unified cylindrical moolavar',
      'Ratnagiri hill / Pampa river setting',
      'Among AP’s highest-revenue Endowments temples',
      'Gold-plated main entrance',
    ],
  ),

  Temple(
    name: 'Veerabhadra Temple',
    state: 'Andhra Pradesh',
    city: 'Lepakshi',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/veerabhadra-temple/800/600',
    description:
        'ASI-protected 16th-century Vijayanagara masterpiece for Veerabhadra '
        '(fierce Shiva), celebrated for hanging pillar, ceiling frescoes, '
        'Nagalinga, and the nearby colossal monolithic Nandi; UNESCO Tentative '
        'List.',
    story:
        'Lepakshi’s Sri Veerabhadra Temple stands on Kurma Saila '
        '(tortoise-shaped granite outcrop) in Sri Sathya Sai district. Built '
        'around 1530 CE by brothers Virupanna and Viranna, officers under '
        'Achyuta Deva Raya of Vijayanagara, it is a centrally protected monument '
        'and figures on UNESCO’s Tentative List for Vijayanagara sculpture and '
        'painting traditions.\n\nThe layout comprises mukha/natya mandapa, ardha '
        'mandapa, and garbhagriha housing a near life-size armed Veerabhadra. '
        'Ceilings carry some of the finest surviving Vijayanagara murals — '
        'Ramayana, Mahabharata and Puranic cycles, court costume studies, and a '
        'colossal Veerabhadra fresco often cited among Asia’s largest '
        'single-figure temple paintings. Pillars teem with dancers, musicians, '
        'and Maheshamurti forms.\n\nVisitor icons include the ‘hanging pillar’ '
        'of the natya mandapa (a slight gap under the base through which cloth '
        'can pass), the seven-hooded Nagalinga carved from living rock, a giant '
        'footprint folklore attributes to Sita or Hanuman, and — about 200 m '
        'away — one of India’s largest monolithic Nandis (~15–20 ft high, ~27–30 '
        'ft long) facing the serpent-linga.\n\nRamayana folklore derives the '
        'place-name from Rama’s ‘Le Pakshi’ address to the fallen Jatayu. As a '
        'living ASI monument, it balances heritage conservation with worship; '
        'Incredible India lists ordinary visiting hours 06:00 AM–06:00 PM.',
    location: 'Lepakshi, Sri Sathya Sai district, Andhra Pradesh 515331',
    timings:
        'Incredible India (official tourism): opening 06:00 AM, closing 06:00 '
        'PM. Some secondary guides mention split ritual windows — prefer the '
        'Incredible India / on-site ASI board. Photography rules and restricted '
        'zones inside may apply; festival days (incl. local Lepakshi Utsavam, '
        'often around March) can extend activity. Confirm locally for abhisheka '
        'participation.',
    latitude: 13.801844,
    longitude: 77.609547,
    specialities: [
      'Vijayanagara fresco cycle (Tentative UNESCO WH)',
      'Famous hanging pillar in natya mandapa',
      'Monolithic Nandi among India’s largest',
      'Seven-hooded Nagalinga boulder sculpture',
      'ASI centrally protected monument',
      'Veerabhadra fierce form of Shiva',
    ],
  ),

  Temple(
    name: 'Ahobilam Narasimha Temples',
    state: 'Andhra Pradesh',
    city: 'Ahobilam',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/ahobilam-narasimha-temples/800/600',
    description:
        'Nava Narasimha pilgrimage in the Eastern Ghats — nine shrines of '
        'Narasimha across Lower and Upper Ahobilam, sacred to Sri Vaishnava '
        'tradition and the Ahobila Matha.',
    story:
        'Ahobilam (also Nava Narasimha Kshetra) spreads across forested hills of '
        'the Eastern Ghats in Nandyal district. Tradition identifies this '
        'landscape with the pillar from which Narasimha emerged to save Prahlada '
        'and slay Hiranyakashipu; nine distinct forms — including Ugra, Jwala, '
        'Malola, Krodha, Yogananda, Bhavana, Bhargava, Chatravata and Prahlada '
        'Varada / Lakshmi Narasimha — are worshipped between Lower Ahobilam '
        '(foothill complex) and Upper Ahobilam (steep shrine approaches).\n\nThe '
        'site is central to the Ahobila Matha (Ahobila Mutt) Sri Vaishnava '
        'lineage, whose jeeyars historically stewarded ritual and pilgrimage '
        'culture here. Lower Ahobilam’s Prahlada Varada Lakshmi Narasimha temple '
        'serves as the primary accessible hub; Upper Ahobilam and forest shrines '
        'require trekking, with seasonal restrictions for wildlife and '
        'safety.\n\nArchitecture mixes Vijayanagara and later phases with '
        'rock-cut and structural shrines set in gorges and hill terraces. Annual '
        'and monthly observances include Narasimha Jayanti and Thirumanjanam on '
        'Swathi nakshatra for the nine forms (per Matha guidance). The circuit '
        'is one of Andhra’s principal Narasimha pilgrimage belts alongside '
        'Simhachalam, Mangalagiri and Kadiri.\n\nEndowments e-services appear '
        'under AP TMS (tms.ap.gov.in/LNAHBM); combine with Ahobila Mutt visit '
        'guidance for trek logistics. Carry water, start early for Upper '
        'Ahobilam, and respect forest closing times.',
    location:
        'Ahobilam, Allagadda mandal, Nandyal district, Andhra Pradesh 518543',
    timings:
        'THIN OFFICIAL CLOCK: Secondary guides commonly list Lower Ahobilam '
        '~06:30 AM–01:00 PM and 03:00 PM–08:00 PM; Upper Ahobilam roughly 07:00 '
        'AM–01:00 PM and 02:00 PM–05:30/07:00 PM with earlier forest cutoffs. '
        'Daily markers often cited: Suprabhata ~06:00 AM; Ekantha ~20:00. '
        'Confirm on AP Endowments TMS (LNAHBM) and ahobilamutt.org before '
        'trekking — monsoon and wildlife notices can close upper paths.',
    latitude: 15.1333,
    longitude: 78.7167,
    specialities: [
      'Nava Narasimha (nine forms) circuit',
      'Ahobila Matha Sri Vaishnava centre',
      'Lower & Upper Ahobilam hill–forest pilgrimage',
      'Prahlada–Hiranyakashipu sthala association',
      'Swathi nakshatra Thirumanjanam tradition',
      'Eastern Ghats gorge setting',
    ],
  ),

  Temple(
    name: 'Padmavathi Temple',
    state: 'Andhra Pradesh',
    city: 'Tiruchanur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/padmavathi-temple/800/600',
    description:
        'TTD-administered temple of Goddess Padmavathi (Alamelu Manga), consort '
        'of Venkateswara, at Tiruchanur near Tirupati — traditional complement '
        'to a Tirumala pilgrimage.',
    story:
        'Sri Padmavathi Ammavari Temple at Tiruchanur (Alamelu Mangapuram) '
        'honours Padmavathi, the form of Lakshmi who, in Tirumala legend, '
        'reunites with Srinivasa after her earthly birth as a princess found in '
        'a ploughed field. Pilgrims commonly visit Tiruchanur before or after '
        'Tirumala darshan as the divine consort’s abode.\n\nThe shrine is '
        'managed by Tirumala Tirupati Devasthanams alongside the hill temple. '
        'Ritual life follows Sri Vaishnava / Shakta-Lakshmi worship patterns '
        'with daily sevas, Friday specials, and major utsavams including '
        'Padmavathi Parinayotsavam linked to the Venkateswara calendar. The '
        'Pushkarini and gopuram complex form a classic temple-town core a few '
        'kilometres from Tirupati city.\n\nTTD publishes arjitha seva '
        'information for Sri PAT (Padmavathi Ammavari Temple), including '
        'break/special darshan tickets. Fridays typically feature earlier '
        'opening and Abhishekam. Brahmotsavam-period and festival days '
        'significantly alter queues.\n\nTogether with Govindaraja (Tirupati), '
        'Kalyana Venkateswara (Srinivasa Mangapuram) and Kapila Theertham, '
        'Tiruchanur completes the classic foot-of-the-hill sacred geography for '
        'Venkateswara devotees.',
    location:
        'Tiruchanur (Tiruchanoor), Tirupati, Tirupati district, Andhra Pradesh '
        '517503',
    timings:
        'TTD-linked schedules (confirm on tirumala.org PAT pages before travel): '
        'regular-day darshan commonly cited in blocks ~05:25–06:30, '
        '~07:30–18:00, and ~19:00–20:45; Fridays often open ~03:30 with '
        'Abhishekam ~05:30–07:00 then darshan from ~08:00. Special/Break Darshan '
        '(Sri PAT) ticket windows are published by TTD (often morning, '
        'afternoon, evening slots; fee historically ~₹200 — verify current '
        'rate). Festival and Brahmotsavam days override ordinary hours.',
    latitude: 13.607806,
    longitude: 79.450111,
    specialities: [
      'Consort shrine of Tirumala Venkateswara (Alamelu Manga)',
      'Administered by TTD',
      'Padmavathi Parinayotsavam link to Tirumala calendar',
      'Friday Abhishekam prominence',
      'Essential Tirupati pilgrimage complement',
      'Temple pushkarini precinct',
    ],
  ),

  Temple(
    name: 'Varasidhi Vinayaka Temple',
    state: 'Andhra Pradesh',
    city: 'Kanipakam',
    deity: 'Ganesha',
    imageUrl: 'https://picsum.photos/seed/varasidhi-vinayaka-temple/800/600',
    description:
        'Famous swayambhu Sri Varasiddhi Vinayaka temple at Kanipakam near '
        'Chittoor, administered by AP Endowments, known for the self-manifested '
        'Ganesha murti and continuous abhisheka traditions.',
    story:
        'Kanipakam, about 11 km from Chittoor on the Irala road, hosts Swayambhu '
        'Sri Varasiddhi Vinayaka Swamy Vari Devasthanam. The swayambhu '
        '(self-manifested) Vinayaka is the focus of intense regional devotion; '
        'local legend narrates discovery of the murti in a well/tank when '
        'villagers digging for water found blood in the soil and unearthed the '
        'growing deity — folklore still claims the murti continues to '
        'grow.\n\nThe temple developed under successive South Indian patrons '
        'into a major Endowments shrine with a tall gali gopuram, temple tank, '
        'and busy seva counters. It is a standard stop on Tirupati–Chittoor '
        'pilgrimage circuits and draws especially large crowds on Vinayaka '
        'Chaturthi and during the annual Brahmotsavam.\n\nWorship emphasises '
        'abhishekam, modaka naivedyam, and special archanas. The official '
        'Devasthanam portal (srikanipakadevasthanam.org / kanipakam.com heritage '
        'URLs) handles darshan and seva information under Andhra Pradesh '
        'Endowments.\n\nArchitecture presents a classic Dravidian urban–village '
        'temple profile with painted gopuram tiers visible across the tank '
        'precinct — a favourite subject for pilgrim photography.',
    location:
        'Kanipakam, Irala mandal, Chittoor district, Andhra Pradesh 517128',
    timings:
        'Official Devasthanam materials emphasise early Suprabhatam (~04:00 AM '
        'cited in visitor guides) with Sarva Darshan through morning and '
        'afternoon windows and evening darshan into ~09:00 PM; exact slot tables '
        'vary by source. Book/confirm on srikanipakadevasthanam.org (sevas & '
        'darshanam). Vinayaka Chaturthi and Brahmotsavam heavily alter hours and '
        'crowd management — use Endowments notices.',
    latitude: 13.217096,
    longitude: 79.100677,
    specialities: [
      'Swayambhu Varasiddhi Vinayaka murti',
      'Growing-idol folklore tied to well discovery legend',
      'Major Chittoor–Tirupati circuit stop',
      'Vinayaka Chaturthi & Brahmotsavam crowds',
      'Temple tank and gali gopuram skyline',
      'AP Endowments–administered Devasthanam',
    ],
  ),

  Temple(
    name: 'Yaganti Uma Maheswara Temple',
    state: 'Andhra Pradesh',
    city: 'Yaganti',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/yaganti-uma-maheswara-temple/800/600',
    description:
        'Cave-associated Shaiva temple of Uma Maheswara in the Erramala hills, '
        'famed for the ‘growing’ Nandi (Basavanna) and Agastya–Veerabrahmendra '
        'folklore.',
    story:
        'Yaganti’s Uma Maheswara Temple nestles against rocky cliffs of the '
        'Erramala range in Nandyal district. The sanctum venerates Shiva and '
        'Parvati together (Uma Maheswara); the complex includes cave shrines, a '
        'pushkarini, tall stambha, and the celebrated monolithic Nandi in the '
        'courtyard.\n\nPopular belief holds that the Nandi is slowly growing — '
        'devotees and local guides often quote roughly an inch every twenty '
        'years, sometimes linking the claim to mineral expansion of the stone. '
        'Treat the growth story as living folklore rather than surveyed '
        'metrology. Another strand of tradition associates the site with sage '
        'Agastya and with prophecies of Sri Potuluri Veerabrahmendra Swamy '
        'regarding the Nandi and the end of Kali Yuga.\n\nHistorically the '
        'temple shows Vijayanagara-period patronage layers within a dramatic '
        'natural amphitheatre of caves and cliffs. Pilgrims combine darshan with '
        'visits to nearby caves (including the Agastya cave tradition) and the '
        'temple tank. Maha Shivaratri is the principal festival '
        'surge.\n\nCompared with Tirumala or Srisailam, published Endowments '
        'timetable detail is thinner; tourism listings converge on morning and '
        'evening darshan with a midday break.',
    location:
        'Yaganti, Banaganapalle area, Nandyal district, Andhra Pradesh 518124',
    timings:
        'THIN PRIMARY SOURCES: Visitor guides commonly list ~06:00 AM–01:00 PM '
        'and ~03:00 PM–08:00 PM (some variants 07:00–11:00 and 17:00–20:00). '
        'Confirm on arrival / local Endowments noticeboards — no richly detailed '
        'official clock found in this research pass. Shivaratri and festival '
        'days extend hours.',
    latitude: 15.350833,
    longitude: 78.139444,
    specialities: [
      'Uma Maheswara (Shiva–Parvati) dual sanctum',
      'Famous ‘growing’ Nandi folklore',
      'Cave shrines in Erramala cliffs',
      'Agastya / Veerabrahmendra associations',
      'Vijayanagara-period architectural layer',
      'Pushkarini and stambha precinct',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  TELANGANA
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 5 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders (same pattern as the
  // original sample). Commons photo_candidates are not Storage paths.
  // Sources and photo candidates: docs/telangana-sample-research.md
  Temple(
    name: 'Sri Lakshmi Narasimha Swamy Temple',
    state: 'Telangana',
    city: 'Yadagirigutta',
    deity: 'Vishnu',
    imageUrl:
        'https://picsum.photos/seed/sri-lakshmi-narasimha-swamy-temple/800/600',
    description:
        'Major Narasimha pilgrimage on a hillock ~60–70 km from Hyderabad, '
        'popularly called Yadadri / Pancha Narasimha Kshetram, recently rebuilt '
        'as a large state-backed temple complex and often nicknamed the '
        '“Tirupati of Telangana.”',
    story:
        'Sri Lakshmi Narasimha Swamy Temple crowns the Yadagirigutta hillock in '
        'Yadadri Bhuvanagiri district. Temple lore, linked in endowment accounts '
        'to the Skanda Purana, tells of sage Yadarishi (son of Rishyasringa) '
        'who, guided by Anjaneya, performed penance in a cave here. Lord '
        'Narasimha is said to have appeared in five forms — Jwala, Yogananda, '
        'Gandabherunda, Ugra, and Lakshmi Narasimha — making the site a Pancha '
        'Narasimha Kshetram; the hill took the sage’s name as Yadagiri / '
        'Yadagirigutta.\n\nFor centuries the cave shrine drew regional pilgrims; '
        'in the 2010s–2020s the Telangana government undertook a massive '
        'reconstruction and landscaping programme, rebranding the complex as '
        'Yadadri with new gopurams, pathways, and pilgrim facilities while '
        'retaining the ancient sanctum tradition. Average weekday footfall is '
        'commonly cited in the several-thousand range, with heavy crowding on '
        'Saturdays, Sundays, and public holidays.\n\nDaily worship follows a '
        'long Vaishnava sequence from pre-dawn Suprabhatam and Nijabhishekam '
        'through daytime darshan windows, Nitya Kalyanotsavam, Sudarshana '
        'Narasimha Homam, and evening Pavalimpu / Dwarabandhanam. Sevas and paid '
        'darshan slots are bookable on the official Telangana endowments '
        'portals. Major observances include Narasimha Jayanti, '
        'Brahmotsavam-period calendars published by the Devasthanam, and '
        'Tuesday-linked Hanuman / Rahu–Ketu sevas noted on official timing pages.',
    location: 'Yadagirigutta, Yadadri Bhuvanagiri District, Telangana 508115',
    timings:
        'Official Devasthanam schedule (confirm on '
        'yadagiriguttatemple.telangana.gov.in / yadadritemple.telangana.gov.in '
        'before travel — festival days override): Temple opens ~3:30 AM; '
        'Suprabhatam ~3:30–4:00 AM; Thiruvaradhana ~4:00–4:30 AM; Bala Bogam '
        '~4:30–5:15 AM; Nijabhishekam ~5:15–6:15 AM; Archana ~6:15–7:00 AM; '
        'general darshan commonly from ~7:00 AM with VIP / Seegra Break Darshan '
        'slots often listed ~9:00 AM and ~4:00 PM; Suvarna Pushparchana / '
        'Sudarshana Narasimha Homam mid-morning; Nitya Kalyanotsavam ~9:45–11:30 '
        'AM; Maharaja Bhogam around midday; Dwarabandanamu / break often '
        '~3:00–4:00 PM; evening darshan resumes then closes after Pavalimpu / '
        'Dwarabandhanam ~9:45 PM. Sources also list alternate historic endowment '
        'tables — treat times as approximate.',
    latitude: 17.5892,
    longitude: 78.9446,
    specialities: [
      'Pancha Narasimha Kshetram (five Narasimha forms)',
      'Yadarishi / Skanda Purana cave-origin legend',
      'Large post-2010s Yadadri state reconstruction complex',
      'Nitya Kalyanotsavam and Sudarshana Narasimha Homam',
      'Online darshan/seva booking via Telangana gov portals',
      'Heavy weekend pilgrim traffic from Hyderabad (~60–70 km)',
    ],
  ),

  Temple(
    name: 'Sita Ramachandra Swamy Temple',
    state: 'Telangana',
    city: 'Bhadrachalam',
    deity: 'Vishnu',
    imageUrl:
        'https://picsum.photos/seed/sita-ramachandra-swamy-temple/800/600',
    description:
        'Famous Rama temple on the Godavari at Bhadrachalam — often called '
        'Dakshina Ayodhya — known for Bhakta Ramadasu’s 17th-century building '
        'legend, Golconda Nawab Tanishah lore, and grand Sri Rama Navami '
        'kalyanam celebrations.',
    story:
        'Sree Seetha Ramachandra Swamy Devasthanam stands on the Godavari at '
        'Bhadrachalam in Bhadradri Kothagudem district. Pilgrim tradition '
        'identifies the hill with Bhadra (a devotee) and with episodes of the '
        'Ramayana, earning the town the popular title Dakshina Ayodhya.\n\nThe '
        'present temple’s historical memory centres on Kancherla Gopanna — '
        'Bhakta Ramadasu — a 17th-century tahsildar under the Golconda court who '
        'is said to have used revenue funds to build the shrine for Rama, Sita, '
        'and Lakshmana. Arrested by Nawab Abul Hasan Qutb Shah (Tanishah), '
        'Ramadasu was later released in the celebrated legend that Rama and '
        'Lakshmana repaid the gold; the Nawab’s gift of pearls remains part of '
        'festival memory. Carnatic kritis of Ramadasu still frame the temple’s '
        'musical identity.\n\nDaily worship follows Vaishnava sevas from '
        'Suprabhata through Sahasra Namarchana, Nitya Kalyanam, Raja Bhogam, '
        'Darbaru Seva, and evening Pavalimpu / Ekantha closing. Sri Rama Navami '
        '(Sita–Rama kalyanam), Brahmotsavam, and Vaikuntha Ekadashi draw the '
        'largest crowds. Official rooms, sevas, and notices are published on the '
        'Telangana endowments portal bhadradritemple.telangana.gov.in.',
    location: 'Bhadrachalam, Bhadradri Kothagudem District, Telangana 507111',
    timings:
        'Official Devasthanam list (bhadradritemple.telangana.gov.in/timings/ — '
        'confirm before travel; festival days shift): Temple opens ~4:30 AM '
        '(some secondary guides cite ~4:00 AM Sundays); Suprabhata Seva '
        '~4:30–5:00 AM; Balabogham / Nivedana / Sevakalam ~5:30–7:00 AM; Sahasra '
        'Namarchana ~8:30–9:30 AM; Archana to main deities windows commonly '
        'listed morning and again afternoon–evening; Nitya Kalyanam ~9:30–11:30 '
        'AM; Raja Bhogam ~11:30 AM–12:00 noon; midday sanctum closure often '
        '~1:00–3:00 PM (secondary sources vary 12:00–3:00 PM); evening darshan '
        'resumes ~3:00 PM; Darbaru Seva ~7:00–8:00 PM; Nivedana after Pavalimpu '
        '~8:30–9:00 PM; temple closes ~9:00–9:30 PM after Ekantha / Pavalimpu. '
        'Prefer official table over aggregator sites.',
    latitude: 17.6669,
    longitude: 80.8828,
    specialities: [
      'Bhakta Ramadasu / Golconda Tanishah building legend',
      'Godavari-bank Dakshina Ayodhya pilgrimage',
      'Sri Rama Navami Sita–Rama kalyanam',
      'Nitya Kalyanam and Darbaru Seva',
      'Ramadasu Carnatic kritis heritage',
      'Official Telangana Endowments online seva/accommodation',
    ],
  ),

  Temple(
    name: 'Thousand Pillar Temple',
    state: 'Telangana',
    city: 'Hanamkonda',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/thousand-pillar-temple/800/600',
    description:
        '12th-century Kakatiya Trikutalaya (Rudreswara) at Hanamkonda, famed for '
        'star-shaped planning, richly carved pillars, and a monolithic Nandi; '
        'maintained in ASI monument context and part of the broader Kakatiya '
        'temples UNESCO tentative grouping with Warangal Fort.',
    story:
        'The Thousand Pillar Temple — Rudreswara Swamy Temple, Telugu Veyyi '
        'Stambhala Gudi — stands in Hanamkonda near Warangal. Tradition and '
        'inscriptions associate its building with Kakatiya king Rudra Deva in '
        'the mid–late 12th century (commonly dated around 1163 CE), making it '
        'one of the earliest major Kakatiya stone temples visitors can still '
        'walk through.\n\nArchitecturally it is a star-shaped Trikutalaya with '
        'shrines for Shiva, Vishnu, and Surya under one composition, surrounded '
        'by a forest of sculpted pillars, perforated screens, rock-cut '
        'elephants, and a polished monolithic dolerite Nandi. Kakatiya sandbox '
        'foundations and lathe-turned polish techniques are often highlighted by '
        'ASI and tourism literature. The monument suffered medieval damage; '
        'later patronage (including a noted Nizam-era grant) and modern ASI '
        'conservation — including long-running work on the dance pavilion / '
        'portico — continue to stabilize the fabric.\n\nAs a living temple '
        'within a protected monument setting, daily worship is simpler than '
        'large Endowments pilgrimage sites; Maha Shivaratri and Kartika draw '
        'extra devotees. The site sits with Warangal Fort and Kakatiya Kala '
        'Thoranam on UNESCO’s “Glorious Kakatiya Temples and Gateways” tentative '
        'list (Ramappa alone later received full inscription).',
    location: 'Hanamkonda, Hanumakonda District, Telangana 506001',
    timings:
        'Visitor / monument hours commonly listed ~6:00 AM–6:00 PM or into early '
        'evening for the ASI precinct; living-temple pooja slots are shorter and '
        'posted locally — confirm on-site or via Hanumakonda district tourism '
        'notices. Festival evenings (esp. Maha Shivaratri) may extend access; '
        'photography rules follow ASI monument norms. Do not treat aggregator '
        '“darshan till 8 PM” claims as official without local confirmation.',
    latitude: 18.0037,
    longitude: 79.5748,
    specialities: [
      'Kakatiya Trikutalaya — Shiva, Vishnu, Surya',
      'Star-shaped plan and thousand carved pillars',
      'Monolithic polished dolerite Nandi',
      'ASI protected monument / conservation context',
      'UNESCO Kakatiya temples tentative-list companion site',
      'Sandbox foundation and lathe-turned sculpture craft',
    ],
  ),

  Temple(
    name: 'Ramappa Temple (Rudreshwara)',
    state: 'Telangana',
    city: 'Palampet',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ramappa-temple-rudreshwara/800/600',
    description:
        '13th-century Kakatiya Shiva temple at Palampet beside Ramappa Lake — '
        'uniquely named after sculptor Ramappa — inscribed as a UNESCO World '
        'Heritage Site in 2021 for its floating-brick vimana, sandbox '
        'foundations, and exceptional sculpture.',
    story:
        'Kakatiya Rudreshwara Temple, popularly Ramappa Temple, stands at '
        'Palampet in Mulugu district beside the Kakatiya-built Ramappa Cheruvu. '
        'An inscription dates construction to 1213 CE under general Recherla '
        'Rudra during the reign of Ganapati Deva; work is traditionally said to '
        'have spanned about forty years. The temple is rare in India for being '
        'known by its chief sculptor’s name rather than only the '
        'deity’s.\n\nUNESCO’s 2021 inscription (criteria i and iii) highlights '
        'the sandstone–granite–dolerite fabric, the pyramidal vimana of '
        'lightweight porous “floating bricks,” sandbox earthquake-resistant '
        'foundations, and sculptural programmes that record Kakatiya dance and '
        'court culture. Setting amid forested foothills and agricultural land '
        'follows dharmic ideals of temple-in-landscape. ASI has protected the '
        'monument since the early 20th century (Nizam-era conservation from 1914 '
        'is often noted).\n\nThough a World Heritage monument, Shiva worship as '
        'Ramalingeswara continues. Visitor experience is as much architectural '
        'pilgrimage as ritual; Maha Shivaratri and cooler months (October–March) '
        'are busiest. Confirm current ASI ticket / camera rules on arrival.',
    location: 'Palampet, Venkatapur Mandal, Mulugu District, Telangana 506345',
    timings:
        'Commonly open daily ~6:00 AM–6:00 PM for visitors/darshan (tourism and '
        'secondary guides; confirm ASI / Telangana Tourism notice on the day). '
        'Living pooja schedule is modest compared with large Endowments temples '
        'and is posted locally. Monument lighting/closing can shift seasonally; '
        'festivals may alter access. Prefer UNESCO / ASI / '
        'tourism.telangana.gov.in guidance over ticket-reseller blogs.',
    latitude: 18.2592,
    longitude: 79.9433,
    specialities: [
      'UNESCO World Heritage Site (inscribed 2021)',
      'Named after sculptor Ramappa — rare in India',
      'Floating-brick vimana and sandbox foundations',
      '1213 CE Kakatiya inscription / Recherla Rudra patronage',
      'Ramappa Lake (Cheruvu) landscape setting',
      'ASI-protected Kakatiya masterpiece',
    ],
  ),

  Temple(
    name: 'Gnana Saraswati Temple',
    state: 'Telangana',
    city: 'Basara',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/gnana-saraswati-temple/800/600',
    description:
        'Renowned Saraswati temple on the Godavari at Basara (Basar), one of the '
        'few major standalone Saraswati shrines in India, famous for children’s '
        'Akshara Abhyasam (initiation into letters) and for housing Saraswati '
        'with Lakshmi and Kali.',
    story:
        'Sri Gnana Saraswati Devasthanam sits on the Godavari at Basara in '
        'Nirmal district (historically associated with Adilabad region in older '
        'sources). Mythological accounts say sage Vyasa, seeking peace after the '
        'Mahabharata war, meditated on Kumaranchala and received the goddess’s '
        'presence; “Vasara” is said to have become Basara under Marathi '
        'influence. Endowment literature pairs Basara with Kashmir’s Sharada '
        'tradition as a premier Saraswati seat.\n\nHistorically, regional '
        'accounts credit a sixth-century Nanded-area ruler (Bijialudu / Bijjala) '
        'with building or patronage; idols were reportedly reinstated in the '
        '17th century after earlier damage. The sanctum places Saraswati with '
        'Lakshmi beside her, and a Mahakali shrine is closely associated, so '
        'devotees speak of a divine trinity abode. Nearby Datta / hill shrines '
        'form a short pilgrimage circuit.\n\nThe ritual that defines modern '
        'Basara is Akshara Abhyasam: children write first letters and offer '
        'books and stationery before schooling. Daily worship runs from pre-dawn '
        'Abhishekam and Alankarana through Sarva Darshan, Pradosha-linked '
        'evening rites, and Maha Harathi. Vasantha Panchami, Navaratri / Dasara, '
        'and Maha Shivaratri periods are especially busy.',
    location: 'Basara, Nirmal District, Telangana 504101',
    timings:
        'Telangana Endowments schedules (endowments.ts.nic.in / Basara content — '
        'confirm locally; festival days override). Representative table: '
        'Melukolupu / ticket issue ~4:00–4:30 AM; Ammavari Abhishekam ~4:30–5:30 '
        'AM; Alankarana / Harathi ~5:30–7:30 AM; Sarva Darshan & poojas ~7:30 '
        'AM–12:00/1:00 PM; midday Nivedana then Dwarabandham ~1:00–2:00 PM; '
        'afternoon darshan ~2:00–6:00 PM; Pradosha / evening pooja ~6:00–7:00 '
        'PM; Maha Harathi & tirtha ~7:00–8:30 PM; close ~8:30 PM. Akshara '
        'Abhyasam commonly listed ~7:30 AM–1:00 PM and ~2:00–6:00 PM; Nitya '
        'Chandi Yagam often ~9:00–11:00 AM. Secondary sources vary slightly — '
        'prefer temple office notice.',
    latitude: 18.8778,
    longitude: 77.9564,
    specialities: [
      'Major standalone Saraswati shrine on the Godavari',
      'Akshara Abhyasam children’s letter-initiation ritual',
      'Saraswati–Lakshmi–Kali trinity association',
      'Vyasa / Kumaranchala origin legend',
      'Vasantha Panchami and Navaratri peaks',
      'Telangana Endowments–administered Devasthanam',
    ],
  ),

  Temple(
    name: 'Chilkur Balaji Temple',
    state: 'Telangana',
    city: 'Chilkur',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/chilkur-balaji-temple/800/600',
    description:
        'Hyderabad-region Venkateswara temple near Osman Sagar, nicknamed Visa '
        'Balaji for the popular 11-then-108 pradakshina vow, notable for '
        'no-hundi / no-VIP darshan policy and independent temple administration '
        'culture.',
    story:
        'Chilkur Balaji Temple (Chilkoor) sits near Osman Sagar in Ranga Reddy '
        'district on Hyderabad’s western fringe. Tradition places its origins '
        'several centuries back, often linking construction or patronage to the '
        'era of Akkanna and Madanna (uncles of Bhakta Ramadasu). The deity is '
        'Venkateswara (Balaji), worshipped in a compact Dravidian shrine whose '
        'gopuram is a familiar Hyderabad pilgrimage landmark.\n\nThe temple’s '
        'modern fame rests on egalitarian practice and a distinctive vow: '
        'devotees commonly perform 11 pradakshinas while making a wish; after '
        'fulfilment they return for 108 circumambulations. Because many '
        'overseas-visa aspirants take this vow, media popularised the nickname '
        '“Visa Balaji,” though the temple itself frames the rite as general '
        'sankalpa fulfilment. Administration is known for refusing VIP queues '
        'and for not maintaining a monetary hundi — a stance often cited '
        'alongside only a few other Indian temples.\n\nAnnual Brahmotsavam draws '
        'heavy suburban traffic; Varuna Japam for rain has been performed at '
        'nearby Gandipet Lake by temple priests. Confirm dress-code and '
        'pradakshina path etiquette on the temple’s notice boards / '
        'chilkurbalaji.com.',
    location:
        'Chilkur Village, near Osman Sagar / Gandipet, Ranga Reddy District, '
        'Telangana 500075',
    timings:
        'Widely published visitor envelope (confirm on temple notice / '
        'chilkurbalaji.com — not a large Endowments e-portal like Yadadri): '
        'typically ~6:00 AM–1:00 PM and ~4:00 PM–8:00 PM; midday closed '
        '~1:00–4:00 PM; Sundays often extend evening darshan toward ~9:00 PM. '
        'Some guides note premises access from ~4:00–5:00 AM for early devotees. '
        'Brahmotsavam and eclipse-day closures can override ordinary hours. '
        'Named arjitha sevas are limited compared with TTD-style temples; free '
        'darshan culture is part of the temple’s identity.',
    latitude: 17.3583,
    longitude: 78.2986,
    specialities: [
      'Visa Balaji — 11 then 108 pradakshina vow',
      'No hundi and no VIP darshan policy',
      'Venkateswara shrine near Osman Sagar / Gandipet',
      'Akkanna–Madanna era traditional association',
      'Annual Brahmotsavam pilgrim surge',
      'Independent administrative culture in Hyderabad region',
    ],
  ),

  Temple(
    name: 'Keesaragutta Temple',
    state: 'Telangana',
    city: 'Keesara',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/keesaragutta-temple/800/600',
    description:
        'Hill Shiva temple (Ramalingeswara) about 30 km from Hyderabad, tied to '
        'a Rama–Hanuman linga legend, early Telugu inscriptions, and '
        'Vishnukundina-era archaeology including Jain Tirthankara finds.',
    story:
        'Keesaragutta Temple (Sri Ramalingeswara Swamy) crowns a rocky hillock '
        'at Keesara in Medchal–Malkajgiri district, roughly 30 km from central '
        'Hyderabad and near ECIL. Legend holds that Rama chose this valley to '
        'install a Shiva linga after the war with Ravana; when Hanuman was '
        'delayed bringing a linga from Kashi, Shiva himself appeared and gave a '
        'swayambhu linga. Hanuman later scattered 101 lingas across the hill — '
        'still pointed out to pilgrims — and Rama named the hill Kesarigiri '
        'after Hanuman (son of Kesari), which colloquially became Keesara / '
        'Keesaragutta. Ritual precedence for Hanuman is part of the founding '
        'command in local tradition.\n\nArchaeology adds depth: rock-cut caves '
        'carry an early Telugu label inscription (often read Thalachuvanru / '
        'related forms), dated paleographically to about the 4th–5th century CE '
        'and cited as among the earliest Telugu words from Telangana. '
        'Excavations have revealed Chalukyan / Vishnukundina-period ruins, '
        'cisterns, and, in 2014, Jain Tirthankara idols near the steps — '
        'evidence of a multi-religious hillscape.\n\nMaha Shivaratri and Kartika '
        'draw several-lakh-scale crowds in temple publicity. The Devasthanam '
        'publishes seva information on keesaragutta.telangana.gov.in.',
    location:
        'Keesaragutta, Keesara, Medchal–Malkajgiri District, Telangana 501301',
    timings:
        'Common published schedule (confirm on keesaragutta.telangana.gov.in / '
        'notice board): opens ~6:00 AM; Suprabhata ~6:00–6:30 AM; Mahanyasa '
        'Poorvaka Rudrabhishekam ~6:30–7:30 AM; Maha Harathi ~7:45 AM; morning '
        'darshan / abhishekam window ~6:30 AM–12:45 PM; closed ~12:45–3:00 PM; '
        'evening darshan / archana / abhishekam ~3:00–7:00 PM; Nivedana / '
        'Harathi / Mantra Pushpam ~7:00–7:20 PM; Pavalimpu ~7:20–7:30 PM; closes '
        '~7:30 PM. Weekends, Kartika, and Maha Shivaratri override ordinary '
        'hours. Secondary guides disagree on exact abhishekam ticket prices — '
        'verify on official site.',
    latitude: 17.5285,
    longitude: 78.6851,
    specialities: [
      'Ramalingeswara swayambhu linga legend (Rama–Hanuman)',
      'Scattered hill lingas attributed to Hanuman’s 101',
      'Early Telugu cave inscription (~4th–5th century)',
      'Vishnukundina / Jain archaeological finds on the hill',
      'Major Hyderabad-region Maha Shivaratri crowd',
      'Official Telangana Devasthanam portal',
    ],
  ),

  Temple(
    name: 'Bhadrakali Temple',
    state: 'Telangana',
    city: 'Warangal',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/bhadrakali-temple/800/600',
    description:
        'Historic goddess temple beside Bhadrakali Cheruvu between Hanamkonda '
        'and Warangal, traditionally linked to Chalukya Pulakeshin II–era '
        'origins and later Kakatiya royal patronage as a guardian deity of the '
        'Warangal region.',
    story:
        'Bhadrakali Temple overlooks the large Bhadrakali Lake on the '
        'Hanamkonda–Warangal stretch. Tradition dates a shrine here to the early '
        '7th century under Chalukya king Pulakeshin II (often cited as c. 625 '
        'CE), with the fierce form of Kali / Bhadrakali as the protective mother '
        'of the region. Kakatiya rulers later elevated the goddess in royal '
        'ritual imagination; the lake-and-temple pair remains one of Warangal’s '
        'defining sacred landscapes.\n\nThe present complex mixes historic '
        'fabric with later renovations and a prominent gopuram visible across '
        'the water. Devotees combine lake-side circumambulation or views with '
        'garbha-griha darshan. Major festivals include Ashada Aashaadha / '
        'rainy-season goddess observances, Navaratri, and local jataras '
        'announced by temple administration.\n\nAs a city temple, timings are '
        'more compact than overnight Endowments mega-shrines; confirm festival '
        'extensions locally. Pairing a visit with Thousand Pillar Temple and '
        'Warangal Fort is a common heritage circuit.',
    location:
        'Bhadrakali Temple Road, beside Bhadrakali Lake, Warangal / Hanamkonda, '
        'Telangana 506002',
    timings:
        'Secondary visitor guides commonly list ~5:30/6:00 AM–1:00 PM and '
        '~3:00–8:00/8:30 PM (exact opening varies by source). Midday break is '
        'usual. Festival evenings (Navaratri, major Ammavari days) often extend '
        'hours — confirm on the temple notice board or Warangal district tourism '
        'pages. Treat aggregator minutes as approximate; no single dominant '
        'e-portal schedule was relied on for this batch.',
    latitude: 17.9951,
    longitude: 79.5823,
    specialities: [
      'Lakeside Bhadrakali Cheruvu setting',
      'Traditional Chalukya-era founding association (~7th century)',
      'Kakatiya regional guardian-goddess heritage',
      'Navaratri and local goddess festival calendar',
      'Warangal–Hanamkonda heritage circuit stop',
      'Prominent gopuram skyline across the lake',
    ],
  ),

  Temple(
    name: 'Jogulamba Temple',
    state: 'Telangana',
    city: 'Alampur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/jogulamba-temple/800/600',
    description:
        'Shakti Peetha of Goddess Jogulamba at Alampur on the Tungabhadra, '
        'paired with Balabrahmeshwara and the nearby Chalukyan Navabrahma temple '
        'group; historically on the AP–Telangana border zone but administered in '
        'Telangana’s Jogulamba Gadwal district today.',
    story:
        'Jogulamba Temple stands at Alampur where the Tungabhadra approaches its '
        'confluence zone with the Krishna — a landscape long called a western '
        'gateway to Srisailam and Dakshina Kailasam. Goddess Jogulamba (Yogula '
        'Amma — Mother of Yogis) is counted among the Shakti Peethas (district '
        'and temple literature often call her the 5th among 18). Iconography '
        'shows a fierce yogic form seated with scorpion, frog, and lizard motifs '
        'in traditional descriptions.\n\nThe wider Alampur sacred complex is '
        'inseparable from the 7th–8th-century Badami Chalukya Navabrahma temples '
        '(ASI-protected brick-and-stone shrines to forms of Shiva such as Bala '
        'Brahma, Swarga Brahma, and others) and the Balabrahmeshwara shrine '
        'paired with Jogulamba. Medieval legend speaks of Rasa Siddha and '
        'tantric rasa alchemy tied to these lingas. The Jogulamba sanctum itself '
        'was rebuilt in the modern period (commonly noted as reconsecrated in '
        '2005 after earlier destruction), restoring living Peetha worship beside '
        'the older Chalukya monuments.\n\nAdministration and district branding '
        'place Alampur firmly in Telangana (Jogulamba Gadwal district) even '
        'though older maps and travel writing sometimes filed it under undivided '
        'Andhra / Kurnool-side circuits — CMS should use city Alampur, state '
        'Telangana as currently administered.',
    location: 'Alampur, Jogulamba Gadwal District, Telangana 509152',
    timings:
        'Jogulamba Gadwal district tourism page: all days 7:00 AM–1:00 PM and '
        '2:00 PM–8:30 PM (confirm locally; Navaratri and Peetha festival days '
        'may extend). Navabrahma ASI monuments follow separate monument visiting '
        'norms and may close earlier. Prefer gadwal.telangana.gov.in notices '
        'over third-party blogs.',
    latitude: 15.877,
    longitude: 78.1346,
    specialities: [
      'Shakti Peetha — Jogulamba (Yogula Amma)',
      'Paired Balabrahmeshwara worship',
      'Adjacent Chalukya Navabrahma temple group',
      'Tungabhadra / Dakshina Kailasam landscape',
      'Western gateway to Srisailam pilgrimage tradition',
      'Modern temple rebuild (living Peetha) beside ASI monuments',
    ],
  ),

  Temple(
    name: 'Kaleshwara Mukteswara Temple',
    state: 'Telangana',
    city: 'Kaleshwaram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/kaleshwara-mukteswara-temple/800/600',
    description:
        'Ancient Shiva temple at the Godavari–Pranahita confluence (Dakshina '
        'Triveni Sangamam), unique for twin lingas of Shiva and Yama on one '
        'pedestal, counted among Trilinga Desham shrines and now also known for '
        'the nearby Kaleshwaram irrigation project landscape.',
    story:
        'Kaleshwara Mukteswara (Mukteeshwara) Swamy Temple stands at Kaleshwaram '
        'in Jayashankar Bhupalpally district where the Godavari meets the '
        'Pranahita — popularly praised as Dakshina Triveni Sangamam. The '
        'sanctum’s distinctive feature is two lingas on a single pedestal, '
        'worshipped as Kaleshwara (linked with Yama / Kala) and Mukteswara '
        '(Shiva); together they give the deity its double name.\n\nRegional '
        'Shaiva geography numbers Kaleshwaram among the Trilinga Desham — the '
        '“land of three lingas” that culturally framed Telugu Shaivism alongside '
        'other great Shiva seats. Pilgrims traditionally bathe at the sangam, '
        'visit Ganesha, then offer respects to Yama before Shiva. Kartika month '
        'holy baths and Maha Shivaratri abhishekams are the peak festivals. Folk '
        'practice also treats the kshetra as a southern counterpart to Kashi for '
        'certain after-death rites (described in temple and tourism summaries — '
        'present as local belief, not a canonical pan-Hindu '
        'rule).\n\nContemporary visitors often combine the temple with views of '
        'the massive Kaleshwaram Lift Irrigation Project infrastructure that '
        'made the place nationally famous in the 2010s–2020s, but the shrine’s '
        'identity remains the twin-linga sangam temple.',
    location:
        'Kaleshwaram, Mahadevpur Mandal, Jayashankar Bhupalpally District, '
        'Telangana 505504',
    timings:
        'Wikipedia and secondary guides commonly cite roughly 6:30 AM–1:30 PM '
        'and 4:00–6:00 PM (some tourism pages imply longer day envelopes). Treat '
        'as approximate — confirm on temple notice board / district tourism '
        'before travel. Kartika holy-bath periods (often mid–late calendar '
        'Kartika / early December windows in older notices) and Maha Shivaratri '
        'significantly extend activity. Laksha Bilwapatri and special '
        'abhishekams may need advance Devasthanam permission per older published '
        'notes.',
    latitude: 18.8118,
    longitude: 79.904,
    specialities: [
      'Twin lingas — Shiva and Yama on one pedestal',
      'Godavari–Pranahita sangam (Dakshina Triveni)',
      'Trilinga Desham Shaiva geography',
      'Kartika month holy baths and Shivaratri peaks',
      'Sangam-bath then Ganesha–Yama–Shiva visit order',
      'Nearby Kaleshwaram Lift Irrigation Project landscape',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  GUJARAT
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 6 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders (same pattern as the
  // original sample). Commons photo_candidates are not Storage paths.
  // Sources and photo candidates: docs/gujarat-sample-research.md
  Temple(
    name: 'Somnath Temple',
    state: 'Gujarat',
    city: 'Somnath',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/somnath-temple/800/600',
    description:
        'First among the twelve Jyotirlingas, the seaside Shiva shrine of '
        'Somnath (Prabhas Patan near Veraval) stands on the Arabian Sea under '
        'the Shree Somnath Trust, with continuous daytime darshan and the Jay '
        'Somnath light-and-sound show.',
    story:
        'Somnath — also called Somanatha — is counted as the first of the twelve '
        'Jyotirlingas of Shiva. Classical and Puranic geography place the shrine '
        'at Prabhas on the Saurashtra coast, where the moon-god Soma is said to '
        'have regained his lustre after worshipping Shiva, giving the place its '
        'name.\n\nThe temple’s long history is marked by repeated destruction '
        'and rebuilding across medieval centuries; modern pilgrimage centres on '
        'the stone temple reconstructed after Independence and consecrated in '
        '1951 under the Shree Somnath Trust, with later '
        'Northern/Solanki-inspired elevation facing the sea. Nearby Prabhas '
        'sites — Triveni Sangam, Bhalka Tirth, and related tirthas — form a '
        'wider coastal circuit for many visitors.\n\nDaily worship follows a '
        'three-aarti rhythm published by the Trust; unlike many large temples '
        'there is no long midday closure for general darshan. Major throngs '
        'gather in Shravan, on Maha Shivaratri, Kartik Purnima fair days, and on '
        'Somnath Sthapana Divas. Electronics are barred inside the sanctum '
        'precinct; lockers and free shoe storage are provided.\n\nEvening '
        'visitors often combine Sandhya aarti with the coastal sunset and, '
        'outside the monsoon, the Jay Somnath sound-and-light presentation. '
        'Accessibility aids (wheelchairs, golf carts, lift) are noted on the '
        'Trust FAQ for elders and differently-abled pilgrims.',
    location:
        'Prabhas Patan, Somnath–Veraval, Gir Somnath district, Gujarat 362268',
    timings:
        'Official Shree Somnath Trust FAQ (somnath.org): darshan 6:00 AM–10:00 '
        'PM; aarti Morning 7:00 AM, Noon 12:00 PM, Evening 7:00 PM. Jay Somnath '
        'Light & Sound Show 8:00–9:00 PM except monsoon/rainy season. Entry '
        'free. Festival days (Shravan Mondays, Maha Shivaratri, Kartik Purnima) '
        'may alter queues and closing — confirm on somnath.org before travel.',
    latitude: 20.8878,
    longitude: 70.4014,
    specialities: [
      'First of the 12 Jyotirlingas',
      'Arabian Sea–facing reconstructed shrine (Trust-managed)',
      'Three daily aartis (7 AM / 12 PM / 7 PM)',
      'Jay Somnath light-and-sound show (non-monsoon)',
      'Prabhas / Triveni / Bhalka tirtha circuit nearby',
      'Continuous daytime darshan (no long midday closure)',
    ],
  ),

  Temple(
    name: 'Dwarkadhish Temple',
    state: 'Gujarat',
    city: 'Dwarka',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/dwarkadhish-temple/800/600',
    description:
        'Jagat Mandir of Dwarkadhish (Krishna as Lord of Dwarka), a Char Dham '
        'and major Vaishnava pilgrimage on the western tip of Saurashtra, with a '
        'royal day-schedule of mangala, shringar, rajbhog and shayan aartis.',
    story:
        'Dwarkadhish Temple — popularly Jagat Mandir — crowns the old town of '
        'Dwarka, traditionally identified with Krishna’s capital by the sea. The '
        'four-armed black-stone murti is worshipped as Dwarkadhish (King of '
        'Dwarka), a form of Vishnu/Krishna that draws Char Dham and pan-Indian '
        'Vaishnava pilgrims.\n\nArchitectural layers combine Chalukya / '
        'Māru-Gurjara idioms with later renovations; the tall shikhara and flag '
        '(dwaja) atop the sanctum are iconic. Epic and Puranic narrative place '
        'Krishna’s departure from Mathura–Vrindavan and founding of Dwarka here; '
        'nearby Beyt Dwarka, Rukmini Temple, and Gomti ghat complete a classic '
        'pilgrimage loop.\n\nDaily life inside the temple follows a courtly '
        'nityakram: Mangala aarti at opening, snan and shringar intervals, '
        'rajbhog, afternoon rest (anosar), evening uthapan, sandhya and shayan — '
        'with brief darshan closures during each bhog. Janmashtami is the '
        'greatest annual surge; Holi, Kartik and other Krishna festivals also '
        'reshape the clock.\n\nOfficial site dwarkadhish.org and Ministry of '
        'Tourism Utsav listings publish the morning/evening darshan windows; '
        'always refresh before travel because festival programmes override '
        'ordinary hours.',
    location: 'Dwarka, Devbhumi Dwarka district, Gujarat 361335',
    timings:
        'Widely published official/tourism windows (dwarkadhish.org / Utsav): '
        'Morning darshan ~6:30 AM–1:00 PM; Evening ~5:00 PM–9:30 PM; closed '
        '~1:00–5:00 PM for anosar. Named markers commonly cited: Mangala Aarti '
        '~6:30 AM; Shringar Aarti mid-morning; Sandhya Aarti ~7:30 PM; Shayan '
        'Aarti ~8:30 PM — with short closures for each bhog. Confirm live '
        'timetable on dwarkadhish.org; Janmashtami and special days change hours.',
    latitude: 22.2378,
    longitude: 68.9675,
    specialities: [
      'Char Dham / major Krishna–Vishnu kshetra',
      'Jagat Mandir shikhara and sacred flag',
      'Royal nityakram — mangala to shayan aartis',
      'Beyt Dwarka & Rukmini Temple circuit',
      'Janmashtami peak pilgrimage',
    ],
  ),

  Temple(
    name: 'Ambaji Temple',
    state: 'Gujarat',
    city: 'Ambaji',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/ambaji-temple/800/600',
    description:
        'Major Shakti Peetha of Arasuri Ambaji Mata in the Aravalli foothills of '
        'Banaskantha, famed for yantra worship (no conventional idol in the '
        'garbhagriha), Gabbar Hill, and the vast Bhadarvi Poonam fair.',
    story:
        'Ambaji (Arasuri Ambaji) is one of Gujarat’s three great Devi shrines '
        'and is widely counted among the Shakti Peethas. Tradition holds that '
        'Sati’s heart fell at Gabbar Hill; the main town temple and the Gabbar '
        'steps form a paired pilgrimage. The sanctum is distinctive for '
        'venerating the goddess primarily through a Shree Yantra rather than a '
        'figurative murti — a point emphasised by the managing trust.\n\nThe '
        'complex is administered by Shri Arasuri Ambaji Mata Devasthan Trust '
        '(ambajitemple.in), which publishes the day’s aarti and darshan board '
        'online. Gold-plated shikhar work and large-scale prasad distribution '
        '(notably mohanthal) mark modern pilgrimage infrastructure serving '
        'millions of annual visitors.\n\nBhadarvi Poonam (Bhadrapad full-moon '
        'fair) draws walking padyatris from across north Gujarat and beyond; '
        'Navaratri likewise extends hours and fills the town. Gabbar’s '
        'light-and-sound show has been temporarily suspended per trust notice — '
        'check the official site before planning an evening visit.\n\nNearby Abu '
        'Road (Rajasthan) is the usual railhead (~20 km); Ahmedabad is the '
        'principal airport (~185 km). Modest dress and gadget bans inside the '
        'temple are strictly enforced.',
    location: 'Ambaji, Danta taluka, Banaskantha district, Gujarat 385110',
    timings:
        'Trust posts a daily board on ambajitemple.in (example Mon 21 Sep 2026 '
        'IST: aarti 06:00–06:30; darshan 06:30–11:30; darshan 12:30–5:00 PM; '
        'evening aarti 07:00–07:30; further evening darshan thereafter). Typical '
        'secondary guides list ~7:00–11:30 AM, 12:30–4:30 PM, 6:30–9:00 PM with '
        'seasonal shifts. ALWAYS use the day’s official board; Navaratri and '
        'Bhadarvi Poonam override ordinary hours.',
    latitude: 24.3357,
    longitude: 72.8497,
    specialities: [
      'Shakti Peetha — Gabbar heart-of-Sati tradition',
      'Shree Yantra garbhagriha (no conventional idol)',
      'Bhadarvi Poonam mega-fair',
      'Gabbar Hill ~999 steps pilgrimage',
      'Mohanthal prasadam',
      'One of Gujarat’s principal Ambaji–Kalika–Bahucharaji Devi circuit',
    ],
  ),

  Temple(
    name: 'Kalika Mata Temple',
    state: 'Gujarat',
    city: 'Pavagadh',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/kalika-mata-temple/800/600',
    description:
        'Hilltop Mahakali / Kalika Mata Shakti Peetha on Pavagadh, a living '
        'shrine inside UNESCO’s Champaner-Pavagadh Archaeological Park, reached '
        'by steep climb or ropeway above the Champaner ruins.',
    story:
        'Kalika Mata (Mahakali) Temple crowns Pavagadh Hill (~800 m landscape '
        'prominence in UNESCO briefings), where the goddess is worshipped as '
        'guardian of the hill. Tradition identifies the site among the Shakti '
        'Peethas (toe of Sati in many popular accounts). The living shrine sits '
        'within Champaner-Pavagadh Archaeological Park, inscribed by UNESCO in '
        '2004 for its layered Hindu fort and pre-Mughal Islamic capital '
        'remains.\n\nPilgrims ascend by stone path or Usha Breco-type ropeway to '
        'a precinct that UNESCO and tourism sources describe as drawing large '
        'year-round crowds — especially Navaratri. Sanctum imagery commonly '
        'includes the red-painted mukhwato / yantra-centred Kalika form with '
        'attendant goddesses; Incredible India notes Mahakali, Kali, and '
        'Bahuchara associations in the complex.\n\nBelow the hill stretch '
        'Champaner mosques, stepwells, and fort walls of Sultan Mahmud Begada’s '
        'capital — a rare Hindu–Muslim architectural continuum. The hill shrine '
        'is managed by Shree Kalika Mataji Mandir Trust (pavagadhtemple.in), '
        'distinct from ASI-protected monuments in the park.\n\nCombine temple '
        'darshan with UNESCO circuit time; ropeway queues dominate festival '
        'weekends. Dress for heat and steep walking if not taking the cable car.',
    location: 'Pavagadh Hill summit, Panchmahal district, Gujarat 389360',
    timings:
        'Official Pavagadh Temple Trust site: temple open 6:00 AM–7:30 PM; '
        'Morning Aarti 6:00 AM; Evening Aarti 7:00 PM. Incredible India lists '
        '5:00 AM–7:00 PM for Mahakali Temple — note the conflict and confirm on '
        'arrival / pavagadhtemple.in. Navaratri typically extends hours '
        '(secondary schedules often ~4–5 AM to 8 PM). Ropeway hours are separate '
        '(commonly ~6 AM–6 PM) — check operator boards.',
    latitude: 22.4611,
    longitude: 73.5117,
    specialities: [
      'Shakti Peetha on Pavagadh summit',
      'Inside UNESCO Champaner-Pavagadh Archaeological Park (2004)',
      'Ropeway access + historic stair climb',
      'Navaratri mega-pilgrimage',
      'Living Hindu shrine amid Champaner Islamic heritage cityscape',
    ],
  ),

  Temple(
    name: 'Modhera Sun Temple',
    state: 'Gujarat',
    city: 'Modhera',
    deity: 'Surya',
    imageUrl: 'https://picsum.photos/seed/modhera-sun-temple/800/600',
    description:
        '11th-century Chaulukya (Solanki) masterpiece dedicated to Surya, '
        'preserved by ASI as a ticketed Monument of National Importance — '
        'celebrated for its sabha mandapa, gudha mandapa, and Suryakund, with no '
        'living temple pooja.',
    story:
        'The Sun Temple at Modhera on the Pushpavati was built in the 11th '
        'century under Bhima I (and associated Chaulukya patronage; ASI notes c. '
        '1026 CE). It is designed so that, by tradition, the equinox sunrise '
        'illuminates the sanctum — an astronomical claim repeated in ASI and '
        'tourism literature.\n\nThe complex has three celebrated components: the '
        'stepped Suryakund (Ramakund) with subsidiary shrines; the open pillared '
        'Sabhamandapa; and the Gudhamandapa leading to the now-empty '
        'garbhagriha. Intricate Māru-Gurjara carving covers pillars and walls '
        'with Adityas, dikpalas, and narrative friezes.\n\nUnlike living '
        'pilgrimage temples in this batch, Modhera is an ASI-protected heritage '
        'monument: no routine priestly darshan or aarti schedule. Visitors buy '
        'ASI tickets (Indians/SAARC/BIMSTEC and foreign rates differ; online '
        'booking via ASI portals). Gujarat Tourism lists morning-to-evening '
        'opening; ASI Must See pages commonly state 08:00–18:00 — confirm at '
        'ticket counter.\n\nEvening solar-powered projection / light shows are '
        'sometimes offered seasonally by tourism partners; treat show timings as '
        'separate from monument hours. Pair with nearby Patan Rani ki Vav '
        '(UNESCO) or Bahucharaji on the same north-Gujarat circuit.',
    location: 'Modhera, Mehsana district, Gujarat (Pushpavati riverbank)',
    timings:
        'ASI Must See (asimustsee.nic.in): Opening Hours 08:00 AM–06:00 PM. '
        'Gujarat Tourism page lists 07:00 AM–06:00 PM — note conflict; confirm '
        'at gate. Ticketed entry (ASI indicative rates: Indian/SAARC/BIMSTEC '
        '~₹25 cash / ₹20 online; other foreign ~₹300 / ₹250 online; facility '
        'ticket options exist). No living pooja/aarti schedule — heritage visit '
        'only. Equinox mornings are popular for the sun-ray lore.',
    latitude: 23.5838,
    longitude: 72.1327,
    specialities: [
      'ASI Monument of National Importance',
      'Chaulukya / Solanki Surya temple c. 1026 CE',
      'Suryakund + Sabhamandapa + Gudhamandapa ensemble',
      'Equinox sunrise–sanctum alignment lore',
      'Ticketed heritage site — no active daily pooja',
      'Intricate Māru-Gurjara sculpture programme',
    ],
  ),

  Temple(
    name: 'Bahucharaji Temple',
    state: 'Gujarat',
    city: 'Bahucharaji',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/bahucharaji-temple/800/600',
    description:
        'Major shrine of Bahuchara Mata at Becharaji in Mehsana district — a '
        'fertility and protection goddess with a rooster vahana, especially '
        'revered by women devotees and the hijra/transgender community, and one '
        'of Gujarat’s great Devi pilgrimage towns.',
    story:
        'Bahucharaji (Becharaji) centres on Bahuchara Mata, a Charan-associated '
        'goddess of chastity, fertility, and courage whose vahana is the '
        'rooster. The temple town in Mehsana district is a principal northern '
        'Gujarat Shakta destination alongside Ambaji and Pavagadh Kalika.\n\nThe '
        'complex traditionally comprises Adyasthan (original site), Madhyasthan, '
        'and the main shrine housing the deity. Pilgrims seek boons for family '
        'welfare and fertility; the site is also a longstanding spiritual focus '
        'for hijra and transgender devotees who regard Bahuchara as '
        'protector.\n\nGujarat Tourism describes the town as open for pilgrimage '
        'all day; detailed minute-level pooja clocks are thinner on official '
        'pages than for Somnath or Dakor. Navaratri is the peak festival season, '
        'with large crowds and occasional high-value offerings reported in '
        'press. State-backed redevelopment of the shikhar and precinct has been '
        'announced in recent years.\n\nLocate ~35 km from Mehsana and ~25 km '
        'from Modhera Sun Temple — a natural same-day pairing for north Gujarat '
        'itineraries.',
    location:
        'Becharaji (Bahucharaji), Mehsana district, Gujarat (Becharaji–Mehsana '
        'Road)',
    timings:
        'THIN PRIMARY CLOCK: Gujarat Tourism lists Bahuchar Mata Temple '
        'Becharaji as “All Day open.” Secondary pilgrim guides commonly cite '
        '~5:30 AM–10:00 PM with morning/evening aartis around 7:00 AM and 7:00 '
        'PM — treat as approximate. Confirm on arrival / local trust '
        'noticeboards; Navaratri overrides ordinary hours.',
    latitude: 23.50012,
    longitude: 72.04485,
    specialities: [
      'Bahuchara Mata — rooster vahana',
      'Major north-Gujarat Devi pilgrimage (with Ambaji & Pavagadh)',
      'Important shrine for hijra / transgender devotees',
      'Adyasthan–Madhyasthan–main shrine complex',
      'Navaratri peak crowds',
      'Near Modhera Sun Temple circuit',
    ],
  ),

  Temple(
    name: 'Ranchhodraiji Temple',
    state: 'Gujarat',
    city: 'Dakor',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/ranchhodraiji-temple/800/600',
    description:
        'Famous Vaishnava temple of Ranchhodraiji (Krishna) at Dakor in Kheda '
        'district, with an official named darshan clock of mangala, shringar, '
        'rajbhog, utthapan and shayan bhogs published by the temple trust.',
    story:
        'Dakor’s Ranchhodraiji Temple venerates Krishna as Ranchhodrai — ‘the '
        'one who left the battlefield,’ a name tied to Krishna’s strategic '
        'withdrawal narratives. The town in Kheda district is one of Gujarat’s '
        'most visited Vaishnava centres after Dwarka, drawing Gujarati and wider '
        'pilgrimage traffic year-round.\n\nTemple legend recounts how devotee '
        'Bodana brought the Lord from Dwarka to Dakor; the black-stone form and '
        'successive reconstructions made the shrine a regional rival to Dwarka '
        'for many inland pilgrims. The present complex includes mandapas, tank '
        'associations, and dense bazaar approaches typical of living Gujarati '
        'temple towns.\n\nThe official trust site ranchhodraiji.org publishes '
        'live darshan and a Gujarati daily schedule: morning mangala through '
        'rajbhog, midday closure, then utthapan and evening bhogs until shayan. '
        'Sundays keep longer continuous morning and evening windows. Donations '
        'are accepted only via official website/counters — the trust warns '
        'against WhatsApp/Facebook impersonators.\n\nJanmashtami, Holi, and '
        'ekadashi observances intensify crowds; confirm festival overrides on '
        'the official site.',
    location: 'Shri Ranchhodraiji Maharaj Mandir, Dakor, Kheda district, Gujarat 388225',
    timings:
        'Official ranchhodraiji.org Live Darshan board: Mangala aarti/darshan '
        '6:45–8:30 AM; Shringar-bhog darshan 9:00–11:00 AM; Rajbhog 11:30 '
        'AM–12:00 PM; temple closed 12:00–4:00 PM; Utthapan 4:00–5:00 PM; '
        'Shayan-bhog 5:15–6:00 PM; Sakhdibhog 6:45–7:30 PM then shayan. Sundays: '
        'continuous darshan 9:00 AM–12:00 PM and 4:00–6:00 PM. Festival days '
        'change — confirm on ranchhodraiji.org.',
    latitude: 22.7544,
    longitude: 73.149,
    specialities: [
      'Ranchhodrai (Krishna) — major Gujarat Vaishnava centre',
      'Official named bhog/aarti clock on trust site',
      'Bodana / Dwarka-transfer legend',
      'Sunday extended continuous darshan windows',
      'Janmashtami pilgrimage surge',
    ],
  ),

  Temple(
    name: 'Nageshwar Jyotirlinga Temple',
    state: 'Gujarat',
    city: 'Dwarka',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/nageshwar-jyotirlinga-temple/800/600',
    description:
        'One of the twelve Jyotirlingas, the Nageshwar Shiva temple near Dwarka '
        'is linked to the Darukavanam legend of devotee Supriya and is commonly '
        'paired with Dwarkadhish on Saurashtra pilgrim circuits.',
    story:
        'Nageshwar (Nageshvara) Jyotirlinga near Dwarka is counted among the '
        'twelve Jyotirlingas. Popular Shaiva narrative places the manifestation '
        'in Darukavanam: demon Daruka tormented devotees until Shiva appeared to '
        'protect the devotee Supriya, establishing the Nageshwar linga '
        'associated with protection from poison and fear.\n\nThe modern temple '
        'complex includes a large linga sanctum and a monumental outdoor Shiva '
        'statue that has become a photographic landmark for Dwarka-bound '
        'pilgrims. It sits inland from the Dwarkadhish sea-temple and is usually '
        'visited on the same day as Jagat Mandir / Beyt Dwarka.\n\nCompared with '
        'Somnath Trust or Dwarkadhish.org, richly detailed official English '
        'timing portals are thinner; pilgrim guides converge on morning and '
        'evening darshan with a midday break. Maha Shivaratri and Shravan '
        'Mondays are the busiest periods.\n\nTreat poison-protection and '
        'Daruka-forest lore as living religious narrative; administrative '
        'notices on site should override third-party clocks.',
    location:
        'Nageshwar / Daarukavanam area near Dwarka, Devbhumi Dwarka district, '
        'Gujarat',
    timings:
        'THIN PRIMARY SOURCES: Visitor guides commonly list ~6:00 AM–12:30 PM '
        'and ~5:00 PM–9:00 PM (variants to 9:30 PM); some list aarti markers '
        'near early morning, noon, and ~7:00 PM. Confirm on arrival — no richly '
        'detailed trust FAQ equivalent to somnath.org found in this research '
        'pass. Shivaratri/Shravan override ordinary hours.',
    latitude: 22.3359,
    longitude: 69.0869,
    specialities: [
      'One of the 12 Jyotirlingas',
      'Darukavanam / Supriya–Daruka legend',
      'Often paired with Dwarkadhish same-day circuit',
      'Large outdoor Shiva statue landmark',
      'Shravan & Maha Shivaratri pilgrimage peaks',
    ],
  ),

  Temple(
    name: 'Akshardham Temple',
    state: 'Gujarat',
    city: 'Gandhinagar',
    deity: 'Swaminarayan',
    imageUrl: 'https://picsum.photos/seed/akshardham-temple/800/600',
    description:
        'BAPS Swaminarayan Akshardham complex in Gandhinagar — monumental '
        'mandir, exhibitions, Abhishek Mandapam, Nilkanth Vatika and '
        'Sat-Chit-Anand water show — closed every Monday, with free mandir '
        'darshan and ticketed exhibitions.',
    story:
        'Swaminarayan Akshardham at Gandhinagar is the Gujarat campus of BAPS '
        '(Bochasanwasi Akshar Purushottam Swaminarayan Sanstha), honouring '
        'Bhagwan Swaminarayan. The pink stone mandir and landscaped campus form '
        'one of modern Gujarat’s most visited spiritual–cultural landmarks, '
        'distinct from the later Delhi Akshardham.\n\nVisitors combine '
        'garbhagriha darshan with exhibitions on Swaminarayan history and '
        'values, the Abhishek Mandapam, Nilkanth Vatika gardens, and the evening '
        'Sat-Chit-Anand water show. Prasadi Mandapam displays sacred relics '
        'associated with Swaminarayan. Security screening is airport-like; dress '
        'code requires covered shoulders/upper arms and below-knee lower wear '
        '(loaner sarongs available).\n\nOfficial visitor-info '
        '(akshardham.com/gujarat) is the authoritative clock: campus closed '
        'every Monday; mandir darshan late morning through evening with arti at '
        'opening and evening. Exhibition ticket windows close earlier than '
        'mandir. Mandir entry is free; exhibitions and water show are '
        'ticketed.\n\nArrive via Ahmedabad airport (~21 km) or Ahmedabad railway '
        '(~32 km). Peak days (Diwali, anniversaries, weekends) mean long '
        'security queues — plan buffer time.',
    location: 'Swaminarayan Akshardham, Sector 20, J Road, Gandhinagar, Gujarat 382020',
    timings:
        'Official BAPS Akshardham Gujarat visitor-info: CLOSED every Monday. '
        'Tue–Sun first entry 10:00 AM, last entry 7:30 PM. Mandir darshan 10:00 '
        'AM–7:30 PM; Arti 10:00 AM and 6:30 PM. Exhibitions ticket window 10:30 '
        'AM–5:30 PM. Abhishek Mandapam 10:30 AM–7:00 PM. Nilkanth Vatika 10:00 '
        'AM–7:00 PM. Sat-Chit-Anand Water Show after sunset (listed currently '
        '7:30 PM). Confirm akshardham.com/gujarat before travel.',
    latitude: 23.2308,
    longitude: 72.6738,
    specialities: [
      'BAPS Swaminarayan Akshardham (Gandhinagar)',
      'Closed every Monday',
      'Free mandir darshan; ticketed exhibitions & water show',
      'Abhishek Mandapam & Nilkanth Vatika',
      'Sat-Chit-Anand evening water show',
      'Strict security and dress code',
    ],
  ),

  Temple(
    name: 'Chotila Chamunda Mata Temple',
    state: 'Gujarat',
    city: 'Chotila',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chotila-chamunda-mata-temple/800/600',
    description:
        'Hilltop Chamunda Mata shrine above Chotila in Surendranagar district — '
        'a classic Saurashtra Devi pilgrimage with steep steps, Navaratri '
        'crowds, and trust-managed worship of Chamunda (with Chandi) on a '
        'gazetteer-recorded sacred hill.',
    story:
        'Chotila Chamunda Mata Temple stands on the hill overlooking Chotila '
        'town, Surendranagar district. The 1884 Gazetteer of the Bombay '
        'Presidency recorded a Chaund Mata temple on the summit and gave the '
        'hill’s elevation as 1,173 ft (358 m); the settlement at the foot was '
        'formerly called Chotgadh and passed from Sodha Parmars to Khachar '
        'Kathis in the sixteenth century.\n\nChamunda — fierce form of the '
        'Goddess associated with defeating the demons Chanda and Munda — is '
        'worshipped here; contemporary reports note Chandi and Chamunda '
        'venerated together. The shrine is managed by Shree Chamunda Mataji '
        'Dungar Trust under Gujarat public trusts law.\n\nAccess is '
        'traditionally by a long flight of steps; ropeway and funicular projects '
        'have been debated and partially advanced in state and court records '
        '(ropeway authorisation litigation concluded 2023; funicular reported '
        'under construction in later press). Navaratri brings garba, '
        'kalash-javara rites, and altered aarti/access times; Poonam walking '
        'processions are also common.\n\nChotila sits on the Ahmedabad–Rajkot '
        'highway corridor, making it a frequent stop for Saurashtra-bound '
        'pilgrims.',
    location: 'Chamunda Hill, Chotila, Surendranagar district, Gujarat',
    timings:
        'THIN PRIMARY CLOCK vs strong secondary consensus: pilgrim guides '
        'commonly list darshan ~5:00 AM–7:30 PM; aarti ~6:00 AM (Sun often '
        'earlier ~5:30 AM) and ~6:00 PM; Purnima mornings earlier. Navaratri may '
        'run near round-the-clock or extended hours with published day-wise '
        'changes. Confirm locally / trust notices — no Somnath-style public FAQ '
        'clock found in this pass.',
    latitude: 22.4199,
    longitude: 71.2101,
    specialities: [
      'Hilltop Chamunda (with Chandi) shrine',
      'Gazetteer-documented sacred hill (~1,173 ft)',
      'Major Saurashtra Navaratri pilgrimage',
      'Long stair ascent (ropeway/funicular projects ongoing)',
      'Managed by Shree Chamunda Mataji Dungar Trust',
      'Highway stop on Ahmedabad–Rajkot corridor',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  ODISHA
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 7 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders (same pattern as the
  // original sample). Commons photo_candidates are not Storage paths.
  // Sources and photo candidates: docs/odisha-sample-research.md
  Temple(
    name: 'Jagannath Temple',
    state: 'Odisha',
    city: 'Puri',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/jagannath-temple/800/600',
    description:
        'Char Dham Vaishnava temple of Jagannath, Balabhadra and Subhadra at '
        'Puri — famed for the annual Ratha Yatra, wooden nabakalebara idols, '
        'vast Mahaprasad kitchen, and Kalinga-style spire crowned by the Nila '
        'Chakra.',
    story:
        'Shree Jagannatha Temple (Shreemandira) stands at the ritual heart of '
        'Puri on Odisha’s coast and is counted among Hinduism’s Char Dham '
        'destinations. The present Eastern Ganga–period complex is traditionally '
        'linked to Anantavarman Chodaganga (early 12th century CE) on a far '
        'older Purushottama / Nilachala pilgrimage site; later Gajapati kings '
        'institutionalised Jagannath as the state’s sovereign deity.\n\nUnlike '
        'stone or metal murtis elsewhere, the triad — Jagannath, Balabhadra and '
        'Subhadra — is carved from sacred neem (daru) wood and periodically '
        'renewed in the elaborate Nabakalebara ceremony (commonly every 8–19 '
        'years when a double Ashadha occurs). Daily life follows a long niti '
        'sequence of besha, dhupa and bhoga; the temple kitchen (Rosaghara) is '
        'widely described as among the largest temple kitchens in the world, '
        'producing vegetarian Mahaprasad without onion or garlic that is '
        'sanctified only after offering also at the Vimala Shakti shrine inside '
        'the complex.\n\nArchitecturally the curvilinear rekha deula rises about '
        '65 m / 214 ft above the Ratnavedi, enclosed by the Meghanada Pacheri '
        'wall and entered primarily through the Singhadwara (Lion Gate) facing '
        'Bada Danda. The Aruna Stambha before the gate was brought from Konark. '
        'Annual highlights include Snana Yatra, the fortnight of Anavasara, '
        'Ratha Yatra to Gundicha with the Gajapati’s Chhera Pahara sweeping '
        'ritual, Niladri Bije, and Chandan Yatra seasons.\n\nPublic darshan is '
        'free and pauses for specific rituals; Lion’s Gate is the usual pilgrim '
        'entry while other gates serve as exits. Only Hindus are admitted to the '
        'inner temple (long-standing custom); non-Hindu visitors traditionally '
        'view from outside (e.g. Raghunandan Library rooftop area). Modest '
        'traditional dress is expected; phones, cameras, leather articles and '
        'footwear are prohibited inside and must be deposited at cloakrooms near '
        'the gate — confirm live notices on shreejagannatha.in before travel.',
    location: 'Grand Road (Bada Danda), Puri, Odisha 752001',
    timings:
        'SJTA visitor page (confirm on shreejagannatha.in / visitor-services '
        'before travel — festival days and niti override): temple/darshan '
        'generally from ~5:30 AM after Mangala Arati until late night (common '
        'visitor summaries ~5:00 AM–10:30/11:30 PM). Approximate public windows: '
        'after Mangala Arati until Besha completion (~5:30–7:30/8:00 AM, '
        'Jagamohan/Bhitar Kaatha); no darshan ~1 hr 15 min for Gopal Ballav Puja '
        '(~8:00–9:15 AM); then Natamandir/Baahaar Kaatha until Sakala Dhupa (~to '
        '11:00 AM); Jagamohan through Bhoga Mandap (~to 1:00 PM); afternoon '
        'window ~2:00–5:30 PM through Sandhya Alati; evening window after '
        'Sandhya Dhupa through Chandan Laagi (~8:00–9:00 PM). Named daily bhogas '
        'include Gopala Ballav, Sakala Dhupa, Madhyanha Dhupa, Sandhya Dhupa and '
        'Bada Singhara. Free darshan — SJTA states no online VIP darshan ticket; '
        'beware fraud sites.',
    latitude: 19.8047,
    longitude: 85.8183,
    specialities: [
      'Char Dham Vaishnava pilgrimage (eastern gate)',
      'Ratha Yatra / Gundicha & Chhera Pahara',
      'Wooden daru idols + Nabakalebara renewal',
      'Vast Rosaghara Mahaprasad kitchen',
      'Nila Chakra & ~65 m Kalinga rekha deula',
      'Vimala Shakti shrine within complex; Singhadwara entry',
    ],
  ),

  Temple(
    name: 'Lingaraj Temple',
    state: 'Odisha',
    city: 'Bhubaneswar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/lingaraj-temple/800/600',
    description:
        'Largest and most prominent temple of Bhubaneswar’s Ekamra Kshetra, a '
        'towering 11th-century Kalinga Shaiva complex for Harihara / Lingaraja '
        'with ~180 ft vimana and dozens of subsidiary shrines beside Bindusagar.',
    story:
        'Lingaraja Temple dominates Old Town Bhubaneswar and is the culminating '
        'masterpiece of mature Kalinga temple architecture. The present deula is '
        'generally dated to the 11th century under Somavamsi patronage '
        '(traditionally associated with Yayati Kesari / Lalatendu Kesari), with '
        'later Eastern Ganga additions; the site sits within the sacred Ekamra '
        'Kshetra landscape around Bindusagar tank.\n\nThe swayambhu linga is '
        'venerated as Harihara — a combined form of Shiva (Hara) and Vishnu '
        '(Hari) — reflecting Odisha’s long Shaiva–Vaishnava synthesis. The '
        'compound holds roughly fifty smaller shrines; the four-part plan '
        '(vimana, jagamohana, natamandira, bhoga mandapa) and ~55 m / 180 ft '
        'rekha spire make it the city’s tallest temple landmark.\n\nMajor '
        'festivals include Maha Shivaratri, Ashokashtami / Rukuna Ratha Yatra '
        '(procession of the utsava murti toward Rameswar), Chandan Yatra boat '
        'rituals on Bindusagar, and busy Shravan Mondays. The living temple is '
        'jointly associated with temple administration and ASI heritage '
        'oversight of the monument fabric.\n\nEntry to the inner compound is '
        'traditionally restricted to Hindus; non-Hindu visitors use the raised '
        'northern viewing platform (often called Curzon / Indira Gandhi–era '
        'platform) for exterior views and photography. Phones, cameras and '
        'leather items are typically not allowed inside — deposit before entry '
        'and confirm local board rules.',
    location:
        'Lingaraj Nagar, Old Town (Ekamra Kshetra), Bhubaneswar, Odisha 751002',
    timings:
        'Commonly listed living-temple windows (visitor/tourism guides; confirm '
        'on site — festival days extend): roughly 6:00 AM–12:30 PM and 3:30 '
        'PM–9:00 PM daily, with a strict midday pahada/break. Secondary ritual '
        'summaries often note morning Dwara Phita / Alati ~6:00–6:30 AM, '
        'abhisheka/snana ~6:30–7:30 AM, morning general darshan thereafter, '
        'afternoon rest ~1:30–3:30 PM, and evening Badasinghara / pahada closing '
        'toward ~9:00 PM. Maha Shivaratri commonly extends hours. Free entry for '
        'devotees.',
    latitude: 20.2383,
    longitude: 85.8336,
    specialities: [
      'Ekamra Kshetra’s largest Kalinga temple (~180 ft spire)',
      'Harihara / swayambhu Lingaraja cult',
      'Bindusagar tank & Chandan Yatra boat rituals',
      'Ashokashtami Rukuna Ratha Yatra',
      '~50 subsidiary shrines in compound',
      'Non-Hindu viewing platform outside north wall',
    ],
  ),

  Temple(
    name: 'Konark Sun Temple',
    state: 'Odisha',
    city: 'Konark',
    deity: 'Surya',
    imageUrl: 'https://picsum.photos/seed/konark-sun-temple/800/600',
    description:
        'UNESCO World Heritage (1984) 13th-century Surya temple built as a '
        'colossal stone chariot by Eastern Ganga king Narasimhadeva I — '
        'ASI-protected, ticketed monument on the Puri–Konark coast.',
    story:
        'Konark Sun Temple (Black Pagoda of colonial accounts) was built c. 1250 '
        'CE under Narasimhadeva I of the Eastern Ganga dynasty as a monumental '
        'chariot for Surya. Twenty-four elaborately carved wheels and seven '
        'horses once framed a soaring vimana; the main shikhara later collapsed, '
        'and what visitors walk today is the preserved jagamohana and lower '
        'fabric within an ASI-managed landscape.\n\nUNESCO inscribed the '
        'property in 1984 under criteria highlighting its creative achievement '
        'and testimony to a vanished building tradition. The wheels famously '
        'encode time symbolism (spokes as hours/pauses in popular explanation), '
        'while erotic and courtly friezes parallel other medieval Indian temple '
        'programmes. The Aruna Stambha that once stood here was later moved to '
        'Puri’s Jagannath Singhadwara.\n\nUnlike living temples, Konark is '
        'primarily a protected archaeological monument: there is no continuous '
        'inner sanctum cult comparable to Puri or Lingaraj. Nearby Chandrabhaga '
        'beach and Magha Saptami / Konark Dance Festival calendars draw seasonal '
        'crowds. Evening sound-and-light shows are separately ticketed when '
        'operating.\n\nVisit as heritage tourism: buy ASI tickets (counter or '
        'online), follow no-touch / no-oil rules on sculpture, and pair with the '
        'site museum where open (museum often closed Fridays — confirm locally).',
    location: 'Konark, Puri District, Odisha 752111',
    timings:
        'ASI Must See / circle guidance: monument generally Sunrise to Sunset '
        'daily (visitor guides commonly paraphrase 6:00 AM–8:00 PM — prefer '
        'sunrise–sunset wording). Ticketed entry (ASI rates as published — '
        'commonly ₹40 Indians/SAARC/BIMSTEC cash / ₹35 online; ₹600 other '
        'foreign cash / ₹550 online; free under 15 — verify asi.nic.in / ASI '
        'e-ticketing before travel). Sound & light show evening slots are '
        'seasonal and separately ticketed. On-site Archaeological Museum often '
        'listed ~10:00 AM–5:00 PM, closed Fridays. Not a living daily-pooja '
        'temple.',
    latitude: 19.8874,
    longitude: 86.0946,
    specialities: [
      'UNESCO World Heritage Site (1984)',
      'Stone chariot — 24 wheels & 7 horses',
      'Eastern Ganga Narasimhadeva I, c. 1250 CE',
      'ASI ticketed protected monument',
      'Konark Dance Festival & Magha Saptami season',
      'Aruna Stambha originally here (now at Puri)',
    ],
  ),

  Temple(
    name: 'Mukteshwar Temple',
    state: 'Odisha',
    city: 'Bhubaneswar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/mukteshwar-temple/800/600',
    description:
        'Exquisite 10th-century Shaiva “gem of Odisha architecture,” celebrated '
        'for its ornate torana gateway, compact Kalinga vimana, and as a '
        'stylistic bridge toward later Bhubaneswar temples.',
    story:
        'Mukteshvara (Mukteswara) Temple in Bhubaneswar’s Old Town is a compact '
        'Shaiva shrine dated roughly 950–975 CE (Somavamsi period). Historians '
        'treat it as a pivotal experiment that culminates earlier Odishan forms '
        'and foreshadows Rajarani and Lingaraja. The name Mukteswara — “Lord of '
        'Liberation” — refers to Shiva as liberator from the cycle of '
        'rebirth.\n\nIts signature is the freestanding torana (arched gateway) '
        'with richly carved pillars, smiling female figures, peacocks and '
        'scrollwork — often compared to Buddhist gateway influences and among '
        'the most photographed temple portals in India. The vimana and early '
        'pidha-roofed jagamohana sit in an octagonal compound with lattice '
        'windows, Panchatantra-related motifs, Lakulisha images, and Marichi '
        'Kunda tank lore linking a dip to fertility blessings.\n\nOdisha '
        'Tourism’s Mukteswar Dance Festival of Odissi is staged in the precinct '
        'seasonally. Incredible India lists visitor hours roughly 6:30 AM–7:30 '
        'PM. The monument is a nationally important protected structure within '
        'the Ekamra heritage cluster; treat sculpture gently and confirm any '
        'ticket/board rules on site.',
    location: 'Old Town, Bhubaneswar, Odisha 751002',
    timings:
        'Incredible India listed hours: 6:30 AM–7:30 PM (confirm locally; '
        'festival/dance-event days may differ). Living Shaiva worship continues '
        'alongside heritage visitation — midday heat is intense; early morning '
        'preferred. No reliable full named-pooja clock on official English '
        'tourism pages — ask sevakas/on-site board.',
    latitude: 20.2427,
    longitude: 85.8404,
    specialities: [
      'Famous ornate torana arched gateway',
      '10th-c. Kalinga “miniature gem”',
      'Bridge style toward Rajarani & Lingaraj',
      'Marichi Kunda fertility-tank tradition',
      'Mukteswar Dance Festival (Odissi)',
      'Lakulisha / Pashupata sculptural programme',
    ],
  ),

  Temple(
    name: 'Rajarani Temple',
    state: 'Odisha',
    city: 'Bhubaneswar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/rajarani-temple/800/600',
    description:
        'Elegant 11th-century pancharatha temple of red-and-yellow “rajarani” '
        'sandstone, ASI-ticketed, famed for graceful nayika sculpture — the '
        'sanctum today has no living cult image.',
    story:
        'Rajarani Temple (possibly the historical Indreshvara) stands in '
        'landscaped grounds east of Old Town Bhubaneswar. Built mid-11th century '
        'in pancharatha Kalinga style, it takes its popular name from the dull '
        'red and yellow sandstone locally called rajarani, not from a royal '
        'couple — though naga/nagini door guardians feed that folk '
        'etymology.\n\nThe vimana rises about 18 m with clustered angashikharas '
        'that scholars compare to Khajuraho silhouettes; the repaired pidha '
        'jagamohana collapsed and was restored around 1903. Walls carry '
        'celebrated slender nayikas, dikpalas, Shaiva marriage and dance panels, '
        'and mithuna reliefs — hence the local “love temple” '
        'nickname.\n\nAlthough broadly classed as Shaivite from dvarapalas, '
        'Lakulisha lintel imagery and narrative niches, the garbha-griha '
        'contains no installed deity image today. ASI maintains it as a ticketed '
        'monument rather than a routine living-pooja shrine; Odisha Tourism’s '
        'Rajarani Music Festival (classical Hindustani/Carnatic/Odissi) is held '
        'here in January.',
    location: 'Tankapani Road, Bhubaneswar, Odisha 751002',
    timings:
        'ASI ticketed monument. Tourism listings commonly give ~6:00 AM–9:00 PM '
        '(some visitor reports say sunrise–sunset — confirm ticket counter '
        'board). Reported entry fee historically ~₹25 Indians / ~₹250 '
        'foreigners; free under 15 — verify current ASI rates on site / ASI '
        'portal. No living daily aarti schedule inside the empty sanctum.',
    latitude: 20.2434,
    longitude: 85.8435,
    specialities: [
      'ASI ticketed monument (empty sanctum)',
      'Red–yellow rajarani sandstone',
      'Graceful nayika & dikpala sculpture',
      '~18 m pancharatha vimana',
      'Rajarani Music Festival (Jan)',
      'Possible historic Indreshvara identification',
    ],
  ),

  Temple(
    name: 'Ananta Vasudeva Temple',
    state: 'Odisha',
    city: 'Bhubaneswar',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/ananta-vasudeva-temple/800/600',
    description:
        '13th-century Vaishnava temple on Bindusagar dedicated to '
        'Krishna–Balarama–Subhadra in complete stone form — Bhubaneswar’s Chakra '
        'Kshetra counterpart to Puri’s wooden Jagannath triad.',
    story:
        'Ananta Vasudeva Temple faces Bindusagar in Old Town Bhubaneswar and is '
        'the city’s principal medieval Vishnu shrine. Tradition and '
        'inscriptional memory link its 13th-century foundation to Queen '
        'Chandrika (daughter of Anangabhima III) in the reign of Bhanudeva; a '
        'foundation inscription is preserved in the British Museum. '
        'Maratha-period renovations later refreshed the fabric.\n\nThe sanctum '
        'houses complete granite murtis of Krishna (Vasudeva), Balarama and '
        'Subhadra — unlike Puri’s unfinished wooden daru images — which is why '
        'Bhubaneswar is remembered as Chakra Kshetra while Puri is Shankha '
        'Kshetra. Architecturally the temple echoes Lingaraja’s longitudinal '
        'banded shikharas but with Vaishnava iconography on the '
        'walls.\n\nDevotees receive Abhada / Mahaprasad from the temple kitchen '
        'tradition (earthen-pot cooking lore similar to Puri’s bhoga culture). '
        'Incredible India lists opening around 6:00 AM and closing around 7:00 '
        'PM; local tourism pages often extend evening hours to ~8:00 PM — treat '
        'as approximate and confirm on site. Free entry.',
    location: 'Near Bindusagar, Old Town, Bhubaneswar, Odisha 751002',
    timings:
        'Incredible India: ~6:00 AM–7:00 PM. Bhubaneswar tourism listings often '
        'state 6:00 AM–8:00 PM daily, free entry. Named aarti/bhoga clocks are '
        'thinner in English official sources — ask temple board/sevakas. '
        'Festival days (Janmashtami, etc.) override.',
    latitude: 20.2406,
    longitude: 85.8358,
    specialities: [
      'Complete stone Krishna–Balarama–Subhadra triad',
      'Chakra Kshetra counterpart to Puri Shankha Kshetra',
      '13th-c. Queen Chandrika / Eastern Ganga foundation',
      'Bindusagar lakeside setting',
      'Abhada / Mahaprasad kitchen tradition',
      'Vaishnava sculptural programme on Kalinga plan',
    ],
  ),

  Temple(
    name: 'Sakshi Gopal Temple',
    state: 'Odisha',
    city: 'Sakshigopal',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/sakshi-gopal-temple/800/600',
    description:
        'Famous Krishna (Gopinatha) temple at Sakhigopal between Bhubaneswar and '
        'Puri, known as the Lord who stood as sakshi (witness) and for the Anla '
        'Navami Radha-pada darshan.',
    story:
        'Sakhigopal / Satyabadi Gopinatha Mandir sits on the Bhubaneswar–Puri '
        'road in Puri district. Temple legend tells of a poor devotee who nursed '
        'a village headman on pilgrimage; the headman promised his daughter in '
        'marriage, then demanded a witness. Krishna as Gopala followed the youth '
        'to testify on condition that he never look back; when the boy glanced '
        'back near a sand mound, the Lord became a stone image rooted to the '
        'spot — sakshi Gopala, the divine witness. Villagers married the couple '
        'and installed the first priests.\n\nTradition also links the murti to '
        'the Braja stone images associated with Vajranabha (Krishna’s '
        'great-grandson) later brought to Odisha. Architecturally the shrine '
        'follows Kalinga forms familiar along the pilgrimage highway.\n\nThe '
        'temple’s standout festival is Anla Navami (Kartika), when pilgrims are '
        'allowed Radha-pada darshan — touching the feet of the Radha image — '
        'drawing huge crowds. Daily offerings here are noted for using wheat '
        'rather than rice in some prasad traditions, an unusual Vaishnava '
        'kitchen detail. Timings in secondary guides are commonly ~6:00 AM–9:00 '
        'PM with possible afternoon ritual breaks; Odisha tourism snippets '
        'sometimes list shorter windows — confirm locally.',
    location: 'Sakhigopal (Satyabadi), Puri District, Odisha (Bhubaneswar–Puri highway)',
    timings:
        'Secondary visitor guides commonly list ~6:00 AM–9:00 PM with possible '
        'brief afternoon ritual closure; some Odisha tourism notes cite shorter '
        'daytime windows (e.g. to ~5:00 PM) — treat as provisional and confirm '
        'on site / local board (thin single official English clock). Anla Navami '
        'sees exceptional crowds and special Radha-pada access. Free darshan '
        'typical.',
    latitude: 19.9357,
    longitude: 85.8298,
    specialities: [
      'Sakshi (witness) Gopala legend',
      'Anla Navami Radha-pada darshan',
      'Satyabadi Gopinatha on Puri highway',
      'Wheat-based prasad tradition (noted locally)',
      'Convenient halt between Bhubaneswar and Puri',
      'Kalinga-style Gopinatha shrine',
    ],
  ),

  Temple(
    name: 'Maa Taratarini Temple',
    state: 'Odisha',
    city: 'Purushottapur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/maa-taratarini-temple/800/600',
    description:
        'Major Shakti Peetha of twin goddesses Tara and Tarini atop the Kumari '
        'Hills in Ganjam, with ropeway access, Chaitra Mela crowds, and an '
        'official Tara Tarini Development Board portal.',
    story:
        'Maa Tara Tarini Temple crowns the Kumari Hills above the Rushikulya '
        'near Purushottampur in Ganjam district. It is counted among Odisha’s '
        'foremost Adi Shakti / Shakti Peetha sites, venerating the twin forms '
        'Tara and Tarini. Traditional accounts link ancient Kalinga patronage '
        'and later medieval rebuilding (often associated with a 17th-century '
        'Basupraharaj phase) with modern development under the Tara Tarini '
        'Development Board.\n\nPilgrims climb or ride the hill ropeway for '
        'darshan; the setting overlooks the river plain and draws especially '
        'large gatherings for Chaitra Mela / Chaitra Parva, Navaratri, Holi and '
        'Sankranti calendars. The site combines living Shakta worship with '
        'hillside tourist infrastructure (ropeway fares and hours published on '
        'secondary timing aggregators and the nic.in portal).\n\nDaily rhythm '
        'typically includes morning and evening alati/bhoga sequences with '
        'midday breaks; treat published English aggregator clocks as provisional '
        'against the official board. Combine spiritually with other Odisha '
        'Shakti circuits (e.g. Biraja, Cuttack Chandi) when planning '
        'Ganjam–coast travel.',
    location: 'Kumari Hills, Purushottampur, Ganjam District, Odisha (Rushikulya river)',
    timings:
        'Secondary schedules (confirm on taratarini.nic.in / temple board — thin '
        'on fully detailed English pooja clocks): temple often listed ~6:30 '
        'AM–8:30 PM (Sundays sometimes ~6:00 AM–9:00 PM) with breaks ~12:30–2:00 '
        'PM and ~5:30–6:30 PM; morning/afternoon/evening darshan segments around '
        'those windows. Ropeway commonly listed ~7:30 AM–1:00 PM and ~2:00–5:30 '
        'PM (fares vary). Chaitra Mela overrides everything.',
    latitude: 19.4897,
    longitude: 84.8998,
    specialities: [
      'Adi Shakti / Shakti Peetha of Tara–Tarini',
      'Kumari Hills overlooking Rushikulya',
      'Hill ropeway pilgrim access',
      'Chaitra Mela / Chaitra Parva yatra',
      'Tara Tarini Development Board (nic.in)',
      'Navaratri & Sankranti pilgrimage peaks',
    ],
  ),

  Temple(
    name: 'Cuttack Chandi Temple',
    state: 'Odisha',
    city: 'Cuttack',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/cuttack-chandi-temple/800/600',
    description:
        'Historic city shrine of Maa Katak Chandi (Chandi / Durga) in Cuttack '
        'near the Mahanadi, especially thronged during Durga Puja when the '
        'temple stays open late into the night.',
    story:
        'Cuttack Chandi (Maa Katak Chandi) Temple is the guardian Shakti shrine '
        'of Cuttack, traditionally placed in the Tulasipur area toward the '
        'Mahanadi side of the old city. The goddess is worshipped as Chandi / '
        'Durga, and the compact urban temple anchors local identity the way '
        'Lingaraj and Jagannath define Bhubaneswar and Puri.\n\nDaily worship '
        'follows a living Shakta rhythm of morning and evening alati with an '
        'afternoon break noted by visitor guides. Durga Puja / Navaratri is the '
        'annual climax: crowds swell dramatically and many accounts say the '
        'temple remains open toward midnight during the festival fortnight, '
        'making that the peak experiential visit for '
        'devotees.\n\nEnglish-language official endowment clocks are thin '
        'compared with Puri’s SJTA portal; rely on local notice boards and '
        'Cuttack municipal/tourism updates near festival time. Combine with '
        'Cuttack’s Bali Yatra season travel only if crowds are acceptable.',
    location: 'Stadium Road, Tulasipur, Cuttack, Odisha 753008',
    timings:
        'Visitor guides commonly list ~6:00 AM–9:00 PM daily with an afternoon '
        'break (exact break varies — confirm on site). Durga Puja: often open '
        'late / toward midnight. THIN official English pooja clock — provisional '
        'secondary timings only.',
    latitude: 20.4772,
    longitude: 85.8626,
    specialities: [
      'Presiding Shakti of Cuttack (Katak Chandi)',
      'Major Durga Puja urban pilgrimage',
      'Mahanadi-side old-city location',
      'Living compact city shrine',
      'Navaratri night openings (festival)',
      'Local guardian-goddess identity',
    ],
  ),

  Temple(
    name: 'Biraja Temple',
    state: 'Odisha',
    city: 'Jajpur',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/biraja-temple/800/600',
    description:
        'Ancient Shakti Peetha of Maa Biraja (Viraja / Girija) at Jajpur — '
        'Mahishasuramardini shrine on the Vaitarani, also famed as Nabhi Gaya '
        'for pitri rites and a 16-day Sharadiya Durga Puja.',
    story:
        'Biraja Temple (Biraja Mandira) is the defining shrine of Jajpur, giving '
        'the town its titles Biraja Kshetra and Biraja Pitha. The present fabric '
        'is commonly dated around the 11th century; the goddess is Durga as '
        'two-armed Mahishasuramardini — spearing Mahisha while standing on lion '
        'and buffalo — with Ganesha, crescent and linga motifs in the crown. '
        'Skanda Purana and tantric sources glorify Viraja; Adi Shankara’s '
        'Ashtadasha Shakti Pitha stotra remembers Girija here, and tradition '
        'holds Sati’s navel fell in this Oddiyana / Utkala pitha near the '
        'Baitarani (Vaitarani) river.\n\nThe complex includes subsidiary Shaiva '
        'shrines and a separate Bagalamukhi shrine (rare Dasamahavidya form). '
        'Nabhi Gaya — a well associated with pitri tarpana / pinda dana — makes '
        'Jajpur a funerary-pilgrimage complement to Gaya. Sharadiya Durga Puja '
        'here is a distinctive 16-day Shodasha Dinatatmika sequence culminating '
        'in Simhadhwaja ratha and bali rites around Ashtami–Navami; other '
        'observances include Raja, Nabanna and Pana Sankranti.\n\nOfficial trust '
        'site maabiraja.com publishes a temple timetable; confirm before travel '
        'as festival calendars expand hours.',
    location:
        'Jajpur Town, Jajpur District, Odisha (Biraja Kshetra / Vaitarani)',
    timings:
        'Official maabiraja.com banner timetable: 5:30 AM–1:00 PM and 3:00 '
        'PM–10:00 PM (confirm on https://maabiraja.com/ — secondary aggregators '
        'sometimes list 5:00 AM–1:00 PM & 4:00–9:00 PM). Sharadiya / Navaratri '
        'and Ratha days extend and intensify. Pitri rites at Nabhi Gaya booked '
        'via temple arrangements.',
    latitude: 20.8338,
    longitude: 86.3381,
    specialities: [
      'Shakti Peetha — Sati’s navel / Viraja Kshetra',
      'Dwibhuja Mahishasuramardini Biraja',
      'Nabhi Gaya pitri / pinda dana',
      '16-day Sharadiya Durga Puja & Simhadhwaja ratha',
      'Bagalamukhi subsidiary shrine',
      'Vaitarani river pilgrimage landscape',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  UTTAR PRADESH
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 8 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders (same pattern as the
  // original sample). Commons photo_candidates are not Storage paths.
  // Sources and photo candidates: docs/uttar-pradesh-sample-research.md
  Temple(
    name: 'Kashi Vishwanath Temple',
    state: 'Uttar Pradesh',
    city: 'Varanasi',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/kashi-vishwanath-temple/800/600',
    description:
        'One of the twelve Jyotirlinga shrines of Shiva in sacred Kashi '
        '(Varanasi), famed for its gold-plated shikhara, the Gyan Vapi precinct, '
        'and the modern corridor linking the temple to the Ganga ghats.',
    story:
        'Kashi Vishwanath Temple (also Vishweshwara / Vishvanath — “Lord of the '
        'Universe”) is among Hinduism’s most visited Shaiva pilgrimage centres '
        'and one of the twelve Jyotirlinga sites. Puranic tradition places an '
        'infinite column of light (jyotirlinga) here; Kashi itself is described '
        'in Skanda Purana’s Kashi Khanda as a city especially dear to '
        'Shiva.\n\nThe living sanctum pilgrims enter today was built in 1780 by '
        'Maratha queen Ahilyabai Holkar of Indore on a site adjacent to earlier '
        'temples that had been destroyed and rebuilt across medieval centuries. '
        'In 1835 Maharaja Ranjit Singh of the Sikh Empire donated about a tonne '
        'of gold for plating the temple’s dome and spires — hence the popular '
        '“Golden Temple” nickname. Subsidiary shrines for deities such as Kala '
        'Bhairava, Kartikeya, Ganesha, and Parvati ring the main quadrangle; the '
        'Jnana Vapi (Gyan Vapi) well lies to the north of the garbha '
        'griha.\n\nDaily worship under the Shri Kashi Vishwanath Temple Trust '
        'follows a dense aarti rhythm: Mangala Aarti before dawn, Mid-Day Bhog '
        'Aarti, the distinctive Sapta Rishi Aarti (seven priests of different '
        'gotras), Night Shringar/Bhog Aarti, and Shayan Aarti before closing. '
        'Rudrabhishek and other sevas can be booked on the official portal. Maha '
        'Shivaratri and Rangbhari Ekadashi / Phalgun bridal traditions are among '
        'the year’s busiest observances.\n\nThe Kashi Vishwanath Dham Corridor '
        '(inaugurated December 2021) widened pilgrim access between the Ganga '
        'ghats and the temple, incorporating restored historic shrines found '
        'during redevelopment. Security screening is strict; phones and bags '
        'rules are posted at entry — follow Trust notices on the day of visit.',
    location:
        'Vishwanath Gali / Kashi Vishwanath Corridor, Varanasi, Uttar Pradesh '
        '221001',
    timings:
        'Trust daily board (shrikashivishwanath.org / FAQ): temple opens ~2:30 '
        'AM; Mangala Aarti 3:00–4:00 AM (ticketed; report by ~2:30 AM, Gate No.1 '
        'for Mangala). General darshan commonly 4:00–11:00 AM, then after '
        'Mid-Day Bhog Aarti (~11:15 AM–12:20 PM) again ~12:20/12:30–7:00 PM; '
        'Sapta Rishi Aarti ~7:00–8:15 PM; brief darshan ~8:30–9:00 PM; Night '
        'Shringar/Bhog Aarti 9:00–10:15 PM; Shayan Aarti ~10:30–11:00 PM; closes '
        '~11:00 PM. Sugam Darshan and Rudrabhishek bookable on the official '
        'portal. Festival days (esp. Maha Shivaratri) override clocks — confirm '
        'on shrikashivishwanath.org before travel.',
    latitude: 25.3108,
    longitude: 83.0106,
    specialities: [
      'One of the twelve Jyotirlinga shrines',
      'Ahilyabai Holkar rebuild (1780); gold plating associated with Maharaja '
          'Ranjit Singh (1835)',
      'Sapta Rishi Aarti — seven priests, different gotras',
      'Kashi Vishwanath Corridor to Ganga ghats (2021)',
      'Gyan Vapi / Jnana Vapi well precinct',
      'Official online booking for aartis & Rudrabhishek',
    ],
  ),

  Temple(
    name: 'Ram Mandir (Shri Ram Janmabhoomi Temple)',
    state: 'Uttar Pradesh',
    city: 'Ayodhya',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/ram-mandir-shri-ram-janmabhoomi-temple/800/600',
    description:
        'Large Nagara-style temple complex in Ayodhya dedicated to Ram Lalla '
        '(infant Rama), consecrated in January 2024 and managed by Shri Ram '
        'Janmabhoomi Teerth Kshetra; among India’s most visited contemporary '
        'pilgrimage sites.',
    story:
        'Shri Ram Janmabhoomi Mandir (Ram Mandir) stands in Ayodhya on the '
        'Sarayu, dedicated to Ram Lalla — the child form of Rama, regarded in '
        'Vaishnava tradition as a complete avatar of Vishnu. Many Hindus revere '
        'the locale as Ram Janmabhoomi, the traditional birthplace of Rama '
        'described in the Ramayana.\n\nThe present Nagara / Maru-Gurjara '
        'sandstone temple was designed by the Sompura family of temple '
        'architects. Groundbreaking (bhumi pujan) was held in August 2020; the '
        'prana pratishtha (consecration) of the sanctum idol took place on 22 '
        'January 2024 under the Shri Ram Janmabhoomi Teerth Kshetra trust. '
        'Published complex dimensions commonly cite a main structure on the '
        'order of ~110 m length, ~72 m width, and ~49 m height, with multiple '
        'mandapas, carved pillars, and subsidiary shrines planned within the '
        'campus. Construction used large volumes of Rajasthan sandstone with '
        'copper joinery and without structural iron/steel in the main stone '
        'fabric — a point repeatedly noted in Trust and architectural '
        'briefings.\n\nPilgrim practice centres on free darshan of Ram Lalla. '
        'The Trust issues free e-passes for timed darshan and aarti through its '
        'official booking portal; it publicly states that it does not charge for '
        'aarti or darshan passes and does not authorise agents. Security is '
        'airport-style: mobiles, cameras, and bags are typically not allowed '
        'inside — use locker facilities at the entry zone. Midday bhog often '
        'closes the sanctum briefly; festival days (Ram Navami and others) and '
        'seasonal aarti shifts can change queues and clocks.\n\nVisitor guidance '
        'should stick to architecture, booking procedure, and published Trust '
        'timings — confirm the live board on srjbtkshetra.org / '
        'online.srjbtkshetra.org before travel.',
    location: 'Ram Janmabhoomi, Ayodhya, Uttar Pradesh 224123',
    timings:
        'Official Trust free darshan slots (srjbtkshetra.org, as published for '
        'booking receipts from 18 April 2026): 07:00–09:00, 09:00–11:00, '
        '11:00–12:00, 13:00–15:00, 15:00–17:00, 17:00–19:00, 19:00–21:00. Free '
        'aarti markers on the same board: Mangal Aarti 04:00 AM; Shringar Aarti '
        '06:00 AM; Shayan Aarti 10:00 PM. Seasonal notices have previously '
        'shifted opening/closing and midday bhog closure — always re-check the '
        'Trust home page and online.srjbtkshetra.org pass instructions before '
        'travel. Darshan and aarti passes are free; Trust warns against agents '
        'charging fees.',
    latitude: 26.7956,
    longitude: 82.1943,
    specialities: [
      'Presiding deity Ram Lalla (infant Rama)',
      'Prana pratishtha 22 January 2024',
      'Nagara / Maru-Gurjara sandstone architecture (Sompura design)',
      'Managed by Shri Ram Janmabhoomi Teerth Kshetra',
      'Free timed darshan & aarti e-passes (official portal only)',
      'High-security entry — phones/cameras usually barred',
    ],
  ),

  Temple(
    name: 'Krishna Janmabhoomi Temple',
    state: 'Uttar Pradesh',
    city: 'Mathura',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/krishna-janmabhoomi-temple/800/600',
    description:
        'Pilgrimage complex in Mathura traditionally identified as the '
        'birthplace of Krishna, with the Garbha Griha (janmasthan) shrine plus '
        'Keshavdev, Bhagwat Bhavan, Yogmaya, and related temples under Shri '
        'Krishna Janmasthan Seva Sansthan.',
    story:
        'Shri Krishna Janmasthan / Krishna Janmabhoomi in Mathura is among the '
        'core sites of the Braj pilgrimage circuit. Vaishnava tradition holds '
        'that Krishna, an avatar of Vishnu, was born here in the prison cell of '
        'Kamsa; the Garbha Griha (sanctum of the birthplace) remains the '
        'emotional heart of the complex for devotees.\n\nThe living temple '
        'campus administered by Shri Krishna Janmasthan Seva Sansthan includes, '
        'alongside the Garbha Griha, the Keshavdev Temple, Bhagwat Bhavan, '
        'Yogmaya, and Giriraj shrines. Architecture mixes rebuilt modern temple '
        'fabric with the layered sacred geography of Mathura’s old Katra '
        'Keshavdev quarter. Strict security screening is standard; photography '
        'inside the complex is generally not permitted — follow posted '
        'boards.\n\nDaily sevas follow a classic Braj temple rhythm of mangala, '
        'bal bhog, rajbhog, afternoon shayan/uthapan, evening aarti, and night '
        'shayan, with summer and winter clocks published by the Sansthan. '
        'Janmashtami (Krishna’s birth festival) draws enormous midnight crowds '
        'for special abhishek and darshan; Holi and other Braj festivals also '
        'swell footfall.\n\nVisitor notes should emphasise pilgrimage practice, '
        'published Sansthan timings, and on-site security rules.',
    location: 'Katra Keshavdev, Mathura, Uttar Pradesh 281001',
    timings:
        'Official Sansthan board (shrikrishnajanmasthan.com): Garbh Grih darshan '
        '05:00 AM–09:30 PM. Keshavdev / Bhagwat Bhavan / Yogmaya / Giriraj — '
        'Summer: 05:00 AM–12:00 noon and 04:00 PM–09:30 PM; Winter: 05:30 '
        'AM–12:00 noon and 03:00 PM–08:30 PM (season dates advance each year on '
        'the official page). Named aarti/bhog markers (official aarti page, '
        'summer vs winter columns): Mangla Aarti 06:30 AM; Bal Bhog 09:00 AM; '
        'Rajbhog Sewa 11:00 AM; Rajbhog Aarti ~11:10 AM; afternoon Sayan ~01:00 '
        'PM; Uthapan 03:00 PM (winter) / 04:00 PM (summer); evening Aarti 07:00 '
        'PM (winter) / 08:00 PM (summer); Sayan Aarti late evening before night '
        'close. Janmashtami midnight programmes override ordinary hours — '
        'confirm on the Sansthan site.',
    latitude: 27.5037,
    longitude: 77.6694,
    specialities: [
      'Traditional janmasthan (birthplace) Garbha Griha of Krishna',
      'Complex: Keshavdev, Bhagwat Bhavan, Yogmaya, Giriraj',
      'Janmashtami midnight celebrations',
      'Core stop on the Braj / Mathura–Vrindavan yatra',
      'Published seasonal summer/winter seva clocks (Sansthan)',
    ],
  ),

  Temple(
    name: 'Banke Bihari Temple',
    state: 'Uttar Pradesh',
    city: 'Vrindavan',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/banke-bihari-temple/800/600',
    description:
        'Beloved Vrindavan temple of Thakur Banke Bihariji — a charming '
        'tribhangi form of Krishna associated with Swami Haridas — known for '
        'curtain-drawn darshan, intense crowds, and no VIP lane.',
    story:
        'Shri Banke Bihari Mandir is among Vrindavan’s most visited living '
        'temples. “Banke” evokes the tribhangi (thrice-bent) posture of Krishna; '
        'the black charm-filled murti is traditionally described as the combined '
        'form of Shyama-Shyam granted to the 16th-century saint-musician Swami '
        'Haridas at Nidhivan, then later installed in the present '
        'shrine.\n\nDarshan practice is distinctive: the curtain before the '
        'deity is drawn and opened repeatedly so that no devotee may gaze too '
        'long — a custom linked to lore that Bihariji’s beauty overwhelms the '
        'viewer. There is no dedicated VIP darshan system on the temple’s own '
        'FAQ; MPs/MLAs are directed to district administration for protocol. '
        'Registration is not required for ordinary darshan.\n\nThe temple sits '
        'in dense old-Vrindavan lanes near other Braj landmarks. Ekadashi, '
        'Purnima, Amavasya, weekends, and annual festivals (Holi, Janmashtami, '
        'Radhashtami seasons) create extreme crowding — the official visit page '
        'advises elderly devotees and families with small children to avoid peak '
        'festival days. Photography of the deity is not a visitor amenity; '
        'follow local sewa adhikari and police guidance.\n\nSevas follow morning '
        'shringar, midday bhog, and evening bhog/aarti with separate summer and '
        'winter clocks published on bihariji.org.',
    location:
        'Banke Bihari Temple Road, Vrindavan, Mathura, Uttar Pradesh 281121',
    timings:
        'Official summer board on bihariji.org (5 Mar–10 Nov): Mandir open 07:45 '
        'AM (morning) / 05:30 PM (evening); Shringar Aarti ~07:55 AM; Bhog '
        '11:00–11:30 AM and 08:30–09:00 PM; Aarti & closing 12:00 noon (morning '
        'session) and 09:30 PM (evening). Winter clocks are widely listed by '
        'visitor guides as roughly 08:45 AM–01:00 PM and 04:30–08:30 PM — the '
        'homepage summer table is the firmly official reference; confirm winter '
        'board on-site or via bihariji.org before travel. Festival days and '
        'Ekadashi crowds change effective waiting time more than the clock '
        'itself.',
    latitude: 27.5797,
    longitude: 77.6964,
    specialities: [
      'Tribhangi Banke Bihari murti — Swami Haridas / Nidhivan tradition',
      'Curtain-drawn intermittent darshan custom',
      'No VIP darshan system (temple FAQ)',
      'Peak crowds on Ekadashi, Purnima, Amavasya & Holi/Janmashtami',
      'Core Vrindavan / Braj pilgrimage stop',
    ],
  ),

  Temple(
    name: 'Prem Mandir',
    state: 'Uttar Pradesh',
    city: 'Vrindavan',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/prem-mandir/800/600',
    description:
        'Contemporary Italian-marble “Temple of Divine Love” in Vrindavan, '
        'founded by Jagadguru Kripalu Ji Maharaj (inaugurated 2012), with '
        'Radha-Krishna and Sita-Ram shrines, sculpted leela panels, gardens, and '
        'an evening musical fountain.',
    story:
        'Prem Mandir (Temple of Divine Love) is a major modern landmark on the '
        'edge of Vrindavan, established and inaugurated by Jagadguru Shri '
        'Kripalu Ji Maharaj in February 2012 and maintained by Jagadguru Kripalu '
        'Parishat. The white Italian-marble complex rises over landscaped '
        'gardens and is dedicated principally to Radha-Krishna (with Sita-Ram '
        'also enshrined on another level).\n\nExterior walls and courtyards '
        'carry life-sized sculptural depictions of Krishna’s leelas — commonly '
        'highlighted are Jhulan, Govardhan, Raas, and Kaliya Nag episodes — '
        'making the parikrama itself a visual pilgrimage narrative. Construction '
        'involved roughly a decade of work by large artisan teams after the 2001 '
        'cornerstone; the campus is often described as spanning tens of acres '
        'with fountains and visitor amenities.\n\nUnlike the cramped lanes of '
        'older Vrindavan shrines, Prem Mandir offers wide processional spaces '
        'suited to families and first-time visitors. Evening musical/digital '
        'fountain shows are scheduled seasonally. Janmashtami and Radhashtami '
        'are peak festival days. Darshan follows clear morning and evening '
        'sessions with named bhog and shayan aartis published on '
        'premmandir.org.in.',
    location:
        'Bhaktivedanta Swami Marg / Kripalu Maharaj Ji Marg, Vrindavan, Mathura, '
        'Uttar Pradesh 281121',
    timings:
        'Official (premmandir.org.in / timings): open daily 08:30 AM–12:00 noon '
        'and 04:30 PM–08:30 PM. Morning: Darshan & Aarti 08:30 AM; Bhog 11:30 '
        'AM; Shayan Aarti & doors close 12:00 noon. Evening: Aarti & Darshan '
        '04:30 PM; Bhog 05:30 PM; Parikrama 07:00 PM; Shayan Aarti 08:10 PM; '
        'doors close 08:30 PM. Musical & digital fountain: 07:30–08:00 PM (1 '
        'Apr–30 Sep); 07:00–07:30 PM (1 Oct–31 Mar). Confirm festival overrides '
        'on the official site.',
    latitude: 27.5725,
    longitude: 77.6725,
    specialities: [
      'Founded by Jagadguru Kripalu Ji Maharaj; inaugurated Feb 2012',
      'Italian marble; Radha-Krishna & Sita-Ram shrines',
      'Sculpted Krishna leela panels (Jhulan, Govardhan, Raas, Kaliya)',
      'Seasonal evening musical / digital fountain show',
      'Wide landscaped campus — popular with families',
    ],
  ),

  Temple(
    name: 'Sankat Mochan Hanuman Temple',
    state: 'Uttar Pradesh',
    city: 'Varanasi',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/sankat-mochan-hanuman-temple/800/600',
    description:
        'Famous Varanasi Hanuman temple traditionally founded by Goswami '
        'Tulsidas, known for Tuesday/Saturday crowds, continuous chanting, and '
        'the annual Sankat Mochan Sangeet Samaroh.',
    story:
        'Sankat Mochan (“reliever of troubles”) Hanuman Temple in southern '
        'Varanasi is closely associated with the poet-saint Goswami Tulsidas, '
        'author of the Ramcharitmanas, who tradition says established the shrine '
        'after a divine vision of Hanuman. The temple remains one of the city’s '
        'most active living Hanuman centres, especially on Tuesdays and '
        'Saturdays.\n\nThe precinct combines the main Hanuman sanctum with '
        'associated Ram-Sita shrines and a lively courtyard culture of '
        'continuous sankirtan and offerings of laddus and sindoor. Security '
        'screening is routine after past incidents; follow bag and phone rules '
        'at the gate. An annual Sankat Mochan Sangeet Samaroh (classical music '
        'festival) hosted by the temple trust is a cultural landmark of '
        'Varanasi’s winter calendar.\n\nPilgrims often pair Sankat Mochan with a '
        'Ganga aarti at nearby Assi Ghat or with Kashi Vishwanath on the same '
        'Varanasi circuit. Festival days and Hanuman Jayanti extend hours and '
        'crowds well beyond ordinary weekday patterns.',
    location:
        'Sankat Mochan Mandir Rd, near Assi / Lanka, Varanasi, Uttar Pradesh '
        '221005',
    timings:
        'Temple visitor information (sankatmochanmandirvaranasi.com): opens '
        '~04:30 AM, morning session to noon; reopens ~03:00 PM; closes ~10:30 PM '
        'on ordinary days; Tuesdays & Saturdays remain open until midnight. '
        'Aarti markers are posted on the visitor page (verify same-day board — '
        'formatting on the public page can be unclear). Secondary guides '
        'sometimes list ~05:00 AM–12:00 PM & 04:00–10:00 PM — prefer the temple '
        'visitor page and on-site notices. Tue/Sat and Hanuman Jayanti are peak.',
    latitude: 25.2821,
    longitude: 83.0,
    specialities: [
      'Associated with Goswami Tulsidas foundation tradition',
      'Peak worship Tuesdays & Saturdays (open till midnight per visitor page)',
      'Annual Sankat Mochan Sangeet Samaroh',
      'Popular stop with Assi Ghat on the south Varanasi circuit',
      'Heavy security screening at entry',
    ],
  ),

  Temple(
    name: 'Hanuman Garhi',
    state: 'Uttar Pradesh',
    city: 'Ayodhya',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/hanuman-garhi/800/600',
    description:
        'Historic hilltop Hanuman temple in Ayodhya, approached by a steep '
        'flight of steps, traditionally regarded as Hanuman’s guard-post over '
        'Ram Janmabhoomi and a standard first stop for many Ayodhya pilgrims.',
    story:
        'Hanuman Garhi (“Hanuman’s fort”) crowns a small fortified hill in the '
        'heart of Ayodhya. Local tradition holds that Hanuman and his vanara '
        'army stayed here while Rama ruled Ayodhya, keeping watch over the '
        'Ramkot / Janmabhoomi area — hence the custom that many pilgrims take '
        'Hanuman’s blessings here before or after Ram Mandir darshan.\n\nThe '
        'present temple complex sits inside a fort-like enclosure reached by a '
        'long staircase (commonly counted around seventy-odd steps). Inside, the '
        'sanctum houses Hanuman in a form that devotees approach for sindoor and '
        'oil offerings, especially on Tuesdays and Saturdays. The circular / '
        'fort precinct and gateway architecture give the site a distinct '
        'military-shrine character among Ayodhya’s temples.\n\nHistorical '
        'patronage is often linked to the Nawabi and earlier local rulers who '
        'maintained the fort-temple as a prominent Ayodhya landmark. Today it '
        'remains one of the city’s most climbed pilgrimage spots, busy from '
        'early morning through evening aarti.',
    location: 'Hanuman Garhi, Ayodhya, Uttar Pradesh 224123',
    timings:
        'No single crisp Trust English clock comparable to Ram Mandir or Kashi '
        'Vishwanath; commonly listed visitor windows are approximately 05:00 '
        'AM–12:00 PM and 04:00–09:00/10:00 PM, with Tuesday/Saturday and '
        'festival extensions. Treat these as provisional secondary listings — '
        'confirm on the local notice board the day you visit. Allow extra time '
        'for the stair climb and security on peak days.',
    latitude: 26.7956,
    longitude: 82.2016,
    specialities: [
      'Hilltop fort-temple; long stair approach (~70+ steps)',
      'Traditional guardian shrine of Ayodhya / Ramkot',
      'Often first stop for Ayodhya pilgrims before Ram Mandir',
      'Busy Tuesdays, Saturdays & Hanuman Jayanti',
      'Fortified gateway precinct unique in the cityscape',
    ],
  ),

  Temple(
    name: 'Vindhyavasini Temple',
    state: 'Uttar Pradesh',
    city: 'Vindhyachal',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/vindhyavasini-temple/800/600',
    description:
        'Ancient Devi shrine of Maa Vindhyavasini at Vindhyachal (Mirzapur), a '
        'major Shakti pilgrimage centre and the apex of the local Trikon / '
        'Trikona parikrama with Ashtabhuja and Kali Khoh temples.',
    story:
        'Maa Vindhyavasini Temple stands at Vindhyachal on the Vindhya foothills '
        'near the Ganga in Mirzapur district. The goddess Vindhyavasini — “she '
        'who dwells in the Vindhyas” — is worshipped as a powerful form of Devi; '
        'popular devotion ranks the site among northern India’s great Shakti '
        'centres and Navaratri magnets.\n\nPilgrims traditionally complete the '
        'Trikon (triangular) parikrama linking three shrines: Vindhyavasini (the '
        'principal temple), Ashtabhuja Devi on a nearby hill, and Kali Khoh '
        '(Kali in the cave). The main Vindhyavasini temple itself is approached '
        'with only a few steps on ordinary days via VIP routes; Ashtabhuja '
        'requires a longer stair climb. Nearest railheads are Vindhyachal (~1 '
        'km) and Mirzapur (~8 km).\n\nNavaratri twice a year transforms the '
        'entire dham into a dense festival city with extended night darshan. '
        'Tuesdays, Sundays, and public holidays are also busy. The Uttar Pradesh '
        'Vindhya Dham Teerth Vikas Parishad publishes practical visitor FAQs '
        'including multi-window darshan boards for normal days and Navaratri.',
    location: 'Vindhyachal, Mirzapur district, Uttar Pradesh 231307',
    timings:
        'UP Vindhya Dham Teerth Vikas Parishad FAQ (normal days): 05:00 AM–12:00 '
        'PM; 01:30–07:15 PM; 08:15–09:30 PM; 10:30 PM–midnight. Navaratri '
        '(extended): 04:00 AM–12:00 PM; 01:00–07:30 PM; 08:30–09:30 PM; 10:30 '
        'PM–03:00 AM. Mid-breaks correspond to ritual closures — follow the '
        'on-site board. Festival crowds can make approach roads pedestrian-only.',
    latitude: 25.165,
    longitude: 82.5025,
    specialities: [
      'Devi Vindhyavasini — major Shakti pilgrimage seat',
      'Trikon parikrama with Ashtabhuja & Kali Khoh',
      'Huge Navaratri footfall; extended night darshan',
      'Near Ganga / Vindhya foothills (Mirzapur)',
      'Published multi-window day board (UPVDTVP FAQ)',
    ],
  ),

  Temple(
    name: 'Gorakhnath Temple',
    state: 'Uttar Pradesh',
    city: 'Gorakhpur',
    deity: 'Gorakhnath',
    imageUrl: 'https://picsum.photos/seed/gorakhnath-temple/800/600',
    description:
        'Historic Nath-sampradaya matha and temple in Gorakhpur dedicated to '
        'Guru Gorakhnath, with continuous bhandara tradition, prominent shikhara '
        'campus, and published Mangala, Bhog, and Sandhya aartis.',
    story:
        'Gorakhnath Mandir / Gorakhnath Math in Gorakhpur is the principal seat '
        'associated with Guru Gorakhnath, the medieval Nath yogi whose order '
        'shaped much of north India’s Shaiva–yoga landscape. The matha tradition '
        'venerates Gorakhnath as an enlightened master within a Shiva-oriented '
        'yogic lineage; the temple campus is both a monastic centre and a mass '
        'pilgrimage shrine.\n\nThe present complex features a towering temple '
        'shikhara, assembly spaces, and the long-running akhand annakshetra '
        '(perpetual bhandara) that feeds devotees midday and evening without '
        'distinction — a hallmark of the matha’s public seva. Annual observances '
        'and Makar Sankranti (khichdi) gatherings draw large regional '
        'crowds.\n\nThe official temple site publishes three named aarti anchors '
        '— early-morning Mangala, midday Bhog, and evening Sandhya — which '
        'structure the ritual day even when a continuous minute-by-minute '
        'darshan clock is not spelled out in English. Pilgrims typically combine '
        'temple darshan with prasad from the bhandara.',
    location: 'Gorakhnath Mandir Rd, Gorakhpur, Uttar Pradesh 273015',
    timings:
        'Official gorakhnathmandir.in aarti markers: Mangala Aarti of Shri Nath '
        'Ji 03:00–04:00 AM; Bhog Aarti from 11:00 AM; Sandhya Aarti 06:00–08:00 '
        'PM. Full continuous darshan open/close times are not crisply tabulated '
        'in English on the homepage — treat general day access as temple-board '
        'dependent and confirm on arrival. Akhand bhandara operates midday and '
        'evening. Festival days (incl. Makar Sankranti) extend programmes.',
    latitude: 26.7572,
    longitude: 83.3578,
    specialities: [
      'Seat of Guru Gorakhnath (Nath sampradaya)',
      'Shaiva–yoga monastic matha with mass pilgrimage footfall',
      'Akhand annakshetra / bhandara (midday & evening)',
      'Named Mangala, Bhog, and Sandhya aartis (official site)',
      'Prominent shikhara campus in Gorakhpur city',
    ],
  ),

  Temple(
    name: 'Bade Hanuman Ji Temple (Lete Hanuman)',
    state: 'Uttar Pradesh',
    city: 'Prayagraj',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/bade-hanuman-ji-temple-lete-hanuman/800/600',
    description:
        'Unique reclining (lete) Hanuman temple near the Triveni Sangam in '
        'Prayagraj, famous for its colossal recumbent image that can be '
        'partially submerged in monsoon floodwaters and for huge Kumbh Mela '
        'footfall.',
    story:
        'Bade Hanuman Ji Mandir — popularly Lete Hanuman Ji — stands close to '
        'the Triveni Sangam and the historic fort at Prayagraj (Allahabad). Its '
        'defining feature is a large reclining image of Hanuman (often described '
        'around twenty feet in length), an unusual iconographic form that draws '
        'pilgrims year-round and especially during Kumbh / Magh Mela '
        'seasons.\n\nTemple lore recounts that the image was fashioned from '
        'Vindhyan stone for a childless merchant of Kannauj, left at Prayag '
        'during a Sangam pilgrimage, and later installed by Baba Balagiri Ji '
        'Maharaj after its rediscovery. Local narratives also link the shrine’s '
        'immovability to the nearby fort walls. During monsoon floods, river '
        'water frequently enters the precinct and partially submerges the '
        'reclining murti — an oft-photographed seasonal spectacle interpreted by '
        'devotees as a sign of Hanuman’s humility.\n\nHanuman Jayanti, Ram '
        'Navami, Bada Mangal, and Narak Chaturdashi are major observance days. '
        'Ahead of recent Kumbh cycles the campus has seen corridor, '
        'parikrama-path, and access upgrades. Pair the visit with Sangam snan '
        'when river conditions allow.',
    location:
        'Near Triveni Sangam / Allahabad Fort, Prayagraj, Uttar Pradesh 211001',
    timings:
        'THIN OFFICIAL CLOCK — commonly listed visitor windows (secondary guides '
        '/ Wikipedia citation-needed summary): about 05:00 AM–02:00 PM and '
        '05:00–08:00 PM; Tuesdays & Saturdays often extended toward 10:00 PM. '
        'Confirm on the local board, especially in monsoon (flood access) and '
        'during Magh/Kumbh Mela when hours and crowd control change. Prefer '
        'early morning on Tue/Sat.',
    latitude: 25.4335,
    longitude: 81.882,
    specialities: [
      'Rare colossal reclining (lete) Hanuman murti',
      'Near Triveni Sangam — key Prayagraj pilgrimage stop',
      'Monsoon partial submersion of the image (seasonal)',
      'Major Kumbh / Magh Mela footfall',
      'Hanuman Jayanti, Ram Navami, Bada Mangal observances',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  JAMMU AND KASHMIR
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 9 — new temples, not enrichments of existing rows.
  // State label is Jammu and Kashmir. No separate Ladakh row: this pass
  // did not find a living Ladakh Hindu temple with a verified Commons photo.
  // Cover imageUrl values are picsum placeholders. Empty Commons lists
  // (Ranbireshwar, Sudh Mahadev) stay documented, not invented Storage paths.
  // Sources and photo candidates: docs/jammu-kashmir-sample-research.md
  Temple(
    name: 'Vaishno Devi Temple',
    state: 'Jammu and Kashmir',
    city: 'Katra',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/vaishno-devi-temple/800/600',
    description:
        'Major Shakti pilgrimage cave shrine of Mata Vaishno Devi on Trikuta '
        'Hills above Katra, managed by Shri Mata Vaishno Devi Shrine Board; '
        'darshan of the three natural rock Pindis (Maha Kali, Maha Lakshmi, Maha '
        'Saraswati).',
    story:
        'Shri Mata Vaishno Devi Bhawan sits in a holy cave on the Trikuta range '
        'above Katra (Reasi). Devotees revere the Goddess as self-manifest in '
        'three natural rock formations — the Holy Pindis — identified with Maha '
        'Kali, Maha Lakshmi, and Maha Saraswati. Popular tradition links the '
        'shrine to the flight of Vaishnavi from the tantric Bhairon Nath, the '
        'Banganga and Adhkuwari landmarks on the climb, and the custom that a '
        'yatra is complete only after visiting the Bhairon temple above the '
        'Bhawan.\n\nThe living pilgrimage is administered by the Shri Mata '
        'Vaishno Devi Shrine Board (SMVDSB). Every pilgrim must carry a free '
        'RFID Yatra Access Card (Yatra Parchi), obtainable online or at Katra '
        'registration counters. The trek from Katra to Bhawan is roughly 12–13 '
        'km on foot (pony, palki, and helicopter segments operate under Board '
        'rules when available). Group numbers at the Bhawan regulate cave '
        'entry.\n\nDaily worship centres on the twice-daily Atka Aarti — morning '
        'near sunrise and evening near sunset — when priests bathe and dress the '
        'Pindis; ordinary darshan is suspended for roughly two hours during each '
        'aarti. Outside those windows the Board describes darshan as nearly '
        'continuous round the clock. The older natural cave (Prachin Gufa) is '
        'opened only in lean seasons when footfall drops.\n\nNavaratri draws '
        'peak crowds. Follow maavaishnodevi.org for live aarti windows, '
        'registration, helicopter/pooja bookings, and security dress rules '
        'before travel.',
    location: 'Bhawan, Trikuta Hills, Katra, Reasi district, Jammu and Kashmir 182301',
    timings:
        'Official Board practice (maavaishnodevi.org): Bhawan darshan nearly 24 '
        'hours daily; suspended only during twice-daily Atka Aarti (~2 hours '
        'each). Live aarti webcast windows published by Board — Summer: morning '
        '~6:20–8:00 AM, evening ~7:20–8:30 PM; Winter: morning ~6:20–8:00 AM, '
        'evening ~6:20–8:00 PM (confirm same-day). Free RFID Yatra Parchi '
        'mandatory; Katra registration counters commonly cited 6:00 AM–10:00 PM. '
        'Helicopter, pony, and special pooja slots are Board-controlled and '
        'change with season/crowd — re-check maavaishnodevi.org before travel.',
    latitude: 33.0297,
    longitude: 74.9484,
    specialities: [
      'Three natural rock Pindis — Maha Kali, Maha Lakshmi, Maha Saraswati',
      'Managed by Shri Mata Vaishno Devi Shrine Board',
      'Mandatory free RFID Yatra Parchi',
      '~12–13 km trek from Katra to Bhawan on Trikuta Hills',
      'Twice-daily Atka Aarti with darshan pause',
      'Bhairon temple visit traditionally completes the yatra',
    ],
  ),

  Temple(
    name: 'Amarnath Cave Temple',
    state: 'Jammu and Kashmir',
    city: 'Pahalgam / Anantnag (yatra)',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/amarnath-cave-temple/800/600',
    description:
        'Seasonal high-altitude Shiva cave shrine famed for a natural ice '
        'lingam; open only during the annual Shri Amarnathji Yatra under Shri '
        'Amarnathji Shrine Board (SASB).',
    story:
        'Amarnath Cave Temple lies at roughly 3,888 m in the Kashmir Himalaya of '
        'Anantnag district. Inside the limestone cave a natural ice stalagmite '
        'is worshipped as a svayambhu Shiva lingam; two smaller ice formations '
        'are popularly associated with Parvati and Ganesha. Classical Kashmiri '
        'sources (including references tied to Amareshvara in the Rajatarangini '
        'tradition) and later Mughal-period notices attest a long pilgrimage '
        'memory.\n\nThe shrine is reachable only in summer, typically for a few '
        'weeks around the Shraavana season (often June–August; exact open/close '
        'dates are declared each year). Two regulated axes run to the cave: the '
        'longer Pahalgam–Chandanwari–Sheshnag–Panjtarni route and the shorter, '
        'steeper Baltal–Domel route. Pre-registration, health certificates, RFID '
        'tracking, and access-gate time windows are mandatory under the Shri '
        'Amarnathji Shrine Board.\n\nOutside the notified yatra period the cave '
        'is inaccessible under snow and Board/security closure. Helicopter '
        'availability, camp logistics, and even route status can change on short '
        'notice for weather or administrative reasons — always treat the live '
        'SASB board as authoritative.\n\nVisitor content should emphasise '
        'seasonal access, registration, altitude fitness, and published darshan '
        'windows — not year-round temple hours.',
    location:
        'Amarnath Cave, Lidder Valley high Himalaya (access via '
        'Pahalgam–Chandanwari or Baltal–Domel axes), Anantnag district, Jammu '
        'and Kashmir',
    timings:
        'SEASONAL ONLY — shrine closed outside the annual SASB Yatra. During an '
        'open yatra, SASB published access/darshan board (subject to fair '
        'weather): Domel/Baltal gate ~5:00–11:00 AM; Nunwan (Pahalgam) '
        '~5:30–10:00 AM; Chandanwari gate ~6:00–11:00 AM; Sheshnag ~6:00 AM–2:00 '
        'PM; Panjtarni ~5:00 AM–3:00 PM; Holy Cave darshan ~6:00 AM–7:00 PM. '
        'Permit date controls which day you may cross the access gate. Confirm '
        'year-specific open dates, registration, and any route/heli notices on '
        'jksasb.nic.in / shriamarnathjishrine.com before travel.',
    latitude: 34.2149,
    longitude: 75.5008,
    specialities: [
      'Natural ice lingam (svayambhu stalagmite) at ~3,888 m',
      'Seasonal Shri Amarnathji Yatra only (SASB-managed)',
      'Twin access axes: Pahalgam and Baltal',
      'Mandatory pre-registration, health certificate, RFID tracking',
      'Classical Amareshvara pilgrimage memory in Kashmiri sources',
    ],
  ),

  Temple(
    name: 'Raghunath Temple',
    state: 'Jammu and Kashmir',
    city: 'Jammu',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/raghunath-temple/800/600',
    description:
        'Large Dogra-era temple complex of seven shrines with distinctive '
        'shikharas in old Jammu city; presiding deity Rama (Raghunath), an '
        'avatar of Vishnu.',
    story:
        'Raghunath Temple is among North India’s larger urban temple complexes '
        'and a landmark of Jammu’s old city north of the Tawi. Dogra rulers '
        'Maharaja Gulab Singh and his son Maharaja Ranbir Singh built and '
        'completed the complex in the mid-19th century (foundation commonly '
        'dated 1835; completion often cited mid-1850s–1860). The precinct '
        'comprises seven shrines, each with its own shikhara.\n\nThe central '
        'shrine is dedicated to Rama (Raghunath) with Sita and Lakshmana; other '
        'shrines and galleries house forms of Vishnu (including Dashavatara '
        'imagery), a Surya shrine, Shiva lingams and saligrams, and images of '
        'Hanuman and Devi. Interior gold-sheet wall cladding and '
        'Mughal-influenced arches are frequently noted in district and tourism '
        'descriptions. A library of Sanskrit manuscripts is historically '
        'associated with the complex.\n\nMorning and evening aarti form the core '
        'daily rhythm. The complex remains a busy city pilgrimage stop for Jammu '
        'residents and Vaishno Devi-bound travellers. Incredible India lists '
        'ordinary visitor hours as 06:00 AM–08:00 PM.\n\nArchitecture, Dogra '
        'patronage, and published visitor hours are the safest CMS framing.',
    location: 'Raghunath Bazar / old city, Jammu, Jammu and Kashmir',
    timings:
        'Incredible India visitor board: Opening 06:00 AM, Closing 08:00 PM. '
        'District page notes morning and evening aarti as the main daily rituals '
        'but does not publish a full named pooja clock in English — treat aarti '
        'minutes as on-site/notice-board unless a temple trust page is '
        'confirmed. Festival days (Ram Navami and others) can extend queues.',
    latitude: 32.7304,
    longitude: 74.8623,
    specialities: [
      'Seven-shrine complex with individual shikharas',
      'Presiding deity Rama (Raghunath) — Vishnu avatar',
      'Dogra patronage (Gulab Singh / Ranbir Singh, mid-19th c.)',
      'Dashavatara gallery; lingams and saligrams',
      'Historic Sanskrit manuscript library association',
    ],
  ),

  Temple(
    name: 'Shankaracharya Temple',
    state: 'Jammu and Kashmir',
    city: 'Srinagar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/shankaracharya-temple/800/600',
    description:
        'Ancient hilltop Shiva temple (also Jyeshteshwara) overlooking Srinagar '
        'from the Zabarwan Range; ASI-noted monument and living worship site on '
        'a steep ascent.',
    story:
        'Shankaracharya Temple — also called Jyeshteshwara — crowns '
        'Shankaracharya Hill above Srinagar at roughly 1,850–1,880 m, about 300 '
        'm above the valley floor. The stone sanctum is dedicated to Shiva. '
        'Local and scholarly traditions link the hill’s sacred geography to '
        'early Kashmir Shaivism; the popular name recalls Adi Shankara’s '
        'association with the site, including tapasya in a small cave beside the '
        'temple in later hagiography.\n\nThe present structure is an ancient '
        'stone temple on a high octagonal plinth, reached by a long flight of '
        'steps (and a motorable approach off Boulevard Road near Gagribal, '
        'subject to security). It is listed among ASI-protected monuments of '
        'Jammu & Kashmir and remains a living place of worship, lit specially '
        'for Herath / Maha Shivaratri. Pilgrims on the Amarnath circuit '
        'sometimes include the hill in Srinagar city itineraries.\n\nViews over '
        'Dal Lake and the city make it a combined pilgrimage and viewpoint stop. '
        'Security screening is routine; carry minimal belongings and follow '
        'local administration notices, especially around major '
        'festivals.\n\nFull English pooja-clock detail is thinner than for '
        'Board-run shrines — confirm day’s board on arrival.',
    location:
        'Shankaracharya Hill (Takht-e-Suleiman / Gopadri), Zabarwan Range, '
        'Srinagar, Jammu and Kashmir',
    timings:
        'Living temple; commonly visited through daylight hours after the hill '
        'climb / road access. No single authoritative continuous English aarti '
        'clock located for this research pass — provisional visitor practice is '
        'morning-to-evening darshan with peak activity around Maha Shivaratri / '
        'Herath. Access can be gated for security; confirm locally with district '
        'administration / on-site board before travel.',
    latitude: 34.0789,
    longitude: 74.8436,
    specialities: [
      'Hilltop Shiva shrine overlooking Srinagar',
      'Also known as Jyeshteshwara Temple',
      'ASI-protected monument (N-JK series)',
      'Associated in tradition with Adi Shankara',
      'Herath / Maha Shivaratri illuminations',
    ],
  ),

  Temple(
    name: 'Kheer Bhawani Temple',
    state: 'Jammu and Kashmir',
    city: 'Tulmulla',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/kheer-bhawani-temple/800/600',
    description:
        'Kashmiri Hindu shrine of Ragnya Devi (Kheer Bhawani) built over a '
        'sacred spring at Tulmulla; famed for the Jyeshtha Ashtami Mela and '
        'milk-rice (kheer) offerings.',
    story:
        'Kheer Bhawani — also Ksheer Bhawani or Ragnya Devi Temple — stands at '
        'Tulmulla in Ganderbal, about 25 km from Srinagar. The sanctum is set '
        'within a sacred spring; the Goddess is widely regarded as a protective '
        'kuladevi among Kashmiri Pandits. The name recalls the offering of kheer '
        '(milk-rice pudding) to propitiate the deity.\n\nThe present temple '
        'fabric and surrounding chinar-shaded precinct are a focus of Kashmiri '
        'Hindu devotion. Devotees traditionally watch the colour of the spring '
        'water as an omen. The annual Mela Kheer Bhawani on Jyeshtha Ashtami '
        'draws large gatherings of Kashmiri Pandits and other devotees from '
        'across India; 2026 observances again centred on the Tulmulla campus '
        'under tight security.\n\nOutside festival peaks the shrine remains an '
        'important valley pilgrimage stop on Srinagar-area circuits. Named '
        'continuous English niti clocks are thinner than Board-run Jammu shrines '
        '— treat published tourism ranges as provisional and confirm locally '
        'around the Mela.',
    location:
        'Tulmulla (Tullamulla), Ganderbal district, ~25 km NE of Srinagar, Jammu '
        'and Kashmir',
    timings:
        'Secondary visitor listings commonly cite ~6:00 AM–8:00 PM on ordinary '
        'days; no firm official English continuous aarti board located this pass '
        '— label provisional. Jyeshtha Ashtami Mela extends activity from before '
        'dawn through evening aarti with heavy security and crowd control. '
        'Confirm locally / district notices before travel, especially in Mela '
        'week.',
    latitude: 34.2211,
    longitude: 74.73,
    specialities: [
      'Ragnya Devi / Kheer Bhawani over a sacred spring',
      'Kuladevi for many Kashmiri Pandit families',
      'Jyeshtha Ashtami Mela Kheer Bhawani',
      'Kheer (milk-rice) as characteristic offering',
      'Spring-water colour watched as traditional omen',
    ],
  ),

  Temple(
    name: 'Mahamaya Temple',
    state: 'Jammu and Kashmir',
    city: 'Jammu',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mahamaya-temple/800/600',
    description:
        'Ancient local Devi shrine of Mahamaya in the wooded city forest behind '
        'Bahu Fort, overlooking the Tawi; often visited together with the Bahu '
        'Fort–Bawe Wali Mata circuit.',
    story:
        'Mahamaya Temple sits in the city forest on the bypass behind Bahu Fort, '
        'looking across the Tawi. District Jammu’s tourism note describes it as '
        'an ancient shrine of Mahamaya, remembered in Dogra tradition as a local '
        'goddess who died fighting invaders centuries ago. A small garden and '
        'wooded slopes make the spot a popular city viewpoint as well as a '
        'pilgrimage pause.\n\nVisitors often combine Mahamaya with Bahu Fort, '
        'where the Bawe Wali Mata (Kali / Mahakali) temple stands inside the '
        'fort walls — a distinct shrine rebuilt in the early Dogra period after '
        'Maharaja Gulab Singh’s coronation (1822) and regarded locally as second '
        'only to Vaishno Devi in mystical repute. CMS entries should keep the '
        'two names distinct while noting the shared Bahu–Tawi sacred '
        'geography.\n\nTuesdays and Sundays are traditionally busy for the fort '
        'temple; Mahamaya’s own village-style rhythm is quieter. Official '
        'English pooja clocks are thin — provisional visitor hours '
        'only.\n\nFrame the entry around local Devi devotion, Dogra sacred '
        'geography, and the forest/fort setting — not as a Board-run mega-shrine.',
    location:
        'City forest / bypass road behind Bahu Fort, overlooking the Tawi, '
        'Jammu, Jammu and Kashmir',
    timings:
        'Thin official English clock. Secondary visitor listings for the '
        'Bahu–Mahamaya belt commonly cite ~6:00 AM–8:00 PM (sometimes to ~8:30 '
        'PM); Tuesdays/Sundays busier at the nearby Bawe Wali Mata fort temple. '
        'Label provisional — confirm on-site board. No dedicated Mahamaya trust '
        'timetable located this pass.',
    latitude: 32.7304,
    longitude: 74.8905,
    specialities: [
      'Local Dogra Devi Mahamaya in city forest behind Bahu Fort',
      'Overlooks the Tawi with wooded garden setting',
      'Often paired with Bahu Fort / Bawe Wali Mata visit',
      'Quiet alternative to Jammu’s larger urban temples',
    ],
  ),

  Temple(
    name: 'Ranbireshwar Temple',
    state: 'Jammu and Kashmir',
    city: 'Jammu',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ranbireshwar-temple/800/600',
    description:
        'Major Dogra-era Shiva temple built by Maharaja Ranbir Singh in 1883, '
        'noted for a very large central lingam and twelve crystal lingams.',
    story:
        'Ranbireshwar Temple (Ranbir + Ishwar) stands on Shalimar Road near '
        'Jammu’s New Secretariat and is among the city’s principal Shaiva '
        'landmarks. Maharaja Ranbir Singh, a devout Shaivite Dogra ruler, built '
        'the temple in 1883 CE and gave it his name.\n\nThe sanctum is famed for '
        'a towering central Shiva lingam — tourism accounts commonly describe it '
        'around seven-and-a-half to eight feet — surrounded by twelve crystal '
        'lingams. Popular telling links those crystal lingams with ceremonial '
        'association to Amarnath. Galleries and stone slabs with numerous '
        'saligrams further enrich the complex.\n\nNagara-style shikhara '
        'architecture and a broad courtyard make it a key stop on Jammu’s urban '
        'temple circuit alongside Raghunath and the Bahu belt. Maha Shivaratri '
        'and Mondays draw heavier footfall.\n\nOfficial English continuous pooja '
        'clocks remain thin; secondary guides often list general opening around '
        '6:00 AM–8:00 PM — treat as provisional.',
    location:
        'Shalimar Road near New Secretariat / Parade area, Jammu, Jammu and '
        'Kashmir',
    timings:
        'Thin official English clock. Secondary visitor listings commonly cite '
        '~6:00 AM–8:00 PM daily; morning and evening worship expected as at '
        'other Jammu Shiva temples. Label provisional — confirm on-site board. '
        'Maha Shivaratri overrides ordinary hours.',
    latitude: 32.7347,
    longitude: 74.8641,
    specialities: [
      'Built 1883 by Maharaja Ranbir Singh',
      'Very large central Shiva lingam',
      'Twelve crystal lingams (Amarnath association in popular telling)',
      'Saligram galleries',
      'Key Shaiva stop on Jammu city temple circuit',
    ],
  ),

  Temple(
    name: 'Martand Sun Temple',
    state: 'Jammu and Kashmir',
    city: 'Mattan / Anantnag',
    deity: 'Surya',
    // KAN-77: verified Commons thumbs — tools/photo-packs/martand-sun-temple/
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Martand_Sun_Temple%2C_J%26K_01.jpg/1280px-Martand_Sun_Temple%2C_J%26K_01.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Martand_Sun_Temple%2C_J%26K_01.jpg/1280px-Martand_Sun_Temple%2C_J%26K_01.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/1_Sun_Temple_Martand_Jammu_Kashmir_India_ancient_Hindu_temple_in_ruins.jpg/1280px-1_Sun_Temple_Martand_Jammu_Kashmir_India_ancient_Hindu_temple_in_ruins.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Martand_Sun_Temple.JPG/1280px-Martand_Sun_Temple.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Sun_Temple_Martand.JPG/1280px-Sun_Temple_Martand.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Sun_temple_martand_indogreek.jpg/1280px-Sun_temple_martand_indogreek.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Martand_Sun_Temple%2C_J%26K_02.jpg/1280px-Martand_Sun_Temple%2C_J%26K_02.jpg',
    ],
    description:
        'Eighth-century Surya temple ruins on the Mattan plateau — ASI centrally '
        'protected monument of national importance. Empty archaeological site: '
        'no living garbha-griha cult or regular aarti.',
    story:
        'Martand Sun Temple (Martanda) stands on a plateau near Mattan in '
        'Anantnag district, looking across the Kashmir Valley. Kalhana’s '
        'tradition credits Lalitaditya Muktapida of the Karkota dynasty (8th '
        'century CE) with commissioning this grand Surya temple. The peristyle '
        'complex once organised a central shrine within a vast colonnaded '
        'courtyard ringed by 84 smaller shrines — among the largest peristyle '
        'compositions in Kashmiri temple architecture, blending Gandharan, '
        'Gupta, and wider Asian influences in grey limestone.\n\nThe temple was '
        'ruined in the medieval period; earthquakes caused further loss. What '
        'visitors walk today is an Archaeological Survey of India protected '
        'monument (listed as Martanda / Sun Temple) — an empty sanctum '
        'archaeological site, not a living temple with daily pooja. There is no '
        'installed cult image under active worship in the garbha griha; '
        'appreciation is architectural, historical, and landscape.\n\nIncredible '
        'India publishes visitor hours (06:00 AM–07:00 PM). Kashmiri Pandit '
        'memory still ranks Martand among treasured heritage pilgrimage '
        'landscapes, but CMS must state clearly: ASI ruins / no living cult. A '
        '2024 J&K government restoration initiative has been reported in press — '
        'conservation status may evolve; do not describe active aarti '
        'schedules.\n\nKeep narrative to architecture, dynasty, ASI status, and '
        'visitor hours — avoid communal framing of the medieval destruction '
        'beyond brief historical note.',
    location:
        'Martanda (Sun Temple) ruins, Mattan plateau, Anantnag district, Jammu '
        'and Kashmir',
    timings:
        'ASI / heritage visitor site — NOT a living temple. Incredible India: '
        'Opening 06:00 AM, Closing 07:00 PM. No aarti, bhog, or darshan of a '
        'living cult image. Ticket/access rules follow ASI / local circle '
        'practice — confirm on arrival. Daylight photography of ruins is the '
        'visitor activity.',
    latitude: 33.7456,
    longitude: 75.2203,
    specialities: [
      '8th-century Surya (Martanda) temple — Lalitaditya Muktapida',
      'Vast peristyle courtyard with 84 subsidiary shrines (ruined)',
      'ASI centrally protected monument of national importance',
      'EMPTY SANCTUM — no living garbha cult / no regular aarti',
      'Panoramic plateau views over the Kashmir Valley',
    ],
  ),

  Temple(
    name: 'Purmandal Temple',
    state: 'Jammu and Kashmir',
    city: 'Samba',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/purmandal-temple/800/600',
    description:
        'Riverside Shiva temple complex at Purmandal on the largely underground '
        'Devak River, popularly called Chhota Kashi; known for a seasonal '
        'Shiva–Parvati marriage fair.',
    story:
        'Purmandal (also Poormandal) lies about 40 km from Jammu in Samba '
        'district, just off the old Pathankot highway belt, on the banks of the '
        'sacred Devak — a river that runs mostly underground in this stretch. '
        'Local tradition names the settlement Chhota Kashi for its concentration '
        'of Shiva shrines and lingams said to have manifested naturally.\n\nThe '
        'main temple is associated with Umapati (Shiva with Uma/Parvati); '
        'surrounding shrines continue the Shaiva focus. Pilgrims bathe where the '
        'Devak surfaces and offer worship especially around the Purmandal Mela, '
        'a multi-day fair traditionally celebrating the marriage of Shiva and '
        'Parvati (often placed in February in tourism '
        'notes).\n\nNineteenth-century travellers recorded the festival in '
        'prints now on Wikimedia Commons; the living village still draws '
        'regional Dogra and Jammu-division devotees. Official English day-board '
        'detail is thin — provisional hours only.\n\nKeep CMS copy on Shaiva '
        'pilgrimage geography, Chhota Kashi epithet, and the Devak setting.',
    location:
        'Purmandal (Poormandal), on the Devak River, Samba district (~40 km from '
        'Jammu), Jammu and Kashmir',
    timings:
        'Thin official English clock. Daytime village-temple hours are typical; '
        'secondary guides do not publish a stable named aarti table. Purmandal '
        'Mela (often February — Shiva–Parvati vivah fair) extends activity '
        'across several days. Label provisional — confirm locally before travel.',
    latitude: 32.6957,
    longitude: 75.0609,
    specialities: [
      'Chhota Kashi epithet — cluster of Shiva shrines',
      'On the sacred Devak River (mostly underground)',
      'Main shrine associated with Umapati (Shiva–Parvati)',
      'Purmandal Mela — Shiva–Parvati marriage fair',
      '~40 km from Jammu in Samba district',
    ],
  ),

  Temple(
    name: 'Sudh Mahadev Temple',
    state: 'Jammu and Kashmir',
    city: 'Udhampur',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/sudh-mahadev-temple/800/600',
    description:
        'Ancient hill Shiva shrine near Patnitop at about 1,225 m, housing a '
        'black marble lingam, a trishul, and associated with Gauri Kund and the '
        'Sawan Purnima mela.',
    story:
        'Sudh Mahadev (Sudhmahadev) is a revered Shiva temple in Udhampur '
        'district, roughly 112 km from Jammu and about 42 km from Patnitop, at '
        'an elevation near 1,225 m. District and tourism accounts describe a '
        'natural black marble lingam, a trishul associated with Shiva, and a '
        'mace linked in local lore with Bhima; a black marble Shiva–Parvati '
        'image is also noted.\n\nLegend holds that Parvati bathed at Gauri Kund '
        '(a short distance before the shrine) before worshipping here. The Devak '
        '/ Pap Nashni tradition and a spring called Pap Nashni Bowli figure in '
        'pilgrim practice — bathing before darshan. The three-day Sudh Mahadev '
        'festival on the full-moon night of Sawan (Shravana) draws large crowds '
        'to honour the trishul and mace.\n\nFurther along the road, Mantalai '
        '(Mantalai) is remembered in legend as the site of Shiva and Parvati’s '
        'marriage, with its own Shiva temple amid deodar forest — a natural '
        'extension of the same yatra.\n\nOfficial English continuous pooja '
        'clocks are thin; secondary listings vary (~6:00 AM–7:00/8:00 PM). No '
        'verified Wikimedia Commons photograph of the temple was located this '
        'pass.',
    location:
        'Sudh Mahadev, near Chenani / Patnitop belt, Udhampur district (~112 km '
        'from Jammu), Jammu and Kashmir',
    timings:
        'Thin official English clock. Secondary visitor listings commonly cite '
        'roughly 6:00 AM–7:00 PM or to 8:00 PM; Sawan Purnima three-day mela '
        'overrides ordinary hours. Label provisional — confirm on-site / '
        'Udhampur district notices. Combine with Gauri Kund and Mantalai only if '
        'road/weather allows.',
    latitude: 33.0214,
    longitude: 75.3635,
    specialities: [
      'Ancient black marble Shiva lingam',
      'Trishul and mace venerated at Sawan Purnima mela',
      'Gauri Kund associated with Parvati’s bath',
      'Pap Nashni Bowli / Devak sacred water tradition',
      'Paired geographically with Mantalai (Shiva–Parvati vivah legend)',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  MAHARASHTRA
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 10 — new temples, not enrichments of existing rows.
  // Cover imageUrl values are picsum placeholders. Commons candidates
  // stay in docs/maharashtra-sample-research.md, not Storage paths.
  Temple(
    name: 'Shree Saibaba Samadhi Mandir',
    state: 'Maharashtra',
    city: 'Shirdi',
    deity: 'Sai Baba',
    imageUrl: 'https://picsum.photos/seed/shree-saibaba-samadhi-mandir/800/600',
    description:
        'Samadhi shrine of Sai Baba of Shirdi in Ahmednagar district, '
        'administered by Shree Saibaba Sansthan Trust; among India’s most '
        'visited living pilgrimage centres, with Dwarkamai, Chavadi, and '
        'Gurusthan in the same sacred campus.',
    story:
        'Shree Saibaba Samadhi Mandir in Shirdi marks the resting place of '
        'Sai Baba of Shirdi (d. 1918), the saint whose teaching “Sabka '
        'Malik Ek” (One God governs all) draws Hindu, Muslim, and other '
        'devotees together. The marble samadhi and seated idol stand in '
        'the main mandir; the wider Sansthan precinct includes Dwarkamai '
        '(the mosque-like hall where Baba kept the eternal dhuni fire), '
        'Chavadi, Gurusthan, Lendi Baug, and related memorials.\n\nDaily '
        'worship under Shree Saibaba Sansthan Trust (SSST) follows a dense '
        'aarti rhythm published on sai.org.in: temple open before dawn, '
        'Bhupali, Kakad (morning) Aarti, Mangal Snaan, the “Shirdi Majhe '
        'Pandharpur” aarti, then general darshan; Mid-day (Madhyan) Aarti '
        'at noon; Dhoop Aarti at sunset; evening bhajans; and Shej Aarti '
        'at night. Online darshan and aarti passes are issued only through '
        'the Trust portal (online.sai.org.in); SSST publicly warns that it '
        'does not authorise agents.\n\nMajor observances include Baba’s '
        'Punyatithi / Maha Samadhi day, Ram Navami processions between '
        'Dwarkamai and Chavadi, Guru Purnima, and Vijayadashami. Security '
        'screening is airport-style on peak days; carry government ID '
        'matching any booked pass and follow on-site locker and phone '
        'rules.\n\nVisitor notes should stick to Sansthan-published '
        'clocks, booking procedure, and campus geography — re-check '
        'sai.org.in / online.sai.org.in before travel, especially on '
        'festival weeks.',
    location:
        'Shree Saibaba Sansthan Trust, Shirdi, Ahmednagar district, '
        'Maharashtra 423109',
    timings:
        'Official SSST daily programme (sai.org.in / daily-programme): '
        'Temple Open 4:45 AM; Bhupali 5:00 AM; Kakad Aarti (morning) 5:15 '
        'AM; Mangal Snaan in Samadhi Mandir 5:50 AM; Aarti “Shirdi Majhe '
        'Pandharpur” 6:20 AM; Darshan begins in Samadhi Mandir 6:25 AM; '
        'Dhuni pooja with rice and ghee in Dwarkamai 11:30 AM; Mid-day '
        'Aarti 12:00 PM; Pothi (devotional reading) in Samadhi Mandir 4:00 '
        'PM; Dhoop Aarti at sunset; Devotional songs / cultural programmes '
        '~8:30–10:00 PM; Shej Aarti 10:00 PM. Festival days and '
        'online-pass rules can override — confirm on sai.org.in and book '
        'only at online.sai.org.in.',
    latitude: 19.7667,
    longitude: 74.4772,
    specialities: [
      'Samadhi shrine of Sai Baba of Shirdi (d. 1918)',
      'Dwarkamai dhuni, Chavadi, Gurusthan in same Sansthan campus',
      'Four named daily aartis: Kakad, Madhyan, Dhoop (sunset), Shej',
      'Official online darshan & aarti booking (online.sai.org.in only)',
      'Teaching motto “Sabka Malik Ek” — multi-faith pilgrimage draw',
      'Ram Navami Dwarkamai–Chavadi procession tradition',
    ],
  ),

  Temple(
    name: 'Siddhivinayak Temple',
    state: 'Maharashtra',
    city: 'Mumbai',
    deity: 'Ganesha',
    imageUrl: 'https://picsum.photos/seed/siddhivinayak-temple/800/600',
    description:
        'Famous Siddhi Vinayak (wish-granting Ganesha) temple in '
        'Prabhadevi, Mumbai, founded in 1801 and managed by Shree '
        'Siddhivinayak Ganapati Mandir Trust; among the city’s most '
        'visited living shrines.',
    story:
        'Shree Siddhivinayak Ganapati Mandir in Prabhadevi is dedicated to '
        'Siddhi Vinayak — Ganesha as the granter of siddhi '
        '(accomplishment). The living temple was consecrated on 19 '
        'November 1801 by Laxman Vithu Patil and Deubai Patil. The '
        'black-stone idol is traditionally described with a right-turned '
        'trunk (a form many devotees treat as especially potent), and the '
        'wooden sanctum doors carry carvings of the Ashtavinayaka — '
        'Maharashtra’s eight sacred Ganesha forms.\n\nDaily worship under '
        'the Shree Siddhivinayak Ganapati Mandir Trust follows published '
        'Kakad, Naivedhya, evening Dhup/Aarti, and Shejaarti windows that '
        'differ on ordinary weekdays versus Tuesdays (Ganesha’s weekly '
        'high day) and on Vinayaki / Sankashti / Maghi Jayanti / Bhadrapad '
        'Chaturthi. Ordinary darshan is free; paid sevas and abhishek are '
        'bookable through the Trust. The dome and exterior lighting make '
        'the shrine a recognisable Mumbai landmark after dark.\n\nGanesh '
        'Chaturthi, Sankashti Chaturthi, and Tuesdays draw the heaviest '
        'queues. Security screening and locker rules apply; follow Trust '
        'boards on phones and offerings. Confirm the live day-type board '
        'on siddhivinayak.org before travel — festival and Tuesday clocks '
        'override the Wednesday–Monday default.',
    location: 'SK Bole Marg, Prabhadevi, Mumbai, Maharashtra 400028',
    timings:
        'Official Trust board (siddhivinayak.org/temple-schedule). '
        'Wednesday–Monday: Kakad Aarti 5:30–6:00 AM; Shree Darshan 6:00 '
        'AM–12:00 PM; Naivedhya 12:05–12:30 PM; Darshan 12:30–7:00 PM; '
        'Evening Dhup Aarti 7:00–7:10 PM; brief darshan 7:10–7:20 PM; '
        'Evening Aarti 7:30–8:00 PM; Darshan 8:00–9:50 PM; Shejaarti 9:50 '
        'PM (gabhara closes after Shejaarti). Tuesdays: early darshan '
        '3:15–4:45 AM; Kakad 5:00–5:30 AM; then extended day with night '
        'pooja/aarti ~9:00–10:10 PM, late darshan to ~11:30 PM, Shejaarti '
        '~11:45 PM (main doors close ~11:30 PM for devotees). Vinayaki / '
        'Sankashti / Maghi Jayanti / Bhadrapad Chaturthi have separate '
        'published boards — confirm on siddhivinayak.org.',
    latitude: 19.0169,
    longitude: 72.8304,
    specialities: [
      'Siddhi Vinayak — right-trunk Ganesha idol',
      'Consecrated 19 November 1801 (Laxman Vithu & Deubai Patil)',
      'Ashtavinayaka carvings on sanctum doors',
      'Distinct Tuesday & Chaturthi day boards (Trust)',
      'Among Mumbai’s highest-footfall living temples',
      'Official Trust portal for sevas / live darshan',
    ],
  ),

  Temple(
    name: 'Trimbakeshwar Temple',
    state: 'Maharashtra',
    city: 'Trimbak',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/trimbakeshwar-temple/800/600',
    description:
        'One of the twelve Jyotirlinga shrines of Shiva at Trimbak near '
        'Nashik, at the source region of the Godavari; the linga is '
        'traditionally described as three-faced (Brahma–Vishnu–Shiva).',
    story:
        'Trimbakeshwar (Tryambakeshwar) is one of the twelve Jyotirlinga '
        'sites of Shiva, set in the Trimbak hills of Nashik district near '
        'the traditional source of the Godavari. The extraordinary feature '
        'devotees note is a three-faced linga embodying the Tridev — '
        'Brahma, Vishnu, and Shiva — rather than a single plain linga '
        'form.\n\nThe present black-basalt temple was rebuilt in the '
        'mid-18th century by Peshwa Balaji Bajirao (Nanasaheb) on an older '
        'sacred site. Four directional mahadwars (east, west, south, '
        'north) organise pilgrim entry. Kushavarta kund and Brahmagiri / '
        'Godavari-source geography make Trimbak a key stop on Godavari and '
        'Nashik–Kumbh pilgrimage circuits; the town hosts major Simhastha '
        'Kumbh-related activity when the Nashik–Trimbak cycle '
        'falls.\n\nDaily worship under Shri Trimbakeshwar Devasthan Trust '
        'follows three named puja windows — morning Brahma puja, mid-day '
        'Mahadev puja, and evening Vishnu puja — with general darshan '
        'published as 05:30 AM–09:00 PM. Rudrabhishek and donation/VIP '
        'darshan passes are handled through Trust counters / online VIP '
        'booking on the Trust site. Maha Shivaratri and Shravan Mondays '
        'are among the year’s densest days.\n\nConfirm live clocks and '
        'pass rules on trimbakeshwartrust.com before travel; festival '
        'boards override ordinary hours.',
    location: 'Trimbakeshwar, Nashik district, Maharashtra 422212',
    timings:
        'Official Trust home board: temple open for darshan 05:30 AM–09:00 '
        'PM. Daily programme (Trust): Morning Puja — Puja of Brahma Deva '
        '~7:00–8:30 AM; Mid-Day Puja — Puja of Mahadev ~10:45 AM–12:30 PM; '
        'Evening Puja — Vishnu Puja ~7:00–8:30 PM (festival days may '
        'change). Donation/VIP darshan and Rudrabhishek via Trust counters '
        '/ online VIP page — confirm fees and QR-pass rules on '
        'trimbakeshwartrust.com before travel.',
    latitude: 19.9322,
    longitude: 73.5308,
    specialities: [
      'One of the twelve Jyotirlinga shrines',
      'Three-faced linga (Brahma–Vishnu–Shiva / Tridev)',
      'At Godavari source region (Brahmagiri / Kushavarta)',
      'Peshwa Balaji Bajirao (Nanasaheb) mid-18th-c. rebuild',
      'Three daily named pujas (Brahma / Mahadev / Vishnu)',
      'Nashik–Trimbak Simhastha Kumbh circuit stop',
    ],
  ),

  Temple(
    name: 'Bhimashankar Temple',
    state: 'Maharashtra',
    city: 'Bhimashankar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/bhimashankar-temple/800/600',
    description:
        'Jyotirlinga shrine of Shiva deep in the Sahyadri (Western Ghats) '
        'of Pune district, inside the Bhimashankar Wildlife Sanctuary '
        'landscape; traditional Dakini–Shakini Bhimashankar of the Dvadasa '
        'Jyotirlinga stotra.',
    story:
        'Bhimashankar is one of the twelve Jyotirlinga shrines, set high '
        'in the Sahyadris of Pune district amid the Bhimashankar Wildlife '
        'Sanctuary. Shaiva tradition links the site to Shiva’s destruction '
        'of the demon Tripurasura and to the origin of the Bhima river '
        'from divine sweat; the Dvadasa Jyotirlinga verse names “Dakinyam '
        'Bhimashankaram.” Kamalaja Mata (Parvati) has a related shrine in '
        'the same sacred landscape.\n\nThe stone temple fabric mixes '
        'Hemadpanti / Nagara elements; the garbha griha sits a few steps '
        'below courtyard level around a swayambhu linga. Maratha patronage '
        '(including traditions associating Chhatrapati Shivaji and later '
        'Peshwa grants) sustained worship; modern Devasthan administration '
        'publishes a full daily pooja/darshan board on '
        'shreebhimashankar.com.\n\nAbhishek and darshan rhythms typically '
        'include early worship, morning–afternoon abhishek windows, midday '
        'naivedya pause, afternoon worship pause, evening worship, and '
        'close by late evening. Construction / development notices on the '
        'official site have at times restricted public darshan to a '
        'morning-only window — always read the live banner. Kartik Purnima '
        '(Tripurari tradition), Maha Shivaratri, and Shravan Mondays are '
        'peak.\n\nCombine spiritual visit with monsoon-road and sanctuary '
        'advisories; fog and winding ghat roads affect timing.',
    location: 'Bhimashankar, Khed taluka, Pune district, Maharashtra 410509',
    timings:
        'Official Devasthan daily board (shreebhimashankar.com/en): Temple '
        'opens 5:00 AM; Worship 5:00–5:30 AM; Darshan & Abhishekam 5:30 '
        'AM–12:00 noon; Naivedyam puja 12:00–12:20 PM; Darshan & '
        'Abhishekam 12:20–2:45 PM; Worship 2:45–3:20 PM; Dev Darshan '
        '3:20–7:30 PM; Worship 7:30–8:00 PM; Dev Darshan 8:00–9:30 PM; '
        'Temple closes 9:30 PM. IMPORTANT: the same official site has '
        'posted construction notices restricting darshan to 7:00–11:00 AM '
        'when Sabhamandap/stair works run — and district notices have also '
        'restored full-day windows (e.g. Shravan). Always re-check the '
        'live banner on shreebhimashankar.com before travel.',
    latitude: 19.072,
    longitude: 73.535,
    specialities: [
      'One of the twelve Jyotirlinga shrines (Dakini–Shakini Bhimashankar)',
      'Sahyadri / Bhimashankar Wildlife Sanctuary setting',
      'Bhima river origin lore; Kamalaja Mata shrine nearby',
      'Hemadpanti–Nagara stone fabric; below-grade garbha griha',
      'Kartik Purnima Tripurasura-victory tradition',
      'Official full day board — subject to construction notices',
    ],
  ),

  Temple(
    name: 'Grishneshwar Temple',
    state: 'Maharashtra',
    city: 'Verul',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/grishneshwar-temple/800/600',
    description:
        'Twelfth Jyotirlinga shrine of Shiva at Verul near the Ellora '
        'Caves; compact red-stone temple closely paired with UNESCO Ellora '
        'on the same pilgrimage day-trip from Chhatrapati Sambhajinagar.',
    story:
        'Grishneshwar (also Ghushmeshwar / Grushneswar / Kusumeshwar) is '
        'counted as the twelfth and final Jyotirlinga in many listings of '
        'the Dvadasa Jyotirlinga. The living temple stands at Verul '
        'village, a short distance from the Ellora Caves (UNESCO), in '
        'Chhatrapati Sambhajinagar district (formerly '
        'Aurangabad).\n\nPuranic lore associated with the site centres on '
        'the devotee Ghushma / Kusuma and a restored child at the '
        'Shivalaya tank; historically the shrine was rebuilt and restored '
        'under Maratha patrons — commonly linked to Maloji Bhosale and '
        'later Ahilyabai Holkar. The compact south–north blend stone '
        'temple is among the smaller Jyotirlinga complexes, which '
        'intensifies queues on Shravan Mondays and Maha '
        'Shivaratri.\n\nIncredible India publishes opening 05:30 AM, '
        'closing 09:30 PM, with aarti markers at 5:30 AM, 12:00 PM, 7:00 '
        'PM, and 9:30 PM. Men are customarily asked to enter the garbha '
        'griha bare-chested; devotees may be allowed to touch the linga — '
        'follow on-site priest/security instructions. A midday break is '
        'claimed by some visitor guides and denied by others — treat '
        'continuous vs split afternoon hours as provisional and confirm '
        'locally.\n\nCombine with Ellora (closed Tuesdays) in one day when '
        'queues allow; Ellora ticket and Grishneshwar free-darshan rules '
        'differ.',
    location:
        'Verul (Ellora), Chhatrapati Sambhajinagar district, Maharashtra '
        '431102',
    timings:
        'Incredible India visitor board: Opening 05:30 AM, Closing 09:30 '
        'PM; Aarti markers listed at 5:30 AM, 12:00 PM, 7:00 PM, and 9:30 '
        'PM. Secondary guides often split darshan ~5:30 AM–12:00 PM and '
        '~4:00–9:30 PM (midday break) while others claim continuous hours '
        '— provisional / confirm on-site; no strong single official '
        'Devasthan English clock page found. Shravan and Maha Shivaratri '
        'commonly extend hours. Free general darshan; abhishek typically '
        'counter-booked locally. Thin official English pooja clock.',
    latitude: 20.0248,
    longitude: 75.1699,
    specialities: [
      'Twelfth Jyotirlinga (Grishneshwar / Ghushmeshwar)',
      'Adjacent to UNESCO Ellora Caves (Verul)',
      'Ahilyabai Holkar / Maratha rebuild associations',
      'Compact red-stone shrine; touchable linga custom often noted',
      'Shivalaya Tirtha tank lore',
      'Incredible India published open/close + aarti markers',
    ],
  ),

  Temple(
    name: 'Vitthal Rukmini Temple',
    state: 'Maharashtra',
    city: 'Pandharpur',
    deity: 'Vitthal',
    imageUrl: 'https://picsum.photos/seed/vitthal-rukmini-temple/800/600',
    description:
        'Principal Varkari pilgrimage temple of Vitthal (Vithoba) and '
        'Rukmini on the Chandrabhaga (Bhima) at Pandharpur; emotional '
        'heart of Maharashtra’s Wari tradition.',
    story:
        'Shri Vitthal Rukmini Mandir in Pandharpur is the spiritual centre '
        'of the Varkari sampradaya. Vitthal (Vithoba / Panduranga) — a '
        'standing form of Vishnu/Krishna with hands on hips — and Rukmini '
        '(Rakhumai) are the presiding deities. The Chandrabhaga (Bhima) '
        'river and the Namdev Payari (steps associated with the saint '
        'Namdev) structure pilgrim approach to the sanctum.\n\nDaily '
        'worship published by Shri Vitthal Rukmini Mandir Samiti opens '
        'with Namdev Payari door at 4:00 AM, Kakad Aarti and nitya pooja, '
        'then long darshan windows interrupted for Maha Naivedya, Poshakh '
        '(dressing), Dhoop Arati, and late-night Shej Arati. Ashadhi '
        'Ekadashi and Kartiki Ekadashi Waris bring hundreds of thousands '
        'of palkhi pilgrims from across Maharashtra; on those yatra peaks '
        'the temple often runs near-continuous access under Samiti crowd '
        'plans.\n\nArchitecture mixes Hemadpanti stone fabric with later '
        'additions; the black-stone Vitthal image and the adjacent Rukmini '
        'shrine define the darshan circuit. Dress and conduct follow '
        'Samiti boards; leather and improper attire are '
        'discouraged.\n\nConfirm daily_schedule.php and any temporary '
        'closure notices on vitthalrukminimandir.org before travel — yatra '
        'weeks and special sevas override ordinary clocks.',
    location:
        'Shri Vitthal Rukmini Mandir Samiti, Pandharpur, Solapur district, '
        'Maharashtra 413304',
    timings:
        'Official Mandir Samiti daily schedule '
        '(vitthalrukminimandir.org/daily_schedule.php): 4:00 AM — Opening '
        'of Shri’s Namdev Payari Door; 4:00–5:30 AM — Kakad Aarti and '
        'Nitya Pooja. Darshan: 6:00–11:00 AM (closed 10:45–11:00 AM for '
        'Maha Naivedya); 11:15 AM–4:30 PM (closed ~4:40–5:00 PM for Shri’s '
        'Poshakh); 5:00–11:15 PM. Evening: Dhoop Arati 6:45–7:00 PM; Shej '
        'Arati 12:00–1:00 AM. Namdev Payari Door remains closed 1:00–4:00 '
        'AM. Ashadhi / Kartiki yatra weeks and announced special closures '
        'override — confirm on vitthalrukminimandir.org.',
    latitude: 17.6746,
    longitude: 75.3237,
    specialities: [
      'Presiding deities Vitthal (Vithoba) & Rukmini (Rakhumai)',
      'Heart of the Varkari / Wari pilgrimage (Ashadhi & Kartiki Ekadashi)',
      'Namdev Payari approach steps',
      'On the Chandrabhaga (Bhima) at Pandharpur',
      'Official Samiti kakad / naivedya / poshakh / dhoop / shej board',
      'Standing Vitthal iconography (hands on hips)',
    ],
  ),

  Temple(
    name: 'Mumba Devi Temple',
    state: 'Maharashtra',
    city: 'Mumbai',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mumba-devi-temple/800/600',
    description:
        'Ancient city-goddess temple of Mumba Devi (Mumbaai) in '
        'Bhuleshwar–Zaveri Bazar; Mumbai’s name is traditionally derived '
        'from this Devi, patron of the Koli fishing community and the '
        'metropolis.',
    story:
        'Mumba Devi Temple (Mumbadevi Mandir) honours Goddess Mumba — a '
        'form of Shakti / Devi regarded as the gramadevata and patron of '
        'Mumbai. The city’s modern name is widely explained as an eponym '
        'of Mumba + Aai (“mother”). Koli fishermen, among Mumbai’s early '
        'inhabitants, especially revere her as guardian.\n\nThe present '
        'shrine in the dense Bhuleshwar / Zaveri Bazar cloth-and-jewellery '
        'quarter is commonly dated to an 18th-century rebuild on an older '
        'sacred site (earlier waterfront locations are remembered in local '
        'tradition as the island city grew). The colourful sikhara and '
        'compact sanctum sit amid bazaar lanes; subsidiary shrines '
        '(including Hanuman and other Devi forms noted on the Trust site) '
        'share the campus.\n\nShree Mumbadevi Mandir Charities publishes a '
        'clear named aarti board — Mangal, Main, Naivaidya, Dhoop, evening '
        'Main, and Shayan — and offers live darshan streaming on the '
        'official site. Magh, Chaitra, Ashadh (Gupt), and Ashvin Navratri '
        'periods, plus monthly Purnima observances, are among the busiest '
        'calendars.\n\nContinuous open/close span is less explicitly '
        'tabulated than the aarti list on the public English home page — '
        'treat full darshan-window edges as confirm-on-site while relying '
        'on the Trust aarti times.',
    location:
        'Mumbadevi Road, Zaveri Bazar / Bhuleshwar, Mumbai, Maharashtra '
        '400002',
    timings:
        'Official Trust aarti board (mumbadevi.org.in): Mangal Aarti 06:30 '
        'AM; Main Aarti 09:30 AM; Naivaidya Aarti 12:15 PM; Dhoop Aarti '
        '06:30 PM; Main Aarti 08:00 PM; Shayan Aarti 08:50 PM. Continuous '
        'darshan commonly runs with these aartis from morning open through '
        'Shayan / ~9:00 PM close (full open–close span thinner on public '
        'English pages — confirm on-site or Trust office). Navratri and '
        'festival days extend or shift boards — re-check mumbadevi.org.in.',
    latitude: 18.95,
    longitude: 72.83,
    specialities: [
      'Patron / city goddess of Mumbai (name-etymology tradition)',
      'Especially revered by the Koli community',
      'Bhuleshwar–Zaveri Bazar historic bazaar setting',
      'Official named six-aarti daily board',
      'Multiple Navratri observances (Magh / Chaitra / Ashadh / Ashvin)',
      'Official live-darshan streaming on Trust site',
    ],
  ),

  Temple(
    name: 'Mahalakshmi Temple',
    state: 'Maharashtra',
    city: 'Mumbai',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mahalakshmi-temple/800/600',
    description:
        'Prominent seaside Devi temple on Bhulabhai Desai Road at '
        'Mahalaxmi, Mumbai, housing Mahalakshmi with Mahakali and '
        'Mahasaraswati; major Navratri pilgrimage site for the city.',
    story:
        'Shri Mahalakshmi Temple on Bhulabhai Desai Road is one of '
        'Mumbai’s principal Shakti temples. The sanctum traditionally '
        'houses three goddesses — Mahalakshmi, Mahakali, and Mahasaraswati '
        '— worshipped as complementary forms of Devi. The temple faces the '
        'Arabian Sea near the historic Breach Candy / Mahalaxmi shoreline '
        'and gives its name to the surrounding neighbourhood and railway '
        'station.\n\nMaratha-period and later rebuilds shape the living '
        'complex pilgrims enter today; the site is woven into Bombay '
        'island lore of the Mahalaxmi vellard and reclaimed foreshore. '
        'Daily worship under Shri Mahalaxmi Temple Trust follows published '
        'darshan hours with mandatory closures during Morning Aarti, '
        'midday Naivedya, Evening Dhoop Aarti, and Evening '
        'Aarti.\n\nSharad Navratri is the year’s climax — Trust notices '
        'commonly extend closing toward midnight and queues stretch for '
        'hours. Fridays and Tuesdays also run busier than mid-week '
        'mornings. Photography inside the sanctum is prohibited; entry is '
        'free with optional booked special poojas.\n\nConfirm festival '
        'boards on mahalakshmi-temple.com before Navratri or Diwali travel.',
    location: 'Bhulabhai Desai Road, Mahalaxmi, Mumbai, Maharashtra 400026',
    timings:
        'Official Trust board (mahalakshmi-temple.com/darshan): Darshan '
        'hours 6:00 AM–10:00 PM daily, but temple remains closed for '
        'darshan during: Morning Aarti 6:45–7:30 AM; Naivedya 11:45 '
        'AM–12:20 PM; Evening Dhoop Aarti 6:15–6:40 PM; Evening Aarti '
        '7:20–7:45 PM. Sharad Navratri often extends toward midnight — '
        'confirm festival notice on the Trust site. Free entry; special '
        'poojas bookable via Trust channels.',
    latitude: 18.9777,
    longitude: 72.8068,
    specialities: [
      'Triad: Mahalakshmi, Mahakali, Mahasaraswati',
      'Seaside Bhulabhai Desai Road / Breach Candy setting',
      'Major Mumbai Sharad Navratri destination',
      'Official Trust aarti + naivedya closure board',
      'Free darshan; neighbourhood namesake (Mahalaxmi)',
      'Photography prohibited in sanctum',
    ],
  ),

  Temple(
    name: 'Jejuri Khandoba Temple',
    state: 'Maharashtra',
    city: 'Jejuri',
    deity: 'Khandoba',
    imageUrl: 'https://picsum.photos/seed/jejuri-khandoba-temple/800/600',
    description:
        'Hilltop Martand / Khandoba temple at Jejuri (Sonyachi Jejuri), '
        'the premier shrine of Khandoba — Maharashtra’s widely worshipped '
        'guardian deity often identified with a fierce form of Shiva / '
        'Martanda Bhairava.',
    story:
        'Jejuri’s Khandoba Temple (Shri Martand Mandir) crowns a fortified '
        'hill in Purandar taluka, Pune district. Khandoba (Malhari Martand '
        '/ Malhar) is among Maharashtra’s most popular folk-deities — a '
        'warrior-guardian figure commonly identified with Martanda '
        'Bhairava, a fierce aspect of Shiva, worshipped with turmeric '
        '(bhandara), sword lore, and dog companions. The turmeric-dusted '
        'steps and deepmalas give Jejuri its popular name Sonyachi Jejuri '
        '(“Golden Jejuri”).\n\nPilgrims climb a long stair flight through '
        'gateways to the stone temple and courtyard. Champa Shashti and '
        'other Khandoba yatras / jatras draw massive throngs; Somvati '
        'Amavasya and weekly patterns also swell footfall. Shri Martand '
        'Dev Sansthan publishes online darshan-pass booking with defined '
        'morning and afternoon windows and fixed donation-pass fees, and '
        'states it has no authorised booking agents.\n\nExpect turmeric '
        'play (bhandara) in festival seasons — clothing will stain. '
        'Footwear rules and prohibited-item boards are strict in the '
        'gadkot (fort-temple) enclosure. Combine with Ashtavinayak Morgaon '
        '(nearby) only with realistic travel time between hill '
        'queues.\n\nConfirm pass windows and yatra overrides on '
        'khandoba.com before travel.',
    location:
        'Shri Martand Dev Sansthan, Jejuri, Purandar taluka, Pune '
        'district, Maharashtra 412303',
    timings:
        'Official Shri Martand Dev Sansthan online-darshan rules '
        '(khandoba.com): Darshan time 7:00 AM–12:00 noon and 1:00 PM–7:00 '
        'PM; darshan-pass donation fees published as ₹100 / ₹200 per '
        'person; Aadhaar + mobile + email required for booking; Trust '
        'states no authorised agents. Yatra / jatra / Saturday–Sunday / '
        'holiday crowd plans can alter pass availability. Hill approach '
        'may open earlier for stairs — inner sanctum pass windows above '
        'are the Trust-published ones; confirm on khandoba.com.',
    latitude: 18.2722,
    longitude: 74.1603,
    specialities: [
      'Premier Khandoba (Malhari Martand) shrine — Sonyachi Jejuri',
      'Turmeric (bhandara) pilgrimage culture',
      'Hilltop gadkot stone temple with long stair ascent',
      'Champa Shashti and major Khandoba yatras',
      'Official online darshan-pass booking (Trust)',
      'Often paired with nearby Ashtavinayak Morgaon day trips',
    ],
  ),

  Temple(
    name: 'Morgaon Mayureshwar Temple',
    state: 'Maharashtra',
    city: 'Morgaon',
    deity: 'Ganesha',
    imageUrl: 'https://picsum.photos/seed/morgaon-mayureshwar-temple/800/600',
    description:
        'Shri Mayureshwar (Moreshwar) Ganpati temple at Morgaon — first '
        'and last stop of the Ashtavinayak circuit and a historic centre '
        'of the Ganapatya tradition.',
    story:
        'Shri Mayureshwar Temple at Morgaon (also Moreshwar) is the first '
        'and concluding shrine of Maharashtra’s Ashtavinayak yatra — the '
        'eight sacred Ganesha temples. The deity is Mayureshwar / '
        'Mayuresvara, Ganesha as the peacock-mounted slayer of the demon '
        'Sindhu (Siṁdhu) in local Purana-linked lore; the village name is '
        'popularly tied to mora (peacock).\n\nThe black-stone temple is '
        'often described with a distinctive plan (commonly called '
        'star-like / mandala-influenced in tourism literature) and an '
        'unusual Nandi in a Ganesha precinct, underscoring '
        'Shaiva–Ganapatya links. The swayambhu idol faces east, flanked by '
        'Riddhi and Siddhi in popular description. Administration falls '
        'under Chinchwad Devasthan Trust, which publishes named daily '
        'aarti and puja markers for Morgaon.\n\nGanesh Chaturthi '
        '(Bhadrapada), Maghi Ganesh Jayanti, palanquin processions on '
        'Shashti of Bhadrapada and Magha, and monthly Sankashti Chaturthi '
        'are major observances. Devotees often begin and end the full '
        'Ashtavinayak circuit here, treating Morgaon as the spiritual '
        'headquarters of the eightfold Ganesha pilgrimage.\n\nContinuous '
        'open/close darshan spans are clearer in secondary yatra guides '
        'than on the Trust’s English ritual list — pack Trust aarti times '
        'as authoritative and label long visiting windows as provisional.',
    location:
        'Chinchwad Deosthan Trust Office, Morgaon, Baramati taluka, Pune '
        'district, Maharashtra 412304',
    timings:
        'Official Chinchwad Devasthan Trust ritual markers '
        '(morgaon.chinchwaddeosthan.org): 5:00 AM Kakad Aarti; 5:30 AM '
        'Prakshal Puja; 7:00 AM Panchaopachar Puja, Naivedya & Dhuparati; '
        '12:00 PM Mahapuja & Mahanaivedya; 3:00 PM Prakshal Puja & '
        'Poshakh; 8:00 PM Dhuparati & Aarti to Avaran deities; 8:30 PM '
        'Maha Aarti & Mantrapushpa; 10:30 PM Shejarati. Secondary '
        'Ashtavinayak guides commonly cite visiting/darshan ~5:00 AM–12:00 '
        'PM and ~3:00–10:00 PM (provisional continuous windows — confirm '
        'locally / Trust office). Festival days (esp. Bhadrapada '
        'Chaturthi) override.',
    latitude: 18.276,
    longitude: 74.321,
    specialities: [
      'First and last temple of the Ashtavinayak circuit',
      'Mayureshwar / Moreshwar — peacock-mounted Ganesha lore',
      'Historic Ganapatya centre (Chinchwad Devasthan Trust)',
      'Unusual Nandi presence in a Ganesha temple precinct',
      'Bhadrapada & Magha Chaturthi / Shashti processions',
      'Trust-published kakad through shejarati ritual board',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  RAJASTHAN
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 11 — new temples, not enrichments of existing rows.
  // Dilwara is a Jain tirtha, not a Hindu temple. Cover imageUrl
  // values are picsum placeholders. Commons candidates stay in
  // docs/rajasthan-sample-research.md, not Storage paths.
  Temple(
    name: 'Brahma Temple',
    state: 'Rajasthan',
    city: 'Pushkar',
    deity: 'Brahma',
    imageUrl: 'https://picsum.photos/seed/brahma-temple/800/600',
    description:
        'Rare living temple to the creator-god Brahma beside sacred '
        'Pushkar Lake, with a distinctive red shikhara and marble sanctum; '
        'Kartik Purnima bath-and-darshan is the year’s peak.',
    story:
        'Jagatpita Brahma Mandir at Pushkar is among the very few '
        'prominent temples in India dedicated to Brahma. Puranic tradition '
        'ties the shrine to a lotus petal that fell here when Brahma slew '
        'the demon Vajranabha, creating Pushkar Lake; a yajna legend '
        'explains why Brahma’s earthly worship concentrates at this tirtha '
        'after Savitri’s curse.\n\nThe present marble-and-stone fabric is '
        'commonly dated to the 14th century with later rebuilding. A red '
        'shikhara and hamsa (swan) motif mark the approach; the garbha '
        'griha houses a four-faced chaumurti of Brahma with Gayatri, and '
        'silver-coin floors and a silver turtle in the mandapa are '
        'familiar pilgrim offerings. Only sanyasi priests traditionally '
        'enter the innermost sanctum — householder devotees offer from the '
        'outer hall.\n\nDaily worship includes Mangala, Sandhya, and Ratri '
        'Shayan aartis keyed to sunrise and sunset. Special rites mark '
        'every Purnima and Amavasya. Kartik Purnima coincides with the '
        'famous Pushkar Camel Fair: lakhs bathe in the lake and queue for '
        'Brahma darshan.\n\nA visit traditionally continues to Gayatri and '
        'Savitri hill shrines across the lake. Photography inside the '
        'sanctum is generally barred; follow Devasthan / on-site boards.',
    location:
        'Brahma Temple Road, near Pushkar Lake, Pushkar, Ajmer district, '
        'Rajasthan 305022',
    timings:
        'Rajasthan Devasthan profile / widely cited board: Summer ~06:00 '
        'AM–09:00 PM; Winter ~06:30 AM–08:30 PM, with afternoon closure '
        'commonly ~01:30–03:00 PM. Named aartis (secondary compilations + '
        'Wikipedia summary of temple board): Mangala ~2 hours before '
        'sunrise; Sandhya ~40 minutes after sunset; Ratri Shayan ~5 hours '
        'after sunset. Kartik Purnima / Pushkar Fair extends hours and '
        'queues — confirm locally or via Rajasthan Tourism / Devasthan '
        'notices before travel. Entry free.',
    latitude: 26.4872,
    longitude: 74.5542,
    specialities: [
      'One of India’s few major Brahma temples',
      'Linked to sacred Pushkar Lake bath pilgrimage',
      'Red shikhara and hamsa motif; four-faced Brahma murti with Gayatri',
      'Kartik Purnima fair + Pushkar Camel Fair peak',
      'Sanyasi priesthood for inner-sanctum service',
      'Companion Savitri and Gayatri hill temples',
    ],
  ),

  Temple(
    name: 'Eklingji Temple',
    state: 'Rajasthan',
    city: 'Kailashpuri (near Udaipur)',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/eklingji-temple/800/600',
    description:
        'Historic Shaiva complex about 22 km north of Udaipur; Eklingji (a '
        'four-faced Shiva lingam) is the kuldevata of Mewar, traditionally '
        'served by the Maharana as diwan.',
    story:
        'Eklingji (Shri Ekling Ji) at Kailashpuri is the tutelary deity of '
        'the Mewar (Sisodia) house. Tradition credits Bappa Rawal with an '
        'early 8th-century foundation; the complex was rebuilt after '
        'medieval destructions, notably under Rana Hamir, Rana Kumbha, and '
        'Rana Raimal, who installed the present black-stone, four-faced '
        'lingam in the main sanctum.\n\nThe walled campus holds dozens of '
        'shrines — often cited as ~108 — including Vishnu and other '
        'subsidiary temples beside the main Shiva shrine. Devasthan '
        'Department and Mewar religious administration oversee worship. '
        'Maha Shivaratri and the temple’s Patotsav draw large local '
        'crowds; Saturdays and Sundays are busy weekly days.\n\nDarshan is '
        'typically offered in morning, midday, and evening windows rather '
        'than continuous open hours, with multiple aarti markers through '
        'the day. Exact clocks on secondary tourism sites conflict '
        'slightly — treat visitor guides as provisional and confirm on '
        'site or via Devasthan Udaipur contacts before travel.\n\nLeather '
        'items and photography rules follow posted boards; modest dress is '
        'expected.',
    location:
        'Shri Eklingji Temple, Kailashpuri / Eklingnagar, Girwa tehsil, '
        'Udaipur district, Rajasthan 313202',
    timings:
        'Provisional visitor listings (tourism compilations; no single '
        'firm public English continuous clock found): common darshan '
        'windows ~04:30–07:00 AM, ~10:30 AM–01:30 PM, and '
        '~05:00/05:30–07:30/08:00 PM. Named aarti markers often cited: '
        'morning ~05:30, 08:15, 09:15, 11:30 AM; afternoon ~03:30 & 04:30 '
        'PM; evening ~05:00 & 06:30 PM. Maha Shivaratri and festival days '
        'override — confirm locally / Devasthan Udaipur before travel. '
        'Entry free. Thin official English clock.',
    latitude: 24.746,
    longitude: 73.7222,
    specialities: [
      'Kuldevata of Mewar; Maharana traditionally diwan of Eklingji',
      'Four-faced black-stone Shiva lingam in main sanctum',
      'Large walled complex with many subsidiary shrines',
      'Rebuilt under Hamir, Kumbha, and Raimal after medieval damage',
      'Maha Shivaratri and Patotsav peak days',
      '~22 km from Udaipur on the Nathdwara road corridor',
    ],
  ),

  Temple(
    name: 'Shrinathji Temple',
    state: 'Rajasthan',
    city: 'Nathdwara',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/shrinathji-temple/800/600',
    description:
        'Principal Pushtimarg haveli of Shrinathji — the seven-year-old '
        'Krishna lifting Govardhan — at Nathdwara; darshan is through '
        'short, named jhankis rather than continuous open hours.',
    story:
        'Shrinathji at Nathdwara is the black stone svarupa of Krishna as '
        'the divine child who lifted Govardhan Hill. Vallabhacharya’s '
        'Pushtimarg (Shuddhadvaita) tradition treats the shrine as '
        'Thakurji’s house: priests wake, dress, feed, rest, and put the '
        'Lord to sleep through the day.\n\nThe murti was brought from Braj '
        'to Mewar in the 17th century to protect it during Aurangzeb’s '
        'campaigns and was installed at Nathdwara (then Sinhad). The town '
        'grew around the haveli; pichwai paintings, mithai, and pilgrimage '
        'commerce remain hallmarks.\n\nDevotees take darshan during eight '
        'classical jhankis — Mangala, Shringar, Gwal, Rajbhog, Uthapan, '
        'Bhog, Aarti/Sandhya, and Shayan — each open only briefly. Exact '
        'clocks change daily with the lunar calendar and season; the '
        'temple trust publishes the day’s board on nathdwaratemple.org. '
        'Janmashtami, Annakut, and other Pushtimarg festivals swell '
        'crowds.\n\nMobiles and cameras are typically barred inside; '
        'follow trust security. Book cottages/dharamshalas via the '
        'official portal when needed.',
    location:
        'Shrinathji Temple (Thakurji ki Haveli), Nathdwara, Rajsamand '
        'district, Rajasthan 313301',
    timings:
        'Official trust home board example (nathdwaratemple.org — times '
        'change daily; re-check date picker): Mangala ~05:45–06:30 AM; '
        'Shringar ~07:30–08:00 AM; Rajbhog ~11:15 AM–12:30 PM; Uthapan '
        '~03:45–04:00 PM; Bhog-Aarti ~04:30–05:55 PM; Shayan ~07:15–08:00 '
        'PM (Gwal and other jhankis also scheduled). Historic Devasthan '
        'summer/winter columns differ slightly. Miss a window and wait for '
        'the next — doors close between jhankis. Confirm same-day board '
        'before travel.',
    latitude: 24.929,
    longitude: 73.8151,
    specialities: [
      'Pushtimarg svarupa of Shrinathji (Krishna–Govardhan)',
      'Eight named daily jhankis (not continuous darshan)',
      '17th-century relocation from Braj to Mewar',
      'Official date-wise darshan board (nathdwaratemple.org)',
      'Pichwai painting and Annakut traditions',
      'Managed as Thakurji ki Haveli',
    ],
  ),

  Temple(
    name: 'Karni Mata Temple',
    state: 'Rajasthan',
    city: 'Deshnok',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/karni-mata-temple/800/600',
    description:
        'Famous Charan-community shrine of Karni Mata (revered as a form '
        'of Durga) at Deshnok, known worldwide for thousands of sacred '
        'rats (kabbas) that share the marble courtyard with devotees.',
    story:
        'Karni Mata Temple at Deshnok honours Karni Mata, a 14th-century '
        'Charan mystic and warrior-sage widely regarded as an incarnation '
        'of Durga. Local tradition holds she laid foundation stones for '
        'the Mehrangarh and Bikaner forts at the request of Rathore '
        'rulers. The living temple fabric is associated with '
        'late-16th-century patronage (often linked to Rao Jaitasi / later '
        'marble work under Maharaja Ganga Singh).\n\nThe shrine is unique '
        'for its kabbas — sacred rats believed to be reincarnated devotees '
        'of Karni Mata’s clan. White rats are considered especially '
        'auspicious. Devotees walk barefoot, offer sweets and milk, and '
        'take care not to harm any animal; killing a rat traditionally '
        'requires replacing it with a silver votive.\n\nDepawat Charan '
        'priests serve in rotation. Bi-annual Navratri fairs (Chaitra and '
        'Ashwin) draw thousands. Rajasthan Tourism lists continuous '
        'opening from early morning to late night with free '
        'entry.\n\nVisitor etiquette: remove shoes, watch your step, and '
        'follow photo rules posted at the gate.',
    location:
        'Karni Mata Temple, Deshnok (Deshnoke), ~30 km from Bikaner, '
        'Bikaner district, Rajasthan 334801',
    timings:
        'Rajasthan Tourism / Devasthan visitor board: generally open '
        '~04:00/05:00 AM–10:00 PM daily; continuous darshan without a long '
        'midday break is widely reported. Named aarti markers (secondary '
        'listings): Mangala ~04:00–05:00 AM; Bhog ~08:00 AM; Shringar '
        '~03:45 PM; Sandhya ~07:00 PM. Navratri fairs override ordinary '
        'flow — confirm locally. Entry free.',
    latitude: 27.7906,
    longitude: 73.3408,
    specialities: [
      'Sacred rats (kabbas) share the temple with devotees',
      'Karni Mata of the Charan community — form of Durga',
      'White rat sighting considered highly auspicious',
      'Bi-annual Navratri fairs (Chaitra & Ashwin)',
      'Marble temple with silver doors; ~30 km from Bikaner',
      'Linked to Rathore fort-foundation lore',
    ],
  ),

  Temple(
    name: 'Govind Dev Ji Temple',
    state: 'Rajasthan',
    city: 'Jaipur',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/govind-dev-ji-temple/800/600',
    description:
        'Jaipur’s aradhya Krishna temple of Radha–Govind Dev Ji inside the '
        'City Palace precinct; seven named daily jhankis structure darshan '
        'for the city’s royal and popular devotion.',
    story:
        'Govind Dev Ji (Radha–Govind) is the aradhya deity of Jaipur. The '
        'murti tradition links to the famed Govind Dev temple of '
        'Vrindavan; Sawai Jai Singh II brought the worship to his new '
        'capital, and the present temple stands in the City Palace / Jaleb '
        'Chowk area as a living centre of Gaudiya–Jaipur Krishna '
        'seva.\n\nDaily life follows seven jhankis — Mangla, Dhoop, '
        'Shringar, Rajbhog, Gwal, Sandhya, and Shayan — when the couple '
        'form of Radha–Govind is revealed. Between windows the sanctum '
        'closes for seva. The temple publishes live darshan and advance '
        'timetables on govinddevji.net; summer and winter spans '
        'differ.\n\nJanmashtami, Holi, Diwali, and special shringar days '
        'pack the courtyard. The temple remains free for general darshan; '
        'apps and UPI donation channels are promoted by the '
        'management.\n\nSecurity screening is routine at palace-precinct '
        'gates — travel light and follow dress norms.',
    location:
        'Shri Govind Dev Ji Temple, Jaleb Chowk / City Palace complex, '
        'Jaipur, Rajasthan 302002',
    timings:
        'Typical seasonal visitor board (compilations aligned with '
        'govinddevji.net jhanki names): Summer morning darshan often '
        '~04:30 AM–12:00 PM and evening ~05:45–09:30 PM; Winter often '
        '~05:00 AM–12:15 PM and ~05:00–08:45 PM, with long midday seva '
        'closure. Named aarti/jhanki markers commonly listed: Mangla '
        '~05:00–05:15 AM; Dhoop ~07:45–09:00 AM; Shringar ~09:30–10:15 AM; '
        'Rajbhog ~10:45–11:15/11:45 AM; Gwal ~05:00–05:15 PM; Sandhya '
        '~05:45–06:45 PM; Shayan ~08:00–08:15 PM. Advance day board on '
        'govinddevji.net/JHAKIA.HTM overrides — confirm before travel.',
    latitude: 26.926,
    longitude: 75.8236,
    specialities: [
      'Aradhya Krishna of Jaipur (Radha–Govind)',
      'Seven named daily jhankis',
      'Located in City Palace / Jaleb Chowk precinct',
      'Linked to Vrindavan Govind Dev tradition via Sawai Jai Singh II',
      'Live darshan and timetable on govinddevji.net',
      'Major Janmashtami and Holi celebrations',
    ],
  ),

  Temple(
    name: 'Birla Mandir (Lakshmi Narayan Temple)',
    state: 'Rajasthan',
    city: 'Jaipur',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/birla-mandir-lakshmi-narayan-temple/800/600',
    description:
        'Modern white-marble Lakshmi–Narayan temple built by the Birla '
        'family below Moti Dungri, with stained-glass panels, subsidiary '
        'shrines, and panoramic city views — a popular Jaipur evening stop.',
    story:
        'Birla Mandir Jaipur (Shri Lakshmi Narayan) was built by the Birla '
        'family and consecrated in the late 1980s on land near Moti Dungri '
        'Fort. White marble halls enshrine Vishnu as Narayan with Lakshmi; '
        'walls and windows carry carved and stained-glass scenes from '
        'Hindu epics, and secondary shrines honour many deities and '
        'spiritual figures — reflecting the Birla temples’ inclusive '
        'iconographic style.\n\nUnlike medieval Rajasthan tirthas, this is '
        'a contemporary pilgrimage-and-tourist temple: open plazas, '
        'evening illumination, and easy road access make it a standard '
        'Jaipur circuit stop with City Palace and Albert Hall.\n\nDaily '
        'worship includes morning and evening aartis; general darshan runs '
        'in morning and evening sessions with an afternoon break on most '
        'visitor listings. Janmashtami and Diwali light displays draw '
        'crowds.\n\nEntry is free; photography of exteriors is common, but '
        'follow any inner-sanctum restrictions posted on site.',
    location:
        'Birla Mandir (Shri Lakshmi Narayan Temple), near Moti Dungri '
        'Fort, Tilak Marg, Jaipur, Rajasthan 302004',
    timings:
        'Provisional tourism listings (no single dense official English '
        'aarti PDF found): commonly ~08:00 AM–12:00 PM and ~04:00–09:00 PM '
        '(some guides cite opening from ~06:00 AM and evening aarti ~07:00 '
        'PM; Incredible India-style listings sometimes differ). Festival '
        'evenings may extend. Confirm on-site board the day of visit. '
        'Entry free. Thin official English clock.',
    latitude: 26.8922,
    longitude: 75.8155,
    specialities: [
      'Birla-built white marble Lakshmi–Narayan temple',
      'Stained-glass and carved epic panels',
      'Set below Moti Dungri Fort with city views',
      'Inclusive subsidiary shrines typical of Birla mandirs',
      'Popular evening illuminated facade',
      'Late-1980s consecration — modern Jaipur landmark',
    ],
  ),

  Temple(
    name: 'Dilwara Temples',
    state: 'Rajasthan',
    city: 'Mount Abu',
    deity: 'Jain Tirthankaras',
    // KAN-77: verified Commons thumbs — tools/photo-packs/dilwara-temples/
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Dilwara_temple_in_mount_abu.jpg/1280px-Dilwara_temple_in_mount_abu.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Dilwara_temple_in_mount_abu.jpg/1280px-Dilwara_temple_in_mount_abu.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/DILWADA_TEMPLE.JPG/1280px-DILWADA_TEMPLE.JPG',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Dilwara_Temple%2C_Mount_Abu%2C_Rajasthan.jpg/1280px-Dilwara_Temple%2C_Mount_Abu%2C_Rajasthan.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Marble_Carved_Ceilings_Showing_Jain_Mythology_in_Dilwara_Temple%2C_Mt._Abu.jpg/1280px-Marble_Carved_Ceilings_Showing_Jain_Mythology_in_Dilwara_Temple%2C_Mt._Abu.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/The_Jain_temples_on_mount_Abu%2C_Rajasthan.jpg/1280px-The_Jain_temples_on_mount_Abu%2C_Rajasthan.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Aisle_in_a_Jain_temple%2C_mount_Abu%2C_Rajasthan.jpg/1280px-Aisle_in_a_Jain_temple%2C_mount_Abu%2C_Rajasthan.jpg',
    ],
    description:
        'Cluster of five marble Jain temples at Mount Abu (11th–16th '
        'centuries), celebrated for unmatched marble carving — Vimal '
        'Vasahi (Adinath), Luna Vasahi (Neminath), and later Parshvanath, '
        'Mahavir, and Pittalhar shrines.',
    story:
        'The Dilwara (Delwara) temples on Mount Abu are among Jainism’s '
        'supreme architectural achievements. Built chiefly between the '
        '11th and 13th centuries under Solanki / Vaghela patronage — Vimal '
        'Shah’s Vimal Vasahi for Adinath and the Tejpal brothers’ Luna '
        'Vasahi for Neminath are the artistic peaks — later Parshvanath, '
        'Mahavir Swami, and Pittalhar temples completed the five-temple '
        'ensemble.\n\nFrom outside the complex looks modest; inside, '
        'ceilings, pillars, and lotus domes are carved from white marble '
        'with extraordinary fineness. The site remains an active Jain '
        'tirtha: early mornings are reserved for Jain devotees’ puja, '
        'while general tourists are admitted in the afternoon under strict '
        'conduct rules.\n\nNo Hindu garbha cult operates here; inclusion '
        'in this directory is for Rajasthan’s iconic sacred architecture '
        'and living Jain pilgrimage. Leather, phones, and cameras are '
        'prohibited; modest dress covering shoulders and knees is '
        'required.\n\nIncredible India and Mount Abu tourism list free '
        'entry with devotee morning / tourist afternoon splits.',
    location:
        'Dilwara Jain Temples, near Mount Abu, Sirohi district, Rajasthan '
        '307501',
    timings:
        'Incredible India / Mount Abu visitor guidance: Jain devotees '
        'generally 06:00 AM–12:00 noon for worship; general tourists '
        'typically ~12:00 noon–05:00/06:00 PM. Overall campus often cited '
        '06:00 AM–06:00 PM. Entry free. Photography, mobile phones, and '
        'leather items prohibited. Confirm locally — tourist cut-off times '
        'vary slightly by source.',
    latitude: 24.6093,
    longitude: 72.7231,
    specialities: [
      'Five marble Jain temples (Adinath, Neminath, Parshvanath, Mahavir, Pittalhar)',
      'Vimal Vasahi (11th c.) and Luna Vasahi (13th c.) masterpiece ceilings',
      'Active Jain tirtha — morning puja for devotees',
      'Tourist afternoon entry with strict no-phone/no-leather rules',
      'Mount Abu hill-station setting',
      'Iconic Rajasthan sacred architecture (Jain, not Hindu)',
    ],
  ),

  Temple(
    name: 'Salasar Balaji',
    state: 'Rajasthan',
    city: 'Salasar',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/salasar-balaji/800/600',
    description:
        'Major Hanuman (Balaji) siddhpeeth at Salasar on the '
        'Jaipur–Bikaner highway, famed for a unique bearded murti and huge '
        'Chaitra / Ashwin Purnima fairs.',
    story:
        'Salasar Balaji (Salasar Dham) is among Rajasthan’s most visited '
        'Hanuman temples. Local legend recounts that a plough struck a '
        'buried murti of Balaji near Asota; dreams directed its '
        'installation at Salasar under the care of Mohandas Ji and others. '
        'The self-manifest idol is distinctive for beard and moustache — a '
        'feature devotees and temple publicity often highlight.\n\nDaily '
        'seva includes Mangala, Rajbhog, Dhoop/Mohandas aartis, Sandhya, '
        'Bal Bhog, and Shayan. Tuesday Rajbhog is especially popular. Two '
        'large fairs at Chaitra Purnima (Hanuman Janmotsav) and Ashwin / '
        'Sharad Purnima pack the town; dozens of dharamshalas serve '
        'pilgrims.\n\nMultiple websites claim official status and publish '
        'slightly different clocks (darshan spans and aarti minutes). '
        'Treat published times as provisional and confirm on site or via '
        'the managing seva samiti boards when you arrive.\n\nOfferings of '
        'churma and laddu are traditional; keep queues orderly on fair '
        'days.',
    location:
        'Shree Salasar Balaji Mandir, Salasar, near Sujangarh, Churu '
        'district, Rajasthan 331502',
    timings:
        'Provisional — conflicting official-claiming sites: (A) '
        'shreesalasarbalajimandir.com lists darshan ~06:00 AM–09:00 PM '
        'with seasonal Mangla/Mohandas/Rajbhog/Dhoop/Sandhya/Bal '
        'Bhog/Shayan aartis (Tue extra Rajbhog); (B) '
        'salasarbalaji.org-style boards cite Pat Khaulana ~04:30 AM, '
        'Mangal Aarti ~05:00 AM, Rajbhog ~10:30 AM, evening aartis '
        '~06:00–10:00 PM; (C) another mandir site cites darshan ~06:00 '
        'AM–08:45 PM with Mangala ~05:30 AM, Sandhya ~07:10 PM, Shayan '
        '~10:00 PM. Use on-site board; Chaitra & Ashwin Purnima fairs '
        'override. Entry free. Thin official English clocks conflict '
        'across sites.',
    latitude: 27.7258,
    longitude: 74.7243,
    specialities: [
      'Bearded Hanuman (Balaji) murti — widely noted as unique',
      'Chaitra Purnima and Ashwin/Sharad Purnima mega fairs',
      'Tuesday Rajbhog especially popular',
      'On Jaipur–Bikaner highway near Sujangarh (Churu)',
      'Large dharamshala infrastructure for pilgrims',
      'Churma offering tradition from foundation lore',
    ],
  ),

  Temple(
    name: 'Khatushyam Temple',
    state: 'Rajasthan',
    city: 'Khatu',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/khatushyam-temple/800/600',
    description:
        'Major pilgrimage to Khatushyam Ji — Barbarika of the Mahabharata, '
        'worshipped as a Krishna/Vishnu form (Shyam) — at Khatu in Sikar; '
        'Phalguna Mela is the year’s largest gathering.',
    story:
        'Khatushyam Ji is identified with Barbarika (Belarsen), the '
        'grandson of Bhima who offered his head to Krishna before '
        'Kurukshetra and was blessed to be worshipped as Shyam in '
        'Kaliyuga. Devotees call him Hare ka Sahara — refuge of the '
        'defeated — and flock to Khatu for mannat fulfilment.\n\nThe '
        'present temple in Khatu (Sikar) houses the Shyam shila / murti '
        'tradition with vibrant shringar; bhajans and the call “Jai Shri '
        'Shyam” fill the lanes. Committee sites (e.g. shrishyammandir.com) '
        'publish darshan photos and notices; seasonal summer/winter aarti '
        'tables circulate widely (Mangala, Shringar, Bhog, Sandhya, '
        'Shayan).\n\nPhalguna Mela (around Holi) and Ekadashi days see the '
        'heaviest crowds; some guides note near-24-hour access on major '
        'Ekadashis. Ordinary days usually follow morning and evening '
        'darshan spans with a midday bhog closure.\n\nConfirm the live '
        'committee board before travel — published English clocks are '
        'thinner than the Hindi notice culture on site.',
    location:
        'Shri Khatu Shyam Ji Temple, Khatu, Sikar district, Rajasthan '
        '332602',
    timings:
        'Provisional seasonal boards (khatu.in / visitor compilations; '
        'confirm shrishyammandir.com / on-site): Summer (approx Apr–Sep) '
        'Mangala ~04:30 AM, Shringar ~07:00 AM, Bhog ~12:30 PM, Sandhya '
        '~07:30 PM, Shayan ~10:00 PM; Winter (approx Oct–Mar) Mangala '
        '~05:30 AM, Shringar ~08:00 AM, Bhog ~12:30 PM, Sandhya ~06:30 PM, '
        'Shayan ~09:00 PM. Darshan often cited ~04:30/05:30 AM–12:30 PM '
        'and ~04:00–09:00/10:00 PM. Ekadashi and Phalguna Mela may run '
        'extended or near-continuous access — verify. Entry free.',
    latitude: 27.3644,
    longitude: 75.4036,
    specialities: [
      'Barbarika worshipped as Shyam (Krishna/Vishnu form)',
      'Title Hare ka Sahara — refuge of the defeated',
      'Phalguna Mela peak pilgrimage',
      'Five named daily aartis (Mangala to Shayan)',
      'Sikar district tirtha on Jaipur–Sikar corridor',
      'Strong bhajan and shringar culture',
    ],
  ),

  Temple(
    name: 'Mehandipur Balaji Temple',
    state: 'Rajasthan',
    city: 'Mehandipur (Dausa)',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/mehandipur-balaji-temple/800/600',
    description:
        'Hugely popular Balaji (child-form Hanuman) siddhpeeth on the '
        'Jaipur–Agra highway in Dausa, visited for relief from '
        'afflictions; official FAQ publishes firm darshan and aarti '
        'windows.',
    story:
        'Mehandipur (Mehandipur) Balaji in Dausa district is a major '
        'Hanuman pilgrimage of northern India. Tradition holds that Balaji '
        'manifested here in bal (child) form centuries ago; the complex '
        'also venerates Pret Raj and Bhairav in associated shrines. '
        'Devotees come seeking relief from mental and spiritual distress, '
        'always under temple discipline that emphasises faith and darshan '
        'rather than priest-led healing claims.\n\nThe official trust site '
        '(shribalajimehandipur.org) states the temple opens about 06:00 '
        'AM–09:00 PM, lists morning and evening aartis, and notes that on '
        'Monday, Wednesday, and Friday darshan closes ~04:00–06:00 PM for '
        'special chola/shringar. Sawamani (large-scale cooked prasad, '
        'including Rajbhog and Chhappan Bhog) can be booked at the office '
        'or online and is offered around midday.\n\nPhotography and mobile '
        'use inside are prohibited. No entry fee or VIP darshan ticket '
        'exists per the FAQ. Hanuman Jayanti, Holi, and Dussehra bring '
        'special shringar and crowds.\n\nStay in nearby '
        'dharamshalas/hotels — the temple itself does not run lodging.',
    location:
        'Shri Mehandipur Balaji Temple, Ghata Mehandipur, Sikrai tehsil, '
        'Dausa district, Rajasthan 321610',
    timings:
        'Official FAQ (shribalajimehandipur.org): temple ~06:00 AM–09:00 '
        'PM. Morning aarti ~06:00–06:40 AM; morning darshan ~07:00–11:00 '
        'AM; afternoon darshan ~12:00–06:50 PM; evening aarti ~06:50–07:30 '
        'PM; evening darshan ~06:50–09:00 PM. On Monday, Wednesday & '
        'Friday darshan closed ~04:00–06:00 PM for special Balaji '
        'chola/shringar. Aarti times: darshan paused — stand in place. '
        'Sawamani typically offered ~12:30 PM when booked. Confirm '
        'FAQ/board before travel.',
    latitude: 26.9483,
    longitude: 76.794,
    specialities: [
      'Bal (child) form Hanuman siddhpeeth',
      'Official FAQ with firm darshan & aarti windows',
      'Mon/Wed/Fri afternoon chola-shringar closure',
      'Sawamani prasad booking (Rajbhog / Chhappan Bhog etc.)',
      'Associated Pret Raj and Bhairav worship in the complex',
      'On Jaipur–Agra NH-21 corridor (Dausa)',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  WEST BENGAL
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 12 — new temples, not enrichments of existing rows.
  // Belur Math stays in the Ramakrishna–Vedanta tradition; Mayapur
  // stays Gaudiya Vaishnava. Cover imageUrl values are picsum
  // placeholders. Commons candidates: docs/west-bengal-sample-research.md.
  Temple(
    name: 'Kalighat Kali Temple',
    state: 'West Bengal',
    city: 'Kolkata',
    deity: 'Devi (Kali)',
    imageUrl: 'https://picsum.photos/seed/kalighat-kali-temple/800/600',
    description:
        'Historic Kali shrine in south Kolkata and one of the best-known '
        'Shakti Peethas, centred on an ath-chala Bengal temple beside the '
        'old Adi Ganga pilgrimage landscape.',
    story:
        'Kalighat is one of eastern India\'s defining Shakta pilgrimage '
        'centres. In the temple\'s Shakti Peetha tradition, the toes of '
        'Sati\'s right foot fell here; the presiding Kali is worshipped '
        'with a golden tongue and distinctive iconography, while '
        'Nakuleshwar Bhairava is associated with the sacred site. The name '
        'joins Kali with ghat, recalling the riverbank setting on the old '
        'course of the Bhagirathi–Adi Ganga.\n\nAlthough literary '
        'references to Kalighat reach back several centuries, the present '
        'temple was completed in 1809 under patronage associated with the '
        'Sabarna Roy Chowdhury family. Its ath-chala form belongs to '
        'Bengal\'s regional temple architecture. The complex includes the '
        'Natmandir, Jor Bangla viewing platform, Kundupukur sacred tank, '
        'Shyamrai Radha-Krishna shrine, and nearby Nakuleshwar '
        'Mahadev.\n\nDaily darshan is divided into morning and evening '
        'sessions around an afternoon closure. Kali Puja, Poila Baisakh, '
        'Durga Puja, Snan Yatra, and amavasya days draw particularly heavy '
        'queues. Incredible India supplies the firm public clock used '
        'here; named aarti minutes reported by guide sites are not treated '
        'as authoritative.',
    location: 'Anami Sangha, Kalighat, Kolkata, West Bengal 700026',
    timings:
        'Incredible India: 5:00 AM–2:00 PM and 5:00–10:30 PM daily, with '
        'the temple closed 2:00–5:00 PM. Kali Puja, Poila Baisakh, '
        'amavasya and other festival arrangements can extend or alter '
        'access; confirm at the temple before travel.',
    latitude: 22.52,
    longitude: 88.34194,
    specialities: [
      'Major Shakti Peetha associated with Sati\'s right toes',
      'Distinctive Kali image with golden tongue',
      'Present ath-chala Bengal temple completed in 1809',
      'Natmandir, Jor Bangla and Kundupukur sacred tank',
      'Kali Puja, Poila Baisakh and amavasya pilgrimages',
      'Historic Adi Ganga / Kalighat sacred landscape',
    ],
  ),

  Temple(
    name: 'Dakshineswar Kali Temple',
    state: 'West Bengal',
    city: 'Kolkata',
    deity: 'Devi (Bhavatarini Kali)',
    imageUrl: 'https://picsum.photos/seed/dakshineswar-kali-temple/800/600',
    description:
        'Rani Rashmoni\'s nine-spired riverfront temple of Bhavatarini '
        'Kali, consecrated in 1855 and inseparably associated with Sri '
        'Ramakrishna, Sarada Devi, and the Ramakrishna movement.',
    story:
        'Rani Rashmoni founded Dakshineswar on the eastern bank of the '
        'Hooghly after acquiring the estate in 1847; the deities were '
        'installed on Snan Yatra, 31 May 1855. The presiding black-stone '
        'image is Sri Sri Jagadiswari Bhavatarini Kalimata Thakurani—Kali '
        'as the Mother who carries devotees across worldly '
        'existence—standing upon reclining Shiva.\n\nThe sacred complex '
        'unites Shakta, Shaiva and Vaishnava worship: the navaratna Kali '
        'temple faces a Natmandir, twelve aat-chala Shiva shrines line the '
        'riverfront, and the Radhakanta temple houses Radha and Krishna. '
        'Sri Ramakrishna served here and undertook profound spiritual '
        'disciplines at Panchavati and Beltala; his room and Sarada '
        'Devi\'s Nahabat are preserved.\n\nThe Trust publishes both '
        'darshan sessions and named daily rites. Mangal Aarti precedes '
        'public opening, annabhog closes the sanctum at midday, and '
        'Sandhya Aarti anchors the evening. Dipanwita, Phalaharini and '
        'Ratanti Kali Pujas, Snan Yatra and Kalpataru Utsav are major '
        'observances.',
    location: 'Dakshineswar, Kolkata, West Bengal 700035',
    timings:
        'Official Trust board: public darshan 6:30 AM–12:30 PM and '
        '3:30–7:30 PM. Daily rites: Mangal Aarti 4:00 AM; morning '
        'puja/darshan 6:30 AM; annabhog 12:30 PM followed by midday '
        'closure; reopening 3:30 PM; Sandhya Aarti 6:30 PM; Shital Bhog '
        'and Shayan 8:00 PM. The Board of Trustees may change timings.',
    latitude: 22.655,
    longitude: 88.35778,
    specialities: [
      'Bhavatarini Kali in a nine-spired navaratna shrine',
      'Founded by Rani Rashmoni; consecrated 31 May 1855',
      'Sri Ramakrishna\'s principal sadhana and teaching centre',
      'Twelve Shiva temples and Radhakanta shrine',
      'Panchavati, Beltala, Nahabat and Sri Ramakrishna\'s room',
      'Hooghly riverfront pilgrimage linked by ferry to Belur Math',
    ],
  ),

  Temple(
    name: 'Belur Math',
    state: 'West Bengal',
    city: 'Howrah',
    deity: 'Sri Ramakrishna (Ramakrishna–Vedanta tradition)',
    imageUrl: 'https://picsum.photos/seed/belur-math/800/600',
    description:
        'World headquarters of the Ramakrishna Math and Ramakrishna '
        'Mission on the Hooghly, centred on Sri Ramakrishna Temple and the '
        'Vedantic ideal of harmony among religions.',
    story:
        'Swami Vivekananda established Belur Math as the headquarters of '
        'the Ramakrishna Math and Ramakrishna Mission in the 1890s, '
        'placing Sri Ramakrishna\'s sacred relics at the Belur grounds in '
        '1898. It is a monastery, pilgrimage centre, and base for a global '
        'tradition of Vedanta, worship, education, relief, and '
        'service.\n\nSri Ramakrishna Temple, consecrated in 1938, was '
        'designed by Swami Vijnanananda according to Vivekananda\'s '
        'vision. Its forms combine Hindu, Buddhist, Islamic and Christian '
        'architectural references to embody harmony of religions. The '
        'campus also holds temples and memorials of Holy Mother Sri Sarada '
        'Devi, Swami Vivekananda and Swami Brahmananda, plus the '
        'Ramakrishna Sangraha Mandir museum.\n\nDaily worship culminates '
        'in evening aratrikam in Sri Ramakrishna Temple. Durga Puja, '
        'Kumari Puja, and the birthdays of Sri Ramakrishna, Sarada Devi '
        'and Swami Vivekananda are important observances. The institution '
        'should be categorised as Ramakrishna–Vedanta rather than forced '
        'into a single conventional deity label.',
    location: 'PO Belur Math, Howrah district, West Bengal 711202',
    timings:
        'Official Belur Math campus hours: morning 6:30–11:30 AM; evening '
        'April–September 4:00–9:00 PM and October–March 3:30–8:30 PM. '
        'Temples close at 11:30 AM. After the evening aratrikam bell, '
        'visitors may remain only inside Sri Ramakrishna Temple. Arati '
        'times shift seasonally; confirm the official website\'s live '
        'arati notice. Museum: 8:30–11:30 AM and 4:00–6:00 PM (Apr–Sep) / '
        '3:30–5:30 PM (Oct–Mar), closed Monday and listed holidays.',
    latitude: 22.6325,
    longitude: 88.35639,
    specialities: [
      'Headquarters of Ramakrishna Math and Ramakrishna Mission',
      'Sri Ramakrishna Temple symbolises harmony of religions',
      'Established by Swami Vivekananda on the Hooghly',
      'Temples of Sarada Devi, Vivekananda and Brahmananda',
      'Ramakrishna Sangraha Mandir museum',
      'Durga Puja and Kumari Puja tradition',
    ],
  ),

  Temple(
    name: 'Tarapith Temple',
    state: 'West Bengal',
    city: 'Tarapith',
    deity: 'Devi (Tara)',
    imageUrl: 'https://picsum.photos/seed/tarapith-temple/800/600',
    description:
        'Tantric pilgrimage shrine of Maa Tara in Birbhum, paired with the '
        'nearby mahashmashan cremation ground and closely associated with '
        'the saint Bamakhepa.',
    story:
        'Tarapith is one of Bengal\'s foremost centres for worship of '
        'Tara, the compassionate yet fierce Mahavidya. Peetha traditions '
        'connect the place with Sati\'s eye, while the living cult focuses '
        'on Maa Tara\'s image and the union of maternal devotion with '
        'Tantric practice. Claims differ over its exact status in '
        'canonical Shakti Peetha lists, so it is safest to describe it as '
        'a revered Tara pitha and major Shakta pilgrimage.\n\nThe temple '
        'town is closely linked to the adjoining mahashmashan, where '
        'Tantric sadhana continues, and to the 19th-century saint '
        'Bamakhepa, whose devotion to Tara shaped the site\'s modern '
        'renown. His ashram and memorial are near the temple and Dwarka '
        'River.\n\nA committee schedule reported in 2026 fixes public '
        'entry around bhog and evening aarti closures. Kaushiki Amavasya, '
        'Kali Puja and other new-moon observances produce exceptional '
        'crowds. A priority-darshan mobile booking system began rolling '
        'out in September 2026, but physical coupons were temporarily '
        'retained during transition, so only same-day committee '
        'instructions should be trusted.',
    location:
        'Tarapith, Rampurhat subdivision, Birbhum district, West Bengal '
        '731233',
    timings:
        'Current committee schedule reported in July 2026: doors open 5:30 '
        'AM; sanctum closed for bhog 12:30–1:30 PM; evening aarti begins '
        '6:00 PM with visitor entry paused; public entry resumes 7:00 PM; '
        'temple closes 10:00 PM. A December 2024 committee order reported '
        'an additional evening closure beginning 5:00 PM. Festival '
        'schedules can override; verify locally on arrival.',
    latitude: 24.1167,
    longitude: 87.7903,
    specialities: [
      'Worship of Tara, one of the ten Mahavidyas',
      'Major Bengali Shakta and Tantric pilgrimage centre',
      'Adjacent mahashmashan cremation-ground sadhana landscape',
      'Association with Tantric saint Bamakhepa',
      'Kaushiki Amavasya and Kali Puja crowds',
      'Distinct free and priority darshan queues',
    ],
  ),

  Temple(
    name: 'Hangseshwari Temple',
    state: 'West Bengal',
    city: 'Bansberia',
    deity: 'Devi (Hangseshwari Kali)',
    imageUrl: 'https://picsum.photos/seed/hangseshwari-temple/800/600',
    description:
        'Early-19th-century Devi temple in Bansberia famed for thirteen '
        'lotus-bud ratnas and an interior conceived through Tantric '
        'imagery of the subtle human body.',
    story:
        'Hangseshwari—also spelled Hanseswari or Hangseswari—is worshipped '
        'as a form of Adi Parashakti and Dakshina Kali. Raja Nrisinhadeb '
        'Roy laid the temple\'s foundation in 1799; after his death, Rani '
        'Sankari completed it in 1814.\n\nThe five-storey structure is '
        'unlike the more familiar brick chala temples of Bengal. Thirteen '
        'tapering towers resemble lotus buds, while the inner arrangement '
        'is interpreted through Tantrik Satchakrabhed and the body\'s '
        'subtle channels, including ida, pingala and sushumna. This gives '
        'the architecture itself a ritual and contemplative '
        'meaning.\n\nThe same complex includes the older Ananta Basudeba '
        'Temple, admired for terracotta decoration, and a nearby Swanbhaba '
        'Kali shrine. Kali Puja is the major annual festival. The Hooghly '
        'district page is strong for heritage facts but publishes no '
        'worship clock; current split hours remain provisional.',
    location: 'Bansberia, Hooghly district, West Bengal 712502',
    timings:
        'Provisional visitor hours commonly reported: about 6:00 AM–11:00 '
        'AM and 4:00–7:00 PM daily. Other current listings extend the '
        'morning to noon, so verify locally before a dedicated trip. '
        'Festival and conservation access can change without an online '
        'notice. Thin official clock.',
    latitude: 22.96432,
    longitude: 88.39981,
    specialities: [
      'Thirteen lotus-bud ratnas / towers',
      'Five-storey Tantric human-body symbolism',
      'Hangseshwari as a form of Adi Parashakti and Kali',
      'Begun by Raja Nrisinhadeb Roy; completed by Rani Sankari in 1814',
      'Ananta Basudeba terracotta temple in the same complex',
      'Protected historic temple architecture in Bansberia',
    ],
  ),

  Temple(
    name: 'Sri Mayapur Chandrodaya Mandir (ISKCON Mayapur)',
    state: 'West Bengal',
    city: 'Mayapur',
    deity: 'Radha-Madhava / Pancha-tattva (Gaudiya Vaishnavism)',
    imageUrl: 'https://picsum.photos/seed/sri-mayapur-chandrodaya-mandir-iskcon-mayapur/800/600',
    description:
        'ISKCON\'s international Gaudiya Vaishnava headquarters at '
        'Mayapur, with daily Radha-Madhava, Pancha-tattva, Jagannath and '
        'Narasimha worship, kirtan, classes and pilgrimage services.',
    story:
        'Mayapur stands in the Nabadwip sacred landscape at the confluence '
        'region of the Bhagirathi and Jalangi. Gaudiya Vaishnavas revere '
        'the area as Chaitanya Mahaprabhu\'s appearance place, and '
        'ISKCON\'s Mayapur campus has become an international centre for '
        'bhakti, scripture, kirtan and pilgrimage.\n\nSri Mayapur '
        'Chandrodaya Mandir\'s established altars include Sri Sri '
        'Radha-Madhava, the Pancha-tattva, Jagannath-Baladeva-Subhadra and '
        'Lord Narasimha. The campus also holds Srila Prabhupada\'s samadhi '
        'and sits beside the developing Temple of the Vedic Planetarium '
        'complex. Its deity label therefore reflects Gaudiya Vaishnava '
        'tradition rather than simply “Vishnu.”\n\nThe official temple day '
        'begins before dawn with Mangala-arati and runs through Narasimha '
        'worship, Tulasi arati, darshan arati, guru-puja, scripture '
        'classes, bhoga and evening worship. Gaura Purnima and the '
        'multi-day Nabadwip Mandal Parikrama are the principal '
        'international pilgrim season.',
    location:
        'ISKCON Mayapur campus, Mayapur, Nadia district, West Bengal 741313',
    timings:
        'Official ISKCON Mayapur main-temple board: Mangala-arati 4:30 AM; '
        'Narasimhadeva Arati 5:00 AM; altar closed 5:10–7:00 AM; Tulasi '
        'Arati 5:10 AM; Darshan Arati 7:00 AM; Srila Prabhupada Guru-puja '
        '7:30 AM; Bhagavatam class 8:00–9:00 AM; Pushpa Arati 8:30 AM; '
        'Bhoga Arati noon; temple closes 1:00 PM and reopens 4:00 PM; '
        'Dhupa Arati 6:30 PM in summer; Bhagavad-gita class 7:30–8:25 PM; '
        'Shayana Arati 8:15 PM; closes 8:30 PM. Festival clocks may differ.',
    latitude: 23.43828,
    longitude: 88.39287,
    specialities: [
      'International centre of ISKCON and Gaudiya Vaishnavism',
      'Radha-Madhava and Pancha-tattva worship',
      'Jagannath-Baladeva-Subhadra and Narasimha altars',
      'Srila Prabhupada samadhi',
      'Daily kirtan, guru-puja and scripture classes',
      'Gaura Purnima and Nabadwip Mandal Parikrama',
    ],
  ),

  Temple(
    name: 'Taraknath Temple',
    state: 'West Bengal',
    city: 'Tarakeswar',
    deity: 'Shiva (Taraknath)',
    imageUrl: 'https://picsum.photos/seed/taraknath-temple/800/600',
    description:
        'Major Bengal Shiva pilgrimage shrine at Tarakeswar, centred on '
        'the swayambhu Taraknath linga, an atchala temple, natmandir and '
        'the Dudhpukur sacred tank.',
    story:
        'Taraknath is Shiva worshipped at Tarakeswar as the saving Lord. '
        'Local tradition tells of a cow pouring milk over a forest stone '
        'that was revealed as a self-manifested linga; Raja Bharamalla Rao '
        'then established worship at the spot.\n\nThe Hooghly district '
        'administration dates the shrine to 1729. Historical accounts '
        'distinguish an early foundation from the present atchala '
        'structure, later rebuilt and renovated under regional patrons. A '
        'natmandir fronts the Shiva temple; shrines of Kali and '
        'Lakshmi-Narayan and the Dudhpukur tank complete the ritual '
        'landscape.\n\nMondays, Maha Shivaratri, the five-day Gajan ending '
        'near Chaitra Sankranti, and the Shravan kanwar pilgrimage bring '
        'the largest crowds. Public clocks vary substantially with season '
        'and mela arrangements, so the provisional split schedule below '
        'should not be treated as a permanent official board.',
    location: 'Tarakeswar, Hooghly district, West Bengal 712410',
    timings:
        'Provisional ordinary-day schedule from current temple guides: '
        'morning darshan approximately 6:00 AM–1:30 PM, followed by an '
        'afternoon break, with evening access commonly reported around '
        '4:00–8:30/9:30 PM. Named rites often reported are Mangal Aarti '
        'about 6:00 AM, Bhog Aarti about 1:00 PM and Shayan Aarti about '
        '8:00 PM. Shravan 2026 press schedules differ (including 4:00 AM '
        'Mangal Aarti and multiple darshan windows); confirm locally, '
        'especially Mondays, Shravan, Shivaratri and Gajan. Thin official '
        'clock outside festival boards.',
    latitude: 22.8854,
    longitude: 88.0176,
    specialities: [
      'Swayambhu Taraknath Shiva linga tradition',
      'Bengal atchala temple with natmandir',
      'Dudhpukur sacred tank',
      'Major Shravan kanwar-yatra destination',
      'Maha Shivaratri and five-day Gajan',
      'Kali and Lakshmi-Narayan shrines in the precinct',
    ],
  ),

  Temple(
    name: 'Birla Mandir',
    state: 'West Bengal',
    city: 'Kolkata',
    deity: 'Vishnu (Radha-Krishna / Lakshminarayan)',
    imageUrl: 'https://picsum.photos/seed/birla-mandir/800/600',
    description:
        'White-marble Birla family temple in Ballygunge, principally '
        'dedicated to Radha-Krishna and Lakshminarayan, with subsidiary '
        'Shiva and Durga shrines.',
    story:
        'Kolkata\'s Birla Mandir is a modern Vaishnava landmark built by '
        'the Birla family on Ashutosh Choudhury Avenue. Construction began '
        'in 1970, took twenty-six years, and culminated in pran pratishtha '
        'and inauguration on 21 February 1996.\n\nThe central shrine '
        'houses Radha and Krishna and the temple is also known as '
        'Lakshminarayan Mandir. Side shrines honour Shiva in meditation '
        'and Durga. White marble, tall shikharas, Rajasthani craft '
        'traditions and stone-carved scenes from the Bhagavad Gita define '
        'the visitor experience.\n\nJanmashtami is the great annual '
        'congregation, while evening aarti and illumination are popular '
        'daily moments. No strong official public timetable page surfaced '
        'in this research pass; the split clock repeated across reference '
        'and city-tourism sources is used provisionally.',
    location:
        '29 Ashutosh Choudhury Avenue, Ballygunge, Kolkata, West Bengal '
        '700019',
    timings:
        'Commonly published daily hours: 5:30–11:00 AM and 4:30–9:00 PM, '
        'closed 11:00 AM–4:30 PM. Evening aarti is commonly reported '
        'around 6:30 PM, but confirm on the local notice board. '
        'Janmashtami arrangements may extend or restrict ordinary access. '
        'Thin official English aarti clock.',
    latitude: 22.53056,
    longitude: 88.365,
    specialities: [
      'Radha-Krishna / Lakshminarayan principal shrine',
      'Modern white-marble temple completed in 1996',
      'Durga and meditating Shiva side shrines',
      'Bhagavad Gita scenes carved in stone',
      'Rajasthani-inspired shikharas and craftsmanship',
      'Major Janmashtami celebration in Kolkata',
    ],
  ),

  Temple(
    name: 'Kiriteswari Temple',
    state: 'West Bengal',
    city: 'Murshidabad',
    deity: 'Devi (Kiriteswari / Mahishamardini)',
    imageUrl: 'https://picsum.photos/seed/kiriteswari-temple/800/600',
    description:
        'Rural Shakti Peetha at Kiritkona in Murshidabad, where Sati\'s '
        'crown is traditionally believed to have fallen and the goddess is '
        'worshipped as Kiriteswari or Mahishamardini.',
    story:
        'Kiriteswari takes its name from kirit, the crown. In local Shakti '
        'Peetha tradition, Sati\'s crown fell at Kiritkona; the goddess is '
        'called Kiriteswari, Mukuteshwari, Vimala or Mahishamardini, with '
        'Samvarta/Sanvarteshwar as Bhairava. The main object of worship is '
        'not presented like a conventional anthropomorphic image.\n\nThe '
        'sacred site\'s history is said to exceed a millennium, although '
        'the older temple was destroyed and the present principal shrine '
        'was reconstructed under Raja Darpanarayan of Lalgola in the 19th '
        'century. The compact char-chala form and remains of the old '
        'temple preserve a distinctly rural Murshidabad pilgrimage '
        'setting.\n\nNo authoritative online daily timetable was found. '
        'The longest current listings say the precinct opens from early '
        'morning to late evening, sometimes with an afternoon closure; '
        'noon anna-bhog is part of local practice. Kiriteswari village '
        'received India\'s Best Tourism Village recognition in 2023, '
        'increasing visitor attention but not resolving the thin '
        'worship-clock record.',
    location:
        'Kiritkona (Kiriteswari) village, Nabagram block, Murshidabad '
        'district, West Bengal 742104',
    timings:
        'Provisional only: sources variously report 6:00 AM–10:00 PM '
        'continuously or split access around 5:00 AM–1:00 PM and '
        '4:00–10:00 PM, with noon anna-bhog. No official daily clock was '
        'located; call/check locally before travel, particularly during '
        'Durga Puja, Kali Puja and village festival days.',
    latitude: 24.2,
    longitude: 88.21861,
    specialities: [
      'Shakti Peetha associated with Sati\'s crown (kirit)',
      'Devi worshipped as Kiriteswari, Mukuteshwari or Mahishamardini',
      'Bhairava tradition of Samvarta / Sanvarteshwar',
      'Old temple remains and 19th-century reconstruction',
      'Rural char-chala Bengal shrine architecture',
      'Kiriteswari named Best Tourism Village of India 2023',
    ],
  ),

  Temple(
    name: 'Kapil Muni Temple',
    state: 'West Bengal',
    city: 'Gangasagar',
    deity: 'Kapil Muni',
    imageUrl: 'https://picsum.photos/seed/kapil-muni-temple/800/600',
    description:
        'Pilgrimage temple and ashram of sage Kapila near the Gangasagar '
        'confluence on Sagar Island, visited after the Makar Sankranti '
        'sea-and-river snan.',
    story:
        'Kapil Muni Temple stands near the Gangasagar shore where the '
        'Ganga meets the Bay of Bengal. The pilgrimage recalls the '
        'Bhagavata and Ramayana cycle of King Sagara\'s sons, sage Kapila, '
        'Bhagiratha\'s penance, and the descent of Ganga to liberate the '
        'ancestors. Pilgrims traditionally bathe at the confluence and '
        'then seek darshan of Kapil Muni.\n\nThe exposed delta coast has '
        'repeatedly reshaped the shrine. Older structures were lost to '
        'erosion and storms; a brick temple was built in 1961 and the '
        'present structure dates to 1974. The temple remains vulnerable to '
        'high tides and cyclones, making the shifting shoreline part of '
        'both its history and practical visitor planning.\n\nGangasagar '
        'Mela around Makar Sankranti is the defining observance, drawing '
        'vast numbers of pilgrims and a temporary service city. '
        'Ordinary-day worship information is thin and published hours '
        'conflict. Ferry, road, tide and weather conditions are at least '
        'as important as the temple clock for any visit.',
    location:
        'Gangasagar, Sagar Island, South 24 Parganas district, West Bengal '
        '743606',
    timings:
        'Thin-source provisional hours: several current pilgrimage '
        'listings give darshan about 9:00 AM–6:00 PM and morning aarti '
        'around 7:00 AM, while others claim broader 4:00 AM–8:00 PM '
        'access. Confirm locally. During Gangasagar Mela / Makar '
        'Sankranti, bathing and darshan run under special district '
        'schedules, barricades, tide windows and crowd controls rather '
        'than ordinary hours.',
    latitude: 21.63654,
    longitude: 88.07334,
    specialities: [
      'Kapil Muni ashram-temple at Gangasagar',
      'Ganga–Bay of Bengal confluence pilgrimage',
      'Bhagiratha and King Sagara sacred narrative',
      'Holy snan followed by temple darshan',
      'Gangasagar Mela at Makar Sankranti',
      'Present temple structure completed in 1974',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  MADHYA PRADESH
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 13 — new temples, not enrichments of existing rows.
  // Kandariya Mahadeva and Lakshmana are ASI/UNESCO monuments, not
  // living pooja listings. Cover imageUrl values are picsum
  // placeholders. Commons candidates: docs/madhya-pradesh-sample-research.md.
  Temple(
    name: 'Mahakaleshwar Temple',
    state: 'Madhya Pradesh',
    city: 'Ujjain',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/mahakaleshwar-temple/800/600',
    description:
        'One of the twelve Jyotirlingas of Shiva, on the Rudra Sagar side '
        'of Ujjain; Mahakala is worshipped as the lord of time, with a '
        'south-facing, self-manifested linga and the celebrated pre-dawn '
        'Bhasma Aarti.',
    story:
        'Mahakaleshwar is one of the twelve Jyotirlinga shrines and the '
        'ritual heart of Ujjain. The presiding linga is revered as '
        'swayambhu and dakshinamukhi (south-facing), an orientation '
        'associated with Shiva as Mahakala, master of time and death. The '
        'five-level complex includes an underground sanctum; the '
        'Nagchandreshwar shrine on the upper level opens to devotees only '
        'on Nag Panchami.\n\nThe temple day is structured around five '
        'official aartis. Bhasma Aarti begins at 4:00 AM and requires '
        'advance booking through the temple’s official portal; ordinary '
        'darshan is listed from 4:00 AM to 11:00 PM. Dadyodak/Bal Bhog, '
        'Bhog, Sandhya and Shayan Aartis follow, with two seasonal clocks '
        'published by the Temple Management Committee.\n\nMahashivaratri, '
        'Shravan Mondays and the Shravan–Bhadrapada Mahakal Sawari '
        'processions produce exceptional crowds and may bring special '
        'hours. Use only the official website for Bhasma Aarti, '
        'Sandhya/Shayan Aarti, sheeghra darshan and pujan bookings, and '
        'follow the reporting time and identification instructions on the '
        'confirmation.',
    location: 'Jaisinghpura, Ujjain, Madhya Pradesh 456006',
    timings:
        'Official seasonal aarti board: Bhasma Aarti 4:00–6:00 AM '
        'year-round. Chaitra Krishna Pratipada–Ashwin Purnima: '
        'Dadyodak/Bal Bhog 7:00–7:45 AM; Bhog 10:00–10:45 AM; Sandhya '
        '7:00–7:45 PM; Shayan 10:30–11:00 PM. Kartik Krishna '
        'Pratipada–Phalgun Purnima: Dadyodak 7:30–8:15 AM; Bhog '
        '10:30–11:15 AM; Sandhya 6:30–7:15 PM; Shayan 10:30–11:00 PM. '
        'Incredible India lists general darshan 4:00 AM–11:00 PM. '
        'Festival/Shravan notices can override; check the official timing '
        'page.',
    latitude: 23.18278,
    longitude: 75.76833,
    specialities: [
      'One of the twelve Jyotirlingas',
      'South-facing (dakshinamukhi) swayambhu linga',
      'Daily pre-dawn Bhasma Aarti',
      'Five-level complex with underground sanctum',
      'Nagchandreshwar opens only on Nag Panchami',
      'Mahakal Lok and Shravan–Bhadrapada sawari tradition',
    ],
  ),

  Temple(
    name: 'Omkareshwar Temple',
    state: 'Madhya Pradesh',
    city: 'Omkareshwar',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/omkareshwar-temple/800/600',
    description:
        'One of the twelve Jyotirlingas, standing on Mandhata island in '
        'the Narmada; the sacred landscape also includes Mamleshwar on the '
        'mainland and the island parikrama route.',
    story:
        'Omkareshwar is one of the twelve Jyotirlinga shrines of Shiva, '
        'set on Mandhata island in the Narmada River. The island is '
        'traditionally said to resemble the sacred syllable Om. '
        'Omkareshwar on the island and Mamleshwar (Amaleshwar) on the '
        'south bank are treated as a paired sacred landscape by many '
        'pilgrims.\n\nThe Trust publishes an unusually precise daily '
        'programme: Mangal Aarti and bhog before public darshan, morning '
        'and midday darshan sessions separated by Madhyanha Bhog, evening '
        'Shringar Darshan, and Shayan Aarti followed by a final short '
        'darshan. Adi Shankara is traditionally believed to have met his '
        'guru Govinda Bhagavatpada in a cave below the temple.\n\nThe '
        'approach includes bridge or boat access, steep lanes and steps. '
        'Maha Shivaratri, Kartik Purnima and Shravan bring heavy queues. '
        'Normal darshan is free; optional Shighra Darshan is sold by the '
        'official Trust for fixed time slots.',
    location:
        'Mandhata Island, Omkareshwar, Khandwa district, Madhya Pradesh '
        '450554',
    timings:
        'Official Trust schedule: Mangal Aarti and Naivedya Bhog 4:30–5:00 '
        'AM; Mangal Darshan 5:00 AM–12:20 PM; Madhyanha Bhog 12:20–1:15 '
        'PM; Madhyanha Darshan 1:15–4:00 PM; Sayamkalin Shringar 4:00–4:30 '
        'PM; Shringar Darshan 4:30–9:30 PM; Shayan Aarti 9:30–10:00 PM; '
        'Shayan Darshan 10:00–10:30 PM. Darshan closes during aarti, bhog '
        'and shringar; festival clocks may vary.',
    latitude: 22.245583,
    longitude: 76.151056,
    specialities: [
      'One of the twelve Jyotirlingas',
      'Mandhata island in the Narmada',
      'Om-shaped-island tradition',
      'Paired pilgrimage with mainland Mamleshwar',
      'Adi Shankara–Govinda Bhagavatpada cave tradition',
      'Trust-published full daily ritual board',
    ],
  ),

  Temple(
    name: 'Kandariya Mahadeva Temple',
    state: 'Madhya Pradesh',
    city: 'Khajuraho',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/kandariya-mahadeva-temple/800/600',
    description:
        'The largest and grandest temple at Khajuraho, an '
        'early-11th-century Shiva monument in the ASI-managed Western '
        'Group and UNESCO World Heritage property.',
    story:
        'Kandariya Mahadeva is the largest and most elaborate temple at '
        'Khajuraho. ASI attributes it to Chandella king Ganda in the '
        'period c. 1017–1029. Its soaring Nagara shikhara, ringed by '
        'clustered miniature spires, evokes a mountain mass above the '
        'sandstone platform.\n\nThe axial sequence moves from entrance '
        'porch through halls and vestibule to the Shiva sanctum. Dense '
        'exterior sculpture integrates deities, guardians, surasundaris, '
        'musicians, couples and scenes of secular life into the '
        'architecture. UNESCO cites Kandariya’s profusion of sculpture '
        'among the masterpieces of Indian art.\n\nThis entry is an '
        'ASI/UNESCO monument visit, not a dependable living-temple pooja '
        'listing. Use the Western Group ticket and observe ASI '
        'conservation barriers, photography notices and sunrise-to-sunset '
        'hours; do not represent monument hours as a ritual schedule.',
    location:
        'Western Group of Temples, Sevagram, Khajuraho, Chhatarpur '
        'district, Madhya Pradesh 471606',
    timings:
        'ASI opening hours for the Khajuraho Group: sunrise to sunset. The '
        'Western Group is ticketed; ASI’s page lists ₹40 for Indian '
        'visitors and ₹600 for other foreign visitors, with free entry for '
        'children below 15 (fees can change). No regular living-pooja '
        'timetable is published for Kandariya Mahadeva; confirm current '
        'ticketing and last entry on ASI systems.',
    latitude: 24.853,
    longitude: 79.9197,
    specialities: [
      'Largest and grandest Khajuraho temple',
      'Early-11th-century Chandella monument',
      'Shiva temple with mountain-like Nagara shikhara',
      'ASI-protected Western Group monument',
      'Part of UNESCO Khajuraho Group (inscribed 1986)',
      'Visitor monument — no regular living pooja schedule claimed',
    ],
  ),

  Temple(
    name: 'Lakshmana Temple',
    state: 'Madhya Pradesh',
    city: 'Khajuraho',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/lakshmana-temple/800/600',
    description:
        'A remarkably complete 10th-century Chandella temple dedicated to '
        'Vaikuntha Vishnu, within Khajuraho’s ASI-managed Western Group '
        'and UNESCO property.',
    story:
        'Lakshmana Temple was built by Chandella ruler Yashovarman in the '
        'mid-10th century and is dedicated to Vaikuntha Vishnu. It is '
        'among the earliest major and most complete temples in Khajuraho’s '
        'Western Group.\n\nThe sandstone temple rises on a high jagati in '
        'a panchayatana scheme, with four subsidiary corner shrines. Its '
        'axial porch, mandapas, vestibule, circumambulatory sanctum and '
        'clustered shikhara illustrate the mature Nagara system. The '
        'doorway presents Vishnu’s avatars, while the exterior carries '
        'bands of divine figures, attendants, couples and everyday '
        'activity.\n\nLakshmana is managed as an ASI monument. The visit '
        'uses the Western Group admission and sunrise-to-sunset monument '
        'hours; no recurring public aarti or darshan ritual board should '
        'be inferred from its Vishnu dedication.',
    location:
        'Western Group of Temples, Sevagram, Khajuraho, Chhatarpur '
        'district, Madhya Pradesh 471606',
    timings:
        'ASI opening hours for the Khajuraho Group: sunrise to sunset. '
        'Western Group admission is ticketed; ASI lists ₹40 for Indian '
        'visitors and ₹600 for other foreign visitors, with free entry '
        'below age 15 (subject to revision). This is a protected monument '
        'visit, not a published living-pooja schedule.',
    latitude: 24.852139,
    longitude: 79.921694,
    specialities: [
      'Dedicated to Vaikuntha Vishnu',
      'Built by Chandella ruler Yashovarman, c. mid-10th century',
      'Panchayatana plan on a high jagati',
      'Among Khajuraho’s best-preserved complete temples',
      'ASI-protected Western Group monument',
      'Part of UNESCO Khajuraho Group (1986)',
    ],
  ),

  Temple(
    name: 'Matangeshwar Temple',
    state: 'Madhya Pradesh',
    city: 'Khajuraho',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/matangeshwar-temple/800/600',
    description:
        'An early-10th-century Shiva temple and the principal actively '
        'worshipped historic temple at Khajuraho, known for its '
        'exceptionally large linga.',
    story:
        'Matangeshwar (Matangeshvara) stands beside the Western Group and '
        'is the actively worshipped exception among Khajuraho’s '
        'Chandella-era temples. ASI dates its comparatively plain design '
        'to about 900–925 CE.\n\nThe temple has a high platform, square '
        'sanctum and a monumental Shiva linga roughly 2.5 metres high and '
        'about one metre in diameter. Its restrained outer walls contrast '
        'with the profuse sculptural programmes of later Khajuraho '
        'monuments. Devotees continue daily worship, and Maha Shivaratri '
        'is marked by a major ceremony in which the linga is bathed and '
        'adorned.\n\nUnlike Kandariya and Lakshmana, this is a living '
        'shrine. However, a reliable official English daily clock is thin: '
        'commonly published visiting hours are around 6:00 AM–6:00 PM. '
        'Confirm at the temple, especially for evening closing and Maha '
        'Shivaratri arrangements.',
    location:
        'Near Western Group entrance, Sevagram, Khajuraho, Chhatarpur '
        'district, Madhya Pradesh 471606',
    timings:
        'Living-temple hours are commonly published as approximately 6:00 '
        'AM–6:00 PM daily, but no strong official English day board was '
        'found; confirm locally. Maha Shivaratri ceremonies and crowd '
        'control alter access. The adjacent ticketed Western Group has '
        'separate ASI sunrise-to-sunset monument hours.',
    latitude: 24.852092,
    longitude: 79.922244,
    specialities: [
      'Actively worshipped historic temple at Khajuraho',
      'Early Chandella period, ASI dated c. 900–925 CE',
      'Exceptionally large Shiva linga',
      'Plain early design contrasting with later sculptural temples',
      'Maha Shivaratri bathing and adornment ceremonies',
      'Part of the UNESCO-listed Khajuraho ensemble',
    ],
  ),

  Temple(
    name: 'Harsiddhi Temple',
    state: 'Madhya Pradesh',
    city: 'Ujjain',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/harsiddhi-temple/800/600',
    description:
        'Ancient Devi shrine near Mahakaleshwar, renowned for twin '
        'multi-tiered deepstambhas that are illuminated during evening '
        'worship and especially Navaratri.',
    story:
        'Harsiddhi Temple is one of Ujjain’s principal Devi shrines, '
        'located near Rudra Sagar and Mahakaleshwar. Local Shakta '
        'tradition identifies it as a Shakti Peetha and associates the '
        'goddess with Ujjain’s legendary king Vikramaditya; these are '
        'devotional traditions rather than archaeological dating '
        'claims.\n\nThe courtyard’s signature features are two tall '
        'Maratha-period deepstambhas, tiered lamp pillars that become the '
        'visual focus when lit for evening worship. The sanctum centres on '
        'Harsiddhi Devi, a form of Durga. Chaitra and Sharad Navaratri, '
        'Ashtami and Navami bring dense queues and elaborate lamp '
        'rituals.\n\nPublished ordinary-day hours conflict, ranging from '
        'roughly 5:00 AM–7:00 PM to 5:00 AM–9:00/10:00 PM. Use a '
        'conservative provisional listing and verify the current closing '
        'and lamp-lighting time locally; evening aarti shifts with sunset '
        'and festival arrangements.',
    location: 'Harsiddhi Marg, near Rudra Sagar, Ujjain, Madhya Pradesh 456006',
    timings:
        'Provisional ordinary-day visiting span: about 5:00 AM–9:00 PM; '
        'local listings disagree, with some citing 7:00 PM or 10:00 PM '
        'closing. Morning aarti is commonly placed around 7:00 AM and '
        'evening aarti/deepstambha lighting around sunset (often 6:30–7:30 '
        'PM). Confirm on arrival; Navaratri schedules override. Thin '
        'official clock.',
    latitude: 23.184478,
    longitude: 75.764581,
    specialities: [
      'Major Harsiddhi Devi shrine of Ujjain',
      'Revered in local tradition as a Shakti Peetha',
      'Twin tiered deepstambhas',
      'Evening lamp-lighting tradition',
      'Close to Mahakaleshwar and Rudra Sagar',
      'Major Chaitra and Sharad Navaratri crowds',
    ],
  ),

  Temple(
    name: 'Chintaman Ganesh Temple',
    state: 'Madhya Pradesh',
    city: 'Ujjain',
    deity: 'Ganesha',
    imageUrl: 'https://picsum.photos/seed/chintaman-ganesh-temple/800/600',
    description:
        'Ujjain’s large ancient Ganesha shrine, where Chintaman is '
        'worshipped with Riddhi and Siddhi as the remover of anxieties and '
        'obstacles.',
    story:
        'Chintaman Ganesh stands southwest of central Ujjain near the '
        'Kshipra and the Fatehabad route. The deity is revered as '
        'swayambhu, with Riddhi and Siddhi beside Ganesha. “Chintaman” is '
        'understood devotionally as the remover of chinta—worry or '
        'anxiety.\n\nThe existing stone fabric and carved pillars are '
        'commonly associated with the Paramara period, while local '
        'tradition places the shrine much earlier and links its '
        'establishment to Sita; the latter is best presented as legend. '
        'The temple is a living pilgrimage site rather than an '
        'archaeological monument.\n\nWednesdays, Ganesh Chaturthi and '
        'monthly Chaturthi observances draw the largest queues. Published '
        'schedules commonly place opening around 5:00 or 6:00 AM and '
        'closing around 10:00 PM, with morning decoration/aarti and '
        'evening/shayan observances, but a strong official detailed clock '
        'is not readily available.',
    location: 'Chintaman Road, Fatehabad, Ujjain, Madhya Pradesh 456006',
    timings:
        'Provisional daily span: approximately 5:00/6:00 AM–10:00 PM. '
        'Secondary schedules commonly list morning Chola Aarti around '
        '7:00–7:30 AM, midday bhog around noon, evening aarti around '
        '7:00–7:30 PM and Shayan Aarti around 9:30 PM. Treat named minutes '
        'as provisional and confirm locally, especially Wednesday and '
        'Ganesh Chaturthi. Thin official ritual clock.',
    latitude: 23.1467,
    longitude: 75.7391,
    specialities: [
      'Swayambhu Chintaman Ganesha tradition',
      'Riddhi and Siddhi flank the deity',
      'Name signifies remover of worries',
      'Carved pillars associated with Paramara-era fabric',
      'One of Ujjain’s foremost Ganesha shrines',
      'Heavy Wednesday and Ganesh Chaturthi attendance',
    ],
  ),

  Temple(
    name: 'Pashupatinath Temple',
    state: 'Madhya Pradesh',
    city: 'Mandsaur',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/pashupatinath-temple/800/600',
    description:
        'Major Mandsaur Shiva shrine on the Shivna River, centred on a '
        'rare monumental eight-faced linga generally dated to the 5th–6th '
        'century.',
    story:
        'Pashupatinath Temple stands on the Shivna River in Mandsaur, '
        'ancient Dashapura. Its defining sacred image is an approximately '
        '4.5-metre-high, eight-faced linga: four faces above and four '
        'below, representing eight aspects of Shiva including Bhava, '
        'Pashupati, Mahadeva and Ishana. Art-historical study generally '
        'dates the image to the 5th or early 6th century.\n\nThe linga was '
        'recovered from the river bed and reconsecrated in the present '
        'temple. The wider complex includes subsidiary shrines, a '
        'deepstambha, ghats and pilgrim spaces. Maha Shivaratri and '
        'Shravan Mondays are major crowd periods.\n\nGovernment listings '
        'disagree on the ordinary closing: the Ministry of Tourism '
        'Utsav/live-darshan page shows 6:00 AM–10:00 PM, while MP tourism '
        'and local listings commonly say 6:00 AM–8:00 PM or '
        'sunrise–sunset. Publish the conflict rather than selecting an '
        'unsupported single closing time.',
    location:
        'Pashupatinath Mandir Road, Shivna River bank, Mandsaur, Madhya '
        'Pradesh 458001',
    timings:
        'Opening is consistently listed at 6:00 AM. Ministry of Tourism’s '
        'Utsav/live-darshan page lists 6:00 AM–10:00 PM; MP tourism/local '
        'listings cite 6:00 AM–8:00 PM or sunrise–sunset. Closing time '
        'conflict (20:00 versus 22:00): confirm locally before an evening '
        'visit. Maha Shivaratri and Shravan may have special arrangements.',
    latitude: 24.05472,
    longitude: 75.072917,
    specialities: [
      'Rare monumental Ashtamukha (eight-faced) Shiva linga',
      'Linga generally dated to 5th–6th century',
      'Sacred setting on the Shivna River',
      'Associated with ancient Dashapura/Mandsaur',
      'Subsidiary shrines, ghats and deepstambha',
      'Major Maha Shivaratri and Shravan pilgrimage',
    ],
  ),

  Temple(
    name: 'Sharda Devi Temple Maihar',
    state: 'Madhya Pradesh',
    city: 'Maihar',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/sharda-devi-temple-maihar/800/600',
    description:
        'Hilltop shrine of Maa Sharda above Maihar, reached by a long '
        'stair ascent or ropeway and especially crowded during Chaitra and '
        'Sharad Navaratri.',
    story:
        'Maa Sharda Temple crowns Trikuta Hill above Maihar. The district '
        'administration describes the shrine as roughly 600 feet above '
        'ground and reached by 1,001 steps; many travel accounts give a '
        'slightly different step count, so the official district figure is '
        'preferred here. A ropeway offers an alternative to the '
        'climb.\n\nSharda is worshipped as the goddess of learning, music '
        'and wisdom. Local tradition connects the shrine with the '
        'legendary warriors Alha and Udal, and devotees regard the hill as '
        'a Shakti Peetha; these should be presented as living religious '
        'traditions. Families commonly seek blessings for children and '
        'education.\n\nChaitra and Sharad Navaratri produce very long '
        'queues and special access controls. The Ministry of Tourism '
        'live-darshan listing gives 5:30 AM–7:00 PM; wider secondary '
        'schedules extend to 9:00 PM. Ropeway operation is separate, '
        'weather-dependent and normally ends before or around temple '
        'closing.',
    location: 'Trikuta Hill, Maihar, Maihar district, Madhya Pradesh 485771',
    timings:
        'Ministry of Tourism live-darshan listing: 5:30 AM–7:00 PM. Other '
        'guides often claim 5:00 AM–9:00 PM, so treat later hours as '
        'unverified and confirm with temple/district notices. Ropeway is '
        'commonly about 6:30 AM–7:30 PM but is weather/daylight dependent '
        'and can be suspended; Navaratri schedules differ. Thin official '
        'aarti board.',
    latitude: 24.26123,
    longitude: 80.72307,
    specialities: [
      'Hilltop Maa Sharda shrine on Trikuta Hill',
      'Official district page describes 1,001-step ascent',
      'Ropeway alternative to the stair climb',
      'Goddess of learning, music and wisdom',
      'Alha–Udal devotional tradition',
      'Major Chaitra and Sharad Navaratri pilgrimage',
    ],
  ),

  Temple(
    name: 'Ram Raja Temple',
    state: 'Madhya Pradesh',
    city: 'Orchha',
    deity: 'Vishnu/Rama',
    imageUrl: 'https://picsum.photos/seed/ram-raja-temple/800/600',
    description:
        'Orchha’s living palace-temple where Rama is worshipped as a king, '
        'with a daily guard of honour and a distinctive Hindu-calendar '
        'seasonal court ritual.',
    story:
        'Ram Raja Temple occupies the former queen’s palace in Orchha. '
        'According to the central temple legend, Queen Ganesh Kunwari '
        'brought a child-form image of Rama from Ayodhya. Because Rama had '
        'stipulated that the first place where he was seated would become '
        'his permanent abode, the image remained in the palace rather than '
        'moving to the newly built Chaturbhuj Temple.\n\nRama is '
        'worshipped here as Orchha’s sovereign Raja Ram. A formal guard of '
        'honour and royal-style bhog distinguish the daily courtly ritual. '
        'The main image is accompanied by Sita, Lakshmana and attendant '
        'figures. Ram Navami, Vivaha Panchami/Ram Vivah, Kartik Purnima '
        'and other festivals bring major crowds.\n\nThe official routine '
        'changes by Hindu-calendar season. Darshan begins with morning '
        'aarti, pauses after Rajbhog, resumes at Sandhya Aarti, and ends '
        'after Biyari Aarti. The seasonal board is more reliable than '
        'generic “sunrise to sunset” tourism wording.',
    location: 'Ram Raja Temple, Orchha, Niwari district, Madhya Pradesh 472246',
    timings:
        'Official seasonal routine. Phagun–Kwar/Kartik (approximately '
        'February–October): morning Aarti 8:00 AM; Rajbhog Chik 12:00 PM; '
        'Rajbhog Aarti 12:30 PM; Shyam Aarti 8:00 PM; Biyari Chik 10:00 '
        'PM; Biyari Aarti 10:30 PM. Kartik–Magh/Phagun (approximately '
        'October–February): morning Aarti 9:00 AM; Rajbhog Chik 12:30 PM; '
        'Rajbhog Aarti 1:00 PM; Shyam Aarti 7:00 PM; Biyari Chik 9:00 PM; '
        'Biyari Aarti 9:30 PM. Morning darshan runs from morning Aarti '
        'through about five minutes after Rajbhog Aarti; evening darshan '
        'runs from Shyam Aarti through about five minutes after Biyari '
        'Aarti. Each aarti is roughly 20 minutes.',
    latitude: 25.350875,
    longitude: 78.639274,
    specialities: [
      'Rama worshipped as the sovereign king of Orchha',
      'Temple housed in the former queen’s palace',
      'Daily ceremonial guard of honour',
      'Official seasonal aarti and Rajbhog/Biyari routine',
      'Legend links palace shrine with nearby Chaturbhuj Temple',
      'Major Ram Navami and Ram Vivah/Vivaha Panchami celebrations',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  BIHAR
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 14 — new temples, not enrichments of existing rows.
  // Mahabodhi is a living Buddhist UNESCO site, not a Hindu temple.
  // Cover imageUrl values are picsum placeholders. Commons candidates:
  // docs/bihar-sample-research.md.
  Temple(
    name: 'Mahavir Mandir',
    state: 'Bihar',
    city: 'Patna',
    deity: 'Hanuman',
    imageUrl: 'https://picsum.photos/seed/mahavir-mandir/800/600',
    description:
        'Major Hanuman temple directly opposite Patna Junction, known for '
        'its two Hanuman images, Naivedyam laddoo prasad, and the '
        'charitable institutions supported by Shri Mahavir Sthan Nyas '
        'Samiti.',
    story:
        'Mahavir Mandir is Patna’s best-known Hanuman shrine, standing '
        'beside the main railway junction and serving both local '
        'worshippers and pilgrims arriving in the Bihar capital. The '
        'sanctum is unusual for its two Hanuman images: temple tradition '
        'associates one with the fulfilment of devotees’ wishes and the '
        'other with relief from suffering, reinforcing the popular Sankat '
        'Mochan character of the shrine.\n\nThe present multi-storey '
        'temple took shape through a major 1980s reconstruction, although '
        'worship at the site is older. Shri Mahavir Sthan Nyas Samiti '
        'administers the temple and channels donations and the proceeds of '
        'its Naivedyam prasad operation into hospitals and other '
        'public-service institutions. Tuesdays, Saturdays, Ram Navami, and '
        'New Year produce exceptionally long queues.\n\nThe official daily '
        'rhythm begins with the opening and morning aarti at 5:00 AM, '
        'followed by bhog aarti at 11:00 AM, an afternoon aarti at 4:00 '
        'PM, a seasonally adjusted evening aarti, and shayan aarti at '
        '10:30 PM. Use only the official Mahavir Mandir sites for donation '
        'information; the Trust warns about unauthorised sites using its '
        'name.',
    location: 'Near Patna Junction railway station, Patna, Bihar 800001',
    timings:
        'Official Mahavir Mandir board: doors open and morning aarti at '
        '5:00 AM daily; bhog aarti 11:00 AM; afternoon aarti 4:00 PM; '
        'evening aarti 7:30 PM from Ashwin Purnima through Phalgun Purnima '
        'and 8:00 PM from Phalgun Purnima through Ashwin Purnima; shayan '
        'aarti 10:30 PM. The public page does not separately tabulate '
        'every darshan pause or a final exit time, so treat the ritual '
        'board as authoritative and confirm crowd controls on Tuesdays, '
        'Saturdays, Ram Navami, and New Year.',
    latitude: 25.60389,
    longitude: 85.13639,
    specialities: [
      'Two Hanuman images with wish-fulfilment and suffering-removal traditions',
      'Sankat Mochan shrine immediately beside Patna Junction',
      'Official five-aarti daily rhythm with seasonal evening shift',
      'Naivedyam laddoo prasad',
      'Trust-supported hospitals and charitable institutions',
      'Peak pilgrimage on Tuesdays, Saturdays, and Ram Navami',
    ],
  ),

  Temple(
    name: 'Mundeshwari Devi Temple',
    state: 'Bihar',
    city: 'Bhabua',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mundeshwari-devi-temple/800/600',
    description:
        'Ancient octagonal stone temple on Mundeshwari Hill in Kaimur, '
        'dedicated to Shakti and Shiva and widely described as one of '
        'India’s oldest continuously functioning temples.',
    story:
        'Mundeshwari Devi Temple crowns the roughly 600-foot Piwara or '
        'Mundeshwari hill near Bhagwanpur in Kaimur district. Bihar '
        'Tourism describes it as an exceptionally ancient functioning '
        'temple because worship is believed to have continued without '
        'interruption; the careful phrasing “often called” or “considered '
        'among the oldest” is preferable to an absolute worldwide '
        'claim.\n\nThe compact octagonal stone shrine is protected by the '
        'Archaeological Survey of India. The principal image is '
        'Mundeshwari Devi, locally identified with a form of Shakti or '
        'Varahi, while a distinctive panchamukhi Shiva linga occupies the '
        'central space. Ganesha, Surya, Vishnu, Nandi, Gupta-period '
        'carving, and an early inscription contribute to the site’s '
        'layered religious and archaeological importance.\n\nA celebrated '
        'local practice is the so-called bloodless goat offering: the '
        'animal is ritually presented but not slaughtered, and is '
        'released. Ram Navami, Maha Shivaratri, and Navratri draw major '
        'crowds. The hill approach and steps require extra time, '
        'particularly for older visitors and during hot weather.',
    location: 'Mundeshwari Hill, Bhagwanpur, Kaimur district, Bihar 821110',
    timings:
        'Bihar Tourism and the district page do not publish a stable '
        'all-season daily clock. Common visitor listings give '
        'approximately 6:00 AM–7:00 PM. A 2026 Trust-secretary / '
        'chief-priest seasonal report gives summer doors and cleaning at '
        '6:00 AM, morning aarti and bhog at 6:30 AM, midday aarti and bhog '
        'at 11:30 AM, and evening maha-aarti at 6:30 PM. Treat these as '
        'seasonal markers, not a permanent annual board; confirm locally '
        'or through Maa Mundeshwari Trust before climbing. Thin official '
        'continuous clock.',
    latitude: 24.9834,
    longitude: 83.5647,
    specialities: [
      'Often called one of India’s oldest continuously functioning temples',
      'Octagonal protected stone temple on Mundeshwari Hill',
      'Mundeshwari Devi / Shakti with central panchamukhi Shiva linga',
      'Gupta-period carving and early inscription',
      'Bloodless goat-offering tradition',
      'Ram Navami, Maha Shivaratri, and Navratri pilgrimage',
    ],
  ),

  Temple(
    name: 'Vishnupad Temple',
    state: 'Bihar',
    city: 'Gaya',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/vishnupad-temple/800/600',
    description:
        'Principal Vishnu shrine of Gaya, centred on a footprint revered '
        'as Vishnu’s and closely linked to pind daan and shraddha rites '
        'for ancestors on the Phalgu River.',
    story:
        'Vishnupad Temple is the ritual heart of Gaya’s Hindu pilgrimage '
        'landscape. Its name means “Vishnu’s foot”: a footprint-like '
        'impression in basalt, enclosed in a silver-plated setting, is '
        'revered as the mark left when Vishnu subdued Gayasura. The legend '
        'links the sacred geography of Gaya with liberation and offerings '
        'made for departed ancestors.\n\nThe present dark-stone, octagonal '
        'shrine was rebuilt in 1787 under Queen Ahilyabai Holkar of '
        'Indore. It stands by the Phalgu River near Akshayavat and the '
        'network of vedis used in the Gaya shraddha circuit. Gayawal '
        'pandas are the traditional pilgrimage priests, and families '
        'arrive throughout the year for pind daan; Pitrapaksha Mela '
        'creates the heaviest annual concentration.\n\nBihar Tourism '
        'prohibits mobile phones, cameras, and other electronic gadgets in '
        'the temple. Pilgrims arranging ancestor rites should agree '
        'clearly on services and costs before beginning, follow district '
        'mela guidance during Pitrapaksha, and reserve enough time for '
        'riverbank and vedi rituals beyond the main sanctum visit.',
    location: 'Vishnupad Road, on the Phalgu River, Gaya, Bihar 823001',
    timings:
        'Bihar Tourism currently presents daily visiting roughly 5:00 '
        'AM–9:00 PM, while some official ready-reckoner material has shown '
        'only a 5:00 AM–12:00 PM morning span. Named aarti and '
        'afternoon-break tables online are inconsistent and mostly '
        'secondary. Plan early-morning darshan and confirm the same-day '
        'afternoon/evening board locally, especially during Pitrapaksha '
        'when access and ritual flows change. Thin official '
        'afternoon/evening clock.',
    latitude: 24.77736,
    longitude: 85.00934,
    specialities: [
      'Sacred footprint revered as Vishnu’s Vishnupad',
      'Gayasura-subduing legend',
      'Major pind daan and shraddha centre',
      '1787 rebuild by Ahilyabai Holkar',
      'Phalgu River and Akshayavat pilgrimage landscape',
      'Pitrapaksha Mela focus',
    ],
  ),

  // KAN-77: Research-verified Wikimedia Commons thumbs (CC BY / BY-SA).
  // Attribution: tools/photo-packs/mahabodhi-temple/ATTRIBUTION.md
  // Replace with Firebase Storage URLs after:
  //   node scripts/upload_research_pack.js --pack tools/photo-packs/mahabodhi-temple --patch-firestore
  Temple(
    name: 'Mahabodhi Temple',
    state: 'Bihar',
    city: 'Bodh Gaya',
    deity: 'Buddha',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Mahabodhi_temple_at_Bodhgaya_in_Bihar_03.jpg/1280px-Mahabodhi_temple_at_Bodhgaya_in_Bihar_03.jpg',
    images: const [
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Mahabodhi_temple_at_Bodhgaya_in_Bihar_03.jpg/1280px-Mahabodhi_temple_at_Bodhgaya_in_Bihar_03.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Mahabodhi_Temple_%2C_Bodh_Gaya.jpg/1280px-Mahabodhi_Temple_%2C_Bodh_Gaya.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mahabodhi_Temple_Complex_-_Bodh_Gaya_%281%29.jpg/1280px-Mahabodhi_Temple_Complex_-_Bodh_Gaya_%281%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Mahabodhi_Temple_-_Bodh_Gaya_%281%29.jpg/1280px-Mahabodhi_Temple_-_Bodh_Gaya_%281%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Mahabodhi_temple_complex%2C_Bodhgaya_23.jpg/1280px-Mahabodhi_temple_complex%2C_Bodhgaya_23.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Mahabodhi_Temple_Shikhara_-_Bodh_Gaya_%281%29.jpg/1280px-Mahabodhi_Temple_Shikhara_-_Bodh_Gaya_%281%29.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Votive_Stupas_-_Mahabodhi_Temple_Complex_-_Bodh_Gaya_%281%29.jpg/1280px-Votive_Stupas_-_Mahabodhi_Temple_Complex_-_Bodh_Gaya_%281%29.jpg',
    ],
    description:
        'UNESCO World Heritage Buddhist temple complex at the place '
        'associated with Gautama Buddha’s Enlightenment, centred on the '
        'Mahabodhi Mahavihara and the Bodhi Tree.',
    story:
        'The Mahabodhi Temple Complex marks the place where Siddhartha '
        'Gautama is believed to have attained Enlightenment and become the '
        'Buddha. It is one of Buddhism’s four foremost pilgrimage '
        'destinations and an iconic Bihar sacred site, included here as a '
        'Buddhist pilgrimage entry rather than a Hindu temple. A '
        'descendant of the Bodhi Tree stands beside the main shrine and '
        'anchors meditation, circumambulation, and offerings.\n\nThe '
        'soaring brick Mahabodhi Mahavihara reflects a long history of '
        'building, restoration, and international devotion; UNESCO '
        'describes it as one of the earliest surviving brick Buddhist '
        'temples in India, with the standing fabric substantially '
        'associated with the 5th–6th centuries CE. The property was '
        'inscribed on the World Heritage List in 2002 and is managed by '
        'the Bodhgaya Temple Management Committee under Bihar law, with '
        'conservation guidance from the Archaeological Survey of '
        'India.\n\nDaily observance is explicitly Buddhist: sutta '
        'chanting, meditation, a kheer offering, circumambulation, '
        'flowers, lamps, and prayer by monastic and lay communities from '
        'many traditions. Buddha Purnima and large international prayer '
        'gatherings change crowd and security arrangements. Visitors '
        'should maintain silence around meditation areas and follow the '
        'current BTMC security and prohibited-item rules.',
    location:
        'Mahabodhi Temple Complex, Bodh Gaya, Gaya district, Bihar 824231',
    timings:
        'Official Bodhgaya Temple Management Committee daily programme: '
        'Mahabodhi Mahavihara opens 5:00 AM; sutta chanting and meditation '
        '5:30–6:00 AM; kheer offering 10:00 AM; Mahayana sutta chanting '
        '6:00–6:30 PM; Pali sutta chanting 6:30–7:00 PM; closes 9:00 PM. '
        'Major ceremonies and Buddha Purnima can modify movement and '
        'access — check bodhgayatemple.com.',
    latitude: 24.696,
    longitude: 84.9913,
    specialities: [
      'Site associated with Gautama Buddha’s Enlightenment',
      'Bodhi Tree and Vajrasana sacred focus',
      'UNESCO World Heritage Site since 2002',
      'Early surviving monumental brick Buddhist architecture',
      'Daily sutta chanting and meditation',
      'Global Buddhist pilgrimage destination',
    ],
  ),

  Temple(
    name: 'Patan Devi Temple',
    state: 'Bihar',
    city: 'Patna',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/patan-devi-temple/800/600',
    description:
        'Historic Badi Patan Devi shrine in Patna City, revered as a '
        'Shakti Peetha and as one of the guardian-goddess temples '
        'associated with the city’s old name, Pataliputra.',
    story:
        'Patan Devi refers to Patna’s old goddess tradition, represented '
        'principally by Badi Patan Devi at Sadikpur and Chhoti Patan Devi '
        'elsewhere in Patna City. This entry is specifically for Badi '
        'Patan Devi. The shrine is revered in Shakta tradition as a Shakti '
        'Peetha connected with the Sati legend, though lists and details '
        'of body-part associations vary across traditions.\n\nThe sanctum '
        'worships a group of goddess forms commonly identified as '
        'Mahakali, Mahalakshmi, and Mahasaraswati. Local tradition links '
        'the city’s name and protection to Patan Devi, making the temple '
        'both a neighbourhood shrine and a larger identity marker for '
        'historic Patna. Navratri and Durga Puja are the principal crowd '
        'peaks, with Tuesdays and Saturdays also busy.\n\nPublic timing '
        'sources disagree: Bihar Tourism’s Patna overview gives a broad '
        '5:00 AM–10:00 PM span, while Incredible India lists 6:00 AM–8:00 '
        'PM and some visitor sources show a midday break. Treat the '
        'official tourism windows as planning boundaries, but confirm the '
        'actual day’s opening and ritual closures locally.',
    location: 'Badi Patan Devi, Sadikpur, Patna City, Patna, Bihar 800007',
    timings:
        'Conflicting government tourism listings: Bihar Tourism’s Patna '
        'overview gives 5:00 AM–10:00 PM; Incredible India gives opening '
        '6:00 AM and closing 8:00 PM. The dedicated Bihar Tourism temple '
        'page does not publish a detailed ritual board, and secondary '
        'sources often show split sessions. Therefore use provisional '
        'visiting hours only and confirm locally; Navratri / Durga Puja '
        'crowd plans override ordinary access.',
    latitude: 25.60531,
    longitude: 85.20629,
    specialities: [
      'Badi Patan Devi shrine in historic Patna City',
      'Revered as a Shakti Peetha',
      'Mahakali–Mahalakshmi–Mahasaraswati goddess triad',
      'Guardian-goddess tradition linked with Patna / Pataliputra',
      'Major Navratri and Durga Puja pilgrimage',
      'Distinct from Chhoti Patan Devi',
    ],
  ),

  Temple(
    name: 'Mangala Gauri Temple',
    state: 'Bihar',
    city: 'Gaya',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/mangala-gauri-temple/800/600',
    description:
        'Hilltop Shakti shrine in Gaya, revered as Mangala Gauri and '
        'counted in tradition among the eighteen Maha Shakti Peethas; '
        'especially visited during the Shravan Mangala Gauri Tuesday '
        'observances.',
    story:
        'Mangala Gauri Temple stands on a hill in Gaya’s sacred landscape '
        'and is dedicated to the auspicious mother goddess. It is '
        'traditionally counted among the eighteen Maha Shakti Peethas and '
        'associated with the breast of Sati, a symbolism tied to '
        'nourishment and maternal power. The compact shrine is reached by '
        'steps and shares the hill precinct with smaller Shiva, Durga, and '
        'Dakshina Kali shrines.\n\nThe temple has a special place in '
        'household and marital devotion. Newly married couples seek '
        'blessings, while women observe Mangala Gauri vrata on Tuesdays in '
        'the month of Shravan for family welfare and auspicious married '
        'life. Navratri also brings heavy attendance, and the narrow '
        'approach becomes congested.\n\nBihar Tourism’s broad guidance is '
        'sunrise to sunset rather than a detailed pooja schedule. Multiple '
        'commercial listings publish incompatible split clocks and aarti '
        'minutes, so they should not be treated as authoritative. An early '
        'morning visit is best for the climb and quieter darshan.',
    location: 'Mangala Gauri Hill, Gaya, Bihar 823001',
    timings:
        'Bihar Tourism gives a broad sunrise-to-sunset visiting span '
        'rather than fixed all-season minutes. Secondary sources variously '
        'cite 6:00 AM–8:00 PM or split morning/evening sessions, so exact '
        'aarti and closure times are thin / provisional. Confirm locally, '
        'especially on Shravan Tuesdays and during Navratri.',
    latitude: 24.77514,
    longitude: 85.00231,
    specialities: [
      'Traditional Maha Shakti Peetha of Mangala Gauri',
      'Sati-breast / maternal nourishment symbolism',
      'Hilltop stair approach in Gaya',
      'Shravan Tuesday Mangala Gauri vrata',
      'Newlywed and family-welfare pilgrimage',
      'Navratri observances',
    ],
  ),

  Temple(
    name: 'Ajgaibinath Temple',
    state: 'Bihar',
    city: 'Sultanganj',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ajgaibinath-temple/800/600',
    description:
        'Ancient Shiva temple on a rocky Ganges outcrop at Sultanganj, '
        'where Kanwar pilgrims collect river water before beginning the '
        'long Shravan journey toward Baidyanath Dham.',
    story:
        'Ajgaibinath Temple, also written Ajgaivinath, rises from a rocky '
        'hill beside the Ganges at Sultanganj. The shrine is dedicated to '
        'Shiva and is known for its dramatic river setting, stone '
        'carvings, and inscriptions. Access conditions can change with the '
        'Ganges level and the state of the connecting '
        'approach.\n\nSultanganj is a principal starting point of the '
        'Shravani Kanwar Yatra. Pilgrims take Ganga water here and carry '
        'it in kanwars on the route toward Baidyanath Dham at Deoghar, '
        'traditionally without setting the vessel on the ground. The '
        'orange-clad pilgrimage transforms the town throughout Shravan, '
        'producing continuous flows, traffic diversions, temporary camps, '
        'and special worship arrangements.\n\nBihar Tourism lists the site '
        'as open 24/7, which is best understood as broad precinct access '
        'rather than a guarantee that every inner-sanctum ritual or priest '
        'service operates continuously. For ordinary visits, daylight is '
        'safer for the river approach; during Shravan, follow district '
        'crowd and river-safety instructions.',
    location:
        'Ajgaibinath Dham, Ganga riverfront, Sultanganj, Bhagalpur '
        'district, Bihar 813213',
    timings:
        'Bihar Tourism lists Ajgaibinath Mandir as open 24/7. Treat that '
        'as broad site / precinct access: inner-sanctum service, river '
        'approach, and ritual handling can still vary with water level, '
        'season, and the Shravan Kanwar crowd plan. Daylight visits are '
        'preferable outside organised yatra conditions.',
    latitude: 25.25239,
    longitude: 86.73431,
    specialities: [
      'Shiva shrine on a rocky Ganges outcrop',
      'Sultanganj starting point for Shravani Kanwar Yatra',
      'Ganga-water collection for Baidyanath Dham',
      'Stone carvings and inscriptions',
      'Dramatic river-island / riverbank setting',
      'Major Shravan Mela pilgrimage logistics',
    ],
  ),

  Temple(
    name: 'Deo Sun Temple',
    state: 'Bihar',
    city: 'Deo',
    deity: 'Surya',
    imageUrl: 'https://picsum.photos/seed/deo-sun-temple/800/600',
    description:
        'Historic Surya temple at Deo in Aurangabad district, one of '
        'Bihar’s foremost Chhath pilgrimage centres, with worship focused '
        'on sunrise, sunset, and the nearby Brahma Kund.',
    story:
        'Deo Sun Temple is the principal Surya shrine of Aurangabad '
        'district and one of Bihar’s emblematic Chhath destinations. The '
        'tall stone temple, about 100 feet according to the district '
        'administration, has an umbrella-like crown and is linked by local '
        'history to a Chandravanshi ruler of Umga. Dating claims vary, so '
        'the district’s broad “15th century old” description should not be '
        'converted into a precise foundation year without inscriptional '
        'support.\n\nWorship is centred on Surya and on arghya at sunrise '
        'and sunset. Pilgrims also bathe at Brahma Kund, a custom the '
        'district page associates with old royal tradition. During Chaiti '
        'Chhath and Kartik Chhath, thousands gather in Deo and the '
        'ordinary visitor clock is replaced by festival crowd-control and '
        'extended ritual access.\n\nBihar Tourism currently gives a broad '
        '6:00 AM–6:00 PM visitor span, while other tourism material and '
        'guides publish longer days. Use the Bihar Tourism span for '
        'ordinary planning and verify locally before dawn worship or any '
        'evening visit.',
    location: 'Deo, Aurangabad district, Bihar 824202',
    timings:
        'Bihar Tourism currently lists approximately 6:00 AM–6:00 PM for '
        'ordinary visits, with worship focused around sunrise and sunset. '
        'Other ready-reckoner / visitor sources have published longer '
        'spans, so the edges are provisional. Kartik and Chaiti Chhath '
        'operate under special, often extended schedules and district '
        'crowd plans — confirm before travel. Thin official ordinary-day '
        'edges.',
    latitude: 24.65879,
    longitude: 84.43703,
    specialities: [
      'Major Surya temple and Bihar Chhath pilgrimage centre',
      'Sunrise and sunset arghya worship',
      'Brahma Kund ritual bathing',
      'Roughly 100-foot stone tower with umbrella-like crown',
      'Kartik and Chaiti Chhath congregations',
      'Historic association with the Umga royal line',
    ],
  ),

  Temple(
    name: 'Ugratara Temple',
    state: 'Bihar',
    city: 'Mahishi',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/ugratara-temple/800/600',
    description:
        'Ancient Bhagwati Tara shrine at Mahishi near Saharsa, where '
        'Ugratara is worshipped with the companion goddess forms Ekjata '
        'and Nil Saraswati.',
    story:
        'Shri Ugratara Sthan lies in Mahishi village, about 17 kilometres '
        'west of Saharsa station. The ancient temple centres on Bhagwati '
        'Tara in her fierce Ugratara form and draws devotees across the '
        'Kosi region. The Saharsa district page records two smaller female '
        'deities beside the principal image, worshipped as Ekjata and Nil '
        'Saraswati.\n\nThe shrine belongs to the living Shakta and Tara '
        'tradition and is often described locally as a siddha or Shakti '
        'site. Associations with the scholar Mandana Mishra and the '
        'intellectual landscape of Mahishi are part of regional memory, '
        'but claims about exact antiquity and formal Shakti Peetha rank '
        'differ across sources and should be presented as tradition rather '
        'than settled history.\n\nSharadiya Navratri and Dussehra are the '
        'major annual peaks. No strong temple-run public timetable was '
        'found: online directories disagree on the midday closure, though '
        'they broadly place worship from early morning into the evening. '
        'The district page is strong for identity and access, not for '
        'ritual minutes.',
    location: 'Shri Ugratara Sthan, Mahishi, Saharsa district, Bihar 852216',
    timings:
        'Thin official clock. The Saharsa district and Bihar Tourism pages '
        'identify the shrine but do not publish a daily timetable. '
        'Secondary listings commonly give 5:00 AM–2:30 PM and 3:30–9:00 '
        'PM; another gives 5:00 AM–12:00 PM and 4:00–9:00 PM. Use only as '
        'a planning range and confirm locally; Navratri / Dussehra '
        'schedules override.',
    latitude: 25.8483,
    longitude: 86.4728,
    specialities: [
      'Bhagwati Tara in fierce Ugratara form',
      'Companion images of Ekjata and Nil Saraswati',
      'Important Kosi-region Shakta pilgrimage',
      'Mahishi sacred and scholarly landscape',
      'Sharadiya Navratri and Dussehra crowds',
      'Ancient image noted by Saharsa district administration',
    ],
  ),

  Temple(
    name: 'Janaki Temple Sitamarhi',
    state: 'Bihar',
    city: 'Sitamarhi',
    deity: 'Sita (Devi)',
    imageUrl: 'https://picsum.photos/seed/janaki-temple-sitamarhi/800/600',
    description:
        'Janaki temple complex at Punaura Dham near Sitamarhi, revered in '
        'local and Ramayana tradition as Sita’s birthplace and centred on '
        'Janaki Mandir and Sita Kund.',
    story:
        'This Sitamarhi Janaki entry uses Punaura Dham, about five '
        'kilometres west of Sitamarhi, rather than a similarly named urban '
        'temple. The pilgrimage complex is revered as Janaki Janmabhoomi: '
        'tradition holds that King Janaka found the infant Sita while '
        'ploughing the ritual field during a drought. Sita Kund or Janaki '
        'Kund preserves the landscape connection to that birth '
        'narrative.\n\nThe complex includes Janaki Mandir and spaces for '
        'Rama, Sita, and Ramayana-centred devotion. It forms a key Bihar '
        'stop on the Ramayan Circuit and maintains cultural links with '
        'Janakpur in Nepal. Ram Navami, Vivah Panchami, and especially '
        'Sita Navami / Janaki Navami bring larger congregations and '
        'devotional programmes.\n\nBihar Tourism gives a straightforward '
        '6:00 AM–6:00 PM visitor span. Temple-trust and local festival '
        'programmes may create midday ritual pauses or extend access, so '
        'visitors should re-check on festival dates. The birthplace '
        'identification is a revered local tradition and should be phrased '
        'as such, not as an archaeological certainty.',
    location: 'Punaura Dham, Punaura, Sitamarhi district, Bihar 843302',
    timings:
        'Bihar Tourism lists Punaura Dham visiting hours as 6:00 AM–6:00 '
        'PM. Some local / directory listings show longer split sessions, '
        'but no detailed trust-run daily ritual board was verified. Use '
        'the tourism span for ordinary planning and confirm Sita Navami, '
        'Ram Navami, and Vivah Panchami programmes locally.',
    latitude: 26.58645,
    longitude: 85.46676,
    specialities: [
      'Punaura Dham Janaki Janmabhoomi tradition',
      'Janaki Mandir and Sita / Janaki Kund',
      'King Janaka ploughing-field birth narrative',
      'Bihar Ramayan Circuit pilgrimage stop',
      'Sita Navami and Vivah Panchami observances',
      'Cultural links with Janakpur in Nepal',
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  //  HIMACHAL PRADESH
  // ═══════════════════════════════════════════════════════════════════════════
  // Expansion batch 15 — new temples, not enrichments of existing rows.
  // Jwalamukhi keeps two conflicting official Kangra portal clocks.
  // Baijnath (Kangra) is not the canonical Vaidyanath Jyotirlinga.
  // Cover imageUrl values are picsum placeholders. Commons candidates:
  // docs/himachal-pradesh-sample-research.md.
  Temple(
    name: 'Jwalamukhi Temple',
    state: 'Himachal Pradesh',
    city: 'Jwalamukhi',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/jwalamukhi-temple/800/600',
    description:
        'Major Kangra Shakti Peetha where Jwala Devi is worshipped as '
        'natural flames emerging from rock fissures rather than as a '
        'conventional idol; the shrine anchors the town of Jwalamukhi.',
    story:
        'Jwalamukhi (Jwala Ji) is one of Himachal Pradesh’s best-known '
        'Shakti shrines. Shakta tradition identifies it with the place '
        'where Sati’s tongue fell, and the goddess is encountered in the '
        'sanctum as sacred flames rising through fissures in the rock. The '
        'official Kangra Temples portal describes nine flames associated '
        'with forms including Mahakali, Annapurna, Chandi, Hinglaj, '
        'Mahalakshmi, Saraswati, and Ambika.\n\nThe flame sanctuary, '
        'without a conventional central idol, gives the temple its '
        'distinctive ritual character. Historical traditions connect the '
        'shrine with regional rulers, Mughal-era visitors, Maharaja Ranjit '
        'Singh, and later rebuilding; the present complex combines wood, '
        'marble, metalwork, domed forms, and subsidiary '
        'shrines.\n\nMorning and evening aarti frame daily worship, with '
        'darshan paused during aarti and the midday bhog interval. Chaitra '
        'and Sharad Navratri are the largest pilgrimage periods; the Trust '
        'also runs langar. Two pages on the official Kangra Temples portal '
        'currently publish materially different opening clocks, so '
        'visitors should verify the live board before travel rather than '
        'treating either table as permanent.\n\nThe approach is by hill '
        'roads in Kangra district. Monsoon rain, fog, road works, and '
        'Navratri traffic can lengthen travel and queues even though the '
        'temple remains a year-round pilgrimage site.',
    location:
        'Jwala Ji Temple Road, Jawalamukhi, Kangra district, Himachal '
        'Pradesh 176031',
    timings:
        'OFFICIAL-PAGE CONFLICT — confirm same day. The detailed Shri '
        'Jawala Mata Mandir profile on kangratemples.hp.gov.in lists '
        'winter darshan 5:00 AM–11:30 AM and 12:30–9:00 PM, summer 4:30 '
        'AM–11:30 AM and 12:30–10:00 PM; bhog closure 11:30 AM–12:30 PM. '
        'It lists winter aarti 5:30–6:00 AM, 6:00–7:00 PM and Shayan '
        '8:00–8:40 PM; summer aarti 5:00–5:30 AM, 7:00–8:00 PM and Shayan '
        '9:00–9:40 PM. A separate official e-puja page instead states '
        'winter 7:00–11:00 AM & 12:30–9:30 PM and summer 6:00–11:30 AM & '
        '12:30–10:00 PM, with aarti at 7:00 AM/7:00 PM winter and 6:00 '
        'AM/8:00 PM summer. Darshan pauses during aarti/bhog; Navratri can '
        'extend access.',
    latitude: 31.8752,
    longitude: 76.3243,
    specialities: [
      'Shakti Peetha associated with Sati’s tongue',
      'Natural sacred flames worshipped instead of a conventional idol',
      'Nine-flame / nine-goddess tradition',
      'Morning, evening, and Shayan aarti rhythm',
      'Major Chaitra and Sharad Navratri pilgrimage',
      'Temple Trust langar for pilgrims',
    ],
  ),

  Temple(
    name: 'Naina Devi Temple',
    state: 'Himachal Pradesh',
    city: 'Naina Devi',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/naina-devi-temple/800/600',
    description:
        'Hilltop Shakti Peetha in Bilaspur district, traditionally '
        'associated with Sati’s eyes and commanding broad views toward the '
        'Sutlej–Bhakra landscape.',
    story:
        'Shri Naina Devi Ji stands on a Bilaspur hill above the plains and '
        'Bhakra region. Shakta tradition identifies the site with Sati’s '
        'eyes (naina), making the goddess one of the most prominent Shakti '
        'Peetha forms in northern India. The official Temple Trust site '
        'places the shrine at roughly 1,200 metres elevation.\n\nLocal '
        'foundation traditions connect the sanctuary with Raja Bir Chand '
        'and with a Gujjar boy named Naina who discovered or worshipped '
        'the sacred presence. The present marble-clad complex contains the '
        'main Devi shrine and subsidiary deities, reached by road, steps, '
        'and a ropeway when operating.\n\nOrdinary darshan runs from '
        'before dawn into the night; during Navratri the official Trust '
        'expands access from 2:00 AM to midnight. Chaitra and Sharad '
        'Navratri, Shravan fairs, weekends, and public holidays bring the '
        'heaviest queues.\n\nBecause this is an exposed hilltop '
        'pilgrimage, fog, thunderstorms, high winds, or maintenance may '
        'affect ropeway service. Road users should also allow for monsoon '
        'disruption and festival traffic, and should follow Trust and '
        'district instructions on the day.',
    location:
        'Shri Naina Devi Ji Temple, Naina Devi, Bilaspur district, '
        'Himachal Pradesh 174310',
    timings:
        'Official Shri Naina Devi Ji Temple Trust board: normal days 4:00 '
        'AM–10:00 PM; Navratri 2:00 AM–12:00 midnight. Incredible India '
        'separately displays 5:00 AM–9:00 PM, so prefer the Temple Trust’s '
        'live board and confirm festival-day changes. Individual '
        'aarti/ritual minutes are not firmly published on the official '
        'home page; do not rely on secondary 5:00 AM/7:00 PM claims '
        'without same-day confirmation.',
    latitude: 31.30603,
    longitude: 76.53639,
    specialities: [
      'Shakti Peetha associated with Sati’s eyes (naina)',
      'Hilltop shrine at roughly 1,200 metres',
      'Extended 2:00 AM–midnight Navratri darshan',
      'Views toward the Bhakra–Sutlej hill landscape',
      'Road, stair, and ropeway approaches',
      'Major Bilaspur Devi pilgrimage centre',
    ],
  ),

  Temple(
    name: 'Chintpurni Temple',
    state: 'Himachal Pradesh',
    city: 'Chintpurni',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chintpurni-temple/800/600',
    description:
        'Una district Shakta pilgrimage shrine of Mata Chintpurni, also '
        'revered as Chhinnamastika, where devotees seek freedom from worry '
        'and worship a sacred pindi.',
    story:
        'Mata Chintpurni Devi is worshipped as the mother who removes '
        'chinta (worry) and as Chhinnamastika, a Shakta form associated '
        'with self-sacrifice and transformative power. The shrine stands '
        'in the lower Shivalik hills of Una district and is widely '
        'included in Himachal’s Devi pilgrimage circuit.\n\nTradition '
        'credits Pandit Mai Das with establishing worship after a divine '
        'revelation; the central presence is a pindi rather than a large '
        'anthropomorphic image. Pilgrims circumambulate the compact bhavan '
        'and may hear continuous bhajan or kirtan during busy seasons. '
        'Historic genealogy registers have also been maintained by '
        'pilgrimage priests at Chintpurni.\n\nThe official temple site '
        'publishes a clear ritual rhythm: morning bathing and aarti, a '
        'noon bhog pause when darshan stops, evening bathing and aarti, '
        'and night sayan. Chaitra, Shravan, and Ashwin Navratri melas are '
        'major peaks, when darshan-parchi and crowd controls are '
        'especially important.\n\nThe hill approach remains comparatively '
        'accessible year-round, but monsoon rain, fog, and mela traffic '
        'can delay buses and cars. Follow the Temple Trust’s queue and '
        'parchi instructions rather than agents or back-door offers.',
    location:
        'Mata Shri Chintpurni Devi Ji, Chintpurni, Amb tehsil, Una '
        'district, Himachal Pradesh 177110',
    timings:
        'Official religious-activity board: Goddess snan and morning aarti '
        '6:30 AM; bhog 12:00–12:30 PM (darshan stopped); evening snan and '
        'aarti 6:30–8:00 PM; Goddess sayan 10:00 PM. General open/close is '
        'thinner on the official page; secondary seasonal boards commonly '
        'list summer (Apr–Oct) 4:30 AM–10:00 PM and winter (Nov–Mar) 5:30 '
        'AM–9:30 PM — PROVISIONAL, confirm with the Temple Trust. '
        'Navratri/mela days may open earlier or extend access.',
    latitude: 31.80862,
    longitude: 76.10287,
    specialities: [
      'Mata Chintpurni / Chhinnamastika Shakta shrine',
      'Sacred pindi worship attributed to Pandit Mai Das',
      'Official snan, aarti, bhog, and sayan ritual board',
      'Three major Navratri mela periods',
      'Hindu pilgrimage genealogy-register tradition',
      'Darshan-parchi crowd-management system',
    ],
  ),

  Temple(
    name: 'Chamunda Devi Temple',
    state: 'Himachal Pradesh',
    city: 'Dharamshala',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/chamunda-devi-temple/800/600',
    description:
        'Major Kangra Devi shrine on the Baner River near Dharamshala and '
        'Palampur, jointly sacred to fierce Chamunda and Shiva as '
        'Nandikeshwar.',
    story:
        'Shri Chamunda Nandikeshwar Dham stands beside the Baner River in '
        'the Dharamshala–Palampur area. It honours Chamunda, the fierce '
        'Durga form associated with the defeat of Chanda and Munda, '
        'together with Nandikeshwar Shiva; the paired identity gives the '
        'site an important Shakti–Shaiva character.\n\nRegional tradition '
        'says the older Aadi Himani Chamunda shrine lay high on the '
        'mountain and was difficult to reach. A ruler and priest, guided '
        'in a dream, established the more accessible valley shrine several '
        'centuries ago. The riverside complex now serves as one of '
        'Kangra’s busiest living Devi temples, with bathing ghats and '
        'subsidiary sacred spaces.\n\nThe official Kangra Temples portal '
        'publishes separate summer and winter opening spans, a one-hour '
        'noon bhog closure, and fixed morning/evening aarti windows. '
        'Navratri and other Devi observances bring dense queues and may '
        'alter access controls.\n\nDo not confuse this shrine with '
        'Chamundeshwari Temple in Mysuru or Chamunda temples in Chamba. '
        'Monsoon-swollen water, rain, fog, and Kangra road conditions '
        'require ordinary hill-travel caution.',
    location:
        'Shri Chamunda Nandikeshwar Dham, Padar (Dadh), Kangra district, '
        'Himachal Pradesh 176052',
    timings:
        'Official Kangra Temples board. Winter: 6:00 AM–12:00 PM and '
        '1:00–9:00 PM; summer: 5:00 AM–12:00 PM and 1:00–10:00 PM. Closed '
        '12:00–1:00 PM for bhog in both seasons. Morning aarti 8:00–8:45 '
        'AM; evening aarti 7:10–7:50 PM. Festival-day arrangements can '
        'override — confirm on kangratemples.hp.gov.in.',
    latitude: 32.14833,
    longitude: 76.41917,
    specialities: [
      'Chamunda Devi with Shiva as Nandikeshwar',
      'Baner River setting near Dharamshala–Palampur',
      'Accessible valley shrine linked to Aadi Himani Chamunda',
      'Official seasonal darshan and aarti board',
      'One of Kangra’s five major Devi pilgrimage stops',
      'Peak Navratri worship and queues',
    ],
  ),

  Temple(
    name: 'Baijnath Temple',
    state: 'Himachal Pradesh',
    city: 'Baijnath',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/baijnath-temple/800/600',
    description:
        'ASI-protected Nagara-style Shiva temple at Baijnath, built in '
        '1204 and dedicated to Vaidyanath, Shiva as the Lord of Physicians.',
    story:
        'Baijnath Temple is dedicated to Shiva as Vaidyanath, the Lord of '
        'Physicians. Two long inscriptions record construction of the '
        'present stone temple in 1204 by local merchants Ahuka and Manyuka '
        'on a site where Shiva worship already existed. The town, '
        'historically Kiragrama, came to be known by the deity’s '
        'name.\n\nThe compact Nagara temple has a curving shikhara, '
        'pillared mandapa, Nandi, a linga in the sanctum, and exterior '
        'images including Ganesha, Harihara, Kalyanasundara, and Shiva’s '
        'defeat of Andhaka. It is protected and conserved by the '
        'Archaeological Survey of India; repairs are associated with '
        'Kangra ruler Sansar Chand, and the complex survived the '
        'destructive 1905 earthquake with limited damage.\n\nLocal Ravana '
        'lore says the Shiva linga became fixed here while the Lanka king '
        'carried it south. In respect for Ravana’s devotion, Baijnath is '
        'noted for not celebrating Dussehra in the usual effigy-burning '
        'manner. Maha Shivaratri is the temple’s largest annual '
        'observance.\n\nIncredible India publishes all-day visiting from '
        '6:00 AM to 9:00 PM. Festival crowds, worship in the compact '
        'sanctum, and Dhauladhar weather can change the practical darshan '
        'pace; verify the local board before a special puja.\n\nThis '
        'Kangra shrine is an ASI-protected living temple of Shiva as '
        'Vaidyanath. It is not the canonical Vaidyanath Jyotirlinga, and '
        'it is distinct from the Baijnath temple in Uttarakhand.',
    location:
        'Baijnath Shiv Temple, Baijnath, Kangra district, Himachal Pradesh '
        '176125',
    timings:
        'Incredible India visitor board: open daily 6:00 AM–9:00 PM. Named '
        'morning/evening aarti minutes found on third-party guides are not '
        'firmly confirmed by the government page, so confirm locally. Maha '
        'Shivaratri, Shravan Mondays, maintenance, or ASI/temple controls '
        'may alter access. The temple is in the Dhauladhar foothills; '
        'winter fog/ice and monsoon road delays can affect arrival even '
        'when the shrine is open.',
    latitude: 32.05095,
    longitude: 76.64553,
    specialities: [
      'Shiva as Vaidyanath — Lord of Physicians',
      'Dated by inscriptions to 1204; patrons Ahuka and Manyuka',
      'ASI-protected Nagara stone architecture',
      'Sanskrit Sharada and local Takri inscription heritage',
      'Ravana lore and distinctive local Dussehra custom',
      'Major Maha Shivaratri pilgrimage',
    ],
  ),

  Temple(
    name: 'Bhimakali Temple',
    state: 'Himachal Pradesh',
    city: 'Sarahan',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/bhimakali-temple/800/600',
    description:
        'Towering kath-kuni Devi complex at Sarahan, the historic kuldevi '
        'shrine of the Bushahr rulers and one of Himachal’s most '
        'distinctive wood-and-stone temples.',
    story:
        'Bhimakali Temple at Sarahan is the historic goddess shrine of the '
        'former Bushahr kingdom. Bhimakali is revered as the rulers’ '
        'kuldevi, and regional tradition treats Sarahan as a Shakta sacred '
        'site associated in one account with Sati’s ear. Navratri and '
        'Dussehra are the largest observances.\n\nThe complex is '
        'celebrated for kath-kuni construction: alternating deodar timber '
        'and stone courses that create resilient Himalayan tower '
        'architecture. Twin towers, layered courtyards, richly worked wood '
        'and silver, gilded gateways, and subsidiary Narsingha and '
        'Raghunath shrines combine Hindu and trans-Himalayan visual '
        'traditions.\n\nThe older fabric has undergone rebuilding and '
        'conservation, including work under Raja Padam Singh in the 1920s. '
        'Because this is a living royal-temple complex, entry, clothing, '
        'leather-item, and photography rules may be stricter near the '
        'upper sanctum than in the courtyards.\n\nPublished daily clocks '
        'are inconsistent and no strong current Temple Trust timetable was '
        'found. Treat the commonly reported split windows as planning '
        'guidance only, and call or confirm locally. Sarahan’s mountain '
        'road can be affected by monsoon landslides, winter snow/ice, fog, '
        'and works on the Hindustan–Tibet road approach.',
    location:
        'Shri Bhimakali Temple, Sarahan, Rampur tehsil, Shimla district, '
        'Himachal Pradesh 172102',
    timings:
        'THIN OFFICIAL CLOCK — provisional. Recent visitor sources '
        'commonly report 6:00 AM–12:00/1:00 PM and 2:00/4:00–7:00/7:15 PM; '
        'some extend evening access later in peak season. Morning aarti is '
        'often reported around 6:00 AM in summer and later in winter, but '
        'no stable current Temple Trust web board was found. Confirm '
        'locally (Temple Trust contact commonly listed: 01782-233002) '
        'before travel. Navratri/Dussehra and seasonal daylight can alter '
        'access.',
    latitude: 31.44943,
    longitude: 77.63087,
    specialities: [
      'Kuldevi shrine of the former Bushahr rulers',
      'Kath-kuni wood-and-stone tower architecture',
      'Twin towers, courtyards, carved wood, and silverwork',
      'Narsingha and Raghunath subsidiary shrines',
      'Major Navratri and Dussehra observances',
      'High Himalayan Sarahan pilgrimage setting',
    ],
  ),

  Temple(
    name: 'Hadimba Devi Temple',
    state: 'Himachal Pradesh',
    city: 'Manali',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/hadimba-devi-temple/800/600',
    description:
        'Four-tiered wooden pagoda temple in Manali’s cedar forest, '
        'dedicated to Hidimbi (Hadimba), Bhima’s wife and a powerful local '
        'goddess of the Kullu valley.',
    story:
        'Hadimba Devi Temple, also called Hidimba or Dhungri Temple, '
        'stands in a deodar grove above central Manali. It is dedicated to '
        'Hidimbi from the Mahabharata, who married Bhima after he defeated '
        'her brother Hidimb and became the mother of the warrior '
        'Ghatotkacha. In local tradition she is not merely an epic figure '
        'but a sovereign protective goddess of the valley.\n\nMaharaja '
        'Bahadur Singh is traditionally credited with building the present '
        'temple in 1553. Its 24-metre wooden tower rises through three '
        'square timber-tiled roofs to a brass finial; carved doors show '
        'deities, dancers, animals, foliage, and epic imagery. The sanctum '
        'encloses a sacred rock/cave form, while a Ghatotkacha shrine '
        'stands nearby.\n\nThe Dhungri/Hadimba fair in spring and Manali’s '
        'Navratri traditions highlight the goddess’s civic importance. '
        'Worship is usually simple darshan rather than a heavily '
        'advertised online-seva programme; no dependable official '
        'minute-by-minute aarti board was found.\n\nThe grove is '
        'accessible in most seasons, but snow, black ice, monsoon rain, '
        'tourist traffic, and parking controls can slow the last approach. '
        'Walk carefully on wet or icy stone and timber surfaces.',
    location:
        'Hadimba Temple Road, Dhungri, Manali, Kullu district, Himachal '
        'Pradesh 175131',
    timings:
        'Incredible India lists daily opening 8:00 AM–6:00 PM. No strong '
        'official fixed aarti schedule was found; confirm any special '
        'ritual locally. The practical closing can be '
        'daylight/weather-sensitive in winter, while fairs, Navratri, and '
        'peak tourist days create queues. Snow, ice, heavy rain, or local '
        'traffic restrictions may affect access even if the temple itself '
        'remains open.',
    latitude: 32.24228,
    longitude: 77.18737,
    specialities: [
      'Hidimbi/Hadimba — Mahabharata figure and Kullu valley goddess',
      '1553 wooden pagoda attributed to Maharaja Bahadur Singh',
      'Three timber roofs, brass finial, and carved wooden doors',
      'Sacred rock/cave-form sanctum in a deodar grove',
      'Nearby Ghatotkacha shrine',
      'Dhungri (Hadimba Devi) spring fair',
    ],
  ),

  Temple(
    name: 'Lakshmi Narayan Temple',
    state: 'Himachal Pradesh',
    city: 'Chamba',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/lakshmi-narayan-temple/800/600',
    description:
        'Chamba’s principal historic temple group: six early Nagara '
        'shrines aligned north–south, led by Lakshmi Narayan and divided '
        'between Vishnu and Shiva dedications.',
    story:
        'The Lakshmi Narayan group is Chamba’s principal temple complex '
        'and is traditionally attributed to Raja Sahil Varman in the 10th '
        'century. The northernmost shrine is dedicated to Lakshmi Narayan, '
        'and the group takes its name from this Vishnu form.\n\nSix major '
        'stone temples stand in a north–south row: three associated with '
        'Vishnu and three with Shiva. Their curving Nagara shikharas, '
        'mandapas, carved doorways, river-goddess figures, and narrative '
        'sculpture preserve some of the oldest monumental architecture in '
        'Chamba. Later rulers added shrines, metal pinnacles, and '
        'protective wooden chhatris suited to snow and mountain '
        'weather.\n\nThe complex remains a living place of worship as well '
        'as a heritage ensemble. Janmashtami, Ram Navami, and major '
        'Vaishnava observances are important, while the Shiva shrines '
        'maintain their own ritual identities. Visitors should avoid '
        'treating every building as a single Lakshmi Narayan '
        'sanctum.\n\nOfficial district and national tourism pages describe '
        'the history but do not publish a firm daily clock. Commonly '
        'circulated split hours should therefore be treated as provisional '
        'and checked at the entrance, especially in winter, festivals, or '
        'restoration periods.',
    location:
        'Lakshmi Narayan Temple Complex, Chowgan Mohalla, Chamba, Himachal '
        'Pradesh 176310',
    timings:
        'THIN OFFICIAL CLOCK — provisional. Visitor guides commonly list '
        '6:00 AM–12:30 PM and 2:30–8:30 PM daily, but the Chamba district '
        'and Incredible India pages do not publish a firm schedule. '
        'Confirm at the temple entrance or District Tourism office before '
        'relying on these windows. Winter daylight, festival rituals, '
        'conservation work, or severe hill weather can shorten access.',
    latitude: 32.55781,
    longitude: 76.1247,
    specialities: [
      'Chamba’s principal 10th-century temple complex',
      'Six major shrines: three Vishnu and three Shiva',
      'Nagara shikharas with Himalayan protective chhatris',
      'Attributed to Raja Sahil Varman',
      'Historic sculpture, inscriptions, and copper-plate patronage',
      'Living worship within a heritage ensemble',
    ],
  ),

  Temple(
    name: 'Panchvaktra Temple',
    state: 'Himachal Pradesh',
    city: 'Mandi',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/panchvaktra-temple/800/600',
    description:
        'ASI-protected Shikhara-style Shiva temple at the Beas–Suketi '
        'confluence in Mandi, centred on a five-faced Panchvaktra image.',
    story:
        'Panchvaktra Mahadev stands where the Suketi meets the Beas in '
        'Mandi, the historic ‘Varanasi of the Hills.’ Its principal image '
        'presents Shiva with five faces, a form interpreted through the '
        'deity’s multiple cosmic aspects and giving the temple its '
        'name.\n\nThe stone shrine is built in a North Indian shikhara '
        'idiom with a carved porch and compact sanctum. Its original date '
        'remains uncertain; regional histories associate restoration with '
        'Raja Sidh Sen after flood damage in the late 17th or early 18th '
        'century. The Archaeological Survey of India protects it as '
        'monument N-HP-36.\n\nDaily worship continues within the protected '
        'structure, and Maha Shivaratri is especially important in Mandi’s '
        'wider deity processions and fair. The riverside setting is '
        'integral to the experience, but it also means that flood controls '
        'and conservation barriers must be respected.\n\nNo dependable '
        'official daily timetable was found. Published hours vary '
        'substantially, so use the provisional daytime window only for '
        'planning and verify locally, particularly during monsoon, '
        'Shivaratri, or restoration work.',
    location:
        'Panchvaktra Mahadev Temple, near Victoria Bridge at the '
        'Beas–Suketi confluence, Mandi, Himachal Pradesh 175001',
    timings:
        'THIN OFFICIAL CLOCK — provisional. Published visitor listings '
        'vary between roughly 6:00 AM–6:00 PM, 7:00 AM–8:00 PM, and split '
        '6:00 AM–12:30 PM & 4:00–9:00 PM. No authoritative current '
        'temple/ASI clock was found; plan a daylight visit, preferably '
        'morning, and confirm locally. Maha Shivaratri, worship pauses, '
        'ASI work, or high-river/monsoon controls may change access.',
    latitude: 31.71131,
    longitude: 76.93563,
    specialities: [
      'Five-faced Panchvaktra form of Shiva',
      'Beas–Suketi river-confluence setting',
      'ASI-protected monument N-HP-36',
      'North Indian shikhara architecture and carved porch',
      'Restoration associated with Raja Sidh Sen',
      'Part of Mandi’s Maha Shivaratri sacred landscape',
    ],
  ),

  Temple(
    name: 'Manikaran Shiva Temple',
    state: 'Himachal Pradesh',
    city: 'Manikaran',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/manikaran-shiva-temple/800/600',
    description:
        'Shiva–Parvati pilgrimage precinct in Manikaran’s Parvati Valley, '
        'inseparable from geothermal hot springs, nearby Raghunath Temple, '
        'and the shared Hindu–Sikh sacred townscape.',
    story:
        'Manikaran is a pilgrimage town on the Parvati River, known for '
        'Shiva–Parvati worship and geothermal springs hot enough to cook '
        'food. Hindu legend says Parvati lost a jewel (mani); when Shiva '
        'demanded its return, Sheshnag’s hissing sent boiling water and '
        'jewels upward, giving Manikaran its sacred name and hot-spring '
        'mythology.\n\nThe Shiva–Parvati temple stands within a dense '
        'sacred precinct that also includes the Raghunath/Ram temple and '
        'Gurudwara Manikaran Sahib. Tradition links the Raghunath shrine '
        'with Kullu ruler Raja Jagat Singh. Hindu and Sikh pilgrims share '
        'the hot-water landscape while following the distinct etiquette of '
        'temple, bathing, and gurdwara spaces.\n\nThe 1905 Kangra '
        'earthquake damaged structures and is said to have altered the '
        'springs; the Shiva temple is often noted for a slight tilt. '
        'Bathing and food preparation around the springs are living '
        'practices, but water temperatures can be dangerously high and '
        'only designated areas should be used.\n\nNo single authoritative '
        'daily web timetable was found for the Shiva and Raghunath '
        'shrines. Hours published online conflict, so a conservative '
        'daytime visit with local confirmation is appropriate. Parvati '
        'Valley access is vulnerable to landslides, flash floods, '
        'snow/ice, road works, and severe traffic; district advisories are '
        'essential.',
    location:
        'Shiv–Parvati Temple and hot-spring pilgrimage precinct, '
        'Manikaran, Parvati Valley, Kullu district, Himachal Pradesh 175105',
    timings:
        'THIN OFFICIAL CLOCK — confirm locally. The Kullu district page '
        'documents Manikaran but gives no temple schedule; secondary '
        'listings conflict (Shiva temple often ~6:00 AM–8:00 PM or split '
        'morning/evening; Raghunath often ~8:00 AM–7:00 PM). Do not treat '
        '24-hour claims as reliable temple access. Visit in daylight and '
        'check each shrine’s board. Festivals, winter conditions, '
        'landslides, flash-flood alerts, and road closures can override '
        'normal access.',
    latitude: 32.02761,
    longitude: 77.34585,
    specialities: [
      'Shiva–Parvati jewel legend (mani) and Sheshnag hot springs',
      'Geothermal pools used for bathing and cooking',
      'Nearby Raghunath/Ram temple tradition',
      'Shared Hindu–Sikh pilgrimage town with Manikaran Sahib',
      'Parvati River gorge setting',
      'Temple structures affected by the 1905 Kangra earthquake',
    ],
  ),
];
