import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/services/seed_service.dart';

/// Injectable seeder so widget tests do not need Firebase.
typedef SeedTemplesFn = Future<SeedResult> Function();

enum SeedPhase { idle, running, success, failure }

/// Debug-only control that runs [seedTempleData] with idle / running /
/// success / failure feedback. Hidden in release/profile builds.
class SeedTemplesControl extends StatefulWidget {
  const SeedTemplesControl({
    super.key,
    this.compact = false,
    this.light = false,
    this.onSuccess,
    this.seed = seedTempleData,
    this.canWrite = true,
    this.unauthorizedMessage =
        'Sign in as an admin (custom claim admin: true) to seed Firestore.',
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

  final String unauthorizedMessage;
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
      if (widget.compact) {
        _showSnackBar(widget.unauthorizedMessage, isError: true);
      } else {
        setState(() {
          _phase = SeedPhase.failure;
          _message = widget.unauthorizedMessage;
        });
      }
      return;
    }

    setState(() {
      _phase = SeedPhase.running;
      _message = 'Seeding sample temples…';
    });

    try {
      final result = await widget.seed();
      if (!mounted) return;
      setState(() {
        _phase = SeedPhase.success;
        _message = result.successMessage;
      });
      widget.onSuccess?.call();
      _showSnackBar(result.successMessage, isError: false);
    } catch (e) {
      if (!mounted) return;
      final error = _shortError(e);
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
          backgroundColor:
              isError ? Colors.red.shade700 : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static String _shortError(Object error) {
    var text = error.toString().trim();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length);
    }
    if (text.length > 180) {
      text = '${text.substring(0, 177)}…';
    }
    if (text.isEmpty) return 'Seeding failed.';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return widget.compact ? _buildCompact() : _buildPanel();
  }

  Widget _buildCompact() {
    final fg = widget.light ? Colors.white : _deepSaffron;
    final running = _phase == SeedPhase.running;
    final blocked = !widget.canWrite;

    return Tooltip(
      message: blocked
          ? widget.unauthorizedMessage
          : 'Seed bundled sample temples into Firestore',
      child: TextButton.icon(
        onPressed: running ? null : _runSeed,
        icon: running
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : Icon(_compactIcon, color: fg, size: 20),
        label: Text(
          _compactLabel,
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

  String get _compactLabel {
    switch (_phase) {
      case SeedPhase.idle:
        return 'Seed';
      case SeedPhase.running:
        return 'Seeding';
      case SeedPhase.success:
        return 'Seeded';
      case SeedPhase.failure:
        return 'Retry';
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
              'Admin sign-in required to seed',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _deepSaffron,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.unauthorizedMessage,
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
            succeeded
                ? Icons.check_circle_rounded
                : Icons.cloud_upload_rounded,
            size: 52,
            color: succeeded ? const Color(0xFF2E7D32) : _saffron,
          ),
          const SizedBox(height: 14),
          Text(
            'No temples in Firestore',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _deepSaffron,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seed the bundled sample temples to populate the Admin list. '
            'Re-running is safe — each temple uses a stable document ID, '
            'so you will not get duplicates.',
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
                    failed
                        ? Icons.refresh_rounded
                        : Icons.cloud_upload_rounded,
                    size: 18,
                  ),
            label: Text(
              running
                  ? 'Seeding…'
                  : failed
                      ? 'Retry seed'
                      : succeeded
                          ? 'Seed again'
                          : 'Seed sample temples',
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
