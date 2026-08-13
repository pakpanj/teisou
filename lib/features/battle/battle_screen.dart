import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/services/battle_score_tally.dart';
import '../../core/services/battle_timer.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/kana_keyboard.dart';
import '../../data/models/battle_answer.dart';
import '../../data/models/battle_match.dart';
import '../../data/models/kana_character.dart';
import '../../data/models/kanji_entry.dart';
import 'widgets/star_result_card.dart';

/// Card Game Mode's live match screen — Tahap 2 butir 5 in
/// `NOTES_CARD_GAME_MODE.md`. Renders one `battleMatches/{matchId}` doc
/// and plays it: shows the current card, lets the answering player type
/// (romaji on the device's own keyboard for kana cards, hiragana via
/// [KanaKeyboard] for kanji cards), and shows the waiting player a
/// "menunggu" state.
///
/// **Everything shown here — correctness, running score, and the final
/// win/lose/draw — is the client's own "fast path" guess, never
/// authoritative.** `BattleMatch.officialScore`/`result` stay untouched
/// by this screen; those are Cloud-Function-only (Tahap 2 butir 7, not
/// built yet). This is deliberate, matching Tahap 2 butir 6's own plan:
/// "uji jalur cepatnya dulu secara manual... tanpa Cloud Function sama
/// sekali" — this screen is exactly that manual test surface.
///
/// **Deliberately simpler than the full design in one respect**: the
/// waiting player doesn't get a transient "lawan menjawab: benar!" flash
/// the instant an answer lands — showing that correctly needs tracking a
/// round that has already been superseded by the next one (the same
/// write that records an answer also advances `currentRound`), which
/// adds real timing complexity for a first pass. Instead every resolved
/// round's correctness feeds the running score shown in the header, so
/// the outcome is still visible, just not as an animated moment.
class BattleScreen extends ConsumerStatefulWidget {
  final String matchId;

  const BattleScreen({super.key, required this.matchId});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  final _romajiController = TextEditingController();
  String _hiraganaBuffer = '';

  Timer? _timer;
  Duration _remaining = Duration.zero;
  int? _timerRoundGuard;
  int? _timeoutHandledForRound;

  final Map<int, bool> _correctByRound = {};
  StreamSubscription<Map<int, BattleAnswer>>? _answersSub;
  String? _localClientResult;

