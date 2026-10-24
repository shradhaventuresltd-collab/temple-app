import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('valid coordinates use a lat,lng directions destination', () {
    final uri = googleMapsDirectionsUri(
      name: 'Manakula Vinayagar Temple, Puducherry',
      latitude: 11.9346,
      longitude: 79.8304,
    );
    expect(uri, isNotNull);
    expect(uri!.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '11.9346,79.8304');
    expect(uri.queryParameters.containsKey('query'), isFalse);
    expect(
      uri.toString(),
      'https://www.google.com/maps/dir/?api=1&destination=11.9346,79.8304',
    );
    expect(uri.toString().contains('Manakula'), isFalse);
    expect(uri.toString().contains('Puducherry'), isFalse);
  });

  test('a comma in the name is not a second destination when coords exist', () {
    final uri = googleMapsDirectionsUri(
      name: 'Murugan Temple, Thirupparankundram',
      latitude: 10,
      longitude: 78.1,
    )!;
    expect(uri.queryParameters['destination'], '10,78.1');
    expect(uri.toString().contains('Murugan'), isFalse);
    expect(uri.toString().contains('%2C'), isFalse);
  });

  test('tricky names are encoded only as the fallback destination', () {
    const name = "Sri Ayyappan & Parvati's Temple, Pondicherry #1 / Gopuram அ";
    final uri = googleMapsDirectionsUri(
      name: name,
      latitude: null,
      longitude: null,
    )!;
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters.keys.toSet(), {'api', 'destination'});
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], name);
    final text = uri.toString();
    expect(
      text,
      startsWith('https://www.google.com/maps/dir/?api=1&destination='),
    );
    expect(text, contains('%26'));
    expect(text, contains('%27'));
    expect(text, contains('%2C'));
    expect(text, contains('%23'));
    expect(text, contains('%2F'));
    expect(text, contains('%E0%AE%85'));
    expect(text.contains('&Parvati'), isFalse);
    expect(text.contains('#'), isFalse);
    expect(text.contains("Parvati's"), isFalse);
    expect(text.contains('Pondicherry,'), isFalse);
    expect(text.contains('Gopuram அ'), isFalse);

    final curly = googleMapsDirectionsUri(
      name: 'Meenakshi’s Temple',
      latitude: double.nan,
      longitude: 80,
    )!;
    expect(curly.queryParameters['destination'], 'Meenakshi’s Temple');
    expect(curly.toString(), contains('%E2%80%99'));
  });

  test('name fallback adds city and state as one encoded destination', () {
    final uri = googleMapsDirectionsUri(
      name: "Sri Ayyappan & Parvati's Temple",
      city: 'Karaikal',
      state: 'Puducherry',
      latitude: 0,
      longitude: 0,
    )!;
    expect(
      uri.queryParameters['destination'],
      "Sri Ayyappan & Parvati's Temple, Karaikal, Puducherry",
    );
    expect(uri.queryParameters.keys.toSet(), {'api', 'destination'});
    final text = uri.toString();
    expect(text, contains('%26'));
    expect(text, contains('%27'));
    expect(text, contains('%2C'));
    expect(text.contains(','), isFalse);
    expect(text.contains('&Parvati'), isFalse);

    final coords = googleMapsDirectionsUri(
      name: 'Manakula Vinayagar Temple, Puducherry',
      city: 'Puducherry',
      state: 'Puducherry',
      latitude: 11.9346,
      longitude: 79.8304,
    )!;
    expect(
      coords.toString(),
      'https://www.google.com/maps/dir/?api=1&destination=11.9346,79.8304',
    );

    expect(
      googleMapsDirectionsUri(
        name: '   ',
        city: 'Karaikal',
        state: 'Puducherry',
      ),
      isNull,
    );
  });

  test('a long fallback name is encoded in full', () {
    final name = 'Temple ${'A & B,' * 40} அ';
    expect(name.length, greaterThan(180));
    final uri = googleMapsDirectionsUri(name: name)!;
    expect(uri.queryParameters['destination'], name);
    expect(uri.toString().length, greaterThan(name.length));
    expect(uri.queryParameters.keys, ['api', 'destination']);
  });

  test('invalid coordinates fall back to the encoded name', () {
    const name = 'Unplaced Temple';
    final cases = <(double?, double?)>[
      (null, null),
      (null, 78.1),
      (11.9, null),
      (0, 0),
      (double.nan, 80),
      (12, double.infinity),
      (double.negativeInfinity, 1),
      (91, 78),
      (-91, 78),
      (11, 181),
      (11, -181),
    ];
    for (final pair in cases) {
      final uri = googleMapsDirectionsUri(
        name: name,
        latitude: pair.$1,
        longitude: pair.$2,
      );
      expect(uri, isNotNull, reason: '$pair');
      expect(uri!.queryParameters['destination'], name, reason: '$pair');
      expect(uri.toString().contains(','), isFalse, reason: '$pair');
    }
    expect(
      googleMapsDirectionsUri(name: '   ', latitude: null, longitude: null),
      isNull,
    );
    expect(
      googleMapsDirectionsUri(name: '', latitude: 0, longitude: 0),
      isNull,
    );
  });

  test('swapped numeric coordinates are sent as stored', () {
    final uri = googleMapsDirectionsUri(
      name: 'Manakula Vinayagar Temple',
      latitude: 79.8304,
      longitude: 11.9346,
    )!;
    expect(
      uri.toString(),
      'https://www.google.com/maps/dir/?api=1&destination=79.8304,11.9346',
    );
  });

  testWidgets('missing or zero coordinates hide the coordinates card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: Scaffold(body: TempleDetailBody(temple: _temple())),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: Scaffold(
          body: TempleDetailBody(temple: _temple(latitude: 0, longitude: 0)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.textContaining('0.0000'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: Scaffold(
          body: TempleDetailBody(
            temple: _temple(name: '   ', latitude: null, longitude: null),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Get Directions'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsNothing);
  });

  test('non-finite coordinates count as missing', () {
    expect(
      _temple(latitude: double.nan, longitude: 80).hasCoordinates,
      isFalse,
    );
    expect(
      _temple(latitude: 12, longitude: double.infinity).hasCoordinates,
      isFalse,
    );
    expect(
      _temple(latitude: double.negativeInfinity, longitude: 1).hasCoordinates,
      isFalse,
    );
    final stored = Temple.fromMap('nan-temple', {
      'name': 'NaN Temple',
      'latitude': double.nan,
      'longitude': double.infinity,
    });
    expect(stored.latitude, isNull);
    expect(stored.longitude, isNull);
    expect(stored.hasCoordinates, isFalse);
  });

  testWidgets('non-finite coordinates hide the card and keep name directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: Scaffold(
          body: TempleDetailBody(
            temple: _temple(latitude: double.nan, longitude: double.nan),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Temple _temple({
  double? latitude,
  double? longitude,
  String name = 'Shore Temple',
}) {
  return Temple(
    name: name,
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: 'Mahabalipuram, Tamil Nadu',
    timings: '',
    specialities: const [],
    latitude: latitude,
    longitude: longitude,
  );
}
