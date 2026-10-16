import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/offline_link.dart';
import 'package:temple_app/services/temple_service.dart';

/// Shown while the device has no network. The directory already on screen
/// stays; Firestore persistence and the cache-first index are what keep
/// temples available. The banner clears when a network returns.
///
/// [savedTempleCount] is how many temples are actually on screen from cache.
/// The "saved on this device" line is only true when that count is above
/// zero. With nothing cached, the banner says the device is offline and the
/// screen underneath can offer Retry.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.savedTempleCount = 0});

  final int savedTempleCount;

  static const offlineMessage = "You're offline";

  static const message =
      "You're offline. Showing temples saved on this device.";

  static String textFor(int savedTempleCount) =>
      savedTempleCount > 0 ? message : offlineMessage;

  @override
  Widget build(BuildContext context) {
    final text = textFor(savedTempleCount);
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
                    text,
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
/// State comes from [TempleService.savedListPhase] and [DirectoryLink.offline].
/// A warm launch that is still refreshing stays quiet while the device is
/// online. The word Offline appears only when the device is offline. Retry
/// asks the server again. The banner stays up when that read fails and the
/// saved list is still the one on screen.
class SavedListBanner extends StatelessWidget {
  const SavedListBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const offlineMessage = 'Offline, showing saved list';
  static const savedMessage = 'Showing saved list';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SavedListPhase>(
      valueListenable: TempleService.savedListPhase,
      builder: (context, phase, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: DirectoryLink.offline,
          builder: (context, offline, _) {
            if (phase == SavedListPhase.hidden) {
              return const SizedBox.shrink();
            }
            if (phase == SavedListPhase.refreshing && !offline) {
              return const SizedBox.shrink();
            }
            return Material(
              key: const Key('saved-list-banner'),
              color: const Color(0xFF6D4C41),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                        offline ? offlineMessage : savedMessage,
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
          },
        );
      },
    );
  }
}
