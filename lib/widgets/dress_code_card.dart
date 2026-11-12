import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/place_sources.dart';
import 'package:temple_app/widgets/source_attribution_footer.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';

/// Visible dress-code footer line for [temple] (KAN-203 §2.5).
String dressCodeSourceFooter(Temple temple) =>
    placeSourceFooterLayout(dressCodeSourcesOf(temple)).text;

/// KAN-197 dress-code card on the temple detail page (Ux SPEC.md section 8).
///
/// Shown only when [Temple.hasDressCode]. An unverified dress code gets the
/// shared [UnverifiedSourceNotice]. The body shows at most
/// [collapsedMaxLines] lines, then "Show more".
class DressCodeCard extends StatefulWidget {
  const DressCodeCard({super.key, required this.temple});

  final Temple temple;

  static const collapsedMaxLines = 6;

  @override
  State<DressCodeCard> createState() => _DressCodeCardState();
}

class _DressCodeCardState extends State<DressCodeCard> {
  var _expanded = false;

  @override
  void didUpdateWidget(DressCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temple.dressCode != widget.temple.dressCode) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final temple = widget.temple;
    final tokens = DetailUxTokens.of(context);
    final text = temple.dressCode?.trim() ?? '';
    final bodyStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: tokens.text,
    );

    return Semantics(
      identifier: 'detail-dress-code',
      container: true,
      child: Container(
        key: const Key('detail-dress-code'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Dress code',
                key: const Key('detail-dress-code-heading'),
                style: GoogleFonts.lora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: tokens.text,
                ),
              ),
            ),
            if (temple.dressCodeUnverified) ...[
              const SizedBox(height: 12),
              UnverifiedSourceNotice(
                id: 'dress-code',
                subject: 'Dress code',
                lead: 'Rules may have changed.',
                noLinkText: 'Confirm with the place.',
                sourceUri: temple.dressCodeSourceUri,
              ),
            ],
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: bodyStyle),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: DressCodeCard.collapsedMaxLines,
                )..layout(maxWidth: constraints.maxWidth);
                final overflows = painter.didExceedMaxLines;
                painter.dispose();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      key: const Key('detail-dress-code-body'),
                      style: bodyStyle,
                      maxLines: _expanded || !overflows
                          ? null
                          : DressCodeCard.collapsedMaxLines,
                      overflow: _expanded || !overflows
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (overflows)
                      Semantics(
                        identifier: 'detail-dress-code-more',
                        button: true,
                        child: InkWell(
                          key: const Key('detail-dress-code-more'),
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 48,
                              minWidth: 48,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1,
                              child: Text(
                                _expanded ? 'Show less' : 'Show more',
                                style: bodyStyle.copyWith(
                                  color: tokens.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SourceAttributionFooter(sources: dressCodeSourcesOf(temple)),
          ],
        ),
      ),
    );
  }
}
