import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_app_bar.dart';
import '../../../meals/presentation/providers/meal_filter_provider.dart';
import '../../../meals/presentation/widgets/meal_filter_bar.dart';
import '../widgets/swipe_cards_view.dart';

/// Màn hình TinderFood — quẹt chọn món (Tinder style).
class RandomCardsScreen extends ConsumerStatefulWidget {
  const RandomCardsScreen({super.key});

  @override
  ConsumerState<RandomCardsScreen> createState() => _RandomCardsScreenState();
}

class _RandomCardsScreenState extends ConsumerState<RandomCardsScreen> {
  int _deckVersion = 0;
  String _sourceKey = '';
  List<MealModel> _deck = const [];
  bool _deckFinished = false;

  void _onLiked(MealModel meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chốt: ${meal.name}. Ngon miệng nhé!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _syncDeck(List<MealModel> meals) {
    final nextKey = '${meals.map((m) => m.id).join(',')}|$_deckVersion';
    if (nextKey == _sourceKey) return;
    _sourceKey = nextKey;
    _deck = List<MealModel>.from(meals)..shuffle();
    _deckFinished = false;
  }

  void _reshuffle() {
    setState(() {
      _deckVersion++;
      _deckFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync =
        ref.watch(filteredEnabledMealsProvider(MealFilterScope.cards));
    final hasFilter =
        ref.watch(mealCategoryFilterProvider(MealFilterScope.cards)).isNotEmpty;

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'TinderFood',
        actions: [
          IconButton(
            tooltip: 'Xáo lại bộ bài',
            onPressed: _reshuffle,
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: MealFilterBar(scope: MealFilterScope.cards),
          ),
          Expanded(
            child: mealsAsync.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Không tải được thẻ bài',
                message: ErrorMessages.forUser(error),
              ),
              data: (meals) {
                if (meals.isEmpty) {
                  return _EmptyCardsView(hasFilter: hasFilter);
                }

                _syncDeck(meals);

                if (_deckFinished || _deck.isEmpty) {
                  return _DeckFinishedView(onReshuffle: _reshuffle);
                }

                return KeyedSubtree(
                  key: ValueKey(_sourceKey),
                  child: SwipeCardsView(
                    meals: _deck,
                    onLiked: _onLiked,
                    onDeckFinished: () {
                      setState(() => _deckFinished = true);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckFinishedView extends StatelessWidget {
  const _DeckFinishedView({required this.onReshuffle});

  final VoidCallback onReshuffle;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.style_outlined,
      title: 'Hết thẻ rồi',
      message: 'Bạn đã quẹt hết bộ bài hiện tại.\nBấm xáo bài để chọn món.',
      action: FilledButton.icon(
        onPressed: onReshuffle,
        icon: const Icon(Icons.shuffle_rounded),
        label: const Text('Xáo bài lại'),
      ),
    );
  }
}

class _EmptyCardsView extends ConsumerWidget {
  const _EmptyCardsView({this.hasFilter = false});

  final bool hasFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppEmptyState(
      icon: Icons.style_outlined,
      title: hasFilter
          ? 'Không có món khớp bộ lọc'
          : 'Chưa có món đang bật',
      message: hasFilter
          ? 'Chọn thêm danh mục hoặc bấm "Tất cả".'
          : 'Vào tab Quản lý để bật ít nhất 1 món.',
      action: hasFilter
          ? OutlinedButton(
              onPressed: () => ref
                  .read(
                    mealCategoryFilterProvider(MealFilterScope.cards).notifier,
                  )
                  .clear(),
              child: const Text('Xóa bộ lọc'),
            )
          : null,
    );
  }
}
