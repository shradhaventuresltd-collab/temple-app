import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/services/firestore_read_log.dart';

class TempleService {
  TempleService({
    FirebaseFirestore? firestore,
    FirestoreReadLog? readLog,
    this.fetchTimeout = const Duration(seconds: 12),
  }) : _firestore = firestore,
       _readLog = readLog ?? FirestoreReadLog.instance;

  final FirebaseFirestore? _firestore;
  final FirestoreReadLog _readLog;
  final Duration fetchTimeout;

  /// In-memory result for this process. Home and the drawer share it so a
  /// launch does not read the index twice. Injected Firestore instances used
  /// by tests do not touch it.
  static Future<List<Temple>>? _session;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Browse, search, and home lists.
  ///
  /// Reads `meta/temple_index` from cache, then from the server, and fetches
  /// only shards whose `updatedAt` changed. A missing meta document or an
  /// index with no shard documents falls back to `temples`. Timeout and
  /// other errors use the index cache when it has rows, then the bundled
  /// sample.
  Future<List<Temple>> getTemples({bool refresh = false}) {
    if (_firestore != null) return _load();
    if (refresh) _session = null;
    return _session ??= _load();
  }

  /// Full `temples/{id}` document for the detail screen.
  Future<Temple?> getTemple(String id) async {
    final snap = await _db.collection('temples').doc(id).get(
      const GetOptions(source: Source.server),
    );
    _readLog.detailRead(id);
    if (!snap.exists) return null;
    return Temple.fromMap(snap.id, snap.data() ?? {});
  }

  Future<List<Temple>> _load() async {
    _readLog.startLoad();
    try {
      final indexed = await _loadIndex();
      if (indexed != null) {
        _readLog.finishLaunch('index');
        return indexed;
      }
    } catch (_) {
      final cached = await _loadIndex(cacheOnly: true);
      if (cached != null && cached.isNotEmpty) {
        _readLog.finishLaunch('index-cache');
        return cached;
      }
    }
    try {
      final rows = await _loadCollection();
      _readLog.finishLaunch(rows == sampleTemples ? 'sample' : 'temples');
      return rows;
    } catch (_) {
      final cached = await _loadIndex(cacheOnly: true);
      if (cached != null && cached.isNotEmpty) {
        _readLog.finishLaunch('index-cache');
        return cached;
      }
      _readLog.finishLaunch('sample');
      return sampleTemples;
    }
  }

  Future<List<Temple>?> _loadIndex({bool cacheOnly = false}) async {
    final metaRef = _db
        .collection(kTempleIndexMetaCollection)
        .doc(kTempleIndexMetaDocId);
    DocumentSnapshot<Map<String, dynamic>>? cachedMeta;
    try {
      cachedMeta = await metaRef.get(const GetOptions(source: Source.cache));
      _readLog.cacheHit();
    } catch (_) {
      cachedMeta = null;
    }

    if (cacheOnly) {
      if (cachedMeta == null || !cachedMeta.exists) return null;
      return _templesFromStamps(
        _stampMap(cachedMeta.data()?['shards']),
        cachedOnly: true,
      );
    }

    late final DocumentSnapshot<Map<String, dynamic>> serverMeta;
    try {
      serverMeta = await metaRef
          .get(const GetOptions(source: Source.server))
          .timeout(fetchTimeout);
      _readLog.serverRead();
    } catch (_) {
      if (cachedMeta != null && cachedMeta.exists) {
        return _templesFromStamps(
          _stampMap(cachedMeta.data()?['shards']),
          cachedOnly: true,
        );
      }
      rethrow;
    }

    if (!serverMeta.exists) return null;
    final serverStamps = _stampMap(serverMeta.data()?['shards']);
    if (serverStamps.isEmpty) return null;

    final cachedStamps = cachedMeta != null && cachedMeta.exists
        ? _stampMap(cachedMeta.data()?['shards'])
        : const <String, Object?>{};
    final inCache = <String>{};
    if (cachedMeta != null && cachedMeta.exists) {
      for (final slug in cachedStamps.keys) {
        final ref = _db.collection(kTempleIndexCollection).doc(slug);
        try {
          final snap = await ref.get(const GetOptions(source: Source.cache));
          if (snap.exists) inCache.add(slug);
        } catch (_) {}
      }
    }

    final plan = planIndexShardReads(
      cachedStamps: cachedStamps,
      serverStamps: serverStamps,
      shardsInCache: inCache,
    );
    final temples = <Temple>[];
    var anyShard = false;
    for (final read in plan) {
      final ref = _db.collection(kTempleIndexCollection).doc(read.slug);
      DocumentSnapshot<Map<String, dynamic>> snap;
      if (read.fromCache) {
        snap = await ref.get(const GetOptions(source: Source.cache));
        _readLog.cacheHit();
      } else {
        try {
          snap = await ref
              .get(const GetOptions(source: Source.server))
              .timeout(fetchTimeout);
          _readLog.serverRead();
        } catch (_) {
          try {
            snap = await ref.get(const GetOptions(source: Source.cache));
            _readLog.cacheHit();
          } catch (_) {
            continue;
          }
        }
      }
      if (!snap.exists) continue;
      anyShard = true;
      temples.addAll(templesFromIndexShard(snap.data()));
    }
    if (!anyShard) return null;
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }

  Future<List<Temple>?> _templesFromStamps(
    Map<String, Object?> stamps, {
    required bool cachedOnly,
  }) async {
    if (stamps.isEmpty) return null;
    final temples = <Temple>[];
    var anyShard = false;
    for (final slug in stamps.keys) {
      final ref = _db.collection(kTempleIndexCollection).doc(slug);
      try {
        final snap = await ref.get(
          GetOptions(source: cachedOnly ? Source.cache : Source.server),
        );
        if (cachedOnly) {
          _readLog.cacheHit();
        } else {
          _readLog.serverRead();
        }
        if (!snap.exists) continue;
        anyShard = true;
        temples.addAll(templesFromIndexShard(snap.data()));
      } catch (_) {}
    }
    if (!anyShard) return null;
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }

  /// `temples` collection. Empty or unavailable data becomes [sampleTemples].
  Future<List<Temple>> _loadCollection() async {
    final snapshot = await _db
        .collection('temples')
        .get(const GetOptions(source: Source.server))
        .timeout(fetchTimeout);
    _readLog.serverRead(snapshot.docs.isEmpty ? 1 : snapshot.docs.length);
    if (snapshot.docs.isEmpty) return sampleTemples;
    final temples = snapshot.docs
        .map((doc) => Temple.fromMap(doc.id, doc.data()))
        .toList();
    temples.sort((a, b) => a.id.compareTo(b.id));
    return temples;
  }
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
