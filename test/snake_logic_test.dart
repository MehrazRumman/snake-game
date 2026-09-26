import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:snake_game/game/snake_logic.dart';

void main() {
  SnakeGame newGame({bool walls = true}) =>
      SnakeGame(cols: 20, rows: 24, level: 3, walls: walls, random: Random(1));

  test('starts with the initial snake moving right', () {
    final g = newGame();
    expect(g.snake.length, SnakeGame.initialLength);
    expect(g.head, const Point(10, 12));
    expect(g.direction, Direction.right);
    expect(g.snake.contains(g.food), isFalse);
  });

  test('moves one cell per tick and keeps its length', () {
    final g = newGame()..food = const Point(0, 0);
    g.tick();
    expect(g.head, const Point(11, 12));
    expect(g.snake.length, SnakeGame.initialLength);
  });

  test('ignores reversing into itself', () {
    final g = newGame()..food = const Point(0, 0);
    g.turn(Direction.left);
    g.tick();
    expect(g.direction, Direction.right);
    expect(g.isOver, isFalse);
  });

  test('buffers two quick turns', () {
    final g = newGame()..food = const Point(0, 0);
    g.turn(Direction.up);
    g.turn(Direction.left);
    g.tick();
    expect(g.head, const Point(10, 11));
    g.tick();
    expect(g.head, const Point(9, 11));
  });

  test('eating food grows the snake and scores the level', () {
    final g = newGame()..food = const Point(11, 12);
    expect(g.tick(), TickEvent.ateFood);
    expect(g.score, 3);
    expect(g.snake.length, SnakeGame.initialLength + 1);
    expect(g.food, isNot(const Point(11, 12)));
  });

  test('hitting a wall ends the game when walls are on', () {
    final g = newGame()..food = const Point(0, 0);
    TickEvent last = TickEvent.moved;
    for (var i = 0; i < 20 && !g.isOver; i++) {
      last = g.tick();
    }
    expect(last, TickEvent.died);
    expect(g.isOver, isTrue);
  });

  test('wraps around when walls are off', () {
    final g = newGame(walls: false)..food = const Point(0, 0);
    for (var i = 0; i < 10; i++) {
      g.tick();
    }
    expect(g.isOver, isFalse);
    expect(g.head, const Point(0, 12));
  });

  test('running into its own body ends the game', () {
    final g = newGame()..food = const Point(0, 0);
    // Grow so the snake is long enough to bite itself.
    g.snake.insertAll(0, [const Point(12, 12), const Point(11, 12)]);
    g.turn(Direction.up);
    g.tick();
    g.turn(Direction.left);
    g.tick();
    g.turn(Direction.down);
    expect(g.tick(), TickEvent.died);
  });

  test('moving into the cell the tail just left is allowed', () {
    final g = newGame()..food = const Point(0, 0);
    g.snake
      ..clear()
      ..addAll(const [Point(5, 5), Point(5, 6), Point(4, 6), Point(4, 5)]);
    g.direction = Direction.up;
    g.turn(Direction.left);
    expect(g.tick(), TickEvent.moved);
    expect(g.head, const Point(4, 5));
  });

  test('a bonus appears after every fifth food and can be eaten', () {
    final g = newGame(walls: false);
    for (var i = 0; i < SnakeGame.foodsPerBonus; i++) {
      g.food = g.nextHead;
      g.tick();
    }
    expect(g.bonus, isNotNull);
    expect(g.bonusTicksLeft, SnakeGame.bonusLifetime);

    final before = g.score;
    final points = g.bonusPoints;
    g.bonus = g.nextHead;
    expect(g.tick(), TickEvent.ateBonus);
    expect(g.score, before + points);
    expect(g.bonus, isNull);
  });
}
