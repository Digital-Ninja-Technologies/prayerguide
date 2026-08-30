import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps [AudioRecorder] for the Sermon Note Taker — mono AAC at a modest
/// bitrate, since it's speech, not music, and the file has to upload over
/// whatever connection the user is on. Not available on web (see
/// `sermon_note_new_screen.dart`, which hides the record button there and
/// falls back to notes-only).
class SermonRecorder {
  final _recorder = AudioRecorder();
  String? _path;

  static const _config = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 64000,
    sampleRate: 44100,
    numChannels: 1,
  );

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    // Application-support, not temporary: the recording has to survive
    // between "stop" and a (possibly retried, possibly offline) upload —
    // temp directories can be purged by the OS at any point, which is how
    // sermon audio was silently going missing before.
    final dir = await getApplicationSupportDirectory();
    final audioDir = Directory('${dir.path}/sermon_audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);
    _path =
        '${audioDir.path}/sermon_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(_config, path: _path!);
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  /// Stops recording and returns the local file path, or null if nothing
  /// was recorded.
  Future<String?> stop() => _recorder.stop();

  /// Stops and discards the in-progress recording (e.g. user cancels).
  Future<void> cancel() => _recorder.cancel();

  Future<void> dispose() => _recorder.dispose();
}
