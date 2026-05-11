import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:temple_app/utils/picked_file_data.dart';

/// Opens the browser's native file picker for images, returns file bytes.
Future<List<PickedFileData>> pickImageFiles() async {
  final completer = Completer<List<PickedFileData>>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;

  var picked = false;

  input.onChange.listen((_) async {
    picked = true;
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete([]);
      return;
    }

    final results = <PickedFileData>[];
    for (final file in files) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;
      if (reader.result case final List<int> raw) {
        results.add(PickedFileData(
          name: file.name,
          bytes: Uint8List.fromList(raw),
        ));
      }
    }
    completer.complete(results);
  });

  // If the user cancels the dialog, onChange never fires.
  // Use a focus event as a fallback after a short delay.
  html.window.addEventListener('focus', (_) {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!picked && !completer.isCompleted) {
        completer.complete([]);
      }
    });
  });

  input.click();
  return completer.future;
}
