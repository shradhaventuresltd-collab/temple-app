import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// State, district, and deity chosen in the filter sheet.
typedef DirectoryFilterSelection = ({
  String? state,
  String? deity,
  String? district,
});

/// Which filter the sheet opens on. The sheet still lists the others below.
enum DirectoryFilterSection { state, district, deity }

/// Opens the shared filter sheet.
///
/// Returns the selection when the user applies it. Returns null when the
/// sheet is dismissed, so the caller keeps the previous chips.
/// [districtOf] is null until the boundary asset has been opened.
/// [districtLookup] loads that asset while the sheet is already on screen.
/// [section] is the list the user tapped. That block is shown first.
Future<DirectoryFilterSelection?> showDirectoryFilterSheet({
  required BuildContext context,
  required List<Temple> temples,
  required String? selectedState,
  required String? selectedDeity,
  String? selectedDistrict,
  String query = '',
  TempleDistrictName? districtOf,
  Future<TempleDistrictName?>? districtLookup,
  DirectoryFilterSection section = DirectoryFilterSection.state,
}) {
  return showModalBottomSheet<DirectoryFilterSelection>(
    context: context,
    isScrollControlled: true,
    // The framework drag calls setState on pointer-down, which rebuilds this
    // builder. The header swipe is handled by the sheet's own Listener, so
    // the route must not also drag. A rebuild here used to rescan the
    // directory once per option on the UI thread (the district-sheet ANR).
    enableDrag: false,
    backgroundColor: const Color(0xFFFFFBF2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _DirectoryFilterSheet(
        temples: temples,
        initialState: selectedState,
        initialDeity: selectedDeity,
        initialDistrict: selectedDistrict,
        query: query,
        districtOf: districtOf,
        districtLookup: districtLookup,
        initialSection: section,
      );
    },
  );
}

/// The filter sheet, pumped directly by tests.
///
/// The modal route captures its arguments once. Tests that change the draft
/// query or the temple list update this widget in place, and the sheet state
/// keeps its census cache.
@visibleForTesting
class DirectoryFilterSheetProbe extends StatelessWidget {
  const DirectoryFilterSheetProbe({
    super.key,
    required this.temples,
    required this.query,
    this.selectedState,
    this.selectedDeity,
    this.selectedDistrict,
    this.districtOf,
  });

  final List<Temple> temples;
  final String query;
  final String? selectedState;
  final String? selectedDeity;
  final String? selectedDistrict;
  final TempleDistrictName? districtOf;

  @override
  Widget build(BuildContext context) {
    return _DirectoryFilterSheet(
      key: const ValueKey('directory-filter-sheet-probe'),
      temples: temples,
      initialState: selectedState,
      initialDeity: selectedDeity,
      initialDistrict: selectedDistrict,
      query: query,
      districtOf: districtOf,
      districtLookup: null,
      initialSection: DirectoryFilterSection.state,
    );
  }
}

/// Trigger chips for state, district, and deity. Each chip opens that list.
///
/// The district asset loads only when the district chip is opened.
class DirectoryFilterBar extends StatefulWidget {
  const DirectoryFilterBar({
    super.key,
    required this.temples,
    required this.selectedState,
    required this.selectedDeity,
    required this.onChanged,
    this.selectedDistrict,
    this.query = '',
    this.districtOf,
    this.prepareDistricts,
    this.onDistrictsLoaded,
    this.onClearAll,
  });

  final List<Temple> temples;
  final String? selectedState;
  final String? selectedDeity;
  final String? selectedDistrict;
  final String query;

  /// Null until boundaries have been loaded. Names come from the loaded index.
  final TempleDistrictName? districtOf;

  /// Called only from the district chip, as the sheet opens.
  ///
  /// The sheet is already on the navigator, with a loader where the district
  /// names will go. Must not rebuild the bar. A setState here runs while the
  /// sheet route is being pushed and the district list then swallows the
  /// dismiss drag.
  final Future<TempleDistrictName?> Function()? prepareDistricts;

  /// Called after the district sheet closes, so the bar can show loaded names.
  final VoidCallback? onDistrictsLoaded;

  /// Called with the new triple. Any value may be null (that chip is cleared).
  final void Function(String? state, String? deity, String? district) onChanged;

  /// Bar Clear. When set, a cleared triple is not also reported through
  /// [onChanged], so the caller can drop the search text with the filters.
  final VoidCallback? onClearAll;

