import 'package:flutter/material.dart';

/// Một dòng cài đặt: icon + tiêu đề + mô tả ngắn + control bên phải.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
          trailing: trailing,
        ),
        if (showDivider) const Divider(height: 1, indent: 68),
      ],
    );
  }
}
