import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/district/district_attribution.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/models/temple_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DistrictIndex index;
  late Map<String, dynamic> manifest;
  late Map<String, dynamic> report;
  late List<dynamic> assignments;

  setUpAll(() async {
    final data = await rootBundle.load(kDistrictBoundaryAsset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    index = DistrictIndex.decode(bytes);
    manifest =
        jsonDecode(File('assets/districts/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    report =
        jsonDecode(
              File(
                'test/fixtures/district_accuracy_report.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final full =
        jsonDecode(
              File(
                'test/fixtures/district_full_assignments.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    assignments = full['temples'] as List<dynamic>;
    expect(sha256.convert(bytes).toString(), manifest['sha256']);
  });

  test('the manifest records the licence and the asset version', () {
    expect(manifest['assetVersion'], kDistrictBoundaryAssetVersion);
    expect(manifest['attribution'], kDistrictBoundaryAttribution);
    expect(manifest['licence'], kDistrictBoundaryLicence);
    expect(manifest['source'], kDistrictBoundarySourceName);
    expect(manifest['allowsBundling'], isTrue);
    expect(manifest['districts'], index.length);
    expect(manifest['bytes'], greaterThan(0));
    expect(manifest['gzipBytes'], lessThan(600 * 1024));
    expect(kTempleIndexEntryVersion, 1);
  });

  test('enclaves, a border vertex, and a sea point resolve', () {
    final probes = {
      for (final probe in report['probes'] as List<dynamic>)
        (probe as Map<String, dynamic>)['label']: probe,
    };

    void expectProbe(String label) {
      final probe = probes[label] as Map<String, dynamic>;
      final located = index.locate(
        (probe['latitude'] as num).toDouble(),
        (probe['longitude'] as num).toDouble(),
      );
      expect(located.hit.name, probe['name'], reason: label);
      expect(located.hit.stateName, probe['state'], reason: label);
      expect(located.hit.lgdCode, probe['lgd'], reason: label);
      expect(located.insidePolygon, probe['inside'], reason: label);
    }

    expectProbe('karaikal');
    expectProbe('mahe-gap');
    expectProbe('mahe-interior');
    expectProbe('yanam');
    expectProbe('meenakshi');
    expectProbe('sea');

    final vertex = index.boundaryVertex('Madurai');
    expect(vertex, isNotNull);
    final onBorder = index.locate(vertex!.latitude, vertex.longitude);
    expect(onBorder.insidePolygon, isTrue);
    expect(onBorder.hit.name, 'Madurai');
  });

  test('simplified districts stay within 2% of the full-resolution hits', () {
    expect(assignments, hasLength(sampleTemples.length));
    final byName = <String, Map<String, dynamic>>{};
    for (final row in assignments) {
      final temple = row as Map<String, dynamic>;
      byName[temple['name'] as String] = temple;
    }

    final mismatches = <String>[];
    final stateMismatches = <String>[];
    final perState = <String, Map<String, int>>{};
    var unresolved = 0;
    for (final temple in sampleTemples) {
      final bucket = perState.putIfAbsent(temple.state, () {
        return {'temples': 0, 'resolved': 0, 'stateMismatches': 0};
      });
      bucket['temples'] = bucket['temples']! + 1;
      if (!temple.hasCoordinates) {
        unresolved += 1;
        continue;
      }
      bucket['resolved'] = bucket['resolved']! + 1;
      final row = byName[temple.name];
      expect(row, isNotNull, reason: temple.name);
      expect((row!['latitude'] as num).toDouble(), temple.latitude);
      expect((row['longitude'] as num).toDouble(), temple.longitude);
      final hits = [
        for (final hit in row['hits'] as List<dynamic>)
          hit as Map<String, dynamic>,
      ];
      final located = index.locate(temple.latitude!, temple.longitude!);
      final inSet = hits.any(
        (hit) =>
            hit['lgd'] == located.hit.lgdCode &&
            hit['name'] == located.hit.name,
      );
      if (!inSet) mismatches.add(temple.name);
      if (!sameDistrictState(temple.state, located.hit.stateName)) {
        stateMismatches.add(temple.name);
        bucket['stateMismatches'] = bucket['stateMismatches']! + 1;
      }
    }

    final listed = [
      for (final row in report['simplificationMismatches'] as List<dynamic>)
        (row as Map<String, dynamic>)['name'],
    ];
    expect(mismatches, listed);
    expect(unresolved, report['unresolved']);
    expect(stateMismatches, [
      for (final row in report['stateMismatches'] as List<dynamic>)
        (row as Map<String, dynamic>)['name'],
    ]);
    expect(mismatches.length / sampleTemples.length, lessThanOrEqualTo(0.02));
    final expectedStates = report['perState'] as Map<String, dynamic>;
    expect(perState.keys.toSet(), expectedStates.keys.toSet());
    for (final entry in perState.entries) {
      final expected = expectedStates[entry.key] as Map<String, dynamic>;
      expect(entry.value['temples'], expected['temples'], reason: entry.key);
      expect(entry.value['resolved'], expected['resolved'], reason: entry.key);
      expect(
        entry.value['stateMismatches'],
        expected['stateMismatches'],
        reason: entry.key,
      );
    }
  });
}
