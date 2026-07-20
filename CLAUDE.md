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
| 9+ | Kanji N3-N1 content (Fase 2), full Bunpou/Partikel/Kaiwa modules, Ujian expansion (Dokkai/Choukai/Kanji-Kombinasi), AdMob/IAP production, release polish | 🔶 in progress — kanji dataset fully real (N5-N1, 2425/2425, no placeholders); Bunpou module fully real across all 5 JLPT levels (84/132/182/197/253 = 848/848 grammar points, no placeholders); Partikel module fully real across all 3 categories (25/25 particles, 48 nested functions, no placeholders); Kaiwa module built (interactive image + multiple-choice dialogue practice, Level(N5-N1)→Theme→Dialogue hierarchy) and **fully authored across all 5 JLPT levels — 17/17 themes and 255/255 (680 for N5) dialogues at every level, 1700/1700 grand total, zero placeholders** — and free. Bunpou/Partikel/Kaiwa are all content-complete for their current scope. **Dokkai (reading comprehension, one of Ujian's four exam categories) is also now content-complete — 500/500 passages, exactly 100 per JLPT level (N5-N1), reached via a 9-phase same-day rollout** (2026-07-20); see the dedicated Dokkai rollout section below for the full history. **Choukai is no longer a standalone module** — per an explicit scope decision (2026-07-19), it was folded into Ujian as a listening-exam category instead; see the "Ujian expansion" note in the status snapshot below. **Premium gating for Partikel/Kaiwa is currently disabled app-wide for dev testing** — see the monetization-roadmap note under "Known placeholders" below, this is not the final state |

Note: "Profile Enhancement" isn't a numbered batch in the original roadmap
doc — it was scoped as part of the same work session as Batch 4 (Search &
Dictionary) but is a separate concern. If you're told to work on "Batch 4"
going forward, confirm which one is meant. Similarly, the Kanji module
above was requested mid-session as "Batch 7" — by that point Batch 7 was
already taken (full Kotoba dataset, previous row), so it's recorded here
as Batch 8. If told to work on "Batch 7" going forward, confirm which is
meant.

## Current status snapshot (session handoff, 2026-07-19)

Read this first if you're picking up this project cold — it's a fast
index into what's actually done vs. still open, with pointers into the
detailed sections below for specifics. Everything here is cross-checked
against the codebase/data as of commit `71f7596`, not just asserted from
memory.

**Fully complete, content-wise (no placeholders, verified against the
data files, not just "code exists")**:
- Kana Master, Profile/Ads/Premium/Leaderboard scaffold, Firebase
  anonymous+Google auth, Profile Enhancement, Search & Dictionary
  (Batches 1-4).
- Kotoba vocab module + full dataset: 519 words across all 45
  categories/7 groups (Batches 6-7).
- Kanji module (browse/detail/quiz screens, `StrokeOrderAnimator`) +
  full dataset: **2425/2425 kanji real across N5-N1**, zero
  placeholders (Batch 8 + Fase 2).
- Bunpou (grammar) module + full dataset: **848/848 grammar points
  real across all 5 JLPT levels** (N5 84, N4 132, N3 182, N2 197, N1
  253), zero placeholders.
- Partikel (particle) module + full dataset: **25/25 particles, 48
  nested functions real** across all 3 categories, zero placeholders.
- Kaiwa (dialogue practice) module + full dataset: **1700/1700
  dialogues real across all 5 JLPT levels** (N5 680, N4/N3/N2/N1 255
  each, 17 themes per level), zero placeholders — this was the subject
  of the multi-session rollout that just finished; see the dedicated
  Kaiwa section below for full design/workflow detail. Final
  verification (`flutter analyze`, `flutter test --concurrency=1`,
  `flutter build apk --debug`) all passed clean against this state.

**Built but with real, open gaps — don't assume "built" means
"finished"**:
- **Cam Detector** (offline Japanese OCR camera scanning) is fully
  built and still compiles/tests clean, but is **deliberately locked
  out of navigation** (the module list — `ModulesSection`, embedded in
  Home's tab body since the 2026-07-19 later-session update above,
  formerly its own `ModulesScreen` tab — shows a grey "Diperbaiki"
  card, not the module itself) because of real bugs — see "Known
  placeholders" below for the full ProGuard/R8, camera-lifecycle, and
  Impeller-rendering history. Several of those specific issues *have*
  been fixed and confirmed on a physical device; one theory (Play
  Services download vs. ProGuard as the root cause of a warning
  banner) was never conclusively resolved either way. Re-enabling
  needs a fresh confirmation pass, not just flipping the lock off.
- **Monetization is unfinished and not representative of the intended
  final product.** Kanji and Bunpou have *no* premium-gating code at
  all — every level is open regardless of the eventual plan. Partikel
  *had* a working premium gate but it was explicitly removed for dev
  testing (deliberate, not a bug). Kaiwa was built free from day one
  and this rollout didn't touch that. The actual intended split
  (Kanji N3-N1, Bunpou N4-N1, Partikel, Choukai, Kaiwa, and two
  entirely unbuilt modules — see below — all eventually premium) is
  documented but essentially unimplemented right now.
- **No illustration images exist in Firebase Storage for either
  Kotoba or Kaiwa** — both modules render real content with graceful
  pastel-emoji placeholders instead of art. Kotoba needs 519 images;
  Kaiwa now needs **7468** (one per NPC line, across all 1700
  dialogues — see the updated note below, this number grew ~350x
  during the N4-N1 rollout and is worth scoping as a deliberate
  project of its own, not a quick upload).
- `KanjiEntry.relatedBunpou` is empty for all 2425 kanji — the
  cross-link curation pass (deciding which of the 848 grammar points
  relate to which kanji) has never been done; the schema and UI are
  ready and waiting.
- AdMob uses Google's public test ad unit IDs, not production ones.
- Avatar art PNGs haven't been supplied yet, but the code is ready for
  them: `AvatarPreset.assetPath` + `AvatarPresetArt` (emoji-fallback
  `Image.asset`) are wired into every render site — drop 16 files into
  `assets/avatars/` named to match each preset id and they'll render
  automatically, no further code changes needed.
- `SavedWordsScreen` is local-only (no cross-device sync via
  Firestore); there's no browse UI for `savedItems` bookmarks at all
  (the write path works, nothing reads it back yet).

**Completely untouched — no code, no content, nothing started**:
- **Choukai's actual dialogue/audio content** — the architecture exists
  (see the 2026-07-19 later-session update above, Ujian expansion) but
  every level ships with zero clips authored. No longer "no code at
  all" the way it was earlier the same day; still "no content at all."
- **Belajar dari Gambar** and **Belajar dari Video** (two more
  planned modules, referenced only in the monetization roadmap note
  below — no screens, models, or scope decisions exist for either
  yet, not even placeholders). **Explicitly deferred (2026-07-20)**:
  after finishing the Kanji-loop/swipe-nav/dictionary-batch work above,
  the natural next step per the user's own stated roadmap was to start
  a base for these two — the user asked to hold off instead, since
  neither has a mature content plan or UX decided yet (for Gambar: what
  images, sourced how, quiz vs. flashcard vs. something else; for
  Video: what videos, hosted where, what format/subtitle shape). Rather
  than write speculative models/screens now that would likely need
  reworking once real product decisions land, the choice was to record
  the deferral here and write nothing — **zero code exists for either,
  on purpose, not because it was forgotten.** `kComingSoonModules`
  (`lib/data/models/module_info.dart`) still lists both as-is; the
  Home tab's "Segera Hadir" section still shows them exactly as before
  this session. When picking this back up, start with the product
  questions above (source/format/UX), not architecture — architecture
  can follow quickly once those are answered, mirroring how every other
  module in this app was built (own model/repository/screens trio) once
  its content shape was actually known.
- AdMob/IAP production setup (still on test IDs, no store billing
  wiring).
- General release polish (the batch-9+ row's own description of what
  "release polish" would cover hasn't been scoped in detail yet).

**Verification gaps worth knowing about** (things that pass every
automated check — `flutter analyze`/`test`/`build`, and this project's
various Python cross-check scripts — but have never had a human or an
on-device pass): the entire Kaiwa N4-N1 rollout (1020 of the 1700
dialogues), Bunpou's N3/N2 levels specifically, and Partikel's full
interactive flow (premium gate → Home → Category → Detail → Quiz) all
fall into this bucket — see each module's own section below for why
(mostly: the physical test device was locked behind a real credential
whenever verification was attempted, which is treated as out of bounds
regardless of task urgency).

If your task is "keep going" without a more specific pointer: the
Batch-9+ row above and this snapshot together are the full list of
what's left — monetization gating is the largest piece of *started-but-
unfinished* work, and the two image-upload backlogs (Kotoba 519 +
Kaiwa 7468) are large, well-defined, non-code tasks that don't require
figuring out what to build next. (Choukai used to be listed here as
the largest fully-unstarted piece of scope — as of the same-day update
directly below, it's no longer unstarted, though its *content* still
is.)

## Update (2026-07-19, later session): UX polish + Ujian expansion

A follow-up session the same day as the snapshot above shipped four
more changes, committed straight to root `master` (`3e67824` →
`881a762` → `50cc0ee` → `dbba461`, in that order) per this project's
standing local-merge convention:

1. **Flashcard swipe navigation** — `FlashcardScreen` (Hiragana/
   Katakana) can now be swiped left/right to move between cards, via a
   new generic `SwipeNavigator` widget (`lib/features/flashcard/widgets/
   swipe_navigator.dart`) wrapping `FlipCard`. The existing next/prev
   arrow buttons stay (added swipe, didn't replace the discoverable
   path). This is the app's first swipe-nav pattern — `SwipeNavigator`
   was deliberately kept generic so `kotoba_word_detail_screen.dart`/
   `kanji_word_detail_screen.dart` (which still use the older index-
   button-only pattern) could adopt it later with no changes to the
   widget itself; that adoption hasn't happened yet.
2. **"Belajar" tab merged into "Home"; bottom nav swipeable.**
   `HomeScreen`'s bottom nav dropped from 4 tabs to 3 (Home / Ujian /
   Profil) — `ModulesScreen` no longer exists as a separate tab; its
   full body (Kosakata/Kanji/Bunpou/Partikel/Kaiwa/Cam Detector/Segera
   Hadir) was extracted into `ModulesSection`
   (`lib/features/home/widgets/modules_section.dart` — git tracks this
   as a rename from `modules_screen.dart`, not a fresh file) and is now
   rendered inline inside Home's tab body, below the pre-existing
   Hiragana/Katakana/Ujian shortcut cards. **Every older mention of
   `ModulesScreen` elsewhere in this file describes historical state
   from when that screen still existed as its own tab — the class name
   survives only as `ModulesSection`, embedded in Home, not a
   standalone screen.** Separately, `HomeScreen`'s tab container changed
   from `IndexedStack` to a `PageView` (each tab wrapped in a small
   `AutomaticKeepAliveClientMixin` helper so per-tab scroll/state
   survives switching, the same guarantee `IndexedStack` gave for
   free) so swiping left/right on the body also switches tabs, not just
   tapping the bottom nav icons.
3. **Kaiwa TTS voice now matches speaker gender where the data actually
   supports it.** Gender is inferred once, at content-generation time
   (`scripts/kaiwa_lists.py`'s `infer_gender`, not hand-authored per
   dialogue), covering proper names and Bu/Pak/Ibu/Ayah/Kakek/Nenek
   honorifics — **64 of the 203 unique speaker labels across the whole
   1700-dialogue dataset**. The remaining, higher-volume role-only
   speakers ("Teman" alone is ~4645 of the ~7468 NPC lines, plus
   "Dokter"/"Petugas Bank"/etc.) are deliberately left unmapped —
   Indonesian carries no grammatical gender signal for generic role
   nouns, so guessing would be fabricating data, not inferring it; those
   lines keep using the app's single default TTS voice, same as before
   this change. `TtsService.speak()` gained an optional gender param;
   on first use it queries `flutter_tts`'s `getVoices()` **once**
   (cached, never re-queried per call) and picks a distinct-sounding
   `ja-JP` voice by name heuristic if the device exposes one, else
   falls back to a pitch nudge — never throws/hangs on a device with a
   sparse voice list. `kaiwa_data.json` was regenerated in full to add
   the new `"gender"` field to every npc line; no dialogue *content*
   changed.
4. **Ujian expanded from kana-only to a 4-category picker: Kana /
   Dokkai / Choukai / Kanji-Kombinasi**, and the standalone Choukai
   module concept is retired (see the Batch-9+ table row above) — this
   is the "Ujian expansion" referenced there. `ExamModePickerScreen` is
   now that category picker; the original 3-mode kana flow moved
   unchanged into `KanaExamModePickerScreen`. `ExamMode`/
   `ExamRepository`/`ExamQuestion`/`ExamResult` (kana-specific, see the
   Architecture section below) were **not** touched or generalized —
   each new category is a sibling module instead, following the same
   own-model/own-repository/own-screens convention every other module
   (Kanji/Kotoba/Bunpou/Partikel/Kaiwa) already uses, plus two small
   shared pieces since their quiz-flow/result shape is genuinely
   identical across all three: `McQuizFlow` and `SimpleExamResultScreen`
   (both `lib/features/exam/`), and one parametrized
   `ExamHistoryRepository` instead of three copy-pasted Firestore-mirror
   classes.
   - **Dokkai** (reading comprehension): `DokkaiPassage` model +
     `assets/data/dokkai_data.json`, JLPT level picker → passage list →
     passage text stays visible alongside its questions (unlike
     Choukai below). Ships with **3 real, hand-authored N5 passages** —
     a proof-of-architecture sample, explicitly not a content rollout —
     via the same locked-list (`scripts/dokkai_lists.py`) +
     generator-script (`scripts/generate_dokkai_seed.py`) pipeline
     Kaiwa/Bunpou/Partikel established. N4-N1 are registered in
     `assets/data/dokkai/_levels.json` as `available: false`, zero
     themes — same placeholder convention Kaiwa used for its own N4-N1
     before that rollout happened. **Expanding Dokkai to more N5
     passages and then N4-N1 is real, unstarted content work,
     comparable in shape to Kaiwa's multi-phase rollout — not done by
     this change.**
   - **Choukai** (listening comprehension): `ChoukaiClip` model, full
     architecture, **zero content authored** — all 5 levels ship
     "Segera" in `assets/data/choukai/_levels.json` and
     `choukai_data.json` is an empty array. Audio is
     `ttsServiceProvider.speak(clip.audioText)` (no recorded-audio
     pipeline anywhere in this app); the Japanese script is
     deliberately never shown during the exam, only revealed on the
     result screen for review — same no-visible-text-for-audio-source
     philosophy already established by Kaiwa's NPC turns. **This is the
     module that most needs a first content-authoring pass** if Ujian's
     Choukai category is to be usable at all.
   - **Kanji-Kombinasi**: deliberately **no new bundled dataset** —
     questions are generated at runtime from data that already exists:
     single-kanji mode reads `KanjiRepository`, compound mode mines
     `KotobaEntry.kanji` for entries that are exactly 2-3 raw kanji
     characters (`lib/data/repositories/kanji_combo_repository.dart`).
     Because of this, every JLPT level with enough real (non-
     placeholder) Kanji/Kotoba content already works today, with no
     separate authoring step — the one new-module exception to the
     "content still needs authoring" pattern above.
   - Firestore: each new category writes exam attempts to its own
     subcollection (`dokkaiExamHistory`/`choukaiExamHistory`/
     `kanjiComboExamHistory` under `users/{uid}`, see
     `lib/core/firebase/firestore_paths.dart`) rather than being forced
     into kana's existing `examHistory` shape, which is hard-typed to
     `KanaCharacter`/`WrongAnswerEntry.kanaId` and couldn't represent a
     reading passage or an audio clip without a bigger refactor that
     wasn't warranted for this pass. There is deliberately no unified
     "riwayat ujian" view across all four categories yet — `ExamHistoryScreen`
     (profile) was already an unbuilt placeholder before this change and
     still is.

Verification for all four: `flutter analyze` clean, `flutter test
--concurrency=1` (11/11, two tests updated/added for the new Ujian
picker structure), `flutter build apk --debug` succeeded. **No
interactive on-device pass has been done for any of this** — same
category of gap already documented elsewhere in this file for other
modules; worth a manual pass (especially the tab-swipe-vs-bottom-nav
interaction, and Kaiwa's gendered-voice playback on a real device)
before treating this as fully verified.

## Update (2026-07-19, third session): comprehensive search dictionary — batch 1/many

`SearchScreen` used to only search `kanji_data.json` (2425 kanji, real
coverage) and `kotoba_data.json` — which turned out to be the original
12-word-ish Batch 4 seed file (30 entries), **not** the 519-word
Kotoba vocab module's per-category files, so Search's word coverage
was accidentally far smaller than what already existed elsewhere in
the app. Rather than just wiring in the existing 519 words, the user
asked for something closer to a translator: search should eventually
cover ~10,000 everyday words, each with kanji/reading/meaning/one
example sentence — explicitly **text only**, no image, no stroke
order requirement (that requirement was raised and then deliberately
dropped once the storage-cost question below was answered).

**New, deliberately separate dataset** — not merged into the 519-word
Kotoba module, so that module's existing curation (registers, images,
categories, progress tracking) stays untouched:
- `DictionaryWord` (`lib/data/models/dictionary_word.dart`): `id`,
  `kanji` (nullable — many entries are kana-only, e.g. これ/とても/コーヒー),
  `reading`, `meaning`, one `DictionaryExample` (`japanese`+
  `translation`, no romaji field — kept intentionally lighter than the
  shared `SentenceExample` class Kanji/Kotoba/Bunpou/Kaiwa use, since
  10,000+ entries need to stay small; see the storage-math note below).
- `DictionaryRepository` (`lib/data/repositories/dictionary_repository.dart`)
  mirrors `KanjiRepository`'s eager-cache-the-whole-file pattern exactly
  — deliberately **not** the lazy per-file pattern Kotoba's
  `getVocabCategory` uses, because even at the full 10,000-word target
  the file is only ~2MB (see below), well within what `kanji_data.json`
  (2.7MB) already parses at startup fine today. Lazy/sharded loading
  would only become worth the complexity somewhere past 50,000-100,000
  words — not a concern at this dataset's actual target size.
- Wired into `SearchScreen` as a third result kind alongside Kanji/
  Kotoba (`_SearchResult.dictionary`, `_DictionaryResultTile` — small
  grey "Kamus" tag instead of a JLPT badge, since this dataset carries
  no level metadata at all). Included in search whenever the "Kotoba"
  type filter is active (they're vocabulary too, just from the bigger
  uncurated dataset) and **excluded whenever a JLPT level filter is
  selected**, since there's nothing to filter by — a deliberate scope
  cut, not a bug, and the honest tradeoff of skipping level-tagging for
  this dataset.
- `DictionaryWordDetailScreen` (`lib/features/search/`) is deliberately
  lighter than `KotobaDetailScreen` — word, reading, meaning, one
  example, TTS speak button, no image/category/registers. One thing it
  *does* add back, cheaply: each kanji character in the word becomes a
  tappable chip (`_KanjiChip`, resolved via the already-existing
  `kanjiRepositoryProvider.findByCharacter`) that opens the full
  `KanjiDetailScreen` (stroke order etc.) whenever that character
  happens to be one of the curated 2425 — greyed out and untappable
  otherwise. This gets back most of the value of the kanji-breakdown
  idea the user originally asked for and then dropped, at effectively
  zero extra engineering cost, since the lookup capability already
  existed (built for Cam Detector).

**Storage math that shaped this design** (measured against the real
519-word Kotoba dataset's per-field byte sizes, not guessed): this
schema averages **~217-280 bytes/word** compact, meaning the full
10,000-word target is only **~2-3MB**, and even 100,000 words would be
~21-27MB — trivial next to the app's existing ~98MB release APK and
`kanji_data.json`'s own 2.7MB. Storage was never the real constraint;
the actual bottleneck is **authoring** (every entry is hand-written by
an AI content-authoring pass, same as Kaiwa/Bunpou/Partikel, not
sourced from an external dictionary — see the next paragraph) and, at
much larger scale than this dataset's target, JSON-parse time at app
startup if it were ever all loaded eagerly (not a concern yet at
10,000).

**Content status: 320/~10,000 words shipped (batch 1 of many)**,
locked in `scripts/dictionary_word_lists.py` (`BATCH_1_WORDS`,
word+reading pairs asserted unique) and built by
`scripts/generate_dictionary_seed.py` into
`assets/data/dictionary_data.json` — ids are assigned sequentially by
the generator (`dict_00001`...), not hand-authored, so future batches
can just append to `ALL_WORDS` without id bookkeeping. Covers common
verbs (50), i-/na-adjectives (50), and everyday nouns across ten
themes (family, body, food, home, time, places/transport, nature,
school/work, emotions, technology) — deliberately broad, general
vocabulary rather than JLPT-level-scoped, and **not** cross-checked
against the existing 519-word Kotoba dataset for overlap (some
duplication between the two is expected and acceptable, same
"intentional overlap" reasoning already established for Bunpou vs.
Partikel elsewhere in this file). **Reaching 10,000 is explicitly a
multi-session effort** — same shape as Kaiwa's N4-N1 rollout — continue
by drafting more themed word batches, appending them to `ALL_WORDS` in
`dictionary_word_lists.py` plus a matching entries block if organized
separately, then re-running the generator and the checks below.
**Caught and fixed during this batch, worth remembering for future
batches**: kana-only entries (no kanji) must be written as
`(None, "reading", ...)` — an early draft of all 31 kana-only entries
in this batch had the tuple fields backwards
(`("reading", None, ...)`, i.e. kanji and reading swapped), caught
immediately by the generator's own `assert e["reading"]` check before
ever reaching the JSON output. Re-run that same assertion (or just
re-run the generator, which asserts on every field) after authoring
any future batch — don't assume the tuple order was followed
correctly by eye.

Verification: `flutter analyze` clean, `flutter test --concurrency=1`
(11/11 unchanged), `flutter build apk --debug` succeeded,
Cyrillic-contamination scan on both new Python files == 0, generated
JSON cross-checked (320 unique ids, no missing reading/meaning/example
fields). **No interactive on-device pass done** — same standing gap as
every other module in this file; worth confirming the "Kamus" tag
renders distinctly from real Kotoba results and that kanji chips in
`DictionaryWordDetailScreen` correctly resolve/grey-out before treating
this as fully verified.

**Update (2026-07-20)**: three more proactive batches shipped (this is
now a standing per-session habit, not something the user needs to ask
for each time — see `memory/feedback_teisou_auto_dictionary_batches.md`
outside this repo). Batch 2 (+235, clothing/shopping/animals/colors/
sports/directions/travel/health), batch 3 (+198, kitchen tools/
furniture/school subjects/professions/seasons/adverbs/question words/
greetings/office supplies/city infra/cooking+emotion+communication
verbs/weather/personality/gestures), batch 4 (+155, numbers/business/
internet/relationships/more verbs+adjectives/restaurant phrases/
exclamations/music/government/environment/transportation). **908/
~10,000 words total now.** Each batch caught and fixed real authoring
bugs via the file's own uniqueness/field assertions before shipping —
batch 3 found 6 more kana-only entries with the reading accidentally
duplicated into the kanji field (same bug class as batch 1's, see
above) via a targeted `kanji == reading` scan; batch 4 hit 3 genuine
cross-batch duplicate words (会社員/会議室/楽器, each already authored
in an earlier batch) caught by `ALL_WORDS`'s own duplicate-key
assertion and swapped for different words rather than silently
dropped. Same standing lesson each time: always actually run the
generator (which executes every assertion) rather than trusting the
tuples were typed correctly by eye — `python -c "import ast; ...`
syntax-checking alone does **not** catch either bug class, since both
are runtime assertion failures, not syntax errors.

## Update (2026-07-20): Kanji stroke animation loops; swipe navigation everywhere

Two UX changes, both session-scoped and quick:

- **`StrokeOrderAnimator`** (`lib/core/widgets/stroke_order_animator.dart`)
  used to play a kanji's stroke order once and stop on the final
  frame. It now loops automatically — an `AnimationStatus.completed`
  listener pauses 700ms on the finished character (more natural for
  repeated practice than an instant restart), then calls
  `forward(from: 0)` again, guarded by a `mounted` check and skipped
  entirely while "show all numbered" static mode is active. Applies
  uniformly to both the initial autoplay and the replay button, since
  both just call the same `forward(from: 0)` under the hood.
- **`SwipeNavigator`** (built this session for the flashcard swipe
  feature, previously `lib/features/flashcard/widgets/`) moved to
  `lib/core/widgets/swipe_navigator.dart` now that it's genuinely
  shared, and is wired into every remaining next/prev "browse" detail
  screen: `KotobaWordDetailScreen`, `KanjiWordDetailScreen`,
  `BunpouDetailScreen`, `ParticleDetailScreen`, and
  `KaiwaDialogueScreen`. Every wiring mirrors that screen's existing
  `hasPrev`/`hasNext`-gated arrow buttons exactly (swipe and the
  buttons always agree on what's available) — **except Kaiwa**, which
  additionally gates swipe on `dialogueComplete` (the same condition
  that reveals the `_CompletionBar`'s next/prev buttons in the first
  place), since without that extra gate a horizontal swipe mid-dialogue
  could let the learner skip past an unanswered user turn — a
  deliberate design constraint the buttons already enforced that swipe
  needed to inherit, not an oversight to fix later.
  **Known untested interaction, worth a physical-device check**:
  `KanjiWordDetailScreen`'s `StrokeOrderAnimator` embeds a `Slider`
  (playback speed) inside the same scrollable that's now wrapped in a
  horizontal-drag-detecting `SwipeNavigator` — both are
  `HorizontalDragGestureRecognizer`-based, and Flutter's gesture arena
  doesn't strictly guarantee the Slider always wins pointer capture
  within its own bounds. In practice nested horizontal-drag widgets
  usually resolve fine (the more specific/descendant recognizer tends
  to claim the gesture), but this specific combination hasn't been
  confirmed on a real device — if the speed slider ever feels
  unresponsive or fights with page-swiping on `KanjiWordDetailScreen`
  specifically, this is the first place to look.

Verification: `flutter analyze` clean, `flutter test --concurrency=1`
(11/11 unchanged), `flutter build apk --debug` succeeded. No
interactive on-device pass — same standing gap noted above, and
specifically relevant here given the Slider-vs-swipe risk just
described.

## Update (2026-07-20): Dokkai content rollout — 3 → 100 passages, all 5 levels at 20 each

User asked to clear out the Ujian → Dokkai backlog specifically,
eventually targeting **~100 passages per JLPT level (~500 total)** —
explicitly acknowledged as a multi-session effort, same shape as
Kaiwa's N4-N1 rollout. Two phases landed this session:

1. **N5 phase 1**: 3 → 20 passages (17 new — notes, announcements,
   schedules, letters, station/library/hospital/store notices, diary
   entries), same locked-list + generator pipeline the original 3
   used.
2. **N4/N3/N2/N1 initial seed**: every level went from **zero** to 10
   passages, per an explicit user call to prioritize breadth (some
   content everywhere) over depth-first on N5 alone — deepening every
   level toward 100 continues in future sessions, "bareng dengan
   fitur-fitur lainnya" (alongside other features), not as its own
   dedicated marathon. Grammar/topic complexity escalates by level
   exactly like Kaiwa's N5→N1 progression did: N4 uses potential
   form/conditionals/giving-receiving verbs over everyday-life topics;
   N3 adds ~ことになる/~わけ/causative-passive over more abstract
   newspaper-style and workplace topics; N2 adds ~にもかかわらず/
   ~をきっかけに/keigo touches over business/editorial/scientific
   topics; N1 adds ~ずにはいられない/~にたえない/~ゆえに/heavy keigo over
   literary and introspective topics (loss, impermanence,
   self-forgiveness) — the same "topic depth escalates independently
   of grammar difficulty, register stays readable" philosophy already
   documented for Kaiwa's N1 dialogues above.

**Architecture change worth knowing if touching this again**:
`generate_dokkai_seed.py`'s `main()` used to hardcode building only
`N5_ENTRIES` — it's now generalized to loop over a `LEVEL_ENTRIES` map
(`{level_key: (ENTRIES_list, TITLES_list)}`) covering all 5 levels, so
adding a future level's entries is just adding to that map, not
touching `main()` again. `_levels.json`'s `passageCount` is now
computed per level instead of hardcoded to `None` for everyone but N5.

3. **N4/N3/N2/N1 phase 2** (same session, immediately after): every
   non-N5 level doubled from 10 to 20, closing the gap with N5's own
   count. Same escalation pattern per level continued, no new topics
   overlapping the first 10 at each level (titles are asserted unique
   across the whole file, per level and across levels).

**Current state**: 100/~500 total (20%) — **N5=20, N4=20, N3=20,
N2=20, N1=20**, every level now at exact parity. All cross-checked
(unique ids across the whole file, unique titles, every question has
≥2 options with a valid `correctIndex`, zero Cyrillic contamination),
`flutter analyze`/`test --concurrency=1` clean. **No interactive
on-device pass done** for any of this content — same standing gap as
everywhere else in this file. If continuing this rollout: pick a
level, draft more passages at that level's grammar/topic ceiling
following the escalation pattern above, append to that level's
`_ENTRIES` list and the matching `_TITLES` list in `dokkai_lists.py`,
regenerate, and re-run the same cross-checks — the pipeline needs no
further changes to keep scaling.

**Update, same day (2026-07-20)**: two follow-up decisions from the
user.
1. **Choukai deferred to "v2"** — the user explicitly decided Choukai
   (zero content, architecture-only, see the Ujian expansion section
   above) is out of scope for now and will be picked up in a future
   v2 update, so that Dokkai can be brought to maturity first. No code
   change from this — Choukai was already architecture-only with
   nothing scheduled — just recorded here so a future session doesn't
   assume Choukai content is next in line without checking first.
2. **Dokkai UX changed: no more passage-list screen.** Per explicit
   product decision, `DokkaiLevelScreen` (the passage-title list
   between the level picker and the exam) is now **deleted outright**
   — tapping a level card in `DokkaiHomeScreen` picks one random
   passage from that level's pool (`dokkaiByLevelProvider` +
   `dart:math Random`) and opens `DokkaiExamScreen` directly. The
   reasoning: Ujian is meant to feel like "take a quiz now", not
   "browse a catalog of passages" — the level card even shows "N
   bacaan · acak setiap kali" (N passages · random each time) instead
   of a passage count you'd tap into. `DokkaiExamScreen` itself is
   unchanged (still just takes one `DokkaiPassage`), so this was a
   small, contained change — one screen deleted, one screen's tap
   handler made async to await the level's passage list before
   picking randomly.

**Update, same day (2026-07-20), phase 3**: another full round across
all five levels — N5/N4/N3/N2/N1 each went from 20 to 40 passages
(100 new, 200/~500 = 40% overall now), same escalation pattern and
pipeline as before, no architecture changes needed. This was
explicitly framed by the user as ongoing work to continue across
future sessions/updates alongside other features, not a
this-session-only push to finish — if picking this back up, the
per-level workflow (draft passages at that level's grammar/topic
ceiling → append to that level's `_ENTRIES`/`_TITLES` lists →
regenerate → re-run cross-checks) is proven and doesn't need
rethinking, just repeating.

**Update, same day (2026-07-20), session redesign + phase 4**: two
more changes right after phase 3.
1. **One Dokkai exam session is now 50 questions, not one passage's
   ~3.** `DokkaiExamScreen` (`lib/features/dokkai/dokkai_exam_screen.dart`)
   takes a `List<DokkaiPassage>` instead of one `DokkaiPassage`,
   flattens them into (passage, question) pairs in order, and stops
   once it collects `sessionQuestionTarget` (50) — consecutive
   questions from the same passage stay grouped so the passage text
   keeps showing correctly while they're answered (McQuizFlow's
   header), before moving to the next passage. `DokkaiHomeScreen`
   shuffles the *entire* level pool (not just one passage) and hands
   it all over; the exam screen just consumes as many as it needs. Per
   the user's own framing, this means a bigger content pool
   automatically buys more session variety with **zero further code
   changes** — the "feels infinite" goal is now purely a content-volume
   problem, not an architecture one.
2. **Phase 4**: N5/N4/N3/N2/N1 each went from 40 to 50 passages (50
   new, 250/~500 = 50% overall — halfway there). Same pipeline, same
   escalation pattern, no surprises.

**Update, same day (2026-07-20), phase 5**: N5/N4/N3/N2/N1 each went
from 50 to 60 passages (50 new, 300/~500 = 60% overall), same
pipeline, same escalation pattern, prompted by the user's terse
"lanjut generate lagi" — this rollout continues across sessions purely
as content authoring now, no further architecture changes expected.

**Update, same day (2026-07-20), phase 6**: N5/N4/N3/N2/N1 each went
from 60 to 70 passages (50 new, 350/~500 = 70% overall), same
pipeline, same escalation pattern, prompted by another terse "lanjut
generate" — purely content authoring, no architecture changes.

**Update, same day (2026-07-20), phase 7**: N5/N4/N3/N2/N1 each went
from 70 to 80 passages (50 new, 400/~500 = 80% overall), same
pipeline, same escalation pattern, prompted by another terse "generate
lagi". **Gotcha caught mid-phase, worth remembering**: the N2 and N1
title lists in `dokkai_lists.py` were initially missed when adding this
phase's 10-title-per-level batch (only N5/N4/N3 got updated in the
first pass) — the generator's own
`assert [e[1] for e in entries] == titles` caught it immediately with
`AssertionError: n2: authored titles don't match the locked list, in
order` on the first `python scripts/generate_dokkai_seed.py` run,
before anything was committed. Fixed by adding the missing N2/N1
title batches and re-running. This is exactly the failure mode
steps 5-6 of the per-theme workflow exist to catch — always run the
generator itself rather than assuming an edit sequence completed
cleanly.

