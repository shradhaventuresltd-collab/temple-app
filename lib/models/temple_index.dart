import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/detail_honesty.dart';

/// `temple_index/{stateSlug}` — one shard per state.
const String kTempleIndexCollection = 'temple_index';

/// `meta/temple_index` cache stamp, written in the same batch as a shard entry.
const String kTempleIndexMetaCollection = 'meta';
const String kTempleIndexMetaDocId = 'temple_index';

/// Entry schema version stored on each summary as `v`.
const int kTempleIndexEntryVersion = 1;

/// Rules reject a shard whose `entries` key set grows past this.
///
/// 400 trimmed summaries stay under Firestore's 1 MiB document cap. A state
/// that outgrows the cap is not written. Splitting one state across more
/// than one shard is a later change; do not raise this to fit a larger state.
const int kTempleIndexMaxEntries = 400;

/// States and union territories, plus a little room for `unknown`.
const int kTempleIndexMaxShards = 48;

/// Browse cards need a short line, not the 500-character temple address.
/// Leading address kept for search. 400 max-size entries, plus a lithograph
/// caption, still fit under 1 MiB. Temple documents may store up to 500.
const int kTempleIndexShortAddressMax = 340;

/// `coverThumb` is a URL, capped so a shard of summaries stays small.
const int kTempleIndexCoverThumbMax = 500;

/// Commons thumb width requested for a non-standard or full-size original.
/// Wikimedia's ladder includes 500 and rejects 480 with HTTP 400. Cards
/// still decode at about 480px.
const int kCommonsThumbPx = 500;

/// Widths Wikimedia serves for a hotlinked thumb (w.wiki/GHai).
const Set<int> kWikimediaThumbSteps = {
  20,
  40,
  60,
  120,
  250,
  330,
  500,
  960,
  1280,
  1920,
  3840,
};

/// List covers only. Widths above 500, including 960, 1280, 1920, and
/// 3840, become 500. 480 becomes 500. Any other non-standard width below
/// 500 becomes 330. A listed width of 500 or below stays. Detail still
/// shows the stored gallery URL.
int _commonsThumbWidth(int width) {
  if (width == 480 || width > kCommonsThumbPx) return kCommonsThumbPx;
  if (kWikimediaThumbSteps.contains(width)) return width;
  return 330;
}

/// Trimmed so 400 entries stay under 1 MiB. Ids are not trimmed; they are
/// the map key and already limited to 200 characters.
const int kTempleIndexNameMax = 80;
const int kTempleIndexCityMax = 40;
const int kTempleIndexStateMax = 40;
const int kTempleIndexDeityMax = 60;

const int kTempleIndexAltNameMax = 8;
const int kTempleIndexAltNameLength = 80;

/// Firestore's per-document limit, in bytes.
const int kTempleIndexDocumentByteLimit = 1048576;

/// Readable admin error when a save would be the 401st entry in a state.
///
/// The save is not written. Splitting that state across shards comes later.
String templeIndexShardFullMessage({
  required String state,
  required int count,
}) {
  final label = state.trim().isEmpty ? 'This state' : state.trim();
  return '$label already has $count temples in the browse index '
      '(the cap is $kTempleIndexMaxEntries). '
      'This save was not written. '
      'Splitting one state across more than one shard is a later change.';
}

final RegExp _indexIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,200}$');

/// Map keys and shard ids. Dots would nest a field path, so they are refused.
void assertTempleIndexId(String id) {
  if (!_indexIdPattern.hasMatch(id)) {
    throw StateError('Temple id "$id" cannot be used as an index entry key.');
  }
}

/// Shard id for a temple's `state` string. Same slug rule as temple documents.
String templeIndexStateSlug(String state) {
  final slug = state
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) return 'unknown';
  return slug;
}

/// Tradition and living/heritage flags copied from [DetailHonesty].
///
/// Browse can show these without the description, story, or timings text.
class TempleIndexFlags {
  const TempleIndexFlags({
    required this.tradition,
    required this.living,
    required this.framing,
  });

  /// `jain`, `buddhist`, `sikh`, or `unspecified`.
  final String tradition;

  /// True only when the listing reads as a living temple.
  final bool living;

  /// `living`, `monument`, or `neutral`.
  final String framing;
}

TempleIndexFlags templeIndexFlagsFor(Temple temple) {
  final honesty = DetailHonesty.of(temple);
  final framing = switch (honesty.framing) {
    SiteFraming.livingTemple => 'living',
    SiteFraming.monumentVisit => 'monument',
    SiteFraming.neutral => 'neutral',
  };
  return TempleIndexFlags(
    tradition: honesty.tradition.name,
    living: framing == 'living',
    framing: framing,
  );
}

