import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/near_me/nearby_temples.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Home opens the rationale before any location request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(templesLoader: () async => [_sample().first]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(NearMeCopy.title), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-near-me')));
    await tester.pumpAndSettle();

    expect(find.text(NearMeCopy.rationaleBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-continue')), findsOneWidget);
    expect(find.byType(TemplesNearMeScreen), findsOneWidget);
  });

  testWidgets('granted permission shows the list sorted by kilometres', (
    tester,
  ) async {
    final location = FakeCoarseLocation(
      permission: CoarsePermission.denied,
      afterRequest: CoarsePermission.granted,
      fix: const CoarseFix(latitude: 9.9195, longitude: 78.1193),
    );
    await _pumpNearMe(tester, location: location);

    expect(find.byKey(const Key('near-me-rationale')), findsOneWidget);
    expect(location.requests, 0);
    expect(location.fixes, 0);

    await _continue(tester);

    expect(location.requests, 1);
    expect(location.fixes, 1);
    expect(find.text(NearMeCopy.nearestHeading), findsOneWidget);
    expect(_rowNames(tester).first, 'Meenakshi Amman Temple');
    expect(find.text('0.0 km'), findsOneWidget);
    expect(
      _rowNames(tester).indexOf('Meenakshi Amman Temple'),
      lessThan(_rowNames(tester).indexOf('Somnath Temple')),
    );
  });

  testWidgets('a denial offers a state or city sort and can retry', (
    tester,
  ) async {
    final location = FakeCoarseLocation(
      permission: CoarsePermission.denied,
      afterRequest: CoarsePermission.denied,
    );
    await _pumpNearMe(tester, location: location);
    await _continue(tester);

    expect(location.requests, 1);
    expect(location.fixes, 0);
    expect(find.text(NearMeCopy.deniedBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-enable-location')), findsOneWidget);
    expect(find.byKey(const Key('near-me-open-settings')), findsNothing);
    expect(find.byKey(const Key('near-me-district')), findsNothing);

    await _pick(
      tester,
      const Key('near-me-state'),
      'near-me-state-option-Tamil Nadu',
    );
    expect(find.text(NearMeCopy.sortedFrom('Tamil Nadu')), findsOneWidget);
    final byState = _rowNames(tester);
    expect(
      byState.indexOf('Meenakshi Amman Temple'),
      lessThan(byState.indexOf('Somnath Temple')),
    );
    expect(find.byKey(const Key('near-me-km-meenakshi')), findsOneWidget);

    await _pick(
      tester,
      const Key('near-me-city'),
      'near-me-city-option-Madurai',
    );
    expect(
      find.text(NearMeCopy.sortedFrom('Madurai, Tamil Nadu')),
      findsOneWidget,
    );
    expect(_rowNames(tester).first, 'Meenakshi Amman Temple');
    expect(find.text('0.0 km'), findsOneWidget);

    location.afterRequest = CoarsePermission.granted;
    location.fix = const CoarseFix(latitude: 9.9195, longitude: 78.1193);
    await tester.tap(find.byKey(const Key('near-me-enable-location')));
    await tester.pumpAndSettle();

    expect(location.requests, 2);
    expect(find.text(NearMeCopy.nearestHeading), findsOneWidget);
    expect(_rowNames(tester).first, 'Meenakshi Amman Temple');
  });

  testWidgets('a permanent denial offers Open settings and the place list', (
    tester,
  ) async {
    final location = FakeCoarseLocation(
      permission: CoarsePermission.deniedForever,
    );
    await _pumpNearMe(tester, location: location);
    await _continue(tester);

    expect(location.requests, 0);
    expect(location.fixes, 0);
    expect(find.text(NearMeCopy.deniedForeverBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-open-settings')), findsOneWidget);
    expect(find.byKey(const Key('near-me-enable-location')), findsNothing);

    await tester.tap(find.byKey(const Key('near-me-open-settings')));
    await tester.pump();
    expect(location.appSettings, 1);

    await _pick(
      tester,
      const Key('near-me-state'),
      'near-me-state-option-Gujarat',
    );
    expect(find.text(NearMeCopy.sortedFrom('Gujarat')), findsOneWidget);
    expect(_rowNames(tester).first, 'Somnath Temple');
  });

  testWidgets('location services off show the fallback and a retry', (
    tester,
  ) async {
    final location = FakeCoarseLocation(serviceEnabled: false);
    await _pumpNearMe(tester, location: location);
    await _continue(tester);

    expect(location.requests, 0);
    expect(location.fixes, 0);
    expect(find.text(NearMeCopy.serviceOffBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-retry')), findsOneWidget);
    expect(find.byKey(const Key('near-me-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('near-me-open-location-settings')));
    await tester.pump();
    expect(location.locationSettings, 1);

    location.serviceEnabled = true;
    location.permission = CoarsePermission.granted;
    location.fix = const CoarseFix(latitude: 20.888, longitude: 70.4012);
    await tester.tap(find.byKey(const Key('near-me-retry')));
    await tester.pumpAndSettle();

    expect(location.fixes, 1);
    expect(find.text(NearMeCopy.nearestHeading), findsOneWidget);
    expect(_rowNames(tester).first, 'Somnath Temple');
  });

  testWidgets('a timeout shows the fallback and a retry', (tester) async {
    final location = FakeCoarseLocation(
      permission: CoarsePermission.granted,
      failure: const LocationFailure(LocationFailureKind.timeout),
    );
    await _pumpNearMe(tester, location: location);
    await _continue(tester);

    expect(location.requests, 0);
    expect(location.fixes, 1);
    expect(find.text(NearMeCopy.timedOutBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-retry')), findsOneWidget);
    expect(find.byKey(const Key('near-me-open-settings')), findsNothing);

    location.failure = null;
    location.fix = const CoarseFix(latitude: 22.6548, longitude: 88.3575);
    await tester.tap(find.byKey(const Key('near-me-retry')));
    await tester.pumpAndSettle();

    expect(location.fixes, 2);
    expect(_rowNames(tester).first, 'Dakshineswar Kali Temple');
    expect(find.text('0.0 km'), findsOneWidget);
  });

  testWidgets('not now keeps location unread and still sorts by a place', (
    tester,
  ) async {
    final location = FakeCoarseLocation();
    await _pumpNearMe(tester, location: location);

    await tester.tap(find.byKey(const Key('near-me-not-now')));
    await tester.pumpAndSettle();

    expect(location.requests, 0);
    expect(location.fixes, 0);
    expect(find.text(NearMeCopy.declinedBody), findsOneWidget);
    expect(find.byKey(const Key('near-me-use-location')), findsOneWidget);

    await tester.tap(find.byKey(const Key('near-me-use-location')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('near-me-rationale')), findsOneWidget);
    expect(location.requests, 0);
  });

  testWidgets('district sorting appears only when the lookup has names', (
    tester,
  ) async {
    final location = FakeCoarseLocation(
      permission: CoarsePermission.denied,
      afterRequest: CoarsePermission.denied,
    );
    await _pumpNearMe(
      tester,
      location: location,
      districtOf: (temple) {
        return switch (temple.id) {
          'jagannath' => 'Puri',
          'lingaraj' => 'Khordha',
          _ => null,
        };
      },
      temples: [
        _temple(
          id: 'jagannath',
          name: 'Jagannath Temple',
          state: 'Odisha',
          city: 'Puri',
          lat: 19.8049,
          lng: 85.8179,
        ),
        _temple(
          id: 'lingaraj',
          name: 'Lingaraj Temple',
          state: 'Odisha',
          city: 'Bhubaneswar',
          lat: 20.2386,
          lng: 85.8336,
        ),
      ],
    );
    await _continue(tester);

    expect(find.byKey(const Key('near-me-district')), findsOneWidget);
    await _pick(
      tester,
      const Key('near-me-district'),
      'near-me-district-option-Puri',
    );
    expect(find.text(NearMeCopy.sortedFrom('Puri')), findsOneWidget);
    expect(_rowNames(tester).first, 'Jagannath Temple');
    expect(find.byKey(const Key('near-me-km-jagannath')), findsOneWidget);
  });
}

Future<void> _pumpNearMe(
  WidgetTester tester, {
  required FakeCoarseLocation location,
  TempleDistrictLookup? districtOf,
  List<Temple>? temples,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TemplesNearMeScreen(
        temples: temples ?? _sample(),
        location: location,
        districtOf: districtOf ?? indexDistrictName,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('near-me-continue')));
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, Key button, String optionKey) async {
  await tester.tap(find.byKey(button));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(optionKey)));
  await tester.pumpAndSettle();
}

List<String> _rowNames(WidgetTester tester) {
  return tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => (tile.title as Text?)?.data)
      .whereType<String>()
      .toList();
}

List<Temple> _sample() {
  return [
    _temple(
      id: 'meenakshi',
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      lat: 9.9195,
      lng: 78.1193,
    ),
    _temple(
      id: 'kapaleeshwarar',
      name: 'Kapaleeshwarar Temple',
      state: 'Tamil Nadu',
      city: 'Chennai',
      lat: 13.0338,
      lng: 80.2619,
    ),
    _temple(
      id: 'somnath',
      name: 'Somnath Temple',
      state: 'Gujarat',
      city: 'Veraval',
      lat: 20.888,
      lng: 70.4012,
    ),
    _temple(
      id: 'dakshineswar',
      name: 'Dakshineswar Kali Temple',
      state: 'West Bengal',
      city: 'Kolkata',
      lat: 22.6548,
      lng: 88.3575,
    ),
  ];
}

Temple _temple({
  required String id,
  required String name,
  required String state,
  required String city,
  required double lat,
  required double lng,
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: city,
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: '$city, $state',
    timings: null,
    specialities: const [],
    latitude: lat,
    longitude: lng,
  );
}

class FakeCoarseLocation implements CoarseLocationClient {
  FakeCoarseLocation({
    this.serviceEnabled = true,
    this.permission = CoarsePermission.denied,
    this.afterRequest = CoarsePermission.granted,
    this.fix = const CoarseFix(latitude: 0, longitude: 0),
    this.failure,
  });

  bool serviceEnabled;
  CoarsePermission permission;
  CoarsePermission afterRequest;
  CoarseFix fix;
  LocationFailure? failure;
  int requests = 0;
  int fixes = 0;
  int appSettings = 0;
  int locationSettings = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<CoarsePermission> checkPermission() async => permission;

  @override
  Future<CoarsePermission> requestPermission() async {
    requests += 1;
    permission = afterRequest;
    return permission;
  }

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    fixes += 1;
    final failure = this.failure;
    if (failure != null) throw failure;
    return fix;
  }

  @override
  Future<void> openAppSettings() async {
    appSettings += 1;
  }

  @override
  Future<void> openLocationSettings() async {
    locationSettings += 1;
  }
}
