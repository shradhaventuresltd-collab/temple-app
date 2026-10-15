import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/index_stamp_store.dart';
import 'package:temple_app/services/temple_directory_client.dart';
import 'package:temple_app/services/temple_service.dart';

const _states = ['bihar', 'kerala', 'odisha'];
final _oldStamp = DateTime.utc(2026, 1, 2).millisecondsSinceEpoch;
final _newStamp = DateTime.utc(2026, 2, 2).millisecondsSinceEpoch;

void main() {
  test('cold, warm, and one changed shard count server reads', () async {
    final cold = _harness(stamps: {});
    final coldRows = await cold.service.getTemples();
    expect(cold.log.serverReads, 1 + _states.length);
    expect(cold.log.cacheHits, 0);
    expect(coldRows.map((temple) => temple.id), [
      'bihar-temple',
      'kerala-temple',
      'odisha-temple',
    ]);
    expect(cold.stamps.stamps[_states.first], _oldStamp);
    expect(cold.fake.count('cache:temple_index/bihar'), 0);
    expect(cold.fake.count('server:temple_index/bihar'), 1);

    final warm = _harness(
      stamps: {for (final state in _states) state: _oldStamp},
    );
    await warm.service.getTemples();
    expect(warm.log.serverReads, 1);
    expect(warm.log.cacheHits, _states.length);
    for (final state in _states) {
      expect(warm.fake.count('cache:temple_index/$state'), 1);
      expect(warm.fake.count('server:temple_index/$state'), 0);
    }

    final changed = _harness(
      stamps: {
        'bihar': _oldStamp,
        'kerala': _oldStamp,
        'odisha': _oldStamp,
      },
      serverStamps: {
        'bihar': _newStamp,
        'kerala': _oldStamp,
        'odisha': _oldStamp,
      },
    );
    final changedRows = await changed.service.getTemples();
    expect(changed.log.serverReads, 2);
    expect(changed.fake.count('server:temple_index/bihar'), 1);
    expect(changed.fake.count('cache:temple_index/kerala'), 1);
    expect(changed.fake.count('cache:temple_index/odisha'), 1);
    expect(changed.fake.count('server:temple_index/kerala'), 0);
    expect(
      changedRows.firstWhere((temple) => temple.id == 'bihar-temple').name,
      'Bihar fresh',
    );
    expect(changed.stamps.stamps['bihar'], _newStamp);
    expect(changed.log.fallbackCount, 0);
  });

  test('a meta timeout never reads the temples collection', () async {
    final hung = _harness(hangMeta: true);
    final rows = await hung.service.getTemples();
    expect(rows, same(sampleTemples));
    expect(hung.fake.gets.where((get) => get.contains('temples')), isEmpty);
    expect(hung.log.serverReads, 0);
    expect(hung.log.fallbacks, ['sample']);
    expect(hung.log.fallbackCount, 1);

    final cached = _harness(
      hangMeta: true,
      stamps: {'kerala': _oldStamp},
    );
    final cachedRows = await cached.service.getTemples();
    expect(cachedRows.map((temple) => temple.id), ['kerala-temple']);
    expect(cached.fake.gets.where((get) => get.contains('temples')), isEmpty);
    expect(cached.log.fallbacks, ['index-cache']);
    expect(cached.fake.count('cache:temple_index/kerala'), 1);
  });

  test('a failed shard fetch does not stick the new stamp', () async {
    final first = _harness(
      stamps: {'bihar': _oldStamp},
      serverStamps: {'bihar': _newStamp},
      failServerShards: {'bihar'},
    );
    final stale = await first.service.getTemples();
    expect(stale.single.name, 'Bihar cached');
    expect(first.stamps.stamps['bihar'], _oldStamp);
    expect(first.log.fallbacks, ['index-cache']);
    expect(first.fake.count('cache:temple_index/bihar'), 1);
    expect(first.fake.count('server:temple_index/bihar'), 1);

    final second = _harness(
      stamps: Map<String, int>.from(first.stamps.stamps),
      serverStamps: {'bihar': _newStamp},
    );
    final fresh = await second.service.getTemples();
    expect(fresh.single.name, 'Bihar fresh');
    expect(second.log.serverReads, 2);
    expect(second.stamps.stamps['bihar'], _newStamp);
  });

  test('a missing meta document reads the temples collection', () async {
    final harness = _harness(metaExists: false);
    harness.fake.serverDocs['temples/kept-temple'] = {
      'name': 'Kept',
      'state': 'Bihar',
    };
    final rows = await harness.service.getTemples();
    expect(rows.map((temple) => temple.id), ['kept-temple']);
    expect(harness.fake.count('query:Source.server:temples'), 1);
    expect(harness.log.fallbackCount, 0);
    expect(harness.log.serverReads, 2);

    final empty = _harness(serverStamps: {});
    empty.fake.serverDocs['temples/kept-temple'] = {'name': 'Kept'};
    final fromEmpty = await empty.service.getTemples();
    expect(fromEmpty.map((temple) => temple.id), ['kept-temple']);
    expect(empty.fake.count('query:Source.server:temples'), 1);
    expect(empty.log.fallbackCount, 0);
  });

  test('detail uses the default source and then the cache', () async {
    final harness = _harness();
    harness.fake.hangDefault.add('temples/shore-temple');
    harness.fake.cacheDocs['temples/shore-temple'] = {
      'name': 'Shore Temple',
      'description': 'A full document',
    };
    final temple = await harness.service.getTemple('shore-temple');
    expect(temple?.description, 'A full document');
    expect(harness.fake.gets, [
      'default:temples/shore-temple',
      'cache:temples/shore-temple',
    ]);
    expect(harness.log.serverReads, 0);
  });

  test('applied stamps round-trip through shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesIndexStampStore();
    expect(await store.readApplied(), isEmpty);
    await store.writeApplied('bihar', _oldStamp);
    await store.writeApplied('kerala', _newStamp);
    expect(await store.readApplied(), {'bihar': _oldStamp, 'kerala': _newStamp});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(IndexStampKeys.applied), contains('bihar'));
  });

  test('the release fallback marker is a fixed non-PII token', () {
    final source = File(
      'lib/services/firestore_read_log.dart',
    ).readAsStringSync();
    expect(source, contains('TODO(KAN-156): report this fallback as a Crashlytics non-fatal.'));
    expect(source, contains("debugPrint('index_fallback:\$marker')"));
    final log = FirestoreReadLog();
    log.recordFallback('sample');
    log.recordFallback('index-cache');
    expect(log.fallbacks, ['sample', 'index-cache']);
    expect(log.fallbackCount, 2);
    for (final marker in log.fallbacks) {
      expect(marker, isNot(contains('/')));
      expect(marker, isNot(contains(' ')));
    }
  });
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
  _FakeDirectory({
    required this.serverDocs,
    required this.cacheDocs,
    required this.hangServer,
    required this.failServerShards,
  });

  final Map<String, Map<String, dynamic>?> serverDocs;
  final Map<String, Map<String, dynamic>?> cacheDocs;
  final Set<String> hangServer;
  final Set<String> hangDefault = {};
  final Set<String> failServerShards;
  final List<String> gets = [];

  int count(String get) => gets.where((entry) => entry == get).length;

  @override
  Future<DirectoryDoc> getDoc(
    String collection,
    String id, {
    Source? source,
  }) async {
    final key = '$collection/$id';
    if (source == null) {
      gets.add('default:$key');
      if (hangDefault.contains(key)) return Completer<DirectoryDoc>().future;
    } else if (source == Source.cache) {
      gets.add('cache:$key');
    } else {
      gets.add('server:$key');
      if (hangServer.contains(key)) return Completer<DirectoryDoc>().future;
      if (collection == kTempleIndexCollection && failServerShards.contains(id)) {
        throw StateError('shard unavailable');
      }
    }
    final store = source == Source.cache ? cacheDocs : serverDocs;
    if (!store.containsKey(key)) {
      if (source == Source.cache) throw StateError('cache miss');
      return DirectoryDoc(id: id, exists: false);
    }
    final data = store[key];
    if (data == null) return DirectoryDoc(id: id, exists: false);
    return DirectoryDoc(id: id, exists: true, data: Map<String, dynamic>.from(data));
  }

  @override
  Future<List<DirectoryDoc>> getDocs(
    String collection, {
    required Source source,
  }) async {
    gets.add('query:$source:$collection');
    final prefix = '$collection/';
    final store = source == Source.cache ? cacheDocs : serverDocs;
    final docs = <DirectoryDoc>[];
    for (final entry in store.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final id = entry.key.substring(prefix.length);
      if (id.contains('/')) continue;
      final data = entry.value;
      if (data == null) continue;
      docs.add(
        DirectoryDoc(id: id, exists: true, data: Map<String, dynamic>.from(data)),
      );
    }
    return docs;
  }
}

