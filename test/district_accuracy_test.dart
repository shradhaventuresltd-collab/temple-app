import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/district/district_attribution.dart';
import 'package:temple_app/district/district_boundary.dart';

void main() {
  test('the Bharatlas district file is not bundled', () {
    expect(kDistrictBoundariesBundled, isFalse);
    expect(File('assets/districts/india_districts.dsb').existsSync(), isFalse);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('india_districts.dsb'), isFalse);

    final manifest =
        jsonDecode(File('assets/districts/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['bundled'], isFalse);
    expect(manifest['allowsBundling'], isFalse);
    expect(manifest['licence'], 'unconfirmed');
    expect(manifest['assetVersion'], kDistrictBoundaryAssetVersion);
    expect(manifest['datasetVersion'], kDistrictBoundaryDatasetVersion);
    expect(manifest['sourceUpdated'], kDistrictBoundarySourceUpdated);
    expect(manifest['attribution'], kDistrictBoundaryAttribution);
    expect(manifest['licence'], isNot('CC0-1.0 / CC-BY-4.0'));
    expect(manifest['licence'], isNot('CC0-1.0'));
    expect(manifest['licence'], isNot('CC-BY-4.0'));
  });

  test('no widget, painter, or map layer reads the boundary asset', () {
    const allowed = <String>{
      'lib/district/district_boundary.dart',
      'lib/district/district_lookup.dart',
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/');
      final text = entity.readAsStringSync();
      final readsAsset =
          text.contains('india_districts.dsb') ||
          text.contains('kDistrictBoundaryAsset');
      final decodesGeometry = text.contains('DistrictIndex');
      if (!readsAsset && !decodesGeometry) continue;
      if (allowed.contains(rel)) continue;
      offenders.add(rel);
    }
    expect(offenders, isEmpty);
  });
}
