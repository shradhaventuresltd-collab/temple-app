import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:temple_app/services/store_platform.dart';

/// Dismissible prompt when the build is below `recommended_build`.
///
/// The directory stays on screen. [onDismiss] hides it for this show.
class SoftUpdateNudgeBanner extends StatelessWidget {
  const SoftUpdateNudgeBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
    this.storePlatform = StorePlatform.android,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;
  final StorePlatform storePlatform;

  /// Android copy. The banner shows [messageFor].
  static const String message = 'A newer version is ready on the Play Store.';

  static String messageFor(StorePlatform platform) =>
      softUpdateMessage(platform);

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
                messageFor(storePlatform),
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
