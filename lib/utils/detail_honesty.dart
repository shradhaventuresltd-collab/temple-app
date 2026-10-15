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
    final tradition = temple.indexTradition != null
        ? _traditionFromIndex(temple.indexTradition!)
        : _tradition(temple);
    final framing = temple.indexFraming != null
        ? _framingFromIndex(temple.indexFraming!)
        : _framing(temple, corpus, tradition);
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
/// Picsum, generic placeholder hosts, unlicensed stock hosts, and empty
/// values are omitted so the detail screen can say photo pending.
List<String> verifiedGalleryUrls(Temple temple) {
  return [
    for (final url in temple.galleryImages)
      if (!isDisallowedImageUrl(url)) url.trim(),
  ];
}

/// First verified photograph for list cards, mosaic tiles, and other covers.
///
/// Null means the UI must show Photo pending — never a picsum/stock URL.
String? verifiedCoverUrl(Temple temple) {
  final urls = verifiedGalleryUrls(temple);
  if (urls.isEmpty) return null;
  return urls.first;
}

/// Verified photograph URLs across temples for collage surfaces such as Home.
///
/// Placeholder hosts are dropped so mosaic tiles never bind stock art.
List<String> verifiedMosaicUrls(Iterable<Temple> temples) {
  return [for (final temple in temples) ...verifiedGalleryUrls(temple)];
}

/// Placeholder-only domains. The host or a subdomain matches.
/// `source.unsplash.com` is exact and is not in this list.
const _placeholderSuffixHosts = <String>[
  'picsum.photos',
  'placeholder.com',
  'placehold.co',
  'placehold.it',
  'dummyimage.com',
  'lorempixel.com',
  'loremflickr.com',
  'placekitten.com',
  'fakeimg.pl',
  'placeimg.com',
];

/// True for empty values and placeholder hosts.
///
/// A listed domain matches the host or a subdomain, so `picsum.photos`
/// covers `fastly.picsum.photos` and `i.picsum.photos`. `source.unsplash.com`
/// is exact: `images.unsplash.com` is a photograph. A path or query that
/// contains `placeholder` or `picsum` is not enough. Unlicensed stock hosts
/// are [isUnlicensedStockImageUrl], not this check.
bool isPlaceholderImageUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return true;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return true;
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return true;
  if (host == 'source.unsplash.com') return true;
  for (final known in _placeholderSuffixHosts) {
    if (host == known || host.endsWith('.$known')) return true;
  }
  return false;
}

/// Named unlicensed-stock hosts. Subdomains match. `gettyimages` is the site name.
const _stockHosts = <String>[
  'shutterstock.com',
  'istockphoto.com',
  'istock.com',
  'pexels.com',
  'stock.adobe.com',
  'alamy.com',
  'dreamstime.com',
  '123rf.com',
  'depositphotos.com',
  'freepik.com',
];

/// `gettyimages.com`, `media.gettyimages.com`, and `www.gettyimages.co.uk`.
/// `gettyimages.example.com` is a different registrable domain.
bool _isGettyImagesHost(String host) {
  final labels = host
      .toLowerCase()
      .split('.')
      .where((label) => label.isNotEmpty)
      .toList();
  final index = labels.lastIndexOf('gettyimages');
  if (index < 0 || index == labels.length - 1) return false;
  final rest = labels.sublist(index + 1);
  if (rest.length == 1) {
    return RegExp(r'^[a-z]{2,24}$').hasMatch(rest[0]);
  }
  if (rest.length == 2) {
    return RegExp(r'^(ac|co|com|edu|gob|gov|net|nic|org)$').hasMatch(rest[0]) &&
        RegExp(r'^[a-z]{2}$').hasMatch(rest[1]);
  }
  return false;
}

