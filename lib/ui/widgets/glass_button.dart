import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  final double borderRadius;
  final double blur;

  const GlassButton({
    super.key,
    required this.text,
    required this.onTap,
    this.borderRadius = 20,
    this.blur = 14,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Premium breathing effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),

                // PREMIUM GOLD GLOW
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC9A85D).withValues(alpha: 0.40),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],

                // Inner gold shine + glass effect
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x33FFFFFF),
                    Color(0x11FFFFFF),
                  ],
                ),
              ),

              // GOLD BORDER (bizim premium border tonu)
              foregroundDecoration: GradientOutline(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFC9A85D), // soft gold
                    Color(0xFFE4C98A), // bright gold
                  ],
                ),
                strokeWidth: 1.7,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),

              child: Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Color(0xFFE4C98A),
                        blurRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PREMIUM GOLD OUTLINE BORDER
class GradientOutline extends Decoration {
  final Gradient gradient;
  final double strokeWidth;
  final BorderRadius borderRadius;

  const GradientOutline({
    required this.gradient,
    this.strokeWidth = 2,
    required this.borderRadius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientOutlinePainter(
      gradient: gradient,
      strokeWidth: strokeWidth,
      borderRadius: borderRadius,
    );
  }
}

class _GradientOutlinePainter extends BoxPainter {
  final Gradient gradient;
  final double strokeWidth;
  final BorderRadius borderRadius;

  _GradientOutlinePainter({
    required this.gradient,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    if (config.size == null) return;

    final rect = offset & config.size!;
    final rrect = borderRadius.toRRect(rect).deflate(strokeWidth / 2);

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }
}
