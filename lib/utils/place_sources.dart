import 'package:temple_app/models/temple.dart';

/// Label used only when [Temple.dressCodeSourceType] is `official` and a
/// usable URL is present.
const officialTempleWebsiteLabel = 'Official temple website';

/// Footer copy when the dress-code card is visible but no http(s) URL remains.
const compiledFromPublicSources = 'Compiled from public sources';

/// How many named sites appear in the footer before "+N more".
const placeSourceFooterVisibleLimit = 3;

/// One attributed http(s) source for the dress-code footer.
class PlaceSource {
  const PlaceSource({required this.uri, required this.label});

  final Uri uri;
  final String label;

  /// Host with a leading `www.` stripped, as used for the default label.
  String get hostLabel => placeSourceHostLabel(uri);
}

/// Host of [uri] with a leading `www.` (any case) removed.
String placeSourceHostLabel(Uri uri) {
  var host = uri.host;
  if (host.length > 4 && host.substring(0, 4).toLowerCase() == 'www.') {
    host = host.substring(4);
  }
  return host;
}

/// Splits [raw] on whitespace, commas, or pipes and keeps unique http(s) URLs.
List<Uri> parseHttpSourceUrls(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return const [];
  final urls = <Uri>[];
  final seen = <String>{};
  for (final part in text.split(RegExp(r'[\s,|]+'))) {
    if (part.isEmpty) continue;
    final uri = httpSourceUri(part);
    if (uri == null) continue;
    if (seen.add(uri.toString())) urls.add(uri);
  }
  return urls;
}

/// Sources for the dress-code footer, from existing fields only.
///
/// Reads [Temple.dressCodeSourceUrl] (which may hold several URLs) and
/// [Temple.dressCodeSourceType]. Timings URLs are not included.
List<PlaceSource> dressCodeSourcesOf(Temple temple) {
  return placeSourcesFromUrls(
    parseHttpSourceUrls(temple.dressCodeSourceUrl),
    official: temple.dressCodeSourceType == 'official',
  );
}

/// Builds [PlaceSource] rows from already-parsed URIs so 2 / 3 / 4+ cases
/// can be tested even when a production document usually holds one URL.
///
/// When [official] is true, the first URL is labelled
/// [officialTempleWebsiteLabel]. Later URLs still use the host.
List<PlaceSource> placeSourcesFromUrls(
  Iterable<Uri> urls, {
  bool official = false,
}) {
  final sources = <PlaceSource>[];
  var index = 0;
  for (final uri in urls) {
    final officialLabel = official && index == 0;
    sources.add(
      PlaceSource(
        uri: uri,
        label: officialLabel
            ? officialTempleWebsiteLabel
            : placeSourceHostLabel(uri),
      ),
    );
    index++;
  }
  return sources;
}

/// Visible names, overflow count, and prefix for a source footer.
class PlaceSourceFooterLayout {
  const PlaceSourceFooterLayout({
    required this.prefix,
    required this.visible,
    required this.remaining,
  });

  /// Empty when there are no sources (the full line is
  /// [compiledFromPublicSources]).
  final String prefix;
  final List<PlaceSource> visible;
  final List<PlaceSource> remaining;

  int get moreCount => remaining.length;

  bool get isTappable => visible.isNotEmpty;

  /// Full visible line, e.g. `Source: en.wikipedia.org` or
  /// `Sources: en.wikipedia.org, openstreetmap.org +1 more`.
  String get text {
    if (visible.isEmpty) return compiledFromPublicSources;
    final names = visible.map((source) => source.label).join(', ');
    final more = moreCount > 0 ? ' +$moreCount more' : '';
    return '$prefix$names$more';
  }
}

/// Lays out [sources] for the footer: 0 / 1 / 2–3 / 4+ with at most
/// [placeSourceFooterVisibleLimit] named sites.
PlaceSourceFooterLayout placeSourceFooterLayout(
  Iterable<PlaceSource> sources, {
  int visibleLimit = placeSourceFooterVisibleLimit,
}) {
  final list = sources.toList();
  if (list.isEmpty) {
    return const PlaceSourceFooterLayout(
      prefix: '',
      visible: [],
      remaining: [],
    );
  }
  if (list.length == 1) {
    return PlaceSourceFooterLayout(
      prefix: 'Source: ',
      visible: list,
      remaining: const [],
    );
  }
  final visible = list.take(visibleLimit).toList();
  final remaining = list.length > visibleLimit
      ? list.sublist(visibleLimit)
      : const <PlaceSource>[];
  return PlaceSourceFooterLayout(
    prefix: 'Sources: ',
    visible: visible,
    remaining: remaining,
  );
}
