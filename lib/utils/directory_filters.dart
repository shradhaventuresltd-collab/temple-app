import 'package:flutter/foundation.dart';
import 'package:temple_app/models/temple.dart';
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

/// Chip text for a selected deity, with a tradition suffix when one applies.
String directoryDeityChipLabel(String deity) {
  final tradition = listedDeityTraditionLabel(deity);
  if (tradition == null) return deity;
  return '$deity · $tradition';
}

/// Note under the deity section when [deities] includes a non-Hindu label.
String? directoryDeityFilterNote(Iterable<String> deities) {
  const order = ['Jain', 'Buddhist', 'Sikh'];
  final present = [
    for (final label in order)
      if (deities.any((deity) => listedDeityTraditionLabel(deity) == label))
        label,
  ];
  if (present.isEmpty) return null;
  final joined = switch (present.length) {
    1 => present.single,
    2 => '${present[0]} and ${present[1]}',
    _ =>
      '${present.sublist(0, present.length - 1).join(', ')}, and ${present.last}',
  };
  return '$joined labels are the listed tradition, not Hindu darshan filters.';
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
  String query = '',
  TempleDistrictName? districtOf,
}) {
  final matched = filterTemples(
    temples,
    state: state,
    deity: deity,
    query: query,
  );
  if (district == null || district.trim().isEmpty) return matched;
  if (districtOf == null) return const [];
  final wanted = district.trim();
  return [
    for (final temple in matched)
      if ((districtOf(temple)?.trim() ?? '') == wanted) temple,
  ];
}

/// App-bar title for a browse list constrained by these chips.
String directoryBrowseTitle({String? state, String? deity, String? district}) {
  final parts = <String>[
    if (deity != null && deity.isNotEmpty) deity,
    if (district != null && district.isNotEmpty) district,
    if (state != null && state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return 'All Temples';
  return parts.join(' · ');
}

/// Empty-state copy. Mentions district only when that chip is constraining.
String directoryEmptyFilterMessage({String? district}) {
  if (district != null && district.isNotEmpty) {
    return 'Nothing in the loaded directory fits this state, district, and deity.';
  }
  return 'Nothing in the loaded directory fits this state and deity.';
}

/// How many loaded temples match this state, deity, and query together.
int directoryFilterCount(
  List<Temple> temples, {
  String? state,
  String? deity,
  String query = '',
}) {
  return filterTemples(
    temples,
    state: state,
    deity: deity,
    query: query,
  ).length;
}

/// Label for the sheet's apply action.
String directoryFilterResultLabel(int count) {
  final noun = count == 1 ? 'temple' : 'temples';
  return 'Show $count $noun';
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
  });

  /// Temples matching the draft state, deity, district, and query together.
  final int matched;

  /// Temples matching the draft deity, district, and query, any state.
  final int anyState;
  final Map<String, int> stateCounts;

  /// Temples matching the draft state, district, and query, any deity.
  final int anyDeity;
  final Map<String, int> deityCounts;

  /// Temples matching the draft state, deity, and query, any district.
  final int anyDistrict;
  final Map<String, int> districtCounts;

  int stateCount(String state) => stateCounts[state] ?? 0;

  int deityCount(String deity) => deityCounts[deity] ?? 0;

  int districtCount(String district) => districtCounts[district] ?? 0;
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
  String query = '',
  TempleDistrictName? districtOf,
}) {
  directoryOptionCensusCalls++;
  final wanted = district?.trim() ?? '';
  final wantedState = state?.trim() ?? '';
  final wantedDeity = deity?.trim() ?? '';
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
  var matched = 0;
  var anyState = 0;
  var anyDeity = 0;
  var anyDistrict = 0;

  for (final temple in temples) {
    if (!templeMatchesQuery(temple, query)) continue;
    final templeState = temple.state.trim();
    final templeDeity = temple.deity.trim();
    final templeDistrict = districtOf == null
        ? ''
        : (districtOf(temple)?.trim() ?? '');
    final stateOk = wantedState.isEmpty || templeState == wantedState;
    final deityOk = wantedDeity.isEmpty || templeDeity == wantedDeity;
    final districtOk =
        !useDistrict || (districtOf != null && templeDistrict == wanted);

    if (deityOk && districtOk) anyState++;
    if (stateOk && districtOk) anyDeity++;
    if (stateOk && deityOk) anyDistrict++;
    if (stateOk && deityOk && districtOk) matched++;

    if (deityOk && templeState.isNotEmpty) {
      final keepsDistrict =
          useDistrict &&
          (districtsInState[templeState]?.contains(wanted) ?? false);
      if (!keepsDistrict || templeDistrict == wanted) {
        stateCounts[templeState] = (stateCounts[templeState] ?? 0) + 1;
      }
    }
    if (stateOk && districtOk && templeDeity.isNotEmpty) {
      deityCounts[templeDeity] = (deityCounts[templeDeity] ?? 0) + 1;
    }
    if (stateOk && deityOk && templeDistrict.isNotEmpty) {
      districtCounts[templeDistrict] =
          (districtCounts[templeDistrict] ?? 0) + 1;
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
  );
}
