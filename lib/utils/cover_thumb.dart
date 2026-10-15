// Storage object names for a temple photo and its `_480` thumb.
//
// Kept in step with `scripts/temple_index.js` (`thumbObjectPath`,
// `fullCoverUrlFromThumb`). `coverThumb` does not invent a sibling URL.
// The card asks [fullCoverUrlFromThumb] only after the stored thumb fails.

final RegExp _imageFile = RegExp(
  r'^(.*)\.(jpe?g|png|webp)$',
  caseSensitive: false,
);
final RegExp _alreadyThumb = RegExp(
  r'_480_g\d+(?:u\d+)?(?:_[A-Za-z0-9]+)?$|[_-]480$',
  caseSensitive: false,
);
final RegExp _thumbFile = RegExp(
  r'_480_g(\d+)(?:u(\d+))?(?:_([A-Za-z0-9]+))?\.jpg$',
  caseSensitive: false,
);

final RegExp _firebaseUrl = RegExp(
  r'^https://([^/?#]+)/v0/b/([^/?#]+)/o/([^?#]+)',
  caseSensitive: false,
);
final RegExp _gcsUrl = RegExp(
  r'^https://storage\.googleapis\.com/([^/?#]+)/([^?#]+)',
  caseSensitive: false,
);
final RegExp _gsUrl = RegExp(
  r'^gs://([^/?#]+)/([^?#]+)',
  caseSensitive: false,
);
final RegExp _rawPath = RegExp(
  r'^[a-z][a-z0-9+.-]*://[^/?#]+([^?#]*)',
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

/// `temples/{id}/{file}_480_g{generation}.jpg` for a full-size temple photo.
///
/// [generation] is the source object's Storage generation, so a replaced
/// original gets a new object and the immutable cache of the old thumb stays
/// on the old URL. A non-jpg source keeps its extension in the name
/// (`hero_480_g42_PNG.jpg`) so a failed card can request that original once.
/// Already-thumb names return null. Extension case of a non-jpg source is kept.
String? thumbObjectPath(
  String objectPath, {
  required String generation,
  int? updatedMillis,
}) {
  final parts = objectPath.split('/');
  if (parts.length != 3 || parts[0] != 'temples') return null;
  final id = parts[1];
  if (id.isEmpty || id == '.' || id == '..') return null;
  final ext = _imageFile.firstMatch(parts[2]);
  if (ext == null) return null;
  final stem = ext.group(1)!;
  if (stem.isEmpty || _alreadyThumb.hasMatch(stem)) return null;
  if (!RegExp(r'^\d+$').hasMatch(generation)) return null;
  final sourceExt = ext.group(2)!;
  final suffix = sourceExt == 'jpg' ? '' : '_$sourceExt';
  final bust = updatedMillis == null ? '' : 'u$updatedMillis';
  return 'temples/$id/${stem}_480_g$generation$bust$suffix.jpg';
}

/// Object name on `https://<bucket>.firebasestorage.app`.
///
/// `/o/<encoded>` is one Storage object. `/o/temples/...` and `/temples/...`
/// name that object with the slashes left in the path.
String? _firebaseHostObjectPath(String rawPath) {
  if (rawPath.isEmpty) return null;
  final path = rawPath.replaceAll(RegExp(r'/+$'), '');
  final encoded = RegExp(r'^/o/([^/]+)$', caseSensitive: false).firstMatch(path);
  if (encoded != null) {
    final decoded = _decode(encoded.group(1)!).replaceAll(RegExp(r'^/+|/+$'), '');
    return decoded.isEmpty ? null : decoded;
  }
  var body = path.replaceFirst(RegExp(r'^/+'), '');
  if (RegExp(r'^o/', caseSensitive: false).hasMatch(body)) {
    body = body.substring(2);
  }
  if (body.isEmpty) return null;
  return body.split('/').map(_decode).join('/');
}

/// Firebase or Cloud Storage object named by [raw].
///
/// The path is read from the raw string so `%2F` in a Firebase object name
/// stays one object instead of extra URL segments. Accepts the download URL
/// `firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded>`,
/// `https://<bucket>.firebasestorage.app/...`, `gs://<bucket>/<path>`, and
/// `storage.googleapis.com/<bucket>/<path>`.
StorageObjectLocation? storageObjectFromUrl(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  if (trimmed.toLowerCase().startsWith('gs://')) {
    final gs = _gsUrl.firstMatch(trimmed);
    if (gs == null) return null;
    final bucket = _decode(gs.group(1)!);
    final objectPath = gs
        .group(2)!
        .replaceAll(RegExp(r'/+$'), '')
        .split('/')
        .map(_decode)
        .join('/');
    if (bucket.isEmpty || objectPath.isEmpty) return null;
    return StorageObjectLocation(
      kind: 'gcs',
      bucket: bucket,
      objectPath: objectPath,
    );
  }
  if (!trimmed.toLowerCase().startsWith('https://')) return null;
  final firebase = _firebaseUrl.firstMatch(trimmed);
  if (firebase != null) {
    if (!_firebaseHost(firebase.group(1)!)) return null;
    final objectPath = _decode(firebase.group(3)!);
    if (objectPath.isEmpty) return null;
    return StorageObjectLocation(
      kind: 'firebase',
      bucket: _decode(firebase.group(2)!),
      objectPath: objectPath,
    );
  }
  final uri = Uri.tryParse(trimmed);
  final host = uri?.host.toLowerCase() ?? '';
  if (host.endsWith('.firebasestorage.app')) {
    final objectPath = _firebaseHostObjectPath(_rawPath.firstMatch(trimmed)?.group(1) ?? '');
    if (objectPath == null || objectPath.isEmpty) return null;
    return StorageObjectLocation(
      kind: 'firebase',
      bucket: host,
      objectPath: objectPath,
    );
  }
  final gcs = _gcsUrl.firstMatch(trimmed);
  if (gcs == null) return null;
  final objectPath = gcs.group(2)!.split('/').map(_decode).join('/');
  if (objectPath.isEmpty) return null;
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

/// Full-size object path named by a generation thumb, or by a guessed
/// `{stem}_480.{ext}` sibling. Null when [objectPath] is not one of those.
String? fullObjectPathFromThumb(String objectPath) {
  final parts = objectPath.split('/');
  if (parts.length != 3 || parts[0] != 'temples') return null;
  final id = parts[1];
  if (id.isEmpty) return null;
  final file = parts[2];
  final match = _thumbFile.firstMatch(file);
  if (match != null) {
    final stem = file.substring(0, file.length - match.group(0)!.length);
    if (stem.isEmpty) return null;
    final ext = match.group(3) ?? 'jpg';
    return 'temples/$id/$stem.$ext';
  }
  final legacy = RegExp(
    r'^(.*)_480\.(jpe?g|png|webp)$',
    caseSensitive: false,
  ).firstMatch(file);
  if (legacy == null) return null;
  final stem = legacy.group(1)!;
  if (stem.isEmpty) return null;
  return 'temples/$id/$stem.${legacy.group(2)}';
}

/// Public URL of the original object behind a `_480_g` thumb.
///
/// Used once, after the stored thumb URL fails to load. The download token
/// belongs to the thumb, so this URL has none. Storage rules allow the same
/// public read as the original. Null when [raw] is not one of our thumbs.
String? fullCoverUrlFromThumb(String? raw) {
  final located = storageObjectFromUrl(raw);
  if (located == null) return null;
  final fullPath = fullObjectPathFromThumb(located.objectPath);
  if (fullPath == null) return null;
  return _publicStorageUrl(located, fullPath);
}

final RegExp _wikiThumbSize = RegExp(r'^\d+px-');

/// Original file behind a Wikimedia `/thumb/.../NNNpx-` URL.
///
/// `thumb.wikimedia.org` is rewritten to `upload.wikimedia.org`. Null when
/// [raw] is not a Wikimedia thumb. A failed Commons thumb requests this
/// once before the placeholder.
String? wikimediaOriginalUrl(String? raw) {
  final trimmed = raw?.trim() ?? '';
  final noQuery = trimmed.split('#').first.split('?').first;
  final match = RegExp(
    r'^(https://)([^/]+)(/.*)$',
    caseSensitive: false,
  ).firstMatch(noQuery);
  if (match == null) return null;
  var host = match.group(2)!.toLowerCase();
  if (host != 'upload.wikimedia.org' && host != 'thumb.wikimedia.org') {
    return null;
  }
  if (host == 'thumb.wikimedia.org') host = 'upload.wikimedia.org';
  final parts = match.group(3)!.split('/');
  if (parts.length < 4 || !_wikiThumbSize.hasMatch(parts.last)) return null;
  final thumbAt = parts.indexOf('thumb');
  if (thumbAt <= 0 || thumbAt >= parts.length - 2) return null;
  parts.removeLast();
  parts.removeAt(thumbAt);
  final result = 'https://$host${parts.join('/')}';
  if (result == noQuery) return null;
  return result;
}
