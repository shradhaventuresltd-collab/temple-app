import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:temple_app/district/district_attribution.dart';

/// Bundled district polygons. Bump this when the asset bytes change so the
/// on-device assignment cache key changes. Index stamps do not belong here.
const String kDistrictBoundaryAssetVersion = 'lgd-2024-dsb1-500m';

/// The boundary asset is a lookup table. It must never be rendered.
/// Widgets, painters, and map layers must not read [kDistrictBoundaryAsset].
/// Only the district lookup service may decode it.
const String kDistrictBoundaryAsset = 'assets/districts/india_districts.dsb';

/// The Bharatlas LGD 2024 layer is bundled under CC BY 4.0.
const bool kDistrictBoundariesBundled = true;

/// Test hook. Null uses [kDistrictBoundariesBundled].
@visibleForTesting
bool? debugDistrictBoundariesBundled;

/// Whether district geometry is available to the filter and near-me button.
bool get districtBoundariesAreBundled =>
    debugDistrictBoundariesBundled ?? kDistrictBoundariesBundled;

/// Coordinate scale. 4 decimal degrees, about 11 metres.
const int kDistrictCoordinateScale = 10000;

/// Nearest in-state district is used only inside this distance.
/// Farther pins get no district.
const double kStoredStateNearestLimitMetres = 2000;

/// Cache key for assignments computed from [assetVersion].
///
/// The key changes only when the boundary asset version changes. It does not
/// include a temple index version.
String districtAssignmentCacheKey(String assetVersion) =>
    'district_lookup:$assetVersion';

/// One district from the bundled boundary asset.
class DistrictHit {
  const DistrictHit({
    required this.lgdCode,
    required this.stateLgdCode,
    required this.name,
    required this.stateName,
  });

  /// LGD district code. Muzaffarabad and Mirpur are both 0 in the 2024
  /// snapshot; [name] keeps those two apart.
  final int lgdCode;
  final int stateLgdCode;
  final String name;
  final String stateName;
}

/// A locate result. [insidePolygon] is false when the point missed every
/// polygon and [hit] is the nearest district by bounding-box distance.
class DistrictLocate {
  const DistrictLocate({required this.hit, required this.insidePolygon});

  final DistrictHit hit;
  final bool insidePolygon;
}

/// One input point for [matchDistrictBatch].
class DistrictBatchRequest {
  const DistrictBatchRequest({
    required this.bytes,
    required this.ids,
    required this.states,
    required this.latitudes,
    required this.longitudes,
  });

  final Uint8List bytes;
  final List<String> ids;

  /// Stored state of each temple. The lookup may not leave this state.
  final List<String> states;
  final List<double> latitudes;
  final List<double> longitudes;
}

/// Isolate entry. Decodes [DistrictBatchRequest.bytes] and locates every point
/// inside that temple's stored state. An empty name means no district.
List<Map<String, Object>> matchDistrictBatch(DistrictBatchRequest request) {
  final index = DistrictIndex.decode(request.bytes);
  final out = <Map<String, Object>>[];
  for (var i = 0; i < request.ids.length; i++) {
    final hit = index.locateInStoredState(
      request.latitudes[i],
      request.longitudes[i],
      request.states[i],
    );
    out.add({
      'id': request.ids[i],
      'lgd': hit?.lgdCode ?? 0,
      'stateLgd': hit?.stateLgdCode ?? 0,
      'name': hit?.name ?? '',
      'state': hit?.stateName ?? '',
      'inside': hit != null,
    });
  }
  return out;
}

int quantizeCoordinate(double value) =>
    (value * kDistrictCoordinateScale).round();

/// Decoded district boundaries.
class DistrictIndex {
  DistrictIndex._(this._districts);

  final List<_DistrictShape> _districts;

  int get length => _districts.length;

