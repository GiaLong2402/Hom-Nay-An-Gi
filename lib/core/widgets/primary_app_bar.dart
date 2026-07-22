import 'package:flutter/material.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';

/// AppBar thống nhất — tiêu đề + nút cài đặt (tuỳ chọn).
class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showSettings = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        ...actions,
        if (showSettings)
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
      ],
    );
  }
}
