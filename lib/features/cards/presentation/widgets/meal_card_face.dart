import 'package:flutter/material.dart';

import '../../../../core/models/meal_model.dart';

/// Mặt trước thẻ món — dùng cho chế độ quẹt thẻ.
class MealCardFace extends StatelessWidget {
  const MealCardFace({
    super.key,
    required this.meal,
  });

  final MealModel meal;

  static const _tagTextColor = Color(0xFF6B2F00);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.tertiary,
            const Color(0xFFFFB347),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meal.category.label,
                  style: const TextStyle(
                    color: _tagTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              meal.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
            ),
            if (meal.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: meal.tags
                    .take(4)
                    .map(
                      (tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(
                            color: _tagTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
