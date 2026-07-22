import 'package:flutter/material.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';

/// Thẻ món trong trận đấu kép.
class BattleMealCard extends StatelessWidget {
  const BattleMealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.highlight = false,
  });

  final MealModel meal;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [scheme.primary, scheme.tertiary]
                  : [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
            ),
            border: Border.all(
              color: highlight ? scheme.primary : scheme.outlineVariant,
              width: highlight ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 40,
                  color: highlight ? Colors.white : scheme.onPrimaryContainer,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  meal.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: highlight ? Colors.white : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: highlight
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    meal.category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: highlight ? scheme.primary : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Chọn món này',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: highlight
                            ? Colors.white.withValues(alpha: 0.9)
                            : scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
