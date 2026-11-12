import 'package:flutter/foundation.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/deity_groups.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/utils/temple_search.dart';

/// States present on the loaded temples, sorted. Not a hard-coded catalog.
List<String> directoryStatesFrom(Iterable<Temple> temples) {
  final states = <String>{
    for (final temple in temples)
      if (temple.state.trim().isNotEmpty) temple.state.trim(),
  };
  final sorted = states.toList()..sort();
  return sorted;
}

/// Deity labels present on the loaded temples, sorted.
///
/// Exact [Temple.deity] strings, including Jain and Buddhist listings.
List<String> directoryDeitiesFrom(Iterable<Temple> temples) {
  final deities = <String>{
    for (final temple in temples)
      if (temple.deity.trim().isNotEmpty) temple.deity.trim(),
  };
  final sorted = deities.toList()..sort();
  return sorted;
}

/// Honesty chip for a listed deity, or null for the Hindu-first default.
///
/// Jain, Buddhist, and Sikh strings stay labeled as those traditions.
String? listedDeityTraditionLabel(String deity) {
  return switch (traditionFromDeityText(deity)) {
    SiteTradition.jain => 'Jain',
    SiteTradition.buddhist => 'Buddhist',
    SiteTradition.sikh => 'Sikh',
    SiteTradition.unspecified => null,
  };
}

/// Display label from a stored or indexed tradition field, then the deity text.
String? listedTempleTraditionLabel(Temple temple) {
  return switch (directoryTraditionKey(temple)) {
    'jain' => 'Jain',
    'buddhist' => 'Buddhist',
    'sikh' => 'Sikh',
    _ => null,
  };
}

/// Jain, Buddhist, or Sikh for an exact `jain` / `buddhist` / `sikh` value.
String? templeTraditionLabel(String? value) {
  return switch (value) {
    'jain' => 'Jain',
    'buddhist' => 'Buddhist',
    'sikh' => 'Sikh',
    _ => null,
  };
}

/// Lookup used when grouping loaded temples, so a stored tradition labels
/// a deity such as "Guru Granth Sahib" even when the text has no Sikh words.
DeityTraditionOf traditionOfLoadedTemples(Iterable<Temple> temples) {
  final byKey = <String, String>{};
  for (final temple in temples) {
    final label = listedTempleTraditionLabel(temple);
    if (label == null) continue;
    final key = deityGroupKey(temple.deity);
    if (key.isEmpty) continue;
    byKey[key] ??= label;
  }
  return (name) => byKey[deityGroupKey(name)];
}

/// Filter / census key: `jain`, `buddhist`, `sikh`, or [directoryTraditionHindu].
const directoryTraditionHindu = 'hindu';

/// Display order for Tradition sheet options that are present in the directory.
const directoryTraditionOrder = ['hindu', 'sikh', 'jain', 'buddhist'];

/// Stored, indexed, or deity-inferred tradition key for chips and census.
String directoryTraditionKey(Temple temple) {
  final stored =
      templeTraditionField(temple.indexTradition) ??
      templeTraditionField(temple.tradition);
  if (stored != null) return stored;
  return switch (traditionFromDeityText(temple.deity)) {
    SiteTradition.jain => 'jain',
    SiteTradition.buddhist => 'buddhist',
    SiteTradition.sikh => 'sikh',
    SiteTradition.unspecified => directoryTraditionHindu,
  };
}

/// Chip and sheet label for a [directoryTraditionKey] value.
String directoryTraditionChipLabel(String key) {
  return switch (key) {
    'jain' => 'Jain',
    'buddhist' => 'Buddhist',
    'sikh' => 'Sikh',
    'hindu' => 'Hindu',
    _ => key,
  };
}

/// True when [selected] is empty or the listing's tradition key matches it.
bool traditionMatches(Temple temple, String? selected) {
  if (selected == null || selected.trim().isEmpty) return true;
  return directoryTraditionKey(temple) == selected.trim();
}

