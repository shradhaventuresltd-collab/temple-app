import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Light and dark colours for the filter bar and [FilterSheetScaffold].
///
/// New filter widgets read these tokens. They do not pick their own colours.
/// The filled action uses a deep orange so white label text stays at or
/// above 4.5:1. Icons and the selected radio keep the brighter saffron.
@immutable
class FilterSheetColors extends ThemeExtension<FilterSheetColors> {
  const FilterSheetColors({
    required this.sheetBackground,
    required this.label,
    required this.selectedLabel,
    required this.selectedRow,
    required this.muted,
    required this.accent,
    required this.accentText,
    required this.buttonFill,
    required this.onButton,
    required this.onAccent,
    required this.radio,
    required this.searchFill,
    required this.border,
    required this.headerBand,
    required this.chipFill,
    required this.barBackground,
  });

  final Color sheetBackground;
  final Color label;
  final Color selectedLabel;
  final Color selectedRow;
  final Color muted;
  final Color accent;

  /// Text and outline accent. Dark is #FFB74D so it stays at or above 4.5:1
  /// on the brown sheet and on chip fill. The filled button keeps [accent].
  final Color accentText;

  /// Filled "Show N temples" background. Dark is #FF9F2E with [onButton] #1A0F08.
  final Color buttonFill;
  final Color onButton;
  final Color onAccent;
  final Color radio;
  final Color searchFill;
  final Color border;
  final Color headerBand;
  final Color chipFill;
  final Color barBackground;

  static const light = FilterSheetColors(
    sheetBackground: Color(0xFFFFFBF5),
    label: Color(0xFF3E2723),
    selectedLabel: Color(0xFF5D1A12),
    selectedRow: Color(0xFFFFF3E0),
    muted: Color(0xFF6D4C41),
    accent: Color(0xFFBF360C),
    accentText: Color(0xFFBF360C),
    buttonFill: Color(0xFFBF360C),
    onButton: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    radio: Color(0xFFE65100),
    searchFill: Color(0xFFFFFFFF),
    border: Color(0xFFE6D3B3),
    headerBand: Color(0xFFFFF6EA),
    chipFill: Color(0xFFFFFFFF),
    barBackground: Color(0xFFFFFBF5),
  );

  static const dark = FilterSheetColors(
    sheetBackground: Color(0xFF241812),
    label: Color(0xFFF3E6D8),
    selectedLabel: Color(0xFFF6C7B8),
    selectedRow: Color(0xFF3A2A22),
    muted: Color(0xFFE6D3C4),
    accent: Color(0xFFFFB74D),
    accentText: Color(0xFFFFB74D),
    buttonFill: Color(0xFFFF9F2E),
    onButton: Color(0xFF1A0F08),
    onAccent: Color(0xFF1A0F08),
    radio: Color(0xFFFF8F00),
    searchFill: Color(0xFF2C211B),
    border: Color(0xFF5C463A),
    headerBand: Color(0xFF32241C),
    chipFill: Color(0xFF2C211B),
    barBackground: Color(0xFF241812),
  );

  static FilterSheetColors of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<FilterSheetColors>();
    if (extension != null) return extension;
    return theme.brightness == Brightness.dark ? dark : light;
  }

  /// WCAG contrast ratio of [foreground] on [background].
  static double contrast(Color foreground, Color background) {
    final lighter = _luminance(foreground);
    final darker = _luminance(background);
    final hi = lighter > darker ? lighter : darker;
    final lo = lighter > darker ? darker : lighter;
    return (hi + 0.05) / (lo + 0.05);
  }

  static double _luminance(Color color) {
    double channel(double value) {
      return value <= 0.04045
          ? value / 12.92
          : _pow((value + 0.055) / 1.055, 2.4);
    }

    final red = channel(color.r);
    final green = channel(color.g);
    final blue = channel(color.b);
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
  }

  static double _pow(double base, double exp) => math.pow(base, exp).toDouble();

  @override
  FilterSheetColors copyWith({
    Color? sheetBackground,
    Color? label,
    Color? selectedLabel,
    Color? selectedRow,
    Color? muted,
    Color? accent,
    Color? accentText,
    Color? buttonFill,
    Color? onButton,
    Color? onAccent,
    Color? radio,
    Color? searchFill,
    Color? border,
    Color? headerBand,
    Color? chipFill,
    Color? barBackground,
  }) {
    return FilterSheetColors(
      sheetBackground: sheetBackground ?? this.sheetBackground,
      label: label ?? this.label,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      selectedRow: selectedRow ?? this.selectedRow,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      buttonFill: buttonFill ?? this.buttonFill,
      onButton: onButton ?? this.onButton,
      onAccent: onAccent ?? this.onAccent,
      radio: radio ?? this.radio,
      searchFill: searchFill ?? this.searchFill,
      border: border ?? this.border,
      headerBand: headerBand ?? this.headerBand,
      chipFill: chipFill ?? this.chipFill,
      barBackground: barBackground ?? this.barBackground,
    );
  }

  @override
  FilterSheetColors lerp(ThemeExtension<FilterSheetColors>? other, double t) {
    if (other is! FilterSheetColors) return this;
    return FilterSheetColors(
      sheetBackground: Color.lerp(sheetBackground, other.sheetBackground, t)!,
      label: Color.lerp(label, other.label, t)!,
      selectedLabel: Color.lerp(selectedLabel, other.selectedLabel, t)!,
      selectedRow: Color.lerp(selectedRow, other.selectedRow, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      buttonFill: Color.lerp(buttonFill, other.buttonFill, t)!,
      onButton: Color.lerp(onButton, other.onButton, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      radio: Color.lerp(radio, other.radio, t)!,
      searchFill: Color.lerp(searchFill, other.searchFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      headerBand: Color.lerp(headerBand, other.headerBand, t)!,
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      barBackground: Color.lerp(barBackground, other.barBackground, t)!,
    );
  }
}

/// Apply or instant. Browse commits from the footer. Near Me commits on tap.
enum FilterSheetMode { apply, instant }

class FilterSheetOption {
  const FilterSheetOption({
    required this.id,
    required this.label,
    required this.count,
    required this.value,
    this.selected = false,
    this.badge,
    this.searchText,
  });

  /// Semantics id and widget key. Harness rows use `filter-option-...`.
  final String id;
  final String label;
  final int count;

  /// Value reported to the caller. Empty string is the Any row.
  final String value;
  final bool selected;
  final String? badge;

  /// Extra search text, such as parenthetical deity variants.
  final String? searchText;

  String get semanticsLabel => '$label  $count';

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;
    return (searchText ?? '').toLowerCase().contains(needle);
  }
}

class FilterSheetSection {
  const FilterSheetSection({
    required this.id,
    required this.title,
    required this.options,
    this.total,
  });

  final String id;
  final String title;
  final int? total;
  final List<FilterSheetOption> options;
}

class FilterSheetJump {
  const FilterSheetJump({
    required this.id,
    required this.label,
    required this.sectionId,
  });

  final String id;
  final String label;
  final String sectionId;
}
