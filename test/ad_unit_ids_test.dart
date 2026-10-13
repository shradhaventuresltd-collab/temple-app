import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/ad_unit_ids.dart';

void main() {
  group('DEMO_BUILD forces Google test units', () {
    test('release + DEMO_BUILD uses Android test banner and interstitial', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: true, android: true),
        kGoogleTestBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: true,
          android: true,
        ),
        kGoogleTestInterstitialAndroid,
      );
    });

    test('release + DEMO_BUILD uses iOS test units', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: true, android: false),
        kGoogleTestBannerIos,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: true,
          android: false,
        ),
        kGoogleTestInterstitialIos,
      );
    });

    test('release without DEMO_BUILD keeps production units', () {
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: false, android: true),
        kProductionBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: false,
          android: true,
        ),
        kProductionInterstitialAndroid,
      );
      expect(
        bannerAdUnitIdFor(releaseMode: true, demoBuild: false, android: false),
        kProductionBannerIos,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: true,
          demoBuild: false,
          android: false,
        ),
        kProductionInterstitialIos,
      );
    });

    test('debug and profile stay on test units without the define', () {
      expect(
        bannerAdUnitIdFor(releaseMode: false, demoBuild: false, android: true),
        kGoogleTestBannerAndroid,
      );
      expect(
        interstitialAdUnitIdFor(
          releaseMode: false,
          demoBuild: false,
          android: true,
        ),
        kGoogleTestInterstitialAndroid,
      );
    });
  });

  group('AdMob application id', () {
    test('DEMO_BUILD selects the Google test app id', () {
      expect(admobApplicationIdFor(demoBuild: true), kGoogleTestAppId);
      expect(admobApplicationIdFor(demoBuild: false), kProductionAndroidAppId);
    });

    test('Android Gradle placeholder uses the same app ids', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains(r'${admobAppId}'));
      expect(gradle, contains(kGoogleTestAppId));
      expect(gradle, contains(kProductionAndroidAppId));
    });
  });
}
