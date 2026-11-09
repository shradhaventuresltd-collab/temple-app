import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/widgets/filter_sheet_theme.dart';

export 'package:temple_app/widgets/filter_sheet_theme.dart';

/// Resource-id for a sheet title. "Sort from state" becomes
/// `filter-sheet-title-sort-from-state`.
String filterSheetTitleId(String title) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'filter-sheet-title-$slug';
}

/// Shared filter sheet. Browse and Near Me both use this scaffold.
///
/// The sheet owns search text and the pull-to-dismiss gesture. The caller
/// owns the draft: [onOption] reports a tap, [onApply] commits it, and
/// [onClear] clears the draft without closing.
class FilterSheetScaffold extends StatefulWidget {
  const FilterSheetScaffold({
    super.key,
    required this.title,
    required this.sectionKey,
    this.subtitle,
    this.searchHint = 'Search',
    this.forceSearch = false,
    this.jumps = const [],
    this.any,
    this.sections = const [],
    this.mode = FilterSheetMode.apply,
    this.resultLabel,
    this.clearEnabled = false,
    this.onClear,
    this.onApply,
    this.onOption,
    this.loading = false,
    this.loadingKey = const Key('filter-sheet-loading'),
    this.error = false,
    this.errorMessage = 'Something went wrong',
    this.onRetry,
    this.scrollToId,
  });

  final String title;

  /// `filter-section-state`, `filter-section-district`, or `filter-section-deity`.
  final Key sectionKey;
  final Widget? subtitle;
  final String searchHint;

  /// Search is also shown when the sheet has more than 15 rows.
  final bool forceSearch;
  final List<FilterSheetJump> jumps;
  final FilterSheetOption? any;
  final List<FilterSheetSection> sections;
  final FilterSheetMode mode;
  final String? resultLabel;
  final bool clearEnabled;
  final VoidCallback? onClear;
  final VoidCallback? onApply;
  final ValueChanged<FilterSheetOption>? onOption;
  final bool loading;
  final Key loadingKey;
  final bool error;
  final String errorMessage;
  final VoidCallback? onRetry;

  /// Option id scrolled into view when the sheet opens or finishes loading.
  final String? scrollToId;

  @override
  State<FilterSheetScaffold> createState() => _FilterSheetScaffoldState();
}

class _FilterSheetScaffoldState extends State<FilterSheetScaffold> {
  final ScrollController _options = ScrollController();
  final TextEditingController _search = TextEditingController();
  final Map<String, GlobalKey> _anchors = {};
  String? _jumpId;
  bool _dismissed = false;
  bool _pullArmed = false;
  double _pullDown = 0;
  double _overscrollPull = 0;
  double _pointerY = 0;
  double _pointerX = 0;
  double _pullSide = 0;

  @override
  void initState() {
    super.initState();
    _scheduleReveal(widget.scrollToId);
  }

