import 'package:audioplayers/audioplayers.dart';

/// Loops a background ambience track (rain / ocean / instrumental) during
/// a prayer session. Track files live in `assets/audio/` and are provided
/// by whoever builds the app (not bundled here — see that folder's README).
class AmbiencePlayer {
  AmbiencePlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  static const _fileFor = {
    'rain': 'audio/rain.mp3',
    'ocean': 'audio/ocean.mp3',
    'instrumental': 'audio/instrumental.mp3',
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
