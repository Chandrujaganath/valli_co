// lib/widgets/neumorphic_button.dart
import 'package:flutter/material.dart';

class NeumorphicButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const NeumorphicButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 50,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F1F1F)
              : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? [
                  // Inner shadow
                  BoxShadow(
                    color: Colors.black26,
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  // Outer shadow
                  BoxShadow(
                    color: Colors.black26,
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool val) {
    setState(() {
      _isPressed = val;
    });
  }
}
