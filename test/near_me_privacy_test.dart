import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/near_me/near_me_copy.dart';

/// Location wording Sanu approved on 24 October 2026. Replaces the KAN-184
/// sentence in the policy, the Data safety note, and the listing location line.
const _approvedLocation =
    "Temples near me uses your device's approximate location only on your device, "
    'to sort temples by distance. That reading is never stored or sent off your '
    'device. Separately, the Google Mobile Ads SDK in this app may collect '
    'approximate location derived from your IP address, and share it with Google, '
    'for advertising, analytics and fraud prevention.';

/// Retired KAN-184 slogan. The policy and Data safety note must not keep it.
const _retiredOnDeviceOnly =
    'approximate location is used on the device only and is not collected or shared';

/// Permissions a plugin must not merge into the app.
const _blockedPermissions = {
  'android.permission.ACCESS_FINE_LOCATION',
  'android.permission.ACCESS_BACKGROUND_LOCATION',
  'android.permission.FOREGROUND_SERVICE_LOCATION',
};

void main() {
  test('near me does not persist, log, or send a fix', () {
    final files = [
      ...Directory('lib/near_me').listSync().whereType<File>(),
      File('lib/screens/temples_near_me_screen.dart'),
      File('lib/utils/haversine.dart'),
    ];
    expect(files, isNotEmpty);

    const forbidden = [
      'cloud_firestore',
      'firebase_analytics',
      'firebase_crashlytics',
      'FirebaseAnalytics',
      'FirebaseCrashlytics',
      'google_mobile_ads',
      'shared_preferences',
      'SharedPreferences',
      'dart:developer',
      'dart:io',
      'debugPrint(',
      'print(',
      'getPositionStream',
      'getLastKnownPosition',
      'ForegroundNotificationConfig',
      'foregroundNotificationConfig',
      'allowBackgroundLocationUpdates: true',
      'LocationAccuracy.high',
      'LocationAccuracy.best',
      'LocationAccuracy.medium',
      'LocationAccuracy.lowest',
      'LocationAccuracy.reduced',
      'ACCESS_FINE_LOCATION',
      'ACCESS_BACKGROUND_LOCATION',
      'CoarseFix?',
      'static CoarseFix',
      'late CoarseFix',
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source.contains(token),
          isFalse,
          reason: '${file.path} contains $token',
        );
      }
    }

    final location = File(
      'lib/near_me/geolocator_coarse_location.dart',
    ).readAsStringSync();
    expect(location, contains('LocationAccuracy.low'));
    expect(location, contains('allowBackgroundLocationUpdates: false'));
    expect(location, isNot(contains('getPositionStream')));

    final geolocatorImport = RegExp(
      r'''import\s+['"]package:geolocator/geolocator\.dart['"]''',
    );
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in libFiles) {
      final source = file.readAsStringSync();
      final importsGeolocator = geolocatorImport.hasMatch(source);
      final allowed = file.path.endsWith('geolocator_coarse_location.dart');
      expect(importsGeolocator, allowed ? isTrue : isFalse, reason: file.path);
    }

    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    expect(home, contains('TemplesNearMeScreen('));
    expect(home, isNot(contains('package:geolocator')));
  });

  test('manifest keeps coarse location and strips fine or background', () {
    final manifests = [
      File('android/app/src/main/AndroidManifest.xml'),
      File('android/app/src/debug/AndroidManifest.xml'),
      File('android/app/src/profile/AndroidManifest.xml'),
    ];
    final parsed = {
      for (final file in manifests)
        file.path: _permissions(file.readAsStringSync()),
    };

    for (final entry in parsed.entries) {
      for (final permission in entry.value) {
        if (_blockedPermissions.contains(permission.name)) {
          expect(
            permission.removed,
            isTrue,
            reason: '${entry.key} grants ${permission.name}',
          );
        }
      }
    }

    final main = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final coarse = parsed['android/app/src/main/AndroidManifest.xml']!.where(
      (permission) =>
          permission.name == 'android.permission.ACCESS_COARSE_LOCATION',
    );
    expect(coarse, hasLength(1));
    expect(coarse.single.removed, isFalse);
    final grantedLocation = parsed['android/app/src/main/AndroidManifest.xml']!
        .where(
          (permission) =>
              permission.name.contains('LOCATION') && !permission.removed,
        )
        .map((permission) => permission.name);
    expect(grantedLocation, ['android.permission.ACCESS_COARSE_LOCATION']);
    for (final path in [
      'android/app/src/debug/AndroidManifest.xml',
      'android/app/src/profile/AndroidManifest.xml',
    ]) {
      final granted = parsed[path]!.where(
        (permission) =>
            permission.name.contains('LOCATION') && !permission.removed,
      );
      expect(granted, isEmpty, reason: path);
    }
    expect(main, contains('tools:remove="android:foregroundServiceType"'));
    expect(main, isNot(contains('android:foregroundServiceType="location"')));

    final pluginManifests = _pluginManifests();
    expect(pluginManifests, isNotEmpty);
    for (final plugin in pluginManifests) {
      final xml = plugin.readAsStringSync();
      for (final permission in _permissions(xml)) {
        if (!_blockedPermissions.contains(permission.name) ||
            permission.removed) {
          continue;
        }
        final removedInApp = parsed['android/app/src/main/AndroidManifest.xml']!
            .any(
              (candidate) =>
                  candidate.name == permission.name && candidate.removed,
            );
        expect(
          removedInApp,
          isTrue,
          reason: '${plugin.path} merges ${permission.name}',
        );
      }
      if (xml.contains('android:foregroundServiceType="location"')) {
        expect(
          main,
          contains('tools:remove="android:foregroundServiceType"'),
          reason: '${plugin.path} merges a location foreground service',
        );
      }
    }
  });

  test('privacy policy and Data safety use the approved location wording', () {
    const pages = ['docs/privacy-policy.html', 'hosting/privacy-policy.html'];
    final docs = File(pages[0]).readAsStringSync();
    final hosted = File(pages[1]).readAsStringSync();
    expect(hosted, docs);
    expect(docs, contains('Sanu Vimal'));
    expect(docs, contains('<strong>Updated:</strong> 24 October 2026'));
    expect(docs, contains('<strong>Effective date:</strong> 23 October 2026'));
    expect(docs, contains(_approvedLocation));
    expect(docs.toLowerCase(), isNot(contains(_retiredOnDeviceOnly)));
    expect(docs, isNot(contains('. (section 6).')));
    expect(
      docs,
      contains(
        'We do not pass the Temples near me reading to Google AdMob',
      ),
    );
    expect(docs, isNot(contains('does not request location permission')));
    expect(docs, contains('<h2>6. Temples near me</h2>'));

    final listing = File('docs/play-store-listing.md').readAsStringSync();
    expect(
      listing,
      contains(
        '**Location:** Temples near me accesses approximate location. $_approvedLocation',
      ),
    );
    expect(listing, isNot(contains('does not request device location')));
    expect(listing.toLowerCase(), isNot(contains(_retiredOnDeviceOnly)));

    final dataSafety = File('docs/play-data-safety.md').readAsStringSync();
    expect(dataSafety, contains(_approvedLocation));
    expect(dataSafety.toLowerCase(), isNot(contains(_retiredOnDeviceOnly)));
    expect(
      dataSafety.toLowerCase(),
      contains('accessed, not collected and not shared'),
    );
    expect(dataSafety, contains('Sanu Vimal'));
    expect(dataSafety, contains('Policy **updated 24 October 2026**.'));
    expect(dataSafety, contains('23 October 2026'));

    expect(PolicyConfig.currentVersion, 2);
    expect(
      NearMeCopy.rationaleBody,
      'Used once on your phone to sort temples by distance. Never stored or sent.',
    );
  });

  test('ads, UMP, analytics, and crashlytics are not given the device fix', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();
    for (final name in ['firebase_analytics', 'firebase_crashlytics']) {
      expect(pubspec, isNot(contains('$name:')));
      expect(lock, isNot(contains('name: $name')));
    }

    const forbidden = [
      'CoarseFix',
      'geolocator',
      'setLocation',
      'LocationAccuracy',
      'ACCESS_COARSE_LOCATION',
      'ACCESS_FINE_LOCATION',
      'ACCESS_BACKGROUND_LOCATION',
      'latitude',
      'longitude',
    ];
    final sdkFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final source = file.readAsStringSync();
          return source.contains('package:google_mobile_ads/') ||
              source.contains('firebase_analytics') ||
              source.contains('firebase_crashlytics') ||
              source.contains('FirebaseAnalytics') ||
              source.contains('FirebaseCrashlytics');
        });
    expect(sdkFiles, isNotEmpty);
    for (final file in sdkFiles) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source.contains(token),
          isFalse,
          reason: '${file.path} contains $token',
        );
      }
    }

    final consent = File('lib/services/ad_consent.dart').readAsStringSync();
    expect(
      consent,
      contains('return const AdRequest(nonPersonalizedAds: true);'),
    );
    expect(consent, contains('return const AdRequest();'));
    expect(consent, contains('return ConsentRequestParameters();'));
    expect(RegExp(r'(?<!\w)AdRequest\(').allMatches(consent), hasLength(2));
  });

  test('iOS asks for when-in-use only, with the same rationale', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<key>NSLocationWhenInUseUsageDescription</key>'));
    expect(plist, contains('<string>${NearMeCopy.rationaleBody}</string>'));
    expect(plist, isNot(contains('NSLocationAlways')));
    expect(plist, isNot(contains('<string>location</string>')));
  });
}

