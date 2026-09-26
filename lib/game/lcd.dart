import 'dart:math';

import 'package:flutter/material.dart';

import 'pixel_font.dart';

/// Classic green monochrome LCD palette.
abstract final class LcdColors {
  static const background = Color(0xFFC7F0D8);
  static const backgroundDim = Color(0xFFB9E4CA);
  static const ink = Color(0xFF2F3B2A);
}

/// Geometry of the virtual LCD, measured in LCD pixels.
abstract final class LcdLayout {
  static const cols = 20;
  static const rows = 24;
  static const cell = 4;

  /// Score line height (7 px text + 1 px spacing).
  static const header = 8;

  /// Field border sits at [header]; one px padding, then the cells.
  static const cellsLeft = 2;
  static const cellsTop = header + 2;

  static const width = cols * cell + 3; // 83
  static const height = cellsTop + rows * cell + 1; // 107

  /// Blank LCD pixels around the drawable area.
  static const margin = 2;
  static const totalWidth = width + margin * 2;
  static const totalHeight = height + margin * 2;
}

/// Collects LCD pixels into batched paths and paints them in draw order.
///
/// Every LCD pixel is a solid square whose edges land on physical screen
/// pixels, so shapes render crisp with no blur or seams.
class LcdCanvas {
  LcdCanvas(this._origin, this._unit, this._dpr);

  final Offset _origin;
  final double _unit;
  final double _dpr;
  final List<(Path, bool)> _layers = [];

  Path _layer(bool ink) {
    if (_layers.isEmpty || _layers.last.$2 != ink) _layers.add((Path(), ink));
    return _layers.last.$1;
  }

  double _snap(double v) => (v * _dpr).roundToDouble() / _dpr;

  /// Fills a rectangle of LCD pixels. Fractional positions are allowed (used
  /// for smooth motion) and are snapped to whole physical pixels.
  void fill(num x, num y, num w, num h, {bool ink = true}) {
    _layer(ink).addRect(Rect.fromLTRB(
      _snap(_origin.dx + x * _unit),
      _snap(_origin.dy + y * _unit),
      _snap(_origin.dx + (x + w) * _unit),
      _snap(_origin.dy + (y + h) * _unit),
    ));
  }

  void px(int x, int y, {bool ink = true}) => fill(x, y, 1, 1, ink: ink);

  void outline(int x, int y, int w, int h) {
    fill(x, y, w, 1);
    fill(x, y + h - 1, w, 1);
    fill(x, y + 1, 1, h - 2);
    fill(x + w - 1, y + 1, 1, h - 2);
  }

  void bitmap(List<String> rows, int x, int y, {int scale = 1, bool ink = true}) {
    for (var j = 0; j < rows.length; j++) {
      final row = rows[j];
      for (var i = 0; i < row.length; i++) {
        if (row[i] == 'X') {
          fill(x + i * scale, y + j * scale, scale, scale, ink: ink);
        }
      }
    }
  }

  void text(String s, int x, int y, {int scale = 1, bool ink = true}) {
    var cx = x;
    for (final ch in s.toUpperCase().split('')) {
      final glyph = glyphs[ch];
      if (glyph != null) bitmap(glyph, cx, y, scale: scale, ink: ink);
      cx += glyphAdvance(ch) * scale;
    }
  }

  void textCentered(String s, int y, {int scale = 1, bool ink = true}) {
    text(s, (LcdLayout.width - textWidth(s, scale: scale)) ~/ 2, y,
        scale: scale, ink: ink);
  }

  void textRight(String s, int right, int y, {int scale = 1, bool ink = true}) {
    text(s, right - textWidth(s, scale: scale) + 1, y, scale: scale, ink: ink);
  }

  void paintTo(Canvas canvas) {
    final ink = Paint()
      ..color = LcdColors.ink
      ..isAntiAlias = false;
    final clear = Paint()
      ..color = LcdColors.background
      ..isAntiAlias = false;
    for (final (path, isInk) in _layers) {
      canvas.drawPath(path, isInk ? ink : clear);
    }
  }
}

class LcdPainter extends CustomPainter {
  LcdPainter(this.draw, {required this.devicePixelRatio, super.repaint});

  final void Function(LcdCanvas c) draw;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final dpr = devicePixelRatio;
    // Snap the LCD pixel size and origin to whole physical pixels.
    final fit = min(size.width / LcdLayout.totalWidth,
        size.height / LcdLayout.totalHeight);
    final unit = max(1.0, (fit * dpr).floorToDouble()) / dpr;
    final origin = Offset(
      ((size.width - LcdLayout.width * unit) / 2 * dpr).roundToDouble() / dpr,
      ((size.height - LcdLayout.height * unit) / 2 * dpr).roundToDouble() / dpr,
    );
    final lcd = LcdCanvas(origin, unit, dpr);
    draw(lcd);
    lcd.paintTo(canvas);
  }

  @override
  bool shouldRepaint(LcdPainter oldDelegate) => true;
}
