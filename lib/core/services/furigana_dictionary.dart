import '../../data/models/kanji_entry.dart';
import '../../data/repositories/kanji_repository.dart';
import '../../data/repositories/kotoba_repository.dart';

/// One segment of a furigana-annotated sentence: either a kanji run with a
/// reading to show above it, or a plain run (kana, punctuation, latin) with
/// no reading.
class FuriganaSegment {
  final String text;
  final String? reading;

  const FuriganaSegment(this.text, [this.reading]);
}

/// A whole-word/whole-character kana lookup used to annotate example
/// sentences with furigana, built once from data that's already loaded for
/// other reasons (the Kotoba vocab module, the Kanji dataset).
///
/// Deliberately **not** built from [KanjiEntry.wordExamples] — that list's
/// own `reading` field is romaji ("hitotsu"), not kana, and this app has no
/// romaji->kana converter (only the reverse, used at content-authoring
/// time). Guessing one at furigana-render time risks a wrong reading
/// shipping silently to a child, which is worse than showing none — so
/// compound coverage comes only from Kotoba's own kana `reading` field, and
/// single-kanji coverage falls back to that kanji's own onyomi/kunyomi
/// (already kana). A sentence using a compound this dictionary doesn't
/// cover just renders without furigana for that run, same as any other
/// word not found in a real dictionary.
class FuriganaDictionary {
  final Map<String, String> _words;

  FuriganaDictionary._(this._words);

  static Future<FuriganaDictionary> build({
    required KotobaRepository kotoba,
    required KanjiRepository kanji,
  }) async {
    final words = <String, String>{};

    final vocab = await kotoba.getAllVocab();
    for (final entry in vocab) {
      final k = entry.kanji;
      if (k == null || k.isEmpty) continue;
      words.putIfAbsent(k, () => entry.reading);
    }

    final kanjiEntries = await kanji.getAll();
    for (final entry in kanjiEntries) {
      final reading = _primaryKanjiReading(entry);
      if (reading == null) continue;
      words.putIfAbsent(entry.character, () => reading);
    }

    words.removeWhere((key, _) => _excludedWords.contains(key));

    return FuriganaDictionary._(words);
  }

