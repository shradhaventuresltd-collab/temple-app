import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:temple_app/models/temple_index.dart';

/// Persistence used by [AdminTempleService] so write paths can be tested
/// without a live Firebase project.
abstract class TempleWriteStore {
  Future<bool> exists(String id);

  /// Current `temples/{id}` map, or `null` if the document is missing.
  Future<Map<String, dynamic>?> get(String id);

  /// Writes the temple and, in the same commit, its index entry and meta bump.
  ///
  /// [previous] is the stored temple when the caller already loaded it.
  /// A state change removes `entries.{id}` from the old shard.
  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
    Map<String, dynamic>? previous,
  });

  Future<void> deleteDocument(String id, {Map<String, dynamic>? previous});

  /// Deletes objects under `temples/{docId}/`. Returns how many were removed.
  /// External URLs (picsum seed images, etc.) are not Storage objects.
  Future<int> deleteStoragePrefix(String docId);
}

/// Firestore + Storage implementation. Schema matches Seed / [Temple].
class FirebaseTempleWriteStore implements TempleWriteStore {
  FirebaseTempleWriteStore({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('temples');

  @override
  Future<bool> exists(String id) async {
    final snap = await _col.doc(id).get();
    return snap.exists;
  }

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  @override
  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
    Map<String, dynamic>? previous,
  }) {
    return _commitTemple(
      id: id,
      data: data,
      isNew: isNew,
      deleteTemple: false,
      previous: previous,
    );
  }

  @override
  Future<void> deleteDocument(String id, {Map<String, dynamic>? previous}) {
    return _commitTemple(
      id: id,
      data: null,
      isNew: false,
      deleteTemple: true,
      previous: previous,
    );
  }

