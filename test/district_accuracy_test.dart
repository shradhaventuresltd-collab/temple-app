import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/district/district_attribution.dart';
import 'package:temple_app/district/district_boundary.dart';

void main() {
  test('the Bharatlas district file is bundled under CC-BY-4.0', () {
    expect(kDistrictBoundariesBundled, isTrue);
    final file = File('assets/districts/india_districts.dsb');
    expect(file.existsSync(), isTrue);
    final bytes = file.lengthSync();
    expect(bytes, lessThan(600 * 1024));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/districts/india_districts.dsb'));

    final manifest =
        jsonDecode(File('assets/districts/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['bundled'], isTrue);
    expect(manifest['allowsBundling'], isTrue);
    expect(manifest['licence'], 'CC-BY-4.0');
    expect(manifest['licence'], isNot('CC0-1.0'));
    expect(manifest['licence'], isNot('CC0-1.0 / CC-BY-4.0'));
    expect(manifest['licence'], isNot('unconfirmed'));
    expect(manifest['bytes'], bytes);
    expect(manifest['assetVersion'], kDistrictBoundaryAssetVersion);
    expect(manifest['datasetVersion'], kDistrictBoundaryDatasetVersion);
    expect(manifest['sourceUpdated'], kDistrictBoundarySourceUpdated);
    expect(manifest['fetchedOn'], kDistrictBoundaryFetchedOn);
    expect(manifest['attribution'], kDistrictBoundaryAttribution);
    expect(
      manifest['sourceUrl'],
      'https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson',
    );
    expect(manifest['sourcePage'], kDistrictBoundarySourcePage);
    expect(manifest['licenceUrl'], kDistrictBoundaryLicenceUrl);
    expect(manifest['toleranceMetres'], 500);
    expect(kDistrictBoundaryAttribution, contains('simplified'));
    expect(kDistrictBoundaryAttribution, isNot(contains('Not bundled')));
    expect(
      kDistrictBoundaryLicenseEntry,
      contains(kDistrictBoundarySourcePage),
    );
    expect(
      kDistrictBoundaryLicenseEntry,
      contains(kDistrictBoundaryLicenceUrl),
    );
    expect(kDistrictBoundaryLicenseEntry, contains('simplified'));
    expect(kDistrictBoundaryLicenseEntry, isNot(contains('Not bundled')));

    final license = File('assets/districts/LICENSE').readAsStringSync();
    expect(license, contains('CC BY 4.0'));
    expect(license, contains('CC0-1.0'));
    expect(license, contains('CC-BY-4.0'));
    expect(
      license,
      contains(
        'Publisher: yashveeeeeeer/india-geodata (https://github.com/yashveeeeeeer/india-geodata).',
      ),
    );
    expect(
      kDistrictBoundaryLicenseEntry,
      contains(kDistrictBoundaryOriginalData),
    );
    expect(kDistrictBoundaryAttribution, endsWith('simplified for this app.'));
    final readme = File('assets/districts/README.md').readAsStringSync();
    expect(readme.toLowerCase(), contains('simplif'));
    expect(readme, contains('500'));

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      expect(text.contains('Not bundled'), isFalse, reason: entity.path);
    }

    final index = DistrictIndex.decode(file.readAsBytesSync());
    final meenakshi = index.locateInStoredState(9.9195, 78.1193, 'Tamil Nadu');
    expect(meenakshi?.name, 'Madurai');
    expect(meenakshi?.stateName, 'Tamil Nadu');

    final report =
        jsonDecode(
              File(
                'test/fixtures/district_accuracy_report.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(report['crossState'], 0);
    expect((report['simplified'] as Map)['cross'], 0);
    expect((report['full'] as Map)['cross'], 0);
    expect(report['toleranceMetres'], 500);
    expect(report['bytes'], bytes);
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
