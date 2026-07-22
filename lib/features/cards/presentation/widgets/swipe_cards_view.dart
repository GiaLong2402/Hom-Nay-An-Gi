import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/services/sfx_service.dart';
import '../../../../core/theme/app_spacing.dart';
import 'meal_card_face.dart';

/// Chế độ quẹt thẻ kiểu Tinder.
class SwipeCardsView extends ConsumerStatefulWidget {
  const SwipeCardsView({
    super.key,
    required this.meals,
    required this.onLiked,
    required this.onDeckFinished,
  });

  final List<MealModel> meals;
  final ValueChanged<MealModel> onLiked;
  final VoidCallback onDeckFinished;

  @override
  ConsumerState<SwipeCardsView> createState() => _SwipeCardsViewState();
}

class _SwipeCardsViewState extends ConsumerState<SwipeCardsView> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    ref.read(sfxServiceProvider).onCardSwipe();
    if (direction == CardSwiperDirection.right) {
      widget.onLiked(widget.meals[previousIndex]);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            key: ValueKey(widget.meals.map((m) => m.id).join(',')),
            controller: _controller,
            cardsCount: widget.meals.length,
            numberOfCardsDisplayed:
                widget.meals.length >= 3 ? 3 : widget.meals.length,
            allowedSwipeDirection:
                const AllowedSwipeDirection.symmetric(horizontal: true),
            backCardOffset: const Offset(0, 28),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            onSwipe: _onSwipe,
            onEnd: widget.onDeckFinished,
            cardBuilder: (
              context,
              index,
              horizontalThresholdPercentage,
              verticalThresholdPercentage,
            ) {
              return MealCardFace(meal: widget.meals[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: Theme.of(context).colorScheme.error,
                label: 'Bỏ qua',
                onPressed: () {
                  ref.read(sfxServiceProvider).onCardSwipe();
                  _controller.swipe(CardSwiperDirection.left);
                },
              ),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: Theme.of(context).colorScheme.primary,
                label: 'Thích',
                onPressed: () {
                  ref.read(sfxServiceProvider).onCardSwipe();
                  _controller.swipe(CardSwiperDirection.right);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(18),
            ),
            onPressed: onPressed,
            child: Icon(icon, size: 28),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
