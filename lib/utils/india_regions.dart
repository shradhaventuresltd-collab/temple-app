/// Visitor-facing regions for the State filter (KAN-198).
///
/// This is the mapping in the KAN-198 spec, not a fresh one. It is a
/// geographic browse grouping. It differs from the Ministry of Home Affairs
/// zonal councils where a visitor would look in a different place:
///
/// * Uttar Pradesh and Uttarakhand are North. The Central Zonal Council
///   lists them as Central.
/// * Rajasthan is West. The Northern Zonal Council lists it as North.
/// * The North Eastern Council states are a Northeast sub-group of East.
///   [indiaRegionOf] still reports [IndiaRegion.east] for them, so each
///   state belongs to exactly one region.
/// * Andaman & Nicobar Islands and Lakshadweep are South, matching the
///   Southern Zonal Council invitees.
///
/// Only names that appear on loaded temples are shown. A string that is not
/// in this table is still listed, under Other, so a directory row is never
/// dropped. Zero-count rows are hidden by the sheet, not by this table.
library;

/// The five jump-chip regions, in the order the sheet shows them.
enum IndiaRegion { north, south, east, west, central }

/// Sheet order. Northeast sits inside East, then West and Central.
const List<String> kIndiaStateSectionOrder = [
  'north',
  'south',
  'east',
  'northeast',
  'west',
  'central',
  'other',
];

/// One state or union territory and the section it is filed under.
///
/// `region` is `northeast` for the East sub-group. Every other value is an
/// [IndiaRegion] name. Each [name] appears once.
const List<({String name, String region})> kIndiaStateRegions = [
  // North — Chandigarh, Delhi, Haryana, Himachal Pradesh, Jammu and Kashmir,
  // Ladakh, Punjab, Uttar Pradesh, Uttarakhand.
  (name: 'Chandigarh', region: 'north'),
  (name: 'Delhi', region: 'north'),
  (name: 'Haryana', region: 'north'),
  (name: 'Himachal Pradesh', region: 'north'),
  (name: 'Jammu and Kashmir', region: 'north'),
  (name: 'Ladakh', region: 'north'),
  (name: 'Punjab', region: 'north'),
  (name: 'Uttar Pradesh', region: 'north'),
  (name: 'Uttarakhand', region: 'north'),
  // South — Andaman & Nicobar, Andhra Pradesh, Karnataka, Kerala,
  // Lakshadweep, Puducherry, Tamil Nadu, Telangana.
  (name: 'Andaman & Nicobar Islands', region: 'south'),
  (name: 'Andhra Pradesh', region: 'south'),
  (name: 'Karnataka', region: 'south'),
  (name: 'Kerala', region: 'south'),
  (name: 'Lakshadweep', region: 'south'),
  (name: 'Puducherry', region: 'south'),
  (name: 'Tamil Nadu', region: 'south'),
  (name: 'Telangana', region: 'south'),
  // East — Bihar, Jharkhand, Odisha, West Bengal.
  (name: 'Bihar', region: 'east'),
  (name: 'Jharkhand', region: 'east'),
  (name: 'Odisha', region: 'east'),
  (name: 'West Bengal', region: 'east'),
  // Northeast, shown under East.
  (name: 'Arunachal Pradesh', region: 'northeast'),
  (name: 'Assam', region: 'northeast'),
  (name: 'Manipur', region: 'northeast'),
  (name: 'Meghalaya', region: 'northeast'),
  (name: 'Mizoram', region: 'northeast'),
  (name: 'Nagaland', region: 'northeast'),
  (name: 'Sikkim', region: 'northeast'),
  (name: 'Tripura', region: 'northeast'),
  // West — Dadra and Nagar Haveli and Daman and Diu, Goa, Gujarat,
  // Maharashtra, Rajasthan.
  (name: 'Dadra and Nagar Haveli and Daman and Diu', region: 'west'),
  (name: 'Goa', region: 'west'),
  (name: 'Gujarat', region: 'west'),
  (name: 'Maharashtra', region: 'west'),
  (name: 'Rajasthan', region: 'west'),
  // Central — Chhattisgarh, Madhya Pradesh.
  (name: 'Chhattisgarh', region: 'central'),
  (name: 'Madhya Pradesh', region: 'central'),
];

