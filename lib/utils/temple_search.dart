import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/deity_synonyms.dart';

/// How long a typed query waits before the temple grid refreshes.
const Duration templeSearchDebounce = Duration(milliseconds: 300);

/// Case-insensitive match of [query] against public directory text.
///
/// An empty or whitespace-only query matches every temple. Otherwise the query
/// is trimmed, lowercased, and split on whitespace. Each word must occur in
/// the name, deity, city, state, or address ([Temple.location]) after
/// [foldTempleSearchText]. Story and description are not searched. Matching
/// uses the temples already loaded in memory, so a keystroke does not read
/// Firestore.
///
/// Queries shorter than 3 characters skip folding. They use the old spaced
/// text, so `ee`, `th`, and `it` stay ordinary substrings and `-` stays a
/// hyphen.
///
/// Longer words match a whole token, a prefix, a partial token, or a short
/// edit (Damerau-Levenshtein). Deity synonyms in [deitySynonymGroups] match
/// whole tokens. Words of 4 characters or fewer that name a deity, and the
/// word `linga`, do not match inside a longer word.
bool templeMatchesQuery(Temple temple, String query) {
  if (query.trim().isEmpty) return true;
  final indexed = _indexFor(temple);
  if (_isShortQuery(query)) {
    return indexed.plain.contains(query.trim().toLowerCase());
  }
  final words = _queryWords(query);
  if (words.isEmpty) return false;
  return _scoreTemple(indexed, words, 0) != null;
}

/// Temples that match [state], [deity], and [query] together.
///
/// A null [state] or [deity] does not constrain that field (exact chip match
/// when set). Results are ranked by prominence, then by how much of a
/// multi-word query is literal, then by deity-group tier (exact group before
/// a parent expansion), then by field: name, deity, town, state, address.
/// Inside a field, the typed word beats a sibling synonym, then exact beats
/// prefix, prefix beats a partial token, and a partial token beats a typo.
/// Ties keep input order. Queries under 3 characters stay plain substrings
/// in input order.
List<Temple> filterTemples(
  List<Temple> temples, {
  String? state,
  String? deity,
  String query = '',
}) {
  if (query.trim().isEmpty) {
    return [
      for (final temple in temples)
        if (_passesChips(temple, state, deity)) temple,
    ];
  }

  if (_isShortQuery(query)) {
    final needle = query.trim().toLowerCase();
    return [
      for (final temple in temples)
        if (_passesChips(temple, state, deity) &&
            _indexFor(temple).plain.contains(needle))
          temple,
    ];
  }

  final words = _queryWords(query);
  if (words.isEmpty) return const [];

  final hits = <_Score>[];
  var index = 0;
  for (final temple in temples) {
    if (!_passesChips(temple, state, deity)) continue;
    final score = _scoreTemple(_indexFor(temple), words, index);
    if (score != null) hits.add(score);
    index++;
  }
  hits.sort(_compareScore);
  return [for (final hit in hits) hit.temple];
}

/// Folded place names. Tirupathi is already `tirupati` before this lookup.
///
/// `sivan` is a [deitySynonymGroups] entry. It stays here so the Shiva
/// prominence alias still resolves when the typed word is `sivan`.
const Map<String, String> _searchAliases = {
  'tirupati': 'tirumala',
  'sivan': 'siva',
};

