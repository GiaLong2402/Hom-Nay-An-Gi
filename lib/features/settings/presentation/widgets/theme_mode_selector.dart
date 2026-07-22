import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';

/// Chọn Sáng / Tối / Hệ thống — gọn, 3 ô vuông cạnh nhau.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _ThemeChoice(
              icon: Icons.light_mode_rounded,
              label: 'Sáng',
              selected: settings.themeMode == ThemeMode.light,
              onTap: () => notifier.setThemeMode(ThemeMode.light),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ThemeChoice(
              icon: Icons.dark_mode_rounded,
              label: 'Tối',
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () => notifier.setThemeMode(ThemeMode.dark),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ThemeChoice(
              icon: Icons.brightness_auto_rounded,
              label: 'Hệ thống',
              selected: settings.themeMode == ThemeMode.system,
              onTap: () => notifier.setThemeMode(ThemeMode.system),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
