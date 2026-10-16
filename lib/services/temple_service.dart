import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/services/firebase_ready.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/index_stamp_store.dart';
import 'package:temple_app/services/temple_directory_client.dart';

/// Browse, search, and home lists, plus the detail document.
///
/// When this device already applied shard stamps and those shards are in the
/// local cache, the list returns that cache immediately and refreshes from
/// the server in the background. A cold launch with no cache waits for server
/// `meta/temple_index`, then each shard whose stamp differs. The full
/// `collection('temples')` scan runs only on that cold foreground load, and
/// only when meta is absent or its shard map is empty. [loadDirectory], which
/// warm refresh, Retry, reconnect, and resume all await, keeps the cache and
/// does not scan. While Remote Config `kill_switch` is on, that call does
/// not read Firestore. A timeout or other error keeps the cached list and
/// says so.
/// With no cache at all the load throws [DirectoryLoadException] so the screen
/// can offer Retry. A missing shard is omitted and named; it is not filled
/// from bundled sample temples.
///
/// Web launches are always cold. The web Firestore cache is memory-only, so
/// a new page load has no shard documents even when [IndexStampStore] still
/// holds the applied stamps. Each cache read misses and the shard is fetched
/// from the server.
class TempleService {
  TempleService({
    FirebaseFirestore? firestore,
    TempleDirectoryClient? directory,
    IndexStampStore? stamps,
    FirestoreReadLog? readLog,
    this.fetchTimeout = const Duration(seconds: 12),
  }) : _firestore = firestore,
       _directory = directory,
       _stamps = stamps,
       _readLog = readLog ?? FirestoreReadLog.instance;

  final FirebaseFirestore? _firestore;
  final TempleDirectoryClient? _directory;
  final IndexStampStore? _stamps;
  final FirestoreReadLog _readLog;
  final Duration fetchTimeout;

  /// In-memory result for this process. Home and the drawer share it so a
  /// launch does not read the index twice. An injected client or Firestore
  /// instance, used by tests, does not touch it.
  static Future<List<Temple>>? _session;

  /// Latest list published after a background refresh. Null until one finishes.
  static List<Temple>? published;

  /// Bumps when [published] changes so Home and the list can swap in the
  /// fresh rows without a loading spinner.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Remote Config `kill_switch`. [TempleDirectoryApp] installs the live
  /// check. While this returns true, [loadDirectory] and [getTemples] do
  /// not read Firestore.
  static bool Function() readsBlocked = () => false;

  @visibleForTesting
  static void resetSessionForTest() {
    _session = null;
    published = null;
    _sharedInFlight = null;
    _sharedLoadSerial = 0;
    _sharedPublishedSerial = 0;
    readsBlocked = () => false;
  }

  /// One server load for the process. Injected test clients keep their own.
  static Future<List<Temple>>? _sharedInFlight;

  static int _sharedLoadSerial = 0;
  static int _sharedPublishedSerial = 0;

  Future<List<Temple>>? _localInFlight;
  Future<List<Temple>>? _background;
  int _loadSerial = 0;
  int _publishedSerial = 0;

  /// Completes the server refresh started by a cache-first [getTemples].
  @visibleForTesting
  Future<List<Temple>?> flushBackgroundForTest() =>
      _inFlightNow ?? _background ?? Future<List<Temple>?>.value();

  /// Marks a newer successful publish so an older in-flight failure cannot
  /// turn the saved-list banner back on.
  @visibleForTesting
  void noteFreshDirectoryPublished() {
    _markPublished(_nextSerial());
    _readLog.showingSavedList = false;
  }

  Future<List<Temple>>? get _inFlightNow =>
      _usesSharedSession ? _sharedInFlight : _localInFlight;

  int _nextSerial() {
    if (_usesSharedSession) return ++_sharedLoadSerial;
    return ++_loadSerial;
  }

  int get _publishedNow =>
      _usesSharedSession ? _sharedPublishedSerial : _publishedSerial;

