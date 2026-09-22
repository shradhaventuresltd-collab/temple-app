import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/temple_search.dart';

void main() {
  Temple temple({
    String name = 'Plain Temple',
    String state = 'Tamil Nadu',
    String city = 'Madurai',
    String deity = 'Devi',
    String location = 'Temple Street',
    String description = '',
    String story = '',
  }) {
    return Temple(
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: '',
      description: description,
      story: story,
      location: location,
      timings: '',
      specialities: const [],
      latitude: 0,
      longitude: 0,
    );
  }

  test('blank query keeps every temple in order', () {
    final temples = [
      temple(name: 'First'),
      temple(name: 'Second', state: 'Kerala', city: 'Kochi', deity: 'Shiva'),
    ];

    expect(filterTemples(temples, query: '   \n  ').map((t) => t.name), [
      'First',
      'Second',
    ]);
    expect(templeMatchesQuery(temples.first, ''), isTrue);
  });

  test('matches name, city, state, deity, and address partially', () {
    final temples = [
      temple(
        name: 'Meenakshi Amman Temple',
        city: 'Madurai',
        state: 'Tamil Nadu',
        deity: 'Devi',
        location: 'Madurai Main, Madurai, Tamil Nadu 625001',
      ),
      temple(
        name: 'Brihadeeswarar Temple',
        city: 'Thanjavur',
        state: 'Tamil Nadu',
        deity: 'Shiva',
        location: 'Membalam Rd, Thanjavur, Tamil Nadu 613007',
      ),
    ];

    expect(
      filterTemples(temples, query: '  MEENA ').single.name,
      'Meenakshi Amman Temple',
    );
    expect(filterTemples(temples, query: 'thanj').single.city, 'Thanjavur');
    expect(filterTemples(temples, query: 'tamil nadu').map((t) => t.name), [
      'Meenakshi Amman Temple',
      'Brihadeeswarar Temple',
    ]);
    expect(
      filterTemples(temples, query: 'SHIVA').single.name,
      'Brihadeeswarar Temple',
    );
    expect(
      filterTemples(temples, query: 'membalam').single.name,
      'Brihadeeswarar Temple',
    );
  });

  test('words can match across different fields', () {
    final temples = [
      temple(
        name: 'Brihadeeswarar Temple',
        city: 'Thanjavur',
        state: 'Tamil Nadu',
        deity: 'Shiva',
      ),
      temple(name: 'Meenakshi Amman Temple', city: 'Madurai', deity: 'Devi'),
    ];

    expect(
      filterTemples(temples, query: 'shiva   thanjavur').single.name,
      'Brihadeeswarar Temple',
    );
  });

  test('does not search story or description', () {
    final temples = [
      temple(
        name: 'Plain Temple',
        description: 'uniquequarkdescription',
        story: 'uniquequarkstory',
      ),
    ];

    expect(filterTemples(temples, query: 'uniquequarkdescription'), isEmpty);
    expect(filterTemples(temples, query: 'uniquequarkstory'), isEmpty);
    expect(filterTemples(temples, query: 'plain'), isNotEmpty);
  });

  test('state and deity filters combine with the query', () {
    final temples = [
      temple(name: 'Kept', state: 'Kerala', deity: 'Shiva', city: 'Kottayam'),
      temple(
        name: 'Other deity',
        state: 'Kerala',
        deity: 'Vishnu',
        city: 'Kottayam',
      ),
      temple(
        name: 'Other state',
        state: 'Gujarat',
        deity: 'Shiva',
        city: 'Kottayam',
      ),
    ];

    expect(
      filterTemples(
        temples,
        state: 'Kerala',
        deity: 'Shiva',
        query: 'kottay',
      ).map((t) => t.name),
      ['Kept'],
    );
  });

  test('chip filters stay exact while the query is case-insensitive', () {
    expect(filterTemples(sampleTemples, state: 'tamil nadu'), isEmpty);
    expect(filterTemples(sampleTemples, query: 'tamil nadu'), isNotEmpty);
    expect(filterTemples(sampleTemples, deity: 'shiva'), isEmpty);
    expect(filterTemples(sampleTemples, query: 'shiva'), isNotEmpty);
  });

  test('sample directory matches name, address, and combined filters', () {
    expect(
      filterTemples(sampleTemples, query: 'meenakshi').single.name,
      'Meenakshi Amman Temple',
    );
    expect(
      filterTemples(sampleTemples, query: '362268').single.name,
      'Somnath Temple',
    );

    final base = filterTemples(sampleTemples, state: 'Gujarat', deity: 'Shiva');
    final onList = filterTemples(base, query: 'somnath');
    final combined = filterTemples(
      sampleTemples,
      state: 'Gujarat',
      deity: 'Shiva',
      query: 'somnath',
    );
    expect(onList.map((t) => t.name), combined.map((t) => t.name));
    expect(combined.single.name, 'Somnath Temple');

    expect(
      filterTemples(sampleTemples, state: 'Kerala', query: 'madurai'),
      isEmpty,
    );
    expect(
      filterTemples(sampleTemples, query: '   ').length,
      sampleTemples.length,
    );
  });

  test('unknown query returns an empty list', () {
    expect(filterTemples(sampleTemples, query: 'zzzz-not-a-temple'), isEmpty);
  });
}
