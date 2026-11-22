import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/temple_share.dart';

/// The WhatsApp switch and the manifest move together: with the direct path
/// on, Android 11+ only reports WhatsApp installed when the manifest
/// declares the `whatsapp` scheme (and the packages) in `<queries>`.
/// Neither variant may add a `<uses-permission>`.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final queries =
      RegExp(r'<queries>([\s\S]*?)</queries>').firstMatch(manifest)?.group(1) ??
      '';

  bool declares(String needle) => queries.contains(needle);

  test('WhatsApp <queries> entries match kShareDirectToWhatsApp', () {
    expect(declares('android:scheme="whatsapp"'), kShareDirectToWhatsApp);
    expect(declares('android:name="com.whatsapp"'), kShareDirectToWhatsApp);
    expect(declares('android:name="com.whatsapp.w4b"'), kShareDirectToWhatsApp);
  });

  test('sharing adds no permission', () {
    final permissions = RegExp(
      r'<uses-permission[^>]*android:name="([^"]+)"',
    ).allMatches(manifest).map((m) => m.group(1)).toSet();
    expect(
      permissions.where(
        (p) =>
            p!.toLowerCase().contains('whatsapp') ||
            p.contains('QUERY_ALL_PACKAGES') ||
            p.contains('SEND'),
      ),
      isEmpty,
    );
    expect(permissions, {
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'com.google.android.gms.permission.AD_ID',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_BACKGROUND_LOCATION',
      'android.permission.FOREGROUND_SERVICE_LOCATION',
    });
  });

  test('the Maps https query stays', () {
    expect(declares('android:scheme="https"'), isTrue);
  });
}
