import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/district/district_boundary.dart';
import 'package:temple_app/district/district_lookup.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/geolocator_coarse_location.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/near_me/near_me_session.dart';
import 'package:temple_app/near_me/nearby_temples.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/analytics_routes.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/india_regions.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';
import 'package:temple_app/widgets/place_type_icon.dart';
import 'package:temple_app/widgets/filter_sheet.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// Sorted temples from one coarse fix, or from a state/city centroid.
///
/// [temples] is the directory already on screen. This widget does not read
/// Firestore. Pass [location] in tests. A null [districtOf] uses the on-device
/// boundary lookup, and only after the district picker is opened.
class TemplesNearMeScreen extends StatefulWidget {
  const TemplesNearMeScreen({
    super.key,
    required this.temples,
    this.location,
    this.districtOf,
  });

  final List<Temple> temples;
  final CoarseLocationClient? location;

  /// Explicit names. Null means compute a district from the bundled boundaries.
  final TempleDistrictLookup? districtOf;

  @override
  State<TemplesNearMeScreen> createState() => _TemplesNearMeScreenState();
}

class _TemplesNearMeScreenState extends State<TemplesNearMeScreen>
    with WidgetsBindingObserver {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);
  static const Color _deepSaffron = Color(0xFFE65100);

  late final NearMeSession _session;
  bool _sheetOpen = false;
  String? _tradition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = NearMeSession(
      temples: widget.temples,
      location: widget.location ?? GeolocatorCoarseLocation(),
      districtOf: widget.districtOf ?? DistrictDirectory.instance.peek,
    );
    _session.addListener(_onSession);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_showRationale());
    });
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSession);
    _session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_session.onAppResumed());
    }
  }

  Future<void> _showRationale() async {
    if (!mounted || _sheetOpen) return;
    _sheetOpen = true;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      builder: (context) => const _RationaleSheet(),
    );
    _sheetOpen = false;
    if (!mounted) return;
    if (accepted == true) {
      await _session.acceptRationale();
    } else {
      _session.declineRationale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _saffron,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          NearMeCopy.title,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_session.phase) {
      case NearMePhase.rationale:
        return const SizedBox.shrink();
      case NearMePhase.locating:
        return _status(NearMeCopy.locating);
      case NearMePhase.sorted:
        return _results(heading: NearMeCopy.nearestHeading);
      case NearMePhase.denied:
      case NearMePhase.deniedForever:
      case NearMePhase.serviceOff:
      case NearMePhase.timedOut:
      case NearMePhase.declined:
        return _fallback();
    }
  }

  Widget _status(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
          key: const Key('near-me-status'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.brown.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  bool _showDistrictPicker() {
    final lookup = widget.districtOf ?? DistrictDirectory.instance.peek;
    final names = nearbyDistricts(
      widget.temples,
      state: _session.anchorState,
      districtOf: lookup,
    );
    if (names.isNotEmpty) return true;
    if (widget.districtOf != null) return false;
    if (!districtBoundariesAreBundled) return false;
    final state = _session.anchorState;
    for (final temple in widget.temples) {
      if (!temple.hasCoordinates) continue;
      if (state != null && state.isNotEmpty && temple.state != state) {
        continue;
      }
      return true;
    }
    return false;
  }

  Widget _fallback() {
    return ListView(
      key: const Key('near-me-fallback'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          _fallbackMessage(),
          key: const Key('near-me-message'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.45,
            color: Colors.brown.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ..._actions(),
        const SizedBox(height: 8),
        _placeButton(
          key: const Key('near-me-state'),
          label: _session.anchorState ?? NearMeCopy.chooseState,
          onPressed: _chooseState,
        ),
        const SizedBox(height: 8),
        _placeButton(
          key: const Key('near-me-city'),
          label: _session.anchorCity ?? NearMeCopy.chooseCity,
          onPressed: _session.anchorState == null ? null : _chooseCity,
        ),
        if (_showDistrictPicker()) ...[
          const SizedBox(height: 8),
          _placeButton(
            key: const Key('near-me-district'),
            label: _session.anchorDistrict ?? NearMeCopy.chooseDistrict,
            onPressed: _chooseDistrict,
          ),
        ],
        const SizedBox(height: 16),
        _anchorResults(),
      ],
    );
  }

  String _fallbackMessage() {
    return switch (_session.phase) {
      NearMePhase.denied => NearMeCopy.deniedBody,
      NearMePhase.deniedForever => NearMeCopy.deniedForeverBody,
      NearMePhase.serviceOff => NearMeCopy.serviceOffBody,
      NearMePhase.timedOut => NearMeCopy.timedOutBody,
      NearMePhase.declined => NearMeCopy.declinedBody,
      _ => NearMeCopy.declinedBody,
    };
  }

  List<Widget> _actions() {
    final buttons = switch (_session.phase) {
      NearMePhase.denied => [
        _actionButton(
          key: const Key('near-me-enable-location'),
          label: NearMeCopy.enableLocation,
          onPressed: () => unawaited(_session.enableLocation()),
        ),
      ],
      NearMePhase.deniedForever => [
        _actionButton(
          key: const Key('near-me-open-settings'),
          label: NearMeCopy.openSettings,
          onPressed: () => unawaited(_session.openAppSettings()),
        ),
      ],
      NearMePhase.serviceOff => [
        _actionButton(
          key: const Key('near-me-retry'),
          label: NearMeCopy.retry,
          onPressed: () => unawaited(_session.retry()),
        ),
        _actionButton(
          key: const Key('near-me-open-location-settings'),
          label: NearMeCopy.openLocationSettings,
          filled: false,
          onPressed: () => unawaited(_session.openLocationSettings()),
        ),
      ],
      NearMePhase.timedOut => [
        _actionButton(
          key: const Key('near-me-retry'),
          label: NearMeCopy.retry,
          onPressed: () => unawaited(_session.retry()),
        ),
      ],
      NearMePhase.declined => [
        _actionButton(
          key: const Key('near-me-use-location'),
          label: NearMeCopy.useLocation,
          onPressed: () => unawaited(_showRationale()),
        ),
      ],
      _ => <Widget>[],
    };
    return [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(height: 4),
        buttons[i],
      ],
    ];
  }

  Widget _anchorResults() {
    final label = _session.placeLabel;
    if (label == null) return const SizedBox.shrink();
    if (_session.rows.isEmpty) {
      return Text(
        NearMeCopy.noAnchorMatch,
        key: const Key('near-me-empty'),
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.brown.shade600),
      );
    }
    return _results(heading: NearMeCopy.sortedFrom(label), shrinkWrap: true);
  }

  List<NearbyTemple> get _visibleRows {
    final rows = _session.rows;
    if (_tradition == null || _tradition!.isEmpty) return rows;
    return [
      for (final row in rows)
        if (traditionMatches(row.temple, _tradition)) row,
    ];
  }

  bool get _showNearMeTraditionChip {
    final temples = [for (final row in _session.rows) row.temple];
    if (temples.isEmpty) return false;
    return directoryTraditionsFrom(temples).isNotEmpty;
  }

  Future<void> _pickTradition() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      final temples = [for (final row in _session.rows) row.temple];
      final next = await showDirectoryFilterSheet(
        context: context,
        temples: temples,
        selectedState: null,
        selectedDeity: null,
        selectedTradition: _tradition,
        section: DirectoryFilterSection.tradition,
        mode: FilterSheetMode.instant,
      );
      if (!mounted || next == null) return;
      setState(() => _tradition = next.tradition);
    } finally {
      _sheetOpen = false;
    }
  }

  Widget _nearMeTraditionChip() {
    final selected = _tradition != null && _tradition!.isNotEmpty;
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        key: const Key('near-me-tradition-chip'),
        avatar: selected
            ? PlaceTypeIcon.forKey(traditionKey: _tradition, size: 16)
            : const TraditionArchIcon(size: 16),
        label: Text(
          selected ? directoryTraditionChipLabel(_tradition!) : 'Tradition',
        ),
        onPressed: _pickTradition,
      ),
    );
  }

  Widget _results({required String heading, bool shrinkWrap = false}) {
    final rows = _visibleRows;
    final children = <Widget>[
      Text(
        heading,
        key: const Key('near-me-heading'),
        style: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _deepSaffron,
        ),
      ),
      if (!shrinkWrap && _session.usingLastKnown) ...[
        const SizedBox(height: 8),
        Text(
          NearMeCopy.lastKnownNote,
          key: const Key('near-me-last-known'),
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _actionButton(
          key: const Key('near-me-retry'),
          label: NearMeCopy.retry,
          onPressed: () => unawaited(_session.retry()),
        ),
      ],
      const SizedBox(height: 8),
      if (_showNearMeTraditionChip) ...[
        _nearMeTraditionChip(),
        const SizedBox(height: 8),
      ],
      if (rows.isEmpty)
        Text(
          NearMeCopy.noMapPoints,
          key: const Key('near-me-empty'),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.brown.shade600,
          ),
        ),
      for (final row in rows) _row(row),
    ];
    if (shrinkWrap) {
      return Column(
        key: const Key('near-me-list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ListView(
      key: const Key('near-me-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: children,
    );
  }

  Widget _row(NearbyTemple row) {
    final temple = row.temple;
    final id = temple.id.isEmpty ? temple.name : temple.id;
    final place = templeBrowsePlaceLabel(temple);
    return ListTile(
      key: Key('near-me-row-$id'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        temple.name,
        style: GoogleFonts.lora(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _saffron,
        ),
      ),
      subtitle: place.isEmpty
          ? null
          : Text(
              place,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.brown.shade600,
              ),
            ),
      trailing: Text(
        NearMeCopy.distanceLabel(row.distanceKm),
        key: Key('near-me-km-$id'),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.brown.shade700,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          namedAnalyticsRoute<void>(
            name: AnalyticsScreens.templeDetail,
            arguments: temple.id,
            builder: (_) => TempleDetailScreen(temple: temple),
          ),
        );
      },
    );
  }

  Widget _placeButton({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _deepSaffron,
        side: const BorderSide(color: Color(0xFFFFD54F)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _actionButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
    bool filled = true,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: _saffron,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          )
        : TextButton.styleFrom(
            foregroundColor: _deepSaffron,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          );
    final child = Text(label);
    if (!filled) {
      return TextButton(
        key: key,
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  Future<void> _chooseState() async {
    final states = nearbyStates(widget.temples);
    final picked = await _pickPlace(
      title: 'Sort from state',
      sectionKey: const Key('filter-section-state'),
      searchHint: 'Search state',
      subtitle: Text(
        'Tap a state to sort places by distance from it',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: FilterSheetColors.of(context).muted,
        ),
      ),
      forceSearch: states.length > 8,
      sections: _stateSections(states),
      selectedId: _session.anchorState == null
          ? null
          : 'near-me-state-option-${_session.anchorState}',
    );
    if (!mounted || picked == null || picked.isEmpty) return;
    _session.selectState(picked);
  }

  Future<void> _chooseCity() async {
    final state = _session.anchorState;
    if (state == null) return;
    final cities = nearbyCities(widget.temples, state: state);
    final picked = await _pickPlace(
      title: 'City',
      sectionKey: const Key('near-me-city-sheet'),
      searchHint: 'Search city',
      subtitle: Text(
        'In $state',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: FilterSheetColors.of(context).muted,
        ),
      ),
      any: FilterSheetOption(
        id: 'near-me-city-option-any',
        label: NearMeCopy.anyCity,
        count: _count((temple) => temple.state.trim() == state),
        value: '',
        selected: _session.anchorCity == null,
      ),
      sections: [
        FilterSheetSection(
          id: 'cities',
          title: '',
          options: [
            for (final city in cities)
              FilterSheetOption(
                id: 'near-me-city-option-$city',
                label: city,
                count: _count(
                  (temple) =>
                      temple.state.trim() == state &&
                      temple.city.trim() == city,
                ),
                value: city,
                selected: _session.anchorCity == city,
              ),
          ],
        ),
      ],
      selectedId: _session.anchorCity == null
          ? 'near-me-city-option-any'
          : 'near-me-city-option-${_session.anchorCity}',
    );
    if (!mounted || picked == null) return;
    _session.selectCity(picked.isEmpty ? null : picked);
  }

  Future<void> _chooseDistrict() async {
    if (widget.districtOf == null) {
      await DistrictDirectory.instance.ensureFor(widget.temples);
      if (!mounted) return;
      setState(() {});
    }
    final lookup = widget.districtOf ?? DistrictDirectory.instance.peek;
    final state = _session.anchorState;
    final districts = nearbyDistricts(
      widget.temples,
      state: state,
      districtOf: lookup,
    );
    final picked = await _pickPlace(
      title: 'District',
      sectionKey: const Key('filter-section-district'),
      searchHint: 'Search district',
      subtitle: state == null
          ? null
          : Text(
              'In $state',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: FilterSheetColors.of(context).muted,
              ),
            ),
      any: FilterSheetOption(
        id: 'near-me-district-option-any',
        label: NearMeCopy.anyDistrict,
        count: _count(
          (temple) => state == null || temple.state.trim() == state,
        ),
        value: '',
        selected: _session.anchorDistrict == null,
      ),
      sections: [
        FilterSheetSection(
          id: 'districts',
          title: '',
          options: [
            for (final district in districts)
              FilterSheetOption(
                id: 'near-me-district-option-$district',
                label: district,
                count: _count((temple) {
                  if (state != null && temple.state.trim() != state) {
                    return false;
                  }
                  return (lookup(temple)?.trim() ?? '') == district;
                }),
                value: district,
                selected: _session.anchorDistrict == district,
              ),
          ],
        ),
      ],
      selectedId: _session.anchorDistrict == null
          ? 'near-me-district-option-any'
          : 'near-me-district-option-${_session.anchorDistrict}',
    );
    if (!mounted || picked == null) return;
    _session.selectDistrict(picked.isEmpty ? null : picked);
  }

  int _count(bool Function(Temple temple) test) {
    var count = 0;
    for (final temple in widget.temples) {
      if (test(temple)) count++;
    }
    return count;
  }

  List<FilterSheetSection> _stateSections(List<String> states) {
    return [
      for (final group in groupStatesByRegion(states))
        FilterSheetSection(
          id: group.id,
          title: group.title,
          total: group.states.fold<int>(
            0,
            (sum, state) =>
                sum + _count((temple) => temple.state.trim() == state),
          ),
          options: [
            for (final state in group.states)
              FilterSheetOption(
                id: 'near-me-state-option-$state',
                label: state,
                count: _count((temple) => temple.state.trim() == state),
                value: state,
                selected: _session.anchorState == state,
                badge: indiaStateIsUnionTerritory(state) ? 'UT' : null,
              ),
          ],
        ),
    ];
  }

  Future<String?> _pickPlace({
    required String title,
    required Key sectionKey,
    required String searchHint,
    Widget? subtitle,
    FilterSheetOption? any,
    required List<FilterSheetSection> sections,
    String? selectedId,
    bool forceSearch = false,
  }) {
    final colors = FilterSheetColors.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: colors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterSheetScaffold(
          title: title,
          sectionKey: sectionKey,
          subtitle: subtitle,
          searchHint: searchHint,
          forceSearch: forceSearch,
          any: any,
          sections: sections,
          mode: FilterSheetMode.instant,
          scrollToId: selectedId,
          onOption: (option) => Navigator.pop(context, option.value),
        );
      },
    );
  }
}

class _RationaleSheet extends StatelessWidget {
  const _RationaleSheet();

  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _deepSaffron = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      key: const Key('near-me-rationale-sheet'),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.brown.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            NearMeCopy.rationaleTitle,
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _deepSaffron,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NearMeCopy.rationaleBody,
            key: const Key('near-me-rationale'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('near-me-continue'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saffron,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            child: const Text(NearMeCopy.continueLabel),
          ),
          TextButton(
            key: const Key('near-me-not-now'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text(NearMeCopy.notNow),
          ),
        ],
      ),
    );
  }
}
