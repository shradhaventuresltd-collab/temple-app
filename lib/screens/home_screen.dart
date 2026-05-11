import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/screens/admin_screen.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  final TempleService _templeService = TempleService();
  late Future<List<Temple>> _templesFuture;

  String _search = '';
  String? _selectedState;
  String? _selectedDeity;

  @override
  void initState() {
    super.initState();
    _templesFuture = _templeService.getTemples();
  }

  List<Temple> _applyFilters(List<Temple> temples) {
    return temples.where((temple) {
      final matchesSearch = _search.isEmpty ||
          temple.name.toLowerCase().contains(_search.toLowerCase()) ||
          temple.city.toLowerCase().contains(_search.toLowerCase());
      final matchesState =
          _selectedState == null || temple.state == _selectedState;
      final matchesDeity =
          _selectedDeity == null || temple.deity == _selectedDeity;
      return matchesSearch && matchesState && matchesDeity;
    }).toList();
  }

  String get _activeFilterLabel {
    final parts = <String>[];
    if (_selectedState != null) parts.add(_selectedState!);
    if (_selectedDeity != null) parts.add(_selectedDeity!);
    return parts.isEmpty ? 'All Temples' : parts.join(' · ');
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedDeity = null;
    });
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
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: _AppDrawer(
        selectedState: _selectedState,
        selectedDeity: _selectedDeity,
        onStateSelected: (state) {
          setState(() => _selectedState = state);
          Navigator.pop(context);
        },
        onDeitySelected: (deity) {
          setState(() => _selectedDeity = deity);
          Navigator.pop(context);
        },
        onClearFilters: () {
          _clearFilters();
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: _saffron,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) =>
                      setState(() => _search = value.trim()),
                  style: GoogleFonts.poppins(color: Colors.brown.shade900),
                  decoration: InputDecoration(
                    hintText: 'Search by temple name or city',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.brown.shade500,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFFFF8E6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_selectedState != null || _selectedDeity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded,
                            size: 18, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _activeFilterLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Temple>>(
              future: _templesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _saffron,
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
                        Text(
                          'Something went wrong.',
                          style: GoogleFonts.poppins(
                              color: Colors.brown.shade700),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _templesFuture =
                                _templeService.getTemples();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered =
                    _applyFilters(snapshot.data ?? []);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.temple_hindu_rounded,
                            size: 56,
                            color: Colors.brown.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No temples found.',
                          style: GoogleFonts.poppins(
                              color: Colors.brown.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search or filters.',
                          style: GoogleFonts.poppins(
                            color: Colors.brown.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _TempleCard(
                        temple: filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWER
// ─────────────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selectedState,
    required this.selectedDeity,
    required this.onStateSelected,
    required this.onDeitySelected,
    required this.onClearFilters,
  });

  final String? selectedState;
  final String? selectedDeity;
  final ValueChanged<String?> onStateSelected;
  final ValueChanged<String?> onDeitySelected;
  final VoidCallback onClearFilters;

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);

  static const _states = ['Tamil Nadu', 'Kerala', 'Karnataka'];
  static const _deities = ['Shiva', 'Vishnu', 'Devi', 'Murugan'];

  static const _deityIcons = {
    'Shiva': Icons.brightness_3_rounded,
    'Vishnu': Icons.water_drop_rounded,
    'Devi': Icons.auto_awesome_rounded,
    'Murugan': Icons.shield_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFFBF2),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_deepSaffron, _saffron],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.temple_hindu_rounded,
                    size: 44, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  'Temple Directory',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'South India',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Filter by State ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(
              'FILTER BY STATE',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final state in _states)
            _DrawerFilterTile(
              label: state,
              icon: Icons.location_on_rounded,
              selected: selectedState == state,
              onTap: () => onStateSelected(
                  selectedState == state ? null : state),
            ),

          const Divider(height: 28, indent: 18, endIndent: 18),

          // ── Filter by Deity ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
            child: Text(
              'FILTER BY DEITY',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final deity in _deities)
            _DrawerFilterTile(
              label: deity,
              icon: _deityIcons[deity] ?? Icons.circle,
              selected: selectedDeity == deity,
              onTap: () => onDeitySelected(
                  selectedDeity == deity ? null : deity),
            ),

          const Divider(height: 28, indent: 18, endIndent: 18),

          // ── Clear All ──
          if (selectedState != null || selectedDeity != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _deepSaffron,
                  side: const BorderSide(color: _gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const Divider(height: 28, indent: 18, endIndent: 18),

          // ── About ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Text(
              'ABOUT',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Explore 30 famous temples across Tamil Nadu, Kerala & Karnataka. '
              'Discover histories, legends, timings and specialities — '
              'all in one beautifully curated directory.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.brown.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.brown.shade300,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerFilterTile extends StatelessWidget {
  const _DrawerFilterTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFFF8F00);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: selected ? const Color(0xFFFFF3D8) : null,
        leading: Icon(
          icon,
          size: 20,
          color: selected ? saffron : Colors.brown.shade400,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? saffron : Colors.brown.shade800,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded,
                color: saffron, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TempleCard extends StatelessWidget {
  const _TempleCard({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TempleDetailScreen(temple: temple),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.09),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
              child: temple.hasNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: temple.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 400),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.brown.shade50,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF8F00),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const TempleImagePlaceholder(
                              height: 200, expand: false),
                    )
                  : const TempleImagePlaceholder(
                      height: 200, expand: false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temple.name,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8F00),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${temple.city}, ${temple.state}',
                          style: GoogleFonts.poppins(
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    temple.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.8,
                      color: Colors.brown.shade600,
                    ),
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
