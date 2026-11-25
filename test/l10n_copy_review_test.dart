import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/app_locale.dart';

const _locales = ['bn', 'hi', 'kn', 'ml', 'mr', 'or', 'ta', 'te'];

const _scriptBlocks = {
  'hi': (0x0900, 0x097F),
  'mr': (0x0900, 0x097F),
  'bn': (0x0980, 0x09FF),
  'or': (0x0B00, 0x0B7F),
  'ta': (0x0B80, 0x0BFF),
  'te': (0x0C00, 0x0C7F),
  'kn': (0x0C80, 0x0CFF),
  'ml': (0x0D00, 0x0D7F),
};

const _neutralNotes = [
  'templeDetailFramingNeutralNote',
  'templeDetailFramingJainNeutralNote',
  'templeDetailFramingBuddhistNeutralNote',
  'templeDetailFramingSikhNeutralNote',
];

/// Words that mean Hindu puja. Neutral and Sikh/Jain/Buddhist notes must not
/// use them. A longer word that merely starts with the same letters is checked
/// as a whole token below.
const _pujaWords = [
  'पूजा',
  'পূজা',
  'ପୂଜା',
  'ಪೂಜ',
  'పూజ',
  'பூஜை',
  'പൂജ',
  'puja',
  'Puja',
];

