import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/deity_groups.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/india_regions.dart';
import 'package:temple_app/widgets/filter_sheet.dart';

/// State, district, and deity chosen in a filter sheet.
typedef DirectoryFilterSelection = ({
  String? state,
  String? deity,
  String? district,
});

/// Which filter the sheet opens on. Each value is its own sheet.
enum DirectoryFilterSection { state, district, deity }

/// Opens one filter sheet.
///
/// Returns the selection when the user applies it. Returns null when the
/// sheet is dismissed, so the caller keeps the previous chips.
/// [districtOf] is null until the boundary asset has been opened.
/// [districtLookup] loads that asset while a district sheet is already up.
Future<DirectoryFilterSelection?> showDirectoryFilterSheet({
  required BuildContext context,
  required List<Temple> temples,
  required String? selectedState,
  required String? selectedDeity,
  String? selectedDistrict,
  String query = '',
  TempleDistrictName? districtOf,
  Future<TempleDistrictName?>? districtLookup,
  Future<TempleDistrictName?> Function()? retryDistricts,
  DirectoryFilterSection section = DirectoryFilterSection.state,
  bool chooseStateFirst = false,
  void Function(DirectoryFilterSelection selection)? onLiveChange,
}) {
  final colors = FilterSheetColors.of(context);
  return showModalBottomSheet<DirectoryFilterSelection>(
    context: context,
    isScrollControlled: true,
    // The framework drag calls setState on pointer-down, which rebuilds this
    // builder. The header swipe is handled by the sheet's own Listener, so
    // the route must not also drag.
    enableDrag: false,
    backgroundColor: colors.sheetBackground,
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
        retryDistricts: retryDistricts,
        initialSection: section,
        chooseStateFirst: chooseStateFirst,
        onLiveChange: onLiveChange,
      );
    },
  );
}

/// The filter sheet, pumped directly by tests.
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
    this.section = DirectoryFilterSection.state,
  });

  final List<Temple> temples;
  final String query;
  final String? selectedState;
  final String? selectedDeity;
  final String? selectedDistrict;
  final TempleDistrictName? districtOf;
  final DirectoryFilterSection section;

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
      retryDistricts: null,
      initialSection: section,
      chooseStateFirst: false,
      onLiveChange: null,
    );
  }
}

/// Trigger chips for state, district, and deity. Each chip opens that sheet.
///
/// The district asset loads only when the district sheet is opened.
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
  final TempleDistrictName? districtOf;

  /// Called only from the district sheet, as that sheet opens.
  final Future<TempleDistrictName?> Function()? prepareDistricts;
  final VoidCallback? onDistrictsLoaded;

  /// Called with the new triple. Any value may be null (that chip is cleared).
  final void Function(String? state, String? deity, String? district) onChanged;

  /// Bar Clear all. When set, a cleared triple is not also reported through
  /// [onChanged], so the caller can drop the search text with the filters.
  final VoidCallback? onClearAll;

  @override
  State<DirectoryFilterBar> createState() => _DirectoryFilterBarState();
}

class _DirectoryFilterBarState extends State<DirectoryFilterBar> {
  /// True from the moment a chip asks for the sheet until that route pops.
  bool _opening = false;
  final GlobalKey _stateChip = GlobalKey();
  final GlobalKey _districtChip = GlobalKey();
  final GlobalKey _deityChip = GlobalKey();

  bool get _active =>
      widget.selectedState != null ||
      widget.selectedDeity != null ||
      (widget.selectedDistrict != null && widget.selectedDistrict!.isNotEmpty);

  bool get _districtNeedsState =>
      widget.selectedState == null || widget.selectedState!.isEmpty;

  Future<void> _openSheet(DirectoryFilterSection section) async {
    if (_opening) return;
    _opening = true;
    Future<TempleDistrictName?>? pending;
    try {
      if (section == DirectoryFilterSection.district &&
          (widget.selectedState == null || widget.selectedState!.isEmpty)) {
        final chosen = await _present(
          section: DirectoryFilterSection.state,
          chooseStateFirst: true,
        );
        if (!mounted || chosen == null) return;
        widget.onChanged(chosen.state, chosen.deity, chosen.district);
        if (chosen.state == null || chosen.state!.isEmpty) return;
        // The apply tap is still finishing. Opening the district sheet on
        // that same pointer dismisses it (run 42689905451: Tamil Nadu is
        // applied, the District chip is still idle, and no sheet remains).
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
        pending = _startDistrictLoadIfNeeded();
        final district = await _present(
          section: DirectoryFilterSection.district,
          state: chosen.state,
          deity: chosen.deity,
          district: chosen.district,
          districtLookup: pending,
        );
        if (!mounted) return;
        if (district != null) {
          widget.onChanged(district.state, district.deity, district.district);
        }
        return;
      }
      if (section == DirectoryFilterSection.district) {
        pending = _startDistrictLoadIfNeeded();
      }
      final result = await _present(section: section, districtLookup: pending);
      if (!mounted) return;
      if (result != null) {
        widget.onChanged(result.state, result.deity, result.district);
      }
    } catch (error, stack) {
      debugPrint('Filter sheet did not open: $error\n$stack');
    } finally {
      _opening = false;
      final load = pending;
      if (load != null) unawaited(_finishDistrictLoad(load));
    }
  }

