import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

/// KAN-74 / KAN-64 Hybrid C: +30 additional TN/KL/KA temples (batches 16–18).
void main() {
  test('bundled sample is 180 temples after South India expansion', () {
    expect(sampleTemples.length, 180);
    final slugs = sampleTemples.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet().length, slugs.length);
  });

  test('Tamil Nadu batch-16 expansion adds ten temples with empty covers', () {
    final rows = sampleTemples.where((t) => t.state == 'Tamil Nadu').toList();
    expect(rows, hasLength(20));

    const expected = <String, String>{
      'sri-ranganathaswamy-temple': 'Sri Ranganathaswamy Temple',
      'dhandayuthapani-swamy-temple': 'Dhandayuthapani Swamy Temple',
      'subramanya-swamy-temple': 'Subramanya Swamy Temple',
      'swamimalai-murugan-temple': 'Swamimalai Murugan Temple',
      'jambukeswarar-temple': 'Jambukeswarar Temple',
      'thyagaraja-temple': 'Thyagaraja Temple',
      'nellaiappar-temple': 'Nellaiappar Temple',
      'kanyakumari-bhagavathi-amman-temple':
          'Kanyakumari Bhagavathi Amman Temple',
      'vaitheeswaran-koil': 'Vaitheeswaran Koil',
      'tiruttani-murugan-temple': 'Tiruttani Murugan Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'sri-ranganathaswamy-temple': (city: 'Srirangam', deity: 'Vishnu'),
      'dhandayuthapani-swamy-temple': (city: 'Palani', deity: 'Murugan'),
      'subramanya-swamy-temple': (city: 'Thiruchendur', deity: 'Murugan'),
      'swamimalai-murugan-temple': (city: 'Swamimalai', deity: 'Murugan'),
      'jambukeswarar-temple': (city: 'Thiruvanaikaval', deity: 'Shiva'),
      'thyagaraja-temple': (city: 'Tiruvarur', deity: 'Shiva'),
      'nellaiappar-temple': (city: 'Tirunelveli', deity: 'Shiva'),
      'kanyakumari-bhagavathi-amman-temple': (
        city: 'Kanyakumari',
        deity: 'Devi',
      ),
      'vaitheeswaran-koil': (city: 'Vaitheeswaran Koil', deity: 'Shiva'),
      'tiruttani-murugan-temple': (city: 'Tiruttani', deity: 'Murugan'),
    };

    final added = rows
        .where((t) => expected.containsKey(templeDocumentId(t.name)))
        .toList();
    expect(added, hasLength(10));
    _assertExpansionRows(
      added,
      expected: expected,
      expectedMeta: expectedMeta,
      latRange: (8.0, 14.0),
      lngRange: (76.0, 81.0),
    );
  });

  test('Kerala batch-17 expansion adds ten temples with empty covers', () {
    final rows = sampleTemples.where((t) => t.state == 'Kerala').toList();
    expect(rows, hasLength(20));

    const expected = <String, String>{
      'vadakkunnathan-temple': 'Vadakkunnathan Temple',
      'sree-poornathrayeesa-temple': 'Sree Poornathrayeesa Temple',
      'ambalappuzha-sri-krishna-temple': 'Ambalappuzha Sri Krishna Temple',
      'ettumanoor-mahadeva-temple': 'Ettumanoor Mahadeva Temple',
      'chettikulangara-devi-temple': 'Chettikulangara Devi Temple',
      'kodungallur-bhagavathy-temple': 'Kodungallur Bhagavathy Temple',
      'parassinikadavu-muthappan-temple': 'Parassinikadavu Muthappan Temple',
      'thiruvalla-sreevallabha-temple': 'Thiruvalla Sreevallabha Temple',
      'chengannur-mahadeva-temple': 'Chengannur Mahadeva Temple',
      'kaviyoor-mahadeva-temple': 'Kaviyoor Mahadeva Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'vadakkunnathan-temple': (city: 'Thrissur', deity: 'Shiva'),
      'sree-poornathrayeesa-temple': (city: 'Tripunithura', deity: 'Vishnu'),
      'ambalappuzha-sri-krishna-temple': (
        city: 'Ambalappuzha',
        deity: 'Vishnu',
      ),
      'ettumanoor-mahadeva-temple': (city: 'Ettumanoor', deity: 'Shiva'),
      'chettikulangara-devi-temple': (city: 'Chettikulangara', deity: 'Devi'),
      'kodungallur-bhagavathy-temple': (city: 'Kodungallur', deity: 'Devi'),
      'parassinikadavu-muthappan-temple': (
        city: 'Parassinikadavu',
        deity: 'Muthappan',
      ),
      'thiruvalla-sreevallabha-temple': (city: 'Thiruvalla', deity: 'Vishnu'),
      'chengannur-mahadeva-temple': (city: 'Chengannur', deity: 'Shiva'),
      'kaviyoor-mahadeva-temple': (city: 'Kaviyoor', deity: 'Shiva'),
    };

    final added = rows
        .where((t) => expected.containsKey(templeDocumentId(t.name)))
        .toList();
    expect(added, hasLength(10));
    _assertExpansionRows(
      added,
      expected: expected,
      expectedMeta: expectedMeta,
      latRange: (8.0, 12.5),
      lngRange: (74.5, 78.0),
    );
  });

  test('Karnataka batch-18 expansion adds ten temples with empty covers', () {
    final rows = sampleTemples.where((t) => t.state == 'Karnataka').toList();
    expect(rows, hasLength(20));

    const expected = <String, String>{
      'cheluvanarayana-swamy-temple': 'Cheluvanarayana Swamy Temple',
      'murudeshwar-temple': 'Murudeshwar Temple',
      'annapoorneshwari-temple-horanadu': 'Annapoorneshwari Temple, Horanadu',
      'kateel-durga-parameshwari-temple': 'Kateel Durga Parameshwari Temple',
      'ghati-subramanya-temple': 'Ghati Subramanya Temple',
      'banashankari-temple-bengaluru': 'Banashankari Temple, Bengaluru',
      'chennakeshava-temple-belur': 'Chennakeshava Temple, Belur',
      'hoysaleswara-temple-halebidu': 'Hoysaleswara Temple, Halebidu',
      'anegudde-vinayaka-temple': 'Anegudde Vinayaka Temple',
      'talakaveri-temple': 'Talakaveri Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'cheluvanarayana-swamy-temple': (city: 'Melukote', deity: 'Vishnu'),
      'murudeshwar-temple': (city: 'Murudeshwar', deity: 'Shiva'),
      'annapoorneshwari-temple-horanadu': (city: 'Horanadu', deity: 'Devi'),
      'kateel-durga-parameshwari-temple': (city: 'Kateel', deity: 'Devi'),
      'ghati-subramanya-temple': (city: 'Doddaballapur', deity: 'Murugan'),
      'banashankari-temple-bengaluru': (city: 'Bengaluru', deity: 'Devi'),
      'chennakeshava-temple-belur': (city: 'Belur', deity: 'Vishnu'),
      'hoysaleswara-temple-halebidu': (city: 'Halebidu', deity: 'Shiva'),
      'anegudde-vinayaka-temple': (city: 'Kumbhashi', deity: 'Ganesha'),
      'talakaveri-temple': (city: 'Bhagamandala', deity: 'Devi'),
    };

    final added = rows
        .where((t) => expected.containsKey(templeDocumentId(t.name)))
        .toList();
    expect(added, hasLength(10));
    _assertExpansionRows(
      added,
      expected: expected,
      expectedMeta: expectedMeta,
      latRange: (11.5, 16.0),
      lngRange: (74.0, 78.0),
    );
  });

  test('South India expansion keeps Hybrid C honesty caveats', () {
    Temple named(String name) =>
        sampleTemples.firstWhere((t) => t.name == name);

    final halebidu = named('Hoysaleswara Temple, Halebidu');
    expect(halebidu.timings.toLowerCase(), contains('symbolic'));
    expect(halebidu.timings.toLowerCase(), contains('unesco'));
    expect(halebidu.timings.toLowerCase(), contains('aarti'));
    expect(halebidu.story.toLowerCase(), contains('belur'));
    expect(halebidu.imageUrl, isEmpty);

    final belur = named('Chennakeshava Temple, Belur');
    expect(belur.timings.toLowerCase(), contains('living'));
    expect(belur.story.toLowerCase(), contains('living'));
    expect(belur.imageUrl, isEmpty);

    final banashankari = named('Banashankari Temple, Bengaluru');
    expect(banashankari.city, 'Bengaluru');
    expect(banashankari.story.toLowerCase(), contains('badami'));
    expect(banashankari.imageUrl, isEmpty);

    final vaitheeswaran = named('Vaitheeswaran Koil');
    expect(vaitheeswaran.timings.toLowerCase(), contains('thin'));

    // Seed / CMS payload must not grow trip_planning or research-only keys.
    for (final temple in [
      halebidu,
      belur,
      banashankari,
      named('Sri Ranganathaswamy Temple'),
      named('Vadakkunnathan Temple'),
    ]) {
      final map = temple.toFirestoreData(
        documentId: templeDocumentId(temple.name),
      );
      expect(map.containsKey('trip_planning'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map['imageUrl'], '');
    }
  });
}

