import 'package:flutter/widgets.dart';
import 'package:temple_app/l10n/app_localizations.dart';

export 'package:temple_app/l10n/app_localizations.dart';

/// Locales wired into [MaterialApp].
///
/// The device locale is used when its language is one of the nine ARB
/// locales. Anything else resolves to English. Flutter 3.47 already ships
/// Odia Material and Cupertino strings, so those delegates are the generated
/// set with no extra fallback.
abstract final class AppLocale {
  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      AppLocalizations.localizationsDelegates;

  static Locale resolve(Locale? locale, Iterable<Locale> supported) {
    if (locale != null) {
      for (final Locale item in supported) {
        if (item.languageCode == locale.languageCode) return item;
      }
    }
    return const Locale('en');
  }
}

/// English bundle for helpers that tests call without a [BuildContext].
///
/// Widgets that a person can see should use [AppLocalizationsBuildContext.l10n]
/// so the resolved locale is the one that supplies the string.
abstract final class L10nLookup {
  static final AppLocalizations english = lookupAppLocalizations(
    const Locale('en'),
  );
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
