import 'package:temple_app/models/temple.dart';

/// How the detail screen should talk about a place, using only existing text.
enum SiteFraming {
  /// Notes describe continuing worship.
  livingTemple,

  /// Notes describe a monument or archaeological visit.
  monumentVisit,

  /// The listing does not say which of the two applies.
  neutral,
}

/// Tradition label when the existing fields say so. Otherwise unspecified.
enum SiteTradition { jain, buddhist, sikh, unspecified }

/// Why the timings block needs a visible caveat, if it does.
enum TimingsCaveatKind { none, missing, provisional, seasonal, multiWindow }

/// Presentation decisions for the temple detail screen.
///
/// Heuristics read free-text fields already on [Temple]. They do not invent
/// schema fields. When a signal is missing, the result stays neutral.
class DetailHonesty {
  const DetailHonesty({
    required this.verifiedImages,
    required this.framing,
    required this.tradition,
    required this.timingsCaveat,
    required this.timingsCaveatText,
  });

  factory DetailHonesty.of(Temple temple) {
    final corpus = _corpus(temple);
    final framing = _framing(corpus);
    final tradition = _tradition(temple);
    final timings = temple.timings;
    final caveat = _timingsCaveat(timings);
    return DetailHonesty(
      verifiedImages: verifiedGalleryUrls(temple),
      framing: framing,
      tradition: tradition,
      timingsCaveat: caveat,
      timingsCaveatText: _timingsCaveatText(timings, caveat),
    );
  }

  final List<String> verifiedImages;
  final SiteFraming framing;
  final SiteTradition tradition;
  final TimingsCaveatKind timingsCaveat;

  /// Null when the listing has a single stated window and no thin/seasonal flag.
  final String? timingsCaveatText;

  bool get photoPending => verifiedImages.isEmpty;

  String? get traditionLabel => switch (tradition) {
    SiteTradition.jain => 'Jain',
    SiteTradition.buddhist => 'Buddhist',
    SiteTradition.sikh => 'Sikh',
    SiteTradition.unspecified => null,
  };

  /// Living-temple chip is withheld when a tradition chip already frames the site.
  String? get framingLabel => switch (framing) {
    SiteFraming.monumentVisit => 'Heritage visit',
    SiteFraming.livingTemple when tradition == SiteTradition.unspecified =>
      'Living temple',
    SiteFraming.livingTemple => null,
    SiteFraming.neutral => null,
  };

  String get timingsHeading =>
      framing == SiteFraming.monumentVisit ? 'Visiting hours' : 'Timings';

  String get storyHeading {
    if (tradition != SiteTradition.unspecified) return 'About this place';
    return switch (framing) {
      SiteFraming.livingTemple => 'Temple story',
      SiteFraming.monumentVisit => 'Site history',
      SiteFraming.neutral => 'Background',
    };
  }

  String get framingNote {
    final buffer = StringBuffer();
    switch (tradition) {
      case SiteTradition.jain:
        buffer.write('Jain pilgrimage site. ');
      case SiteTradition.buddhist:
        buffer.write('Buddhist pilgrimage site. ');
      case SiteTradition.sikh:
        buffer.write('Sikh site. ');
      case SiteTradition.unspecified:
        break;
    }
    switch (framing) {
      case SiteFraming.livingTemple:
        buffer.write(
          tradition == SiteTradition.unspecified
              ? 'Notes describe continuing worship at a living temple. '
                    'The hours below are published text from the listing.'
              : 'Notes describe continuing observance. '
                    'The hours below are published text from the listing.',
        );
      case SiteFraming.monumentVisit:
        buffer.write(
          'Heritage visit. The hours below are visitor access for a '
          'monument or archaeological site.',
        );
      case SiteFraming.neutral:
        buffer.write(
          'These notes do not say clearly whether worship continues or '
          'this is only a monument visit.',
        );
    }
    return buffer.toString().trim();
  }
}

/// Gallery URLs that are safe to show as photographs of the place.
///
/// Picsum, generic placeholder hosts, and empty values are omitted so the
/// detail screen can say photo pending instead of framing stock images as real.
List<String> verifiedGalleryUrls(Temple temple) {
  return [
    for (final url in temple.galleryImages)
      if (!isPlaceholderImageUrl(url)) url.trim(),
  ];
}

