import 'package:temple_app/models/temple.dart';
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
/// 400 summaries stay well under the 1 MiB document cap at the size of one
/// browse entry. The directory target is about 50 temples per state.
const int kTempleIndexMaxEntries = 400;

/// States and union territories, plus a little room for `unknown`.
const int kTempleIndexMaxShards = 48;

/// Browse cards need a short line, not the 500-character temple address.
const int kTempleIndexShortAddressMax = 120;

/// `coverThumb` is a URL, capped so a shard of summaries stays small.
const int kTempleIndexCoverThumbMax = 500;

const int kTempleIndexAltNameMax = 8;
const int kTempleIndexAltNameLength = 80;

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

/// Collapses whitespace and keeps at most [kTempleIndexShortAddressMax]
/// characters, breaking on a comma when that still leaves a useful line.
String shortTempleAddress(String raw) {
  final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= kTempleIndexShortAddressMax) return text;
  final cut = text.substring(0, kTempleIndexShortAddressMax);
  final comma = cut.lastIndexOf(',');
  if (comma >= 40) return cut.substring(0, comma).trimRight();
  return cut.trimRight();
}

/// Browse cover for one temple document.
///
/// Order: `photos[0].thumbUrl`, then a `_480` file on `photos[0]`, then
/// `imageUrl`, then `images[0]`. Wikimedia `/thumb/` URLs wider than 480px
/// are rewritten to `480px`. Placeholder hosts are skipped. The result is
/// at most [kTempleIndexCoverThumbMax] characters.
///
/// TODO(KAN-146): cover thumbnails are not generated yet. Until they exist,
/// a full-size `imageUrl` or `images[0]` is stored instead of null.
String? coverThumbFor(Map<String, dynamic> data) {
  final photo = _firstPhoto(data['photos']);
  final photoThumb = photo == null ? null : photo['thumbUrl'];
  final photoUrl = photo == null ? null : photo['url'];
  final fromPhoto =
      _usableCover(photoThumb, allowFull: true) ??
      _usableCover(_is480File(photoUrl) ? photoUrl : null, allowFull: false);
  if (fromPhoto != null) return fromPhoto;
  final fromCover = _usableCover(data['imageUrl'], allowFull: true);
  if (fromCover != null) return fromCover;
  return _usableCover(_firstListItem(data['images']), allowFull: true);
}

/// URL list helper. Prefer [coverThumbFor] so `photos[0]` stays first.
String? coverThumbFromUrls(Iterable<Object?> urls) {
  for (final raw in urls) {
    final thumb = _browseThumb(raw);
    if (thumb != null) return thumb;
  }
  // TODO(KAN-146): drop the full-URL fallback once thumbs exist.
  for (final raw in urls) {
    final full = _usableCover(raw, allowFull: true);
    if (full != null) return full;
  }
  return null;
}

Map<String, Object?>? _firstPhoto(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  final first = raw.first;
  if (first is Map) return Map<String, Object?>.from(first);
  if (first is String) return {'url': first};
  return null;
}

Object? _firstListItem(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  return raw.first;
}

bool _is480File(Object? raw) {
  if (raw is! String) return false;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return false;
  return RegExp(
    r'[_-]480\.(jpe?g|png|webp)$',
    caseSensitive: false,
  ).hasMatch(Uri.decodeFull(uri.path));
}

String? _usableCover(Object? raw, {required bool allowFull}) {
  final thumb = _browseThumb(raw);
  if (thumb != null) return thumb;
  if (!allowFull) return null;
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (!_httpUrl(trimmed) || isPlaceholderImageUrl(trimmed)) return null;
  if (trimmed.length > kTempleIndexCoverThumbMax) return null;
  return trimmed;
}

String? _browseThumb(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (!_httpUrl(trimmed) || isPlaceholderImageUrl(trimmed)) return null;
  if (trimmed.length > kTempleIndexCoverThumbMax) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  final decodedPath = Uri.decodeFull(uri.path);
  if (RegExp(
    r'[_-]480\.(jpe?g|png|webp)$',
    caseSensitive: false,
  ).hasMatch(decodedPath)) {
    return trimmed;
  }
  if (!decodedPath.contains('/thumb/')) return null;
  return trimmed.replaceFirstMapped(RegExp(r'/(\d+)px-([^/?#]+)'), (match) {
    final width = int.tryParse(match.group(1)!) ?? 0;
    if (width <= 480) return match.group(0)!;
    return '/480px-${match.group(2)}';
  });
}

bool _httpUrl(String trimmed) {
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// `lat`/`lng` for an index entry. Missing numbers and the (0, 0) placeholder
/// are null. A real zero on only one axis is kept.
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
    'name': _text(data['name']),
    'city': _text(data['city']),
    'state': _text(data['state']),
    'deity': _text(data['deity']),
    'address': address,
    'coverThumb': coverThumbFor(data),
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
  return entry;
}

/// Browse filter hook for KAN-145. The client still reads `temples` and does
/// not call this yet.
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
