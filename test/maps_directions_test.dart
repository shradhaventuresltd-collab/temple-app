import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('maps query includes the temple name', () {
    final uri = googleMapsSearchUri(
      name: 'Shore Temple',
      latitude: 12.6,
      longitude: 80.1,
    );
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], 'Shore Temple 12.6,80.1');
  });

  testWidgets('missing or zero coordinates hide directions and the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _temple())),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _temple(latitude: 0, longitude: 0)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsNothing);
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

  testWidgets('non-finite coordinates hide directions and the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: _temple(latitude: double.nan, longitude: double.nan),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Coordinates'), findsNothing);
    expect(find.text('Get Directions'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Temple _temple({double? latitude, double? longitude}) {
  return Temple(
    name: 'Shore Temple',
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
