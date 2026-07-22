import 'package:flutter/material.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Dialog kết quả sau khi vòng quay dừng.
class MealResultDialog extends StatelessWidget {
  const MealResultDialog({
    super.key,
    required this.meal,
    required this.onSpinAgain,
    required this.onConfirm,
    required this.onContinueBattle,
  });

  final MealModel meal;
  final VoidCallback onSpinAgain;
  final VoidCallback onConfirm;
  final VoidCallback onContinueBattle;

  static Future<void> show(
    BuildContext context, {
    required MealModel meal,
    required VoidCallback onSpinAgain,
    required VoidCallback onConfirm,
    required VoidCallback onContinueBattle,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MealResultDialog(
        meal: meal,
        onSpinAgain: onSpinAgain,
        onConfirm: onConfirm,
        onContinueBattle: onContinueBattle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.seed, scheme.tertiary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.seed.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Hôm nay ăn',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              meal.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                meal.category.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const Text('Chốt món này'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinueBattle();
                },
                child: const Text('Mang sang Đấu kép'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSpinAgain();
                },
                child: const Text('Xoay lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
