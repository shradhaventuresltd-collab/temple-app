// KAN-197: dress code on temple detail, with the shared
// "Unverified, check before visiting" chip.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/near_me/coarse_location.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/widgets/app_drawer.dart' show TempleListScreen;
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/screens/temples_near_me_screen.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers/dress_code_fixtures.dart';
import 'helpers/fake_admin_auth.dart';
import 'temples_near_me_screen_test.dart' show FakeCoarseLocation;

const _section = kDressSection;
const _chip = kDressChip;
const _link = kDressLink;
const _rule = kDressRule;
const _src = kDressSrc;
const _dressFields = kDressFields;

Map<String, dynamic> _doc({
  Object? dressCode = kDressRule,
  Object? url = kDressSrc,
  Object? type = 'secondary',
  Object? verified = false,
  bool timingsUnverified = false,
}) => dressDoc(
  dressCode: dressCode,
  url: url,
  type: type,
  verified: verified,
  timingsUnverified: timingsUnverified,
);

Temple _temple({
  Object? dressCode = kDressRule,
  Object? url = kDressSrc,
  Object? type = 'secondary',
  Object? verified = false,
}) =>
    dressTemple(dressCode: dressCode, url: url, type: type, verified: verified);

typedef _FakeLauncher = FakeLauncher;

