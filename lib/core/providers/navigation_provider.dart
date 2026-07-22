import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/meal_model.dart';

/// Tab đang chọn trên bottom navigation.
class HomeTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) => state = index;
}

final homeTabIndexProvider =
    NotifierProvider<HomeTabIndex, int>(HomeTabIndex.new);

/// Index tab Đấu kép trong HomeShell.
const kBattleTabIndex = 1;

/// Món mang từ Vòng quay sang Đấu kép (làm hạt giống / nhà vô địch tạm).
class BattleSeed extends Notifier<MealModel?> {
  @override
  MealModel? build() => null;

  void setSeed(MealModel meal) => state = meal;

  void clear() => state = null;
}

final battleSeedProvider =
    NotifierProvider<BattleSeed, MealModel?>(BattleSeed.new);