/// Well-known temples that should lead when the query actually names them.
///
/// Ids are the Firestore document ids in the seed and sample packs. Names
/// cover sample rows, which leave [Temple.id] empty. The bonus is code-only:
/// no new Firestore field and no extra read. It applies only when a query
/// word hits the temple name or one of [aliases], not when the hit is only
/// a city, state, or address.
const List<_ProminentTemple> _prominentTemples = [
  _ProminentTemple(
    id: 'tirumala-venkateswara-temple',
    name: 'Tirumala Venkateswara Temple',
    aliases: {'tirumala'},
  ),
  _ProminentTemple(
    id: 'brihadeeswarar-temple',
    name: 'Brihadeeswarar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'arunachaleswarar-temple',
    name: 'Arunachaleswarar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'ramanathaswamy-temple',
    name: 'Ramanathaswamy Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'sri-mallikarjuna-swamy-temple',
    name: 'Sri Mallikarjuna Swamy Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'somnath-temple',
    name: 'Somnath Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'nageshwar-jyotirlinga-temple',
    name: 'Nageshwar Jyotirlinga Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'kashi-vishwanath-temple',
    name: 'Kashi Vishwanath Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'trimbakeshwar-temple',
    name: 'Trimbakeshwar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'bhimashankar-temple',
    name: 'Bhimashankar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'grishneshwar-temple',
    name: 'Grishneshwar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'mahakaleshwar-temple',
    name: 'Mahakaleshwar Temple',
    aliases: _shivaAliases,
  ),
  _ProminentTemple(
    id: 'omkareshwar-temple',
    name: 'Omkareshwar Temple',
    aliases: _shivaAliases,
  ),
];

/// Folded deity Shiva. `shiva` folds to this; `shiv` folds to `siv`.
const Set<String> _shivaAliases = {'siva'};

/// Name tokens that are too common to count as "this temple's name".
const Set<String> _genericNameTokens = {
  'temple',
  'mandir',
  'kovil',
  'swamy',
  'swami',
  'sri',
  'shri',
};

const int _kindExact = 0;
const int _kindPrefix = 1;
const int _kindPartial = 2;
const int _kindFuzzy = 3;

class _ProminentTemple {
  const _ProminentTemple({
    required this.id,
    required this.name,
    required this.aliases,
  });

  final String id;
  final String name;
  final Set<String> aliases;
}

Map<String, _ProminentTemple>? _prominentById;
Map<String, _ProminentTemple>? _prominentByName;

_ProminentTemple? _prominentFor(Temple temple) {
  final byId = _prominentById ??= {
    for (final row in _prominentTemples) row.id: row,
  };
  if (temple.id.isNotEmpty) {
    final match = byId[temple.id];
    if (match != null) return match;
  }
  final byName = _prominentByName ??= {
    for (final row in _prominentTemples) foldTempleSearchText(row.name): row,
  };
  return byName[foldTempleSearchText(temple.name)];
}

/// 0 when this curated temple should lead, 1 otherwise.
int _boostRank(Temple temple, List<String> words) {
  final spec = _prominentFor(temple);
  if (spec == null) return 1;
  if (_queryHitsNameOrAlias(temple, spec, words)) return 0;
  return 1;
}

bool _queryHitsNameOrAlias(
  Temple temple,
  _ProminentTemple spec,
  List<String> words,
) {
  final tokens = _nameTokens(temple.name);
  for (final word in words) {
    if (_wordHitsName(tokens, word)) return true;
    final canonical = _aliasCanonical(word);
    if (canonical != null && spec.aliases.contains(canonical)) return true;
    if (spec.aliases.contains(word)) return true;
    final synonym = _synonyms.word(word);
    if (synonym != null && synonym.exactTokens.any(spec.aliases.contains)) {
      return true;
    }
  }
  final phrase = _synonyms.phrase(words);
  if (phrase != null && phrase.exactTokens.any(spec.aliases.contains)) {
    return true;
  }
  return false;
}

List<String> _nameTokens(String name) {
  final tokens = <String>[];
  for (final word in name.trim().toLowerCase().split(_splitMarks)) {
    final token = foldTempleSearchText(word);
    if (token.isEmpty || _genericNameTokens.contains(token)) continue;
    tokens.add(token);
  }
  return tokens;
}

/// Whole name token, or a prefix in either direction.
///
/// A mid-word [String.contains] would treat `sivakasi` as a hit on the token
/// `kasi` and boost Kashi.
bool _wordHitsName(List<String> tokens, String word) {
  if (word.length < 4 || _genericNameTokens.contains(word)) return false;
  for (final token in tokens) {
    if (token == word || token.startsWith(word) || word.startsWith(token)) {
      return true;
    }
  }
  return false;
}

