# Play Console Data safety — approximate location (KAN-184)

**Note for a person to enter in Play Console.** This file is not a submission. Confirm it against Play’s SDK scan of the uploaded App Bundle before publishing. Do not commit keystores or other secrets.

Owner on the privacy policy remains **Sanu Vimal**. Policy **updated 23 October 2026**.

## Approximate location (Temples near me)

For the Play Console form, approximate location is accessed, not collected and not shared.

Answer the form for the device reading as follows:

- **Accessed:** yes. Temples near me reads approximate location on the device to sort temples by distance.
- **Collected:** no.
- **Shared:** no.

Wording per KAN-184, for the form and the policy: approximate location is used on the device only and is not collected or shared.

Precise location is not accessed. Background location is not accessed. The only location permission the app keeps is `android.permission.ACCESS_COARSE_LOCATION`. The app manifest removes `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, and `FOREGROUND_SERVICE_LOCATION` if a plugin merges them, and it strips the geolocator location foreground-service type. The fix is not written to disk, logs, Firestore, or an ad request.

## Do not fold the device reading into ad location

Google AdMob may still derive approximate location from the IP address when ads are requested. That is separate from the Temples near me reading. It is already described in the privacy policy (section 4) and in the advertising bullet of [`play-store-listing.md`](play-store-listing.md). Do not mark the on-device fix as collected or shared with AdMob, the User Messaging Platform, Analytics, or Crashlytics.

## SDK check (23 October 2026)

Reviewed in this repo, not by running an ad request on a device:

- App code does not pass coordinates into `AdRequest`, UMP `ConsentRequestParameters`, Analytics, or Crashlytics. `AdRequest` is built with no location fields (`nonPersonalizedAds` only on the fail-soft path, otherwise an empty request). Release consent parameters are an empty `ConsentRequestParameters()`.
- `pubspec.yaml` and `pubspec.lock` do not depend on `firebase_analytics` or `firebase_crashlytics`. Those SDKs are not in the app, so they receive no location.
- `google_mobile_ads` 5.3.1 pulls `com.google.android.gms:play-services-ads:23.6.0` and `com.google.android.ump:user-messaging-platform:3.1.0`. Those library manifests declare no location permission. UMP classes do not reference location APIs. The ads SDK does not call `LocationManager` or `FusedLocationProviderClient`. `geolocator_android` 5.2.1 declares no coarse, fine, or background permission; it does declare a location foreground service, which the app manifest strips.
- Residual, for the person filling the form: in `play-services-ads` 23.6.0, the ad WebView’s `onGeolocationPermissionsShowPrompt` grants HTML5 geolocation when `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` is already granted to the app, and denies it otherwise. The app does not pass the Temples near me fix into that WebView. This note does not check that box.
- [ ] Before filling in the Play Data safety form, check this note against Play's SDK scan or Play Console's SDK data declarations for AdMob and UMP.

`test/near_me_privacy_test.dart` checks the manifest rules and that ad, consent, analytics, and crashlytics code is not given the device fix.
