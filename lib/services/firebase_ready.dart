import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Test hook. Production leaves this null.
///
/// [site] is `Firebase.apps` for the init guard, or a product singleton
/// (`FirebaseFirestore.instance`, `FirebaseAuth.instance`) when that
/// singleton is about to be read.
@visibleForTesting
void Function(String site)? debugFirebaseAccessProbe;

/// Records [site] when a test installed [debugFirebaseAccessProbe].
void noteFirebaseAccess(String site) {
  final probe = debugFirebaseAccessProbe;
  if (probe != null) probe(site);
}

/// True when a default Firebase app already exists.
///
/// A missing plugin or a core/no-app read is not ready. Callers then keep
/// running on cached or sample data instead of touching Auth or Firestore.
bool firebaseAppsReady() {
  noteFirebaseAccess('Firebase.apps');
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
