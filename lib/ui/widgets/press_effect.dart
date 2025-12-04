import 'package:flutter/material.dart';

class Pressable extends StatefulWidget {
  final Widget child;

  /// Optional: bir basılma rengi verebilirsin. Vermediğinde default sarı glow.
  final Color glowColor;

  const Pressable({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFE3A3), // GlassButton sarı tonu
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 0.99,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.glowColor,
                      blurRadius: 32,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
