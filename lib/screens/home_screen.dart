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
import 'package:temple_app/widgets/home_mosaic_collage.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.adminAuth, this.templesLoader});

  /// Injected in tests. Defaults to [AdminAuth.instance].
  final AdminAuth? adminAuth;

  /// Injected in tests. Defaults to [TempleService.getTemples].
  final Future<List<Temple>> Function()? templesLoader;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  final TempleService _templeService = TempleService();
  late Future<List<Temple>> _templesFuture;

  Future<List<Temple>> _loadTemples() {
    final loader = widget.templesLoader;
    if (loader != null) return loader();
    return _templeService.getTemples();
  }

  @override
  void initState() {
    super.initState();
    _templesFuture = _loadTemples();
  }

  void _reloadTemples() {
    setState(() => _templesFuture = _loadTemples());
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
            return const _HomeLoadingBody();
          }
          if (snapshot.hasError) {
            return _HomeErrorBody(onRetry: _reloadTemples);
          }

          final allTemples = snapshot.data ?? [];
          if (allTemples.isEmpty) {
            return _HomeEmptyBody(onRetry: _reloadTemples);
          }

          return _HomeBody(
            allTemples: allTemples,
            onBrowseTemples: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TempleListScreen(
                    temples: allTemples,
                    title: 'All Temples',
                  ),
                ),
              );
            },
          );
        },
      ),
      // New future identity refreshes the drawer after Seed / Admin.
      drawer: AppDrawer(key: ObjectKey(_templesFuture)),
    );
  }
}

/// Cream loading state so users see Home chrome instead of solid orange splash.
class _HomeLoadingBody extends StatelessWidget {
  const _HomeLoadingBody();

  static const Color _saffron = Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.temple_hindu_rounded, size: 48, color: _saffron),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: _saffron),
            const SizedBox(height: 16),
            Text(
              'Loading temples…',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing the directory. This usually takes a moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorBody extends StatelessWidget {
  const _HomeErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.brown.shade300),
            const SizedBox(height: 12),
            Text(
              'Could not load temples.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyBody extends StatelessWidget {
  const _HomeEmptyBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.temple_hindu_outlined,
                size: 56, color: Colors.brown.shade300),
            const SizedBox(height: 12),
            Text(
              'No temples available yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The directory came back empty. Tap Retry, or try again later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME BODY (mosaic collage + heritage write-up + browse entry)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.allTemples,
    required this.onBrowseTemples,
  });

  final List<Temple> allTemples;
  final VoidCallback onBrowseTemples;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Verified-photo mosaic (KAN-73) — picsum never shown as temple art.
        SliverToBoxAdapter(
          child: HomeMosaicCollage(temples: allTemples),
        ),

        // ── Browse directory (temple cards live here / in the drawer) ──
        SliverToBoxAdapter(
          child: _BrowseTemplesCta(
            templeCount: allTemples.length,
            onPressed: onBrowseTemples,
          ),
        ),

        // ── Heritage write-up ──
        SliverToBoxAdapter(child: _HeritageWriteUp()),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _BrowseTemplesCta extends StatelessWidget {
  const _BrowseTemplesCta({
    required this.templeCount,
    required this.onPressed,
  });

  final int templeCount;
  final VoidCallback onPressed;

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final label = templeCount == 0
        ? 'Browse temples'
        : 'Browse $templeCount Temple${templeCount == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Open the directory for temple cards, search, and filters. '
            'You can also use the menu (☰).',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('home-browse-temples'),
            onPressed: onPressed,
            icon: const Icon(Icons.temple_hindu_rounded),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saffron,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Heritage reading continues below',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _deepSaffron.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

