import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/config/policy_config.dart';

/// Local record that the Terms and Privacy documents were accepted.
class PolicyAcceptance {
  const PolicyAcceptance({required this.version, required this.acceptedAt});

  /// [PolicyConfig.currentVersion] at the time of acceptance.
  final int version;

  /// When the user tapped Accept, stored in UTC.
  final DateTime acceptedAt;
}

/// Which gate to show, if any.
///
/// [firstLaunch] is frame A (nothing stored yet). [policyUpdate] is frame C
/// (a stored version is older than the current constant).
enum PolicyGateKind { firstLaunch, policyUpdate }

/// `null` when [stored] already covers [currentVersion].
///
/// The gate returns only when the current constant is greater than the stored
/// version, or when nothing valid is stored.
PolicyGateKind? policyGateKind({
  required PolicyAcceptance? stored,
  required int currentVersion,
}) {
  if (stored == null) return PolicyGateKind.firstLaunch;
  if (currentVersion > stored.version) return PolicyGateKind.policyUpdate;
  return null;
}

/// Device-local acceptance. Implementations must not talk to Firestore.
abstract class PolicyAcceptanceStore {
  Future<PolicyAcceptance?> read();

  Future<void> write(PolicyAcceptance acceptance);
}

/// Keys kept stable so a later release can still read an older acceptance.
abstract final class PolicyAcceptanceKeys {
  static const String version = 'tos_accepted_version';
  static const String acceptedAt = 'tos_accepted_at';
}

/// Shared-preferences backing store for [PolicyAcceptanceStore].
class SharedPreferencesPolicyAcceptanceStore implements PolicyAcceptanceStore {
  SharedPreferencesPolicyAcceptanceStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<PolicyAcceptance?> read() async {
    final prefs = await _preferences();
    return policyAcceptanceFromValues(
      version: prefs.getInt(PolicyAcceptanceKeys.version),
      acceptedAt: prefs.getString(PolicyAcceptanceKeys.acceptedAt),
    );
  }

  @override
  Future<void> write(PolicyAcceptance acceptance) async {
    final prefs = await _preferences();
    final savedVersion = await prefs.setInt(
      PolicyAcceptanceKeys.version,
      acceptance.version,
    );
    final savedTime = await prefs.setString(
      PolicyAcceptanceKeys.acceptedAt,
      acceptance.acceptedAt.toUtc().toIso8601String(),
    );
    if (!savedVersion || !savedTime) {
      throw StateError('Could not store Terms acceptance on this device.');
    }
  }
}

/// Parses stored values. A missing or unreadable field is treated as no
/// acceptance so the gate is shown again.
PolicyAcceptance? policyAcceptanceFromValues({
  required int? version,
  required String? acceptedAt,
}) {
  if (version == null || acceptedAt == null || acceptedAt.isEmpty) return null;
  final parsed = DateTime.tryParse(acceptedAt);
  if (parsed == null) return null;
  return PolicyAcceptance(version: version, acceptedAt: parsed.toUtc());
}
