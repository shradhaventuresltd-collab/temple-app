import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/index_resume.dart';
import 'package:temple_app/services/index_stamp_store.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/temple_directory_client.dart';
import 'package:temple_app/services/temple_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('the resume window is 15 minutes from the last check', () {
    final start = DateTime.utc(2026, 10, 16, 8);
    expect(indexResumeCheckDue(lastIndexCheck: null, now: start), isTrue);
    expect(
      indexResumeCheckDue(
        lastIndexCheck: start,
        now: start.add(const Duration(minutes: 14, seconds: 59)),
      ),
      isFalse,
    );
    expect(
      indexResumeCheckDue(
        lastIndexCheck: start,
        now: start.add(const Duration(minutes: 15)),
      ),
      isTrue,
    );
    expect(kIndexResumeCheckInterval, const Duration(minutes: 15));
  });

  test('an unchanged content_version skips the resume read', () {
    expect(
      indexResumeReadSkipped(appliedContentVersion: 4, remoteContentVersion: 4),
      isTrue,
    );
    expect(
      indexResumeReadSkipped(appliedContentVersion: 4, remoteContentVersion: 5),
      isFalse,
    );
    expect(
      indexResumeReadSkipped(
        appliedContentVersion: null,
        remoteContentVersion: 4,
      ),
      isFalse,
    );
  });

  test('a refresh reads meta once and only the shards that changed', () async {
    final harness = _harness();
    await harness.service.getTemples();
    await harness.service.flushBackgroundForTest();
    expect(harness.fake.serverCount('meta/temple_index'), 1);
    expect(harness.fake.serverCount('temple_index/bihar'), 0);
    expect(harness.fake.cacheCount('temple_index/kerala'), 2);

    harness.fake.gets.clear();
    await harness.service.getTemples(refresh: true);
    expect(harness.fake.serverCount('meta/temple_index'), 1);
    expect(
      harness.fake.gets.where((get) => get.startsWith('server:temple_index/')),
      isEmpty,
    );
    expect(harness.fake.cacheCount('temple_index/bihar'), 1);
    expect(harness.fake.cacheCount('temple_index/kerala'), 1);

    harness.serverStamps['bihar'] = _newStamp;
    harness.serverDocs['temple_index/bihar'] = _shard('bihar', 'Bihar fresh');
    harness.fake.gets.clear();
    final rows = await harness.service.getTemples(refresh: true);
    expect(harness.fake.serverCount('meta/temple_index'), 1);
    expect(harness.fake.serverCount('temple_index/bihar'), 1);
    expect(harness.fake.serverCount('temple_index/kerala'), 0);
    expect(harness.fake.cacheCount('temple_index/kerala'), 1);
    expect(rows.map((temple) => temple.name), ['Bihar fresh', 'Kerala cached']);
  });

  testWidgets(
    'resume inside 15 minutes does not read; after it, one meta read',
    (tester) async {
      var now = DateTime.utc(2026, 10, 16, 8);
      final harness = _harness(() => now);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            adminToolsEnabled: false,
            templeService: harness.service,
            now: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Browse 2 Temples'), findsOneWidget);
      expect(harness.fake.serverCount('meta/temple_index'), 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(harness.fake.serverCount('meta/temple_index'), 1);

      now = now.add(const Duration(minutes: 14));
      await _resume(tester);
      expect(harness.fake.serverCount('meta/temple_index'), 1);
      expect(harness.fake.gets.where((get) => get.startsWith('server:')), [
        'server:meta/temple_index',
      ]);

      now = now.add(const Duration(minutes: 1));
      await _resume(tester);
      expect(harness.fake.serverCount('meta/temple_index'), 2);
      expect(harness.fake.serverCount('temple_index/bihar'), 0);
      expect(harness.fake.serverCount('temple_index/kerala'), 0);
      expect(find.text('Loading temples…'), findsNothing);
      expect(find.text('Browse 2 Temples'), findsOneWidget);
    },
  );

  testWidgets('resume refetches only a changed shard and keeps the list up', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 16, 8);
    final harness = _harness(() => now);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminToolsEnabled: false,
          templeService: harness.service,
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    harness.serverStamps['bihar'] = _newStamp;
    harness.serverDocs['temple_index/bihar'] = _shard('bihar', 'Bihar fresh');
    harness.fake.holdNextMeta = Completer<void>();
    now = now.add(const Duration(minutes: 15));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    // loadDirectory waits one turn before the meta read, then holds.
    await tester.pump(Duration.zero);

    expect(find.text('Loading temples…'), findsNothing);
    expect(find.text('Browse 2 Temples'), findsOneWidget);
    expect(harness.fake.serverCount('meta/temple_index'), 2);

    harness.fake.holdNextMeta!.complete();
    await tester.pumpAndSettle();

    expect(harness.fake.serverCount('meta/temple_index'), 2);
    expect(harness.fake.serverCount('temple_index/bihar'), 1);
    expect(harness.fake.serverCount('temple_index/kerala'), 0);
    expect(find.text('Loading temples…'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('home-browse-temples')));
    await tester.tap(find.byKey(const Key('home-browse-temples')));
    await tester.pumpAndSettle();
    expect(find.text('Bihar fresh'), findsOneWidget);
    expect(find.text('Kerala cached'), findsOneWidget);
  });

  testWidgets('an unchanged content_version does not read on resume', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 16, 8);
    final harness = _harness(() => now);
    var version = 4;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminToolsEnabled: false,
          templeService: harness.service,
          now: () => now,
          appliedContentVersion: () => version,
          remoteContentVersion: () => version,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.fake.serverCount('meta/temple_index'), 1);

    now = now.add(const Duration(minutes: 20));
    await _resume(tester);
    expect(harness.fake.serverCount('meta/temple_index'), 1);

    version = 5;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminToolsEnabled: false,
          templeService: harness.service,
          now: () => now,
          appliedContentVersion: () => 4,
          remoteContentVersion: () => version,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = harness.fake.serverCount('meta/temple_index');
    now = now.add(const Duration(minutes: 15));
    await _resume(tester);
    expect(harness.fake.serverCount('meta/temple_index'), before + 1);
  });

  testWidgets(
    'the app shares one directory so resume stays inside the window',
    (tester) async {
      var now = DateTime.utc(2026, 10, 16, 8);
      final harness = _harness(() => now);
      await tester.pumpWidget(
        TempleDirectoryApp(
          acceptanceStore: _AcceptedPolicy(),
          initializeFirebase: () async => false,
          initializeAds: () async {},
          directory: harness.service,
          installedBuildNumber: null,
          now: () => now,
          onExitApp: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(harness.fake.serverCount('meta/temple_index'), 1);

      now = now.add(const Duration(minutes: 14));
      await _resume(tester);
      expect(harness.fake.serverCount('meta/temple_index'), 1);

      now = now.add(const Duration(minutes: 1));
      await _resume(tester);
      expect(harness.fake.serverCount('meta/temple_index'), 2);
      expect(harness.fake.gets.where((get) => get.startsWith('server:')), [
        'server:meta/temple_index',
        'server:meta/temple_index',
      ]);
    },
  );

  testWidgets('resume calls loadDirectory and does not scan temples', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 16, 8);
    final harness = _harness(() => now);
    final service = _CountingDirectory(
      directory: harness.fake,
      stamps: _MemoryStamps({'bihar': _oldStamp, 'kerala': _oldStamp}),
      now: () => now,
    );
    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedPolicy(),
        initializeFirebase: () async => false,
        initializeAds: () async {},
        directory: service,
        installedBuildNumber: null,
        now: () => now,
        onExitApp: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final afterOpen = service.loadDirectoryCalls;
    expect(afterOpen, 1);
    expect(service.refreshGets, 0);
    expect(_collectionScans(harness.fake), 0);

    now = now.add(const Duration(minutes: 14));
    await _resume(tester);
    expect(service.loadDirectoryCalls, afterOpen);
    expect(service.refreshGets, 0);

    now = now.add(const Duration(minutes: 1));
    await _resume(tester);
    expect(service.loadDirectoryCalls, afterOpen + 1);
    expect(service.refreshGets, 0);
    expect(_collectionScans(harness.fake), 0);
    expect(find.text('Browse 2 Temples'), findsOneWidget);
  });

  testWidgets(
    'resume does not call loadDirectory while the kill switch is on',
    (tester) async {
      var now = DateTime.utc(2026, 10, 16, 8);
      final harness = _harness(() => now);
      final service = _CountingDirectory(
        directory: harness.fake,
        stamps: _MemoryStamps({'bihar': _oldStamp, 'kerala': _oldStamp}),
        now: () => now,
      );
      final config = AppConfigController();
      await tester.pumpWidget(
        TempleDirectoryApp(
          acceptanceStore: _AcceptedPolicy(),
          initializeFirebase: () async => false,
          initializeAds: () async {},
          appConfig: config,
          directory: service,
          installedBuildNumber: null,
          now: () => now,
          onExitApp: () {},
        ),
      );
      await tester.pumpAndSettle();
      final afterOpen = service.loadDirectoryCalls;
      expect(afterOpen, 1);

      config.snapshot = config.snapshot.copyWith(killSwitch: true);
      now = now.add(const Duration(minutes: 20));
      await _resume(tester);
      expect(service.loadDirectoryCalls, afterOpen);
      expect(service.refreshGets, 0);
      expect(_collectionScans(harness.fake), 0);
    },
  );
}

