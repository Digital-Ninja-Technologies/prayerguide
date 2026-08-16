import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/sermon_share.dart';
import '../../state/sermon_shares_provider.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';

class SermonSharesInboxScreen extends ConsumerWidget {
  const SermonSharesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesAsync = ref.watch(sermonSharesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: PgHeader(title: 'Shared with you', onBack: () => context.pop()),
            ),
            Expanded(
              child: sharesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: PgErrorState(
                      error: e, onRetry: () => ref.invalidate(sermonSharesProvider)),
                ),
                data: (shares) {
                  if (shares.isEmpty) return const _EmptyState();
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(sermonSharesProvider.future),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                      child: Column(
                        children: [for (final s in shares) _ShareCard(share: s)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends ConsumerStatefulWidget {
  const _ShareCard({required this.share});
  final SermonShare share;

  @override
  ConsumerState<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends ConsumerState<_ShareCard> {
  bool _responding = false;
  String? _error;

  Future<void> _respond(bool accept) async {
    setState(() {
      _responding = true;
      _error = null;
    });
    try {
      if (accept) {
        await ref.read(sermonSharesProvider.notifier).accept(widget.share.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to your sermon notes')),
          );
        }
      } else {
        await ref.read(sermonSharesProvider.notifier).decline(widget.share.id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't respond — $e");
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final share = widget.share;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${share.senderName} shared a sermon note',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.dim)),
          const SizedBox(height: 6),
          Text(share.sermonTitle,
              style: PgText.serif(size: 17, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(DateFormat('MMM d, yyyy').format(share.createdAt),
              style: TextStyle(fontSize: 11.5, color: c.faint)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _responding ? null : () => _respond(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.line2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Decline', style: TextStyle(color: c.dim, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _responding ? null : () => _respond(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _responding
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.onTeal))
                      : Text('Accept',
                          style: TextStyle(color: c.onTeal, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                  color: c.tealSoft, borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.inbox_outlined, size: 36, color: c.teal),
            ),
            const SizedBox(height: 16),
            Text('Nothing shared with you yet',
                style: PgText.serif(size: 19, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'When someone shares a sermon note with you, it shows up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: c.dim),
            ),
          ],
        ),
      ),
    );
  }
}