**Update, same day (2026-07-20), phase 8**: N5/N4/N3/N2/N1 each went
from 80 to 90 passages (50 new, 450/~500 = 90% overall), same
pipeline, same escalation pattern, prompted by another terse "generate
lagi". This time all 5 levels' titles were added to `dokkai_lists.py`
in one pass before touching `generate_dokkai_seed.py` at all, specifically
to avoid repeating phase 7's N2/N1-titles-missed gotcha — worked
cleanly, generator matched on the first run.

**Update, same day (2026-07-20), phase 9 — rollout complete**:
N5/N4/N3/N2/N1 each went from 90 to 100 passages (50 new, **500/500 =
100%**), closing out the Dokkai maturity rollout that started this
same day at 3 N5-only passages. **Every JLPT level now has exactly
100 real, non-placeholder passages with 3 questions each (300
questions/level, 1500 questions total)** — the ~100/level target set
at the very start of this rollout is now met exactly, not just
approximately. Same pipeline throughout all 9 phases (locked-list +
generator-script, per-theme workflow: draft → lock titles for *all 5
levels* → author entries → syntax-check → regenerate → cross-check →
flutter analyze/test → commit → merge → update this doc), no
architecture changes were needed after the initial 50-question-session
redesign (see phase 4 above) — content authoring alone closed the
remaining 50%.