/// Folds common Indian transliteration variants.
///
/// Applied to both the query and the indexed text: `zh`/`l`, `sh`/`s`,
/// `th`/`t`, `ee`/`i`, `oo`/`u`, `aa`/`a`, `w`/`v`, doubled consonants, and
/// spaces, hyphens, or other punctuation inside a word. Letters outside
/// ASCII, including Devanagari, are kept.
String foldTempleSearchText(String value) {
  var text = value.toLowerCase();
  if (text.isEmpty) return text;
  text = text.replaceAll(_splitMarks, '');
  if (text.isEmpty) return text;
  for (var pass = 0; pass < 4; pass++) {
    final next = _collapseDoubleConsonants(
      text
          .replaceAll('zh', 'l')
          .replaceAll('sh', 's')
          .replaceAll('th', 't')
          .replaceAll('ee', 'i')
          .replaceAll('oo', 'u')
          .replaceAll('aa', 'a')
          .replaceAll('w', 'v'),
    );
    if (next == text) return text;
    text = next;
  }
  return text;
}

bool _passesChips(Temple temple, String? state, String? deity) {
  return (state == null || temple.state == state) &&
      (deity == null || temple.deity == deity);
}

/// Folding `ee` or `th`, or deleting the space in `devi temple`, turns a
/// two-character query into a hit on most of the directory.
bool _isShortQuery(String query) => query.trim().length < 3;

final RegExp _splitMarks = RegExp(r'''[\s\-_/'’".,:;!?()\[\]{}]+''');
final RegExp _whitespace = RegExp(r'\s+');

/// Normalised query words. Empty when [query] has no searchable characters.
List<String> _queryWords(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return const [];
  final words = <String>[];
  for (final word in normalized.split(_whitespace)) {
    final folded = foldTempleSearchText(word);
    if (folded.isNotEmpty) words.add(folded);
  }
  return words;
}

final Expando<_TempleIndex> _indexes = Expando<_TempleIndex>();

_TempleIndex _indexFor(Temple temple) {
  final cached = _indexes[temple];
  if (cached != null) return cached;
  final built = _TempleIndex.build(temple);
  _indexes[temple] = built;
  return built;
}

class _FieldText {
  const _FieldText(this.tokens, this.blob);

  final List<String> tokens;
  final String blob;

  static const empty = _FieldText(<String>[], '');

  static _FieldText build(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return empty;
    final tokens = <String>[];
    for (final word in trimmed.split(_splitMarks)) {
      final token = foldTempleSearchText(word);
      if (token.isNotEmpty) tokens.add(token);
    }
    return _FieldText(tokens, foldTempleSearchText(trimmed));
  }
}

class _TempleIndex {
  _TempleIndex(
    this.temple,
    this.plain,
    this.name,
    this.deity,
    this.town,
    this.state,
    this.address,
  );

  final Temple temple;
  final String plain;
  final _FieldText name;
  final _FieldText deity;
  final _FieldText town;
  final _FieldText state;
  final _FieldText address;

  static _TempleIndex build(Temple temple) {
    final fields = [
      temple.name,
      temple.city,
      temple.state,
      temple.deity,
      temple.location,
    ];
    final plainFields = <String>[];
    for (final field in fields) {
      final trimmed = field.trim().toLowerCase();
      if (trimmed.isEmpty) continue;
      plainFields.add(trimmed.replaceAll(_whitespace, ' '));
    }
    return _TempleIndex(
      temple,
      plainFields.join(' '),
      _FieldText.build(temple.name),
      _FieldText.build(temple.deity),
      _FieldText.build(temple.city),
      _FieldText.build(temple.state),
      _FieldText.build(temple.location),
    );
  }
}

class _WordHit {
  const _WordHit(
    this.tier,
    this.field,
    this.origin,
    this.kind,
    this.distance,
    this.literal,
  );

  final int tier;
  final int field;