class _AcceptedPolicy implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async {
    return PolicyAcceptance(
      version: PolicyConfig.currentVersion,
      acceptedAt: DateTime.utc(2026, 10, 14),
    );
  }

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

const _oldStamp = 1767225600000;
const _newStamp = 1769904000000;

class _CountingDirectory extends TempleService {
  _CountingDirectory({
    required TempleDirectoryClient directory,
    required IndexStampStore stamps,
    super.now,
  }) : super(
         directory: directory,
         stamps: stamps,
         readLog: FirestoreReadLog(),
         fetchTimeout: const Duration(milliseconds: 30),
       );

  int loadDirectoryCalls = 0;
  int refreshGets = 0;

  @override
  Future<List<Temple>> loadDirectory() {
    loadDirectoryCalls += 1;
    return super.loadDirectory();
  }

  @override
  Future<List<Temple>> getTemples({bool refresh = false}) {
    if (refresh) refreshGets += 1;
    return super.getTemples(refresh: refresh);
  }
}

int _collectionScans(_FakeDirectory fake) => fake.gets
    .where((get) => get.startsWith('query:') && get.endsWith(':temples'))
    .length;

class _MemoryStamps implements IndexStampStore {
  _MemoryStamps(this.stamps);

  final Map<String, int> stamps;

