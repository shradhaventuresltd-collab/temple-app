import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Material strings for Odia.
///
/// Flutter's [GlobalMaterialLocalizations] delegate does not support `or`.
/// This delegate loads the English Material strings so an Odia [Locale] can
/// still build [MaterialApp].
class OdiaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const OdiaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'or';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(OdiaMaterialLocalizationsDelegate old) => false;
}

/// Cupertino strings for Odia, loaded from English.
class OdiaCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const OdiaCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'or';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(OdiaCupertinoLocalizationsDelegate old) => false;
}
