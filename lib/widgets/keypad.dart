import 'package:flutter/material.dart';

const _keyColor = Color(0xFFE4EAEE);
const _keyPressed = Color(0xFFAFBFC9);
const _keyText = Color(0xFF1C2630);
const _okColor = Color(0xFF3E5A36);
const _okPressed = Color(0xFF2C4226);
const _softColor = Color(0xFF33424F);
const _softPressed = Color(0xFF24303A);

/// Phone-style controls: two soft keys under the screen and a D-pad.
///
/// The D-pad reports the classic keypad numbers: 2/4/6/8 steer, 5 is OK.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    required this.onBack,
    required this.backEnabled,
    required this.okLabel,
  });

  final ValueChanged<int> onKey;
  final VoidCallback onBack;
  final bool backEnabled;

  /// Label for the right soft key, which mirrors the OK button.
  final String okLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: _SoftKey(
                  key: const ValueKey('key-back'),
                  label: 'BACK',
                  icon: Icons.arrow_back_rounded,
                  enabled: backEnabled,
                  onPressed: onBack,
                ),
              ),
              const Spacer(),
              Expanded(
                child: _SoftKey(
                  key: const ValueKey('key-soft-ok'),
                  label: okLabel,
                  enabled: true,
                  onPressed: () => onKey(5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _DPad(onKey: onKey)),
      ],
    );
  }
}

class _DPad extends StatelessWidget {
  const _DPad({required this.onKey});

  final ValueChanged<int> onKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size =
          (constraints.maxHeight / 3).clamp(0.0, constraints.maxWidth / 3.4);
      Widget arrow(int n, IconData icon) => _PadKey(
            key: ValueKey('key-$n'),
            onPressed: () => onKey(n),
            child: Icon(icon, size: size * 0.55, color: _keyText),
          );
      return Center(
        child: SizedBox(
          width: size * 3,
          height: size * 3,
          child: GridView.count(
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              const SizedBox.shrink(),
              arrow(2, Icons.keyboard_arrow_up_rounded),
              const SizedBox.shrink(),
              arrow(4, Icons.keyboard_arrow_left_rounded),
              _PadKey(
                key: const ValueKey('key-5'),
                color: _okColor,
                pressedColor: _okPressed,
                circular: true,
                onPressed: () => onKey(5),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: const Color(0xFFD9F5E3),
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              arrow(6, Icons.keyboard_arrow_right_rounded),
              const SizedBox.shrink(),
              arrow(8, Icons.keyboard_arrow_down_rounded),
              const SizedBox.shrink(),
            ],
          ),
        ),
      );
    });
  }
}

/// Fires on pointer down rather than tap-up: games need instant response.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onPressed,
    required this.builder,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final Widget Function(bool pressed) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled
          ? (_) {
              _setPressed(true);
              widget.onPressed();
            }
          : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: widget.builder(_pressed),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = _keyColor,
    this.pressedColor = _keyPressed,
    this.circular = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final Color pressedColor;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: _Pressable(
        onPressed: onPressed,
        builder: (pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? pressedColor : color,
            shape: circular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circular ? null : BorderRadius.circular(18),
            boxShadow: pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 3),
                      blurRadius: 3,
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftKey extends StatelessWidget {
  const _SoftKey({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? const Color(0xFFE4EAEE) : const Color(0xFF5E6E7B);
    return _Pressable(
      enabled: enabled,
      onPressed: onPressed,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: pressed ? _softPressed : _softColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF465867)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
