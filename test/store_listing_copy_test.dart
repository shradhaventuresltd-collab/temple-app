import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/force_update_screen.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:temple_app/services/store_platform.dart';
import 'package:temple_app/services/update_nudge_store.dart';
import 'package:temple_app/widgets/soft_update_nudge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('iOS force update names the App Store and does not open Play', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ForceUpdateScreen(
          packageName: 'com.shradhaventures.temple',
          storePlatform: StorePlatform.ios,
          launch: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    expect(
      find.text(forceUpdateButtonLabel(StorePlatform.ios)),
      findsOneWidget,
    );
    expect(find.text(forceUpdateBody(StorePlatform.ios)), findsOneWidget);
    expect(find.textContaining('Play Store'), findsNothing);

    await tester.tap(find.byKey(const Key('force-update-button')));
    await tester.pump();

    expect(opened, isEmpty);
    expect(find.text(forceUpdateOpenFailed(StorePlatform.ios)), findsOneWidget);
  });

  testWidgets('Android force update still names the Play Store', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ForceUpdateScreen(
          packageName: 'com.shradhaventures.temple',
          storePlatform: StorePlatform.android,
          launch: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    expect(find.text(ForceUpdateScreen.buttonLabel), findsOneWidget);
    expect(find.text(ForceUpdateScreen.body), findsOneWidget);
    expect(find.textContaining('App Store'), findsNothing);

    await tester.tap(find.byKey(const Key('force-update-button')));
    await tester.pump();
    expect(opened.single, playStoreMarketUri('com.shradhaventures.temple'));
  });

  testWidgets('the soft nudge names the store for the platform', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SoftUpdateNudgeBanner(
          storePlatform: StorePlatform.ios,
          onUpdate: () {},
          onDismiss: () {},
        ),
      ),
    );
    expect(find.text(softUpdateMessage(StorePlatform.ios)), findsOneWidget);
    expect(find.textContaining('Play Store'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: SoftUpdateNudgeBanner(onUpdate: () {}, onDismiss: () {}),
      ),
    );
    expect(find.text(SoftUpdateNudgeBanner.message), findsOneWidget);
  });

  testWidgets('Home shows the App Store nudge on iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          templesLoader: () async => [_temple],
          offerSoftUpdate: true,
          nudgeStore: MemoryUpdateNudgeStore(),
          now: () => DateTime.utc(2026, 10, 16),
          storePlatform: StorePlatform.ios,
          openStoreListing: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(softUpdateMessage(StorePlatform.ios)), findsOneWidget);
    expect(find.textContaining('Play Store'), findsNothing);
  });
}

const Temple _temple = Temple(
  name: 'Meenakshi Amman Temple',
  state: 'Tamil Nadu',
  city: 'Madurai',
  deity: 'Devi',
  imageUrl: '',
  description: 'A historic temple.',
  story: 'Story',
  location: 'Madurai, Tamil Nadu',
  timings: '6am–9pm',
  specialities: [],
);
