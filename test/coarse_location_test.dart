import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/geolocator_coarse_location.dart';

void main() {
  test('plugin permissions map onto coarse states', () {
    expect(
      coarsePermissionFrom(LocationPermission.whileInUse),
      CoarsePermission.granted,
    );
    expect(
      coarsePermissionFrom(LocationPermission.always),
      CoarsePermission.granted,
    );
    expect(
      coarsePermissionFrom(LocationPermission.denied),
      CoarsePermission.denied,
    );
    expect(
      coarsePermissionFrom(LocationPermission.deniedForever),
      CoarsePermission.deniedForever,
    );
    expect(
      coarsePermissionFrom(LocationPermission.unableToDetermine),
      CoarsePermission.denied,
    );
  });

  test('a last-known fix older than 30 minutes is rejected', () {
    final now = DateTime.utc(2026, 10, 25, 12);
    final fresh = coarseFixFromLastKnownPosition(
      _position(now.subtract(const Duration(minutes: 29))),
      now: now,
    );
    expect(fresh, isNotNull);
    expect(fresh!.lastKnown, isTrue);
    expect(fresh.timestamp, now.subtract(const Duration(minutes: 29)));
    expect(fresh.latitude, 9.9);
    expect(fresh.longitude, 78.1);

    final atLimit = coarseFixFromLastKnownPosition(
      _position(now.subtract(lastKnownMaxAge)),
      now: now,
    );
    expect(atLimit, isNotNull);
    expect(atLimit!.lastKnown, isTrue);

    expect(
      coarseFixFromLastKnownPosition(
        _position(now.subtract(const Duration(minutes: 31))),
        now: now,
      ),
      isNull,
    );
    expect(
      coarseFixFromLastKnownPosition(
        _position(now.subtract(const Duration(hours: 5))),
        now: now,
      ),
      isNull,
    );
  });
}

Position _position(DateTime timestamp) {
  return Position(
    latitude: 9.9,
    longitude: 78.1,
    timestamp: timestamp,
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
