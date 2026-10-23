import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/near_me/geolocator_coarse_location.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/near_me/near_me_session.dart';
import 'package:temple_app/near_me/nearby_temples.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// Sorted temples from one coarse fix, or from a state/city centroid.
///
/// [temples] is the directory already on screen. This widget does not read
/// Firestore. Pass [location] in tests. [districtOf] stays [indexDistrictName]
/// until district names exist on the loaded entries.
class TemplesNearMeScreen extends StatefulWidget {
  const TemplesNearMeScreen({
    super.key,
    required this.temples,
    this.location,
    this.districtOf = indexDistrictName,
  });

  final List<Temple> temples;
  final CoarseLocationClient? location;
  final TempleDistrictLookup districtOf;

  @override
  State<TemplesNearMeScreen> createState() => _TemplesNearMeScreenState();
}

class _TemplesNearMeScreenState extends State<TemplesNearMeScreen> {
  static const Color _saffron = Color(0xFFFF8F00);
  static const Color _cream = Color(0xFFFFFBF2);
  static const Color _deepSaffron = Color(0xFFE65100);

  late final NearMeSession _session;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _session = NearMeSession(
      temples: widget.temples,
      location: widget.location ?? GeolocatorCoarseLocation(),
      districtOf: widget.districtOf,
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
    _session.removeListener(_onSession);
    _session.dispose();
    super.dispose();
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

  Widget _fallback() {
    final districts = nearbyDistricts(
      widget.temples,
      state: _session.anchorState,
      districtOf: widget.districtOf,
    );
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
        if (districts.isNotEmpty) ...[
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

  Widget _results({required String heading, bool shrinkWrap = false}) {
    final rows = _session.rows;
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
      const SizedBox(height: 8),
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
          MaterialPageRoute(builder: (_) => TempleDetailScreen(temple: temple)),
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
    final picked = await _pick(
      options: [
        for (final state in states)
          (id: 'near-me-state-option-$state', value: state, label: state),
      ],
    );
    if (!mounted || picked == null) return;
    _session.selectState(picked);
  }

  Future<void> _chooseCity() async {
    final state = _session.anchorState;
    if (state == null) return;
    final cities = nearbyCities(widget.temples, state: state);
    final picked = await _pick(
      options: [
        (id: 'near-me-city-option-any', value: '', label: NearMeCopy.anyCity),
        for (final city in cities)
          (id: 'near-me-city-option-$city', value: city, label: city),
      ],
    );
    if (!mounted || picked == null) return;
    _session.selectCity(picked.isEmpty ? null : picked);
  }

  Future<void> _chooseDistrict() async {
    final districts = nearbyDistricts(
      widget.temples,
      state: _session.anchorState,
      districtOf: widget.districtOf,
    );
    final picked = await _pick(
      options: [
        (
          id: 'near-me-district-option-any',
          value: '',
          label: NearMeCopy.anyDistrict,
        ),
        for (final district in districts)
          (
            id: 'near-me-district-option-$district',
            value: district,
            label: district,
          ),
      ],
    );
    if (!mounted || picked == null) return;
    _session.selectDistrict(picked.isEmpty ? null : picked);
  }

  Future<String?> _pick({
    required List<({String id, String value, String label})> options,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cream,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              for (final option in options)
                ListTile(
                  key: Key(option.id),
                  title: Text(option.label),
                  onTap: () => Navigator.pop(context, option.value),
                ),
            ],
          ),
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
