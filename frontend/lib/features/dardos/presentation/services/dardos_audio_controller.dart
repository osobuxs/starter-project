import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DardosAudioController {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  late final Future<void> _initFuture;

  DardosAudioController() {
    _initFuture = _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    await _effectsPlayer.setReleaseMode(ReleaseMode.stop);

    await _tts.awaitSpeakCompletion(false);
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    await _trySetLanguage(const ['es-AR', 'es-ES', 'es-US', 'es-MX']);
  }

  Future<void> _trySetLanguage(List<String> locales) async {
    for (final locale in locales) {
      try {
        await _tts.setLanguage(locale);
        return;
      } catch (_) {
        // Try next locale.
      }
    }
  }

  Future<void> speakScore(int score) async {
    await _initFuture;
    try {
      await _tts.stop();
      await _tts.speak('$score');
    } catch (_) {
      // Non-blocking UX enhancement.
    }
  }

  Future<void> playBust() => _playEffect('bust_defeat.wav');

  Future<void> playLegWon() => _playEffect('leg_applause.wav');

  Future<void> playGameWon() => _playEffect('game_drums.wav');

  Future<void> _playEffect(String assetPath) async {
    await _initFuture;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('audio/dardos/$assetPath'));
    } catch (_) {
      // Non-blocking UX enhancement.
    }
  }

  void dispose() {
    unawaited(_safeDispose());
  }

  Future<void> _safeDispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    await _effectsPlayer.dispose();
  }
}
