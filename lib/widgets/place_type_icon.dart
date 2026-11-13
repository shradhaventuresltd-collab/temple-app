import 'package:flutter/material.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/directory_filters.dart';

/// Kind of place icon shown on a browse card or mosaic fallback.
enum PlaceTypeKind { hindu, sikhGurdwara, jainDerasar, buddhist }

/// Light / dark outline colours from the KAN-203 artwork.
const traditionIconColorLight = Color(0xFF8D6E63);
const traditionIconColorDark = Color(0xFFA99079);

/// Outline colour for the current theme when no override is passed.
Color traditionIconColorOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? traditionIconColorDark
      : traditionIconColorLight;
}

/// Kind for a listing, from the same tradition key as the Tradition chip.
PlaceTypeKind placeTypeKindOf(Temple temple) {
  return placeTypeKindForKey(directoryTraditionKey(temple));
}

/// Kind for a tradition filter key (`hindu`, `sikh`, `jain`, `buddhist`).
PlaceTypeKind placeTypeKindForKey(String? key) {
  return switch (key) {
    'sikh' => PlaceTypeKind.sikhGurdwara,
    'jain' => PlaceTypeKind.jainDerasar,
    'buddhist' => PlaceTypeKind.buddhist,
    _ => PlaceTypeKind.hindu,
  };
}

/// Spoken label for the type icon.
String placeTypeIconLabel(PlaceTypeKind kind, {AppLocalizations? l10n}) {
  final strings = l10n ?? L10nLookup.english;
  return switch (kind) {
    PlaceTypeKind.sikhGurdwara => strings.placeTypeGurdwaraLabel,
    PlaceTypeKind.jainDerasar => strings.placeTypeDerasarLabel,
    PlaceTypeKind.buddhist => strings.placeTypeBuddhistTempleLabel,
    PlaceTypeKind.hindu => strings.placeTypeTempleLabel,
  };
}

/// Type icon for a listing. Material icons for Hindu and Buddhist temples;
/// CustomPainter silhouettes (Ux artwork, no religious emblems) for gurdwara
/// and derasar.
class PlaceTypeIcon extends StatelessWidget {
  const PlaceTypeIcon({
    super.key,
    required this.temple,
    this.size = 24,
    this.color,
  }) : _kind = null;

  const PlaceTypeIcon.forKind({
    super.key,
    required PlaceTypeKind kind,
    this.size = 24,
    this.color,
  }) : temple = null,
       _kind = kind;

  PlaceTypeIcon.forKey({
    super.key,
    required String? traditionKey,
    this.size = 24,
    this.color,
  }) : temple = null,
       _kind = placeTypeKindForKey(traditionKey);

  final Temple? temple;
  final PlaceTypeKind? _kind;
  final double size;
  final Color? color;

  PlaceTypeKind get kind => _kind ?? placeTypeKindOf(temple!);

  @override
  Widget build(BuildContext context) {
    final paint = color ?? traditionIconColorOf(context);
    final resolved = kind;
    final child = switch (resolved) {
      PlaceTypeKind.hindu => Icon(
        Icons.temple_hindu_outlined,
        size: size,
        color: paint,
      ),
      PlaceTypeKind.buddhist => Icon(
        Icons.temple_buddhist_outlined,
        size: size,
        color: paint,
      ),
      PlaceTypeKind.sikhGurdwara => _VectorIcon(
        size: size,
        painter: _SvgStrokePainter(
          paint,
          _gurdwaraPaths,
          circles: _gurdwaraCircles,
        ),
      ),
      PlaceTypeKind.jainDerasar => _VectorIcon(
        size: size,
        painter: _SvgStrokePainter(
          paint,
          _derasarPaths,
          circles: _derasarCircles,
        ),
      ),
    };
    return Semantics(
      identifier: 'place-type-icon',
      label: placeTypeIconLabel(resolved, l10n: context.l10n),
      image: true,
      child: child,
    );
  }
}

/// Neutral 16dp gateway / arch used by the idle Tradition chip.
class TraditionArchIcon extends StatelessWidget {
  const TraditionArchIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final paint = color ?? traditionIconColorOf(context);
    return _VectorIcon(
      size: size,
      painter: _SvgStrokePainter(paint, _archPaths, stroke: 1.6),
    );
  }
}

class _VectorIcon extends StatelessWidget {
  const _VectorIcon({required this.size, required this.painter});

