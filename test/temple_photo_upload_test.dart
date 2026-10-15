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
  _RecordingWriter({this.failThumb = false});

  final bool failThumb;
  final puts = <_Put>[];
  final deletes = <String>[];

  @override
  Future<TemplePhotoStoredObject> put({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required String cacheControl,
    required void Function(double progress) onProgress,
  }) async {
    if (failThumb && path.contains('_480_g')) {
      throw StateError('thumb failed');
    }
    puts.add(
      _Put(
        path: path,
        bytes: bytes,
        contentType: contentType,
        cacheControl: cacheControl,
      ),
    );
    onProgress(1);
    return TemplePhotoStoredObject(
      path: path,
      url: 'https://storage.googleapis.com/bucket/$path?token=real',
      generation: '42',
    );
  }

  @override
  Future<void> delete({required String path}) async {
    deletes.add(path);
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
    expect(kTemplePhotoThumbQuality, inInclusiveRange(75, 80));
  });

  test('upload writes the original then the generation thumb', () async {
    final writer = _RecordingWriter();
    final uploader = FirebaseTemplePhotoUploader(
      objects: writer,
      clock: () => 171000,
    );
    final progress = <double>[];
    final uploaded = await uploader.upload(
      docId: 'shore-temple',
      bytes: Uint8List.fromList([1, 2, 3]),
      thumbBytes: Uint8List.fromList([4]),
      extension: 'jpeg',
      onProgress: progress.add,
    );

    expect(
      uploaded.url,
      'https://storage.googleapis.com/bucket/temples/shore-temple/171000.jpeg?token=real',
    );
    expect(
      uploaded.thumbUrl,
      'https://storage.googleapis.com/bucket/temples/shore-temple/171000_480_g42_jpeg.jpg?token=real',
    );
    expect(writer.puts.map((put) => put.path), [
      'temples/shore-temple/171000.jpeg',
      'temples/shore-temple/171000_480_g42_jpeg.jpg',
    ]);
    expect(writer.puts[0].contentType, 'image/jpeg');
    expect(writer.puts[1].contentType, 'image/jpeg');
    for (final put in writer.puts) {
      expect(put.cacheControl, 'public, max-age=31536000, immutable');
    }
    expect(writer.puts[0].bytes, Uint8List.fromList([1, 2, 3]));
    expect(writer.puts[1].bytes, Uint8List.fromList([4]));
    expect(writer.deletes, isEmpty);
    expect(progress, contains(1));
  });

  test('a failed thumb deletes the original', () async {
    final writer = _RecordingWriter(failThumb: true);
    final uploader = FirebaseTemplePhotoUploader(
      objects: writer,
      clock: () => 171000,
    );
    await expectLater(
      uploader.upload(
        docId: 'shore-temple',
        bytes: Uint8List.fromList([1]),
        thumbBytes: Uint8List.fromList([4]),
        extension: 'jpg',
        onProgress: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(writer.puts.map((put) => put.path), [
      'temples/shore-temple/171000.jpg',
    ]);
    expect(writer.deletes, ['temples/shore-temple/171000.jpg']);
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
    expect(writer.deletes, isEmpty);
  });

  test('png originals keep their file and the thumb is jpeg', () {
    final png = planTemplePhotoUpload(
      docId: 'shore',
      timestamp: 5,
      extension: 'PNG',
      generation: '9',
    );
    expect(png.mainPath, 'temples/shore/5.png');
    expect(png.thumbPath, 'temples/shore/5_480_g9_png.jpg');
    expect(png.contentType, 'image/png');
    expect(png.thumbContentType, 'image/jpeg');

    final heic = planTemplePhotoUpload(
      docId: 'shore',
      timestamp: 6,
      extension: 'heic',
      generation: '9',
    );
    expect(heic.mainPath, 'temples/shore/6.jpg');
    expect(heic.thumbPath, 'temples/shore/6_480_g9.jpg');
    expect(heic.contentType, 'image/jpeg');
    expect(heic.thumbContentType, 'image/jpeg');
  });
}
