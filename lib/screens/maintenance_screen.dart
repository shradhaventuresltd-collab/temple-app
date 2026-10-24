import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';

/// Full-screen stop when Remote Config `kill_switch` is true.
///
/// This screen does not load temples. System back leaves the app.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, required this.message, this.onExit});

  /// Remote Config `maintenance_message`. Empty uses [fallbackMessage].
  final String message;

  final VoidCallback? onExit;

  static String get title => L10nLookup.english.maintenanceTitle;
  static String get fallbackMessage => L10nLookup.english.maintenanceFallback;

  static const Color saffron = Color(0xFFFF8F00);
  static const Color cream = Color(0xFFFFFBF2);
  static const Color navy = Color(0xFF0A2540);

  void _exit() {
    final exit = onExit;
    if (exit != null) {
      exit();
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final body = message.trim().isEmpty
        ? context.l10n.maintenanceFallback
        : message.trim();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exit();
      },
      child: Scaffold(
        key: const Key('maintenance-screen'),
        backgroundColor: cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.temple_hindu_rounded,
                  color: saffron,
                  size: 40,
                ),
                const Spacer(),
                Text(
                  context.l10n.maintenanceTitle,
                  style: GoogleFonts.lora(
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  key: const Key('maintenance-message'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.45,
                    color: const Color(0xFF6D4C41),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
