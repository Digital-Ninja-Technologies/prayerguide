import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/pg_colors.dart';
import '../../core/theme/pg_text.dart';
import '../../data/scripture/scripture_of_day_library.dart';
import '../../state/bible_library_provider.dart';
import '../../widgets/pg_button.dart';
import '../../widgets/pg_header.dart';
import 'scripture_share_card.dart';

class ScriptureScreen extends ConsumerStatefulWidget {
  const ScriptureScreen({super.key});

  @override
  ConsumerState<ScriptureScreen> createState() => _ScriptureScreenState();
}

class _ScriptureScreenState extends ConsumerState<ScriptureScreen> {
  final _cardKey = GlobalKey();
  bool _exporting = false;

  Future<Uint8List> _captureCard() async {
    // Two frames so the off-screen ScriptureShareCard (built alongside the
    // real UI below) is guaranteed laid out and painted at least once
    // before capture — on the very first build a single frame can race it.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('The card isn\'t ready yet — try again in a moment.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Could not render the card.');
    return byteData.buffer.asUint8List();
  }

  Future<void> _saveCard() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _captureCard();
      await Gal.putImageBytes(bytes,
          name: 'prayer_guide_scripture_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to your photos'),
            action: SnackBarAction(label: 'View', onPressed: () => Gal.open()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't save — $e")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareCard() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _captureCard();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/prayer_guide_scripture_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Scripture of the Day, from Prayer Guide 🙏',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't share — $e")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();
    final entry = scriptureOfDayForDate(today);
    final libraryAsync = ref.watch(bibleLibraryProvider);
    final dateLabel = DateFormat('MMMM d').format(today);
    final quote = libraryAsync.valueOrNull == null
        ? ''
        : () {
            final verses =
                libraryAsync.value!.versesFor(entry.book, entry.chapter);
            return verses.isEmpty
                ? ''
                : verses.sublist(entry.verseStart - 1, entry.verseEnd).join(' ');
          }();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 6, 14, 0),
                child: PgHeader(
                  eyebrow: dateLabel.toUpperCase(),
                  onBack: () => context.pop(),
                  trailing: quote.isEmpty
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _exporting ? null : _saveCard,
                              tooltip: 'Save as image',
                              icon: _exporting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: c.dim))
                                  : Icon(Icons.download_rounded, color: c.dim),
                            ),
                            IconButton(
                              onPressed: _exporting ? null : _shareCard,
                              tooltip: 'Share',
                              icon: Icon(Icons.ios_share_rounded, color: c.dim),
                            ),
                          ],
                        ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text('SCRIPTURE OF THE DAY',
                                textAlign: TextAlign.center,
                                style: PgText.serif(
                                    size: 11, letterSpacing: 3, color: c.teal)),
                            const SizedBox(height: 20),
                            libraryAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (e, st) => Text(
                                  'Could not load scripture text.',
                                  style: TextStyle(color: c.danger)),
                              data: (library) => Text(
                                '"$quote"',
                                textAlign: TextAlign.center,
                                style: PgText.serif(
                                    size: 27, weight: FontWeight.w500, height: 1.5),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text('${entry.reference} · KJV',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: c.amber)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Block(
                          label: 'EXPLANATION',
                          labelColor: c.teal,
                          body: entry.explanation),
                      const SizedBox(height: 14),
                      _Block(
                          label: 'PRAYER FOCUS',
                          labelColor: c.amber,
                          body: entry.prayerFocus),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('REFLECTION QUESTION',
                                style: PgText.sans(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: c.dim,
                                    letterSpacing: 1)),
                            const SizedBox(height: 10),
                            Text(entry.question,
                                style: PgText.serif(size: 18, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      PgButton(
                          label: 'Pray on this',
                          onPressed: () =>
                              context.push('/timer?category=Scripture')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Off-screen — never visible, exists purely so `_cardKey` has a
          // real RenderRepaintBoundary to capture into a PNG on demand.
          if (quote.isNotEmpty)
            Positioned(
              left: -ScriptureShareCard.width - 50,
              top: 0,
              child: RepaintBoundary(
                key: _cardKey,
                child: ScriptureShareCard(
                  quote: quote,
                  reference: entry.reference,
                  dateLabel: dateLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(
      {required this.label, required this.labelColor, required this.body});

  final String label;
  final Color labelColor;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PgText.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(fontSize: 15, height: 1.65, color: c.text)),
        ],
      ),
    );
  }
}
