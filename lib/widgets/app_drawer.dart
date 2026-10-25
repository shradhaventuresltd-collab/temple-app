import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_scroll.dart';
import 'package:temple_app/screens/licences_screen.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/services/app_analytics.dart';
import 'package:temple_app/services/ad_consent.dart';
import 'package:temple_app/services/ad_helper.dart';
import 'package:temple_app/services/interstitial_ad_manager.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/temple_search.dart';
import 'package:temple_app/widgets/banner_ad_widget.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';
import 'package:temple_app/widgets/home_mosaic_collage.dart';
import 'package:temple_app/widgets/offline_banner.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';
import 'package:temple_app/widgets/unavailable_states_notice.dart';

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
  String? _selectedDistrict;

  late final Future<List<Temple>> _templesFuture;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _appliedQuery = '';
  bool _showClear = false;
  bool _hasDraft = false;

  /// True while a drawer item is handling a tap.
  ///
  /// The drawer's local-history entry is removed as soon as it starts to
  /// close. A second tap in that same turn would otherwise [Navigator.pop]
  /// the page underneath (Home disappears, or another list is pushed).
  ///
  /// The flag stays up for [_navGuardHold]. Clearing it on the next frame
  /// was too soon: a finger's second contact arrives during the close fling,
  /// moves past the touch slop, and the drawer's drag recognizer accepts it
  /// before this tile's [onTap]. That stops the fling and opens the drawer
  /// again, because the panel is still more than half on screen.
  bool _navBusy = false;

  /// Close fling is about 246ms. Hold the guard until that fling is done.
  static const _navGuardHold = Duration(milliseconds: 400);

  Timer? _navGuardTimer;

  @override
  void initState() {
    super.initState();
    _templesFuture = TempleService().getTemples();
  }

  @override
  void dispose() {
    _navGuardTimer?.cancel();
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
      final previous = _appliedQuery;
      setState(() => _appliedQuery = value);
      _reportSearchIfChanged(previous, value);
    });
  }

  void _reportSearchIfChanged(String previous, String next) {
    final query = next.trim();
    if (query.isEmpty || query == previous.trim()) return;
    unawaited(_reportSearch(query));
  }

  Future<void> _reportSearch(String query) async {
    final temples = await _templesFuture;
    if (!mounted) return;
    final matches = directoryMatchingTemples(
      temples,
      state: _selectedState,
      deity: _selectedDeity,
      district: _selectedDistrict,
      query: query,
      districtOf: bundledDistrictLookup(),
    );
    await AppAnalytics.instance.logSearch(
      queryLength: query.length,
      hasResults: matches.isNotEmpty,
    );
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
      _selectedDistrict = null;
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

        final districtOf = bundledDistrictLookup();
        final filtered = directoryMatchingTemples(
          all,
          state: _selectedState,
          deity: _selectedDeity,
          district: _selectedDistrict,
          query: _appliedQuery,
          districtOf: districtOf,
        );

        final hasFilter =
            _selectedState != null ||
            _selectedDeity != null ||
            (_selectedDistrict != null && _selectedDistrict!.isNotEmpty);

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
                absorbDrawerDrag: _navBusy,
                onTap: () => _goHome(context),
              ),

              const Divider(height: 20, indent: 18, endIndent: 18),

              // ── All Temples ──
              _DrawerNavTile(
                label: 'All Temples',
                icon: Icons.temple_hindu_rounded,
                count: all.length,
                absorbDrawerDrag: _navBusy,
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
                        _selectedDeity == null &&
                        (_selectedDistrict == null ||
                            _selectedDistrict!.isEmpty)) {
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
                  selectedDistrict: _selectedDistrict,
                  districtOf: districtOf,
                  prepareDistricts: () => prepareDirectoryDistricts(all),
                  onDistrictsLoaded: () {
                    if (mounted) setState(() {});
                  },
                  onChanged: (state, deity, district) {
                    final previousState = _selectedState;
                    final previousDeity = _selectedDeity;
                    final previousDistrict = _selectedDistrict;
                    setState(() {
                      _selectedState = state;
                      _selectedDeity = deity;
                      _selectedDistrict = district;
                    });
                    unawaited(
                      AppAnalytics.instance.logFilterTransition(
                        previousState: previousState,
                        nextState: state,
                        previousDeity: previousDeity,
                        nextDeity: deity,
                        previousDistrict: previousDistrict,
                        nextDistrict: district,
                      ),
                    );
                  },
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
              _DrawerNavTile(
                key: const Key('drawer-licences'),
                label: 'Licences',
                icon: Icons.article_outlined,
                absorbDrawerDrag: _navBusy,
                onTap: () => _openLicences(context),
              ),
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
    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      parts.add(_selectedDistrict!);
    }
    if (_selectedState != null) parts.add(_selectedState!);
    final query = _appliedQuery.trim();
    if (query.isNotEmpty) parts.add('"$query"');
    if (parts.isEmpty) return 'All Temples';
    return parts.join(' · ');
  }

  String _browseTitle() {
    if (_selectedState == null &&
        _selectedDeity == null &&
        (_selectedDistrict == null || _selectedDistrict!.isEmpty)) {
      return 'Search';
    }
    return directoryBrowseTitle(
      state: _selectedState,
      deity: _selectedDeity,
      district: _selectedDistrict,
    );
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
    final previous = _appliedQuery;
    final query = _searchController.text;
    _appliedQuery = query;
    _reportSearchIfChanged(previous, query);
    _showClear = query.isNotEmpty;
    _hasDraft = query.trim().isNotEmpty;
    _navigateToList(
      context,
      all,
      _browseTitle(),
      initialQuery: query,
      stateFilter: _selectedState,
      deityFilter: _selectedDeity,
      districtFilter: _selectedDistrict,
      directory: directory,
    );
  }

  void _goHome(BuildContext context) {
    if (!_beginDrawerNavigation(context)) return;
    final navigator = Navigator.of(context);
    final alreadyHome = ModalRoute.of(context)?.isFirst ?? false;
    if (alreadyHome) {
      _releaseNavGuardNextFrame();
      unawaited(HomeScroll.animateToTop());
      return;
    }
    _holdNavGuard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) {
        navigator.popUntil((route) => route.isFirst);
        unawaited(HomeScroll.animateToTop());
      }
    });
  }

  void _openLicences(BuildContext context) {
    if (!_beginDrawerNavigation(context)) return;
    final navigator = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.name == AnalyticsScreens.licences) {
      _releaseNavGuardNextFrame();
      return;
    }
    _holdNavGuard();
    final page = namedAnalyticsRoute<void>(
      name: AnalyticsScreens.licences,
      builder: (_) => const LicencesScreen(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) navigator.push(page);
    });
  }

  /// Closes the drawer once and returns false when this tap must not navigate.
  ///
  /// [ScaffoldState.closeDrawer] drops the drawer's local history without
  /// popping the page. A repeat tap, after that history is gone, used to call
  /// [Navigator.pop] and remove Home or push a second list.
  bool _beginDrawerNavigation(BuildContext context) {
    if (_navBusy) return false;
    final scaffold = Scaffold.maybeOf(context);
    final drawerOpen = scaffold?.isDrawerOpen ?? false;
    final handlesPop = ModalRoute.of(context)?.willHandlePopInternally ?? false;
    if (!drawerOpen && !handlesPop) return false;
    _navBusy = true;
    // Callers that leave this screen extend the guard for the close fling.
    // Callers that were already on the screen release it on the next frame.
    if (drawerOpen) {
      scaffold!.closeDrawer();
    } else {
      Navigator.of(context).pop();
    }
    return true;
  }

  /// Drops the same-turn guard once the closing frame has been handled.
  ///
  /// Used when the tap only closes the drawer because that screen is already
  /// showing. Holding the 400ms drag claim there blocks the next item.
  void _releaseNavGuardNextFrame() {
    _navGuardTimer?.cancel();
    _navGuardTimer = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navGuardTimer != null) return;
      setState(() => _navBusy = false);
    });
  }

  /// Rebuilds the nav tiles so they claim the next pointer, and keeps
  /// [_navBusy] set until the close fling can no longer be reversed.
  void _holdNavGuard() {
    _navGuardTimer?.cancel();
    _navGuardTimer = Timer(_navGuardHold, () {
      if (!mounted) return;
      setState(() => _navBusy = false);
    });
    if (mounted) setState(() {});
  }

  bool _isSameOpenList(
    BuildContext context, {
    required String title,
    required String initialQuery,
    String? stateFilter,
    String? deityFilter,
    String? districtFilter,
  }) {
    final list = context.findAncestorStateOfType<_TempleListScreenState>();
    if (list == null) return false;
    return list._title == title &&
        list.widget.initialQuery == initialQuery &&
        _blankFilter(list.widget.stateFilter) == _blankFilter(stateFilter) &&
        _blankFilter(list.widget.deityFilter) == _blankFilter(deityFilter) &&
        _blankFilter(list.widget.districtFilter) ==
            _blankFilter(districtFilter);
  }

  String? _blankFilter(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  void _navigateToList(
    BuildContext context,
    List<Temple> temples,
    String title, {
    String initialQuery = '',
    String? stateFilter,
    String? deityFilter,
    String? districtFilter,
    required AsyncSnapshot<List<Temple>> directory,
  }) {
    if (!_beginDrawerNavigation(context)) return;
    final waiting = directory.connectionState == ConnectionState.waiting;
    final failed = directory.hasError;
    // Already showing this directory: closing the drawer is the navigation.
    // Pushing again covered the list and stacked a duplicate route.
    if (_isSameOpenList(
      context,
      title: title,
      initialQuery: initialQuery,
      stateFilter: stateFilter,
      deityFilter: deityFilter,
      districtFilter: districtFilter,
    )) {
      _releaseNavGuardNextFrame();
      return;
    }
    _holdNavGuard();
    final navigator = Navigator.of(context);
    final page = namedAnalyticsRoute<void>(
      name: AnalyticsScreens.templeList,
      builder: (_) => TempleListScreen(
        temples: waiting || failed ? const [] : temples,
        title: title,
        initialQuery: initialQuery,
        templesFuture: waiting ? _templesFuture : null,
        stateFilter: stateFilter,
        deityFilter: deityFilter,
        districtFilter: districtFilter,
        loadFailed: failed,
      ),
    );
    // Wait until the drawer history entry is gone, then replace any list so
    // Back returns to Home instead of an older copy of the same directory.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) {
        navigator.popUntil((route) => route.isFirst);
        navigator.push(page);
      }
    });
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
    this.districtFilter,
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
  final String? districtFilter;

  final bool loadFailed;

  @override
  State<TempleListScreen> createState() => _TempleListScreenState();
}

