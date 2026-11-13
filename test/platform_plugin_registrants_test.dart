import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The committed desktop registrants match the resolved plugins, so a new
/// plugin (share_plus, in_app_review in PR 148) cannot leave them stale.
/// `.flutter-plugins-dependencies` is written by `flutter pub get`, which
/// `flutter test` runs first.
void main() {
  final deps = File('.flutter-plugins-dependencies');
  final plugins = deps.existsSync()
      ? (jsonDecode(deps.readAsStringSync()) as Map)['plugins'] as Map
      : const {};

  Set<String> native(String platform) => {
    for (final p in (plugins[platform] as List? ?? const []))
      if ((p as Map)['native_build'] == true && p['dev_dependency'] != true)
        p['name'] as String,
  };

  Set<String> cmakeList(String text) => {
    for (final m in RegExp(
      r'list\(APPEND FLUTTER_(?:FFI_)?PLUGIN_LIST([^)]*)\)',
    ).allMatches(text))
      ...m.group(1)!.split(RegExp(r'\s+')).where((s) => s.isNotEmpty),
  };

  for (final platform in ['linux', 'windows']) {
    test('$platform generated_plugins.cmake lists every native plugin', () {
      final listed = cmakeList(
        File('$platform/flutter/generated_plugins.cmake').readAsStringSync(),
      );
      expect(listed, native(platform));
    }, skip: !deps.existsSync());
  }

  test('linux needs no native share_plus / in_app_review entry', () {
    final listed = cmakeList(
      File('linux/flutter/generated_plugins.cmake').readAsStringSync(),
    );
    expect(listed, isNot(contains('share_plus')));
    expect(listed, isNot(contains('in_app_review')));
  }, skip: !deps.existsSync());

  test('macOS registrant imports every native plugin', () {
    final swift = File(
      'macos/Flutter/GeneratedPluginRegistrant.swift',
    ).readAsStringSync();
    for (final name in native('macos')) {
      expect(swift, contains('import $name'), reason: name);
    }
  }, skip: !deps.existsSync());
}
