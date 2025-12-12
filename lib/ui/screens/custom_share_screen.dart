import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CustomShareScreen extends StatefulWidget {
  final File imageFile;

  const CustomShareScreen({super.key, required this.imageFile});

  @override
  State<CustomShareScreen> createState() => _CustomShareScreenState();
}

class _CustomShareScreenState extends State<CustomShareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _isStoryMode = true;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 330),
    )..forward();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Image load error: $e");
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _anim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ARKA PLAN RESİM
            if (_imageBytes != null)
              if (_imageBytes != null)
                Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Image memory error: $error");
                    return Container(color: Colors.grey[900]);
                  },
                )
              else
                Container(color: Colors.grey[900]),

            // OVERLAY
            Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),

            // İÇERİK
            SafeArea(
              child: Column(
                children: [
                  // CLOSE BUTTON
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // BOTTOM SHEET
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 24,
                      bottom: 32,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TOGGLE BUTTONS
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _toggleButton("Story", _isStoryMode, () {
                                setState(() => _isStoryMode = true);
                              }),
                              _toggleButton("Square", !_isStoryMode, () {
                                setState(() => _isStoryMode = false);
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SHARE ICONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _shareIcon(
                              "Instagram\nStory",
                              "assets/icons/ig.png",
                              () => _share("ig"),
                            ),
                            _shareIcon(
                              "Facebook",
                              "assets/icons/fb.png",
                              () => _share("fb"),
                            ),
                            _shareIcon(
                              "Whatsapp",
                              "assets/icons/wa.png",
                              () => _share("wa"),
                            ),
                            _shareIcon(
                              "Wallpaper",
                              "assets/icons/lock.png",
                              _setWallpaper,
                            ),
                            _shareIcon(
                              "Other",
                              "assets/icons/more.png",
                              _nativeShare,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color:
              active ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _shareIcon(String label, String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                asset,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 28,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nativeShare() async {
    await Share.shareXFiles([XFile(widget.imageFile.path)]);
  }

  Future<void> _share(String platform) async {
    await Share.shareXFiles([XFile(widget.imageFile.path)]);
  }

  Future<void> _setWallpaper() async {
    debugPrint("set wallpaper TODO");
  }
}
