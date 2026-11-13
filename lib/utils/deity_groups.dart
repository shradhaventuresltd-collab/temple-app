/// Groups listed deity strings by their main name (KAN-198).
///
/// 'Shiva', 'Shiva (Gangadhareshwara)', 'Shiva — Gangadhareshwara', and
/// 'Shiva, Gangadhareshwara' are one Shiva row. The cut is the earliest of
/// '(', ' —', and ','. Case and extra whitespace do not split a group.
/// The group is chosen on the client from names the directory already
/// loaded. Nothing here reads Firestore.
library;

import 'package:temple_app/utils/detail_honesty.dart';

final RegExp _whitespace = RegExp(r'\s+');

/// Text before the earliest of '(', ' —', or ',', with edges folded.
String deityGroupBase(String raw) {
  var text = raw.trim().replaceAll(_whitespace, ' ');
  var cut = text.length;
  for (final mark in ['(', ' —', ',']) {
    final at = text.indexOf(mark);
    if (at >= 0 && at < cut) cut = at;
  }
  if (cut < text.length) text = text.substring(0, cut);
  return text.trim().replaceAll(_whitespace, ' ');
}

/// Stable identity for a deity group. Empty when [raw] has no name.
String deityGroupKey(String raw) => deityGroupBase(raw).toLowerCase();

/// True when [templeDeity] belongs to the group selected by [selected].
///
/// A null or blank [selected] matches every deity. [selected] may be the
/// group's display label or any variant.
bool deityGroupMatches(String templeDeity, String? selected) {
  if (selected == null || selected.trim().isEmpty) return true;
  final want = deityGroupKey(selected);
  if (want.isEmpty) return true;
  return deityGroupKey(templeDeity) == want;
}

/// One row in the Deity sheet.
class DeityGroup {
  const DeityGroup({
    required this.key,
    required this.label,
    required this.variants,
    this.tradition,
  });

  final String key;

  /// The name shown on the row. 'Shiva', not 'Shiva (Gangadhareshwara)'.
  final String label;

  /// Original spellings that fell into this group, in first-seen order.
  final List<String> variants;

  /// Jain, Buddhist, or Sikh when a variant carries that label.
  final String? tradition;

  /// Text the sheet search compares, including parenthetical variants.
  String get searchText {
    final parts = <String>[label, ...variants];
    return parts.join(' ').toLowerCase();
  }
}

/// Optional lookup from a listed deity string to Jain, Buddhist, or Sikh.
typedef DeityTraditionOf = String? Function(String name);

/// Groups [names] into one [DeityGroup] per main deity.
///
/// The label prefers a spelling that already looks like a name ('Shiva'
/// over 'SHIVA' or 'shiva'). When the data only has a parenthetical form,
/// the label is that base. Groups are sorted by label. [traditionOf]
/// supplies a stored or indexed tradition when the deity text has none.
List<DeityGroup> groupDeityNames(
  Iterable<String> names, {
  DeityTraditionOf? traditionOf,
}) {
  final order = <String>[];
  final variants = <String, List<String>>{};
  final bases = <String, Map<String, _BaseVote>>{};
  for (final raw in names) {
    final trimmed = raw.trim().replaceAll(_whitespace, ' ');
    if (trimmed.isEmpty) continue;
    final key = deityGroupKey(trimmed);
    if (key.isEmpty) continue;
    if (!variants.containsKey(key)) order.add(key);
    (variants[key] ??= <String>[]).add(trimmed);
    final base = deityGroupBase(trimmed);
    final votes = bases[key] ??= <String, _BaseVote>{};
    final vote = votes[base] ??= _BaseVote();
    vote.count += 1;
    if (trimmed == base) vote.exact = true;
  }

  final groups = <DeityGroup>[];
  for (final key in order) {
    final label = _chooseLabel(key, bases[key] ?? const {});
    final seen = variants[key] ?? const <String>[];
    String? tradition;
    if (traditionOf != null) {
      tradition = traditionOf(label);
      if (tradition == null) {
        for (final variant in seen) {
          tradition = traditionOf(variant);
          if (tradition != null) break;
        }
      }
    }
    if (tradition == null) {
      for (final variant in seen) {
        tradition = _traditionLabel(deityGroupBase(variant));
        if (tradition != null) break;
        tradition = _traditionLabel(variant);
        if (tradition != null) break;
      }
    }
    groups.add(
      DeityGroup(
        key: key,
        label: label,
        variants: List<String>.unmodifiable(seen),
        tradition: tradition,
      ),
    );
  }
  groups.sort((a, b) => a.label.compareTo(b.label));
  return groups;
}

String _chooseLabel(String key, Map<String, _BaseVote> votes) {
  if (votes.isEmpty) return _titleCase(key);
  final title = _titleCase(key);
  if (votes.containsKey(title)) return title;

  final ranked = votes.entries.toList()
    ..sort((a, b) {
      final exact = (b.value.exact ? 1 : 0) - (a.value.exact ? 1 : 0);
      if (exact != 0) return exact;
      final mixed = (_mixedCase(b.key) ? 1 : 0) - (_mixedCase(a.key) ? 1 : 0);
      if (mixed != 0) return mixed;
      final count = b.value.count - a.value.count;
      if (count != 0) return count;
      final caps = (_allCaps(a.key) ? 1 : 0) - (_allCaps(b.key) ? 1 : 0);
      if (caps != 0) return caps;
      return a.key.compareTo(b.key);
    });
  final best = ranked.first;
  if (best.value.exact || _mixedCase(best.key)) return best.key;
  return title;
}

bool _mixedCase(String value) {
  final letters = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.length < 2) return false;
  final lower = letters.toLowerCase();
  final upper = letters.toUpperCase();
  return letters != lower && letters != upper;
}

bool _allCaps(String value) {
  final letters = value.replaceAll(RegExp(r'[^A-Za-z]'), '');
  return letters.isNotEmpty && letters == letters.toUpperCase();
}

String _titleCase(String lower) {
  return lower
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

class _BaseVote {
  int count = 0;
  bool exact = false;
}

String? _traditionLabel(String deity) {
  return switch (traditionFromDeityText(deity)) {
    SiteTradition.jain => 'Jain',
    SiteTradition.buddhist => 'Buddhist',
    SiteTradition.sikh => 'Sikh',
    SiteTradition.unspecified => null,
  };
}
