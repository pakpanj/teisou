# Teisou — Kana Master

Flutter app (Android-first) teaching Japanese from absolute beginner (kana)
through dictionary lookup and camera-based scanning. State management is
**Riverpod** throughout — don't introduce Bloc/Provider/GetX.

## Batch status

| Batch | Scope | Status |
|---|---|---|
| 1 | Kana Master (Hiragana, Katakana, Ujian, SVG glyphs) | ✅ |
| 2 | Profile/Ads/Premium/Leaderboard scaffold, module placeholders | ✅ |
| 3 | Firebase Live & Auth (anonymous + Google Sign-In, real `firebase_options.dart`) | ✅ |
| — | Profile Enhancement (custom name + avatar picker/upload, gated by rewarded ads/premium) | ✅ |
| 4 | Search & Dictionary (Kanji/Kotoba lookup) | ✅ |
| 5 | Cam Detector (offline Japanese OCR scanning) | ✅ built, but 🔒 locked from navigation since — real bugs, not gone; see "Known placeholders" below |
| 6 | Kotoba vocab module (Home/Category/Detail, on-demand images, progress + quiz) | ✅ |
| 7 | Full Kotoba dataset — all 45 categories across 7 groups, 519 words | ✅ |
| 8 | Kanji module Fase 1 — StrokeOrderAnimator, browse (Home/Level/Detail/Quiz) screens, full N5 (107) + N4 (133) dataset | ✅ |
| 9+ | Kanji N3-N1 content (Fase 2), full Bunpou/Partikel/Kaiwa/Choukai modules, AdMob/IAP production, release polish | 🔶 in progress — kanji dataset fully real (N5-N1, 2425/2425, no placeholders); Bunpou module fully real across all 5 JLPT levels (84/132/182/197/253 = 848/848 grammar points, no placeholders); Partikel module fully real across all 3 categories (25/25 particles, 48 nested functions, no placeholders); Kaiwa module built (interactive image + multiple-choice dialogue practice, Level(N5-N1)→Theme→Dialogue hierarchy, N5 fully authored: 17 themes/51 dialogues, N4-N1 placeholders) and free — Bunpou/Partikel/Kaiwa are done for their current scope; Choukai still untouched. **Premium gating for Partikel/Kaiwa is currently disabled app-wide for dev testing** — see the monetization-roadmap note under "Known placeholders" below, this is not the final state |

Note: "Profile Enhancement" isn't a numbered batch in the original roadmap
doc — it was scoped as part of the same work session as Batch 4 (Search &
Dictionary) but is a separate concern. If you're told to work on "Batch 4"
going forward, confirm which one is meant. Similarly, the Kanji module
above was requested mid-session as "Batch 7" — by that point Batch 7 was
already taken (full Kotoba dataset, previous row), so it's recorded here
as Batch 8. If told to work on "Batch 7" going forward, confirm which is
meant.

## Architecture

- **Firebase pattern**: anonymous sign-in on first launch (`AuthService`),
  optional Google linking later without changing the UID. Every screen that
  reads/writes progress gates on `appStartupProvider` resolving first.
- **Static content lives in bundled JSON assets, not Firestore** — kana
  (`assets/data/kana_data.json`), kanji (`kanji_data.json`), kotoba
  (`kotoba_data.json`). Each has a `Repository` class
  (`KanaRepository`/`KanjiRepository`/`KotobaRepository`) that loads once
  and caches in memory: `getAll`/`getByLevel`/`getById`/`search`, plus
  exact-match helpers (`findByCharacter`/`findExact`) added for Cam
  Detector's lookup. Regenerate kanji/kotoba seed data via
  `scripts/generate_kanji_seed.py` / `generate_kotoba_seed.py`.
- **Per-user data lives in Firestore** under `users/{uid}`: `profile`,
  `progress`, `subscription`, `adRewards`, plus subcollections
  `examHistory`, `moduleInterest`, `savedItems` (bookmarked dictionary
  entries), `savedWords` (Cam Detector's "Daftar Belajar" — mirrors the
  SharedPreferences-first local copy `SavedWordsRepository` reads from;
  Firestore there is a best-effort backup, not the read source).
- **Leaderboard** (`leaderboard/{uid}`) is a separate top-level collection,
  kept in sync with profile name/avatar changes via
  `LeaderboardRepository.syncProfileInfo` — see
  `EditNameDialog`/`AvatarPickerSheet` for the call sites, and
  `ExamRepository.submitExam` for the exam-driven update path (which now
  also carries `avatarType`/`avatarValue`, not just `photoUrl`, so a custom
  avatar isn't clobbered back to the Google photo on the next exam
  submission).
- **Avatar resolution priority** (see `UserAvatar` widget, and its
  leaderboard-row counterpart `_Avatar` in `leaderboard_screen.dart`):
  custom Storage upload > premium preset > free preset > Google photo >
  default emoji. 16 presets (6 free, 10 premium) are emoji + color
  placeholders defined in `lib/core/constants/avatars.dart` — swap for real
  SVG art there without touching callers.
