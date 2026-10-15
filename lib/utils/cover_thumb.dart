// Storage object paths and the public `_480` URL beside a temple photo.
//
// Kept in step with `scripts/temple_index.js` (`storageThumbUrl`,
// `thumbObjectPath`, `fileThumbSibling`). List cards read the result from
// `coverThumb`. Detail keeps the full object.

final RegExp _imageFile = RegExp(
  r'^(.*)\.(jpe?g|png|webp)$',
  caseSensitive: false,
);
final RegExp _alreadyThumb = RegExp(r'[_-]480$', caseSensitive: false);

final RegExp _firebaseUrl = RegExp(
  r'^https://([^/?#]+)/v0/b/([^/?#]+)/o/([^?#]+)',
  caseSensitive: false,
);
final RegExp _gcsUrl = RegExp(
  r'^https://storage\.googleapis\.com/([^/?#]+)/([^?#]+)',
  caseSensitive: false,
);

/// `firebase` (download URL) or `gcs` (`storage.googleapis.com`).
class StorageObjectLocation {
  const StorageObjectLocation({
    required this.kind,
    required this.bucket,
    required this.objectPath,
  });

  final String kind;
  final String bucket;
  final String objectPath;
}

String _decode(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

bool _firebaseHost(String host) {
  final lower = host.toLowerCase();
  return lower == 'firebasestorage.googleapis.com' ||
      lower.endsWith('.firebasestorage.app');
}

/// `temples/{id}/{file}_480.{ext}`, or null when [objectPath] is not a
/// full-size temple photo. Extension case is kept.
String? thumbObjectPath(String objectPath) {
  final parts = objectPath.split('/');
  if (parts.length != 3 || parts[0] != 'temples') return null;
  final id = parts[1];
  if (id.isEmpty || id == '.' || id == '..') return null;
  final ext = _imageFile.firstMatch(parts[2]);
  if (ext == null) return null;
  final stem = ext.group(1)!;
  if (stem.isEmpty || _alreadyThumb.hasMatch(stem)) return null;
  return 'temples/$id/${stem}_480.${ext.group(2)}';
}

/// Firebase or Cloud Storage object named by [raw].
///
/// The path is read from the raw string so `%2F` in a Firebase object name
/// stays one object instead of extra URL segments.
StorageObjectLocation? storageObjectFromUrl(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (!trimmed.toLowerCase().startsWith('https://')) return null;
  final firebase = _firebaseUrl.firstMatch(trimmed);
  if (firebase != null) {
    if (!_firebaseHost(firebase.group(1)!)) return null;
    return StorageObjectLocation(
      kind: 'firebase',
      bucket: _decode(firebase.group(2)!),
      objectPath: _decode(firebase.group(3)!),
    );
  }
  final gcs = _gcsUrl.firstMatch(trimmed);
  if (gcs == null) return null;
  final objectPath = gcs.group(2)!.split('/').map(_decode).join('/');
  return StorageObjectLocation(
    kind: 'gcs',
    bucket: _decode(gcs.group(1)!),
    objectPath: objectPath,
  );
}

String _publicStorageUrl(StorageObjectLocation located, String objectPath) {
  if (located.kind == 'gcs') {
    final segments = objectPath.split('/').map(Uri.encodeComponent).join('/');
    return 'https://storage.googleapis.com/'
        '${Uri.encodeComponent(located.bucket)}/$segments';
  }
  return 'https://firebasestorage.googleapis.com/v0/b/'
      '${Uri.encodeComponent(located.bucket)}/o/'
      '${Uri.encodeComponent(objectPath)}?alt=media';
}

/// Public `_480` URL for a full-size `temples/{id}/{file}` object.
///
/// Null when [raw] is not one of those objects. The download token is
/// dropped: Storage rules allow public read, and that token belongs to the
/// full-size object. [maxLength] rejects a URL the index cannot store.
String? storageThumbUrl(String? raw, {int maxLength = 500}) {
  final located = storageObjectFromUrl(raw);
  if (located == null) return null;
  final thumbPath = thumbObjectPath(located.objectPath);
  if (thumbPath == null) return null;
  final url = _publicStorageUrl(located, thumbPath);
  if (url.length > maxLength) return null;
  return url;
}

/// `{name}_480.ext` beside a non-Storage https URL. Query and fragment stay.
String? fileThumbSibling(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (!trimmed.toLowerCase().startsWith('https://')) return null;
  if (storageObjectFromUrl(trimmed) != null) return null;
  final hashAt = trimmed.indexOf('#');
  final beforeHash = hashAt == -1 ? trimmed : trimmed.substring(0, hashAt);
  final fragment = hashAt == -1 ? '' : trimmed.substring(hashAt);
  final queryAt = beforeHash.indexOf('?');
  final withoutQuery = queryAt == -1
      ? beforeHash
      : beforeHash.substring(0, queryAt);
  final query = queryAt == -1 ? '' : beforeHash.substring(queryAt);
  final slash = withoutQuery.lastIndexOf('/');
  if (slash < 'https://'.length) return null;
  final ext = _imageFile.firstMatch(_decode(withoutQuery.substring(slash + 1)));
  if (ext == null) return null;
  final stem = ext.group(1)!;
  if (stem.isEmpty || _alreadyThumb.hasMatch(stem)) return null;
  final name = Uri.encodeComponent('${stem}_480.${ext.group(2)}');
  return '${withoutQuery.substring(0, slash + 1)}$name$query$fragment';
}
