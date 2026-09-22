import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  test(
    'sample directory covers fifteen states and one hundred fifty temples',
    () {
      expect(sampleTemples.length, 150);
      expect(sampleTemples.map((t) => t.state).toSet(), {
        'Tamil Nadu',
        'Kerala',
        'Karnataka',
        'Andhra Pradesh',
        'Telangana',
        'Gujarat',
        'Odisha',
        'Uttar Pradesh',
        'Jammu and Kashmir',
        'Maharashtra',
        'Rajasthan',
        'West Bengal',
        'Madhya Pradesh',
        'Bihar',
        'Himachal Pradesh',
      });
      final slugs = sampleTemples.map((t) => templeDocumentId(t.name)).toList();
      expect(slugs.toSet().length, slugs.length);
    },
  );

  test('Andhra Pradesh expansion is ten new seeded temples', () {
    final rows = sampleTemples
        .where((t) => t.state == 'Andhra Pradesh')
        .toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'tirumala-venkateswara-temple': 'Tirumala Venkateswara Temple',
      'sri-mallikarjuna-swamy-temple': 'Sri Mallikarjuna Swamy Temple',
      'varaha-lakshmi-narasimha-temple': 'Varaha Lakshmi Narasimha Temple',
      'kanaka-durga-temple': 'Kanaka Durga Temple',
      'satyanarayana-swamy-temple': 'Satyanarayana Swamy Temple',
      'veerabhadra-temple': 'Veerabhadra Temple',
      'ahobilam-narasimha-temples': 'Ahobilam Narasimha Temples',
      'padmavathi-temple': 'Padmavathi Temple',
      'varasidhi-vinayaka-temple': 'Varasidhi Vinayaka Temple',
      'yaganti-uma-maheswara-temple': 'Yaganti Uma Maheswara Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'tirumala-venkateswara-temple': (city: 'Tirumala', deity: 'Vishnu'),
      'sri-mallikarjuna-swamy-temple': (city: 'Srisailam', deity: 'Shiva'),
      'varaha-lakshmi-narasimha-temple': (
        city: 'Visakhapatnam',
        deity: 'Vishnu',
      ),
      'kanaka-durga-temple': (city: 'Vijayawada', deity: 'Devi'),
      'satyanarayana-swamy-temple': (city: 'Annavaram', deity: 'Vishnu'),
      'veerabhadra-temple': (city: 'Lepakshi', deity: 'Shiva'),
      'ahobilam-narasimha-temples': (city: 'Ahobilam', deity: 'Vishnu'),
      'padmavathi-temple': (city: 'Tiruchanur', deity: 'Devi'),
      'varasidhi-vinayaka-temple': (city: 'Kanipakam', deity: 'Ganesha'),
      'yaganti-uma-maheswara-temple': (city: 'Yaganti', deity: 'Shiva'),
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
      expect(temple.latitude, inInclusiveRange(12.717, 18.266));
      expect(temple.longitude, inInclusiveRange(77.110, 83.751));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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

  test('Telangana expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Telangana').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'sri-lakshmi-narasimha-swamy-temple':
          'Sri Lakshmi Narasimha Swamy Temple',
      'sita-ramachandra-swamy-temple': 'Sita Ramachandra Swamy Temple',
      'thousand-pillar-temple': 'Thousand Pillar Temple',
      'ramappa-temple-rudreshwara': 'Ramappa Temple (Rudreshwara)',
      'gnana-saraswati-temple': 'Gnana Saraswati Temple',
      'chilkur-balaji-temple': 'Chilkur Balaji Temple',
      'keesaragutta-temple': 'Keesaragutta Temple',
      'bhadrakali-temple': 'Bhadrakali Temple',
      'jogulamba-temple': 'Jogulamba Temple',
      'kaleshwara-mukteswara-temple': 'Kaleshwara Mukteswara Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'sri-lakshmi-narasimha-swamy-temple': (
        city: 'Yadagirigutta',
        deity: 'Vishnu',
      ),
      'sita-ramachandra-swamy-temple': (city: 'Bhadrachalam', deity: 'Vishnu'),
      'thousand-pillar-temple': (city: 'Hanamkonda', deity: 'Shiva'),
      'ramappa-temple-rudreshwara': (city: 'Palampet', deity: 'Shiva'),
      'gnana-saraswati-temple': (city: 'Basara', deity: 'Devi'),
      'chilkur-balaji-temple': (city: 'Chilkur', deity: 'Vishnu'),
      'keesaragutta-temple': (city: 'Keesara', deity: 'Shiva'),
      'bhadrakali-temple': (city: 'Warangal', deity: 'Devi'),
      'jogulamba-temple': (city: 'Alampur', deity: 'Devi'),
      'kaleshwara-mukteswara-temple': (city: 'Kaleshwaram', deity: 'Shiva'),
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
      expect(temple.latitude, inInclusiveRange(15.377, 19.378));
      expect(temple.longitude, inInclusiveRange(77.456, 81.383));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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

  test('Gujarat expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Gujarat').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'somnath-temple': 'Somnath Temple',
      'dwarkadhish-temple': 'Dwarkadhish Temple',
      'ambaji-temple': 'Ambaji Temple',
      'kalika-mata-temple': 'Kalika Mata Temple',
      'modhera-sun-temple': 'Modhera Sun Temple',
      'bahucharaji-temple': 'Bahucharaji Temple',
      'ranchhodraiji-temple': 'Ranchhodraiji Temple',
      'nageshwar-jyotirlinga-temple': 'Nageshwar Jyotirlinga Temple',
      'akshardham-temple': 'Akshardham Temple',
      'chotila-chamunda-mata-temple': 'Chotila Chamunda Mata Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'somnath-temple': (city: 'Somnath', deity: 'Shiva'),
      'dwarkadhish-temple': (city: 'Dwarka', deity: 'Vishnu'),
      'ambaji-temple': (city: 'Ambaji', deity: 'Devi'),
      'kalika-mata-temple': (city: 'Pavagadh', deity: 'Devi'),
      'modhera-sun-temple': (city: 'Modhera', deity: 'Surya'),
      'bahucharaji-temple': (city: 'Bahucharaji', deity: 'Devi'),
      'ranchhodraiji-temple': (city: 'Dakor', deity: 'Vishnu'),
      'nageshwar-jyotirlinga-temple': (city: 'Dwarka', deity: 'Shiva'),
      'akshardham-temple': (city: 'Gandhinagar', deity: 'Swaminarayan'),
      'chotila-chamunda-mata-temple': (city: 'Chotila', deity: 'Devi'),
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
      expect(temple.latitude, inInclusiveRange(20.388, 24.836));
      expect(temple.longitude, inInclusiveRange(68.468, 74.012));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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

  test('Odisha expansion is ten new seeded temples', () {
    final rows = sampleTemples.where((t) => t.state == 'Odisha').toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'jagannath-temple': 'Jagannath Temple',
      'lingaraj-temple': 'Lingaraj Temple',
      'konark-sun-temple': 'Konark Sun Temple',
      'mukteshwar-temple': 'Mukteshwar Temple',
      'rajarani-temple': 'Rajarani Temple',
      'ananta-vasudeva-temple': 'Ananta Vasudeva Temple',
      'sakshi-gopal-temple': 'Sakshi Gopal Temple',
      'maa-taratarini-temple': 'Maa Taratarini Temple',
      'cuttack-chandi-temple': 'Cuttack Chandi Temple',
      'biraja-temple': 'Biraja Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'jagannath-temple': (city: 'Puri', deity: 'Vishnu'),
      'lingaraj-temple': (city: 'Bhubaneswar', deity: 'Shiva'),
      'konark-sun-temple': (city: 'Konark', deity: 'Surya'),
      'mukteshwar-temple': (city: 'Bhubaneswar', deity: 'Shiva'),
      'rajarani-temple': (city: 'Bhubaneswar', deity: 'Shiva'),
      'ananta-vasudeva-temple': (city: 'Bhubaneswar', deity: 'Vishnu'),
      'sakshi-gopal-temple': (city: 'Sakshigopal', deity: 'Vishnu'),
      'maa-taratarini-temple': (city: 'Purushottapur', deity: 'Devi'),
      'cuttack-chandi-temple': (city: 'Cuttack', deity: 'Devi'),
      'biraja-temple': (city: 'Jajpur', deity: 'Devi'),
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
      expect(temple.latitude, inInclusiveRange(18.990, 21.334));
      expect(temple.longitude, inInclusiveRange(84.400, 86.838));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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

  test('Uttar Pradesh expansion is ten new seeded temples', () {
    final rows = sampleTemples
        .where((t) => t.state == 'Uttar Pradesh')
        .toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'kashi-vishwanath-temple': 'Kashi Vishwanath Temple',
      'ram-mandir-shri-ram-janmabhoomi-temple':
          'Ram Mandir (Shri Ram Janmabhoomi Temple)',
      'krishna-janmabhoomi-temple': 'Krishna Janmabhoomi Temple',
      'banke-bihari-temple': 'Banke Bihari Temple',
      'prem-mandir': 'Prem Mandir',
      'sankat-mochan-hanuman-temple': 'Sankat Mochan Hanuman Temple',
      'hanuman-garhi': 'Hanuman Garhi',
      'vindhyavasini-temple': 'Vindhyavasini Temple',
      'gorakhnath-temple': 'Gorakhnath Temple',
      'bade-hanuman-ji-temple-lete-hanuman':
          'Bade Hanuman Ji Temple (Lete Hanuman)',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'kashi-vishwanath-temple': (city: 'Varanasi', deity: 'Shiva'),
      'ram-mandir-shri-ram-janmabhoomi-temple': (
        city: 'Ayodhya',
        deity: 'Vishnu',
      ),
      'krishna-janmabhoomi-temple': (city: 'Mathura', deity: 'Vishnu'),
      'banke-bihari-temple': (city: 'Vrindavan', deity: 'Vishnu'),
      'prem-mandir': (city: 'Vrindavan', deity: 'Vishnu'),
      'sankat-mochan-hanuman-temple': (city: 'Varanasi', deity: 'Hanuman'),
      'hanuman-garhi': (city: 'Ayodhya', deity: 'Hanuman'),
      'vindhyavasini-temple': (city: 'Vindhyachal', deity: 'Devi'),
      'gorakhnath-temple': (city: 'Gorakhpur', deity: 'Gorakhnath'),
      'bade-hanuman-ji-temple-lete-hanuman': (
        city: 'Prayagraj',
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
      expect(temple.latitude, inInclusiveRange(24.665, 28.080));
      expect(temple.longitude, inInclusiveRange(77.169, 83.858));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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

  test('Jammu and Kashmir expansion is ten new seeded temples', () {
    final rows = sampleTemples
        .where((t) => t.state == 'Jammu and Kashmir')
        .toList();
    expect(rows, hasLength(10));
    const expected = <String, String>{
      'vaishno-devi-temple': 'Vaishno Devi Temple',
      'amarnath-cave-temple': 'Amarnath Cave Temple',
      'raghunath-temple': 'Raghunath Temple',
      'shankaracharya-temple': 'Shankaracharya Temple',
      'kheer-bhawani-temple': 'Kheer Bhawani Temple',
      'mahamaya-temple': 'Mahamaya Temple',
      'ranbireshwar-temple': 'Ranbireshwar Temple',
      'martand-sun-temple': 'Martand Sun Temple',
      'purmandal-temple': 'Purmandal Temple',
      'sudh-mahadev-temple': 'Sudh Mahadev Temple',
    };
    const expectedMeta = <String, ({String city, String deity})>{
      'vaishno-devi-temple': (city: 'Katra', deity: 'Devi'),
      'amarnath-cave-temple': (
        city: 'Pahalgam / Anantnag (yatra)',
        deity: 'Shiva',
      ),
      'raghunath-temple': (city: 'Jammu', deity: 'Vishnu'),
      'shankaracharya-temple': (city: 'Srinagar', deity: 'Shiva'),
      'kheer-bhawani-temple': (city: 'Tulmulla', deity: 'Devi'),
      'mahamaya-temple': (city: 'Jammu', deity: 'Devi'),
      'ranbireshwar-temple': (city: 'Jammu', deity: 'Shiva'),
      'martand-sun-temple': (city: 'Mattan / Anantnag', deity: 'Surya'),
      'purmandal-temple': (city: 'Samba', deity: 'Shiva'),
      'sudh-mahadev-temple': (city: 'Udhampur', deity: 'Shiva'),
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
      expect(temple.latitude, inInclusiveRange(32.196, 34.721));
      expect(temple.longitude, inInclusiveRange(74.230, 76.001));
      expect(temple.imageUrl, "https://picsum.photos/seed/$id/800/600");
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
  test('expansion timings and stories keep research honesty caveats', () {
    Temple named(String name) =>
        sampleTemples.firstWhere((t) => t.name == name);

    expect(
      named('Tirumala Venkateswara Temple').timings.toLowerCase(),
      contains('tirumala.org'),
    );
    expect(
      named('Sri Mallikarjuna Swamy Temple').timings.toLowerCase(),
      contains('secondary'),
    );
    expect(
      named('Varaha Lakshmi Narasimha Temple').timings.toLowerCase(),
      contains('sources differ'),
    );
    expect(
      named('Kanaka Durga Temple').timings.toLowerCase(),
      contains('not a full clock'),
    );
    expect(named('Veerabhadra Temple').timings.toLowerCase(), contains('asi'));
    expect(
      named('Ahobilam Narasimha Temples').timings.toLowerCase(),
      contains('thin official clock'),
    );
    expect(
      named('Yaganti Uma Maheswara Temple').timings.toLowerCase(),
      contains('thin primary sources'),
    );
    expect(
      named('Varasidhi Vinayaka Temple').story.toLowerCase(),
      contains('folklore'),
    );
    expect(
      named('Bhadrakali Temple').timings.toLowerCase(),
      contains('varies by source'),
    );
    expect(
      named('Kaleshwara Mukteswara Temple').timings.toLowerCase(),
      contains('approximate'),
    );
    expect(
      named('Jogulamba Temple').story.toLowerCase(),
      contains('telangana'),
    );
    expect(
      named('Ramappa Temple (Rudreshwara)').timings.toLowerCase(),
      contains('confirm'),
    );
    expect(
      named('Somnath Temple').timings.toLowerCase(),
      contains('somnath.org'),
    );
    expect(
      named('Modhera Sun Temple').timings.toLowerCase(),
      contains('no living'),
    );
    expect(
      named('Akshardham Temple').timings.toLowerCase(),
      contains('monday'),
    );
    expect(
      named('Chotila Chamunda Mata Temple').timings.toLowerCase(),
      contains('thin primary'),
    );
    expect(
      named('Kalika Mata Temple').timings.toLowerCase(),
      contains('incredible india'),
    );
    expect(named('Jagannath Temple').timings.toLowerCase(), contains('sjta'));
    expect(
      named('Konark Sun Temple').timings.toLowerCase(),
      contains('sunrise to sunset'),
    );
    expect(
      named('Rajarani Temple').timings.toLowerCase(),
      contains('empty sanctum'),
    );
    expect(
      named('Sakshi Gopal Temple').timings.toLowerCase(),
      contains('provisional'),
    );
    expect(
      named('Cuttack Chandi Temple').timings.toLowerCase(),
      contains('thin'),
    );
    expect(
      named('Biraja Temple').timings.toLowerCase(),
      contains('maabiraja.com'),
    );
    expect(
      named('Kashi Vishwanath Temple').timings.toLowerCase(),
      contains('shrikashivishwanath.org'),
    );
    expect(
      named('Ram Mandir (Shri Ram Janmabhoomi Temple)').timings.toLowerCase(),
      contains('srjbtkshetra.org'),
    );
    expect(
      named('Banke Bihari Temple').timings.toLowerCase(),
      contains('summer'),
    );
    expect(
      named('Hanuman Garhi').timings.toLowerCase(),
      contains('provisional'),
    );
    expect(
      named('Gorakhnath Temple').timings.toLowerCase(),
      contains('not crisply'),
    );
    expect(
      named('Bade Hanuman Ji Temple (Lete Hanuman)').timings.toLowerCase(),
      contains('thin official clock'),
    );
    expect(
      named('Vindhyavasini Temple').timings.toLowerCase(),
      contains('navaratri'),
    );
    expect(
      named('Vaishno Devi Temple').timings.toLowerCase(),
      contains('maavaishnodevi.org'),
    );
    expect(
      named('Amarnath Cave Temple').timings.toLowerCase(),
      contains('seasonal only'),
    );
    expect(
      named('Martand Sun Temple').timings.toLowerCase(),
      contains('not a living temple'),
    );
    expect(
      named('Mahamaya Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Ranbireshwar Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Purmandal Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Sudh Mahadev Temple').timings.toLowerCase(),
      contains('thin official'),
    );
    expect(
      named('Shankaracharya Temple').timings.toLowerCase(),
      contains('provisional'),
    );
  });
}
