import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'theme_mode';
const _kSoundEnabled = 'sound_enabled';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.soundEnabled,
  });

  final ThemeMode themeMode;
  final bool soundEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    soundEnabled: true,
  );

  static Future<AppSettings> load(SharedPreferences prefs) async {
    final themeIndex = prefs.getInt(_kThemeMode);
    return AppSettings(
      themeMode: themeIndex == null
          ? ThemeMode.system
          : ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
    );
  }
}

late AppSettings bootstrapAppSettings;

class AppSettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  AppSettings build() => bootstrapAppSettings;

  Future<void> setThemeMode(ThemeMode mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_kSoundEnabled, enabled);
    state = state.copyWith(soundEnabled: enabled);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
