import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/widgets/affirmation_card.dart';

class AffirmationSwiper extends StatefulWidget {
  final List items;
  final PageController controller;
  final void Function(int index) onPageChanged;
  final AnimationController actionAnim;

  const AffirmationSwiper({
    super.key,
    required this.items,
    required this.controller,
    required this.onPageChanged,
    required this.actionAnim,
  });

  @override
  State<AffirmationSwiper> createState() => _AffirmationSwiperState();
}

class _AffirmationSwiperState extends State<AffirmationSwiper> {
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentIndex = appState.currentIndex;

    // PageController'ı state ile eşitle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients &&
          widget.controller.page?.round() != currentIndex &&
          !_isAnimating) {
        widget.controller.jumpToPage(currentIndex);
      }
    });

    return GestureDetector(
      onVerticalDragEnd: (details) async {
        if (_isAnimating) return;

        final velocity = details.primaryVelocity ?? 0;

        if (velocity < -500 && currentIndex < widget.items.length - 1) {
          // Yukarı swipe - sonraki sayfa
          setState(() {
            _isAnimating = true;
          });

          await widget.controller.animateToPage(
            currentIndex + 1,
            duration: const Duration(milliseconds: 600), // Hız ayarı
            curve: Curves.easeInOutCubic,
          );

          widget.onPageChanged(currentIndex + 1);
          widget.actionAnim.forward(from: 0);

          setState(() {
            _isAnimating = false;
          });
        } else if (velocity > 500 && currentIndex > 0) {
          // Aşağı swipe - önceki sayfa
          setState(() {
            _isAnimating = true;
          });

          await widget.controller.animateToPage(
            currentIndex - 1,
            duration: const Duration(milliseconds: 150), // Hız ayarı
            curve: Curves.easeInOutCubic,
          );

          widget.onPageChanged(currentIndex - 1);
          widget.actionAnim.forward(from: 0);

          setState(() {
            _isAnimating = false;
          });
        }
      },
      child: SizedBox.expand(
        child: PageView.builder(
          key: ValueKey(widget.controller),
          controller: widget.controller,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(), // Manuel kontrol
          itemCount: widget.items.length,
          itemBuilder: (_, index) {
            final aff = widget.items[index];

            return Center(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height, // Tam ekran yüksekliği
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.52,
                    child: AffirmationCard(affirmation: aff),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
