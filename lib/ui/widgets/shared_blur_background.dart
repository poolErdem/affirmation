import 'dart:ui';
import 'package:flutter/material.dart';

class SharedBlurBackground extends StatelessWidget {
  final String imageAsset;
  final Widget child;

  const SharedBlurBackground({
    super.key,
    required this.imageAsset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ana ekrandaki aynı görsel
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
          ),
        ),

        // BLUR (opacity yok!)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(color: Colors.transparent),
          ),
        ),

        // İçerik
        child,
      ],
    );
  }
}
