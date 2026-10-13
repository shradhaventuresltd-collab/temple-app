// AdMob unit ids and the Android application id.
//
// kDemoBuild (`--dart-define=DEMO_BUILD=true`) forces Google's official test
// units even in release mode (KAN-89). Debug and profile builds already use
// test units because they are not release. The Android application id
// switches to Google's test app id in android/app/build.gradle.kts when that
// same define is visible to Gradle. Keep those two strings in sync with
// [kGoogleTestAppId] and [kProductionAndroidAppId].
//
// iOS keeps the production GADApplicationIdentifier in ios/Runner/Info.plist.
// Unit ids on iOS still follow [bannerAdUnitIdFor] and
// [interstitialAdUnitIdFor].

const String kGoogleTestAppId = 'ca-app-pub-3940256099942544~3347511713';
const String kProductionAndroidAppId = 'ca-app-pub-7782159535499045~4640625144';

const String kGoogleTestBannerAndroid =
    'ca-app-pub-3940256099942544/6300978111';
const String kGoogleTestBannerIos = 'ca-app-pub-3940256099942544/2934735716';
const String kGoogleTestInterstitialAndroid =
    'ca-app-pub-3940256099942544/1033173712';
const String kGoogleTestInterstitialIos =
    'ca-app-pub-3940256099942544/4411468910';

const String kProductionBannerAndroid =
    'ca-app-pub-7782159535499045/8504682685';
const String kProductionBannerIos = 'ca-app-pub-7782159535499045/9654826832';
const String kProductionInterstitialAndroid =
    'ca-app-pub-7782159535499045/8118383886';
const String kProductionInterstitialIos =
    'ca-app-pub-7782159535499045/1552975530';

/// Android `com.google.android.gms.ads.APPLICATION_ID`.
String admobApplicationIdFor({required bool demoBuild}) =>
    demoBuild ? kGoogleTestAppId : kProductionAndroidAppId;

/// Banner unit. [demoBuild] wins over [releaseMode].
String bannerAdUnitIdFor({
  required bool releaseMode,
  required bool demoBuild,
  required bool android,
}) {
  if (demoBuild || !releaseMode) {
    return android ? kGoogleTestBannerAndroid : kGoogleTestBannerIos;
  }
  return android ? kProductionBannerAndroid : kProductionBannerIos;
}

/// Interstitial unit. [demoBuild] wins over [releaseMode].
String interstitialAdUnitIdFor({
  required bool releaseMode,
  required bool demoBuild,
  required bool android,
}) {
  if (demoBuild || !releaseMode) {
    return android
        ? kGoogleTestInterstitialAndroid
        : kGoogleTestInterstitialIos;
  }
  return android ? kProductionInterstitialAndroid : kProductionInterstitialIos;
}
