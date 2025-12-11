import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const PremiumTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<PremiumTile> createState() => _PremiumTileState();
}

class _PremiumTileState extends State<PremiumTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Future.delayed(const Duration(milliseconds: 10), widget.onTap);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // GLASS BACKDROP
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ⭐ ICON — Soft Blue Accent
                      Icon(
                        widget.icon,
                        size: 24,
                        color: const Color(0xFFAEE5FF), // <— SENİN MAVİ ACCENT
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // RIGHT ARROW — soft white
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              // PRESSED OVERLAY
              if (_pressed)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
