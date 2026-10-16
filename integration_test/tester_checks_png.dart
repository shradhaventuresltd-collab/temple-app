import 'dart:io';
import 'dart:typed_data';

/// FNV-1a over the length and every 64th byte. Used to decide one recapture.
int pngFingerprint(List<int> bytes) {
  var hash = 0x811c9dc5;
  hash = _fnv(hash, bytes.length & 0xff);
  hash = _fnv(hash, (bytes.length >> 8) & 0xff);
  hash = _fnv(hash, (bytes.length >> 16) & 0xff);
  hash = _fnv(hash, (bytes.length >> 24) & 0xff);
  for (var i = 0; i < bytes.length; i += 64) {
    hash = _fnv(hash, bytes[i]);
  }
  return hash;
}

int _fnv(int hash, int byte) => ((hash ^ byte) * 0x01000193) & 0x7fffffff;

/// True when the PNG is undecodable or at least 92% near-black.
bool pngLooksBlack(List<int> bytes) {
  try {
    return _darkRatio(bytes) >= 0.92;
  } catch (_) {
    return true;
  }
}

double _darkRatio(List<int> bytes) {
  if (bytes.length < 8) {
    throw const FormatException('short png');
  }
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) throw const FormatException('not a png');
  }
  var pos = 8;
  int? width;
  int? height;
  int? color;
  final compressed = BytesBuilder(copy: false);
  while (pos + 8 <= bytes.length) {
    final length = _u32(bytes, pos);
    final kind = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));
    final start = pos + 8;
    final end = start + length;
    if (end + 4 > bytes.length) throw const FormatException('truncated chunk');
    if (kind == 'IHDR') {
      width = _u32(bytes, start);
      height = _u32(bytes, start + 4);
      color = bytes[start + 9];
      if (bytes[start + 12] != 0) throw const FormatException('interlaced');
    } else if (kind == 'IDAT') {
      compressed.add(bytes.sublist(start, end));
    } else if (kind == 'IEND') {
      break;
    }
    pos = end + 4;
  }
  if (width == null || height == null || color == null) {
    throw const FormatException('missing IHDR');
  }
  const channelsByColor = <int, int>{0: 1, 2: 3, 4: 2, 6: 4};
  final channels = channelsByColor[color];
  if (channels == null || width <= 0 || height <= 0) {
    throw const FormatException('unsupported png');
  }
  final raw = zlib.decode(compressed.takeBytes());
  final stride = width * channels;
  if (raw.length < height * (stride + 1)) {
    throw const FormatException('short scanlines');
  }
  var index = 0;
  var previous = Uint8List(stride);
  var dark = 0;
  var seen = 0;
  for (var y = 0; y < height; y++) {
    final filter = raw[index];
    index++;
    final row = Uint8List.fromList(raw.sublist(index, index + stride));
    index += stride;
    _unfilter(filter, row, previous, channels);
    if (y % 40 == 0) {
      for (var x = 0; x < width; x += 40) {
        final offset = x * channels;
        final red = row[offset];
        final green = channels == 1 ? red : row[offset + 1];
        final blue = channels == 1 ? red : row[offset + 2];
        final value = (red + green + blue) / 3;
        if (value < 16) dark++;
        seen++;
      }
    }
    previous = row;
  }
  if (seen == 0) return 1;
  return dark / seen;
}

int _u32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

void _unfilter(int filter, Uint8List row, Uint8List previous, int channels) {
  switch (filter) {
    case 0:
      return;
    case 1:
      for (var x = 0; x < row.length; x++) {
        final left = x >= channels ? row[x - channels] : 0;
        row[x] = (row[x] + left) & 255;
      }
    case 2:
      for (var x = 0; x < row.length; x++) {
        row[x] = (row[x] + previous[x]) & 255;
      }
    case 3:
      for (var x = 0; x < row.length; x++) {
        final left = x >= channels ? row[x - channels] : 0;
        row[x] = (row[x] + ((left + previous[x]) >> 1)) & 255;
      }
    case 4:
      for (var x = 0; x < row.length; x++) {
        final left = x >= channels ? row[x - channels] : 0;
        final up = previous[x];
        final upLeft = x >= channels ? previous[x - channels] : 0;
        row[x] = (row[x] + _paeth(left, up, upLeft)) & 255;
      }
    default:
      throw FormatException('filter $filter');
  }
}

int _paeth(int left, int up, int upLeft) {
  final estimate = left + up - upLeft;
  final leftDistance = (estimate - left).abs();
  final upDistance = (estimate - up).abs();
  final upLeftDistance = (estimate - upLeft).abs();
  if (leftDistance <= upDistance && leftDistance <= upLeftDistance) {
    return left;
  }
  if (upDistance <= upLeftDistance) return up;
  return upLeft;
}