  @override
  State<DirectoryFilterBar> createState() => _DirectoryFilterBarState();
}

class _DirectoryFilterBarState extends State<DirectoryFilterBar> {
  final ScrollController _chipScroll = ScrollController();

  /// True from the moment a chip asks for the sheet until that route pops.
  ///
  /// The district sheet is pushed before boundaries finish loading, so Back
  /// pops the sheet and leaves All Temples on the stack. The flag drops when
  /// that route pops, including while the load is still running, so the next
  /// deity tap is not swallowed.
  bool _opening = false;
  final GlobalKey _stateChip = GlobalKey();
  final GlobalKey _districtChip = GlobalKey();
  final GlobalKey _deityChip = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(DirectoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedState != widget.selectedState ||
        oldWidget.selectedDeity != widget.selectedDeity ||
        oldWidget.selectedDistrict != widget.selectedDistrict) {
      _scheduleReveal();
    }
  }

  @override
  void dispose() {
    _chipScroll.dispose();
    super.dispose();
  }

  /// The rightmost selected chip stays on screen at 320dp. State sits at the
  /// start of the row; a selected deity used to be clipped past the edge.
  ///
  /// Only [_chipScroll] moves. [Scrollable.ensureVisible] would also scroll
  /// every ancestor, including the drawer list that holds this bar.
  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipScroll.hasClients) return;
      final target = _chipToReveal()?.currentContext?.findRenderObject();
      if (target is! RenderBox || !target.hasSize || !target.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(target);
      if (viewport == null) return;
      final position = _chipScroll.position;
      final next = viewport
          .getOffsetToReveal(target, 1)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((next - position.pixels).abs() < 0.5) return;
      _chipScroll.animateTo(
        next,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  GlobalKey? _chipToReveal() {
    if (widget.selectedDeity != null) return _deityChip;
    final district = widget.selectedDistrict;
    if (district != null && district.isNotEmpty) return _districtChip;
    if (widget.selectedState != null) return _stateChip;
    return null;
  }

  bool get _active =>
      widget.selectedState != null ||
      widget.selectedDeity != null ||
      (widget.selectedDistrict != null && widget.selectedDistrict!.isNotEmpty);

  bool get _showDistrict => directoryDistrictChipVisible(
    temples: widget.temples,
    state: widget.selectedState,
    selectedDistrict: widget.selectedDistrict,
    districtOf: widget.districtOf,
  );

  Future<void> _openSheet({
    required bool loadDistricts,
    required DirectoryFilterSection section,
  }) async {
    if (_opening) return;
    _opening = true;
    Future<TempleDistrictName?>? pending;
    DirectoryFilterSelection? result;
    try {
      final lookup = widget.districtOf;
      if (loadDistricts && lookup == null) {
        final prepare = widget.prepareDistricts;
        if (prepare != null) {
          pending = _startDistrictLoad(prepare);
        }
      }
      if (!mounted) return;
      result =
          await showDirectoryFilterSheet(
            context: context,
            temples: widget.temples,
            selectedState: widget.selectedState,
            selectedDeity: widget.selectedDeity,
            selectedDistrict: widget.selectedDistrict,
            query: widget.query,
            districtOf: lookup,
            districtLookup: pending,
            section: section,
          ).whenComplete(() {
            _opening = false;
          });
    } catch (error, stack) {
      debugPrint('Filter sheet did not open: $error\n$stack');
    } finally {
      _opening = false;
    }
    if (!mounted) return;
    // Apply before the boundary load finishes. Waiting here drops a State or
    // Deity apply when the load hangs, and a late apply can overwrite a newer
    // one from another chip.
    if (result != null) {
      widget.onChanged(result.state, result.deity, result.district);
    }
    final load = pending;
    if (load != null) unawaited(_finishDistrictLoad(load));
  }

  Future<void> _finishDistrictLoad(Future<TempleDistrictName?> pending) async {
    var loaded = false;
    try {
      await pending;
      loaded = true;
    } catch (_) {
      // Reported when the load was started.
    }
    if (loaded && mounted) widget.onDistrictsLoaded?.call();
  }

  /// Starts the boundary load and attaches an error listener immediately.
  ///
  /// The sheet listens too. A later `await` is another listener, so this one
  /// has to exist before the future can fail, including a synchronous throw
  /// from [prepare].
  Future<TempleDistrictName?> _startDistrictLoad(
    Future<TempleDistrictName?> Function() prepare,
  ) {
    Future<TempleDistrictName?> pending;
    try {
      pending = prepare();
    } catch (error, stack) {
      pending = Future<TempleDistrictName?>.error(error, stack);
    }
    unawaited(
      pending.then(
        (_) {},
        onError: (Object error, StackTrace stack) {
          debugPrint('District boundaries did not load: $error\n$stack');
        },
      ),
    );
    return pending;
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = widget.selectedState;
    final selectedDeity = widget.selectedDeity;
    final selectedDistrict = widget.selectedDistrict;
    final clear = _active
        ? Semantics(
            identifier: 'filter-clear',
            button: true,
            child: TextButton(
              key: const Key('filter-clear'),
              onPressed:
                  widget.onClearAll ?? () => widget.onChanged(null, null, null),
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _deepSaffron,
                ),
              ),
            ),
          )
        : null;
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _chipScroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KeyedSubtree(
                  key: _stateChip,
                  child: _TriggerChip(
                    chipKey: const Key('filter-chip-state'),
                    semanticsId: 'filter-chip-state',
                    clearKey: const Key('filter-chip-state-clear'),
                    icon: Icons.place_rounded,
                    label: selectedState ?? 'State',
                    selected: selectedState != null,
                    openTooltip: 'Choose a state',
                    clearTooltip: 'Clear state filter',
                    onOpen: () => _openSheet(
                      loadDistricts: false,
                      section: DirectoryFilterSection.state,
                    ),
                    onClear: () =>
                        widget.onChanged(null, selectedDeity, selectedDistrict),
                  ),
                ),
                if (_showDistrict) ...[
                  const SizedBox(width: 8),
                  KeyedSubtree(
                    key: _districtChip,
                    child: _TriggerChip(
                      chipKey: const Key('filter-chip-district'),
                      semanticsId: 'filter-chip-district',
                      clearKey: const Key('filter-chip-district-clear'),
                      icon: Icons.map_outlined,
                      label:
                          selectedDistrict == null || selectedDistrict.isEmpty
                          ? 'All districts'
                          : selectedDistrict,
                      selected:
                          selectedDistrict != null &&
                          selectedDistrict.isNotEmpty,
                      openTooltip: 'Choose a district',
                      clearTooltip: 'Clear district filter',
                      onOpen: () => _openSheet(
                        loadDistricts: true,
                        section: DirectoryFilterSection.district,
                      ),
                      onClear: () =>
                          widget.onChanged(selectedState, selectedDeity, null),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                KeyedSubtree(
                  key: _deityChip,
                  child: _TriggerChip(
                    chipKey: const Key('filter-chip-deity'),
                    semanticsId: 'filter-chip-deity',
                    clearKey: const Key('filter-chip-deity-clear'),
                    icon: Icons.auto_awesome_rounded,
                    label: selectedDeity == null
                        ? 'Deity'
                        : directoryDeityChipLabel(selectedDeity),
                    selected: selectedDeity != null,
                    openTooltip: 'Choose a deity',
                    clearTooltip: 'Clear deity filter',
                    onOpen: () => _openSheet(
                      loadDistricts: false,
                      section: DirectoryFilterSection.deity,
                    ),
                    onClear: () =>
                        widget.onChanged(selectedState, null, selectedDistrict),
                  ),
                ),
              ],
            ),
          ),
        ),
        ?clear,
      ],
    );
  }
}