- **Kotoba vocab module** (Batch 6-7) extends Batch 4's `KotobaEntry`
  rather than duplicating it: added `imagePath`, and `sentenceExample`
  (singular) became `sentenceExamples` (list) with a backward-compat
  getter + dual `fromJson` support (old singular key still works, so
  `kotoba_data.json` from Batch 4 didn't need regenerating). Per-category
  datasets live at `assets/data/kotoba/{category_id}.json` (bundled in
  the APK, loaded lazily and cached by `KotobaRepository.getVocabCategory`),
  distinct from Batch 4's single `kotoba_data.json`.
  `assets/data/kotoba/_categories.json` is metadata-only
  (id/name/group/icon/available/wordCount) for all 45 categories across 7
  groups — all `available: true` now, generated by one script per group
  (`scripts/generate_kotoba_<group>.py`, e.g. `generate_kotoba_alam.py`
  for Alam & Lingkungan, `generate_kotoba_waktu_angka.py` for Waktu &
  Angka) that writes each category's `CATEGORIES` dict entry to its own
  JSON file. Regenerate a category's word list by editing its group
  script and re-running it, then re-run
  `scripts/generate_kotoba_categories.py` to refresh `_categories.json`'s
  `available`/`wordCount` — **don't hand-edit `_categories.json` and forget
  to re-run the word-list script, or vice versa; a stale mismatch between
  the two shipped once** (all 10 Alam & Lingkungan categories showed as
  available with placeholder counts before any dataset existed for 9 of
  them — caught via device screenshot, fixed by re-running the generator).
- **Kotoba registers across word types**: every group script has a
  `_registers(casual, casual_romaji, formal, formal_romaji, word_type)`
  helper taking an explicit casual/formal pair per entry rather than
  deriving one pattern for the whole file, because the dataset mixes
  nouns, verbs, and adjectives:
  - concrete nouns (animals, food, places, objects): casual = formal =
    the same word, honest keigo note ("tidak ada bentuk keigo khusus
    untuk ...") — politeness lives in the sentence, not the noun.
  - verbs (`cara_memasak`'s cooking actions, `ekspresi_wajah`'s facial
    actions, `perasaan_emosi`'s `okoru`): casual = dictionary form,
    formal = real ~masu form (e.g. 焼く→焼きます) — plain, unambiguous
    grammar, not a fabrication.
  - i-/na-adjectives (`perasaan_emosi`, `arah_lokasi`'s `tooi`, `warna`'s
    five true-adjective colors): casual = plain form, formal = plain +
    です — deliberately skips the classical adjective+ございます
    conjugation (痛うございます-style) since that's correct only for a
    handful of textbook-canonical words and easy to get subtly wrong
    elsewhere; every adjective entry here gets the honest keigo fallback
    instead.
  `warna` specifically keeps the real noun/adjective split baked into
  Japanese color words — akai/aoi/kiiroi/shiroi/kuroi are true
  i-adjectives, but midori/chairo/murasaki/pinku/orenji/haiiro are nouns
  (say 緑です not 緑い) — rather than forcing one pattern onto all eleven.
- **`agama_budaya` (religion) entries are deliberately neutral**: each of
  the five major religions gets the same even-handed treatment (name +
  one factual, non-doctrinal example — either a plain "Saya beragama X"
  self-statement or a well-documented demographic fact like Bali's Hindu
  majority), no claims about belief or practice for any one of them. Keep
  this evenness if adding more entries here.
- **Kotoba images** are on-demand from Firebase Storage
  (`kotoba_images/{category}/{entry_id}.png`), never bundled — `KotobaImage`
  widget resolves the download URL, caches it permanently via a dedicated
  `CacheManager` (`KotobaImageCache`, 365-day stale period), and falls back
  to a pastel-and-category-emoji placeholder on any failure (404 because the
  image hasn't been uploaded yet, network error, etc.) — this widget is
  designed to never crash or show Flutter's broken-image icon. **Gotcha**:
  don't write `setState(() => someFuture = asyncCall())` — the assignment
  expression's value (the Future) becomes the closure's own return value,
  which trips Flutter's "setState callback returned a Future" debug
  assertion. Wrap in a block body (`setState(() { someFuture = asyncCall();
  });`) instead. This crashed word-to-word navigation in
  `KotobaWordDetailScreen` (via `KotobaImage.didUpdateWidget`) until fixed.
- **Kotoba progress** (`KotobaProgressRepository`) mirrors
  `SavedWordsRepository`'s shape exactly — SharedPreferences
  (`kotoba_learned_words`) is the source of truth,
  `users/{uid}/kotobaProgress/{wordId}` is a best-effort Firestore mirror.
  `kotobaLearnedIdsProvider` (FutureProvider) is the single source Home/
  Category/Detail screens watch; call `ref.invalidate(kotobaLearnedIdsProvider)`
  after `markLearned`/`unmarkLearned` rather than threading local state
  through three screens. The multiple-choice quiz (`KotobaQuizScreen`,
  reached from the category screen's app bar) is a standalone practice
  tool — answering questions doesn't touch progress; marking "Sudah
  Dipelajari" stays a deliberate action on the detail screen.
- **Kanji module** (Batch 8) extends Batch 4's `KanjiEntry` the same way
  Kotoba extended `KotobaEntry` — added `svgAsset`, `radical`,
  `wordExamples`/`sentenceExamples` (reusing the same `SentenceExample`
  class Kotoba uses, promoted from `KotobaSentenceExample` to be
  module-neutral), and `examples` became a *computed* getter (pairs
  `wordExamples[i]` with `sentenceExamples[i]`) so
  `search/kanji_detail_screen.dart` — Batch 4's original search-flow
  detail screen — kept working unchanged. There are deliberately **two**
  Kanji detail screens: that search-flow one (static `KanjiGlyph`, no
  next/prev, reached from `SearchScreen`) and
  `kanji/kanji_word_detail_screen.dart` (animated `StrokeOrderAnimator`,
  next/prev across a level's kanji list, reached from
  `KanjiLevelScreen`'s grid) — don't conflate them.
  - **Stroke order**: `assets/kanjivg/{unicode_hex}.svg` (240 files, N5+N4
    only, fetched via `scripts/fetch_kanjivg.py` from the upstream
    KanjiVG repo — CC BY-SA, attributed in `AboutScreen`) are parsed by
    `KanjiVgParser` (`core/services/kanjivg_parser.dart`) into `Path`
    objects — a small hand-written parser, not `flutter_svg`, because
    `flutter_svg` has no public string-to-`Path` API.
    **Correction to a previous claim here**: this used to say KanjiVG's
    generated paths "only ever use M/c commands" — that was wrong, and
    the bug it caused shipped for the entirety of Batch 8. A proper scan
    of all 240 files' stroke `d` attributes (case-sensitive; an earlier,
    wrong scan used PowerShell's default case-*insensitive* string
    comparison and missed this) found 291 strokes using absolute `C` and
    32 using smooth-continuation `s`/`S`, across **177 of the 240
    characters (74%) — 77/107 N5 and 100/133 N4, almost the same rate for
    both levels**. The old M/c-only regex (`([Mc])([^Mc]*)`) swallowed
    any `C`/`s`/`S` letter into the *preceding* `c` command's captured
    argument text (since it only stopped at the next M or c), so that
    command's numbers got merged with the next one and re-sliced into
    groups of 6 — corrupting the curve from that point on, typically as a
    wild loop/spike rather than a missing or truncated stroke. Fixed by
    recognizing `C`/`s`/`S` as their own commands and tracking
    `currentX/Y` plus the last cubic's second control point, so smooth
    continuations can compute their implied first control point (the
    reflection of the previous curve's second control point through the
    current point) per the SVG spec. `test/kanjivg_parser_test.dart` has
    a regression test asserting exact hand-computed endpoints for one
    stroke of each affected command type (all three appear in 近/U+8FD1's
    strokes). If you ever touch this parser again: re-run the
    case-sensitive stroke-command scan across all 240 files before
    trusting any claim about which SVG commands appear — don't rely on
    eyeballing a handful of files, that's exactly how this shipped
    unnoticed for a full batch.
    `StrokeOrderAnimator`
    (`core/widgets/stroke_order_animator.dart`) drives a **single**
    continuous `AnimationController` (not one per stroke) and computes
    `completeStrokes`/`partialStroke` from its 0-1 value each frame; it
    also has a static "show all strokes numbered" mode reusing KanjiVG's
    own pre-computed `StrokeNumbers` label positions. `KanjiGlyph` (the
    plain static glyph used by the search-flow detail screen and
    anywhere else a non-animated character is needed) also goes through
    `KanjiVgParser` rather than `SvgPicture.asset` — the raw KanjiVG SVG
    file bundles that same `StrokeNumbers` text layer, so a naive
    `SvgPicture.asset(svgAsset)` draws stroke-count digits on top of the
    glyph everywhere it's used. This actually shipped that way through
    Batches 8's early sections and only got caught by chance while
    eyeballing search results during Fase 1's final verification pass —
    look for it if `KanjiGlyph` output ever looks numbered/cluttered
    again.
  - **Content scope**: `scripts/kanji_char_lists.py` is the single locked
    source of truth for which 107 N5 + 133 N4 characters are in scope —
    both `fetch_kanjivg.py` (which SVGs to download) and
    `generate_kanji_seed.py` (which kanji to write full content for)
    import it, so the two can't silently drift apart. Every content batch
    committed during dataset authoring was cross-checked against this
    list (`set(dataset_characters) == set(locked_characters)`) before
    committing — do the same for N3-N1 later rather than trusting a
    manual re-read of the character strings; a mid-session miscount
    (said 22, was actually 24) is exactly the failure mode this guards
    against.
  - **Progress**: `KanjiProgressRepository` mirrors
    `KotobaProgressRepository`/`SavedWordsRepository` exactly —
    SharedPreferences (`kanji_learned_ids`) is the source of truth,
    `users/{uid}/kanjiProgress/{kanjiId}` is a best-effort Firestore
    mirror, `kanjiLearnedIdsProvider` is the single thing screens watch
    and `ref.invalidate()` after marking/unmarking. **Known gap shared
    with Kotoba's identical pattern**: `_toggleLearned` in both
    `KanjiWordDetailScreen` and `KotobaWordDetailScreen` `await`s the
    repository call with no try/catch — if the Firestore mirror write
    throws (e.g. offline), the local write already succeeded but the
    button's spinner never clears until the screen is revisited, since
    the `setState(() => _togglingLearned = false)` after it never runs.
    Not fixed as part of Batch 8 since it's pre-existing in already-
    shipped Kotoba code too and touching both isn't this batch's scope —
    worth a dedicated pass later.
  - **Quiz** (`kanji_quiz_screen.dart`) has two modes picked from a
    bottom sheet (`KanjiLevelScreen`'s quiz icon) — kanji→arti (mirrors
    `KotobaQuizScreen` almost exactly) and arti→kanji (same question/
    scoring logic, just swaps which field is the prompt vs. the options
    and renders kanji options in a large centered style instead of small
    left-aligned text).
- **Bunpou module** (Batch 9+, Fase 1) is a brand-new module built by
  mirroring Kanji's architecture field-for-field rather than inventing a
  new pattern: `BunpouEntry` (`lib/data/models/bunpou_entry.dart`) has
  `pattern`/`patternRomaji`/`meaning`/`formation`/`usageNotes`/
  `similarPatterns`/`sentenceExamples`/`placeholder`, reusing the same
  `JlptLevel` enum and the same module-neutral `SentenceExample` class
  Kanji/Kotoba already share — no new example type was created. Repository
  (`BunpouRepository`), level metadata (`BunpouLevel`/
  `BunpouLevelRepository`, `assets/data/bunpou/_levels.json`), and progress
  tracking (`BunpouProgressRepository`/`BunpouProgressEntry`,
  SharedPreferences key `bunpou_learned_ids`, Firestore mirror at
  `users/{uid}/bunpouProgress` via `FirestorePaths.bunpouProgressCollection`)
  all mirror their Kanji counterparts exactly, including the same
  known try/catch gap around the Firestore mirror write (see the Kanji
  progress note above — not fixed here either, same reasoning). Screens
  (`lib/features/bunpou/`: `bunpou_home_screen.dart`,
  `bunpou_level_screen.dart`, `bunpou_detail_screen.dart`,
  `bunpou_quiz_screen.dart`) mirror Kanji's Home/Level/Detail/Quiz
  structure, with two deliberate differences: the level screen is a
  **list** (pattern + short meaning per row), not a grid, since grammar
  patterns read better as text than as a glyph grid; and the detail
  screen has no stroke animator/radical pill (not applicable to grammar)
  — the pattern is shown large with its romaji underneath instead, plus
  Arti/Pembentukan/Catatan Pemakaian sections and a TTS speak button
  (reuses `ttsServiceProvider`, no new service). `ModulesScreen` now pushes
  `BunpouHomeScreen` directly for the Bunpou card under "Tersedia"
  (`_AvailableModuleCard`, same as Kanji/Kotoba), same as how the
  previously-available modules work — the `bunpou` entry was removed
  from `kComingSoonModules` and its now-dead 12-line `ComingSoonScreen`
  stub (`lib/features/bunpou/bunpou_screen.dart`, which nothing actually
  referenced even before this) was deleted outright rather than kept
  around. Content pipeline (`scripts/bunpou_grammar_lists.py` locking
  `N5_GRAMMAR`, `scripts/generate_bunpou_seed.py` building
  `assets/data/bunpou_data.json`) mirrors the Kanji pipeline too, with an
  8-field tuple per entry (one fewer than Kanji's 9 — there's no separate
  "word examples" layer since a grammar pattern doesn't have a standalone
  vocabulary-word form the way a kanji does; sentence examples alone
  carry the teaching content). **Content scope**: all five JLPT levels
  are fully real — N5 (84 patterns), N4 (132), N3 (182), N2 (197), and
  N1 (253), totaling **848/848, zero placeholders**. All sourced from
  jlptsensei.com's grammar lists — same source already established for
  N2/N1 kanji — fetched across N5's 3, N4's 4, N3's 5, N2's 5, and N1's
  7 paginated pages respectively, each verified against the page's own
  stated total ("84"/"132"/"182"/"197"/"253") before locking. The
  Bunpou module itself is now feature-complete; only Kaiwa/Choukai
  remain unbuilt for the wider Batch 9+ scope. Don't forget to add new
  asset paths to `pubspec.yaml`'s `flutter: assets:` list when adding a
  new bundled-JSON module like this — `bunpou_data.json` and
  `assets/data/bunpou/` were initially missing from there and the app
  would have shipped with 404s on every Bunpou screen despite
  `flutter analyze`/`flutter test` both passing clean, since neither
  catches a missing asset declaration.
  **jlptsensei sometimes lists two distinct grammar points under
  identical surface text** — N4's raw source list has のに and そうだ
  each appearing twice (contrastive "even though" vs. purpose-marking
  "for ~ing" for のに; hearsay vs. appearance for そうだ) — these are
  disambiguated directly in the locked list text itself with a
  parenthetical qualifier (のに（逆接）/のに（目的）, そうだ（伝聞）/
  そうだ（様態）) rather than kept as bare duplicate strings, both so the
  list's own uniqueness assertion holds and so the two entries are
  distinguishable in the UI. Separately, eleven grammar points reuse
  identical pattern text **across** levels on purpose (でも, にする, も,
  と — N5 vs N4; だけ, こと — N5/N4 vs N3; ばかり, より — N4 vs N2; に,
  という, さ — N5/N4 vs N1) — each higher-level entry covers a genuinely
  different nuance than its lower-level counterpart (documented in that
  entry's own `usageNotes`, and cross-linked via `similarPatterns`) and
  gets an incremented id suffix (`demo2`, `ni_suru2`, `mo2`, `to2`,
  `dake2`, `koto2`, `bakari2`, `yori2`, `ni2`, `to_iu2`, `sa2`) — the
  full-dataset check tolerates duplicate `pattern` text as long as `id`
  stays unique, and specifically confirms every remaining duplicate is
  one of these eleven intentional pairs before treating the dataset as
  clean. N2's `より` is a good example of why the nuance actually
  differs: N4's is the comparison particle ("daripada"), while N2's is
  the formal written register that replaces から in
  announcements/letters/speeches ("mulai hari ini...") — jlptsensei's
  own N2 page even flags this row with a footnote-style bracket
  (`より [2]`), which is site UI, not part of the pattern text, and was
  dropped when locking `N2_GRAMMAR`. N1's three reuses follow the same
  logic: N5's bare `に` (locative/time particle) vs. N1's `に` (the
  V-masu+に+same-V repetition intensifier, e.g. 困りに困る); N4's `という`
  (simple naming, "a person called X") vs. N1's `という` (an entire
  descriptive clause attached to a noun, journalistic/narrative
  register); N4's `さ` (i-adjective→noun nominalizer, e.g. 高さ) vs.
  N1's `さ` (a colloquial masculine sentence-final assertion particle).
  **Bug found and fixed during N4's on-device verification**:
  `BunpouDetailScreen`'s "Pola Serupa" section originally rendered each
  `similarPatterns` entry as a pill showing the raw id string (e.g.
  `bunpou_aida_ni`) instead of that entry's actual pattern text — harmless
  for Kanji's equivalent `relatedBunpou` section since every kanji's list
  there is still empty, but immediately visible once Bunpou's
  `similarPatterns` started actually being populated. Fixed by adding
  `bunpouAllProvider` (`FutureProvider<List<BunpouEntry>>` wrapping
  `BunpouRepository.getAll()`, in `bunpou_providers.dart`) and a
  `_SimilarPatternsRow` widget that resolves each id to its `pattern` via
  that full list before rendering — needed because a similar pattern can
  point at an entry from a *different* JLPT level than the one currently
  being viewed (e.g. N4's `ato_de` cross-references N5's `te_kara`, or
  N1's `ba_koso` cross-references N3's `kara_koso`), so the level-scoped
  `entries` list the detail screen already holds isn't enough on its
  own. Verified end-to-end on a physical device (Moto G52J 5G):
  Home→Level→Detail→mark-learned all work for N5, N4, and N1 (progress
  badge/checkmark update live via the same invalidate-on-mutate pattern
  as Kanji/Kotoba, and "Pola Serupa" resolves cross-level ids to
  readable pattern text, confirmed again on an N1→N3 reference
  specifically). **N3 and N2 did not get the same live on-device
  re-check** — the physical test device was found locked behind a real
  PIN/pattern credential (confirmed via `adb shell locksettings
  get-disabled` erroring with "Credential can't be null or empty", not
  just a swipeable keyguard) both times verification was due for those
  two levels, and bypassing/guessing a device credential is treated as
  out of bounds regardless of task urgency. For both, the full-dataset
  Python cross-check (duplicate ids, locked-list match, schema
  completeness, `similarPatterns` resolution) passed clean and the UI
  code path is identical to the one now proven on-device for N5/N4/N1 —
  but if you're touching `BunpouDetailScreen` or related screens next, a
  fresh on-device pass covering N3/N2 specifically is still worth doing
  since it hasn't actually happened yet.
- **Partikel module** (Batch 9+) mirrors Bunpou's architecture pattern
  (model → repository → progress → screens → content pipeline), but with
  one deliberate structural difference: a Bunpou grammar pattern is ~one
  meaning per entry, while a real Japanese particle genuinely has multiple
  distinct grammatical functions (に alone covers location/direction/time/
  recipient/passive-agent). So `ParticleEntry`
  (`lib/data/models/particle_entry.dart`) nests
  `functions: List<ParticleFunction>` rather than being flat — each
  `ParticleFunction` (`particle_function.dart`) has its own
  title/explanation/formation, `sentenceExamples` (reuses the shared
  module-neutral `SentenceExample` class, same as Kanji/Kotoba/Bunpou —
  no new example type there) and `clozeExamples`
  (`List<ClozeExample>`, `cloze_example.dart` — a new, Partikel-only type,
  deliberately kept separate from `SentenceExample` rather than bolting
  quiz-only fields onto a class the other three modules share).
  `ParticleEntry.category` is a plain validated `String`
  ("kasus"/"keterangan"/"akhir_kalimat"), not a new Dart enum — unlike
  `JlptLevel` (reused app-wide: exams, profile, Bunpou), a category enum
  here would be a second source of truth for just 3 fixed values, the
  exact `_categories.json`/word-list drift risk already documented above
  for Kotoba. `ParticleCategoryInfo` (`particle_category_info.dart`,
  mirrors `BunpouLevel` + `KotobaCategory.icon`) is the only
  category-related model, loaded from `assets/data/particle/_categories.json`.
  Repository/progress layer (`ParticleRepository`/
  `ParticleCategoryRepository`/`ParticleProgressRepository`,
  SharedPreferences key `particle_learned_ids`, Firestore mirror at
  `users/{uid}/particleProgress` via
  `FirestorePaths.particleProgressCollection`) mirrors Bunpou's exactly,
  including the same known unguarded-Firestore-write gap carried a third
  time now (Kanji → Kotoba → Bunpou → Partikel) — still not fixed, still
  out of scope for whichever batch touches it, but three repetitions in
  is probably worth a dedicated fix pass rather than a fourth copy-paste
  later. `particleAllProvider` (resolves `similarParticles` ids to display
  text) was built in from day one rather than retrofitted — this is
  exactly the fix Bunpou needed only *after* its "Pola Serupa shows raw
  ids" bug shipped (see the Bunpou note above), done right the first time
  here.
  - **Screens** (`lib/features/particle/`) mirror Bunpou's Home→Category
    (renamed from "Level")→Detail/Quiz shape, with two adjustments for the
    nested model: `ParticleDetailScreen` pages next/prev **between
    particles** (same as Bunpou/Kanji), but renders each particle's
    `functions` as `ExpansionTile`s (first expanded, rest collapsed)
    instead of one flat meaning section — a に/で-style particle can have
    5 functions × 2-3 examples each, which would make an unconditionally-
    stacked column the longest page in the app. Its outer
    `SingleChildScrollView` is keyed on `ValueKey(entry.id)` — **fixing a
    real bug found in `BunpouDetailScreen` while building this**: Bunpou
    only keys the inner `_PatternDisplay`, not the scrollable itself, so
    paging next/prev carries over the previous entry's scroll offset.
    Barely visible in Bunpou (every pattern's content is similar length);
    would be very visible here (function-count varies 1-6 per particle).
    Worth the same fix in `BunpouDetailScreen` if it's touched again.
    `ParticleCategoryScreen`'s quiz icon pushes `ParticleQuizScreen`
    directly with no mode-picker sheet (unlike Bunpou's two-mode quiz) —
    the cloze mini-game only has one mode.
  - **Mini-game** (`ParticleQuizScreen`): fill-in-the-blank ("cloze") over
    one category's particles — pool every `ClozeExample` across the
    category's `ParticleFunction`s, pick 10 at random, 4-option multiple
    choice (correct answer + 3 distractor particle strings from elsewhere
    in the same category), score + restart, mirrors `BunpouQuizScreen`'s
    mechanics. `ClozeExample.sentenceBefore`/`sentenceAfter` are
    hand-split at authoring time rather than derived by searching a
    sentence for the particle substring at runtime, because a 1-2
    character hiragana particle can coincidentally appear inside an
    unrelated word/conjugation.
  - **Cloze-authoring discipline — some functions deliberately have zero
    `clozeExamples`**: に's "direction" function and へ's only function
    both mean "toward a destination" with *identical* Indonesian
    translations (学校に行きます = 学校へ行きます) — に and へ are
    genuinely, not just superficially, interchangeable there, so any
    multiple-choice question built from either would have two equally-
    correct answers whenever the other happened to land as a distractor.
    Rather than ship a coin-flip question, both functions carry full
    `sentenceExamples` for the notes screen but no `clozeExamples` — cloze
    coverage for に comes from its other 4 functions instead. The same
    reasoning drops cloze coverage from Akhir Kalimat's register-only
    particles (わ/ぞ/ぜ/さ, and な's second "casual emphasis" function):
    they differ from ね/よ/な's prohibition sense purely by *speaker
    register* (feminine/masculine/casual), which Indonesian has no
    gendered-particle equivalent for, so no translation wording can anchor
    a single correct answer. If you add more particles later, apply the
    same test before authoring a cloze: would *every* other particle in
    the category produce a sentence with a genuinely different shown
    translation? If not, leave `clozeExamples` empty for that function and
    say why inline, the same way the entries in
    `scripts/generate_particle_seed.py` do.
  - **Content scope**: 25 particles across 3 categories — Kasus (格助詞:
    が/を/に/で/と/へ/から/まで/の, 9), Keterangan (副助詞: は/も/しか/だけ/
    くらい/ばかり/でも/や, 8), Akhir Kalimat (終助詞: か/ね/よ/な/わ/ぞ/ぜ/
    さ, 8), locked in `scripts/particle_lists.py` — sourced from Tae Kim's
    Guide to Japanese Grammar + jlptsensei.com's particle-tagged entries,
    the same "well-established community source, not a nonexistent
    authority" approach already used for Kanji/Bunpou (there's no official
    JLPT particle list, official or otherwise). か lives *only* under
    Akhir Kalimat (its primary classification, sentence-final question
    marker) even though it also means "or" between nouns — that secondary
    sense is a nested `ParticleFunction` under the same entry rather than
    a second top-level list membership, since `category` is single-valued;
    の's casual sentence-final question use (どこ行くの？) is nested the
    same way under its Kasus entry. `particle_lists.py` asserts the three
    category lists are pairwise disjoint specifically so a repeat of this
    か-in-two-categories mistake — an early draft of this scope genuinely
    had it wrong — fails loudly instead of silently.
    **Overlap with Bunpou is intentional, not redundant scope**: nearly
    every particle here already has its own standalone Bunpou entry
    (が/を/で/から/まで/の/は/か/や/ね/よ/な as single N5 entries; に/と/も/
    だけ/でも/ばかり as one-of-two id-suffix pairs already documented
    above). An early draft of this module's plan assumed the two
    modules' scopes should avoid touching the same particles — that was
    wrong. Bunpou gives one terse JLPT-tagged meaning per pattern (its N5
    `に` entry is locative/time only); Partikel catalogs a particle's
    *entire* set of functions side by side in one place (5 に senses at
    once). Both modules deliberately cover the same core particles at
    different depths — that's the reason this module exists at all, not
    an oversight to fix later.
  - **Premium gate**: unlike Kanji/Kotoba/Bunpou (all shipped free),
    Partikel is deliberately premium-gated per an explicit product
    decision (confirmed, not assumed from precedent). Gating follows the
    established pattern already used by
    `lib/features/profile/widgets/avatar_picker_sheet.dart` for premium
    avatar presets/gallery upload — `ref.watch(subscriptionProvider)
    .valueOrNull?.isPremium ?? false` checked at the **tap site**
    (`ModulesScreen`'s new `_PremiumModuleCard`, not inside
    `ParticleHomeScreen`'s `build()`), branching to
    `AppNavigator.slideFromRight(context, const ParticleHomeScreen())` if
    premium or `PaywallScreen(moduleId: 'particle', moduleTitle:
    'Partikel')` if not. This required converting `ModulesScreen` from
    `StatelessWidget` to `ConsumerWidget`. `ModuleStatus.previewUnlocked`
    (an existing enum value) and the ad-reward 24h-preview read path
    (`ProgressRepository.getAdRewards`) were both confirmed **dead/never
    consulted anywhere** before this — deliberately not built on top of
    either, since the user asked for a plain premium gate, not an
    ad-preview option. `particle` was removed from `kComingSoonModules`
    (the module is real now, "sedang dalam pengembangan" messaging would
    be dishonest — same reasoning as Cam Detector's `_LockedModuleCard`
    above) and the dead 12-line `lib/features/particle/particle_screen.dart`
    stub was deleted, mirroring exactly how `bunpou_screen.dart` was
    handled. `pubspec.yaml` got `assets/data/particle_data.json` +
    `assets/data/particle/` added up front, precisely to avoid repeating
    the missing-asset gotcha documented in the Bunpou note above.
  - **Verification gap, honestly not closed**: `flutter analyze` (clean)
    and `flutter test --concurrency=1` (all 10 pre-existing tests still
    pass) both ran clean, and the full-dataset Python cross-check (no
    duplicate particle/function ids, all three category lists match
    `particle_lists.py` exactly in order and content, every
    `similarParticles` id resolves, 46 total `clozeExamples` across the
    dataset) passed clean too. The app was also confirmed to build,
    install, and launch correctly on a freshly-booted Pixel 8 emulator
    (Android 15) — Home screen renders with correct Japanese glyph display
    (confirmed via `uiautomator dump`, e.g. "あ Belajar Hiragana" renders
    as real kana, not tofu boxes). **What did NOT get verified**: tapping
    through the actual Partikel flow (premium gate → Home → Category →
    Detail's `ExpansionTile`/scroll-reset behavior → Quiz). The physical
    test device was locked behind a real credential when this was due
    (same standing rule as the Bunpou N3/N2 gap above: bypassing a device
    lock is out of bounds regardless of urgency), and on the fresh
    emulator, `adb shell input tap` reported success (exit 0) but produced
    no observable change in repeated `uiautomator dump`s despite confirmed
    correct app focus, no keyguard, and an awake screen — root cause not
    diagnosed (Android 15 ATD-image touch-injection restriction is the
    leading guess, unconfirmed). If you're touching any Partikel screen
    next, a fresh interactive on-device pass — particularly confirming the
    premium gate actually opens `PaywallScreen` for a non-premium user, and
    that ExpansionTile/scroll-reset behave as designed on the Detail
    screen — is still worth doing since it hasn't actually happened yet.
  **Update (2026-07-17)**: the premium gate described above has been
  temporarily removed — `ModulesScreen` now renders Partikel as a plain
  `_AvailableModuleCard` (no `isPremium` check, no `PaywallScreen` branch)
  so the user could test its features directly. This was an explicit,
  deliberate request, not a regression — see the monetization-roadmap
  memory (`project_monetization_roadmap.md`, outside this repo) for the
  intended final split (Partikel goes premium again eventually, alongside
  Kanji N3-N1, Bunpou N4-N1, Choukai, Kaiwa, and two still-unbuilt modules).
  Restore `_PremiumModuleCard` + the `PaywallScreen` branch (both deleted,
  not just disabled — see git history for the removed code) before release.
- **Kaiwa module** (Batch 9+) is a conversation-practice module scoped
  around **interactive** dialogues rather than a static browse/quiz pair
  like the other modules. **It went through two designs**: Fase 1
  (2026-07-17) used mic/typed free-text input matched offline by a
  `KaiwaAnswerMatcher`; this was replaced the same day (2026-07-17, second
  session) after it turned out to be the app's main source of bugs/crashes
  — `SpeechToTextService` had no `onError`/`onStatus` wiring so recognition
  errors left the mic button stuck forever, among other issues (see git
  history on `speech_to_text_service.dart`/`kaiwa_dialogue_screen.dart` for
  the blow-by-blow). **Fase 2 (current) replaces all typing/speech input
  with image + multiple-choice**, per explicit user request — the
  `speech_to_text` dependency, `SpeechToTextService`, `KaiwaAnswerMatcher`,
  and the `RECORD_AUDIO`/microphone manifest entries were all deleted
  outright rather than kept dormant, since dead permission/native-plugin
  code carries real risk (see the "Verifying changes" section's native-
  dependency gotchas) for no benefit once nothing calls it.
  Model layer (`lib/data/models/kaiwa_entry.dart`, `kaiwa_line.dart`,
  `kaiwa_answer_option.dart`, `kaiwa_category_info.dart`,
  `kaiwa_jlpt_level_info.dart`, `kaiwa_progress_entry.dart`) mirrors
  Partikel's nested shape: a `KaiwaEntry` (one dialogue/scenario, e.g.
  "Memesan Makanan di Restoran") holds an ordered `List<KaiwaLine>`, each
  either an **NPC turn** (`npcLine` a `SentenceExample` — reused
  module-neutral same as Kanji/Kotoba/Bunpou/Partikel, but only
  `.japanese` is actually used, for TTS — plus `imagePath`,
  `isUserTurn: false`) or a **user turn** (`options:
  List<KaiwaAnswerOption>`, `isUserTurn: true`). `category` is a scenario
  id ("perkenalan", "restoran", ...) grouping dialogues thematically.
  **Correction to a previous claim here**: this used to say themes were
  deliberately not JLPT-level-based, "since a real conversation doesn't
  sort itself by grammar difficulty" — that reasoning held for the
  original 2-category Fase 1/2 scope, but the user explicitly asked
  (2026-07-19) for a third layer on top: **JLPT level (N5-N1) → theme →
  dialogue**, matching Kanji/Bunpou's Home→Level→Detail shape one level
  deeper. `KaiwaCategoryInfo` gained a `level: JlptLevel` field; a theme's
  level determines the vocabulary/grammar ceiling of its dialogues, not
  the theme's subject matter itself (a theme like "Di Restoran" could in
  principle exist at multiple levels with different language complexity —
  currently only N5 versions exist, so that distinction is theoretical
  for now). Repository/progress/provider layer
  (`KaiwaRepository`/`KaiwaCategoryRepository`/`KaiwaLevelRepository`/
  `KaiwaProgressRepository`, `kaiwa_providers.dart`,
  `FirestorePaths.kaiwaProgressCollection`) mirrors Partikel's exactly for
  the theme/dialogue layers and Bunpou's `BunpouLevelRepository` for the
  new level layer, including the same known unguarded-Firestore-write gap
  carried a fourth time now (Kanji → Kotoba → Bunpou → Partikel → Kaiwa)
  — still not fixed, still out of scope for whichever batch eventually
  addresses it.
  - **No LLM/cloud AI conversation partner** — an explicit scope decision
    both designs shared, not a limitation discovered later. There is also,
    as of Fase 2, no free-text matching of any kind: correctness is just
    "did the learner tap the `KaiwaAnswerOption` with `isCorrect: true`" —
    no normalization, no fuzzy matching, nothing that can silently
    misgrade an answer or hang waiting for input that never resolves.
  - **NPC turns show only an image + a speak button, no visible text** —
    an explicit, literal product requirement (not a simplification of
    convenience): `KaiwaLine.npcLine.japanese`/`.translation` are still on
    the model (translation is unused for now, japanese feeds
    `ttsServiceProvider.speak()`) but `KaiwaDialogueScreen`'s `_LineBubble`
    never renders them as on-screen text. `KaiwaImage`
    (`lib/features/kaiwa/widgets/kaiwa_image.dart`) + `KaiwaImageCache`
    (`lib/core/services/kaiwa_image_cache.dart`) mirror
    `KotobaImage`/`KotobaImageCache` exactly: on-demand Firebase Storage
    download, permanent 365-day disk cache, graceful pastel-placeholder
    fallback on 404/null/error — same "never crash, never show Flutter's
    broken-image icon" contract. **No images have actually been uploaded
    to Storage yet** — every NPC line's `imagePath` (generated as
    `kaiwa_images/{category}/{entry_id}_{line_suffix}.png`) is a real path
    with no object behind it, so every NPC turn currently shows the 💬
    placeholder. This is the same kind of gap already documented below for
    Kotoba's 519 words — uploading illustrations is a separate task from
    building the module.
  - **User turns are pure multiple choice, in Japanese** — 2-3
    hand-authored `KaiwaAnswerOption`s per turn (one `isCorrect: true`,
    the rest plausible-but-wrong distractors — same "author explicitly,
    don't derive" reasoning as `ClozeExample`'s before/after split),
    **shuffled once per turn** (`KaiwaDialogueScreen._optionOrder`, computed
    when the turn is revealed, not recomputed every rebuild — recomputing
    on every `setState` would make the buttons visibly jump position after
    every tap). Tapping the correct option reveals it as an answered bubble
    (japanese + romaji + translation + expression-reaction emoji, mirroring
    the Fase 1 design's reveal). Tapping a wrong option gives a brief
    (600ms) red-flash on that specific button and nothing else — **no
    score penalty, no attempt limit, all options stay tappable** — per an
    explicit product decision for the app's child audience: keep trying
    until correct, never punish a wrong guess.
  - **Expression reactions**: `KaiwaAnswerOption.expressionTag` (e.g.
    `'semangat'` for 頑張ります) resolves to an emoji via
    `kaiwaExpressionEmoji` (`lib/core/constants/kaiwa_expressions.dart`) —
    shown next to the learner's bubble once the correct option is tapped.
    This was the specific feature the user asked for by name when scoping
    this module (頑張ります → "ekspresi semangat") — most options have no
    tag (`null`) and get no reaction, which is the expected common case,
    not a gap.
  - **Screens** (`lib/features/kaiwa/`): navigation is now
    `KaiwaHomeScreen` (level picker, mirrors `BunpouHomeScreen`) →
    `KaiwaLevelScreen` (theme picker for one level — this is what
    `KaiwaHomeScreen` used to be before the level layer was added, moved
    almost verbatim) → `KaiwaCategoryScreen` (dialogue list for one theme,
    unchanged) → `KaiwaDialogueScreen` (unchanged). `KaiwaCategoryScreen`
    and `KaiwaDialogueScreen` needed **no changes at all** for the level
    restructure, since neither ever touched the level concept directly —
    only the two entry-point screens above them did.
    `KaiwaDialogueScreen` is the chat-bubble UI (reveals lines
    progressively, pauses at each user turn). Its outer
    `SingleChildScrollView` is keyed on `ValueKey(entry.id)` **from the
    start** — this is the exact scroll-reset bug that shipped in
    `BunpouDetailScreen` and was only fixed for `ParticleDetailScreen`
    afterward (see the Partikel section above); Kaiwa is the first module
    built *after* that fix was documented, so it went in from day one
    instead of being a third repeat. Next/prev pages between dialogues in
    the current theme, same convention as every other detail screen;
    paging (and disposing the screen) resets all per-dialogue state,
    including the shuffled option-order cache.
  - **Content scope**: **N5 is fully built out — 17 themes, 51 dialogues,
    0 placeholders.** The original 7 themes (Perkenalan, Di Restoran, Di
    Stasiun, Belanja, Menanyakan Arah, Di Sekolah, Cuaca & Basa-basi, 21
    dialogues) were all tagged `level: "N5"` when the level layer was
    added, then 10 new N5 themes were authored alongside them in the same
    pass: Di Rumah Sakit, Hobi, Telepon, Transportasi, Di Kantor Pos,
    Rencana Liburan, Keluarga, Di Bank, Olahraga, Di Bioskop (3 dialogues
    each, 30 new dialogues at the time). **N4-N1 are registered in
    `assets/data/kaiwa/_levels.json` as `available: false` placeholders
    with zero themes** — the level layer exists in the schema and UI from
    day one, but only N5 has content; extending N4-N1 is a pure
    content-authoring pass later, no schema change needed. Locked in
    `scripts/kaiwa_lists.py` (`LEVEL_META` for the 5 levels,
    `CATEGORY_META` now a 3-tuple of name/icon/level per theme) and
    generated by `scripts/generate_kaiwa_seed.py` into
    `assets/data/kaiwa_data.json` + `assets/data/kaiwa/_categories.json` +
    `assets/data/kaiwa/_levels.json` (mirrors the Partikel/Kotoba
    Python-locked-list + generator-script pattern; the generator asserts
    every user turn has ≥2 options and exactly 1 marked correct, every
    theme's title list has no duplicates, and `CATEGORY_META`/
    `AVAILABLE_CATEGORIES` cover exactly the same theme ids).
    `PLANNED_CATEGORIES` in `kaiwa_lists.py` stays an empty list (not
    deleted) as the obvious place to register a future theme as
    `available: false` before its dialogues are ready — same convention
    already established, now joined by `LEVEL_META`'s N4-N1 entries doing
    the analogous job one layer up.
  - **Dialogue expansion, phase 1 (2026-07-17, later the same day)**: the
    user's ultimate target for N5 is 30-50 dialogues *per theme*, with
    each dialogue noticeably longer than the original 2-exchange/4-6-line
    ones. Given the true scale of that ask (17 themes × 30-50 = 510-850
    dialogues), phase 1 scoped down to bringing every theme from 3 to 10
    dialogues (7 new per theme, 119 new dialogues total), each new one
    running 4 exchanges / 7-8 lines instead of 2/4-6 — **done, all 17
    themes, 170 dialogues total** (up from 51). The per-theme assertion in
    `kaiwa_lists.py` was relaxed from `== 3` to `>= 3` to allow themes to
    grow independently during this transition; it's intentionally not
    pinned to `== 10` either, since more dialogues are still coming in
    later sessions toward the 30-50 target. **N4-N1 remain untouched** —
    this phase was N5-only, matching the user's request. Distractor design
    across all ~490 new user-turn options follows one rule: every wrong
    option is grammatically valid Japanese that's contextually wrong
    (wrong topic, contradicts a fact just stated, wrong unit — e.g.
    answering a quantity question with a time, or vice versa — or the
    wrong response type, like a question where an answer was expected) —
    never broken/nonsensical Japanese. If you continue this expansion
    (phase 2 toward 30-50/theme), keep both the exchange-count bump and
    this distractor-design rule; don't regress to the original terser
    style just because it's faster to author.
  - **Premium**: free, per explicit product decision when this module was
    scoped (2026-07-17) — see the monetization-roadmap memory for the
    intended eventual gating.
  - **Verification gap, honestly not closed**: `flutter analyze` (clean),
    `flutter test --concurrency=1` (all 10 tests clean), `flutter build
    apk --debug` (clean) all passed again after phase 1's expansion, and
    the generator's own assertions (every user turn has ≥2 options with
    exactly 1 correct, no duplicate entry ids) held for all 170 dialogues.
    Earlier interactive gaps for this module (image placeholder
    rendering, wrong-answer red flash, expression-reaction emoji) **were**
    verified on a physical device (Moto G52J 5G) during the sessions that
    chased the "empty theme list" and "missing NPC image" reports — both
    turned out not to be bugs (a stale build, and a theme's dialogues
    intentionally starting with the user speaking first, respectively).
    **What's still unverified**: the level picker screen (`KaiwaHomeScreen`)
    and N5 theme list, and phase 1's 119 newly-added dialogues
    specifically, have not had an interactive on-device pass — the Moto
    G52J wasn't connected (`adb devices` returned empty) when phase 1
    wrapped up. If you're touching Kaiwa next, tapping through Home→N5→a
    handful of the newly-expanded themes (Bank/Olahraga/Bioskop are the
    most recently authored) on a real device is worth doing since it
    hasn't actually happened yet.
- **AppNavigator** (`lib/core/navigation/app_navigator.dart`) holds the
  custom transitions (slide-from-right for drilling into content,
  slide-from-bottom for modal-ish flows, fade-scale for exam results).
  Not every navigation uses it — leaderboard/profile sub-screens still use
  plain `MaterialPageRoute`, which is fine, just don't assume 100%
  consistency.

## Known placeholders / deferred work

- **Monetization is mid-transition, not final** (as of 2026-07-17): the
  eventual plan is Kanji N3-N1, Bunpou N4-N1, Partikel, Choukai, Kaiwa,
  Belajar dari Gambar, and Belajar dari Video all premium; everything else
  free. Right now, almost none of that gating actually exists — Kanji and
  Bunpou have no premium-gating code at all (every level open), Partikel's
  gate was explicitly removed for dev testing (see the Partikel section
  above), and Kaiwa was built free from the start. Don't assume the
  current free/premium split reflects the final product; a dedicated
  pre-release pass needs to add JLPT-level-scoped gating to Kanji/Bunpou
  (new work) and restore gating on Partikel/Kaiwa/Choukai.
- **Cam Detector is deliberately locked from navigation** (not deleted —
  every file under `lib/features/cam_detector/` is untouched and still
  compiles/tests clean). `ModulesScreen` renders it as a grey
  `_LockedModuleCard` with a "Diperbaiki" badge instead of the
  `_AvailableModuleCard` it used to be; tapping shows a `SnackBar`
  explaining it's under repair, instead of the generic
  `ComingSoonContent` sheet (that sheet says "sedang dalam pengembangan"
  — appropriate for a module that was *never built*, misleading for one
  that already exists and just has open bugs). Re-enable by swapping the
  `_LockedModuleCard` call back to `_AvailableModuleCard(... onTap: () =>
  AppNavigator.slideFromBottom(context, const CamDetectorScreen()))` once
  the known issues are actually fixed — see the OCR/camera-lifecycle
  notes below for what's already been chased down vs. still unverified.
- `lib/firebase_options.dart` has real Firebase project values now (Batch
  3), but AdMob uses Google's public **test** ad unit IDs
  (`lib/core/services/ad_service.dart`, `AndroidManifest.xml`) — swap for
  production IDs before release (Batch 12+).
- Avatar art is unbuilt; every place that renders it already has a
  graceful emoji fallback. (Kanji stroke-order art *is* built now, as of
  Batch 8 — see the Kanji module note above; don't confuse the two.)
- **No Kotoba vocab images have been uploaded to Firebase Storage yet** —
  all 519 words across all 45 categories have a real `imagePath` (see
  `KotobaImage`'s gracefully-handled 404 fallback above), but the actual
  PNGs at `kotoba_images/{category}/{entry_id}.png` don't exist in the
  bucket. Every category/word tile currently shows its pastel emoji
  placeholder. Uploading real illustrations is a separate task from
  dataset authoring — re-derive the full path list via `python -c
  "import json,glob; [print(e['imagePath']) for f in
  glob.glob('assets/data/kotoba/*.json') if '_categories' not in f for e
  in json.load(open(f, encoding='utf-8'))]"` (519 lines).
- **No Kaiwa dialogue images have been uploaded to Firebase Storage
  either** — same gap as Kotoba's, just younger. Every NPC line across all
  21 dialogues (all 7 categories) has a real `imagePath`
  (`kaiwa_images/{category}/{entry_id}_{line_suffix}.png`), but none of
  those objects exist in the bucket yet, so every NPC turn currently shows
  `KaiwaImage`'s 💬 placeholder. Since the image+multiple-choice redesign
  made images the *only* thing an NPC turn shows (no text fallback), this
  gap is more visible in Kaiwa than in Kotoba right now — worth
  prioritizing this upload before Kotoba's larger 45-category backlog if
  only one can be done soon.
- Word counts per category are curated, not padded to a target — they
  range from 5 (`musim`, a genuinely small closed set) to 22
  (`hari_bulan`, which deliberately includes all 7 days + all 12 months
  since that's a complete set learners expect, not a curatorial sample).
  Every entry was only included if the kanji/reading/meaning was
  confident-enough to ship; see individual `scripts/generate_kotoba_
  <group>.py` docstrings for group-specific accuracy notes (e.g.
  `makanan_indonesia`'s Japanese transliterations of Indonesian dishes
  carry more uncertainty than native-word categories, so it stayed at 7
  entries rather than reaching for shakier ones).
- Kanji dataset: N5 (107), N4 (133), N3 (315), and now **N2 (367) are all
  fully real** as of Batch 9 — `scripts/kanji_char_lists.py` locks each
  level's character list (`N3_CHARACTERS` sourced from the Tanos JLPT
  list; `N2_CHARACTERS` sourced from jlptsensei.com's N2 list instead —
  Tanos' own N2 page returned HTTP 500 during that session — 374
  characters across 4 pages, 7 already in N5/N4 removed, 367 remain), and
  `scripts/generate_kanji_seed.py` has real content for all of them:
  `N3_KANJI` in fifteen batches (A-O, 22 each except the final batch O of
  7), `N2_KANJI` in seventeen batches (A-P 22 each, final batch Q of 15) —
  `build_n3_entries()`/`build_n2_entries()` both mirror
  `build_n4_entries()`. Every batch was cross-checked against its locked
  list before committing (authored count == locked count, no
  missing/duplicate characters or ids, order matches the locked list
  exactly) — `_levels.json`'s N3/N2 `kanjiCount` are `315`/`367`. A
  **full-dataset schema check** (all 927 entries, not just the batch just
  authored) is worth re-running after any future batch: assert no
  duplicate ids/characters across the *whole* file, every non-placeholder
  entry has ≥3 word examples / ≥2 sentence examples / a non-empty
  radical/strokeCount, and every `svgAsset` path actually exists on disk
  — this caught a real gap once (N3's 努 had only 2 word examples,
  probably a leftover from early in N3's authoring, invisible to any
  single-batch check since batch-level verification only checks the
  *newly added* entries, not the accumulated whole).
  N1, the last remaining step of this same pipeline, is now **complete
  (1503/1503)**: `N1_CHARACTERS` is locked in `kanji_char_lists.py` (1503
  characters, sourced from jlptsensei.com — Tanos' N1 page also returned
  HTTP 500 that session, same as N2's), all 2425 N5+N4+N3+N2+N1 SVGs are
  fetched, and `PLACEHOLDER_COUNTS` no longer includes N1. `N1_KANJI` was
  built batch-by-batch (22 kanji per batch, lettered A-Z, then AA/BB/CC/...
  once the single-letter alphabet ran out at Z, then AAA/BBB/CCC/... once
  the double-letter alphabet ran out at ZZ, finishing at batch QQQ — a
  final batch of 7 to close out exactly at 1503) via `build_n1_entries()`
  mirroring `build_n2_entries()`. `_levels.json`'s N1 `kanjiCount` is
  `1503`, and `kanji_data.json` now has **2425 real entries, 0
  placeholders** across all five levels. **Id-collision gotcha specific
  to N1's scale**: with 1500+ kanji sharing a small pool of common
  on'yomi/kun'yomi readings, collisions became frequent starting around
  batch W and only got more common as the dataset filled in — dozens of
  batches each produced at least one fresh `_n1` suffix that collided
  with a suffix already used many batches earlier for a *different*
  kanji with the same reading (e.g. 舗's `ho_n1` vs 浦's from batch F;
  虚's `kyo4_n1` vs 距's from batch P; 憂's `yuu4_n1` vs 裕's from batch
  L; late-stage batches like JJJ needed 3-4 rename rounds on a single
  character before landing on a free suffix). The per-batch cross-check
  script's duplicate-id assertion caught every single one before it
  shipped, by design — always by querying the actual current `N1_KANJI`
  ids via Python and incrementing the suffix number, never by guessing.
  A second permanent check — `assert t[2] or t[3]` (onyomi-or-kunyomi
  presence) — was added mid-pipeline after it caught a real bug (婦/
  `fu5_n3` was missing its onyomi); every batch since has been verified
  against both checks. If N1 content is ever revisited (corrections,
  re-authoring), keep using the same cross-check pattern — it's cheap
  and it has caught a real bug every time it's been exercised in anger.
  **jlptsensei's own N1 page total has since drifted to 1504** (their
  site explicitly says it's a "work in progress, new lessons being added
  regularly") — re-verified by fetching all 16 of their current pages
  and diffing against the locked 1503-character `N1_CHARACTERS`. The
  single extra character on their page is 嫌 (kirai/ken/gen, "benci/
  tidak suka"), which is already correctly authored under **N4**
  (`kanji_kirai`) in this dataset — the same "remove characters already
  covered at an earlier level" rule already documented for N2 (374 raw
  → 367 after removing 7 N5/N4 overlaps) applies here too, just
  undocumented for N1 until this check. **1503 is correct, not a gap.**
  If you ever re-fetch jlptsensei's N1 list and the total doesn't match
  1503 again, check for overlap with N5-N4-N3-N2 first before assuming
  a kanji is missing — don't just add whatever's new on their page.
  **Gotcha found while fetching N3's SVGs**: two of KanjiVG's stroke paths
  open with a lowercase `m` instead of `M` — `KanjiVgParser` didn't handle
  it and would have dropped that stroke's numbers the same way it dropped
  C/s/S before the fix earlier in this batch. Fixed by treating opening
  `m` as equivalent to `M` (spec-correct: a path's first moveto has no
  current point to be relative to, so relative-vs-absolute is moot
  there), with a regression test in `kanjivg_parser_test.dart`. Re-ran the
  case-sensitive stroke-command scan across the *entire* `assets/kanjivg/`
  directory (all 922 now-bundled N5+N4+N3+N2 kanji, properly scoping the
  regex to each `<path d="...">` attribute and using a case-sensitive/
  ordinal comparer — a plain PowerShell hashtable silently merges `C`≡`c`
  by default, the same footgun documented in the "Verifying changes"
  section below) after N2 landed: **M/m/c/C/s/S is still the complete
  vocabulary** (8695/2/19489/1153/86/16 occurrences respectively, nothing
  else). N2 didn't introduce anything new. If N1's SVG fetch turns up yet
  another command letter, re-run this same scan before assuming the
  vocabulary is still complete — it wasn't, the first two times this was
  checked.
- Every `KanjiEntry.relatedBunpou` is still currently an empty list, even
  though the Bunpou module now exists (Fase 1, N5) — the two datasets
  simply haven't been cross-linked yet (that's a manual curation pass:
  deciding *which* N5 grammar points relate to *which* kanji, across
  2425 kanji and 84 grammar points, not a schema change). The field and
  its UI section (`KanjiWordDetailScreen`, conditionally hidden when
  empty) were already wired for this before Bunpou existed; nothing else
  needs to change to start populating it whenever that curation pass
  happens.
- Cam Detector's Japanese OCR uses ML Kit's **bundled** model
  (`com.google.mlkit:text-recognition-japanese:16.0.1`, ~4MB, added as an
  explicit `implementation` dependency in `android/app/build.gradle.kts`).
  **Correction to a previous claim here**: this used to say "fully
  offline, no Play Services download needed" — that's unverified and
  may be wrong. The resolved dependency graph also pulls in
  `com.google.android.gms:play-services-mlkit-text-recognition-japanese`
  transitively, and `CamDetectorScreen`'s five-consecutive-failures
  comment assumes a one-time Play Services background download on first
  use. But every time that warning banner was actually reproduced on a
  physical device (release build, see "Verifying changes" below), the
  real cause was a ProGuard/R8 gap — ML Kit's component registrars losing
  their no-arg constructors — not a Play Services download. So the
  download theory in that code comment has never actually been confirmed
  true or false; don't assume either way until someone tests on a device
  with Play Services freshly reset. Relatedly, `CamDetectorScreen`'s
  `.catchError((_) { ... })` around `_recognizer.processImage(...)`
  silently discards the real exception — it only counts failures. That
  swallowing is exactly what made this ProGuard bug so slow to diagnose
  (nothing in Dart-visible logs pointed at it; had to go via physical
  logcat down to the native `TextRecognizer.kt` call). Worth logging the
  actual error there before the next time this needs debugging.
  Important gotcha if you add another script (Chinese/Korean/Devanagari)
  or another ML Kit feature later: `google_mlkit_*` plugins only
  `compileOnly`-reference their native per-feature dependencies (see the
  plugin's own `android/build.gradle`), so the *app* must add a real
  `implementation` dependency for whatever it actually uses, or it
  compiles fine but crashes at runtime with `NoClassDefFoundError` the
  first time that feature is invoked — this bit Cam Detector once
  already (fixed by adding the line above).
- Cam Detector's camera lifecycle uses a `_requestGeneration` token
  (`cam_detector_screen.dart`) so an in-flight `_startController` that
  gets superseded by a newer dispose/start — e.g. rapid background/
  foreground toggling — recognizes it's stale and discards its result
  instead of resurrecting a disposed controller. `didChangeAppLifecycleState`
  only reconnects on `resumed` when `_controller == null && _state ==
  ready` (not unconditionally) — the previous unconditional-guard version
  crashed with `CameraException(Disposed CameraController, buildPreview()
  was called on a disposed CameraController.)` when switching to another
  camera app and back, confirmed via physical-device logcat.
- Impeller is disabled for Android (`AndroidManifest.xml` meta-data
  `EnableImpeller=false`) because it renders `CameraPreview` solid black
  on API < 33 — confirmed on a physical Android 12 device: the camera
  session opens and streams frames to ML Kit fine (OCR pipeline logs
  "succeeded"), only the on-screen texture is broken. Falls back to Skia.
- Cam Detector's bounding-box overlay math (`scaleDetections` in
  `detection_overlay.dart`) assumes a portrait-locked back camera —
  verified end-to-end on a physical device (Moto G52J 5G, Android 12):
  live preview renders correctly, survives backgrounding/resuming, and
  the OCR pipeline detects text. Exact box-to-text pixel alignment
  wasn't visually re-checked against real Japanese text in this pass —
  worth a glance next time someone's on-device with real text in frame.
- `SavedWordsScreen` reads only the local SharedPreferences copy, not
  merged with Firestore — a word saved on one device won't show on
  another. Fine for now; revisit if multi-device sync matters later.
- No dedicated "Daftar Belajar" screen for `savedItems` (dictionary
  bookmarks from `KanjiDetailScreen`/`KotobaDetailScreen`) — the write
  works, there's just no browse UI yet. Don't confuse this with
  `savedWords` (Cam Detector's list, which *does* have a screen).

## Verifying changes

`flutter analyze` and `flutter test` after any change; `flutter build apk
--debug` before considering camera/native-dependency work done — that's
the cheapest way to catch native Android build breaks (Gradle dependency
conflicts, manifest merge failures) before Codemagic does. minSdk is 24
(bumped from Flutter's default for the `camera` plugin).

**Gotcha**: bare `flutter test` (default concurrency) silently drops
`test/kanjivg_parser_test.dart` from the report on this machine — it
doesn't even print a "loading" line for it, and the pass count comes out
9 instead of the real 13, with no error or warning either way. Confirmed
it isn't actually broken by re-running with `flutter test
--concurrency=1`, which loads, runs, and passes all 4 of its tests.
Root cause not diagnosed (possibly an isolate-scheduling race specific to
this file, this test package version, or this machine); `flutter clean`
didn't change anything. If a change to `kanjivg_parser.dart` or its test
needs verifying, run `flutter test test/kanjivg_parser_test.dart`
directly (or the whole suite with `--concurrency=1`) rather than trusting
bare `flutter test`'s pass count.

`flutter build apk --release` now succeeds — real release APK is
**~97.7MB** (102,435,658 bytes, `android/app/proguard-rules.pro` +
`isMinifyEnabled = true` in `build.gradle.kts`'s release buildType), a
number worth quoting instead of the debug APK's 200MB+ (inflated by debug
symbols and unshrunk resources). It wasn't a one-shot fix — three
rounds of R8 failures surfaced one after another, each only reachable
once the previous one stopped blocking the build, and **none of them are
caught by `flutter build apk --debug`** since R8 doesn't run in debug.
Do a release build at least once after touching any native Android
dependency, not just the debug build above:
1. **Missing classes**: `google_mlkit_text_recognition`'s native bridge
   (`TextRecognizer.kt`) references Chinese/Devanagari/Korean recognizer
   classes unconditionally in a `when` block, but the app only bundles
   Japanese (see the Cam Detector OCR note above) — R8 refused to build
   at all. Fixed with `-dontwarn` for the three unused
   `com.google.mlkit.vision.text.*` packages, since those branches are
   genuinely unreachable (Cam Detector only ever requests
   `TextRecognitionScript.japanese`).
2. **WorkManager/Room crash on every launch**: with (1) fixed, R8
   minification completed for the first time ever and the resulting APK
   crashed on *every* launch — `Failed to create an instance of
   androidx.work.impl.WorkDatabase`, `NoSuchMethodException` on Room's
   generated `WorkDatabase_Impl` constructor (confirmed via
   `build/app/outputs/mapping/release/configuration.txt`, R8's fully
   merged rule set: WorkManager's own consumer rules keep the Room
   database's class shell via `-keep class * extends
   androidx.room.RoomDatabase`, bare, but that doesn't protect the
   generated subclass's constructor from being stripped as apparently
   unused). Fixed with `-keep class **_Impl { *; }` / `**_Impl$*`.
3. **ML Kit/Firebase ComponentRegistrar**: with the app launching, Cam
   Detector's Japanese recognizer still failed on *every single frame*
   (see the corrected Cam Detector OCR note above) — confirmed via
   physical-device logcat: `NoSuchMethodException` on `<init>` for
   `CommonComponentRegistrar`/`TextRegistrar`/`VisionCommonRegistrar`,
   plus Firebase App Check's two registrars, all discovered reflectively
   via Firebase's `ComponentDiscoveryService` and all confirmed (via
   `javap` on the actual AARs) to `implements
   com.google.firebase.components.ComponentRegistrar`. Fixed with a keep
   rule for that interface's implementors' no-arg constructors.

If you add another native Android dependency that does anything
reflection-based (component discovery, Room, or similar), expect the
same category of failure and check `configuration.txt` plus a
physical-device logcat capture before assuming a keep rule is
unnecessary — a clean `flutter build apk --release` is not sufficient
proof by itself; (3) above built and installed fine and only showed up
as a runtime failure.
