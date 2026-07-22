/// Danh mục món ăn dùng trong app "Hôm Nay Ăn Gì?".
enum MealCategory {
  breakfast('Sáng'),
  lunch('Trưa'),
  dinner('Tối'),
  dry('Đồ khô'),
  soup('Đồ nước'),
  snack('Ăn vặt');

  const MealCategory(this.label);

  /// Nhãn tiếng Việt lưu trên Firestore / hiển thị UI.
  final String label;

  /// Parse từ chuỗi (label hoặc tên enum). Fallback: [MealCategory.lunch].
  static MealCategory fromString(String? value) {
    if (value == null || value.isEmpty) return MealCategory.lunch;

    for (final category in MealCategory.values) {
      if (category.label == value || category.name == value) {
        return category;
      }
    }
    return MealCategory.lunch;
  }
}