class _TempleListScreenState extends State<TempleListScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);

  /// Tall enough for a two-line title. The default 56px toolbar clips the
  /// second line.
  static const double _titleBarHeight = 80;

  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();
  int _templeOpenCount = 0;
  late String _title;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _interstitialAdManager.loadAd();
    TempleService.revision.addListener(_onPublished);
  }

  List<Temple>? _shown;

  List<Temple> get _directory => _shown ?? widget.temples;

  void _onPublished() {
    final rows = TempleService.published;
    if (rows == null || !mounted) return;
    setState(() => _shown = rows);
  }

  Future<void> _retrySavedList() async {
    try {
      final rows = await TempleService().loadDirectory();
      if (!mounted) return;
      setState(() => _shown = rows);
    } catch (e, st) {
      debugPrint('Saved list retry failed: $e\n$st');
    }
  }

  void _onFiltersChanged(String? state, String? deity, String? district) {
    final unconstrained =
        state == null &&
        deity == null &&
        (district == null || district.isEmpty);
    final next = unconstrained && widget.initialQuery.trim().isNotEmpty
        ? 'Search'
        : directoryBrowseTitle(state: state, deity: deity, district: district);
    if (next == _title) return;
    setState(() => _title = next);
  }

  @override
  void dispose() {
    TempleService.revision.removeListener(_onPublished);
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
      namedAnalyticsRoute<void>(
        name: AnalyticsScreens.templeDetail,
        arguments: temple.id,
        builder: (_) => TempleDetailScreen(temple: temple),
      ),
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
        toolbarHeight: _titleBarHeight,
        title: Text(
          _title,
          key: const Key('temple-list-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Semantics(
            identifier: 'temple-list-home',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Home',
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                unawaited(HomeScroll.animateToTop());
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          OfflineBanner(savedTempleCount: _directory.length),
          SavedListBanner(onRetry: _retrySavedList),
          Expanded(child: _buildBody()),
        ],
      ),
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
        temples: _directory,
        initialQuery: widget.initialQuery,
        initialState: widget.stateFilter,
        initialDeity: widget.deityFilter,
        initialDistrict: widget.districtFilter,
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
            initialDistrict: widget.districtFilter,
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
          initialDistrict: widget.districtFilter,
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
    this.initialDistrict,
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
  final String? initialDistrict;
  final void Function(String? state, String? deity, String? district)?
  onFiltersChanged;
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
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _appliedQuery = widget.initialQuery;
    _showClear = widget.initialQuery.isNotEmpty;
    _selectedState = widget.initialState;
    _selectedDeity = widget.initialDeity;
    _selectedDistrict = widget.initialDistrict;
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
      _applySearch(value);
    });
  }

  void _submitSearch(String value) {
    _searchDebounce?.cancel();
    _applySearch(value);
  }

  void _applySearch(String raw) {
    final previous = _appliedQuery;
    setState(() {
      _showClear = raw.isNotEmpty;
      _appliedQuery = raw;
    });
    final query = raw.trim();
    if (query.isEmpty || query == previous.trim()) return;
    final matches = directoryMatchingTemples(
      widget.temples,
      state: _selectedState,
      deity: _selectedDeity,
      district: _selectedDistrict,
      query: query,
      districtOf: bundledDistrictLookup(),
    );
    unawaited(
      AppAnalytics.instance.logSearch(
        queryLength: query.length,
        hasResults: matches.isNotEmpty,
      ),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _showClear = false;
      _appliedQuery = '';
    });
  }

  /// Empty-state Clear filters, and the chip-row Clear. Both drop the
  /// search text as well as State, district, and deity. A Clear inside the
  /// sheet does not come through here until Apply.
  void _clearFiltersAndSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    final previousState = _selectedState;
    final previousDeity = _selectedDeity;
    final previousDistrict = _selectedDistrict;
    setState(() {
      _showClear = false;
      _appliedQuery = '';
      _selectedState = null;
      _selectedDeity = null;
      _selectedDistrict = null;
    });
    widget.onFiltersChanged?.call(null, null, null);
    unawaited(
      AppAnalytics.instance.logFilterTransition(
        previousState: previousState,
        nextState: null,
        previousDeity: previousDeity,
        nextDeity: null,
        previousDistrict: previousDistrict,
        nextDistrict: null,
      ),
    );
  }

  void _setFilters(String? state, String? deity, String? district) {
    final previousState = _selectedState;
    final previousDeity = _selectedDeity;
    final previousDistrict = _selectedDistrict;
    setState(() {
      _selectedState = state;
      _selectedDeity = deity;
      _selectedDistrict = district;
    });
    widget.onFiltersChanged?.call(state, deity, district);
    unawaited(
      AppAnalytics.instance.logFilterTransition(
        previousState: previousState,
        nextState: state,
        previousDeity: previousDeity,
        nextDeity: deity,
        previousDistrict: previousDistrict,
        nextDistrict: district,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districtOf = bundledDistrictLookup();
    final visible = directoryMatchingTemples(
      widget.temples,
      state: _selectedState,
      deity: _selectedDeity,
      district: _selectedDistrict,
      query: _appliedQuery,
      districtOf: districtOf,
    );
    final query = _appliedQuery.trim();
    final filtersActive =
        _selectedState != null ||
        _selectedDeity != null ||
        (_selectedDistrict != null && _selectedDistrict!.isNotEmpty);
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
            const UnavailableStatesNotice(),
            if (showFilterBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
                child: DirectoryFilterBar(
                  temples: widget.temples,
                  query: _appliedQuery,
                  selectedState: _selectedState,
                  selectedDeity: _selectedDeity,
                  selectedDistrict: _selectedDistrict,
                  districtOf: districtOf,
                  prepareDistricts: () =>
                      prepareDirectoryDistricts(widget.temples),
                  onDistrictsLoaded: () {
                    if (mounted) setState(() {});
                  },
                  onChanged: _setFilters,
                  onClearAll: _clearFiltersAndSearch,
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
        district: _selectedDistrict,
        onClearSearch: query.isEmpty ? null : _clearSearch,
        onClearFilters: filtersActive ? _clearFiltersAndSearch : null,
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
    return Semantics(
      identifier: 'temple-list-search-field',
      child: TextField(
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFFF8F00),
          ),
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
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.query,
    this.filtersActive = false,
    this.district,
    this.onClearSearch,
    this.onClearFilters,
  });

  final String query;
  final bool filtersActive;
  final String? district;
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
        ? directoryEmptyFilterMessage(district: district)
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
            final show = onShowPrivacyOptions ?? AdHelper.presentPrivacyOptions;
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
    super.key,
    required this.label,
    required this.icon,
    this.count,
    required this.onTap,
    this.absorbDrawerDrag = false,
  });

  final String label;
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  /// While the drawer is closing, claim horizontal drags on this tile.
  ///
  /// The drawer's own drag recognizer would otherwise accept the next
  /// finger, stop the close, and open the drawer again.
  final bool absorbDrawerDrag;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
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
      onTap: absorbDrawerDrag ? null : onTap,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: absorbDrawerDrag
          ? RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              gestures: <Type, GestureRecognizerFactory>{
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(
                      () => EagerGestureRecognizer(),
                      (EagerGestureRecognizer instance) {},
                    ),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _keepDrawerClosing(context),
                child: tile,
              ),
            )
          : tile,
    );
  }
}

/// The drawer's drag recognizer stops the close on pointer down, then opens
/// again if the panel is still mostly on screen. Claim the pointer on the
/// tile, and close once more after that recognizer has settled.
void _keepDrawerClosing(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  });
}
