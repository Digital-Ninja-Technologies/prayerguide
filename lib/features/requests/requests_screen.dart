import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/models/prayer_request.dart';
import '../../state/requests_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_card.dart';
import '../../widgets/pg_error_state.dart';
import '../../widgets/pg_header.dart';
import '../../widgets/pg_icon_badge.dart';
import '../../widgets/pg_pill.dart';

final _dateFmt = DateFormat('MMM d');

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String _tab = 'active';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reqsAsync = ref.watch(requestsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: PgHeader(
              title: 'Requests',
              onBack: () => context.pop(),
              trailing: PgButton(
                label: 'Add',
                expand: false,
                dense: true,
                icon: Icon(Icons.add_rounded, color: c.onTeal, size: 16),
                onPressed: () => context.push('/requests/new'),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(requestsProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    reqsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, st) => PgErrorState(
                          error: e,
                          onRetry: () => ref.invalidate(requestsProvider)),
                      data: (reqs) {
                        if (reqs.isEmpty) {
                          return _EmptyState(
                              onAdd: () => context.push('/requests/new'));
                        }

                        final byStatus = <String, List<PrayerRequest>>{};
                        for (final r in reqs) {
                          (byStatus[r.status] ??= []).add(r);
                        }
                        final filtered = byStatus[_tab] ?? const [];
                        final notifier = ref.read(requestsProvider.notifier);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (final t in const [
                                  ('active', 'Active'),
                                  ('answered', 'Answered'),
                                  ('archived', 'Archived')
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: PgPill(
                                      label:
                                          '${t.$2} · ${byStatus[t.$1]?.length ?? 0}',
                                      active: _tab == t.$1,
                                      onTap: () => setState(() => _tab = t.$1),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (filtered.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                    child: Text('Nothing here yet.',
                                        style: TextStyle(
                                            color: c.faint, fontSize: 14))),
                              )
                            else
                              for (final r in filtered)
                                _RequestCard(
                                    key: ValueKey(r.id),
                                    request: r,
                                    notifier: notifier),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(
      {super.key, required this.request, required this.notifier});
  final PrayerRequest request;
  final RequestsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final meta = request.status == 'answered'
        ? 'Answered ${_dateFmt.format(request.updatedAt)}'
        : 'Added ${_dateFmt.format(request.createdAt)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PgCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _Badge(
                        label: request.category.toUpperCase(),
                        bg: c.tealSoft,
                        fg: c.teal),
                    if (request.sharedWithCompanion) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.diversity_1_outlined, size: 15, color: c.dim),
                    ],
                  ],
                ),
                if (request.status == 'answered')
                  _Badge(label: 'Answered', bg: c.amberSoft, fg: c.amber)
                else if (request.reminder)
                  _Badge(
                      label: 'Daily',
                      bg: c.surface2,
                      fg: c.dim,
                      icon: Icons.notifications_none_rounded),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.title,
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(meta,
                style: TextStyle(
                    fontSize: 12.5,
                    color: c.faint,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            if (request.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Remind',
                      icon: Icons.notifications_none_rounded,
                      active: request.reminder,
                      onTap: () => notifier.toggleReminder(request.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Answered',
                      icon: Icons.check_rounded,
                      color: c.amber,
                      onTap: () => notifier.markAnswered(request.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                      icon: Icons.archive_outlined,
                      fixedWidth: 40,
                      onTap: () => notifier.archive(request.id)),
                ],
              )
            else if (request.status == 'answered')
              Row(
                children: [
                  Expanded(
                      child: _ActionBtn(
                          label: 'Reopen',
                          onTap: () => notifier.restore(request.id))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ActionBtn(
                          label: 'Archive',
                          onTap: () => notifier.archive(request.id))),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                        label: 'Restore to active',
                        color: c.teal,
                        onTap: () => notifier.restore(request.id)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Delete',
                      color: c.danger,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: c.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            title: const Text('Delete this request?'),
                            content: const Text("This can't be undone."),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Delete',
                                    style: TextStyle(color: c.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) notifier.delete(request.id);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Small `border-radius:100` status/category tag — distinct from [PgPill]
/// (tab/segment control sizing) in padding, font size and optional icon.
class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label, required this.bg, required this.fg, this.icon});
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4)
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

/// Outlined tappable pill — label+icon by default, or a fixed-width
/// icon-only button when [fixedWidth] is set and [label] is omitted.
class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {this.label,
      this.icon,
      this.active = false,
      this.color,
      this.fixedWidth,
      required this.onTap});
  final String? label;
  final IconData? icon;
  final bool active;
  final Color? color;
  final double? fixedWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? c.teal : (color ?? c.dim);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: label == null ? 15 : 14, color: fg),
            if (label != null) const SizedBox(width: 5)
          ],
          if (label != null)
            Text(label!,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
    return Material(
      color: active ? c.tealSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: active ? c.teal : c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: fixedWidth != null
            ? SizedBox(width: fixedWidth, height: 38, child: content)
            : content,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
      child: Column(
        children: [
          PgIconBadge(
              icon: Icons.favorite_border_rounded,
              color: c.amber,
              background: c.amberSoft,
              size: 78,
              iconSize: 36,
              radius: 24),
          const SizedBox(height: 16),
          Text('Nothing to carry yet',
              style: PgText.serif(size: 21, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 250,
            child: Text(
              "Add the people and needs on your heart. We'll help you remember to lift them up — and celebrate when they're answered.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: c.dim),
            ),
          ),
          const SizedBox(height: 16),
          PgButton(label: 'Add a request', expand: false, onPressed: onAdd),
        ],
      ),
    );
  }
}
