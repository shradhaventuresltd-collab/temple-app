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

/// `market://` first. Https is the fallback when the store app cannot open.
Future<bool> openPlayStoreListing({
  required String packageName,
  required Future<bool> Function(Uri url) launch,
}) async {
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
