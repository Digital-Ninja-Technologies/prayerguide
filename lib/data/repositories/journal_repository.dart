import '../../core/security/encryption_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final _enc = EncryptionService.instance;

  Future<List<JournalEntry>> fetchAll() async {
    final uid = supa.auth.currentUser!.id;
    final rows = await supa
        .from('journal_entries')
        .select()
        .order('created_at', ascending: false);

    final entries = <JournalEntry>[];
    for (final r in rows as List) {
      final row = r as Map<String, dynamic>;
      final title = await _enc.decrypt(uid, row['title_cipher'] as String);
      final body = await _enc.decrypt(uid, row['body_cipher'] as String);
      entries.add(JournalEntry.fromMap({
        ...row,
        'title': title ?? '🔒 Unable to decrypt on this device',
        'body': body ?? '',
      }));
    }
    return entries;
  }

  Future<JournalEntry> create({
    required String type,
    required String title,
    required String body,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final titleCipher = await _enc.encrypt(uid, title);
    final bodyCipher = await _enc.encrypt(uid, body);
    final row = await supa
        .from('journal_entries')
        .insert({
          'user_id': uid,
          'type': type,
          'title_cipher': titleCipher,
          'body_cipher': bodyCipher,
        })
        .select()
        .single();
    // We already have the plaintext locally — no need to round-trip decrypt.
    return JournalEntry.fromMap({...row, 'title': title, 'body': body});
  }

  Future<JournalEntry> update({
    required String id,
    required String type,
    required String title,
    required String body,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final titleCipher = await _enc.encrypt(uid, title);
    final bodyCipher = await _enc.encrypt(uid, body);
    final row = await supa
        .from('journal_entries')
        .update({
          'type': type,
          'title_cipher': titleCipher,
          'body_cipher': bodyCipher,
        })
        .eq('id', id)
        .select()
        .single();
    return JournalEntry.fromMap({...row, 'title': title, 'body': body});
  }

  Future<void> delete(String id) =>
      supa.from('journal_entries').delete().eq('id', id);
}