**If picking this module back up in the future**: the pool is now
large enough (300 questions/level) that a 50-question session draws
from roughly a sixth of the pool, giving strong session-to-session
variety without needing more raw content for that reason alone.
Further growth is optional, not required — reasonable next directions
instead would be: authoring Choukai's content (still zero, see the
"Known placeholders" section), a first interactive on-device pass for
Dokkai specifically (never done across any of the 9 phases — see the
verification-gap note in Batch 9+'s row), or growing past 100/level
only if a future session variety complaint actually surfaces in
practice.

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
- **Per-category exam "Rekor"** (2026-07-20): each of the four exam
  categories — Kana, Dokkai, Choukai, Kanji-Kombinasi — earns its own
  leaderboard record, defined per explicit user request as **the average
  score-percentage across every attempt** (`Poin Nilai / berapa kali
  ujian`), not a single high score. This is deliberately additive, not a
  replacement of the pre-existing `totalMastered`/`examHighScore` fields —
  `LeaderboardScreen` now has 6 scrollable tabs (`isScrollable: true`,
  bumped from 2 non-scrollable), the original two plus "Rekor Kana"/"Rekor
  Dokkai"/"Rekor Choukai"/"Rekor Kanji-Kombinasi". Storage: 3 flat fields
  per category on the same `leaderboard/{uid}` doc — `{category}RecordSum`,
  `{category}RecordCount`, `{category}RecordAvg` (the only one actually
  `orderBy`'d, since Firestore can't sort by a computed ratio of two
  fields) — updated via `LeaderboardRepository.updateCategoryRecord()`,
  which mirrors the existing `updateTotalMastered`/
  `updateExamHighScoreIfHigher` read-then-write style exactly (non-
  transactional `getSelf()` then `.set(merge:true)` — same accepted race
  trade-off already made for those two, not a new gap). `LeaderboardEntry`
  gained a `LeaderboardCategory` enum (`kana`/`dokkai`/`choukai`/
  `kanjiCombo`) and `recordSumFor`/`recordCountFor`/`recordAvgFor` accessors
  so callers don't need their own per-category switch. Kana's
  `ExamRepository.submitExam` calls `updateCategoryRecord` directly
  alongside its existing two leaderboard calls; Dokkai/Choukai/
  Kanji-Kombinasi's shared `ExamHistoryRepository` (previously just an
  `.add()` with no leaderboard hook at all) now takes a `LeaderboardCategory`
  + `LeaderboardRepository` in its constructor and calls the record update
  internally — best-effort, wrapped in its own try/catch so a leaderboard
  hiccup never undoes a history write that already succeeded — right after
  every `submit()`. This meant `ExamHistoryRepository.submit()`'s signature
  changed from positional `(uid, result)` to named params including
  `displayName`/`photoUrl`/`avatarType`/`avatarValue`, so all three exam
  screens (`dokkai_exam_screen.dart`/`choukai_exam_screen.dart`/
  `kanji_combo_exam_screen.dart`) now also read `userProfileProvider` at
  submit time, mirroring the kana exam screen's existing
  `profile?.resolveDisplayName(user)` pattern exactly (previously they only
  read `appStartupProvider` for the uid). `SimpleExamResult` gained a
  `percentage` getter mirroring `ExamResult.percentage` (`score/total*100`)
  for reuse. **Not touched on purpose**: `SimpleExamResultScreen` (the
  post-exam result screen) doesn't show anything about the new record —
  user asked for it in the Leaderboard specifically, not the result screen.
  **Verification gap, same standing pattern as everywhere else in this
  file**: `flutter analyze`/`test --concurrency=1`/`build apk --debug` all
  passed clean, but no interactive on-device pass has been done — worth
  confirming the 6-tab scrollable `TabBar` renders/scrolls correctly and
  that a real Dokkai/Choukai/Kanji-Kombinasi submission actually updates
  its "Rekor" tab before treating this as fully verified.