/// Tradition keys present on the loaded listings, in [directoryTraditionOrder].
List<String> directoryTraditionsFrom(Iterable<Temple> temples) {
  final present = {for (final temple in temples) directoryTraditionKey(temple)};
  return [
    for (final key in directoryTraditionOrder)
      if (present.contains(key)) key,
  ];
}

/// Count line for the filter bar and related copy.
String directoryPlaceCountLabel(int count) {
  return count == 1 ? '1 place' : '$count places';
}

/// Chip text for a selected deity, with a tradition suffix when one applies.
String directoryDeityChipLabel(String deity, {String? tradition}) {
  final label = tradition ?? listedDeityTraditionLabel(deity);
  if (label == null) return deity;
  return '$deity · $label';
}

/// Subtitle for the Deity sheet.
///
/// With no Jain, Buddhist, or Sikh name this is "N deities". Otherwise it
/// names those traditions, for example "Jain and Buddhist sites are labelled
/// by their own tradition, not Hindu darshan."
String directoryDeityFilterNote(
  Iterable<String> deities, {
  int? count,
  Iterable<String> traditionLabels = const [],
}) {
  const order = ['Jain', 'Buddhist', 'Sikh'];
  final extra = traditionLabels.toSet();
  final present = [
    for (final label in order)
      if (extra.contains(label) ||
          deities.any((deity) => listedDeityTraditionLabel(deity) == label))
        label,
  ];
  if (present.isEmpty) {
    final total = count ?? deities.length;
    return '$total deities';
  }
  final joined = switch (present.length) {
    1 => present.single,
    2 => '${present[0]} and ${present[1]}',
    _ =>
      '${present.sublist(0, present.length - 1).join(', ')} and ${present.last}',
  };
  return '$joined sites are labelled by their own tradition, not Hindu darshan.';
}

/// District name for one loaded temple, or null when it is not resolved.
typedef TempleDistrictName = String? Function(Temple temple);

/// District names for temples in [state], sorted. Blank names are skipped.
///
/// A null [districtOf] means the boundary asset has not been opened yet.
List<String> directoryDistrictsFrom(
  Iterable<Temple> temples, {
  String? state,
  TempleDistrictName? districtOf,
}) {
  if (districtOf == null) return const [];
  final names = <String>{};
  for (final temple in temples) {
    if (state != null && state.isNotEmpty && temple.state != state) continue;
    final name = districtOf(temple)?.trim() ?? '';
    if (name.isEmpty) continue;
    names.add(name);
  }
  final sorted = names.toList()..sort();
  return sorted;
}

/// Whether the District chip should be on screen.
///
/// Before the asset loads ([districtOf] is null) the chip is shown when any
/// in-scope temple has coordinates. After it loads, the chip is shown only
/// when at least one district name resolved, or a district is already chosen.
bool directoryDistrictChipVisible({
  required Iterable<Temple> temples,
  String? state,
  String? selectedDistrict,
  TempleDistrictName? districtOf,
}) {
  if (selectedDistrict != null && selectedDistrict.trim().isNotEmpty) {
    return true;
  }
  if (districtOf == null) {
    for (final temple in temples) {
      if (!temple.hasCoordinates) continue;
      if (state != null && state.isNotEmpty && temple.state != state) {
        continue;
      }
      return true;
    }
    return false;
  }
  return directoryDistrictsFrom(
    temples,
    state: state,
    districtOf: districtOf,
  ).isNotEmpty;
}

