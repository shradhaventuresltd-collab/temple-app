import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_attribution.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:url_launcher/url_launcher.dart';

/// Credit for data bundled with the app, including district boundaries.
class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key});

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  Future<void> _open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.poppins(
      fontSize: 14,
      height: 1.45,
      color: Colors.brown.shade800,
    );
    final linkStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE65100),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFE65100),
    );
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _saffron,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.l10n.licences,
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
            context.l10n.districtBoundaries,
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kDistrictBoundaryAttribution,
            key: const Key('licences-attribution'),
            style: body,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 4),
          TextButton(
            key: const Key('licences-source-link'),
            onPressed: () => unawaited(_open(kDistrictBoundarySourcePage)),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Text(context.l10n.bharatlasLink, style: linkStyle),
          ),
          TextButton(
            key: const Key('licences-licence-link'),
            onPressed: () => unawaited(_open(kDistrictBoundaryLicenceUrl)),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Text(context.l10n.ccBy40, style: linkStyle),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.districtBundlingNote(
              kDistrictBoundaryDatasetVersion,
              kDistrictBoundarySourceUpdated,
              kDistrictBoundaryFetchedOn,
            ),
            key: const Key('licences-bundling'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kDistrictBoundaryOriginalData,
            key: const Key('licences-original-data'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: Colors.brown.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