  @override
  void initState() {
    super.initState();
    _answersSub = ref
        .read(battleRepositoryProvider)
        .watchAllAnswers(widget.matchId)
        .listen(_onAnswersUpdate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answersSub?.cancel();
    _romajiController.dispose();
    super.dispose();
  }

  Future<void> _onAnswersUpdate(Map<int, BattleAnswer> answers) async {
    if (!mounted) return;
    final match = ref.read(battleMatchProvider(widget.matchId)).valueOrNull;
    final cardData = ref.read(battleCardDataProvider).valueOrNull;
    if (match == null || cardData == null) return;
    final romajiConverter = ref.read(romajiConverterProvider);

    var changed = false;
    for (final e in answers.entries) {
      final round = e.key;
      if (_correctByRound.containsKey(round)) continue;
      if (round < 0 || round >= match.turnOrder.length) continue;
      final card = resolveCard(
        match.turnOrder[round].cardId,
        cardData.$1,
        cardData.$2,
      );
      if (card == null) continue;

      final typed = e.value.text.trim();
      String romaji;
      if (typed.isEmpty) {
        romaji = '';
      } else if (card.answerInHiragana) {
        romaji = (await romajiConverter.convert(typed)).trim().toLowerCase();
      } else {
        romaji = typed.toLowerCase();
      }
      final correct =
          romaji.isNotEmpty &&
          romaji == card.correctRomaji.trim().toLowerCase();
      _correctByRound[round] = correct;
      changed = true;
    }
    if (!mounted) return;
    if (changed) setState(() {});
    _maybeConclude(match);
  }

  void _maybeConclude(BattleMatch match) {
    if (_localClientResult != null) return;
    // Rounds always resolve in strict order (submitAnswer's transaction
    // only succeeds when currentRound == round), so the resolved keys
    // are always a contiguous 0..N-1 prefix — length-1 is exactly the
    // highest fully-resolved round.
    final highestResolved = _correctByRound.length - 1;
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final conclusion = clientConclusion(
      players: match.players,
      tally: tally,
      highestResolvedRound: highestResolved,
    );
    if (conclusion == null) return;
    _localClientResult = conclusion;
    ref.read(battleRepositoryProvider).setClientResult(widget.matchId, conclusion);
    if (mounted) setState(() {});
  }

  void _ensureTimerFor(BattleMatch match) {
    if (_timerRoundGuard == match.currentRound) return;
    if (match.currentRound >= match.turnOrder.length) return;
    _timerRoundGuard = match.currentRound;
    _timer?.cancel();

    final limit = cardTimeLimit(match.currentRound);
    final anchor = match.turnStartedAt ?? DateTime.now();

    void tick() {
      if (!mounted) return;
      var remaining = limit - DateTime.now().difference(anchor);
      if (remaining.isNegative) remaining = Duration.zero;
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) {
        _timer?.cancel();
        _handleTimeout(match);
      }
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _handleTimeout(BattleMatch match) async {
    final round = match.currentRound;
    if (_timeoutHandledForRound == round) return;
    _timeoutHandledForRound = round;

    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    // Only the WAITING player (this round's deck owner) forces the
    // advance — see the class doc comment / NOTES_CARD_GAME_MODE.md's
    // "Kalau lawan menutup aplikasi di tengah pertandingan".
    if (match.turnOrder[round].deckOwnerUid != myUid) return;
    final answerer = match.currentAnswererUid;
    if (answerer == null) return;

    await ref
        .read(battleRepositoryProvider)
        .forfeitRoundOnTimeout(
          matchId: widget.matchId,
          round: round,
          answererUid: answerer,
        );
  }

  Future<void> _submit(BattleMatch match, BattleCard card) async {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    final text = card.answerInHiragana
        ? _hiraganaBuffer
        : _romajiController.text;
    if (text.trim().isEmpty) return;

    await ref
        .read(battleRepositoryProvider)
        .submitAnswer(
          matchId: widget.matchId,
          round: match.currentRound,
          byUid: myUid,
          text: text.trim(),
        );
    _romajiController.clear();
    setState(() => _hiraganaBuffer = '');
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(battleMatchProvider(widget.matchId));
    final cardDataAsync = ref.watch(battleCardDataProvider);
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.battleTitle)),
      body: matchAsync.when(
        data: (match) => cardDataAsync.when(
          data: (cardData) => _buildBody(context, s, match, cardData, myUid),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(s.battleLoadCardDataError(e))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(s.battleLoadMatchError(e))),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    (List<KanaCharacter>, List<KanjiEntry>) cardData,
    String? myUid,
  ) {
    if (myUid == null) {
      return Center(child: Text(s.battleNotSignedIn));
    }
    if (_localClientResult != null) {
      return _buildResult(context, s, match, myUid);
    }
    if (match.currentRound >= match.turnOrder.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final entry = match.turnOrder[match.currentRound];
    final card = resolveCard(entry.cardId, cardData.$1, cardData.$2);
    if (card == null) {
      return Center(child: Text(s.battleCardNotFound));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureTimerFor(match);
    });

    final isAnswerer = match.currentAnswererUid == myUid;
    final palette = context.palette;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.battleCardProgress(
                  match.currentRound + 1,
                  match.turnOrder.length,
                ),
                style: TextStyle(color: palette.textNavy, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_remaining.inSeconds}s',
                style: TextStyle(
                  color: _remaining.inSeconds <= 5
                      ? palette.errorRed
                      : palette.textNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        _buildScoreRow(context, s, match, myUid),
        Expanded(
          child: Center(
            child: Text(
              card.prompt,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: palette.textNavy,
              ),
            ),
          ),
        ),
        if (isAnswerer)
          _buildAnswerInput(context, s, match, card)
        else
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s.battleWaitingForOpponent,
              style: TextStyle(color: palette.textNavy.withValues(alpha: 0.6)),
            ),
          ),
      ],
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    String myUid,
  ) {
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final opponentUid = match.players.firstWhere(
      (p) => p != myUid,
      orElse: () => myUid,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(s.battleMyScore(tally.scoreOf(myUid))),
          Text(s.battleOpponentScore(tally.scoreOf(opponentUid))),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    BattleCard card,
  ) {
    final palette = context.palette;
    if (card.answerInHiragana) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: palette.divider),
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: Text(
              _hiraganaBuffer.isEmpty ? ' ' : _hiraganaBuffer,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: KanaKeyboard(
              value: _hiraganaBuffer,
              onChanged: (v) => setState(() => _hiraganaBuffer = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submit(match, card),
                child: Text(s.battleSendAnswer),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _romajiController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.battleRomajiHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(match, card),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _submit(match, card),
            child: Text(s.battleSendAnswer),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    String myUid,
  ) {
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final isDraw = _localClientResult == 'draw';
    final iWon = _localClientResult == myUid;
    final opponentUid = match.players.firstWhere(
      (p) => p != myUid,
      orElse: () => myUid,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isDraw
                ? s.battleResultDraw
                : (iWon ? s.battleResultWin : s.battleResultLose),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(s.battleMyScore(tally.scoreOf(myUid))),
          Text(s.battleOpponentScore(tally.scoreOf(opponentUid))),
          const SizedBox(height: 20),
          StarResultCard(match: match, myUid: myUid, strings: s),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(s.battleResultDone),
          ),
        ],
      ),
    );
  }
}
