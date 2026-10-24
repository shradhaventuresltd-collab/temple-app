import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

/// English copy for the acceptance gate.
///
/// Frame A is [firstLaunchTitle]. Frame C is [updateTitle]. Wording matches
/// the Figma section for KAN-93. The screen itself reads
/// [AppLocalizationsBuildContext.l10n]; these getters stay on the English
/// bundle so the wording tests keep a single source.
abstract final class PolicyGateCopy {
  static final _en = L10nLookup.english;

  static String get acceptButton => _en.acceptAndContinue;
  static String get acceptHint => _en.acceptHint;
  static String get termsLabel => _en.termsOfService;
  static String get updateTermsLabel => _en.termsShort;
  static String get privacyLabel => _en.privacyPolicy;
  static String get linkHint => _en.opensInTheApp;
  static String get appName => _en.appName;

  static String get firstLaunchTitle => _en.beforeYouBegin;
  static String get firstLaunchLead => _en.policyFirstLaunchLead;
  static String get firstLaunchTail => _en.policyFirstLaunchTail;
  static String get firstLaunchBody =>
      '$firstLaunchLead$termsLabel${_en.policyAnd}$privacyLabel$firstLaunchTail';

  static String get updateTitle => _en.policyUpdatedTitle;
  static String get updateLead => _en.policyUpdateLead;
  static String get updateTail => _en.policyUpdateTail;
  static String get updateBody =>
      '$updateLead$updateTermsLabel${_en.policyAnd}$privacyLabel$updateTail';

  static String get saveFailed => _en.policySaveFailed;
  static String get linkFailed => _en.policyLinkFailed;
}

/// Colours for the gate.
///
/// The app theme is seeded from saffron and has no navy token. Figma uses a
/// navy header and a navy heading on the cream page, so this screen uses
/// [navy] for both instead of the deep-saffron title colour used elsewhere.
abstract final class PolicyGateColors {
  static const Color saffron = Color(0xFFFF8F00);
  static const Color cream = Color(0xFFFFFBF2);
  static const Color navy = Color(0xFF0A2540);
  static const Color body = Color(0xFF6D4C41);
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
  bool _saving = false;

  /// Set before [setState] so a second tap in the same frame cannot start
  /// another write or another navigation to Home.
  bool _acceptInFlight = false;

  bool get _update => widget.kind == PolicyGateKind.policyUpdate;

  Future<void> _accept() async {
    if (_acceptInFlight) return;
    _acceptInFlight = true;
    setState(() => _saving = true);
    try {
      await widget.onAccept();
    } catch (e, st) {
      _acceptInFlight = false;
      debugPrint('Policy acceptance failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.policySaveFailed)));
      setState(() => _saving = false);
    }
  }

  Future<void> _open(Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await widget.onOpenUrl(url);
    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.policyLinkFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _update ? l10n.policyUpdatedTitle : l10n.beforeYouBegin;
    final lead = _update ? l10n.policyUpdateLead : l10n.policyFirstLaunchLead;
    final tail = _update ? l10n.policyUpdateTail : l10n.policyFirstLaunchTail;
    final termsLabel = _update ? l10n.termsShort : l10n.termsOfService;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onExit();
      },
      child: Scaffold(
        key: const Key('policy-acceptance-gate'),
        backgroundColor: PolicyGateColors.cream,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: GoogleFonts.lora(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: PolicyGateColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.5,
                          color: PolicyGateColors.body,
                        ),
                        children: [
                          TextSpan(text: lead),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _InlinePolicyLink(
                              label: termsLabel,
                              semanticsId: 'policy-terms-link',
                              onPressed: _saving
                                  ? null
                                  : () => _open(PolicyConfig.termsOfServiceUri),
                            ),
                          ),
                          TextSpan(text: l10n.policyAnd),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _InlinePolicyLink(
                              label: l10n.privacyPolicy,
                              semanticsId: 'policy-privacy-link',
                              onPressed: _saving
                                  ? null
                                  : () => _open(PolicyConfig.privacyPolicyUri),
                            ),
                          ),
                          TextSpan(text: tail),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: _AcceptButton(saving: _saving, onPressed: _accept),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: PolicyGateColors.navy,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: PolicyGateColors.saffron,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.appName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: PolicyGateColors.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlinePolicyLink extends StatelessWidget {
  const _InlinePolicyLink({
    required this.label,
    required this.semanticsId,
    required this.onPressed,
  });

  final String label;
  final String semanticsId;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: PolicyGateColors.saffron,
      decoration: TextDecoration.underline,
      decorationColor: PolicyGateColors.saffron,
    );
    return Semantics(
      key: Key(semanticsId),
      identifier: semanticsId,
      button: true,
      link: true,
      label: label,
      hint: context.l10n.opensInTheApp,
      enabled: onPressed != null,
      child: ExcludeSemantics(
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: PolicyGateColors.saffron,
          ),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  static const Color _pressed = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final enabled = !saving;
    final activate = enabled ? onPressed : null;
    return Semantics(
      // Widget tests and the Maestro smoke flow both use this id.
      // onTap is the accessibility action only. The FilledButton below is
      // the pointer target, so the first tap is not spent focusing this node.
      // Both paths call the same idempotent callback.
      key: const Key('policy-accept-button'),
      identifier: 'policy-accept-button',
      button: true,
      label: context.l10n.acceptAndContinue,
      hint: context.l10n.acceptHint,
      enabled: enabled,
      onTap: activate,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: activate,
            style:
                FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  // InkSparkle (Material 3 on Android) can drop the first press
                  // and draw no splash. InkRipple plus a pressed fill keeps one
                  // tap visible.
                  splashFactory: InkRipple.splashFactory,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return PolicyGateColors.saffron.withAlpha(140);
                    }
                    if (states.contains(WidgetState.pressed)) return _pressed;
                    return PolicyGateColors.saffron;
                  }),
                  overlayColor: const WidgetStatePropertyAll(Color(0x52FFFFFF)),
                ),
            child: saving
                ? const SizedBox(
                    key: Key('policy-accept-progress'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(context.l10n.acceptAndContinue),
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

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Scaffold(
      backgroundColor: PolicyGateColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.temple_hindu_rounded,
                size: 48,
                color: PolicyGateColors.saffron,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PolicyGateColors.body,
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
