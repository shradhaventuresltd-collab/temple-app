import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/district/district_overrides.dart';
import 'package:temple_app/models/temple.dart';

Future<Uint8List> _syntheticBoundaries() async {
  return Uint8List.fromList(
    File('test/fixtures/synthetic_districts.dsb').readAsBytesSync(),
  );
}

Temple _temple({
  String id = '',
  String name = 'Meenakshi Amman Temple',
  String state = 'Tamil Nadu',
  double latitude = 9.9195,
  double longitude = 78.1193,
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: '',
    story: '',
    location: 'Madurai',
    timings: '',
    specialities: const [],
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => DistrictDirectory.instance.resetForTest(
      loadBytes: _syntheticBoundaries,
    ),
  );
  tearDown(DistrictDirectory.instance.resetForTest);

  test('district warm-up follows a flag, not the binding type name', () {
    final source = File('lib/district/district_lookup.dart').readAsStringSync();
    expect(source.contains('TestWidgetsFlutterBinding'), isFalse);
    expect(source.contains('runtimeType'), isFalse);

    final previous = debugWarmDirectoryDistricts;
    addTearDown(() => debugWarmDirectoryDistricts = previous);
    debugWarmDirectoryDistricts = false;
    expect(shouldWarmDirectoryDistricts, isFalse);
    debugWarmDirectoryDistricts = true;
    expect(shouldWarmDirectoryDistricts, districtBoundariesAreBundled);
  });

  test('assignments stay in memory and skip a second asset load', () async {
    final directory = DistrictDirectory.instance;
    final temple = _temple(id: 'meenakshi');
    expect(directory.peek(temple), isNull);

    await directory.ensureFor([
      temple,
      _temple(name: 'No point', latitude: 0, longitude: 0),
    ]);
    expect(directory.peek(temple), 'Madurai');
    expect(directory.assetLoadCount, 1);

    await directory.ensureFor([temple]);
    expect(directory.assetLoadCount, 1);

    final moved = _temple(
      id: 'meenakshi',
      state: 'Puducherry',
      latitude: 10.92,
      longitude: 79.83,
    );
    await directory.ensureFor([moved]);
    expect(directory.peek(moved), 'Karaikal');
    expect(directory.assetLoadCount, 2);
    expect(directory.peek(temple), isNull);

    final otherState = _temple(
      id: 'meenakshi-tamil',
      state: 'Tamil Nadu',
      latitude: 10.92,
      longitude: 79.83,
    );
    await directory.ensureFor([otherState]);
    expect(directory.peek(otherState), isNull);
    expect(directory.peek(moved), 'Karaikal');
  });

  test('the preferences key is only the boundary asset version', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = DistrictDirectory.instance;
    directory.resetForTest(
      store: PrefsDistrictAssignmentStore(),
      loadBytes: _syntheticBoundaries,
    );
    await directory.ensureFor([_temple(id: 'meenakshi')]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {
      districtAssignmentCacheKey(kDistrictBoundaryAssetVersion),
    });
    final raw = prefs.getString(
      districtAssignmentCacheKey(kDistrictBoundaryAssetVersion),
    );
    expect(raw, isNotNull);
    expect(raw, isNot(contains('indexVersion')));
    expect(raw, isNot(contains('temple_index')));

    directory.resetForTest(
      store: PrefsDistrictAssignmentStore(),
      loadBytes: _syntheticBoundaries,
    );
    expect(directory.assetLoadCount, 0);
    await directory.ensureFor([_temple(id: 'meenakshi')]);
    expect(directory.peek(_temple(id: 'meenakshi')), 'Madurai');
    expect(directory.assetLoadCount, 0);
  });

  test('overrides publish without reading the boundary asset', () async {
    DistrictDirectory.instance.resetForTest();
    final directory = DistrictDirectory.instance;
    final sita = _temple(
      id: 'sita-ramachandra-swamy-temple',
      name: 'Sita Ramachandra Swamy Temple',
      state: 'Telangana',
      latitude: 17.6669,
      longitude: 80.8828,
    );
    final malinithan = _temple(
      id: 'malinithan',
      name: 'Malinithan',
      state: 'Arunachal Pradesh',
      latitude: 27.6567,
      longitude: 94.7058,
    );
    await directory.ensureFor([sita, malinithan]);
    expect(directory.assetLoadCount, 0);
    expect(directory.isReady, isTrue);
    expect(directory.peek(sita), 'Bhadradri Kothagudem');
    expect(directory.peek(malinithan), 'Lower Siang');
    expect(districtOverrideFor(sita)?.name, 'Bhadradri Kothagudem');
    expect(districtOverrideFor(malinithan)?.name, 'Lower Siang');
    expect(
      districtOverrideFor(
        _temple(
          id: 'sita-ramachandra-swamy-temple',
          state: 'Andhra Pradesh',
          latitude: 17.6669,
          longitude: 80.8828,
        ),
      ),
      isNull,
    );
  });

  test('overrides stay unpublished when boundaries are not bundled', () async {
    debugDistrictBoundariesBundled = false;
    addTearDown(() => debugDistrictBoundariesBundled = null);
    DistrictDirectory.instance.resetForTest();
    final directory = DistrictDirectory.instance;
    final sita = _temple(
      id: 'sita-ramachandra-swamy-temple',
      name: 'Sita Ramachandra Swamy Temple',
      state: 'Telangana',
      latitude: 17.6669,
      longitude: 80.8828,
    );
    final malinithan = _temple(
      id: 'malinithan',
      name: 'Malinithan',
      state: 'Arunachal Pradesh',
      latitude: 27.6567,
      longitude: 94.7058,
    );
    await directory.ensureFor([sita, malinithan]);
    expect(directory.assetLoadCount, 0);
    expect(directory.isReady, isFalse);
    expect(directory.peek(sita), isNull);
    expect(directory.peek(malinithan), isNull);
  });

  test('an override beats a polygon in another state', () async {
    final directory = DistrictDirectory.instance;
    final sita = _temple(
      id: 'sita-ramachandra-swamy-temple',
      name: 'Sita Ramachandra Swamy Temple',
      state: 'Telangana',
      latitude: 9.9195,
      longitude: 78.1193,
    );
    await directory.ensureFor([sita]);
    expect(directory.peek(sita), 'Bhadradri Kothagudem');
    expect(directory.assetLoadCount, 0);
  });

  test('a preferences failure still keeps the in-memory district', () async {
    final directory = DistrictDirectory.instance;
    directory.resetForTest(
      store: _BrokenStore(),
      loadBytes: _syntheticBoundaries,
    );
    final temple = _temple();
    await directory.ensureFor([temple]);
    expect(directory.peek(temple), 'Madurai');
  });
}

class _BrokenStore implements DistrictAssignmentStore {
  @override
  Future<List<DistrictAssignment>?> read(String assetVersion) async {
    throw StateError('preferences unavailable');
  }

  @override
  Future<void> write(String assetVersion, List<DistrictAssignment> rows) async {
    throw StateError('preferences unavailable');
  }
}
