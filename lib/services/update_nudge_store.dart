import 'package:shared_preferences/shared_preferences.dart';

/// Day the soft update nudge was last shown, as `yyyy-mm-dd` UTC.
abstract class UpdateNudgeStore {
  Future<String?> readShownDay();

  Future<void> writeShownDay(String day);
}

abstract final class UpdateNudgeKeys {
  static const String shownDay = 'soft_update_nudge_day';
}

class SharedPreferencesUpdateNudgeStore implements UpdateNudgeStore {
  SharedPreferencesUpdateNudgeStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<String?> readShownDay() async {
    final prefs = await _preferences();
    return prefs.getString(UpdateNudgeKeys.shownDay);
  }

  @override
  Future<void> writeShownDay(String day) async {
    final prefs = await _preferences();
    await prefs.setString(UpdateNudgeKeys.shownDay, day);
  }
}

/// In-memory store for tests.
class MemoryUpdateNudgeStore implements UpdateNudgeStore {
  String? day;

  @override
  Future<String?> readShownDay() async => day;

  @override
  Future<void> writeShownDay(String day) async {
    this.day = day;
  }
}
