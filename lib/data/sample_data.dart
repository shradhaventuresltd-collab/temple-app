import 'package:temple_app/models/temple.dart';

const List<Temple> sampleTemples = [
  // ═══════════════════════════════════════════════════════════════════════════
  //  TAMIL NADU
  // ═══════════════════════════════════════════════════════════════════════════
  Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: 'https://picsum.photos/seed/meenakshi/800/600',
    description:
        'A historic Hindu temple dedicated to Goddess Meenakshi (Parvati) and Lord Sundareswarar (Shiva), renowned for its stunning Dravidian gopurams adorned with thousands of colorful sculptures.',
    story:
        'Legend holds that Meenakshi was born with three breasts and a prophecy said the third would vanish when she met her future husband. When she encountered Lord Shiva at Mount Kailash, the prophecy came true, and their divine wedding is celebrated annually as Meenakshi Thirukalyanam.',
    location: 'Madurai Main, Madurai, Tamil Nadu 625001',
    timings: '5:00 AM – 12:30 PM, 4:00 PM – 10:00 PM',
    latitude: 9.9195,
    longitude: 78.1193,
    specialities: [
      '14 magnificent gopurams',
      'Golden lotus tank (Potramarai Kulam)',
      'Thousand Pillar Hall with musical pillars',
      'Meenakshi Thirukalyanam festival',
    ],
  ),
  Temple(
    name: 'Brihadeeswarar Temple',
    state: 'Tamil Nadu',
    city: 'Thanjavur',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/brihadeeswarar/800/600',
    description:
        'A UNESCO World Heritage Site built by Raja Raja Chola I in 1010 AD, this temple is a masterpiece of Chola architecture with a towering 66-metre vimana crowned by an 80-ton monolithic granite cupola.',
    story:
        'It is said the massive shadow of the vimana never falls on the ground at noon. The 80-ton capstone was moved to the top using an inclined plane stretching several kilometres — an engineering marvel of the 11th century.',
    location: 'Membalam Rd, Balaganapathy Nagar, Thanjavur, Tamil Nadu 613007',
    timings: '6:00 AM – 12:30 PM, 4:00 PM – 8:30 PM',
    latitude: 10.7828,
    longitude: 79.1318,
    specialities: [
      'UNESCO World Heritage Site',
      'Monolithic Nandi (25 tons)',
      'Shadow-less vimana at noon',
      'Chola bronze gallery',
    ],
  ),
  Temple(
    name: 'Kapaleeshwarar Temple',
    state: 'Tamil Nadu',
    city: 'Chennai',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/kapaleeshwarar/800/600',
    description:
        'A 7th-century Dravidian temple dedicated to Lord Shiva as Kapaleeshwarar, located in the cultural heart of Mylapore, Chennai, with a 37-metre-high gopuram.',
    story:
        'Goddess Parvati is said to have worshipped Shiva here in the form of a peahen (Myil in Tamil), giving the neighbourhood its name Mylapore. The temple was rebuilt in the 16th century by the Vijayanagara kings.',
    location: 'Kapaleeshwarar Sannadhi St, Mylapore, Chennai, Tamil Nadu 600004',
    timings: '5:30 AM – 12:00 PM, 4:00 PM – 9:30 PM',
    latitude: 13.0339,
    longitude: 80.2695,
    specialities: [
      'Arubathu Moovar festival',
      'Panguni Peruvizha (10-day event)',
      'Sacred peacock mythology',
      'Mylapore cultural hub setting',
    ],
  ),
  Temple(
    name: 'Ramanathaswamy Temple',
    state: 'Tamil Nadu',
    city: 'Rameswaram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ramanathaswamy/800/600',
    description:
        'One of the Char Dham pilgrimage sites and home to the longest corridor of any Hindu temple in India, this Jyotirlinga shrine on Pamban island is where Lord Rama worshipped Shiva before crossing to Lanka.',
    story:
        'After defeating Ravana, Rama wished to atone for killing a Brahmin (Ravana) and asked Hanuman to bring a Shiva lingam from Kailash. When Hanuman was delayed, Sita fashioned a lingam from sand, which is worshipped to this day.',
    location: 'Rameswaram, Ramanathapuram, Tamil Nadu 623526',
    timings: '5:00 AM – 1:00 PM, 3:00 PM – 9:00 PM',
    latitude: 9.2882,
    longitude: 79.3174,
    specialities: [
      'Longest temple corridor in India (1220m)',
      '22 sacred theerthams (wells)',
      'Char Dham & Jyotirlinga site',
      'Pamban Bridge approach',
    ],
  ),
  Temple(
    name: 'Murugan Temple, Thirupparankundram',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Murugan',
    imageUrl: 'https://picsum.photos/seed/thirupparankundram/800/600',
    description:
        'One of the Arupadai Veedu (six abodes of Lord Murugan), this rock-cut cave temple carved into a hillside is believed to be where Murugan married Devasena after slaying the demon Surapadman.',
    story:
        'After his victory over Surapadman, Lord Murugan married Devasena at this very hill. The divine wedding is re-enacted annually during the Panguni Uthiram festival drawing lakhs of devotees.',
    location: 'Thirupparankundram, Madurai, Tamil Nadu 625005',
    timings: '5:30 AM – 1:00 PM, 4:00 PM – 9:30 PM',
    latitude: 9.8833,
    longitude: 78.0694,
    specialities: [
      'Arupadai Veedu (first abode)',
      'Rock-cut cave architecture',
      'Panguni Uthiram wedding festival',
      'Jain carvings on hilltop',
    ],
  ),
  Temple(
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/shoretemple/800/600',
    description:
        'A UNESCO World Heritage structural temple built by Pallava king Narasimhavarman II in the 8th century, overlooking the Bay of Bengal with twin shrines to Shiva and one to Vishnu.',
    story:
        'Local legend speaks of Seven Pagodas — a series of grand temples along the coast, six of which were swallowed by the sea. The 2004 tsunami briefly receded to reveal submerged ruins offshore, lending credence to the myth.',
    location: 'Mahabalipuram, Chengalpattu, Tamil Nadu 603104',
    timings: '6:00 AM – 6:00 PM (ASI monument)',
    latitude: 12.6169,
    longitude: 80.1991,
    specialities: [
      'UNESCO World Heritage Site',
      'Pallava stone architecture',
      'Seaside granite setting',
      'Seven Pagodas legend',
    ],
  ),
  Temple(
    name: 'Nataraja Temple',
    state: 'Tamil Nadu',
    city: 'Chidambaram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/nataraja/800/600',
    description:
        'The only temple where Lord Shiva is worshipped in his Nataraja (cosmic dancer) form. The sanctum houses the Chidambara Rahasyam — a curtain symbolising the formless nature of the divine.',
    story:
        'The temple enshrines the Akasha Lingam, representing the element of space (Akasha). Behind the golden curtain in the sanctum lies empty space decorated with golden bilva leaves — the Chidambara Rahasyam, the secret of consciousness.',
    location: 'Car Street, Chidambaram, Cuddalore, Tamil Nadu 608001',
    timings: '6:00 AM – 12:00 PM, 4:30 PM – 10:00 PM',
    latitude: 11.3994,
    longitude: 79.6937,
    specialities: [
      'Chidambara Rahasyam (cosmic secret)',
      'Pancha Bootha Sthalam (Space)',
      'Natyanjali dance festival',
      'Four gopurams with 108 Bharatanatyam poses',
    ],
  ),
  Temple(
    name: 'Ekambaranathar Temple',
    state: 'Tamil Nadu',
    city: 'Kanchipuram',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/ekambaranathar/800/600',
    description:
        'One of the Pancha Bootha Sthalams representing Earth, this massive temple complex in Kanchipuram spans 25 acres and features a 59-metre rajagopuram and a 3500-year-old mango tree.',
    story:
        'Parvati is said to have worshipped a lingam made of sand under a mango tree here. Shiva tested her devotion by sending fire and floods, but she held the lingam close, and Shiva appeared, granting her wish. The ancient mango tree with four branches representing four Vedas still stands.',
    location: 'Ekambaranathar Koil St, Kanchipuram, Tamil Nadu 631502',
    timings: '6:00 AM – 12:30 PM, 4:00 PM – 8:30 PM',
    latitude: 12.8489,
    longitude: 79.7005,
    specialities: [
      'Pancha Bootha Sthalam (Earth)',
      '3500-year-old mango tree',
      '59-metre tall rajagopuram',
      'Pallava & Chola architectural heritage',
    ],
  ),
  Temple(
    name: 'Arunachaleswarar Temple',
    state: 'Tamil Nadu',
    city: 'Tiruvannamalai',
    deity: 'Shiva',
    imageUrl: 'https://picsum.photos/seed/arunachaleswarar/800/600',
    description:
        'One of the Pancha Bootha Sthalams representing Fire, this ancient temple at the foot of Arunachala hill is where the Karthigai Deepam — a massive flame lit on the hilltop — is visible for miles.',
    story:
        'Shiva manifested as an infinite column of fire (Jyotirlinga) to settle a dispute between Brahma and Vishnu about who was supreme. Neither could find its beginning or end, proving Shiva\'s supremacy. The Karthigai Deepam flame re-enacts this cosmic pillar of fire.',
    location: 'Tiruvannamalai, Tamil Nadu 606601',
    timings: '5:30 AM – 12:30 PM, 3:30 PM – 9:30 PM',
    latitude: 12.2310,
    longitude: 79.0677,
    specialities: [
      'Pancha Bootha Sthalam (Fire)',
      'Karthigai Deepam hilltop flame',
      'Girivalam (14 km hill circumambulation)',
      'Ramana Maharshi ashram nearby',
    ],
  ),
  Temple(
    name: 'Sarangapani Temple',
    state: 'Tamil Nadu',
    city: 'Kumbakonam',
    deity: 'Vishnu',
    imageUrl: 'https://picsum.photos/seed/sarangapani/800/600',
    description:
        'The largest Vishnu temple in Kumbakonam and one of the 108 Divya Desams, featuring a chariot-shaped 11-tier gopuram and exquisite Chola-Nayak era sculptures.',
    story:
        'When a great deluge threatened creation, Vishnu placed the Vedas safely in a pot (Kumbha) and sent it floating. It landed here, giving the town its name Kumbakonam. Sarangapani is Vishnu as the bearer of the bow Saranga.',
    location: 'Sarangapani East Sannadhi St, Kumbakonam, Tamil Nadu 612001',
    timings: '6:00 AM – 12:00 PM, 4:00 PM – 9:00 PM',
    latitude: 10.9617,
    longitude: 79.3881,
    specialities: [
      '108 Divya Desam site',
      'Chariot-shaped gopuram',
      'Mahamaham tank (holy dip every 12 years)',
      'Chola-Nayak sculptural art',
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
