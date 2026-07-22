import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/meal_repository.dart';
import '../../../../core/models/meal_model.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository();
});

/// Toàn bộ món ăn từ Firestore.
final mealsProvider = StreamProvider<List<MealModel>>((ref) {
  return ref.watch(mealRepositoryProvider).watchAll();
});

/// Chỉ món `isEnabled == true` — dùng cho Vòng quay / Thẻ bài.
final enabledMealsProvider = StreamProvider<List<MealModel>>((ref) {
  return ref.watch(mealRepositoryProvider).watchEnabled();
});
