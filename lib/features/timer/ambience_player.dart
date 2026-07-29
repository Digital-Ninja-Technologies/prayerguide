import 'package:audioplayers/audioplayers.dart';

/// Loops a background ambience track (meditation / silence / tender clouds)
/// during a prayer session. Track files live in `assets/audio/`.
class AmbiencePlayer {
  AmbiencePlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  static const _fileFor = {
    'meditation': 'audio/meditation.mp3',
    'silence': 'audio/silence.mp3',
    'tenderclouds': 'audio/tenderclouds.mp3',
  };

  final AudioPlayer _player = AudioPlayer();

  /// Plays [key] on loop, replacing whatever was playing before. Throws if
  /// the corresponding asset file hasn't been added yet.
  Future<void> play(String key) async {
    final file = _fileFor[key];
    if (file == null) throw ArgumentError('Unknown ambience track: $key');
    await _player.stop();
    await _player.play(AssetSource(file), volume: 0.55);
  }

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
