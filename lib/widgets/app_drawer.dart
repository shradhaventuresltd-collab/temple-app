import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/ad_consent.dart';
import 'package:temple_app/services/ad_helper.dart';
import 'package:temple_app/services/interstitial_ad_manager.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/temple_search.dart';
import 'package:temple_app/widgets/banner_ad_widget.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';
import 'package:temple_app/widgets/home_mosaic_collage.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

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
                onTap: () => _navigateToList(
                  context,
                  all,
                  'All Temples',
                  directory: snapshot,
                ),
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
                    _openBrowse(context, all, directory: snapshot);
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
                      onPressed: () =>
                          _openBrowse(context, all, directory: snapshot),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        _matchButtonLabel(filtered.length),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

              // ── State + deity chips (sheet). Same control as the browse list. ──
              _SectionHeader(label: 'FILTERS'),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 8, 4),
                child: DirectoryFilterBar(
                  temples: all,
                  query: _appliedQuery,
                  selectedState: _selectedState,
                  selectedDeity: _selectedDeity,
                  onChanged: (state, deity) => setState(() {
                    _selectedState = state;
                    _selectedDeity = deity;
                  }),
                ),
              ),

              const SizedBox(height: 8),

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
                        onPressed: () =>
                            _openBrowse(context, all, directory: snapshot),
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
                  drawerAboutDirectoryBlurb(all.length),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.brown.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const AdPrivacyChoicesTile(),
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
    return directoryBrowseTitle(state: _selectedState, deity: _selectedDeity);
  }

  String _matchButtonLabel(int count) {
    if (_appliedQuery.trim().isEmpty) return 'Search directory';
    if (count == 0) return 'No matching temples';
    return 'View $count match${count == 1 ? '' : 'es'}';
  }

  void _openBrowse(
    BuildContext context,
    List<Temple> all, {
    required AsyncSnapshot<List<Temple>> directory,
  }) {
    _searchDebounce?.cancel();
    final query = _searchController.text;
    _appliedQuery = query;
    _showClear = query.isNotEmpty;
    _hasDraft = query.trim().isNotEmpty;
    _navigateToList(
      context,
      all,
      _browseTitle(),
      initialQuery: query,
      stateFilter: _selectedState,
      deityFilter: _selectedDeity,
      directory: directory,
    );
  }

  void _navigateToList(
    BuildContext context,
    List<Temple> temples,
    String title, {
    String initialQuery = '',
    String? stateFilter,
    String? deityFilter,
    required AsyncSnapshot<List<Temple>> directory,
  }) {
    final waiting = directory.connectionState == ConnectionState.waiting;
    final failed = directory.hasError;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TempleListScreen(
          temples: waiting || failed ? const [] : temples,
          title: title,
          initialQuery: initialQuery,
          templesFuture: waiting ? _templesFuture : null,
          stateFilter: stateFilter,
          deityFilter: deityFilter,
          loadFailed: failed,
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
    this.templesFuture,
    this.stateFilter,
    this.deityFilter,
    this.loadFailed = false,
  });

  final List<Temple> temples;
  final String title;

  /// Query already chosen in the drawer. The list applies it on top of [temples].
  final String initialQuery;

  /// Set while the drawer directory is still loading so the list can finish
  /// that same fetch instead of showing an empty directory.
  final Future<List<Temple>>? templesFuture;

  /// Chips selected when the list opens. [temples] stays the loaded directory;
  /// the list filters it on the device.
  final String? stateFilter;
  final String? deityFilter;

  final bool loadFailed;

  @override
  State<TempleListScreen> createState() => _TempleListScreenState();
}

class _TempleListScreenState extends State<TempleListScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();
  int _templeOpenCount = 0;
  late String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _interstitialAdManager.loadAd();
  }

  void _onFiltersChanged(String? state, String? deity) {
    final next = state == null &&
            deity == null &&
            widget.initialQuery.trim().isNotEmpty
        ? 'Search'
        : directoryBrowseTitle(state: state, deity: deity);
    if (next == _title) return;
    setState(() => _title = next);
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
          _title,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.loadFailed) {
      return TempleBrowseList(
        temples: const [],
        initialQuery: widget.initialQuery,
        loadFailed: true,
        onTempleTap: _onTempleTap,
      );
    }

    final pending = widget.templesFuture;
    if (pending == null) {
      return TempleBrowseList(
        temples: widget.temples,
        initialQuery: widget.initialQuery,
        initialState: widget.stateFilter,
        initialDeity: widget.deityFilter,
        onFiltersChanged: _onFiltersChanged,
        onTempleTap: _onTempleTap,
        footer: const BannerAdWidget(),
      );
    }

    return FutureBuilder<List<Temple>>(
      future: pending,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return TempleBrowseList(
            temples: const [],
            initialQuery: widget.initialQuery,
            initialState: widget.stateFilter,
            initialDeity: widget.deityFilter,
            isLoading: true,
            onTempleTap: _onTempleTap,
          );
        }
        if (snapshot.hasError) {
          return TempleBrowseList(
            temples: const [],
            initialQuery: widget.initialQuery,
            loadFailed: true,
            onTempleTap: _onTempleTap,
          );
        }
        return TempleBrowseList(
          temples: snapshot.data ?? const [],
          initialQuery: widget.initialQuery,
          initialState: widget.stateFilter,
          initialDeity: widget.deityFilter,
          onFiltersChanged: _onFiltersChanged,
          onTempleTap: _onTempleTap,
          footer: const BannerAdWidget(),
        );
      },
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
    this.initialState,
    this.initialDeity,
    this.onFiltersChanged,
    this.onTempleTap,
    this.footer,
    this.isLoading = false,
    this.loadFailed = false,
  });

  /// Directory already loaded for this screen. State and deity chips filter
  /// it on the device.
  final List<Temple> temples;
  final String initialQuery;
  final String? initialState;
  final String? initialDeity;
  final void Function(String? state, String? deity)? onFiltersChanged;
  final ValueChanged<Temple>? onTempleTap;

  /// Banner slot under the cards when at least one temple is visible.
  ///
  /// Kept outside the scroll view so a loaded ad does not cover a card.
  final Widget? footer;

  final bool isLoading;
  final bool loadFailed;

  @override
  State<TempleBrowseList> createState() => _TempleBrowseListState();
}

