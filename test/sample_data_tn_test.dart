import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  final tamilNadu = sampleTemples
      .where((t) => t.state == 'Tamil Nadu')
      .toList();

  const originalExpected = <String, String>{
    'meenakshi-amman-temple': 'Meenakshi Amman Temple',
    'brihadeeswarar-temple': 'Brihadeeswarar Temple',
    'kapaleeshwarar-temple': 'Kapaleeshwarar Temple',
    'ramanathaswamy-temple': 'Ramanathaswamy Temple',
    'murugan-temple-thirupparankundram':
        'Murugan Temple, Thirupparankundram',
    'shore-temple': 'Shore Temple',
    'nataraja-temple': 'Nataraja Temple',
    'ekambaranathar-temple': 'Ekambaranathar Temple',
    'arunachaleswarar-temple': 'Arunachaleswarar Temple',
    'sarangapani-temple': 'Sarangapani Temple',
  };

  const originalMeta = <String, ({String city, String deity})>{
    'meenakshi-amman-temple': (city: 'Madurai', deity: 'Devi'),
    'brihadeeswarar-temple': (city: 'Thanjavur', deity: 'Shiva'),
    'kapaleeshwarar-temple': (city: 'Chennai', deity: 'Shiva'),
    'ramanathaswamy-temple': (city: 'Rameswaram', deity: 'Shiva'),
    'murugan-temple-thirupparankundram': (
      city: 'Madurai',
      deity: 'Murugan',
    ),
    'shore-temple': (city: 'Mahabalipuram', deity: 'Shiva'),
    'nataraja-temple': (city: 'Chidambaram', deity: 'Shiva'),
    'ekambaranathar-temple': (city: 'Kanchipuram', deity: 'Shiva'),
    'arunachaleswarar-temple': (city: 'Tiruvannamalai', deity: 'Shiva'),
    'sarangapani-temple': (city: 'Kumbakonam', deity: 'Vishnu'),
  };

  test('Tamil Nadu sample keeps original ten and totals twenty', () {
    expect(sampleTemples.length, 180);
    expect(tamilNadu.length, 20);

    final slugs = tamilNadu.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(
      slugs.toSet().intersection(originalExpected.keys.toSet()),
      originalExpected.keys.toSet(),
    );

    for (final temple in tamilNadu.where(
      (t) => originalExpected.containsKey(templeDocumentId(t.name)),
    )) {
      final slug = templeDocumentId(temple.name);
      expect(temple.name, originalExpected[slug]);
      expect(temple.city, originalMeta[slug]!.city);
      expect(temple.deity, originalMeta[slug]!.deity);
    }
  });

  test('TN sample temples parse visitor fields without dropping covers', () {
    for (final temple in tamilNadu) {
      expect(temple.description.trim(), isNotEmpty);
      expect(temple.story.trim(), isNotEmpty);
      expect(temple.story.split('\n\n').length, greaterThanOrEqualTo(3));
      expect(temple.timings.trim(), isNotEmpty);
      expect(temple.location.trim(), isNotEmpty);
      expect(temple.specialities, isNotEmpty);
      expect(temple.latitude, inInclusiveRange(8.0, 14.0));
      expect(temple.longitude, inInclusiveRange(76.0, 81.0));
      final slug = templeDocumentId(temple.name);
      if (slug == 'meenakshi-amman-temple' || slug == 'shore-temple') {
        // KAN-77: verified Commons thumbs until Storage upload.
        expect(temple.imageUrl.contains('picsum'), isFalse);
        expect(temple.imageUrl, contains('upload.wikimedia.org'));
        expect(temple.images, hasLength(6));
        expect(temple.imageUrl, temple.images.first);
      } else if (originalExpected.containsKey(slug)) {
        expect(temple.images, isEmpty);
        expect(
          temple.imageUrl,
          startsWith('https://picsum.photos/seed/'),
        );
      } else {
        // KAN-74 Hybrid C: expansion temples keep empty covers.
        expect(temple.images, isEmpty);
        expect(temple.imageUrl, isEmpty);
      }
    }
  });

  test('uncertain TN timings keep source caveats', () {
    Temple named(String name) =>
        tamilNadu.firstWhere((t) => t.name == name);

    expect(named('Shore Temple').timings, contains('ASI'));
    expect(
      named('Shore Temple').timings.toLowerCase(),
      contains('heritage'),
    );
    expect(
      named('Arunachaleswarar Temple').timings,
      contains('VERIFY'),
    );
    expect(
      named('Brihadeeswarar Temple').timings.toLowerCase(),
      contains('confirm'),
    );
    expect(
      named('Ekambaranathar Temple').timings.toLowerCase(),
      contains('confirm'),
    );
    expect(
      named('Ekambaranathar Temple').timings.toLowerCase(),
      contains('ritual'),
    );
  });

  test('TN sample round-trips through Seed/CMS Firestore field names', () {
    for (final temple in tamilNadu) {
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
