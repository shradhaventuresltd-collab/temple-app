import 'package:temple_app/services/store_platform.dart';
import 'package:temple_app/services/update_nudge_store.dart';

/// Play listing for the Android app. The `.demo` suffix is the distribution
/// application id, not a second store listing baked into the release script.
const String kPlayStorePackageName = 'com.shradhaventures.temple';

String playStorePackageName({required bool demoAppIdSuffix}) =>
    demoAppIdSuffix ? '$kPlayStorePackageName.demo' : kPlayStorePackageName;

Uri playStoreMarketUri(String packageName) =>
    Uri.parse('market://details?id=$packageName');

Uri playStoreHttpsUri(String packageName) =>
    Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

/// PLACEHOLDER. Not an Apple ID. No App Store Connect or TestFlight
/// record uses this value.
///
/// Sanu replaces [kAppStoreId] with the numeric App Store id. Until then
/// [appStoreIdIsSet] is false and iOS does not open a store URL.
const String kAppStoreIdPlaceholder = 'APP_STORE_ID';

/// Numeric App Store id, or [kAppStoreIdPlaceholder] while the listing
/// does not exist.
const String kAppStoreId = kAppStoreIdPlaceholder;

bool appStoreIdIsSet(String appStoreId) {
  final value = appStoreId.trim();
  if (value.isEmpty || value == kAppStoreIdPlaceholder) return false;
  return RegExp(r'^\d+$').hasMatch(value);
}

Uri appStoreItmsUri(String appStoreId) =>
    Uri.parse('itms-apps://apps.apple.com/app/id$appStoreId');

Uri appStoreHttpsUri(String appStoreId) =>
    Uri.parse('https://apps.apple.com/app/id$appStoreId');

/// Update copy is not in an arb catalog. The force-update screen, the
/// soft nudge, and Home show these strings.
String storeListingName(StorePlatform platform) =>
    platform == StorePlatform.ios ? 'App Store' : 'Play Store';

String forceUpdateBody(StorePlatform platform) =>
    'This version of Temple Directory India is no longer supported. '
    'Install the latest version from the ${storeListingName(platform)} to continue.';

String forceUpdateButtonLabel(StorePlatform platform) =>
    'Update on ${storeListingName(platform)}';

String forceUpdateOpenFailed(StorePlatform platform) =>
    'Could not open the ${storeListingName(platform)}.';

String softUpdateMessage(StorePlatform platform) =>
    'A newer version is ready on the ${storeListingName(platform)}.';

/// Android: `market://` then the https Play URL.
///
/// iOS: `itms-apps://` then the https App Store URL. An unset
/// [appStoreId] returns false and does not open Play.
Future<bool> openStoreListing({
  required StorePlatform platform,
  required String packageName,
  required Future<bool> Function(Uri url) launch,
  String appStoreId = kAppStoreId,
}) async {
  if (platform == StorePlatform.ios) {
    if (!appStoreIdIsSet(appStoreId)) return false;
    try {
      if (await launch(appStoreItmsUri(appStoreId))) return true;
    } catch (_) {}
    try {
      return await launch(appStoreHttpsUri(appStoreId));
    } catch (_) {
      return false;
    }
  }
  try {
    if (await launch(playStoreMarketUri(packageName))) return true;
  } catch (_) {}
  try {
    return await launch(playStoreHttpsUri(packageName));
  } catch (_) {
    return false;
  }
}

/// What this install should do about [minSupportedBuild] and [recommendedBuild].
///
/// A null [buildNumber] fails open: defaults are 1, and a missing package
/// info read must not block the directory.
enum UpdateRequirement { none, soft, hard }

UpdateRequirement updateRequirement({
  required int? buildNumber,
  required int minSupportedBuild,
  required int recommendedBuild,
}) {
  if (buildNumber == null) return UpdateRequirement.none;
  if (buildNumber < minSupportedBuild) return UpdateRequirement.hard;
  if (buildNumber < recommendedBuild) return UpdateRequirement.soft;
  return UpdateRequirement.none;
}

/// UTC day key for the soft nudge. One show per calendar day.
String updateNudgeDay(DateTime now) {
  final utc = now.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$day';
}

/// Decides whether the soft nudge may appear.
///
/// At most once in this object (the session) and at most once per UTC day
/// in [store]. The day is written when the nudge is claimed, so leaving it
/// on screen still counts.
class SoftUpdateNudge {
  bool shownThisSession = false;

  Future<bool> claim(UpdateNudgeStore store, DateTime now) async {
    if (shownThisSession) return false;
    final today = updateNudgeDay(now);
    final last = await store.readShownDay();
    if (last == today) return false;
    shownThisSession = true;
    await store.writeShownDay(today);
    return true;
  }
}
