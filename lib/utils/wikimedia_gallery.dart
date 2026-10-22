import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Long edge requested for a legacy Commons file in the detail gallery.
///
/// List covers stay at 500px. This cap is only for `images[]` display.
const int kWikimediaGalleryCapPx = 1280;

/// Result of [capLegacyWikimediaImage].
///
/// [reason] is null when [url] is a 1280px thumb that should replace the
/// input. Otherwise [url] is the trimmed input and [reason] says why it was
/// left alone.
class WikimediaImageCap {
  const WikimediaImageCap({required this.url, this.reason});

  final String url;
  final String? reason;

  bool get rewrites => reason == null;
}

/// Detail and admin display URL for one stored gallery string.
///
/// An `upload.wikimedia.org` original becomes
/// `/wikipedia/commons/thumb/<h>/<hh>/<name>/1280px-<name>`. A thumb wider
/// than 1280px is snapped to 1280px. SVG, a thumb already at or under
/// 1280px, and any host other than `upload.wikimedia.org` are unchanged.
String capLegacyWikimediaImageUrl(String raw) {
  return capLegacyWikimediaImage(raw).url;
}

/// Pure mapping. No network. See [capLegacyWikimediaImageUrl].
WikimediaImageCap capLegacyWikimediaImage(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.toLowerCase().startsWith('https://')) {
    return WikimediaImageCap(url: trimmed, reason: 'not-wikimedia');
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.toLowerCase() != 'upload.wikimedia.org') {
    return WikimediaImageCap(url: trimmed, reason: 'not-wikimedia');
  }
  // Raw path, not [Uri.path], so `%2C` and `%2F` stay inside one segment.
  final rawPath = RegExp(
    r'^[a-z][a-z0-9+.-]*://[^/?#]+([^?#]*)',
    caseSensitive: false,
  ).firstMatch(trimmed);
  final parts = (rawPath?.group(1) ?? '').split('/');
  if (parts.length < 4 || parts[1].toLowerCase() != 'wikipedia') {
    return WikimediaImageCap(url: trimmed, reason: 'unrecognized');
  }
  if (parts[2].toLowerCase() != 'commons') {
    return WikimediaImageCap(url: trimmed, reason: 'not-commons');
  }
  if (parts[3].toLowerCase() == 'thumb') {
    return _capThumb(trimmed, parts);
  }
  return _capOriginal(trimmed, parts);
}

WikimediaImageCap _keep(String url, String reason) {
  return WikimediaImageCap(url: url, reason: reason);
}

WikimediaImageCap _capThumb(String trimmed, List<String> parts) {
  if (parts.length != 8) return _keep(trimmed, 'unrecognized');
  final h = parts[4];
  final hh = parts[5];
  final file = parts[6];
  final last = parts[7];
  if (!RegExp(r'^[0-9a-f]$', caseSensitive: false).hasMatch(h) ||
      !RegExp(r'^[0-9a-f]{2}$', caseSensitive: false).hasMatch(hh) ||
      file.isEmpty ||
      last.isEmpty) {
    return _keep(trimmed, 'unrecognized');
  }
  final sized = RegExp(
    r'^(\d+)px-(.+)$',
    caseSensitive: false,
  ).firstMatch(last);
  if (sized == null) return _keep(trimmed, 'unrecognized');
  if (_isSvgName(file) || _isSvgName(sized.group(2)!)) {
    return _keep(trimmed, 'svg');
  }
  final width = int.tryParse(sized.group(1)!) ?? 0;
  if (width <= kWikimediaGalleryCapPx) {
    return _keep(trimmed, 'at-or-under-1280');
  }
  return WikimediaImageCap(url: _narrowLastSegment(trimmed));
}

WikimediaImageCap _capOriginal(String trimmed, List<String> parts) {
  if (parts.contains('thumb')) return _keep(trimmed, 'unrecognized');
  final String rawName;
  String? givenH;
  String? givenHh;
  if (parts.length == 4) {
    rawName = parts[3];
  } else if (parts.length == 6) {
    givenH = parts[3];
    givenHh = parts[4];
    rawName = parts[5];
  } else {
    return _keep(trimmed, 'unrecognized');
  }
  if (rawName.isEmpty) return _keep(trimmed, 'unrecognized');
  final decoded = _safeDecode(rawName).replaceAll(' ', '_');
  if (decoded.isEmpty || decoded.contains('/') || decoded.contains('\\')) {
    return _keep(trimmed, 'unrecognized');
  }
  if (_isSvgName(decoded)) return _keep(trimmed, 'svg');
  if (_isUntouchable(decoded)) return _keep(trimmed, 'not-thumbnailable');
  final digest = md5.convert(utf8.encode(decoded)).toString();
  final h = digest[0];
  final hh = digest.substring(0, 2);
  if (givenH != null &&
      (givenH.toLowerCase() != h || givenHh!.toLowerCase() != hh)) {
    return _keep(trimmed, 'hash-mismatch');
  }
  final encoded = _commonsEncode(decoded);
  final thumbFile = _thumbFileName(decoded, encoded);
  if (thumbFile == null) return _keep(trimmed, 'not-thumbnailable');
  return WikimediaImageCap(
    url:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/$h/$hh/$encoded/$thumbFile',
  );
}

String _narrowLastSegment(String trimmed) {
  final hashAt = trimmed.indexOf('#');
  final noHash = hashAt == -1 ? trimmed : trimmed.substring(0, hashAt);
  final queryAt = noHash.indexOf('?');
  final path = queryAt == -1 ? noHash : noHash.substring(0, queryAt);
  final suffix = trimmed.substring(path.length);
  final slash = path.lastIndexOf('/');
  final last = path.substring(slash + 1);
  final next = last.replaceFirst(
    RegExp(r'^\d+px-', caseSensitive: false),
    '${kWikimediaGalleryCapPx}px-',
  );
  return '${path.substring(0, slash + 1)}$next$suffix';
}

bool _isSvgName(String name) {
  final lower = _safeDecode(name).replaceAll(' ', '_').toLowerCase();
  return lower.endsWith('.svg') ||
      lower.endsWith('.svgz') ||
      RegExp(r'\.svg\.(png|jpe?g)$').hasMatch(lower);
}

bool _isUntouchable(String decoded) {
  return RegExp(
    r'\.(pdf|djvu|webm|ogv)$',
    caseSensitive: false,
  ).hasMatch(decoded);
}

/// Thumb filename for a Commons original. TIFF becomes JPEG.
/// SVG and non-image types return null so the caller keeps the original.
String? _thumbFileName(String decoded, String encoded) {
  final lower = decoded.toLowerCase();
  final width = '${kWikimediaGalleryCapPx}px';
  if (lower.endsWith('.svg') || lower.endsWith('.svgz')) return null;
  if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
    return '$width-$encoded.jpg';
  }
  if (_isUntouchable(decoded)) return null;
  if (!RegExp(r'\.[a-z0-9]+$', caseSensitive: false).hasMatch(lower)) {
    return null;
  }
  return '$width-$encoded';
}

String _safeDecode(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

/// MediaWiki path encoding. Commas stay literal so this matches
/// `scripts/temple_index.js`.
String _commonsEncode(String name) {
  return Uri.encodeComponent(name).replaceAllMapped(
    RegExp(
      r'%27|%21|%2A|%28|%29|%7E|%3B|%40|%24|%2C|%3A',
      caseSensitive: false,
    ),
    (match) => Uri.decodeComponent(match.group(0)!),
  );
}
