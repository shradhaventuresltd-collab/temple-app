import 'package:firebase_core/firebase_core.dart';

/// True when a default Firebase app already exists.
///
/// A missing plugin or a core/no-app read is not ready. Callers then keep
/// running on cached or sample data instead of touching Auth or Firestore.
bool firebaseAppsReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
