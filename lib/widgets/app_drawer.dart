import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/interstitial_ad_manager.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/utils/temple_search.dart';
import 'package:temple_app/widgets/banner_ad_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  APP DRAWER — shared across all screens, supports search + state/deity filters
// ─────────────────────────────────────────────────────────────────────────────

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);
  static const Color _gold = Color(0xFFFFD54F);

  static const _states = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Gujarat',
    'Odisha',
    'Uttar Pradesh',
    'Jammu and Kashmir',
    'Maharashtra',
    'Rajasthan',
    'West Bengal',
    'Madhya Pradesh',
    'Bihar',
    'Himachal Pradesh',
  ];
  static const _deities = [
    'Shiva',
    'Vishnu',
    'Devi',
    'Murugan',
    'Ganesha',
    'Surya',
    'Hanuman',
    'Swaminarayan',
    'Gorakhnath',
    'Sai Baba',
    'Vitthal',
    'Khandoba',
    'Brahma',
    'Jain Tirthankaras',
    'Devi (Kali)',
    'Devi (Bhavatarini Kali)',
    'Sri Ramakrishna (Ramakrishna–Vedanta tradition)',
    'Devi (Tara)',
    'Devi (Hangseshwari Kali)',
    'Radha-Madhava / Pancha-tattva (Gaudiya Vaishnavism)',
    'Shiva (Taraknath)',
    'Vishnu (Radha-Krishna / Lakshminarayan)',
    'Devi (Kiriteswari / Mahishamardini)',
    'Kapil Muni',
    'Vishnu/Rama',
    'Buddha',
    'Sita (Devi)',
  ];

  static const _deityIcons = {
    'Shiva': Icons.brightness_3_rounded,
    'Vishnu': Icons.water_drop_rounded,
    'Devi': Icons.auto_awesome_rounded,
    'Murugan': Icons.shield_rounded,
    'Ganesha': Icons.spa_rounded,
    'Surya': Icons.wb_sunny_rounded,
    'Hanuman': Icons.back_hand_rounded,
    'Swaminarayan': Icons.account_balance_rounded,
    'Gorakhnath': Icons.self_improvement_rounded,
    'Sai Baba': Icons.person_rounded,
    'Vitthal': Icons.favorite_rounded,
    'Khandoba': Icons.shield_rounded,
    'Brahma': Icons.filter_vintage_rounded,
    'Jain Tirthankaras': Icons.account_balance_rounded,
    'Devi (Kali)': Icons.auto_awesome_rounded,
    'Devi (Bhavatarini Kali)': Icons.auto_awesome_rounded,
    'Sri Ramakrishna (Ramakrishna–Vedanta tradition)':
        Icons.self_improvement_rounded,
    'Devi (Tara)': Icons.auto_awesome_rounded,
    'Devi (Hangseshwari Kali)': Icons.auto_awesome_rounded,
    'Radha-Madhava / Pancha-tattva (Gaudiya Vaishnavism)':
        Icons.favorite_rounded,
    'Shiva (Taraknath)': Icons.brightness_3_rounded,
    'Vishnu (Radha-Krishna / Lakshminarayan)': Icons.water_drop_rounded,
    'Devi (Kiriteswari / Mahishamardini)': Icons.auto_awesome_rounded,
    'Kapil Muni': Icons.self_improvement_rounded,
    'Vishnu/Rama': Icons.water_drop_rounded,
    'Buddha': Icons.spa_rounded,
    'Sita (Devi)': Icons.auto_awesome_rounded,
  };

  String? _selectedState;
  String? _selectedDeity;

  late final Future<List<Temple>> _templesFuture;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _appliedQuery = '';
  bool _showClear = false;
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _templesFuture = TempleService().getTemples();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final showClear = value.isNotEmpty;
    final hasDraft = value.trim().isNotEmpty;
    if (showClear != _showClear || hasDraft != _hasDraft) {
      setState(() {
        _showClear = showClear;
        _hasDraft = hasDraft;
      });
    }
    if (value.trim().isEmpty) {
      if (_appliedQuery.isNotEmpty) {
        setState(() => _appliedQuery = '');
      }
      return;
    }
    _searchDebounce = Timer(templeSearchDebounce, () {
      if (!mounted) return;
      setState(() => _appliedQuery = value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _showClear = false;
      _hasDraft = false;
      _appliedQuery = '';
    });
  }

  void _clearFiltersAndSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedState = null;
      _selectedDeity = null;
      _showClear = false;
      _hasDraft = false;
      _appliedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Temple>>(
      future: _templesFuture,
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];

        final stateCounts = <String, int>{};
        for (final t in all) {
          stateCounts[t.state] = (stateCounts[t.state] ?? 0) + 1;
        }

        // Deity counts reflect selected state if any
        final deityPool = _selectedState != null
            ? all.where((t) => t.state == _selectedState)
            : all;
        final deityCounts = <String, int>{};
        for (final t in deityPool) {
          deityCounts[t.deity] = (deityCounts[t.deity] ?? 0) + 1;
        }

        final filtered = filterTemples(
          all,
          state: _selectedState,
          deity: _selectedDeity,
          query: _appliedQuery,
        );

        final hasFilter = _selectedState != null || _selectedDeity != null;

        return Drawer(
          backgroundColor: const Color(0xFFFFFBF2),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Header ──
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
                    const Icon(
                      Icons.temple_hindu_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
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
                      'India',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Home ──
              _DrawerNavTile(
                label: 'Home',
                icon: Icons.home_rounded,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),

              const Divider(height: 20, indent: 18, endIndent: 18),

              // ── All Temples ──
              _DrawerNavTile(
                label: 'All Temples',
                icon: Icons.temple_hindu_rounded,
                count: all.length,
                onTap: () => _navigateToList(context, all, 'All Temples'),
              ),

              const Divider(height: 20, indent: 18, endIndent: 18),

              // ── Search (combines with the state / deity chips below) ──
              _SectionHeader(label: 'SEARCH'),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                child: _DirectorySearchField(
                  key: const Key('temple-drawer-search-field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) {
                    if (_searchController.text.trim().isEmpty &&
                        _selectedState == null &&
                        _selectedDeity == null) {
                      return;
                    }
                    _openBrowse(context, all);
                  },
                  onClear: _clearSearch,
                  showClear: _showClear,
                ),
              ),
              if (_hasDraft)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openBrowse(context, all),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        _matchButtonLabel(filtered.length),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

              // ── State filter ──
              _SectionHeader(
                label: 'FILTER BY STATE',
                trailing: _selectedState != null
                    ? _ClearChip(
                        onTap: () => setState(() {
                          _selectedState = null;
                          // Reset deity if it has 0 count without state filter
                          if (_selectedDeity != null) {
                            final globalDeityCount = all
                                .where((t) => t.deity == _selectedDeity)
                                .length;
                            if (globalDeityCount == 0) _selectedDeity = null;
                          }
                        }),
                      )
                    : null,
              ),
              for (final state in _states)
                _FilterTile(
                  label: state,
                  icon: Icons.location_on_rounded,
                  count: stateCounts[state] ?? 0,
                  selected: _selectedState == state,
                  onTap: () => setState(() {
                    _selectedState = _selectedState == state ? null : state;
                  }),
                ),

              const Divider(height: 20, indent: 18, endIndent: 18),

              // ── Deity filter ──
              _SectionHeader(
                label: _selectedState != null
                    ? 'DEITY IN ${_selectedState!.toUpperCase()}'
                    : 'FILTER BY DEITY',
                trailing: _selectedDeity != null
                    ? _ClearChip(
                        onTap: () => setState(() => _selectedDeity = null),
                      )
                    : null,
              ),
              for (final deity in _deities)
                _FilterTile(
                  label: '$deity Temples',
                  icon: _deityIcons[deity] ?? Icons.circle,
                  count: deityCounts[deity] ?? 0,
                  selected: _selectedDeity == deity,
                  onTap: (deityCounts[deity] ?? 0) > 0
                      ? () => setState(() {
                          _selectedDeity = _selectedDeity == deity
                              ? null
                              : deity;
                        })
                      : null,
                ),

              const SizedBox(height: 16),

              // ── Browse button ──
              if (hasFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filter summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _saffron.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.filter_alt_rounded,
                              color: _deepSaffron,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _summaryLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _deepSaffron,
                                ),
                              ),
                            ),
                            Text(
                              '${filtered.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _deepSaffron,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _openBrowse(context, all),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          'Browse ${filtered.length} Temple${filtered.length == 1 ? '' : 's'}',
                        ),
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
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _clearFiltersAndSearch,
                        child: Text(
                          _hasDraft
                              ? 'Clear search and filters'
                              : 'Clear All Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _deepSaffron,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 24, indent: 18, endIndent: 18),

              // ── About ──
              _SectionHeader(label: 'ABOUT'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Explore 150 famous temples across Tamil Nadu, Kerala, Karnataka, '
                  'Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, '
                  'Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, '
                  'Madhya Pradesh, Bihar, and Himachal Pradesh. '
                  'Discover histories, legends, timings and specialities — '
                  'all in one curated directory.',
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
      },
    );
  }

  String get _filterLabel {
    final parts = <String>[];
    if (_selectedDeity != null) parts.add(_selectedDeity!);
    if (_selectedState != null) parts.add(_selectedState!);
    if (parts.isEmpty) return 'All Temples';
    return parts.join(' · ');
  }

  String get _summaryLabel {
    final parts = <String>[];
    if (_selectedDeity != null) parts.add(_selectedDeity!);
    if (_selectedState != null) parts.add(_selectedState!);
    final query = _appliedQuery.trim();
    if (query.isNotEmpty) parts.add('"$query"');
    if (parts.isEmpty) return 'All Temples';
    return parts.join(' · ');
  }

  String _browseTitle() {
    if (_selectedState == null && _selectedDeity == null) return 'Search';
    return _filterLabel;
  }

  String _matchButtonLabel(int count) {
    if (_appliedQuery.trim().isEmpty) return 'Search directory';
    if (count == 0) return 'No matching temples';
    return 'View $count match${count == 1 ? '' : 'es'}';
  }

  void _openBrowse(BuildContext context, List<Temple> all) {
    _searchDebounce?.cancel();
    final query = _searchController.text;
    _appliedQuery = query;
    _showClear = query.isNotEmpty;
    _hasDraft = query.trim().isNotEmpty;
    final base = filterTemples(
      all,
      state: _selectedState,
      deity: _selectedDeity,
    );
    _navigateToList(context, base, _browseTitle(), initialQuery: query);
  }

  void _navigateToList(
    BuildContext context,
    List<Temple> temples,
    String title, {
    String initialQuery = '',
  }) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TempleListScreen(
          temples: temples,
          title: title,
          initialQuery: initialQuery,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLE LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TempleListScreen extends StatefulWidget {
  const TempleListScreen({
    super.key,
    required this.temples,
    required this.title,
    this.initialQuery = '',
  });

  final List<Temple> temples;
  final String title;

  /// Query already chosen in the drawer. The list applies it on top of [temples].
  final String initialQuery;

  @override
  State<TempleListScreen> createState() => _TempleListScreenState();
}

class _TempleListScreenState extends State<TempleListScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();
  int _templeOpenCount = 0;

  @override
  void initState() {
    super.initState();
    _interstitialAdManager.loadAd();
  }

  @override
  void dispose() {
    _interstitialAdManager.dispose();
    super.dispose();
  }

  void _onTempleTap(Temple temple) {
    _templeOpenCount++;
    if (_templeOpenCount % 3 == 0) {
      _interstitialAdManager.showAdIfAvailable();
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TempleDetailScreen(temple: temple)),
    );
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
          widget.title,
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TempleBrowseList(
        temples: widget.temples,
        initialQuery: widget.initialQuery,
        onTempleTap: _onTempleTap,
        footer: const BannerAdWidget(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLE BROWSE LIST — debounced text search over an already loaded list
// ─────────────────────────────────────────────────────────────────────────────

class TempleBrowseList extends StatefulWidget {
  const TempleBrowseList({
    super.key,
    required this.temples,
    this.initialQuery = '',
    this.onTempleTap,
    this.footer,
  });

  /// Temples already limited by state/deity (or the full directory).
  final List<Temple> temples;
  final String initialQuery;
  final ValueChanged<Temple>? onTempleTap;

  /// Shown under the grid when at least one temple is visible.
  final Widget? footer;

  @override
  State<TempleBrowseList> createState() => _TempleBrowseListState();
}

class _TempleBrowseListState extends State<TempleBrowseList> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _appliedQuery = '';
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _appliedQuery = widget.initialQuery;
    _showClear = widget.initialQuery.isNotEmpty;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final showClear = value.isNotEmpty;
    if (showClear != _showClear) {
      setState(() => _showClear = showClear);
    }
    if (value.trim().isEmpty) {
      if (_appliedQuery.isNotEmpty) {
        setState(() => _appliedQuery = '');
      }
      return;
    }
    _searchDebounce = Timer(templeSearchDebounce, () {
      if (!mounted) return;
      setState(() => _appliedQuery = value);
    });
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _showClear = value.isNotEmpty;
      _appliedQuery = value;
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _showClear = false;
      _appliedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterTemples(widget.temples, query: _appliedQuery);
    final query = _appliedQuery.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: _DirectorySearchField(
            key: const Key('temple-list-search-field'),
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _submitSearch,
            onClear: _clearSearch,
            showClear: _showClear,
          ),
        ),
        if (query.isNotEmpty && visible.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visible.length} temple${visible.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.brown.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? _SearchEmptyState(
                  query: query,
                  onClear: query.isEmpty ? null : _clearSearch,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final temple = visible[index];
                    return TempleGridCard(
                      temple: temple,
                      onTap: widget.onTempleTap == null
                          ? null
                          : () => widget.onTempleTap!(temple),
                    );
                  },
                ),
        ),
        if (visible.isNotEmpty && widget.footer != null) widget.footer!,
      ],
    );
  }
}

