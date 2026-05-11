import 'package:temple_app/utils/picked_file_data.dart';

/// Stub for non-web platforms — not implemented here since admin is web-only.
Future<List<PickedFileData>> pickImageFiles() async {
  throw UnsupportedError('Image picking is only supported on web.');
}
