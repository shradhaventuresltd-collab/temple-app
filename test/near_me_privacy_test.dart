import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/near_me/near_me_copy.dart';

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
