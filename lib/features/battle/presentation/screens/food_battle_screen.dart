import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_app_bar.dart';
import '../../../meals/presentation/providers/meal_filter_provider.dart';
import '../../../meals/presentation/widgets/meal_filter_bar.dart';
import '../widgets/battle_meal_card.dart';

/// Màn hình Đấu kép chọn món — knockout đến khi có vô địch.
class FoodBattleScreen extends ConsumerStatefulWidget {
  const FoodBattleScreen({super.key});

  @override
  ConsumerState<FoodBattleScreen> createState() => _FoodBattleScreenState();
}

class _FoodBattleScreenState extends ConsumerState<FoodBattleScreen> {
  MealModel? _champion;
  MealModel? _challenger;
  List<MealModel> _queue = const [];
  int _round = 0;
  int _totalFights = 0;
  bool _isFinished = false;
  String? _seedLabel;

  void _reset() {
    setState(() {
      _champion = null;
      _challenger = null;
      _queue = const [];
      _round = 0;
      _totalFights = 0;
      _isFinished = false;
      _seedLabel = null;
    });
  }

  void _startBattle(List<MealModel> meals) {
    final shuffled = List<MealModel>.from(meals)..shuffle();
    if (shuffled.length < 2) return;

    setState(() {
      _totalFights = shuffled.length - 1;
      _champion = shuffled.first;
      _queue = shuffled.sublist(1);
      _challenger = _queue.removeAt(0);
      _round = 1;
      _isFinished = false;
      _seedLabel = null;
    });
  }

  /// Bắt đầu với món từ Vòng quay làm nhà vô địch tạm, đấu với các món còn lại.
  bool _startBattleWithSeed(List<MealModel> meals, MealModel seed) {
    final others = meals.where((m) => m.id != seed.id).toList()..shuffle();
    if (others.isEmpty) return false;

    setState(() {
      _totalFights = others.length;
      _champion = seed;
      _queue = others;
      _challenger = _queue.removeAt(0);
      _round = 1;
      _isFinished = false;
      _seedLabel = seed.name;
    });
    return true;
  }

  void _tryConsumeSeed(List<MealModel> meals) {
    final seed = ref.read(battleSeedProvider);
    if (seed == null) return;

    final started = _startBattleWithSeed(meals, seed);
    ref.read(battleSeedProvider.notifier).clear();

    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cần thêm đối thủ trong bộ lọc Đấu kép để tiếp tục.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _pickWinner(MealModel winner) {
    if (_isFinished || _challenger == null) return;

    if (_queue.isEmpty) {
      setState(() {
        _champion = winner;
        _challenger = null;
        _isFinished = true;
      });
      _showChampionDialog(winner);
      return;
    }

    setState(() {
      _champion = winner;
      _challenger = _queue.removeAt(0);
      _round++;
    });
  }

  Future<void> _showChampionDialog(MealModel meal) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Vô địch hôm nay!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 64, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                meal.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                meal.category.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reset();
              },
              child: const Text('Đấu lại'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Đã chốt: ${meal.name}. Ngon miệng nhé!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _reset();
              },
              child: const Text('Chốt món này'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync =
        ref.watch(filteredEnabledMealsProvider(MealFilterScope.battle));
    final scheme = Theme.of(context).colorScheme;
    final inBattle = _champion != null && _challenger != null && !_isFinished;

    ref.listen<MealModel?>(battleSeedProvider, (previous, next) {
      if (next == null) return;
      final meals = ref
          .read(filteredEnabledMealsProvider(MealFilterScope.battle))
          .asData
          ?.value;
      if (meals == null || meals.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryConsumeSeed(meals);
      });
    });

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Đấu kép chọn món',
        actions: [
          if (inBattle || _isFinished)
            IconButton(
              tooltip: 'Đấu lại',
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: MealFilterBar(
              scope: MealFilterScope.battle,
              enabled: !inBattle,
            ),
          ),
          Expanded(
            child: mealsAsync.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Không tải được món',
                message: ErrorMessages.forUser(error),
              ),
              data: (meals) {
                // Nếu vừa mang món từ vòng quay sang khi màn đã sẵn sàng.
                final pendingSeed = ref.read(battleSeedProvider);
                if (pendingSeed != null &&
                    !inBattle &&
                    !_isFinished &&
                    meals.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _tryConsumeSeed(meals);
                  });
                }

                if (meals.length < 2 && pendingSeed == null) {
                  return const AppEmptyState(
                    icon: Icons.sports_martial_arts_outlined,
                    title: 'Chưa đủ món để đấu',
                    message: 'Cần ít nhất 2 món đang bật để bắt đầu đấu kép.',
                  );
                }

                if (!inBattle && !_isFinished) {
                  return _StartView(
                    mealCount: meals.length,
                    onStart: () => _startBattle(meals),
                  );
                }

                if (_isFinished && _champion != null) {
                  return _ChampionView(
                    meal: _champion!,
                    onPlayAgain: _reset,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      if (_seedLabel != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'Tiếp tục từ vòng quay: $_seedLabel',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'Vòng $_round/$_totalFights',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _round / _totalFights,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Chạm món bạn thích hơn',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: BattleMealCard(
                                meal: _champion!,
                                highlight: true,
                                onTap: () => _pickWinner(_champion!),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Center(
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'VS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: BattleMealCard(
                                meal: _challenger!,
                                onTap: () => _pickWinner(_challenger!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _StartView extends StatelessWidget {
  const _StartView({
    required this.mealCount,
    required this.onStart,
  });

  final int mealCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.sports_martial_arts_rounded,
      title: 'Khó chọn quá?',
      message: 'Để $mealCount món đấu loại trực tiếp\ncho đến khi chọn ra vô địch.',
      action: FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Bắt đầu đấu'),
      ),
    );
  }
}

class _ChampionView extends StatelessWidget {
  const _ChampionView({
    required this.meal,
    required this.onPlayAgain,
  });

  final MealModel meal;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.seed, scheme.tertiary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.seed.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Vô địch hôm nay',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              meal.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              meal.category.label,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Đấu lại'),
            ),
          ],
        ),
      ),
    );
  }
}
