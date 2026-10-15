import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/cover_thumb.dart';

/// Long edge of a photo before it is stored. The picker applies this.
const double kTemplePhotoMaxEdge = 1600;

/// JPEG quality for the stored photo. The picker applies this.
const int kTemplePhotoJpegQuality = 80;

/// JPEG quality for the `_480` thumb. Within the 75–80 range.
const int kTemplePhotoThumbQuality = 80;

/// Width of the list-card thumb. Taller frames keep their aspect ratio.
const int kTemplePhotoThumbEdge = 480;

/// Arguments for [ImagePicker.pickMultiImage]. The admin form passes these
/// through so a test can see the resize without opening the picker.
///
/// Both edges are [kTemplePhotoMaxEdge]. The picker fits the frame inside
/// that box, so a portrait photo cannot stay taller than the long-edge cap.
({int limit, double maxWidth, double maxHeight, int imageQuality})
templePhotoPickArguments({required int limit}) {
  return (
    limit: limit,
    maxWidth: kTemplePhotoMaxEdge,
    maxHeight: kTemplePhotoMaxEdge,
    imageQuality: kTemplePhotoJpegQuality,
  );
}

/// Extension stored for a picked file. Unknown types are stored as JPEG,
/// which is what the picker produces when [kTemplePhotoJpegQuality] is set.
String templePhotoStoredExtension(String extension) {
  final ext = extension.trim().toLowerCase().replaceAll(RegExp(r'^\.'), '');
  if (ext == 'png' || ext == 'webp' || ext == 'jpg' || ext == 'jpeg') {
    return ext;
  }
  return 'jpg';
}

/// Paths and metadata for one admin photo and its `_480` sibling.
class TemplePhotoUploadPlan {
  const TemplePhotoUploadPlan({
    required this.mainPath,
    required this.thumbPath,
    required this.contentType,
    required this.thumbContentType,
    required this.cacheControl,
  });

  final String mainPath;
  final String thumbPath;
  final String contentType;

  /// Thumbs are JPEG, including when the original is PNG or WebP.
  final String thumbContentType;

  /// Timestamped names never change (KAN-49). The thumb uses the same header.
  /// Its object name includes the source generation, so a replaced original
  /// does not reuse this immutable URL.
  final String cacheControl;
}

/// `temples/{docId}/{timestamp}.{ext}` and
/// `temples/{docId}/{timestamp}_480_g{generation}.jpg`.
TemplePhotoUploadPlan planTemplePhotoUpload({
  required String docId,
  required int timestamp,
  required String extension,
  required String generation,
  int? updatedMillis,
}) {
  final stored = templePhotoStoredExtension(extension);
  final mainPath = templePhotoStoragePath(
    docId: docId,
    timestamp: timestamp,
    extension: stored,
  );
  final thumbPath = thumbObjectPath(
    mainPath,
    generation: generation,
    updatedMillis: updatedMillis,
  );
  if (thumbPath == null) {
    throw StateError('Photo path "$mainPath" has no _480 thumbnail.');
  }
  return TemplePhotoUploadPlan(
    mainPath: mainPath,
    thumbPath: thumbPath,
    contentType: contentTypeForPhotoExtension(stored),
    thumbContentType: 'image/jpeg',
    cacheControl: 'public, max-age=31536000, immutable',
  );
}

/// Download URLs for the full photo and its thumb.
class TemplePhotoUpload {
  const TemplePhotoUpload({required this.url, required this.thumbUrl});

  /// Stored as `photos[].url`.
  final String url;

  /// Stored as `photos[].thumbUrl`. This is the thumb's own download URL.
  final String thumbUrl;
}

/// One stored object. [generation] is the Storage generation string.
class TemplePhotoStoredObject {
  const TemplePhotoStoredObject({
    required this.path,
    required this.url,
    required this.generation,
  });

  final String path;
  final String url;
  final String generation;
}

/// Writes one Storage object and returns its download URL and generation.
abstract class TemplePhotoObjectWriter {
  Future<TemplePhotoStoredObject> put({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String cacheControl,
    required void Function(double progress) onProgress,
  });

  /// Removes an object left behind when the other half of the upload fails.
  Future<void> delete({required String path});
}

