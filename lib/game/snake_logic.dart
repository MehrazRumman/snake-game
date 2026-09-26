import 'dart:collection';
import 'dart:math';

typedef Cell = Point<int>;

enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Direction(this.dx, this.dy);

  final int dx;
  final int dy;

  bool isOpposite(Direction other) => dx + other.dx == 0 && dy + other.dy == 0;
}

enum TickEvent { moved, ateFood, ateBonus, died, won }

/// Pure game rules for the classic snake, independent of any UI.
class SnakeGame {
  SnakeGame({
    this.cols = 20,
    this.rows = 24,
    this.level = 5,
    this.walls = true,
    Random? random,
  }) : _random = random ?? Random() {
    reset();
  }

  static const initialLength = 5;
  static const foodsPerBonus = 5;
  static const bonusLifetime = 40;
  static const bonusVariants = 3;

  final int cols;
  final int rows;
  final int level;
  final bool walls;
  final Random _random;

  /// Snake body, head first.
  final List<Cell> snake = [];
  final Queue<Direction> _pendingTurns = Queue();
  Direction direction = Direction.right;

  Cell? food;

  /// Left cell of the two-cell-wide bonus creature.
  Cell? bonus;
  int bonusVariant = 0;
  int bonusTicksLeft = 0;

  int score = 0;
  int foodsEaten = 0;
  int _growth = 0;
  bool isOver = false;
  bool isWon = false;

  Cell get head => snake.first;

  int get bonusPoints => level * (5 + bonusTicksLeft ~/ 2);

  void reset() {
    snake.clear();
    _pendingTurns.clear();
    final startX = cols ~/ 2;
    final startY = rows ~/ 2;
    for (var i = 0; i < initialLength; i++) {
      snake.add(Point(startX - i, startY));
    }
    direction = Direction.right;
    score = 0;
    foodsEaten = 0;
    _growth = 0;
    bonus = null;
    bonusTicksLeft = 0;
    isOver = false;
    isWon = false;
    food = _randomFreeCell();
  }

  /// Queues a turn. Up to two turns are buffered so quick inputs between
  /// ticks are not lost, and reversing onto the body is ignored.
  void turn(Direction d) {
    if (isOver) return;
    final last = _pendingTurns.isEmpty ? direction : _pendingTurns.last;
    if (d == last || d.isOpposite(last)) return;
    if (_pendingTurns.length < 2) _pendingTurns.add(d);
  }

  /// The direction the snake will move on the next tick.
  Direction get nextDirection =>
      _pendingTurns.isEmpty ? direction : _pendingTurns.first;

  /// The cell the head will move into on the next tick.
  Cell get nextHead {
    final d = nextDirection;
    var x = head.x + d.dx;
    var y = head.y + d.dy;
    if (!walls) {
      x %= cols;
      y %= rows;
    }
    return Point(x, y);
  }

  bool isBonusCell(Cell c) {
    final b = bonus;
    return b != null && c.y == b.y && (c.x == b.x || c.x == b.x + 1);
  }

  /// Whether the tail stays in place on the next tick.
  bool get willGrow => _growth > 0 || nextHead == food;

  /// Whether the next tick will end the game.
  bool get nextMoveIsFatal => isOver || _isFatal(nextHead);

  bool _isFatal(Cell next) {
    if (next.x < 0 || next.x >= cols || next.y < 0 || next.y >= rows) {
      return true;
    }
    // The tail moves out of the way this tick unless the snake is growing.
    final checkedLength = willGrow ? snake.length : snake.length - 1;
    for (var i = 0; i < checkedLength; i++) {
      if (snake[i] == next) return true;
    }
    return false;
  }

  TickEvent tick() {
    if (isOver) return isWon ? TickEvent.won : TickEvent.died;

    final next = nextHead;
    if (_isFatal(next)) {
      isOver = true;
      return TickEvent.died;
    }
    if (_pendingTurns.isNotEmpty) direction = _pendingTurns.removeFirst();

    final eatsFood = next == food;

    snake.insert(0, next);
    var event = TickEvent.moved;
    if (eatsFood) {
      score += level;
      foodsEaten++;
      _growth++;
      event = TickEvent.ateFood;
    } else if (isBonusCell(next)) {
      score += bonusPoints;
      bonus = null;
      bonusTicksLeft = 0;
      event = TickEvent.ateBonus;
    }

    if (_growth > 0) {
      _growth--;
    } else {
      snake.removeLast();
    }

    if (bonus != null && --bonusTicksLeft <= 0) bonus = null;

    if (eatsFood) {
      food = _randomFreeCell();
      if (food == null) {
        isOver = true;
        isWon = true;
        return TickEvent.won;
      }
      if (foodsEaten % foodsPerBonus == 0) _spawnBonus();
    }
    return event;
  }

  Set<Cell> _occupied() => {
        ...snake,
        ?food,
        if (bonus != null) ...[bonus!, Point(bonus!.x + 1, bonus!.y)],
      };

  Cell? _randomFreeCell() {
    final occupied = _occupied();
    final free = <Cell>[
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < cols; x++)
          if (!occupied.contains(Point(x, y))) Point(x, y),
    ];
    return free.isEmpty ? null : free[_random.nextInt(free.length)];
  }

  void _spawnBonus() {
    final occupied = _occupied();
    final spots = <Cell>[
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < cols - 1; x++)
          if (!occupied.contains(Point(x, y)) &&
              !occupied.contains(Point(x + 1, y)))
            Point(x, y),
    ];
    if (spots.isEmpty) return;
    bonus = spots[_random.nextInt(spots.length)];
    bonusVariant = _random.nextInt(bonusVariants);
    bonusTicksLeft = bonusLifetime;
  }
}
