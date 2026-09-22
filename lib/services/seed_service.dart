import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/utils/detail_honesty.dart';

/// Stable Firestore document ID for a temple name.
///
/// Lowercased, non-alphanumeric runs collapsed to hyphens, leading/trailing
/// hyphens stripped. Re-seeding the same name always targets the same doc,
/// so the write is idempotent instead of creating duplicate documents.
String templeDocumentId(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// Cover + gallery fields for Seed writes.
///
/// Drops picsum / placeholder hosts so Seed never stores stock URLs as
/// photographs. Verified admin uploads in [existingImages] are kept; a
/// verified [existingImageUrl] is kept when the bundled cover is a placeholder.
Map<String, Object> seedHonestyImageFields({
  required String bundledImageUrl,
  String? existingImageUrl,
  List<String> existingImages = const [],
}) {
  final bundled = bundledImageUrl.trim();
  final existingCover = (existingImageUrl ?? '').trim();

  final verifiedImages = [
    for (final raw in existingImages)
      if (!isPlaceholderImageUrl(raw)) raw.trim(),
  ];

  final String imageUrl;
  if (!isPlaceholderImageUrl(bundled)) {
    imageUrl = bundled;
  } else if (!isPlaceholderImageUrl(existingCover)) {
    imageUrl = existingCover;
  } else {
    imageUrl = '';
  }

  final images = verifiedImages.isNotEmpty
      ? verifiedImages
      : (imageUrl.isNotEmpty ? <String>[imageUrl] : <String>[]);

  return {'imageUrl': imageUrl, 'images': images};
}

/// Parses a Firestore `images` field into trimmed URL strings.
List<String> templeSeedImagesFromFirestore(Object? value) {
  if (value is! Iterable) return const [];
  return [
    for (final item in value)
      if (item != null && item.toString().trim().isNotEmpty)
        item.toString().trim(),
  ];
}

/// Outcome of [seedTempleData].
class SeedResult {
  const SeedResult({
    required this.writtenCount,
    required this.createdCount,
    required this.updatedCount,
  });

  /// Total sample temples written in this run.
  final int writtenCount;

  /// Documents that did not already exist.
  final int createdCount;

  /// Documents that already existed and were merged.
  final int updatedCount;

  String get successMessage {
    if (createdCount > 0 && updatedCount > 0) {
      return 'Seeded $writtenCount temples '
          '($createdCount new, $updatedCount updated).';
    }
    if (updatedCount > 0) {
      return 'Updated $updatedCount existing sample temples. No duplicates created.';
    }
    return 'Seeded $createdCount temples into Firestore.';
  }
}

/// Uploads all temples from [sampleTemples] to the Firestore `temples`
/// collection.
///
/// **Idempotency:** each document ID is a slug of the temple name
/// ([templeDocumentId]), so re-running overwrites/merges the same docs
/// instead of inserting duplicates. Existing verified `images` arrays and
/// `createdAt` timestamps are preserved so admin photo uploads are not
/// wiped; placeholder hosts (picsum, etc.) are stripped from cover/gallery
/// on every run. Other bundled fields (name, story, timings, …) are
/// refreshed from sample data.
///
/// Debug-only: calling this from a release/profile build throws.
/// Also requires a signed-in Firebase user with custom claim `admin: true`
/// (rules reject the write otherwise). Pass [isAdmin] in tests.
Future<SeedResult> seedTempleData({
  FirebaseFirestore? firestore,
  Future<bool> Function()? isAdmin,
}) async {
  if (!kDebugMode) {
    throw StateError('Temple seeding is only available in debug builds.');
  }

  final allowed =
      await (isAdmin ?? AdminAuth.instance.isCurrentUserAdmin)();
  if (!allowed) {
    throw StateError(
      'Seeding requires a signed-in admin (custom claim admin: true).',
    );
  }

  final db = firestore ?? FirebaseFirestore.instance;
  final collection = db.collection('temples');
  final existingSnap = await collection.get();
  final existing = {
    for (final doc in existingSnap.docs) doc.id: doc.data(),
  };

  final batch = db.batch();
  var created = 0;
  var updated = 0;

  for (final temple in sampleTemples) {
    final docId = templeDocumentId(temple.name);
    final docRef = collection.doc(docId);
    final already = existing[docId];
    final isNew = already == null;
    if (isNew) {
      created++;
    } else {
      updated++;
    }

    final data = temple.toFirestoreData(
      documentId: docId,
      includeImages: false,
    );

    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    final honesty = seedHonestyImageFields(
      bundledImageUrl: temple.imageUrl,
      existingImageUrl: already == null
          ? null
          : already['imageUrl'] as String?,
      existingImages: already == null
          ? const <String>[]
          : templeSeedImagesFromFirestore(already['images']),
    );
    data['imageUrl'] = honesty['imageUrl'];
    data['images'] = honesty['images'];

    batch.set(docRef, data, SetOptions(merge: true));
  }

  await batch.commit();
  return SeedResult(
    writtenCount: created + updated,
    createdCount: created,
    updatedCount: updated,
  );
}
