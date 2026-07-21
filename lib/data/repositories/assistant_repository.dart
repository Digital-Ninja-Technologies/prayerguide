import '../../core/supabase/supabase_config.dart';

class AssistantMessage {
  const AssistantMessage({required this.role, required this.text});
  final String role; // 'user' | 'assistant'
  final String text;
}

/// Talks to the `assistant-proxy` Supabase Edge Function (see
/// supabase/functions/assistant-proxy), which forwards to Claude using a
/// server-side-only API key. Throws if the function isn't deployed yet.
class AssistantRepository {
  Future<String> send(List<AssistantMessage> history) async {
    final res = await supa.functions.invoke(
      'assistant-proxy',
      body: {
        'messages': [
          for (final m in history) {'role': m.role, 'content': m.text},
        ],
      },
    );
    final data = res.data;
    if (data is Map && data['content'] is List && (data['content'] as List).isNotEmpty) {
      final first = (data['content'] as List).first;
      if (first is Map && first['text'] is String) return first['text'] as String;
    }
    throw StateError('Unexpected response from assistant-proxy: $data');
  }
}
