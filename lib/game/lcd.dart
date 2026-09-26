import 'dart:math';

import 'package:flutter/material.dart';

import 'pixel_font.dart';

/// Classic green monochrome LCD palette.
abstract final class LcdColors {
  static const background = Color(0xFFC7F0D8);
  static const backgroundDim = Color(0xFFB4DEC4);
  static const ink = Color(0xFF43523D);
}

/// Geometry of the virtual LCD, measured in LCD pixels.
abstract final class LcdLayout {
  static const cols = 20;
  static const rows = 24;
  static const cell = 4;

  /// Score line height (5 px text + 1 px spacing).
  static const header = 6;

  /// Field border sits at [header]; one px padding, then the cells.
  static const cellsLeft = 2;
  static const cellsTop = header + 2;

  static const width = cols * cell + 3; // 83
  static const height = cellsTop + rows * cell + 1; // 105

  /// Blank LCD pixels around the drawable area.
  static const margin = 2;
  static const totalWidth = width + margin * 2;
  static const totalHeight = height + margin * 2;
}

/// Collects LCD pixels into batched paths and paints them in draw order.
class LcdCanvas {
  LcdCanvas(this._origin, this._unit)
      : _gap = _unit >= 3 ? _unit * 0.12 : 0.0;

  final Offset _origin;
  final double _unit;
  final double _gap;
  final List<(Path, bool)> _layers = [];

  Path _layer(bool ink) {
    if (_layers.isEmpty || _layers.last.$2 != ink) _layers.add((Path(), ink));
    return _layers.last.$1;
  }

  void px(int x, int y, {bool ink = true}) {
    final left = _origin.dx + x * _unit;
    final top = _origin.dy + y * _unit;
    if (ink) {
      // A hairline gap between lit pixels gives the dot-matrix look.
      _layer(true).addRect(Rect.fromLTWH(
          left + _gap / 2, top + _gap / 2, _unit - _gap, _unit - _gap));
    } else {
      _layer(false).addRect(Rect.fromLTWH(left, top, _unit, _unit));
    }
  }

  void fill(int x, int y, int w, int h, {bool ink = true}) {
    if (!ink) {
      _layer(false).addRect(Rect.fromLTWH(_origin.dx + x * _unit,
          _origin.dy + y * _unit, w * _unit, h * _unit));
      return;
    }
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        px(x + i, y + j);
      }
    }
  }

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

  void paintTo(Canvas canvas) {
    final shadowOffset = Offset(_unit * 0.3, _unit * 0.3);
    final shadow = Paint()..color = LcdColors.ink.withValues(alpha: 0.16);
    final ink = Paint()..color = LcdColors.ink;
    final clear = Paint()..color = LcdColors.background;
    for (final (path, isInk) in _layers) {
      if (isInk) {
        canvas.drawPath(path.shift(shadowOffset), shadow);
        canvas.drawPath(path, ink);
      } else {
        canvas.drawPath(path, clear);
      }
    }
  }
}

class LcdPainter extends CustomPainter {
  LcdPainter(this.draw);

  final void Function(LcdCanvas c) draw;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = min(size.width / LcdLayout.totalWidth,
        size.height / LcdLayout.totalHeight);
    final origin = Offset(
      (size.width - LcdLayout.width * unit) / 2,
      (size.height - LcdLayout.height * unit) / 2,
    );
    final lcd = LcdCanvas(origin, unit);
    draw(lcd);
    lcd.paintTo(canvas);
  }

  @override
  bool shouldRepaint(LcdPainter oldDelegate) => true;
}
