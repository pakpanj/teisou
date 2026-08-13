import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/card_game_rank.dart';
import 'battle_screen.dart';

/// A manual test aid for Tahap 2 butir 6 in `NOTES_CARD_GAME_MODE.md`
/// ("uji jalur cepatnya dulu secara manual — dua emulator/device saling
/// baca-tulis `battleMatches` langsung, tanpa Cloud Function sama
/// sekali") — **not a real product flow**. There's no invite or
/// matchmaking system yet (Tahap 3), so this is the only way to get two
/// real accounts into the same `battleMatches` doc right now: type in
/// the second account's uid by hand.
///
/// Deliberately not wired into any real navigation (`ModulesSection`,
/// Profile, etc.) — this is a developer tool, not something an end user
/// should ever stumble into. Reach it by temporarily pushing it from
/// wherever's convenient while testing, then remove that temporary
/// entry point again.
///
/// Both decks are built from *this* signed-in account's own current
/// tier (`CardGameRank.tier.cardContent`) — a real match would look up
/// each player's own tier separately, but for a same-tier manual test
/// this is one fewer lookup and one fewer thing that can go wrong while
/// verifying the fast path itself.
class BattleTestStartScreen extends ConsumerStatefulWidget {
  const BattleTestStartScreen({super.key});

  @override
  ConsumerState<BattleTestStartScreen> createState() =>
      _BattleTestStartScreenState();
}

class _BattleTestStartScreenState extends ConsumerState<BattleTestStartScreen> {
  final _opponentUidController = TextEditingController();
  final _joinMatchIdController = TextEditingController();
  bool _creating = false;
  String? _error;
  String? _createdMatchId;

  @override
  void dispose() {
    _opponentUidController.dispose();
    _joinMatchIdController.dispose();
    super.dispose();
  }

  void _joinMatch() {
    final matchId = _joinMatchIdController.text.trim();
    if (matchId.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId)));
  }

  Future<void> _createMatch() async {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final opponentUid = _opponentUidController.text.trim();
    if (myUid == null || opponentUid.isEmpty) return;

    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final rank = await ref
          .read(progressRepositoryProvider)
          .getCardGameRank(myUid);
      final cardData = await ref.read(battleCardDataProvider.future);
      final deck = buildDeckIds(
        content: rank.tier.cardContent,
        allKana: cardData.$1,
        allKanji: cardData.$2,
      );
      final matchId = await ref
          .read(battleRepositoryProvider)
          .createMatch(
            firstCandidateUid: myUid,
            firstCandidateDeck: deck,
            secondCandidateUid: opponentUid,
            secondCandidateDeck: deck,
          );
      if (!mounted) return;
      setState(() => _createdMatchId = matchId);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => BattleScreen(matchId: matchId)));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(s.battleTestTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.battleTestDescription),
            const SizedBox(height: 16),
            SelectableText('Uid saya: ${myUid ?? '...'}'),
            const SizedBox(height: 16),
            TextField(
              controller: _opponentUidController,
              decoration: InputDecoration(
                labelText: s.battleTestOpponentUidLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: context.palette.errorRed),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _creating ? null : _createMatch,
              child: _creating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.battleTestCreateButton),
            ),
            if (_createdMatchId != null) ...[
              const SizedBox(height: 8),
              SelectableText('Match dibuat: $_createdMatchId'),
            ],
            const Divider(height: 48),
            Text(s.battleTestJoinDescription),
            const SizedBox(height: 16),
            TextField(
              controller: _joinMatchIdController,
              decoration: InputDecoration(
                labelText: s.battleTestMatchIdLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _joinMatch,
              child: Text(s.battleTestJoinButton),
            ),
          ],
        ),
      ),
    );
  }
}
