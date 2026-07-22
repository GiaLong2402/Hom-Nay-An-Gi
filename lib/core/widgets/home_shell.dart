import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/battle/presentation/screens/food_battle_screen.dart';
import '../../features/cards/presentation/screens/random_cards_screen.dart';
import '../../features/meals/presentation/screens/meal_management_screen.dart';
import '../../features/pantry/presentation/screens/pantry_screen.dart';
import '../../features/wheel/presentation/screens/lucky_wheel_screen.dart';
import '../providers/navigation_provider.dart';

/// Shell chính với bottom navigation.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _pages = <Widget>[
    LuckyWheelScreen(),
    FoodBattleScreen(),
    RandomCardsScreen(),
    PantryScreen(),
    MealManagementScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            ref.read(homeTabIndexProvider.notifier).goTo(value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Vòng quay',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_martial_arts_outlined),
            selectedIcon: Icon(Icons.sports_martial_arts),
            label: 'Đấu kép',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Thẻ bài',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Tủ lạnh',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Quản lý',
          ),
        ],
      ),
    );
  }
}
