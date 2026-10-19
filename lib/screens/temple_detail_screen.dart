import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/widgets/offline_banner.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _saffron = Color(0xFFFF8F00);
const Color _gold = Color(0xFFFFD54F);

/// Maps search for a temple that has coordinates. The name is part of the
/// query so a pin is not only a bare lat,lng pair.
Uri googleMapsSearchUri({
  required String name,
  required double latitude,
  required double longitude,
}) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$name $latitude,$longitude',
  });
}

class TempleDetailScreen extends StatefulWidget {
  const TempleDetailScreen({super.key, required this.temple, this.loadTemple});

  /// Browse summary, or a full document when the caller already has one.
  final Temple temple;

  /// Loads `temples/{id}`. Tests pass a fake. Index summaries fetch; a full
  /// document passed in is shown as-is.
  final Future<TempleDetailLoad> Function(String id)? loadTemple;

  @override
  State<TempleDetailScreen> createState() => _TempleDetailScreenState();
}

class _TempleDetailScreenState extends State<TempleDetailScreen> {
  late Temple _temple;
  var _loading = false;
  var _missing = false;
  var _fromCache = false;

  @override
  void initState() {
    super.initState();
    _temple = widget.temple;
    final id = widget.temple.id.trim();
    if (!widget.temple.isIndexSummary || id.isEmpty) return;
    _loading = true;
    final load = widget.loadTemple ?? TempleService().getTemple;
    unawaited(_fetch(load, id));
  }

  Future<void> _fetch(
    Future<TempleDetailLoad> Function(String id) load,
    String id,
  ) async {
    try {
      final loaded = await load(id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        final full = loaded.temple;
        if (full == null) {
          _missing = true;
        } else {
          _temple = full;
          _fromCache = loaded.fromCache;
        }
      });
    } catch (e, st) {
      debugPrint('Temple detail read failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _missing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _saffron))
          : _missing
          ? Center(
              child: Text(
                'Could not load this temple.',
                style: GoogleFonts.poppins(color: Colors.brown.shade700),
              ),
            )
          : TempleDetailBody(temple: _temple, fromCache: _fromCache),
    );
  }
}

/// Scrollable detail content. Separated so honesty UI can be tested without
/// opening the shared drawer (which reads Firestore).
class TempleDetailBody extends StatefulWidget {
  const TempleDetailBody({
    super.key,
    required this.temple,
    this.fromCache = false,
  });

  final Temple temple;

  /// True when [temple] was read from the local cache after the server read
  /// failed. The page says it may be out of date.
  final bool fromCache;

  @override
  State<TempleDetailBody> createState() => _TempleDetailBodyState();
}

class _TempleDetailBodyState extends State<TempleDetailBody> {
  static const Color _deepSaffron = Color(0xFFE65100);
  static const _autoAdvanceInterval = Duration(seconds: 5);
  static const double _imageHeight = 450;

  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _autoTimer;
  final Set<int> _fullSizePages = {};

  Temple get temple => widget.temple;
  DetailHonesty get honesty => DetailHonesty.of(temple);

  /// Photographs safe to show. Placeholder and picsum URLs are dropped.
  ///
  /// The page shows [displayUrl] (the gallery copy when one exists).
  /// Credits stay on [DetailGalleryFrame.sourceUrl].
  List<DetailGalleryFrame> get frames =>
      detailGalleryFrames(temple, fullSizeIndexes: _fullSizePages);

  List<String> get gallery => [for (final frame in frames) frame.sourceUrl];

  void _showOriginal(int index) {
    if (_fullSizePages.contains(index)) return;
    setState(() => _fullSizePages.add(index));
  }

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

  static const String _directionsUnavailableMessage =
      "Couldn't open directions on this device.";

  Future<void> _openGoogleMaps() async {
    final lat = temple.latitude;
    final lng = temple.longitude;
    if (!temple.hasCoordinates || lat == null || lng == null) return;
    final url = googleMapsSearchUri(
      name: temple.name,
      latitude: lat,
      longitude: lng,
    );
    final opened = await _tryOpenMaps(url);
    if (!opened && mounted) {
      _showDirectionsUnavailable();
    }
  }

