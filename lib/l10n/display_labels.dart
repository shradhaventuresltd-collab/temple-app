import 'package:temple_app/l10n/app_localizations.dart';
import 'package:temple_app/utils/india_regions.dart';

/// Display name for a canonical state. Unknown spellings stay as stored.
String stateDisplayLabel(AppLocalizations l10n, String canonical) {
  final trimmed = canonical.trim();
  final name = kIndiaStateAliases[trimmed] ?? trimmed;
  return switch (name) {
    'Andaman & Nicobar Islands' => l10n.filterStateAndamanNicobar,
    'Andhra Pradesh' => l10n.filterStateAndhraPradesh,
    'Arunachal Pradesh' => l10n.filterStateArunachalPradesh,
    'Assam' => l10n.filterStateAssam,
    'Bihar' => l10n.filterStateBihar,
    'Chandigarh' => l10n.filterStateChandigarh,
    'Chhattisgarh' => l10n.filterStateChhattisgarh,
    'Dadra and Nagar Haveli and Daman and Diu' => l10n.filterStateDadra,
    'Delhi' => l10n.filterStateDelhi,
    'Goa' => l10n.filterStateGoa,
    'Gujarat' => l10n.filterStateGujarat,
    'Haryana' => l10n.filterStateHaryana,
    'Himachal Pradesh' => l10n.filterStateHimachalPradesh,
    'Jammu and Kashmir' => l10n.filterStateJammuKashmir,
    'Jharkhand' => l10n.filterStateJharkhand,
    'Karnataka' => l10n.filterStateKarnataka,
    'Kerala' => l10n.filterStateKerala,
    'Ladakh' => l10n.filterStateLadakh,
    'Lakshadweep' => l10n.filterStateLakshadweep,
    'Madhya Pradesh' => l10n.filterStateMadhyaPradesh,
    'Maharashtra' => l10n.filterStateMaharashtra,
    'Manipur' => l10n.filterStateManipur,
    'Meghalaya' => l10n.filterStateMeghalaya,
    'Mizoram' => l10n.filterStateMizoram,
    'Nagaland' => l10n.filterStateNagaland,
    'Odisha' => l10n.filterStateOdisha,
    'Puducherry' => l10n.filterStatePuducherry,
    'Punjab' => l10n.filterStatePunjab,
    'Rajasthan' => l10n.filterStateRajasthan,
    'Sikkim' => l10n.filterStateSikkim,
    'Tamil Nadu' => l10n.filterStateTamilNadu,
    'Telangana' => l10n.filterStateTelangana,
    'Tripura' => l10n.filterStateTripura,
    'Uttar Pradesh' => l10n.filterStateUttarPradesh,
    'Uttarakhand' => l10n.filterStateUttarakhand,
    'West Bengal' => l10n.filterStateWestBengal,
    _ => trimmed,
  };
}

/// Display name for a district. Districts are an open catalog, so the
/// canonical English name is shown until a reviewed label exists.
String districtDisplayLabel(AppLocalizations l10n, String canonical) {
  // District names are an open catalog, so the canonical spelling is shown.
  return l10n.localeName.isEmpty ? canonical : canonical;
}

/// Tradition chip word. [key] stays `hindu`, `jain`, `buddhist`, or `sikh`.
String traditionDisplayLabel(AppLocalizations l10n, String key) {
  return switch (key.trim()) {
    'jain' => l10n.traditionJain,
    'buddhist' => l10n.traditionBuddhist,
    'sikh' => l10n.traditionSikh,
    'hindu' => l10n.traditionHindu,
    _ => key,
  };
}

/// Sheet section heading. English stays the small-caps catalog label.
String indiaStateSectionTitleOf(AppLocalizations l10n, String sectionId) {
  return switch (sectionId) {
    'north' => l10n.filterSheetRegionNorthHeading,
    'south' => l10n.filterSheetRegionSouthHeading,
    'east' => l10n.filterSheetRegionEastHeading,
    'northeast' => l10n.filterSheetRegionNortheastHeading,
    'west' => l10n.filterSheetRegionWestHeading,
    'central' => l10n.filterSheetRegionCentralHeading,
    _ => l10n.filterSheetRegionOtherHeading,
  };
}

/// Jump chip. Not derived by changing the case of the heading.
String indiaStateJumpLabel(AppLocalizations l10n, String sectionId) {
  return switch (sectionId) {
    'north' => l10n.filterSheetRegionNorthJump,
    'south' => l10n.filterSheetRegionSouthJump,
    'east' => l10n.filterSheetRegionEastJump,
    'west' => l10n.filterSheetRegionWestJump,
    'central' => l10n.filterSheetRegionCentralJump,
    _ => indiaStateSectionTitleOf(l10n, sectionId),
  };
}

/// Endonym for a supported language code. The same script is used in every locale.
String languageEndonym(AppLocalizations l10n, String languageCode) {
  return switch (languageCode) {
    'hi' => l10n.languageEndonymHi,
    'kn' => l10n.languageEndonymKn,
    'ml' => l10n.languageEndonymMl,
    'ta' => l10n.languageEndonymTa,
    'te' => l10n.languageEndonymTe,
    'mr' => l10n.languageEndonymMr,
    'bn' => l10n.languageEndonymBn,
    'or' => l10n.languageEndonymOr,
    _ => l10n.languageEndonymEn,
  };
}

/// Map native digits from Marathi and Bengali number formats back to Latin.
String latinDigits(String value) {
  const from = '०१२३४५६७८९০১২৩৪৫৬৭৮৯';
  const to = '01234567890123456789';
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString();
}
