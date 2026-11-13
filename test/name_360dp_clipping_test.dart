// Regression for PR #79: the name sits in a SizedBox(width: double.infinity)
// so a long title wraps (and ellipsizes after two lines) at 360dp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

Temple _longName() {
  return Temple(
    name:
        'Sri Kalyana Venkateswara Swamy Temple at Srinivasa Mangapuram in Chittoor',
    state: 'Andhra Pradesh',
    city: 'Tirupati',
    deity: 'Vishnu',
    imageUrl: '',
    description: '',
    story: '',
    location: 'Tirupati, Andhra Pradesh',
    timings: '',
    specialities: const [],
    latitude: 13.6,
    longitude: 79.4,
  );
}

void _failOnOverflow() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed') ||
        details.toString().contains('RenderFlex')) {
      fail(details.toString());
    }
    (previous ?? FlutterError.presentError)(details);
  };
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('browse card name stays inside 360dp', (t) async {
    _failOnOverflow();
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseCard(temple: _longName(), onTap: () {}),
        ),
      ),
    );
    await t.pump();
    final name = find.byKey(const Key('browse-temple-name'));
    expect(name, findsOneWidget);
    expect(t.getRect(name).left, greaterThanOrEqualTo(0));
    expect(t.getRect(name).right, lessThanOrEqualTo(360));
    final box = t.widget<SizedBox>(
      find.ancestor(of: name, matching: find.byType(SizedBox)).first,
    );
    expect(box.width, double.infinity);
  });

  testWidgets('detail name stays inside 360dp', (t) async {
    _failOnOverflow();
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _longName())),
      ),
    );
    await t.pump();
    final name = find.byKey(const Key('detail-temple-name'));
    expect(name, findsOneWidget);
    expect(t.getRect(name).left, greaterThanOrEqualTo(0));
    expect(t.getRect(name).right, lessThanOrEqualTo(360));
    final box = t.widget<SizedBox>(
      find.ancestor(of: name, matching: find.byType(SizedBox)).first,
    );
    expect(box.width, double.infinity);
  });
}