- **Clan/host system** (2026-07-20, same day as Rekor): a Clash-of-Clans-
  style grouping feature, deliberately scoped to **just leaderboard
  ranking** — no teacher/student role system, no per-student detail
  dashboard, per explicit user request ("hanya sebagai leaderboard saja").
  Anyone can create a clan (self-serve — `ClanRepository.createClan`);
  students join with a short generated code (`clans/{code}`, where the
  Firestore **document id doubles as the join code** — no separate lookup
  index needed, joining is just `clans.doc(code).get()`). A user can
  belong to multiple clans simultaneously (explicit user choice, not the
  simpler single-clan default that was recommended). Schema: `clans/{code}`
  (name/hostUid/hostDisplayName/memberCount/createdAt),
  `clans/{code}/members/{uid}` (roster, denormalized display identity —
  same reasoning as `leaderboard/{uid}`), `users/{uid}/clanMemberships/{code}`
  (reverse index so "which clans am I in" doesn't need a Firestore
  collection-group query + index this session couldn't verify against a
  live console). `memberCount` is the one place this feature uses
  `FieldValue.increment` rather than the read-then-write style
  `LeaderboardRepository` already established for Rekor — the right tool
  for a bare counter (no averaging involved), not an inconsistency.
  **Clan ranking is assembled client-side, not a Firestore `orderBy`**:
  `LeaderboardRepository.getMany()` (chunked `whereIn`, the first query of
  that kind in this codebase) fetches whatever `leaderboard/{uid}` docs
  exist for a clan's roster, then `clanRankingProvider`
  (`lib/features/leaderboard/clan_providers.dart`) fills in a zero-scored
  placeholder `LeaderboardEntry` for any roster member with no doc yet
  (using their `ClanMember`-denormalized name/avatar) before sorting via
  the new `LeaderboardRepository.sortByMetric()` — **every clan member
  always appears in the ranking, even at 0**, specifically so a teacher
  monitoring the clan never loses sight of a student who hasn't attempted
  anything. This is a deliberate design choice, not a bug, if the ranking
  ever looks like it's "padding" the list with zero-scorers. Ranking is a
  **one-shot fetch, not a live stream** (`getMembersOnce`) — a school clan
  could run into the dozens/hundreds of members, and this app has no
  Cloud Functions for server-side aggregation, so holding that many
  realtime listeners open wasn't worth it; `myClansProvider` (which clans
  the user is in) stays live since that list is always small per user.
  UI: 7th tab "Clan" in `LeaderboardScreen`
  (`lib/features/leaderboard/widgets/clan_tab.dart`) — clan picker +
  metric picker (reusing all six existing `LeaderboardMetric` values via
  a new `LeaderboardMetricX.label` getter, so "which stat ranks the clan"
  needed zero new metrics) + join-code display with a copy button + leave
  action, reusing `LeaderboardTile`/`LeaderboardAvatar` (renamed from
  private `_LeaderboardTile`/`_Avatar` specifically so this new file could
  reuse them instead of duplicating row rendering — any other doc in this
  file referring to `_Avatar` in `leaderboard_screen.dart` predates this
  rename). Host gets a 👑 badge in the ranking (`LeaderboardTile.isHost`).
  **Deliberately not built this pass**: kick member, rename/delete clan,
  transfer host — moderation was out of the user's stated scope.
  **"Leave clan" was added despite not being explicitly requested** — a
  judgment call, flagged here in case it needs revisiting: without it, a
  mistyped join code traps a student in the wrong clan permanently, which
  seemed like an obvious enough gap to close rather than leave as a dead
  end. **Verification gap, same standing pattern as everywhere else in
  this file**: `flutter analyze`/`test --concurrency=1`/`build apk --debug`
  all passed clean, but no interactive on-device pass — worth confirming
  the create → share-code → join → leave round trip actually works, and
  that the 7-tab scrollable `TabBar` still renders correctly, before
  treating this as fully verified.
  **Real bug shipped with this feature, caught the same day when the user
  tried it and every clan creation failed**: `firestore.rules` was never
  updated for the new `clans` collection — it only had rules for
  `users/{uid}/**` and `leaderboard/{uid}`, and Firestore denies by
  default, so every read/write to `clans/*` (including just creating one)
  failed with permission-denied from the moment this feature shipped.
  Fixed the same day by adding `clans/{code}` + `clans/{code}/members/{uid}`
  rules (any signed-in user can read; creating requires `hostUid` to match
  the creator; updating an existing clan doc is host-only except a
  memberCount-only write, which is what join/leave actually perform; each
  roster row is writable only by the uid it belongs to). **This fix lives
  in the repo's `firestore.rules` file, but that file being correct in git
  does not mean the live Firebase project is enforcing it** — Firestore
  rules only take effect once deployed (`firebase deploy --only
  firestore:rules`, or pasted into the Firebase Console's Rules tab and
  published). Neither this coding environment's Firebase CLI (broken —
  crashes on its own first-run welcome script) nor Claude's own operating
  guidelines (deploying to shared/live infrastructure needs explicit user
  action) allow deploying this automatically — **if clan creation is still
  failing, check whether the updated rules have actually been deployed to
  the live project before assuming there's a new client-side bug.** Worth
  remembering for any *future* new top-level Firestore collection in this
  app too: adding a repository/provider/UI for a new collection is not
  enough by itself, `firestore.rules` needs an explicit `match` block for
  it or every read/write silently permission-denies — this is exactly the
  kind of gap that's invisible to `flutter analyze`/`test`/`build` (which
  is exactly why it slipped through the Clan feature's original
  verification pass).
