import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';
import 'package:temple_app/widgets/filter_sheet.dart';

Temple filterTemple({
  required String name,
  required String state,
  required String city,
  required String deity,
  double latitude = 9.9,
  double longitude = 78.1,
}) {
  return Temple(
    name: name,
    state: state,
    city: city,
    deity: deity,
    imageUrl: '',
    description: '',
    story: '',
    location: '$city, $state',
    timings: '',
    specialities: const [],
    latitude: latitude,
    longitude: longitude,
  );
}

void useFilterSurface(
  WidgetTester tester, {
  Size size = const Size(800, 1600),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps a bar whose list uses [directoryMatchingTemples].
Future<void> pumpFilterBar(
  WidgetTester tester, {
  required List<Temple> temples,
  String? Function(Temple temple)? districtOf,
  Future<String? Function(Temple)?> Function()? prepareDistricts,
  String? initialState,
  String? initialDeity,
  String? initialDistrict,
  Size size = const Size(800, 1600),
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  useFilterSurface(tester, size: size);
  String? state = initialState;
  String? deity = initialDeity;
  String? district = initialDistrict;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            final visible = directoryMatchingTemples(
              temples,
              state: state,
              deity: deity,
              district: district,
              districtOf: districtOf,
            );
            return Column(
              children: [
                DirectoryFilterBar(
                  temples: temples,
                  selectedState: state,
                  selectedDeity: deity,
                  selectedDistrict: district,
                  districtOf: districtOf,
                  prepareDistricts: prepareDistricts,
                  onChanged: (nextState, nextDeity, nextDistrict) {
                    setState(() {
                      state = nextState;
                      deity = nextDeity;
                      district = nextDistrict;
                    });
                  },
                ),
                Expanded(
                  child: ListView(
                    children: [for (final temple in visible) Text(temple.name)],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openFilterChip(WidgetTester tester, String chip) async {
  await tester.tap(find.byKey(Key('filter-chip-$chip')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('filter-sheet')), findsOneWidget);
}

Future<void> applyFilterSheet(WidgetTester tester) async {
  final apply = find.byKey(const Key('filter-sheet-apply'));
  await tester.ensureVisible(apply);
  await tester.tap(apply);
  await tester.pumpAndSettle();
}

Future<void> chooseAndApply(WidgetTester tester, Key option) async {
  final finder = find.byKey(option);
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('filter-sheet-options')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pump();
  await applyFilterSheet(tester);
}

/// Dark theme that resolves [FilterSheetColors.dark] from brightness.
ThemeData darkFilterTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    extensions: const [FilterSheetColors.dark],
  );
}
