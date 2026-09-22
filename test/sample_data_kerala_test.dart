import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  final kerala = sampleTemples.where((t) => t.state == 'Kerala').toList();

  const originalExpected = <String, String>{
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

  const originalMeta = <String, ({String city, String deity})>{
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

  test('Kerala sample keeps original ten and totals twenty', () {
    expect(sampleTemples.length, 180);
    expect(kerala.length, 20);

    final slugs = kerala.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(
      slugs.toSet().intersection(originalExpected.keys.toSet()),
      originalExpected.keys.toSet(),
    );

    for (final temple in kerala.where(
      (t) => originalExpected.containsKey(templeDocumentId(t.name)),
    )) {
      final slug = templeDocumentId(temple.name);
      expect(temple.name, originalExpected[slug]);
      expect(temple.city, originalMeta[slug]!.city);
      expect(temple.deity, originalMeta[slug]!.deity);
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
        final slug = templeDocumentId(temple.name);
        const stillPicsum = {
          // KAN-77 shortfalls: no READY pack. Picsum stays; Seed still drops it.
          'anjengo-sree-durga-devi-temple',
          'mannarsala-sree-nagaraja-temple',
        };
        if (stillPicsum.contains(slug)) {
          expect(temple.images, isEmpty, reason: slug);
          expect(
            temple.imageUrl,
            startsWith('https://picsum.photos/seed/'),
            reason: slug,
          );
        } else {
          // KAN-77 Wave A: Commons downloaded_url thumbs until Storage upload.
          expect(temple.imageUrl.contains('picsum'), isFalse, reason: slug);
          expect(
            temple.imageUrl.contains('firebasestorage'),
            isFalse,
            reason: slug,
          );
          expect(temple.imageUrl, contains('wikimedia.org'), reason: slug);
          expect(temple.images.length, greaterThanOrEqualTo(5), reason: slug);
          expect(temple.imageUrl, temple.images.first, reason: slug);
          if (slug == 'sabarimala-ayyappan-temple') {
            expect(temple.imageUrl, contains('Sabarimala_5.jpg'));
            expect(temple.imageUrl, isNot(contains('/Sabarimala.jpg/')));
          }
          if (slug == 'thiruvalla-sreevallabha-temple') {
            expect(temple.imageUrl, contains('Sreevallabha_temple'));
            expect(temple.imageUrl, isNot(contains('Kadhakali')));
          }
          for (final url in temple.images) {
            expect(url, contains('wikimedia.org'), reason: slug);
            expect(url.contains('picsum'), isFalse, reason: slug);
          }
        }
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