  void _markPublished(int serial) {
    if (_usesSharedSession) {
      _sharedPublishedSerial = serial;
    } else {
      _publishedSerial = serial;
    }
  }

  void _retain(Future<List<Temple>> future) {
    if (_usesSharedSession) {
      _sharedInFlight = future;
    } else {
      _localInFlight = future;
    }
    future.whenComplete(() {
      if (_usesSharedSession) {
        if (identical(_sharedInFlight, future)) _sharedInFlight = null;
      } else if (identical(_localInFlight, future)) {
        _localInFlight = null;
      }
    }).ignore();
  }

  /// Injected clients are used as-is. Otherwise a missing default app must
  /// not touch [FirebaseFirestore.instance] (that throws core/no-app).
  bool get _canUseFirestore =>
      _directory != null || _firestore != null || firebaseAppsReady();

  TempleDirectoryClient get _client => _directory ?? _ownedClient;

  IndexStampStore get _stampStore => _stamps ?? _ownedStamps;

  late final TempleDirectoryClient _ownedClient =
      FirestoreTempleDirectoryClient(_firestore ?? _firestoreInstance());

  static FirebaseFirestore _firestoreInstance() {
    noteFirebaseAccess('FirebaseFirestore.instance');
    return FirebaseFirestore.instance;
  }

  late final IndexStampStore _ownedStamps = SharedPreferencesIndexStampStore();

  bool get _usesSharedSession => _directory == null && _firestore == null;

  /// Browse, search, and home lists.
  ///
  /// [refresh] awaits [loadDirectory] instead of returning the cache first.
  /// A server failure still returns the saved list when one exists.
  Future<List<Temple>> getTemples({bool refresh = false}) {
    if (readsBlocked()) return _stoppedDirectory();
    if (refresh) {
      final next = loadDirectory();
      if (_usesSharedSession) _session = next;
      return next;
    }
    if (!_usesSharedSession) return _open();
    return _session ??= _open();
  }

  /// One shared directory load.
  ///
  /// Signature: `Future<List<Temple>> loadDirectory()`.
  ///
  /// Warm refresh, Retry, reconnect, and the resume check all await this.
  /// A caller that arrives while a load is running receives that same future,
  /// so meta is not read twice and the read log is not reset underneath the
  /// load already in flight. This path never scans `collection('temples')`.
  /// A cold foreground [getTemples] with no cache is the only scan.
  ///
  /// When [readsBlocked] is true (`kill_switch`), this returns the list
  /// already published, or an empty list, and does not read Firestore.
  Future<List<Temple>> loadDirectory() {
    if (readsBlocked()) return _stoppedDirectory();
    return _startInFlight(allowCollectionScan: false);
  }

  /// Kill switch: no cache read and no server read.
  Future<List<Temple>> _stoppedDirectory() async {
    final saved = published;
    if (saved == null) return const [];
    return List<Temple>.from(saved);
  }

  /// Full `temples/{id}` document for the detail screen.
  ///
  /// Uses the default Firestore source, with a timeout. A timeout or other
  /// error reads the cache and [TempleDetailLoad.fromCache] is true. This
  /// read is not part of the launch total.
  Future<TempleDetailLoad> getTemple(String id) async {
    if (!_canUseFirestore) return const TempleDetailLoad();
    DirectoryDoc snap;
    var fromCache = false;
    try {
      snap = await _client.getDoc('temples', id).timeout(fetchTimeout);
    } catch (_) {
      fromCache = true;
      snap = await _client.getDoc('temples', id, source: Source.cache);
    }
    _readLog.detailRead(id);
    if (!snap.exists) return const TempleDetailLoad();
    return TempleDetailLoad(
      temple: Temple.fromMap(snap.id, snap.data ?? {}),
      fromCache: fromCache,
    );
  }

  Future<List<Temple>> _open() async {
    _readLog.startLoad();
    final cached = await _cachedDirectory();
    if (cached != null) {
      _noteSaved(cached);
      _background = loadDirectory();
      return cached;
    }
    return _startInFlight(allowCollectionScan: true);
  }

