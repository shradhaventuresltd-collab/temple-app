import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/district/district_overrides.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';

/// One temple's district, remembered on this device for the asset version.
class DistrictAssignment {
  const DistrictAssignment({
    required this.id,
    required this.lgd,
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final int lgd;
  final String name;
  final String state;
  final double latitude;
  final double longitude;
}

/// Local assignments for one boundary asset version.
///
/// The key is the asset version only. Temple index stamps are not stored.
abstract class DistrictAssignmentStore {
  Future<List<DistrictAssignment>?> read(String assetVersion);

  Future<void> write(String assetVersion, List<DistrictAssignment> rows);
}

/// In-memory stand-in for tests and for a preferences failure.
class MemoryDistrictAssignmentStore implements DistrictAssignmentStore {
  final Map<String, List<DistrictAssignment>> _rows = {};

  @override
  Future<List<DistrictAssignment>?> read(String assetVersion) async {
    final rows = _rows[assetVersion];
    if (rows == null) return null;
    return List<DistrictAssignment>.of(rows);
  }

  @override
  Future<void> write(String assetVersion, List<DistrictAssignment> rows) async {
    _rows[assetVersion] = List<DistrictAssignment>.of(rows);
  }
}

/// Shared-preferences cache. A failure is the caller's to swallow.
class PrefsDistrictAssignmentStore implements DistrictAssignmentStore {
  PrefsDistrictAssignmentStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<List<DistrictAssignment>?> read(String assetVersion) async {
    final prefs = await _preferences();
    return decodeDistrictAssignments(
      prefs.getString(districtAssignmentCacheKey(assetVersion)),
    );
  }

  @override
  Future<void> write(String assetVersion, List<DistrictAssignment> rows) async {
    final prefs = await _preferences();
    await prefs.setString(
      districtAssignmentCacheKey(assetVersion),
      jsonEncode([
        for (final row in rows)
          {
            'id': row.id,
            'lgd': row.lgd,
            'name': row.name,
            'state': row.state,
            'lat': row.latitude,
            'lng': row.longitude,
          },
      ]),
    );
  }
}

/// Parses a cache payload. Unknown shapes become null so the asset is read.
List<DistrictAssignment>? decodeDistrictAssignments(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = jsonDecode(raw);
  if (decoded is! List) return null;
  final rows = <DistrictAssignment>[];
  for (final item in decoded) {
    if (item is! Map) return null;
    final id = item['id'];
    final lgd = item['lgd'];
    final name = item['name'];
    final state = item['state'];
    final lat = item['lat'];
    final lng = item['lng'];
    if (id is! String || name is! String || state is! String) return null;
    if (lgd is! int || lat is! num || lng is! num) return null;
    rows.add(
      DistrictAssignment(
        id: id,
        lgd: lgd,
        name: name,
        state: state,
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
      ),
    );
  }
  return rows;
}

/// On-device district names. Nothing here reads Firestore.
class DistrictDirectory {
  DistrictDirectory._();

  static final DistrictDirectory instance = DistrictDirectory._();

  DistrictAssignmentStore _store = PrefsDistrictAssignmentStore();
  Future<Uint8List> Function() _loadBytes = _loadBundledBoundaries;
  bool _bundledLoader = true;
  final Map<String, DistrictAssignment> _byKey = {};
  String? _version;
  Future<void>? _flight;

  /// How many times the boundary asset was decoded. Tests watch this.
  @visibleForTesting
  int assetLoadCount = 0;

  /// True after assignments for [kDistrictBoundaryAssetVersion] are in memory.
  bool get isReady => _version == kDistrictBoundaryAssetVersion;

  /// District name for [temple], or null when this directory is cold,
  /// the temple has no coordinates, the point has no in-state district,
  /// or the stored point does not match.
  String? peek(Temple temple) {
    if (!isReady || !temple.hasCoordinates) return null;
    final row = _byKey[_templeKey(temple)];
    if (row == null) return null;
    if (row.latitude != temple.latitude || row.longitude != temple.longitude) {
      return null;
    }
    if (row.name.isEmpty) return null;
    if (!sameDistrictState(temple.state, row.state)) return null;
    return row.name;
  }

  /// Computes a district for every temple with coordinates.
  ///
  /// Loads the asset only when a temple is missing or its coordinates
  /// changed. Preferences failures leave the in-memory result in place.
  Future<void> ensureFor(List<Temple> temples) {
    final current = _flight;
    if (current != null) {
      return current.then((_) => ensureFor(temples));
    }
    final run = _ensure(temples);
    _flight = run;
    return run.whenComplete(() {
      if (identical(_flight, run)) _flight = null;
    });
  }

  /// Clears memory and swaps the store. Tests pass a memory store.
  @visibleForTesting
  void resetForTest({
    DistrictAssignmentStore? store,
    Future<Uint8List> Function()? loadBytes,
  }) {
    _store = store ?? MemoryDistrictAssignmentStore();
    _bundledLoader = loadBytes == null;
    _loadBytes = loadBytes ?? _loadBundledBoundaries;
    _byKey.clear();
    _version = null;
    _flight = null;
    assetLoadCount = 0;
  }

  Future<void> _ensure(List<Temple> temples) async {
    // No bundled file until a publisher names one licence. Overrides are
    // names, so they still apply. A test loader still runs. This path does
    // not read Firestore.
    if (_bundledLoader && !kDistrictBoundariesBundled) {
      _applyOverrides(temples);
      _version = kDistrictBoundaryAssetVersion;
      return;
    }
    if (_version != kDistrictBoundaryAssetVersion) {
      _byKey.clear();
      _version = null;
      try {
        final stored = await _store.read(kDistrictBoundaryAssetVersion);
        if (stored != null) {
          for (final row in stored) {
            _byKey[row.id] = row;
          }
          _version = kDistrictBoundaryAssetVersion;
        }
      } catch (_) {}
    }

    _applyOverrides(temples);
    final pending = <Temple>[];
    for (final temple in temples) {
      if (!temple.hasCoordinates) continue;
      if (districtOverrideFor(temple) != null) continue;
      final key = _templeKey(temple);
      final cached = _byKey[key];
      if (cached != null &&
          cached.latitude == temple.latitude &&
          cached.longitude == temple.longitude &&
          (cached.name.isEmpty ||
              sameDistrictState(temple.state, cached.state))) {
        continue;
      }
      pending.add(temple);
    }
    if (pending.isEmpty) {
      _version = kDistrictBoundaryAssetVersion;
      return;
    }

    final bytes = await _loadBytes();
    assetLoadCount += 1;
    final located = await compute(
      matchDistrictBatch,
      DistrictBatchRequest(
        bytes: bytes,
        ids: [for (final temple in pending) _templeKey(temple)],
        states: [for (final temple in pending) temple.state],
        latitudes: [for (final temple in pending) temple.latitude!],
        longitudes: [for (final temple in pending) temple.longitude!],
      ),
    );
    for (var i = 0; i < pending.length; i++) {
      final temple = pending[i];
      final row = located[i];
      final name = row['name']! as String;
      final state = row['state']! as String;
      final inState = name.isNotEmpty && sameDistrictState(temple.state, state);
      _byKey[_templeKey(temple)] = DistrictAssignment(
        id: _templeKey(temple),
        lgd: inState ? row['lgd']! as int : 0,
        name: inState ? name : '',
        state: inState ? state : temple.state,
        latitude: temple.latitude!,
        longitude: temple.longitude!,
      );
    }
    _version = kDistrictBoundaryAssetVersion;
    try {
      await _store.write(kDistrictBoundaryAssetVersion, _byKey.values.toList());
    } catch (_) {}
  }

  void _applyOverrides(List<Temple> temples) {
    for (final temple in temples) {
      if (!temple.hasCoordinates) continue;
      final override = districtOverrideFor(temple);
      if (override == null) continue;
      _byKey[_templeKey(temple)] = DistrictAssignment(
        id: _templeKey(temple),
        lgd: 0,
        name: override.name,
        state: override.state,
        latitude: temple.latitude!,
        longitude: temple.longitude!,
      );
    }
  }
}

String _templeKey(Temple temple) {
  if (temple.id.isNotEmpty) return temple.id;
  return '${temple.name}|${temple.latitude}|${temple.longitude}';
}

Future<Uint8List> _loadBundledBoundaries() async {
  // Lookup only. This asset must never be rendered. Widgets, painters, and
  // map layers must not read it.
  if (!kDistrictBoundariesBundled) {
    throw StateError(
      'District boundaries are not bundled. The evaluated LGD file does not '
      'name a single licence.',
    );
  }
  final data = await rootBundle.load(kDistrictBoundaryAsset);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Lookup passed into the directory filter.
///
/// Null until assignments are ready, which lets the chip show first.
/// After that, temples with no in-state district are omitted.
TempleDistrictName? bundledDistrictLookup() {
  if (!DistrictDirectory.instance.isReady) return null;
  return DistrictDirectory.instance.peek;
}

/// Loads boundaries for [temples]. A failure still returns [peek] so the
/// sheet can open with whatever is already in memory.
Future<TempleDistrictName> prepareDirectoryDistricts(
  List<Temple> temples,
) async {
  try {
    await DistrictDirectory.instance.ensureFor(temples);
  } catch (error, stack) {
    debugPrint('District boundaries did not load: $error\n$stack');
  }
  return DistrictDirectory.instance.peek;
}
