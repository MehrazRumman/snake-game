# snake-game

A retro, pixel-style Snake game for Android, built with Flutter and styled after the classic monochrome phone Snake: green LCD screen, dot-matrix pixels, and a 3x3 phone keypad.

## Features

- Everything on screen is drawn pixel by pixel on a virtual 83x105 LCD, including a custom 5 px bitmap font
- Keypad controls (2/4/6/8 to steer, 5 for OK/pause) or swipe on the screen
- Speed levels 1–9, with food worth more points at higher levels
- Walls on (hitting the border ends the game) or no walls (the snake wraps around)
- A bonus creature appears after every 5th food and is worth more the sooner you catch it
- The snake opens its mouth when food is right ahead and blinks when it dies
- Top score and settings are saved on the device
- Pauses automatically when the app goes to the background, and the Android back button pauses the game

## Run

```sh
flutter pub get
flutter run            # on a connected Android device or emulator
flutter build apk      # release APK at build/app/outputs/flutter-apk/app-release.apk
```

On an emulator or with a keyboard you can also use the arrow keys or WASD, plus Enter/Space for OK.

## Project layout

```
lib/
  main.dart                 app entry, portrait lock
  game/snake_logic.dart     pure game rules (movement, growth, collisions, bonus)
  game/lcd.dart             virtual LCD canvas and painter
  game/pixel_font.dart      bitmap font
  game/scenes.dart          menu, game, pause and game-over screens
  screens/game_screen.dart  game loop, input, persistence
  widgets/keypad.dart       phone keypad
test/                       unit tests for the rules, plus a widget smoke test
```

```sh
flutter test
```
