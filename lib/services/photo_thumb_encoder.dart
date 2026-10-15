import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:temple_app/services/temple_photo_upload.dart';

// The source extension is unused: every stored photo and thumb is JPEG.
// The parameter stays so callers can pass the picked filename.

/// Builds the JPEG bytes stored for a temple photo.
///
/// [encodeFull] is the public full-size object. [encode] is the `_480` thumb.
/// Both are a fresh JPEG. GPS and other EXIF from the picked file are not
/// copied.
abstract class TemplePhotoThumbEncoder {
  Future<Uint8List> encode({
    required Uint8List bytes,
    required String extension,
  });

  Future<Uint8List> encodeFull({
    required Uint8List bytes,
    required String extension,
  });
}

/// Decodes with the Flutter codec and encodes JPEG at [quality].
///
/// The codec raster has no EXIF. The platform encoder is called with
/// `keepExif: false`, so a GPS tag on the picked file is not in the bytes
/// that are uploaded. No image library is bundled in the APK.
class FlutterTemplePhotoThumbEncoder implements TemplePhotoThumbEncoder {
  const FlutterTemplePhotoThumbEncoder();

  @override
  Future<Uint8List> encode({
    required Uint8List bytes,
    required String extension,
  }) {
    return encodePublicJpeg(
      bytes,
      maxEdge: kTemplePhotoThumbEdge,
      quality: kTemplePhotoThumbQuality,
    );
  }

  @override
  Future<Uint8List> encodeFull({
    required Uint8List bytes,
    required String extension,
  }) {
    return encodePublicJpeg(
      bytes,
      maxEdge: kTemplePhotoMaxEdge.round(),
      quality: kTemplePhotoJpegQuality,
      capLongEdge: true,
    );
  }
}

/// Rasterize [bytes], then JPEG-encode. Tests pass [jpeg] so a GPS fixture
/// can be checked without the platform encoder. Production uses
/// [FlutterImageCompress] with `keepExif: false`.
Future<Uint8List> encodePublicJpeg(
  Uint8List bytes, {
  required int maxEdge,
  required int quality,
  bool capLongEdge = false,
  Future<Uint8List> Function(Uint8List png, int width, int height, int quality)?
  jpeg,
}) async {
  final scaled = await rasterWithoutMetadata(
    bytes,
    maxEdge: maxEdge,
    capLongEdge: capLongEdge,
  );
  final encode = jpeg ?? _compressJpeg;
  final encoded = await encode(
    scaled.png,
    scaled.width,
    scaled.height,
    quality,
  );
  if (encoded.isEmpty) {
    throw StateError('Could not encode the photo.');
  }
  return encoded;
}

Future<Uint8List> _compressJpeg(
  Uint8List png,
  int width,
  int height,
  int quality,
) {
  return FlutterImageCompress.compressWithList(
    png,
    minWidth: width,
    minHeight: height,
    quality: quality,
    format: CompressFormat.jpeg,
    keepExif: false,
  );
}

/// PNG raster of [bytes] at [maxEdge]. The PNG is a new image, so EXIF on
/// the source, including GPS, is not in the result.
///
/// When [capLongEdge] is false, only the width is capped (list thumbs).
/// When it is true, the longer side is capped (the public full-size photo).
/// Frames already inside the cap are not enlarged.
Future<({Uint8List png, int width, int height})> rasterWithoutMetadata(
  Uint8List bytes, {
  required int maxEdge,
  bool capLongEdge = false,
}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final probed = await probe.getNextFrame();
  final sourceWidth = probed.image.width;
  final sourceHeight = probed.image.height;
  probed.image.dispose();
  probe.dispose();
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    throw StateError('Could not read the photo.');
  }
  final target = _targetWidth(
    sourceWidth,
    sourceHeight,
    maxEdge: maxEdge,
    capLongEdge: capLongEdge,
  );
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: target);
  final frame = await codec.getNextFrame();
  try {
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Could not resize the photo.');
    }
    return (
      png: data.buffer.asUint8List(),
      width: frame.image.width,
      height: frame.image.height,
    );
  } finally {
    frame.image.dispose();
    codec.dispose();
  }
}

int? _targetWidth(
  int sourceWidth,
  int sourceHeight, {
  required int maxEdge,
  required bool capLongEdge,
}) {
  if (!capLongEdge) {
    return sourceWidth > maxEdge ? maxEdge : null;
  }
  final long = sourceWidth > sourceHeight ? sourceWidth : sourceHeight;
  if (long <= maxEdge) return null;
  if (sourceWidth >= sourceHeight) return maxEdge;
  final width = (sourceWidth * maxEdge / sourceHeight).round();
  if (width < 1) return 1;
  if (width > maxEdge) return maxEdge;
  return width;
}