class _ManifestPermission {
  const _ManifestPermission({required this.name, required this.removed});

  final String name;
  final bool removed;
}

List<_ManifestPermission> _permissions(String xml) {
  final tags = RegExp(r'<uses-permission\b([^>]*)/?>');
  final name = RegExp(r'android:name="([^"]+)"');
  final permissions = <_ManifestPermission>[];
  for (final tag in tags.allMatches(xml)) {
    final body = tag.group(1)!;
    final found = name.firstMatch(body);
    if (found == null) continue;
    permissions.add(
      _ManifestPermission(
        name: found.group(1)!,
        removed: body.contains('tools:node="remove"'),
      ),
    );
  }
  return permissions;
}

List<File> _pluginManifests() {
  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final manifests = <File>[];
  for (final package in packages) {
    final rootUri = (package as Map<String, dynamic>)['rootUri'] as String;
    final root = _packageRoot(rootUri);
    if (root == null || !root.existsSync()) continue;
    for (final relative in const [
      'android/src/main/AndroidManifest.xml',
      'android/src/debug/AndroidManifest.xml',
      'android/src/profile/AndroidManifest.xml',
      'android/src/release/AndroidManifest.xml',
    ]) {
      final file = File('${root.path}/$relative');
      if (file.existsSync()) manifests.add(file);
    }
  }
  return manifests;
}

Directory? _packageRoot(String rootUri) {
  final uri = Uri.parse(rootUri);
  if (uri.scheme == 'file') return Directory.fromUri(uri);
  if (uri.scheme.isEmpty) {
    return Directory(Directory.current.uri.resolve(rootUri).toFilePath());
  }
  return null;
}