/// Collapses whitespace and keeps the leading searchable text.
///
/// The cut is a word boundary inside [kTempleIndexShortAddressMax]. A comma
/// inside that window stays, so a place name after the comma can still match
/// search. Words that start past the cap do not fit in the shard budget.
String shortTempleAddress(String raw) {
  final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= kTempleIndexShortAddressMax) return text;
  var cut = text.substring(0, kTempleIndexShortAddressMax);
  final space = cut.lastIndexOf(' ');
  if (space >= 40) cut = cut.substring(0, space);
  return cut.trimRight().replaceFirst(RegExp(r'[,\s]+$'), '');
}

/// Browse cover for one temple document.
///
/// Same photo as [verifiedCoverUrl]: the first verified URL in `images`,
/// or `imageUrl` when `images` is empty. Placeholder hosts are skipped.
///
/// A stored `photos[].thumbUrl` is used as written unless it is a Commons
/// thumb, which is snapped the same way. Widths above 500, including 960,
/// 1280, 1920, and 3840, become 500px. 480px becomes 500px. Any other
/// non-standard width below 500 becomes 330px. A listed width of 500 or
/// below stays. A Commons original
/// `.../commons/<h>/<hh>/<name>` becomes a 500px thumb when `<h>/<hh>`
/// match the MD5 of the underscored filename. An SVG thumb appends `.png`.
/// A TIFF thumb appends `.jpg`. PDF, DjVu, WebM, OGV, and anything else
/// stay the full URL. Storage siblings are not invented. The
/// result is at most [kTempleIndexCoverThumbMax] characters. Detail keeps
/// the full gallery URL.
String? coverThumbFor(Map<String, dynamic> data) {
  final source = firstVerifiedGalleryUrl(data);
  if (source == null) return null;
  final explicit = _explicitThumb(data, source);
  if (explicit != null) return _wikimedia480(explicit) ?? explicit;
  final wiki = _wikimedia480(source);
  if (wiki != null) return wiki;
  return _fullCover(source, credit: _photoCredit(data, source));
}

String? _explicitThumb(Map<String, dynamic> data, String source) {
  final photos = data['photos'];
  if (photos is! List) return null;
  for (final photo in photos) {
    if (photo is! Map) continue;
    final url = photo['url'];
    if (url is! String || url.trim() != source) continue;
    final credit = photo['credit'];
    final thumb = _knownThumbUrl(
      photo['thumbUrl'],
      credit: credit is String ? credit : null,
    );
    if (thumb != null) return thumb;
  }
  return null;
}

String? _photoCredit(Map<String, dynamic> data, String url) {
  final photos = data['photos'];
  if (photos is! List) return null;
  for (final photo in photos) {
    if (photo is! Map) continue;
    final raw = photo['url'];
    if (raw is! String || raw.trim() != url) continue;
    final credit = photo['credit'];
    return credit is String ? credit : null;
  }
  return null;
}

/// Unrewritten gallery URL [coverThumbFor] is taken from.
String? firstVerifiedGalleryUrl(Map<String, dynamic> data) {
  for (final url in _galleryCandidates(data)) {
    if (!_httpUrl(url) || isDisallowedImageUrl(url, credit: _photoCredit(data, url))) {
      continue;
    }
    return url;
  }
  return null;
}

List<String> _galleryCandidates(Map<String, dynamic> data) {
  final images = data['images'];
  final urls = <String>[];
  if (images is List) {
    for (final item in images) {
      if (item is! String) continue;
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      urls.add(trimmed);
    }
  }
  if (urls.isNotEmpty) return urls;
  final imageUrl = data['imageUrl'];
  if (imageUrl is String && imageUrl.trim().isNotEmpty) {
    return [imageUrl.trim()];
  }
  return const [];
}

/// URL list helper. Prefer [coverThumbFor] so the gallery order stays put.
///
/// Wikimedia thumbs that are not on [kWikimediaThumbSteps] are rewritten
/// to 500px, or to 330px when the stored width is below 500 and is not 480.
/// Other URLs stay full size.
String? coverThumbFromUrls(Iterable<Object?> urls) {
  for (final raw in urls) {
    if (raw is! String) continue;
    final wiki = _wikimedia480(raw);
    if (wiki != null) return wiki;
  }
  for (final raw in urls) {
    final full = _fullCover(raw);
    if (full != null) return full;
  }
  return null;
}

String? _knownThumbUrl(Object? raw, {String? credit}) {
  if (raw is! String) return null;
  return _fullCover(raw, credit: credit);
}