  Future<List<Temple>> _startInFlight({required bool allowCollectionScan}) {
    final existing = _inFlightNow;
    if (existing != null) return existing;
    final next = _runDirectoryLoad(allowCollectionScan: allowCollectionScan);
    _background = next;
    _retain(next);
    return next;
  }

  Future<List<Temple>> _runDirectoryLoad({
    required bool allowCollectionScan,
  }) async {
    final serial = _nextSerial();
    if (!allowCollectionScan) {
      // Let the cache-first caller observe read counts and the saved-list
      // banner. A microtask runs before that caller's await resumes.
      await Future<void>.delayed(Duration.zero);
      _readLog.serverReads = 0;
      _readLog.cacheHits = 0;
      _readLog.unavailableShards.clear();
    }
    final outcome = await _loadFromNetwork(
      allowCollectionScan: allowCollectionScan,
    );
    if (outcome.rows != null) {
      return _accept(serial, outcome, outcome.rows!);
    }
    final cached = await _templesFromAppliedCache();
    if (cached.isEmpty) throw const DirectoryLoadException();
    return _accept(serial, const _NetworkOutcome.keepCache(), cached);
  }

  /// Applies the outcome of [serial] unless a newer load already published.
  /// A late failure must not turn the saved-list banner back on.
  List<Temple> _accept(int serial, _NetworkOutcome outcome, List<Temple> rows) {
    if (_publishedNow > serial) return rows;
    if (outcome.freshIndex) {
      _readLog.showingSavedList = false;
      _markPublished(serial);
    } else if (outcome.savedList) {
      _readLog.noteSavedList();
      if (outcome.rows == null) {
        _readLog.recordFallback('index-cache');
        _readLog.finishLaunch('index-cache');
      }
    }
    _publish(rows);
    return rows;
  }

  void _noteSaved(List<Temple> rows) {
    _readLog.noteSavedList();
    _readLog.finishLaunch('index-cache');
    _publish(rows);
  }

  void _publish(List<Temple> rows) {
    if (!_usesSharedSession) return;
    published = rows;
    _session = Future<List<Temple>>.value(rows);
    revision.value = revision.value + 1;
  }

  /// Applied stamps plus cached shard documents. Null when this device has
  /// nothing saved to show.
  Future<List<Temple>?> _cachedDirectory() async {
    if (!_canUseFirestore) return null;
    final applied = await _stampStore.readApplied();
    if (applied.isEmpty) return null;
    final temples = await _templesFromAppliedCache();
    if (temples.isEmpty) return null;
    return temples;
  }

  Future<_NetworkOutcome> _loadFromNetwork({
    required bool allowCollectionScan,
  }) async {
    if (!_canUseFirestore) throw const DirectoryLoadException();
    final index = await _loadFromServerMeta();
    if (index.confirmedMissing) {
      if (!allowCollectionScan) return const _NetworkOutcome.keepCache();
      final rows = await _loadCollectionOrRescue();
      final fresh = _readLog.source == 'temples' || _readLog.source == 'index';
      return _NetworkOutcome.rows(rows, savedList: !fresh, freshIndex: fresh);
    }
    final rows = index.temples;
    if (rows != null) {
      final stale = index.servedStale;
      if (stale) _readLog.recordFallback('index-cache');
      _readLog.finishLaunch(stale ? 'index-cache' : 'index');
      return _NetworkOutcome.rows(rows, savedList: stale, freshIndex: !stale);
    }
    return const _NetworkOutcome.keepCache();
  }

