import 'package:flutter/material.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/l10n/display_labels.dart';
import 'package:temple_app/widgets/cover_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/place_type_icon.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

/// City and state line for a browse card. Omits a dangling comma.
String templeBrowsePlaceLabel(Temple temple, {AppLocalizations? l10n}) {
  final strings = l10n ?? L10nLookup.english;
  final city = temple.city.trim();
  final state = temple.state.trim();
  if (city.isEmpty && state.isEmpty) return '';
  if (city.isEmpty) return stateDisplayLabel(strings, state);
  if (state.isEmpty) return city;
  return strings.templeBrowsePlaceLabel(city, stateDisplayLabel(strings, state));
}

/// Labels that keep a browse card from reading as living Hindu darshan.
///
/// Hindu-first cards stay name, place, and deity. Jain, Buddhist, and Sikh
/// sites add [DetailHonesty.traditionLabel]. Monument / ASI sites add
/// [DetailHonesty.framingLabel] only when that label is a heritage visit.
/// "Living temple" is not repeated on the card.
List<String> templeBrowseHonestyLabels(
  Temple temple, {
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? L10nLookup.english;
  final honesty = DetailHonesty.of(temple);
  return [
    if (honesty.traditionLabelOf(strings) != null)
      honesty.traditionLabelOf(strings)!,
    if (honesty.framing == SiteFraming.monumentVisit &&
        honesty.framingLabelOf(strings) != null)
      honesty.framingLabelOf(strings)!,
  ];
}

/// Browse card: cover, name, place, and deity chip.
///
/// Cover uses [verifiedCoverUrl] — the same honesty as the detail hero.
/// Placeholder hosts and unlicensed stock hosts ([isDisallowedImageUrl])
/// render as [TempleImagePlaceholder] so those URLs are not presented as
/// photographs. Outlier sites also show the
/// honesty chip from [templeBrowseHonestyLabels]. Story, gallery, and
/// timings stay off the card.
class TempleBrowseCard extends StatelessWidget {
  const TempleBrowseCard({super.key, required this.temple, this.onTap});

  final Temple temple;
  final VoidCallback? onTap;

  static const Color saffron = Color(0xFFFF8F00);
  static const Color gold = Color(0xFFFFD54F);
  static const double coverHeight = 168;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final place = templeBrowsePlaceLabel(temple, l10n: strings);
    final deity = temple.deity.trim();
    final honestyLabels = templeBrowseHonestyLabels(temple, l10n: strings);

    return Semantics(
      identifier: 'temple-browse-card',
      child: DecoratedBox(
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
                  namedAnalyticsRoute<void>(
                    name: AnalyticsScreens.templeDetail,
                    arguments: temple.id,
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
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          temple.name,
                          key: const Key('browse-temple-name'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: saffron,
                            height: 1.25,
                          ),
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
                                key: const Key('browse-temple-place'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
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
                      if (deity.isNotEmpty || honestyLabels.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final traditionKey = listedTempleTraditionLabel(temple);
                            final traditionLabel = switch (traditionKey) {
                              'Jain' => // l10n-allow: canonical tradition key
                                strings.traditionJain,
                              'Buddhist' => // l10n-allow: canonical tradition key
                                strings.traditionBuddhist,
                              'Sikh' => // l10n-allow: canonical tradition key
                                strings.traditionSikh,
                              _ => null,
                            };
                            Widget chip(
                              String label, {
                              Color? background,
                              Widget? leading,
                            }) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: _BrowseChip(
                                  label: label,
                                  background:
                                      background ?? const Color(0xFFFFF9E3),
                                  leading: leading,
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (deity.isNotEmpty) chip(deity),
                                for (final label in honestyLabels)
                                  chip(
                                    label,
                                    background:
                                        label ==
                                            strings.templeDetailHeritageVisitLabel
                                        ? const Color(0xFFFFF3D8)
                                        : const Color(0xFFFFF9E3),
                                    leading: label == traditionLabel
                                        ? PlaceTypeIcon(
                                            key: const Key(
                                              'browse-place-type-icon',
                                            ),
                                            temple: temple,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
    // Same honesty as detail hero: never bind picsum / placeholder hosts.
    final coverUrl = verifiedCoverUrl(temple);
    if (coverUrl == null) {
      return const TempleImagePlaceholder(height: TempleBrowseCard.coverHeight);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final decode = listImageDecodeSize(
          logicalWidth: width,
          logicalHeight: TempleBrowseCard.coverHeight,
          devicePixelRatio: dpr,
        );
        final caption =
            temple.coverCaption ??
            historicalCoverCaption(temple.photos, coverUrl);
        return Stack(
          children: [
            CoverNetworkImage(
              url: coverUrl,
              fallbackUrl: storedFullCoverUrl(temple, coverUrl),
              height: TempleBrowseCard.coverHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: decode.width,
              memCacheHeight: decode.height,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: const ColoredBox(
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
              error: const TempleImagePlaceholder(
                height: TempleBrowseCard.coverHeight,
              ),
            ),
            if (caption != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: _CoverCaptionChip(label: caption),
              ),
          ],
        );
      },
    );
  }
}

class _CoverCaptionChip extends StatelessWidget {
  const _CoverCaptionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('cover-caption'),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TempleBrowseCard.gold),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6D4C41),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({
    required this.label,
    this.background = const Color(0xFFFFF9E3),
    this.leading,
  });

  final String label;
  final Color background;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TempleBrowseCard.gold),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D4C41),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
