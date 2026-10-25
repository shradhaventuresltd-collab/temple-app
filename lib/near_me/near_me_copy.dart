/// User-facing copy for Temples near me.
///
/// Every string a person can read for this feature lives here so wording
/// can be reviewed on its own.
abstract final class NearMeCopy {
  static const title = 'Temples near me';
  static const rationaleTitle = 'Sort by distance';
  static const rationaleBody =
      'Used once on your phone to sort temples by distance. Never stored or sent.';
  static const continueLabel = 'Continue';
  static const notNow = 'Not now';
  static const locating = 'Finding temples near you…';
  static const nearestHeading = 'Nearest temples';
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
      'None of the temples in that place have a map point.';
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
