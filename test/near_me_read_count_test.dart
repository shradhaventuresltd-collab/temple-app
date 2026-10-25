import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/near_me_session.dart';
import 'package:temple_app/near_me/nearby_temples.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/index_stamp_store.dart';
import 'package:temple_app/services/temple_directory_client.dart';
import 'package:temple_app/services/temple_service.dart';

/// meta/temple_index plus one shard per state. Near me must not add a read.
const _shardCount = 33;
const _stamp = 1760000000000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TempleService.resetSessionForTest();
    DistrictDirectory.instance.resetForTest();
  });
  tearDown(() {
    TempleService.resetSessionForTest();
    DistrictDirectory.instance.resetForTest();
  });

  test('cold stays at 34 reads and warm stays at 1', () async {
    final cold = _harness(applied: false);
    final coldRows = await cold.service.getTemples();
    expect(coldRows, hasLength(_shardCount));
    expect(cold.log.serverReads, 1 + _shardCount);
    expect(
      cold.fake.gets.where((get) => get == 'server:meta/temple_index'),
      hasLength(1),
    );
    expect(
      cold.fake.gets.where((get) => get.startsWith('server:temple_index/')),
      hasLength(_shardCount),
    );
    expect(cold.fake.gets.where((get) => get.contains('temples')), isEmpty);

    final coldGets = List<String>.of(cold.fake.gets);
    final coldSorted = sortTemplesByDistance(
      coldRows,
      latitude: 8,
      longitude: 77,
    );
    expect(coldSorted.first.temple.id, 'state-00');
    expect(cold.log.serverReads, 34);
    expect(cold.fake.gets, coldGets);

    final coldSession = NearMeSession(
      temples: coldRows,
      location: _FixedLocation(const CoarseFix(latitude: 8, longitude: 77)),
    );
    await coldSession.acceptRationale();
    expect(coldSession.rows.first.temple.id, 'state-00');
    expect(cold.log.serverReads, 34);
    expect(cold.fake.gets, coldGets);

    final warm = _harness(applied: true);
    final warmRows = await warm.service.getTemples();
    expect(warmRows, hasLength(_shardCount));
    expect(warm.log.serverReads, 0);
    await warm.service.flushBackgroundForTest();
    expect(warm.log.serverReads, 1);
    expect(
      warm.fake.gets.where((get) => get == 'server:meta/temple_index'),
      hasLength(1),
    );
    expect(
      warm.fake.gets.where((get) => get.startsWith('server:temple_index/')),
      isEmpty,
    );
    expect(warm.fake.gets.where((get) => get.contains('temples')), isEmpty);

    final warmGets = List<String>.of(warm.fake.gets);
    final warmSorted = sortTemplesByDistance(
      warmRows,
      latitude: 8,
      longitude: 77,
    );
    expect(warmSorted.first.temple.id, 'state-00');
    final warmSession = NearMeSession(
      temples: warmRows,
      location: _FixedLocation(const CoarseFix(latitude: 40, longitude: 77)),
    );
    await warmSession.acceptRationale();
    expect(warmSession.rows.first.temple.id, 'state-32');
    expect(warm.log.serverReads, 1);
    expect(warm.fake.gets, warmGets);

    await DistrictDirectory.instance.ensureFor(coldRows);
    expect(cold.log.serverReads, 34);
    expect(cold.fake.gets, coldGets);
    await DistrictDirectory.instance.ensureFor(warmRows);
    expect(warm.log.serverReads, 1);
    expect(warm.fake.gets, warmGets);
  });
}

class _FixedLocation implements CoarseLocationClient {
  _FixedLocation(this.fix);

  final CoarseFix fix;

  @override
  Future<CoarsePermission> checkPermission() async => CoarsePermission.granted;

  @override
  Future<CoarseFix?> lastKnownFix() async => null;

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 20),
  }) async => fix;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<CoarsePermission> requestPermission() async =>
      CoarsePermission.granted;
}

class _MemoryStamps implements IndexStampStore {
  _MemoryStamps(Map<String, int> initial) : stamps = Map.of(initial);

  final Map<String, int> stamps;

  @override
  Future<Map<String, int>> readApplied() async => Map.of(stamps);

  @override
  Future<void> writeApplied(String slug, int millis) async {
    stamps[slug] = millis;
  }
}

class _FakeDirectory implements TempleDirectoryClient {
  _FakeDirectory({required this.serverDocs, required this.cacheDocs});

  final Map<String, Map<String, dynamic>?> serverDocs;
  final Map<String, Map<String, dynamic>?> cacheDocs;
  final List<String> gets = [];

  @override
  Future<DirectoryDoc> getDoc(
    String collection,
    String id, {
    Source? source,
  }) async {
    final key = '$collection/$id';
    if (source == Source.cache) {
      gets.add('cache:$key');
    } else if (source == Source.server) {
      gets.add('server:$key');
    } else {
      gets.add('default:$key');
    }
    final store = source == Source.cache ? cacheDocs : serverDocs;
    if (!store.containsKey(key)) {
      if (source == Source.cache) throw StateError('cache miss');
      return DirectoryDoc(id: id, exists: false);
    }
    final data = store[key];
    if (data == null) return DirectoryDoc(id: id, exists: false);
    return DirectoryDoc(
      id: id,
      exists: true,
      data: Map<String, dynamic>.from(data),
    );
  }

  @override
  Future<List<DirectoryDoc>> getDocs(
    String collection, {
    required Source source,
  }) async {
    gets.add('query:$source:$collection');
    return const [];
  }

  @override
  Future<List<DirectoryDoc>> getDocsWhere(
    String collection, {
    required String field,
    required String value,
    required Source source,
  }) async {
    gets.add('query:$source:$collection:$field=$value');
    return const [];
  }
}

({TempleService service, FirestoreReadLog log, _FakeDirectory fake}) _harness({
  required bool applied,
}) {
  final slugs = [
    for (var i = 0; i < _shardCount; i++)
      'state-${i.toString().padLeft(2, '0')}',
  ];
  final serverDocs = <String, Map<String, dynamic>?>{
    'meta/temple_index': {
      'indexVersion': 1,
      'shards': {for (final slug in slugs) slug: _stamp},
    },
  };
  final cacheDocs = <String, Map<String, dynamic>?>{};
  for (var i = 0; i < slugs.length; i++) {
    final slug = slugs[i];
    final id = slug;
    final shard = {
      'entries': {
        id: {
          'id': id,
          'name': 'Temple $i',
          'state': 'State $i',
          'city': 'City $i',
          'deity': 'Shiva',
          'lat': 8.0 + i,
          'lng': 77.0,
          'tradition': 'unspecified',
          'framing': 'neutral',
        },
      },
    };
    serverDocs['$kTempleIndexCollection/$slug'] = shard;
    cacheDocs['$kTempleIndexCollection/$slug'] = shard;
  }
  final fake = _FakeDirectory(serverDocs: serverDocs, cacheDocs: cacheDocs);
  final log = FirestoreReadLog();
  final service = TempleService(
    directory: fake,
    stamps: _MemoryStamps({
      if (applied)
        for (final slug in slugs) slug: _stamp,
    }),
    readLog: log,
    fetchTimeout: const Duration(milliseconds: 30),
  );
  return (service: service, log: log, fake: fake);
}
