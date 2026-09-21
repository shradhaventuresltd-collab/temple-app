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

  /// Current `temples/{id}` map, or `null` if the document is missing.
  Future<Map<String, dynamic>?> get(String id);

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

  /// After Storage upload: merge [imageUrls] into `images` and write a
  /// **full** temple payload (not an images-only `update` / `arrayUnion`).
  ///
  /// Firestore rules validate `request.resource.data` on every update, so a
  /// partial images write is denied when the existing doc is missing required
  /// fields. Returns the temple as persisted.
  Future<Temple> appendTempleImages(Temple temple, List<String> imageUrls);
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

  /// Storage has already succeeded. Merge URLs, then `set(merge: true)` the
  /// complete temple map rules expect — never `arrayUnion` on `images` alone.
  @override
  Future<Temple> appendTempleImages(
    Temple temple,
    List<String> imageUrls,
  ) async {
    await _assertCanWrite();

    final id = temple.id.trim();
    if (id.isEmpty) {
      throw StateError('Temple id is missing.');
    }

    final urls = imageUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) {
      throw StateError('No image URLs to save.');
    }

    final stored = await _store.get(id);
    if (stored == null) {
      throw StateError(
        'Temple was not found. It may have already been deleted.',
      );
    }

    _assertNoDisallowedFirestoreKeys(stored);

    final current = coalesceTemple(Temple.fromMap(id, stored), temple);
    final updated = templeWithAppendedImages(current, urls);
    final payload = _payload(updated, id);
    assertTemplePayloadValidForRules(payload);

    try {
      await _store.set(id, payload, isNew: false);
    } catch (e) {
      throw StateError(
        'Storage upload succeeded, but Firestore could not save the image '
        'list. ${adminWriteErrorMessage(e)}',
      );
    }
    return updated;
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

/// Keys allowed on `temples/{id}` by `firestore.rules` (`hasOnlyAllowedFields`).
const kTempleFirestoreAllowedFields = {
  'id',
  'name',
  'state',
  'city',
  'deity',
  'imageUrl',
  'description',
  'story',
  'address',
  'location',
  'timings',
  'specialities',
  'images',
  'latitude',
  'longitude',
  'createdAt',
};

void _assertNoDisallowedFirestoreKeys(Map<String, dynamic> stored) {
  final extra = stored.keys
      .where((k) => !kTempleFirestoreAllowedFields.contains(k))
      .toList()
    ..sort();
  if (extra.isEmpty) return;
  throw StateError(
    'This temple document has extra fields (${extra.join(', ')}) that '
    'Firestore rules reject on update. Open Edit and save to rewrite a '
    'valid document, then retry Upload.',
  );
}

/// Builds the temple that will be written after an image upload.
///
/// Model fields come from [current] (the Admin list item). Gallery URLs come
/// from [stored] when present so a stale list snapshot cannot drop images.
Temple coalesceTemple(Temple stored, Temple current) {
  String pick(String preferred, String backup) =>
      preferred.trim().isNotEmpty ? preferred : backup;
  return current.copyWith(
    imageUrl: pick(current.imageUrl, stored.imageUrl),
    images: stored.images.isNotEmpty ? stored.images : current.images,
    latitude: current.latitude != 0 ? current.latitude : stored.latitude,
    longitude: current.longitude != 0 ? current.longitude : stored.longitude,
  );
}

/// Appends [newUrls] onto [temple.images] without duplicates, keeping order.
/// If [Temple.imageUrl] is empty, uses the first gallery URL as the cover.
Temple templeWithAppendedImages(Temple temple, Iterable<String> newUrls) {
  final merged = <String>[];
  final seen = <String>{};

  void add(String raw) {
    final url = raw.trim();
    if (url.isEmpty || !seen.add(url)) return;
    merged.add(url);
  }

  for (final url in temple.images) {
    add(url);
  }
  for (final url in newUrls) {
    add(url);
  }

  final cover = temple.imageUrl.trim();
  return temple.copyWith(
    images: merged,
    imageUrl: cover.isNotEmpty
        ? temple.imageUrl
        : (merged.isNotEmpty ? merged.first : ''),
  );
}

/// Client-side check matching `isValidTempleUpdate` when a full payload is
/// written, so Admin gets a field-level error instead of permission-denied.
void assertTemplePayloadValidForRules(Map<String, dynamic> data) {
  final extra = data.keys
      .where((k) => !kTempleFirestoreAllowedFields.contains(k))
      .toList()
    ..sort();
  if (extra.isNotEmpty) {
    throw StateError(
      'Temple payload has fields Firestore rules do not allow: '
      '${extra.join(', ')}.',
    );
  }

  void requireString(String field, {int min = 1, required int max}) {
    final value = data[field];
    if (value is! String) {
      throw StateError(
        'Temple "$field" is required for Firestore rules and was missing.',
      );
    }
    if (value.length < min) {
      throw StateError(
        'Temple "$field" is empty; Firestore rules require a non-empty string.',
      );
    }
    if (value.length > max) {
      throw StateError(
        'Temple "$field" is ${value.length} characters; '
        'Firestore rules allow at most $max.',
      );
    }
  }

  requireString('id', max: 200);
  requireString('name', max: 200);
  requireString('state', max: 100);
  requireString('city', max: 100);
  requireString('deity', max: 100);
  requireString('description', max: 10000);
  requireString('story', max: 20000);
  requireString('address', max: 500);
  requireString('timings', max: 1000);

  final imageUrl = data['imageUrl'];
  if (imageUrl is! String) {
    throw StateError('Temple "imageUrl" must be a string.');
  }
  if (imageUrl.length > 2000) {
    throw StateError(
      'Temple "imageUrl" is ${imageUrl.length} characters; '
      'Firestore rules allow at most 2000.',
    );
  }

  void requireList(String field, int maxItems) {
    final value = data[field];
    if (value is! List) {
      throw StateError('Temple "$field" must be a list.');
    }
    if (value.length > maxItems) {
      throw StateError(
        'Temple "$field" has ${value.length} items; '
        'Firestore rules allow at most $maxItems.',
      );
    }
  }

  requireList('specialities', 20);
  requireList('images', 50);

  final lat = data['latitude'];
  final lng = data['longitude'];
  if (lat is! num || lat < -90 || lat > 90) {
    throw StateError(
      'Temple "latitude" must be a number between -90 and 90.',
    );
  }
  if (lng is! num || lng < -180 || lng > 180) {
    throw StateError(
      'Temple "longitude" must be a number between -180 and 180.',
    );
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
        final plugin = error.plugin.toLowerCase();
        if (plugin.contains('storage')) {
          return 'Permission denied. Sign in as an admin '
              '(custom claim admin: true) and retry.';
        }
        return 'Permission denied. If you are not signed in as an admin '
            '(custom claim admin: true), grant that claim and retry. '
            'If you already are an admin, Firestore rejected the temple '
            'document — required fields may be missing or empty, values '
            'may exceed size limits, or the document may have extra keys.';
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
