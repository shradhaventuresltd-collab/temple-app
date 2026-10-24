import 'package:flutter/material.dart';
import 'package:temple_app/l10n/app_locale.dart';

/// Shown when a temple has no verified photograph.
///
/// Empty galleries, placeholder hosts such as picsum, and failed loads all
/// use this state so the screen never presents stock art as a real photo.
class TempleImagePlaceholder extends StatelessWidget {
  const TempleImagePlaceholder({
    super.key,
    this.height = 180,
    this.expand = false,
  });

  /// Fixed height for compact slots; ignored when [expand] is true.
  final double height;

  /// When true, fills the parent (detail hero).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8EE), Color(0xFFFFE0B2)],
    );

    final showCaption = expand || height >= 120;
    final iconSize = expand ? 72.0 : height * 0.28;
    final column = _PendingColumn(
      showCaption: showCaption,
      iconSize: iconSize,
      large: expand,
    );

    final Widget core;
    if (expand) {
      // Mosaic cells are much shorter than the detail hero. Scale the same
      // caption down instead of overflowing into a blank tile.
      core = DecoratedBox(
        decoration: const BoxDecoration(gradient: gradient),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: 280, child: column),
          ),
        ),
      );
    } else {
      core = DecoratedBox(
        decoration: const BoxDecoration(gradient: gradient),
        child: Center(child: column),
      );
    }

    return Semantics(
      label: context.l10n.photoPendingSemantics,
      child: expand
          ? SizedBox.expand(child: core)
          : SizedBox(height: height, width: double.infinity, child: core),
    );
  }
}

class _PendingColumn extends StatelessWidget {
  const _PendingColumn({
    required this.showCaption,
    required this.iconSize,
    required this.large,
  });

  final bool showCaption;
  final double iconSize;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_outlined,
            size: iconSize,
            color: const Color(0xFF8D6E63),
          ),
          if (showCaption) ...[
            SizedBox(height: large ? 14 : 8),
            Text(
              context.l10n.photoPending,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5D4037),
                fontSize: large ? 26 : 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.noVerifiedPhotograph,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6D4C41),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
