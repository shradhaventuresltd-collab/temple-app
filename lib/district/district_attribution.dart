import 'package:flutter/foundation.dart';

/// Exact credit line published with the LGD district layer.
///
/// Bharatlas labels the layer CC0-1.0 / CC-BY-4.0. Both licences allow
/// bundling the geometry in this app. CC-BY-4.0 requires this credit.
const String kDistrictBoundaryAttribution =
    'Source: LGD. Published via bharatlas (bharatlas.com). '
    'Licence: CC0-1.0 / CC-BY-4.0.';

/// Human-readable source name for the About / licences screen.
const String kDistrictBoundarySourceName = 'Bharatlas LGD Districts (2024)';

const String kDistrictBoundaryLicence = 'CC0-1.0 / CC-BY-4.0';

const String kDistrictBoundarySourcePage =
    'https://bharatlas.com/view/lgd_districts';

const String kDistrictBoundaryDownload =
    'https://bharatlas.com/api/dl/admin/districts/LGD_Districts.geojson';

const String kDistrictBoundaryUpstream = 'https://lgdirectory.gov.in/';

const String kDistrictBoundaryCc0 =
    'https://creativecommons.org/publicdomain/zero/1.0/';

const String kDistrictBoundaryCcBy4 =
    'https://creativecommons.org/licenses/by/4.0/';

/// Registers the district-boundary credit for the platform licence page.
void registerDistrictBoundaryLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const <String>[kDistrictBoundarySourceName],
      '$kDistrictBoundaryAttribution\n\n'
      'Licence: $kDistrictBoundaryLicence.\n'
      'CC0-1.0 ($kDistrictBoundaryCc0) and CC-BY-4.0 '
      '($kDistrictBoundaryCcBy4) both allow this geometry to be bundled '
      'in the app. CC-BY-4.0 requires the credit line above.\n'
      'Layer: $kDistrictBoundarySourcePage\n'
      'Upstream: $kDistrictBoundaryUpstream\n',
    );
  });
}
