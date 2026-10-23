import 'dart:math' as math;

/// Mean Earth radius used for the great-circle distance, in kilometres.
const double earthRadiusKm = 6371;

/// Great-circle distance in kilometres between two WGS84 points.
///
/// Pure function: no platform, network, or storage. Callers pass index
/// `lat`/`lng` and a position that stays in memory for this call only.
double haversineKm({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  final lat1 = _toRadians(fromLat);
  final lat2 = _toRadians(toLat);
  final dLat = _toRadians(toLat - fromLat);
  final dLng = _toRadians(toLng - fromLng);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLng * sinLng;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
