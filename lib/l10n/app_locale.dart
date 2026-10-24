import 'package:flutter/widgets.dart';
import 'package:temple_app/l10n/app_localizations.dart';

export 'package:temple_app/l10n/app_localizations.dart';

/// Locales wired into [MaterialApp].
///
/// Every ARB is generated, but a language is advertised only when its file
/// has no `@@x-needs-translation` flag. Placeholders stay English, so
/// offering them would claim a translation that is not there. [resolve]
/// only returns a language from [supportedLocales]. Removing the flag and
/// adding that language here is what turns it on; the ARB key test fails
/// until the two match.
abstract final class AppLocale {
  /// Generated bundles. Includes locales that are still placeholders.
  static const List<Locale> generatedLocales =
      AppLocalizations.supportedLocales;

  /// Locales a device may resolve to. English until the other ARBs are translated.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      AppLocalizations.localizationsDelegates;

  /// Locales from [generated] whose language is not in [needsTranslation].
  ///
  /// Order follows [generated], which lists English first.
  static List<Locale> localesReady(
    Iterable<Locale> generated,
    Set<String> needsTranslation,
  ) {
    return [
      for (final Locale locale in generated)
        if (!needsTranslation.contains(locale.languageCode)) locale,
    ];
  }

  static Locale resolve(Locale? locale, Iterable<Locale> supported) {
    if (locale != null) {
      for (final Locale item in supportedLocales) {
        final matchesDevice = item.languageCode == locale.languageCode;
        final offered = supported.any(
          (Locale candidate) => candidate.languageCode == item.languageCode,
        );
        if (matchesDevice && offered) return item;
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