  Future<DirectoryFilterSelection?> _present({
    required DirectoryFilterSection section,
    bool chooseStateFirst = false,
    String? state,
    String? deity,
    String? district,
    Future<TempleDistrictName?>? districtLookup,
  }) {
    return showDirectoryFilterSheet(
      context: context,
      temples: widget.temples,
      selectedState: state ?? widget.selectedState,
      selectedDeity: deity ?? widget.selectedDeity,
      selectedDistrict: district ?? widget.selectedDistrict,
      query: widget.query,
      districtOf: widget.districtOf,
      districtLookup: districtLookup,
      retryDistricts: widget.prepareDistricts,
      section: section,
      chooseStateFirst: chooseStateFirst,
      onLiveChange: (selection) {
        widget.onChanged(selection.state, selection.deity, selection.district);
      },
    );
  }

  Future<TempleDistrictName?>? _startDistrictLoadIfNeeded() {
    if (widget.districtOf != null) return null;
    final prepare = widget.prepareDistricts;
    if (prepare == null) return null;
    return _startDistrictLoad(prepare);
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
    final colors = FilterSheetColors.of(context);
    final selectedState = widget.selectedState;
    final selectedDeity = widget.selectedDeity;
    final selectedDistrict = widget.selectedDistrict;
    final matched = directoryMatchingTemples(
      widget.temples,
      state: selectedState,
      deity: selectedDeity,
      district: selectedDistrict,
      query: widget.query,
      districtOf: widget.districtOf,
    ).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
                KeyedSubtree(
                  key: _stateChip,
                  child: _TriggerChip(
                    chipKey: const Key('filter-chip-state'),
                    semanticsId: 'filter-chip-state',
                    clearKey: const Key('filter-chip-state-clear'),
                    icon: Icons.place_outlined,
                    label: selectedState ?? 'State',
                    selected: selectedState != null,
                    openTooltip: 'Choose a state',
                    clearTooltip: 'Clear state filter',
                    onOpen: () => _openSheet(DirectoryFilterSection.state),
                    onClear: () => widget.onChanged(null, selectedDeity, null),
                  ),
                ),
                KeyedSubtree(
                  key: _districtChip,
                  child: _TriggerChip(
                    chipKey: const Key('filter-chip-district'),
                    semanticsId: 'filter-chip-district',
                    clearKey: const Key('filter-chip-district-clear'),
                    icon: Icons.account_balance_outlined,
                    label: selectedDistrict == null || selectedDistrict.isEmpty
                        ? 'District'
                        : selectedDistrict,
                    selected:
                        selectedDistrict != null && selectedDistrict.isNotEmpty,
                    openTooltip: _districtNeedsState
                        ? 'Choose a state first'
                        : 'Choose a district',
                    clearTooltip: 'Clear district filter',
                    onOpen: () => _openSheet(DirectoryFilterSection.district),
                    onClear: () =>
                        widget.onChanged(selectedState, selectedDeity, null),
                  ),
                ),
                KeyedSubtree(
                  key: _deityChip,
                  child: _TriggerChip(
                    chipKey: const Key('filter-chip-deity'),
                    semanticsId: 'filter-chip-deity',
                    clearKey: const Key('filter-chip-deity-clear'),
                    icon: Icons.auto_awesome_outlined,
                    label: selectedDeity == null
                        ? 'Deity'
                        : directoryDeityChipLabel(selectedDeity),
                    selected: selectedDeity != null,
                    openTooltip: 'Choose a deity',
                    clearTooltip: 'Clear deity filter',
                    onOpen: () => _openSheet(DirectoryFilterSection.deity),
                    onClear: () =>
                        widget.onChanged(selectedState, null, selectedDistrict),
                  ),
                ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  matched == 1 ? '1 temple' : '$matched temples',
                  key: const Key('filter-match-count'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.label,
                  ),
                ),
              ),
              if (_active)
                Semantics(
                  identifier: 'filter-clear',
                  button: true,
                  child: TextButton(
                    key: const Key('filter-clear'),
                    onPressed:
                        widget.onClearAll ??
                        () => widget.onChanged(null, null, null),
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.accentText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    required this.retryDistricts,
    required this.initialSection,
    required this.chooseStateFirst,
    required this.onLiveChange,
  });

