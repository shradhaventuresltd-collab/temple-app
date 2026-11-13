import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/pin_precision_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/admin_temple_service.dart';

Temple _temple({
  String? pinPrecision,
  String? pinOrigin,
  double? latitude = 25.6111,
  double? longitude = 85.1372,
  String? timings,
}) {
  return Temple(
    id: 'example-temple',
    name: 'Example Temple',
    state: 'Bihar',
    city: 'Patna',
    deity: 'Shiva',
    imageUrl: '',
    description: 'A shrine in Patna.',
    story: 'A shrine in Patna.',
    location: 'Patna, Bihar',
    timings: timings,
    specialities: const ['River bank'],
    latitude: latitude,
    longitude: longitude,
    pinPrecision: pinPrecision,
    pinOrigin: pinOrigin,
  );
}

Map<String, dynamic> _doc({
  Object? pinPrecision = 'approx',
  Object? pinOrigin = 'village_centroid',
}) => {
  'id': 'example-temple',
  'name': 'Example Temple',
  'state': 'Bihar',
  'city': 'Patna',
  'deity': 'Shiva',
  'imageUrl': '',
  'description': 'A shrine in Patna.',
  'story': 'A shrine in Patna.',
  'address': 'Patna, Bihar',
  'timings': null,
  'specialities': ['River bank'],
  'images': <String>[],
  'latitude': 25.6111,
  'longitude': 85.1372,
  'pinPrecision': pinPrecision,
  'pinOrigin': pinOrigin,
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Temple pin fields', () {
    test('fromMap reads approx + origin and treats missing as exact', () {
      final approx = Temple.fromMap('example-temple', _doc());
      expect(approx.pinPrecision, 'approx');
      expect(approx.pinOrigin, 'village_centroid');
      expect(approx.hasApproximatePin, isTrue);

      final exact = Temple.fromMap('example-temple', _doc(pinPrecision: null, pinOrigin: null));
      expect(exact.pinPrecision, isNull);
      expect(exact.pinOrigin, isNull);
      expect(exact.hasApproximatePin, isFalse);
    });

    test('fromMap ignores illegal enum values', () {
      final t = Temple.fromMap(
        'example-temple',
        _doc(pinPrecision: 'exact', pinOrigin: 'britannica'),
      );
      expect(t.pinPrecision, isNull);
      expect(t.pinOrigin, isNull);
      expect(pinPrecisionField('approx'), 'approx');
      expect(pinPrecisionField('exact'), isNull);
      expect(pinPrecisionField(1), isNull);
      expect(pinOriginField('osm'), 'osm');
      expect(pinOriginField('google_maps'), 'google_maps');
      expect(pinOriginField('wikipedia'), 'wikipedia');
      expect(pinOriginField('britannica'), isNull);
    });

    test('toFirestoreData writes only when set, and CMS allow-list accepts them', () {
      final payload = _temple(
        pinPrecision: 'approx',
        pinOrigin: 'village_centroid',
        timings: '6:00 AM – 6:00 PM',
      ).toFirestoreData(documentId: 'example-temple');
      expect(payload['pinPrecision'], 'approx');
      expect(payload['pinOrigin'], 'village_centroid');
      expect(kTempleFirestoreAllowedFields, containsAll(['pinPrecision', 'pinOrigin']));
      expect(
        () => assertTemplePayloadValidForRules(payload),
        returnsNormally,
      );

      final exact = _temple().toFirestoreData(documentId: 'example-temple');
      expect(exact.containsKey('pinPrecision'), isFalse);
      expect(exact.containsKey('pinOrigin'), isFalse);
    });

    test('hasApproximatePin is false without coordinates', () {
      final t = _temple(
        pinPrecision: 'approx',
        pinOrigin: 'osm',
        latitude: null,
        longitude: null,
      );
      expect(t.hasApproximatePin, isFalse);
    });
  });

  group('index entry', () {
    test('stores pinPrecision only when approx, never pinOrigin', () {
      final approx = templeIndexEntryFromMap('example-temple', _doc());
      expect(approx['pinPrecision'], 'approx');
      expect(approx.containsKey('pinOrigin'), isFalse);
      final fromIndex = templeFromIndexEntry(approx);
      expect(fromIndex.pinPrecision, 'approx');
      expect(fromIndex.hasApproximatePin, isTrue);
      expect(fromIndex.pinOrigin, isNull);

      final exact = templeIndexEntryFromMap(
        'example-temple',
        _doc(pinPrecision: null, pinOrigin: 'osm'),
      );
      expect(exact.containsKey('pinPrecision'), isFalse);
      expect(templeFromIndexEntry(exact).hasApproximatePin, isFalse);
    });
  });

  group('copy', () {
    test('Near Me uses a tilde only for approximate pins', () {
      expect(NearMeCopy.distanceLabel(3.2), '3.2 km');
      expect(NearMeCopy.distanceLabel(3.2, approximate: true), '~3.2 km');
      expect(NearMeCopy.distanceLabel(12.6), '13 km');
      expect(NearMeCopy.distanceLabel(12.6, approximate: true), '~13 km');
      expect(
        NearMeCopy.distanceLabel(3.2, approximate: true),
        PinPrecisionStrings.approximateDistanceKm('3.2'),
      );
    });
  });

  testWidgets('detail screen shows Approximate location near directions', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: TempleDetailScreen(
          temple: _temple(
            pinPrecision: 'approx',
            pinOrigin: 'village_centroid',
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.byKey(const Key('detail-approximate-location')), findsOneWidget);
    expect(find.text(PinPrecisionStrings.approximateLocation), findsOneWidget);
  });

  testWidgets('detail screen hides the note for an exact pin', (t) async {
    await t.pumpWidget(
      MaterialApp(home: TempleDetailScreen(temple: _temple())),
    );
    await t.pump();
    expect(find.byKey(const Key('detail-approximate-location')), findsNothing);
  });
}
