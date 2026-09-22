import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/detail_honesty.dart';
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
  const HomeMosaicCollage({
    super.key,
    required this.temples,
  });

  final List<Temple> temples;

  static const Color deepSaffron = Color(0xFFE65100);

  /// Verified URLs only — same honesty as browse cards and detail.
  List<String> get verifiedImages => verifiedMosaicUrls(temples);

  @override
  Widget build(BuildContext context) {
    final images = verifiedImages;
    final count = temples.length;

    return SizedBox(
      height: images.isEmpty ? 320 : 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const TempleImagePlaceholder(expand: true)
          else
            _MosaicGrid(images: images),
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
  const _MosaicGrid({required this.images});

  final List<String> images;

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
                child: _MosaicTile(url: images[0 % images.length]),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _MosaicTile(url: images[1 % images.length]),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _MosaicTile(url: images[2 % images.length]),
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
                  child: _MosaicTile(url: images[i % images.length]),
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
                      child: _MosaicTile(url: images[7 % images.length]),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _MosaicTile(url: images[8 % images.length]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: _MosaicTile(url: images[9 % images.length]),
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
  const _MosaicTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (isPlaceholderImageUrl(url)) {
      return const ColoredBox(
        color: Color(0xFFFFE0B2),
        child: Center(
          child: Icon(Icons.photo_outlined, color: Color(0xFF8D6E63), size: 28),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 400),
      placeholder: (context, url) =>
          ColoredBox(color: Colors.brown.shade100),
      errorWidget: (context, url, error) => ColoredBox(
        color: Colors.brown.shade200,
        child: const Icon(
          Icons.photo_outlined,
          color: Colors.white54,
          size: 28,
        ),
      ),
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
