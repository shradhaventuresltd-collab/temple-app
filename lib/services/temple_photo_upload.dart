import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/cover_thumb.dart';

/// Long edge of a photo before it is stored. The picker applies this.
const double kTemplePhotoMaxEdge = 1600;

/// JPEG/WebP quality for the stored photo and its `_480` thumb.
const int kTemplePhotoJpegQuality = 80;

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
    required this.cacheControl,
  });

  final String mainPath;
  final String thumbPath;
  final String contentType;

  /// Timestamped names never change (KAN-49). The thumb uses the same header.
  final String cacheControl;
}

/// `temples/{docId}/{timestamp}.{ext}` and `temples/{docId}/{timestamp}_480.{ext}`.
TemplePhotoUploadPlan planTemplePhotoUpload({
  required String docId,
  required int timestamp,
  required String extension,
}) {
  final stored = templePhotoStoredExtension(extension);
  final mainPath = templePhotoStoragePath(
    docId: docId,
    timestamp: timestamp,
    extension: stored,
  );
  final thumbPath = thumbObjectPath(mainPath);
  if (thumbPath == null) {
    throw StateError('Photo path "$mainPath" has no _480 thumbnail.');
  }
  return TemplePhotoUploadPlan(
    mainPath: mainPath,
    thumbPath: thumbPath,
    contentType: contentTypeForPhotoExtension(stored),
    cacheControl: 'public, max-age=31536000, immutable',
  );
}

/// Writes one Storage object and returns its download URL.
abstract class TemplePhotoObjectWriter {
  Future<String> put({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String cacheControl,
    required void Function(double progress) onProgress,
  });
}

/// Uploads one temple photo and its thumb, and returns the full-size URL.
abstract class TemplePhotoUploader {
  Future<String> upload({
    required String docId,
    required Uint8List bytes,
    required Uint8List thumbBytes,
    required String extension,
    required void Function(double progress) onProgress,
  });
}

/// Writes both objects with one timestamp. The full-size download URL is
/// what `photos[].url` stores. Browse derives `{name}_480` from that URL.
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
  Future<String> upload({
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
    final plan = planTemplePhotoUpload(
      docId: docId,
      timestamp: timestamp,
      extension: extension,
    );
    final mainUrl = await _objects.put(
      path: plan.mainPath,
      bytes: bytes,
      contentType: plan.contentType,
      cacheControl: plan.cacheControl,
      onProgress: (value) => onProgress((value * 0.5).clamp(0, 0.5)),
    );
    await _objects.put(
      path: plan.thumbPath,
      bytes: thumbBytes,
      contentType: plan.contentType,
      cacheControl: plan.cacheControl,
      onProgress: (value) => onProgress((0.5 + value * 0.5).clamp(0.5, 1)),
    );
    onProgress(1);
    return mainUrl;
  }
}

class FirebaseTemplePhotoObjectWriter implements TemplePhotoObjectWriter {
  FirebaseTemplePhotoObjectWriter({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> put({
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
      return await ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
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