String? _fullCover(Object? raw, {String? credit}) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (!_httpUrl(trimmed) || isDisallowedImageUrl(trimmed, credit: credit)) return null;
  if (trimmed.length > kTempleIndexCoverThumbMax) return null;
  return trimmed;
}

/// Wikimedia URL on the thumbnail ladder, or null when [raw] is not a
/// Commons file.
///
/// An existing `/thumb/` above 500px, including 960, 1280, 1920, and 3840,
/// becomes 500px. 480px becomes 500px. Any other non-standard width below
/// 500 becomes 330px. A listed width of 500 or below stays. An original
/// `.../commons/<h>/<hh>/<name>` becomes a 500px thumb.
String? _wikimedia480(Object? raw) {
  final trimmed = _fullCover(raw);
  if (trimmed == null) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  final decodedPath = Uri.decodeFull(uri.path);
  if (!decodedPath.contains('/thumb/')) return _commonsOriginal480(trimmed);
  return trimmed.replaceFirstMapped(RegExp(r'/(\d+)px-([^/?#]+)'), (match) {
    final width = int.tryParse(match.group(1)!) ?? 0;
    final next = _commonsThumbWidth(width);
    if (next == width) return match.group(0)!;
    return '/${next}px-${match.group(2)}';
  });
}

String? _commonsOriginal480(String trimmed) {
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.toLowerCase() != 'upload.wikimedia.org') {
    return null;
  }
  final raw = RegExp(
    r'^[a-z][a-z0-9+.-]*://[^/?#]+([^?#]*)',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (raw == null) return null;
  final parts = raw.group(1)!.split('/');
  if (parts.length < 4 ||
      parts[1].toLowerCase() != 'wikipedia' ||
      parts[2].toLowerCase() != 'commons') {
    return null;
  }
  if (parts.contains('thumb')) return null;
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
    return null;
  }
  if (rawName.isEmpty) return null;
  final decoded = _commonsDecode(rawName).replaceAll(' ', '_');
  if (decoded.isEmpty || decoded.contains('/') || decoded.contains('\\')) {
    return null;
  }
  final digest = md5.convert(utf8.encode(decoded)).toString();
  final h = digest[0];
  final hh = digest.substring(0, 2);
  if (givenH != null &&
      (givenH.toLowerCase() != h || givenHh!.toLowerCase() != hh)) {
    return null;
  }
  final encoded = _commonsEncode(decoded);
  final thumbFile = _commonsThumbName(decoded, encoded);
  if (thumbFile == null) return null;
  final next =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/$h/$hh/$encoded/$thumbFile';
  if (next.length > kTempleIndexCoverThumbMax) return null;
  return next;
}

String _commonsDecode(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

/// Thumb filename for a Commons original. SVG becomes PNG. TIFF becomes
/// JPEG. PDF, DjVu, WebM, and OGV are not rewritten.
String? _commonsThumbName(String decoded, String encoded) {
  final lower = decoded.toLowerCase();
  if (lower.endsWith('.svg')) return '${kCommonsThumbPx}px-$encoded.png';
  if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
    return '${kCommonsThumbPx}px-$encoded.jpg';
  }
  if (lower.endsWith('.pdf') ||
      lower.endsWith('.djvu') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.ogv')) {
    return null;
  }
  return '${kCommonsThumbPx}px-$encoded';
}

/// MediaWiki path encoding. Commas stay literal so Dart and JS match.
String _commonsEncode(String name) {
  return Uri.encodeComponent(name).replaceAllMapped(
    RegExp(
      r'%27|%21|%2A|%28|%29|%7E|%3B|%40|%24|%2C|%3A',
      caseSensitive: false,
    ),
    (match) => Uri.decodeComponent(match.group(0)!),
  );
}

bool _httpUrl(String trimmed) {
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// `lat`/`lng` for an index entry. Missing numbers and the (0, 0) placeholder
/// are null. A real zero on only one axis is kept. Both axes are doubles,
/// including a whole-degree longitude.
({double? lat, double? lng}) templeIndexCoordinates(Map<String, dynamic> data) {
  final lat = data['latitude'];
  final lng = data['longitude'];
  if (lat is! num || lng is! num) return (lat: null, lng: null);
  if (lat == 0 && lng == 0) return (lat: null, lng: null);
  return (lat: lat.toDouble(), lng: lng.toDouble());
}

List<String>? _altNames(Object? raw) {
  if (raw is! List) return null;
  final names = <String>[];
  for (final item in raw) {
    if (item is! String) continue;
    final trimmed = item.trim();
    if (trimmed.isEmpty) continue;
    names.add(
      trimmed.length <= kTempleIndexAltNameLength
          ? trimmed
          : trimmed.substring(0, kTempleIndexAltNameLength),
    );
    if (names.length == kTempleIndexAltNameMax) break;
  }
  if (names.isEmpty) return null;
  return names;
}

String _text(Object? value) => value is String ? value.trim() : '';

String _clip(Object? value, int max) {
  final collapsed = _text(value).replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.length <= max) return collapsed;
  return collapsed.substring(0, max).trimRight();
}

