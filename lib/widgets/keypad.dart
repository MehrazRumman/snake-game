import 'package:flutter/material.dart';

/// A 3x3 phone keypad. Keys 2/4/6/8 steer, 5 is OK/pause.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey});

  final ValueChanged<int> onKey;

  static const _subLabels = {
    2: Icons.keyboard_arrow_up,
    4: Icons.keyboard_arrow_left,
    6: Icons.keyboard_arrow_right,
    8: Icons.keyboard_arrow_down,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 3; col++)
                  Expanded(child: _buildKey(row * 3 + col + 1)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKey(int n) {
    final active = n.isEven || n == 5;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: _KeyButton(
        label: '$n',
        icon: _subLabels[n],
        subText: n == 5 ? 'OK' : null,
        enabled: active,
        onPressed: () => onKey(n),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
    this.icon,
    this.subText,
  });

  final String label;
  final IconData? icon;
  final String? subText;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1C2630);
    final base = widget.enabled ? const Color(0xFFE4EAEE) : const Color(0xFF9AA6AF);
    final color = _pressed ? const Color(0xFFAFBFC9) : base;

    // Fire on pointer down rather than tap-up: games need instant response.
    return Listener(
      onPointerDown: (_) {
        _setPressed(true);
        widget.onPressed();
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _pressed
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x88000000),
                    offset: Offset(0, 3),
                    blurRadius: 2,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.icon != null)
              Icon(widget.icon, color: textColor, size: 22),
            if (widget.subText != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  widget.subText!,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