  /// Builds an index from GeoJSON-order rings (`[lng, lat]`).
  factory DistrictIndex.fromGeoRings(
    List<({DistrictHit hit, List<List<List<List<double>>>> polygons})>
    districts,
  ) {
    final shapes = <_DistrictShape>[];
    for (final district in districts) {
      final polygons = <List<Int32List>>[];
      var minLat = 1 << 30;
      var minLng = 1 << 30;
      var maxLat = -(1 << 30);
      var maxLng = -(1 << 30);
      for (final polygon in district.polygons) {
        final rings = <Int32List>[];
        for (final ring in polygon) {
          final coords = <int>[];
          for (final pair in ring) {
            final lng = quantizeCoordinate(pair[0]);
            final lat = quantizeCoordinate(pair[1]);
            if (coords.length >= 2 &&
                coords[coords.length - 2] == lat &&
                coords[coords.length - 1] == lng) {
              continue;
            }
            coords.add(lat);
            coords.add(lng);
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
            if (lng < minLng) minLng = lng;
            if (lng > maxLng) maxLng = lng;
          }
          if (coords.length >= 4 &&
              coords[0] == coords[coords.length - 2] &&
              coords[1] == coords[coords.length - 1]) {
            coords.removeRange(coords.length - 2, coords.length);
          }
          if (coords.length >= 6) rings.add(Int32List.fromList(coords));
        }
        if (rings.isNotEmpty) polygons.add(rings);
      }
      if (polygons.isEmpty) continue;
      shapes.add(
        _DistrictShape(
          hit: district.hit,
          minLat: minLat,
          minLng: minLng,
          maxLat: maxLat,
          maxLng: maxLng,
          area: _polygonArea(polygons),
          polygons: polygons,
        ),
      );
    }
    return DistrictIndex._(shapes);
  }

  /// Reads the compact binary written by `scripts/build_district_boundaries.mjs`.
  factory DistrictIndex.decode(Uint8List bytes) {
    final reader = _Reader(bytes);
    final magic = String.fromCharCodes(reader.bytes(4));
    if (magic != 'DSB1') {
      throw FormatException('District boundary asset is not DSB1 ($magic).');
    }
    final version = reader.u16();
    if (version != 1 && version != 2) {
      throw FormatException('Unsupported district boundary version $version.');
    }
    final count = reader.u16();
    final stringBytes = reader.u32();
    reader.u32(); // point count, retained for the build report
    reader.u32(); // tolerance metres
    final table = reader.bytes(stringBytes);
    final districts = <_DistrictShape>[];
    for (var i = 0; i < count; i++) {
      final lgd = reader.u32();
      final stateLgd = reader.u32();
      final nameOff = reader.u16();
      final nameLen = reader.u16();
      final stateOff = reader.u16();
      final stateLen = reader.u16();
      final minLat = reader.i32();
      final minLng = reader.i32();
      final maxLat = reader.i32();
      final maxLng = reader.i32();
      final polygonCount = reader.u16();
      final polygons = <List<Int32List>>[];
      for (var p = 0; p < polygonCount; p++) {
        final ringCount = reader.u16();
        final rings = <Int32List>[];
        for (var r = 0; r < ringCount; r++) {
          final pointCount = reader.u16();
          final coords = Int32List(pointCount * 2);
          var lat = reader.i32();
          var lng = reader.i32();
          coords[0] = lat;
          coords[1] = lng;
          for (var n = 1; n < pointCount; n++) {
            if (version == 2) {
              lat += reader.i16();
              lng += reader.i16();
            } else {
              lat += reader.i32();
              lng += reader.i32();
            }
            coords[n * 2] = lat;
            coords[n * 2 + 1] = lng;
          }
          rings.add(coords);
        }
        polygons.add(rings);
      }
      final name = _utf8Slice(table, nameOff, nameLen);
      final state = _utf8Slice(table, stateOff, stateLen);
      districts.add(
        _DistrictShape(
          hit: DistrictHit(
            lgdCode: lgd,
            stateLgdCode: stateLgd,
            name: name,
            stateName: state,
          ),
          minLat: minLat,
          minLng: minLng,
          maxLat: maxLat,
          maxLng: maxLng,
          area: _polygonArea(polygons),
          polygons: polygons,
        ),
      );
    }
    return DistrictIndex._(districts);
  }