- **Avatar resolution priority** (see `UserAvatar` widget, and its
  leaderboard-row counterpart `LeaderboardAvatar` in
  `leaderboard_screen.dart` — renamed from private `_Avatar` when the Clan
  tab needed to reuse it, see the Clan/host note above):
  custom Storage upload > premium preset > free preset > Google photo >
  default emoji. 16 presets (6 free, 10 premium) are emoji + color
  placeholders defined in `lib/core/constants/avatars.dart` — swap for real
  SVG art there without touching callers.
- **Profile bug-hunt pass** (2026-07-20, requested explicitly by the user
  before any code was touched — analysis first, fixes second): found and
  fixed several real gaps in `EditNameDialog`/`AvatarPickerSheet`/
  `PaywallScreen`/`ProfileScreen`. The one worth remembering if this area
  is touched again: **`AdService.loadAndShowRewarded`'s `onRewardEarned`/
  `onFailedToLoad` callbacks did not cover every outcome** — if a rewarded
  ad loaded and showed but the user closed it before earning the reward,
  neither callback fired at all, so any caller's "watching ad" flag got
  stuck `true` forever (in `EditNameDialog` specifically, the Batal button
  is disabled while watching, so this trapped the user in the dialog with
  no way out). Fixed by adding a third callback,
  `onDismissedWithoutReward`, wired at the one shared call site in
  `AdService` — both `EditNameDialog` and `PaywallScreen` (which had the
  identical gap, found by grepping for the other caller of
  `loadAndShowRewarded` rather than assuming there was only one) now wire
  it. Also fixed in the same pass: `_saveDirectly`/`onRewardEarned`/
  `_select` had no try/catch around their Firestore writes (an unhandled
  exception meant the dialog never reached its `mounted`-check/pop, no
  user-facing error either); the "Reset Progress" dialog said "reset
  *semua* progress" but `resetAllProgress` only ever wiped hiragana/
  katakana (streak and exam history survive) — fixed by correcting the
  copy rather than silently expanding what gets deleted to match the old
  claim; `_ProgressStatCard`'s kana total was hardcoded to `46` instead of
  read from `kanaListProvider`. **Also added, not originally on the bug
  list but found while reading `firestore.rules` for an unrelated Clan
  issue the same day**: premium-gated avatar types
  (`preset_premium`/`custom_upload`) were only checked client-side in
  `AvatarPickerSheet` — nothing stopped a client writing straight to
  Firestore from setting a premium avatar without being premium. Added
  `isAllowedAvatarWrite()` to `firestore.rules`, deliberately scoped to
  only fire when `avatarType` is *actively changing* to a gated type
  while the stored subscription tier isn't premium — **not** on every
  write to the user doc, so a user whose subscription later lapses after
  legitimately setting a premium avatar doesn't get blocked from
  unrelated writes. **Same deploy caveat as the Clan feature's rules fix
  above applies here too** — this only takes effect once
  `firestore.rules` is actually deployed to the live Firebase project.
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
    and `ref.invalidate()` after marking/unmarking. **Fixed gap, shared
    with Kotoba's identical pattern**: `_toggleLearned` in both
    `KanjiWordDetailScreen` and `KotobaWordDetailScreen` `await`s the
    repository call with no try/catch of its own — if the Firestore mirror
    write threw (e.g. offline), the local write had already succeeded but
    the button's spinner never cleared until the screen was revisited,
    since the `setState(() => _togglingLearned = false)` after it never
    ran. Left unfixed through Batch 8 (out of scope then) and repeated
    unfixed in Kotoba/Bunpou/Partikel/Kaiwa's identical pattern for
    several batches after — finally fixed across all five progress
    repositories (`KanjiProgressRepository`, `KotobaProgressRepository`,
    `BunpouProgressRepository`, `ParticleProgressRepository`,
    `KaiwaProgressRepository`) in one pass during Kaiwa's dialogue-expansion
    phase 3 session: each repository's `markLearned`/`unmarkLearned` now
    wraps only the Firestore call in try/catch, since the local
    SharedPreferences write is the source of truth and already succeeded
    by that point — a network/Firestore failure there must not propagate
    up into the screen's `setState`. Fixed at the repository layer, not
    the five screens, so the fix applies uniformly without touching
    `KanjiWordDetailScreen`/`KotobaWordDetailScreen`/etc. individually.
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
  Firestore-mirror-write gap (see the Kanji progress note above) — since
  fixed there along with the other four repositories. Screens
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
  including the same unguarded-Firestore-write gap carried a third time
  (Kanji → Kotoba → Bunpou → Partikel) — since fixed there along with the
  other four repositories, see the Kanji progress note above.
  `particleAllProvider` (resolves `similarParticles` ids to display
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
  new level layer, including the same unguarded-Firestore-write gap carried
  a fourth time (Kanji → Kotoba → Bunpou → Partikel → Kaiwa) — since fixed
  there along with the other four repositories, see the Kanji progress
  note above.
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
  - **Dialogue expansion, phase 2 (2026-07-17, later the same day again)**:
    continued straight on from phase 1 toward the same 30-50/theme target
    — brought every theme from 10 to 20 dialogues (10 new per theme, 170
    new dialogues total), same 4-exchange/7-8-line style and same
    distractor-design rule as phase 1. **Done, all 17 themes, 340
    dialogues total** (up from 170 at the end of phase 1, up from 51
    originally). Still N5-only; N4-N1 untouched. 340/850 is roughly 40%
    of the eventual full-scope target (17 themes × avg. 40 = ~680-850) —
    phases 3+ would need to continue the identical per-theme workflow
    (draft 10 more → insert into `generate_kaiwa_seed.py` → append titles
    to the matching `*_TITLES` list in `kaiwa_lists.py` → syntax-check →
    regenerate → commit) to close the remaining gap. The per-theme
    assertion stays `>= 3` (not pinned to `== 20`) for the same reason as
    phase 1 — themes keep growing across sessions.
  - **Dialogue expansion, phase 3 (2026-07-18)**: brought every theme from
    20 to 40 dialogues (20 new per theme, 340 new dialogues total), same
    4-exchange/7-8-line style and same distractor-design rule as phases 1
    and 2. **Done, all 17 themes, 680 dialogues total** (up from 340 at
    the end of phase 2, up from 51 originally). Still N5-only; N4-N1
    untouched. 680 sits at the low end of the 680-850 full-scope target
    (17 themes × 40-50 avg.) — the per-theme assertion in `kaiwa_lists.py`
    stays `>= 3` rather than being pinned to `== 40`, on the chance a
    future session pushes any individual theme past 40 rather than
    lock-stepping all 17 at once. The user's original ask for this phase
    was 20-30 new dialogues per theme; 20 (the low end) was chosen
    deliberately to keep quality/distractor-design consistent across the
    full 340-dialogue scope rather than stretch to 30 and risk rushed
    content.
  - **Bug fix, same session as phase 3**: before merging phase 3, a
    codebase-wide bug audit (requested alongside the content-expansion
    ask) confirmed the long-standing "Firestore mirror write has no
    try/catch" gap — documented but left unfixed across Kanji → Kotoba →
    Bunpou → Partikel → Kaiwa's identical progress-repository pattern
    (see the Kanji progress note above for the full mechanism) — as a
    real, reproducible bug: a failed `markLearned`/`unmarkLearned`
    Firestore write (e.g. offline) left the "Tandai Sudah Dipelajari"
    button's spinner stuck forever, since the exception skipped the
    caller's `setState(() => _togglingLearned = false)`. Fixed by
    wrapping only the Firestore call (not the local SharedPreferences
    write, which is the source of truth and by that point has already
    succeeded) in try/catch, in all five progress repositories in one
    pass — the first time this five-times-repeated gap was actually
    closed rather than carried forward to the next module.
  - **Premium**: free, per explicit product decision when this module was
    scoped (2026-07-17) — see the monetization-roadmap memory for the
    intended eventual gating.
  - **Verification gap, honestly not closed**: `flutter analyze` (clean),
    `flutter test --concurrency=1` (all 10 tests clean), `flutter build
    apk --debug` (clean) all passed again after phase 3's expansion and
    the progress-repository bug fix, and the generator's own assertions
    (every user turn has ≥2 options with exactly 1 correct, no duplicate
    entry ids) held for all 680 dialogues. Earlier interactive gaps for
    this module (image placeholder rendering, wrong-answer red flash,
    expression-reaction emoji) **were** verified on a physical device
    (Moto G52J 5G) during the sessions that chased the "empty theme list"
    and "missing NPC image" reports — both turned out not to be bugs (a
    stale build, and a theme's dialogues intentionally starting with the
    user speaking first, respectively). **What's still unverified**: the
    level picker screen (`KaiwaHomeScreen`) and N5 theme list, and
    phases 1-3's combined 629 newly-added dialogues (out of 680 total),
    have not had an interactive on-device pass, nor has the progress-
    repository bug fix been confirmed to actually clear a stuck spinner
    on a real device — the Moto G52J wasn't connected (`adb devices`
    returned empty) at any point during this session either. If you're
    touching Kaiwa (or any of the other four modules sharing this fix)
    next, tapping through Home→N5→a handful of themes, and specifically
    forcing an offline Firestore write to confirm the spinner now clears,
    is still worth doing since neither has actually happened yet.
  - **N4-N1 rollout — complete (2026-07-19)**: extending Kaiwa beyond
    N5 per explicit user request ("OKE UNTUK LANJUTKAN GENERATE KAIWA
    SAMPAI N1" — continue generating Kaiwa until N1), this multi-session
    effort is now **fully done**: N4, N3, N2, and N1 are each 17/17
    themes and 255/255 dialogues (**15 dialogues per theme** for these
    four levels, deliberately less than N5's 40 — the user's locked
    scope for this rollout), landing the grand total at **1700/1700**
    across all five levels (N5 680 + N4 255 + N3 255 + N2 255 + N1
    255). Every level covers the same 17 themes: Perkenalan, Restoran,
    Stasiun, Belanja, Arah Jalan, Sekolah, Cuaca & Basa-basi, Rumah
    Sakit, Hobi, Telepon, Transportasi, Kantor Pos, Liburan, Keluarga,
    Bank, Olahraga, Bioskop. Every dialogue keeps the same 10-line/5-
    exchange (5 npc + 5 user turns) structure as N5, and the same
    distractor-design rule from N5's phases 1-3 (every wrong option is
    grammatically valid Japanese that's contextually wrong, never
    broken/nonsensical; the third option is consistently a generic
    filler like 何時ですか/何ですか/分からないよ). Final verification
    (`flutter analyze`, `flutter test --concurrency=1`, `flutter build
    apk --debug`) all passed clean against the completed dataset.
    **Grammar escalates by level, register stays conversational
    throughout**: each level's dialogues use vocabulary and grammar
    appropriate to that JLPT tier (N4 patterns for N4, all the way up
    to N1's literary-register grammar points — ~ずにはいられない, ~ゆえに,
    ~にたえない, ~と言わんばかりに, ~にせよ, heavy keigo, etc.), but the
    *topic depth* also escalates independently of grammar difficulty —
    N3 favors concrete everyday scenarios, N2 skews abstract/
    introspective (career, identity, life philosophy), and N1 goes
    further still into genuinely literary/emotional territory (grief,
    impermanence, self-forgiveness) while the two characters'
    *dialogue* itself is deliberately kept conversational rather than
    written/formal-register, even when the grammar points themselves
    are N1-level. Where a theme repeats across levels (e.g. Perkenalan
    at N5 through N1), each level's 15-40 titles are freshly drafted
    for that level's depth, never reused or simply reworded from a
    lower level.
    **The repeatable per-theme workflow** (used identically ~85 times
    across N4/N3/N2/N1, safe to trust if this ever needs revisiting —
    e.g. correcting an entry, or extending an existing level's theme
    count): (1) draft 15 dialogue titles for the theme, matching the
    target level's vocabulary/grammar ceiling and topic depth as
    described above; (2) add a `{THEME}_{LEVEL}_TITLES` list plus 3
    registration lines (`CATEGORY_META`, `AVAILABLE_CATEGORIES`,
    `_ALL_TITLE_LISTS`) to `scripts/kaiwa_lists.py`, anchored via Edit
    on the immediately preceding theme's equivalent lines; (3) draft
    the matching 15 full dialogue tuples (10-line schema: `("npc",
    suffix, speaker, japanese, romaji, translation)` / `("user",
    suffix, [(japanese, romaji, translation, is_correct,
    expression_tag_or_None), ...])`) using level-appropriate grammar
    woven naturally into the scenario implied by each title; (4) add a
    `{THEME}_{LEVEL}_ENTRIES` list to `scripts/generate_kaiwa_seed.py`
    (insert immediately before the `ENTRIES_BY_CATEGORY = {`
    declaration) plus one registration line inside that dict; (5)
    syntax-check both files with `python -c "import ast;
    ast.parse(open(path, encoding='utf-8').read())"`; (6) regenerate
    via `python scripts/generate_kaiwa_seed.py` from
    `/c/Users/LENOVO/teisou` and confirm the printed per-category count
    and running grand total match expectations exactly; (7) run three
    Python cross-checks against the regenerated
    `assets/data/kaiwa_data.json` before committing — no duplicate
    entry ids across the whole file, every user turn has ≥2 options
    with exactly 1 marked correct, and no dialogue has two identical
    NPC lines within itself (this exact "reused a stock line for two
    different NPC turns" bug shipped-then-was-caught **four** times
    across this rollout — Stasiun N1, Rumah Sakit N1's
    `pilih_transportasi_umum_rasakan_kehidupan_n1`-adjacent catch,
    Transportasi N1, and Rumah Sakit N1's own
    `perawat_keluarga_lelah_batin_n1` a second time, caught only on the
    Bioskop N1 commit when the check was finally run against the
    *entire* regenerated file rather than just newly-added entries —
    worth re-running full-file, not incremental, if this is ever
    touched again) — plus a Cyrillic-contamination scan (`python -c
    "import re; print(len(re.findall(r'[Ѐ-ӿ]',
    open('scripts/generate_kaiwa_seed.py', encoding='utf-8').read())))"`
    should print 0), added after a stray Cyrillic "т" was found mixed
    into a romaji line in Arah Jalan N1; (8) `git add
    assets/data/kaiwa_data.json assets/data/kaiwa/_categories.json
    assets/data/kaiwa/_levels.json scripts/generate_kaiwa_seed.py
    scripts/kaiwa_lists.py && git commit` directly on root master's
    `master` branch (per this project's standing "local merge, not PR"
    preference — never worktree branches, never a PR flow for this kind
    of work), with a message documenting theme content, the specific
    grammar points used, and the running per-level/grand totals; (9)
    move to the next theme. **Two earlier authoring bugs**, also
    self-caught before ever reaching a commit (during N4/N3): a stray
    `.replace(...)` expression left in a string-literal position in one
    N4 entry, and a malformed 6-element user-turn tuple (should always
    be exactly 5: `(japanese, romaji, translation, is_correct,
    expression_tag)`) in one N3 entry — both caught by the
    syntax-check/regenerate step, which is exactly why steps 5-6 are
    never skipped.
    **Verification gap, honestly not closed**: `flutter analyze`,
    `flutter test --concurrency=1`, and `flutter build apk --debug` all
    passed clean against the fully completed 1700-dialogue dataset, and
    the generator's own schema assertions plus the four cross-checks in
    step 7 above all passed against the entire file. **No interactive
    on-device pass has been done for any of N4/N3/N2/N1's content** —
    this mirrors the same gap already documented above for N5's own
    rollout, which similarly never got a full on-device pass across its
    phases. If you're touching any Kaiwa level next, tapping through
    Home→a level→a handful of themes across N4 through N1 — confirming
    the level picker surfaces all five levels correctly, dialogues
    render and progress through their 5 exchanges properly, and nothing
    about the deeper N1 topics (grief, loss, self-forgiveness) breaks
    the UI in unexpected ways — is still worth doing since it hasn't
    actually happened yet. Kaiwa remains free app-wide (see the
    monetization-roadmap note above) — this rollout didn't touch
    premium gating either way.
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
  compiles/tests clean). `ModulesSection` (formerly `ModulesScreen`,
  see the 2026-07-19 later-session update above — same module list,
  now embedded in Home instead of its own tab) renders it as a grey
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
- Avatar art PNGs haven't been supplied yet, but as of the 2026-07-20
  profile bug-hunt session the code is fully ready for them:
  `AvatarPreset` (`lib/core/constants/avatars.dart`) gained an
  `assetPath` getter (`assets/avatars/{id}.png`, derived from `id` so
  there's no separate filename-mapping table to keep in sync) and a
  new `AvatarPresetArt` widget that renders `Image.asset(preset.assetPath)`
  with an `errorBuilder` falling back to the existing emoji — same
  never-crash contract as `KotobaImage`/`KaiwaImage`, just for a
  bundled asset instead of an on-demand Storage download. Wired into
  all three render sites (`_PresetCircle` in `user_avatar.dart`,
  `LeaderboardAvatar`, `_PresetTile` in `avatar_picker_sheet.dart`).
  `assets/avatars/` is declared in `pubspec.yaml` and exists on disk
  (currently just a `.gitkeep`, confirmed an empty declared asset
  directory doesn't break `flutter build apk --debug`). Dropping in 16
  PNGs named to match each preset's `id` (`mood_happy.png`,
  `neko_sakura.png`, etc.) is the only remaining step — no code changes
  needed. (Kanji stroke-order art *is* built now, as of Batch 8 — see
  the Kanji module note above; don't confuse the two.)
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
  either** — same gap as Kotoba's, just younger, and now much bigger
  in scale. **Updated for the completed N4-N1 rollout**: Kaiwa now has
  1700 dialogues (all five JLPT levels × 17 themes each, N5's 40/theme
  and N4-N1's 15/theme) with **7468 total NPC lines**, every one
  carrying a real `imagePath`
  (`kaiwa_images/{category}/{entry_id}_{line_suffix}.png`) — none of
  those objects exist in the bucket yet, so every NPC turn across the
  entire module currently shows `KaiwaImage`'s 💬 placeholder. Since
  the image+multiple-choice redesign made images the *only* thing an
  NPC turn shows (no text fallback), this gap is fully visible
  throughout Kaiwa right now — re-derive the full path list the same
  way as Kotoba's, via `python -c "import json; data =
  json.load(open('assets/data/kaiwa_data.json', encoding='utf-8'));
  [print(l['npcLine']['imagePath']) for e in data for l in e['lines']
  if not l.get('isUserTurn')]"` (7468 lines). Uploading illustrations
  at this scale is a substantial separate task from dataset authoring
  — worth scoping deliberately (e.g. shared/reusable images per scene
  type rather than one bespoke illustration per NPC line) rather than
  assuming 7468 unique uploads.
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
