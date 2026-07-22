import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/models/meal_category.dart';
import '../../../../core/models/meal_model.dart';

/// Đọc / ghi collection `meals` trên Cloud Firestore.
class MealRepository {
  MealRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _mealsRef =>
      _firestore.collection(FirestoreConstants.mealsCollection);

  /// Stream toàn bộ món ăn (realtime + offline cache), sắp xếp theo tên.
  Stream<List<MealModel>> watchAll() {
    return _mealsRef.snapshots().map((snapshot) {
      final meals = snapshot.docs.map(MealModel.fromFirestore).toList();
      meals.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return List<MealModel>.unmodifiable(meals);
    });
  }

  /// Stream chỉ món đang bật (`isEnabled == true`).
  Stream<List<MealModel>> watchEnabled() {
    return _mealsRef.where('isEnabled', isEqualTo: true).snapshots().map(
      (snapshot) {
        final meals = snapshot.docs.map(MealModel.fromFirestore).toList();
        meals.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return List<MealModel>.unmodifiable(meals);
      },
    );
  }

  /// Bật/tắt món trên Firestore (realtime sync sang Vòng quay).
  Future<void> setEnabled({
    required String mealId,
    required bool isEnabled,
  }) {
    return _mealsRef.doc(mealId).update({'isEnabled': isEnabled});
  }

  /// Thêm món tùy chỉnh (`isCustom: true`).
  Future<MealModel> addMeal({
    required String name,
    required MealCategory category,
    List<String> tags = const [],
    List<String> ingredients = const [],
  }) async {
    final docRef = _mealsRef.doc();
    final meal = MealModel(
      id: docRef.id,
      name: name.trim(),
      category: category,
      tags: tags,
      ingredients: ingredients,
      isEnabled: true,
      isCustom: true,
      createdAt: DateTime.now(),
    );
    await docRef.set(meal.toFirestore());
    return meal;
  }

  /// Cập nhật thông tin món (tên, danh mục, tags, nguyên liệu...).
  Future<void> updateMeal(MealModel meal) {
    return _mealsRef.doc(meal.id).update({
      'name': meal.name.trim(),
      'category': meal.category.label,
      'tags': meal.tags,
      'ingredients': meal.ingredients,
      'isEnabled': meal.isEnabled,
      'isCustom': meal.isCustom,
    });
  }

  /// Cập nhật field `ingredients` theo id (dùng để sync từ preset).
  Future<void> updateIngredients({
    required String mealId,
    required List<String> ingredients,
  }) {
    return _mealsRef.doc(mealId).update({'ingredients': ingredients});
  }

  /// Xóa món theo id.
  Future<void> deleteMeal(String mealId) {
    return _mealsRef.doc(mealId).delete();
  }
}
