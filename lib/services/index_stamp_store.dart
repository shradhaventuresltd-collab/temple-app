import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stamp this device last applied for each `temple_index` shard.
///
/// Values are the server meta `updatedAt` in milliseconds. A shard is fetched
/// again when the server stamp differs. The Firestore cache meta is not the
/// source of this decision.
///
/// Web launches are always cold. The web Firestore cache lives in memory, so
/// a new page load has no shard documents even when these stamps are still
/// stored. The cache read misses and each shard is read from the server.
abstract class IndexStampStore {
  Future<Map<String, int>> readApplied();

  Future<void> writeApplied(String slug, int millis);
}

/// Shared-preferences key for [SharedPreferencesIndexStampStore].
abstract final class IndexStampKeys {
  static const String applied = 'temple_index_applied_stamps';
}

/// Device-local applied stamps. A read or write failure leaves the launch
/// on the server path instead of throwing.
class SharedPreferencesIndexStampStore implements IndexStampStore {
  SharedPreferencesIndexStampStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<Map<String, int>> readApplied() async {
    try {
      final prefs = await _preferences();
      return decodeAppliedStamps(prefs.getString(IndexStampKeys.applied));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> writeApplied(String slug, int millis) async {
    try {
      final prefs = await _preferences();
      final current = decodeAppliedStamps(prefs.getString(IndexStampKeys.applied));
      current[slug] = millis;
      await prefs.setString(IndexStampKeys.applied, jsonEncode(current));
    } catch (_) {}
  }
}

/// Parses the stored JSON object. Unknown shapes become an empty map.
Map<String, int> decodeAppliedStamps(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return {};
  final stamps = <String, int>{};
  for (final entry in decoded.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String) continue;
    if (value is int) {
      stamps[key] = value;
    } else if (value is num) {
      stamps[key] = value.toInt();
    }
  }
  return stamps;
}
