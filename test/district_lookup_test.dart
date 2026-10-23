import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple.dart';

Temple _temple({
  String id = '',
  String name = 'Meenakshi Amman Temple',
  double latitude = 9.9195,
  double longitude = 78.1193,
}) {
  return Temple(
    id: id,
    name: name,
    state: 'Tamil Nadu',
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

  setUp(DistrictDirectory.instance.resetForTest);
  tearDown(DistrictDirectory.instance.resetForTest);

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

    final moved = _temple(id: 'meenakshi', latitude: 10.92, longitude: 79.83);
    await directory.ensureFor([moved]);
    expect(directory.peek(moved), 'Karaikal');
    expect(directory.assetLoadCount, 2);
    expect(directory.peek(temple), isNull);
  });

  test('the preferences key is only the boundary asset version', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = DistrictDirectory.instance;
    directory.resetForTest(store: PrefsDistrictAssignmentStore());
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

    directory.resetForTest(store: PrefsDistrictAssignmentStore());
    expect(directory.assetLoadCount, 0);
    await directory.ensureFor([_temple(id: 'meenakshi')]);
    expect(directory.peek(_temple(id: 'meenakshi')), 'Madurai');
    expect(directory.assetLoadCount, 0);
  });

  test('a preferences failure still keeps the in-memory district', () async {
    final directory = DistrictDirectory.instance;
    directory.resetForTest(store: _BrokenStore());
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
