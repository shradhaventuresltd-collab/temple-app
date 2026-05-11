import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

class TempleDetailScreen extends StatefulWidget {
  const TempleDetailScreen({super.key, required this.temple});

  final Temple temple;

  @override
  State<TempleDetailScreen> createState() => _TempleDetailScreenState();
}

class _TempleDetailScreenState extends State<TempleDetailScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _gold = Color(0xFFFFD54F);
  static const _autoAdvanceInterval = Duration(seconds: 5);

  int _currentPage = 0;
  Timer? _autoTimer;

  Temple get temple => widget.temple;
  List<String> get gallery => temple.galleryImages;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _startAutoAdvance() {
    if (gallery.length <= 1) return;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentPage = (_currentPage + 1) % gallery.length;
      });
    });
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _startAutoAdvance();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = gallery.length > 1;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    // Use a 4:3 aspect ratio so the full image is always visible
    final imageHeight = screenWidth * 3 / 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image gallery section ──
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: imageHeight + topPadding,
                  color: Colors.black,
                  padding: EdgeInsets.only(top: topPadding),
                  child: gallery.isEmpty
                      ? const TempleImagePlaceholder(expand: true)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child: CachedNetworkImage(
                            key: ValueKey(gallery[_currentPage]),
                            imageUrl: gallery[_currentPage],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: imageHeight,
                            fadeInDuration:
                                const Duration(milliseconds: 400),
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(
                                  color: _saffron),
                            ),
                            errorWidget: (_, _, _) =>
                                const TempleImagePlaceholder(
                                    expand: true),
                          ),
                        ),
                ),

                // Back button
                Positioned(
                  top: topPadding + 8,
                  left: 8,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                // Counter pill
                if (hasMultiple)
                  Positioned(
                    top: topPadding + 8,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
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
                        size: 42,
                        iconSize: 30,
                        onTap: () => _goToPage(
                            (_currentPage - 1 + gallery.length) %
                                gallery.length),
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
                        size: 42,
                        iconSize: 30,
                        onTap: () => _goToPage(
                            (_currentPage + 1) % gallery.length),
                      ),
                    ),
                  ),

                // Dot indicators at bottom of image
                if (hasMultiple)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
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
                              color: isActive
                                  ? Colors.white
                                  : Colors.white38,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF2),
              ),
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
                      Icon(Icons.place_rounded,
                          size: 18, color: Colors.brown.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${temple.city}, ${temple.state}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.brown.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                    title: 'Timings',
                    icon: Icons.access_time_filled_rounded,
                    content: temple.timings,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Coordinates',
                    icon: Icons.explore_rounded,
                    content:
                        '${temple.latitude.toStringAsFixed(4)}° N, ${temple.longitude.toStringAsFixed(4)}° E',
                  ),
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
                  const SizedBox(height: 24),
                  Text(
                    'Temple Story',
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
                              Icons.temple_buddhist_rounded,
                              size: 18,
                              color: _saffron,
                            ),
                            label: Text(item,
                                style: GoogleFonts.poppins()),
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
  });

  final String title;
  final IconData icon;
  final String content;

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
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
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
