import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/utils/haversine.dart';

void main() {
  test('known Indian city pairs stay within 0.5% of WGS84', () {
    // City-centre pins. Expected kilometres are the WGS84 inverse (Vincenty),
    // computed independently of [haversineKm], so this is not a round trip
    // of the same formula.
    const pairs =
        <
          ({
            String name,
            double lat1,
            double lng1,
            double lat2,
            double lng2,
            double vincentyKm,
          })
        >[
          (
            name: 'Delhi–Mumbai',
            lat1: 28.6139,
            lng1: 77.2090,
            lat2: 19.0760,
            lng2: 72.8777,
            vincentyKm: 1144.527,
          ),
          (
            name: 'Mumbai–Chennai',
            lat1: 19.0760,
            lng1: 72.8777,
            lat2: 13.0827,
            lng2: 80.2707,
            vincentyKm: 1031.869,
          ),
          (
            name: 'Kolkata–Delhi',
            lat1: 22.5726,
            lng1: 88.3639,
            lat2: 28.6139,
            lng2: 77.2090,
            vincentyKm: 1304.227,
          ),
          (
            name: 'Bengaluru–Hyderabad',
            lat1: 12.9716,
            lng1: 77.5946,
            lat2: 17.3850,
            lng2: 78.4867,
            vincentyKm: 497.662,
          ),
          (
            name: 'Jaipur–Ahmedabad',
            lat1: 26.9124,
            lng1: 75.7873,
            lat2: 23.0225,
            lng2: 72.5714,
            vincentyKm: 539.489,
          ),
          (
            name: 'Kochi–Thiruvananthapuram',
            lat1: 9.9312,
            lng1: 76.2673,
            lat2: 8.5241,
            lng2: 76.9366,
            vincentyKm: 172.132,
          ),
        ];

    for (final pair in pairs) {
      final actual = haversineKm(
        fromLat: pair.lat1,
        fromLng: pair.lng1,
        toLat: pair.lat2,
        toLng: pair.lng2,
      );
      final relative = (actual - pair.vincentyKm).abs() / pair.vincentyKm;
      expect(
        relative,
        lessThan(0.005),
        reason: '${pair.name}: $actual km vs ${pair.vincentyKm} km',
      );
    }
  });

  test('distance is symmetric and zero at one point', () {
    const delhiLat = 28.6139;
    const delhiLng = 77.2090;
    const mumbaiLat = 19.0760;
    const mumbaiLng = 72.8777;

    expect(
      haversineKm(
        fromLat: delhiLat,
        fromLng: delhiLng,
        toLat: delhiLat,
        toLng: delhiLng,
      ),
      0,
    );

    final forward = haversineKm(
      fromLat: delhiLat,
      fromLng: delhiLng,
      toLat: mumbaiLat,
      toLng: mumbaiLng,
    );
    final back = haversineKm(
      fromLat: mumbaiLat,
      fromLng: mumbaiLng,
      toLat: delhiLat,
      toLng: delhiLng,
    );
    expect(forward, closeTo(back, 1e-9));
    expect(forward, greaterThan(1000));
  });
}
