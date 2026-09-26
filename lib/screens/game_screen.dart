import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/lcd.dart';
import '../game/scenes.dart';
import '../game/snake_logic.dart';
import '../widgets/keypad.dart';

enum _Mode { menu, playing, paused, dying, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _bodyTop = Color(0xFF2A3947);
  static const _bodyBottom = Color(0xFF141C24);
  static const _swipeThreshold = 18.0;

  late SnakeGame _game;
  _Mode _mode = _Mode.menu;
  int _menuIndex = 0;
  int _level = 5;
  bool _walls = true;
  int _highScore = 0;
  bool _newRecord = false;
  int _frame = 0;
  Timer? _timer;
  SharedPreferences? _prefs;

  /// Drives the game every frame while playing, so the snake can glide
  /// between ticks.
  late final Ticker _ticker = createTicker(_onFrame);
  final _repaint = ValueNotifier<int>(0);
  Duration _lastTick = Duration.zero;
  double _progress = 0;
  Offset _swipeDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = SnakeGame(level: _level, walls: _walls);
    _loadPrefs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker.dispose();
    _repaint.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _mode == _Mode.playing) {
      setState(_pause);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _highScore = prefs.getInt('highScore') ?? 0;
      _level = (prefs.getInt('level') ?? 5).clamp(1, 9);
      _walls = prefs.getBool('walls') ?? true;
    });
  }

  void _saveSettings() {
    _prefs?.setInt('level', _level);
    _prefs?.setBool('walls', _walls);
  }

  // --- Game flow -----------------------------------------------------------

  Duration get _tickInterval => Duration(milliseconds: 330 - _level * 30);

  void _startTimer(Duration interval, VoidCallback onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _ticker.stop();
  }

  /// Starts the frame loop, continuing from the current glide [_progress].
  void _startLoop() {
    _timer?.cancel();
    _lastTick = -_tickInterval * _progress;
    _ticker.start();
  }

  void _onFrame(Duration elapsed) {
    final interval = _tickInterval;
    while (_mode == _Mode.playing && elapsed - _lastTick >= interval) {
      _lastTick += interval;
      _onTick();
    }
    if (_mode == _Mode.playing) {
      _progress = (elapsed - _lastTick).inMicroseconds / interval.inMicroseconds;
    }
    _repaint.value++;
  }

  void _startGame() {
    _game = SnakeGame(level: _level, walls: _walls);
    _newRecord = false;
    _mode = _Mode.playing;
    _progress = 0;
    _startLoop();
  }

  void _onTick() {
    final event = _game.tick();
    switch (event) {
      case TickEvent.ateFood:
        HapticFeedback.selectionClick();
      case TickEvent.ateBonus:
        HapticFeedback.mediumImpact();
      case TickEvent.died:
      case TickEvent.won:
        _endGame();
      case TickEvent.moved:
        break;
    }
  }

  void _endGame() {
    HapticFeedback.heavyImpact();
    _recordScore();
    _ticker.stop();
    _progress = 0;
    // Blink the snake a few times, like the original, before the summary.
    _mode = _Mode.dying;
    _frame = 0;
    // Called from inside a frame callback, so defer the rebuild request.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    _startTimer(const Duration(milliseconds: 180), () {
      setState(() {
        _frame++;
        if (_frame >= 8) _showGameOver();
      });
    });
  }

  void _recordScore() {
    if (_game.score > _highScore) {
      _highScore = _game.score;
      _newRecord = true;
      _prefs?.setInt('highScore', _highScore);
    }
  }

  void _showGameOver() {
    _mode = _Mode.gameOver;
    _frame = 0;
    if (_newRecord) {
      _startTimer(const Duration(milliseconds: 400), () {
        setState(() => _frame++);
      });
    } else {
      _stopTimer();
    }
  }

  void _pause() {
    _stopTimer();
    _mode = _Mode.paused;
  }

  void _resume() {
    _mode = _Mode.playing;
    _startLoop();
  }

  void _toMenu() {
    _stopTimer();
    _mode = _Mode.menu;
    _menuIndex = 0;
  }

  // --- Input ---------------------------------------------------------------

  void _onKeypad(int key) {
    HapticFeedback.selectionClick();
    switch (key) {
      case 2:
        _onDirection(Direction.up);
      case 4:
        _onDirection(Direction.left);
      case 6:
        _onDirection(Direction.right);
      case 8:
        _onDirection(Direction.down);
      case 5:
        _onOk();
    }
  }

  void _onDirection(Direction d) {
    setState(() {
      switch (_mode) {
        case _Mode.menu:
          _menuDirection(d);
        case _Mode.playing:
          _game.turn(d);
        case _Mode.paused:
          _game.turn(d);
          _resume();
        case _Mode.dying:
        case _Mode.gameOver:
          break;
      }
    });
  }

  void _menuDirection(Direction d) {
    switch (d) {
      case Direction.up:
        _menuIndex = (_menuIndex - 1) % menuItemCount;
      case Direction.down:
        _menuIndex = (_menuIndex + 1) % menuItemCount;
      case Direction.left:
      case Direction.right:
        final step = d == Direction.right ? 1 : -1;
        if (_menuIndex == 1) {
          _level = (_level - 1 + step) % 9 + 1;
          _saveSettings();
        } else if (_menuIndex == 2) {
          _walls = !_walls;
          _saveSettings();
        }
    }
  }

  void _onOk() {
    setState(() {
      switch (_mode) {
        case _Mode.menu:
          switch (_menuIndex) {
            case 0:
              _startGame();
            case 1:
              _level = _level % 9 + 1;
              _saveSettings();
            case 2:
              _walls = !_walls;
              _saveSettings();
          }
        case _Mode.playing:
          _pause();
        case _Mode.paused:
          _resume();
        case _Mode.dying:
          break;
        case _Mode.gameOver:
          _toMenu();
      }
    });
  }

  /// On-screen BACK: leave the current game and return to the menu.
  void _onBackButton() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_mode == _Mode.playing || _mode == _Mode.paused) {
        _recordScore();
      }
      _toMenu();
    });
  }

  String get _okLabel => switch (_mode) {
        _Mode.menu => 'SELECT',
        _Mode.playing => 'PAUSE',
        _Mode.paused => 'RESUME',
        _Mode.dying || _Mode.gameOver => 'OK',
      };

  void _onBack() {
    setState(() {
      switch (_mode) {
        case _Mode.playing:
          _pause();
        case _Mode.paused:
        case _Mode.gameOver:
          _toMenu();
        case _Mode.menu:
        case _Mode.dying:
          break;
      }
    });
  }

  KeyEventResult _onHardwareKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final direction = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => Direction.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => Direction.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => Direction.left,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => Direction.right,
      _ => null,
    };
    if (direction != null) {
      _onDirection(direction);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.select) {
      _onOk();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _swipeDelta += details.delta;
    final dx = _swipeDelta.dx;
    final dy = _swipeDelta.dy;
    if (dx.abs() < _swipeThreshold && dy.abs() < _swipeThreshold) return;
    if (dx.abs() > dy.abs()) {
      _onDirection(dx > 0 ? Direction.right : Direction.left);
    } else {
      _onDirection(dy > 0 ? Direction.down : Direction.up);
    }
    // Reset so a single continuous drag can chain several turns.
    _swipeDelta = Offset.zero;
  }

  // --- Rendering -----------------------------------------------------------

  void _drawScene(LcdCanvas c) {
    switch (_mode) {
      case _Mode.menu:
        drawMenu(c,
            selected: _menuIndex,
            level: _level,
            walls: _walls,
            highScore: _highScore);
      case _Mode.playing:
        drawGame(c, _game, progress: _progress);
      case _Mode.paused:
        drawGame(c, _game, progress: _progress);
        drawPaused(c);
      case _Mode.dying:
        drawGame(c, _game, showSnake: _frame.isOdd);
      case _Mode.gameOver:
        drawGameOver(c,
            score: _game.score,
            highScore: _highScore,
            newRecord: _newRecord,
            won: _game.isWon,
            frame: _frame);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bodyBottom,
      ),
      child: PopScope(
        canPop: _mode == _Mode.menu,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _onHardwareKey,
          child: Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bodyTop, _bodyBottom],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(child: Center(child: _buildScreen())),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: (screenHeight * 0.36).clamp(230.0, 330.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Keypad(
                          onKey: _onKeypad,
                          onBack: _onBackButton,
                          backEnabled: _mode != _Mode.menu,
                          okLabel: _okLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1218),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3B4A57), width: 2),
        ),
        child: AspectRatio(
          aspectRatio: LcdLayout.totalWidth / LcdLayout.totalHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_mode != _Mode.playing) _onOk();
            },
            onPanStart: (_) => _swipeDelta = Offset.zero,
            onPanUpdate: _onPanUpdate,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const RadialGradient(
                  radius: 1.1,
                  colors: [LcdColors.background, LcdColors.backgroundDim],
                ),
              ),
              child: CustomPaint(
                painter: LcdPainter(
                  _drawScene,
                  devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                  repaint: _repaint,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
