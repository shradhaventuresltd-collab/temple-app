import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/widgets/seed_temples_control.dart';

/// Debug-only Home app-bar actions: Seed when the user is an admin,
/// otherwise a sign-in / not-admin control plus the Admin Panel button.
class DebugHomeAdminActions extends StatelessWidget {
  const DebugHomeAdminActions({
    super.key,
    required this.auth,
    required this.onOpenAdmin,
    this.onSeedSuccess,
    this.seed,
  });

  final AdminAuth auth;
  final VoidCallback onOpenAdmin;
  final VoidCallback? onSeedSuccess;
  final SeedTemplesFn? seed;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminSession>(
      stream: auth.session,
      initialData: AdminSession.signedOut,
      builder: (context, snapshot) {
        final session = snapshot.data ?? AdminSession.signedOut;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.isAdmin)
              SeedTemplesControl(
                compact: true,
                light: true,
                onSuccess: onSeedSuccess,
                seed: seed ?? seedTempleData,
              )
            else
              TextButton(
                key: const Key('home-admin-sign-in'),
                onPressed: onOpenAdmin,
                child: Text(
                  session.isSignedIn ? 'Not admin' : 'Admin sign-in',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Admin Panel',
              onPressed: onOpenAdmin,
            ),
          ],
        );
      },
    );
  }
}
