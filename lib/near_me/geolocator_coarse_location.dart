import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temple_app/near_me/coarse_location.dart';

/// Maps a plugin permission onto the coarse states this feature uses.
///
/// [LocationPermission.always] is treated as already granted. Nothing in
/// this file requests background or always permission.
CoarsePermission coarsePermissionFrom(LocationPermission permission) {
  switch (permission) {
    case LocationPermission.whileInUse:
    case LocationPermission.always:
      return CoarsePermission.granted;
    case LocationPermission.deniedForever:
      return CoarsePermission.deniedForever;
    case LocationPermission.denied:
    case LocationPermission.unableToDetermine:
      return CoarsePermission.denied;
  }
}

/// One-shot approximate position through geolocator.
///
/// Accuracy is [LocationAccuracy.low] (Android PRIORITY_LOW_POWER, about
/// a kilometre on iOS). The fix is returned to the caller and not stored.
/// Background updates stay off. The position stream is not used.
class GeolocatorCoarseLocation implements CoarseLocationClient {
  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<CoarsePermission> checkPermission() async {
    return coarsePermissionFrom(await Geolocator.checkPermission());
  }

  @override
  Future<CoarsePermission> requestPermission() async {
    return coarsePermissionFrom(await Geolocator.requestPermission());
  }

  @override
  Future<CoarseFix?> lastKnownFix() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return coarseFixFromLastKnownPosition(position);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _oneShotSettings(timeout),
      );
      final latitude = position.latitude;
      final longitude = position.longitude;
      if (!latitude.isFinite || !longitude.isFinite) {
        throw const LocationFailure(LocationFailureKind.timeout);
      }
      return CoarseFix(latitude: latitude, longitude: longitude);
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      throw const LocationFailure(LocationFailureKind.timeout);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    } catch (_) {
      throw const LocationFailure(LocationFailureKind.timeout);
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

/// A cached platform position is only useful for a short while.
const Duration lastKnownMaxAge = Duration(minutes: 30);

/// Turns [position] into a last-known [CoarseFix], or null when it is
/// unusable. Keeps [Position.timestamp]. A fix older than [lastKnownMaxAge]
/// is rejected so a stale cache is not shown as a live reading.
CoarseFix? coarseFixFromLastKnownPosition(Position position, {DateTime? now}) {
  final latitude = position.latitude;
  final longitude = position.longitude;
  if (!latitude.isFinite || !longitude.isFinite) return null;
  final age = (now ?? DateTime.now()).difference(position.timestamp);
  if (age > lastKnownMaxAge) return null;
  return CoarseFix(
    latitude: latitude,
    longitude: longitude,
    timestamp: position.timestamp,
    lastKnown: true,
  );
}

/// Low accuracy, a time limit, and no background updates.
LocationSettings _oneShotSettings(Duration timeout) {
  if (kIsWeb) {
    return LocationSettings(accuracy: LocationAccuracy.low, timeLimit: timeout);
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppleSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
        allowBackgroundLocationUpdates: false,
        showBackgroundLocationIndicator: false,
      );
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      return LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeout,
      );
  }
}
