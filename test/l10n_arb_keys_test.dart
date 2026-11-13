import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/app_locale.dart';

/// Locales from the multi-language design, besides the English template.
const _localeCodes = ['bn', 'hi', 'kn', 'ml', 'mr', 'or', 'ta', 'te'];

/// Copy that stays identical in every language: placeholder patterns and
/// Latin proper names. A real sentence left equal to English is not here.
const _sameInEveryLanguage = {
  'licencesBharatlasLinkLabel',
  'licencesCcByLinkLabel',
  'templeBrowsePlaceLabel',
  'templeDetailGalleryPositionLabel',
};

void main() {
  test('every locale ARB has each app_en.arb message key', () {
    final english = _readArb(File('lib/l10n/app_en.arb'));
    final englishKeys = _messageKeys(english);

    expect(english['@@locale'], 'en');
    expect(englishKeys, isNotEmpty);

    for (final key in englishKeys) {
      expect(
        english.containsKey('@$key'),
        isTrue,
        reason: 'app_en.arb is missing @description metadata for $key',
      );
      final meta = english['@$key'];
      expect(meta, isA<Map>(), reason: '@$key must be metadata');
      expect(
        (meta as Map)['description'],
        isA<String>(),
        reason: '@$key needs a description',
      );
    }

    for (final code in _localeCodes) {
      final file = File('lib/l10n/app_$code.arb');
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
      final arb = _readArb(file);
      expect(arb['@@locale'], code);
      expect(
        arb['@@x-needs-translation'],
        'machine draft pending review',
        reason: 'app_$code.arb must be marked as a machine draft',
      );

      final keys = _messageKeys(arb);
      final missing = englishKeys.difference(keys);
      final extra = keys.difference(englishKeys);
      expect(missing, isEmpty, reason: 'app_$code.arb is missing $missing');
      expect(extra, isEmpty, reason: 'app_$code.arb has extra keys $extra');

      for (final key in englishKeys) {
        expect(
          _placeholderNames(arb[key] as String),
          _placeholderNames(english[key] as String),
          reason: 'app_$code.arb key $key has different placeholders',
        );
      }
    }
  });

  test('Odia is a full catalog, not a stub', () {
    final english = _messageKeys(_readArb(File('lib/l10n/app_en.arb')));
    final odia = _messageKeys(_readArb(File('lib/l10n/app_or.arb')));
    expect(odia, english);
    expect(odia.length, greaterThan(200));
  });

  test('ui libraries have no new user-visible literals', () {
    final leftovers = <String>[];
    for (final folder in ['lib/screens', 'lib/widgets', 'lib/near_me']) {
      for (final entity in Directory(folder).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll('\\', '/');
        if (path.contains('/admin_') ||
            path.contains('debug_') ||
            path.contains('seed_temples') ||
            path.contains('policy_acceptance_gate.dart') ||
            path.contains('place_type_icon.dart')) {
          continue;
        }
        final lines = entity.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('l10n-allow') ||
              line.trimLeft().startsWith('//') ||
              line.contains('debugPrint(') ||
              line.contains('throw ') ||
              line.contains('toString()')) {
            continue;
          }
          for (final body in _stringBodies(_withoutLineComment(line))) {
            if (!_isChrome(body)) continue;
            leftovers.add('$path:${i + 1}: $body');
          }
        }
      }
    }
    expect(leftovers, isEmpty);
  });

  test('untranslated strings are reported and do not fail CI', () {
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final same = <String>[];
    for (final code in _localeCodes) {
      final arb =
          jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final entry in english.entries) {
        if (entry.key.startsWith('@')) continue;
        if (entry.key.startsWith('languageEndonym')) continue;
        if (_sameInEveryLanguage.contains(entry.key)) continue;
        if (arb[entry.key] == entry.value) {
          same.add('$code.${entry.key}');
        }
      }
    }
    // ignore: avoid_print
    print(
      'L10N_UNTRANSLATED ${same.length} values still match English'
      '${same.isEmpty ? '' : ': ${same.take(12).join(', ')}'}',
    );
    // Missing keys fail the parity test above. Identical copy is a review
    // warning here. A release gate can refuse it with L10N_RELEASE_GATE=1.
    if (Platform.environment['L10N_RELEASE_GATE'] == '1') {
      expect(same, isEmpty, reason: 'release gate refuses untranslated copy');
    }
  });

  test('supported locales include the nine shipped languages', () {
    expect(
      AppLocale.supportedLocales.map((locale) => locale.languageCode).toList(),
      ['en', 'hi', 'kn', 'ml', 'ta', 'te', 'mr', 'bn', 'or'],
    );
    expect(
      AppLocale.resolve(const Locale('fr'), AppLocale.supportedLocales),
      const Locale('en'),
    );
  });
}

Map<String, Object?> _readArb(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}

Set<String> _messageKeys(Map<String, Object?> arb) {
  return {
    for (final key in arb.keys)
      if (!key.startsWith('@') && arb[key] is String) key,
  };
}

Set<String> _placeholderNames(String value) {
  final names = <String>{};
  var i = 0;
  while (i < value.length) {
    if (value[i] != '{') {
      i++;
      continue;
    }
    final start = i + 1;
    var j = start;
    while (j < value.length && RegExp(r'[A-Za-z0-9_]').hasMatch(value[j])) {
      j++;
    }
    if (j == start || j >= value.length) {
      i++;
      continue;
    }
    final name = value.substring(start, j);
    if (value[j] == '}' || value[j] == ',') {
      names.add(name);
      i = _skipBraced(value, i);
      continue;
    }
    i++;
  }
  return names;
}

bool _isChrome(String body) {
  if (!RegExp(r'[A-Za-z]').hasMatch(body)) return false;
  if (body.toLowerCase() == body) return false;
  if (RegExp(r'^M[\d .A-Za-z,-]+$').hasMatch(body)) return false;
  if (const {'M', 'L', 'H', 'V', 'C', 'Z'}.contains(body)) return false;
  return body.contains(' ') || RegExp(r'^[A-Z]').hasMatch(body);
}

String _withoutLineComment(String line) {
  final mark = line.indexOf('//');
  if (mark < 0) return line;
  return line.substring(0, mark);
}

List<String> _stringBodies(String code) {
  final bodies = <String>[];
  final pattern = RegExp("'[^']*'|" '"[^"]*"');
  for (final match in pattern.allMatches(code)) {
    final raw = match.group(0)!;
    bodies.add(raw.substring(1, raw.length - 1));
  }
  return bodies;
}

int _skipBraced(String value, int open) {
  var depth = 0;
  for (var i = open; i < value.length; i++) {
    if (value[i] == '{') depth++;
    if (value[i] == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return value.length;
}
