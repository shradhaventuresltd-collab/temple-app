/// User-facing copy for Places near me.
///
/// Every string a person can read for this feature lives here so wording
/// can be reviewed on its own.
abstract final class NearMeCopy {
  static const title = 'Places near me';
  static const rationaleTitle = 'Sort by distance';
  static const rationaleBody =
      'Used once on your phone to sort places by distance. Never stored or sent.';
  static const continueLabel = 'Continue';
  static const notNow = 'Not now';
  static const locating = 'Finding places near you…';
  static const nearestHeading = 'Nearest places';
  static const lastKnownNote = 'Using last known location';
  static const deniedBody =
      'Location is off for this app. Pick a state or city and the list is sorted from there.';
  static const deniedForeverBody =
      'Location stays off until you allow approximate location in settings. You can still pick a state or city.';
  static const openSettings = 'Open settings';
  static const enableLocation = 'Enable location';
  static const serviceOffBody =
      'Location is turned off on this phone. Turn it on and try again, or pick a state or city.';
  static const retry = 'Try again';
  static const openLocationSettings = 'Open location settings';
  static const timedOutBody =
      'Could not read a location in time. Try again, or pick a state or city.';
  static const declinedBody = 'Pick a state or city to sort the list.';
  static const useLocation = 'Use approximate location';
  static const chooseState = 'Choose a state';
  static const chooseCity = 'Choose a city';
  static const chooseDistrict = 'Choose a district';
  static const anyCity = 'Any city';
  static const anyDistrict = 'Any district';
  static const noMapPoints = 'None of these listings have a map point.';
  static const noAnchorMatch =
      'None of the listings in that area have a map point.';

  /// Empty list after a tradition chip is applied, not a missing map point.
  static String noTraditionMatch(String label) =>
      'No $label places in that area.';
  static const kilometres = 'km';

  static String sortedFrom(String place) => 'Sorted from $place';

  /// Short distance for a row. Under 10 km keeps one decimal.
  static String distanceLabel(double kilometres) {
    if (!kilometres.isFinite || kilometres < 0) return '';
    final number = kilometres < 10
        ? kilometres.toStringAsFixed(1)
        : kilometres.round().toString();
    return '$number ${NearMeCopy.kilometres}';
  }
}
