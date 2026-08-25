const {test, describe} = require("node:test");
const assert = require("node:assert/strict");

const {
  K,
  DECAY,
  REPEAT_CYCLE_WINDOW_MS,
  difficultyMultiplierFor,
  repeatKeyFor,
  decideAward,
  toEpochMs,
} = require("./global_points");

const DAY_MS = 24 * 60 * 60 * 1000;

describe("formula", () => {
  test("constants match the approved Final Decision Memo exactly", () => {
    assert.equal(K, 10);
    assert.equal(DECAY, 0.6);
    assert.equal(REPEAT_CYCLE_WINDOW_MS, 30 * DAY_MS);
  });

  test("difficulty multiplier matches the approved scale", () => {
    assert.equal(difficultyMultiplierFor("hiragana"), 1.0);
    assert.equal(difficultyMultiplierFor("katakana"), 1.0);
    assert.equal(difficultyMultiplierFor("mixed"), 1.0);
    assert.equal(difficultyMultiplierFor("N5"), 1.0);
    assert.equal(difficultyMultiplierFor("N4"), 1.2);
    assert.equal(difficultyMultiplierFor("N3"), 1.5);
    assert.equal(difficultyMultiplierFor("N2"), 1.8);
    assert.equal(difficultyMultiplierFor("N1"), 2.2);
  });

  test("difficulty matching is case-insensitive — a casing mismatch "
      + "between modules must not silently fall back to a wrong tier", () => {
    assert.equal(difficultyMultiplierFor("n3"), 1.5);
    assert.equal(difficultyMultiplierFor("n1"), 2.2);
  });

  test("an unrecognised level falls back to 1.0, never 0 — an unknown "
      + "value must not zero out an otherwise-earned attempt", () => {
    assert.equal(difficultyMultiplierFor("something-unexpected"), 1.0);
    assert.equal(difficultyMultiplierFor(undefined), 1.0);
    assert.equal(difficultyMultiplierFor(null), 1.0);
  });

  test("first attempt: points = correct x difficulty x k (n=1, decay^0=1)", () => {
    const result = decideAward({
      alreadyAwarded: false,
      cycle: null,
      now: 1000,
      correct: 9,
      difficulty: 1.0,
    });
    assert.equal(result.points, 90);
    assert.deepEqual(result.newCycle, {attemptCountInCycle: 1, cycleStartedAt: 1000});
  });

  test("N4 20-soal 90% worked example from the approved memo (correct=18)", () => {
    const result = decideAward({
      alreadyAwarded: false, cycle: null, now: 0, correct: 18, difficulty: 1.2,
    });
    // 18 * 1.2 * 10 is 215.99999999999997 in IEEE 754 double arithmetic —
    // asserted with a tolerance rather than strict equality for exactly
    // that reason, not a bug in the formula itself.
    assert.ok(Math.abs(result.points - 216) < 1e-9);
  });

  test("N3 50-soal 80% worked example from the approved memo (correct=40)", () => {
    const result = decideAward({
      alreadyAwarded: false, cycle: null, now: 0, correct: 40, difficulty: 1.5,
    });
    assert.equal(result.points, 40 * 1.5 * 10);
    assert.equal(result.points, 600);
  });

  test("second attempt in the same cycle applies decay^1", () => {
    const result = decideAward({
      alreadyAwarded: false,
      cycle: {attemptCountInCycle: 1, cycleStartedAt: 1000},
      now: 2000,
      correct: 9,
      difficulty: 1.0,
    });
    // 90 * 0.6^1 = 54
    assert.equal(result.points, 54);
    assert.equal(result.newCycle.attemptCountInCycle, 2);
  });

  test("five repeats on the same item converge toward the 2.5x ceiling, "
      + "never exceeding it — the mathematical anti-farming property the "
      + "Final Decision Memo's simulation is built on", () => {
    let cycle = null;
    let total = 0;
    const base = 90;
    for (let i = 0; i < 5; i++) {
      const result = decideAward({
        alreadyAwarded: false, cycle, now: i * DAY_MS, correct: 9, difficulty: 1.0,
      });
      total += result.points;
      cycle = result.newCycle;
    }
    assert.ok(Math.abs(total - 207.504) < 0.01, `expected ~207.5, got ${total}`);
    assert.ok(total < base * 2.5, "must never exceed the 2.5x convergence ceiling");
  });

  test("a zero-correct attempt still returns a real award (0 points), "
      + "not null — 'already awarded' is the only case that returns "
      + "null, so a legitimate failed attempt still advances the cycle", () => {
    const result = decideAward({
      alreadyAwarded: false, cycle: null, now: 0, correct: 0, difficulty: 1.0,
    });
    assert.notEqual(result, null);
    assert.equal(result.points, 0);
    assert.equal(result.newCycle.attemptCountInCycle, 1);
  });
});

