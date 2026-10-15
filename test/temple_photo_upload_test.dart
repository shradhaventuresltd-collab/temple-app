import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/temple_photo_upload.dart';

class _Put {
  _Put({
    required this.path,
    required this.bytes,
    required this.contentType,
    required this.cacheControl,
  });

  final String path;
  final Uint8List bytes;
  final String contentType;
  final String cacheControl;
}

class _RecordingWriter implements TemplePhotoObjectWriter {
  final puts = <_Put>[];

  @override
  Future<String> put({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String cacheControl,
    required void Function(double progress) onProgress,
  }) async {
    puts.add(
      _Put(
        path: path,
        bytes: bytes,
        contentType: contentType,
        cacheControl: cacheControl,
      ),
    );
    onProgress(1);
    return 'https://storage.googleapis.com/bucket/$path';
  }
}

void main() {
  test('the picker resize is 1600px at quality 80', () {
    final args = templePhotoPickArguments(limit: 4);
    expect(args.limit, 4);
    expect(args.maxWidth, kTemplePhotoMaxEdge);
    expect(args.maxWidth, 1600);
    expect(args.maxHeight, kTemplePhotoMaxEdge);
    expect(args.maxHeight, 1600);
    expect(args.imageQuality, kTemplePhotoJpegQuality);
    expect(args.imageQuality, 80);
    expect(kTemplePhotoThumbEdge, 480);
  });

  test('upload writes the full object and the _480 thumb', () async {
    final writer = _RecordingWriter();
    final uploader = FirebaseTemplePhotoUploader(
      objects: writer,
      clock: () => 171000,
    );
    final progress = <double>[];
    final url = await uploader.upload(
      docId: 'shore-temple',
      bytes: Uint8List.fromList([1, 2, 3]),
      thumbBytes: Uint8List.fromList([4]),
      extension: 'jpeg',
      onProgress: progress.add,
    );

    expect(
      url,
      'https://storage.googleapis.com/bucket/temples/shore-temple/171000.jpeg',
    );
    expect(writer.puts.map((put) => put.path), [
      'temples/shore-temple/171000.jpeg',
      'temples/shore-temple/171000_480.jpeg',
    ]);
    for (final put in writer.puts) {
      expect(put.contentType, 'image/jpeg');
      expect(put.cacheControl, 'public, max-age=31536000, immutable');
    }
    expect(writer.puts[0].bytes, Uint8List.fromList([1, 2, 3]));
    expect(writer.puts[1].bytes, Uint8List.fromList([4]));
    expect(progress, contains(1));
  });

  test('an empty thumbnail is not uploaded', () async {
    final writer = _RecordingWriter();
    final uploader = FirebaseTemplePhotoUploader(
      objects: writer,
      clock: () => 171000,
    );
    expect(
      () => uploader.upload(
        docId: 'shore-temple',
        bytes: Uint8List.fromList([1]),
        thumbBytes: Uint8List(0),
        extension: 'jpg',
        onProgress: (_) {},
      ),
      throwsStateError,
    );
    expect(writer.puts, isEmpty);
  });

  test('png and unknown extensions keep a matching thumb name', () {
    final png = planTemplePhotoUpload(
      docId: 'shore',
      timestamp: 5,
      extension: 'PNG',
    );
    expect(png.mainPath, 'temples/shore/5.png');
    expect(png.thumbPath, 'temples/shore/5_480.png');
    expect(png.contentType, 'image/png');

    final heic = planTemplePhotoUpload(
      docId: 'shore',
      timestamp: 6,
      extension: 'heic',
    );
    expect(heic.mainPath, 'temples/shore/6.jpg');
    expect(heic.thumbPath, 'temples/shore/6_480.jpg');
    expect(heic.contentType, 'image/jpeg');
  });
}
