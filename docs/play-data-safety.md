# Play Console Data safety — approximate location (KAN-184)

**Note for a person to enter in Play Console.** This file is not a submission. Confirm it against Play’s SDK scan of the uploaded App Bundle before publishing. Do not commit keystores or other secrets.

Owner on the privacy policy remains **Sanu Vimal**. Policy **updated 24 October 2026**.

## Approximate location (Temples near me)

For the Play Console form, approximate location is accessed, not collected and not shared.

Answer the form for the device reading as follows:

- **Accessed:** yes. Temples near me reads approximate location on the device to sort temples by distance.
- **Collected:** no.
- **Shared:** no.

Wording per KAN-184, for the form and the policy:

Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention.

Precise location is not accessed. Background location is not accessed. The only location permission the app keeps is `android.permission.ACCESS_COARSE_LOCATION`. The app manifest removes `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, and `FOREGROUND_SERVICE_LOCATION` if a plugin merges them, and it strips the geolocator location foreground-service type. The fix is not written to disk, logs, Firestore, or an ad request.

## Firebase Analytics

Firebase Analytics collects app interactions, device or other IDs (app instance ID) and diagnostics. We use this information for analytics. It is not used for ads by us. Firebase Analytics does not collect precise location.

For the Play Console Data safety form:

- **App interactions:** collected. Used for analytics. Not used for advertising by us. Events are screen views, search (trimmed query length and whether the directory had a match; the query text is not sent), filter used (type deity, state, or district, and the deity, state, or district name), temple opened (temple id), get directions (temple id), and temples near me (no parameters).
- **Device or other IDs:** collected. The identifier is the Firebase app instance ID. Used for analytics. Not used for advertising by us. The app does not set a user id. Analytics does not collect the advertising ID or the Android ID (`google_analytics_adid_collection_enabled` and `google_analytics_ssaid_collection_enabled` are false).
- **Diagnostics:** collected. Used for analytics.
- **Precise location:** not collected. Temples near me does not send its reading to Analytics. Events do not include coordinates.

Collection runs in the production Play build only. The Android manifest sets `firebase_analytics_collection_enabled` to false. After Firebase starts, the app calls `setAnalyticsCollectionEnabled(true)` only when the binary is a release build and it is not `DEMO_BUILD`, `DEMO_APP_ID_SUFFIX`, or `ENABLE_ADMIN_TOOLS`. Debug, profile, demo, seed/admin, and unit tests leave collection off. The ad User Messaging Platform pass is unchanged (KAN-69). The app does not include Firebase Crashlytics.

## Do not fold the device reading into ad location

Google AdMob may still derive approximate location from the IP address when ads are requested. That is separate from the Temples near me reading. It is already described in the privacy policy (section 4) and in the advertising bullet of [`play-store-listing.md`](play-store-listing.md). Do not mark the on-device fix as collected or shared with AdMob, the User Messaging Platform, Analytics, or Crashlytics.

## SDK check (23 October 2026)

Reviewed in this repo, not by running an ad request on a device:

- App code does not pass coordinates into `AdRequest`, UMP `ConsentRequestParameters`, Analytics, or Crashlytics. `AdRequest` is built with no location fields (`nonPersonalizedAds` only on the fail-soft path, otherwise an empty request). Release consent parameters are an empty `ConsentRequestParameters()`.
- `pubspec.yaml` depends on `firebase_analytics` (11.x, with Firebase core 3). `firebase_crashlytics` is not a dependency. Analytics is not given the Temples near me reading: the near-me screen does not call the analytics service, and the `temples_near_me` event has no parameters. Search events carry length and a has-results flag, not the query text.
- `google_mobile_ads` 5.3.1 pulls `com.google.android.gms:play-services-ads:23.6.0` and `com.google.android.ump:user-messaging-platform:3.1.0`. Those library manifests declare no location permission. UMP classes do not reference location APIs. The ads SDK does not call `LocationManager` or `FusedLocationProviderClient`. `geolocator_android` 5.2.1 declares no coarse, fine, or background permission; it does declare a location foreground service, which the app manifest strips.
- Residual, for the person filling the form: in `play-services-ads` 23.6.0, the ad WebView’s `onGeolocationPermissionsShowPrompt` grants HTML5 geolocation when `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` is already granted to the app, and denies it otherwise. The app does not pass the Temples near me fix into that WebView. This note does not check that box.
- [ ] Before filling in the Play Data safety form, check this note against Play's SDK scan or Play Console's SDK data declarations for AdMob and UMP.

`test/near_me_privacy_test.dart` checks the manifest rules and that ad, consent, analytics, and crashlytics code is not given the device fix.
