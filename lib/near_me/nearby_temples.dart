import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/haversine.dart';

/// District name for one loaded index entry.
///
/// Shards have no district field. [indexDistrictName] returns null until a
/// later change can supply one without an extra read. [centroidFor] and
/// [nearbyDistricts] already honour a lookup that returns names.
typedef TempleDistrictLookup = String? Function(Temple temple);

/// Default district hook. The index does not carry a district.
String? indexDistrictName(Temple temple) => null;

/// One temple and its distance from the anchor, in kilometres.
class NearbyTemple {
  const NearbyTemple({required this.temple, required this.distanceKm});

  final Temple temple;
  final double distanceKm;
}

/// Mean of the index coordinates for the temples in this place.
class PlaceCentroid {
  const PlaceCentroid({
    required this.latitude,
    required this.longitude,
    required this.templeCount,
  });

  final double latitude;
  final double longitude;
  final int templeCount;
}

/// States on the loaded list, sorted. Empty names are skipped.
List<String> nearbyStates(Iterable<Temple> temples) {
  final states = <String>{
    for (final temple in temples)
      if (temple.state.trim().isNotEmpty) temple.state.trim(),
  };
  return states.toList()..sort();
}

/// Cities on the loaded list for [state], sorted.
List<String> nearbyCities(Iterable<Temple> temples, {required String state}) {
  final cities = <String>{
    for (final temple in temples)
      if (temple.state.trim() == state && temple.city.trim().isNotEmpty)
        temple.city.trim(),
  };
  return cities.toList()..sort();
}

/// District names from [districtOf]. Empty until a lookup returns any.
List<String> nearbyDistricts(
  Iterable<Temple> temples, {
  String? state,
  TempleDistrictLookup districtOf = indexDistrictName,
}) {
  final names = <String>{};
  for (final temple in temples) {
    if (state != null && state.isNotEmpty && temple.state.trim() != state) {
      continue;
    }
    final name = districtOf(temple)?.trim() ?? '';
    if (name.isEmpty) continue;
    names.add(name);
  }
  return names.toList()..sort();
}

/// Label for the place the list is sorted from. Null when nothing is chosen.
String? nearMePlaceLabel({String? state, String? city, String? district}) {
  final parts = <String>[
    if (city != null && city.trim().isNotEmpty) city.trim(),
    if (district != null && district.trim().isNotEmpty) district.trim(),
    if (state != null && state.trim().isNotEmpty) state.trim(),
  ];
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

/// Arithmetic mean of `lat`/`lng` for temples that match the place and have
/// coordinates. Null when none do. A district filter matches nothing while
/// [districtOf] is [indexDistrictName].
PlaceCentroid? centroidFor(
  Iterable<Temple> temples, {
  String? state,
  String? city,
  String? district,
  TempleDistrictLookup districtOf = indexDistrictName,
}) {
  var latitude = 0.0;
  var longitude = 0.0;
  var count = 0;
  for (final temple in temples) {
    if (!_inPlace(
      temple,
      state: state,
      city: city,
      district: district,
      districtOf: districtOf,
    )) {
      continue;
    }
    if (!temple.hasCoordinates) continue;
    latitude += temple.latitude!;
    longitude += temple.longitude!;
    count += 1;
  }
  if (count == 0) return null;
  return PlaceCentroid(
    latitude: latitude / count,
    longitude: longitude / count,
    templeCount: count,
  );
}

/// Haversine distance from [latitude]/[longitude] to every index entry that
/// has coordinates, nearest first. Entries without a map point are omitted.
/// Ties break by name, then id.
List<NearbyTemple> sortTemplesByDistance(
  Iterable<Temple> temples, {
  required double latitude,
  required double longitude,
}) {
  if (!latitude.isFinite || !longitude.isFinite) {
    throw ArgumentError('Origin must be a finite latitude and longitude.');
  }
  final rows = <NearbyTemple>[];
  for (final temple in temples) {
    if (!temple.hasCoordinates) continue;
    rows.add(
      NearbyTemple(
        temple: temple,
        distanceKm: haversineKm(
          fromLat: latitude,
          fromLng: longitude,
          toLat: temple.latitude!,
          toLng: temple.longitude!,
        ),
      ),
    );
  }
  rows.sort((a, b) {
    final byDistance = a.distanceKm.compareTo(b.distanceKm);
    if (byDistance != 0) return byDistance;
    final byName = a.temple.name.compareTo(b.temple.name);
    if (byName != 0) return byName;
    return a.temple.id.compareTo(b.temple.id);
  });
  return rows;
}

bool _blank(String? value) => value == null || value.trim().isEmpty;

bool _inPlace(
  Temple temple, {
  required String? state,
  required String? city,
  required String? district,
  required TempleDistrictLookup districtOf,
}) {
  if (!_blank(state) && temple.state.trim() != state!.trim()) return false;
  if (!_blank(city) && temple.city.trim() != city!.trim()) return false;
  if (!_blank(district)) {
    final name = districtOf(temple)?.trim() ?? '';
    if (name != district!.trim()) return false;
  }
  return true;
}
