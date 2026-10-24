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

  test('an unsupported or untranslated locale resolves to English', () {
    expect(AppLocale.supportedLocales, const [Locale('en')]);
    expect(
      AppLocale.resolve(const Locale('fr'), AppLocale.supportedLocales),
      const Locale('en'),
    );
    expect(
      AppLocale.resolve(const Locale('hi', 'IN'), AppLocale.supportedLocales),
      const Locale('en'),
    );
    expect(
      AppLocale.resolve(const Locale('hi'), AppLocalizations.supportedLocales),
      const Locale('en'),
    );
    expect(
      AppLocale.resolve(null, AppLocale.supportedLocales),
      const Locale('en'),
    );
  });

  test('supportedLocales follow ARBs that are not awaiting translation', () {
    final needsTranslation = <String>{};
    for (final code in ['en', ..._localeCodes]) {
      final arb = _readArb(File('lib/l10n/app_$code.arb'));
      if (arb.containsKey('@@x-needs-translation')) {
        needsTranslation.add(code);
      }
    }
    final ready = AppLocale.localesReady(
      AppLocale.generatedLocales,
      needsTranslation,
    );
    expect(
      AppLocale.supportedLocales.map((locale) => locale.languageCode).toList(),
      ready.map((locale) => locale.languageCode).toList(),
      reason:
          'Advertised locales must be the generated locales whose ARB has '
          'no @@x-needs-translation flag. Remove the flag and add that '
          'Locale to AppLocale.supportedLocales together.',
    );
  });

  test('comment stripping keeps // inside strings', () {
    final code = _withoutLineComment(
      "final url = 'https://example.com/a'; // trailing note",
    );
    expect(code, contains('https://example.com/a'));
    expect(code.contains('trailing'), isFalse);
    expect(_isUserVisible('lib/screens/home_screen.dart', 'or'), isTrue);
    expect(_isUserVisible('lib/screens/home_screen.dart', 'api'), isFalse);
    expect(_isUserVisible('lib/utils/detail_honesty.dart', 'or'), isFalse);
  });

  test('ui and service libraries have no new user-visible literals', () {
    final leftovers = <String>[];
    for (final folder in [
      'lib/screens',
      'lib/widgets',
      'lib/near_me',
      'lib/utils',
      'lib/services',
    ]) {
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

final _skipLine = RegExp(
  r'debugPrint\(|\bKey\(|identifier:|throw |assert |\bfieldKey:',
);

/// Single lowercase words that are identifiers, not chrome.
///
/// `or` and `km` are not listed for screens, widgets, or near_me, so a new
/// `Text('or')` fails this test.
const _uiTreeWords = {'api', 'destination', 'jpg'};

const _libraryWords = {
  'a',
  'aa',
  'above',
  'address',
  'admin',
  'am',
  'and',
  'are',
  'around',
  'author',
  'b',
  'be',
  'been',
  'begins',
  'beside',
  'buddhist',
  'but',
  'city',
  'commons',
  'credit',
  'd',
  'deity',
  'description',
  'devaswom',
  'did',
  'do',
  'does',
  'durga',
  'ee',
  'endowments',
  'entries',
  'error',
  'excavated',
  'excavation',
  'excavations',
  'firebase',
  'fort',
  'gcs',
  'gettyimages',
  'gif',
  'had',
  'has',
  'have',
  'held',
  'holds',
  'hrce',
  'http',
  'https',
  'i',
  'id',
  'images',
  'index',
  'is',
  'jain',
  'jpeg',
  'jpg',
  'kali',
  'kovil',
  'l',
  'latitude',
  'licence',
  'linga',
  'living',
  'location',
  'longitude',
  'mandir',
  'monument',
  'myself',
  'na',
  'name',
  'never',
  'no',
  'not',
  'o',
  'oo',
  'or',
  'order',
  'photos',
  'pm',
  'png',
  'puja',
  'pujas',
  'px',
  'rather',
  'revealed',
  'runs',
  's',
  'self',
  'server',
  'sh',
  'shards',
  'shri',
  'sikh',
  'siva',
  'sivan',
  'specialities',
  'sri',
  'st',
  'starts',
  'state',
  'storage',
  'story',
  'svg',
  'swami',
  'swamy',
  't',
  'temple',
  'temples',
  'th',
  'than',
  'thumb',
  'timings',
  'tirumala',
  'tirupati',
  'to',
  'tradition',
  'u',
  'unavailable',
  'unknown',
  'unknownartist',
  'unknownauthor',
  'unknownphotographer',
  'unlike',
  'unrecognized',
  'url',
  'v',
  'various',
  'w',
  'was',
  'webp',
  'were',
  'wikimedia',
  'wikipedia',
  'without',
  'zh',
};

/// Admin CMS, sign-in, seed, and form-validation copy that stays in the
/// service layer (shown from snackbars and field errors, pinned by tests).
/// Also programmer identifiers the sentence scan would otherwise flag.
const _serviceLiterals = {
  'Enter a valid email address.',
  'This account has been disabled.',
  'INVALID_LOGIN_CREDENTIALS',
  'Email or password is incorrect.',
  'Too many attempts. Try again later.',
  'Network error. Check your connection and retry.',
  'Email/password sign-in is not enabled in Firebase Auth.',
  'Sign-in failed (). Check email/password',
  'and that Email/Password is enabled in Firebase Auth.',
  'Exception:',
  'Sign-in failed.',
  'FirebaseAuth.instance',
  'Name is required.',
  'State is required.',
  'City is required.',
  'Deity is required.',
  'Location / address is required.',
  'Enter a latitude.',
  'Enter a longitude.',
  'Use a photograph URL. Placeholder hosts are not saved.',
  'Use a photograph URL. Unlicensed stock hosts are not saved.',
  'Use a credited photograph. Google Places mirrors are not saved.',
  'Use photograph URLs. Placeholder hosts are not saved.',
  'Use photograph URLs. Unlicensed stock hosts are not saved.',
  'Use credited photographs. Google Places mirrors are not saved.',
  'Enter a valid .',
  'must be between  and .',
  'Temple seeding is only available in debug builds',
  '(or demo builds with ENABLE_ADMIN_TOOLS).',
  'Seeding requires a signed-in admin (custom claim admin: true).',
  'Temple was not found. It may have already been deleted.',
  'Storage upload succeeded, but Firestore could not save the image',
  'Could not delete Storage objects for this temple.',
  'The Firestore document was not removed.',
  'Removed  Storage object(s), but the Firestore',
  'document could not be deleted.',
  'Temple CMS writes are only available in debug builds',
  'Writes require a signed-in admin (custom claim admin: true).',
  'This temple document has extra fields () that',
  'Firestore rules reject on update. Open Edit and save to rewrite a',
  'valid document, then retry Upload.',
  'Temple payload has fields Firestore rules do not allow:',
  'Temple "" is required for Firestore rules and was missing.',
  'Temple "" is empty; Firestore rules require a non-empty string.',
  'Temple "" is  characters;',
  'Firestore rules allow at most .',
  'Temple "imageUrl" is  characters;',
  'Firestore rules allow at most 2000.',
  'Temple "" has  items;',
  'Temple "" must be null or a number between  and .',
  'CC-BY',
  'CC-BY-SA',
  'CC0',
  'Own',
  'Permission',
  'Temple "photos" has  items; Firestore rules allow at most 12.',
  'Temple photo  url must be an https string of at most 2000 characters.',
  'Temple photo  licence must be CC-BY, CC-BY-SA, CC0, Own, or Permission.',
  'Temple photo  order must be an integer from 0 to 11.',
  'Temple photo  credit must be a string of at most 200 characters.',
  'Credit is required for .',
  'Write failed.',
  'Permission denied. Sign in as an admin',
  '(custom claim admin: true) and retry.',
  'Permission denied. If you are not signed in as an admin',
  '(custom claim admin: true), grant that claim and retry.',
  'If you already are an admin, Firestore rejected the temple',
  'document — required fields may be missing or empty, values',
  'may exceed size limits, or the document may have extra keys.',
  'A temple with this name already exists.',
  'Write failed ().',
  'Exception: ',
  'A temple named "" already exists.',
  'Name must include letters or numbers.',
  'Temple id is missing.',
  'No image URLs to save.',
  'Temple "imageUrl" must be a string.',
  'Temple "" must be a list.',
  'Temple "photos" must be a list.',
  'Temple photo  must be a map.',
  'Firebase.apps',
  'FirebaseFirestore.instance',
  'DirectoryLoadException',
  'EEA',
  'US',
  'REGULATED_US_STATE',
  'OTHER',
  'UMP_DEBUG_GEOGRAPHY',
  'UMP_TEST_DEVICE_ID',
  'UMP consent form: :',
  'UMP consent form timed out; continuing with non-personalized ads:',
  'UMP debug geography= testDevice=',
  'AdHelper should not be used on web',
  'UMP consent info update failed ():',
};

/// Catalogue and ranking data, not chrome.
const _dataFiles = {
  'lib/utils/deity_synonyms.dart',
  'lib/utils/temple_search.dart',
};

Iterable<String> _visibleLiterals(File file) sync* {
  final path = file.path.replaceAll('\\', '/');
  if (_dataFiles.any(path.endsWith)) return;
  final source = file.readAsStringSync().replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  final lines = source.split('\n');
  var skipDepth = 0;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (skipDepth > 0) {
      skipDepth += _parenDelta(line);
      continue;
    }
    if (line.contains('l10n-allow')) continue;
    final code = _withoutLineComment(line);
    if (_skipLine.hasMatch(code)) {
      if (code.contains('debugPrint(')) {
        skipDepth = _parenDelta(code);
      }
      continue;
    }
    for (final raw in _stringBodies(code)) {
      final body = _plain(raw).trim();
      if (!_isUserVisible(path, body)) continue;
      if (_serviceLiterals.contains(body)) continue;
      yield '$path:${index + 1}: $body';
    }
  }
}

bool _isUserVisible(String path, String body) {
  if (!RegExp(r'[A-Za-z]').hasMatch(body)) return false;
  if (body.contains(r'\') || body.startsWith('^') || body.startsWith('|')) {
    return false;
  }
  if (RegExp(r'^[a-z]+$').hasMatch(body)) {
    final inUiTree =
        path.contains('/screens/') ||
        path.contains('/widgets/') ||
        path.contains('/near_me/');
    final allowed = inUiTree ? _uiTreeWords : _libraryWords;
    return !allowed.contains(body);
  }
  // Corpus needles and cache headers are lowercase phrases, not chrome.
  if (body.toLowerCase() == body) return false;
  return body.contains(' ') || RegExp(r'^[A-Z]').hasMatch(body);
}

String _plain(String raw) {
  return raw
      .replaceAll(RegExp(r'\$\{[^{}]*\}'), '')
      .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '');
}

String _withoutLineComment(String line) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < line.length) {
    final quote = line[i];
    if (quote == "'" || quote == '"') {
      final read = _takeString(line, i, quote);
      if (read == null) {
        buffer.write(line.substring(i));
        break;
      }
      buffer.write(line.substring(i, read.end));
      i = read.end;
      continue;
    }
    if (quote == '/' && i + 1 < line.length && line[i + 1] == '/') break;
    buffer.write(quote);
    i++;
  }
  return buffer.toString();
}

