import 'dart:typed_data';

class PickedFileData {
  const PickedFileData({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot != -1 ? name.substring(dot + 1).toLowerCase() : 'jpg';
  }
}
