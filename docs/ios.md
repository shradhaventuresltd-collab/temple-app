# iOS runner

This is the same Flutter app as the Android build. `ios/` is the iPhone runner. There is no second app, no new Firebase app, and no App Store Connect or TestFlight setup in this change.

## Ready

- `ios/Podfile` sets `platform :ios, '15.0'`, the same deployment target as `ios/Runner.xcodeproj/project.pbxproj` and the Podfile `post_install` hook. Locked plugin podspecs are iOS 12 or 13. Flutter 3.47's Flutter pod is 15.0, and that SDK rewrites a 13 or 14 project up to 15.0 before CocoaPods runs.
- The Runner bundle id is `com.shradhaventures.temple` (RunnerTests is `com.shradhaventures.temple.RunnerTests`).
- Update prompts open the App Store on iOS and the Play Store on Android. The Apple id is still the placeholder `APP_STORE_ID`. While that placeholder is unset, iOS does not open a link and does not fall through to Play.
- Remote Config on iOS reads `min_supported_build_ios` and `recommended_build_ios`. Those keys default to 1 when unset. A raised Android `min_supported_build` does not block iOS.
- Debug uses Google's public iOS test AdMob app id `ca-app-pub-3940256099942544~1458002511` via `GAD_APP_ID` in `ios/Flutter/Debug.xcconfig`. `Info.plist` reads `$(GAD_APP_ID)`. Release (and Profile, which includes `Release.xcconfig`) keeps `ca-app-pub-7782159535499045~2293663404`. There is no iOS demo xcconfig. Debug ad units already resolve to Google's iOS test units. Swift Package Manager is off in `pubspec.yaml` because `google_mobile_ads` is still a CocoaPod and depends on the `webview_flutter_wkwebview` pod.
- `SKAdNetworkItems` is Google's published AdMob list from [Privacy strategies](https://developers.google.com/admob/ios/privacy/strategies).
- There is no ATT prompt and no `NSUserTrackingUsageDescription`. Every iOS `AdRequest` sets `nonPersonalizedAds: true`. Android consent behaviour is unchanged.
- `LSApplicationQueriesSchemes` includes `itms-apps` and `itms`.

## Build without a Mac

[`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml) is `workflow_dispatch` only. It does not run on push, pull request, or a schedule. macOS minutes bill at 10x; do not dispatch without Sanu's OK. The job times out after 30 minutes. It checks out the repo, installs Flutter 3.47.7, prints `flutter doctor -v`, `xcodebuild -version`, and `pod --version`, runs `flutter pub get` and `pod repo update`, installs pods through `flutter build ios --config-only --no-codesign`, then runs `flutter build ios --no-codesign --debug`. The simulator build still runs when that device build fails. A failure uploads `ios/Podfile.lock` and the build logs. `pod repo update` does not fix a missing Flutter plugin pod; `webview_flutter_wkwebview` is not on the CocoaPods trunk.

Ubuntu CI (`analyze-test`) now includes `ios/**` in its path filters. That job stays on `ubuntu-latest` and does not build the iOS app.

## Known Firebase mismatch

`PRODUCT_BUNDLE_IDENTIFIER` is `com.shradhaventures.temple`. `BUNDLE_ID` in `ios/Runner/GoogleService-Info.plist` and `iosBundleId` on the iOS `FirebaseOptions` in `lib/firebase_options.dart` are still `com.example.templeApp`. Those two Firebase files move together later. They were not edited here. Firebase may log a bundle-id mismatch warning until the iOS app is re-registered. `macos/` is unchanged.

## Still needs Sanu

- Apple Developer Program ($99/year), signing certificates, and a provisioning profile. No `DEVELOPMENT_TEAM` is committed.
- App Store Connect, when a listing should exist. This change does not create that app or a TestFlight build. Replace `APP_STORE_ID` in `lib/services/app_update.dart` with the numeric Apple id after the listing exists.
- Where to store the new `GoogleService-Info.plist` after the Firebase iOS app is re-registered for `com.shradhaventures.temple`, then update `lib/firebase_options.dart` in the same change.
- Confirm the production AdMob iOS app id `ca-app-pub-7782159535499045~2293663404` is the one that should ship.
- Privacy nutrition labels, and `ITSAppUsesNonExemptEncryption`, before an App Store submission.
- ATT stays off. iOS ads stay non-personalized unless that decision is explicitly changed.
