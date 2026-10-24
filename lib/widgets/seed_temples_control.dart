import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/services/seed_service.dart';

/// Injectable seeder so widget tests do not need Firebase.
typedef SeedTemplesFn = Future<SeedResult> Function();

enum SeedPhase { idle, running, success, failure }

/// Seed control that runs [seedTempleData] with idle / running /
/// success / failure feedback. Hidden unless admin tools are enabled.
class SeedTemplesControl extends StatefulWidget {
  const SeedTemplesControl({
    super.key,
    this.compact = false,
    this.light = false,
    this.onSuccess,
    this.seed = seedTempleData,
    this.canWrite = true,
    this.unauthorizedMessage,
    this.onUnauthorized,
  });

  /// App-bar sized button (short label). Otherwise a full empty-state panel.
  final bool compact;

  /// White foreground for use on the saffron AppBar.
  final bool light;

  final VoidCallback? onSuccess;
  final SeedTemplesFn seed;

  /// When false, tapping Seed does not write; shows [unauthorizedMessage].
  final bool canWrite;

  /// When null, the localized [AppLocalizations.seedUnauthorized] string.
  final String? unauthorizedMessage;
  final VoidCallback? onUnauthorized;

  @override
  State<SeedTemplesControl> createState() => _SeedTemplesControlState();
}

class _SeedTemplesControlState extends State<SeedTemplesControl> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);

  SeedPhase _phase = SeedPhase.idle;
  String? _message;

  Future<void> _runSeed() async {
    if (_phase == SeedPhase.running) return;
    if (!widget.canWrite) {
      widget.onUnauthorized?.call();
      final blocked = _unauthorizedMessage;
      if (widget.compact) {
        _showSnackBar(blocked, isError: true);
      } else {
        setState(() {
          _phase = SeedPhase.failure;
          _message = blocked;
        });
      }
      return;
    }

    setState(() {
      _phase = SeedPhase.running;
      _message = context.l10n.seedingSampleTemples;
    });

    try {
      final result = await widget.seed();
      if (!mounted) return;
      final message = result.successMessageOf(context.l10n);
      setState(() {
        _phase = SeedPhase.success;
        _message = message;
      });
      widget.onSuccess?.call();
      _showSnackBar(message, isError: false);
    } catch (e) {
      if (!mounted) return;
      final error = _shortError(e, context.l10n);
      setState(() {
        _phase = SeedPhase.failure;
        _message = error;
      });
      _showSnackBar(error, isError: true);
    }
  }

  void _showSnackBar(String text, {required bool isError}) {
    if (!widget.compact) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: GoogleFonts.poppins()),
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String get _unauthorizedMessage =>
      widget.unauthorizedMessage ?? context.l10n.seedUnauthorized;

  static String _shortError(Object error, AppLocalizations l10n) {
    var text = error.toString().trim();
    const prefix = 'Exception: '; // l10n-allow: exception prefix, not copy
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length);
    }
    if (text.length > 180) {
      text = '${text.substring(0, 177)}…';
    }
    if (text.isEmpty) return l10n.seedingFailed;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (!kAdminToolsEnabled) return const SizedBox.shrink();
    return widget.compact ? _buildCompact() : _buildPanel();
  }

  Widget _buildCompact() {
    final fg = widget.light ? Colors.white : _deepSaffron;
    final running = _phase == SeedPhase.running;
    final blocked = !widget.canWrite;

    final l10n = context.l10n;
    return Tooltip(
      message: blocked ? _unauthorizedMessage : l10n.seedBundledTooltip,
      child: TextButton.icon(
        onPressed: running ? null : _runSeed,
        icon: running
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Icon(_compactIcon, color: fg, size: 20),
        label: Text(
          _compactLabel(l10n),
          style: GoogleFonts.poppins(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  IconData get _compactIcon {
    switch (_phase) {
      case SeedPhase.idle:
        return Icons.cloud_upload_rounded;
      case SeedPhase.running:
        return Icons.cloud_upload_rounded;
      case SeedPhase.success:
        return Icons.check_circle_rounded;
      case SeedPhase.failure:
        return Icons.error_outline_rounded;
    }
  }

  String _compactLabel(AppLocalizations l10n) {
    switch (_phase) {
      case SeedPhase.idle:
        return l10n.seed;
      case SeedPhase.running:
        return l10n.seeding;
      case SeedPhase.success:
        return l10n.seeded;
      case SeedPhase.failure:
        return l10n.retry;
    }
  }

  Widget _buildPanel() {
    if (!widget.canWrite) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 52, color: _saffron),
            const SizedBox(height: 14),
            Text(
              context.l10n.adminSignInRequiredToSeed,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _deepSaffron,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _unauthorizedMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.brown.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final running = _phase == SeedPhase.running;
    final failed = _phase == SeedPhase.failure;
    final succeeded = _phase == SeedPhase.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            succeeded ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
            size: 52,
            color: succeeded ? const Color(0xFF2E7D32) : _saffron,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noTemplesInFirestore,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _deepSaffron,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.seedPanelBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: running ? null : _runSeed,
            icon: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    failed ? Icons.refresh_rounded : Icons.cloud_upload_rounded,
                    size: 18,
                  ),
            label: Text(
              running
                  ? context.l10n.seedingEllipsis
                  : failed
                  ? context.l10n.retrySeed
                  : succeeded
                  ? context.l10n.seedAgain
                  : context.l10n.seedSampleTemples,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _saffron,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _saffron.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: failed
                    ? Colors.red.shade700
                    : succeeded
                    ? const Color(0xFF2E7D32)
                    : Colors.brown.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
