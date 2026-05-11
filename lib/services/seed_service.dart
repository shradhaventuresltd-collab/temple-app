import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/data/sample_data.dart';

/// Uploads all temples from [sampleTemples] to the Firestore `temples`
/// collection. Each document uses a slug of the temple name as its ID
/// so re-running is idempotent (overwrites rather than duplicates).
Future<void> seedTempleData({
  FirebaseFirestore? firestore,
}) async {
  final db = firestore ?? FirebaseFirestore.instance;
  final batch = db.batch();
  final collection = db.collection('temples');

  for (final temple in sampleTemples) {
    final docId = temple.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final docRef = collection.doc(docId);

    batch.set(docRef, {
      'id': docId,
      'name': temple.name,
      'state': temple.state,
      'city': temple.city,
      'deity': temple.deity,
      'description': temple.description,
      'story': temple.story,
      'imageUrl': temple.imageUrl,
      'address': temple.location,
      'latitude': temple.latitude,
      'longitude': temple.longitude,
      'timings': temple.timings,
      'specialities': temple.specialities,
      'images': [temple.imageUrl],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}
