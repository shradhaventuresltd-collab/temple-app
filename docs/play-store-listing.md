# Play Store listing (draft)

**Draft for Sanu/Deployer to paste into Play Console.** This file is not a store submission. It does not add screenshots or AdMob ID changes.

App name and Android package already match the release identity:

| Field | Value |
| --- | --- |
| App name | Temple Directory India |
| Package name | `com.shradhaventures.temple` |
| Bundled directory | 180 temples, 15 states |

Confirm the live `version` in `pubspec.yaml` before upload. Do not commit keystores or `android/key.properties`.

## Short description

80 characters (Play’s limit). Paste as a single line:

```
Directory of famous temples across India, with history, timings, and directions.
```

## Full description

Paste the block below. It describes the current app: public browse of the bundled sample temples (or newer Firestore records when the cloud has them), on-device search, and AdMob on Android.

```
Temple Directory India is a guide to famous temples across India. Browse temples in 15 states, read their history and legends, check opening timings, and open directions in Google Maps. Verified photographs appear when on file; otherwise the app shows Photo pending instead of stock art.

Find a temple by name, city, state, deity, or address. Filter the list by state and deity, then open a page with the story, specialities, timings, and any verified photos on file.

States in this directory: Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh.

The app also includes a long-form heritage essay on Indian temple architecture and pilgrimage.

Visitors do not need an account to browse. When a connection is available, the directory can show temple records stored in the cloud. A bundled copy stays on the device so browsing still works offline.

The Android app shows ads: a banner on the temple list, and a full-screen ad on every third temple you open.

Temples near me can sort the list by distance. Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention. You can pick a state or city instead.

Timings, photos, and other facts are a starting point for planning a visit. Confirm details with the temple before you travel.
```

## Category

Suggested primary category: **Travel & Local** (pilgrimage planning, place details, and maps directions).

Alternate: **Books & Reference** (directory facts and the heritage essay).

Tags, if Console asks: temples, pilgrimage, India, heritage, travel.

## Content rating notes

Answer the IARC questionnaire from the release app, not from the debug admin tools. Expected shape, for Sanu to confirm in Console:

- Audience: general. No sexual content, graphic violence, gambling, or drugs.
- The app is religious and cultural reference material (temple history, mythology, and worship timings).
- No chat, no public user posts, and no social graph. Visitors cannot create an account in the release app. The admin CMS (including sign-in) and seed tools are debug-only; release/profile builds do not present that UI.
- No unrestricted web browser. Directions open Google Maps for a temple’s published coordinates. Terms and Privacy open two fixed hosted https pages in an in-app browser.
- Approximate location: Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention. Precise location and background location are not requested. See [`docs/play-data-safety.md`](play-data-safety.md).
- Advertising: **yes**. Google AdMob on Android (banner on the temple list; interstitial every third temple detail), after the Terms and Privacy acceptance gate and a Google UMP consent check. Ads are disabled on web. No ads load before Terms are accepted.
- Digital purchases: none in this repo (no in-app purchases or subscriptions).

Do not submit a rating until the questionnaire matches the build you upload.

## Data safety

Draft bullets for the Data safety form. Sanu should confirm them against Play’s SDK scan of the uploaded App Bundle. This repo does not include Firebase Analytics or Crashlytics.

**Honesty vs the binary (KAN-70 / KAN-66 B1):** the release App Bundle still links `firebase_auth` and `firebase_storage` (Play’s scan will see those SDKs). There is no separate release flavor that strips them. Visitor-facing honesty is **UI + write gating**, not SDK absence:

