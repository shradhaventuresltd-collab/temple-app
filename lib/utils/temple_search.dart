import 'package:temple_app/models/temple.dart';

/// How long a typed query waits before the temple grid refreshes.
const Duration templeSearchDebounce = Duration(milliseconds: 300);

/// Case-insensitive match of [query] against public directory text.
///
/// An empty or whitespace-only query matches every temple. Otherwise the query
/// is trimmed, lowercased, and split on whitespace. Each word must occur in the
/// combined name, city, state, deity, and address ([Temple.location]) after
/// [foldTempleSearchText]. Story and description are not searched.
///
/// Queries shorter than 3 characters skip that folding. They use the old
/// spaced text, so `ee`, `th`, and `it` stay ordinary substrings and `-`
/// stays a hyphen.
///
/// This is the normalised exact check. [filterTemples] adds a short
/// edit-distance fallback only when that check matches nothing.
///
/// A folded query word also matches the canonical place or deity it aliases
/// (`tirupati` → Tirumala, `sivan` → Shiva). See [_searchAliases].
bool templeMatchesQuery(Temple temple, String query) {
  if (query.trim().isEmpty) return true;
  final indexed = _indexFor(temple);
  if (_isShortQuery(query)) {
    return indexed.plain.contains(query.trim().toLowerCase());
  }
  final words = _queryWords(query);
  if (words.isEmpty) return false;
  return _wordsMatchBlob(words, indexed.blob);
}

/// Temples that match [state], [deity], and [query] together.
///
/// A null [state] or [deity] does not constrain that field (exact match when
/// set, same as the drawer chips). An exact match on a name, field, or
/// [_searchAliases] entry outranks every edit-distance match. Edit distance
/// runs only when no temple matched every word exactly. Among equal matches,
/// a [_prominentTemples] entry that the query hits by name or alias sorts
/// ahead of the others; remaining ties keep input order. Queries under 3
/// characters stay plain substrings in input order, with no alias or boost.
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

  final exact = <({Temple temple, int index})>[];
  final missed = <({Temple temple, _TempleIndex indexed, int index})>[];
  var index = 0;
  for (final temple in temples) {
    if (!_passesChips(temple, state, deity)) continue;
    final indexed = _indexFor(temple);
    if (_wordsMatchBlob(words, indexed.blob)) {
      exact.add((temple: temple, index: index));
    } else {
      missed.add((temple: temple, indexed: indexed, index: index));
    }
    index++;
  }
  if (exact.isNotEmpty) {
    exact.sort((a, b) {
      final byBoost = _boostRank(a.temple, words) - _boostRank(b.temple, words);
      if (byBoost != 0) return byBoost;
      return a.index.compareTo(b.index);
    });
    return [for (final row in exact) row.temple];
  }

  final fuzzy = <_FuzzyHit>[];
  for (final row in missed) {
    final score = _fuzzyScore(words, row.indexed.tokens);
    if (score == null) continue;
    fuzzy.add(_FuzzyHit(row.temple, score, row.index));
  }
  fuzzy.sort((a, b) {
    final byScore = a.score.compareTo(b.score);
    if (byScore != 0) return byScore;
    final byBoost = _boostRank(a.temple, words) - _boostRank(b.temple, words);
    if (byBoost != 0) return byBoost;
    return a.index.compareTo(b.index);
  });
  return [for (final hit in fuzzy) hit.temple];
}

/// Folded spellings that mean one place or deity.
///
/// Applied after [foldTempleSearchText], so `Tirupathi` is already `tirupati`
/// and `Shiva` / `Shiv` are already `siva` / `siv`. The value is the folded
/// canonical form stored on the temple (Tirumala, or deity Shiva).
const Map<String, String> _searchAliases = {
  'tirupati': 'tirumala',
  'sivan': 'siva',
  'siv': 'siva',
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
    final canonical = _searchAliases[word];
    if (canonical != null && spec.aliases.contains(canonical)) return true;
    if (spec.aliases.contains(word)) return true;
  }
  return false;
}