void main() {
  final english = _read('en');

  test('Temple Directory India stays in Latin via {appName}', () {
    expect(english['appTitle'], 'Temple Directory India');
    expect(english['appNameShort'], 'Temple Directory');
    expect(
      english['forceUpdateBody'],
      'This version of {appName} is no longer supported. '
      'Install the latest version from the Play Store to continue.',
    );
    expect(
      english['maintenanceFallbackMessage'],
      '{appName} is temporarily unavailable. Please try again later.',
    );

    final rendered = L10nLookup.english.forceUpdateBody(
      L10nLookup.english.appTitle,
    );
    expect(
      rendered,
      'This version of Temple Directory India is no longer supported. '
      'Install the latest version from the Play Store to continue.',
    );
    expect(
      L10nLookup.english.maintenanceFallbackMessage(
        L10nLookup.english.appNameShort,
      ),
      'Temple Directory is temporarily unavailable. Please try again later.',
    );

    const transliterations = [
      'मंदिर निर्देशिका',
      'मंदिर डायरेक्टरी',
      'ದೇವಾಲಯ ಡೈರೆಕ್ಟರಿ',
      'ക്ഷേത്ര ഡയറക്ടറി',
      'கோவில் அடைவு',
      'దేవాలయ డైరెక్టరీ',
      'মন্দির নির্দেশিকা',
      'ମନ୍ଦିର ଡାଇରେକ୍ଟୋରୀ',
    ];
    for (final code in ['en', ..._locales]) {
      final arb = code == 'en' ? english : _read(code);
      expect(arb['appTitle'], 'Temple Directory India', reason: code);
      expect(arb['appNameShort'], 'Temple Directory', reason: code);
      expect(arb['forceUpdateBody'], contains('{appName}'), reason: code);
      expect(
        arb['maintenanceFallbackMessage'],
        contains('{appName}'),
        reason: code,
      );
      for (final entry in arb.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        for (final banned in transliterations) {
          expect(
            entry.value,
            isNot(contains(banned)),
            reason: '$code.${entry.key} transliterates the brand',
          );
        }
      }
    }
  });

  test('Sikh, Jain, Buddhist and neutral notes do not say puja', () {
    for (final code in _locales) {
      final arb = _read(code);
      for (final key in _neutralNotes) {
        final value = arb[key] as String;
        for (final word in _pujaWords) {
          expect(value, isNot(contains(word)), reason: '$code.$key');
        }
      }
    }
  });

  test('Odia monument, neutral and timings copy has no darshan', () {
    final or = _read('or');
    final keys = or.keys.where((key) {
      if (key.startsWith('@')) return false;
      if (key.startsWith('templeDetailTimings')) return true;
      if (key == 'templeDetailVisitingHoursTitle') return true;
      if (key == 'templeDetailHeritageVisitLabel') return true;
      if (key.startsWith('directoryDeityNote')) return true;
      return key.startsWith('templeDetailFraming') &&
          (key.contains('Monument') || key.contains('Neutral'));
    });
    expect(keys, isNotEmpty);
    for (final key in keys) {
      expect(or[key], isNot(contains('ଦର୍ଶନ')), reason: key);
      expect(or[key], isNot(contains('\u0BCD')), reason: key);
    }
    expect(or['templeDetailVisitingHoursTitle'], 'ଖୋଲିବା ସମୟ');
    expect(or['templeDetailHeritageVisitLabel'], contains('ଐତିହ୍ୟ ଭ୍ରମଣ'));
    expect(or['templeDetailTimingsSeasonalMultiMessage'], contains('ଯାତ୍ରା'));
    expect(
      or['templeDetailTimingsSeasonalMultiMessage'],
      isNot(contains('ୟାତ୍ରା')),
    );
    expect(or['templeDetailTimingsMissingMessage'], contains('ଖୋଲିବା ସମୟ'));
    expect(or['templeDetailTimingsMultiWindowMessage'], contains('ପ୍ରବେଶ ସମୟ'));
  });

  test('Hindi and Bengali visiting-hours copy does not say darshan', () {
    final hi = _read('hi');
    final bn = _read('bn');
    for (final key in hi.keys) {
      if (key.startsWith('@')) continue;
      final visiting =
          key.startsWith('templeDetailTimings') ||
          key == 'templeDetailVisitingHoursTitle' ||
          key == 'templeDetailHeritageVisitLabel' ||
          (key.startsWith('templeDetailFraming') &&
              (key.contains('Monument') || key.contains('Neutral')));
      if (!visiting) continue;
      expect(hi[key], isNot(contains('दर्शन')), reason: key);
      final bengali = bn[key] as String;
      expect(
        bengali.contains('দর্শনার্থী')
            ? bengali.replaceAll('দর্শনার্থী', '')
            : bengali,
        isNot(contains('দর্শন')),
        reason: key,
      );
    }
  });

  test('Bengali tradition keys say পরম্পরা, not ঐতিহ্য', () {
    final bn = _read('bn');
    const heritage = 'ঐতিহ্য';
    const parampara = 'পরম্পরা';
    final traditionKeys = [
      for (final key in bn.keys)
        if (!key.startsWith('@') && key.contains('Tradition')) key,
    ];
    expect(traditionKeys, isNotEmpty);
    for (final key in traditionKeys) {
      expect(bn[key], isNot(contains(heritage)), reason: key);
    }
    expect(bn['filterSheetAnyTraditionLabel'], 'যেকোনো $parampara');
    expect(bn['filterChipChooseTraditionTooltip'], 'একটি পরম্পরা বেছে নিন');
    expect(bn['filterChipClearTraditionTooltip'], 'পরম্পরা ফিল্টার মুছুন');
    expect(bn['filterSheetChangeTraditionButton'], 'পরম্পরা বদলান');
    expect(bn['filterSheetSearchTraditionHint'], 'পরম্পরা খুঁজুন');
  });

  test('each non-English value stays in its own script', () {
    final offenders = <String>[];
    for (final code in _locales) {
      final block = _scriptBlocks[code]!;
      final arb = _read(code);
      for (final entry in arb.entries) {
        final key = entry.key;
        if (key.startsWith('@') || key.startsWith('languageEndonym')) continue;
        final value = entry.value;
        if (value is! String) continue;
        final stripped = _stripBraces(value);
        for (final rune in stripped.runes) {
          if (_runeAllowed(rune, block)) continue;
          offenders.add('$code.$key U+${rune.toRadixString(16).toUpperCase()}');
          break;
        }
      }
    }
    expect(offenders, isEmpty);
  });
}

Map<String, Object?> _read(String code) {
  final decoded = jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync());
  return Map<String, Object?>.from(decoded as Map);
}

String _stripBraces(String value) {
  final out = StringBuffer();
  var depth = 0;
  for (final rune in value.runes) {
    if (rune == 0x7B) {
      depth++;
      continue;
    }
    if (rune == 0x7D) {
      if (depth > 0) depth--;
      continue;
    }
    if (depth == 0) out.writeCharCode(rune);
  }
  return out.toString();
}

bool _runeAllowed(int rune, (int, int) block) {
  if (rune < 0x80) return true;
  if (rune >= 0xA0 && rune <= 0xFF) return true;
  if (rune >= 0x2000 && rune <= 0x206F) return true;
  if (rune == 0x200C || rune == 0x200D) return true;
  if (rune == 0x0964 || rune == 0x0965) return true;
  if (rune == 0x2630) return true;
  return rune >= block.$1 && rune <= block.$2;
}
