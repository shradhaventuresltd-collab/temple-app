import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_attribution.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/screens/licences_screen.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';

Temple _temple({
  required String name,
  required String state,
  required String city,
  required String deity,
  double latitude = 0,
  double longitude = 0,
}) {
  return Temple(
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: '',
    location: '$city, $state',
    timings: '',
    specialities: const [],
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final temples = [
    _temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
      latitude: 9.9195,
      longitude: 78.1193,
    ),
    _temple(
      name: 'Shore Temple',
      state: 'Tamil Nadu',
      city: 'Mahabalipuram',
      deity: 'Shiva',
      latitude: 12.6167,
      longitude: 80.1918,
    ),
    _temple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
      latitude: 9.75,
      longitude: 76.4,
    ),
  ];

  String? districtOf(Temple temple) {
    return switch (temple.name) {
      'Meenakshi Amman Temple' => 'Madurai',
      'Shore Temple' => 'Chengalpattu',
      'Vaikom Mahadeva Temple' => 'Kottayam',
      _ => null,
    };
  }

  Future<void> pumpBar(
    WidgetTester tester, {
    String? state,
    String? deity,
    String? district,
    String? Function(Temple temple)? lookup,
    Future<String? Function(Temple temple)> Function()? prepare,
    String query = '',
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectoryFilterBar(
            temples: temples,
            query: query,
            selectedState: state,
            selectedDeity: deity,
            selectedDistrict: district,
            districtOf: lookup,
            prepareDistricts: prepare,
            onChanged: (_, _, _) {},
          ),
        ),
      ),
    );
  }

  test('district names follow the selected state', () {
    expect(directoryDistrictsFrom(temples, districtOf: districtOf), [
      'Chengalpattu',
      'Kottayam',
      'Madurai',
    ]);
    expect(
      directoryDistrictsFrom(
        temples,
        state: 'Tamil Nadu',
        districtOf: districtOf,
      ),
      ['Chengalpattu', 'Madurai'],
    );
    expect(
      directoryBrowseTitle(
        state: 'Tamil Nadu',
        deity: 'Devi',
        district: 'Madurai',
      ),
      'Devi · Madurai · Tamil Nadu',
    );
    expect(
      directoryMatchingTemples(
        temples,
        state: 'Tamil Nadu',
        deity: 'Devi',
        district: 'Madurai',
        districtOf: districtOf,
      ).map((temple) => temple.name),
      ['Meenakshi Amman Temple'],
    );
  });

  testWidgets('the district chip stays hidden until a name resolves', (
    tester,
  ) async {
    await pumpBar(tester, lookup: (_) => null);
    expect(find.byKey(const Key('filter-chip-district')), findsNothing);
    expect(find.text('All districts'), findsNothing);
  });

  testWidgets('All districts is the default before the asset loads', (
    tester,
  ) async {
    await pumpBar(tester);
    expect(find.text('All districts'), findsOneWidget);
    expect(find.byKey(const Key('filter-chip-district')), findsOneWidget);
  });

  testWidgets('state and deity chips do not load districts', (tester) async {
    var loads = 0;
    await pumpBar(
      tester,
      prepare: () async {
        loads += 1;
        return districtOf;
      },
    );

    await tester.tap(find.byKey(const Key('filter-chip-state')));
    await tester.pumpAndSettle();
    expect(loads, 0);
    expect(find.text('DISTRICT'), findsNothing);
    expect(find.text('District'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-sheet-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-chip-deity')));
    await tester.pumpAndSettle();
    expect(loads, 0);
    expect(find.text('DISTRICT'), findsNothing);
  });

  testWidgets('the district chip loads, lists, and combines filters', (
    tester,
  ) async {
    String? state;
    String? deity;
    String? district;
    var loads = 0;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              final visible = directoryMatchingTemples(
                temples,
                state: state,
                deity: deity,
                district: district,
                districtOf: loads == 0 ? null : districtOf,
              );
              return Column(
                children: [
                  DirectoryFilterBar(
                    temples: temples,
                    selectedState: state,
                    selectedDeity: deity,
                    selectedDistrict: district,
                    districtOf: loads == 0 ? null : districtOf,
                    prepareDistricts: () async {
                      loads += 1;
                      return districtOf;
                    },
                    onChanged: (nextState, nextDeity, nextDistrict) {
                      setState(() {
                        state = nextState;
                        deity = nextDeity;
                        district = nextDistrict;
                      });
                    },
                  ),
                  for (final temple in visible) Text(temple.name),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.text('DISTRICT'), findsOneWidget);
    expect(find.byKey(const Key('filter-option-district-any')), findsOneWidget);
    expect(find.text('All districts'), findsWidgets);
    expect(
      find.byKey(const Key('filter-option-district-Madurai')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter-option-district-Kottayam')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('filter-option-state-Tamil Nadu')));
    await tester.pump();
    expect(
      find.byKey(const Key('filter-option-district-Kottayam')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('filter-option-district-Madurai')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-option-deity-Devi')));
    await tester.pump();
    expect(find.text('Show 1 temple'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Shore Temple'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsNothing);
    expect(find.text('Madurai'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-chip-district')));
    await tester.pumpAndSettle();
    expect(loads, 1);
    await tester.tap(find.byKey(const Key('filter-option-deity-any')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    expect(
      find.byKey(const Key('filter-option-district-Madurai')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('filter-sheet-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-clear')));
    await tester.pump();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Shore Temple'), findsOneWidget);
    expect(find.text('All districts'), findsOneWidget);
  });

  testWidgets('an empty district combination can be cleared', (tester) async {
    String? district = 'Madurai';
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              final visible = directoryMatchingTemples(
                temples,
                deity: 'Shiva',
                district: district,
                query: 'vaikom',
                districtOf: districtOf,
              );
              return Column(
                children: [
                  DirectoryFilterBar(
                    temples: temples,
                    selectedState: null,
                    selectedDeity: 'Shiva',
                    selectedDistrict: district,
                    query: 'vaikom',
                    districtOf: districtOf,
                    onChanged: (_, _, nextDistrict) {
                      setState(() => district = nextDistrict);
                    },
                  ),
                  if (visible.isEmpty)
                    Text(directoryEmptyFilterMessage(district: district)),
                  TextButton(
                    key: const Key('filter-empty-clear'),
                    onPressed: () => setState(() => district = null),
                    child: const Text('Clear filters'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Nothing in the loaded directory fits this state, district, and deity.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('filter-empty-clear')));
    await tester.pump();
    expect(
      find.text(
        'Nothing in the loaded directory fits this state, district, and deity.',
      ),
      findsNothing,
    );
  });

  testWidgets('licences do not pin a district licence', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LicencesScreen()));
    expect(find.text(kDistrictBoundarySourceName), findsOneWidget);
    expect(find.text(kDistrictBoundaryLicence), findsOneWidget);
    expect(find.text(kDistrictBoundaryAttribution), findsOneWidget);
    expect(find.textContaining('Not bundled'), findsWidgets);
    expect(find.textContaining('CC-BY-4.0 requires'), findsNothing);
    expect(find.text('CC0-1.0 / CC-BY-4.0'), findsNothing);
    expect(
      find.textContaining(kDistrictBoundaryDatasetVersion),
      findsOneWidget,
    );
    expect(
      find.textContaining(kDistrictBoundarySourceUpdated),
      findsOneWidget,
    );
  });

  testWidgets('near me does not load a boundary asset when none is bundled', (
    tester,
  ) async {
    DistrictDirectory.instance.resetForTest();
    addTearDown(DistrictDirectory.instance.resetForTest);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final location = FakeCoarseLocation(
      permission: CoarsePermission.denied,
      afterRequest: CoarsePermission.denied,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TemplesNearMeScreen(temples: [temples.first], location: location),
      ),
    );
    await tester.pumpAndSettle();
    expect(DistrictDirectory.instance.assetLoadCount, 0);
    await tester.tap(find.byKey(const Key('near-me-not-now')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('near-me-district')), findsNothing);
    expect(DistrictDirectory.instance.assetLoadCount, 0);
    expect(DistrictDirectory.instance.peek(temples.first), isNull);
  });
}

class FakeCoarseLocation implements CoarseLocationClient {
  FakeCoarseLocation({required this.permission, required this.afterRequest});

  CoarsePermission permission;
  final CoarsePermission afterRequest;

  @override
  Future<CoarsePermission> checkPermission() async => permission;

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return const CoarseFix(latitude: 9.9195, longitude: 78.1193);
  }

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<CoarsePermission> requestPermission() async {
    permission = afterRequest;
    return afterRequest;
  }
}
