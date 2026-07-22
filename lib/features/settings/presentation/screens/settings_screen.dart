import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_mode_selector.dart';

/// Màn hình cài đặt giao diện & hiệu ứng.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          _SettingsHero(scheme: scheme),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: 'Giao diện',
            subtitle: 'Chế độ sáng hoặc tối',
            child: const ThemeModeSelector(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: 'Trải nghiệm',
            subtitle: 'Âm thanh khi tương tác',
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Âm thanh hiệu ứng',
                  subtitle: 'Tiếng quay vòng, trúng món & quẹt thẻ',
                  showDivider: false,
                  trailing: Switch.adaptive(
                    value: settings.soundEnabled,
                    onChanged: notifier.setSoundEnabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSection(
            title: 'Ứng dụng',
            child: SettingsTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Hôm Nay Ăn Gì?',
              subtitle: 'Phiên bản 1.0.0 · Giúp bạn chọn món mỗi ngày',
              showDivider: false,
              trailing: Icon(
                Icons.info_outline_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.seed,
            scheme.tertiary,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuỳ chỉnh trải nghiệm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giao diện và âm thanh — tất cả ở đây.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