/// True for an unlicensed stock-photo host.
///
/// A named host matches itself or a subdomain (`www.shutterstock.com`).
/// `gettyimages` matches that site name (`gettyimages.co.uk`,
/// `media.gettyimages.com`). `gettyimages.example.com` does not.
/// `stock.adobe.com` does not block `adobe.com`.
/// Empty values and non-HTTP URLs are not stock. `images.unsplash.com`
/// stays allowed. Firestore rules do not apply this list.
bool isUnlicensedStockImageUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  if (_isGettyImagesHost(host)) return true;
  for (final stock in _stockHosts) {
    if (host == stock || host.endsWith('.$stock')) return true;
  }
  return false;
}

/// Placeholder host or unlicensed stock host. Empty values count.
bool isDisallowedImageUrl(String raw) {
  return isPlaceholderImageUrl(raw) || isUnlicensedStockImageUrl(raw);
}

SiteTradition _traditionFromIndex(String value) {
  return switch (value) {
    'jain' => SiteTradition.jain,
    'buddhist' => SiteTradition.buddhist,
    'sikh' => SiteTradition.sikh,
    _ => SiteTradition.unspecified,
  };
}

SiteFraming _framingFromIndex(String value) {
  return switch (value) {
    'living' => SiteFraming.livingTemple,
    'monument' => SiteFraming.monumentVisit,
    _ => SiteFraming.neutral,
  };
}

String _corpus(Temple temple) {
  return _normalizeHonestyText(
    [
      temple.description,
      temple.story,
      temple.timings,
      temple.specialities.join('\n'),
    ].join('\n'),
  );
}

/// Lowercase copy for phrase checks.
///
/// En dashes and em dashes become spaces. An ASCII hyphen inside a word stays
/// put, so "No-VIP" is one token and is not the denial word "no".
String _normalizeHonestyText(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll(RegExp(r'[–—]'), ' ');
}

