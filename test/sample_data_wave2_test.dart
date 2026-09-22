import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  test('Maharashtra expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Maharashtra').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'shree-saibaba-samadhi-mandir': 'Shree Saibaba Samadhi Mandir',
      'siddhivinayak-temple': 'Siddhivinayak Temple',
      'trimbakeshwar-temple': 'Trimbakeshwar Temple',
      'bhimashankar-temple': 'Bhimashankar Temple',
      'grishneshwar-temple': 'Grishneshwar Temple',
      'vitthal-rukmini-temple': 'Vitthal Rukmini Temple',
      'mumba-devi-temple': 'Mumba Devi Temple',
      'mahalakshmi-temple': 'Mahalakshmi Temple',
      'jejuri-khandoba-temple': 'Jejuri Khandoba Temple',
      'morgaon-mayureshwar-temple': 'Morgaon Mayureshwar Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'shree-saibaba-samadhi-mandir': (city: 'Shirdi', deity: 'Sai Baba'),
      'siddhivinayak-temple': (city: 'Mumbai', deity: 'Ganesha'),
      'trimbakeshwar-temple': (city: 'Trimbak', deity: 'Shiva'),
      'bhimashankar-temple': (city: 'Bhimashankar', deity: 'Shiva'),
      'grishneshwar-temple': (city: 'Verul', deity: 'Shiva'),
      'vitthal-rukmini-temple': (city: 'Pandharpur', deity: 'Vitthal'),
      'mumba-devi-temple': (city: 'Mumbai', deity: 'Devi'),
      'mahalakshmi-temple': (city: 'Mumbai', deity: 'Devi'),
      'jejuri-khandoba-temple': (city: 'Jejuri', deity: 'Khandoba'),
      'morgaon-mayureshwar-temple': (city: 'Morgaon', deity: 'Ganesha'),
    };
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
      expect(temple.latitude, inInclusiveRange(17.654, 20.045));
      expect(temple.longitude, inInclusiveRange(72.786, 75.344));
      expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
      expect(temple.images, isEmpty);
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });

  test('Rajasthan expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Rajasthan').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'brahma-temple': 'Brahma Temple',
      'eklingji-temple': 'Eklingji Temple',
      'shrinathji-temple': 'Shrinathji Temple',
      'karni-mata-temple': 'Karni Mata Temple',
      'govind-dev-ji-temple': 'Govind Dev Ji Temple',
      'birla-mandir-lakshmi-narayan-temple':
          'Birla Mandir (Lakshmi Narayan Temple)',
      'dilwara-temples': 'Dilwara Temples',
      'salasar-balaji': 'Salasar Balaji',
      'khatushyam-temple': 'Khatushyam Temple',
      'mehandipur-balaji-temple': 'Mehandipur Balaji Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'brahma-temple': (city: 'Pushkar', deity: 'Brahma'),
      'eklingji-temple': (city: 'Kailashpuri (near Udaipur)', deity: 'Shiva'),
      'shrinathji-temple': (city: 'Nathdwara', deity: 'Vishnu'),
      'karni-mata-temple': (city: 'Deshnok', deity: 'Devi'),
      'govind-dev-ji-temple': (city: 'Jaipur', deity: 'Vishnu'),
      'birla-mandir-lakshmi-narayan-temple': (city: 'Jaipur', deity: 'Vishnu'),
      'dilwara-temples': (city: 'Mount Abu', deity: 'Jain Tirthankaras'),
      'salasar-balaji': (city: 'Salasar', deity: 'Hanuman'),
      'khatushyam-temple': (city: 'Khatu', deity: 'Vishnu'),
      'mehandipur-balaji-temple': (
        city: 'Mehandipur (Dausa)',
        deity: 'Hanuman',
      ),
    };
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
      expect(temple.latitude, inInclusiveRange(24.589, 27.811));
      expect(temple.longitude, inInclusiveRange(72.703, 76.814));
      expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
      expect(temple.images, isEmpty);
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });

  test('West Bengal expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'West Bengal').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'kalighat-kali-temple': 'Kalighat Kali Temple',
      'dakshineswar-kali-temple': 'Dakshineswar Kali Temple',
      'belur-math': 'Belur Math',
      'tarapith-temple': 'Tarapith Temple',
      'hangseshwari-temple': 'Hangseshwari Temple',
      'sri-mayapur-chandrodaya-mandir-iskcon-mayapur':
          'Sri Mayapur Chandrodaya Mandir (ISKCON Mayapur)',
      'taraknath-temple': 'Taraknath Temple',
      'birla-mandir': 'Birla Mandir',
      'kiriteswari-temple': 'Kiriteswari Temple',
      'kapil-muni-temple': 'Kapil Muni Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'kalighat-kali-temple': (city: 'Kolkata', deity: 'Devi (Kali)'),
      'dakshineswar-kali-temple': (
        city: 'Kolkata',
        deity: 'Devi (Bhavatarini Kali)',
      ),
      'belur-math': (
        city: 'Howrah',
        deity: 'Sri Ramakrishna (Ramakrishna–Vedanta tradition)',
      ),
      'tarapith-temple': (city: 'Tarapith', deity: 'Devi (Tara)'),
      'hangseshwari-temple': (
        city: 'Bansberia',
        deity: 'Devi (Hangseshwari Kali)',
      ),
      'sri-mayapur-chandrodaya-mandir-iskcon-mayapur': (
        city: 'Mayapur',
        deity: 'Radha-Madhava / Pancha-tattva (Gaudiya Vaishnavism)',
      ),
      'taraknath-temple': (city: 'Tarakeswar', deity: 'Shiva (Taraknath)'),
      'birla-mandir': (
        city: 'Kolkata',
        deity: 'Vishnu (Radha-Krishna / Lakshminarayan)',
      ),
      'kiriteswari-temple': (
        city: 'Murshidabad',
        deity: 'Devi (Kiriteswari / Mahishamardini)',
      ),
      'kapil-muni-temple': (city: 'Gangasagar', deity: 'Kapil Muni'),
    };
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
      expect(temple.latitude, inInclusiveRange(21.616, 24.22));
      expect(temple.longitude, inInclusiveRange(87.77, 88.42));
      expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
      expect(temple.images, isEmpty);
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });

  test('Madhya Pradesh expansion is ten new seeded temples', () {
    final rows = sampleTemples
        .where((t) => t.state == 'Madhya Pradesh')
        .toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'mahakaleshwar-temple': 'Mahakaleshwar Temple',
      'omkareshwar-temple': 'Omkareshwar Temple',
      'kandariya-mahadeva-temple': 'Kandariya Mahadeva Temple',
      'lakshmana-temple': 'Lakshmana Temple',
      'matangeshwar-temple': 'Matangeshwar Temple',
      'harsiddhi-temple': 'Harsiddhi Temple',
      'chintaman-ganesh-temple': 'Chintaman Ganesh Temple',
      'pashupatinath-temple': 'Pashupatinath Temple',
      'sharda-devi-temple-maihar': 'Sharda Devi Temple Maihar',
      'ram-raja-temple': 'Ram Raja Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'mahakaleshwar-temple': (city: 'Ujjain', deity: 'Shiva'),
      'omkareshwar-temple': (city: 'Omkareshwar', deity: 'Shiva'),
      'kandariya-mahadeva-temple': (city: 'Khajuraho', deity: 'Shiva'),
      'lakshmana-temple': (city: 'Khajuraho', deity: 'Vishnu'),
      'matangeshwar-temple': (city: 'Khajuraho', deity: 'Shiva'),
      'harsiddhi-temple': (city: 'Ujjain', deity: 'Devi'),
      'chintaman-ganesh-temple': (city: 'Ujjain', deity: 'Ganesha'),
      'pashupatinath-temple': (city: 'Mandsaur', deity: 'Shiva'),
      'sharda-devi-temple-maihar': (city: 'Maihar', deity: 'Devi'),
      'ram-raja-temple': (city: 'Orchha', deity: 'Vishnu/Rama'),
    };
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
      expect(temple.latitude, inInclusiveRange(22.225, 25.371));
      expect(temple.longitude, inInclusiveRange(75.052, 80.744));
      expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
      expect(temple.images, isEmpty);
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });

  test('Bihar expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Bihar').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'mahavir-mandir': 'Mahavir Mandir',
      'mundeshwari-devi-temple': 'Mundeshwari Devi Temple',
      'vishnupad-temple': 'Vishnupad Temple',
      'mahabodhi-temple': 'Mahabodhi Temple',
      'patan-devi-temple': 'Patan Devi Temple',
      'mangala-gauri-temple': 'Mangala Gauri Temple',
      'ajgaibinath-temple': 'Ajgaibinath Temple',
      'deo-sun-temple': 'Deo Sun Temple',
      'ugratara-temple': 'Ugratara Temple',
      'janaki-temple-sitamarhi': 'Janaki Temple Sitamarhi',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'mahavir-mandir': (city: 'Patna', deity: 'Hanuman'),
      'mundeshwari-devi-temple': (city: 'Bhabua', deity: 'Devi'),
      'vishnupad-temple': (city: 'Gaya', deity: 'Vishnu'),
      'mahabodhi-temple': (city: 'Bodh Gaya', deity: 'Buddha'),
      'patan-devi-temple': (city: 'Patna', deity: 'Devi'),
      'mangala-gauri-temple': (city: 'Gaya', deity: 'Devi'),
      'ajgaibinath-temple': (city: 'Sultanganj', deity: 'Shiva'),
      'deo-sun-temple': (city: 'Deo', deity: 'Surya'),
      'ugratara-temple': (city: 'Mahishi', deity: 'Devi'),
      'janaki-temple-sitamarhi': (city: 'Sitamarhi', deity: 'Sita (Devi)'),
    };
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
      expect(temple.latitude, inInclusiveRange(24.638, 26.607));
      expect(temple.longitude, inInclusiveRange(83.544, 86.755));
      if (id == 'mahabodhi-temple') {
        // KAN-77: verified Commons thumbs until Storage upload.
        expect(temple.imageUrl.contains('picsum'), isFalse);
        expect(temple.imageUrl, contains('upload.wikimedia.org'));
        expect(temple.images, hasLength(7));
        for (final url in temple.images) {
          expect(url, contains('upload.wikimedia.org'));
          expect(url.contains('picsum'), isFalse);
        }
        expect(temple.imageUrl, temple.images.first);
      } else {
        expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
        expect(temple.images, isEmpty);
      }
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
      if (id == 'mahabodhi-temple') {
        expect(parsed.images, temple.images);
      }
    }
  });

  test('Himachal Pradesh expansion is ten new seeded temples', () {
    final rows = sampleTemples
        .where((t) => t.state == 'Himachal Pradesh')
        .toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'jwalamukhi-temple': 'Jwalamukhi Temple',
      'naina-devi-temple': 'Naina Devi Temple',
      'chintpurni-temple': 'Chintpurni Temple',
      'chamunda-devi-temple': 'Chamunda Devi Temple',
      'baijnath-temple': 'Baijnath Temple',
      'bhimakali-temple': 'Bhimakali Temple',
      'hadimba-devi-temple': 'Hadimba Devi Temple',
      'lakshmi-narayan-temple': 'Lakshmi Narayan Temple',
      'panchvaktra-temple': 'Panchvaktra Temple',
      'manikaran-shiva-temple': 'Manikaran Shiva Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'jwalamukhi-temple': (city: 'Jwalamukhi', deity: 'Devi'),
      'naina-devi-temple': (city: 'Naina Devi', deity: 'Devi'),
      'chintpurni-temple': (city: 'Chintpurni', deity: 'Devi'),
      'chamunda-devi-temple': (city: 'Dharamshala', deity: 'Devi'),
      'baijnath-temple': (city: 'Baijnath', deity: 'Shiva'),
      'bhimakali-temple': (city: 'Sarahan', deity: 'Devi'),
      'hadimba-devi-temple': (city: 'Manali', deity: 'Devi'),
      'lakshmi-narayan-temple': (city: 'Chamba', deity: 'Vishnu'),
      'panchvaktra-temple': (city: 'Mandi', deity: 'Shiva'),
      'manikaran-shiva-temple': (city: 'Manikaran', deity: 'Shiva'),
    };
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
      expect(temple.latitude, inInclusiveRange(31.286, 32.578));
      expect(temple.longitude, inInclusiveRange(76.082, 77.651));
      expect(temple.imageUrl, 'https://picsum.photos/seed/$id/800/600');
      expect(temple.images, isEmpty);
      expect(temple.imageUrl.contains('firebasestorage'), isFalse);

      final map = temple.toFirestoreData(documentId: id);
      expect(map['id'], id);
      expect(map['address'], temple.location);
      expect(map.containsKey('location'), isFalse);
      expect(map.containsKey('photo_candidates'), isFalse);
      expect(map.containsKey('sources'), isFalse);
      expect(map.containsKey('rituals_notes'), isFalse);
      expect(map.containsKey('pooja_schedule'), isFalse);
      final parsed = Temple.fromMap(id, map);
      expect(parsed.name, temple.name);
      expect(parsed.state, temple.state);
      expect(parsed.location, temple.location);
      expect(parsed.story, temple.story);
      expect(parsed.timings, temple.timings);
      expect(parsed.specialities, temple.specialities);
      expect(parsed.imageUrl, temple.imageUrl);
    }
  });

  test('wave-2 timings and stories keep research honesty caveats', () {
    Temple named(String name) =>
        sampleTemples.firstWhere((t) => t.name == name);

    expect(
      named('Grishneshwar Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Grishneshwar Temple').timings.toLowerCase(),
      contains('midday'),
    );
    expect(
      named('Bhimashankar Temple').timings.toLowerCase(),
      contains('7:00'),
    );
    expect(
      named('Mumba Devi Temple').timings.toLowerCase(),
      contains('thinner'),
    );
    expect(
      named('Morgaon Mayureshwar Temple').timings.toLowerCase(),
      contains('provisional'),
    );
    expect(named('Dilwara Temples').story.toLowerCase(), contains('jain'));
    expect(named('Dilwara Temples').story.toLowerCase(), contains('no hindu'));
    expect(
      named('Eklingji Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(named('Salasar Balaji').timings.toLowerCase(), contains('conflict'));
    expect(
      named('Khatushyam Temple').timings.toLowerCase(),
      contains('provisional'),
    );
    expect(named('Mahabodhi Temple').story.toLowerCase(), contains('buddhist'));
    expect(named('Mahabodhi Temple').story.toLowerCase(), contains('unesco'));
    expect(
      named('Mahabodhi Temple').story.toLowerCase(),
      contains('world heritage'),
    );
    expect(
      named('Jwalamukhi Temple').timings.toLowerCase(),
      contains('conflict'),
    );
    expect(
      named('Baijnath Temple').story.toLowerCase(),
      contains('not the canonical vaidyanath jyotirlinga'),
    );
    expect(
      named('Naina Devi Temple').timings.toLowerCase(),
      contains('navratri'),
    );
    expect(
      named('Bhimakali Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Pashupatinath Temple').timings.toLowerCase(),
      contains('20:00 versus 22:00'),
    );
    expect(
      named('Kandariya Mahadeva Temple').timings.toLowerCase(),
      contains('no regular living'),
    );
    expect(
      named('Ugratara Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Patan Devi Temple').timings.toLowerCase(),
      contains('incredible india'),
    );
    expect(
      named('Hangseshwari Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(named('Kapil Muni Temple').timings.toLowerCase(), contains('thin'));
    expect(named('Belur Math').deity.toLowerCase(), contains('ramakrishna'));
  });
}
