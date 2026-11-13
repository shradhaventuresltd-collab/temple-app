/// Copy for approximate-pin notices.
///
/// Main does not yet ship generated l10n (the i18n work is on a separate
/// branch). These constants are the l10n keys and the English strings so
/// a later arb pass can replace the lookups without renaming.
abstract final class PinPrecisionStrings {
  /// l10n key: [approximateLocation]
  static const approximateLocation = 'Approximate location';

  /// l10n key: [approximateDistanceKm]
  ///
  /// [number] is the already-formatted distance (for example `3.2` or `12`).
  static String approximateDistanceKm(String number) => '~$number km';
}
