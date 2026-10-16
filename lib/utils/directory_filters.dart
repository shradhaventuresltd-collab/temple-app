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

/// App-bar title for a browse list constrained by these chips.
String directoryBrowseTitle({String? state, String? deity}) {
  final parts = <String>[
    if (deity != null && deity.isNotEmpty) deity,
    if (state != null && state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return 'All Temples';
  return parts.join(' · ');
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