  /// 0 when the typed word itself hits the field, 1 for a sibling synonym.
  final int origin;
  final int kind;
  final int distance;
  final bool literal;
}

class _Score {
  _Score({
    required this.temple,
    required this.boost,
    required this.literalWords,
    required this.tier,
    required this.field,
    required this.origin,
    required this.kind,
    required this.distance,
    required this.index,
  });

  final Temple temple;
  final int boost;
  final int literalWords;
  final int tier;
  final int field;
  final int origin;
  final int kind;
  final int distance;
  final int index;
}

int _compareScore(_Score a, _Score b) {
  final boost = a.boost.compareTo(b.boost);
  if (boost != 0) return boost;
  final literal = b.literalWords.compareTo(a.literalWords);
  if (literal != 0) return literal;
  final tier = a.tier.compareTo(b.tier);
  if (tier != 0) return tier;
  final field = a.field.compareTo(b.field);
  if (field != 0) return field;
  final origin = a.origin.compareTo(b.origin);
  if (origin != 0) return origin;
  final kind = a.kind.compareTo(b.kind);
  if (kind != 0) return kind;
  final distance = a.distance.compareTo(b.distance);
  if (distance != 0) return distance;
  return a.index.compareTo(b.index);
}

_WordHit _prefer(_WordHit? current, _WordHit next) {
  if (current == null) return next;
  if (next.tier != current.tier) {
    return next.tier < current.tier ? next : current;
  }
  if (next.field != current.field) {
    return next.field < current.field ? next : current;
  }
  if (next.origin != current.origin) {
    return next.origin < current.origin ? next : current;
  }
  if (next.kind != current.kind) {
    return next.kind < current.kind ? next : current;
  }
  if (next.distance != current.distance) {
    return next.distance < current.distance ? next : current;
  }
  return current;
}

/// Short deity names, and `linga`, match a whole token only.
///
/// `shiv`, `kali`, `rama`, `maa`, and `uma` must not match inside Sivakasi,
/// Kalina, Ramanathapuram, or a longer word. Other words of 4 or more
/// characters may be a prefix or a partial token (`tiru` → Tirupati).
bool _strictWord(String word) {
  if (word.length < 4 || word == 'linga') return true;
  final synonym = _synonyms.word(word);
  return synonym != null && word.length == 4;
}

_Score? _scoreTemple(_TempleIndex indexed, List<String> words, int index) {
  final boost = _boostRank(indexed.temple, words);
  _Score? best = _scoreWords(indexed, words, index, boost);
  final phrase = _synonyms.phrase(words);
  if (phrase != null) {
    final hit = _matchSynonym(phrase, indexed);
    if (hit != null) {
      final phraseScore = _Score(
        temple: indexed.temple,
        boost: boost,
        literalWords: words.length < 2 ? 0 : _literalCount(words, indexed),
        tier: hit.tier,
        field: hit.field,
        origin: hit.origin,
        kind: hit.kind,
        distance: hit.distance,
        index: index,
      );
      if (best == null || _compareScore(phraseScore, best) < 0) {
        best = phraseScore;
      }
    }
  }
  return best;
}

_Score? _scoreWords(
  _TempleIndex indexed,
  List<String> words,
  int index,
  int boost,
) {
  final hits = <_WordHit>[];
  var literals = 0;
  for (final word in words) {
    final hit = _hitForWord(word, indexed);
    if (hit == null) return null;
    hits.add(hit);
    if (hit.literal) literals++;
  }
  var tier = 0;
  var field = 0;
  var origin = 0;
  var kind = 0;
  var distance = 0;
  for (final hit in hits) {
    if (hit.tier > tier) tier = hit.tier;
    field += hit.field;
    origin += hit.origin;
    kind += hit.kind;
    distance += hit.distance;
  }
  return _Score(
    temple: indexed.temple,
    boost: boost,
    literalWords: words.length < 2 ? 0 : literals,
    tier: tier,
    field: field,
    origin: origin,
    kind: kind,
    distance: distance,
    index: index,
  );
}