  /// Words whose single stored reading is wrong often enough, across this
  /// app's real content, that showing it is worse than showing nothing —
  /// found via a full audit of every real sentence in Kaiwa/Dokkai/Choukai/
  /// Bab (2026-08-12), not guessed at:
  ///
  /// - 市場: the Kotoba dataset only records いちば (a physical market
  ///   stall/bazaar), but real N2/N1 content ("労働市場", "市場調査", "海外
  ///   市場") uses it in the economic sense しじょう ("market" as in
  ///   labor market / market research / overseas market) — a genuine
  ///   homograph this flat one-reading-per-word dictionary has no way to
  ///   disambiguate by context.
  /// - 気味: きみ is correct standalone ("気味が悪い" = creepy), but wrong
  ///   whenever it's the 〜気味 suffix ("a touch of") — that always
  ///   rendaku-voices to ぎみ (confirmed against this app's own Bunpou
  ///   entry for the pattern: `bunpou_gimi`, romaji "Kazegimi desu.",
  ///   for 風邪気味 — the segmenter matched it as 風邪(かぜ)+気味(きみ),
  ///   silently wrong by exactly the voicing this dictionary was built to
  ///   read from real data instead of guessing).
  ///
  /// The remaining nine are all the same shape — a lone kunyomi, or the
  /// first of several, that's an obscure/archaic reading or the wrong verb
  /// sense for how this app's real sentences actually use the character,
  /// while the reading a modern learner would expect (usually the onyomi,
  /// or a *different* kunyomi than whichever happened to be listed first)
  /// never gets a chance. Each was checked against real occurrences in
  /// Kaiwa/Dokkai/Choukai/Bunpou, not assumed from the character alone:
  /// - 件: only kunyomi is くだん (classical "the aforementioned") — every
  ///   real use ("この件は", "お見積もりの件で") is the everyday onyomi けん
  ///   ("matter/case").
  /// - 字: only kunyomi is あざ (an archaic land-division term) — every
  ///   real use ("字が汚い", "どんな字") is onyomi じ ("character").
  /// - 室: only kunyomi is むろ (archaic "cellar/cave") — every real use
  ///   ("コンピューター室", "音楽室") is onyomi しつ ("room").
  /// - 市: only kunyomi is いち ("marketplace") — real use ("市の図書館")
  ///   is onyomi し ("city"), the same homograph shape as 市場 above.
  /// - 入: kunyomi list is [い-る, はい-る] — real use ("今日から入りました",
  ///   "サークルに入りたい", joining an organization) needs はいる; い alone
  ///   (from い-る, a rarer sense as in 気に入る) is picked first and wrong.
  /// - 弾: kunyomi list is [たま, ひ-く, はず-む] — real use ("ギターを弾く",
  ///   playing an instrument) needs ひく; たま ("bullet", a noun sense) is
  ///   picked first and wrong.
  /// - 摂/敢: both have an *empty* kunyomi list in this app's own Kanji
  ///   dataset even though real usage is clearly kunyomi (摂る "to take/
  ///   ingest", 敢えて "dare to") — falls through to onyomi せつ/かん,
  ///   which is wrong for how either actually appears here. A data gap in
  ///   kanji_data.json, not a selection-order problem, but the fix at this
  ///   layer is the same: don't show the wrong reading that's all there is.
  /// - 関: kunyomi list is [せき, かか-わる] — real use ("関わりたくない")
  ///   needs かかわる; せき ("barrier/checkpoint", a noun sense) is picked
  ///   first and wrong.
  /// - 非: only kunyomi is あら-ず (classical negation, "is not") — real
  ///   use ("自分の非を認めて", "fault/wrongdoing") is onyomi ひ.
  ///
  /// Two more found the same day via real teacher/student reports rather
  /// than the corpus audit above — both genuinely can't be fixed by
  /// reordering which kunyomi comes first, unlike the twelve above, because
  /// the *correct* reading changes with how the word is actually used:
  /// - 降: kunyomi is [お-りる, ふ-る] — "落ちてくる/降水" senses ("雨が降る",
  ///   "雪が降る", rain/snow falling) need ふる, but "乗り物から降りる"
  ///   (getting off a train/car) needs おりる. Picking either kunyomi first
  ///   is right for one sense and confidently wrong for the other — a
  ///   genuine homograph, not a selection-order bug.
  ///   Reported: `雨が降る`/`雪が降る` in a Kotoba cuaca (weather) example
  ///   showed おりる's お instead of ふる's ふ.
  /// - 来: kunyomi is [く-る, きた-る] — 来る is one of only two genuinely
  ///   irregular verbs in Japanese, and its stem changes with conjugation:
  ///   来る=くる, 来ます/来た=き, 来ない/来い=こ. A single static reading is
  ///   wrong for every conjugated form except the bare dictionary form —
  ///   which is rare in real sentences compared to 来ます/来た/来て. Showing
  ///   く (or nothing) over 来 in "彼も来ます"/"日本から来ました" is exactly
  ///   this: the dictionary-form reading applied to a ます/た-conjugated
  ///   verb, where the real reading is き. Reported from real Bunpou も/
  ///   から example sentences.
  /// A second, much larger pass (2026-08-12, same day, after real teacher/
  /// student reports said the first pass above still missed a lot) — this
  /// time not by eyeballing sentences one at a time, but by dumping every
  /// isolated single-kanji occurrence across the *entire* bundled corpus
  /// (Kotoba/Kanji/Bunpou/Partikel/Kaiwa/Dokkai/Choukai — 49,484 sentences,
  /// 1,457 distinct characters) and running a small conjugation-aware
  /// checker over every one: does the kana actually following the kanji in
  /// the real sentence match *any* of its kunyomi's okurigana tails
  /// (including godan/ichidan/i-adjective conjugated forms — きる/きます/
  /// きた/きて, not just the bare dictionary form), or only a kunyomi other
  /// than the one `_primaryKanjiReading` would show today. That checker is
  /// a triage aid only (`scripts/_audit_furigana_heuristic.py`, not part of
  /// the app) — every one of its ~77 flags was still read by hand against
  /// the real sentence before being trusted, since it has known blind
  /// spots (it can't tell a shared stem from a real mismatch, so most of
  /// its flags turned out to be false positives where every candidate
  /// happens to reduce to the same displayed reading anyway).
  ///
  /// Every character below is a *confirmed* case, not a heuristic guess —
  /// each one has at least one real sentence in this app's own content
  /// where the reading `_primaryKanjiReading` would show today is
  /// genuinely a different word/sense than what that sentence needs. They
  /// fall into three shapes:
  ///
  /// **Wrong kunyomi picked** (a later kunyomi, not the first, is what the
  /// real sentence's okurigana actually calls for): 治 (おさめる picked,
  /// but "治りました" needs なおる), 増 (ます picked, but "増えました" needs
  /// ふえる), 悔 (くいる picked, but "悔しい" needs くやしい), 懐 (ふところ
  /// picked, but "懐かしい" needs なつかしい), 剥 (はぐ picked, but "剥き
  /// ました" needs むく), 細 (ほそい picked, but "細かく" needs こまかい),
  /// 笑 (わらう picked, but "笑みを湛えて" needs えむ), 干 (ひる picked, but
  /// every real use — "洗濯物を干します" — needs ほす), 通 (とおる picked,
  /// but every real use — "学校に通っています" — needs かよう), 跳 (とぶ
  /// picked, but "跳ね上がる" needs はねる), 捕 (とらえる picked, but every
  /// real use — "犯人を捕まえました" — needs つかまえる), 苦 (くるしい
  /// picked, but "苦いです" [bitter] needs にがい), 消 (きえる picked, but
  /// "消しゴムで消します" needs けす), 少 (すくない picked, but "少し" needs
  /// すこし), 全 (まったく picked, but "全ての人" needs すべて), 恐 (おそれる
  /// picked, but "恐いです" [scary, casual] needs こわい), 逃 (にげる
  /// picked, but "電車を逃して" [missed the train] needs のがす), 占 (しめる
  /// picked, but "占いを信じますか" needs うらなう), 担 (かつぐ picked, but
  /// "役割を担っていた" needs になう), 焦 (こげる picked, but "焦らないで"
  /// needs あせる), 潜 (ひそむ picked, but "海に潜りました" needs もぐる),
  /// 怠 (なまける picked, but "努力を怠れば" needs おこたる), 和 (なごむ
  /// picked, but every real use — "気持ちを和らげる" — needs やわらぐ), 生
  /// (いきる picked, but "生まれました" needs うまれる, and "生えています"
  /// needs an はえる reading missing from this kanji's kunyomi list
  /// entirely — a data gap, not just a selection-order problem), 盛 (もる
  /// picked, but most real use — "貿易が盛んです" — needs さかん).
  ///
  /// **Counter/idiom sense needs onyomi, kunyomi was picked**: 回 (まわる
  /// picked, but "1回だけ" needs the counter かい), 人 (ひと picked, but
  /// "30人です" needs the counter にん), 月 (つき picked, but "3月" needs
  /// がつ and "3か月" needs げつ), 泊 (とまる picked, but "1泊3万円" needs
  /// the counter はく), 巻 (まく picked, but "20巻まで" needs the counter
  /// かん), 教 (おしえる picked, but every religion-name use — "イスラム
  /// 教" — needs the suffix きょう), 定 (さだめる picked, but the idiom
  /// "案の定" doesn't use either kunyomi at all — it's read あんのじょう).
  ///
  /// **A noun/idiomatic sense needs the *whole* non-hyphenated kunyomi,
  /// but only its kanji-fallback stem showed** (would visibly look
  /// truncated, e.g. わ instead of わり): 割 ("安い割に" needs the full
  /// わり, not る-stripped わ), 係 ("私の係です" [my duty] needs the full
  /// かかり, not かか), 偽 ("偽のレビュー" [fake review] needs にせ, not
  /// いつわる's stem).
  ///
  /// **Everyday grammatical-particle-adjacent homographs, each with at
  /// least one common real use needing the *other* sense**: 分 (わかる
  /// picked, but "5分です" [5 minutes] needs the counter ふん), 後 (あと
  /// picked, but "家の後ろに" [behind the house] needs うしろ), 上 (うえ
  /// picked, but "階段を上ります" [climb the stairs] needs のぼる), 着 (きる
  /// picked, but most real use — "空港に着きました" [arrived] — needs つく),
  /// 外 (そと picked, but "予測は外れた" [the prediction missed] needs an
  /// はずれる reading missing from this kanji's kunyomi list entirely),
  /// 間 (あいだ picked, but the idiom "間に合いました" [made it in time]
  /// needs ま), 主 (ぬし picked, but "主な理由" [main reason] needs おも),
  /// 何 (なに picked, but most real use before です/だ — "趣味は何ですか"
  /// — needs なん), 訪 (おとずれる picked, but "古い寺院を訪ねました" needs
  /// たずねる), 閉 (とじる picked, but most real use — "戸を閉めて
  /// ください" — needs しめる), 汚 (きたない picked, but "泥で汚れました"
  /// needs よごれる).
  static const _excludedWords = {
    '市場', '気味', '件', '字', '室', '市', '入', '弾', '摂', '敢', '関', '非',
    '降', '来',
    '治', '増', '悔', '懐', '剥', '細', '笑', '干', '通', '跳', '捕', '苦',
    '消', '少', '全', '恐', '逃', '占', '担', '焦', '潜', '怠', '和', '生',
    '盛', '回', '人', '月', '泊', '巻', '教', '定', '割', '係', '偽', '分',
    '後', '上', '着', '外', '間', '主', '何', '訪', '閉', '汚',
  };

