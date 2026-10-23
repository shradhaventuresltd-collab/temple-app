import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/temple_search.dart';

void main() {
  Temple temple({
    String id = '',
    String name = 'Plain Temple',
    String state = 'Tamil Nadu',
    String city = 'Madurai',
    String deity = 'Devi',
    String location = 'Temple Street',
    String description = '',
    String story = '',
  }) {
    return Temple(
      id: id,
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
    // Meenakshi is a Parvati synonym, so Uma and Gauri temples match too.
    // The original .single assertion counted only the name; the top stays
    // Meenakshi Amman Temple.
    final meenakshi = filterTemples(sampleTemples, query: 'meenakshi');
    expect(meenakshi.first.name, 'Meenakshi Amman Temple');
    expect(meenakshi.map((t) => t.name), contains('Mangala Gauri Temple'));
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
    // Somnath is a Shiva synonym, so the other Gujarat Shiva temple matches
    // too. The original .single assertion counted only the place name.
    expect(combined.first.name, 'Somnath Temple');
    expect(
      combined.map((t) => t.name),
      contains('Nageshwar Jyotirlinga Temple'),
    );

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

  test('Minakshi, Tirupathi, and the Chendur spellings find the temples', () {
    expect(
      filterTemples(sampleTemples, query: 'Minakshi').map((t) => t.name),
      contains('Meenakshi Amman Temple'),
    );
    expect(
      filterTemples(sampleTemples, query: 'Tirupathi').map((t) => t.name),
      contains('Tirumala Venkateswara Temple'),
    );

    final thiru = filterTemples(sampleTemples, query: 'Thiruchendur');
    final tiru = filterTemples(sampleTemples, query: 'Tiruchendur');
    expect(thiru.map((t) => t.name), contains('Subramanya Swamy Temple'));
    expect(tiru.map((t) => t.name), contains('Subramanya Swamy Temple'));

    final onlyThiru = temple(
      name: 'Thiruchendur Murugan Temple',
      city: 'Thoothukudi',
    );
    final onlyTiru = temple(
      name: 'Tiruchendur Murugan Temple',
      city: 'Thoothukudi',
    );
    expect(filterTemples([onlyThiru], query: 'Tiruchendur'), [onlyThiru]);
    expect(filterTemples([onlyTiru], query: 'Thiruchendur'), [onlyTiru]);
  });

  test('spaces, hyphens, and the other transliteration folds match', () {
    expect(
      filterTemples([
        temple(name: 'Meena kshi Amman'),
      ], query: 'Minakshi').single.name,
      'Meena kshi Amman',
    );
    expect(
      filterTemples([
        temple(name: 'Tiru-pathi Devasthanam'),
      ], query: 'Tirupathi').single.name,
      'Tiru-pathi Devasthanam',
    );
    expect(
      filterTemples([
        temple(name: 'Tirupati Temple'),
      ], query: 'Tiru pathi').single.name,
      'Tirupati Temple',
    );
    expect(
      filterTemples([
        temple(name: 'Dwarka Temple'),
      ], query: 'Dvarka').single.name,
      'Dwarka Temple',
    );
    expect(
      filterTemples([
        temple(name: 'Kottayam Temple'),
      ], query: 'Kotayam').single.name,
      'Kottayam Temple',
    );
    expect(
      filterTemples([
        temple(name: 'Tamizh Temple'),
      ], query: 'Tamil').single.name,
      'Tamizh Temple',
    );
    expect(
      filterTemples([
        temple(name: 'Kashi Vishwanath'),
      ], query: 'Kasi').single.name,
      'Kashi Vishwanath',
    );
  });

  test('exact matches stay first and edit distance is only a fallback', () {
    final farther = temple(name: 'Meenaksha Temple');
    final exact = temple(name: 'Meenakshi Amman Temple');
    final other = temple(name: 'Somnath Temple', city: 'Veraval');

    expect(
      filterTemples([
        farther,
        exact,
        other,
      ], query: 'Meenakshi').map((t) => t.name),
      ['Meenakshi Amman Temple'],
    );
    expect(
      filterTemples([farther, exact], query: 'Meenakshix').map((t) => t.name),
      ['Meenakshi Amman Temple', 'Meenaksha Temple'],
    );
    expect(
      filterTemples([
        other,
        temple(name: 'Meenakshi Amman Temple', city: 'Madurai'),
      ], query: 'Maduri').single.city,
      'Madurai',
    );
    expect(filterTemples([exact], query: 'Sivo'), isEmpty);
  });

  test('an obvious non-match finds nothing', () {
    expect(filterTemples(sampleTemples, query: 'qqqqqqqq'), isEmpty);
    expect(filterTemples(sampleTemples, query: 'zzzz-not-a-temple'), isEmpty);
  });

  test('short queries keep the old substring counts', () {
    expect(filterTemples(sampleTemples, query: 'ee'), hasLength(19));
    expect(filterTemples(sampleTemples, query: 'th'), hasLength(71));
    expect(filterTemples(sampleTemples, query: 'it'), hasLength(19));
    expect(filterTemples(sampleTemples, query: '-'), hasLength(4));
    expect(filterTemples(sampleTemples, query: 'EE'), hasLength(19));
  });

  test('a fuzzy match still respects state and deity filters', () {
    final meenakshi = temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      deity: 'Devi',
      city: 'Madurai',
    );
    final other = temple(
      name: 'Other Temple',
      state: 'Tamil Nadu',
      deity: 'Shiva',
      city: 'Chennai',
    );
    final kerala = temple(
      name: 'Guruvayur Temple',
      state: 'Kerala',
      deity: 'Vishnu',
      city: 'Guruvayur',
    );

    expect(
      filterTemples(
        [other, kerala, meenakshi],
        state: 'Tamil Nadu',
        query: 'Meenakshix',
      ).map((t) => t.name),
      ['Meenakshi Amman Temple'],
    );
    expect(
      filterTemples([meenakshi, kerala], state: 'Kerala', query: 'Meenakshix'),
      isEmpty,
    );
    expect(
      filterTemples(
        [other, meenakshi],
        deity: 'Devi',
        query: 'Meenakshix',
      ).single.name,
      'Meenakshi Amman Temple',
    );
  });

  test('an empty query keeps every temple that matches the filters', () {
    final temples = [
      temple(name: 'A', state: 'Kerala', deity: 'Shiva', city: 'Kochi'),
      temple(name: 'B', state: 'Tamil Nadu', deity: 'Shiva', city: 'Madurai'),
      temple(name: 'C', state: 'Kerala', deity: 'Devi', city: 'Kollam'),
    ];

    expect(
      filterTemples(temples, state: 'Kerala', query: '').map((t) => t.name),
      ['A', 'C'],
    );
    expect(
      filterTemples(
        temples,
        state: 'Kerala',
        deity: 'Shiva',
        query: '  \n',
      ).map((t) => t.name),
      ['A'],
    );
    expect(
      filterTemples(sampleTemples, state: 'Kerala', query: '').length,
      sampleTemples.where((t) => t.state == 'Kerala').length,
    );
  });

  test('non-Latin text is searched literally', () {
    final listed = temple(
      name: 'मीनाक्षी अम्मन मंदिर',
      city: 'मदुरै',
      state: 'तमिलनाडु',
    );

    expect(filterTemples(sampleTemples, query: 'मीनाक्षी'), isEmpty);
    expect(
      filterTemples([
        temple(name: 'Tirumal Hill Shrine'),
        temple(
          id: 'tirumala-venkateswara-temple',
          name: 'Tirumala Venkateswara Temple',
          city: 'Tirumala',
          deity: 'Vishnu',
          location: 'Tirumala hills',
        ),
      ], query: 'Tirupathi').map((t) => t.name),
      ['Tirumala Venkateswara Temple'],
    );
    expect(filterTemples(sampleTemples, query: 'திருச்செந்தூர்'), isEmpty);
    expect(
      filterTemples([listed], query: 'मीनाक्षी').single.name,
      'मीनाक्षी अम्मन मंदिर',
    );
    expect(filterTemples([listed], query: 'मदुरै').single.city, 'मदुरै');
    expect(
      () => filterTemples(sampleTemples, query: '🛕 मीनाक्षी'),
      returnsNormally,
    );
  });

  const majorShiva = {
    'Brihadeeswarar Temple',
    'Arunachaleswarar Temple',
    'Ramanathaswamy Temple',
    'Sri Mallikarjuna Swamy Temple',
    'Somnath Temple',
    'Nageshwar Jyotirlinga Temple',
    'Kashi Vishwanath Temple',
    'Trimbakeshwar Temple',
    'Bhimashankar Temple',
    'Grishneshwar Temple',
    'Mahakaleshwar Temple',
    'Omkareshwar Temple',
  };

  test('Tirupati spellings rank Tirumala Venkateswara first', () {
    final kalyana = temple(
      name: 'Kalyana Venkateswara Temple, Srinivasa Mangapuram',
      city: 'Tirupati',
      deity: 'Vishnu',
      location: 'Srinivasa Mangapuram, Tirupati',
    );
    final tirumala = temple(
      id: 'tirumala-venkateswara-temple',
      name: 'Tirumala Venkateswara Temple',
      city: 'Tirumala',
      deity: 'Vishnu',
      location: 'Tirumala, Tirupati district',
    );
    final listed = [kalyana, tirumala];

    for (final query in ['Tirupathi', 'Tirupati', 'Tirumala']) {
      expect(
        filterTemples(listed, query: query).first.name,
        'Tirumala Venkateswara Temple',
        reason: query,
      );
      expect(
        filterTemples(sampleTemples, query: query).first.name,
        'Tirumala Venkateswara Temple',
        reason: query,
      );
    }
  });

  test('Sivan ranks a major Shiva temple ahead of a local Shiv temple', () {
    final budheswar = temple(
      id: 'budheswar-shiv-temple-dhamdha',
      name: 'Budheswar Shiv Temple Dhamdha',
      city: 'Dhamdha',
      deity: 'Shiva',
    );
    final brihad = temple(
      id: 'brihadeeswarar-temple',
      name: 'Brihadeeswarar Temple',
      city: 'Thanjavur',
      deity: 'Shiva',
    );

    expect(
      filterTemples([budheswar, brihad], query: 'Sivan').first.name,
      'Brihadeeswarar Temple',
    );
    expect(
      majorShiva,
      contains(filterTemples(sampleTemples, query: 'Sivan').first.name),
    );
    expect(
      majorShiva,
      contains(filterTemples(sampleTemples, query: 'Shiva').first.name),
    );
  });

  test('sivan still finds Shiva temples', () {
    final found = filterTemples(sampleTemples, query: 'Sivan');

    expect(found, isNotEmpty);
    expect(found.where((t) => t.deity == 'Shiva'), isNotEmpty);
    expect(majorShiva, contains(found.first.name));
  });

  test('sivan does not rank Sivaganga or Sivakasi as Shiva matches', () {
    final sivaganga = temple(
      name: 'Sivaganga Temple',
      city: 'Sivaganga',
      deity: 'Murugan',
    );
    final sivakasi = temple(
      name: 'Sivakasi Temple',
      city: 'Sivakasi',
      deity: 'Murugan',
    );
    final shiva = temple(
      id: 'brihadeeswarar-temple',
      name: 'Brihadeeswarar Temple',
      city: 'Thanjavur',
      deity: 'Shiva',
    );

    final names = filterTemples([
      sivaganga,
      sivakasi,
      shiva,
    ], query: 'Sivan').map((t) => t.name).toList();

    expect(names.first, 'Brihadeeswarar Temple');
    expect(names.indexOf('Sivaganga Temple'), greaterThan(0));
    expect(names.indexOf('Sivakasi Temple'), greaterThan(0));
  });

  test('a search for sivakasi does not boost Kashi', () {
    final sivakasi = temple(
      name: 'Sivakasi Temple',
      city: 'Sivakasi',
      deity: 'Devi',
    );
    // The address keeps Kashi in the same result set. Only a name-token
    // boost would move it ahead, and `sivakasi` is not the token `kasi`.
    final kashi = temple(
      id: 'kashi-vishwanath-temple',
      name: 'Kashi Vishwanath Temple',
      city: 'Varanasi',
      deity: 'Shiva',
      location: 'Sivakasi Road, Varanasi',
    );

    expect(
      filterTemples([sivakasi, kashi], query: 'sivakasi').map((t) => t.name),
      ['Sivakasi Temple', 'Kashi Vishwanath Temple'],
    );
  });

  test('Minakshi, Tiruchendur, and short queries keep their top result', () {
    expect(
      filterTemples(sampleTemples, query: 'Minakshi').first.name,
      'Meenakshi Amman Temple',
    );
    expect(
      filterTemples(sampleTemples, query: 'Tiruchendur').first.name,
      'Subramanya Swamy Temple',
    );
    expect(
      filterTemples(sampleTemples, query: 'ee').first.name,
      'Meenakshi Amman Temple',
    );
    expect(
      filterTemples(sampleTemples, query: 'th').first.name,
      'Brihadeeswarar Temple',
    );
    expect(
      filterTemples(sampleTemples, query: 'it').first.name,
      'Vaitheeswaran Koil',
    );
  });
}
