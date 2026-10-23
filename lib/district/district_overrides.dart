import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/models/temple.dart';

/// A district name for one temple id. No polygon is stored here.
class DistrictOverride {
  const DistrictOverride({required this.name, required this.state});

  final String name;
  final String state;
}

/// Border pins kept unconditionally.
///
/// The bundled lookup already names the same district as nearest-in-state
/// for both temples. These overrides still win over the polygon so a later
/// simplification cannot move the pin. An override is ignored when its
/// state does not match the temple's stored state. There is no general
/// post-2011 override table.
const Map<String, DistrictOverride> kDistrictOverrides = {
  'sita-ramachandra-swamy-temple': DistrictOverride(
    name: 'Bhadradri Kothagudem',
    state: 'Telangana',
  ),
  'malinithan': DistrictOverride(
    name: 'Lower Siang',
    state: 'Arunachal Pradesh',
  ),
};

/// The override for [temple], when its state matches the stored state.
DistrictOverride? districtOverrideFor(Temple temple) {
  if (temple.id.isEmpty) return null;
  final override = kDistrictOverrides[temple.id];
  if (override == null) return null;
  if (!sameDistrictState(temple.state, override.state)) return null;
  return override;
}