  /// Server meta, then the shards [planIndexShardReads] selects.
  ///
  /// [confirmedMissing] may scan `temples` only when the caller is a cold
  /// foreground load with no cache.
  Future<_ServerIndex> _loadFromServerMeta() async {
    final DirectoryDoc serverMeta;
    try {
      serverMeta = await _client
          .getDoc(
            kTempleIndexMetaCollection,
            kTempleIndexMetaDocId,
            source: Source.server,
          )
          .timeout(fetchTimeout);
      _readLog.serverRead();
    } catch (_) {
      return const _ServerIndex.unavailable();
    }

    if (!serverMeta.exists) return const _ServerIndex.confirmedMissing();
    final serverStamps = _stampMap(serverMeta.data?['shards']);
    if (serverStamps.isEmpty) return const _ServerIndex.confirmedMissing();

    final applied = await _stampStore.readApplied();
    final plan = planIndexShardReads(
      appliedStamps: applied,
      serverStamps: serverStamps,
    );
    final temples = <Temple>[];
    var anyDoc = false;
    var servedFresh = false;
    var servedStale = false;
    for (final read in plan) {
      final loaded = await _readPlannedShard(read, serverStamps[read.slug]);
      if (loaded == null) continue;
      anyDoc = true;
      servedFresh = servedFresh || loaded.fresh;
      servedStale = servedStale || loaded.stale;
      temples.addAll(loaded.temples);
    }
    if (!anyDoc && _readLog.unavailableShards.isEmpty) {
      return const _ServerIndex.unavailable();
    }
    temples.sort((a, b) => a.id.compareTo(b.id));
    return _ServerIndex.rows(
      temples,
      servedFresh: servedFresh,
      servedStale: servedStale,
    );
  }

  /// One cache read when the applied stamp matches. A cache miss fetches the
  /// server once and does not read the cache again. A changed shard is read
  /// from the server; the cache is a display fallback and does not become
  /// the applied stamp.
  Future<_ShardRows?> _readPlannedShard(
    IndexShardRead read,
    Object? stamp,
  ) async {
    if (read.fromCache) {
      final cached = await _cachedShard(read.slug, stale: false);
      if (cached != null) return cached;
      final fresh = await _serverShard(read.slug, stamp);
      if (fresh != null) return fresh;
      return _stateOrSample(read.slug);
    }
    final fresh = await _serverShard(read.slug, stamp);
    if (fresh != null) return fresh;
    final cached = await _cachedShard(read.slug, stale: true);
    if (cached != null) return cached;
    return _stateOrSample(read.slug);
  }

  /// One state's `temples` documents. A failed or empty query names the
  /// state and omits it. Bundled sample temples are not inserted.
  Future<_ShardRows?> _stateOrSample(String slug) async {
    final fromState = await _templesForState(slug);
    if (fromState != null) return fromState;
    return _sampleForMissingShard(slug);
  }

  Future<_ShardRows?> _templesForState(String slug) async {
    final state = _stateLabel(slug);
    try {
      final docs = await _client
          .getDocsWhere(
            'temples',
            field: 'state',
            value: state,
            source: Source.server,
          )
          .timeout(fetchTimeout);
      _readLog.serverRead(docs.isEmpty ? 1 : docs.length);
      if (docs.isEmpty) return null;
      final temples = [
        for (final doc in docs) Temple.fromMap(doc.id, doc.data ?? {}),
      ];
      temples.sort((a, b) => a.id.compareTo(b.id));
      return _ShardRows(temples, fresh: true, stale: false);
    } catch (_) {
      return null;
    }
  }

  /// A shard that missed the server, the cache, and the state query. The
  /// state is named and omitted. Bundled sample temples are not inserted.
  _ShardRows? _sampleForMissingShard(String slug) {
    _readLog.noteUnavailableShard(_stateLabel(slug));
    return null;
  }

