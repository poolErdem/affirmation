import 'package:flutter/material.dart';

class SnapScrollView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const SnapScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<SnapScrollView> createState() => _SnapScrollViewState();
}

class _SnapScrollViewState extends State<SnapScrollView> {
  final ScrollController _controller = ScrollController();
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    // NotificationListener kullanarak scroll bitişini dinle
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Snap işlemi devam ediyorsa bir şey yapma
    if (_isSnapping) return;

    // Kullanıcı hala scroll yapıyorsa bekle
    if (_controller.position.isScrollingNotifier.value) return;

    // Scroll momentum'u bitmişse snap yap
    _snapToNearestPage();
  }

  void _snapToNearestPage() async {
    if (_isSnapping) return;

    _isSnapping = true;

    final viewportHeight = MediaQuery.of(context).size.height * 0.70;
    final offset = _controller.offset;

    // En yakın sayfayı bul
    final targetPage = (offset / viewportHeight).round();
    final targetOffset = (targetPage * viewportHeight).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );

    // Zaten doğru pozisyondaysa snap yapma
    if ((offset - targetOffset).abs() < 1.0) {
      _isSnapping = false;
      return;
    }

    // Snap animasyonu
    await _controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );

    _isSnapping = false;
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height * 0.70;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Kullanıcı parmağını ekrandan kaldırdığında
        if (notification is ScrollEndNotification) {
          // Kısa bir gecikme ile snap yap (momentum bitsin)
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && !_isSnapping) {
              _snapToNearestPage();
            }
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: viewportHeight,
            child: widget.itemBuilder(context, index),
          );
        },
      ),
    );
  }
}