int _literalCount(List<String> words, _TempleIndex indexed) {
  var count = 0;
  for (final word in words) {
    if (_directHit(word, indexed) != null) count++;
  }
  return count;
}

_WordHit? _hitForWord(String word, _TempleIndex indexed) {
  final direct = _directHit(word, indexed);
  final synonym = _synonyms.word(word);
  if (synonym == null) return direct;
  final viaGroup = _matchSynonym(synonym, indexed);
  if (viaGroup == null) return direct;
  if (direct == null) return viaGroup;
  return _prefer(direct, viaGroup);
}

_WordHit? _directHit(String word, _TempleIndex indexed) {
  final strict = _strictWord(word);
  final fields = [
    indexed.name,
    indexed.deity,
    indexed.town,
    indexed.state,
    indexed.address,
  ];
  _WordHit? best;
  for (var rank = 0; rank < fields.length; rank++) {
    final hit = _matchField(word, fields[rank], rank, strict);
    if (hit != null) best = _prefer(best, hit);
  }
  return best;
}

_WordHit? _matchField(
  String word,
  _FieldText field,
  int fieldRank,
  bool strict,
) {
  _WordHit? best;
  for (final token in field.tokens) {
    if (token == word) {
      best = _prefer(best, _WordHit(0, fieldRank, 0, _kindExact, 0, true));
      continue;
    }
    if (strict) continue;
    if (token.startsWith(word) ||
        (word.startsWith(token) && token.length >= 5)) {
      best = _prefer(best, _WordHit(0, fieldRank, 0, _kindPrefix, 0, true));
      continue;
    }
    final maxDistance = _maxEditDistance(word.length);
    if (maxDistance == 0) continue;
    final distance = _editDistanceAtMost(word, token, maxDistance);
    if (distance != null && distance > 0) {
      best = _prefer(
        best,
        _WordHit(0, fieldRank, 0, _kindFuzzy, distance, true),
      );
    }
  }
  if (!strict && word.isNotEmpty && field.blob.contains(word)) {
    final kind = field.blob.startsWith(word) ? _kindPrefix : _kindPartial;
    best = _prefer(best, _WordHit(0, fieldRank, 0, kind, 0, true));
  }
  final canonical = _aliasCanonical(word);
  if (canonical != null && canonical != word) {
    for (final token in field.tokens) {
      if (token != canonical) continue;
      final exactKey = _searchAliases.containsKey(word);
      best = _prefer(
        best,
        _WordHit(
          0,
          fieldRank,
          0,
          exactKey ? _kindExact : _kindFuzzy,
          exactKey ? 0 : 1,
          true,
        ),
      );
    }
  }
  return best;
}

_WordHit? _matchSynonym(_SynonymHit hit, _TempleIndex indexed) {
  final fields = [indexed.name, indexed.deity];
  _WordHit? best;
  for (var rank = 0; rank < fields.length; rank++) {
    final tokens = fields[rank].tokens;
    for (final token in tokens) {
      if (hit.exactTokens.contains(token)) {
        best = _prefer(best, _WordHit(0, rank, 1, _kindExact, 0, false));
      } else if (hit.expansionTokens.contains(token)) {
        best = _prefer(best, _WordHit(1, rank, 1, _kindExact, 0, false));
      }
    }
    if (_phrasesHit(tokens, hit.exactPhrases)) {
      best = _prefer(best, _WordHit(0, rank, 1, _kindExact, 0, false));
    }
    if (_phrasesHit(tokens, hit.expansionPhrases)) {
      best = _prefer(best, _WordHit(1, rank, 1, _kindExact, 0, false));
    }
  }
  return best;
}

bool _phrasesHit(List<String> tokens, List<List<String>> phrases) {
  if (phrases.isEmpty) return false;
  final have = tokens.toSet();
  for (final phrase in phrases) {
    if (phrase.every(have.contains)) return true;
  }
  return false;
}