void _assertExpansionRows(
  List<Temple> rows, {
  required Map<String, String> expected,
  required Map<String, ({String city, String deity})> expectedMeta,
  required (double, double) latRange,
  required (double, double) lngRange,
}) {
  final slugs = rows.map((t) => templeDocumentId(t.name)).toList();
  expect(slugs.toSet(), expected.keys.toSet());
  expect(slugs.toSet().length, slugs.length);

  for (final temple in rows) {
    final id = templeDocumentId(temple.name);
    expect(temple.name, expected[id]);
    expect(temple.city, expectedMeta[id]!.city);
    expect(temple.deity, expectedMeta[id]!.deity);
    expect(temple.description.trim(), isNotEmpty);
    expect(temple.story.trim(), isNotEmpty);
    expect(temple.story.split('\n\n').length, greaterThanOrEqualTo(3));
    expect(temple.timings.trim(), isNotEmpty);
    expect(temple.timings.length, lessThanOrEqualTo(1000));
    expect(temple.location.trim(), isNotEmpty);
    expect(temple.location.length, lessThanOrEqualTo(500));
    expect(temple.specialities, isNotEmpty);
    expect(temple.specialities.length, lessThanOrEqualTo(20));
    for (final spec in temple.specialities) {
      expect(spec.length, lessThanOrEqualTo(200));
    }
    expect(temple.latitude, inInclusiveRange(latRange.$1, latRange.$2));
    expect(temple.longitude, inInclusiveRange(lngRange.$1, lngRange.$2));
    // Hybrid C honesty: no invented picsum / Storage covers for this wave.
    expect(temple.imageUrl, isEmpty);
    expect(temple.images, isEmpty);

    final map = temple.toFirestoreData(documentId: id);
    expect(map['id'], id);
    expect(map['address'], temple.location);
    expect(map.containsKey('location'), isFalse);
    expect(map.containsKey('trip_planning'), isFalse);
    expect(map.containsKey('photo_candidates'), isFalse);
    expect(map.containsKey('sources'), isFalse);
    expect(map.containsKey('rituals_notes'), isFalse);
    final parsed = Temple.fromMap(id, map);
    expect(parsed.name, temple.name);
    expect(parsed.state, temple.state);
    expect(parsed.location, temple.location);
    expect(parsed.imageUrl, isEmpty);
  }
}
