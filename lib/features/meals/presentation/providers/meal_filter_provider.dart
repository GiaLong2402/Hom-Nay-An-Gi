import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/meal_category.dart';
import '../../../../core/models/meal_model.dart';
import 'meals_provider.dart';

/// Mỗi màn có bộ lọc riêng — không dùng chung.
enum MealFilterScope { wheel, battle, cards }

/// Bộ lọc danh mục theo từng màn.
/// Tập rỗng = không lọc (hiển thị tất cả món đang bật).
class MealCategoryFilter extends Notifier<Set<MealCategory>> {
  MealCategoryFilter(this.scope);

  final MealFilterScope scope;

  @override
  Set<MealCategory> build() => <MealCategory>{};

  void toggle(MealCategory category) {
    final next = {...state};
    if (!next.add(category)) {
      next.remove(category);
    }
    state = next;
  }

  void clear() => state = <MealCategory>{};

  void selectOnly(MealCategory category) => state = {category};
}

final mealCategoryFilterProvider = NotifierProvider.family<MealCategoryFilter,
    Set<MealCategory>, MealFilterScope>(
  MealCategoryFilter.new,
);

/// Món `isEnabled` sau khi áp dụng bộ lọc danh mục của [scope].
final filteredEnabledMealsProvider =
    Provider.family<AsyncValue<List<MealModel>>, MealFilterScope>((ref, scope) {
  final selected = ref.watch(mealCategoryFilterProvider(scope));

  return ref.watch(enabledMealsProvider).whenData((meals) {
    if (selected.isEmpty) return meals;
    return meals
        .where((meal) => selected.contains(meal.category))
        .toList(growable: false);
  });
});