/// Spellings that mean the same state as a catalogued name.
const Map<String, String> kIndiaStateAliases = {
  'Andaman and Nicobar Islands': 'Andaman & Nicobar Islands',
  'Andaman & Nicobar': 'Andaman & Nicobar Islands',
  'NCT of Delhi': 'Delhi',
  'Jammu & Kashmir': 'Jammu and Kashmir',
  'Orissa': 'Odisha',
  'Pondicherry': 'Puducherry',
  'DNH & DD': 'Dadra and Nagar Haveli and Daman and Diu',
  'Dadra & Nagar Haveli and Daman & Diu':
      'Dadra and Nagar Haveli and Daman and Diu',
};

const Set<String> kIndiaUnionTerritories = {
  'Andaman & Nicobar Islands',
  'Andaman and Nicobar Islands',
  'Andaman & Nicobar',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'DNH & DD',
  'Dadra & Nagar Haveli and Daman & Diu',
  'Delhi',
  'NCT of Delhi',
  'Jammu and Kashmir',
  'Jammu & Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
  'Pondicherry',
};

final Map<String, String> _regionByName = {
  for (final entry in kIndiaStateRegions) entry.name: entry.region,
};

/// The region for [state], or null when the directory uses an unknown label.
///
/// Northeast states return [IndiaRegion.east]. Null means the sheet files
/// the label under Other.
IndiaRegion? indiaRegionOf(String state) {
  final section = indiaStateSectionId(state);
  if (section == null || section == 'other') return null;
  final regionName = section == 'northeast' ? 'east' : section;
  for (final region in IndiaRegion.values) {
    if (region.name == regionName) return region;
  }
  return null;
}

/// Sheet section id: `north`, `south`, `east`, `northeast`, `west`,
/// `central`, or null when [state] is not catalogued.
String? indiaStateSectionId(String state) {
  final trimmed = state.trim();
  final canonical = kIndiaStateAliases[trimmed] ?? trimmed;
  return _regionByName[canonical];
}

/// True for union territories and the National Capital Territory.
bool indiaStateIsUnionTerritory(String state) {
  final trimmed = state.trim();
  if (kIndiaUnionTerritories.contains(trimmed)) return true;
  final canonical = kIndiaStateAliases[trimmed];
  return canonical != null && kIndiaUnionTerritories.contains(canonical);
}

/// Heading for a section id, matching the sheet's small-caps labels.
String indiaStateSectionTitle(String sectionId) {
  return switch (sectionId) {
    'north' => 'NORTH',
    'south' => 'SOUTH',
    'east' => 'EAST',
    'northeast' => 'NORTHEAST',
    'west' => 'WEST',
    'central' => 'CENTRAL',
    _ => 'OTHER',
  };
}

/// States from [states] grouped for the sheet.
///
/// Known names stay in [kIndiaStateSectionOrder]. Unknown names keep their
/// spelling and go in a trailing Other section. Empty sections are omitted.
/// Order inside a section is Dart's default [String] sort.
List<IndiaStateSection> groupStatesByRegion(Iterable<String> states) {
  final buckets = <String, List<String>>{};
  for (final raw in states) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    final section = indiaStateSectionId(name) ?? 'other';
    (buckets[section] ??= <String>[]).add(name);
  }
  final sections = <IndiaStateSection>[];
  for (final id in kIndiaStateSectionOrder) {
    final names = buckets[id];
    if (names == null || names.isEmpty) continue;
    names.sort();
    sections.add(
      IndiaStateSection(
        id: id,
        title: indiaStateSectionTitle(id),
        states: List<String>.unmodifiable(names),
      ),
    );
  }
  return sections;
}

class IndiaStateSection {
  const IndiaStateSection({
    required this.id,
    required this.title,
    required this.states,
  });

  /// `north`, `northeast`, `other`, and the other section ids.
  final String id;
  final String title;
  final List<String> states;
}
