import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/widgets/filter_sheet_theme.dart';

import 'filter_sheet_support.dart';

void main() {
  test('filter sheet tokens clear 4.5:1', () {
    for (final colors in [FilterSheetColors.light, FilterSheetColors.dark]) {
      expect(
        FilterSheetColors.contrast(colors.label, colors.sheetBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        FilterSheetColors.contrast(colors.selectedLabel, colors.selectedRow),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        FilterSheetColors.contrast(colors.muted, colors.sheetBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        FilterSheetColors.contrast(colors.onAccent, colors.accent),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        FilterSheetColors.contrast(colors.muted, colors.headerBand),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('filter_sheet_dark_tokens_test', (tester) async {
    final temples = [
      filterTemple(
        name: 'Vaikom Mahadeva Temple',
        state: 'Kerala',
        city: 'Kottayam',
        deity: 'Shiva',
      ),
    ];
    await pumpFilterBar(
      tester,
      temples: temples,
      theme: darkFilterTheme(),
    );
    await openFilterChip(tester, 'state');
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const Key('filter-sheet')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, FilterSheetColors.dark.sheetBackground);
    await tester.tap(find.byKey(const Key('filter-option-state-Kerala')));
    await tester.pump();
    final selected = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const Key('filter-option-state-Kerala')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(selected.color, FilterSheetColors.dark.selectedRow);
    final label = tester.widget<Text>(find.text('Kerala').last);
    expect(label.style?.color, FilterSheetColors.dark.selectedLabel);
  });
}
