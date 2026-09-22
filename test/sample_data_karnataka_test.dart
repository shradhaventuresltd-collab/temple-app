import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  final karnataka = sampleTemples.where((t) => t.state == 'Karnataka').toList();

  const originalExpected = <String, String>{
    'sri-krishna-matha-udupi': 'Sri Krishna Matha (Udupi)',
    'sri-manjunatha-temple-dharmasthala': 'Sri Manjunatha Temple, Dharmasthala',
    'kukke-subramanya-temple': 'Kukke Subramanya Temple',
    'sringeri-sharada-peetham': 'Sringeri Sharada Peetham',
    'kollur-mookambika-temple': 'Kollur Mookambika Temple',
    'mahabaleshwar-temple-gokarna': 'Mahabaleshwar Temple, Gokarna',
    'chamundeshwari-temple': 'Chamundeshwari Temple',
    'virupaksha-temple': 'Virupaksha Temple',
    'srikanteshwara-temple-nanjangud': 'Srikanteshwara Temple, Nanjangud',
    'iskcon-temple-bangalore': 'ISKCON Temple, Bangalore',
  };

  const originalMeta = <String, ({String city, String deity})>{
    'sri-krishna-matha-udupi': (city: 'Udupi', deity: 'Vishnu'),
    'sri-manjunatha-temple-dharmasthala': (
      city: 'Dharmasthala',
      deity: 'Shiva',
    ),
    'kukke-subramanya-temple': (city: 'Sullia', deity: 'Murugan'),
    'sringeri-sharada-peetham': (city: 'Sringeri', deity: 'Devi'),
    'kollur-mookambika-temple': (city: 'Kollur', deity: 'Devi'),
    'mahabaleshwar-temple-gokarna': (city: 'Gokarna', deity: 'Shiva'),
    'chamundeshwari-temple': (city: 'Mysuru', deity: 'Devi'),
    'virupaksha-temple': (city: 'Hampi', deity: 'Shiva'),
    'srikanteshwara-temple-nanjangud': (city: 'Nanjangud', deity: 'Shiva'),
    'iskcon-temple-bangalore': (city: 'Bengaluru', deity: 'Vishnu'),
  };

  test('Karnataka sample keeps original ten and totals twenty', () {
    expect(sampleTemples.length, 180);
    expect(karnataka.length, 20);

    final slugs = karnataka.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(
      slugs.toSet().intersection(originalExpected.keys.toSet()),
      originalExpected.keys.toSet(),
    );

    for (final temple in karnataka.where(
      (t) => originalExpected.containsKey(templeDocumentId(t.name)),
    )) {
      final slug = templeDocumentId(temple.name);
      expect(temple.name, originalExpected[slug]);
      expect(temple.city, originalMeta[slug]!.city);
      expect(temple.deity, originalMeta[slug]!.deity);
    }
  });

  test(
    'Karnataka sample temples parse visitor fields without dropping covers',
    () {
      for (final temple in karnataka) {
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
        expect(temple.latitude, inInclusiveRange(11.5, 16.0));
        expect(temple.longitude, inInclusiveRange(74.0, 78.0));
        // Bengaluru Banashankari is Photo pending until Research resends a pack.
        if (temple.name == 'Banashankari Temple, Bengaluru') {
          expect(temple.imageUrl, isEmpty);
          expect(temple.images, isEmpty);
          continue;
        }
        // KAN-77 Wave B: Commons downloaded_url thumbs, not picsum or Storage.
        expect(temple.imageUrl.contains('picsum'), isFalse);
        expect(temple.imageUrl, contains('wikimedia.org'));
        expect(temple.imageUrl.contains('firebasestorage'), isFalse);
        expect(temple.imageUrl.contains('storage.googleapis.com'), isFalse);
        expect(temple.images, isNotEmpty);
        expect(temple.imageUrl, temple.images.first);
        for (final url in temple.images) {
          expect(url, contains('wikimedia.org'));
          expect(url.contains('picsum'), isFalse);
        }
      }
    },
  );

  test('reviewer wrong-site frames are not in Karnataka sample galleries', () {
    Temple named(String name) => karnataka.firstWhere((t) => t.name == name);

    final banashankari = named('Banashankari Temple, Bengaluru');
    expect(banashankari.imageUrl, isEmpty);
    expect(banashankari.images, isEmpty);

    final talakaveri = named('Talakaveri Temple');
    final talakaveriUrls = talakaveri.images.join(' ');
    expect(talakaveri.images, hasLength(4));
    expect(talakaveri.imageUrl, talakaveri.images.first);
    for (final banned in [
      'Brihadeeswara',
      'Srirangam',
      'Ranganathaswamy',
      'Thalakkaveri_Temple',
    ]) {
      expect(talakaveriUrls.contains(banned), isFalse, reason: banned);
    }

    final gokarna = named('Mahabaleshwar Temple, Gokarna');
    final gokarnaUrls = gokarna.images.join(' ');
    expect(gokarna.images, hasLength(5));
    expect(gokarna.imageUrl, gokarna.images.first);
    for (final banned in [
      'Kathmandu',
      'Gokarneshwor',
      'Mahabaleshwar_temple_at_Gokaran',
      'panoramio',
    ]) {
      expect(gokarnaUrls.contains(banned), isFalse, reason: banned);
    }
  });

  test('uncertain Karnataka timings keep source caveats', () {
    Temple named(String name) => karnataka.firstWhere((t) => t.name == name);

    expect(named('Sri Krishna Matha (Udupi)').timings, contains('Paryaya'));
    expect(
      named('Mahabaleshwar Temple, Gokarna').timings.toLowerCase(),
      contains('confirm on site'),
    );
    expect(
      named('Virupaksha Temple').timings.toLowerCase(),
      contains('confirm locally'),
    );
    expect(named('Kukke Subramanya Temple').timings, contains('HRCE'));
    expect(
      named('Sri Manjunatha Temple, Dharmasthala').timings,
      contains('shridharmasthala.org'),
    );
    expect(named('Srikanteshwara Temple, Nanjangud').timings, contains('HRCE'));
    expect(
      named('ISKCON Temple, Bangalore').specialities.join(' '),
      contains('Kanakapura Road'),
    );
  });

  test(
    'Karnataka sample round-trips through Seed/CMS Firestore field names',
    () {
      for (final temple in karnataka) {
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
        expect(parsed.images, temple.images);
      }
    },
  );
}