  /// District of [storedState] only.
  ///
  /// A pin inside a polygon of that state uses the smallest such polygon,
  /// then the lower LGD code, then the name. A pin in none of them uses the
  /// nearest district of that state within [kStoredStateNearestLimitMetres].
  /// Beyond that limit the result is null. It is never a district of
  /// another state.
  DistrictHit? locateInStoredState(
    double latitude,
    double longitude,
    String storedState,
  ) {
    final latQ = quantizeCoordinate(latitude);
    final lngQ = quantizeCoordinate(longitude);
    final hits = <_DistrictShape>[];
    final pool = <_DistrictShape>[];
    for (final district in _districts) {
      if (!sameDistrictState(storedState, district.hit.stateName)) continue;
      pool.add(district);
      if (lngQ < district.minLng ||
          lngQ > district.maxLng ||
          latQ < district.minLat ||
          latQ > district.maxLat) {
        continue;
      }
      if (district.contains(latQ, lngQ)) hits.add(district);
    }
    if (hits.isNotEmpty) {
      hits.sort(_bySpecificity);
      return hits.first.hit;
    }
    _DistrictShape? best;
    (double, int, int, String)? bestKey;
    for (final district in pool) {
      if (district.bboxDistanceMetres(latitude, longitude) >
          kStoredStateNearestLimitMetres) {
        continue;
      }
      final distance = district.boundaryDistanceMetres(latitude, longitude);
      if (distance > kStoredStateNearestLimitMetres) continue;
      final key = (
        distance,
        district.area,
        district.hit.lgdCode,
        district.hit.name,
      );
      if (bestKey == null || _nearer(key, bestKey)) {
        best = district;
        bestKey = key;
      }
    }
    return best?.hit;
  }

  /// Point-in-polygon with a bounding-box prefilter.
  ///
  /// A point in several polygons (the source layer overlaps) uses the
  /// smallest polygon, then the lower LGD code, then the name. A point in
  /// no polygon is the nearest district by bounding-box distance. Temple
  /// assignment uses [locateInStoredState], which can return null.
  DistrictLocate locate(double latitude, double longitude) {
    if (_districts.isEmpty) {
      throw StateError('District boundary asset has no districts.');
    }
    final latQ = quantizeCoordinate(latitude);
    final lngQ = quantizeCoordinate(longitude);
    final hits = <_DistrictShape>[];
    for (final district in _districts) {
      if (lngQ < district.minLng ||
          lngQ > district.maxLng ||
          latQ < district.minLat ||
          latQ > district.maxLat) {
        continue;
      }
      if (district.contains(latQ, lngQ)) hits.add(district);
    }
    if (hits.isNotEmpty) {
      hits.sort(_bySpecificity);
      return DistrictLocate(hit: hits.first.hit, insidePolygon: true);
    }
    var best = _districts.first;
    var bestKey = _nearestKey(best, latitude, longitude);
    for (final district in _districts.skip(1)) {
      final key = _nearestKey(district, latitude, longitude);
      if (_nearer(key, bestKey)) {
        best = district;
        bestKey = key;
      }
    }
    return DistrictLocate(hit: best.hit, insidePolygon: false);
  }

  /// A vertex of [name], for border tests. Null when the district is absent.
  ({double latitude, double longitude})? boundaryVertex(String name) {
    for (final district in _districts) {
      if (district.hit.name != name) continue;
      final ring = district.polygons.first.first;
      return (
        latitude: ring[0] / kDistrictCoordinateScale,
        longitude: ring[1] / kDistrictCoordinateScale,
      );
    }
    return null;
  }
}