/// Uploads one temple photo and its thumb.
abstract class TemplePhotoUploader {
  Future<TemplePhotoUpload> upload({
    required String docId,
    required Uint8List bytes,
    required Uint8List thumbBytes,
    required String extension,
    required void Function(double progress) onProgress,
  });
}

/// Writes the original, then the thumb named with that object's generation.
///
/// The original is deleted if the thumb upload fails, so a full-size object
/// is not left without its `photos[].thumbUrl`. Both download URLs are the
/// ones Storage returns. Thumbs sit under `temples/{id}/`, the same public
/// read as the original.
class FirebaseTemplePhotoUploader implements TemplePhotoUploader {
  FirebaseTemplePhotoUploader({
    TemplePhotoObjectWriter? objects,
    FirebaseStorage? storage,
    this.clock,
  }) : _objects = objects ?? FirebaseTemplePhotoObjectWriter(storage: storage);

  final TemplePhotoObjectWriter _objects;

  /// Microsecond timestamp. Tests can pin it.
  final int Function()? clock;

  @override
  Future<TemplePhotoUpload> upload({
    required String docId,
    required Uint8List bytes,
    required Uint8List thumbBytes,
    required String extension,
    required void Function(double progress) onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Photo file is empty.');
    }
    if (thumbBytes.isEmpty) {
      throw StateError('Photo thumbnail is empty.');
    }
    final timestamp = clock?.call() ?? DateTime.now().microsecondsSinceEpoch;
    final stored = templePhotoStoredExtension(extension);
    final mainPath = templePhotoStoragePath(
      docId: docId,
      timestamp: timestamp,
      extension: stored,
    );
    final cacheControl = 'public, max-age=31536000, immutable';
    final main = await _objects.put(
      path: mainPath,
      bytes: bytes,
      contentType: contentTypeForPhotoExtension(stored),
      cacheControl: cacheControl,
      onProgress: (value) => onProgress((value * 0.5).clamp(0, 0.5)),
    );
    final plan = planTemplePhotoUpload(
      docId: docId,
      timestamp: timestamp,
      extension: extension,
      generation: main.generation,
    );
    try {
      final thumb = await _objects.put(
        path: plan.thumbPath,
        bytes: thumbBytes,
        contentType: plan.thumbContentType,
        cacheControl: plan.cacheControl,
        onProgress: (value) => onProgress((0.5 + value * 0.5).clamp(0.5, 1)),
      );
      onProgress(1);
      return TemplePhotoUpload(url: main.url, thumbUrl: thumb.url);
    } catch (error) {
      try {
        await _objects.delete(path: main.path);
      } catch (_) {
        // The thumb failed. Surface that error even if cleanup also fails.
      }
      throw StateError('Photo thumbnail upload failed. $error');
    }
  }
}

class FirebaseTemplePhotoObjectWriter implements TemplePhotoObjectWriter {
  FirebaseTemplePhotoObjectWriter({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<TemplePhotoStoredObject> put({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String cacheControl,
    required void Function(double progress) onProgress,
  }) async {
    final ref = _storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType, cacheControl: cacheControl),
    );
    final subscription = task.snapshotEvents.listen((event) {
      final total = event.totalBytes;
      if (total <= 0) {
        onProgress(0);
        return;
      }
      onProgress((event.bytesTransferred / total).clamp(0, 1).toDouble());
    });
    try {
      await task;
      onProgress(1);
      final meta = await ref.getMetadata();
      final generation = meta.generation;
      if (generation == null || !RegExp(r'^\d+$').hasMatch(generation)) {
        throw StateError('Storage did not return a generation for $path.');
      }
      return TemplePhotoStoredObject(
        path: path,
        url: await ref.getDownloadURL(),
        generation: generation,
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> delete({required String path}) {
    return _storage.ref(path).delete();
  }
}

String contentTypeForPhotoExtension(String extension) {
  switch (extension.toLowerCase().replaceAll(RegExp(r'^\.'), '')) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'image/jpeg';
  }
}

/// File extension from a picker filename. Falls back to `jpg`.
String photoExtensionFromName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return 'jpg';
  final ext = name.substring(dot + 1).toLowerCase();
  if (!RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext)) return 'jpg';
  return ext;
}
