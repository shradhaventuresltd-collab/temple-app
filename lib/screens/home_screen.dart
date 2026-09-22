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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Verified-photo mosaic (KAN-73) — picsum never shown as temple art.
        SliverToBoxAdapter(
          child: HomeMosaicCollage(temples: allTemples),
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

