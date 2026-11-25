import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/l10n/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('an unsupported device locale falls back to English', () {
    expect(
      AppLocale.resolve(const Locale('fr'), AppLocale.supportedLocales),
      const Locale('en'),
    );
    expect(
      AppLocale.resolve(const Locale('hi'), AppLocale.supportedLocales),
      const Locale('hi'),
    );
    expect(
      AppLocale.resolve(null, AppLocale.supportedLocales),
      const Locale('en'),
    );
  });

  testWidgets('picking Hindi changes visible text', (tester) async {
    await tester.pumpWidget(const _LocaleHarness());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-language')));
    await tester.pumpAndSettle();
    expect(find.text('System default'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ଓଡ଼ିଆ'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('ଓଡ଼ିଆ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-option-hi')));
    await tester.pumpAndSettle();
    expect(find.text('होम'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('a saved choice is restored and beats the device locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({localePreferenceKey: 'hi'});
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const _LocaleHarness());
    await tester.pumpAndSettle();
    expect(find.text('होम'), findsOneWidget);
  });

  testWidgets('System default follows the device locale', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('hi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const _LocaleHarness());
    await tester.pumpAndSettle();
    expect(find.text('होम'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-option-system')));
    await tester.pumpAndSettle();
    expect(find.text('होम'), findsOneWidget);
  });

  testWidgets('an unsupported device locale shows English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const _LocaleHarness());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}

class _LocaleHarness extends StatefulWidget {
  const _LocaleHarness();

  @override
  State<_LocaleHarness> createState() => _LocaleHarnessState();
}

class _LocaleHarnessState extends State<_LocaleHarness> {
  late final AppLocaleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppLocaleController();
    _controller.addListener(_rebuild);
    _controller.load();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _controller,
      child: MaterialApp(
        locale: _controller.override,
        localeResolutionCallback: AppLocale.resolve,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  Text(
                    context.l10n.commonHomeLabel,
                    key: const Key('sample-label'),
                  ),
                  TextButton(
                    key: const Key('open-language'),
                    onPressed: () => showAppLanguagePicker(context),
                    child: Text(context.l10n.drawerLanguageTitle),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
