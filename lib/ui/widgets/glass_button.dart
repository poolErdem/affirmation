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
    this.borderRadius = 50,
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

    // Premium "breathing" pulse animation
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
              HapticFeedback.mediumImpact(); // premium hissiyat
              widget.onTap();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),

              // Glow + gradient shine
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),

                // Outer glow + white aura
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(71, 255, 193, 7), // amber glow %28
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Color.fromARGB(46, 255, 255, 255), // white aura %18
                    blurRadius: 12,
                    spreadRadius: -1,
                  ),
                ],

                // Inner glass shine
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(51, 255, 255, 255), // %20
                    Color.fromARGB(18, 255, 255, 255), // %7
                  ],
                ),
              ),

              // GOLD BORDER (foregroundDecoration yoksa gradient border olmuyor)
              foregroundDecoration: GradientOutline(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE8B8), // soft gold
                    Color(0xFFFFC878), // vivid gold
                  ],
                ),
                strokeWidth: 2,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),

              child: Center(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
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

/// GOLD GRADIENT OUTLINE BORDER (BoxBorder kullanılmıyor → override hatası YOK)
class GradientOutline extends Decoration {
  final Gradient gradient;
  final double strokeWidth;
  final BorderRadius borderRadius;

  const GradientOutline({
    required this.gradient,
    this.strokeWidth = 2,
    this.borderRadius = BorderRadius.zero,
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

    final Rect rect = offset & config.size!;
    final RRect rrect = borderRadius.toRRect(rect).deflate(strokeWidth / 2);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }
}
