import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  final kerala = sampleTemples.where((t) => t.state == 'Kerala').toList();

  const expected = <String, String>{
    'guruvayur-sri-krishna-temple': 'Guruvayur Sri Krishna Temple',
    'sree-padmanabhaswamy-temple': 'Sree Padmanabhaswamy Temple',
    'sabarimala-ayyappan-temple': 'Sabarimala Ayyappan Temple',
    'attukal-bhagavathy-temple': 'Attukal Bhagavathy Temple',
    'chottanikkara-bhagavathy-temple': 'Chottanikkara Bhagavathy Temple',
    'ernakulathappan-temple': 'Ernakulathappan Temple',
    'vaikom-mahadeva-temple': 'Vaikom Mahadeva Temple',
    'anjengo-sree-durga-devi-temple': 'Anjengo Sree Durga Devi Temple',
    'mannarsala-sree-nagaraja-temple': 'Mannarsala Sree Nagaraja Temple',
    'thirunelli-maha-vishnu-temple': 'Thirunelli Maha Vishnu Temple',
  };

  const expectedMeta = <String, ({String city, String deity})>{
    'guruvayur-sri-krishna-temple': (city: 'Guruvayur', deity: 'Vishnu'),
    'sree-padmanabhaswamy-temple': (
      city: 'Thiruvananthapuram',
      deity: 'Vishnu',
    ),
    'sabarimala-ayyappan-temple': (city: 'Pathanamthitta', deity: 'Vishnu'),
    'attukal-bhagavathy-temple': (city: 'Thiruvananthapuram', deity: 'Devi'),
    'chottanikkara-bhagavathy-temple': (city: 'Ernakulam', deity: 'Devi'),
    'ernakulathappan-temple': (city: 'Ernakulam', deity: 'Shiva'),
    'vaikom-mahadeva-temple': (city: 'Kottayam', deity: 'Shiva'),
    'anjengo-sree-durga-devi-temple': (
      city: 'Thiruvananthapuram',
      deity: 'Devi',
    ),
    'mannarsala-sree-nagaraja-temple': (city: 'Alappuzha', deity: 'Vishnu'),
    'thirunelli-maha-vishnu-temple': (city: 'Wayanad', deity: 'Vishnu'),
  };

  test('Kerala sample remains ten distinct seeded temples', () {
    expect(sampleTemples.length, 30);
    expect(kerala.length, 10);

    final slugs = kerala.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet(), expected.keys.toSet());
    expect(slugs.toSet().length, slugs.length);

    for (final temple in kerala) {
      final slug = templeDocumentId(temple.name);
      expect(temple.name, expected[slug]);
      expect(temple.city, expectedMeta[slug]!.city);
      expect(temple.deity, expectedMeta[slug]!.deity);
    }
  });

  test(
    'Kerala sample temples parse visitor fields without dropping covers',
    () {
      for (final temple in kerala) {
        expect(temple.description.trim(), isNotEmpty);
        expect(temple.story.trim(), isNotEmpty);
        expect(temple.story.split('\n\n').length, greaterThanOrEqualTo(3));
        expect(temple.timings.trim(), isNotEmpty);
        expect(temple.timings.length, lessThanOrEqualTo(1000));
        expect(temple.location.trim(), isNotEmpty);
        expect(temple.specialities, isNotEmpty);
        expect(temple.specialities.length, lessThanOrEqualTo(20));
        for (final spec in temple.specialities) {
          expect(spec.length, lessThanOrEqualTo(200));
        }
        expect(temple.latitude, inInclusiveRange(8.0, 12.5));
        expect(temple.longitude, inInclusiveRange(74.5, 78.0));
        expect(temple.imageUrl, startsWith('https://picsum.photos/seed/'));
        expect(temple.images, isEmpty);
      }
    },
  );

  test(
    'Kerala timings prefer official clocks over conflicting sample envelopes',
    () {
      Temple named(String name) => kerala.firstWhere((t) => t.name == name);

      expect(
        named('Guruvayur Sri Krishna Temple').timings,
        contains('Devaswom'),
      );
      expect(named('Sree Padmanabhaswamy Temple').timings, contains('SPST'));
      expect(
        named('Sabarimala Ayyappan Temple').timings.toLowerCase(),
        contains('seasonal'),
      );
      expect(
        named('Chottanikkara Bhagavathy Temple').timings,
        contains('Valiya Guruthi'),
      );
      expect(
        named('Mannarsala Sree Nagaraja Temple').timings,
        contains('mannarasala.org'),
      );
      expect(
        named('Thirunelli Maha Vishnu Temple').timings,
        contains('Kerala Tourism'),
      );
      expect(
        named('Anjengo Sree Durga Devi Temple').timings.toLowerCase(),
        contains('not independently verified'),
      );
    },
  );

  test('Kerala sample round-trips through Seed/CMS Firestore field names', () {
    for (final temple in kerala) {
      final docId = templeDocumentId(temple.name);
      final map = temple.toFirestoreData(documentId: docId);
      expect(map['id'], docId);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);

      final parsed = Temple.fromMap(docId, map);
      expect(parsed.name, temple.name);
      expect(parsed.location, temple.location);
      expect(parsed.description, temple.description);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.latitude, temple.latitude);
      expect(parsed.longitude, temple.longitude);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });
}
