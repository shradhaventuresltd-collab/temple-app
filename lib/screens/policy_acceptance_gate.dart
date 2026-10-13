import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

/// Copy for the acceptance gate.
///
/// Frame A is [firstLaunchTitle]. Frame C is [updateTitle]. Figma for these
/// frames could not be opened, so the layout follows the app's Material theme.
abstract final class PolicyGateCopy {
  static const String acceptButton = 'Accept & continue';
  static const String acceptHint =
      'Agrees to the Terms of Service and Privacy Policy';
  static const String termsLabel = 'Terms of Service';
  static const String privacyLabel = 'Privacy Policy';
  static const String linkHint = 'Opens in the browser';
  static const String firstLaunchEyebrow = 'Terms and privacy';
  static const String firstLaunchTitle = 'Before you continue';
  static const String firstLaunchBody =
      'Temple Directory India lists temples, timings, and directions. '
      'Accept the Terms of Service and the Privacy Policy to continue. '
      'The Terms state that the app is for people aged 13 and older.';
  static const String updateEyebrow = 'Policy update';
  static const String updateTitle = 'Policies updated';
  static const String updateBody =
      'We updated the Terms of Service and the Privacy Policy. '
      'Review them, then accept to keep using Temple Directory India.';
  static const String saveFailed =
      'Could not save your acceptance on this device. Please try again.';
  static const String linkFailed = 'Could not open that link.';
}

/// Full-screen Terms and Privacy gate. Accept is the only action.
///
/// System back calls [onExit] and does not reveal Home.
class PolicyAcceptanceGate extends StatefulWidget {
  const PolicyAcceptanceGate({
    super.key,
    required this.kind,
    required this.onAccept,
    required this.onOpenUrl,
    required this.onExit,
  });

  final PolicyGateKind kind;
  final Future<void> Function() onAccept;
  final Future<bool> Function(Uri url) onOpenUrl;
  final VoidCallback onExit;

  @override
  State<PolicyAcceptanceGate> createState() => _PolicyAcceptanceGateState();
}

class _PolicyAcceptanceGateState extends State<PolicyAcceptanceGate> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _cream = Color(0xFFFFFBF2);
  static const Color _card = Color(0xFFFFF8EE);

  bool _saving = false;

  bool get _update => widget.kind == PolicyGateKind.policyUpdate;

  Future<void> _accept() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onAccept();
    } catch (e, st) {
      debugPrint('Policy acceptance failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(PolicyGateCopy.saveFailed)));
      setState(() => _saving = false);
    }
  }

  Future<void> _open(Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await widget.onOpenUrl(url);
    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(PolicyGateCopy.linkFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _update
        ? PolicyGateCopy.updateTitle
        : PolicyGateCopy.firstLaunchTitle;
    final eyebrow = _update
        ? PolicyGateCopy.updateEyebrow
        : PolicyGateCopy.firstLaunchEyebrow;
    final body = _update
        ? PolicyGateCopy.updateBody
        : PolicyGateCopy.firstLaunchBody;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onExit();
      },
      child: Scaffold(
        key: const Key('policy-acceptance-gate'),
        backgroundColor: _cream,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 36)
                        .clamp(0, double.infinity)
                        .toDouble(),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _TempleMark(),
                        const SizedBox(height: 20),
                        Text(
                          eyebrow,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: _saffron,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: _deepSaffron,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _gold),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                _PolicyLink(
                                  label: PolicyGateCopy.termsLabel,
                                  semanticsId: 'policy-terms-link',
                                  onPressed: _saving
                                      ? null
                                      : () => _open(
                                          PolicyConfig.termsOfServiceUri,
                                        ),
                                ),
                                Divider(height: 1, color: _gold.withAlpha(180)),
                                _PolicyLink(
                                  label: PolicyGateCopy.privacyLabel,
                                  semanticsId: 'policy-privacy-link',
                                  onPressed: _saving
                                      ? null
                                      : () => _open(
                                          PolicyConfig.privacyPolicyUri,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _AcceptButton(saving: _saving, onPressed: _accept),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TempleMark extends StatelessWidget {
  const _TempleMark();

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _saffron,
          shape: BoxShape.circle,
          border: Border.all(color: _gold, width: 3),
        ),
        child: const Icon(
          Icons.temple_hindu_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({
    required this.label,
    required this.semanticsId,
    required this.onPressed,
  });

  final String label;
  final String semanticsId;
  final VoidCallback? onPressed;

  static const Color _deepSaffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key(semanticsId),
      identifier: semanticsId,
      button: true,
      link: true,
      label: label,
      hint: PolicyGateCopy.linkHint,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              foregroundColor: _deepSaffron,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _deepSaffron,
                    ),
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  static const Color _saffron = Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Widget tests and the Maestro smoke flow both use this id.
      key: const Key('policy-accept-button'),
      identifier: 'policy-accept-button',
      button: true,
      label: PolicyGateCopy.acceptButton,
      hint: PolicyGateCopy.acceptHint,
      enabled: !saving,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: _saffron,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _saffron.withAlpha(140),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text(PolicyGateCopy.acceptButton),
          ),
        ),
      ),
    );
  }
}

/// Cream hold between the native splash and the next step.
///
/// No ad or Home copy here, so a slow read of local acceptance cannot be
/// mistaken for Home.
class PolicyStartupHold extends StatelessWidget {
  const PolicyStartupHold({super.key, this.message});

  final String? message;

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Scaffold(
      backgroundColor: _cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.temple_hindu_rounded, size: 48, color: _saffron),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
