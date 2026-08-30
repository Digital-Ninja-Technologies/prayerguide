import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-first index of sermon recordings — the source of truth for "does a
/// copy of this recording still exist on this device" and "has it made it
/// to the cloud yet," entirely independent of network. Keyed by the
/// recording's id: the real Supabase `SermonRecording.id` once an upload
/// has succeeded, or a locally-generated key (see [newLocalRecordingKey])
/// before that — [rekey] moves an entry from one to the other once the
/// upload lands. Persisted the same way `sermon_note_new_screen.dart`
/// already persists its draft: a JSON blob in SharedPreferences.
class LocalRecordingEntry {
  const LocalRecordingEntry({
    required this.localPath,
    required this.noteId,
    required this.pendingUpload,
    this.durationSeconds,
  });

  final String localPath;
  final String noteId;
  final bool pendingUpload;
  final int? durationSeconds;

  LocalRecordingEntry copyWith({bool? pendingUpload}) => LocalRecordingEntry(
        localPath: localPath,
        noteId: noteId,
        pendingUpload: pendingUpload ?? this.pendingUpload,
        durationSeconds: durationSeconds,
      );

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        'noteId': noteId,
        'pendingUpload': pendingUpload,
        'durationSeconds': durationSeconds,
      };

  factory LocalRecordingEntry.fromJson(Map<String, dynamic> j) =>
      LocalRecordingEntry(
        localPath: j['localPath'] as String,
        noteId: j['noteId'] as String,
        pendingUpload: j['pendingUpload'] as bool? ?? false,
        durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
      );
}

const _prefsKey = 'sermon_local_recordings_v1';

class LocalRecordingStore {
  Future<Map<String, LocalRecordingEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, LocalRecordingEntry.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      // Corrupt or outdated shape — treat as empty rather than crash; any
      // recordings it referenced are still on disk, just no longer indexed.
      return {};
    }
  }

  Future<void> _save(Map<String, LocalRecordingEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(entries.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> put(String key, LocalRecordingEntry entry) async {
    final all = await _load();
    all[key] = entry;
    await _save(all);
  }

  Future<LocalRecordingEntry?> get(String key) async => (await _load())[key];

  /// Moves an entry from its temporary local key to the real server id once
  /// an upload succeeds, keeping the local file indexed under the id the
  /// rest of the app now refers to it by.
  Future<void> rekey(String oldKey, String newKey) async {
    final all = await _load();
    final entry = all.remove(oldKey);
    if (entry == null) return;
    all[newKey] = entry;
    await _save(all);
  }

  Future<void> markSynced(String key) async {
    final all = await _load();
    final entry = all[key];
    if (entry == null) return;
    all[key] = entry.copyWith(pendingUpload: false);
    await _save(all);
  }

  Future<void> remove(String key) async {
    final all = await _load();
    all.remove(key);
    await _save(all);
  }

  Future<List<MapEntry<String, LocalRecordingEntry>>> pending() async =>
      (await _load()).entries.where((e) => e.value.pendingUpload).toList();
}

final localRecordingStore = LocalRecordingStore();

/// A stable local key for a recording that hasn't been uploaded yet —
/// timestamp-based like the filenames `SermonRecorder` already generates;
/// never sent to Supabase, so it doesn't need to be a real UUID.
String newLocalRecordingKey() =>
    'local_${DateTime.now().microsecondsSinceEpoch}';
