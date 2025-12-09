import 'dart:ui';
import 'package:affirmation/ui/widgets/video_bg.dart';
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
    final isVideo = imageAsset.toLowerCase().endsWith(".mp4");

    return Stack(
      children: [
        Positioned.fill(
          child: isVideo
              ? VideoBg(assetPath: imageAsset)
              : Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
        ),

        // Blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),

        child,
      ],
    );
  }
}
