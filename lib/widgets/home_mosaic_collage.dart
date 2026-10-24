import 'package:flutter/material.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/widgets/cover_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/widgets/mosaic_tile_placeholder.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

/// Home hero subtitle for the directory size.
///
/// Uses the loaded temple list length — never a hardcoded 150/180.
String homeDirectoryCountLabel(int templeCount, [AppLocalizations? l10n]) {
  final copy = l10n ?? L10nLookup.english;
  if (templeCount <= 0) return copy.noTemplesLoadedYet;
  return copy.templesAcrossIndia(templeCount);
}

/// Drawer About blurb with a live directory size.
String drawerAboutDirectoryBlurb(int templeCount, [AppLocalizations? l10n]) {
  final copy = l10n ?? L10nLookup.english;
  if (templeCount <= 0) return copy.drawerAboutEmpty;
  return copy.drawerAboutWithCount(templeCount);
}

/// One mosaic cell's cover, resolved the same way as a browse card.
class _MosaicCover {
  const _MosaicCover({required this.url, this.fallbackUrl, this.caption});

  final String url;
  final String? fallbackUrl;
  final String? caption;
}

/// Covers for the home mosaic. Each temple contributes [verifiedCoverUrl]
/// and [storedFullCoverUrl], the same pair a browse card requests.
List<_MosaicCover> _mosaicCoversFor(Iterable<Temple> temples) {
  final covers = <_MosaicCover>[];
  for (final temple in temples) {
    final url = verifiedCoverUrl(temple);
    if (url == null) continue;
    final caption =
        temple.coverCaption ?? historicalCoverCaption(temple.photos, url);
    covers.add(
      _MosaicCover(
        url: url,
        fallbackUrl: storedFullCoverUrl(temple, url),
        caption: caption,
      ),
    );
  }
  return covers;
}

/// Home mosaic collage that only shows verified temple photographs.
///
/// Each tile uses the browse cover ([verifiedCoverUrl] plus
/// [storedFullCoverUrl]). Picsum and other placeholder hosts never bind.
/// When no cover remains, the hero is [TempleImagePlaceholder] (Photo pending).
class HomeMosaicCollage extends StatelessWidget {
  const HomeMosaicCollage({super.key, required this.temples});

  final List<Temple> temples;

  static const Color deepSaffron = Color(0xFFE65100);

  /// Browse covers only — one verified photograph per temple.
  List<String> get verifiedImages => [
    for (final cover in _mosaicCoversFor(temples)) cover.url,
  ];

  @override
  Widget build(BuildContext context) {
    final covers = _mosaicCoversFor(temples);
    final count = temples.length;

    return SizedBox(
      height: covers.isEmpty ? 320 : 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (covers.isEmpty)
            const TempleImagePlaceholder(expand: true)
          else
            _MosaicGrid(covers: covers),
          const _MosaicScrim(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: _MosaicCopy(templeCount: count),
          ),
        ],
      ),
    );
  }
}

class _MosaicGrid extends StatelessWidget {
  const _MosaicGrid({required this.covers});

  final List<_MosaicCover> covers;

  _MosaicCover _at(int index) => covers[index % covers.length];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(flex: 2, child: _MosaicTile(cover: _at(0))),
              const SizedBox(width: 2),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(child: _MosaicTile(cover: _at(1))),
                    const SizedBox(height: 2),
                    Expanded(child: _MosaicTile(cover: _at(2))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              for (int i = 3; i < 7; i++) ...[
                if (i > 3) const SizedBox(width: 2),
                Expanded(child: _MosaicTile(cover: _at(i))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(child: _MosaicTile(cover: _at(7))),
                    const SizedBox(height: 2),
                    Expanded(child: _MosaicTile(cover: _at(8))),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Expanded(flex: 2, child: _MosaicTile(cover: _at(9))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single mosaic cell. Placeholder hosts never reach here from
/// [HomeMosaicCollage]; defense-in-depth still refuses them.
///
/// The loaded photo uses a finite box, a fade-in placeholder, and
/// [CoverNetworkImage]'s error path (OctoImage `errorBuilder`). A miss
/// becomes Photo pending. The cell is never only the loading icon.
class _MosaicTile extends StatelessWidget {
  const _MosaicTile({required this.cover});

  final _MosaicCover cover;

  @override
  Widget build(BuildContext context) {
    final url = cover.url;
    if (isDisallowedImageUrl(url)) {
      return const TempleImagePlaceholder(expand: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
          return const TempleImagePlaceholder(expand: true);
        }
        final decode = listImageDecodeSize(
          logicalWidth: width,
          logicalHeight: height,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            CoverNetworkImage(
              url: url,
              fallbackUrl: cover.fallbackUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
              memCacheWidth: decode.width,
              memCacheHeight: decode.height,
              fadeInDuration: const Duration(milliseconds: 400),
              placeholder: const MosaicTilePlaceholder(),
              error: const TempleImagePlaceholder(expand: true),
            ),
            if (cover.caption != null)
              Positioned(
                left: 4,
                bottom: 4,
                child: DecoratedBox(
                  key: const Key('cover-caption'),
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFF8EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      cover.caption!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6D4C41),
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MosaicScrim extends StatelessWidget {
  const _MosaicScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              HomeMosaicCollage.deepSaffron.withAlpha(160),
              Colors.transparent,
              Colors.transparent,
              HomeMosaicCollage.deepSaffron.withAlpha(200),
            ],
          ),
        ),
      ),
    );
  }
}

class _MosaicCopy extends StatelessWidget {
  const _MosaicCopy({required this.templeCount});

  final int templeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.discover,
          style: GoogleFonts.lora(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black.withAlpha(120)),
            ],
          ),
        ),
        Text(
          context.l10n.indiasSacredTemples,
          style: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(235),
            height: 1.3,
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black.withAlpha(120)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          homeDirectoryCountLabel(templeCount, context.l10n),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black.withAlpha(100)),
            ],
          ),
        ),
      ],
    );
  }
}
