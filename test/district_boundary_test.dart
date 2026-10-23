import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/district/district_boundary.dart';

void main() {
  DistrictHit hit({
    required int lgd,
    required String name,
    String state = 'Tamil Nadu',
  }) {
    return DistrictHit(
      lgdCode: lgd,
      stateLgdCode: 33,
      name: name,
      stateName: state,
    );
  }

  List<List<List<List<double>>>> square(double size) {
    return [
      [
        [
          [0, 0],
          [size, 0],
          [size, size],
          [0, size],
          [0, 0],
        ],
      ],
    ];
  }

  test('a point inside a square is that district', () {
    final index = DistrictIndex.fromGeoRings([
      (hit: hit(lgd: 1, name: 'Box'), polygons: square(1)),
    ]);
    final located = index.locate(0.5, 0.5);
    expect(located.insidePolygon, isTrue);
    expect(located.hit.name, 'Box');
  });

  test('an edge and a vertex count as inside', () {
    final index = DistrictIndex.fromGeoRings([
      (hit: hit(lgd: 1, name: 'Box'), polygons: square(1)),
    ]);
    expect(index.locate(0, 0.5).insidePolygon, isTrue);
    expect(index.locate(0, 0).insidePolygon, isTrue);
  });

  test('a hole is not inside the polygon and still names the district', () {
    final index = DistrictIndex.fromGeoRings([
      (
        hit: hit(lgd: 1, name: 'Ring'),
        polygons: [
          [
            [
              [0, 0],
              [10, 0],
              [10, 10],
              [0, 10],
              [0, 0],
            ],
            [
              [4, 4],
              [6, 4],
              [6, 6],
              [4, 6],
              [4, 4],
            ],
          ],
        ],
      ),
    ]);
    final located = index.locate(5, 5);
    expect(located.insidePolygon, isFalse);
    expect(located.hit.name, 'Ring');
  });

  test('a point outside every polygon is the nearest district', () {
    final index = DistrictIndex.fromGeoRings([
      (hit: hit(lgd: 1, name: 'Near'), polygons: square(1)),
      (
        hit: hit(lgd: 2, name: 'Far'),
        polygons: [
          [
            [
              [10, 10],
              [11, 10],
              [11, 11],
              [10, 11],
              [10, 10],
            ],
          ],
        ],
      ),
    ]);
    final located = index.locate(2, 2);
    expect(located.insidePolygon, isFalse);
    expect(located.hit.name, 'Near');
  });

  test('overlapping polygons keep the smaller district', () {
    final index = DistrictIndex.fromGeoRings([
      (hit: hit(lgd: 2, name: 'Large'), polygons: square(10)),
      (hit: hit(lgd: 9, name: 'Small'), polygons: square(1)),
    ]);
    final located = index.locate(0.5, 0.5);
    expect(located.insidePolygon, isTrue);
    expect(located.hit.name, 'Small');
  });

  test('equal areas break ties by LGD code then name', () {
    final index = DistrictIndex.fromGeoRings([
      (hit: hit(lgd: 4, name: 'Zed'), polygons: square(1)),
      (hit: hit(lgd: 4, name: 'Aye'), polygons: square(1)),
      (hit: hit(lgd: 2, name: 'Low'), polygons: square(1)),
    ]);
    expect(index.locate(0.2, 0.2).hit.name, 'Low');
  });

  test('the cache key is the boundary asset version only', () {
    expect(
      districtAssignmentCacheKey(kDistrictBoundaryAssetVersion),
      'district_lookup:lgd-2024-dsb1-500m',
    );
    expect(
      districtAssignmentCacheKey('other-asset'),
      'district_lookup:other-asset',
    );
  });

  test('state labels fold the same way as the boundary build', () {
    expect(canonicalDistrictState('ANDHRA PRADESH'), 'andhra pradesh');
    expect(sameDistrictState('Puducherry', 'PUDUCHERRY'), isTrue);
    expect(canonicalDistrictState('Orissa'), 'odisha');
    expect(canonicalDistrictState('NCT of Delhi'), 'delhi');
    expect(
      canonicalDistrictState('Andaman and Nicobar Islands'),
      'andaman nicobar',
    );
  });

  test('a computed district never leaves the stored state', () {
    final index = DistrictIndex.fromGeoRings([
      (
        hit: hit(lgd: 1, name: 'Madurai', state: 'Tamil Nadu'),
        polygons: [
          [
            [
              [78.00, 10.00],
              [78.01, 10.00],
              [78.01, 10.01],
              [78.00, 10.01],
              [78.00, 10.00],
            ],
          ],
        ],
      ),
      (
        hit: hit(lgd: 2, name: 'Kollam', state: 'Kerala'),
        polygons: [
          [
            [
              [78.014, 10.004],
              [78.020, 10.004],
              [78.020, 10.010],
              [78.014, 10.010],
              [78.014, 10.004],
            ],
          ],
        ],
      ),
    ]);

    final insideTamil = index.locateInStoredState(10.005, 78.005, 'Tamil Nadu');
    final insideKeralaBox = index.locateInStoredState(10.006, 78.016, 'Tamil Nadu');
    final far = index.locateInStoredState(10.006, 78.05, 'Tamil Nadu');
    final keralaStored = index.locateInStoredState(10.006, 78.016, 'Kerala');

    expect(insideTamil?.name, 'Madurai');
    expect(sameDistrictState('Tamil Nadu', insideTamil!.stateName), isTrue);
    expect(insideKeralaBox?.name, 'Madurai');
    expect(insideKeralaBox!.stateName, isNot('Kerala'));
    expect(far, isNull);
    expect(keralaStored?.name, 'Kollam');
    expect(sameDistrictState('Kerala', keralaStored!.stateName), isTrue);

    for (var lat = 10.0; lat <= 10.08; lat += 0.01) {
      for (var lng = 78.0; lng <= 78.08; lng += 0.01) {
        final computed = index.locateInStoredState(lat, lng, 'Tamil Nadu');
        if (computed == null) continue;
        expect(
          sameDistrictState('Tamil Nadu', computed.stateName),
          isTrue,
          reason: '$lat,$lng -> ${computed.name} ${computed.stateName}',
        );
      }
    }
  });

  test('a short buffer is rejected', () {
    expect(
      () => DistrictIndex.decode(Uint8List.fromList([1, 2, 3, 4])),
      throwsFormatException,
    );
  });
}
