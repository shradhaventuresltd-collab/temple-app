import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_attribution.dart';

/// Credit for data bundled with the app, including district boundaries.
class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key});

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _saffron,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Licences',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'District boundaries',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kDistrictBoundarySourceName,
            key: const Key('licences-source'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kDistrictBoundaryLicence,
            key: const Key('licences-licence'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            kDistrictBoundaryAttribution,
            key: const Key('licences-attribution'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dataset $kDistrictBoundaryDatasetVersion, updated $kDistrictBoundarySourceUpdated. This geometry is not in the app.',
            key: const Key('licences-bundling'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: Colors.brown.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