class _DirectoryFilterSheet extends StatefulWidget {
  const _DirectoryFilterSheet({
    super.key,
    required this.temples,
    required this.initialState,
    required this.initialDeity,
    required this.initialDistrict,
    required this.query,
    required this.districtOf,
    required this.districtLookup,
    required this.initialSection,
  });

  final List<Temple> temples;
  final String? initialState;
  final String? initialDeity;
  final String? initialDistrict;
  final String query;
  final TempleDistrictName? districtOf;

  /// In flight when the district chip opened before boundaries were ready.
  final Future<TempleDistrictName?>? districtLookup;
  final DirectoryFilterSection initialSection;

  @override
  State<_DirectoryFilterSheet> createState() => _DirectoryFilterSheetState();
}

class _DirectoryFilterSheetState extends State<_DirectoryFilterSheet> {
  String? _state;
  String? _deity;
  String? _district;
  TempleDistrictName? _resolvedDistrictOf;
  bool _districtsLoading = false;
  bool _districtError = false;

  /// A swipe on the option list does not move the sheet. The list wins the
  /// drag, so the modal route stays current and the next chip tap never
  /// lands. [_dismiss] pops that route once the pull passes the threshold.
  ///
  /// The district list is long enough that a downward drag never overscrolls.
  /// [_options] plus the [Listener] below dismiss that drag when it starts
  /// at the top, including a swipe that begins on the Filters title.
  final ScrollController _options = ScrollController();
  bool _dismissed = false;
  bool _pullArmed = false;
  double _pullDown = 0;
  double _overscrollPull = 0;
  double _pointerY = 0;

