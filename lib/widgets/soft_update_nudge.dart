import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dismissible prompt when the build is below `recommended_build`.
///
/// The directory stays on screen. [onDismiss] hides it for this show.
class SoftUpdateNudgeBanner extends StatelessWidget {
  const SoftUpdateNudgeBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  static const String message = 'A newer version is ready on the Play Store.';

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('soft-update-nudge'),
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            const Icon(
              Icons.system_update_alt,
              color: Color(0xFF0A2540),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF0A2540),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            TextButton(
              key: const Key('soft-update-open'),
              onPressed: onUpdate,
              child: const Text('Update'),
            ),
            TextButton(
              key: const Key('soft-update-dismiss'),
              onPressed: onDismiss,
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
