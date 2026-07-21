import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_colors.dart';
import '../../data/repositories/assistant_repository.dart';
import '../../widgets/pg_back_button.dart';
import '../../widgets/pg_pill.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _repo = AssistantRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  final List<AssistantMessage> _messages = const [
    AssistantMessage(
      role: 'assistant',
      text: "Peace to you. What's on your heart today? I can help you find scripture, shape a prayer, or sit with a hard question.",
    ),
  ].toList();

  Future<void> _send([String? text]) async {
    final content = (text ?? _input.text).trim();
    if (content.isEmpty || _sending) return;
    setState(() {
      _messages.add(AssistantMessage(role: 'user', text: content));
      _input.clear();
      _sending = true;
    });
    _scrollDown();
    try {
      final reply = await _repo.send(_messages);
      setState(() => _messages.add(AssistantMessage(role: 'assistant', text: reply)));
    } catch (_) {
      setState(() => _messages.add(const AssistantMessage(
            role: 'assistant',
            text:
                "I'm not connected yet — the assistant needs its Edge Function deployed with an Anthropic API key. Ask your developer to run `supabase functions deploy assistant-proxy` with `ANTHROPIC_API_KEY` set.",
          )));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                children: [
                  PgBackButton(onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prayer Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Here to help you pray, not replace it', style: TextStyle(fontSize: 11.5, color: c.faint)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/upgrade'),
                    style: TextButton.styleFrom(
                      backgroundColor: c.amberSoft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    child: Text('Premium', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.amber)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  final m = _messages[i];
                  final isUser = m.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isUser ? c.teal : c.surface,
                        border: isUser ? null : Border.all(color: c.line),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 5),
                          bottomRight: Radius.circular(isUser ? 5 : 18),
                        ),
                      ),
                      child: Text(m.text, style: TextStyle(fontSize: 14.5, height: 1.6, color: isUser ? c.onTeal : c.text)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  PgPill(label: 'Suggest a scripture', onTap: () => _send('Suggest a scripture for today.')),
                  const SizedBox(width: 8),
                  PgPill(label: 'Prayer for my family', onTap: () => _send('Help me pray for my family.')),
                  const SizedBox(width: 8),
                  PgPill(label: 'Explain this verse', onTap: () => _send('Can you explain a verse to me?')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: "Ask or share what's on your heart…",
                        hintStyle: TextStyle(color: c.faint),
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: c.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: c.line)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: c.teal)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: c.teal,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _send(),
                      child: SizedBox(width: 46, height: 46, child: Icon(Icons.arrow_forward_rounded, color: c.onTeal)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