  final double size;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

/// Artwork transcribed from /workspace/tradition-places/icons/*-24-light.svg.
const _gurdwaraPaths = [
  'M5 21 V3.2',
  'M5 3.2 L10.4 5.8 L5 8.2 Z',
  'M9 21 V14.2 H21 V21',
  'M9 14.2 H21',
  'M13.1 21 V17.6 C13.1 16.2 14.1 15.3 15 15.3 C15.9 15.3 16.9 16.2 16.9 17.6 V21',
  'M11.1 14.2 C10.9 11.8 12.2 10.2 13.4 9.1 C14.1 8.4 14.6 7.4 15 6.4 C15.4 7.4 15.9 8.4 16.6 9.1 C17.8 10.2 19.1 11.8 18.9 14.2',
  'M15 6.4 V5.2',
];
const _gurdwaraCircles = [(15.0, 4.6, 0.55)];

const _derasarPaths = [
  'M3.8 21 H20.2',
  'M5.2 21 V17.8 H18.8 V21',
  'M10.2 21 V18.4 C10.2 17.1 11 16.3 12 16.3 C13 16.3 13.8 17.1 13.8 18.4 V21',
  'M6.4 17.8 C6.6 15.2 8.2 13.6 9.4 11.8 C10.3 10.4 10.7 8.6 12 3.8 C13.3 8.6 13.7 10.4 14.6 11.8 C15.8 13.6 17.4 15.2 17.6 17.8',
  'M7.6 15.6 C8.6 14.8 10.2 14.2 12 14.2 C13.8 14.2 15.4 14.8 16.4 15.6',
  'M8.6 12.8 C9.4 12.2 10.6 11.7 12 11.7 C13.4 11.7 14.6 12.2 15.4 12.8',
  'M12 3.8 V2.8',
  'M12.5 2.35 H16.8',
  'M16.8 2.35 L20.2 3.7 L16.8 5.05 Z',
];
const _derasarCircles = [(12.0, 2.35, 0.5)];

const _archPaths = [
  'M5 20 V11',
  'M19 20 V11',
  'M5 11 C5 5.5 19 5.5 19 11',
  'M9 20 V14 C9 12.5 10.2 11.6 12 11.6 C13.8 11.6 15 12.5 15 14 V20',
];

class _SvgStrokePainter extends CustomPainter {
  const _SvgStrokePainter(
    this.color,
    this.paths, {
    this.circles = const [],
    this.stroke = 1.6,
  });

  final Color color;
  final List<String> paths;
  final List<(double, double, double)> circles;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..filterQuality = FilterQuality.high;
    canvas.save();
    canvas.scale(scale);
    for (final d in paths) {
      canvas.drawPath(_parseSvgPath(d), paint);
    }
    for (final (cx, cy, r) in circles) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SvgStrokePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

/// Minimal parser for the M/L/H/V/C/Z subset used by the Ux SVGs.
Path _parseSvgPath(String d) {
  final path = Path();
  final tokens = _lexSvg(d);
  var i = 0;
  var cmd = 'M';
  var cx = 0.0, cy = 0.0;
  var startX = 0.0, startY = 0.0;
  double num() => tokens[i++];
  while (i < tokens.length) {
    final t = tokens[i];
    if (t is String) {
      cmd = t;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cx = startX;
        cy = startY;
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        cx = num();
        cy = num();
        path.moveTo(cx, cy);
        startX = cx;
        startY = cy;
        cmd = 'L';
      case 'L':
        cx = num();
        cy = num();
        path.lineTo(cx, cy);
      case 'H':
        cx = num();
        path.lineTo(cx, cy);
      case 'V':
        cy = num();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = num(), y1 = num(), x2 = num(), y2 = num();
        cx = num();
        cy = num();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
      default:
        throw FormatException('Unsupported SVG command $cmd in $d');
    }
  }
  return path;
}

List<dynamic> _lexSvg(String d) {
  final out = <dynamic>[];
  final buf = StringBuffer();
  void flush() {
    if (buf.isEmpty) return;
    out.add(double.parse(buf.toString()));
    buf.clear();
  }

  for (var i = 0; i < d.length; i++) {
    final ch = d[i];
    if ('MmLlHhVvCcZz'.contains(ch)) {
      flush();
      out.add(ch.toUpperCase());
    } else if (ch == ',' || ch == ' ' || ch == '\t' || ch == '\n') {
      flush();
    } else if (ch == '-') {
      flush();
      buf.write(ch);
    } else {
      buf.write(ch);
    }
  }
  flush();
  return out;
}
