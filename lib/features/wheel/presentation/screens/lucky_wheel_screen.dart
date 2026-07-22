import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/sfx_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_app_bar.dart';
import '../../../meals/presentation/providers/meal_filter_provider.dart';
import '../../../meals/presentation/widgets/meal_filter_bar.dart';
import '../widgets/meal_result_dialog.dart';

/// Màn hình Chiếc nón may mắn — chọn ngẫu nhiên món đã lọc.
class LuckyWheelScreen extends ConsumerStatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  ConsumerState<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends ConsumerState<LuckyWheelScreen> {
  final StreamController<int> _selectedController =
      StreamController<int>.broadcast();

  bool _isSpinning = false;
  int? _pendingIndex;

  static const _sliceColors = AppTheme.wheelPalette;

  @override
  void dispose() {
    _selectedController.close();
    super.dispose();
  }

  void _spin(List<MealModel> meals) {
    if (_isSpinning || meals.length < 2) return;

    final index = Fortune.randomInt(0, meals.length);
    setState(() {
      _isSpinning = true;
      _pendingIndex = index;
    });
    ref.read(sfxServiceProvider).startWheelSpinning();
    _selectedController.add(index);
  }

  Future<void> _onSpinEnd(List<MealModel> meals) async {
    final index = _pendingIndex;
    if (index == null || index < 0 || index >= meals.length) {
      ref.read(sfxServiceProvider).stopWheelSpinning();
      setState(() => _isSpinning = false);
      return;
    }

    final meal = meals[index];
    await ref.read(sfxServiceProvider).playWheelWin();
    setState(() {
      _isSpinning = false;
      _pendingIndex = null;
    });

    if (!mounted) return;

    await MealResultDialog.show(
      context,
      meal: meal,
      onSpinAgain: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _spin(meals);
        });
      },
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chốt: ${meal.name}. Ngon miệng nhé!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onContinueBattle: () {
        ref.read(battleSeedProvider.notifier).setSeed(meal);
        ref.read(homeTabIndexProvider.notifier).goTo(kBattleTabIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đang đưa "${meal.name}" sang Đấu kép — chọn tiếp đến khi ưng ý!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(filteredEnabledMealsProvider(MealFilterScope.wheel));
    final hasFilter =
        ref.watch(mealCategoryFilterProvider(MealFilterScope.wheel)).isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Chiếc nón may mắn'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: MealFilterBar(
                scope: MealFilterScope.wheel,
                enabled: !_isSpinning,
              ),
            ),
            Expanded(
              child: mealsAsync.when(
                loading: () => const AppLoading(),
                error: (error, _) =>
                    _ErrorView(error: error),
                data: (meals) {
                  if (meals.length < 2) {
                    return _EmptyEnabledMealsView(hasFilter: hasFilter);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Không biết ăn gì?',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          hasFilter
                              ? '${meals.length} món khớp bộ lọc — để vòng quay chọn giúp bạn'
                              : '${meals.length} món đang bật — để vòng quay chọn giúp bạn',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: GestureDetector(
                              onTap: _isSpinning ? null : () => _spin(meals),
                              child: FortuneWheel(
                                key: ValueKey(
                                  meals.map((m) => m.id).join(','),
                                ),
                                animateFirst: false,
                                selected: _selectedController.stream,
                                rotationCount: 6,
                                duration: const Duration(seconds: 4),
                                onFling: _isSpinning
                                    ? null
                                    : () => _spin(meals),
                                indicators: [
                                  FortuneIndicator(
                                    alignment: Alignment.topCenter,
                                    child: TriangleIndicator(
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                                onAnimationEnd: () => _onSpinEnd(meals),
                                items: [
                                  for (var i = 0; i < meals.length; i++)
                                    FortuneItem(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          meals[i].name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize:
                                                meals.length > 16 ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      style: FortuneItemStyle(
                                        color: _sliceColors[
                                            i % _sliceColors.length],
                                        borderColor: Colors.white,
                                        borderWidth: 1.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed:
                                _isSpinning ? null : () => _spin(meals),
                            icon: Icon(
                              _isSpinning
                                  ? Icons.hourglass_top_rounded
                                  : Icons.casino_rounded,
                            ),
                            label: Text(
                              _isSpinning ? 'Đang xoay...' : 'Xoay',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEnabledMealsView extends ConsumerWidget {
  const _EmptyEnabledMealsView({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppEmptyState(
      icon: Icons.casino_outlined,
      title: hasFilter
          ? 'Bộ lọc chưa đủ món'
          : 'Cần ít nhất 2 món để quay',
      message: hasFilter
          ? 'Chọn thêm danh mục hoặc bấm "Tất cả".'
          : 'Vào tab Quản lý và bật thêm món.',
      action: hasFilter
          ? OutlinedButton(
              onPressed: () => ref
                  .read(
                    mealCategoryFilterProvider(MealFilterScope.wheel).notifier,
                  )
                  .clear(),
              child: const Text('Xóa bộ lọc'),
            )
          : null,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Không tải được món ăn',
      message: ErrorMessages.forUser(error),
    );
  }
}