  @override
  void didUpdateWidget(FilterSheetScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToId != oldWidget.scrollToId ||
        (oldWidget.loading && !widget.loading)) {
      _scheduleReveal(widget.scrollToId);
    }
  }

  @override
  void dispose() {
    _options.dispose();
    _search.dispose();
    super.dispose();
  }

  GlobalKey _anchor(String id) => _anchors.putIfAbsent(id, GlobalKey.new);

  void _scheduleReveal(String? id, {double alignment = 0.3}) {
    if (id == null || id.isEmpty) return;
    _reveal(id, alignment: alignment, hops: 0);
  }

  /// Scrolls until [id] is built. Deity rows are lazy, so an off-screen
  /// selection is not in the tree until the viewport reaches it.
  void _reveal(String id, {required double alignment, required int hops}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _anchor(id).currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: alignment,
          duration: const Duration(milliseconds: 200),
        );
        return;
      }
      if (hops >= 40 || !_options.hasClients) return;
      final position = _options.position;
      if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
        return;
      }
      final next = math.min(
        position.maxScrollExtent,
        position.pixels + position.viewportDimension,
      );
      if (next <= position.pixels + 1) return;
      position.jumpTo(next);
      _reveal(id, alignment: alignment, hops: hops + 1);
    });
  }

  bool get _listAtTop => !_options.hasClients || _options.offset <= 0;

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
    _pointerX = event.position.dx;
    _pullSide = 0;
    _pullArmed = _listAtTop || _eventOnHeader(event.position);
    if (_pullArmed) _pullDown = 0;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final dy = event.position.dy - _pointerY;
    _pointerY = event.position.dy;
    _pullSide += (event.position.dx - _pointerX).abs();
    _pointerX = event.position.dx;
    if (_dismissed || !_pullArmed) return;
    if (dy == 0) return;
    if (dy < 0) {
      _pullArmed = false;
      _pullDown = 0;
      return;
    }
    _pullDown += dy;
    if (_pullDown >= 72 && _pullDown > _pullSide) _dismiss();
  }

  void _onPointerEnd(PointerEvent event) {
    _pullArmed = false;
    if (!_dismissed) _pullDown = 0;
  }

  int get _rowCount {
    var count = widget.any == null ? 0 : 1;
    for (final section in widget.sections) {
      count += section.options.length;
    }
    return count;
  }

  bool get _showSearch => widget.forceSearch || _rowCount > 15;

  List<FilterSheetSection> get _sections {
    final query = _search.text;
    if (query.trim().isEmpty) return widget.sections;
    return [
      for (final section in widget.sections)
        if (section.options.any((option) => option.matches(query)))
          FilterSheetSection(
            id: section.id,
            title: section.title,
            total: section.total,
            options: [
              for (final option in section.options)
                if (option.matches(query)) option,
            ],
          ),
    ];
  }

  bool get _anyVisible {
    final any = widget.any;
    if (any == null) return false;
    return any.matches(_search.text);
  }

  bool get _nothingMatches {
    if (_search.text.trim().isEmpty) return false;
    if (_anyVisible) return false;
    return _sections.isEmpty;
  }

  void _jumpTo(FilterSheetJump jump) {
    setState(() => _jumpId = jump.sectionId);
    _scheduleReveal(jump.sectionId, alignment: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FilterSheetColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final screen = MediaQuery.sizeOf(context);
    final height = screen.height * 0.78;
    final sheetWidth = math.min(screen.width, 560).toDouble();
    final sections = _sections;
    final jumps = [
      for (final jump in widget.jumps)
        if (sections.any((section) => section.id == jump.sectionId)) jump,
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: Material(
          color: colors.sheetBackground,
          child: SafeArea(
            child: Semantics(
              identifier: 'filter-sheet',
              container: true,
              // Run 42675181050: without explicitChildNodes the search field
              // merged into this node. The sheet was one empty EditText and
              // the title was not in the accessibility tree.
              explicitChildNodes: true,
              child: SizedBox(
                key: const Key('filter-sheet'),
                width: sheetWidth,
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
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: widget.sectionKey,
                              child: Semantics(
                                identifier: filterSheetTitleId(widget.title),
                                label: widget.title,
                                header: true,
                                container: true,
                                explicitChildNodes: true,
                                child: Text(
                                  widget.title,
                                  key: const Key('filter-sheet-title'),
                                  style: GoogleFonts.lora(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: colors.label,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('filter-sheet-close'),
                            tooltip: 'Close filters',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: widget.subtitle,
                      ),
                    if (_showSearch)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          key: const Key('filter-sheet-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colors.label,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.searchHint,
                            hintStyle: GoogleFonts.poppins(color: colors.muted),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colors.muted,
                            ),
                            filled: true,
                            fillColor: colors.searchFill,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                        ),
                      ),
                    if (jumps.isNotEmpty)
                      SizedBox(
                        height: 48 * scale.clamp(1, 1.4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            children: [
                              for (final jump in jumps)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _JumpChip(
                                    jump: jump,
                                    selected:
                                        (_jumpId ?? jumps.first.sectionId) ==
                                        jump.sectionId,
                                    onTap: () => _jumpTo(jump),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(child: _body(colors, sections)),
                    if (widget.mode == FilterSheetMode.apply)
                      _Footer(
                        colors: colors,
                        resultLabel: widget.resultLabel ?? 'Show temples',
                        clearEnabled: widget.clearEnabled,
                        onClear: widget.onClear,
                        onApply: widget.onApply,
                        scale: scale,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(FilterSheetColors colors, List<FilterSheetSection> sections) {
    if (widget.loading) {
      return _Skeleton(loadingKey: widget.loadingKey, colors: colors);
    }
    if (widget.error) {
      return _ErrorBody(
        message: widget.errorMessage,
        onRetry: widget.onRetry,
        colors: colors,
      );
    }
    final extent = _headerExtent(context);
    final query = _search.text.trim();
    final slivers = <Widget>[
      if (_anyVisible && widget.any != null)
        SliverToBoxAdapter(child: _optionTile(widget.any!)),
      for (final section in sections) _sectionSliver(section, colors, extent),
      if (_nothingMatches)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'No match for \u2018$query\u2019',
              key: const Key('filter-sheet-no-match'),
            ),
          ),
        ),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: _pullToDismiss,
      child: CustomScrollView(
        key: const Key('filter-sheet-options'),
        controller: _options,
        slivers: slivers,
      ),
    );
  }

  double _headerExtent(BuildContext context) {
    final font = MediaQuery.textScalerOf(context).scale(12);
    return math.max(36, font * 1.5 + 16);
  }

  Widget _optionTile(FilterSheetOption option) {
    return _OptionRow(
      option: option,
      anchor: _anchor(option.id),
      onTap: () => widget.onOption?.call(option),
    );
  }

  /// Lazy rows via [SliverChildBuilderDelegate], the same delegate
  /// [ListView.builder] uses. Section headers stay pinned.
  Widget _sectionSliver(
    FilterSheetSection section,
    FilterSheetColors colors,
    double extent,
  ) {
    final rows = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _optionTile(section.options[index]),
        childCount: section.options.length,
      ),
    );
    if (section.title.isEmpty) return rows;
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            extent: extent,
            child: _InlineHeader(
              key: _anchor(section.id),
              title: section.title,
              total: section.total,
              colors: colors,
            ),
          ),
        ),
        rows,
      ],
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: extent, width: double.infinity, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) => true;
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({
    super.key,
    required this.title,
    required this.total,
    required this.colors,
  });

  final String title;
  final int? total;
  final FilterSheetColors colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.headerBand,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colors.muted,
                ),
              ),
            ),
            if (total != null)
              Text(
                '$total',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.colors,
    required this.resultLabel,
    required this.clearEnabled,
    required this.onClear,
    required this.onApply,
    required this.scale,
  });

  final FilterSheetColors colors;
  final String resultLabel;
  final bool clearEnabled;
  final VoidCallback? onClear;
  final VoidCallback? onApply;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final clear = Semantics(
      identifier: 'filter-sheet-clear',
      button: true,
      enabled: clearEnabled,
      child: OutlinedButton(
        key: const Key('filter-sheet-clear'),
        onPressed: clearEnabled ? onClear : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: colors.accentText,
          disabledForegroundColor: colors.muted,
          side: BorderSide(
            color: clearEnabled ? colors.accentText : colors.border,
          ),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        child: const Text('Clear'),
      ),
    );
    final apply = FilledButton(
      key: const Key('filter-sheet-apply'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: colors.buttonFill,
        foregroundColor: colors.onButton,
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onApply,
      child: Text(resultLabel),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = scale >= 1.5 || constraints.maxWidth < 340;
          if (stack) {
            return Column(
              key: const Key('filter-sheet-footer-stack'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [apply, const SizedBox(height: 8), clear],
            );
          }
          return Row(
            children: [
              Expanded(child: clear),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: apply),
            ],
          );
        },
      ),
    );
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({
    required this.jump,
    required this.selected,
    required this.onTap,
  });

  final FilterSheetJump jump;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FilterSheetColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      identifier: jump.id,
      child: Material(
        color: colors.chipFill,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.radio : colors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          key: Key(jump.id),
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                jump.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.accentText : colors.label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.anchor,
    required this.onTap,
  });

  final FilterSheetOption option;
  final GlobalKey anchor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FilterSheetColors.of(context);
    final labelColor = option.selected ? colors.selectedLabel : colors.label;
    return Semantics(
      key: anchor,
      identifier: option.id,
      button: true,
      selected: option.selected,
      label: option.semanticsLabel,
      child: ExcludeSemantics(
        child: Material(
          color: option.selected ? colors.selectedRow : colors.sheetBackground,
          child: InkWell(
            key: Key(option.id),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            option.label,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: option.selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: labelColor,
                            ),
                          ),
                          if (option.badge != null)
                            Text(
                              option.badge!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: colors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${option.count}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      option.selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: option.selected ? colors.radio : colors.muted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.loadingKey, required this.colors});

  final Key loadingKey;
  final FilterSheetColors colors;

  @override
  Widget build(BuildContext context) {
    final key = loadingKey;
    final id = key is ValueKey<String> ? key.value : null;
    return Semantics(
      identifier: id,
      label: 'Loading districts',
      child: ListView(
        key: loadingKey,
        children: [
          for (var i = 0; i < 8; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: colors.headerBand,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.colors,
  });

  final String message;
  final VoidCallback? onRetry;
  final FilterSheetColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'filter-district-error',
      label: message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                key: const Key('filter-district-error'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.label,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('filter-district-retry'),
                  onPressed: onRetry,
                  child: Text(
                    'Try again',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: colors.accentText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
