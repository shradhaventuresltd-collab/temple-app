import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/heritage_content.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/admin_screen.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/debug_home_admin_actions.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.adminAuth});

  /// Injected in tests. Defaults to [AdminAuth.instance].
  final AdminAuth? adminAuth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  final TempleService _templeService = TempleService();
  late Future<List<Temple>> _templesFuture;

  @override
  void initState() {
    super.initState();
    _templesFuture = _templeService.getTemples();
  }

  void _reloadTemples() {
    setState(() => _templesFuture = _templeService.getTemples());
  }

  AdminAuth get _auth => widget.adminAuth ?? AdminAuth.instance;

  Future<void> _openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminScreen(adminAuth: widget.adminAuth),
      ),
    );
    if (mounted) _reloadTemples();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _saffron,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Temple Directory',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (kDebugMode)
            DebugHomeAdminActions(
              auth: _auth,
              onOpenAdmin: _openAdmin,
              onSeedSuccess: _reloadTemples,
            ),
        ],
      ),
      body: FutureBuilder<List<Temple>>(
        future: _templesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: _saffron),
                  const SizedBox(height: 16),
                  Text(
                    'Loading temples',
                    style: GoogleFonts.poppins(
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 56, color: Colors.brown.shade300),
                  const SizedBox(height: 12),
                  Text('Something went wrong.',
                      style:
                          GoogleFonts.poppins(color: Colors.brown.shade700)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _reloadTemples,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allTemples = snapshot.data ?? [];

          return _HomeBody(
            allTemples: allTemples,
          );
        },
      ),
      // New future identity refreshes the drawer after Seed / Admin.
      drawer: AppDrawer(key: ObjectKey(_templesFuture)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME BODY (mosaic collage + heritage write-up + temple grid)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.allTemples,
  });

  final List<Temple> allTemples;

  List<String> get _allImages {
    final urls = <String>[];
    for (final t in allTemples) {
      if (t.images.isNotEmpty) {
        urls.addAll(t.images.where((u) => u.trim().isNotEmpty));
      } else if (t.hasNetworkImage) {
        urls.add(t.imageUrl);
      }
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;

    return CustomScrollView(
      slivers: [
        // ── Static mosaic collage ──
        SliverToBoxAdapter(
          child: _MosaicCollage(images: images, templeCount: allTemples.length),
        ),

        // ── Heritage write-up ──
        SliverToBoxAdapter(child: _HeritageWriteUp()),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOSAIC COLLAGE — static, non-interactive grid of temple images
// ─────────────────────────────────────────────────────────────────────────────

class _MosaicCollage extends StatelessWidget {
  const _MosaicCollage({required this.images, required this.templeCount});

  final List<String> images;
  final int templeCount;

  static const Color _deepSaffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 260,
        color: Colors.brown.shade200,
        child: Center(
          child: Text(
            'Temple Collage',
            style: GoogleFonts.lora(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }

    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          // Mosaic grid of images
          Column(
            children: [
              // Row 1: 3 images
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _mosaicImage(images[0 % images.length]),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                              child: _mosaicImage(
                                  images[1 % images.length])),
                          const SizedBox(height: 2),
                          Expanded(
                              child: _mosaicImage(
                                  images[2 % images.length])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Row 2: 4 equal images
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    for (int i = 3; i < 7; i++) ...[
                      if (i > 3) const SizedBox(width: 2),
                      Expanded(
                          child:
                              _mosaicImage(images[i % images.length])),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Row 3: 2 images with different proportions
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                              child: _mosaicImage(
                                  images[7 % images.length])),
                          const SizedBox(height: 2),
                          Expanded(
                              child: _mosaicImage(
                                  images[8 % images.length])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 2,
                      child: _mosaicImage(images[9 % images.length]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    _deepSaffron.withAlpha(160),
                    Colors.transparent,
                    Colors.transparent,
                    _deepSaffron.withAlpha(200),
                  ],
                ),
              ),
            ),
          ),

          // Text overlay
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
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
                      Shadow(
                          blurRadius: 12,
                          color: Colors.black.withAlpha(120)),
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
                      Shadow(
                          blurRadius: 12,
                          color: Colors.black.withAlpha(120)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$templeCount temples across India',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                          blurRadius: 8,
                          color: Colors.black.withAlpha(100)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mosaicImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 400),
      placeholder: (context, url) => Container(color: Colors.brown.shade100),
      errorWidget: (context, url, error) => Container(
        color: Colors.brown.shade200,
        child: const Icon(Icons.temple_hindu, color: Colors.white54, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERITAGE WRITE-UP — detailed 10,000+ word content
// ─────────────────────────────────────────────────────────────────────────────

class _HeritageWriteUp extends StatelessWidget {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 24, 14, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded,
                  color: _saffron, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Temple Heritage of India',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _deepSaffron,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A comprehensive exploration of India\'s sacred architectural legacy',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.brown.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          _OrnamentDivider(),
          const SizedBox(height: 18),

          // Render all sections from heritage data
          for (int i = 0; i < heritageSections.length; i++) ...[
            if (i > 0) const SizedBox(height: 28),
            if (i > 0) _OrnamentDivider(),
            if (i > 0) const SizedBox(height: 22),
            Text(
              heritageSections[i].title,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _deepSaffron,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            for (int p = 0; p < heritageSections[i].paragraphs.length; p++) ...[
              if (p > 0) const SizedBox(height: 12),
              Text(
                heritageSections[i].paragraphs[p],
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.75,
                  color: Colors.brown.shade700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OrnamentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFFFD54F),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.temple_hindu_rounded,
              size: 18, color: Color(0xFFFF8F00)),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD54F),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

