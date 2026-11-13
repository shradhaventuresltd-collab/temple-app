import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/widgets/place_type_icon.dart';

/// Warm tile shown while a collage photo loads and when that load fails.
///
/// A vector icon and a short gradient, not a bundled bitmap, so the APK does
/// not grow. Release and profile builds also sweep a highlight. Debug,
/// including widget tests, stays on the still frame so a repeating ticker
/// cannot block [WidgetTester.pumpAndSettle].
class MosaicTilePlaceholder extends StatelessWidget {
  const MosaicTilePlaceholder({super.key, this.animate, this.kind});

  /// Overrides the debug/release default. Tests pass true to cover the sweep.
  final bool? animate;

  /// Resolved tradition for this tile. Null keeps the Hindu outline.
  final PlaceTypeKind? kind;

  bool get _animate => animate ?? !kDebugMode;

  @override
  Widget build(BuildContext context) {
    final art = _TileArt(kind: kind);
    return Semantics(
      label: context.l10n.homeMosaicPlacePhotoLabel,
      child: SizedBox.expand(child: _animate ? _ShimmerTile(child: art) : art),
    );
  }
}

class _TileArt extends StatelessWidget {
  const _TileArt({this.kind});

  final PlaceTypeKind? kind;

  @override
  Widget build(BuildContext context) {
    final icon = kind == null || kind == PlaceTypeKind.hindu
        ? const Icon(
            Icons.temple_hindu_outlined,
            color: Color(0xFF8D6E63),
            size: 28,
          )
        : PlaceTypeIcon.forKind(
            kind: kind!,
            size: 28,
            color: const Color(0xFF8D6E63),
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE0B2), Color(0xFFFFF8EE), Color(0xFFFFCC80)],
        ),
      ),
      child: Center(child: icon),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile({required this.child});

  final Widget child;

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.4 + (2.8 * t), -0.2),
                      end: Alignment(-0.4 + (2.8 * t), 0.2),
                      colors: const [
                        Color(0x00FFFFFF),
                        Color(0x66FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
