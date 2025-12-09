import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBg extends StatefulWidget {
  final String assetPath;

  const VideoBg({super.key, required this.assetPath});

  @override
  State<VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<VideoBg> {
  late VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _c.play();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _c.value.size.width,
          height: _c.value.size.height,
          child: VideoPlayer(_c),
        ),
      ),
    );
  }
}
