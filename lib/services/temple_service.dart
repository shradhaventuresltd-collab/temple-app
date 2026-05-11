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

      return snapshot.docs.map((doc) {
        final d = doc.data();
        return Temple(
          id: doc.id,
          name: d['name'] as String? ?? '',
          state: d['state'] as String? ?? '',
          city: d['city'] as String? ?? '',
          deity: d['deity'] as String? ?? '',
          imageUrl: d['imageUrl'] as String? ?? '',
          description: d['description'] as String? ?? '',
          story: d['story'] as String? ?? '',
          location: d['address'] as String? ?? d['location'] as String? ?? '',
          timings: d['timings'] as String? ?? '',
          specialities: List<String>.from(d['specialities'] ?? []),
          images: List<String>.from(d['images'] ?? []),
          latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (_) {
      return sampleTemples;
    }
  }
}