class _TempleBrowseListState extends State<TempleBrowseList> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _appliedQuery = '';
  bool _showClear = false;
  String? _selectedState;
  String? _selectedDeity;

  @override
  void initState() {
    super.initState();
    _appliedQuery = widget.initialQuery;
    _showClear = widget.initialQuery.isNotEmpty;
    _selectedState = widget.initialState;
    _selectedDeity = widget.initialDeity;
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

  void _setFilters(String? state, String? deity) {
    setState(() {
      _selectedState = state;
      _selectedDeity = deity;
    });
    widget.onFiltersChanged?.call(state, deity);
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterTemples(
      widget.temples,
      state: _selectedState,
      deity: _selectedDeity,
      query: _appliedQuery,
    );
    final query = _appliedQuery.trim();
    final filtersActive = _selectedState != null || _selectedDeity != null;
    final showFilterBar = !widget.isLoading && !widget.loadFailed;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
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
            if (showFilterBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
                child: DirectoryFilterBar(
                  temples: widget.temples,
                  query: _appliedQuery,
                  selectedState: _selectedState,
                  selectedDeity: _selectedDeity,
                  onChanged: _setFilters,
                ),
              ),
            if ((query.isNotEmpty || filtersActive) && visible.isNotEmpty)
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
              child: _browseBody(visible, query, filtersActive: filtersActive),
            ),
            if (visible.isNotEmpty &&
                !widget.isLoading &&
                !widget.loadFailed &&
                widget.footer != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Center(child: widget.footer),
              ),
          ],
        ),
      ),
    );
  }

  Widget _browseBody(
    List<Temple> visible,
    String query, {
    required bool filtersActive,
  }) {
    if (widget.isLoading) {
      return const _BrowseMessage(
        progress: true,
        title: 'Loading temples',
        message: 'Fetching the directory.',
      );
    }
    if (widget.loadFailed) {
      return const _BrowseMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load temples',
        message: 'The directory did not load. Go back and try again.',
      );
    }
    if (visible.isEmpty) {
      return _SearchEmptyState(
        query: query,
        filtersActive: filtersActive,
        onClearSearch: query.isEmpty ? null : _clearSearch,
        onClearFilters: filtersActive ? () => _setFilters(null, null) : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final temple = visible[index];
        return TempleBrowseCard(
          temple: temple,
          onTap: widget.onTempleTap == null
              ? null
              : () => widget.onTempleTap!(temple),
        );
      },
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
  const _SearchEmptyState({
    required this.query,
    this.filtersActive = false,
    this.onClearSearch,
    this.onClearFilters,
  });

  final String query;
  final bool filtersActive;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final searching = query.isNotEmpty;
    final title = filtersActive && searching
        ? 'No temples match these filters and "$query".'
        : filtersActive
        ? 'No temples match these filters.'
        : searching
        ? 'No temples match "$query".'
        : 'No temples to browse';
    final message = filtersActive && searching
        ? 'Clear the filters or the search. The list is the directory already loaded.'
        : filtersActive
        ? 'Nothing in the loaded directory fits this state and deity.'
        : searching
        ? 'Try a name, city, state, deity, or address.'
        : 'Nothing is listed in this view yet.';
    final icon = filtersActive
        ? Icons.filter_alt_off_rounded
        : searching
        ? Icons.search_off_rounded
        : Icons.temple_hindu_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.brown.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.brown.shade400,
              ),
            ),
            if (onClearFilters != null || onClearSearch != null) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (onClearFilters != null)
                    TextButton(
                      key: const Key('filter-empty-clear'),
                      onPressed: onClearFilters,
                      child: const Text('Clear filters'),
                    ),
                  if (onClearSearch != null)
                    TextButton(
                      onPressed: onClearSearch,
                      child: const Text('Clear search'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrowseMessage extends StatelessWidget {
  const _BrowseMessage({
    required this.title,
    required this.message,
    this.icon = Icons.temple_hindu_rounded,
    this.progress = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress)
              const CircularProgressIndicator(color: Color(0xFFFF8F00))
            else
              Icon(icon, size: 56, color: Colors.brown.shade300),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.brown.shade400,
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

/// Shown only after UMP says a privacy-options entry point is required.
class AdPrivacyChoicesTile extends StatelessWidget {
  const AdPrivacyChoicesTile({
    super.key,
    this.consent,
    this.onShowPrivacyOptions,
  });

  final AdConsentController? consent;
  final Future<void> Function()? onShowPrivacyOptions;

  @override
  Widget build(BuildContext context) {
    final gate = consent ?? AdConsentController.instance;
    return ListenableBuilder(
      listenable: gate,
      builder: (context, _) {
        if (!gate.isReady || !gate.privacyOptionsRequired) {
          return const SizedBox.shrink();
        }
        return _DrawerNavTile(
          label: 'Ad privacy choices',
          icon: Icons.privacy_tip_outlined,
          onTap: () {
            final navigator = Navigator.maybeOf(context);
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
            }
            final show =
                onShowPrivacyOptions ?? AdHelper.presentPrivacyOptions;
            unawaited(show());
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.brown.shade400,
          letterSpacing: 1.2,
        ),
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
