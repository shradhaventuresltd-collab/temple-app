import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:temple_app/l10n/app_localizations.dart';
import 'package:temple_app/l10n/odia_localizations.dart';

export 'package:temple_app/l10n/app_localizations.dart';

/// Locales wired into [MaterialApp].
///
/// Every ARB is generated. A non-English file carries
/// `@@x-needs-translation` while its copy is a machine draft. The draft is
/// still offered: Odia ships in full, and choosing a language must change
/// the UI. This release's drafts are real translations, so every supported
/// language is offered.
abstract final class AppLocale {
  /// Generated bundles, English first.
  static const List<Locale> generatedLocales =
      AppLocalizations.supportedLocales;

  /// Locales a device or the picker may resolve to.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
    Locale('mr'),
    Locale('bn'),
    Locale('or'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        OdiaMaterialLocalizationsDelegate(),
        OdiaCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

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
  /// Resolved strings, or English when a test [MaterialApp] has no delegates.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      L10nLookup.english;
}
