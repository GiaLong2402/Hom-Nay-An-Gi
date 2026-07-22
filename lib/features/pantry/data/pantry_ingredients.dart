/// Danh sách nguyên liệu phổ biến, gom theo nhóm để UI gọn hơn.
abstract final class PantryIngredients {
  static const List<PantryGroup> groups = [
    PantryGroup(
      id: 'protein',
      label: 'Thịt & hải sản',
      items: [
        'Thịt bò',
        'Thịt heo',
        'Sườn heo',
        'Gà',
        'Lòng heo',
        'Huyết',
        'Tôm',
        'Cua',
        'Ốc',
        'Hải sản',
        'Trứng',
        'Trứng cút',
        'Xúc xích',
        'Pate',
        'Ruốc',
      ],
    ),
    PantryGroup(
      id: 'carb',
      label: 'Tinh bột',
      items: [
        'Gạo',
        'Bún',
        'Bánh phở',
        'Hủ tiếu',
        'Mì',
        'Mì Quảng',
        'Mì cao lầu',
        'Bánh mì',
        'Bánh tráng',
        'Bột gạo',
        'Bột chiên',
      ],
    ),
    PantryGroup(
      id: 'veggie',
      label: 'Rau & đậu',
      items: [
        'Rau sống',
        'Rau',
        'Rau cải',
        'Rau thơm',
        'Rau răm',
        'Giá đỗ',
        'Cà chua',
        'Nấm',
        'Bắp',
        'Mộc nhĩ',
        'Đậu phụ',
        'Đậu xanh',
        'Đậu đỏ',
        'Đậu Hà Lan',
        'Đậu phộng',
        'Dưa chua',
        'Đồ chua',
      ],
    ),
    PantryGroup(
      id: 'spice',
      label: 'Gia vị & khác',
      items: [
        'Hành',
        'Tỏi',
        'Gừng',
        'Sả',
        'Ớt',
        'Tiêu',
        'Me',
        'Nước mắm',
        'Nước tương',
        'Mắm tôm',
        'Tương ớt',
        'Nước cốt dừa',
        'Bơ',
        'Thạch',
        'Đá',
      ],
    ),
  ];

  /// Flat list — dùng cho sync / match.
  static List<String> get all => [
        for (final group in groups) ...group.items,
      ];
}

class PantryGroup {
  const PantryGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<String> items;
}
