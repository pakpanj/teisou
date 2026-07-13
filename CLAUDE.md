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
| 5 | Cam Detector (offline Japanese OCR scanning) | ✅ |
| 6 | Kotoba vocab module (Home/Category/Detail, on-demand images, progress + quiz), Fase 1 dataset (10/45 categories) | ✅ |
| 7+ | Remaining 35 Kotoba categories, full Kanji/Bunpou/Kaiwa/Choukai modules, AdMob/IAP production, release polish | ⬜ not started |

Note: "Profile Enhancement" isn't a numbered batch in the original roadmap
doc — it was scoped as part of the same work session as Batch 4 (Search &
Dictionary) but is a separate concern. If you're told to work on "Batch 4"
going forward, confirm which one is meant.

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
- **Kotoba vocab module** (Batch 6) extends Batch 4's `KotobaEntry` rather
  than duplicating it: added `imagePath`, and `sentenceExample` (singular)
  became `sentenceExamples` (list) with a backward-compat getter + dual
  `fromJson` support (old singular key still works, so `kotoba_data.json`
  from Batch 4 didn't need regenerating). Per-category datasets live at
  `assets/data/kotoba/{category_id}.json` (bundled in the APK, loaded
  lazily and cached by `KotobaRepository.getVocabCategory`), distinct from
  Batch 4's single `kotoba_data.json`. `assets/data/kotoba/_categories.json`
  is metadata-only (id/name/group/icon/available/wordCount) for all 45
  planned categories across 7 groups — see `KotobaCategoryRepository` and
  `scripts/generate_kotoba_categories.py`'s `GROUPS` dict for the full
  roadmap and which are real vs. `available: false` placeholders. Regenerate
  a category's word list via its `scripts/generate_kotoba_<id>.py` (or add
  a new category tuple to `generate_kotoba_alam.py`'s `CATEGORIES` dict if
  it belongs to a group that already has a generator script), then re-run
  `generate_kotoba_categories.py` to refresh `_categories.json`'s
  `available`/`wordCount` — **don't hand-edit `_categories.json` and forget
  to re-run the word-list script, or vice versa; a stale mismatch between
  the two shipped once** (all 10 Alam & Lingkungan categories showed as
  available with placeholder counts before any dataset existed for 9 of
  them — caught via device screenshot, fixed by re-running the generator).
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
- **AppNavigator** (`lib/core/navigation/app_navigator.dart`) holds the
  custom transitions (slide-from-right for drilling into content,
  slide-from-bottom for modal-ish flows, fade-scale for exam results).
  Not every navigation uses it — leaderboard/profile sub-screens still use
  plain `MaterialPageRoute`, which is fine, just don't assume 100%
  consistency.

## Known placeholders / deferred work

- `lib/firebase_options.dart` has real Firebase project values now (Batch
  3), but AdMob uses Google's public **test** ad unit IDs
  (`lib/core/services/ad_service.dart`, `AndroidManifest.xml`) — swap for
  production IDs before release (Batch 12+).
- Avatar art and kanji stroke-order SVGs (`assets/svg/kanji/` doesn't exist
  yet — `KanjiGlyph` falls back to `Text`) are unbuilt; every place that
  renders them already has a graceful text/emoji fallback.
- **No Kotoba vocab images have been uploaded to Firebase Storage yet** —
  all 124 Fase 1 words have a real `imagePath` (see `KotobaImage`'s
  gracefully-handled 404 fallback above), but the actual PNGs at
  `kotoba_images/{category}/{entry_id}.png` don't exist in the bucket.
  Every category/word tile currently shows its pastel emoji placeholder.
  Uploading real illustrations is a separate task from dataset authoring —
  see the id list in the Batch 6 completion summary (or re-derive via
  `python -c "import json,glob; [print(e['imagePath']) for f in
  glob.glob('assets/data/kotoba/*.json') if '_categories' not in f for e
  in json.load(open(f, encoding='utf-8'))]"`) for exactly which paths are
  expected.
- 35 of 45 planned Kotoba categories (7 groups) are still `available:
  false` placeholders with no dataset — see the batch status table.
- Kanji dataset: only N5 has real entries (15). N4-N1 are `placeholder:
  true` marker rows (5 each) so level filters aren't empty — see
  `scripts/generate_kanji_seed.py` to add real ones.
- Cam Detector's Japanese OCR uses ML Kit's **bundled** model
  (`com.google.mlkit:text-recognition-japanese:16.0.1`, ~4MB, added as an
  explicit `implementation` dependency in `android/app/build.gradle.kts`)
  — fully offline from install, no Play Services download needed.
  Important gotcha if you add another script (Chinese/Korean/Devanagari)
  or another ML Kit feature later: `google_mlkit_*` plugins only
  `compileOnly`-reference their native per-feature dependencies (see the
  plugin's own `android/build.gradle`), so the *app* must add a real
  `implementation` dependency for whatever it actually uses, or it
  compiles fine but crashes at runtime with `NoClassDefFoundError` the
  first time that feature is invoked — this bit Cam Detector once
  already (fixed by adding the line above). There's still a
  five-consecutive-failures warning banner in `CamDetectorScreen` for
  genuine recognition failures unrelated to this.
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
