// Satyavrat's follow-up from PR #142: the Near Me tradition chip must keep
// an approximate-pin row, with its "~x km" label and the places copy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/pin_precision_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';

import 'filter_sheet_support.dart';

Temple _place({
  required String id,
  required String name,
  required String city,
  required String state,
  required String deity,
  required double lat,
  required double lng,
  String? tradition,
  String? pinPrecision,
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: '',
    location: '$city, $state',
    timings: null,
    specialities: const [],
    latitude: lat,
    longitude: lng,
    tradition: tradition,
    pinPrecision: pinPrecision,
    pinOrigin: pinPrecision == null ? null : 'village_centroid',
  );
}

class _GrantedLocation implements CoarseLocationClient {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<CoarsePermission> checkPermission() async => CoarsePermission.denied;

  @override
  Future<CoarsePermission> requestPermission() async =>
      CoarsePermission.granted;

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 20),
  }) async => const CoarseFix(latitude: 31.58, longitude: 74.80);

  @override
  Future<CoarseFix?> lastKnownFix() async => null;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'tradition chip keeps an approx-pin row with ~x km and places copy',
    (tester) async {
      useFilterSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: TemplesNearMeScreen(
            temples: [
              _place(
                id: 'golden-temple',
                name: 'Harmandir Sahib',
                city: 'Amritsar',
                state: 'Punjab',
                deity: 'Guru Granth Sahib',
                tradition: 'sikh',
                lat: 31.6200,
                lng: 74.8765,
                pinPrecision: 'approx',
              ),
              _place(
                id: 'durgiana',
                name: 'Durgiana Temple',
                city: 'Amritsar',
                state: 'Punjab',
                deity: 'Durga',
                lat: 31.6328,
                lng: 74.8678,
              ),
            ],
            location: _GrantedLocation(),
            districtOf: (temple) => temple.city,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('near-me-continue')));
      await tester.pumpAndSettle();

      expect(find.text(NearMeCopy.nearestHeading), findsOneWidget);
      expect(find.byKey(const Key('near-me-row-durgiana')), findsOneWidget);
      final approxKm = find.byKey(const Key('near-me-km-golden-temple'));
      final before = tester.widget<Text>(approxKm).data;

      await tester.tap(find.byKey(const Key('near-me-tradition-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-option-tradition-sikh')));
      await tester.pumpAndSettle();

      // Filtered to the Sikh row only; the approximate pin is not dropped.
      expect(
        find.byKey(const Key('near-me-row-golden-temple')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('near-me-row-durgiana')), findsNothing);
      expect(find.text('Harmandir Sahib'), findsOneWidget);

      // Same "~x km" label as before the filter.
      final after = tester.widget<Text>(approxKm).data!;
      expect(after, before);
      expect(after, matches(RegExp(r'^~\d+(\.\d)? km$')));
      expect(after, isNot('~0.0 km'));
      expect(
        after,
        startsWith(PinPrecisionStrings.approximateDistanceKm('')[0]),
      );

      // Places copy, not temples.
      expect(find.text(NearMeCopy.title), findsOneWidget);
      expect(find.text('Places near me'), findsOneWidget);
      expect(find.text('Nearest places'), findsOneWidget);
      expect(find.textContaining('Temples near me'), findsNothing);
      expect(find.textContaining('Nearest temples'), findsNothing);
      expect(find.byKey(const Key('near-me-empty')), findsNothing);
    },
  );
}