int _polygonArea(List<List<Int32List>> polygons) {
  var area = 0;
  for (final rings in polygons) {
    if (rings.isEmpty) continue;
    var part = _ringAbsCross(rings.first);
    for (final hole in rings.skip(1)) {
      part -= _ringAbsCross(hole);
    }
    area += part.abs();
  }
  return area;
}

int _ringAbsCross(Int32List ring) {
  final n = ring.length ~/ 2;
  var sum = 0;
  for (var i = 0; i < n; i++) {
    final y1 = ring[i * 2];
    final x1 = ring[i * 2 + 1];
    final j = (i + 1) % n;
    final y2 = ring[j * 2];
    final x2 = ring[j * 2 + 1];
    sum += x1 * y2 - x2 * y1;
  }
  return sum.abs();
}

int _bySpecificity(_DistrictShape a, _DistrictShape b) {
  final byArea = a.area.compareTo(b.area);
  if (byArea != 0) return byArea;
  final byLgd = a.hit.lgdCode.compareTo(b.hit.lgdCode);
  if (byLgd != 0) return byLgd;
  return a.hit.name.compareTo(b.hit.name);
}

(double, int, int, String) _nearestKey(
  _DistrictShape district,
  double latitude,
  double longitude,
) {
  return (
    district.bboxDistanceMetres(latitude, longitude),
    district.area,
    district.hit.lgdCode,
    district.hit.name,
  );
}

double _segmentDistanceFromOrigin(
  double ax,
  double ay,
  double bx,
  double by,
) {
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return math.sqrt(ax * ax + ay * ay);
  final t = ((-ax * dx) + (-ay * dy)) / len2;
  final clamped = t.clamp(0.0, 1.0);
  final px = ax + clamped * dx;
  final py = ay + clamped * dy;
  return math.sqrt(px * px + py * py);
}

bool _nearer(
  (double, int, int, String) candidate,
  (double, int, int, String) best,
) {
  if (candidate.$1 < best.$1) return true;
  if (candidate.$1 > best.$1) return false;
  if (candidate.$2 != best.$2) return candidate.$2 < best.$2;
  if (candidate.$3 != best.$3) return candidate.$3 < best.$3;
  return candidate.$4.compareTo(best.$4) < 0;
}

class _DistrictShape {
  const _DistrictShape({
    required this.hit,
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
    required this.area,
    required this.polygons,
  });

  final DistrictHit hit;
  final int minLat;
  final int minLng;
  final int maxLat;
  final int maxLng;
  final int area;

  /// Polygons of rings. Each ring is `lat, lng, lat, lng, ...` quantized.
  final List<List<Int32List>> polygons;

  bool contains(int lat, int lng) {
    for (final rings in polygons) {
      if (rings.isEmpty || !_inRing(lng, lat, rings.first)) continue;
      var hole = false;
      for (final ring in rings.skip(1)) {
        if (_inRing(lng, lat, ring)) {
          hole = true;
          break;
        }
      }
      if (!hole) return true;
    }
    return false;
  }

  /// Metres from [latitude], [longitude] to the nearest ring edge.
  double boundaryDistanceMetres(double latitude, double longitude) {
    final kx = 111320 * math.cos(latitude * math.pi / 180);
    const ky = 110540.0;
    var best = double.infinity;
    for (final rings in polygons) {
      for (final ring in rings) {
        final n = ring.length ~/ 2;
        for (var i = 0; i < n; i++) {
          final j = (i + 1) % n;
          final ax =
              (ring[i * 2 + 1] / kDistrictCoordinateScale - longitude) * kx;
          final ay = (ring[i * 2] / kDistrictCoordinateScale - latitude) * ky;
          final bx =
              (ring[j * 2 + 1] / kDistrictCoordinateScale - longitude) * kx;
          final by = (ring[j * 2] / kDistrictCoordinateScale - latitude) * ky;
          final distance = _segmentDistanceFromOrigin(ax, ay, bx, by);
          if (distance < best) best = distance;
        }
      }
    }
    return best;
  }