/// True for empty values and known stock/placeholder image URLs.
bool isPlaceholderImageUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return true;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return true;
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return true;
  const hosts = <String>[
    'picsum.photos',
    'placeholder.com',
    'placehold.co',
    'placehold.it',
    'dummyimage.com',
    'loremflickr.com',
    'placekitten.com',
    'fakeimg.pl',
    'placeimg.com',
  ];
  for (final known in hosts) {
    if (host == known || host.endsWith('.$known')) return true;
  }
  if (host.contains('picsum.photos')) return true;
  final blob = '${uri.path} ${uri.query}'.toLowerCase();
  if (blob.contains('placeholder') || blob.contains('picsum')) return true;
  return false;
}

String _corpus(Temple temple) {
  return [
    temple.description,
    temple.story,
    temple.timings,
    temple.specialities.join('\n'),
  ].join('\n').toLowerCase().replaceAll(RegExp(r'[-–—]'), ' ');
}

SiteFraming _framing(String corpus) {
  const monumentPhrases = <String>[
    'not a living',
    'no living',
    'empty sanctum',
    'no installed deity',
    'no installed cult',
    'not a dependable living',
    'rather than a conventional living',
    'rather than a routine living',
    'heritage visit only',
    'monument visit',
    'archaeological site',
    'visitor monument',
    'no regular living',
    'no recurring public aarti',
    'not a typical hr&ce',
    'not a typical darshan',
  ];
  if (monumentPhrases.any(corpus.contains)) {
    return SiteFraming.monumentVisit;
  }
  const livingPhrases = <String>[
    'living temple',
    'living shrine',
    'living pilgrimage',
    'living monument',
    'living asi',
    'living pooja',
    'living cult',
    'daily worship',
    'daily pooja',
    'daily puja',
    'daily darshan',
    'daily aarti',
    'daily observance',
    'six pooja',
    'active ritual',
    'active worship',
    'active jain',
    'worship continues',
    'pooja continues',
    'hr&ce',
    'hrce',
    'devaswom',
    'endowments',
  ];
  if (_anyAffirmative(corpus, livingPhrases)) {
    return SiteFraming.livingTemple;
  }
  return SiteFraming.neutral;
}

SiteTradition _tradition(Temple temple) {
  final deity = temple.deity.toLowerCase();
  if (RegExp(r'\b(jain|tirthankaras?)\b').hasMatch(deity)) {
    return SiteTradition.jain;
  }
  if (RegExp(r'\b(buddha|buddhist)\b').hasMatch(deity)) {
    return SiteTradition.buddhist;
  }
  if (RegExp(r'\b(sikh|gurdwara|gurudwara|guru nanak)\b').hasMatch(deity)) {
    return SiteTradition.sikh;
  }

  final name = temple.name.toLowerCase();
  if (name.contains('gurdwara') || name.contains('gurudwara')) {
    return SiteTradition.sikh;
  }

  final brief =
      '${temple.name}\n${temple.description}\n'
              '${temple.specialities.join('\n')}'
          .toLowerCase();
  if (RegExp(r'\bjain (temples?|tirtha|pilgrimage)\b').hasMatch(brief)) {
    return SiteTradition.jain;
  }
  if (RegExp(r'\bbuddhist (temples?|pilgrimage|shrine)\b').hasMatch(brief)) {
    return SiteTradition.buddhist;
  }
  return SiteTradition.unspecified;
}

bool _anyAffirmative(String text, List<String> phrases) {
  for (final phrase in phrases) {
    if (_affirmative(text, phrase)) return true;
  }
  return false;
}

/// True when [phrase] appears without a nearby denial such as "not" or "no".
bool _affirmative(String text, String phrase) {
  final pattern = RegExp(RegExp.escape(phrase));
  for (final match in pattern.allMatches(text)) {
    final start = match.start - 48;
    final prefix = text.substring(start < 0 ? 0 : start, match.start);
    if (RegExp(
      r'\b(no|not|without|never|unlike|rather than)\b',
    ).hasMatch(prefix)) {
      continue;
    }
    return true;
  }
  return false;
}

