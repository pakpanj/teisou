import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/battle_rules.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/battle_deck_builder.dart';
import '../../core/services/battle_score_tally.dart';
import '../../core/services/battle_timer.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/kana_keyboard.dart';
import 'recent_matches_providers.dart';
import '../../data/models/battle_answer.dart';
import '../../data/models/battle_match.dart';
import '../../data/models/turn_order_entry.dart';
import '../../data/models/kana_character.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/battle_repository.dart' show battleBotUid;
import '../../core/constants/card_skins.dart';
import '../../core/widgets/mascot_widget.dart';
import 'battle_card_picker_screen.dart';
import 'battle_invite_providers.dart';
import 'widgets/star_result_card.dart';
import 'widgets/battle_arena.dart';
import '../../core/widgets/romaji_keyboard.dart';
import '../../core/widgets/keyboard_look.dart';

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
/// **Correction — the limitation this paragraph used to describe is
/// fixed (see C4 in `AUDIT_PHASE_C_BATTLE_RELIABILITY.md`).** Both
/// players now get a transient "Benar!"/"Salah!" badge, a colour flash,
/// and (for whoever actually answered) a haptic tap the moment a round
/// resolves — held on screen for [_BattleScreenState._feedbackHoldDuration]
/// via [_BattleScreenState._heldRound], specifically so the round that
/// has already been superseded by `currentRound` advancing still gets
/// shown before the next card takes over. See
/// [_BattleScreenState._showRoundFeedback] for the mechanism.
class BattleScreen extends ConsumerStatefulWidget {
  final String matchId;

  const BattleScreen({super.key, required this.matchId});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with WidgetsBindingObserver {
  /// What has been typed for the current card. One buffer, not one per
  /// answer type — both keyboards are this app's own now, so there is no
  /// `TextEditingController` left to keep in step with it.
  String _romajiBuffer = '';
  String _hiraganaBuffer = '';

  Timer? _timer;
  Duration _remaining = Duration.zero;
  int? _timerRoundGuard;
  int? _timeoutHandledForRound;
  int? _choiceTimeoutHandledForRound;
  int? _pickerOpenedForRound;

  final Map<int, bool> _correctByRound = {};
  DateTime? _flashUntil;
  bool _flashWasCorrect = false;
  StreamSubscription<Map<int, BattleAnswer>>? _answersSub;
  String? _localClientResult;

  /// C4 fix — how long the just-resolved round's card stays on screen
  /// after `match.currentRound` has already moved past it. See
  /// [_showRoundFeedback]'s doc comment for why this exists at all.
  static const _feedbackHoldDuration = Duration(milliseconds: 700);

  /// Which round's card the top of the screen is currently showing,
  /// overriding `match.currentRound` — null once no hold is active, in
  /// which case rendering falls back to the real current round exactly as
  /// before this phase. Visual-only: everything below the card (keyboard,
  /// choose button, waiting text) keeps reading `match.currentRound`
  /// directly and is never affected by this.
  int? _heldRound;

  /// Clears [_heldRound] at the end of its hold window — a real [Timer]
  /// rather than trusting some other incidental rebuild to notice
  /// [_flashUntil] has passed, since nothing else in this screen is
  /// guaranteed to rebuild promptly at exactly the 700ms mark otherwise
  /// (the per-second round timer only ticks once a second).
  Timer? _feedbackHoldTimer;

  /// The face-down-card auto-reveal fires once, later, off a bare
  /// [Timer] — tracked here so [dispose] can cancel it like every other
  /// timer in this screen, rather than trusting its own internal
  /// `mounted` guard alone to make an unwanted late call harmless.
  Timer? _choiceDeadlineTimer;

  /// When the match actually ended, stamped once.
  ///
  /// The result screen used to work out its duration with
  /// `DateTime.now().difference(started)` — evaluated on every build. This
  /// screen is built from the match stream, and writes keep landing after
  /// the final round (the star result, the other player's own result), so
  /// the "Durasi" figure crept upward while the learner sat looking at it.
  /// Reported from a real match: 01:15 climbing to 01:35 after the game
  /// was already won.
  DateTime? _finishedAt;

  /// The most recently seen match state — updated every `build()`, read
  /// from `dispose()` (which cannot itself watch a provider) to decide
  /// whether leaving this screen right now should mark this player as
  /// having abandoned an active match. See [_maybeMarkAbandoningOnLeave].
  BattleMatch? _lastKnownMatch;

  /// Reconnect grace period (2026-08-30) — mirrors [_timeoutHandledForRound]'s
  /// shape: which opponent-abandon episode this device has already
  /// scheduled a resolve call for, so a rebuild while the same countdown
  /// is still running doesn't start a second one. Reset to null whenever
  /// `match.abandon` itself goes back to null (a reconnect, or a
  /// finalize that already landed).
  DateTime? _abandonResolveScheduledFor;
  Timer? _abandonResolveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToAnswers();
    // Covers returning to an already-open BattleScreen instance (a quick
    // background/foreground cycle) as well as arriving fresh via the
    // "Kembali ke Pertandingan" resume card — either way, the very first
    // thing this screen does is say "I'm here" for its own uid.
    _clearOwnAbandonMark();
  }