/// Lean `entries.{id}` value. `updatedAt` is null here; the writer stamps it.
///
/// [data] is the temple document (or the merged admin payload). Descriptions,
/// timings, and `photos` are read only to derive [TempleIndexFlags].
Map<String, dynamic> templeIndexEntryFromMap(
  String id,
  Map<String, dynamic> data,
) {
  assertTempleIndexId(id);
  final temple = Temple.fromMap(id, data);
  final flags = templeIndexFlagsFor(temple);
  final coords = templeIndexCoordinates(data);
  final cover = coverThumbFor(data);
  final address = shortTempleAddress(
    _text(data['address']).isNotEmpty
        ? _text(data['address'])
        : _text(data['location']),
  );
  final altNames = data.containsKey('altNames')
      ? _altNames(data['altNames'])
      : null;
  final entry = <String, dynamic>{
    'id': id,
    'slug': id,
    'name': _clip(data['name'], kTempleIndexNameMax),
    'city': _clip(data['city'], kTempleIndexCityMax),
    'state': _clip(data['state'], kTempleIndexStateMax),
    'deity': _clip(data['deity'], kTempleIndexDeityMax),
    'address': address,
    'coverThumb': cover,
    'lat': coords.lat,
    'lng': coords.lng,
    'updatedAt': null,
    'v': kTempleIndexEntryVersion,
    'tradition': flags.tradition,
    'living': flags.living,
    'framing': flags.framing,
  };
  if (altNames != null) entry['altNames'] = altNames;
  if (data.containsKey('published') && data['published'] is bool) {
    entry['published'] = data['published'];
  }
  if (data.containsKey('hidden') && data['hidden'] is bool) {
    entry['hidden'] = data['hidden'];
  }
  final source = firstVerifiedGalleryUrl(data);
  final caption = _indexCoverCaption(temple.photos, source, cover);
  if (caption != null) entry['coverCaption'] = caption;
  return entry;
}

String? _indexCoverCaption(
  List<TemplePhoto> photos,
  String? source,
  String? cover,
) {
  if (source != null) {
    final fromSource = historicalCoverCaption(photos, source);
    if (fromSource != null) return fromSource;
  }
  if (cover != null && cover != source) {
    return historicalCoverCaption(photos, cover);
  }
  return null;
}

/// Browse card built from one `entries.{id}` value. Description, story, and
/// timings stay empty; the detail screen loads `temples/{id}` for those.
Temple templeFromIndexEntry(Map<String, dynamic> entry) {
  final id = _text(entry['id']).isNotEmpty
      ? _text(entry['id'])
      : _text(entry['slug']);
  final cover = _text(entry['coverThumb']);
  final caption = _text(entry['coverCaption']);
  final coords = templeIndexCoordinates({
    'latitude': entry['lat'],
    'longitude': entry['lng'],
  });
  return Temple(
    id: id,
    name: _text(entry['name']),
    state: _text(entry['state']),
    city: _text(entry['city']),
    deity: _text(entry['deity']),
    imageUrl: cover,
    images: cover.isEmpty ? const [] : [cover],
    description: '',
    story: '',
    location: _text(entry['address']),
    timings: null,
    specialities: const [],
    latitude: coords.lat,
    longitude: coords.lng,
    indexTradition: _text(entry['tradition']).isEmpty
        ? 'unspecified'
        : _text(entry['tradition']),
    indexFraming: _text(entry['framing']).isEmpty
        ? 'neutral'
        : _text(entry['framing']),
    coverCaption: caption.isEmpty ? null : caption,
  );
}

/// Milliseconds for a meta shard stamp. Null when the value is not a time.
int? indexStampMillis(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is int) return value;
  final millis = _tryMillis(value);
  return millis;
}

int? _tryMillis(Object value) {
  try {
    final dynamic stamp = value;
    final dynamic millis = stamp.millisecondsSinceEpoch;
    if (millis is int) return millis;
  } catch (_) {}
  return null;
}

/// True when both stamps are times and name the same instant.
bool sameIndexStamp(Object? cached, Object? server) {
  final left = indexStampMillis(cached);
  final right = indexStampMillis(server);
  if (left == null || right == null) return false;
  return left == right;
}