  static String? _primaryKanjiReading(KanjiEntry entry) {
    final source = entry.kunyomi.isNotEmpty ? entry.kunyomi : entry.onyomi;
    if (source.isEmpty) return null;
    final raw = source.first;
    // A kunyomi with okurigana is dictionary-formatted as "kanji-okurigana"
    // (遠 -> "とお-い"): the part before the hyphen is the kanji's own
    // reading, the part after is inflectional kana that's already written
    // out separately in any real sentence — the isolated-kanji fallback
    // only ever fires when this kanji is flanked by non-kanji, which for a
    // verb/adjective means its own okurigana is exactly what follows. Kept
    // whole (だけ replaceAll-ing the hyphen), 遠 flanked by its own い would
    // render furigana "とおい" over 遠 alone, immediately followed by that
    // same い again as plain text — showing い twice for one character.
    // Splitting at the hyphen and keeping only the kanji's own portion
    // (とお) matches how real printed furigana handles okurigana, and a
    // kunyomi with no okurigana at all (山 -> "やま", no hyphen) is
    // untouched either way.
    final reading = raw.contains('-') ? raw.split('-').first : raw;
    // KanjiEntry.onyomi is stored in katakana (the standard dictionary
    // convention for distinguishing it from kunyomi) — real furigana in
    // this app is otherwise uniformly hiragana (every Kotoba reading and
    // every kunyomi already is), so a kanji with no kunyomi at all (falls
    // through to onyomi here) would otherwise show as the only katakana
    // furigana anywhere in the app, which reads as visually inconsistent
    // rather than a deliberate convention.
    return entry.kunyomi.isEmpty ? _katakanaToHiragana(reading) : reading;
  }

