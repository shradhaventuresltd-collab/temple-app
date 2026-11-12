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

    // ACCESS_FINE_LOCATION and tools:node="remove" must be on the same
    // uses-permission element, not merely somewhere in the file.
    final usesPermissions = RegExp(
      r'<uses-permission\b[^>]*/\s*>',
      dotAll: true,
    ).allMatches(manifest).map((match) => match.group(0)!).toList();
    final fineLocation = [
      for (final element in usesPermissions)
        if (element.contains('android.permission.ACCESS_FINE_LOCATION'))
          element,
    ];
    expect(fineLocation, hasLength(1));
    expect(fineLocation.single, contains('tools:node="remove"'));
  });
}