  /// Option counts for the current draft. A drag rebuilds the sheet without
  /// changing the draft, so the walk must not run again.
  DirectoryOptionCensus? _census;
  String? _censusKey;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _deity = widget.initialDeity;
    _district = widget.initialDistrict;
    _resolvedDistrictOf = widget.districtOf;
    final pending = widget.districtLookup;
    if (widget.districtOf == null && pending != null) {
      _districtsLoading = true;
      unawaited(
        pending.then(
          (lookup) {
            if (!mounted) return;
            setState(() {
              _resolvedDistrictOf = lookup;
              _districtsLoading = false;
              _districtError = lookup == null;
            });
          },
          onError: (Object _, StackTrace _) {
            if (!mounted) return;
            setState(() {
              _districtsLoading = false;
              _districtError = true;
            });
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _options.dispose();
    super.dispose();
  }

  bool get _listAtTop => !_options.hasClients || _options.offset <= 0;

  DirectoryOptionCensus _readCensus() {
    final key =
        '${_state ?? ''}\u0000${_deity ?? ''}\u0000${_district ?? ''}\u0000${identityHashCode(_resolvedDistrictOf)}\u0000${widget.query}\u0000${identityHashCode(widget.temples)}';
    final cached = _census;
    if (cached != null && _censusKey == key) return cached;
    final next = directoryOptionCensus(
      widget.temples,
      state: _state,
      deity: _deity,
      district: _district,
      query: widget.query,
      districtOf: _resolvedDistrictOf,
    );
    _census = next;
    _censusKey = key;
    return next;
  }

  bool _showChoice(int count, bool selected) => selected || count > 0;

  /// Pops this sheet with null. A second notification in the same gesture
  /// must not pop the page underneath.
  void _dismiss() {
    if (_dismissed || !mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    _dismissed = true;
    Navigator.of(context).pop();
  }

  bool _pullToDismiss(ScrollNotification notification) {
    if (_dismissed) return false;
    if (notification is OverscrollNotification &&
        notification.overscroll < 0 &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      _overscrollPull += -notification.overscroll;
      if (_overscrollPull >= 72) _dismiss();
      return false;
    }
    if (notification is ScrollEndNotification) _overscrollPull = 0;
    return false;
  }

  /// The title, handle, and blurb sit above the option list. A downward
  /// pull there dismisses even when that list is scrolled. A pull on the
  /// list itself dismisses only from the top, so a scroll back up is kept.
  bool _eventOnHeader(Offset global) {
    if (!_options.hasClients) return false;
    final object = _options.position.context.storageContext.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return false;
    }
    return global.dy < object.localToGlobal(Offset.zero).dy;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerY = event.position.dy;
    _pullArmed = _listAtTop || _eventOnHeader(event.position);
    if (_pullArmed) _pullDown = 0;
  }

  /// Downward travel from the header, or from the list when it is already
  /// at the top. An upward move is a scroll into the list, so that gesture
  /// must not dismiss.
  void _onPointerMove(PointerMoveEvent event) {
    final dy = event.position.dy - _pointerY;
    _pointerY = event.position.dy;
    if (_dismissed || !_pullArmed) return;
    // A move with no vertical travel (horizontal jitter, or the first
    // sample of `adb shell input swipe`, which repeats the down point) is
    // not an upward scroll. Disarming on it made a header pull never
    // dismiss the sheet.
    if (dy == 0) return;
    if (dy < 0) {
      _pullArmed = false;
      _pullDown = 0;
      return;
    }
    _pullDown += dy;
    if (_pullDown >= 72) _dismiss();
  }

  void _onPointerEnd(PointerEvent event) {
    _pullArmed = false;
    if (!_dismissed) _pullDown = 0;
  }

  void _chooseState(String? state) {
    final names = directoryDistrictsFrom(
      widget.temples,
      state: state,
      districtOf: _resolvedDistrictOf,
    );
    setState(() {
      _state = state;
      if (_district != null && !names.contains(_district)) {
        _district = null;
      }
    });
  }

  /// One count per chip. The any/all chip is always listed. A zero-count
  /// option stays only when it is the current selection.
  List<Widget> _labeledOptions({
    required String prefix,
    required String anyLabel,
    required int anyCount,
    required bool anySelected,
    required VoidCallback onAny,
    required List<String> names,
    required int Function(String name) countOf,
    required bool Function(String name) isSelected,
    required String Function(String name) labelOf,
    required void Function(String name) onSelect,
  }) {
    final chips = <Widget>[
      _OptionChip(
        optionKey: Key('$prefix-any'),
        label: anyLabel,
        count: anyCount,
        selected: anySelected,
        onTap: onAny,
      ),
    ];
    for (final name in names) {
      final count = countOf(name);
      final selected = isSelected(name);
      if (!_showChoice(count, selected)) continue;
      chips.add(
        _OptionChip(
          optionKey: Key('$prefix-$name'),
          label: labelOf(name),
          count: count,
          selected: selected,
          onTap: () => onSelect(name),
        ),
      );
    }
    return chips;
  }

  /// The tapped section leads. One sheet still holds the other filters,
  /// but the list the user asked for is the one on screen.
  List<Widget> _sections({
    required List<String> states,
    required List<String> deities,
    required List<String> districts,
    required bool showDistricts,
    required String? note,
    required DirectoryOptionCensus census,
  }) {
    final stateSection = <Widget>[
      const _SheetSectionLabel('STATE', key: Key('filter-section-state')),
      const SizedBox(height: 8),
      _OptionWrap(
        children: _labeledOptions(
          prefix: 'filter-option-state',
          anyLabel: 'Any state',
          anyCount: census.anyState,
          anySelected: _state == null,
          onAny: () => _chooseState(null),
          names: states,
          countOf: census.stateCount,
          isSelected: (state) => _state == state,
          labelOf: (state) => state,
          onSelect: _chooseState,
        ),
      ),
    ];
    final districtSection = <Widget>[
      if (_districtsLoading)
        const _DistrictLoading()
      else if (_districtError)
        const _DistrictLoadError()
      else ...[
        const _SheetSectionLabel(
          'DISTRICT',
          key: Key('filter-section-district'),
        ),
        const SizedBox(height: 8),
        _OptionWrap(
          children: _labeledOptions(
            prefix: 'filter-option-district',
            anyLabel: 'All districts',
            anyCount: census.anyDistrict,
            anySelected: _district == null || _district!.isEmpty,
            onAny: () => setState(() => _district = null),
            names: districts,
            countOf: census.districtCount,
            isSelected: (district) => _district == district,
            labelOf: (district) => district,
            onSelect: (district) => setState(() => _district = district),
          ),
        ),
      ],
    ];
    final deitySection = <Widget>[
      const _SheetSectionLabel('DEITY', key: Key('filter-section-deity')),
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(
          note,
          key: const Key('filter-deity-note'),
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.4,
            color: Colors.brown.shade600,
          ),
        ),
      ],
      const SizedBox(height: 8),
      _OptionWrap(
        children: _labeledOptions(
          prefix: 'filter-option-deity',
          anyLabel: 'Any deity',
          anyCount: census.anyDeity,
          anySelected: _deity == null,
          onAny: () => setState(() => _deity = null),
          names: deities,
          countOf: census.deityCount,
          isSelected: (deity) => _deity == deity,
          labelOf: directoryDeityChipLabel,
          onSelect: (deity) => setState(() => _deity = deity),
        ),
      ),
    ];

    var focus = widget.initialSection;
    if (focus == DirectoryFilterSection.district && !showDistricts) {
      focus = DirectoryFilterSection.state;
    }
    final blocks = <DirectoryFilterSection, List<Widget>>{
      DirectoryFilterSection.state: stateSection,
      DirectoryFilterSection.deity: deitySection,
      if (showDistricts) DirectoryFilterSection.district: districtSection,
    };
    const rest = [
      DirectoryFilterSection.state,
      DirectoryFilterSection.district,
      DirectoryFilterSection.deity,
    ];
    final children = <Widget>[];
    for (final section in [focus, ...rest]) {
      final block = blocks[section];
      if (block == null || block.isEmpty) continue;
      blocks.remove(section);
      if (children.isNotEmpty) children.add(const SizedBox(height: 18));
      children.addAll(block);
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final states = directoryStatesFrom(widget.temples);
    final deities = directoryDeitiesFrom(widget.temples);
    final districts = directoryDistrictsFrom(
      widget.temples,
      state: _state,
      districtOf: _resolvedDistrictOf,
    );
    final showDistricts =
        _districtsLoading ||
        _districtError ||
        (_resolvedDistrictOf != null &&
            (districts.isNotEmpty ||
                (_district != null && _district!.isNotEmpty)));
    final note = directoryDeityFilterNote(deities);
    final census = _readCensus();
    final matched = census.matched;
    final draftActive =
        _state != null ||
        _deity != null ||
        (_district != null && _district!.isNotEmpty);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: SafeArea(
        child: SizedBox(
          key: const Key('filter-sheet'),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Filters',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _deepSaffron,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('filter-sheet-close'),
                      tooltip: 'Close filters',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  showDistricts
                      ? 'State, district, and deity, on the temples already loaded.'
                      : 'State and deity, on the temples already loaded.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.brown.shade500,
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _pullToDismiss,
                  child: ListView(
                    controller: _options,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    children: _sections(
                      states: states,
                      deities: deities,
                      districts: districts,
                      showDistricts: showDistricts,
                      note: note,
                      census: census,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Semantics(
                      identifier: 'filter-sheet-clear',
                      button: true,
                      enabled: draftActive,
                      child: TextButton(
                        key: const Key('filter-sheet-clear'),
                        onPressed: draftActive
                            ? () => setState(() {
                                _state = null;
                                _deity = null;
                                _district = null;
                              })
                            : null,
                        child: Text(
                          'Clear',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: draftActive
                                ? _deepSaffron
                                : Colors.brown.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        key: const Key('filter-sheet-apply'),
                        style: FilledButton.styleFrom(
                          backgroundColor: TempleBrowseCard.saffron,
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
                        onPressed: () {
                          Navigator.pop(context, (
                            state: _state,
                            deity: _deity,
                            district: _district,
                          ));
                        },
                        child: Text(directoryFilterResultLabel(matched)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistrictLoading extends StatelessWidget {
  const _DistrictLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'filter-district-loading',
      label: 'Loading districts',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                key: Key('filter-district-loading'),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading districts',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictLoadError extends StatelessWidget {
  const _DistrictLoadError();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'filter-district-error',
      label: 'Districts could not be loaded',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Districts could not be loaded',
          key: const Key('filter-district-error'),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade600,
          ),
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.brown.shade400,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.optionKey,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF6D4C41);
    final empty = count == 0 && !selected;
    final chipKey = optionKey;
    final semanticsId = chipKey is ValueKey<String> ? chipKey.value : null;
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: Material(
        color: selected
            ? TempleBrowseCard.saffron
            : empty
            ? const Color(0xFFFFF8EE)
            : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? TempleBrowseCard.saffron : TempleBrowseCard.gold,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: optionKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: '  $count',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withAlpha(230)
                          : empty
                          ? Colors.brown.shade300
                          : Colors.brown.shade400,
                    ),
                  ),
                ],
              ),
              softWrap: true,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: empty ? Colors.brown.shade300 : foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({
    required this.chipKey,
    this.semanticsId,
    required this.clearKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.openTooltip,
    required this.clearTooltip,
    required this.onOpen,
    required this.onClear,
  });

  final Key chipKey;
  final String? semanticsId;
  final Key clearKey;
  final IconData icon;
  final String label;
  final bool selected;
  final String openTooltip;
  final String clearTooltip;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF6D4C41);
    return Material(
      color: selected ? TempleBrowseCard.saffron : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? TempleBrowseCard.saffron : TempleBrowseCard.gold,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: semanticsId,
            button: semanticsId != null,
            child: InkWell(
              key: chipKey,
              onTap: onOpen,
              child: Tooltip(
                message: openTooltip,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, selected ? 4 : 10, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : TempleBrowseCard.saffron,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          label,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ),
                      if (!selected) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: Colors.brown.shade400,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            IconButton(
              key: clearKey,
              tooltip: clearTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

const Color _deepSaffron = Color(0xFFE65100);