  final List<Temple> temples;
  final String? initialState;
  final String? initialDeity;
  final String? initialDistrict;
  final String query;
  final TempleDistrictName? districtOf;
  final Future<TempleDistrictName?>? districtLookup;
  final Future<TempleDistrictName?> Function()? retryDistricts;
  final DirectoryFilterSection initialSection;
  final bool chooseStateFirst;
  final void Function(DirectoryFilterSelection selection)? onLiveChange;

  @override
  State<_DirectoryFilterSheet> createState() => _DirectoryFilterSheetState();
}

class _DirectoryFilterSheetState extends State<_DirectoryFilterSheet> {
  bool _changingState = false;
  String? _state;
  String? _deity;
  String? _district;
  TempleDistrictName? _resolvedDistrictOf;
  bool _districtsLoading = false;
  bool _districtError = false;
  DirectoryOptionCensus? _census;
  String? _censusKey;
  List<DeityGroup>? _deityGroups;
  int? _deityGroupsId;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _deity = widget.initialDeity;
    _district = widget.initialDistrict;
    _resolvedDistrictOf = widget.districtOf;
    final pending = widget.districtLookup;
    if (widget.initialSection == DirectoryFilterSection.district &&
        widget.districtOf == null &&
        pending != null) {
      _districtsLoading = true;
      unawaited(_applyLookup(pending));
    }
  }

  Future<void> _applyLookup(Future<TempleDistrictName?> pending) {
    return pending.then(
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
    );
  }

  Future<void> _retryDistricts() async {
    final retry = widget.retryDistricts;
    if (retry == null || _districtsLoading) return;
    setState(() {
      _districtsLoading = true;
      _districtError = false;
    });
    Future<TempleDistrictName?> pending;
    try {
      pending = retry();
    } catch (error, stack) {
      pending = Future<TempleDistrictName?>.error(error, stack);
    }
    await _applyLookup(pending);
  }

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

  DirectoryFilterSelection get _selection =>
      (state: _state, deity: _deity, district: _district);

  void _chooseState(String? state) {
    final changed = state != _state;
    final names = directoryDistrictsFrom(
      widget.temples,
      state: state,
      districtOf: _resolvedDistrictOf,
    );
    setState(() {
      _state = state;
      if (state == null || state.isEmpty) {
        _district = null;
      } else if (changed && _district != null && !names.contains(_district)) {
        _district = null;
      }
    });
  }

  Future<void> _changeState() async {
    if (_changingState) return;
    _changingState = true;
    try {
      await _changeStateOnce();
    } finally {
      _changingState = false;
    }
  }

  Future<void> _changeStateOnce() async {
    final next = await showDirectoryFilterSheet(
      context: context,
      temples: widget.temples,
      selectedState: _state,
      selectedDeity: _deity,
      selectedDistrict: _district,
      query: widget.query,
      districtOf: _resolvedDistrictOf,
      section: DirectoryFilterSection.state,
    );
    if (!mounted || next == null) return;
    final names = directoryDistrictsFrom(
      widget.temples,
      state: next.state,
      districtOf: _resolvedDistrictOf,
    );
    setState(() {
      _state = next.state;
      _deity = next.deity;
      if (next.state == null ||
          next.state!.isEmpty ||
          (_district != null && !names.contains(_district))) {
        _district = null;
      }
    });
    widget.onLiveChange?.call(_selection);
    if ((_state == null || _state!.isEmpty) && mounted) {
      Navigator.of(context).pop(_selection);
    }
  }

  void _clearDraft() {
    setState(() {
      switch (widget.initialSection) {
        case DirectoryFilterSection.state:
          _state = null;
          _district = null;
        case DirectoryFilterSection.district:
          _district = null;
        case DirectoryFilterSection.deity:
          _deity = null;
      }
    });
  }

  bool get _clearEnabled {
    return switch (widget.initialSection) {
      DirectoryFilterSection.state => _state != null,
      DirectoryFilterSection.district =>
        _district != null && _district!.isNotEmpty,
      DirectoryFilterSection.deity => _deity != null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final census = _readCensus();
    final colors = FilterSheetColors.of(context);
    return switch (widget.initialSection) {
      DirectoryFilterSection.state => _stateSheet(census, colors),
      DirectoryFilterSection.district => _districtSheet(census, colors),
      DirectoryFilterSection.deity => _deitySheet(census, colors),
    };
  }

  Widget _stateSheet(DirectoryOptionCensus census, FilterSheetColors colors) {
    final names = [
      for (final state in directoryStatesFrom(widget.temples))
        if (_showChoice(census.stateCount(state), _state == state)) state,
    ];
    final grouped = groupStatesByRegion(names);
    final sections = [
      for (final group in grouped)
        FilterSheetSection(
          id: group.id,
          title: group.title,
          total: group.states.fold<int>(
            0,
            (sum, state) => sum + census.stateCount(state),
          ),
          options: [
            for (final state in group.states)
              FilterSheetOption(
                id: 'filter-option-state-$state',
                label: state,
                count: census.stateCount(state),
                value: state,
                selected: _state == state,
                badge: indiaStateIsUnionTerritory(state) ? 'UT' : null,
              ),
          ],
        ),
    ];
    final jumps = <FilterSheetJump>[
      for (final id in ['north', 'south', 'east', 'west', 'central'])
        if (sections.any((section) => section.id == id) ||
            (id == 'east' &&
                sections.any((section) => section.id == 'northeast')))
          FilterSheetJump(
            id: 'filter-region-jump-$id',
            label:
                indiaStateSectionTitle(
                  id == 'east' ? 'east' : id,
                ).substring(0, 1).toUpperCase() +
                indiaStateSectionTitle(id).substring(1).toLowerCase(),
            sectionId: sections.any((section) => section.id == id)
                ? id
                : 'northeast',
          ),
    ];
    final stateSubtitle = Text(
      widget.chooseStateFirst
          ? 'Choose a state first'
          : '${names.length} states & UTs with temples',
      key: widget.chooseStateFirst
          ? const Key('filter-choose-state-first')
          : const Key('filter-state-count'),
      style: GoogleFonts.poppins(fontSize: 13, color: colors.muted),
    );
    return FilterSheetScaffold(
      title: 'State',
      sectionKey: const Key('filter-section-state'),
      subtitle: widget.chooseStateFirst
          ? Semantics(
              identifier: 'filter-choose-state-first',
              container: true,
              child: stateSubtitle,
            )
          : stateSubtitle,
      searchHint: 'Search state',
      forceSearch: true,
      jumps: jumps,
      any: FilterSheetOption(
        id: 'filter-option-state-any',
        label: 'Any state',
        count: census.anyState,
        value: '',
        selected: _state == null,
      ),
      sections: sections,
      resultLabel: directoryFilterResultLabel(census.matched),
      clearEnabled: _clearEnabled,
      onClear: _clearDraft,
      scrollToId: _state == null ? null : 'filter-option-state-$_state',
      onOption: (option) =>
          _chooseState(option.value.isEmpty ? null : option.value),
      onApply: () => Navigator.pop(context, _selection),
    );
  }

  Widget _districtSheet(
    DirectoryOptionCensus census,
    FilterSheetColors colors,
  ) {
    final state = _state;
    final names = directoryDistrictsFrom(
      widget.temples,
      state: state,
      districtOf: _resolvedDistrictOf,
    );
    final options = [
      for (final name in names)
        if (_showChoice(census.districtCount(name), _district == name))
          FilterSheetOption(
            id: 'filter-option-district-$name',
            label: name,
            count: census.districtCount(name),
            value: name,
            selected: _district == name,
          ),
    ];
    final anyLabel = state == null || state.isEmpty
        ? 'All districts'
        : 'All districts in $state';
    return FilterSheetScaffold(
      title: 'District',
      sectionKey: const Key('filter-section-district'),
      subtitle: state == null || state.isEmpty
          ? null
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'In $state · ',
                  style: GoogleFonts.poppins(fontSize: 13, color: colors.muted),
                ),
                TextButton(
                  key: const Key('filter-change-state'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _changeState,
                  child: Text(
                    'Change state',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.accentText,
                    ),
                  ),
                ),
              ],
            ),
      searchHint: 'Search district',
      loading: _districtsLoading,
      loadingKey: const Key('filter-district-loading'),
      error: _districtError,
      errorMessage: 'Districts could not be loaded',
      onRetry: widget.retryDistricts == null ? null : _retryDistricts,
      any: FilterSheetOption(
        id: 'filter-option-district-any',
        label: anyLabel,
        count: census.anyDistrict,
        value: '',
        selected: _district == null || _district!.isEmpty,
      ),
      sections: [
        FilterSheetSection(id: 'districts', title: '', options: options),
      ],
      resultLabel: directoryFilterResultLabel(census.matched),
      clearEnabled: _clearEnabled,
      onClear: _clearDraft,
      scrollToId: _district == null || _district!.isEmpty
          ? null
          : 'filter-option-district-$_district',
      onOption: (option) => setState(() {
        _district = option.value.isEmpty ? null : option.value;
      }),
      onApply: () => Navigator.pop(context, _selection),
    );
  }

  List<DeityGroup> _deityGroupsForSheet() {
    final id = identityHashCode(widget.temples);
    final cached = _deityGroups;
    if (cached != null && _deityGroupsId == id) return cached;
    final next = groupDeityNames(directoryDeitiesFrom(widget.temples));
    _deityGroups = next;
    _deityGroupsId = id;
    return next;
  }

  Widget _deitySheet(DirectoryOptionCensus census, FilterSheetColors colors) {
    final groups = _deityGroupsForSheet();
    final visible = [
      for (final group in groups)
        if (_showChoice(census.deityCount(group.label), _deity == group.label))
          group,
    ];
    FilterSheetOption optionFor(DeityGroup group, {required String id}) {
      return FilterSheetOption(
        id: id,
        label: group.label,
        count: census.deityCount(group.label),
        value: group.label,
        selected: _deity == group.label,
        badge: group.tradition,
        searchText: group.searchText,
      );
    }

    final sections = <FilterSheetSection>[];
    if (visible.length > 8) {
      final ranked = [...visible]
        ..sort((a, b) {
          final count = census.deityCount(b.label) - census.deityCount(a.label);
          if (count != 0) return count;
          return a.label.compareTo(b.label);
        });
      sections.add(
        FilterSheetSection(
          id: 'deity-most',
          title: 'MOST LISTED',
          options: [
            for (final group in ranked.take(8))
              optionFor(group, id: 'filter-deity-top-${group.label}'),
          ],
        ),
      );
      final byLetter = <String, List<DeityGroup>>{};
      for (final group in visible) {
        final letter = group.label.isEmpty ? '#' : group.label[0].toUpperCase();
        (byLetter[letter] ??= <DeityGroup>[]).add(group);
      }
      final letters = byLetter.keys.toList()..sort();
      for (final letter in letters) {
        sections.add(
          FilterSheetSection(
            id: 'deity-letter-$letter',
            title: letter,
            options: [
              for (final group in byLetter[letter]!)
                optionFor(group, id: 'filter-option-deity-${group.label}'),
            ],
          ),
        );
      }
    } else {
      sections.add(
        FilterSheetSection(
          id: 'deities',
          title: '',
          options: [
            for (final group in visible)
              optionFor(group, id: 'filter-option-deity-${group.label}'),
          ],
        ),
      );
    }
    final traditions = [
      for (final label in ['Jain', 'Buddhist', 'Sikh'])
        if (visible.any((group) => group.tradition == label)) label,
    ];
    final note = directoryDeityFilterNote([
      for (final group in visible) group.label,
      ...[for (final group in visible) ...group.variants],
    ], count: visible.length);
    return FilterSheetScaffold(
      title: 'Deity',
      sectionKey: const Key('filter-section-deity'),
      subtitle: Text(
        note,
        key: traditions.isEmpty ? null : const Key('filter-deity-note'),
        style: GoogleFonts.poppins(fontSize: 13, color: colors.muted),
      ),
      searchHint: 'Search deity (e.g. Murugan)',
      forceSearch: true,
      any: FilterSheetOption(
        id: 'filter-option-deity-any',
        label: 'Any deity',
        count: census.anyDeity,
        value: '',
        selected: _deity == null,
      ),
      sections: sections,
      resultLabel: directoryFilterResultLabel(census.matched),
      clearEnabled: _clearEnabled,
      onClear: _clearDraft,
      scrollToId: _deity == null ? null : 'filter-option-deity-$_deity',
      onOption: (option) => setState(() {
        _deity = option.value.isEmpty ? null : option.value;
      }),
      onApply: () => Navigator.pop(context, _selection),
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
    final colors = FilterSheetColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: selected ? colors.selectedRow : colors.chipFill,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.radio : colors.border,
            width: selected ? 1.4 : 1,
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
                        Icon(icon, size: 16, color: colors.radio),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.label,
                            ),
                          ),
                        ),
                        if (!selected) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: colors.muted,
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
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.accentText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
