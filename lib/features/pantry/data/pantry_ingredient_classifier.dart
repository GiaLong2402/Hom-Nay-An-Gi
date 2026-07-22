import 'pantry_ingredients.dart';

/// Nguyên liệu tự thêm, gắn với một nhóm sẵn có.
class CustomPantryIngredient {
  const CustomPantryIngredient({
    required this.name,
    required this.groupId,
  });

  final String name;
  final String groupId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'groupId': groupId,
      };

  factory CustomPantryIngredient.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final groupId = (json['groupId'] as String?)?.trim();
    return CustomPantryIngredient(
      name: name,
      groupId: PantryIngredientClassifier.isValidGroup(groupId)
          ? groupId!
          : PantryIngredientClassifier.classify(name),
    );
  }
}

/// Phân loại nguyên liệu vào nhóm: protein / carb / veggie / spice.
abstract final class PantryIngredientClassifier {
  static const defaultGroupId = 'spice';

  static const validGroupIds = {'protein', 'carb', 'veggie', 'spice'};

  static bool isValidGroup(String? id) =>
      id != null && validGroupIds.contains(id);

  /// Gán nhóm theo từ khóa tên nguyên liệu (tiếng Việt).
  static String classify(String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name.isEmpty) return defaultGroupId;

    if (_matches(name, _proteinKeywords)) return 'protein';
    if (_matches(name, _carbKeywords)) return 'carb';
    if (_matches(name, _veggieKeywords)) return 'veggie';
    if (_matches(name, _spiceKeywords)) return 'spice';

    return defaultGroupId;
  }

  static bool _matches(String name, List<String> keywords) {
    for (final keyword in keywords) {
      if (name.contains(keyword)) return true;
    }
    return false;
  }

  static const _proteinKeywords = [
    'thịt',
    'bò',
    'heo',
    'lợn',
    'gà',
    'vịt',
    'chim',
    'sườn',
    'ba chỉ',
    'lòng',
    'huyết',
    'tôm',
    'cua',
    'cá',
    'mực',
    'ốc',
    'nghêu',
    'sò',
    'hến',
    'hải sản',
    'trứng',
    'xúc xích',
    'pate',
    'giò',
    'chả',
    'ruốc',
    'lươn',
    'ếch',
    'tép',
  ];

  static const _carbKeywords = [
    'gạo',
    'cơm',
    'bún',
    'phở',
    'hủ tiếu',
    'mì',
    'nui',
    'bánh mì',
    'bánh tráng',
    'bánh',
    'bột',
    'khoai',
    'ngô',
  ];

  static const _veggieKeywords = [
    'lá lốt',
    'lá',
    'rau',
    'cải',
    'đậu',
    'nấm',
    'mộc nhĩ',
    'giá',
    'cà chua',
    'cà',
    'dưa',
    'bí',
    'su su',
    'su hào',
    'bầu',
    'mướp',
    'bông cải',
    'xà lách',
    'diếp',
    'ngò',
    'húng',
    'thơm',
    'hành lá',
    'củ cải',
    'cà rốt',
    'ớt chuông',
  ];

  static const _spiceKeywords = [
    'hành tím',
    'hành tây',
    'hành',
    'tỏi',
    'gừng',
    'sả',
    'ớt',
    'tiêu',
    'muối',
    'đường',
    'nước mắm',
    'nước tương',
    'mắm',
    'tương',
    'dầu',
    'bơ',
    'me',
    'chanh',
    'quế',
    'hồi',
    'đinh hương',
    'ngũ vị',
    'bột ngọt',
    'hạt nêm',
    'dừa',
    'thạch',
    'đá',
  ];
}

/// Gom nguyên liệu custom vào đúng nhóm sẵn có (giữ thứ tự mặc định).
List<PantryGroup> mergeCustomIntoGroups(
  List<CustomPantryIngredient> custom,
) {
  if (custom.isEmpty) return PantryIngredients.groups;

  final knownLower = {
    for (final group in PantryIngredients.groups)
      for (final item in group.items) item.toLowerCase(),
  };

  final extras = <String, List<String>>{
    for (final group in PantryIngredients.groups) group.id: <String>[],
  };

  for (final item in custom) {
    final key = item.name.toLowerCase();
    if (knownLower.contains(key)) continue;
    knownLower.add(key);

    final groupId = PantryIngredientClassifier.isValidGroup(item.groupId)
        ? item.groupId
        : PantryIngredientClassifier.classify(item.name);
    extras.putIfAbsent(groupId, () => <String>[]);
    extras[groupId]!.add(item.name);
  }

  for (final list in extras.values) {
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  return [
    for (final group in PantryIngredients.groups)
      PantryGroup(
        id: group.id,
        label: group.label,
        items: [
          ...group.items,
          ...?extras[group.id],
        ],
      ),
  ];
}
