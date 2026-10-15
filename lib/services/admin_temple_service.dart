import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/services/temple_write_store.dart';

export 'package:temple_app/services/temple_write_store.dart';

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
  }) : _firestore = firestore,
       _store =
           store ??
           FirebaseTempleWriteStore(firestore: firestore, storage: storage),
       _isAdmin = isAdmin ?? AdminAuth.instance.isCurrentUserAdmin,
       _isDebug = isDebug ?? kAdminToolsEnabled,
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
    // Photo-editor writes already mirrored imageUrl/images from photos[].
    // Do not invent a gallery from a stale cover, and do not backfill photos.
    if (!temple.writePhotos && (data['images'] as List).isEmpty) {
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
    final previous = await _store.get(id);
    if (previous == null) {
      throw StateError(
        'Temple was not found. It may have already been deleted.',
      );
    }

    await _store.set(
      id,
      _payload(temple, id),
      isNew: false,
      previous: previous,
    );
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
      await _store.set(id, payload, isNew: false, previous: stored);
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
      final previous = await _store.get(docId);
      await _store.deleteDocument(docId, previous: previous);
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
      throw StateError(
        'Temple CMS writes are only available in debug builds '
        '(or demo builds with ENABLE_ADMIN_TOOLS).',
      );
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
  'photos',
  'latitude',
  'longitude',
  'createdAt',
};

void _assertNoDisallowedFirestoreKeys(Map<String, dynamic> stored) {
  final extra =
      stored.keys
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

double? _preferCoordinate(double? current, double? stored) {
  if (current == null || current == 0) return stored;
  return current;
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
    latitude: _preferCoordinate(current.latitude, stored.latitude),
    longitude: _preferCoordinate(current.longitude, stored.longitude),
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
  final extra =
      data.keys
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
  _requirePhotos(data['photos']);

  final lat = data['latitude'];
  final lng = data['longitude'];
  if (lat is! num || lat < -90 || lat > 90) {
    throw StateError('Temple "latitude" must be a number between -90 and 90.');
  }
  if (lng is! num || lng < -180 || lng > 180) {
    throw StateError(
      'Temple "longitude" must be a number between -180 and 180.',
    );
  }
}

const _photoLicences = {'CC-BY', 'CC-BY-SA', 'CC0', 'Own', 'Permission'};

void _requirePhotos(Object? raw) {
  if (raw == null) return;
  if (raw is! List) {
    throw StateError('Temple "photos" must be a list.');
  }
  if (raw.length > 12) {
    throw StateError(
      'Temple "photos" has ${raw.length} items; Firestore rules allow at most 12.',
    );
  }
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is! Map) {
      throw StateError('Temple photo ${i + 1} must be a map.');
    }
    final url = item['url'];
    if (url is! String || url.length > 2000 || !url.startsWith('https://')) {
      throw StateError(
        'Temple photo ${i + 1} url must be an https string of at most 2000 characters.',
      );
    }
    final licence = item['licence'];
    if (licence is! String || !_photoLicences.contains(licence)) {
      throw StateError(
        'Temple photo ${i + 1} licence must be CC-BY, CC-BY-SA, CC0, Own, or Permission.',
      );
    }
    final order = item['order'];
    if (order is! int || order < 0 || order > 11) {
      throw StateError(
        'Temple photo ${i + 1} order must be an integer from 0 to 11.',
      );
    }
    final credit = item['credit'];
    if (credit != null && (credit is! String || credit.length > 200)) {
      throw StateError(
        'Temple photo ${i + 1} credit must be a string of at most 200 characters.',
      );
    }
    final needsCredit = licence == 'CC-BY' || licence == 'CC-BY-SA';
    if (needsCredit && (credit is! String || credit.trim().isEmpty)) {
      throw StateError('Credit is required for $licence.');
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
