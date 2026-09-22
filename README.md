# 🛕 Temple Directory India

A beautifully crafted Flutter application that serves as a comprehensive directory of famous temples across India. The app showcases 150 bundled sample temples from Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh with rich details including history, legends, timings, photo galleries, GPS directions, and an in-depth heritage write-up on India's sacred architectural legacy.

## Why We Built This

India's temple heritage is one of the richest in the world — thousands of sacred sites spanning millennia of history, architecture, and devotion. Yet there's no single, well-designed mobile resource that brings together the essential information a pilgrim or traveler needs: location, timings, stories, specialities, and directions — all in one place.

**Temple Directory India** was created by [Shradha Ventures](https://github.com/shradhaventuresltd-collab) to solve this. Our goals are:

- **Preserve and share heritage** — Detailed write-ups on temple history, mythology, and architectural significance so this knowledge reaches a wider audience.
- **Help pilgrims and tourists** — One-tap Google Maps directions, opening timings, and photo galleries so visitors can plan their trips with ease.
- **Celebrate Dravidian and South Indian architecture** — Showcasing the gopurams, vimanas, and mandapams that make these temples world-class cultural monuments.
- **Build a living directory** — An admin panel (debug builds, admin Auth) lets content managers add, edit, and remove temples, upload images, and keep information current via Firebase.

## Features

### For Users
- **Mosaic Home Screen** — A visually striking collage of temple images with an overlay introducing the directory.
- **Heritage Write-Up** — A comprehensive, 10,000+ word exploration of India's temple heritage embedded directly in the app.
- **Temple List & Filtering** — Browse all temples in a grid view. Filter by state (Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, Himachal Pradesh) and deity (Shiva, Vishnu, Devi, Murugan, Ganesha, Surya, Hanuman, Swaminarayan, Gorakhnath, plus labels such as Sai Baba, Vitthal, Khandoba, Brahma, Jain Tirthankaras, Buddha, Kapil Muni, and specific forms used on individual temples) via the navigation drawer.
- **Search** — Type in the temple list, or in the drawer, to match name, city, state, deity, or address. Search combines with the state and deity filters. See [Search](#search).
- **Temple Detail Screen** — Full-screen image gallery with auto-advance and swipe, pinch-to-zoom, temple story, description, specialities (as chips), timings, and one-tap Google Maps directions.
- **Navigation Drawer** — Shared across all screens with text search, state/deity filters, temple counts, and quick navigation.

### For Admins (Debug Mode + Auth)
- **Admin CMS** — Debug builds only. After admin sign-in, create, edit, and delete temple documents in Firestore using the same fields the app already reads.
- **Image Upload** — Pick and upload multiple images per temple to Firebase Storage with progress tracking. The file picker is **web-oriented** (native `<input type="file">`); field CRUD still works in mobile debug.
- **Seed Data** — Debug-only **Seed** control (Home + Admin) writes the 150 bundled sample temples. It is shown only for a signed-in admin. Re-running is idempotent (stable document IDs). Hidden in release/profile builds.

### Technical
- **Firebase Backend** — Cloud Firestore for temple data, Firebase Storage for images, Firebase Auth for admin writes.
- **Public browse, admin writes** — Unauthenticated clients can **read** temples (and temple images). Create/update/delete and Storage uploads require a signed-in user with custom claim `admin: true`.
- **Offline Fallback** — If Firestore is unreachable, the app falls back to bundled sample data so it always works.
- **Google AdMob** — Banner ads on the temple list screen and interstitial ads every 3rd temple detail view. Uses Google's official test ad units in debug/profile builds to avoid policy violations during development.
- **Platform-Aware Ads** — Ads are fully disabled on web; the app runs cleanly on Chrome/web with no ads and no crashes.
- **Custom App Icon & Splash** — A temple gopuram silhouette on saffron background, generated for all platform sizes (Android adaptive, iOS, web).
- **Material 3 Theming** — Saffron and gold color palette with Google Fonts (Poppins + Lora).

### Search

Public directory search runs on the device against temples already loaded for browse (Firestore, or the 150 bundled sample temples if Firestore is empty or unreachable). It does not call a search service or add a Firestore index.

- **Where:** open **All Temples** and type in the search field above the grid, or type in the drawer **Search** field and tap **View matches** (keyboard search does the same). State and deity chips still apply. **Browse** opens that filtered set with the query filled in, and the list narrows it further.
- **Match:** the query is trimmed and compared without case sensitivity. Extra spaces are collapsed. Every word must appear in the temple’s name, city, state, deity, or address (`location`, stored as Firestore `address`). `meena` matches Meenakshi; `shiva gujarat` matches a Gujarat Shiva temple. Story and description are not searched.
- **Empty query:** clearing the field restores that list — all temples from **All Temples**, or the state/deity subset from **Browse**.
- **No matches:** the list shows `No temples match "…"`, with a clear action.
- **Typing:** the field updates immediately. The grid refreshes after 300ms so each keystroke does not rebuild the temple images.

Admin, Seed, and Auth are unchanged.

## Screenshots

The app uses a warm saffron (`#FF8F00`) and gold (`#FFD54F`) color palette with a cream (`#FFFBF2`) background, featuring a gopuram-inspired app icon.

## Project Structure

```
lib/
├── main.dart                          # App entry point, Firebase & AdMob init
├── firebase_options.dart              # FlutterFire CLI generated config
├── models/
│   └── temple.dart                    # Temple data model
├── data/
│   ├── sample_data.dart               # 150 bundled sample temples (offline fallback; research-backed copy)
│   └── heritage_content.dart          # Heritage write-up content sections
├── services/
│   ├── temple_service.dart            # Firestore temple reads with fallback
│   ├── seed_service.dart              # Debug seed to Firestore (admin Auth required)
│   ├── admin_auth.dart                # Firebase Auth session + admin custom claim
│   ├── admin_temple_service.dart      # Debug Admin CMS create/update/delete
│   ├── temple_form_validation.dart    # Admin form field validation
│   ├── ad_helper.dart                 # AdMob unit IDs (test vs release, per platform)
│   └── interstitial_ad_manager.dart   # Interstitial ad lifecycle management
├── screens/
│   ├── home_screen.dart               # Mosaic collage + heritage write-up
│   ├── temple_detail_screen.dart      # Full temple detail with gallery
│   ├── admin_screen.dart              # Debug admin panel (sign-in + CMS + uploads)
│   └── admin_temple_form_screen.dart  # Create/edit temple form
├── widgets/
│   ├── app_drawer.dart                # Navigation drawer + TempleListScreen + grid cards
│   ├── banner_ad_widget.dart          # Self-contained banner ad widget
│   ├── seed_temples_control.dart      # Debug-only Seed control (idle/running/success/failure)
│   ├── admin_auth_gate.dart           # Debug admin sign-in / not-admin states
│   ├── debug_home_admin_actions.dart  # Home app-bar Seed vs Admin sign-in
│   └── temple_image_placeholder.dart  # Placeholder for missing images
└── utils/
    ├── temple_search.dart              # Client-side directory search (name, city, state, deity, address)
    ├── image_picker_helper.dart       # Platform-aware image picker
    ├── image_picker_web.dart          # Web image picker implementation
    ├── image_picker_stub.dart         # Stub for non-web platforms
    └── picked_file_data.dart          # Cross-platform picked file model
docs/
├── tamil-nadu-sample-research.md      # TN sample sources, caveats, Commons photo candidates
├── kerala-sample-research.md          # Kerala sample sources, caveats, Commons photo candidates
├── karnataka-sample-research.md       # Karnataka sample sources, caveats, Commons photo candidates
├── andhra-pradesh-sample-research.md  # AP expansion sources, caveats, Commons photo candidates
├── telangana-sample-research.md       # Telangana expansion sources, caveats, Commons photo candidates
├── gujarat-sample-research.md         # Gujarat expansion sources, caveats, Commons photo candidates
├── odisha-sample-research.md          # Odisha expansion sources, caveats, Commons photo candidates
├── uttar-pradesh-sample-research.md   # UP expansion sources, caveats, Commons photo candidates
├── jammu-kashmir-sample-research.md   # Jammu and Kashmir expansion sources, caveats, Commons photo candidates
├── maharashtra-sample-research.md     # Maharashtra expansion sources, caveats, Commons photo candidates
├── rajasthan-sample-research.md       # Rajasthan expansion sources, caveats, Commons photo candidates
├── west-bengal-sample-research.md     # West Bengal expansion sources, caveats, Commons photo candidates
├── madhya-pradesh-sample-research.md  # Madhya Pradesh expansion sources, caveats, Commons photo candidates
├── bihar-sample-research.md           # Bihar expansion sources, caveats, Commons photo candidates
├── himachal-pradesh-sample-research.md # Himachal Pradesh expansion sources, caveats, Commons photo candidates
└── android-play-internal-test.md      # Android application id, upload key, Firebase package follow-up
```

## Prerequisites

- **Flutter SDK** `^3.11.5` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (bundled with Flutter)
- **Firebase project** — A Firebase project with Firestore, Storage, and **Authentication** (Email/Password) enabled
- **AdMob account** (optional) — Only needed for production ads; test ads work out of the box in debug builds

## Setup

### 1. Clone the Repository

```bash
git clone git@github.com:shradhaventuresltd-collab/temple-app.git
cd temple-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

The app comes pre-configured with our Firebase project. If you want to use your own:

1. Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure your project:
   ```bash
   flutterfire configure
   ```
   This regenerates `lib/firebase_options.dart` with your project's credentials.

3. Enable **Cloud Firestore**, **Firebase Storage**, and **Authentication** in your Firebase Console.

4. Deploy the checked-in security rules (do **not** use open write rules):

   ```bash
   firebase deploy --only firestore:rules,storage
   ```

   Rules live in `firestore.rules` and `storage.rules`, wired from `firebase.json`. Default project id is `temple-directory-india` (see `.firebaserc`).

   **What they allow**
   - **Read:** anyone may read `temples/{id}` documents and files under `temples/{docId}/` in Storage (public directory).
   - **Write:** create/update/delete of temple documents and Storage uploads/deletes require a signed-in user whose ID token has custom claim **`admin: true`**.
   - Everything else is denied.

   There is no `allow write: if true`. Production clients cannot seed or upload without admin Auth.

### 4. Create a debug admin and seed data

Production / release browsing does **not** require signing in. Seed and Admin writes are **debug + Auth**.

**Admin** means Firebase Auth custom claim `admin: true` (not a Firestore document the client could edit). Grant it with the Admin SDK — clients cannot set this claim.

1. In Firebase Console → **Authentication**, enable **Email/Password** and create a user (or use an existing one). Do not commit passwords.
2. Download a service-account JSON (Project settings → Service accounts → Generate new private key). Save it as `service-account.json` at the repo root or in `scripts/`. This file is gitignored.
3. Grant the claim:

   ```bash
   cd scripts
   npm install
   node grant_admin.js --email you@example.com
   ```

   To remove it later: `node grant_admin.js --email you@example.com --revoke`.
4. Run a **debug** build (`flutter run` or `flutter run -d chrome`).
5. Tap **Admin sign-in** (Home app bar) or the Admin Panel icon. Sign in with that email/password.
   - If you granted the claim while already signed in, tap **Refresh admin status** (or sign out and back in) so the ID token picks it up.
   - Signed-in without the claim shows **Signed in, but not an admin** — Seed, CMS, and Upload stay hidden.
6. After you are recognized as admin, tap **Seed** on Home or **Seed sample temples** on Admin’s empty state. Watch idle → Seeding → success or a short error (not a silent no-op). Or tap **Create a temple** to add one document without seeding.
7. Admin uses a live Firestore snapshot, so the temple list appears as soon as a seed/create/edit/delete succeeds — no hot restart. Home reloads when you leave Admin (and after a successful seed from Home).

**Idempotency:** each seeded temple is stored under a slug of its name (e.g. `meenakshi-amman-temple`). Re-running Seed merges into those same documents instead of creating duplicates. Existing admin-uploaded `images` and original `createdAt` values are preserved. CMS **Create** uses the same slug rule and refuses a name that would collide.

Release and profile builds hide Seed/Admin; `seedTempleData` and Admin CMS writes also refuse to run outside debug, and rules reject non-admin writes even if a client tried.

The home screen **falls back** to the 150 bundled sample temples if Firestore is empty or unreachable, so browse can look populated while the cloud `temples` collection is still empty. Admin reads Firestore only — it stays empty until an admin seeds or creates a temple.

The 10 Tamil Nadu, 10 Kerala, and 10 Karnataka sample temples carry research-enriched story, timings (with source caveats), specialities, address, and map pins. Expansion batches add 10 temples each for Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh, with the same field mapping (`location` stored as `address`) and the same honesty caveats kept in `timings` / `story`. Cover `imageUrl` values are picsum placeholders (existing seeds left as-is; new rows use `https://picsum.photos/seed/{slug}/800/600`). Gallery `images` stay empty until a real Storage upload. Sources and Commons photo candidates live in [`docs/tamil-nadu-sample-research.md`](docs/tamil-nadu-sample-research.md), [`docs/kerala-sample-research.md`](docs/kerala-sample-research.md), [`docs/karnataka-sample-research.md`](docs/karnataka-sample-research.md), [`docs/andhra-pradesh-sample-research.md`](docs/andhra-pradesh-sample-research.md), [`docs/telangana-sample-research.md`](docs/telangana-sample-research.md), [`docs/gujarat-sample-research.md`](docs/gujarat-sample-research.md), [`docs/odisha-sample-research.md`](docs/odisha-sample-research.md), [`docs/uttar-pradesh-sample-research.md`](docs/uttar-pradesh-sample-research.md), [`docs/jammu-kashmir-sample-research.md`](docs/jammu-kashmir-sample-research.md), [`docs/maharashtra-sample-research.md`](docs/maharashtra-sample-research.md), [`docs/rajasthan-sample-research.md`](docs/rajasthan-sample-research.md), [`docs/west-bengal-sample-research.md`](docs/west-bengal-sample-research.md), [`docs/madhya-pradesh-sample-research.md`](docs/madhya-pradesh-sample-research.md), [`docs/bihar-sample-research.md`](docs/bihar-sample-research.md), and [`docs/himachal-pradesh-sample-research.md`](docs/himachal-pradesh-sample-research.md) — they are not Firestore fields. Re-seeding from a debug admin client refreshes bundled text on the stable slug IDs; this repo does not ship a live Firebase seed from CI.

### Admin CMS vs Seed

**Seed** is a one-shot debug action: it writes the 150 bundled sample temples with stable slug IDs. Use it to populate Firestore quickly. It does not provide a per-field editor.

**Admin CMS** is the Admin panel form + list: a signed-in admin can create, edit, and delete individual `temples/{id}` documents. Fields match what the app already stores and reads — `name`, `state`, `city`, `deity`, `description`, `story`, `imageUrl`, `address` (the model’s location), `timings`, `specialities`, `images`, `latitude`, `longitude`. There is no separate admin schema.

**Delete** removes the Firestore document. Uploaded files under `temples/{docId}/` in Storage are deleted first; if that cleanup fails, the document is left in place so you can retry. Seeded cover photos that live on external hosts (for example picsum URLs) are not Storage objects and are left as-is.

Image **file** picking is implemented for **web** only (`lib/utils/image_picker_web.dart`). On iOS/Android/desktop debug, you can still create/edit/delete temple fields and paste image URLs; choosing local image files is not implemented.

This CMS is not public user accounts, directory search, AdMob configuration, or store listing hygiene. Browse search is covered under [Search](#search).

### 5. AdMob Configuration

The app is pre-configured with AdMob IDs. In **debug/profile** builds, it automatically uses Google's official test ad unit IDs, so no changes are needed for development.

For **production**, the real ad unit IDs are already set in `lib/services/ad_helper.dart`. The platform app IDs are configured in:
- **Android:** `android/app/src/main/AndroidManifest.xml` (meta-data `com.google.android.gms.ads.APPLICATION_ID`)
- **iOS:** `ios/Runner/Info.plist` (key `GADApplicationIdentifier`)

### 6. Run the App

```bash
# On a connected Android/iOS device or emulator
flutter run

# On Chrome (web) — ads are disabled on web
flutter run -d chrome

# On macOS desktop
flutter run -d macos
```

### 7. Regenerate Icons & Splash (if you change artwork)

Replace the source images in `assets/icon/` and `assets/splash/`, then run:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ (Dart) |
| UI | Material 3, Google Fonts (Poppins, Lora) |
| Backend | Firebase (Auth, Cloud Firestore, Firebase Storage) |
| Ads | Google AdMob (Banner + Interstitial) |
| Images | CachedNetworkImage for efficient loading |
| Navigation | URL Launcher for Google Maps directions |
| Icons | flutter_launcher_icons |
| Splash | flutter_native_splash |

## Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires Xcode and Apple Developer account)
flutter build ios --release

# Web
flutter build web --release
```

Application id is `com.shradhaventures.temple` and the Android launcher label is **Temple Directory India**. Release signing and the Play upload key are documented in [`docs/android-play-internal-test.md`](docs/android-play-internal-test.md). `android/key.properties`, `*.jks`, and `*.keystore` stay out of git. Debug builds do not need that file. A release build with missing or incomplete signing properties fails with an actionable error and is not signed with the debug keystore.

`android/app/google-services.json` is the Firebase-generated config for project `temple-directory-india`. It includes the previous `com.example.temple_app` client and the new `com.shradhaventures.temple` app (`1:109314154382:android:d34e6caea62c14124ccedf`). The Android section of `lib/firebase_options.dart` uses that new app id. Other platforms are unchanged.

Draft Play Console listing copy is in [`docs/play-store-listing.md`](docs/play-store-listing.md).

## Ad Unit IDs Reference

| Platform | Ad Type | Unit ID |
|----------|---------|---------|
| Android | Banner | `ca-app-pub-7782159535499045/8504682685` |
| Android | Interstitial | `ca-app-pub-7782159535499045/8118383886` |
| iOS | Banner | `ca-app-pub-7782159535499045/9654826832` |
| iOS | Interstitial | `ca-app-pub-7782159535499045/1552975530` |

> **Note:** In debug/profile builds, Google's official test ad unit IDs are used automatically.

## Contributing

This project is maintained by Shradha Ventures. For contributions, please open a pull request or file an issue on the repository.

## License

This project is proprietary software owned by Shradha Ventures Ltd. All rights reserved.
