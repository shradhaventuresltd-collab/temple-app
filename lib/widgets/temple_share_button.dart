import 'package:flutter/material.dart';
import 'package:temple_app/l10n/share_strings.dart';

/// Share action on the detail photo header.
///
/// Placeholder styling until Ux's spec lands: it matches the round
/// back/menu/home buttons beside it. Restyle here only; the detail screen
/// just places it and passes [onPressed].
class TempleShareButton extends StatelessWidget {
  const TempleShareButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const double size = 38;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'detail-share-button',
      label: ShareStrings.templeDetailShareButtonLabel,
      button: true,
      excludeSemantics: true,
      child: IconButton(
        key: const Key('detail-share-button'),
        tooltip: ShareStrings.templeDetailShareTooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.share),
        iconSize: 22,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black45,
          foregroundColor: Colors.white,
          fixedSize: const Size.square(size),
          minimumSize: const Size.square(size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
