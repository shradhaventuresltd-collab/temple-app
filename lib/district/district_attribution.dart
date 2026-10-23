import 'package:flutter/foundation.dart';

/// Publisher of the bundled LGD district layer.
const String kDistrictBoundarySourceName = 'Bharatlas LGD Districts (2024)';

/// SPDX id recorded in assets/districts/manifest.json.
///
/// The build gate accepts this value only. CC0-1.0 is not the licence of
/// the copy shipped in this app.
const String kDistrictBoundaryLicence = 'CC-BY-4.0';

/// Shown on the licences screen and registered with [LicenseRegistry].
const String kDistrictBoundaryAttribution =
    'District boundaries © Bharatlas (LGD 2024), licensed CC BY 4.0, simplified for this app.';

const String kDistrictBoundarySourcePage =
    'https://bharatlas.com/view/lgd_districts';

const String kDistrictBoundaryLicenceUrl =
    'https://creativecommons.org/licenses/by/4.0/';

/// Dataset the card calls "LGD snapshot 2024". Card updated date.
const String kDistrictBoundaryDatasetVersion = 'LGD snapshot 2024';

const String kDistrictBoundarySourceUpdated = '2026-05-19';

const String kDistrictBoundaryFetchedOn = '2026-10-23';

/// Package name on the Flutter licence page.
const String kDistrictBoundaryLicensePackage = 'Bharatlas LGD Districts 2024';

/// Const credit for [LicenseRegistry]. Startup does not read the geometry.
const String kDistrictBoundaryLicenseEntry =
    'District boundaries © Bharatlas (LGD 2024), licensed CC BY 4.0, '
    'simplified for this app.\n\n'
    'Source: https://bharatlas.com/view/lgd_districts\n'
    'Licence: https://creativecommons.org/licenses/by/4.0/\n\n'
    'The polygons in this app were simplified from the Bharatlas LGD '
    'Districts 2024 layer.';

/// Registers the district-boundary credit without opening the asset.
void registerDistrictBoundaryLicense() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(<String>[
      kDistrictBoundaryLicensePackage,
    ], kDistrictBoundaryLicenseEntry);
  });
}
