import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';

class TempleService {
  TempleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetches temples from the `temples` Firestore collection.
  /// Falls back to [sampleTemples] if the collection is empty or on error.
  Future<List<Temple>> getTemples() async {
    try {
      final snapshot = await _firestore.collection('temples').get();

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
