import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/models/meal_model.dart';
import '../../../meals/presentation/providers/meals_provider.dart';
import '../../data/gemini_meal_service.dart';
import '../../data/pantry_ingredient_classifier.dart';
import '../../data/pantry_ingredients.dart';

final geminiMealServiceProvider = Provider<GeminiMealService>((ref) {
  return GeminiMealService();
});

const _kCustomPantryIngredients = 'custom_pantry_ingredients_v2';
const _kCustomPantryIngredientsLegacy = 'custom_pantry_ingredients';

/// Nguyên liệu người dùng tự thêm — đã gắn nhóm (protein/carb/veggie/spice).
class CustomPantryIngredients extends Notifier<List<CustomPantryIngredient>> {
  SharedPreferences? _prefs;

  @override
  List<CustomPantryIngredient> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_kCustomPantryIngredients);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = List<CustomPantryIngredient>.unmodifiable(
          decoded
              .whereType<Map>()
              .map(
                (item) => CustomPantryIngredient.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.name.isNotEmpty),
        );
        return;
      }
    }

    // Migrate bản cũ (chỉ tên, chưa có nhóm).
    final legacy =
        _prefs!.getStringList(_kCustomPantryIngredientsLegacy) ?? const [];
    if (legacy.isEmpty) {
      state = const [];
      return;
    }

    final migrated = [
      for (final name in legacy)
        if (name.trim().isNotEmpty)
          CustomPantryIngredient(
            name: name.trim(),
            groupId: PantryIngredientClassifier.classify(name),
          ),
    ];
    await _persist(migrated);
    await _prefs!.remove(_kCustomPantryIngredientsLegacy);
    state = List<CustomPantryIngredient>.unmodifiable(migrated);
  }

  Future<void> _persist(List<CustomPantryIngredient> items) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kCustomPantryIngredients,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Thêm nguyên liệu chưa có — tự xếp vào nhóm phù hợp.
  Future<List<CustomPantryIngredient>> addMissing(
    Iterable<String> candidates,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();

    final knownLower = {
      for (final item in PantryIngredients.all) item.toLowerCase(),
      for (final item in state) item.name.toLowerCase(),
    };

    final toAdd = <CustomPantryIngredient>[];
    for (final raw in candidates) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (knownLower.contains(key)) continue;
      knownLower.add(key);
      toAdd.add(
        CustomPantryIngredient(
          name: name,
          groupId: PantryIngredientClassifier.classify(name),
        ),
      );
    }

    if (toAdd.isEmpty) return const [];

    final next = [...state, ...toAdd];
    await _persist(next);
    state = List<CustomPantryIngredient>.unmodifiable(next);
    return toAdd;
  }
}

final customPantryIngredientsProvider =
    NotifierProvider<CustomPantryIngredients, List<CustomPantryIngredient>>(
  CustomPantryIngredients.new,
);

/// Nhóm hiển thị: nguyên liệu mới được gộp vào đúng mục sẵn có.
final pantryIngredientGroupsProvider = Provider<List<PantryGroup>>((ref) {
  final custom = ref.watch(customPantryIngredientsProvider);
  return mergeCustomIntoGroups(custom);
});

/// Nguyên liệu người dùng đang chọn trong tủ lạnh.
class PantrySelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String ingredient) {
    final next = {...state};
    if (!next.add(ingredient)) {
      next.remove(ingredient);
    }
    state = next;
  }

  void clear() => state = <String>{};
}

final pantrySelectionProvider =
    NotifierProvider<PantrySelection, Set<String>>(PantrySelection.new);

/// Kết quả khớp món với nguyên liệu đã chọn.
class MealIngredientMatch {
  const MealIngredientMatch({
    required this.meal,
    required this.matchedIngredients,
  });

  final MealModel meal;
  final List<String> matchedIngredients;

  int get matchedCount => matchedIngredients.length;

  double get matchRatio {
    if (meal.ingredients.isEmpty) return 0;
    return matchedCount / meal.ingredients.length;
  }
}

/// Món đang bật + đã gắn ingredients (ưu tiên Firestore, fallback preset).
final pantryReadyMealsProvider = FutureProvider<List<MealModel>>((ref) async {
  final meals = await ref.watch(enabledMealsProvider.future);
  final presetById = await _loadPresetById();

  return meals.map((meal) {
    if (meal.ingredients.isNotEmpty) return meal;
    final preset = presetById[meal.id];
    if (preset == null || preset.ingredients.isEmpty) return meal;
    return meal.copyWith(ingredients: preset.ingredients);
  }).toList(growable: false);
});

final pantryMatchesProvider = Provider<AsyncValue<List<MealIngredientMatch>>>((
  ref,
) {
  final selected = ref.watch(pantrySelectionProvider);
  final mealsAsync = ref.watch(pantryReadyMealsProvider);

  return mealsAsync.whenData((meals) {
    if (selected.isEmpty) return const <MealIngredientMatch>[];

    final selectedLower = selected.map((e) => e.toLowerCase()).toSet();
    final matches = <MealIngredientMatch>[];

    for (final meal in meals) {
      if (meal.ingredients.isEmpty) continue;
      final matched = meal.ingredients
          .where((ing) => selectedLower.contains(ing.toLowerCase()))
          .toList();
      if (matched.isEmpty) continue;
      matches.add(
        MealIngredientMatch(meal: meal, matchedIngredients: matched),
      );
    }

    matches.sort((a, b) {
      final ratioCmp = b.matchRatio.compareTo(a.matchRatio);
      if (ratioCmp != 0) return ratioCmp;
      return b.matchedCount.compareTo(a.matchedCount);
    });
    return matches;
  });
});

/// Đồng bộ field ingredients từ preset JSON lên Firestore (món thiếu ingredients).
Future<int> syncMealIngredientsFromPreset(WidgetRef ref) async {
  final repo = ref.read(mealRepositoryProvider);
  final meals = await ref.read(mealsProvider.future);
  final presetById = await _loadPresetById();

  var updated = 0;
  for (final meal in meals) {
    if (meal.ingredients.isNotEmpty) continue;
    final preset = presetById[meal.id];
    if (preset == null || preset.ingredients.isEmpty) continue;
    await repo.updateIngredients(
      mealId: meal.id,
      ingredients: preset.ingredients,
    );
    updated++;
  }
  return updated;
}

Future<Map<String, MealModel>> _loadPresetById() async {
  final raw = await rootBundle.loadString(AssetPaths.presetMeals);
  final decoded = jsonDecode(raw);
  if (decoded is! List) return {};

  final map = <String, MealModel>{};
  for (final item in decoded.whereType<Map>()) {
    final meal = MealModel.fromJson(Map<String, dynamic>.from(item));
    if (meal.id.isNotEmpty) map[meal.id] = meal;
  }
  return map;
}
