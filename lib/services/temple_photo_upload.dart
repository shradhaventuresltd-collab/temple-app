import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:temple_app/models/temple_photo.dart';

/// Uploads one temple photo and returns its download URL.
abstract class TemplePhotoUploader {
  Future<String> upload({
    required String docId,
    required Uint8List bytes,
    required String extension,
    required void Function(double progress) onProgress,
  });
}

/// Writes `temples/{docId}/{timestamp}.{ext}` in Cloud Storage.
class FirebaseTemplePhotoUploader implements TemplePhotoUploader {
  FirebaseTemplePhotoUploader({FirebaseStorage? storage, this.clock})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Microsecond timestamp. Tests can pin it.
  final int Function()? clock;

  @override
  Future<String> upload({
    required String docId,
    required Uint8List bytes,
    required String extension,
    required void Function(double progress) onProgress,
  }) async {
    final timestamp = clock?.call() ?? DateTime.now().microsecondsSinceEpoch;
    final path = templePhotoStoragePath(
      docId: docId,
      timestamp: timestamp,
      extension: extension,
    );
    final ref = _storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentTypeForPhotoExtension(extension),
        // Timestamped names never change (KAN-49).
        cacheControl: 'public, max-age=31536000, immutable',
      ),
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
