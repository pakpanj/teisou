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
import '../../data/repositories/battle_repository.dart' show battleBotUid;
import '../../core/constants/card_skins.dart';
import '../../core/widgets/mascot_widget.dart';
import 'battle_invite_providers.dart';
import 'widgets/star_result_card.dart';
import 'widgets/battle_arena.dart';

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
  int? _choiceTimeoutHandledForRound;

  final Map<int, bool> _correctByRound = {};
  DateTime? _flashUntil;
  bool _flashWasCorrect = false;
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
        match.effectiveCardId(round) ?? match.turnOrder[round].cardId,
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
      _flashWasCorrect = correct;
      _flashUntil = DateTime.now().add(const Duration(milliseconds: 900));
      changed = true;
    }
    if (!mounted) return;
    if (changed) setState(() {});
    _maybeConclude(match);
  }

  void _maybeConclude(BattleMatch match) {
    if (_localClientResult != null) return;
    // **How far the match has got comes from the match, not from the
    // answers this device happens to have seen.**
    //
    // It used to be `_correctByRound.length - 1`, on the reasoning that
    // rounds resolve in strict order so the keys form a contiguous
    // prefix. True of the writes; not true of what arrives here. A round
    // whose card fails to resolve is skipped by `_onAnswersUpdate`
    // without recording anything, and any answer document that never
    // shows up leaves the same hole — after which this count is
    // permanently one or more short of the real progress.
    //
    // For a match decided on points that only delays the result. For a
    // **draw** it never resolves at all: the tie can only be called at
    // the very last round, the count never reaches it, and the screen
    // sits on a bare spinner with the match already over. Reported after
    // a real drawn match.
    //
    // `currentRound` advances only when a round resolves, so minus one
    // is exactly the highest resolved round, whatever this device
    // received.
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final conclusion = conclusionAt(
      players: match.players,
      tally: tally,
      currentRound: match.currentRound,
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

    final limit = roundBudget(
      match.currentRound,
      ownerIsBot: match.turnOrder[match.currentRound].deckOwnerUid ==
          battleBotUid,
    );
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
    // **Whoever is looking at an expired round pushes it along**, no
    // matter which side of it they are on.
    //
    // This used to be "only the WAITING player (this round's deck owner)
    // forces the advance" — see NOTES_CARD_GAME_MODE.md's "Kalau lawan
    // menutup aplikasi di tengah pertandingan" — which covers an
    // opponent who closes the app mid-match and leaves a hole wherever
    // the *other* player is the one who never shows up at all. Two of
    // those, both reproduced on a device, both freezing the match on one
    // card forever:
    //
    // - against BOT, which never runs a client, on any round BOT owns;
    // - against a human who was invited and never joined (declined the
    //   invitation, or never opened it), on any round they own.
    //
    // The first was patched by special-casing BOT. The second has the
    // same shape and no such sentinel to test for, so the special case
    // is gone and both are closed by dropping the restriction instead.
    // Double-advancing is not a risk: `submitAnswer` writes inside a
    // transaction that only proceeds while `currentRound` still equals
    // this round, so a simultaneous force from both sides leaves the
    // second one a no-op.
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
      // Every round is played and the result has not been worked out
      // yet. Concluding was previously driven only by the answers
      // stream, so if its last event had already been and gone this
      // screen waited on something that was never coming again — the
      // spinner a drawn match got stuck on. The match document
      // updating is the other thing that can mean "it is over", so it
      // gets to conclude too.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeConclude(match);
      });
      return const Center(child: CircularProgressIndicator());
    }

    final entry = match.turnOrder[match.currentRound];
    final ownerIsBot = entry.deckOwnerUid == battleBotUid;
    final chosen = match.playedCards[match.currentRound];
    // The choosing window is over the moment its owner picks, and
    // otherwise when the clock runs out — after which the card dealt to
    // this round is what goes out.
    final choosing = chosen == null && !ownerIsBot && _sinceTurnStart(match) <
        cardChoiceWindow(ownerIsBot: ownerIsBot);
    final card = resolveCard(
      match.effectiveCardId(match.currentRound) ?? entry.cardId,
      cardData.$1,
      cardData.$2,
    );
    if (card == null) {
      return Center(child: Text(s.battleCardNotFound));
    }
    final iChoose = entry.deckOwnerUid == myUid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureTimerFor(match);
    });
    if (choosing) _scheduleChoiceDeadline(match, ownerIsBot: ownerIsBot);

    final isAnswerer = match.currentAnswererUid == myUid;
    final palette = context.palette;
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final opponentUid = match.players.firstWhere(
      (p) => p != myUid,
      orElse: () => myUid,
    );
    final identities =
        ref.watch(battleOpponentsProvider(match.players)).valueOrNull;

    return BattleBackdrop(
      child: Column(
        children: [
          BattleScorePanel(
            strings: s,
            round: match.currentRound + 1,
            totalRounds: match.turnOrder.length,
            remaining: _remaining,
            limit: roundBudget(match.currentRound, ownerIsBot: ownerIsBot),
            me: BattlePlayerChip(
              entry: identities?[myUid],
              fallbackName: s.battleYouLabel,
              score: tally.scoreOf(myUid),
              isMe: true,
              isTheirTurn: isAnswerer,
            ),
            opponent: BattlePlayerChip(
              entry: identities?[opponentUid],
              fallbackName: opponentUid == battleBotUid
                  ? s.battleBotName
                  : s.battleOpponentLabel,
              score: tally.scoreOf(opponentUid),
              isMe: false,
              isTheirTurn: !isAnswerer,
              isBot: opponentUid == battleBotUid,
            ),
          ),
          Expanded(
            // Pinned near the top of the space rather than floating in
            // the middle of it: with the hand or the keyboard taking the
            // bottom third, centring left a screen's worth of empty
            // background between the scores and the card.
            child: Align(
              alignment: const Alignment(0, -0.55),
              child: choosing
                  ? BattleCardFace(
                      // Face down while its owner decides: revealing the
                      // dealt card here would show the answerer a card
                      // that may never be played.
                      prompt: '',
                      faceDown: true,
                      // The skin belongs to whoever owns this card, so
                      // what you see while waiting is your opponent's,
                      // and what they see while you choose is yours.
                      // Resolved through the unlock rule, not read raw:
                      // an achievement skin whose owner has dropped below
                      // its threshold has to stop showing on *their*
                      // opponent's screen too, or the lock means nothing
                      // to anyone but themselves.
                      skin: effectiveCardSkin(
                        identities?[entry.deckOwnerUid]?.cardSkinId,
                        starTotal: identities?[entry.deckOwnerUid]
                                ?.cardGameStarTotal ??
                            0,
                        allUnlocked: kCardSkinsAllUnlocked,
                      ),
                      caption: iChoose
                          ? s.battleChooseYourCard
                          : s.battleOpponentChoosing,
                      flashColor: null,
                    )
                  : BattleCardFace(
                      prompt: card.prompt,
                      caption: isAnswerer
                          ? s.battleCardFromOpponent
                          : s.battleCardFromYou,
                      // Face up, the card still belongs to whoever dealt
                      // it, so it keeps wearing their skin — the whole
                      // point of a cosmetic your opponent sees is that
                      // they see it while they are looking at the card,
                      // not only for the second it stays face down.
                      // Resolved through the unlock rule for the same
                      // reason the face-down branch above does.
                      skin: effectiveCardSkin(
                        identities?[entry.deckOwnerUid]?.cardSkinId,
                        starTotal: identities?[entry.deckOwnerUid]
                                ?.cardGameStarTotal ??
                            0,
                        allUnlocked: kCardSkinsAllUnlocked,
                      ),
                      flashColor: _flashColor(context),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BattleDeckStrip(slots: _deckSlots(match)),
          ),
          const SizedBox(height: 12),
          if (choosing && iChoose)
            BattleHand(
              title: s.battleChooseYourCard,
              secondsLeft: _choiceSecondsLeft(match, ownerIsBot: ownerIsBot),
              cards: _handCards(match, myUid, cardData),
              onPlay: (cardId) => ref.read(battleRepositoryProvider).playCard(
                matchId: widget.matchId,
                round: match.currentRound,
                cardId: cardId,
              ),
            )
          else if (choosing)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.battleOpponentChoosing,
                style: TextStyle(
                  color: palette.textNavy.withValues(alpha: 0.6),
                ),
              ),
            )
          else if (isAnswerer)
            _buildAnswerInput(context, s, match, card)
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.battleWaitingForOpponent,
                style: TextStyle(
                  color: palette.textNavy.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Puts the dealt card on the table when nobody chose in time.
  ///
  /// Making the reveal an explicit write, rather than something each
  /// device works out from the clock on its own, is what lets everything
  /// else react to it — the bot in particular waits for this write
  /// before answering, and without it a round whose owner said nothing
  /// would sit there with no card ever appearing.
  ///
  /// Whichever device is watching does it, not just the owner: an owner
  /// who has closed the app is exactly the case that needs covering, and
  /// `playCard` ignores a second write for a round that already has a
  /// card.
  void _scheduleChoiceDeadline(BattleMatch match, {required bool ownerIsBot}) {
    final round = match.currentRound;
    if (_choiceTimeoutHandledForRound == round) return;
    _choiceTimeoutHandledForRound = round;
    final left = cardChoiceWindow(ownerIsBot: ownerIsBot) -
        _sinceTurnStart(match);
    Timer(left.isNegative ? Duration.zero : left, () {
      if (!mounted) return;
      final current = ref.read(battleMatchProvider(widget.matchId)).valueOrNull;
      if (current == null) return;
      if (current.currentRound != round) return;
      if (current.playedCards.containsKey(round)) return;
      ref.read(battleRepositoryProvider).playCard(
        matchId: widget.matchId,
        round: round,
        cardId: current.turnOrder[round].cardId,
      );
    });
  }

  /// How long this round has been running, from the server anchor.
  Duration _sinceTurnStart(BattleMatch match) {
    final anchor = match.turnStartedAt;
    if (anchor == null) return Duration.zero;
    return DateTime.now().difference(anchor);
  }

  int _choiceSecondsLeft(BattleMatch match, {required bool ownerIsBot}) {
    final left = cardChoiceWindow(ownerIsBot: ownerIsBot) -
        _sinceTurnStart(match);
    return left.isNegative ? 0 : left.inSeconds + 1;
  }

  /// The player's remaining cards, resolved to what each one shows.
  List<({String cardId, String prompt})> _handCards(
    BattleMatch match,
    String myUid,
    (List<KanaCharacter>, List<KanjiEntry>) cardData,
  ) {
    final out = <({String cardId, String prompt})>[];
    for (final cardId in match.remainingHand(myUid)) {
      final card = resolveCard(cardId, cardData.$1, cardData.$2);
      if (card != null) out.add((cardId: cardId, prompt: card.prompt));
    }
    return out;
  }

  /// One slot per round: how each has come out, for [BattleDeckStrip].
  List<BattleSlotState> _deckSlots(BattleMatch match) {
    return [
      for (var i = 0; i < match.turnOrder.length; i++)
        if (i == match.currentRound)
          BattleSlotState.current
        else if (_correctByRound[i] == true)
          BattleSlotState.correct
        else if (_correctByRound[i] == false)
          BattleSlotState.wrong
        else
          BattleSlotState.upcoming,
    ];
  }

  /// Tints the card for a moment after the round just gone resolved.
  /// Deliberately driven by the *previous* round's result: by the time
  /// this rebuild happens the turn has already moved on, so keying it to
  /// the current round would never show anything.
  Color? _flashColor(BuildContext context) {
    if (_flashUntil == null || DateTime.now().isAfter(_flashUntil!)) {
      return null;
    }
    return _flashWasCorrect
        ? context.palette.secondaryBlue
        : context.palette.errorRed;
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
            // Four rows at a fingertip's height each. The old 220 was
            // holding twelve rows and crushing every one of them.
            height: 200,
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

    final identities =
        ref.watch(battleOpponentsProvider(match.players)).valueOrNull;
    final palette = context.palette;

    // Counted over the rounds *I* answered. A deck owner never answers
    // their own card, so counting every round would credit me with the
    // opponent's mistakes alongside my own.
    var correct = 0;
    var wrong = 0;
    for (var round = 0; round < match.turnOrder.length; round++) {
      if (match.turnOrder[round].deckOwnerUid == myUid) continue;
      final answered = _correctByRound[round];
      if (answered == null) continue;
      answered ? correct++ : wrong++;
    }
    final played = match.currentRound.clamp(0, match.turnOrder.length);
    final started = match.createdAt;
    final duration =
        started == null ? null : DateTime.now().difference(started);

    return BattleBackdrop(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Center(
            child: MascotWidget(
              // Never `sad`, even on a loss — the same rule MascotCoach
              // already follows for wrong answers: the audience is
              // children, and a mascot that looks let down by them is
              // the thing this app decided not to do.
              mood: isDraw
                  ? MascotMood.curious
                  : (iWon ? MascotMood.cheering : MascotMood.encouraging),
              size: 120,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isDraw
                  ? s.battleResultDraw
                  : (iWon ? s.battleResultWin : s.battleResultLose),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: iWon ? palette.primaryCoral : palette.textNavy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BattlePlayerChip(
                entry: identities?[myUid],
                fallbackName: s.battleYouLabel,
                score: tally.scoreOf(myUid),
                isMe: true,
                isTheirTurn: false,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.textNavy.withValues(alpha: 0.4),
                  ),
                ),
              ),
              BattlePlayerChip(
                entry: identities?[opponentUid],
                fallbackName: opponentUid == battleBotUid
                    ? s.battleBotName
                    : s.battleOpponentLabel,
                score: tally.scoreOf(opponentUid),
                isMe: false,
                isTheirTurn: false,
                isBot: opponentUid == battleBotUid,
              ),
            ],
          ),
          const SizedBox(height: 18),
          BattleResultStats(
            strings: s,
            correct: correct,
            wrong: wrong,
            cards: played,
            duration: duration,
          ),
          const SizedBox(height: 18),
          StarResultCard(match: match, myUid: myUid, strings: s),
          const SizedBox(height: 22),
          BattleResultReview(
            title: s.battleReviewTitle,
            cards: _reviewCards(match, myUid),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (match.rankedMatch) ...[
                  Expanded(
                    child: OutlinedButton(
                      // Pops back to whichever screen started this match,
                      // which for a ranked match is the search screen —
                      // so "play again" lands exactly where playing again
                      // begins. Deliberately not a true rematch against
                      // the same opponent: that needs an invite the other
                      // player may never answer.
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(s.battlePlayAgain),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(s.battleResultDone),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Every round that actually resolved, in order, for the review row.
  List<BattleReviewCard> _reviewCards(BattleMatch match, String myUid) {
    final cardData = ref.read(battleCardDataProvider).valueOrNull;
    if (cardData == null) return const [];
    final cards = <BattleReviewCard>[];
    for (var round = 0; round < match.turnOrder.length; round++) {
      final correct = _correctByRound[round];
      if (correct == null) continue; // never played (match ended early)
      final entry = match.turnOrder[round];
      final card = resolveCard(
        match.effectiveCardId(round) ?? entry.cardId,
        cardData.$1,
        cardData.$2,
      );
      if (card == null) continue;
      cards.add(
        BattleReviewCard(
          prompt: card.prompt,
          reading: card.correctRomaji,
          correct: correct,
          mine: entry.deckOwnerUid != myUid,
        ),
      );
    }
    return cards;
  }
}
