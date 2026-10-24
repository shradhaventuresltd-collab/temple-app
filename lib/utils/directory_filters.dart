import 'package:temple_app/l10n/app_locale.dart';
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
String? listedDeityTraditionLabel(String deity, [AppLocalizations? l10n]) {
  final copy = l10n ?? L10nLookup.english;
  return switch (traditionFromDeityText(deity)) {
    SiteTradition.jain => copy.traditionJain,
    SiteTradition.buddhist => copy.traditionBuddhist,
    SiteTradition.sikh => copy.traditionSikh,
    SiteTradition.unspecified => null,
  };
}

/// Chip text for a selected deity, with a tradition suffix when one applies.
String directoryDeityChipLabel(String deity, [AppLocalizations? l10n]) {
  final tradition = listedDeityTraditionLabel(deity, l10n);
  if (tradition == null) return deity;
  return '$deity · $tradition';
}

/// Note under the deity section when [deities] includes a non-Hindu label.
String? directoryDeityFilterNote(
  Iterable<String> deities, [
  AppLocalizations? l10n,
]) {
  final copy = l10n ?? L10nLookup.english;
  const order = [
    SiteTradition.jain,
    SiteTradition.buddhist,
    SiteTradition.sikh,
  ];
  final present = [
    for (final tradition in order)
      if (deities.any((deity) => traditionFromDeityText(deity) == tradition))
        switch (tradition) {
          SiteTradition.jain => copy.traditionJain,
          SiteTradition.buddhist => copy.traditionBuddhist,
          SiteTradition.sikh => copy.traditionSikh,
          SiteTradition.unspecified => '',
        },
  ];
  if (present.isEmpty) return null;
  final joined = switch (present.length) {
    1 => present.single,
    2 => copy.listPair(present[0], present[1]),
    _ => copy.listAndLast(
      present.sublist(0, present.length - 1).join(', '),
      present.last,
    ),
  };
  return copy.deityTraditionNote(joined);
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
String directoryBrowseTitle({
  String? state,
  String? deity,
  String? district,
  AppLocalizations? l10n,
}) {
  final parts = <String>[
    if (deity != null && deity.isNotEmpty) deity,
    if (district != null && district.isNotEmpty) district,
    if (state != null && state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return (l10n ?? L10nLookup.english).allTemples;
  return parts.join(' · ');
}

/// Empty-state copy. Mentions district only when that chip is constraining.
String directoryEmptyFilterMessage({String? district, AppLocalizations? l10n}) {
  final copy = l10n ?? L10nLookup.english;
  if (district != null && district.isNotEmpty) {
    return copy.emptyFilterWithDistrict;
  }
  return copy.emptyFilterStateDeity;
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
String directoryFilterResultLabel(int count, [AppLocalizations? l10n]) {
  return (l10n ?? L10nLookup.english).showTempleCount(count);
}