List<String> _nameTokens(String name) {
  final tokens = <String>[];
  for (final word in name.trim().toLowerCase().split(_whitespace)) {
    final token = foldTempleSearchText(word);
    if (token.isEmpty || _genericNameTokens.contains(token)) continue;
    tokens.add(token);
  }
  return tokens;
}

bool _wordHitsName(List<String> tokens, String word) {
  if (word.length < 4 || _genericNameTokens.contains(word)) return false;
  for (final token in tokens) {
    if (token.contains(word) || word.contains(token)) return true;
  }
  return false;
}

bool _wordsMatchBlob(List<String> words, String blob) {
  for (final word in words) {
    if (blob.contains(word)) continue;
    final canonical = _searchAliases[word];
    if (canonical != null && blob.contains(canonical)) continue;
    return false;
  }
  return true;
}

/// Folds common Indian transliteration variants.
///
/// Applied to both the query and the indexed text: `zh`/`l`, `sh`/`s`,
/// `th`/`t`, `ee`/`i`, `oo`/`u`, `aa`/`a`, `w`/`v`, doubled consonants, and
/// spaces or hyphens inside a word.
String foldTempleSearchText(String value) {
  var text = value.toLowerCase();
  if (text.isEmpty) return text;
  text = text.replaceAll(_spaceOrHyphen, '');
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

final RegExp _spaceOrHyphen = RegExp(r'[\s-]+');
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

class _TempleIndex {
  _TempleIndex(this.plain, this.blob, this.tokens);

  /// Lowercased directory text with spaces kept, for queries under 3 characters.
  final String plain;

  /// Folded fields joined so a word cannot match across two fields.
  final String blob;
  final List<String> tokens;

  static _TempleIndex build(Temple temple) {
    final fields = [
      temple.name,
      temple.city,
      temple.state,
      temple.deity,
      temple.location,
    ];
    final plainFields = <String>[];
    final foldedFields = <String>[];
    final tokens = <String>[];
    for (final field in fields) {
      final trimmed = field.trim().toLowerCase();
      if (trimmed.isEmpty) continue;
      plainFields.add(trimmed.replaceAll(_whitespace, ' '));
      final folded = foldTempleSearchText(trimmed);
      if (folded.isNotEmpty) foldedFields.add(folded);
      for (final word in trimmed.split(_whitespace)) {
        final token = foldTempleSearchText(word);
        if (token.isNotEmpty) tokens.add(token);
      }
    }
    return _TempleIndex(
      plainFields.join(' '),
      foldedFields.join('\u0000'),
      tokens,
    );
  }
}

class _FuzzyHit {
  _FuzzyHit(this.temple, this.score, this.index);

  final Temple temple;
  final int score;
  final int index;
}

/// Sum of per-word distances, or null when any word is out of tolerance.
///
/// Words under 5 characters must match exactly. 5–7 characters allow one
/// edit, and 8 or more allow two. Distance is measured against indexed
/// words, not the whole listing.
int? _fuzzyScore(List<String> words, List<String> tokens) {
  var total = 0;
  for (final word in words) {
    final maxDistance = _maxEditDistance(word.length);
    if (maxDistance == 0) return null;
    var best = maxDistance + 1;
    for (final token in tokens) {
      final distance = _editDistanceAtMost(word, token, maxDistance);
      if (distance == null || distance >= best) continue;
      best = distance;
      if (best <= 1) break;
    }
    if (best > maxDistance) return null;
    total += best;
  }
  return total;
}

int _maxEditDistance(int length) {
  if (length < 5) return 0;
  if (length <= 7) return 1;
  return 2;
}

int? _editDistanceAtMost(String a, String b, int maxDistance) {
  if ((a.length - b.length).abs() > maxDistance) return null;
  if (maxDistance == 0) return a == b ? 0 : null;
  if (a == b) return 0;

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
      current[j] = value;
      if (value < rowMin) rowMin = value;
    }
    if (rowMin > maxDistance) return null;
    final swap = previous;
    previous = current;
    current = swap;
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
