import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:temple_app/services/temple_photo_upload.dart';

// The source extension is unused: every thumb is JPEG. The parameter stays
// so callers can pass the picked filename without a second API.

/// Builds the `{timestamp}_480` bytes uploaded next to a temple photo.
abstract class TemplePhotoThumbEncoder {
  Future<Uint8List> encode({
    required Uint8List bytes,
    required String extension,
  });
}

/// Scales to [kTemplePhotoThumbEdge] wide with the Flutter codec, then
/// encodes JPEG with the platform encoder at [kTemplePhotoThumbQuality].
/// PNG and WebP originals become JPEG thumbs. No image library is bundled
/// in the APK. Frames already at or under that width are not enlarged.
class FlutterTemplePhotoThumbEncoder implements TemplePhotoThumbEncoder {
  const FlutterTemplePhotoThumbEncoder();

  @override
  Future<Uint8List> encode({
    required Uint8List bytes,
    required String extension,
  }) async {
    final scaled = await _scaleToThumbWidth(bytes);
    final encoded = await FlutterImageCompress.compressWithList(
      scaled.png,
      minWidth: scaled.width,
      minHeight: scaled.height,
      quality: kTemplePhotoThumbQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (encoded.isEmpty) {
      throw StateError('Could not encode the photo thumbnail.');
    }
    return encoded;
  }
}

class _ScaledPng {
  const _ScaledPng({
    required this.png,
    required this.width,
    required this.height,
  });

  final Uint8List png;
  final int width;
  final int height;
}

Future<_ScaledPng> _scaleToThumbWidth(Uint8List bytes) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final probed = await probe.getNextFrame();
  final sourceWidth = probed.image.width;
  final sourceHeight = probed.image.height;
  probed.image.dispose();
  probe.dispose();
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    throw StateError('Could not read the photo.');
  }
  final target = sourceWidth > kTemplePhotoThumbEdge
      ? kTemplePhotoThumbEdge
      : null;
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: target);
  final frame = await codec.getNextFrame();
  try {
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Could not resize the photo.');
    }
    return _ScaledPng(
      png: data.buffer.asUint8List(),
      width: frame.image.width,
      height: frame.image.height,
    );
  } finally {
    frame.image.dispose();
    codec.dispose();
  }
}
