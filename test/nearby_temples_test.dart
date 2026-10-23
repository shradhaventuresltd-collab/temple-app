import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/near_me/nearby_temples.dart';

void main() {
  test('distance sort is nearest first and skips a missing map point', () {
    final temples = [
      _temple(id: 'far', name: 'Far', lat: 28.6, lng: 77.2),
      _temple(id: 'none', name: 'No point'),
      _temple(id: 'near', name: 'Near', lat: 13.08, lng: 80.27),
    ];

    final rows = sortTemplesByDistance(
      temples,
      latitude: 13.1,
      longitude: 80.3,
    );

    expect(rows.map((row) => row.temple.id), ['near', 'far']);
    expect(rows.first.distanceKm, lessThan(rows.last.distanceKm));
    expect(NearMeCopy.distanceLabel(rows.first.distanceKm), endsWith(' km'));
  });

  test('equal distances break ties by name', () {
    final temples = [
      _temple(id: 'b', name: 'Beta', lat: 10, lng: 10),
      _temple(id: 'a', name: 'Alpha', lat: 10, lng: 10),
    ];

    final rows = sortTemplesByDistance(temples, latitude: 10, longitude: 10);

    expect(rows.map((row) => row.temple.name), ['Alpha', 'Beta']);
    expect(rows.first.distanceKm, 0);
  });

  test('state and city centroids use index coordinates only', () {
    final temples = [
      _temple(
        id: 'madurai',
        name: 'Meenakshi',
        state: 'Tamil Nadu',
        city: 'Madurai',
        lat: 9,
        lng: 78,
      ),
      _temple(
        id: 'chennai',
        name: 'Kapaleeshwarar',
        state: 'Tamil Nadu',
        city: 'Chennai',
        lat: 13,
        lng: 80,
      ),
      _temple(
        id: 'somnath',
        name: 'Somnath',
        state: 'Gujarat',
        city: 'Veraval',
        lat: 20,
        lng: 70,
      ),
    ];

    final state = centroidFor(temples, state: 'Tamil Nadu');
    expect(state, isNotNull);
    expect(state!.latitude, 11);
    expect(state.longitude, 79);
    expect(state.templeCount, 2);

    final city = centroidFor(temples, state: 'Tamil Nadu', city: 'Madurai');
    expect(city!.latitude, 9);
    expect(city.longitude, 78);
    expect(city.templeCount, 1);

    final fromCity = sortTemplesByDistance(
      temples,
      latitude: city.latitude,
      longitude: city.longitude,
    );
    expect(fromCity.first.temple.id, 'madurai');
    expect(
      nearMePlaceLabel(state: 'Tamil Nadu', city: 'Madurai'),
      'Madurai, Tamil Nadu',
    );
    expect(nearbyCities(temples, state: 'Tamil Nadu'), ['Chennai', 'Madurai']);
  });

  test('district hook is unused until a lookup returns names', () {
    final temples = [
      _temple(
        id: 'jagannath',
        name: 'Jagannath',
        state: 'Odisha',
        city: 'Puri',
        lat: 19.8,
        lng: 85.8,
      ),
      _temple(
        id: 'lingaraj',
        name: 'Lingaraj',
        state: 'Odisha',
        city: 'Bhubaneswar',
        lat: 20.2,
        lng: 85.8,
      ),
    ];

    expect(indexDistrictName(temples.first), isNull);
    expect(nearbyDistricts(temples), isEmpty);
    expect(centroidFor(temples, district: 'Puri'), isNull);

    String? lookup(Temple temple) {
      return switch (temple.id) {
        'jagannath' => 'Puri',
        'lingaraj' => 'Khordha',
        _ => null,
      };
    }

    expect(nearbyDistricts(temples, districtOf: lookup), ['Khordha', 'Puri']);
    final puri = centroidFor(temples, district: 'Puri', districtOf: lookup);
    expect(puri!.latitude, 19.8);
    expect(puri.longitude, 85.8);
    expect(puri.templeCount, 1);

    final sorted = sortTemplesByDistance(
      temples,
      latitude: puri.latitude,
      longitude: puri.longitude,
    );
    expect(sorted.first.temple.id, 'jagannath');
    expect(sorted.first.distanceKm, 0);
  });

  test('distance label keeps one decimal under 10 km', () {
    expect(NearMeCopy.distanceLabel(0), '0.0 km');
    expect(NearMeCopy.distanceLabel(9.94), '9.9 km');
    expect(NearMeCopy.distanceLabel(12.4), '12 km');
    expect(NearMeCopy.distanceLabel(12.6), '13 km');
  });
}

Temple _temple({
  required String id,
  required String name,
  String state = 'Tamil Nadu',
  String city = 'Madurai',
  double? lat,
  double? lng,
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: city,
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: city,
    timings: null,
    specialities: const [],
    latitude: lat,
    longitude: lng,
  );
}