int _parenDelta(String line) {
  final code = _withoutLineComment(line);
  return '('.allMatches(code).length - ')'.allMatches(code).length;
}

List<String> _stringBodies(String code) {
  final bodies = <String>[];
  var i = 0;
  while (i < code.length) {
    final quote = code[i];
    if (quote != "'" && quote != '"') {
      i++;
      continue;
    }
    final read = _takeString(code, i, quote);
    if (read == null) break;
    bodies.add(read.body);
    i = read.end;
  }
  return bodies;
}

({String body, int end})? _takeString(String code, int start, String quote) {
  final buffer = StringBuffer();
  var i = start + 1;
  while (i < code.length) {
    final char = code[i];
    if (char == r'\') {
      if (i + 1 >= code.length) return null;
      buffer
        ..write(char)
        ..write(code[i + 1]);
      i += 2;
      continue;
    }
    if (char == r'$' && i + 1 < code.length) {
      final next = code[i + 1];
      if (next == '{') {
        final end = _skipInterpolation(code, i + 1);
        buffer.write(code.substring(i, end));
        i = end;
        continue;
      }
      if (RegExp(r'[A-Za-z_]').hasMatch(next)) {
        var j = i + 2;
        while (j < code.length && RegExp(r'[A-Za-z0-9_]').hasMatch(code[j])) {
          j++;
        }
        buffer.write(code.substring(i, j));
        i = j;
        continue;
      }
    }
    if (char == quote) return (body: buffer.toString(), end: i + 1);
    buffer.write(char);
    i++;
  }
  return null;
}

int _skipInterpolation(String code, int brace) {
  var depth = 0;
  var i = brace;
  while (i < code.length) {
    final char = code[i];
    if (char == "'" || char == '"') {
      final read = _takeString(code, i, char);
      if (read == null) return code.length;
      i = read.end;
      continue;
    }
    if (char == '{') depth++;
    if (char == '}') {
      depth--;
      i++;
      if (depth == 0) return i;
      continue;
    }
    i++;
  }
  return code.length;
}
