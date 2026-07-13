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
| 6+ | Kotoba vocab modules, full Kanji/Bunpou/Kaiwa/Choukai modules, AdMob/IAP production, release polish | ⬜ not started |

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
- Avatar art, kanji stroke-order SVGs (`assets/svg/kanji/` doesn't exist
  yet — `KanjiGlyph` falls back to `Text`), and kotoba illustration PNGs
  are all unbuilt; every place that renders them already has a graceful
  text/emoji fallback.
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
- Cam Detector's bounding-box overlay math (`scaleDetections` in
  `detection_overlay.dart`) assumes a portrait-locked back camera.
  Verified on a physical device (Moto G52J 5G, Android 12) that the
  camera preview + OCR pipeline run without crashing and detect text
  end-to-end, but exact box-to-text pixel alignment wasn't visually
  re-checked after the last change — worth a glance next time someone's
  on-device with real Japanese text in frame.
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
