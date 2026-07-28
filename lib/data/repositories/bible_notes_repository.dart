import '../../core/supabase/supabase_config.dart';
import '../models/bible_note.dart';

class BibleNotesRepository {
  Future<List<BibleNote>> fetchAll() async {
    final rows =
        await supa.from('bible_notes').select().order('created_at', ascending: false);
    return (rows as List).map((r) => BibleNote.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<BibleNote> create({
    required String kind,
    required String reference,
    String? verseText,
    String? note,
  }) async {
    final uid = supa.auth.currentUser!.id;
    final row = await supa
        .from('bible_notes')
        .insert({
          'user_id': uid,
          'kind': kind,
          'reference': reference,
          'verse_text': verseText,
          'note': note,
        })
        .select()
        .single();
    return BibleNote.fromMap(row);
  }

  Future<void> delete(String id) => supa.from('bible_notes').delete().eq('id', id);
}
