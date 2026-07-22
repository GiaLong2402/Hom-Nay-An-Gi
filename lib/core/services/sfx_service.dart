import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_settings_provider.dart';

/// Âm thanh hiệu ứng cho vòng quay, thẻ bài, v.v.
class SfxService {
  SfxService(this._readSettings);

  final AppSettings Function() _readSettings;

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _swipePlayer = AudioPlayer();
  Timer? _wheelTickTimer;

  AppSettings get _settings => _readSettings();

  Future<void> dispose() async {
    _wheelTickTimer?.cancel();
    await _tickPlayer.dispose();
    await _winPlayer.dispose();
    await _swipePlayer.dispose();
  }

  void _wheelTick() {
    if (!_settings.soundEnabled) return;
    unawaited(_playAsset(_tickPlayer, 'sounds/wheel_tick.wav'));
  }

  Future<void> _playAsset(AudioPlayer player, String asset) async {
    if (!_settings.soundEnabled) return;
    await player.stop();
    await player.play(AssetSource(asset));
  }

  /// Tiếng "tạch tạch" khi vòng quay đang chạy.
  void startWheelSpinning() {
    _wheelTickTimer?.cancel();
    _wheelTick();
    _wheelTickTimer = Timer.periodic(
      const Duration(milliseconds: 260),
      (_) => _wheelTick(),
    );
  }

  void stopWheelSpinning() {
    _wheelTickTimer?.cancel();
    _wheelTickTimer = null;
  }

  /// Tiếng reo / ting khi trúng món.
  Future<void> playWheelWin() async {
    stopWheelSpinning();
    await _playAsset(_winPlayer, 'sounds/wheel_win.wav');
  }

  /// Tiếng quẹt thẻ.
  void onCardSwipe() {
    if (!_settings.soundEnabled) return;
    unawaited(_playAsset(_swipePlayer, 'sounds/card_swipe.wav'));
  }
}

final sfxServiceProvider = Provider<SfxService>((ref) {
  final service = SfxService(() => ref.read(appSettingsProvider));
  ref.onDispose(service.dispose);
  return service;
});