({
  TempleService service,
  FirestoreReadLog log,
  _FakeDirectory fake,
  _MemoryStamps stamps,
})
_harness({
  Map<String, int> stamps = const {},
  Map<String, int>? serverStamps,
  bool hangMeta = false,
  bool metaExists = true,
  Set<String> failServerShards = const {},
}) {
  final metaStamps = serverStamps ?? {for (final state in _states) state: _oldStamp};
  final serverDocs = <String, Map<String, dynamic>?>{};
  final cacheDocs = <String, Map<String, dynamic>?>{};
  if (metaExists) {
    serverDocs['meta/temple_index'] = {'indexVersion': 1, 'shards': metaStamps};
  }
  for (final state in _states) {
    final fresh = metaStamps[state] != _oldStamp;
    serverDocs['temple_index/$state'] = _shard(
      state,
      name: fresh ? _title(state, fresh: true) : _title(state, fresh: false),
    );
    cacheDocs['temple_index/$state'] = _shard(state, name: _title(state, fresh: false));
  }
  final fake = _FakeDirectory(
    serverDocs: serverDocs,
    cacheDocs: cacheDocs,
    hangServer: hangMeta ? {'meta/temple_index'} : {},
    failServerShards: failServerShards,
  );
  final memory = _MemoryStamps(stamps);
  final log = FirestoreReadLog();
  final service = TempleService(
    directory: fake,
    stamps: memory,
    readLog: log,
    fetchTimeout: const Duration(milliseconds: 30),
  );
  return (service: service, log: log, fake: fake, stamps: memory);
}

Map<String, dynamic> _shard(String state, {required String name}) {
  final id = '$state-temple';
  return {
    'entries': {
      id: {
        'id': id,
        'name': name,
        'state': state,
        'city': 'City',
        'deity': 'Shiva',
        'tradition': 'unspecified',
        'framing': 'neutral',
      },
    },
  };
}

String _title(String state, {required bool fresh}) {
  final head = state[0].toUpperCase() + state.substring(1);
  return fresh ? '$head fresh' : '$head cached';
}