  /// Converts katakana to hiragana one character at a time via their fixed
  /// Unicode offset (0x60 apart across the whole syllable range) — leaves
  /// anything outside that range (already hiragana, the long-vowel mark ー,
  /// punctuation) untouched, since only the syllable range has a direct
  /// hiragana counterpart.
  static String _katakanaToHiragana(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x30A1 && rune <= 0x30F6) {
        buffer.writeCharCode(rune - 0x60);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static const _maxWordLength = 4;

  bool _isKanji(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF);

  /// Splits [sentence] into [FuriganaSegment]s via greedy longest-match
  /// against this dictionary: at every kanji run, try the longest substring
  /// first and fall back to shorter ones, so a covered compound (今日) is
  /// preferred over annotating its first character alone. Kana, punctuation
  /// and any other non-kanji text pass through as plain, unannotated runs.
  ///
  /// **A kanji that is part of a longer, uncovered compound is never
  /// annotated with its own isolated reading.** The per-kanji fallback
  /// (single-kanji Kotoba entries, then onyomi/kunyomi) only fires for a
  /// kanji that truly stands alone — flanked by non-kanji on both sides.
  /// Applying it to the *first character of an unmatched multi-kanji run*
  /// used to be the actual behaviour, and it produces confidently wrong
  /// readings for real compounds: 三時半 ("3:30", read さんじはん) has no
  /// entry as a whole word, so it fell back to 三(さん)+時(とき)+半(なかば)
  /// — three individually real but jointly nonsensical readings, exactly
  /// the "guessed, silently wrong" outcome this class's own doc comment
  /// says is worse than showing nothing. When no dictionary entry covers
  /// any prefix of a multi-kanji run, the whole run is left unannotated
  /// instead.
  ///
  /// **A leftover character after a partial match must not be re-judged
  /// as freshly "isolated" either.** 時間割 ("class schedule") matches
  /// 時間(じかん) as a covered 2-kanji prefix, leaving a single trailing
  /// 割 — but 割 is still part of the original 3-kanji run, not a
  /// standalone character, so its own kunyomi (わる, the dictionary form
  /// of the verb 割る) is exactly as wrong here as 三時半's per-character
  /// guess was: the real reading in this compound is わり, not わる. Each
  /// contiguous kanji run's isolated/multi-character status is decided
  /// once, from its true start and end, before any matching begins —
  /// never re-derived from wherever a partial match happens to leave off.
  List<FuriganaSegment> segment(String sentence) {
    final runes = sentence.runes.toList();
    final segments = <FuriganaSegment>[];
    var i = 0;
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isNotEmpty) {
        segments.add(FuriganaSegment(plain.toString()));
        plain.clear();
      }
    }