/// [filterTemples], then the district name when one is selected.
///
/// District is applied here so search stays untouched. A selected district
/// with no lookup yet matches nothing.
List<Temple> directoryMatchingTemples(
  List<Temple> temples, {
  String? state,
  String? deity,
  String? district,
  String? tradition,
  String query = '',
  TempleDistrictName? districtOf,
}) {
  final matched = [
    for (final temple in filterTemples(temples, state: state, query: query))
      if (deityGroupMatches(temple.deity, deity) &&
          traditionMatches(temple, tradition))
        temple,
  ];
  if (district == null || district.trim().isEmpty) return matched;
  if (districtOf == null) return const [];
  final wanted = district.trim();
  return [
    for (final temple in matched)
      if ((districtOf(temple)?.trim() ?? '') == wanted) temple,
  ];
}

/// App-bar title for a browse list constrained by these chips.
String directoryBrowseTitle({
  String? state,
  String? deity,
  String? district,
  String? tradition,
}) {
  final parts = <String>[
    if (deity != null && deity.isNotEmpty) deity,
    if (district != null && district.isNotEmpty) district,
    if (state != null && state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return 'All places';
  return parts.join(' · ');
}

/// Empty-state copy. Mentions district only when that chip is constraining.
String directoryEmptyFilterMessage({String? district, String? tradition}) {
  return 'Nothing in the loaded directory fits these filters.';
}

/// True when [deity] still has at least one listing under [tradition].
bool directoryDeityFitsTradition(
  Iterable<Temple> temples, {
  required String? deity,
  required String? tradition,
}) {
  if (deity == null || deity.isEmpty) return true;
  if (tradition == null || tradition.isEmpty) return true;
  return temples.any(
    (temple) =>
        deityGroupMatches(temple.deity, deity) &&
        traditionMatches(temple, tradition),
  );
}

/// Label for the sheet's apply action.
String directoryFilterResultLabel(int count) {
  return 'Show ${directoryPlaceCountLabel(count)}';
}

/// Counts for every option in the filter sheet, from one walk of [temples].
///
/// The sheet used to call [directoryMatchingTemples] once per chip. That
/// ranks the whole directory again for every state, deity, and district.
/// A header drag rebuilds the sheet, so the walk ran on the UI thread for
/// each pointer-down. This census is that walk, once.
class DirectoryOptionCensus {
  const DirectoryOptionCensus({
    required this.matched,
    required this.anyState,
    required this.stateCounts,
    required this.anyDeity,
    required this.deityCounts,
    required this.anyDistrict,
    required this.districtCounts,
    required this.anyTradition,
    required this.traditionCounts,
  });

  /// Temples matching the draft state, deity, district, tradition, and query together.
  final int matched;

  /// Temples matching the draft deity, district, tradition, and query, any state.
  final int anyState;
  final Map<String, int> stateCounts;

  /// Temples matching the draft state, district, tradition, and query, any deity.
  final int anyDeity;
  final Map<String, int> deityCounts;

  /// Temples matching the draft state, deity, tradition, and query, any district.
  final int anyDistrict;
  final Map<String, int> districtCounts;

  /// Temples matching the draft state, deity, district, and query, any tradition.
  final int anyTradition;
  final Map<String, int> traditionCounts;

  int stateCount(String state) => stateCounts[state] ?? 0;

  int deityCount(String deity) => deityCounts[deity] ?? 0;

  int districtCount(String district) => districtCounts[district] ?? 0;

  int traditionCount(String tradition) => traditionCounts[tradition] ?? 0;
}

/// How many times [directoryOptionCensus] has run.
///
/// Widget tests reset this. A header drag must not run it once per chip.
@visibleForTesting
int directoryOptionCensusCalls = 0;

/// One pass over [temples] for the sheet's option counts.
///
/// A district that belongs to another state is ignored for that state's
/// chip, matching the sheet's state picker. It still constrains the other
/// counts. A selected district with no lookup yet matches no temple, and
/// it does not paint state chips as zero.
DirectoryOptionCensus directoryOptionCensus(
  List<Temple> temples, {
  String? state,
  String? deity,
  String? district,
  String? tradition,
  String query = '',
  TempleDistrictName? districtOf,
}) {
  directoryOptionCensusCalls++;
  final wanted = district?.trim() ?? '';
  final wantedState = state?.trim() ?? '';
  final wantedDeity = deity?.trim() ?? '';
  final wantedTradition = tradition?.trim() ?? '';
  final wantedDeityKey = wantedDeity.isEmpty ? '' : deityGroupKey(wantedDeity);
  final deityLabelOf = {
    for (final group in groupDeityNames(temples.map((temple) => temple.deity)))
      group.key: group.label,
  };
  final useDistrict = wanted.isNotEmpty;
  final districtsInState = <String, Set<String>>{};
  if (useDistrict && districtOf != null) {
    for (final temple in temples) {
      final name = districtOf(temple)?.trim() ?? '';
      if (name.isEmpty) continue;
      final templeState = temple.state.trim();
      if (templeState.isEmpty) continue;
      (districtsInState[templeState] ??= <String>{}).add(name);
    }
  }

  final stateCounts = <String, int>{};
  final deityCounts = <String, int>{};
  final districtCounts = <String, int>{};
  final traditionCounts = <String, int>{};
  var matched = 0;
  var anyState = 0;
  var anyDeity = 0;
  var anyDistrict = 0;
  var anyTradition = 0;

  for (final temple in temples) {
    if (!templeMatchesQuery(temple, query)) continue;
    final templeState = temple.state.trim();
    final templeDeity = temple.deity.trim();
    final templeDistrict = districtOf == null
        ? ''
        : (districtOf(temple)?.trim() ?? '');
    final templeTradition = directoryTraditionKey(temple);
    final stateOk = wantedState.isEmpty || templeState == wantedState;
    final deityOk =
        wantedDeityKey.isEmpty || deityGroupKey(templeDeity) == wantedDeityKey;
    final districtOk =
        !useDistrict || (districtOf != null && templeDistrict == wanted);
    final traditionOk =
        wantedTradition.isEmpty || templeTradition == wantedTradition;

    if (deityOk && districtOk && traditionOk) anyState++;
    if (stateOk && districtOk && traditionOk) anyDeity++;
    if (stateOk && deityOk && traditionOk) anyDistrict++;
    if (stateOk && deityOk && districtOk) anyTradition++;
    if (stateOk && deityOk && districtOk && traditionOk) matched++;

    if (deityOk && traditionOk && templeState.isNotEmpty) {
      final keepsDistrict =
          useDistrict &&
          (districtsInState[templeState]?.contains(wanted) ?? false);
      if (!keepsDistrict || templeDistrict == wanted) {
        stateCounts[templeState] = (stateCounts[templeState] ?? 0) + 1;
      }
    }
    if (stateOk && districtOk && traditionOk && templeDeity.isNotEmpty) {
      final deityLabel =
          deityLabelOf[deityGroupKey(templeDeity)] ?? templeDeity.trim();
      if (deityLabel.isNotEmpty) {
        deityCounts[deityLabel] = (deityCounts[deityLabel] ?? 0) + 1;
      }
    }
    if (stateOk && deityOk && traditionOk && templeDistrict.isNotEmpty) {
      districtCounts[templeDistrict] =
          (districtCounts[templeDistrict] ?? 0) + 1;
    }
    // Tradition options ignore the deity chip so a tradition that would
    // drop a stale deity stays visible (KAN-203). Any-tradition still
    // respects deity, because that row means "clear Tradition only".
    if (stateOk && districtOk) {
      traditionCounts[templeTradition] =
          (traditionCounts[templeTradition] ?? 0) + 1;
    }
  }

  return DirectoryOptionCensus(
    matched: matched,
    anyState: anyState,
    stateCounts: stateCounts,
    anyDeity: anyDeity,
    deityCounts: deityCounts,
    anyDistrict: anyDistrict,
    districtCounts: districtCounts,
    anyTradition: anyTradition,
    traditionCounts: traditionCounts,
  );
}
