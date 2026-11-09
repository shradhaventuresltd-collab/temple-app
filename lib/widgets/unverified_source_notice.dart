import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail-page colour tokens from the Ux filters-redesign spec (SPEC.md
/// section 6, KAN-197 / KAN-198). Picked by [ThemeData.brightness].
///
/// Local to the detail page for now. KAN-198 (filters redesign) is adding
/// the shared token set in the filter files; reconcile at rebase.
@immutable
class DetailUxTokens {
  const DetailUxTokens._({
    required this.surface,
    required this.divider,
    required this.text,
    required this.muted,
    required this.accent,
    required this.cautionBg,
    required this.cautionBorder,
    required this.cautionIcon,
  });

  static const light = DetailUxTokens._(
    surface: Color(0xFFFFFFFF),
    divider: Color(0xFFEFE3CF),
    text: Color(0xFF3E2723),
    muted: Color(0xFF8D6E63),
    // Ux (KAN-197 answers, Nov 9): #B23C00 is 5.43:1 on cautionBg. The
    // spec's original #E65100 was 3.47:1.
    accent: Color(0xFFB23C00),
    cautionBg: Color(0xFFFFF4DC),
    cautionBorder: Color(0xFFF2B544),
    cautionIcon: Color(0xFFB26A00),
  );

  static const dark = DetailUxTokens._(
    surface: Color(0xFF2B1F1B),
    divider: Color(0xFF3A2A24),
    text: Color(0xFFF6EADB),
    muted: Color(0xFFA99079),
    accent: Color(0xFFFFB74D),
    cautionBg: Color(0xFF3A2A0E),
    cautionBorder: Color(0xFFFFCA6B),
    cautionIcon: Color(0xFFFFCA6B),
  );

  static DetailUxTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final Color surface;
  final Color divider;
  final Color text;
  final Color muted;

  /// Links ("View source", "Show more").
  final Color accent;
  final Color cautionBg;
  final Color cautionBorder;
  final Color cautionIcon;
}

/// Shared "Unverified, check before visiting" caution block (KAN-197 AC2).
/// Used by the timings card and the dress-code card.
///
/// [id] prefixes the Key and Semantics identifier of the block
/// (`<id>-unverified-chip`) and of the link (`<id>-source-link`).
/// Line 2 is [lead] followed by a "View source" link to [sourceUri]; with no
/// [sourceUri] it is [noLinkText]. [subject] starts the screen-reader label.
///
/// The link opens [sourceUri] in an external app. A second tap while the
/// first launch is pending is ignored.
class UnverifiedSourceNotice extends StatefulWidget {
  const UnverifiedSourceNotice({
    super.key,
    required this.id,
    required this.subject,
    required this.lead,
    required this.noLinkText,
    this.sourceUri,
  });

  final String id;
  final String subject;
  final String lead;
  final String noLinkText;
  final Uri? sourceUri;

  static const title = 'Unverified, check before visiting';
  static const linkText = 'View source';
  static const launchFailedText = "Couldn't open the source link.";

  @override
  State<UnverifiedSourceNotice> createState() => _UnverifiedSourceNoticeState();
}

class _UnverifiedSourceNoticeState extends State<UnverifiedSourceNotice> {
  bool _opening = false;

  Future<void> _openSource() async {
    final uri = widget.sourceUri;
    if (uri == null || _opening) return;
    _opening = true;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      opened = false;
    } finally {
      _opening = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(UnverifiedSourceNotice.launchFailedText),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DetailUxTokens.of(context);
    final base = GoogleFonts.poppins(
      fontSize: 13,
      height: 1.4,
      color: tokens.text,
    );
    final hasLink = widget.sourceUri != null;
    final subject = widget.subject;
    final label = hasLink
        ? '$subject unverified. Check before visiting. View source, opens browser.'
        : '$subject unverified. Check before visiting. ${widget.noLinkText}';
    final chipId = '${widget.id}-unverified-chip';
    final linkId = '${widget.id}-source-link';

    return Semantics(
      key: Key(chipId),
      identifier: chipId,
      container: true,
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: tokens.cautionBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.cautionBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              key: Key('${widget.id}-unverified-icon'),
              size: 18,
              color: tokens.cautionIcon,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      UnverifiedSourceNotice.title,
                      style: base.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!hasLink)
                    ExcludeSemantics(
                      child: Text(widget.noLinkText, style: base),
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: Text('${widget.lead} ', style: base),
                        ),
                        Semantics(
                          identifier: linkId,
                          button: true,
                          link: true,
                          label: 'View source, opens browser',
                          onTap: _openSource,
                          excludeSemantics: true,
                          child: InkWell(
                            key: Key(linkId),
                            onTap: _openSource,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 48,
                                minWidth: 48,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      UnverifiedSourceNotice.linkText,
                                      style: base.copyWith(
                                        color: tokens.accent,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: tokens.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
