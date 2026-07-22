import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/pantry_ingredients.dart';
import '../providers/pantry_provider.dart';

/// Chọn nguyên liệu: tìm kiếm + nhóm gọn, không còn đống chip rối.
class IngredientPicker extends ConsumerStatefulWidget {
  const IngredientPicker({super.key});

  @override
  ConsumerState<IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends ConsumerState<IngredientPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PantryGroup> _visibleGroups(List<PantryGroup> allGroups) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return allGroups;

    return [
      for (final group in allGroups)
        if (group.items.any((item) => item.toLowerCase().contains(q)))
          PantryGroup(
            id: group.id,
            label: group.label,
            items: group.items
                .where((item) => item.toLowerCase().contains(q))
                .toList(growable: false),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(pantrySelectionProvider);
    final notifier = ref.read(pantrySelectionProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final allGroups = ref.watch(pantryIngredientGroupsProvider);
    final groups = _visibleGroups(allGroups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm nguyên liệu...',
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SelectedSummary(
            selected: selected.toList()..sort(),
            onClear: notifier.clear,
            onRemove: notifier.toggle,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Không tìm thấy nguyên liệu phù hợp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (var i = 0; i < groups.length; i++)
            _CollapsibleGroup(
              key: ValueKey('pantry_${groups[i].id}_$_query'),
              group: groups[i],
              selected: selected,
              initiallyExpanded: _query.isNotEmpty || i == 0,
              onToggle: notifier.toggle,
            ),
      ],
    );
  }
}

class _CollapsibleGroup extends StatelessWidget {
  const _CollapsibleGroup({
    super.key,
    required this.group,
    required this.selected,
    required this.initiallyExpanded,
    required this.onToggle,
  });

  final PantryGroup group;
  final Set<String> selected;
  final bool initiallyExpanded;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedInGroup = group.items.where(selected.contains).length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              selectedInGroup > 0
                  ? '$selectedInGroup/${group.items.length}'
                  : '${group.items.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selectedInGroup > 0
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in group.items)
                  _IngredientPill(
                    label: item,
                    selected: selected.contains(item),
                    onTap: () => onToggle(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.selected,
    required this.onClear,
    required this.onRemove,
  });

  final List<String> selected;
  final VoidCallback onClear;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đã chọn ${selected.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: scheme.primary,
                ),
                child: const Text('Xóa hết'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in selected)
                InputChip(
                  label: Text(item),
                  onDeleted: () => onRemove(item),
                  deleteIconColor: scheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: scheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primary
          : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
