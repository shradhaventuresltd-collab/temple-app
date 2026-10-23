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
}
