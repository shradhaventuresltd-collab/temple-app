import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Non-blocking text from Remote Config `maintenance_message`.
///
/// Shown while the directory stays available. An empty message is omitted
/// by the caller.
class MaintenanceMessageBanner extends StatelessWidget {
  const MaintenanceMessageBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('maintenance-message-banner'),
      color: const Color(0xFF0A2540),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.campaign_outlined,
              color: Color(0xFFFFD54F),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFF8EE),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
