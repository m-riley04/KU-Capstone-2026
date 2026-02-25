import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final Map<String, AudioPlayer> _players = {};

  /// Play a sound effect from an asset path.
  /// If a player for this asset already exists, it will be reused.
  void playSound(String assetPath) {
    // Run async operation in background without blocking
    _playSoundAsync(assetPath);
  }

  Future<void> _playSoundAsync(String assetPath) async {
    try {
      print('[AudioService] Playing sound: $assetPath');

      AudioPlayer player = _players[assetPath] ?? AudioPlayer();
      _players[assetPath] = player;

      await player.setAsset(assetPath);
      print('[AudioService] Asset loaded, starting playback');

      await player.play();
      print('[AudioService] Sound playing');
    } catch (e) {
      print('[AudioService] Error playing sound $assetPath: $e');
    }
  }

  /// Dispose all audio players.
  Future<void> dispose() async {
    for (var player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
