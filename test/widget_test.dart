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
    for (final n in [2, 4, 5, 6, 8]) {
      expect(find.byKey(ValueKey('key-$n')), findsOneWidget);
    }
    expect(find.text('SELECT'), findsOneWidget);

    // OK on "NEW GAME" starts a game; the soft key then offers PAUSE.
    await tester.tap(find.byKey(const ValueKey('key-5')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('PAUSE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('key-5')));
    await tester.pump();
    expect(find.text('RESUME'), findsOneWidget);

    // BACK leaves the game and returns to the menu.
    await tester.tap(find.byKey(const ValueKey('key-back')));
    await tester.pump();
    expect(find.text('SELECT'), findsOneWidget);
  });
}
