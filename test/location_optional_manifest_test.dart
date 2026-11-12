import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location hardware features are optional in the app manifest', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains(
        '<uses-feature android:name="android.hardware.location" android:required="false"/>',
      ),
    );
    expect(
      manifest,
      contains(
        '<uses-feature android:name="android.hardware.location.network" android:required="false"/>',
      ),
    );

    // ACCESS_FINE_LOCATION is removed, so GPS is not implied and is not
    // declared as a uses-feature.
    expect(
      manifest.contains(
        '<uses-feature android:name="android.hardware.location.gps"',
      ),
      isFalse,
    );
    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(manifest, contains('tools:node="remove"'));
  });
}
