import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/detail_honesty.dart';

/// How a synonym group is applied to a listing's resolved tradition.
enum TraditionSynonymMode { expand, nameOnly }

/// One row of the KAN-203 §3.1 synonym table.
class TraditionSynonymGroup {
  const TraditionSynonymGroup({
    required this.tradition,
    required this.mode,
    required this.forms,
  });

  /// `sikh`, `jain`, or `buddhist`.
  final String tradition;
  final TraditionSynonymMode mode;

  /// Typed forms, already lowercased. Diacritic variants are folded at lookup.
  final List<String> forms;
}

/// Place-type words that expand to every listing of that tradition.
const traditionSynonymGroups = [
  TraditionSynonymGroup(
    tradition: 'sikh',
    mode: TraditionSynonymMode.expand,
    forms: [
      'gurdwara',
      'gurudwara',
      'gurdwaras',
      'gurudwaras',
      'gurdwara sahib',
      'gurudwara sahib',
      'guru dwara',
      'guru dwaras',
    ],
  ),
  TraditionSynonymGroup(
    tradition: 'jain',
    mode: TraditionSynonymMode.expand,
    forms: [
      'derasar',
      'derasars',
      'basadi',
      'basadis',
      'jinalaya',
      'jainalaya',
    ],
  ),
  TraditionSynonymGroup(
    tradition: 'buddhist',
    mode: TraditionSynonymMode.expand,
    forms: [
      'vihara',
      'viharas',
      'stupa',
      'stupas',
      'monastery',
      'monasteries',
      'gompa',
      'gompas',
      'gonpa',
      'gonpas',
    ],
  ),
  TraditionSynonymGroup(
    tradition: 'jain',
    mode: TraditionSynonymMode.nameOnly,
    forms: ['basti', 'bastis'],
  ),
];

/// Cached tradition key: stored document field, then the index flag, then
/// deity text. Hindu is [directoryTraditionHinduValue].
///
/// One helper for directory chips, census, and search. The document field
/// is preferred when both stored values are set (review #142).
const directoryTraditionHinduValue = 'hindu';

final Expando<String> _traditionKeyCache = Expando<String>();

/// `jain`, `buddhist`, `sikh`, or `hindu` for [temple], computed once.
String templeTraditionKey(Temple temple) {
  final cached = _traditionKeyCache[temple];
  if (cached != null) return cached;
  final stored =
      templeTraditionField(temple.tradition) ??
      templeTraditionField(temple.indexTradition);
  final key =
      stored ??
      switch (traditionFromDeityText(temple.deity)) {
        SiteTradition.jain => 'jain',
        SiteTradition.buddhist => 'buddhist',
        SiteTradition.sikh => 'sikh',
        SiteTradition.unspecified => directoryTraditionHinduValue,
      };
  _traditionKeyCache[temple] = key;
  return key;
}

/// Non-Hindu key for search expansion, or null for Hindu.
String? traditionSearchKey(Temple temple) {
  final key = templeTraditionKey(temple);
  return key == directoryTraditionHinduValue ? null : key;
}

/// Strip Latin diacritics for synonym lookup only. Callers then apply
/// [foldTempleSearchText] so `gurdwārā` hits `gurdwara` without changing
/// the general search fold.
String stripTraditionDiacritics(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final ch = String.fromCharCode(rune);
    buffer.write(_latinDiacriticToAscii[ch] ?? ch);
  }
  return buffer.toString();
}

const _latinDiacriticToAscii = {
  'ā': 'a',
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'å': 'a',
  'Ā': 'A',
  'Á': 'A',
  'À': 'A',
  'Ä': 'A',
  'Â': 'A',
  'ē': 'e',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'Ē': 'E',
  'É': 'E',
  'È': 'E',
  'Ë': 'E',
  'Ê': 'E',
  'ī': 'i',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'Ī': 'I',
  'Í': 'I',
  'Ì': 'I',
  'Ï': 'I',
  'Î': 'I',
  'ō': 'o',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'Ō': 'O',
  'Ó': 'O',
  'Ò': 'O',
  'Ö': 'O',
  'Ô': 'O',
  'ū': 'u',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'Ū': 'U',
  'Ú': 'U',
  'Ù': 'U',
  'Ü': 'U',
  'Û': 'U',
  'ś': 's',
  'ş': 's',
  'š': 's',
  'Ś': 'S',
  'ṇ': 'n',
  'ñ': 'n',
  'ń': 'n',
  'ṭ': 't',
  'ḍ': 'd',
  'ṛ': 'r',
  'ḷ': 'l',
  'ḥ': 'h',
  'ṃ': 'm',
};