final _seasonalPattern = RegExp(
  r'\b(seasonal(?:ly)?|closed outside|only during|not a daily|not year-round)\b',
  caseSensitive: false,
);

final _thinPattern = RegExp(
  r'\b(thin|provisional|incomplete|unconfirmed)\b|not published|no official|to be confirmed|\btb[cd]\b',
  caseSensitive: false,
);

final _multiWordPattern = RegExp(r'\b(conflict|split)\b', caseSensitive: false);

final _clockRangePattern = RegExp(
  r'(?<!\d)(?:\d{1,2}:\d{2}\s*(?:a\.?m\.?|p\.?m\.?)?|\d{1,2}\s*(?:a\.?m\.?|p\.?m\.?))'
  r'\s*(?:–|—|-|to)\s*'
  r'(?:\d{1,2}:\d{2}\s*(?:a\.?m\.?|p\.?m\.?)?|\d{1,2}\s*(?:a\.?m\.?|p\.?m\.?))'
  r'(?!\d)',
  caseSensitive: false,
);

final _clockPointPattern = RegExp(
  r'\d{1,2}:\d{2}\s*(?:a\.?m\.?|p\.?m\.?)',
  caseSensitive: false,
);

TimingsCaveatKind _timingsCaveat(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return TimingsCaveatKind.missing;
  if (_seasonalPattern.hasMatch(text)) return TimingsCaveatKind.seasonal;
  if (_isMultiWindow(text)) return TimingsCaveatKind.multiWindow;
  if (_thinPattern.hasMatch(text) || !_hasAnyClock(text)) {
    return TimingsCaveatKind.provisional;
  }
  return TimingsCaveatKind.none;
}

String? _timingsCaveatText(String raw, TimingsCaveatKind kind) {
  final multi = _isMultiWindow(raw);
  return switch (kind) {
    TimingsCaveatKind.none => null,
    TimingsCaveatKind.missing =>
      'No visiting hours are published in this listing. Confirm locally. '
          'Nothing here is an always-open clock.',
    TimingsCaveatKind.seasonal when multi =>
      'Provisional / seasonal. Several visiting windows or a limited season '
          'are described. This is not a single always-open clock. Confirm '
          'before you travel.',
    TimingsCaveatKind.seasonal =>
      'Provisional / seasonal. These notes describe season-dependent access. '
          'This is not a single always-open clock. Confirm before you travel.',
    TimingsCaveatKind.multiWindow =>
      'Provisional. More than one visiting window is listed, or the notes '
          'disagree. This is not a single always-open clock. Confirm the '
          "day's board.",
    TimingsCaveatKind.provisional =>
      'Provisional. Published hours here are thin or incomplete. This is not '
          'a fixed always-open clock. Confirm locally.',
  };
}

bool _isMultiWindow(String text) {
  if (_multiWordPattern.hasMatch(text)) return true;
  final ranges = _uniqueRanges(text);
  if (ranges.length >= 2) return true;
  final sunrise =
      RegExp(r'\bsunrise\b', caseSensitive: false).hasMatch(text) &&
      RegExp(r'\bsunset\b', caseSensitive: false).hasMatch(text);
  return sunrise && ranges.isNotEmpty;
}

bool _hasAnyClock(String text) {
  return _uniqueRanges(text).isNotEmpty ||
      _clockPointPattern.hasMatch(text) ||
      RegExp(r'\b(sunrise|sunset)\b', caseSensitive: false).hasMatch(text);
}

Set<String> _uniqueRanges(String text) {
  final found = <String>{};
  for (final match in _clockRangePattern.allMatches(text)) {
    found.add(_normalizeRange(match.group(0)!));
  }
  return found;
}

String _normalizeRange(String raw) {
  var value = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  value = value
      .replaceAll('a.m.', 'am')
      .replaceAll('p.m.', 'pm')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('to', '-');
  value = value.replaceAllMapped(
    RegExp(r'(?<!\d)0+(\d)'),
    (match) => match.group(1)!,
  );
  return value;
}
