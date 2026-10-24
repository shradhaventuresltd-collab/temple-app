/// Approximate-location permission. [granted] is while-in-use or a
/// previous always grant. This feature never asks for background access.
enum CoarsePermission { denied, deniedForever, granted }

/// One in-memory fix. Not written to disk, logs, or a network call.
class CoarseFix {
  const CoarseFix({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFailureKind { timeout, serviceDisabled }

/// A location read that did not produce a fix. The message is this kind
/// only, so a platform error cannot carry coordinates into a log.
class LocationFailure implements Exception {
  const LocationFailure(this.kind);

  final LocationFailureKind kind;

  @override
  String toString() => 'LocationFailure(${kind.name})'; // l10n-allow: diagnostic, not UI copy
}

/// One-shot approximate location. Tests pass a fake. Production uses
/// [GeolocatorCoarseLocation].
abstract class CoarseLocationClient {
  Future<bool> isServiceEnabled();

  Future<CoarsePermission> checkPermission();

  Future<CoarsePermission> requestPermission();

  /// Low-accuracy fix. Times out after [timeout] (10 seconds).
  Future<CoarseFix> currentFix({
    Duration timeout = const Duration(seconds: 10),
  });

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
