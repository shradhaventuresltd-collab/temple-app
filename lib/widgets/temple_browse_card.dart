import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

/// City and state line for a browse card. Omits a dangling comma.
String templeBrowsePlaceLabel(Temple temple) {
  final city = temple.city.trim();
  final state = temple.state.trim();
  if (city.isEmpty) return state;
  if (state.isEmpty) return city;
  return '$city, $state';
}

/// Browse card: cover, name, place, and deity chip.
///
/// Placeholder hosts (picsum, placehold, and the rest of
/// [isPlaceholderImageUrl]) render as [TempleImagePlaceholder] so stock
/// images are not presented as photographs.
class TempleBrowseCard extends StatelessWidget {
  const TempleBrowseCard({super.key, required this.temple, this.onTap});

  final Temple temple;
  final VoidCallback? onTap;

  static const Color saffron = Color(0xFFFF8F00);
  static const Color gold = Color(0xFFFFD54F);
  static const double coverHeight = 168;

  @override
  Widget build(BuildContext context) {
    final place = templeBrowsePlaceLabel(temple);
    final deity = temple.deity.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: gold),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              onTap ??
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TempleDetailScreen(temple: temple),
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrowseCover(temple: temple),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: saffron,
                        height: 1.25,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: Colors.brown.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.brown.shade600,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (deity.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _DeityChip(label: deity),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseCover extends StatelessWidget {
  const _BrowseCover({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    final urls = verifiedGalleryUrls(temple);
    if (urls.isEmpty) {
      return const TempleImagePlaceholder(height: TempleBrowseCard.coverHeight);
    }

    return CachedNetworkImage(
      imageUrl: urls.first,
      height: TempleBrowseCard.coverHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => const ColoredBox(
        color: Color(0xFFFFF8EE),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TempleBrowseCard.saffron,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          const TempleImagePlaceholder(height: TempleBrowseCard.coverHeight),
    );
  }
}

class _DeityChip extends StatelessWidget {
  const _DeityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TempleBrowseCard.gold),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D4C41),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