describe("toEpochMs", () => {
  test("a plain finite number is trusted as-is, never silently replaced "
      + "with Date.now() — found as a real bug while writing the backfill "
      + "replay's own fixture tests, where a bare-number completedAt was "
      + "being discarded, masking a 30-day-reset test's real intent", () => {
    assert.equal(toEpochMs(0), 0);
    assert.equal(toEpochMs(1234567), 1234567);
  });

  test("a Firestore-Timestamp-shaped object uses toMillis()", () => {
    assert.equal(toEpochMs({toMillis: () => 999}), 999);
  });

  test("an ISO string parses via Date.parse", () => {
    assert.equal(toEpochMs("2026-01-01T00:00:00.000Z"), Date.parse("2026-01-01T00:00:00.000Z"));
  });

  test("a plain Date instance uses getTime()", () => {
    const d = new Date(2026, 0, 1);
    assert.equal(toEpochMs(d), d.getTime());
  });

  test("null/undefined/garbage falls back to Date.now(), within a "
      + "generous tolerance so this test isn't flaky", () => {
    const before = Date.now();
    const result = toEpochMs(null);
    const after = Date.now();
    assert.ok(result >= before && result <= after);
  });
});

describe("repeat key derivation", () => {
  test("kana repeats by mode, not by any per-attempt identity", () => {
    assert.equal(repeatKeyFor("kana", {type: "hiragana"}), "kana:hiragana");
    assert.equal(repeatKeyFor("kana", {type: "mixed"}), "kana:mixed");
  });

  test("dokkai repeats by jlptLevel, deliberately NOT by itemId — "
      + "dokkai_exam_screen.dart mints itemId from a fresh timestamp "
      + "every session, so it can never repeat by construction and would "
      + "silently defeat repeat detection if used here", () => {
    assert.equal(repeatKeyFor("dokkai", {jlptLevel: "N3"}), "dokkai:N3");
    assert.equal(
      repeatKeyFor("dokkai", {itemId: "dokkai_session_1", jlptLevel: "N3"}),
      repeatKeyFor("dokkai", {itemId: "dokkai_session_2", jlptLevel: "N3"}),
      "two different session ids at the same level must produce the same repeat key",
    );
  });

  test("choukai repeats by itemId, which already IS clip.id — stable "
      + "and real, no substitution needed", () => {
    assert.equal(
      repeatKeyFor("choukai", {itemId: "choukai_n5_jam_berapa"}),
      "choukai:choukai_n5_jam_berapa",
    );
  });

  test("kanji-kombinasi repeats by itemId, which already encodes "
      + "{mode}_{level} — every session at the same mode+level shares "
      + "one key by design, since questions are regenerated from the "
      + "same pool each time", () => {
    assert.equal(repeatKeyFor("kanjiCombo", {itemId: "single_n5"}), "kanjiCombo:single_n5");
    assert.equal(repeatKeyFor("kanjiCombo", {itemId: "combo_n1"}), "kanjiCombo:combo_n1");
  });

  test("the same repeat-key value never collides across different modules", () => {
    // Both Dokkai and Kanji-Kombinasi can produce an "N5"-shaped value —
    // the module prefix keeps them from sharing a repeat cycle.
    assert.notEqual(
      repeatKeyFor("dokkai", {jlptLevel: "N5"}),
      repeatKeyFor("kanjiCombo", {itemId: "N5"}),
    );
  });

  test("an unknown module type throws rather than silently producing a "
      + "malformed key", () => {
    assert.throws(() => repeatKeyFor("not-a-real-module", {}));
  });
});

