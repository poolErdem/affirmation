import 'package:flutter/widgets.dart';

class BounceOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceOnTap({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BounceOnTap> createState() => _BounceOnTapState();
}

class _BounceOnTapState extends State<BounceOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.85,
      upperBound: 1.0,
      vsync: this,
    )..value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: widget.child,
      ),
    );
  }
}