void main() {
  late UrlLauncherPlatform original;
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => original = UrlLauncherPlatform.instance);
  tearDown(() {
    UrlLauncherPlatform.instance = original;
    TempleDetailScreen.debugLoadTemple = null;
  });

  group('Temple.fromMap dress code', () {
    test('reads all four fields', () {
      final t = _temple(type: 'official', verified: true);
      expect(t.dressCode, _rule);
      expect(t.dressCodeSourceUrl, _src);
      expect(t.dressCodeSourceType, 'official');
      expect(t.dressCodeVerified, isTrue);
      expect(t.hasDressCode, isTrue);
      expect(t.dressCodeUnverified, isFalse);
      expect(t.dressCodeSourceUri.toString(), _src);
    });

    test('unverified reads as unverified', () {
      final t = _temple();
      expect(t.dressCodeVerified, isFalse);
      expect(t.dressCodeUnverified, isTrue);
      expect(t.dressCodeSourceType, 'secondary');
    });

    test('absent fields are null and there is no dress code', () {
      final t = Temple.fromMap('a', const {});
      expect(t.dressCode, isNull);
      expect(t.dressCodeSourceUrl, isNull);
      expect(t.dressCodeSourceType, isNull);
      expect(t.dressCodeVerified, isNull);
      expect(t.hasDressCode, isFalse);
      expect(t.dressCodeUnverified, isFalse);
      expect(t.dressCodeSourceUri, isNull);
    });

    test('wrong types are null', () {
      final t = Temple.fromMap('a', const {
        'dressCode': 42,
        'dressCodeSourceUrl': ['https://x.org'],
        'dressCodeSourceType': true,
        'dressCodeVerified': 'false',
      });
      expect(t.dressCode, isNull);
      expect(t.dressCodeSourceUrl, isNull);
      expect(t.dressCodeSourceType, isNull);
      expect(t.dressCodeVerified, isNull);
      expect(t.dressCodeUnverified, isFalse);
      expect(t.hasDressCode, isFalse);
    });

    test('source type is only official or secondary', () {
      for (final v in ['Official', 'SECONDARY', 'none', '', ' official']) {
        expect(_temple(type: v).dressCodeSourceType, isNull, reason: v);
      }
      expect(dressCodeSourceTypeField('official'), 'official');
      expect(dressCodeSourceTypeField('secondary'), 'secondary');
      expect(dressCodeSourceTypeField(null), isNull);
    });

    test('verified as 0/1 or "true" is not a bool', () {
      for (final v in [0, 1, 'true', 'no']) {
        expect(_temple(verified: v).dressCodeVerified, isNull, reason: '$v');
      }
    });

    test('non-http source urls are rejected', () {
      for (final u in [
        '',
        '  ',
        'not a url',
        'ftp://x.org/dress',
        'javascript:alert(1)',
        'mailto:a@b.c',
        'file:///etc/hosts',
        'intent://x#Intent;end',
        'https://',
        '//x.org/dress',
      ]) {
        expect(_temple(url: u).dressCodeSourceUri, isNull, reason: u);
      }
      expect(_temple(url: 'http://x.org').dressCodeSourceUri, isNotNull);
      expect(
        _temple(url: '  https://x.org/a  ').dressCodeSourceUri.toString(),
        'https://x.org/a',
      );
    });

    test('blank dress code text is no dress code', () {
      for (final v in ['', '   ', '\n\t']) {
        expect(_temple(dressCode: v).hasDressCode, isFalse, reason: v);
      }
    });

    test('timings url getter still matches the shared parser', () {
      final t = Temple.fromMap('a', const {
        'timingsSourceUrl': 'javascript:alert(1)',
      });
      expect(t.timingsSourceUri, isNull);
      expect(httpSourceUri('https://x.org')!.host, 'x.org');
    });

    test('copyWith keeps and replaces dress-code fields', () {
      final t = _temple();
      final same = t.copyWith(name: 'Renamed');
      expect(same.dressCode, _rule);
      expect(same.dressCodeSourceUrl, _src);
      expect(same.dressCodeSourceType, 'secondary');
      expect(same.dressCodeVerified, isFalse);
      final changed = t.copyWith(
        dressCode: 'Modest clothing.',
        dressCodeVerified: true,
      );
      expect(changed.dressCode, 'Modest clothing.');
      expect(changed.dressCodeVerified, isTrue);
    });

    test('toFirestoreData never writes dress-code fields', () {
      final data = _temple().toFirestoreData();
      for (final f in _dressFields) {
        expect(data.containsKey(f), isFalse, reason: f);
      }
    });

    test('directory index entry has no dress-code fields', () {
      final entry = templeIndexEntryFromMap('shore-temple', _doc());
      for (final f in _dressFields) {
        expect(entry.containsKey(f), isFalse, reason: f);
      }
      final summary = templeFromIndexEntry(entry);
      expect(summary.hasDressCode, isFalse);
    });
  });

  group('admin save keeps dress-code fields', () {
    test('updateTemple merges and leaves all four fields', () async {
      final stored = _doc(type: 'official', verified: false);
      final store = MemoryTempleWriteStore(docs: {'shore-temple': stored});
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      // Admin form builds a fresh Temple from text fields; the dress code is
      // not on it.
      final edited = Temple.fromMap(
        'shore-temple',
        _doc(dressCode: null, url: null, type: null, verified: null),
      ).copyWith(name: 'Shore Temple (edited)');
      expect(edited.hasDressCode, isFalse);

      await service.updateTemple(edited);

      final after = store.docs['shore-temple']!;
      expect(after['name'], 'Shore Temple (edited)');
      expect(after['dressCode'], _rule);
      expect(after['dressCodeSourceUrl'], _src);
      expect(after['dressCodeSourceType'], 'official');
      expect(after['dressCodeVerified'], isFalse);
    });

    test('updateTemple with a loaded temple keeps the same values', () async {
      final store = MemoryTempleWriteStore(
        docs: {'shore-temple': _doc(verified: true)},
      );
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      final loaded = Temple.fromMap(
        'shore-temple',
        store.docs['shore-temple']!,
      );
      await service.updateTemple(loaded.copyWith(story: 'New story.'));
      final after = store.docs['shore-temple']!;
      expect(after['story'], 'New story.');
      expect(after['dressCodeVerified'], isTrue);
      expect(after['dressCode'], _rule);
    });

    test('image upload on a doc with research fields is not refused', () async {
      final store = MemoryTempleWriteStore(
        docs: {
          'shore-temple': {
            ..._doc(timingsUnverified: true),
            'timingsSourceType': 'official',
          },
        },
      );
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      final loaded = Temple.fromMap(
        'shore-temple',
        store.docs['shore-temple']!,
      );
      await service.appendTempleImages(loaded, ['https://example.org/new.jpg']);
      final after = store.docs['shore-temple']!;
      expect(after['images'], contains('https://example.org/new.jpg'));
      expect(after['dressCode'], _rule);
      expect(after['timingsVerified'], isFalse);
      expect(after['timingsSourceType'], 'official');
    });

    test('image upload still refuses an unknown extra field', () async {
      final store = MemoryTempleWriteStore(
        docs: {
          'shore-temple': {..._doc(), 'stray': 1},
        },
      );
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      await expectLater(
        service.appendTempleImages(
          Temple.fromMap('shore-temple', store.docs['shore-temple']!),
          ['https://example.org/new.jpg'],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('stray'),
          ),
        ),
      );
    });

    test('research fields are not in the client payload allow-list', () {
      for (final f in kTempleReadOnlyResearchFields) {
        expect(kTempleFirestoreAllowedFields.contains(f), isFalse, reason: f);
      }
      expect(kTempleReadOnlyResearchFields, containsAll(_dressFields));
      expect(
        () => assertTemplePayloadValidForRules({
          ..._temple().toFirestoreData(),
          'dressCode': 'x',
        }),
        throwsStateError,
      );
    });

    test('index shard written by the save has no dress-code fields', () async {
      final store = MemoryTempleWriteStore(docs: {'shore-temple': _doc()});
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      await service.updateTemple(
        Temple.fromMap('shore-temple', _doc()).copyWith(city: 'Mamallapuram'),
      );
      final entries = [
        for (final shard in store.shards.values) ...shard.values,
      ];
      expect(entries, isNotEmpty);
      for (final e in entries) {
        for (final f in _dressFields) {
          expect(e.containsKey(f), isFalse, reason: f);
        }
      }
    });
  });

  group('re-opening the detail screen', () {
    Temple summary() =>
        templeFromIndexEntry(templeIndexEntryFromMap('shore-temple', _doc()));

    Future<void> open(WidgetTester t) async {
      await t.tap(find.byKey(const Key('open')));
      await t.pump();
      await t.pump();
    }

    Future<void> back(WidgetTester t) async {
      final nav = t.state<NavigatorState>(find.byType(Navigator));
      nav.pop();
      await t.pumpAndSettle();
    }

    Future<void> host(
      WidgetTester t,
      Future<TempleDetailLoad> Function(String) load,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('open'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TempleDetailScreen(
                        temple: summary(),
                        loadTemple: load,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('index summary loads the doc, then shows the chip', (t) async {
      expect(summary().isIndexSummary, isTrue);
      expect(summary().hasDressCode, isFalse);
      final gate = Completer<TempleDetailLoad>();
      await host(t, (_) => gate.future);
      await open(t);
      expect(find.byKey(_section), findsNothing);
      gate.complete(TempleDetailLoad(temple: _temple()));
      await t.pump();
      await t.pump();
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
      await back(t);
    });

    testWidgets('open, back, open three times: one fresh section each', (
      t,
    ) async {
      var loads = 0;
      await host(t, (_) async {
        loads++;
        return TempleDetailLoad(temple: _temple());
      });
      for (var i = 0; i < 3; i++) {
        await open(t);
        expect(find.byKey(_section), findsOneWidget, reason: 'open $i');
        expect(find.byKey(_chip), findsOneWidget, reason: 'open $i');
        expect(find.byKey(_link), findsOneWidget, reason: 'open $i');
        await back(t);
        expect(find.byKey(_section), findsNothing, reason: 'back $i');
      }
      expect(loads, 3);
    });

    testWidgets('re-open picks up a verified change, then removal', (t) async {
      final docs = [
        _temple(),
        _temple(verified: true),
        _temple(dressCode: null, url: null, type: null, verified: null),
      ];
      var i = 0;
      await host(t, (_) async => TempleDetailLoad(temple: docs[i++]));

      await open(t);
      expect(find.byKey(_chip), findsOneWidget);
      await back(t);

      await open(t);
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsNothing);
      await back(t);

      await open(t);
      expect(find.byKey(_section), findsNothing);
      await back(t);
    });

    testWidgets('pending link launch survives back and re-open', (t) async {
      final gate = Completer<void>();
      final l = _FakeLauncher(gate: gate);
      UrlLauncherPlatform.instance = l;
      await host(t, (_) async => TempleDetailLoad(temple: _temple()));
      await open(t);
      await t.ensureVisible(find.byKey(_link));
      await t.tap(find.byKey(_link));
      await t.pump();
      await back(t);
      await open(t);
      gate.complete();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.byKey(_link));
      await t.tap(find.byKey(_link));
      await t.pumpAndSettle();
      expect(l.launches, 2);
    });

    testWidgets('cached detail still shows the dress code', (t) async {
      await host(
        t,
        (_) async => TempleDetailLoad(temple: _temple(), fromCache: true),
      );
      await open(t);
      expect(find.byKey(const Key('detail-cache-hint')), findsOneWidget);
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
    });
  });

  group('every way into detail shows the card (AC7)', () {
    late List<String> loaded;
    setUp(() {
      loaded = [];
      TempleDetailScreen.debugLoadTemple = (id) async {
        loaded.add(id);
        return TempleDetailLoad(temple: _temple());
      };
    });

    Temple summary() =>
        templeFromIndexEntry(templeIndexEntryFromMap('shore-temple', _doc()));

    testWidgets('Browse / Search / Home card (TempleBrowseCard)', (t) async {
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(children: [TempleBrowseCard(temple: summary())]),
          ),
        ),
      );
      await t.tap(find.byType(TempleBrowseCard));
      await t.pumpAndSettle();
      expect(loaded, ['shore-temple']);
      expect(find.byType(TempleDetailScreen), findsOneWidget);
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
    });

    testWidgets('a full document passed in shows the card without a load', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(home: TempleDetailScreen(temple: _temple())),
      );
      await t.pump();
      expect(loaded, isEmpty);
      expect(find.byKey(_section), findsOneWidget);
    });

    testWidgets('Near Me row', (t) async {
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final location = FakeCoarseLocation(
        permission: CoarsePermission.granted,
        fix: const CoarseFix(latitude: 12.616, longitude: 80.199),
      );
      await t.pumpWidget(
        MaterialApp(
          home: TemplesNearMeScreen(
            temples: [summary()],
            location: location,
            districtOf: (_) => null,
          ),
        ),
      );
      await t.pumpAndSettle();
      final cont = find.byKey(const Key('near-me-continue'));
      if (cont.evaluate().isNotEmpty) {
        await t.tap(cont);
        await t.pumpAndSettle();
      }
      final row = find.byKey(const Key('near-me-row-shore-temple'));
      await t.ensureVisible(row);
      await t.tap(row);
      await t.pumpAndSettle();
      expect(loaded, ['shore-temple']);
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
    });
    Future<void> pumpHome(WidgetTester t) async {
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      TempleService.readsBlocked = () => true;
      TempleService.published = [summary()];
      addTearDown(TempleService.resetSessionForTest);
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: HomeScreen(
            adminAuth: FakeAdminAuth(),
            adminToolsEnabled: false,
            templesLoader: () async => [summary()],
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> openCardFromList(WidgetTester t) async {
      expect(find.byType(TempleListScreen), findsOneWidget);
      final card = find.byType(TempleBrowseCard).first;
      await t.ensureVisible(card);
      await t.tap(card);
      await t.pumpAndSettle();
      expect(loaded, ['shore-temple']);
      expect(find.byType(TempleDetailScreen), findsOneWidget);
      await t.ensureVisible(find.byKey(_section));
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
      expect(find.byKey(_link), findsOneWidget);
    }

    testWidgets('Home: Browse temples, then a card', (t) async {
      await pumpHome(t);
      await t.tap(find.byKey(const Key('home-browse-temples')));
      await t.pumpAndSettle();
      await openCardFromList(t);
    });

    testWidgets(
      'Home: Near Me opens on the same directory (row to card: Near Me row test)',
      (t) async {
        await pumpHome(t);
        final nearMe = find.byKey(const Key('home-near-me'));
        await t.ensureVisible(nearMe);
        await t.tap(nearMe);
        await t.pumpAndSettle();
        expect(find.byType(TemplesNearMeScreen), findsOneWidget);
      },
    );

    testWidgets('Drawer: All Temples, then a card', (t) async {
      await pumpHome(t);
      await t.tap(find.byTooltip('Open navigation menu'));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('All Temples'),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      await openCardFromList(t);
    });

    testWidgets('Drawer from the list, card, back, re-open', (t) async {
      await pumpHome(t);
      await t.tap(find.byKey(const Key('home-browse-temples')));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Open navigation menu').first);
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('All Temples'),
        ),
      );
      await t.pumpAndSettle();
      await openCardFromList(t);
      t.state<NavigatorState>(find.byType(Navigator)).pop();
      await t.pumpAndSettle();
      expect(find.byKey(_section), findsNothing);
      final card = find.byType(TempleBrowseCard).first;
      await t.tap(card);
      await t.pumpAndSettle();
      expect(loaded, ['shore-temple', 'shore-temple']);
      expect(find.byKey(_section), findsOneWidget);
      expect(find.byKey(_chip), findsOneWidget);
    });
  });
}
