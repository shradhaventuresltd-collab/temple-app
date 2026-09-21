# 🛕 Temple Directory India

A beautifully crafted Flutter application that serves as a comprehensive directory of famous temples across South India. The app showcases 30+ temples from Tamil Nadu, Kerala, and Karnataka with rich details including history, legends, timings, photo galleries, GPS directions, and an in-depth heritage write-up on India's sacred architectural legacy.

## Why We Built This

India's temple heritage is one of the richest in the world — thousands of sacred sites spanning millennia of history, architecture, and devotion. Yet there's no single, well-designed mobile resource that brings together the essential information a pilgrim or traveler needs: location, timings, stories, specialities, and directions — all in one place.

**Temple Directory India** was created by [Shradha Ventures](https://github.com/shradhaventuresltd-collab) to solve this. Our goals are:

- **Preserve and share heritage** — Detailed write-ups on temple history, mythology, and architectural significance so this knowledge reaches a wider audience.
- **Help pilgrims and tourists** — One-tap Google Maps directions, opening timings, and photo galleries so visitors can plan their trips with ease.
- **Celebrate Dravidian and South Indian architecture** — Showcasing the gopurams, vimanas, and mandapams that make these temples world-class cultural monuments.
- **Build a living directory** — An admin panel allows content managers to add temples, upload images, and keep information current via Firebase.

## Features

### For Users
- **Mosaic Home Screen** — A visually striking collage of temple images with an overlay introducing the directory.
- **Heritage Write-Up** — A comprehensive, 10,000+ word exploration of India's temple heritage embedded directly in the app.
- **Temple List & Filtering** — Browse all temples in a grid view. Filter by state (Tamil Nadu, Kerala, Karnataka) and deity (Shiva, Vishnu, Devi, Murugan) via the navigation drawer.
- **Temple Detail Screen** — Full-screen image gallery with auto-advance and swipe, pinch-to-zoom, temple story, description, specialities (as chips), timings, and one-tap Google Maps directions.
- **Navigation Drawer** — Shared across all screens with state/deity filters, temple counts, and quick navigation.

### For Admins (Debug Mode + Auth)
- **Admin Panel** — Debug builds only. Sign in with a Firebase Auth admin account to manage temple images in Cloud Firestore / Storage.
- **Image Upload** — After admin sign-in, pick and upload multiple images per temple to Firebase Storage with progress tracking.
- **Seed Data** — Debug-only **Seed** control (Home + Admin) writes the 30 bundled sample temples. It is shown only for a signed-in admin. Re-running is idempotent (stable document IDs). Hidden in release/profile builds.

### Technical
- **Firebase Backend** — Cloud Firestore for temple data, Firebase Storage for images, Firebase Auth for admin writes.
- **Public browse, admin writes** — Unauthenticated clients can **read** temples (and temple images). Create/update/delete and Storage uploads require a signed-in user with custom claim `admin: true`.
- **Offline Fallback** — If Firestore is unreachable, the app falls back to bundled sample data so it always works.
- **Google AdMob** — Banner ads on the temple list screen and interstitial ads every 3rd temple detail view. Uses Google's official test ad units in debug/profile builds to avoid policy violations during development.
- **Platform-Aware Ads** — Ads are fully disabled on web; the app runs cleanly on Chrome/web with no ads and no crashes.
- **Custom App Icon & Splash** — A temple gopuram silhouette on saffron background, generated for all platform sizes (Android adaptive, iOS, web).
- **Material 3 Theming** — Saffron and gold color palette with Google Fonts (Poppins + Lora).

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
│   ├── sample_data.dart               # 30 bundled sample temples (offline fallback)
│   └── heritage_content.dart          # Heritage write-up content sections
├── services/
│   ├── temple_service.dart            # Firestore temple reads with fallback
│   ├── seed_service.dart              # Debug seed to Firestore (admin Auth required)
│   ├── admin_auth.dart                # Firebase Auth session + admin custom claim
│   ├── ad_helper.dart                 # AdMob unit IDs (test vs release, per platform)
│   └── interstitial_ad_manager.dart   # Interstitial ad lifecycle management
├── screens/
│   ├── home_screen.dart               # Mosaic collage + heritage write-up
│   ├── temple_detail_screen.dart      # Full temple detail with gallery
│   └── admin_screen.dart              # Debug admin panel (sign-in + uploads)
├── widgets/
│   ├── app_drawer.dart                # Navigation drawer + TempleListScreen + grid cards
│   ├── banner_ad_widget.dart          # Self-contained banner ad widget
│   ├── seed_temples_control.dart      # Debug-only Seed control (idle/running/success/failure)
│   ├── admin_auth_gate.dart           # Debug admin sign-in / not-admin states
│   ├── debug_home_admin_actions.dart  # Home app-bar Seed vs Admin sign-in
│   └── temple_image_placeholder.dart  # Placeholder for missing images
└── utils/
    ├── image_picker_helper.dart       # Platform-aware image picker
    ├── image_picker_web.dart          # Web image picker implementation
    ├── image_picker_stub.dart         # Stub for non-web platforms
    └── picked_file_data.dart          # Cross-platform picked file model
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
   - Signed-in without the claim shows **Signed in, but not an admin** — Seed/Upload stay hidden.
6. After you are recognized as admin, tap **Seed** on Home or **Seed sample temples** on Admin’s empty state. Watch idle → Seeding → success or a short error (not a silent no-op).
7. Admin uses a live Firestore snapshot, so the temple list appears as soon as the write succeeds — no hot restart. Home reloads after a successful seed from that screen.

**Idempotency:** each temple is stored under a slug of its name (e.g. `meenakshi-amman-temple`). Re-running Seed merges into those same documents instead of creating duplicates. Existing admin-uploaded `images` and original `createdAt` values are preserved.

Release and profile builds hide Seed/Admin; `seedTempleData` also refuses to run outside debug, and rules reject non-admin writes even if a client tried.

The home screen **falls back** to the 30 bundled sample temples if Firestore is empty or unreachable, so browse can look populated while the cloud `temples` collection is still empty. Admin reads Firestore only — it stays empty until an admin seeds.

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