  double bboxDistanceMetres(double latitude, double longitude) {
    final minLatitude = minLat / kDistrictCoordinateScale;
    final maxLatitude = maxLat / kDistrictCoordinateScale;
    final minLongitude = minLng / kDistrictCoordinateScale;
    final maxLongitude = maxLng / kDistrictCoordinateScale;
    final dLng = longitude < minLongitude
        ? minLongitude - longitude
        : longitude > maxLongitude
        ? longitude - maxLongitude
        : 0.0;
    final dLat = latitude < minLatitude
        ? minLatitude - latitude
        : latitude > maxLatitude
        ? latitude - maxLatitude
        : 0.0;
    final kx = 111320 * math.cos(latitude * math.pi / 180);
    return math.sqrt(dLng * kx * dLng * kx + dLat * 110540 * dLat * 110540);
  }
}

/// Even-odd point in ring. [x] is quantized longitude, [y] is quantized latitude.
/// A point on an edge counts as inside.
bool _inRing(int x, int y, Int32List ring) {
  final n = ring.length ~/ 2;
  var inside = false;
  for (var i = 0; i < n; i++) {
    final y1 = ring[i * 2];
    final x1 = ring[i * 2 + 1];
    final j = (i + 1) % n;
    final y2 = ring[j * 2];
    final x2 = ring[j * 2 + 1];
    final cross = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1);
    if (cross == 0) {
      final dot = (x - x1) * (x2 - x1) + (y - y1) * (y2 - y1);
      final len2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
      if (dot >= 0 && dot <= len2) return true;
    }
    if ((y1 > y) != (y2 > y)) {
      final den = y2 - y1;
      final num = (x2 - x1) * (y - y1);
      final left = (x - x1) * den;
      if ((den > 0 && left < num) || (den < 0 && left > num)) {
        inside = !inside;
      }
    }
  }
  return inside;
}

String _utf8Slice(Uint8List table, int offset, int length) {
  return String.fromCharCodes(table.sublist(offset, offset + length));
}

class _Reader {
  _Reader(Uint8List bytes) : data = ByteData.sublistView(bytes), _bytes = bytes;

  final ByteData data;
  final Uint8List _bytes;
  int offset = 0;

  Uint8List bytes(int length) {
    final slice = Uint8List.sublistView(_bytes, offset, offset + length);
    offset += length;
    return slice;
  }

  int u16() {
    final value = data.getUint16(offset, Endian.little);
    offset += 2;
    return value;
  }

  int u32() {
    final value = data.getUint32(offset, Endian.little);
    offset += 4;
    return value;
  }

  int i32() {
    final value = data.getInt32(offset, Endian.little);
    offset += 4;
    return value;
  }

  int i16() {
    final value = data.getInt16(offset, Endian.little);
    offset += 2;
    return value;
  }
}

/// Fold a state label so temple text and LGD display names compare.
String canonicalDistrictState(String raw) {
  var text = raw.toLowerCase().replaceAll('&', ' and ');
  text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  text = text.replaceAll(RegExp(r'\band\b'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return switch (text) {
    'nct of delhi' => 'delhi',
    'orissa' => 'odisha',
    'pondicherry' => 'puducherry',
    'andaman nicobar islands' => 'andaman nicobar',
    _ => text,
  };
}

/// States are the same place after [canonicalDistrictState].
bool sameDistrictState(String templeState, String boundaryState) {
  return canonicalDistrictState(templeState) ==
      canonicalDistrictState(boundaryState);
}

/// Referenced so the attribution module stays part of the boundary library
/// for licence review. The licences screen shows the same constant.
String get districtBoundaryAttribution => kDistrictBoundaryAttribution;
