import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/firestore_read_log.dart';
import 'package:temple_app/services/offline_link.dart';

/// Shown while the device has no network. The directory already on screen
/// stays; Firestore persistence and the cache-first index are what keep
/// temples available. The banner clears when a network returns.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const message =
      "You're offline. Showing temples saved on this device.";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DirectoryLink.offline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Material(
          key: const Key('offline-banner'),
          color: const Color(0xFF6D4C41),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFFFF8EE),
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
      },
    );
  }
}

/// Shown when the directory on screen came from the local cache.
///
/// Retry asks the server again. The banner stays up when that read fails and
/// the saved list is still the one on screen.
class SavedListBanner extends StatelessWidget {
  const SavedListBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const message = 'Offline, showing saved list';

  @override
  Widget build(BuildContext context) {
    if (!FirestoreReadLog.instance.showingSavedList) {
      return const SizedBox.shrink();
    }
    return Material(
      key: const Key('saved-list-banner'),
      color: const Color(0xFF6D4C41),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFFF8EE),
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
            TextButton(
              key: const Key('saved-list-retry'),
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFF8EE),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
