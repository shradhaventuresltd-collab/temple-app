// KAN-203 search synonyms: expand vs name-only, diacritics, chip constraint.
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/temple_search.dart';

Temple _place({
  required String name,
  required String deity,
  String? tradition,
  String state = 'Punjab',
  String city = 'Amritsar',
  String story = '',
  String location = '',
}) {
  return Temple(
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: story,
    location: location.isEmpty ? '$city, $state' : location,
    timings: '',
    specialities: const [],
    latitude: 0,
    longitude: 0,
    tradition: tradition,
  );
}

void main() {
  final sikh = _place(
    name: 'Harmandir Sahib',
    deity: 'Guru Granth Sahib',
    tradition: 'sikh',
  );
  final jain = _place(
    name: 'Dilwara Temples',
    deity: 'Rishabhanatha',
    tradition: 'jain',
    state: 'Rajasthan',
    city: 'Mount Abu',
  );
  final jainBasti = _place(
    name: 'Shantinath Basti',
    deity: 'Shantinatha',
    tradition: 'jain',
    state: 'Karnataka',
    city: 'Shravanabelagola',
  );
  final hindu = _place(
    name: 'Meenakshi Amman Temple',
    deity: 'Devi',
    state: 'Tamil Nadu',
    city: 'Madurai',
    story: 'A gurdwara stands on the neighbouring street.',
  );
  final hinduBasti = _place(
    name: 'Old Basti shrine',
    deity: 'Shiva',
    state: 'Uttar Pradesh',
    city: 'Varanasi',
  );
  final buddhist = _place(
    name: 'Mahabodhi Temple',
    deity: 'Buddha',
    tradition: 'buddhist',
    state: 'Bihar',
    city: 'Bodh Gaya',
  );
  final all = [sikh, jain, jainBasti, hindu, hinduBasti, buddhist];

  test('expand synonyms match the resolved tradition, not the name', () {
    expect(templeMatchesQuery(sikh, 'gurdwara'), isTrue);
    expect(templeMatchesQuery(sikh, 'gurudwara'), isTrue);
    expect(templeMatchesQuery(sikh, 'gurdwara sahib'), isTrue);
    expect(templeMatchesQuery(jain, 'derasar'), isTrue);
    expect(templeMatchesQuery(jain, 'jinalaya'), isTrue);
    expect(templeMatchesQuery(buddhist, 'vihara'), isTrue);
    expect(templeMatchesQuery(buddhist, 'stupa'), isTrue);
    expect(templeMatchesQuery(buddhist, 'gompa'), isTrue);
    expect(templeMatchesQuery(hindu, 'gurdwara'), isFalse);
    expect(templeMatchesQuery(hindu, 'derasar'), isFalse);
  });

  test('gurdwara and gurudwara do not fold to the same string', () {
    expect(
      foldTempleSearchText('gurdwara'),
      isNot(foldTempleSearchText('gurudwara')),
    );
    expect(templeMatchesQuery(sikh, 'gurdwara'), isTrue);
    expect(templeMatchesQuery(sikh, 'gurudwara'), isTrue);
  });

  test('diacritics on synonym lookup only: gurdwārā hits gurdwara', () {
    expect(templeMatchesQuery(sikh, 'gurdwārā'), isTrue);
    expect(templeMatchesQuery(buddhist, 'vihāra'), isTrue);
    expect(templeMatchesQuery(buddhist, 'stūpa'), isTrue);
  });

  test('basti is name-only for Jain listings', () {
    expect(templeMatchesQuery(jainBasti, 'basti'), isTrue);
    expect(templeMatchesQuery(jain, 'basti'), isFalse);
    expect(templeMatchesQuery(hinduBasti, 'basti'), isFalse);
  });

  test('short queries do not fire tradition expansion', () {
    // "gu" is a plain substring of "Guru" and is not used here.
    expect(templeMatchesQuery(sikh, 'go'), isFalse);
    expect(templeMatchesQuery(buddhist, 'go'), isFalse);
    expect(templeMatchesQuery(sikh, 'vi'), isFalse);
  });

  test('story text must not leak a tradition match', () {
    expect(templeMatchesQuery(hindu, 'gurudwara'), isFalse);
    expect(templeMatchesQuery(hindu, 'gurdwara'), isFalse);
  });

  test('a Tradition chip still constrains synonym hits', () {
    expect(
      directoryMatchingTemples(all, query: 'gurudwara').map((t) => t.name),
      ['Harmandir Sahib'],
    );
    expect(
      directoryMatchingTemples(all, query: 'gurudwara', tradition: 'hindu'),
      isEmpty,
    );
    expect(
      directoryMatchingTemples(
        all,
        query: 'gurudwara',
        tradition: 'sikh',
      ).map((t) => t.name),
      ['Harmandir Sahib'],
    );
  });

  test('a name that contains Gurdwara outranks a synonym-only hit', () {
    final named = _place(
      name: 'Patna Gurdwara',
      deity: 'Guru Granth Sahib',
      tradition: 'sikh',
      state: 'Bihar',
      city: 'Patna',
    );
    final ranked = filterTemples([sikh, named], query: 'gurdwara');
    expect(ranked.first.name, 'Patna Gurdwara');
  });
}
