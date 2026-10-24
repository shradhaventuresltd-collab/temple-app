import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/services/app_update.dart';

/// Full-screen block when the installed build is below `min_supported_build`.
///
/// The only forward action opens the Play listing. System back leaves the app.
class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({
    super.key,
    required this.packageName,
    required this.launch,
    this.onExit,
  });

  final String packageName;
  final Future<bool> Function(Uri url) launch;
  final VoidCallback? onExit;

  static String get title => L10nLookup.english.forceUpdateTitle;
  static String get body => L10nLookup.english.forceUpdateBody;
  static String get buttonLabel => L10nLookup.english.forceUpdateButton;

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);
  static const Color _navy = Color(0xFF0A2540);

  bool _opening = false;

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() => _opening = true);
    final opened = await openPlayStoreListing(
      packageName: widget.packageName,
      launch: widget.launch,
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenPlayStore)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onExit?.call();
      },
      child: Scaffold(
        key: const Key('force-update-screen'),
        backgroundColor: _cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.temple_hindu_rounded,
                  color: _saffron,
                  size: 40,
                ),
                const Spacer(),
                Text(
                  context.l10n.forceUpdateTitle,
                  style: GoogleFonts.lora(
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.forceUpdateBody,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.45,
                    color: const Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('force-update-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _saffron,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _opening ? null : _openStore,
                    child: Text(context.l10n.forceUpdateButton),
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
