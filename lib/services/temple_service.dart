import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/index_stamp_store.dart';
import 'package:temple_app/services/temple_directory_client.dart';

/// Browse, search, and home lists, plus the detail document.
///
/// The list reads server `meta/temple_index`, then each shard whose server
/// stamp differs from the stamp this device last applied. The full
/// `collection('temples')` scan runs only when that server read confirms the
/// meta document is absent or its shard map is empty. A timeout or other
/// error serves the applied shards from the local cache when they exist,
/// otherwise the bundled sample, and the next launch tries the server again.
/// When one shard misses on both the server and the cache, the client queries
/// `temples` where `state` equals that state. Zero documents is the same gap
/// as a failed query: the state is not dropped. The bundled sample for the
/// state is used only in that case, and the screen says it could not load
/// the state. A sample on screen also says it is the offline sample.
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

  TempleDirectoryClient get _client => _directory ?? _ownedClient;

  IndexStampStore get _stampStore => _stamps ?? _ownedStamps;

  late final TempleDirectoryClient _ownedClient =
      FirestoreTempleDirectoryClient(_firestore ?? FirebaseFirestore.instance);

  late final IndexStampStore _ownedStamps = SharedPreferencesIndexStampStore();

  bool get _usesSharedSession => _directory == null && _firestore == null;

  /// Browse, search, and home lists.
  Future<List<Temple>> getTemples({bool refresh = false}) {
    if (!_usesSharedSession) return _load();
    if (refresh) _session = null;
    return _session ??= _load();
  }

  /// Full `temples/{id}` document for the detail screen.
  ///
  /// Uses the default Firestore source, with a timeout. A timeout or other
  /// error reads the cache and [TempleDetailLoad.fromCache] is true. This
  /// read is not part of the launch total.
  Future<TempleDetailLoad> getTemple(String id) async {
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

  Future<List<Temple>> _load() async {
    _readLog.startLoad();
    final index = await _loadFromServerMeta();
    if (index.confirmedMissing) return _loadCollectionOrRescue();
    final rows = index.temples;
    if (rows != null) {
      if (index.servedStale) _readLog.recordFallback('index-cache');
      if (index.servedSample) _readLog.recordFallback('sample');
      _readLog.finishLaunch(
        index.servedFresh
            ? 'index'
            : index.servedStale
            ? 'index-cache'
            : index.servedSample
            ? 'sample'
            : 'index',
      );
      return rows;
    }
    return _rescueFromAppliedCache();
  }

  /// Server meta, then the shards [planIndexShardReads] selects.
  ///
  /// [confirmedMissing] is the only result that may read `temples`.
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
    var servedSample = false;
    for (final read in plan) {
      final loaded = await _readPlannedShard(read, serverStamps[read.slug]);
      if (loaded == null) continue;
      anyDoc = true;
      servedFresh = servedFresh || loaded.fresh;
      servedStale = servedStale || loaded.stale;
      servedSample = servedSample || loaded.sample;
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
      servedSample: servedSample,
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

  /// One state's `temples` documents. The bundled sample is for a failed
  /// query or a query that returns nothing, and that sample is always
  /// announced. An empty result would otherwise drop the state with no notice.
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

  /// Bundled temples for [slug] when the state query failed. An empty sample
  /// for that state is a visible gap, not a silent omission. A non-empty
  /// sample is still announced as offline.
  _ShardRows? _sampleForMissingShard(String slug) {
    final label = _stateLabel(slug);
    final temples = [
      for (final temple in sampleTemples)
        if (templeIndexStateSlug(temple.state) == slug) temple,
    ];
    if (temples.isEmpty) {
      _readLog.noteUnavailableShard(label);
      return null;
    }
    _readLog.noteOfflineSample(label);
    return _ShardRows(temples, fresh: false, stale: false, sample: true);
  }

  String _stateLabel(String slug) {
    for (final temple in sampleTemples) {
      if (templeIndexStateSlug(temple.state) == slug) return temple.state;
    }
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
      _readLog.finishLaunch(
        identical(rows, sampleTemples) ? 'sample' : 'temples',
      );
      return rows;
    } catch (_) {
      return _rescueFromAppliedCache();
    }
  }

  Future<List<Temple>> _rescueFromAppliedCache() async {
    final cached = await _templesFromAppliedCache();
    if (cached.isNotEmpty) {
      _readLog.recordFallback('index-cache');
      _readLog.finishLaunch('index-cache');
      return cached;
    }
    _readLog.noteOfflineSample();
    _readLog.recordFallback('sample');
    _readLog.finishLaunch('sample');
    return sampleTemples;
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

  /// `temples` collection. An empty result becomes [sampleTemples].
  Future<List<Temple>> _loadCollection() async {
    final docs = await _client
        .getDocs('temples', source: Source.server)
        .timeout(fetchTimeout);
    _readLog.serverRead(docs.isEmpty ? 1 : docs.length);
    if (docs.isEmpty) return sampleTemples;
    final temples = [
      for (final doc in docs) Temple.fromMap(doc.id, doc.data ?? {}),
    ];
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }
}

class _ServerIndex {
  const _ServerIndex.confirmedMissing()
    : confirmedMissing = true,
      temples = null,
      servedFresh = false,
      servedStale = false,
      servedSample = false;

  const _ServerIndex.unavailable()
    : confirmedMissing = false,
      temples = null,
      servedFresh = false,
      servedStale = false,
      servedSample = false;

  const _ServerIndex.rows(
    this.temples, {
    required this.servedFresh,
    required this.servedStale,
    required this.servedSample,
  }) : confirmedMissing = false;

  final bool confirmedMissing;
  final List<Temple>? temples;
  final bool servedFresh;
  final bool servedStale;
  final bool servedSample;
}

class _ShardRows {
  const _ShardRows(
    this.temples, {
    required this.fresh,
    required this.stale,
    this.sample = false,
  });

  final List<Temple> temples;
  final bool fresh;
  final bool stale;
  final bool sample;
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
