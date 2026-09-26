import 'dart:math';

import 'lcd.dart';
import 'snake_logic.dart';

const _food = ['.X.', 'X.X', '.X.'];

const _bonusSprites = [
  ['X.XXX.X', '.XXXXX.', 'X.X.X.X'], // bug
  ['.XXXX.X', 'X.XXXX.', '.XXXX.X'], // fish
  ['.XXXXX.', 'XX.X.XX', 'X.X.X.X'], // ghost
];

const _headClosed = {
  Direction.right: ['X.X', 'XXX', 'XXX'],
  Direction.left: ['X.X', 'XXX', 'XXX'],
  Direction.up: ['XXX', '.XX', 'XXX'],
  Direction.down: ['XXX', 'XX.', 'XXX'],
};

const _headOpen = {
  Direction.right: ['XX.', 'X..', 'XX.'],
  Direction.left: ['.XX', '..X', '.XX'],
  Direction.up: ['X.X', 'X.X', 'XXX'],
  Direction.down: ['XXX', 'X.X', 'X.X'],
};

const menuItemCount = 3;

(int, int) _cellOrigin(Cell c) => (
      LcdLayout.cellsLeft + c.x * LcdLayout.cell,
      LcdLayout.cellsTop + c.y * LcdLayout.cell,
    );

/// Draws one 3x3 body block, bridging the 1 px gap towards neighbours on the
/// right or below so the snake reads as one continuous line.
void _segment(LcdCanvas c, int px, int py,
    {bool joinRight = false, bool joinDown = false, List<String>? pattern}) {
  if (pattern != null) {
    c.bitmap(pattern, px, py);
  } else {
    c.fill(px, py, 3, 3);
  }
  if (joinRight) c.fill(px + 3, py, 1, 3);
  if (joinDown) c.fill(px, py + 3, 3, 1);
}

void drawMenu(
  LcdCanvas c, {
  required int selected,
  required int level,
  required bool walls,
  required int highScore,
}) {
  c.textCentered('SNAKE', 3, scale: 3);

  // A little decorative snake chasing its food.
  const segments = 10;
  const startX = (LcdLayout.width - (segments + 2) * 4) ~/ 2;
  for (var i = 0; i < segments; i++) {
    _segment(c, startX + i * 4, 22,
        joinRight: i < segments - 1,
        pattern: i == segments - 1 ? _headOpen[Direction.right] : null);
  }
  c.bitmap(_food, startX + (segments + 1) * 4, 22);

  final items = ['NEW GAME', 'LEVEL $level', walls ? 'WALLS ON' : 'NO WALLS'];
  for (var i = 0; i < items.length; i++) {
    final y = 30 + i * 14;
    if (i == selected) {
      c.fill(2, y, LcdLayout.width - 4, 14);
      c.textCentered(items[i], y + 2, scale: 2, ink: false);
      if (i > 0) {
        c.text('<', 3, y + 5, ink: false);
        c.text('>', LcdLayout.width - 6, y + 5, ink: false);
      }
    } else {
      c.textCentered(items[i], y + 2, scale: 2);
    }
  }

  c.textCentered('TOP $highScore', 80);
  c.textCentered('5:OK  4/6:CHANGE', 94);
}

void drawGame(LcdCanvas c, SnakeGame g, {bool showSnake = true}) {
  // Header: score on the left, bonus creature countdown on the right.
  c.text(g.score.toString().padLeft(4, '0'), 0, 0);
  if (g.bonus != null) {
    c.bitmap(_bonusSprites[g.bonusVariant], LcdLayout.width - 16, 1);
    c.text(g.bonusTicksLeft.toString().padLeft(2, '0'), LcdLayout.width - 7, 0);
  }

  // Field border: solid when walls kill, dotted when the snake wraps.
  const top = LcdLayout.header;
  const bottom = LcdLayout.height - 1;
  const right = LcdLayout.width - 1;
  if (g.walls) {
    c.outline(0, top, LcdLayout.width, bottom - top + 1);
  } else {
    for (var x = 0; x <= right; x += 2) {
      c.px(x, top);
      c.px(x, bottom);
    }
    for (var y = top; y <= bottom; y += 2) {
      c.px(0, y);
      c.px(right, y);
    }
  }

  final food = g.food;
  if (food != null) {
    final (fx, fy) = _cellOrigin(food);
    c.bitmap(_food, fx, fy);
  }

  final bonus = g.bonus;
  if (bonus != null) {
    final (bx, by) = _cellOrigin(bonus);
    c.bitmap(_bonusSprites[g.bonusVariant], bx, by);
  }

  if (!showSnake) return;

  final snake = g.snake;
  final next = g.nextHead;
  final mouthOpen = !g.isOver && (next == food || g.isBonusCell(next));
  for (var i = 0; i < snake.length; i++) {
    final s = snake[i];
    bool isNeighbour(int j, int dx, int dy) =>
        j >= 0 &&
        j < snake.length &&
        snake[j].x == s.x + dx &&
        snake[j].y == s.y + dy;
    final (px, py) = _cellOrigin(s);
    _segment(
      c,
      px,
      py,
      joinRight: isNeighbour(i - 1, 1, 0) || isNeighbour(i + 1, 1, 0),
      joinDown: isNeighbour(i - 1, 0, 1) || isNeighbour(i + 1, 0, 1),
      pattern: i == 0
          ? (mouthOpen ? _headOpen : _headClosed)[g.direction]
          : null,
    );
  }
}

void drawPaused(LcdCanvas c) {
  const w = 59;
  const h = 17;
  const x = (LcdLayout.width - w) ~/ 2;
  const y = 46;
  c.fill(x - 1, y - 1, w + 2, h + 2, ink: false);
  c.outline(x, y, w, h);
  c.textCentered('PAUSED', y + 4, scale: 2);
}

void drawGameOver(
  LcdCanvas c, {
  required int score,
  required int highScore,
  required bool newRecord,
  required bool won,
  required int frame,
}) {
  c.textCentered(won ? 'YOU' : 'GAME', 8, scale: 3);
  c.textCentered(won ? 'WIN!' : 'OVER', 26, scale: 3);
  c.textCentered('SCORE', 50, scale: 2);
  c.textCentered('$score', 64, scale: 2);
  if (newRecord) {
    // Blink the record banner.
    if (frame.isEven) c.textCentered('NEW TOP SCORE!', 80);
  } else {
    c.textCentered('TOP ${max(score, highScore)}', 80);
  }
  c.textCentered('5:CONTINUE', 94);
}