    while (i < runes.length) {
      if (!_isKanji(runes[i])) {
        plain.writeCharCode(runes[i]);
        i++;
        continue;
      }

      // The extent of the *whole* contiguous kanji run, decided once —
      // not re-derived after a prefix of it is consumed by a match.
      var runEnd = i + 1;
      while (runEnd < runes.length && _isKanji(runes[runEnd])) {
        runEnd++;
      }
      final minLen = (runEnd - i) == 1 ? 1 : 2;

      while (i < runEnd) {
        final maxLen = _maxWordLength.clamp(1, runEnd - i);
        String? matchedText;
        String? matchedReading;
        if (maxLen >= minLen) {
          for (var len = maxLen; len >= minLen; len--) {
            final candidate = String.fromCharCodes(runes, i, i + len);
            final reading = _words[candidate];
            if (reading != null) {
              matchedText = candidate;
              matchedReading = reading;
              break;
            }
          }
        }

        if (matchedText != null) {
          flushPlain();
          segments.add(FuriganaSegment(matchedText, matchedReading));
          i += matchedText.length;
        } else if (minLen == 1) {
          // This run is exactly one character long — a genuinely
          // isolated kanji with no dictionary entry (rare — the
          // dataset's own kanji list is the source of the fallback map)
          // — show it plain rather than leaving a gap.
          flushPlain();
          segments.add(FuriganaSegment(String.fromCharCode(runes[i])));
          i++;
        } else {
          // No compound covers this position, and it belongs to a
          // longer run — never decompose per character (see the method
          // doc comment above). Swallow the rest of the run as one
          // plain chunk instead of retrying character by character,
          // since every remaining character would hit this same branch.
          plain.write(String.fromCharCodes(runes, i, runEnd));
          i = runEnd;
        }
      }
    }
    flushPlain();
    return segments;
  }
}