  /// One batch: the temple document, a single `entries.{id}` field path,
  /// and the `meta/temple_index` bump.
  ///
  /// A state move also field-deletes `entries.{id}` on the old shard.
  /// That shard is read only to see whether the delete is needed. The
  /// entries map is never loaded or rewritten.
  Future<void> _commitTemple({
    required String id,
    required Map<String, dynamic>? data,
    required bool isNew,
    required bool deleteTemple,
    Map<String, dynamic>? previous,
  }) async {
    final ref = _col.doc(id);
    var prior = previous;
    if (prior == null && !isNew) {
      final snap = await ref.get();
      if (snap.exists) prior = snap.data();
    }
    final plan = planTempleIndex(
      id: id,
      next: deleteTemple ? null : data,
      previous: isNew ? null : prior,
    );

    DocumentReference<Map<String, dynamic>>? oldShard;
    if (plan.removeShard != null) {
      final candidate = _firestore
          .collection(kTempleIndexCollection)
          .doc(plan.removeShard);
      final oldSnap = await candidate.get();
      if (oldSnap.exists) oldShard = candidate;
    }

    final batch = _firestore.batch();
    if (deleteTemple) {
      batch.delete(ref);
    } else if (isNew) {
      final payload = Map<String, dynamic>.from(data!);
      payload['createdAt'] = FieldValue.serverTimestamp();
      batch.set(ref, payload);
    } else {
      batch.set(ref, data!, SetOptions(merge: true));
    }

    if (plan.upsertShard != null && plan.entry != null) {
      final state = data?['state'];
      await _rejectFullShard(
        plan.upsertShard!,
        id,
        state: state is String ? state : '',
      );
      final entry = Map<String, dynamic>.from(plan.entry!);
      entry['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(
        _firestore.collection(kTempleIndexCollection).doc(plan.upsertShard),
        {
          'entries': {id: entry},
        },
        SetOptions(
          mergeFields: [
            FieldPath(['entries', id]),
          ],
        ),
      );
    }
    if (oldShard != null) {
      // Entry ids are slugs with no dots, so this is one field path.
      batch.update(oldShard, {'entries.$id': FieldValue.delete()});
    }
    if (plan.touchesIndex) {
      final metaRef = _firestore
          .collection(kTempleIndexMetaCollection)
          .doc(kTempleIndexMetaDocId);
      final metaSnap = await metaRef.get();
      // mergeFields + increment resets indexVersion in the emulator's web
      // SDK, and the rules then deny the whole batch. merge: true keeps the
      // +1. Copy sibling shard stamps so the replaced map does not drop them.
      final stamps = <String, dynamic>{};
      final existing = metaSnap.data()?['shards'];
      if (existing is Map) {
        for (final entry in existing.entries) {
          stamps[entry.key.toString()] = entry.value;
        }
      }
      for (final slug in plan.metaShards) {
        stamps[slug] = FieldValue.serverTimestamp();
      }
      batch.set(metaRef, {
        'indexVersion': metaSnap.exists ? FieldValue.increment(1) : 1,
        'shards': stamps,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Reads the shard only to count keys. The entries map is not rewritten.
  Future<void> _rejectFullShard(
    String shard,
    String id, {
    required String state,
  }) async {
    final snap = await _firestore
        .collection(kTempleIndexCollection)
        .doc(shard)
        .get();
    final entries = snap.data()?['entries'];
    final count = entries is Map ? entries.length : 0;
    final already = entries is Map && entries.containsKey(id);
    if (!already && count >= kTempleIndexMaxEntries) {
      throw StateError(templeIndexShardFullMessage(state: state, count: count));
    }
  }

  @override
  Future<int> deleteStoragePrefix(String docId) {
    return _deletePrefix(_storage.ref('temples/$docId'));
  }

  Future<int> _deletePrefix(Reference ref) async {
    final listed = await ref.listAll();
    var count = 0;
    for (final item in listed.items) {
      await item.delete();
      count++;
    }
    for (final prefix in listed.prefixes) {
      count += await _deletePrefix(prefix);
    }
    return count;
  }
}

/// In-memory store for tests.
class MemoryTempleWriteStore implements TempleWriteStore {
  MemoryTempleWriteStore({
    Map<String, Map<String, dynamic>>? docs,
    this.storageObjectCounts = const {},
  }) : docs = docs ?? {};

  final Map<String, Map<String, dynamic>> docs;

  /// How many Storage objects [deleteStoragePrefix] should report per doc id.
  Map<String, int> storageObjectCounts;

  /// `temple_index/{stateSlug}` → temple id → entry. One key is written
  /// at a time; siblings already in the shard are left in place.
  final Map<String, Map<String, Map<String, dynamic>>> shards = {};

  int indexVersion = 0;
  final Map<String, String> shardStamps = {};
  List<String> lastIndexFieldPaths = const [];

  Object? setError;
  Object? deleteDocumentError;
  Object? deleteStorageError;
  int deleteStorageCalls = 0;

  @override
  Future<bool> exists(String id) async => docs.containsKey(id);

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    final data = docs[id];
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
    Map<String, dynamic>? previous,
  }) async {
    if (setError != null) throw setError!;
    final prior = isNew
        ? null
        : (previous ??
              (docs[id] == null ? null : Map<String, dynamic>.from(docs[id]!)));
    final plan = planTempleIndex(id: id, next: data, previous: prior);
    _rejectFullShardMemory(plan, data['state']);
    final payload = Map<String, dynamic>.from(data);
    if (isNew) {
      payload['createdAt'] = 'server';
      docs[id] = payload;
    } else {
      docs[id] = {...?docs[id], ...payload};
    }
    _applyIndexPlan(plan);
  }

  @override
  Future<void> deleteDocument(
    String id, {
    Map<String, dynamic>? previous,
  }) async {
    if (deleteDocumentError != null) throw deleteDocumentError!;
    final prior =
        previous ??
        (docs[id] == null ? null : Map<String, dynamic>.from(docs[id]!));
    final plan = planTempleIndex(id: id, next: null, previous: prior);
    docs.remove(id);
    _applyIndexPlan(plan);
  }

  void _rejectFullShardMemory(TempleIndexPlan plan, Object? state) {
    final shard = plan.upsertShard;
    if (shard == null) return;
    final current = shards[shard];
    final count = current?.length ?? 0;
    final already = current?.containsKey(plan.id) ?? false;
    if (!already && count >= kTempleIndexMaxEntries) {
      final label = state is String ? state : '';
      throw StateError(templeIndexShardFullMessage(state: label, count: count));
    }
  }

  void _applyIndexPlan(TempleIndexPlan plan) {
    final paths = <String>[];
    if (plan.upsertShard != null && plan.entry != null) {
      final shard = shards.putIfAbsent(plan.upsertShard!, () => {});
      final entry = Map<String, dynamic>.from(plan.entry!);
      entry['updatedAt'] = 'server';
      shard[plan.id] = entry;
      paths.add('temple_index/${plan.upsertShard}/entries/${plan.id}');
    }
    if (plan.removeShard != null) {
      final old = shards[plan.removeShard!];
      if (old != null && old.containsKey(plan.id)) {
        old.remove(plan.id);
        paths.add('temple_index/${plan.removeShard}/entries/${plan.id} delete');
      }
    }
    if (plan.touchesIndex) {
      indexVersion += 1;
      for (final slug in plan.metaShards) {
        shardStamps[slug] = 'server';
      }
      paths.add('meta/temple_index');
    }
    lastIndexFieldPaths = paths;
  }

  @override
  Future<int> deleteStoragePrefix(String docId) async {
    deleteStorageCalls++;
    if (deleteStorageError != null) throw deleteStorageError!;
    return storageObjectCounts[docId] ?? 0;
  }
}
