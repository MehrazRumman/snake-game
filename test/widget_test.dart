import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snake_game/main.dart';
import 'package:snake_game/game/lcd.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the LCD and keypad, and starts a game', (tester) async {
    await tester.pumpWidget(const SnakeApp());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is LcdPainter),
      findsOneWidget,
    );
    for (final n in ['2', '4', '5', '6', '8']) {
      expect(find.text(n), findsOneWidget);
    }

    // Press 5 (OK) on "NEW GAME", let a few ticks pass, then pause.
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(seconds: 1));
  });
}
