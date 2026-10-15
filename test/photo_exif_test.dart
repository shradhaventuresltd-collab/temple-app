import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/photo_thumb_encoder.dart';
import 'package:temple_app/services/temple_photo_upload.dart';

/// 1x1 JPEG, with an APP1 Exif block inserted after the SOI marker.
///
/// The payload is the text a GPS-tagged photo carries. A re-encode must not
/// copy those bytes into the public full-size object.
Uint8List gpsTaggedJpeg() {
  // 1x1 baseline JPEG. APP1 is inserted after SOI so the fixture is a real
  // photo the Flutter codec can decode, with a GPS Exif block in front.
  const jpeg =
      'ffd8ffe100304578696600004750534c617469747564653d31332e303832373b4750534c6f6e6769747564653d38302e32373037ffe000104a46494600010200000100010000fffe00104c61766336302e33312e31303200ffdb0043000804040404040505050505050606060606060606060606060607070708080807070706060707080808080909090808080809090a0a0a0c0c0b0b0e0e0e111114ffc4004c0001010000000000000000000000000000000601010100000000000000000000000000000607100100000000000000000000000000000000110100000000000000000000000000000000ffc00011080008000803012200021100031100ffda000c03010002110311003f008b00517f7fffd9';
  return Uint8List.fromList([
    for (var i = 0; i < jpeg.length; i += 2)
      int.parse(jpeg.substring(i, i + 2), radix: 16),
  ]);
}

String _latin1(Uint8List bytes) => latin1.decode(bytes, allowInvalid: true);

void main() {
  test('a GPS-tagged photo is re-encoded without EXIF', () async {
    final tagged = gpsTaggedJpeg();
    expect(_latin1(tagged), contains('GPSLatitude'));
    expect(_latin1(tagged), contains('GPSLongitude'));

    Uint8List? raster;
    final encoded = await encodePublicJpeg(
      tagged,
      maxEdge: kTemplePhotoMaxEdge.round(),
      quality: kTemplePhotoJpegQuality,
      capLongEdge: true,
      jpeg: (png, width, height, quality) async {
        raster = png;
        expect(quality, kTemplePhotoJpegQuality);
        expect(quality, inInclusiveRange(75, 80));
        expect(width, greaterThan(0));
        expect(height, greaterThan(0));
        return Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
      },
    );

    expect(raster, isNotNull);
    expect(_latin1(raster!), isNot(contains('GPSLatitude')));
    expect(_latin1(raster!), isNot(contains('GPSLongitude')));
    expect(_latin1(raster!), isNot(contains('Exif')));
    expect(_latin1(encoded), isNot(contains('GPSLatitude')));
    expect(_latin1(encoded), isNot(contains('GPSLongitude')));
  });
}
