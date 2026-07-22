import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/primary_app_bar.dart';
import '../providers/meals_provider.dart';
import '../widgets/add_meal_sheet.dart';

/// Màn hình quản lý món — bật/tắt realtime + thêm/sửa món.
class MealManagementScreen extends ConsumerStatefulWidget {
  const MealManagementScreen({super.key});

  @override
  ConsumerState<MealManagementScreen> createState() =>
      _MealManagementScreenState();
}

class _MealManagementScreenState extends ConsumerState<MealManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MealModel> _filterMeals(List<MealModel> meals) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return meals;

    return meals.where((meal) {
      if (meal.name.toLowerCase().contains(q)) return true;
      if (meal.category.label.toLowerCase().contains(q)) return true;
      if (meal.tags.any((tag) => tag.toLowerCase().contains(q))) return true;
      if (meal.ingredients.any((ing) => ing.toLowerCase().contains(q))) {
        return true;
      }
      return false;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      appBar: const PrimaryAppBar(title: 'Quản lý món ăn'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final added = await MealFormSheet.show(context);
          if (!mounted || added != true) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đã thêm món mới'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
      body: mealsAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppEmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được danh sách',
          message: ErrorMessages.forUser(error),
        ),
        data: (meals) {
          final scheme = Theme.of(context).colorScheme;
          if (meals.isEmpty) {
            return const AppEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'Chưa có món nào',
              message: 'Bấm "Thêm món" để bắt đầu xây danh sách.',
            );
          }

          final filtered = _filterMeals(meals);
          final enabledCount = meals.where((m) => m.isEnabled).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm món, tag, nguyên liệu...',
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
                        fillColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MealStatsBanner(
                      enabledCount: enabledCount,
                      totalCount: meals.length,
                      filteredCount:
                          _query.trim().isEmpty ? null : filtered.length,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'Không tìm thấy món khớp "$_query".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          100,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          return _MealListTile(meal: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MealStatsBanner extends StatelessWidget {
  const _MealStatsBanner({
    required this.enabledCount,
    required this.totalCount,
    this.filteredCount,
  });

  final int enabledCount;
  final int totalCount;
  final int? filteredCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = totalCount == 0 ? 0.0 : enabledCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filteredCount == null
                      ? '$enabledCount/$totalCount món đang bật'
                      : 'Tìm thấy $filteredCount/$totalCount món',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealListTile extends ConsumerStatefulWidget {
  const _MealListTile({required this.meal});

  final MealModel meal;

  @override
  ConsumerState<_MealListTile> createState() => _MealListTileState();
}

class _MealListTileState extends ConsumerState<_MealListTile> {
  bool _isUpdating = false;

  Future<void> _onToggle(bool value) async {
    if (_isUpdating) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);
    try {
      await ref.read(mealRepositoryProvider).setEnabled(
            mealId: widget.meal.id,
            isEnabled: value,
          );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorMessages.forUser(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _onEdit() async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await MealFormSheet.show(context, meal: widget.meal);
    if (!mounted || saved != true) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật món ăn'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món?'),
        content: Text('Bạn có chắc muốn xóa "${widget.meal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(mealRepositoryProvider).deleteMeal(widget.meal.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${widget.meal.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorMessages.forUser(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: _onEdit,
        leading: CircleAvatar(
          backgroundColor: meal.isEnabled
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Icon(
            Icons.restaurant,
            color: meal.isEnabled
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          meal.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: meal.isEnabled ? null : scheme.outline,
            decoration:
                meal.isEnabled ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          [
            meal.category.label,
            if (meal.ingredients.isNotEmpty)
              '${meal.ingredients.length} NL',
            if (meal.tags.isNotEmpty) meal.tags.take(2).join(' · '),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUpdating)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: meal.isEnabled,
                onChanged: _onToggle,
              ),
            PopupMenuButton<String>(
              tooltip: 'Thêm',
              onSelected: (value) {
                if (value == 'edit') _onEdit();
                if (value == 'delete') _onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
