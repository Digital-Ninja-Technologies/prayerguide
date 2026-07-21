import '../../core/security/encryption_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/prayer_request.dart';

class RequestsRepository {
  final _enc = EncryptionService.instance;

  Future<List<PrayerRequest>> fetchAll() async {
    final uid = supa.auth.currentUser!.id;
    final rows =
        await supa.from('prayer_requests').select().order('created_at', ascending: false);

    final requests = <PrayerRequest>[];
    for (final r in rows as List) {
      final row = r as Map<String, dynamic>;
      final title = await _enc.decrypt(uid, row['title_cipher'] as String);
      final noteCipher = row['note_cipher'] as String?;
      final note = noteCipher == null ? null : await _enc.decrypt(uid, noteCipher);
      requests.add(PrayerRequest.fromMap({
        ...row,
        'title': title ?? '🔒 Unable to decrypt on this device',
        'note': note,
      }));
    }
    return requests;
  }

  Future<PrayerRequest> create({
    required String category,
    required String title,
    String? note,
    bool reminder = false,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final titleCipher = await _enc.encrypt(uid, title);
    final noteCipher = note == null ? null : await _enc.encrypt(uid, note);
    final row = await supa
        .from('prayer_requests')
        .insert({
          'user_id': uid,
          'category': category,
          'title_cipher': titleCipher,
          'note_cipher': noteCipher,
          'reminder': reminder,
        })
        .select()
        .single();
    return PrayerRequest.fromMap({...row, 'title': title, 'note': note});
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    final uid = supa.auth.currentUser!.id;
    final dbPatch = <String, dynamic>{...patch, 'updated_at': DateTime.now().toIso8601String()};
    if (dbPatch.containsKey('title')) {
      dbPatch['title_cipher'] = await _enc.encrypt(uid, dbPatch.remove('title') as String);
    }
    if (dbPatch.containsKey('note')) {
      final note = dbPatch.remove('note') as String?;
      dbPatch['note_cipher'] = note == null ? null : await _enc.encrypt(uid, note);
    }
    await supa.from('prayer_requests').update(dbPatch).eq('id', id);
  }
}
