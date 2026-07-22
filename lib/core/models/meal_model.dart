import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_category.dart';

/// Model món ăn — map 1-1 với document trong collection `meals`.
class MealModel {
  const MealModel({
    required this.id,
    required this.name,
    required this.category,
    this.tags = const [],
    this.ingredients = const [],
    this.isEnabled = true,
    this.isCustom = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final MealCategory category;
  final List<String> tags;
  final List<String> ingredients;
  final bool isEnabled;
  final bool isCustom;
  final DateTime? createdAt;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: MealCategory.fromString(json['category'] as String?),
      tags: _parseStringList(json['tags']),
      ingredients: _parseStringList(json['ingredients']),
      isEnabled: json['isEnabled'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.label,
      'tags': tags,
      'ingredients': ingredients,
      'isEnabled': isEnabled,
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Parse từ Firestore document.
  /// [doc.id] được ưu tiên nếu field `id` trong data bị thiếu.
  factory MealModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Meal document ${doc.id} has no data');
    }

    return MealModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      category: MealCategory.fromString(data['category'] as String?),
      tags: _parseStringList(data['tags']),
      ingredients: _parseStringList(data['ingredients']),
      isEnabled: data['isEnabled'] as bool? ?? true,
      isCustom: data['isCustom'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  /// Payload ghi lên Firestore (dùng `Timestamp` thay vì ISO string).
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category.label,
      'tags': tags,
      'ingredients': ingredients,
      'isEnabled': isEnabled,
      'isCustom': isCustom,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  MealModel copyWith({
    String? id,
    String? name,
    MealCategory? category,
    List<String>? tags,
    List<String>? ingredients,
    bool? isEnabled,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      ingredients: ingredients ?? this.ingredients,
      isEnabled: isEnabled ?? this.isEnabled,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealModel &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.ingredients, ingredients) &&
        other.isEnabled == isEnabled &&
        other.isCustom == isCustom &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        Object.hashAll(tags),
        Object.hashAll(ingredients),
        isEnabled,
        isCustom,
        createdAt,
      );

  @override
  String toString() {
    return 'MealModel(id: $id, name: $name, category: ${category.label}, '
        'isEnabled: $isEnabled, isCustom: $isCustom)';
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
