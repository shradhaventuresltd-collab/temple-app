import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// Spaces let the line break. Repeated so two lines are not enough at 360dp.
const _overflowName = 'Sri Kalahasti Swamy Temple of the Sacred Hill ';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('browse card wraps a long name to two lines at 360dp', (
    tester,
  ) async {
    await _pump360(
      tester,
      TempleBrowseCard(temple: _temple(_overflowName * 4)),
    );
    _expectTwoLineEllipsis(tester, find.byKey(const Key('browse-temple-name')));
  });

  testWidgets('detail name wraps to two lines at 360dp', (tester) async {
    await _pump360(
      tester,
      TempleDetailBody(temple: _temple(_overflowName * 4)),
    );
    _expectTwoLineEllipsis(tester, find.byKey(const Key('detail-temple-name')));
  });

  testWidgets('list app bar wraps a long title without clipping at 360dp', (
    tester,
  ) async {
    await _pump360(
      tester,
      TempleListScreen(
        temples: [_temple('Meenakshi')],
        title: _overflowName * 4,
      ),
    );
    final title = find.byKey(const Key('temple-list-title'));
    _expectTwoLineEllipsis(tester, title);
    final titleRect = tester.getRect(title);
    final bar = tester.getRect(find.byType(AppBar));
    expect(bar.top, lessThanOrEqualTo(titleRect.top));
    expect(
      bar.bottom,
      greaterThanOrEqualTo(titleRect.bottom),
      reason: 'the toolbar must be tall enough for both lines',
    );
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight,
      greaterThan(kToolbarHeight),
    );
  });
}

Temple _temple(String name) {
  return Temple(
    name: name,
    state: 'Andhra Pradesh',
    city: 'Srikalahasti',
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: 'Srikalahasti, Andhra Pradesh',
    timings: '',
    specialities: const [],
    latitude: 13.75,
    longitude: 79.70,
  );
}

Future<void> _pump360(WidgetTester tester, Widget home) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: home)));
}

void _expectTwoLineEllipsis(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  expect(text.maxLines, 2);
  expect(text.overflow, TextOverflow.ellipsis);
  expect(text.softWrap, isTrue);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isTrue);
  expect(_lineCount(paragraph), 2);
  expect(tester.takeException(), isNull);
}

int _lineCount(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}