  String _stateLabel(String slug) {
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Future<_ShardRows?> _serverShard(String slug, Object? stamp) async {
    try {
      final snap = await _client
          .getDoc(kTempleIndexCollection, slug, source: Source.server)
          .timeout(fetchTimeout);
      _readLog.serverRead();
      if (!snap.exists) return null;
      final millis = indexStampMillis(stamp);
      if (millis != null) await _stampStore.writeApplied(slug, millis);
      return _ShardRows(
        templesFromIndexShard(snap.data),
        fresh: true,
        stale: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_ShardRows?> _cachedShard(String slug, {required bool stale}) async {
    try {
      final snap = await _client.getDoc(
        kTempleIndexCollection,
        slug,
        source: Source.cache,
      );
      if (!snap.exists) return null;
      _readLog.cacheHit();
      return _ShardRows(
        templesFromIndexShard(snap.data),
        fresh: !stale,
        stale: stale,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Temple>> _loadCollectionOrRescue() async {
    try {
      final rows = await _loadCollection();
      _readLog.finishLaunch('temples');
      return rows;
    } catch (_) {
      return _rescueFromAppliedCache();
    }
  }

  Future<List<Temple>> _rescueFromAppliedCache() async {
    final cached = await _templesFromAppliedCache();
    if (cached.isNotEmpty) {
      _readLog.noteSavedList();
      _readLog.recordFallback('index-cache');
      _readLog.finishLaunch('index-cache');
      return cached;
    }
    throw const DirectoryLoadException();
  }

  Future<List<Temple>> _templesFromAppliedCache() async {
    final applied = await _stampStore.readApplied();
    final slugs = applied.keys.toList()..sort();
    final temples = <Temple>[];
    for (final slug in slugs) {
      final cached = await _cachedShard(slug, stale: true);
      if (cached == null) continue;
      temples.addAll(cached.temples);
    }
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }

  /// `temples` collection. An empty result stays empty.
  Future<List<Temple>> _loadCollection() async {
    final docs = await _client
        .getDocs('temples', source: Source.server)
        .timeout(fetchTimeout);
    _readLog.serverRead(docs.isEmpty ? 1 : docs.length);
    if (docs.isEmpty) return const [];
    final temples = [
      for (final doc in docs) Temple.fromMap(doc.id, doc.data ?? {}),
    ];
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }
}

class _NetworkOutcome {
  const _NetworkOutcome.rows(
    this.rows, {
    required this.savedList,
    required this.freshIndex,
  });

  const _NetworkOutcome.keepCache()
    : rows = null,
      savedList = true,
      freshIndex = false;

  final List<Temple>? rows;
  final bool savedList;
  final bool freshIndex;
}

class _ServerIndex {
  const _ServerIndex.confirmedMissing()
    : confirmedMissing = true,
      temples = null,
      servedFresh = false,
      servedStale = false;

  const _ServerIndex.unavailable()
    : confirmedMissing = false,
      temples = null,
      servedFresh = false,
      servedStale = false;

  const _ServerIndex.rows(
    this.temples, {
    required this.servedFresh,
    required this.servedStale,
  }) : confirmedMissing = false;

  final bool confirmedMissing;
  final List<Temple>? temples;
  final bool servedFresh;
  final bool servedStale;
}

class _ShardRows {
  const _ShardRows(this.temples, {required this.fresh, required this.stale});

  final List<Temple> temples;
  final bool fresh;
  final bool stale;
}

/// Detail document, and whether it came from the cache fallback.
class TempleDetailLoad {
  const TempleDetailLoad({this.temple, this.fromCache = false});

  final Temple? temple;
  final bool fromCache;
}

Map<String, Object?> _stampMap(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

/// The directory has no cached list and the server read failed.
class DirectoryLoadException implements Exception {
  const DirectoryLoadException();

  @override
  String toString() => 'DirectoryLoadException';
}

/// Listed entries on one shard document.
List<Temple> templesFromIndexShard(Map<String, dynamic>? data) {
  final entries = data?['entries'];
  if (entries is! Map) return const [];
  final temples = <Temple>[];
  for (final value in entries.values) {
    if (value is! Map) continue;
    final entry = Map<String, dynamic>.from(value);
    if (!templeIndexEntryListed(entry)) continue;
    temples.add(templeFromIndexEntry(entry));
  }
  return temples;
}
