import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';

class TempleService {
  TempleService({
    FirebaseFirestore? firestore,
    this.fetchTimeout = const Duration(seconds: 12),
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Duration fetchTimeout;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Fetches temples from the `temples` Firestore collection.
  /// Falls back to [sampleTemples] if the collection is empty, times out,
  /// or errors (including Firebase not initialized).
  Future<List<Temple>> getTemples() async {
    try {
      final snapshot =
          await _db.collection('temples').get().timeout(fetchTimeout);

      if (snapshot.docs.isEmpty) {
        return sampleTemples;
      }

      return snapshot.docs
          .map((doc) => Temple.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return sampleTemples;
    }
  }
}
