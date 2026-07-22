import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_category.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/meal_filter_provider.dart';

/// Thanh chip lọc theo danh mục — mỗi [scope] độc lập.
class MealFilterBar extends ConsumerWidget {
  const MealFilterBar({
    super.key,
    required this.scope,
    this.enabled = true,
  });

  final MealFilterScope scope;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mealCategoryFilterProvider(scope));
    final filter = ref.read(mealCategoryFilterProvider(scope).notifier);
    final scheme = Theme.of(context).colorScheme;
    final allSelected = selected.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.filter_alt_outlined,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: allSelected,
                  enabled: enabled,
                  onSelected: () => filter.clear(),
                ),
                for (final category in MealCategory.values)
                  _FilterChip(
                    label: category.label,
                    selected: selected.contains(category),
                    enabled: enabled,
                    onSelected: () => filter.toggle(category),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        onSelected: enabled ? (_) => onSelected() : null,
        selectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }
}
