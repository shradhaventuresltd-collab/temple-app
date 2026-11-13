import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/l10n/display_labels.dart';

/// User-facing copy for Places near me.
///
/// Getters without a bundle return English so existing tests keep their
/// matchers. Widgets pass the resolved [AppLocalizations].
abstract final class NearMeCopy {
  static AppLocalizations _copy(AppLocalizations? l10n) =>
      l10n ?? L10nLookup.english;

  static String titleOf(AppLocalizations? l10n) => _copy(l10n).nearMeTitle;
  static String get title => titleOf(null);

  static String rationaleTitleOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeRationaleTitle;
  static String get rationaleTitle => rationaleTitleOf(null);

  static String rationaleBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeRationaleBody;
  static String get rationaleBody => rationaleBodyOf(null);

  static String continueLabelOf(AppLocalizations? l10n) =>
      _copy(l10n).commonContinueButton;
  static String get continueLabel => continueLabelOf(null);

  static String notNowOf(AppLocalizations? l10n) =>
      _copy(l10n).commonNotNowButton;
  static String get notNow => notNowOf(null);

  static String locatingOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeLocatingMessage;
  static String get locating => locatingOf(null);

  static String nearestHeadingOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeNearestHeading;
  static String get nearestHeading => nearestHeadingOf(null);

  static String lastKnownNoteOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeLastKnownNote;
  static String get lastKnownNote => lastKnownNoteOf(null);

  static String deniedBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeDeniedBody;
  static String get deniedBody => deniedBodyOf(null);

  static String deniedForeverBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeDeniedForeverBody;
  static String get deniedForeverBody => deniedForeverBodyOf(null);

  static String openSettingsOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeOpenSettingsButton;
  static String get openSettings => openSettingsOf(null);

  static String enableLocationOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeEnableLocationButton;
  static String get enableLocation => enableLocationOf(null);

  static String serviceOffBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeServiceOffBody;
  static String get serviceOffBody => serviceOffBodyOf(null);

  static String retryOf(AppLocalizations? l10n) =>
      _copy(l10n).commonTryAgainButton;
  static String get retry => retryOf(null);

  static String openLocationSettingsOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeOpenLocationSettingsButton;
  static String get openLocationSettings => openLocationSettingsOf(null);

  static String timedOutBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeTimedOutBody;
  static String get timedOutBody => timedOutBodyOf(null);

  static String declinedBodyOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeDeclinedBody;
  static String get declinedBody => declinedBodyOf(null);

  static String useLocationOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeUseLocationButton;
  static String get useLocation => useLocationOf(null);

  static String chooseStateOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeChooseStateLabel;
  static String get chooseState => chooseStateOf(null);

  static String chooseCityOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeChooseCityLabel;
  static String get chooseCity => chooseCityOf(null);

  static String chooseDistrictOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeChooseDistrictLabel;
  static String get chooseDistrict => chooseDistrictOf(null);

  static String anyCityOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeAnyCityLabel;
  static String get anyCity => anyCityOf(null);

  static String anyDistrictOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeAnyDistrictLabel;
  static String get anyDistrict => anyDistrictOf(null);

  static String noMapPointsOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeNoMapPointsMessage;
  static String get noMapPoints => noMapPointsOf(null);

  static String noAnchorMatchOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeNoAnchorMatchMessage;
  static String get noAnchorMatch => noAnchorMatchOf(null);

  static String kilometresOf(AppLocalizations? l10n) =>
      _copy(l10n).nearMeDistanceLabel('whole', 0, 1).replaceAll('1', '').trim();
  static String get kilometres => 'km';

  /// Empty list after a tradition chip is applied, not a missing map point.
  ///
  /// [label] is the English chip word (`Sikh`) or the stored key (`sikh`).
  static String noTraditionMatch(String label, {AppLocalizations? l10n}) {
    final key = switch (label) {
      'Sikh' || 'sikh' => 'sikh', // l10n-allow: canonical tradition key
      'Jain' || 'jain' => 'jain', // l10n-allow: canonical tradition key
      'Buddhist' || 'buddhist' => 'buddhist', // l10n-allow: canonical tradition key
      'Hindu' || 'hindu' => 'hindu', // l10n-allow: canonical tradition key
      _ => 'other',
    };
    return _copy(l10n).nearMeNoTraditionPlacesMessage(key);
  }

  static String sortedFrom(String place, {AppLocalizations? l10n}) =>
      _copy(l10n).nearMeSortedFromLabel(place);

  /// Short distance for a row. Under 10 km keeps one decimal.
  ///
  /// Marathi and Bengali number formats use native digits. Those are mapped
  /// back to Latin digits before the label is shown.
  static String distanceLabel(
    double kilometres, {
    bool approximate = false,
    AppLocalizations? l10n,
  }) {
    if (!kilometres.isFinite || kilometres < 0) return '';
    final strings = _copy(l10n);
    final String raw;
    if (kilometres < 10) {
      final tenths = (kilometres * 10).round() / 10;
      raw = approximate
          ? strings.nearMeApproximateDistanceLabel('tenth', tenths, 0)
          : strings.nearMeDistanceLabel('tenth', tenths, 0);
    } else {
      final whole = kilometres.round();
      raw = approximate
          ? strings.nearMeApproximateDistanceLabel('whole', 0, whole)
          : strings.nearMeDistanceLabel('whole', 0, whole);
    }
    return latinDigits(raw);
  }
}
