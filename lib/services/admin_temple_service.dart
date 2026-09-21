import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/seed_service.dart';

/// Persistence used by [AdminTempleService] so write paths can be tested
/// without a live Firebase project.
abstract class TempleWriteStore {
  Future<bool> exists(String id);

  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
  });

  Future<void> deleteDocument(String id);

  /// Deletes objects under `temples/{docId}/`. Returns how many were removed.
  /// External URLs (picsum seed images, etc.) are not Storage objects.
  Future<int> deleteStoragePrefix(String docId);
}

/// Firestore + Storage implementation. Schema matches Seed / [Temple].
class FirebaseTempleWriteStore implements TempleWriteStore {
  FirebaseTempleWriteStore({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
  }) async {
    final payload = Map<String, dynamic>.from(data);
    final ref = _col.doc(id);
    if (isNew) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(payload);
    } else {
      await ref.set(payload, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteDocument(String id) => _col.doc(id).delete();

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

  Object? setError;
  Object? deleteDocumentError;
  Object? deleteStorageError;
  int deleteStorageCalls = 0;

  @override
  Future<bool> exists(String id) async => docs.containsKey(id);

  @override
  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    required bool isNew,
  }) async {
    if (setError != null) throw setError!;
    final payload = Map<String, dynamic>.from(data);
    if (isNew) {
      payload['createdAt'] = 'server';
      docs[id] = payload;
    } else {
      docs[id] = {...?docs[id], ...payload};
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (deleteDocumentError != null) throw deleteDocumentError!;
    docs.remove(id);
  }

  @override
  Future<int> deleteStoragePrefix(String docId) async {
    deleteStorageCalls++;
    if (deleteStorageError != null) throw deleteStorageError!;
    return storageObjectCounts[docId] ?? 0;
  }
}

class AdminDeleteResult {
  const AdminDeleteResult({
    required this.docId,
    required this.storageObjectsDeleted,
  });

  final String docId;
  final int storageObjectsDeleted;

  String get successMessage {
    if (storageObjectsDeleted > 0) {
      return 'Deleted temple and $storageObjectsDeleted uploaded image(s).';
    }
    return 'Deleted temple.';
  }
}

/// Debug Admin CMS surface: live list plus create / update / delete.
abstract class AdminTempleApi {
  Stream<List<Temple>> get watchTemples;

  Future<String> createTemple(Temple temple);

  Future<void> updateTemple(Temple temple);

  Future<AdminDeleteResult> deleteTemple(String id);
}

/// Admin CMS writes. Requires debug + Auth custom claim `admin: true`.
class AdminTempleService implements AdminTempleApi {
  AdminTempleService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    TempleWriteStore? store,
    Future<bool> Function()? isAdmin,
    bool? isDebug,
    Stream<List<Temple>> Function()? watch,
  })  : _firestore = firestore,
        _store = store ??
            FirebaseTempleWriteStore(
              firestore: firestore,
              storage: storage,
            ),
        _isAdmin = isAdmin ?? AdminAuth.instance.isCurrentUserAdmin,
        _isDebug = isDebug ?? kDebugMode,
        _watch = watch;

  final FirebaseFirestore? _firestore;
  final TempleWriteStore _store;
  final Future<bool> Function() _isAdmin;
  final bool _isDebug;
  final Stream<List<Temple>> Function()? _watch;

  Stream<List<Temple>>? _cachedWatch;

  @override
  Stream<List<Temple>> get watchTemples {
    final cached = _cachedWatch;
    if (cached != null) return cached;

    final customWatch = _watch;
    final stream = customWatch != null
        ? customWatch()
        : (_firestore ?? FirebaseFirestore.instance)
            .collection('temples')
            .orderBy('name')
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((doc) => Temple.fromMap(doc.id, doc.data()))
                  .toList(),
            );
    _cachedWatch = stream;
    return stream;
  }

  @override
  Future<String> createTemple(Temple temple) async {
    await _assertCanWrite();

    final name = temple.name.trim();
    if (name.isEmpty) {
      throw StateError('Name is required.');
    }

    final id = temple.id.trim().isNotEmpty
        ? temple.id.trim()
        : templeDocumentId(name);
    if (id.isEmpty) {
      throw StateError('Name must include letters or numbers.');
    }
    if (await _store.exists(id)) {
      throw StateError('A temple named "$name" already exists.');
    }

    final data = _payload(temple, id);
    if ((data['images'] as List).isEmpty) {
      final cover = temple.imageUrl.trim();
      if (cover.isNotEmpty) data['images'] = [cover];
    }

    await _store.set(id, data, isNew: true);
    return id;
  }

  @override
  Future<void> updateTemple(Temple temple) async {
    await _assertCanWrite();

    final id = temple.id.trim();
    if (id.isEmpty) {
      throw StateError('Temple id is missing.');
    }
    if (temple.name.trim().isEmpty) {
      throw StateError('Name is required.');
    }
    if (!await _store.exists(id)) {
      throw StateError('Temple was not found. It may have already been deleted.');
    }

    await _store.set(id, _payload(temple, id), isNew: false);
  }

  /// Deletes the Firestore document after removing known Storage objects
  /// under `temples/{id}/`.
  ///
  /// Seeded external image URLs are not Storage files and are left as-is.
  /// If Storage listing/deletion fails, the Firestore document is left in
  /// place so the operator can retry.
  @override
  Future<AdminDeleteResult> deleteTemple(String id) async {
    await _assertCanWrite();

    final docId = id.trim();
    if (docId.isEmpty) {
      throw StateError('Temple id is missing.');
    }

    final int storageDeleted;
    try {
      storageDeleted = await _store.deleteStoragePrefix(docId);
    } catch (e) {
      throw StateError(
        'Could not delete Storage objects for this temple. '
        'The Firestore document was not removed. ${adminWriteErrorMessage(e)}',
      );
    }

    try {
      await _store.deleteDocument(docId);
    } catch (e) {
      throw StateError(
        'Removed $storageDeleted Storage object(s), but the Firestore '
        'document could not be deleted. ${adminWriteErrorMessage(e)}',
      );
    }

    return AdminDeleteResult(
      docId: docId,
      storageObjectsDeleted: storageDeleted,
    );
  }

  Map<String, dynamic> _payload(Temple temple, String id) {
    return temple.copyWith(id: id).toFirestoreData(documentId: id);
  }

  Future<void> _assertCanWrite() async {
    if (!_isDebug) {
      throw StateError('Temple CMS writes are only available in debug builds.');
    }
    final allowed = await _isAdmin();
    if (!allowed) {
      throw StateError(
        'Writes require a signed-in admin (custom claim admin: true).',
      );
    }
  }
}

/// Maps Firestore / Storage / CMS write failures to a short UI string.
String adminWriteErrorMessage(Object error) {
  if (error is StateError) {
    final message = error.message.trim();
    return message.isEmpty ? 'Write failed.' : message;
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Sign in as an admin '
            '(custom claim admin: true) and retry.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
      case 'not-found':
        return 'Temple was not found. It may have already been deleted.';
      case 'already-exists':
        return 'A temple with this name already exists.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isEmpty) return 'Write failed (${error.code}).';
        return message;
    }
  }
  var text = error.toString().trim();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    text = text.substring(prefix.length);
  }
  if (text.length > 180) {
    text = '${text.substring(0, 177)}…';
  }
  if (text.isEmpty) return 'Write failed.';
  return text;
}