  void _clearOwnAbandonMark() {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    ref.read(battleRepositoryProvider).clearAbandoning(widget.matchId);
  }

  /// Backgrounding/foregrounding while this screen stays mounted — the
  /// other half of leaving/returning that `dispose()`/`initState()` alone
  /// cannot see, since neither fires just from the app losing focus.
  /// **A true force-kill of the app is not covered by either path** —
  /// there is no reliable client-side hook for that on any platform, so
  /// that case still falls through to the older, unmodified per-round
  /// staleness sweep exactly as it always has (see
  /// `functions/battle_abandonment_sweep.js`'s own doc comment on this
  /// exact gap).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clearOwnAbandonMark();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _maybeMarkAbandoningOnLeave();
    }
    super.didChangeAppLifecycleState(state);
  }

  /// Split out of [initState] so a stream error can re-subscribe itself
  /// without duplicating the `listen(...)` call — see [_onAnswersError].
  void _subscribeToAnswers() {
    _answersSub = ref
        .read(battleRepositoryProvider)
        .watchAllAnswers(widget.matchId)
        .listen(_onAnswersUpdate, onError: _onAnswersError);
  }

  /// Hardening, not a confirmed fix for any specific crash report — see
  /// AUDIT_PHASE_C_BATTLE_RELIABILITY.md's C1 finding. This stream had no
  /// `onError` at all: an error event (plausible after an iOS background
  /// -> foreground cycle interrupts the underlying gRPC stream) would
  /// otherwise reach the zone's uncaught-error handler instead of this
  /// widget. Catching it here cannot regress anything that worked before,
  /// since "uncaught" was never a working state to begin with.
  ///
  /// One bounded re-subscribe attempt, not a retry loop: the Firestore
  /// SDK already retries the underlying connection on its own, so this
  /// only needs to give this *widget* a fresh subscription to listen on
  /// once that connection recovers, not re-implement backoff itself. If
  /// re-subscribing itself immediately errors again, [_onAnswersError]
  /// simply runs again and tries once more — never a tight synchronous
  /// loop, since each attempt waits for a real stream event (data or
  /// error) before firing again.
  void _onAnswersError(Object error, StackTrace stackTrace) {
    debugPrint('BattleScreen: answers stream error, re-subscribing: $error');
    if (!mounted) return;
    _answersSub?.cancel();
    _subscribeToAnswers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _maybeMarkAbandoningOnLeave();
    _timer?.cancel();
    _choiceDeadlineTimer?.cancel();
    _feedbackHoldTimer?.cancel();
    _abandonResolveTimer?.cancel();
    _answersSub?.cancel();
    super.dispose();
  }

  /// Marks this player away — back press, Home navigation, or any other
  /// way this screen stops being on top. Deliberately skipped once the
  /// match already has a `result`/is `finished`, or once this device's
  /// own fast-path already showed the conclusion screen
  /// ([_localClientResult] set): leaving a screen that is already over
  /// is not abandoning anything, it is just leaving.
  ///
  /// **[_lastKnownMatch] being `null` is NOT the same as "not active",
  /// and must not be treated as a reason to skip** — it only means this
  /// screen has not yet received its first snapshot from
  /// [battleMatchProvider], which can genuinely happen: a challenge is
  /// accepted, this screen mounts, and the very first Firestore listen
  /// has not resolved yet (even from local cache) before the screen is
  /// left again — a real gap this project's own reconnect-testing found
  /// live, orphaning a match with no `abandon` marker ever written for
  /// it, permanently, since nothing else was ever going to write one.
  /// Attempting the mark anyway when the match state is unknown is
  /// always safe: `firestore.rules`' `abandon` clause and the eventual
  /// resolve/sweep both already treat a target that turns out to not
  /// need it (already concluded, or a uid that isn't actually a player)
  /// as a harmless no-op — the whole reconnect design was already built
  /// to re-derive every fact server-side rather than trust what the
  /// client asserts, so there's nothing this optimistic attempt could
  /// get wrong that the server wouldn't have caught anyway.
  ///
  /// `dispose()` cannot `await` — Flutter tears the widget down
  /// synchronously right after this returns — so [BattleRepository
  /// .markAbandoning]'s own fire-and-forget write is exactly the shape
  /// this needs; nothing here waits for it to land.
  void _maybeMarkAbandoningOnLeave() {
    if (_localClientResult != null) return;
    final match = _lastKnownMatch;
    if (match != null &&
        (match.status != BattleMatchStatus.active || match.result != null)) {
      return;
    }
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    ref.read(battleRepositoryProvider).markAbandoning(widget.matchId, myUid);
  }

  /// Starts (once) a local countdown to the moment [match.abandon]'s
  /// grace period is up, then asks the server to actually finalize it —
  /// see [BattleRepository.resolveAbandonmentIfDue]'s own doc comment
  /// for why the client only ever *asks*, never decides. Only ever
  /// scheduled for the *opponent's* mark, never this device's own — a
  /// player cannot be the one who notices and resolves their own
  /// abandonment, they're the one who left.
  void _ensureAbandonResolveScheduled(BattleMatch match, String myUid) {
    final abandon = match.abandon;
    if (abandon == null || abandon.uid == myUid) {
      _abandonResolveTimer?.cancel();
      _abandonResolveTimer = null;
      _abandonResolveScheduledFor = null;
      return;
    }
    if (_abandonResolveScheduledFor == abandon.since) return;
    _abandonResolveScheduledFor = abandon.since;
    _abandonResolveTimer?.cancel();

    final since = abandon.since;
    final grace = const Duration(seconds: kBattleAbandonGracePeriodSeconds);
    // No known `since` yet (the serverTimestamp sentinel hasn't round-
    // tripped back down to this device) — fall back to the full grace
    // period from now; the next snapshot carrying a real timestamp will
    // reschedule this correctly.
    final delay = since == null
        ? grace
        : grace - DateTime.now().difference(since);
    _abandonResolveTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) return;
      ref.read(battleRepositoryProvider).resolveAbandonmentIfDue(widget.matchId);
    });
  }

  Future<void> _onAnswersUpdate(Map<int, BattleAnswer> answers) async {
    if (!mounted) return;
    final match = ref.read(battleMatchProvider(widget.matchId)).valueOrNull;
    final cardData = ref.read(battleCardDataProvider).valueOrNull;
    if (match == null || cardData == null) return;
    final romajiConverter = ref.read(romajiConverterProvider);
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;

    var changed = false;
    // C4: a single snapshot
    // can carry more than one never-seen-before round — normally just the
    // one that resolved a moment ago, but a rejoin/reconnect can deliver a
    // whole backlog at once. Only the highest-numbered one newly resolved
    // in *this* call gets the transient feedback (held card, badge,
    // haptic); anything older in the same batch is already superseded by
    // the time this runs, so showing feedback for it would describe a
    // moment that has already passed. Every round still gets its
    // correctness recorded either way, unconditionally — this only gates
    // the transient extras.
    int? latestNewRound;
    var latestNewCorrect = false;
    String? latestNewByUid;

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
      changed = true;

      if (latestNewRound == null || round > latestNewRound) {
        latestNewRound = round;
        latestNewCorrect = correct;
        latestNewByUid = e.value.byUid;
      }
    }
    if (!mounted) return;
    if (latestNewRound != null) {
      _showRoundFeedback(
        round: latestNewRound,
        correct: latestNewCorrect,
        answeredByMe: myUid != null && latestNewByUid == myUid,
      );
    }
    if (changed) setState(() {});
    _maybeConclude(match);
  }

  /// Holds [round]'s card on screen (with its flash + badge) for
  /// [_feedbackHoldDuration], and fires a haptic tap — but only on the
  /// device of whoever actually answered it.
  ///
  /// **Why a hold exists at all**: `BattleRepository.submitAnswer` writes
  /// the answer *and* advances `currentRound` in one Firestore
  /// transaction (`battle_repository.dart`), so by the time this device's
  /// listeners deliver either write, `match.currentRound` has almost
  /// always already moved past [round]. Left alone, `build()` would
  /// already be looking at the *next* round the instant this fires,
  /// which is exactly the bug the C4 audit traced: the flash either never
  /// renders (the next round is still being chosen) or renders on the
  /// wrong card (the next round already has one). Rather than fight that
  /// timing, this screen now deliberately keeps showing [round]'s own
  /// card for a fixed window regardless of what `currentRound` has moved
  /// on to — see `_buildCardArea`'s use of [_heldRound].
  ///
  /// **This is a purely local, visual hold** — nothing here touches
  /// `currentRound`, `turnStartedAt`, or any server write; the next
  /// round's own timer is already running underneath, untouched, and the
  /// bottom control area (keyboard/choose button/waiting text) keeps
  /// reading the real `match.currentRound` the whole time, so a player
  /// who needs to act on the next round right away always can.
  ///
  /// **Haptic fires exactly once per round, on this device**, guarded by
  /// the same invariant that already makes [_correctByRound] idempotent:
  /// this is only ever called from inside `_onAnswersUpdate`'s
  /// `if (_correctByRound.containsKey(round)) continue;` guard, so a
  /// round that has already been processed — including a duplicate
  /// Firestore snapshot for the same underlying write (e.g. the
  /// optimistic local write followed by the server-confirmed one) — can
  /// never reach here a second time for the same round.
  void _showRoundFeedback({
    required int round,
    required bool correct,
    required bool answeredByMe,
  }) {
    _feedbackHoldTimer?.cancel();
    _heldRound = round;
    _flashWasCorrect = correct;
    _flashUntil = DateTime.now().add(_feedbackHoldDuration);
    _feedbackHoldTimer = Timer(_feedbackHoldDuration, () {
      if (!mounted) return;
      setState(() => _heldRound = null);
    });

    // Self only — the opponent's device shows the identical visual badge
    // and flash (built from the same [_correctByRound]/[_heldRound]
    // state, see `_buildCardArea`) but never buzzes for an answer it did
    // not give — the entitlement/anti-cheat constraint this phase was
    // built against: never leak more than the derived correct/wrong
    // signal, and never let one player's device react to a signal the
    // other player caused.
    if (answeredByMe) {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
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
    _finishedAt = DateTime.now();
    ref
        .read(battleRepositoryProvider)
        .setClientResult(widget.matchId, conclusion);
    // The lobby's recent-matches list is read from a tab the card game
    // shell keeps alive in an `IndexedStack`, so it is never disposed and
    // would otherwise still be showing the list from before this match.
    ref.invalidate(recentMatchesProvider);
    if (mounted) setState(() {});
  }

  void _ensureTimerFor(BattleMatch match) {
    if (_timerRoundGuard == match.currentRound) return;
    if (match.currentRound >= match.turnOrder.length) return;
    _timerRoundGuard = match.currentRound;
    _timer?.cancel();

    final limit = roundBudget(
      match.currentRound,
      ownerIsBot:
          match.turnOrder[match.currentRound].deckOwnerUid == battleBotUid,
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
    final text = card.answerInHiragana ? _hiraganaBuffer : _romajiBuffer;
    if (text.trim().isEmpty) return;

    await ref
        .read(battleRepositoryProvider)
        .submitAnswer(
          matchId: widget.matchId,
          round: match.currentRound,
          byUid: myUid,
          text: text.trim(),
        );
    setState(() {
      _hiraganaBuffer = '';
      _romajiBuffer = '';
    });
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
        data: (match) {
          _lastKnownMatch = match;
          if (myUid != null) _ensureAbandonResolveScheduled(match, myUid);
          return cardDataAsync.when(
            data: (cardData) => _buildBody(context, s, match, cardData, myUid),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(s.battleLoadCardDataError(e))),
          );
        },
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
    final choosing =
        chosen == null &&
        !ownerIsBot &&
        _sinceTurnStart(match) < cardChoiceWindow(ownerIsBot: ownerIsBot);
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
    // Opened for the player rather than waiting to be asked for. The
    // window is ten seconds long; spending any of it on a tap that only
    // reveals the hand is spending it on nothing. The button left behind
    // is the way back in after a deliberate close.
    if (choosing && iChoose) {
      _maybeOpenCardPicker(match, myUid, cardData, ownerIsBot: ownerIsBot);
    }

    final isAnswerer = match.currentAnswererUid == myUid;
    final palette = context.palette;
    // Read once, here: the SafeArea below no longer takes it, so every
    // branch of the column has to account for the navigation bar itself.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tally = tallyScores(
      players: match.players,
      turnOrder: match.turnOrder,
      correctByRound: _correctByRound,
    );
    final opponentUid = match.players.firstWhere(
      (p) => p != myUid,
      orElse: () => myUid,
    );
    final identities = ref
        .watch(battleOpponentsProvider(match.players))
        .valueOrNull;

    return BattleBackdrop(
      // **The bottom inset is handled per branch, not by a SafeArea
      // around the lot.** It has to be honoured — without it the column
      // runs under the system navigation bar, and the hand of cards once
      // ended 21 pixels below the visible area with the bottom of every
      // tappable card drawn beneath it. Nothing overflows and nothing is
      // logged; the screen is simply taller than the part you can see.
      //
      // But the keyboard wants the opposite: its tray should reach the
      // very bottom of the glass, with the keys staying where they are.
      // A SafeArea here would stop the tray short and leave a strip of
      // the battle background showing under it. So the inset is passed
      // to whichever branch is on screen — as padding for the ones that
      // must clear the bar, as tray height for the keyboard.
      //
      // The top is left alone either way: the app bar already handles
      // that edge.
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (match.abandon != null && match.abandon!.uid != myUid)
              _OpponentAbandonBanner(
                strings: s,
                abandon: match.abandon!,
              ),
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
                child: _buildCardArea(
                  context,
                  s,
                  match,
                  cardData,
                  myUid,
                  entry,
                  identities,
                  choosing: choosing,
                  iChoose: iChoose,
                  isAnswerer: isAnswerer,
                  card: card,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BattleDeckStrip(slots: _deckSlots(match)),
            ),
            const SizedBox(height: 12),
            if (choosing && iChoose)
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _OpenPickerButton(
                  label: s.battleCardPickerTitle,
                  secondsLeft: _choiceSecondsLeft(
                    match,
                    ownerIsBot: ownerIsBot,
                  ),
                  onTap: () =>
                      _openCardPicker(match, myUid, cardData, ownerIsBot),
                ),
              )
            else if (choosing)
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Text(
                  s.battleOpponentChoosing,
                  style: TextStyle(
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              )
            else if (isAnswerer)
              _buildAnswerInput(context, s, match, card, bottomInset)
            else
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Text(
                  s.battleWaitingForOpponent,
                  style: TextStyle(
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The card area at the top of the screen: [_heldRound]'s card, badge
  /// and flash for [_feedbackHoldDuration] right after it resolves,
  /// otherwise exactly the pre-C4 choosing/face-down/face-up branching,
  /// unchanged, off the real [match.currentRound].
  ///
  /// **Only this — the card visual — is ever affected by a hold.** The
  /// bottom control area (built separately, back in [_buildBody]) always
  /// reads `choosing`/`iChoose`/`isAnswerer` off the live match state,
  /// never off [_heldRound], so a player who needs to choose a card or
  /// type an answer for the real current round can always do so
  /// immediately — the round clock is server-anchored and keeps running
  /// underneath a hold regardless, so the timer/input must never be the
  /// thing held back.
  Widget _buildCardArea(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    (List<KanaCharacter>, List<KanjiEntry>) cardData,
    String myUid,
    TurnOrderEntry entry,
    Map<String, LeaderboardEntry>? identities, {
    required bool choosing,
    required bool iChoose,
    required bool isAnswerer,
    required BattleCard card,
  }) {
    final held = _buildHeldCard(context, s, match, cardData, myUid, identities);
    if (held != null) return held;

    return choosing && iChoose
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Held down to roughly the height of the panel beside it.
              // At full size the card dwarfed the sentence it is paired
              // with, and the two read as unrelated things that happened
              // to share a row rather than as one instruction.
              Flexible(
                child: SizedBox(
                  height: 230,
                  child: _faceDownCard(
                    s,
                    entry,
                    identities,
                    myUid,
                    s.battleCardToSend,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BattleChoosePrompt(text: s.battleChooseInstruction),
                ),
              ),
            ],
          )
        : choosing
        ? _faceDownCard(s, entry, identities, myUid, s.battleOpponentChoosing)
        : BattleCardFace(
            prompt: card.prompt,
            caption: isAnswerer
                ? s.battleCardFromOpponent
                : s.battleCardFromYou,
            // Face up, the card still belongs to whoever dealt it, so it
            // keeps wearing their skin — the whole point of a cosmetic
            // your opponent sees is that they see it while they are
            // looking at the card, not only for the second it stays face
            // down. Resolved through [_skinFor] for the same reason the
            // face-down branch above does — see its own doc comment for
            // why C3-1's fix is a real live check for the viewing
            // player's own skin and a trusted-mirror read for the
            // opponent's.
            skin: _skinFor(entry.deckOwnerUid, myUid, identities),
            // No flash here any more — a flash on the *real* current
            // round's card would be exactly the C4 bug (a round that
            // has not been answered yet showing a color that claims it
            // has). Every flash now belongs to [_heldRound] alone, via
            // [_buildHeldCard].
            flashColor: null,
          );
  }

  /// [_heldRound]'s own card, badge and flash — or null if no hold is
  /// active (or the held round's card, unexpectedly, fails to resolve;
  /// falls back to the normal current-round rendering rather than
  /// showing nothing).
  Widget? _buildHeldCard(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    (List<KanaCharacter>, List<KanjiEntry>) cardData,
    String myUid,
    Map<String, LeaderboardEntry>? identities,
  ) {
    final heldRound = _heldRound;
    if (heldRound == null) return null;
    if (heldRound < 0 || heldRound >= match.turnOrder.length) return null;
    final heldCorrect = _correctByRound[heldRound];
    if (heldCorrect == null) return null;

    final heldEntry = match.turnOrder[heldRound];
    final heldCard = resolveCard(
      match.effectiveCardId(heldRound) ?? heldEntry.cardId,
      cardData.$1,
      cardData.$2,
    );
    if (heldCard == null) return null;

    // Whoever did NOT own this round's deck is who answered it — mirrors
    // BattleMatch.currentAnswererUid's own derivation, just for a round
    // other than the live current one.
    final heldIsAnswerer = heldEntry.deckOwnerUid != myUid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnswerFeedbackBadge(correct: heldCorrect, strings: s),
        const SizedBox(height: 6),
        Flexible(
          child: BattleCardFace(
            prompt: heldCard.prompt,
            caption: heldIsAnswerer
                ? s.battleCardFromOpponent
                : s.battleCardFromYou,
            skin: _skinFor(heldEntry.deckOwnerUid, myUid, identities),
            flashColor: _flashColor(context),
          ),
        ),
      ],
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
    final left =
        cardChoiceWindow(ownerIsBot: ownerIsBot) - _sinceTurnStart(match);
    _choiceDeadlineTimer?.cancel();
    _choiceDeadlineTimer = Timer(left.isNegative ? Duration.zero : left, () {
      if (!mounted) return;
      final current = ref.read(battleMatchProvider(widget.matchId)).valueOrNull;
      if (current == null) return;
      if (current.currentRound != round) return;
      if (current.playedCards.containsKey(round)) return;
      ref
          .read(battleRepositoryProvider)
          .playCard(
            matchId: widget.matchId,
            round: round,
            cardId: current.turnOrder[round].cardId,
          );
    });
  }

  /// Opens the picker once per round, and never while one is already up.
  ///
  /// Guarded by round rather than by a bool: `build` runs many times
  /// inside a single choosing window — every timer tick, every match
  /// snapshot — and an unguarded push would stack a screen per frame.
  void _maybeOpenCardPicker(
    BattleMatch match,
    String myUid,
    (List<KanaCharacter>, List<KanjiEntry>) cardData, {
    required bool ownerIsBot,
  }) {
    final round = match.currentRound;
    if (_pickerOpenedForRound == round) return;
    _pickerOpenedForRound = round;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openCardPicker(match, myUid, cardData, ownerIsBot);
    });
  }

  /// Shows the hand, and plays whatever comes back.
  ///
  /// The picker returns a card id and nothing else — closing it, or
  /// letting the clock run out, both come back null and leave the round
  /// to `_scheduleChoiceDeadline`, which is what sends the dealt card.
  Future<void> _openCardPicker(
    BattleMatch match,
    String myUid,
    (List<KanaCharacter>, List<KanjiEntry>) cardData,
    bool ownerIsBot,
  ) async {
    final round = match.currentRound;
    final chosen = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BattleCardPickerScreen(
          cards: _handCards(match, myUid, cardData),
          // The hand shrinks as it is played, so the denominator is the
          // deck each player was dealt, not what is left of it.
          totalCards: kBattleTotalRounds ~/ 2,
          deadline: (match.turnStartedAt ?? DateTime.now()).add(
            cardChoiceWindow(ownerIsBot: ownerIsBot),
          ),
        ),
      ),
    );
    if (!mounted || chosen == null) return;
    // The round can have moved on while the picker was open — the clock
    // ran out, or the opponent's device wrote the dealt card first.
    // `playCard` ignores a second write for a round that already has a
    // card, but asking for one at all would be asking about a round that
    // is no longer being played.
    final current = ref.read(battleMatchProvider(widget.matchId)).valueOrNull;
    if (current == null || current.currentRound != round) return;
    if (current.playedCards.containsKey(round)) return;
    await ref
        .read(battleRepositoryProvider)
        .playCard(matchId: widget.matchId, round: round, cardId: chosen);
  }

  /// How long this round has been running, from the server anchor.
  Duration _sinceTurnStart(BattleMatch match) {
    final anchor = match.turnStartedAt;
    if (anchor == null) return Duration.zero;
    return DateTime.now().difference(anchor);
  }

  int _choiceSecondsLeft(BattleMatch match, {required bool ownerIsBot}) {
    final left =
        cardChoiceWindow(ownerIsBot: ownerIsBot) - _sinceTurnStart(match);
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

  /// The tint for whichever round [_heldRound] is currently holding.
  ///
  /// **Correction, C4**: this used to be applied to whatever card
  /// `match.currentRound` happened to be showing, on the theory that "the
  /// turn has already moved on by the time this rebuild happens, so keying
  /// it to the current round would never show anything." That reasoning
  /// was half right and half backwards — the turn genuinely has already
  /// moved on (`submitAnswer` advances `currentRound` in the same
  /// transaction as the answer write, `battle_repository.dart`), but the
  /// old code still applied this colour to *whatever round was currently
  /// being rendered*, which by then was almost always the *next* round,
  /// not the one this colour describes — so the flash either never
  /// rendered (next round still choosing) or tinted a card that had not
  /// been answered yet. Only ever called from [_buildHeldCard] now, so it
  /// always describes [_heldRound] specifically.
  Color? _flashColor(BuildContext context) {
    if (_flashUntil == null || DateTime.now().isAfter(_flashUntil!)) {
      return null;
    }
    return _flashWasCorrect
        ? context.palette.secondaryBlue
        : context.palette.errorRed;
  }

  /// The skin to render for whoever owns [deckOwnerUid]'s card —
  /// **the actual fix for C3-1**: the two call sites below used to pass
  /// `effectiveCardSkin` neither `owned` nor `premium`, so it always fell
  /// through to `false`/`false` and — with [kCardSkinsAllUnlocked] false
  /// in every release build — every achievement/paid skin silently
  /// downgraded to [CardSkinPresets.classic] for both players, always.
  /// Invisible in debug because [kCardSkinsAllUnlocked] papered over it
  /// there. See AUDIT_PHASE_C_BATTLE_RELIABILITY.md's C3 finding.
  ///
  /// **The two players are resolved differently, and that split is
  /// deliberate, not an oversight** — audited before writing this:
  /// - [myUid]'s own skin gets the *real* live check, the same one
  ///   `card_skin_picker_screen.dart` already uses (`ownedSkinsProvider`
  ///   for a bought skin, `subscriptionProvider.isPremium` for the
  ///   Premium-bundled paid family) — this device genuinely has that
  ///   data, so there is no reason to trust anything less than the full
  ///   rule.
  /// - The **opponent's** skin cannot be live-checked the same way: their
  ///   `entitlements.skins`/`subscription.tier` live under their own
  ///   private `users/{uid}` document, which `firestore.rules` only ever
  ///   lets its owner read — there is no public mirror of either on
  ///   `leaderboard/{uid}`. Building one would mean a new Cloud-Function-
  ///   mirrored field (a real schema/rules addition, out of this fix's
  ///   scope). Instead this trusts `LeaderboardEntry.cardSkinId` directly
  ///   — the same level of trust this app *already* gives an opponent's
  ///   avatar and frame everywhere (neither has ever had a live re-check
  ///   for a non-owner viewer).
  ///
  ///   **Correction (RISK-2, AUDIT_COSMETIC_PROFILE_SHOP.md)**: this used
  ///   to claim that trust was sound because `isAllowedCardSkinWrite`
  ///   "already refuses to let that id become anything the opponent
  ///   wasn't entitled to" — that was never actually true.
  ///   `isAllowedCardSkinWrite` (and the avatar/frame/cover equivalents)
  ///   were only ever wired into `allow update` on `users/{uid}` itself,
  ///   never into `leaderboard/{uid}` — proven via the real Firestore
  ///   Rules Emulator that a client could write ANY cardSkinId/
  ///   avatarType/avatarValue/frameId/coverId directly onto their own
  ///   `leaderboard/{uid}` row, no entitlement required at all. Fixed by
  ///   `firestore.rules`' `mirrorsOwnCosmetics`, which now requires every
  ///   `leaderboard/{uid}` write's resulting cosmetic fields to equal
  ///   exactly what the writer's own `users/{uid}.profile` currently
  ///   says — so trusting `LeaderboardEntry.cardSkinId` here really is
  ///   sound now, just not for the reason this comment used to give.
  ///

  /// **Known, accepted gap, not silently swept under the rug**: an
  /// opponent whose Premium lapses right after equipping a
  /// premium-bundled paid skin, and who never reopens the picker
  /// afterward, can still be seen wearing it here until they do — the
  /// exact staleness the picker's own live check exists to close, just
  /// unreachable for someone else's device. Achievement skins have the
  /// same theoretical gap for the `premium` half specifically (their
  /// `starTotal` half is already correctly live — see below — since
  /// that field genuinely is public).
  CardSkinPreset _skinFor(
    String deckOwnerUid,
    String myUid,
    Map<String, LeaderboardEntry>? identities,
  ) {
    final entry = identities?[deckOwnerUid];
    if (deckOwnerUid != myUid) {
      // Opponent — trust the server-validated mirror, see doc comment.
      return CardSkinPresets.byId(entry?.cardSkinId);
    }
    final owned = ref.watch(ownedSkinsProvider).valueOrNull ?? const <String>{};
    final premium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
    return effectiveCardSkin(
      entry?.cardSkinId,
      // cardGameStarTotal is written by battle_stars.js onto the same
      // public leaderboard/{uid} row — genuinely public, so this was
      // already correct even before this fix; kept exactly as it was.
      starTotal: entry?.cardGameStarTotal ?? 0,
      owned: owned.contains(CardSkinPresets.byId(entry?.cardSkinId).id),
      premium: premium,
      allUnlocked: kCardSkinsAllUnlocked,
    );
  }

  /// The face-down card, shared by both choosing states.
  ///
  /// The skin belongs to whoever owns this card, so what you see while
  /// waiting is your opponent's, and what they see while you choose is
  /// yours. Resolved through [_skinFor] rather than read raw: an
  /// achievement skin whose owner has dropped below its threshold has to
  /// stop showing on *their* opponent's screen too, or the lock means
  /// nothing to anyone but themselves.
  Widget _faceDownCard(
    AppStrings s,
    TurnOrderEntry entry,
    Map<String, LeaderboardEntry>? identities,
    String myUid,
    String caption,
  ) {
    return BattleCardFace(
      // Face down while its owner decides: revealing the dealt card here
      // would show the answerer a card that may never be played.
      prompt: '',
      faceDown: true,
      skin: _skinFor(entry.deckOwnerUid, myUid, identities),
      caption: caption,
      flashColor: null,
    );
  }

  Widget _buildAnswerInput(
    BuildContext context,
    AppStrings s,
    BattleMatch match,
    BattleCard card,
    double bottomInset,
  ) {
    final hiragana = card.answerInHiragana;
    final typed = hiragana ? _hiraganaBuffer : _romajiBuffer;
    // What the tray takes: the navigation bar, plus room so the bottom
    // row of keys is not sitting on it.
    final trayInset = bottomInset + kKeyboardBottomGap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Send sits beside what was typed rather than under the
        // keyboard. Down there it was the furthest thing on screen from
        // both the answer and the eyes reading it, and on a timed card
        // that is a long way to travel to finish. Beside the buffer it
        // is where the answer already is.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _AnswerField(
                  text: typed,
                  hint: hiragana ? '' : s.battleRomajiHint,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _submit(match, card),
                child: Text(s.battleSendAnswer),
              ),
            ],
          ),
        ),
        SizedBox(
          // Four rows at a fingertip's height each for kana, three for
          // romaji. The old 220 was holding twelve rows and crushing
          // every one of them.
          height: (hiragana ? 200 : 190) + trayInset,
          child: hiragana
              ? KanaKeyboard(
                  value: _hiraganaBuffer,
                  bottomInset: trayInset,
                  onChanged: (v) => setState(() => _hiraganaBuffer = v),
                )
              // The romaji half used to open the phone's own keyboard.
              // On a timed card that meant a prediction bar offering the
              // answer, and a different amount of the card covered on
              // every phone.
              : RomajiKeyboard(
                  value: _romajiBuffer,
                  bottomInset: trayInset,
                  onChanged: (v) => setState(() => _romajiBuffer = v),
                ),
        ),
      ],
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

    final identities = ref
        .watch(battleOpponentsProvider(match.players))
        .valueOrNull;
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
    final ended = _finishedAt;
    // Measured to when the match ended, not to now — see [_finishedAt].
    final duration = started == null || ended == null
        ? null
        : ended.difference(started);

    // Never `sad`, even on a loss — the same rule MascotCoach already
    // follows for wrong answers: the audience is children, and a mascot
    // that looks let down by them is the thing this app decided not to
    // do.
    final resultMood = isDraw
        ? MascotMood.curious
        : (iWon ? MascotMood.cheering : MascotMood.encouraging);
    // `encouraging` has no costumed pose yet, and reusing one of the
    // seven that do exist would undercut exactly what this mood is for
    // — every costumed pose reads positive-to-neutral, none reads as
    // gently reassuring the way a loss needs. So it falls back to the
    // real standard art instead of a mismatched costume; `curious`
    // (draw) and `cheering` (win) both have costumes and keep wearing
    // them. See AUDIT_CARD_BATTLE_MASCOT_MAPPING_IMPACT.md.
    final resultMascotSkin = resultMood != MascotMood.encouraging;

    return BattleBackdrop(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Center(
            child: MascotWidget(
              mood: resultMood,
              size: 120,
              cardBattleSkin: resultMascotSkin,
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

/// The 30-second reconnect grace period's own visible countdown — shown
/// on the *still-present* player's screen only, above the score panel,
/// while `match.abandon` names the *other* player. Purely cosmetic:
/// nothing here decides when the match actually ends —
/// [_BattleScreenState._ensureAbandonResolveScheduled] does that,
/// independently, off the same [abandon] marker's own server timestamp.
class _OpponentAbandonBanner extends StatefulWidget {
  const _OpponentAbandonBanner({required this.strings, required this.abandon});

  final AppStrings strings;
  final BattleAbandonMarker abandon;

  @override
  State<_OpponentAbandonBanner> createState() => _OpponentAbandonBannerState();
}

class _OpponentAbandonBannerState extends State<_OpponentAbandonBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final since = widget.abandon.since;
    final elapsed = since == null ? Duration.zero : DateTime.now().difference(since);
    final remaining =
        const Duration(seconds: kBattleAbandonGracePeriodSeconds) - elapsed;
    final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.tertiaryAmberCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: palette.textNavy, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.strings.battleOpponentAbandonedTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: palette.textNavy,
                  ),
                ),
                Text(
                  widget.strings.battleOpponentAbandonedCountdown(secondsLeft),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textNavy.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// C4 — the "Benar!"/"Salah!"
/// pill shown above [_BattleScreenState._buildHeldCard]'s card for
/// [_BattleScreenState._feedbackHoldDuration]. Deliberately a small,
/// non-blocking pill above the card rather than an overlay on top of it —
/// per the locked spec it must never cover the card, keyboard/input,
/// score, or timer, and this sits entirely in the caption's own space
/// above the card, changing nothing about the layout beneath it.
///
/// Colour matches this app's existing colourblind-safe correct/wrong
/// language ([AppPalette.secondaryBlue]/[AppPalette.errorRed] — the same
/// two tokens `_flashColor`/`BattleDeckStrip`'s slot coloring already use,
/// see `theme_consistency`/quiz-colour conventions elsewhere in this
/// codebase) rather than green, which this app avoids everywhere else for
/// the same reason. The ✅/❌ glyphs are literal, per the approved spec.
class _AnswerFeedbackBadge extends StatelessWidget {
  const _AnswerFeedbackBadge({required this.correct, required this.strings});

  final bool correct;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = correct ? palette.secondaryBlue : palette.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            correct ? '✅' : '❌',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(width: 6),
          Text(
            correct ? strings.battleAnswerCorrect : strings.battleAnswerWrong,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// The way back into the picker after closing it, and the only thing the
/// arena shows of the hand now.
///
/// The hand itself moved to its own screen, so what is left here is a
/// door rather than a drawer — and it carries the countdown, because the
/// player who closed the picker still has a window running.
class _OpenPickerButton extends StatelessWidget {
  const _OpenPickerButton({
    required this.label,
    required this.secondsLeft,
    required this.onTap,
  });

  final String label;
  final int secondsLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: palette.primaryCoral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: onTap,
          icon: Icon(Icons.style, color: palette.cardWhite),
          label: Text(
            '$label  ·  ${secondsLeft}s',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: palette.cardWhite,
            ),
          ),
        ),
      ),
    );
  }
}

/// What has been typed so far, which neither keyboard shows itself.
///
/// Without it a player is typing blind: no way to see a wrong character,
/// and no way to know a key registered at all.
class _AnswerField extends StatelessWidget {
  const _AnswerField({required this.text, required this.hint});

  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final empty = text.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        empty ? (hint.isEmpty ? ' ' : hint) : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 22,
          color: empty
              ? palette.textNavy.withValues(alpha: 0.4)
              : palette.textNavy,
        ),
      ),
    );
  }
}
