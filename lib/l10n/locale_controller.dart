import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/l10n/display_labels.dart';

/// Saved language choice. `system` follows the device locale.
const localePreferenceKey = 'app_locale';
const localePreferenceSystem = 'system';

/// Persists the language picker on the device. No Firestore read.
class LocalePreferenceStore {
  const LocalePreferenceStore({this.readPrefs});

  /// Test hook. Production uses [SharedPreferences.getInstance].
  final Future<SharedPreferences> Function()? readPrefs;

  Future<SharedPreferences> _prefs() {
    final reader = readPrefs;
    if (reader != null) return reader();
    return SharedPreferences.getInstance();
  }

  Future<String?> read() async {
    final prefs = await _prefs();
    return prefs.getString(localePreferenceKey);
  }

  Future<void> write(String? code) async {
    final prefs = await _prefs();
    if (code == null || code == localePreferenceSystem) {
      await prefs.remove(localePreferenceKey);
      return;
    }
    await prefs.setString(localePreferenceKey, code);
  }
}

/// The in-app locale. Null means system default.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({LocalePreferenceStore? store})
    : _store = store ?? const LocalePreferenceStore();

  final LocalePreferenceStore _store;
  Locale? _override;

  /// Explicit choice. Null follows the device locale.
  Locale? get override => _override;

  Future<void> load() async {
    final saved = await _store.read();
    _override = _localeFor(saved);
    notifyListeners();
  }

  Future<void> choose(Locale? locale) async {
    _override = locale;
    notifyListeners();
    await _store.write(locale?.languageCode);
  }

  static Locale? _localeFor(String? saved) {
    if (saved == null || saved.isEmpty || saved == localePreferenceSystem) {
      return null;
    }
    for (final locale in AppLocale.supportedLocales) {
      if (locale.languageCode == saved) return locale;
    }
    return null;
  }
}

/// Exposes [AppLocaleController] under the app so the drawer can switch
/// language without replacing the navigator.
class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLocaleScope>()
        ?.notifier;
  }

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope is missing above this widget');
    return scope!.notifier!;
  }
}

/// Drawer language sheet. Choosing a language rebuilds [MaterialApp]'s locale
/// and leaves the navigator stack in place.
Future<void> showAppLanguagePicker(BuildContext context) async {
  final controller = AppLocaleScope.of(context);
  final l10n = context.l10n;
  final selected = controller.override?.languageCode;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('language-picker'),
        title: Text(l10n.drawerLanguageTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                key: const Key('language-option-system'),
                title: Text(l10n.drawerLanguageSystemDefault),
                selected: selected == null,
                onTap: () {
                  Navigator.pop(dialogContext);
                  unawaited(controller.choose(null));
                },
              ),
              for (final locale in AppLocale.supportedLocales)
                ListTile(
                  key: Key('language-option-${locale.languageCode}'),
                  title: Text(languageEndonym(l10n, locale.languageCode)),
                  selected: selected == locale.languageCode,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    unawaited(controller.choose(locale));
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