String? _aliasCanonical(String word) {
  final exact = _searchAliases[word];
  if (exact != null) return exact;
  if (word.length >= 5) {
    for (final entry in _searchAliases.entries) {
      if (entry.key.startsWith(word)) return entry.value;
    }
  }
  final maxDistance = _maxEditDistance(word.length);
  if (maxDistance == 0) return null;
  String? found;
  var best = maxDistance + 1;
  for (final entry in _searchAliases.entries) {
    final distance = _editDistanceAtMost(word, entry.key, maxDistance);
    if (distance == null || distance == 0 || distance >= best) continue;
    best = distance;
    found = entry.value;
  }
  return found;
}

/// Edit budget for one folded token: 1 for 4–7 characters, 2 from 8 up.
///
/// Shorter tokens stay exact. Deity names of 4 characters are also exact-only
/// via [_strictWord], so `kali` cannot drift into a nearby spelling.
int _maxEditDistance(int length) {
  if (length < 4) return 0;
  if (length <= 7) return 1;
  return 2;
}

/// Damerau-Levenshtein, counting an adjacent transposition as one edit.
int? _editDistanceAtMost(String a, String b, int maxDistance) {
  if ((a.length - b.length).abs() > maxDistance) return null;
  if (maxDistance == 0) return a == b ? 0 : null;
  if (a == b) return 0;

  var previousPrevious = List<int>.filled(b.length + 1, 0);
  var previous = List<int>.generate(b.length + 1, (index) => index);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var rowMin = i;
    final left = a.codeUnitAt(i - 1);
    for (var j = 1; j <= b.length; j++) {
      final cost = left == b.codeUnitAt(j - 1) ? 0 : 1;
      var value = previous[j] + 1;
      final insert = current[j - 1] + 1;
      if (insert < value) value = insert;
      final substitute = previous[j - 1] + cost;
      if (substitute < value) value = substitute;
      if (i > 1 &&
          j > 1 &&
          left == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        final transpose = previousPrevious[j - 2] + 1;
        if (transpose < value) value = transpose;
      }
      current[j] = value;
      if (value < rowMin) rowMin = value;
    }
    if (rowMin > maxDistance) return null;
    final oldest = previousPrevious;
    previousPrevious = previous;
    previous = current;
    current = oldest;
  }
  final distance = previous[b.length];
  return distance <= maxDistance ? distance : null;
}

String _collapseDoubleConsonants(String value) {
  if (value.length < 2) return value;
  final out = StringBuffer();
  var previous = 0;
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if (i > 0 && code == previous && _isConsonant(code)) continue;
    out.writeCharCode(code);
    previous = code;
  }
  return out.toString();
}

bool _isConsonant(int code) {
  return (code >= 0x62 && code <= 0x64) ||
      (code >= 0x66 && code <= 0x68) ||
      (code >= 0x6a && code <= 0x6e) ||
      (code >= 0x70 && code <= 0x74) ||
      (code >= 0x76 && code <= 0x7a);
}

class _SynonymHit {
  _SynonymHit({
    required this.exactTokens,
    required this.exactPhrases,
    required this.expansionTokens,
    required this.expansionPhrases,
  });

  final Set<String> exactTokens;
  final List<List<String>> exactPhrases;
  final Set<String> expansionTokens;
  final List<List<String>> expansionPhrases;

  void add(_SynonymHit other) {
    exactTokens.addAll(other.exactTokens);
    exactPhrases.addAll(other.exactPhrases);
    expansionTokens.addAll(other.expansionTokens);
    expansionPhrases.addAll(other.expansionPhrases);
  }
}

class _CompiledGroup {
  _CompiledGroup(this.id);

  final String id;
  final exactTokens = <String>{};
  final exactPhrases = <List<String>>[];
  final oneWayTokens = <String>{};
  final oneWayPhrases = <List<String>>[];
  String? parentId;
  final children = <_CompiledGroup>[];
}

class _SynonymIndex {
  _SynonymIndex._(this._words, this._phrases);

