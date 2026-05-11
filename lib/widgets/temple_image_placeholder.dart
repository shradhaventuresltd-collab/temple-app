import 'package:flutter/material.dart';

/// Shown when [Temple.imageUrl] is empty or when a network image fails to load.
class TempleImagePlaceholder extends StatelessWidget {
  const TempleImagePlaceholder({
    super.key,
    this.height = 180,
    this.expand = false,
  });

  /// Fixed height for list cards; ignored when [expand] is true.
  final double height;

  /// When true, fills parent (e.g. [SliverAppBar] flexible space).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFE0B2),
        Color(0xFFFFB74D),
        Color(0xFFFF8F00),
      ],
    );

    final iconSize = expand ? 88.0 : height * 0.32;

    final core = DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: Center(
        child: Icon(
          Icons.account_balance_rounded,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );

    if (expand) {
      return SizedBox.expand(child: core);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: core,
    );
  }
}
