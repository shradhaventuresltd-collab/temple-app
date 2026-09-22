import 'package:flutter/material.dart';

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

    final core = DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: Center(
        child: Padding(
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
                SizedBox(height: expand ? 14 : 8),
                Text(
                  'Photo pending',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D4037),
                    fontSize: expand ? 26 : 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No verified photograph is on file.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D4C41),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (expand) {
      return Semantics(
        label: 'Photo pending. No verified photograph is on file.',
        child: SizedBox.expand(child: core),
      );
    }

    return Semantics(
      label: 'Photo pending. No verified photograph is on file.',
      child: SizedBox(height: height, width: double.infinity, child: core),
    );
  }
}