  final Map<String, _SynonymHit> _words;
  final Map<String, _SynonymHit> _phrases;

  _SynonymHit? word(String word) => _words[word];

  _SynonymHit? phrase(List<String> words) {
    if (words.length < 2) return null;
    return _phrases[words.join(' ')];
  }

  static final _SynonymIndex instance = _SynonymIndex._build();

  static _SynonymIndex _build() {
    final byId = <String, _CompiledGroup>{};
    for (final group in deitySynonymGroups) {
      final id = foldTempleSearchText(group.name);
      final compiled = byId.putIfAbsent(id, () => _CompiledGroup(id));
      _addNames(compiled.exactTokens, compiled.exactPhrases, [group.name]);
      _addNames(compiled.exactTokens, compiled.exactPhrases, group.synonyms);
      _addNames(compiled.oneWayTokens, compiled.oneWayPhrases, group.oneWay);
      final parent = group.parent;
      if (parent != null && parent.trim().isNotEmpty) {
        compiled.parentId = foldTempleSearchText(parent);
      }
    }
    for (final group in byId.values) {
      final parentId = group.parentId;
      if (parentId == null) continue;
      byId[parentId]?.children.add(group);
    }

    final words = <String, _SynonymHit>{};
    final phrases = <String, _SynonymHit>{};
    for (final group in byId.values) {
      final hit = _hitFor(group);
      for (final token in group.exactTokens) {
        final existing = words[token];
        if (existing == null) {
          words[token] = _copy(hit);
        } else {
          existing.add(hit);
        }
      }
      for (final phrase in group.exactPhrases) {
        phrases[phrase.join(' ')] = _copy(hit);
      }
      for (final token in group.oneWayTokens) {
        words.putIfAbsent(
          token,
          () => _SynonymHit(
            exactTokens: {token},
            exactPhrases: const [],
            expansionTokens: const {},
            expansionPhrases: const [],
          ),
        );
      }
    }
    return _SynonymIndex._(words, phrases);
  }

  static void _addNames(
    Set<String> tokens,
    List<List<String>> phrases,
    List<String> names,
  ) {
    for (final name in names) {
      final parts = _foldPhrase(name);
      if (parts.isEmpty) continue;
      if (parts.length == 1) {
        tokens.add(parts.single);
      } else {
        phrases.add(parts);
      }
    }
  }

  static _SynonymHit _hitFor(_CompiledGroup group) {
    final expansionTokens = <String>{};
    final expansionPhrases = <List<String>>[];
    _collectExpansion(group, expansionTokens, expansionPhrases, self: true);
    return _SynonymHit(
      exactTokens: {...group.exactTokens},
      exactPhrases: [...group.exactPhrases],
      expansionTokens: expansionTokens,
      expansionPhrases: expansionPhrases,
    );
  }

  static void _collectExpansion(
    _CompiledGroup group,
    Set<String> tokens,
    List<List<String>> phrases, {
    required bool self,
  }) {
    if (self) {
      tokens.addAll(group.oneWayTokens);
      phrases.addAll(group.oneWayPhrases);
    }
    for (final child in group.children) {
      tokens.addAll(child.exactTokens);
      phrases.addAll(child.exactPhrases);
      _collectExpansion(child, tokens, phrases, self: true);
    }
  }

  static _SynonymHit _copy(_SynonymHit hit) {
    return _SynonymHit(
      exactTokens: {...hit.exactTokens},
      exactPhrases: [...hit.exactPhrases],
      expansionTokens: {...hit.expansionTokens},
      expansionPhrases: [...hit.expansionPhrases],
    );
  }
}

final _SynonymIndex _synonyms = _SynonymIndex.instance;

List<String> _foldPhrase(String phrase) {
  final tokens = <String>[];
  for (final word in phrase.trim().toLowerCase().split(_splitMarks)) {
    final token = foldTempleSearchText(word);
    if (token.isNotEmpty) tokens.add(token);
  }
  return tokens;
}
