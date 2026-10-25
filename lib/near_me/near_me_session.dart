import 'package:flutter/foundation.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/nearby_temples.dart';

/// Where the near-me screen is in the permission flow.
enum NearMePhase {
  rationale,
  locating,
  sorted,
  denied,
  deniedForever,
  serviceOff,
  timedOut,
  declined,
}

/// Rationale, then one coarse fix, or a state/city (and later district)
/// centroid when location is unavailable.
///
/// The device fix is not stored on this object.
class NearMeSession extends ChangeNotifier {
  NearMeSession({
    required this.temples,
    required CoarseLocationClient location,
    this.districtOf = indexDistrictName,
    this.fixTimeout = const Duration(seconds: 20),
  }) : _location = location;

  final List<Temple> temples;
  final TempleDistrictLookup districtOf;
  final Duration fixTimeout;

  final CoarseLocationClient _location;

  NearMePhase phase = NearMePhase.rationale;
  List<NearbyTemple> rows = const [];
  String? placeLabel;
  String? anchorState;
  String? anchorCity;
  String? anchorDistrict;

  /// True when [rows] were sorted from the platform cache, not a live fix.
  bool usingLastKnown = false;

  bool _busy = false;
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// User accepted the rationale. Checks the service, then permission.
  Future<void> acceptRationale() => _locate(requestIfDenied: true);

  /// Denied this time. Asks again, then reads a fix when granted.
  Future<void> enableLocation() => _locate(requestIfDenied: true);

  /// Service was off, or the read timed out. Tries the same steps again.
  Future<void> retry() => _locate(requestIfDenied: true);

  /// App returned to the foreground. Re-checks the service and permission
  /// after Settings. A timeout stays on the error until [retry], so coming
  /// back cannot start another read and flash the locating message again.
  Future<void> onAppResumed() async {
    if (_busy || _disposed) return;
    switch (phase) {
      case NearMePhase.denied:
      case NearMePhase.deniedForever:
      case NearMePhase.serviceOff:
        break;
      case NearMePhase.rationale:
      case NearMePhase.locating:
      case NearMePhase.sorted:
      case NearMePhase.timedOut:
      case NearMePhase.declined:
        return;
    }
    _busy = true;
    var handedToLocate = false;
    try {
      final serviceOn = await _location.isServiceEnabled();
      if (_disposed) return;
      if (!serviceOn) {
        if (phase != NearMePhase.serviceOff) _fail(NearMePhase.serviceOff);
        return;
      }
      final permission = await _location.checkPermission();
      if (_disposed) return;
      if (permission == CoarsePermission.deniedForever) {
        if (phase != NearMePhase.deniedForever) {
          _fail(NearMePhase.deniedForever);
        }
        return;
      }
      if (permission != CoarsePermission.granted) {
        if (phase != NearMePhase.denied) _fail(NearMePhase.denied);
        return;
      }
      handedToLocate = true;
      await _locate(requestIfDenied: false, holdsBusy: true);
    } finally {
      if (!handedToLocate) _busy = false;
    }
  }

  Future<void> openAppSettings() => _location.openAppSettings();

  Future<void> openLocationSettings() => _location.openLocationSettings();

  /// User closed the rationale. The place picker is the list from here.
  void declineRationale() {
    phase = NearMePhase.declined;
    _notify();
  }

  void selectState(String? state) {
    anchorState = _clean(state);
    anchorCity = null;
    anchorDistrict = null;
    _applyAnchor();
  }

  void selectCity(String? city) {
    anchorCity = _clean(city);
    _applyAnchor();
  }

  void selectDistrict(String? district) {
    anchorDistrict = _clean(district);
    _applyAnchor();
  }

  Future<void> _locate({
    required bool requestIfDenied,
    bool holdsBusy = false,
  }) async {
    if (!holdsBusy) {
      if (_busy) return;
      _busy = true;
    }
    phase = NearMePhase.locating;
    _notify();
    try {
      if (!await _location.isServiceEnabled()) {
        _fail(NearMePhase.serviceOff);
        return;
      }
      var permission = await _location.checkPermission();
      if (permission == CoarsePermission.denied && requestIfDenied) {
        permission = await _location.requestPermission();
      }
      if (permission == CoarsePermission.deniedForever) {
        _fail(NearMePhase.deniedForever);
        return;
      }
      if (permission != CoarsePermission.granted) {
        _fail(NearMePhase.denied);
        return;
      }
      await _readFix();
    } on LocationFailure catch (failure) {
      _fail(
        failure.kind == LocationFailureKind.serviceDisabled
            ? NearMePhase.serviceOff
            : NearMePhase.timedOut,
      );
    } catch (_) {
      _fail(NearMePhase.timedOut);
    } finally {
      _busy = false;
    }
  }

  Future<void> _readFix() async {
    CoarseFix? fix;
    var usedLastKnown = false;
    try {
      fix = await _location.currentFix(timeout: fixTimeout);
    } on LocationFailure catch (failure) {
      if (failure.kind != LocationFailureKind.timeout) rethrow;
      if (_disposed) return;
      fix = await _location.lastKnownFix();
      if (_disposed) return;
      if (fix == null) rethrow;
      usedLastKnown = true;
    }
    if (_disposed) return;
    anchorState = null;
    anchorCity = null;
    anchorDistrict = null;
    placeLabel = null;
    rows = sortTemplesByDistance(
      temples,
      latitude: fix.latitude,
      longitude: fix.longitude,
    );
    usingLastKnown = usedLastKnown || fix.lastKnown;
    phase = NearMePhase.sorted;
    _notify();
  }

  void _fail(NearMePhase next) {
    if (_disposed) return;
    usingLastKnown = false;
    phase = next;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _applyAnchor() {
    usingLastKnown = false;
    placeLabel = nearMePlaceLabel(
      state: anchorState,
      city: anchorCity,
      district: anchorDistrict,
    );
    if (placeLabel == null) {
      rows = const [];
      _notify();
      return;
    }
    final centroid = centroidFor(
      temples,
      state: anchorState,
      city: anchorCity,
      district: anchorDistrict,
      districtOf: districtOf,
    );
    rows = centroid == null
        ? const []
        : sortTemplesByDistance(
            temples,
            latitude: centroid.latitude,
            longitude: centroid.longitude,
          );
    _notify();
  }

  String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
