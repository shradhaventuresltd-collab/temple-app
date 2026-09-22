import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// State and deity chosen in the filter sheet.
typedef DirectoryFilterSelection = ({String? state, String? deity});

/// Opens the shared state + deity sheet.
///
/// Returns the selection when the user applies it. Returns null when the
/// sheet is dismissed, so the caller keeps the previous chips.
Future<DirectoryFilterSelection?> showDirectoryFilterSheet({
  required BuildContext context,
  required List<Temple> temples,
  required String? selectedState,
  required String? selectedDeity,
  String query = '',
}) {
  return showModalBottomSheet<DirectoryFilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFBF2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _DirectoryFilterSheet(
        temples: temples,
        initialState: selectedState,
        initialDeity: selectedDeity,
        query: query,
      );
    },
  );
}

/// Trigger chips for the two supported filters. Either chip opens the sheet.
class DirectoryFilterBar extends StatelessWidget {
  const DirectoryFilterBar({
    super.key,
    required this.temples,
    required this.selectedState,
    required this.selectedDeity,
    required this.onChanged,
    this.query = '',
  });

  final List<Temple> temples;
  final String? selectedState;
  final String? selectedDeity;
  final String query;

  /// Called with the new pair. Either value may be null (that chip is cleared).
  final void Function(String? state, String? deity) onChanged;

  bool get _active => selectedState != null || selectedDeity != null;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showDirectoryFilterSheet(
      context: context,
      temples: temples,
      selectedState: selectedState,
      selectedDeity: selectedDeity,
      query: query,
    );
    if (result == null || !context.mounted) return;
    onChanged(result.state, result.deity);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TriggerChip(
            chipKey: const Key('filter-chip-state'),
            clearKey: const Key('filter-chip-state-clear'),
            icon: Icons.place_rounded,
            label: selectedState ?? 'State',
            selected: selectedState != null,
            openTooltip: 'Choose a state',
            clearTooltip: 'Clear state filter',
            onOpen: () => _openSheet(context),
            onClear: () => onChanged(null, selectedDeity),
          ),
          const SizedBox(width: 8),
          _TriggerChip(
            chipKey: const Key('filter-chip-deity'),
            clearKey: const Key('filter-chip-deity-clear'),
            icon: Icons.auto_awesome_rounded,
            label: selectedDeity == null
                ? 'Deity'
                : directoryDeityChipLabel(selectedDeity!),
            selected: selectedDeity != null,
            openTooltip: 'Choose a deity',
            clearTooltip: 'Clear deity filter',
            onOpen: () => _openSheet(context),
            onClear: () => onChanged(selectedState, null),
          ),
          if (_active) ...[
            const SizedBox(width: 4),
            TextButton(
              key: const Key('filter-clear'),
              onPressed: () => onChanged(null, null),
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _deepSaffron,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectoryFilterSheet extends StatefulWidget {
  const _DirectoryFilterSheet({
    required this.temples,
    required this.initialState,
    required this.initialDeity,
    required this.query,
  });

  final List<Temple> temples;
  final String? initialState;
  final String? initialDeity;
  final String query;

  @override
  State<_DirectoryFilterSheet> createState() => _DirectoryFilterSheetState();
}

class _DirectoryFilterSheetState extends State<_DirectoryFilterSheet> {
  String? _state;
  String? _deity;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _deity = widget.initialDeity;
  }

  int _count({String? state, String? deity}) {
    return directoryFilterCount(
      widget.temples,
      state: state,
      deity: deity,
      query: widget.query,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final note = directoryDeityFilterNote();
    final matched = _count(state: _state, deity: _deity);
    final draftActive = _state != null || _deity != null;

    return SafeArea(
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
                'State and deity, on the temples already loaded.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.brown.shade500,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                children: [
                  const _SheetSectionLabel('STATE'),
                  const SizedBox(height: 8),
                  _OptionWrap(
                    children: [
                      _OptionChip(
                        optionKey: const Key('filter-option-state-any'),
                        label: 'Any state',
                        count: _count(deity: _deity),
                        selected: _state == null,
                        onTap: () => setState(() => _state = null),
                      ),
                      for (final state in directoryFilterStates)
                        _OptionChip(
                          optionKey: Key('filter-option-state-$state'),
                          label: state,
                          count: _count(state: state, deity: _deity),
                          selected: _state == state,
                          onTap: () => setState(() => _state = state),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SheetSectionLabel('DEITY'),
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
                    children: [
                      _OptionChip(
                        optionKey: const Key('filter-option-deity-any'),
                        label: 'Any deity',
                        count: _count(state: _state),
                        selected: _deity == null,
                        onTap: () => setState(() => _deity = null),
                      ),
                      for (final deity in directoryFilterDeities)
                        _OptionChip(
                          optionKey: Key('filter-option-deity-$deity'),
                          label: directoryDeityChipLabel(deity),
                          count: _count(state: _state, deity: deity),
                          selected: _deity == deity,
                          onTap: () => setState(() => _deity = deity),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    key: const Key('filter-sheet-clear'),
                    onPressed: draftActive
                        ? () => setState(() {
                            _state = null;
                            _deity = null;
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
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label);

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
    return Material(
      color: selected
          ? TempleBrowseCard.saffron
          : empty
          ? const Color(0xFFFFF8EE)
          : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? TempleBrowseCard.saffron
              : TempleBrowseCard.gold,
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: empty ? Colors.brown.shade300 : foreground,
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
          InkWell(
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
                      color: selected ? Colors.white : TempleBrowseCard.saffron,
                    ),
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
          if (selected)
            IconButton(
              key: clearKey,
              tooltip: clearTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

const Color _deepSaffron = Color(0xFFE65100);
