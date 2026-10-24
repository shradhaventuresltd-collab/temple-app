import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/app_locale.dart';

/// Locales from the multi-language design, besides the English template.
const _localeCodes = ['bn', 'hi', 'kn', 'ml', 'mr', 'or', 'ta', 'te'];

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
    }

    for (final code in _localeCodes) {
      final file = File('lib/l10n/app_$code.arb');
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
      final arb = _readArb(file);
      expect(arb['@@locale'], code);
      expect(
        arb['@@x-needs-translation'],
        isNotNull,
        reason: 'app_$code.arb placeholders must be marked for translation',
      );

      final keys = _messageKeys(arb);
      final missing = englishKeys.difference(keys);
      expect(
        missing,
        isEmpty,
        reason: 'app_$code.arb is missing keys from app_en.arb: $missing',
      );

      for (final key in englishKeys) {
        final expected = _placeholderNames(english[key] as String);
        final actual = _placeholderNames(arb[key] as String);
        expect(
          actual,
          expected,
          reason: 'app_$code.arb key $key has different placeholders',
        );
      }
    }
  });

  test('an unsupported locale resolves to English', () {
    expect(
      AppLocale.resolve(const Locale('fr'), AppLocale.supportedLocales),
      const Locale('en'),
    );
    expect(
      AppLocale.resolve(const Locale('hi', 'IN'), AppLocale.supportedLocales),
      const Locale('hi'),
    );
    expect(
      AppLocale.resolve(null, AppLocale.supportedLocales),
      const Locale('en'),
    );
  });

  test('screens, widgets, and near_me have no new user-visible literals', () {
    final leftovers = <String>[];
    for (final folder in ['lib/screens', 'lib/widgets', 'lib/near_me']) {
      for (final entity in Directory(folder).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        leftovers.addAll(_visibleLiterals(entity));
      }
    }
    expect(leftovers, isEmpty);
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

final _stringLiteral = RegExp(
  '''('(?:\\\\.|[^'\\\\])*'|"(?:\\\\.|[^"\\\\])*")''',
);
final _skipLine = RegExp(
  r'debugPrint\(|\bKey\(|identifier:|throw |assert |\bfieldKey:',
);

Iterable<String> _visibleLiterals(File file) sync* {
  final source = file.readAsStringSync().replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.contains('l10n-allow')) continue;
    final code = line.contains('//')
        ? line.substring(0, line.indexOf('//'))
        : line;
    if (_skipLine.hasMatch(code)) continue;
    for (final match in _stringLiteral.allMatches(code)) {
      final raw = match.group(0)!;
      final body = raw
          .substring(1, raw.length - 1)
          .replaceAll(RegExp(r'\$\{[^{}]*\}'), '')
          .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '');
      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(body);
      final userVisible =
          hasLetter && (body.contains(' ') || RegExp(r'^[A-Z]').hasMatch(body));
      if (userVisible) {
        yield '${file.path}:${index + 1}: $raw';
      }
    }
  }
}
