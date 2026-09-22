import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';

class TempleDetailScreen extends StatelessWidget {
  const TempleDetailScreen({super.key, required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      drawer: const AppDrawer(),
      body: TempleDetailBody(temple: temple),
    );
  }
}

/// Scrollable detail content. Separated so honesty UI can be tested without
/// opening the shared drawer (which reads Firestore).
class TempleDetailBody extends StatefulWidget {
  const TempleDetailBody({super.key, required this.temple});

  final Temple temple;

  @override
  State<TempleDetailBody> createState() => _TempleDetailBodyState();
}

class _TempleDetailBodyState extends State<TempleDetailBody> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);
  static const _autoAdvanceInterval = Duration(seconds: 5);
  static const double _imageHeight = 450;

  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _autoTimer;

  Temple get temple => widget.temple;
  DetailHonesty get honesty => DetailHonesty.of(temple);

  /// Photographs safe to show. Placeholder and picsum URLs are dropped.
  List<String> get gallery => honesty.verifiedImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    if (gallery.length <= 1) return;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % gallery.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _startAutoAdvance();
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${temple.latitude},${temple.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = gallery.length > 1;
    final topPadding = MediaQuery.of(context).padding.top;

    final caveat = honesty.timingsCaveatText;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image gallery with PageView ──
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: _imageHeight + topPadding,
                color: Colors.black,
                padding: EdgeInsets.only(top: topPadding),
                child: gallery.isEmpty
                    ? const TempleImagePlaceholder(
                        key: Key('photo-pending'),
                        expand: true,
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: gallery.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: CachedNetworkImage(
                              imageUrl: gallery[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: _imageHeight,
                              fadeInDuration: const Duration(milliseconds: 400),
                              fadeOutDuration: const Duration(
                                milliseconds: 200,
                              ),
                              placeholder: (_, _) => Container(
                                color: Colors.brown.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: _saffron,
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) =>
                                  const TempleImagePlaceholder(expand: true),
                            ),
                          );
                        },
                      ),
              ),

              // Gradient overlay at bottom for visual polish
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black45],
                    ),
                  ),
                ),
              ),

              // Back + menu buttons
              Positioned(
                top: topPadding + 8,
                left: 8,
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) => _CircleIconButton(
                        icon: Icons.menu_rounded,
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ],
                ),
              ),

              // Home button — top right
              Positioned(
                top: topPadding + 8,
                right: hasMultiple ? 100 : 16,
                child: _CircleIconButton(
                  icon: Icons.home_rounded,
                  onTap: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ),

              // Counter pill — top right
              if (hasMultiple)
                Positioned(
                  top: topPadding + 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${gallery.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Left arrow
              if (hasMultiple)
                Positioned(
                  left: 8,
                  top: topPadding,
                  bottom: 0,
                  child: Center(
                    child: _CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      size: 44,
                      iconSize: 32,
                      onTap: () => _goToPage(
                        (_currentPage - 1 + gallery.length) % gallery.length,
                      ),
                    ),
                  ),
                ),

              // Right arrow
              if (hasMultiple)
                Positioned(
                  right: 8,
                  top: topPadding,
                  bottom: 0,
                  child: Center(
                    child: _CircleIconButton(
                      icon: Icons.chevron_right_rounded,
                      size: 44,
                      iconSize: 32,
                      onTap: () =>
                          _goToPage((_currentPage + 1) % gallery.length),
                    ),
                  ),
                ),

              // Dot indicators — bottom of image
              if (hasMultiple)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gallery.length, (i) {
                      final isActive = _currentPage == i;
                      return GestureDetector(
                        onTap: () => _goToPage(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),

          // ── Temple name header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temple.name,
                  style: GoogleFonts.lora(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _saffron,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 18,
                      color: Colors.brown.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${temple.city}, ${temple.state}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.brown.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (honesty.traditionLabel != null ||
                    honesty.framingLabel != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (honesty.traditionLabel != null)
                        Chip(
                          key: const Key('detail-tradition-chip'),
                          label: Text(
                            honesty.traditionLabel!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          side: const BorderSide(color: _gold),
                          backgroundColor: const Color(0xFFFFF9E3),
                        ),
                      if (honesty.framingLabel != null)
                        Chip(
                          key: const Key('detail-framing-chip'),
                          label: Text(
                            honesty.framingLabel!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          side: const BorderSide(color: _gold),
                          backgroundColor: const Color(0xFFFFF3D8),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  honesty.framingNote,
                  key: const Key('detail-framing-note'),
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.brown.shade700,
                  ),
                ),
                if (temple.deity.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Listed focus: ${temple.deity}',
                    key: const Key('detail-listed-focus'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCard(
                  title: 'Location',
                  icon: Icons.location_on_rounded,
                  content: temple.location,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: honesty.timingsHeading,
                  titleKey: const Key('detail-timings-heading'),
                  icon: Icons.access_time_filled_rounded,
                  content: temple.timings.trim().isEmpty
                      ? 'Not listed in this entry.'
                      : temple.timings,
                  contentKey: const Key('detail-timings-body'),
                  leading: caveat == null ? null : _TimingsCaveat(text: caveat),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Coordinates',
                  icon: Icons.explore_rounded,
                  content:
                      '${temple.latitude.toStringAsFixed(4)}° N, ${temple.longitude.toStringAsFixed(4)}° E',
                ),

                // ── How to Reach ──
                const SizedBox(height: 24),
                Text(
                  'How to Reach',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _saffron,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_city_rounded,
                            color: _saffron,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              temple.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.brown.shade800,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const Key('get-directions-button'),
                          onPressed: _openGoogleMaps,
                          icon: const Icon(
                            Icons.directions_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Get Directions',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _deepSaffron,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── About ──
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _saffron,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  temple.description,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.brown.shade800,
                  ),
                ),

                // ── Temple Story ──
                const SizedBox(height: 24),
                Text(
                  honesty.storyHeading,
                  key: const Key('detail-story-heading'),
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _saffron,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  temple.story,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.brown.shade800,
                  ),
                ),

                // ── Specialities ──
                const SizedBox(height: 24),
                Text(
                  'Specialities',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _saffron,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: temple.specialities
                      .map(
                        (item) => Chip(
                          avatar: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: _saffron,
                          ),
                          label: Text(item, style: GoogleFonts.poppins()),
                          side: const BorderSide(color: _gold),
                          backgroundColor: const Color(0xFFFFF9E3),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable circle icon button ─────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.content,
    this.leading,
    this.titleKey,
    this.contentKey,
  });

  final String title;
  final IconData icon;
  final String content;
  final Widget? leading;
  final Key? titleKey;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF8F00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: titleKey,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade900,
                  ),
                ),
                if (leading != null) ...[const SizedBox(height: 8), leading!],
                const SizedBox(height: 4),
                Text(
                  content,
                  key: contentKey,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.brown.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingsCaveat extends StatelessWidget {
  const _TimingsCaveat({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('timings-caveat'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE65100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFE65100),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                color: Colors.brown.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