- **Not collected from visitors:** name, email, password, or user ID. Public browse has no sign-in surface. Firebase Auth email/password and Storage uploads exist only for the **debug-only** Admin CMS (custom claim `admin: true`). Release and profile builds gate the entire Admin screen — including `AdminSignInPanel` — so visitors never see sign-in or upload UI even if a route to Admin is forced.
- **App activity and device IDs (advertising):** Google AdMob on Android, after the on-device Terms and Privacy acceptance gate (KAN-93) and Google’s User Messaging Platform consent check (KAN-69 / KAN-60). Startup does not request a consent-info update until Terms are accepted. After acceptance, Home opens immediately and the consent check runs in the background. When Google requires a form, the app shows it before `MobileAds.initialize`. Ad requests wait until that check resolves. Where UMP says consent is not required, ad requests may be personalized. Where the user completes the form, requests do not force non-personalized ads; the Mobile Ads SDK applies the choices UMP stored. If the user dismisses a required form without consent, the app does not request ads. If UMP fails or times out, the app still runs and any ad request is non-personalized. When ads are requested, Google may receive the advertising ID and ad interactions under Google’s policies. The manifest declares `com.google.android.gms.permission.AD_ID` for that case. Debug and profile builds use Google’s test ad units; release uses the AdMob units already in the project. This draft does not change those IDs. iOS App Tracking Transparency is not part of this Android listing.
- **Directory content, not a user profile:** Cloud Firestore holds temple records (name, state, city, deity, story, description, timings, address, coordinates, image URLs). Visitors read that published content. They do not write it.
- **Photos:** Firebase Storage holds temple images uploaded by admins (debug CMS). Visitors download them. The release app does not ask visitors to pick or upload photos, even though the Storage SDK is present in the binary.
- **Location:** Temples near me accesses approximate location. Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention. The manifest adds `ACCESS_COARSE_LOCATION` only; fine and background location are removed if a plugin merges them. Precise location is not accessed. “Directions” opens Google Maps with the temple’s published coordinates and does not send the device reading. Play Console answers for this device reading are in [`docs/play-data-safety.md`](play-data-safety.md). A person updates the form; this draft does not submit it. IP-derived approximate location that Google AdMob may receive is separate and stays under the advertising bullet above.
- **In transit:** Firebase and AdMob traffic uses HTTPS. Answer encryption-in-transit as yes only after confirming the form’s wording against that.
- **Deletion:** there is no visitor account to delete in the release app. Admin accounts are created outside the consumer UI.

When filling Play Console, declare SDKs that the scan reports (including Auth/Storage if listed). Do **not** claim Auth or Storage are absent from the AAB. If the scan reports an SDK this list does not mention, update the form and this draft before publishing.

## Privacy policy

**URL:** https://temple-directory-india.web.app/privacy-policy.html

Enter that URL in Play Console. Terms of Service: https://temple-directory-india.web.app/terms-of-service.html. Deployer publishes both with `firebase deploy --only hosting --project temple-directory-india`.

The page should cover public temple data in Cloud Firestore and Firebase Storage, AdMob on Android (including the UMP consent form where Google requires it, non-personalized ads when UMP fails, and no ad request when a required form is dismissed without consent), the fact that `firebase_auth` / `firebase_storage` may ship in the release binary while visitors are never asked to sign in or upload photos, and Temples near me. Temples near me uses your device's approximate location only on your device, to sort temples by distance. That reading is never stored or sent off your device. Separately, the Google Mobile Ads SDK in this app may collect approximate location derived from your IP address, and share it with Google, for advertising, analytics and fraud prevention. The owner on the page is Sanu Vimal. This file is not the policy.

## Screenshot shot list

Capture these from a release or release-like build on a phone. Do not add image files in this pull request. Play still needs at least two phone screenshots and a 1024×500 feature graphic; confirm the current size rules in Console before export.

- [ ] Home: saffron mosaic and the heritage introduction
- [ ] All Temples grid, with names and places readable
- [ ] Drawer: state or deity filter applied, with the temple count visible
- [ ] Search: a query such as a temple or city name, with matching results
- [ ] Temple detail: photo gallery
- [ ] Temple detail: timings and the directions action
- [ ] Optional: search with no matches
- [ ] Optional: 7-inch and 10-inch tablet frames, if you are filling those slots
- [ ] Feature graphic, 1024×500, using the existing saffron and gopuram artwork (not a new invented screenshot)
- [ ] Hi-res icon: export the existing launcher icon; do not draw a new one for this draft

Check each shot for test-ad labels, debug banners, and the admin or seed controls. Those belong on debug builds only.
