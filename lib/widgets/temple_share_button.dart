import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/share_strings.dart';

/// Share button in the detail page's How to Reach card (Ux SHARE-SPEC.md).
///
/// Secondary to Get Directions: full width, outlined, 50 dp tall, radius
/// 12, #E65100 border/icon/label on white, 1.5 dp border, Poppins 15 w600,
/// 8% pressed overlay. A generic outline share glyph, never the WhatsApp
/// logo. Dark tokens apply only if a dark theme ships.
class TempleShareButton extends StatelessWidget {
  const TempleShareButton({
    super.key,
    required this.onPressed,
    this.whatsApp = false,
  });

  final VoidCallback onPressed;

  /// "Share on WhatsApp" instead of "Share".
  final bool whatsApp;

  static const Color accent = Color(0xFFE65100);
  static const Color fill = Colors.white;
  static const Color darkAccent = Color(0xFFFFB74D);
  static const Color darkFill = Color(0xFF1C1410);
  static const double minHeight = 50;

  String get label => whatsApp
      ? ShareStrings.templeDetailShareOnWhatsAppLabel
      : ShareStrings.templeDetailShareButtonLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? darkAccent : accent;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        identifier: 'detail-share-button',
        label: label,
        hint: ShareStrings.templeDetailShareTooltip,
        button: true,
        enabled: true,
        focusable: true,
        onTap: onPressed,
        excludeSemantics: true,
        child: Tooltip(
          message: ShareStrings.templeDetailShareTooltip,
          excludeFromSemantics: true,
          child: OutlinedButton.icon(
            key: const Key('detail-share-button'),
            onPressed: onPressed,
            icon: Icon(Icons.share_outlined, color: color, size: 22),
            label: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style:
                OutlinedButton.styleFrom(
                  backgroundColor: dark ? darkFill : fill,
                  foregroundColor: color,
                  minimumSize: const Size.fromHeight(minHeight),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  side: BorderSide(color: color, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ).copyWith(
                  // styleFrom's overlayColor uses 10% when pressed; Ux wants 8%.
                  overlayColor: WidgetStatePropertyAll(
                    color.withValues(alpha: 0.08),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
