import 'package:temple_app/l10n/app_locale.dart';

/// User-facing copy for Temples near me.
///
/// Widgets pass the resolved [AppLocalizations]. The no-argument getters
/// read the English bundle so tests and the platform permission string stay
/// locked to [app_en.arb].
abstract final class NearMeCopy {
  static final AppLocalizations _en = L10nLookup.english;

  static String titleOf(AppLocalizations l10n) => l10n.nearMeTitle;
  static String get title => titleOf(_en);

  static String rationaleTitleOf(AppLocalizations l10n) =>
      l10n.nearMeRationaleTitle;
  static String get rationaleTitle => rationaleTitleOf(_en);

  static String rationaleBodyOf(AppLocalizations l10n) =>
      l10n.nearMeRationaleBody;
  static String get rationaleBody => rationaleBodyOf(_en);

  static String continueLabelOf(AppLocalizations l10n) => l10n.continueLabel;
  static String get continueLabel => continueLabelOf(_en);

  static String notNowOf(AppLocalizations l10n) => l10n.notNow;
  static String get notNow => notNowOf(_en);

  static String locatingOf(AppLocalizations l10n) => l10n.nearMeLocating;
  static String get locating => locatingOf(_en);

  static String nearestHeadingOf(AppLocalizations l10n) =>
      l10n.nearMeNearestHeading;
  static String get nearestHeading => nearestHeadingOf(_en);

  static String deniedBodyOf(AppLocalizations l10n) => l10n.nearMeDeniedBody;
  static String get deniedBody => deniedBodyOf(_en);

  static String deniedForeverBodyOf(AppLocalizations l10n) =>
      l10n.nearMeDeniedForeverBody;
  static String get deniedForeverBody => deniedForeverBodyOf(_en);

  static String openSettingsOf(AppLocalizations l10n) =>
      l10n.nearMeOpenSettings;
  static String get openSettings => openSettingsOf(_en);

  static String enableLocationOf(AppLocalizations l10n) =>
      l10n.nearMeEnableLocation;
  static String get enableLocation => enableLocationOf(_en);

  static String serviceOffBodyOf(AppLocalizations l10n) =>
      l10n.nearMeServiceOffBody;
  static String get serviceOffBody => serviceOffBodyOf(_en);

  static String retryOf(AppLocalizations l10n) => l10n.tryAgain;
  static String get retry => retryOf(_en);

  static String openLocationSettingsOf(AppLocalizations l10n) =>
      l10n.nearMeOpenLocationSettings;
  static String get openLocationSettings => openLocationSettingsOf(_en);

  static String timedOutBodyOf(AppLocalizations l10n) =>
      l10n.nearMeTimedOutBody;
  static String get timedOutBody => timedOutBodyOf(_en);

  static String declinedBodyOf(AppLocalizations l10n) =>
      l10n.nearMeDeclinedBody;
  static String get declinedBody => declinedBodyOf(_en);

  static String useLocationOf(AppLocalizations l10n) => l10n.nearMeUseLocation;
  static String get useLocation => useLocationOf(_en);

  static String chooseStateOf(AppLocalizations l10n) => l10n.chooseState;
  static String get chooseState => chooseStateOf(_en);

  static String chooseCityOf(AppLocalizations l10n) => l10n.chooseCity;
  static String get chooseCity => chooseCityOf(_en);

  static String chooseDistrictOf(AppLocalizations l10n) => l10n.chooseDistrict;
  static String get chooseDistrict => chooseDistrictOf(_en);

  static String anyCityOf(AppLocalizations l10n) => l10n.anyCity;
  static String get anyCity => anyCityOf(_en);

  static String anyDistrictOf(AppLocalizations l10n) => l10n.anyDistrict;
  static String get anyDistrict => anyDistrictOf(_en);

  static String noMapPointsOf(AppLocalizations l10n) => l10n.nearMeNoMapPoints;
  static String get noMapPoints => noMapPointsOf(_en);

  static String noAnchorMatchOf(AppLocalizations l10n) =>
      l10n.nearMeNoAnchorMatch;
  static String get noAnchorMatch => noAnchorMatchOf(_en);

  static String kilometresOf(AppLocalizations l10n) => l10n.nearMeKilometres;
  static String get kilometres => kilometresOf(_en);

  static String sortedFrom(String place, [AppLocalizations? l10n]) =>
      (l10n ?? _en).nearMeSortedFrom(place);

  /// Short distance for a row. Under 10 km keeps one decimal.
  static String distanceLabel(double kilometres, [AppLocalizations? l10n]) {
    if (!kilometres.isFinite || kilometres < 0) return '';
    final number = kilometres < 10
        ? kilometres.toStringAsFixed(1)
        : kilometres.round().toString();
    return '$number ${(l10n ?? _en).nearMeKilometres}';
  }
}
