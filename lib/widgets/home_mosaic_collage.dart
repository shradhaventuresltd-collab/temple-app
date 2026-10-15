import 'package:flutter/material.dart';
import 'package:temple_app/widgets/cover_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/widgets/mosaic_tile_placeholder.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

/// Home hero subtitle for the directory size.
///
/// Uses the loaded temple list length — never a hardcoded 150/180.
String homeDirectoryCountLabel(int templeCount) {
  if (templeCount <= 0) {
    return 'No temples loaded yet';
  }
  return '$templeCount temples across India';
}

/// Drawer About blurb with a live directory size.
String drawerAboutDirectoryBlurb(int templeCount) {
  final lead = templeCount > 0
      ? 'Explore $templeCount famous temples across '
      : 'Explore famous temples across ';
  return '$lead'
      'Tamil Nadu, Kerala, Karnataka, '
      'Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, '
      'Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, '
      'Madhya Pradesh, Bihar, and Himachal Pradesh. '
      'Discover histories, legends, timings and specialities — '
      'all in one curated directory.';
}

/// Home mosaic collage that only shows verified temple photographs.
///
/// Picsum / placeholder hosts are dropped via [verifiedMosaicUrls]. When none
/// remain, tiles use [TempleImagePlaceholder] (Photo pending) instead of stock.
class HomeMosaicCollage extends StatelessWidget {
  const HomeMosaicCollage({super.key, required this.temples});

  final List<Temple> temples;

  static const Color deepSaffron = Color(0xFFE65100);

  /// Verified URLs only — same honesty as browse cards and detail.
  List<String> get verifiedImages => verifiedMosaicUrls(temples);

  @override
  Widget build(BuildContext context) {
    final images = verifiedImages;
    final captions = <String, String>{
      for (final temple in temples)
        for (final url in verifiedGalleryUrls(temple))
          if ((temple.coverCaption ??
                  historicalCoverCaption(temple.photos, url)) !=
              null)
            url:
                temple.coverCaption ??
                historicalCoverCaption(temple.photos, url)!,
    };
    final count = temples.length;

    return SizedBox(
      height: images.isEmpty ? 320 : 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const TempleImagePlaceholder(expand: true)
          else
            _MosaicGrid(images: images, captions: captions),
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
  const _MosaicGrid({required this.images, required this.captions});

  final List<String> images;
  final Map<String, String> captions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _MosaicTile(
                  url: images[0 % images.length],
                  caption: captions[images[0 % images.length]],
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _MosaicTile(
                        url: images[1 % images.length],
                        caption: captions[images[1 % images.length]],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _MosaicTile(
                        url: images[2 % images.length],
                        caption: captions[images[2 % images.length]],
                      ),
                    ),
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
                Expanded(
                  child: _MosaicTile(
                    url: images[i % images.length],
                    caption: captions[images[i % images.length]],
                  ),
                ),
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
                    Expanded(
                      child: _MosaicTile(
                        url: images[7 % images.length],
                        caption: captions[images[7 % images.length]],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _MosaicTile(
                        url: images[8 % images.length],
                        caption: captions[images[8 % images.length]],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: _MosaicTile(
                  url: images[9 % images.length],
                  caption: captions[images[9 % images.length]],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single mosaic cell. Placeholder hosts never reach here from
/// [HomeMosaicCollage]; defense-in-depth still refuses them.
class _MosaicTile extends StatelessWidget {
  const _MosaicTile({required this.url, this.caption});

  final String url;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    if (isPlaceholderImageUrl(url)) {
      return const MosaicTilePlaceholder();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CoverNetworkImage(
          url: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: const Duration(milliseconds: 400),
          placeholder: const MosaicTilePlaceholder(),
          error: const MosaicTilePlaceholder(),
        ),
        if (caption != null)
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  caption!,
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
          'Discover',
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
          "India's Sacred Temples",
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
          homeDirectoryCountLabel(templeCount),
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