describe("idempotency", () => {
  test("an already-awarded attempt returns null — a replayed trigger "
      + "invocation (Cloud Functions v2's at-least-once delivery) must "
      + "never award twice", () => {
    const result = decideAward({
      alreadyAwarded: true,
      cycle: {attemptCountInCycle: 3, cycleStartedAt: 0},
      now: 1000,
      correct: 10,
      difficulty: 2.2,
    });
    assert.equal(result, null);
  });

  test("alreadyAwarded short-circuits before touching cycle/now/correct/"
      + "difficulty at all — passing deliberately nonsensical values for "
      + "the rest confirms none of them are consulted", () => {
    const result = decideAward({
      alreadyAwarded: true,
      cycle: undefined,
      now: NaN,
      correct: -999,
      difficulty: -1,
    });
    assert.equal(result, null);
  });
});

describe("repeat cycle / reset", () => {
  test("no prior cycle (first-ever attempt for this key) starts n=1", () => {
    const result = decideAward({
      alreadyAwarded: false, cycle: null, now: 5000, correct: 5, difficulty: 1.0,
    });
    assert.equal(result.newCycle.attemptCountInCycle, 1);
    assert.equal(result.newCycle.cycleStartedAt, 5000);
  });

  test("an attempt exactly at the 30-day boundary is still within the "
      + "old cycle (strictly-greater-than triggers reset, not "
      + "greater-or-equal)", () => {
    const cycleStartedAt = 0;
    const result = decideAward({
      alreadyAwarded: false,
      cycle: {attemptCountInCycle: 4, cycleStartedAt},
      now: REPEAT_CYCLE_WINDOW_MS,
      correct: 9,
      difficulty: 1.0,
    });
    assert.equal(result.newCycle.attemptCountInCycle, 5, "still inside the same cycle");
  });

  test("an attempt one millisecond past 30 days resets to n=1, with a "
      + "fresh cycleStartedAt at the new attempt's time", () => {
    const cycleStartedAt = 0;
    const now = REPEAT_CYCLE_WINDOW_MS + 1;
    const result = decideAward({
      alreadyAwarded: false,
      cycle: {attemptCountInCycle: 4, cycleStartedAt},
      now,
      correct: 9,
      difficulty: 1.0,
    });
    assert.equal(result.newCycle.attemptCountInCycle, 1);
    assert.equal(result.newCycle.cycleStartedAt, now);
    assert.equal(result.points, 90, "a reset attempt earns full, undecayed points");
  });

  test("a reset attempt earns full value again, matching the memo's "
      + "'legitimate replay after a real gap gets rewarded fully' claim", () => {
    const now = 40 * DAY_MS;
    const result = decideAward({
      alreadyAwarded: false,
      cycle: {attemptCountInCycle: 10, cycleStartedAt: 0},
      now,
      correct: 9,
      difficulty: 1.0,
    });
    assert.equal(result.points, 90, "no trace of the old decay chain survives a reset");
  });

  test("farming within one 30-day window converges to the same ~2.5x "
      + "ceiling regardless of attempt frequency inside the window", () => {
    let cycle = null;
    let total = 0;
    for (let i = 0; i < 20; i++) {
      // All 20 attempts inside one 30-day window (spaced 1 day apart).
      const result = decideAward({
        alreadyAwarded: false, cycle, now: i * DAY_MS, correct: 9, difficulty: 1.0,
      });
      total += result.points;
      cycle = result.newCycle;
    }
    assert.ok(total < 90 * 2.5, "must stay under the convergence ceiling");
    assert.ok(total > 90 * 2.4, "must have essentially converged by attempt 20");
  });

  test("resetting every 30 days re-harvests the ceiling each time — "
      + "matches the memo's own annual-yield table (~2700/item/year for "
      + "a daily-grinding farmer under a 30-day reset)", () => {
    let cycle = null;
    let total = 0;
    const daysPerYear = 360; // round number for the assertion below
    for (let day = 0; day < daysPerYear; day++) {
      const now = day * DAY_MS;
      const stillInCycle =
        cycle && now - cycle.cycleStartedAt <= REPEAT_CYCLE_WINDOW_MS;
      const result = decideAward({
        alreadyAwarded: false,
        cycle: stillInCycle ? cycle : null,
        now,
        correct: 9,
        difficulty: 1.0,
      });
      total += result.points;
      cycle = result.newCycle;
    }
    // 360 / 30 = 12 resets/year; ceiling ~225 each => ~2700, per the memo.
    assert.ok(total > 2600 && total < 2800, `expected ~2700, got ${total}`);
  });
});
