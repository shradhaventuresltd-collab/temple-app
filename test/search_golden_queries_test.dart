import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/temple_search.dart';

/// Expected first result for queries a tester actually types, including typos.
const Map<String, String> goldenTopResults = {
  'guruvayur': 'Guruvayur Sri Krishna Temple',
  'guruvayoor': 'Guruvayur Sri Krishna Temple',
  'guruvayoorappan': 'Guruvayur Sri Krishna Temple',
  'tirupathi': 'Tirumala Venkateswara Temple',
  'tirupati': 'Tirumala Venkateswara Temple',
  'tirumala': 'Tirumala Venkateswara Temple',
  'tirup': 'Tirumala Venkateswara Temple',
  'tirupti': 'Tirumala Venkateswara Temple',
  'madurai meenakshi': 'Meenakshi Amman Temple',
  'minakshi': 'Meenakshi Amman Temple',
  'meenakshi': 'Meenakshi Amman Temple',
  'meenakshy': 'Meenakshi Amman Temple',
  'kanyakumari': 'Kanyakumari Bhagavathi Amman Temple',
  'kanyakumar': 'Kanyakumari Bhagavathi Amman Temple',
  'madurai': 'Meenakshi Amman Temple',
  'maduari': 'Meenakshi Amman Temple',
  'thanjavur': 'Brihadeeswarar Temple',
  'tiruchendur': 'Subramanya Swamy Temple',
  'thiruchendur': 'Subramanya Swamy Temple',
  'sabarimala': 'Sabarimala Ayyappan Temple',
  'ayyappa': 'Sabarimala Ayyappan Temple',
  'sastha': 'Sabarimala Ayyappan Temple',
  'somnath': 'Somnath Temple',
  'samnath': 'Somnath Temple',
  'kashi': 'Kashi Vishwanath Temple',
  'kasi': 'Kashi Vishwanath Temple',
  'shiva': 'Brihadeeswarar Temple',
  'sivan': 'Brihadeeswarar Temple',
  'shiv': 'Brihadeeswarar Temple',
  'mahadev': 'Brihadeeswarar Temple',
  'venkateswara': 'Tirumala Venkateswara Temple',
  'venkateshwara': 'Tirumala Venkateswara Temple',
  'balaji': 'Chilkur Balaji Temple',
  'srirangam': 'Sri Ranganathaswamy Temple',
  'ranganatha': 'Sri Ranganathaswamy Temple',
  'padmanabha': 'Sree Padmanabhaswamy Temple',
  'vishnu': 'Thirunelli Maha Vishnu Temple',
  'krishna': 'Guruvayur Sri Krishna Temple',
  'kannan': 'Guruvayur Sri Krishna Temple',
  'murugan': 'Murugan Temple, Thirupparankundram',
  'subramanya': 'Subramanya Swamy Temple',
  'kartikeya': 'Murugan Temple, Thirupparankundram',
  'ganesha': 'Chintaman Ganesh Temple',
  'vinayaka': 'Anegudde Vinayaka Temple',
  'hanuman': 'Sankat Mochan Hanuman Temple',
  'anjaneya': 'Sankat Mochan Hanuman Temple',
  'durga': 'Anjengo Sree Durga Devi Temple',
  'kali': 'Kalighat Kali Temple',
  'devi': 'Anjengo Sree Durga Devi Temple',
  'lakshmi': 'Varaha Lakshmi Narasimha Temple',
  'jagannath': 'Jagannath Temple',
  'vitthal': 'Vitthal Rukmini Temple',
  'nataraja': 'Nataraja Temple',
  'udupi': 'Sri Krishna Matha (Udupi)',
  'varanasi': 'Kashi Vishwanath Temple',
  'vaikom': 'Vaikom Mahadeva Temple',
  'amarnath': 'Amarnath Cave Temple',
  'konark': 'Konark Sun Temple',
  'siddhivinayak': 'Siddhivinayak Temple',
  'brihadishwar': 'Brihadeeswarar Temple',
  'dwarka': 'Dwarkadhish Temple',
};

void main() {
  test('golden queries name the expected top temple', () {
    expect(goldenTopResults.length, greaterThanOrEqualTo(40));
    final mismatches = <String>[];
    for (final entry in goldenTopResults.entries) {
      final found = filterTemples(sampleTemples, query: entry.key);
      final actual = found.isEmpty ? '(none)' : found.first.name;
      if (actual != entry.value) {
        mismatches.add('${entry.key} → $actual (expected ${entry.value})');
      }
    }
    expect(mismatches, isEmpty);
  });

  test('negative queries reject mid-word deity hits', () {
    final sivakasi = _temple(
      name: 'Sivakasi Temple',
      city: 'Sivakasi',
      deity: 'Murugan',
    );
    final kalina = _temple(
      name: 'Kalina Temple',
      city: 'Kalina',
      deity: 'Ganesha',
    );
    final ramanathapuram = _temple(
      name: 'Coast Temple',
      city: 'Ramanathapuram',
      deity: 'Shiva',
    );
    final kumaraswamy = _temple(name: 'Kumaraswamy Temple', deity: 'Murugan');
    final maathru = _temple(name: 'Maathru Hall', deity: 'Shiva');
    final lingaraj = _temple(name: 'Lingaraj Temple', deity: 'Surya');
    final krishna = _temple(name: 'Krishna Shrine', deity: 'Krishna');
    final balaji = _temple(name: 'Balaji Shrine', deity: 'Venkateswara');
    final perumal = _temple(name: 'Perumal Koil', deity: 'Perumal');

    final kasi = filterTemples([sivakasi, ...sampleTemples], query: 'kasi');
    expect(kasi.map((t) => t.name), isNot(contains('Sivakasi Temple')));
    expect(kasi.first.name, 'Kashi Vishwanath Temple');
    expect(kasi.map((t) => t.city), contains('Varanasi'));

    expect(filterTemples([sivakasi], query: 'siva'), isEmpty);
    expect(filterTemples([sivakasi], query: 'shiva'), isEmpty);
    expect(filterTemples([kalina], query: 'kali'), isEmpty);
    expect(filterTemples([ramanathapuram], query: 'rama'), isEmpty);
    expect(
      filterTemples(sampleTemples, query: 'rama').map((t) => t.name),
      isNot(contains('Ramanathaswamy Temple')),
    );
    expect(filterTemples([kumaraswamy], query: 'uma'), isEmpty);
    expect(filterTemples([maathru], query: 'maa'), isEmpty);
    expect(filterTemples([lingaraj], query: 'linga'), isEmpty);

    expect(
      filterTemples([
        perumal,
        krishna,
        balaji,
      ], query: 'govinda').map((t) => t.name),
      ['Krishna Shrine', 'Balaji Shrine'],
    );
  });
}

Temple _temple({
  required String name,
  String deity = 'Devi',
  String city = 'Madurai',
}) {
  return Temple(
    name: name,
    state: 'Tamil Nadu',
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: '',
    location: 'Temple Street',
    timings: '',
    specialities: const [],
    latitude: 0,
    longitude: 0,
  );
}