class _DirectorySearchField extends StatelessWidget {
  const _DirectorySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.brown.shade800),
      decoration: InputDecoration(
        hintText: 'Name, city, state, deity, or address',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.brown.shade300,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8F00)),
        suffixIcon: showClear
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, color: Colors.brown.shade400),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFD54F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF8F00), width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query, this.onClear});

  final String query;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final searching = query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.temple_hindu_rounded,
              size: 56,
              color: Colors.brown.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              searching ? 'No temples match "$query".' : 'No temples found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (searching) ...[
              const SizedBox(height: 6),
              Text(
                'Try a name, city, state, deity, or address.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.brown.shade400,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onClear, child: const Text('Clear search')),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLE GRID CARD
// ─────────────────────────────────────────────────────────────────────────────

class TempleGridCard extends StatelessWidget {
  const TempleGridCard({super.key, required this.temple, this.onTap});

  final Temple temple;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TempleDetailScreen(temple: temple),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: temple.hasNetworkImage
                    ? CachedNetworkImage(
                        imageUrl: temple.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        fadeInDuration: const Duration(milliseconds: 400),
                        placeholder: (context, url) => Container(
                          color: Colors.brown.shade50,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF8F00),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.brown.shade200,
                          child: const Icon(
                            Icons.temple_hindu,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.brown.shade200,
                        child: const Icon(
                          Icons.temple_hindu,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF8F00),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${temple.city}, ${temple.state}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.brown.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade400,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ClearChip extends StatelessWidget {
  const _ClearChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'clear',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  static const _saffron = Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? const Color(0xFFFFF3D8) : null,
        leading: Icon(
          icon,
          size: 20,
          color: disabled
              ? Colors.brown.shade200
              : selected
              ? _saffron
              : Colors.brown.shade400,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: disabled
                ? Colors.brown.shade300
                : selected
                ? _saffron
                : Colors.brown.shade800,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? _saffron.withAlpha(30)
                    : Colors.brown.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? Colors.brown.shade300
                      : selected
                      ? _saffron
                      : Colors.brown.shade500,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, color: _saffron, size: 20),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.label,
    required this.icon,
    this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 20, color: Colors.brown.shade400),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Colors.brown.shade800,
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade500,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