  /// Returns false when no app can open [url], or the launch itself fails.
  Future<bool> _tryOpenMaps(Uri url) async {
    try {
      if (!await canLaunchUrl(url)) return false;
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  void _showDirectionsUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _directionsUnavailableMessage,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = gallery.length > 1;
    final topPadding = MediaQuery.of(context).padding.top;
    final photoCredit = gallery.isEmpty
        ? null
        : visiblePhotoCredit(temple.photos, gallery[_currentPage]);

    final caveat = honesty.timingsCaveatText;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OfflineBanner(savedTempleCount: 1),
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
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (context, index) {
                              final frame = frames[index];
                              return _GalleryPhoto(
                                key: ValueKey('detail-gallery-$index'),
                                displayUrl: frame.displayUrl,
                                sourceUrl: frame.sourceUrl,
                                onWantFullSize: () => _showOriginal(index),
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
                            (_currentPage - 1 + gallery.length) %
                                gallery.length,
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

              if (photoCredit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    photoCredit,
                    key: const Key('detail-photo-credit'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.black54,
                    ),
                  ),
                ),

              // ── Temple name header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        temple.name,
                        key: const Key('detail-temple-name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: GoogleFonts.lora(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: _saffron,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            key: const Key('detail-temple-place'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.brown.shade600,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
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
                    if (widget.fromCache) ...[
                      Text(
                        'This page may be out of date.',
                        key: const Key('detail-cache-hint'),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                      leading: caveat == null
                          ? null
                          : _TimingsCaveat(text: caveat),
                    ),
                    if (temple.hasCoordinates) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Coordinates',
                        icon: Icons.explore_rounded,
                        content:
                            '${temple.latitude!.toStringAsFixed(4)}° N, ${temple.longitude!.toStringAsFixed(4)}° E',
                      ),
                    ],

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
                          if (temple.hasCoordinates) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: Semantics(
                                identifier: 'get-directions-button',
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                    // Chip locks the label to one line and fades the rest
                    // (maxLines: 1, softWrap: false, TextOverflow.fade).
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var i = 0;
                          i < temple.specialities.length;
                          i++
                        ) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _SpecialityPill(label: temple.specialities[i]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (topPadding > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: const IgnorePointer(
              child: ColoredBox(
                key: Key('detail-status-bar-scrim'),
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-width speciality pill. The label wraps to as many lines as it needs.
class _SpecialityPill extends StatelessWidget {
  const _SpecialityPill({required this.label});

  final String label;

  static const Color _cream = Color(0xFFFFF9E3);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 18, color: _saffron),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                height: 1.43,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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

/// Detail photo. Loads [displayUrl] (the gallery copy when one exists).
///
/// A pinch past [kDetailGalleryFullSizeScale], or a failed gallery fetch,
/// asks for the original. Auto-advance only changes the page, so it does
/// not request that original.
class _GalleryPhoto extends StatefulWidget {
  const _GalleryPhoto({
    super.key,
    required this.displayUrl,
    required this.sourceUrl,
    required this.onWantFullSize,
  });

  final String displayUrl;
  final String sourceUrl;
  final VoidCallback onWantFullSize;

  @override
  State<_GalleryPhoto> createState() => _GalleryPhotoState();
}

class _GalleryPhotoState extends State<_GalleryPhoto> {
  static const double _imageHeight = 450;

  late final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void _onTransform() {
    final scale = _transform.value.getMaxScaleOnAxis();
    if (detailGalleryZoomWantsOriginal(scale) &&
        widget.displayUrl != widget.sourceUrl) {
      widget.onWantFullSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOriginalOnError = widget.displayUrl != widget.sourceUrl;
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1.0,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: widget.displayUrl,
        cacheManager: ClientCache.detailImages,
        fit: BoxFit.contain,
        width: double.infinity,
        height: _imageHeight,
        fadeInDuration: const Duration(milliseconds: 400),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => Container(
          color: Colors.brown.shade200,
          child: const Center(
            child: CircularProgressIndicator(color: _saffron),
          ),
        ),
        errorWidget: (_, _, _) => showOriginalOnError
            ? _RequestFullSize(onReady: widget.onWantFullSize)
            : const TempleImagePlaceholder(expand: true),
      ),
    );
  }
}

class _RequestFullSize extends StatefulWidget {
  const _RequestFullSize({required this.onReady});

  final VoidCallback onReady;

  @override
  State<_RequestFullSize> createState() => _RequestFullSizeState();
}

class _RequestFullSizeState extends State<_RequestFullSize> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TempleImagePlaceholder(expand: true);
  }
}
