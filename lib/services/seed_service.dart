import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/temple_write_store.dart';
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
/// photographs. Verified admin uploads in [existingImages] are kept. When
/// that gallery is non-empty, [imageUrl] is `images.first` so a later Seed
/// cannot point the cover at a different host than the gallery.
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

  final cover = images.isNotEmpty ? images.first : imageUrl;
  return {'imageUrl': cover, 'images': images};
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

/// KAN-77 layer on top of [seedHonestyImageFields].
///
/// Picsum is never written. A verified existing gallery is kept, and its
/// cover is that gallery's first URL. This adds the Research pack gallery
/// when the live gallery is empty or only placeholders, with `imageUrl` set
/// to `images.first`. A non-empty verified existing gallery is not replaced
/// by the pack.
Map<String, Object> seedImageFieldsWithPack({
  required String bundledImageUrl,
  List<String> bundledImages = const [],
  String? existingImageUrl,
  List<String> existingImages = const [],
}) {
  final honesty = seedHonestyImageFields(
    bundledImageUrl: bundledImageUrl,
    existingImageUrl: existingImageUrl,
    existingImages: existingImages,
  );

  final verifiedExisting = [
    for (final raw in existingImages)
      if (!isPlaceholderImageUrl(raw)) raw.trim(),
  ];
  if (verifiedExisting.isNotEmpty) return honesty;

  final pack = [
    for (final raw in bundledImages)
      if (!isPlaceholderImageUrl(raw)) raw.trim(),
  ];
  if (pack.isEmpty) return honesty;

  return {'imageUrl': pack.first, 'images': pack};
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

Future<Map<String, Map<String, dynamic>>> _existingTempleDocs(
  FirebaseFirestore db,
) async {
  final existingSnap = await db.collection('temples').get();
  return {for (final doc in existingSnap.docs) doc.id: doc.data()};
}

/// Uploads all temples from [sampleTemples] to the Firestore `temples`
/// collection.
///
/// **Idempotency:** each document ID is a slug of the temple name
/// ([templeDocumentId]), so re-running overwrites/merges the same docs
/// instead of inserting duplicates. Each temple is one
/// [FirebaseTempleWriteStore] commit (`_commitTemple`): the temple document,
/// `entries.{id}`, and the `meta/temple_index` bump. A state change removes
/// the old shard field in that same batch. Image fields go through
/// [seedHonestyImageFields]: picsum is never written, and a verified
/// existing gallery is kept so admin / Storage uploads are not wiped.
/// `imageUrl` is that gallery's first URL. [seedImageFieldsWithPack] fills
/// an empty gallery from verified sample `images` (Commons packs) only when
/// live has no verified URLs, again with `imageUrl` equal to `images.first`.
/// `createdAt` is preserved. Other bundled fields (name, story, timings, …) are
/// refreshed from sample data. Admin and Storage galleries are not replaced.
///
/// Throws when admin tools are off (release/profile without ENABLE_ADMIN_TOOLS).
/// Also requires a signed-in Firebase user with custom claim `admin: true`
/// (rules reject the write otherwise). Pass [isAdmin] in tests.
Future<SeedResult> seedTempleData({
  FirebaseFirestore? firestore,
  TempleWriteStore? store,
  Map<String, Map<String, dynamic>>? existingDocs,
  Future<bool> Function()? isAdmin,
}) async {
  if (!kAdminToolsEnabled) {
    throw StateError(
      'Temple seeding is only available in debug builds '
      '(or demo builds with ENABLE_ADMIN_TOOLS).',
    );
  }

  final allowed = await (isAdmin ?? AdminAuth.instance.isCurrentUserAdmin)();
  if (!allowed) {
    throw StateError(
      'Seeding requires a signed-in admin (custom claim admin: true).',
    );
  }

  final db = firestore ?? (store == null ? FirebaseFirestore.instance : null);
  final existing = existingDocs ?? await _existingTempleDocs(db!);
  final writer = store ?? FirebaseTempleWriteStore(firestore: db);

  var created = 0;
  var updated = 0;

  for (final temple in sampleTemples) {
    final docId = templeDocumentId(temple.name);
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

    final existingImages = already == null
        ? const <String>[]
        : templeSeedImagesFromFirestore(already['images']);
    final honesty = seedImageFieldsWithPack(
      bundledImageUrl: temple.imageUrl,
      bundledImages: temple.images,
      existingImageUrl: already == null ? null : already['imageUrl'] as String?,
      existingImages: existingImages,
    );
    data['imageUrl'] = honesty['imageUrl'];
    data['images'] = honesty['images'];

    // One _commitTemple batch per temple. Do not gather these into one
    // batch: a shard document can be written once per batch, and rules
    // allow only one entry key to change.
    await writer.set(
      docId,
      data,
      isNew: isNew,
      previous: already == null ? null : Map<String, dynamic>.from(already),
    );
  }

  return SeedResult(
    writtenCount: created + updated,
    createdCount: created,
    updatedCount: updated,
  );
}