  @override
  Future<Map<String, int>> readApplied() async => Map<String, int>.of(stamps);

  @override
  Future<void> writeApplied(String slug, int millis) async {
    stamps[slug] = millis;
  }
}

class _FakeDirectory implements TempleDirectoryClient {
  _FakeDirectory(this.serverDocs, this.cacheDocs);

  final Map<String, Map<String, dynamic>?> serverDocs;
  final Map<String, Map<String, dynamic>?> cacheDocs;
  final List<String> gets = [];
  Completer<void>? holdNextMeta;
  bool _heldMeta = false;

  int serverCount(String path) =>
      gets.where((get) => get == 'server:$path').length;

  int cacheCount(String path) =>
      gets.where((get) => get == 'cache:$path').length;

  @override
  Future<DirectoryDoc> getDoc(
    String collection,
    String id, {
    Source? source,
  }) async {
    final where = source == Source.cache
        ? 'cache'
        : source == Source.server
        ? 'server'
        : 'default';
    gets.add('$where:$collection/$id');
    if (where == 'server' &&
        collection == kTempleIndexMetaCollection &&
        id == kTempleIndexMetaDocId &&
        !_heldMeta &&
        holdNextMeta != null) {
      _heldMeta = true;
      await holdNextMeta!.future;
    }
    final store = source == Source.cache ? cacheDocs : serverDocs;
    final data = store['$collection/$id'];
    if (data == null) {
      if (source == Source.cache) throw StateError('cache miss');
      return DirectoryDoc(id: id, exists: false);
    }
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

({
  TempleService service,
  _FakeDirectory fake,
  Map<String, int> serverStamps,
  Map<String, Map<String, dynamic>?> serverDocs,
})
_harness([DateTime Function()? now]) {
  final serverStamps = <String, int>{'bihar': _oldStamp, 'kerala': _oldStamp};
  final serverDocs = <String, Map<String, dynamic>?>{
    'meta/temple_index': {'shards': serverStamps},
    'temple_index/bihar': _shard('bihar', 'Bihar cached'),
    'temple_index/kerala': _shard('kerala', 'Kerala cached'),
  };
  final cacheDocs = <String, Map<String, dynamic>?>{
    'temple_index/bihar': _shard('bihar', 'Bihar cached'),
    'temple_index/kerala': _shard('kerala', 'Kerala cached'),
  };
  final fake = _FakeDirectory(serverDocs, cacheDocs);
  final service = TempleService(
    directory: fake,
    stamps: _MemoryStamps({'bihar': _oldStamp, 'kerala': _oldStamp}),
    readLog: FirestoreReadLog(),
    now: now,
    fetchTimeout: const Duration(milliseconds: 30),
  );
  return (
    service: service,
    fake: fake,
    serverStamps: serverStamps,
    serverDocs: serverDocs,
  );
}

Map<String, dynamic> _shard(String state, String name) {
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
