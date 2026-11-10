import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/utils/deity_groups.dart';

void main() {
  test('count Shiva-group temples whose pin is in Madurai district', () {
    final index = DistrictIndex.decode(
      File('assets/districts/india_districts.dsb').readAsBytesSync(),
    );
    var shivaMadurai = 0;
    var shivaTamilNadu = 0;
    final byDistrict = <String, int>{};
    for (final temple in sampleTemples) {
      if (deityGroupBase(temple.deity) != 'Shiva') continue;
      if (temple.state != 'Tamil Nadu') continue;
      final latitude = temple.latitude;
      final longitude = temple.longitude;
      if (latitude == null || longitude == null) continue;
      shivaTamilNadu++;
      final hit = index.locateInStoredState(
        latitude,
        longitude,
        temple.state,
      );
      final name = hit?.name ?? '(none)';
      byDistrict[name] = (byDistrict[name] ?? 0) + 1;
      if (name == 'Madurai') shivaMadurai++;
    }
    // lib/data/sample_data.dart pins, matched with
    // assets/districts/india_districts.dsb. 0 of the Tamil Nadu Shiva-group
    // temples fall in Madurai (the rest are Thanjavur, Chennai,
    // Ramanathapuram, Chengalpattu, Cuddalore, Kanchipuram, Tiruvannamalai,
    // Tiruchirappalli, Thiruvarur, Tirunelveli, Mayiladuthurai).
    expect(shivaTamilNadu, greaterThan(0));
    expect(shivaMadurai, 0);
    expect(byDistrict.containsKey('Madurai'), isFalse);
  });
}
