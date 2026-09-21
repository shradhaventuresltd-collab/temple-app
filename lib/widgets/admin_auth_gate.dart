import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/admin_auth.dart';

const Color _saffron = Color(0xFFFF8F00);
const Color _deepSaffron = Color(0xFFE65100);

/// Debug sign-in form for Seed/Admin writes. Production browse does not use this.
class AdminSignInPanel extends StatefulWidget {
  const AdminSignInPanel({super.key, required this.auth});

  final AdminAuth auth;

  @override
  State<AdminSignInPanel> createState() => _AdminSignInPanelState();
}

class _AdminSignInPanelState extends State<AdminSignInPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.auth.signInWithEmail(email: email, password: password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = adminSignInErrorMessage(e);
      });
      return;
    }

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminStatusCard(
      icon: Icons.lock_rounded,
      title: 'Admin sign-in required',
      body:
          'Temple data is publicly readable, but Seed and Admin writes need a '
          'signed-in account with the Firebase custom claim admin: true. '
          'Production browsing does not require signing in.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('admin-email-field'),
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Admin email',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('admin-password-field'),
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('admin-sign-in-error'),
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('admin-sign-in-button'),
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded, size: 18),
            label: Text(
              _busy ? 'Signing in…' : 'Sign in',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _saffron,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _saffron.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the user is signed in but the ID token lacks `admin: true`.
class AdminNotAuthorizedPanel extends StatelessWidget {
  const AdminNotAuthorizedPanel({
    super.key,
    required this.auth,
    required this.session,
  });

  final AdminAuth auth;
  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    final who = session.email ?? session.uid ?? 'this account';
    return _AdminStatusCard(
      icon: Icons.gpp_maybe_rounded,
      title: 'Signed in, but not an admin',
      body:
          'Signed in as $who. Writes are blocked until this user has the '
          'custom claim admin: true. Grant the claim with scripts/grant_admin.js, '
          'then refresh or sign out and back in.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('admin-refresh-claims-button'),
            onPressed: () => auth.refreshClaims(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Refresh admin status',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('admin-sign-out-button'),
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              'Sign out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusCard extends StatelessWidget {
  const _AdminStatusCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: _saffron),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _deepSaffron,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