/// One shard the browse load will read.
class IndexShardRead {
  const IndexShardRead({required this.slug, required this.fromCache});

  final String slug;

  /// True when this device already applied the server stamp.
  final bool fromCache;
}

/// Shards to read after the server meta.
///
/// A shard comes from the local cache only when the stamp this device last
/// applied matches the server meta stamp. The cached meta document is not
/// consulted: a failed shard fetch must not look applied. Anything else is
/// a server read. Slugs are sorted so the browse order does not depend on
/// map order.
List<IndexShardRead> planIndexShardReads({
  required Map<String, int> appliedStamps,
  required Map<String, Object?> serverStamps,
}) {
  final slugs = serverStamps.keys.toList()..sort();
  return [
    for (final slug in slugs)
      IndexShardRead(
        slug: slug,
        fromCache: sameIndexStamp(appliedStamps[slug], serverStamps[slug]),
      ),
  ];
}

/// Browse filter. The client drops hidden or explicitly unpublished entries.
///
/// When `hidden` or `published` is present on an entry, the index lists the
/// temple only if it is not hidden and not explicitly unpublished. Missing
/// flags stay listed.
bool templeIndexEntryListed(Map<String, dynamic> entry) {
  if (entry['hidden'] == true) return false;
  if (entry['published'] == false) return false;
  return true;
}

/// What one admin commit does to the index. The entries map is not loaded.
class TempleIndexPlan {
  const TempleIndexPlan({
    required this.id,
    required this.upsertShard,
    required this.entry,
    required this.removeShard,
    required this.metaShards,
  });

  final String id;
  final String? upsertShard;
  final Map<String, dynamic>? entry;

  /// Set when the temple left this shard. Null when the state did not change.
  final String? removeShard;
  final List<String> metaShards;

  bool get touchesIndex => upsertShard != null || removeShard != null;
}

/// [next] is the temple payload. Null deletes the entry.
/// [previous] is the stored temple, used for a state move and for optional
/// fields the payload does not carry (`altNames`, `published`, `hidden`).
TempleIndexPlan planTempleIndex({
  required String id,
  Map<String, dynamic>? next,
  Map<String, dynamic>? previous,
}) {
  assertTempleIndexId(id);
  if (next == null) {
    final removeShard = previous == null
        ? null
        : templeIndexStateSlug(_text(previous['state']));
    return TempleIndexPlan(
      id: id,
      upsertShard: null,
      entry: null,
      removeShard: removeShard,
      metaShards: [?removeShard],
    );
  }

  final merged = <String, dynamic>{...?previous, ...next};
  final entry = templeIndexEntryFromMap(id, merged);
  final shard = templeIndexStateSlug(_text(merged['state']));
  final previousSlug = previous == null
      ? null
      : templeIndexStateSlug(_text(previous['state']));
  final removeShard = previousSlug != null && previousSlug != shard
      ? previousSlug
      : null;
  return TempleIndexPlan(
    id: id,
    upsertShard: shard,
    entry: entry,
    removeShard: removeShard,
    metaShards: [shard, ?removeShard],
  );
}

int _stringBytes(String value) => value.length + 1;

/// Upper bound, in bytes, of a shard holding [entryCount] max-size entries.
///
/// 400 must stay under [kTempleIndexDocumentByteLimit].
int estimateTempleIndexShardBytes([int entryCount = kTempleIndexMaxEntries]) {
  const strings = <String, int>{
    'id': 200,
    'slug': 200,
    'name': kTempleIndexNameMax,
    'city': kTempleIndexCityMax,
    'state': kTempleIndexStateMax,
    'deity': kTempleIndexDeityMax,
    'address': kTempleIndexShortAddressMax,
    'coverThumb': kTempleIndexCoverThumbMax,
    'coverCaption': 16,
    'tradition': 11,
    'framing': 8,
  };
  var entry = 32;
  for (final field in strings.entries) {
    entry += _stringBytes(field.key) + field.value + 1;
  }
  for (final name in ['lat', 'lng', 'v', 'updatedAt']) {
    entry += _stringBytes(name) + 8;
  }
  for (final name in ['living', 'published', 'hidden']) {
    entry += _stringBytes(name) + 1;
  }
  entry += _stringBytes('altNames') + 32;
  entry += kTempleIndexAltNameMax * (kTempleIndexAltNameLength + 1);
  entry += 201;
  final overhead =
      _stringBytes('temple_index') +
      _stringBytes('x' * 80) +
      _stringBytes('entries') +
      32;
  return overhead + entry * entryCount;
}
