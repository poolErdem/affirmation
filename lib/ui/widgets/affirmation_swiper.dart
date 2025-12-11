import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/widgets/affirmation_card.dart';

class AffirmationSwiper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentIndex = appState.currentIndex;

    // PageView’i state ile senkronize et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients && controller.page?.round() != currentIndex) {
        controller.jumpToPage(currentIndex);
      }
    });

    return SizedBox.expand(
      child: PageView.builder(
        key: ValueKey(controller),
        controller: controller,
        scrollDirection: Axis.vertical,
        physics: const SmoothPagePhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: items.length,
        onPageChanged: (index) {
          onPageChanged(index);
          actionAnim.forward(from: 0);
        },
        itemBuilder: (_, index) {
          final aff = items[index];

          return Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: AffirmationAnimatedItem(
                key: ValueKey(aff.id),
                child: AffirmationCard(
                  affirmation: aff,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////
/// ⭐ PREMIUM ANIMASYON YAPAN WIDGET
/// affirmation değiştiğinde:
/// - Eski affirmation yukarı kayarak kaybolur
/// - Yeni affirmation alttan yukarı kayarak gelir
//////////////////////////////////////////////////////////////////////////

class AffirmationAnimatedItem extends StatelessWidget {
  final Widget child;

  const AffirmationAnimatedItem({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        // Yeni gelen affirmation → alttan yukarı
        final inAnimation = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation);

        // Giden affirmation → yukarı kayıp kaybolur
        final outAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -0.35),
        ).animate(animation);

        bool isIncoming = widget.key == child.key;

        return SlideTransition(
          position: isIncoming ? inAnimation : outAnimation,
          child: FadeTransition(
            opacity: isIncoming ? animation : ReverseAnimation(animation),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

//////////////////////////////////////////////////////////////////////////
/// ⭐ SMOOTH PAGE PHYSICS – NE ÇOK YAVAŞ NE ÇOK HIZLI
//////////////////////////////////////////////////////////////////////////

class SmoothPagePhysics extends PageScrollPhysics {
  const SmoothPagePhysics({super.parent});

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * 0.90; // Smooth & premium hız
  }

  @override
  double get dragStartDistanceMotionThreshold =>
      6.0; // gereksiz hassasiyeti engeller
}
