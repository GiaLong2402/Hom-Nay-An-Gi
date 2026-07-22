import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/firestore_constants.dart';
import '../models/meal_model.dart';

/// Kết quả thao tác seed món ăn mặc định lên Firestore.
class SeedResult {
  const SeedResult._({
    required this.success,
    required this.seededCount,
    required this.skipped,
    this.message,
  });

  factory SeedResult.seeded(int count) => SeedResult._(
        success: true,
        seededCount: count,
        skipped: false,
        message: 'Đã seed $count món ăn lên Firestore.',
      );

  factory SeedResult.skippedAlreadyHasData(int existingCount) => SeedResult._(
        success: true,
        seededCount: 0,
        skipped: true,
        message:
            'Collection meals đã có $existingCount món — bỏ qua seed.',
      );

  factory SeedResult.failure(Object error) => SeedResult._(
        success: false,
        seededCount: 0,
        skipped: false,
        message: 'Seed thất bại: $error',
      );

  final bool success;
  final int seededCount;
  final bool skipped;
  final String? message;
}

/// Đọc [AssetPaths.presetMeals] và đẩy lên Firestore khi collection trống.
class MealSeedService {
  MealSeedService({
    FirebaseFirestore? firestore,
    this.assetPath = AssetPaths.presetMeals,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String assetPath;

  CollectionReference<Map<String, dynamic>> get _mealsRef =>
      _firestore.collection(FirestoreConstants.mealsCollection);

  /// Seed chỉ khi `meals` đang trống. An toàn gọi nhiều lần.
  Future<SeedResult> seedIfEmpty() async {
    try {
      final existing = await _mealsRef.limit(1).get();
      if (existing.docs.isNotEmpty) {
        final countSnap = await _mealsRef.count().get();
        final count = countSnap.count ?? existing.docs.length;
        return SeedResult.skippedAlreadyHasData(count);
      }

      final meals = await loadPresetMeals();
      await _writeMeals(meals);
      return SeedResult.seeded(meals.length);
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('MealSeedService.seedIfEmpty error: $error\n$stackTrace');
        return true;
      }());
      return SeedResult.failure(error);
    }
  }

  /// Đọc & parse JSON preset từ asset bundle.
  Future<List<MealModel>> loadPresetMeals() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException(
        'preset_meals.json phải là một mảng JSON.',
      );
    }

    return decoded
        .whereType<Map>()
        .map((item) => MealModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .map(
          (meal) => meal.copyWith(
            isEnabled: true,
            isCustom: false,
            createdAt: meal.createdAt ?? DateTime.now(),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _writeMeals(List<MealModel> meals) async {
    final batch = _firestore.batch();

    for (final meal in meals) {
      final docId = meal.id.isNotEmpty ? meal.id : _mealsRef.doc().id;
      final docRef = _mealsRef.doc(docId);
      final data = meal.copyWith(id: docId).toFirestore();
      batch.set(docRef, data);
    }

    await batch.commit();
  }
}