const _livingPhrases = <String>[
  'living temple',
  'living shrine',
  'living pilgrimage',
  'living monument',
  'living asi',
  'living pooja',
  'living cult',
  'living peetha',
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

final _ruinWord = RegExp(r'\b(?:ruined|ruins?)\b');

/// Nearby words that mean the ruin is not this shrine: a fort, an excavation
/// find, or a neighboring site.
const _incidentalRuinWords = <String>{
  'above',
  'around',
  'beside',
  'excavated',
  'excavation',
  'excavations',
  'fort',
  'revealed',
};

SiteFraming _framing(Temple temple, String corpus, SiteTradition tradition) {
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
  // Fixed heritage phrases win over every living path, including "living temple".
  // The phrase has to end on a word boundary, so "monument visiting" is not
  // "monument visit". Jogulamba's Navabrahma note uses the longer word, and
  // its restored "living Peetha" worship stays a living claim.
  if (monumentPhrases.any((phrase) => _hasBoundedPhrase(corpus, phrase))) {
    return SiteFraming.monumentVisit;
  }
  final presentWorship =
      _anyAffirmative(corpus, _livingPhrases) || _affirmativeWorship(temple);
  // "asi", "ruin(s)", and "protected monument" do not force heritage on
  // their own. Present-tense darshan or puja wins. Heritage from ruins
  // requires a ruined shrine, ceased or past-tense worship, and no
  // present-tense evidence. Protected or ASI status alone stays neutral.
  if (!presentWorship &&
      _shrineIsRuin(corpus) &&
      _ceasedOrPastWorship(corpus)) {
    return SiteFraming.monumentVisit;
  }
  // Jain, Buddhist, and Sikh keep the tradition chip on every path. Legacy
  // phrases such as "daily puja" or "active jain" do not add living-temple
  // framing.
  if (tradition != SiteTradition.unspecified) {
    return SiteFraming.neutral;
  }
  if (presentWorship) {
    return SiteFraming.livingTemple;
  }
  return SiteFraming.neutral;
}

final _ceasedOrPastWorshipPattern = RegExp(
  r'\b(?:once|historic|historical|formerly|former|erstwhile|discontinued|ceased|stopped|ended|abandoned|abolished)\b',
);

bool _ceasedOrPastWorship(String corpus) {
  return _ceasedOrPastWorshipPattern.hasMatch(corpus);
}

/// True when ruin wording describes this shrine, not a fort or a dig.
bool _shrineIsRuin(String corpus) {
  for (final match in _ruinWord.allMatches(corpus)) {
    final before = corpus.substring(
      _clauseStart(corpus, match.start),
      match.start,
    );
    final after = corpus.substring(match.end, _clauseEnd(corpus, match.end));
    final beforeWords = _words(before);
    final afterWords = _words(after);
    final tail = beforeWords.length <= 8
        ? beforeWords
        : beforeWords.sublist(beforeWords.length - 8);
    final head = afterWords.length <= 4 ? afterWords : afterWords.sublist(0, 4);
    final around = [...tail, ...head];
    if (around.any(_incidentalRuinWords.contains)) continue;
    return true;
  }
  return false;
}

/// Worship words in the timings text or the description.
///
/// A clock by itself is not darshan. Story and specialities are not read.
/// Matches are whole words, so a name such as Darshana is not darshan.
/// "puja discontinued", "once worshipped", and "historic puja" do not count.
///
/// Festival titles "Durga Puja" and "Kali Puja" are not a worship schedule.
/// Kiriteswari Temple stays neutral on those titles beside "No official daily
/// clock". That miss is not a regression, and the temple is not special-cased
/// by name.
bool _affirmativeWorship(Temple temple) {
  final text = _normalizeHonestyText(
    [temple.description, temple.timings].join('\n'),
  );
  final pattern = RegExp(
    r'\b(?:widely worshipped|darshan time|darshans?|aartis?|artis?|poojas?|pujas?|abhisheks?)\b',
  );
  for (final match in pattern.allMatches(text)) {
    final word = match.group(0)!;
    if ((word == 'puja' || word == 'pujas') &&
        _festivalPujaTitle(text, match.start)) {
      continue;
    }
    if (_matchIsAffirmative(text, match.start, match.end)) return true;
  }
  return false;
}

bool _festivalPujaTitle(String text, int pujaStart) {
  final previous = _words(text.substring(0, pujaStart));
  if (previous.isEmpty) return false;
  final title = previous.last;
  return title == 'durga' || title == 'kali';
}

/// Tradition named by a deity string alone.
///
/// Name, story, and description are not read. [_tradition] still checks those
/// when the deity field itself does not say.
SiteTradition traditionFromDeityText(String deity) {
  final lower = deity.toLowerCase();
  if (RegExp(r'\b(jain|tirthankaras?)\b').hasMatch(lower)) {
    return SiteTradition.jain;
  }
  if (RegExp(r'\b(buddha|buddhist)\b').hasMatch(lower)) {
    return SiteTradition.buddhist;
  }
  if (RegExp(r'\b(sikh|gurdwara|gurudwara|guru nanak)\b').hasMatch(lower)) {
    return SiteTradition.sikh;
  }
  return SiteTradition.unspecified;
}

SiteTradition _tradition(Temple temple) {
  final fromDeity = traditionFromDeityText(temple.deity);
  if (fromDeity != SiteTradition.unspecified) return fromDeity;

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

/// True when [phrase] appears without a nearby denial.
///
/// Spaces in [phrase] also match a hyphen, so "living-temple" still counts
/// as "living temple". The hyphen is not turned into a space first, which
/// would split "No-VIP" into the denial word "no".
bool _affirmative(String text, String phrase) {
  final pattern = RegExp(_phrasePattern(phrase));
  for (final match in pattern.allMatches(text)) {
    if (_matchIsAffirmative(text, match.start, match.end)) return true;
  }
  return false;
}

String _phrasePattern(String phrase) {
  return phrase.split(RegExp(r'\s+')).map(RegExp.escape).join(r'[\s-]+');
}

const _denialWords = <String>{'no', 'not', 'without', 'never', 'unlike'};

final _qualifierBefore = RegExp(
  r'\b(once|historic|historical|formerly|former|erstwhile)\b',
);

final _ceasedAfter = RegExp(
  r'\b(?:discontinued|ceased|stopped|ended|abandoned|abolished)\b'
  r'|\bno more\b'
  r'|\bno longer\b'
  r'|\bonce worshipped\b'
  r'|\b(?:was|were)\b(?:\s+\w+){0,4}\s+once\b',
);

/// A denial that follows the hit, as in "darshan not allowed".
///
/// "not" has to attach to a word that takes the worship back. A later "not"
/// in "not spelled out" or "not a ticket" stays outside this pattern.
final _deniedAfter = RegExp(
  r'\b(?:not|never|no)\b(?:\s+\w+){0,2}\s+(?:allowed|permitted|offered|held|performed|available|conducted)\b',
);

/// How many tokens before a hit can carry "no" / "not" / "without".
///
/// An unrelated earlier "not", as in "Not crowded on weekdays and darshan",
/// is outside this window. "and" and "but" also start a new claim, so a
/// denial before them does not cross. Inside one claim, a "no" further than
/// three tokens away still denies ("no ... daily puja"), because missing a
/// living claim is better than inventing one.
const _denialTokenWindow = 3;

/// A hit counts only when the clause does not take it back.
///
/// Qualifiers have to sit next to the word ("historic puja", "once worshipped").
/// Words after the hit count too ("puja discontinued", "puja was once
/// performed", "puja site no more", "darshan not allowed").
bool _matchIsAffirmative(String text, int start, int end) {
  final before = text.substring(_clauseStart(text, start), start);
  final after = text.substring(end, _clauseEnd(text, end));
  if (_deniedBefore(before)) return false;
  if (_qualifierBefore.hasMatch(_tailWords(before, 4))) return false;
  final afterHead = _headWords(after, 6);
  if (_ceasedAfter.hasMatch(afterHead)) return false;
  if (_deniedAfter.hasMatch(afterHead)) return false;
  return true;
}

bool _hasBoundedPhrase(String corpus, String phrase) {
  return RegExp('${RegExp.escape(phrase)}(?![a-z0-9])').hasMatch(corpus);
}

bool _deniedBefore(String before) {
  final words = _words(before);
  if (words.isEmpty) return false;
  final windowStart = words.length <= _denialTokenWindow
      ? 0
      : words.length - _denialTokenWindow;
  if (_containsDenial(words, windowStart, words.length)) return true;
  var conjunctStart = 0;
  for (var i = 0; i < words.length; i++) {
    if (words[i] == 'and' || words[i] == 'but') conjunctStart = i + 1;
  }
  if (conjunctStart >= words.length) return false;
  return _containsDenial(words, conjunctStart, words.length);
}

bool _containsDenial(List<String> words, int start, int end) {
  if (start > 0 &&
      words[start - 1] == 'rather' &&
      start < end &&
      words[start] == 'than') {
    return true;
  }
  for (var i = start; i < end; i++) {
    if (_denialWords.contains(words[i])) return true;
    if (words[i] == 'rather' && i + 1 < end && words[i + 1] == 'than') {
      return true;
    }
  }
  return false;
}

List<String> _words(String text) {
  final words = <String>[];
  for (final part in text.split(RegExp(r"[^a-z0-9.'’-]+"))) {
    final word = part.replaceAll(RegExp(r"^[.'’-]+|[.'’-]+$"), '');
    if (word.isNotEmpty) words.add(word);
  }
  return words;
}

int _clauseStart(String text, int index) {
  final floor = index - 240 < 0 ? 0 : index - 240;
  for (var i = index - 1; i >= floor; i--) {
    if (_isClauseBreak(text, i)) return i + 1;
  }
  return floor;
}

int _clauseEnd(String text, int index) {
  final cap = index + 120;
  final limit = cap > text.length ? text.length : cap;
  for (var i = index; i < limit; i++) {
    if (_isClauseBreak(text, i)) return i;
  }
  return limit;
}

/// Semicolons and commas break clauses, so "No entry fee, 5.30 am darshan"
/// keeps the darshan. A comma inside a list does not: "No darshan, puja or
/// aarti" stays one denial. "St.", "A.D.", and decimals such as "5.30" do not
/// split a sentence.
bool _isClauseBreak(String text, int index) {
  final ch = text[index];
  if (ch == ',') return !_commaContinuesList(text, index);
  if (ch == '\n' || ch == '!' || ch == '?' || ch == ';') return true;
  if (ch != '.') return false;
  if (_isDecimalDot(text, index) || _isAbbreviationDot(text, index)) {
    return false;
  }
  return true;
}

/// True when [commaIndex] joins list items ("puja or aarti", ", or puja").
///
/// "No entry fee, 5.30 am darshan" has no coordinator after the comma, so
/// that comma still starts a new clause. ", and darshan begins" does too.
bool _commaContinuesList(String text, int commaIndex) {
  var i = commaIndex + 1;
  final limit = i + 80 > text.length ? text.length : i + 80;
  final buffer = StringBuffer();
  for (; i < limit; i++) {
    final ch = text[i];
    if (ch == '.' && _isDecimalDot(text, i)) {
      buffer.write(ch);
      continue;
    }
    if (ch == ',' ||
        ch == '.' ||
        ch == '!' ||
        ch == '?' ||
        ch == ';' ||
        ch == '\n') {
      break;
    }
    buffer.write(ch);
  }
  final words = _words(buffer.toString());
  if (words.isEmpty) return false;
  if (words.first == 'or') return true;
  if (words.first == 'and' || words.first == 'but') return false;
  final coord = words.indexWhere((word) => word == 'or' || word == 'and');
  if (coord <= 0 || coord > 3 || coord + 1 >= words.length) return false;
  const itemVerbs = <String>{
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'has',
    'have',
    'had',
    'do',
    'does',
    'did',
    'held',
    'holds',
    'begins',
    'runs',
    'starts',
  };
  for (var n = 0; n < coord; n++) {
    if (itemVerbs.contains(words[n])) return false;
  }
  return true;
}

bool _isDecimalDot(String text, int index) {
  if (index == 0 || index + 1 >= text.length) return false;
  return _isDigit(text[index - 1]) && _isDigit(text[index + 1]);
}

bool _isAbbreviationDot(String text, int index) {
  if (_wordImmediatelyBefore(text, index, 'st')) return true;
  final firstOfAd =
      _wordImmediatelyBefore(text, index, 'a') &&
      index + 2 < text.length &&
      text[index + 1] == 'd' &&
      text[index + 2] == '.';
  if (firstOfAd) return true;
  return index >= 2 &&
      text[index - 1] == 'd' &&
      text[index - 2] == '.' &&
      _wordImmediatelyBefore(text, index - 2, 'a');
}

bool _wordImmediatelyBefore(String text, int dotIndex, String word) {
  final start = dotIndex - word.length;
  if (start < 0) return false;
  if (text.substring(start, dotIndex) != word) return false;
  if (start == 0) return true;
  final prev = text[start - 1];
  return !_isWordChar(prev);
}

bool _isDigit(String ch) {
  final code = ch.codeUnitAt(0);
  return code >= 48 && code <= 57;
}

bool _isWordChar(String ch) {
  final code = ch.codeUnitAt(0);
  return (code >= 48 && code <= 57) || (code >= 97 && code <= 122);
}

String _tailWords(String text, int count) {
  final words = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length <= count) return words.join(' ');
  return words.sublist(words.length - count).join(' ');
}

String _headWords(String text, int count) {
  final words = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length <= count) return words.join(' ');
  return words.sublist(0, count).join(' ');
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
