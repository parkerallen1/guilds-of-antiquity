import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioService() {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playMusic(String assetPath) async {
    // In a real app, we would fade out current and fade in new
    try {
      await _musicPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Ignore errors for now as assets might not exist yet
      print('Error playing music: $e');
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> playSfx(String assetPath) async {
    try {
      // For SFX, we might want multiple players or one-shot
      // creating a new player for overlapping sounds is better for game feel
      final player = AudioPlayer();
      await player.play(AssetSource(assetPath));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      print('Error playing sfx: $e');
    }
  }

  // Specific Triggers
  Future<void> playGoldSound() async {
    // Randomized pitch could be added here
    await playSfx('audio/gold_gain.mp3');
  }

  Future<void> playCombatHit() async {
    await playSfx('audio/combat_hit.mp3');
  }

  Future<void> playLevelUp() async {
    await playSfx('audio/level_up.mp3');
  }

  Future<void> playLegendaryDrop() async {
    await playSfx('audio/legendary_drop.mp3');
  }
}
