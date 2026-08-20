import '../../data/models/app_language.dart';
import '../constants/card_skins.dart';

/// Hand-written UI-chrome string bundle — one getter per string, an id/en
/// pair each, picked by [language]. This app has no codegen anywhere else
/// (hand-written `fromJson`/`toJson` throughout `data/models`, no
/// freezed/json_serializable), so this follows suit instead of introducing
/// Flutter's ARB/gen-l10n pipeline for the first time.
///
/// **Coverage**: every screen in the app reads this now — Home tab,
/// Modules section, Profile (+ its avatar/cover/edit-name sheets), the
/// language picker, all 5 learning modules (Kanji, Kotoba, Bunpou,
/// Partikel, Kaiwa), Search + its detail screens, Leaderboard + Clan,
/// the whole Ujian/exam flow, Saved Words, About, Notification, Paywall,
/// Cam Detector, and the "coming soon" module placeholders. See
/// CLAUDE.md's "Bahasa App" note for the full rollout history. Learning
/// content (kana/kanji/kotoba/bunpou/particle/kaiwa datasets) is
/// intentionally and permanently out of scope — this bundle is UI chrome
/// only.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  bool get _isEn => language == AppLanguage.english;
  String _t(String id, String en) => _isEn ? en : id;

  // --- Home tab ---
  String get searchTooltip => _t('Cari Kanji & Kotoba', 'Search Kanji & Kotoba');
  String get leaderboardTooltip => _t('Papan Peringkat', 'Leaderboard');
  String get homeTagline =>
      _t('Belajar Kana, Langkah Pertama Menuju Jepang!',
          'Learn Kana, Your First Step Towards Japan!');
  String get learnHiragana => _t('Belajar Hiragana', 'Learn Hiragana');
  String get learnKatakana => _t('Belajar Katakana', 'Learn Katakana');
  String get basicChars46 => _t(
        '104 karakter (dasar, tenten, maru, kombinasi)',
        '104 characters (basic, dakuten, handakuten, combinations)',
      );
  String get exam => _t('Ujian', 'Exam');

  // --- Stroke animation speed, on the kana flashcard ---
  String get strokeSpeedLabel => _t('Kecepatan', 'Speed');
  String get strokeSpeedSlow => _t('Pelan', 'Slow');
  String get strokeSpeedNormal => _t('Sedang', 'Medium');
  String get strokeSpeedFast => _t('Cepat', 'Fast');

  // --- Kana table (the gojuon picker in front of the flashcards) ---
  String get kanaTableHint =>
      _t('Pilih huruf yang ingin kamu pelajari', 'Pick a character to study');

  /// The three blocks a kana chart is taught in. Rows 0-10, 11-15 and 16-26
  /// of the dataset respectively -- see [KanaTableScreen].
  String get kanaSectionBasic => _t('Huruf Dasar', 'Basic Characters');
  String get kanaSectionDakuten =>
      _t('Tenten & Maru', 'Dakuten & Handakuten');
  String get kanaSectionYouon => _t('Huruf Gabungan', 'Combined Characters');

  /// Shown under each section heading so a child knows how big it is.
  String kanaSectionCount(int count) =>
      _t('$count huruf', '$count characters');

  // --- Home level/XP card ---
  String homeLevelLabel(int level) => _t('Level $level', 'Level $level');
  String get homeLevelSubtitle =>
      _t('Terus belajar dan kumpulkan poin!', 'Keep learning and earn points!');
  String homeLevelPointsLabel(int xpIntoLevel, int xpPerLevel) =>
      _t('$xpIntoLevel / $xpPerLevel poin', '$xpIntoLevel / $xpPerLevel points');
  String get xpClaimRewardTooltip => _t('Klaim hadiah', 'Claim reward');
  String get xpRewardClaimedTitle => _t('Selamat! 🎉', 'Congratulations! 🎉');
  String xpRewardClaimedBody(String label) =>
      _t('Kamu membuka $label!', 'You unlocked $label!');
  String get xpRewardNoneTitle => _t('Naik Level!', 'Level Up!');
  String get xpRewardNoneBody => _t(
      'Semua hadiah sudah kamu miliki. Terus belajar untuk naik level lagi!',
      'You already own every reward. Keep learning to level up again!');
  String get xpRewardKindAvatar => _t('Avatar', 'Avatar');
  String get xpRewardKindFrame => _t('Bingkai profil', 'Profile frame');
  String get xpRewardKindCover => _t('Sampul profil', 'Profile cover');
  String get close => _t('Tutup', 'Close');

  // --- Bottom nav ---
  String get navHome => _t('Home', 'Home');
  String get navExam => _t('Ujian', 'Exam');
  String get navProfile => _t('Profil', 'Profile');

  // --- Modules section ---
  // Section headers, ordered the way someone actually learns Japanese:
  // the two syllabaries first, then the words and characters built from
  // them, then the grammar that joins those, then putting it to use.
  // Tools and unbuilt modules sit after the learning path, not inside it.
  String get sectionBasics => _t('Dasar', 'Basics');
  String get sectionVocabKanji => _t('Kosakata & Kanji', 'Vocabulary & Kanji');
  String get sectionGrammar => _t('Tata Bahasa', 'Grammar');
  String get sectionPractice => _t('Latihan', 'Practice');
  String get sectionBattle => _t('Bertanding', 'Battle');
  String get sectionTools => _t('Alat', 'Tools');
  String get comingSoonHeader => _t('Segera Hadir', 'Coming Soon');
  String get fixingBadge => _t('Diperbaiki', 'Fixing');
  String get comingSoonBadge => _t('Segera Hadir', 'Coming Soon');
  String get camDetectorTitle => 'Cam Detector';
  String get camDetectorSubtitle =>
      _t('Scan karakter Jepang lewat kamera', 'Scan Japanese text via camera');
  String get camDetectorReason => _t(
        'Sedang diperbaiki karena masih ada beberapa bug. '
            'Modul ini akan diaktifkan kembali setelah perbaikan selesai.',
        'Currently being fixed due to a few remaining bugs. '
            'This module will be re-enabled once fixes are done.',
      );
  String get kotobaTitle => _t('Kosakata', 'Vocabulary');
  String get kotobaSubtitle =>
      _t('Belajar kotoba per kategori', 'Learn vocabulary by category');
  String get kanjiTitle => 'Kanji';
  String get kanjiSubtitle =>
      _t('Belajar Kanji per level JLPT', 'Learn Kanji by JLPT level');
  String get bunpouTitle => 'Bunpou';
  String get bunpouSubtitle => _t(
        'Belajar pola tata bahasa per level JLPT',
        'Learn grammar patterns by JLPT level',
      );
  String get particleTitle => _t('Partikel', 'Particles');
  String get particleSubtitle => _t(
        'Catatan fungsi partikel + mini-game latihan',
        'Particle function notes + practice mini-game',
      );
  String get kaiwaTitle => 'Kaiwa';
  String get kaiwaSubtitle =>
      _t('Latihan percakapan interaktif', 'Interactive conversation practice');
  String get pictureLearningTitle =>
      _t('Belajar dari Gambar', 'Learn from Pictures');
  String get pictureLearningSubtitle => _t(
        'Perkaya kosakata lewat asosiasi gambar',
        'Grow your vocabulary through picture association',
      );
  String get videoLearningTitle => _t('Belajar dari Video', 'Learn from Videos');
  String get videoLearningSubtitle => _t(
        'Video singkat dengan subtitle dwibahasa',
        'Short videos with bilingual subtitles',
      );

  // --- Profile screen ---
  String get profile => _t('Profil', 'Profile');
  String failedToLoadProfile(Object e) =>
      _t('Gagal memuat profil: $e', 'Failed to load profile: $e');
  String get changeNameTooltip => _t('Ganti Nama', 'Change Name');
  String get profileMotivation => _t(
        'Belajar setiap hari,\nsedikit demi sedikit, pasti bisa! 🌸',
        'Learn a little every day,\nlittle by little, you can do it! 🌸',
      );
  String get signInWithGoogle => _t('Masuk dengan Google', 'Sign in with Google');
  String get defaultLearnerName => _t('Pelajar Kana', 'Kana Learner');
  String userIdLabel(String id) => _t('ID: $id', 'ID: $id');
  String get userIdCopied => _t('ID disalin.', 'ID copied.');
  String get userIdTooltip =>
      _t('Ketuk untuk salin ID', 'Tap to copy ID');
  String get googleAccountAlreadyLinked =>
      _t('Akun Google ini sudah terhubung ke akun lain.',
          'This Google account is already linked to another account.');
  String get googleSignInFailed => _t(
        'Gagal masuk dengan Google. Periksa koneksi internet kamu dan coba lagi.',
        'Failed to sign in with Google. Check your internet connection and try again.',
      );
  String masteredCount(int mastered, int total) =>
      _t('$mastered/$total Dikuasai', '$mastered/$total Mastered');
  String get streak => _t('Streak', 'Streak');
  String streakDays(int streak) => _t(
        '$streak hari berturut-turut belajar!',
        '$streak days in a row!',
      );
  String get keepYourStreak => _t('Pertahankan streak-mu!', 'Keep your streak going!');
  String get days => _t('HARI', 'DAYS');
  String get examHistory => _t('Riwayat Ujian', 'Exam History');
  String get seeAll => _t('Lihat Semua', 'See All');
  String get noExamHistory => _t('Belum ada riwayat ujian.', 'No exam history yet.');
  String get examCategoryDokkai => _t('Dokkai', 'Dokkai');
  String get examCategoryChoukai => _t('Choukai', 'Choukai');
  String get examCategoryKanjiComboCombination =>
      _t('Kombinasi Kanji', 'Kanji Combination');
  String get examCategoryKanjiComboSingle =>
      _t('Kanji Tunggal', 'Single Kanji');
  String examResultTitle(String category) =>
      _t('Hasil $category', '$category Result');
  String get failedToLoadExamHistory =>
      _t('Gagal memuat riwayat ujian.', 'Failed to load exam history.');
  String get savedWords => _t('Daftar Belajar', 'Saved Words');
  String get appLanguage => _t('Bahasa App', 'App Language');
  String get notifications => _t('Notifikasi', 'Notifications');
  String get aboutApp => _t('Tentang App', 'About App');
  String get logout => _t('Keluar', 'Log Out');
  String get cancel => _t('Batal', 'Cancel');
  String get continueLabel => _t('Lanjut', 'Continue');
  String get delete => _t('Hapus', 'Delete');
  String get logoutConfirmTitle => _t('Keluar dari akun?', 'Log out of your account?');
  String get logoutConfirmBody => _t(
        'Yakin mau keluar? Progress kamu sudah tersimpan di cloud dan '
            'bisa diakses kembali setelah login.',
        "Are you sure you want to log out? Your progress is already saved "
            "to the cloud and can be restored after logging back in.",
      );
  // --- Language screen ---
  String get chooseAppLanguage =>
      _t('Pilih bahasa aplikasi', 'Choose app language');
  String get languageScopeNote => _t(
        'Catatan: sebagian layar mungkin masih menggunakan Bahasa '
            'Indonesia untuk saat ini.',
        "Note: some screens may still show Indonesian text for now.",
      );
  String get languageSaved => _t('Bahasa disimpan.', 'Language saved.');

  // --- Theme screen ---
  String get appTheme => _t('Tema App', 'App Theme');
  String get chooseAppTheme => _t('Pilih tema aplikasi', 'Choose app theme');
  String get themeLight => _t('Terang', 'Light');
  String get themeDark => _t('Gelap', 'Dark');
  String get themeSystem => _t('Ikuti Sistem', 'Follow System');
  String get themeLightDesc =>
      _t('Tampilan cerah, seperti biasa.', 'Bright look, as always.');
  String get themeDarkDesc => _t(
        'Latar gelap, lebih nyaman di ruangan minim cahaya.',
        'Dark background, easier on the eyes in low light.',
      );
  String get themeSystemDesc => _t(
        'Ikut pengaturan terang/gelap di HP kamu.',
        "Follows your phone's light/dark setting.",
      );

  // --- Shared across module Home/Level/Category/Detail/Quiz screens ---
  String get soonBadge => _t('Segera', 'Soon');
  String get startQuizTooltip => _t('Mulai Kuis', 'Start Quiz');
  String get filterAll => _t('Semua', 'All');
  String get filterNotLearned => _t('Belum Dipelajari', 'Not Learned');
  String get filterLearned => _t('Sudah Dipelajari', 'Learned');
  String progressLearned(int learned, int total) =>
      _t('$learned/$total dipelajari', '$learned/$total learned');
  String get markedLearned => _t('Sudah Dipelajari', 'Learned');
  String get markAsLearned => _t('Tandai Sudah Dipelajari', 'Mark as Learned');
  String questionOf(int index, int total) =>
      _t('Soal $index / $total', 'Question $index / $total');
  String get seeScore => _t('Lihat Skor', 'See Score');
  String get finish => _t('Selesai', 'Finish');
  String get retry => _t('Ulangi', 'Retry');
  String scoreOf(int score, int total) =>
      _t('Skor: $score / $total', 'Score: $score / $total');
  String get resultExcellent => _t('Luar biasa!', 'Excellent!');
  String get resultGood => _t('Bagus, terus berlatih!', 'Good, keep practicing!');
  String get sentenceExamplesTitle => _t('Contoh Kalimat', 'Sentence Examples');
  /// Generic "X segera hadir!" snackbar shared by Kotoba/Partikel/Kaiwa's
  /// category cards (Kanji/Bunpou use [kanjiLevelComingSoon] instead since
  /// theirs is phrased "Kanji X segera hadir!" with a module prefix).
  String categoryComingSoon(String name) =>
      _t('$name segera hadir!', '$name coming soon!');

  // --- Kanji module ---
  String failedToLoadLevels(Object e) =>
      _t('Gagal memuat level: $e', 'Failed to load levels: $e');
  String kanjiLevelComingSoon(String levelName) =>
      _t('Kanji $levelName segera hadir!', 'Kanji $levelName coming soon!');
  String kanjiLevelLockedReason(String previousLevelKey) => _t(
        'Pelajari semua kanji $previousLevelKey dulu untuk membuka level ini.',
        'Learn every $previousLevelKey kanji first to unlock this level.',
      );
  String kanjiLevelCardTitle(String levelName) => 'Kanji $levelName';
  String kanjiCount(int n) => _t('$n kanji', '$n kanji');
  String kanjiLevelAppBarTitle(String levelName) => 'Kanji $levelName';
  String failedToLoadKanji(Object e) =>
      _t('Gagal memuat kanji: $e', 'Failed to load kanji: $e');
  String get noKanjiForLevel =>
      _t('Kanji untuk level ini belum tersedia.', 'No kanji available for this level yet.');
  String get noKanjiMatchesFilter => _t(
        'Tidak ada kanji yang cocok dengan filter.',
        'No kanji match this filter.',
      );
  String get sortTooltip => _t('Urutkan', 'Sort');
  String get sortDefault => _t('Urutan Dasar', 'Default Order');
  String get sortByStrokeCount => _t('Jumlah Goresan', 'Stroke Count');
  String get chooseQuizMode => _t('Pilih Mode Kuis', 'Choose Quiz Mode');
  String get kanjiToMeaningTitle => _t('Kanji → Arti', 'Kanji → Meaning');
  String get kanjiToMeaningSubtitle =>
      _t('Lihat kanji, pilih artinya', 'See the kanji, pick its meaning');
  String get meaningToKanjiTitle => _t('Arti → Kanji', 'Meaning → Kanji');
  String get meaningToKanjiSubtitle =>
      _t('Lihat artinya, pilih kanjinya', 'See the meaning, pick the kanji');
  String strokeCountPill(int n) => _t('$n goresan', '$n strokes');
  String radicalPill(String radical) => _t('Radikal $radical', 'Radical $radical');
  String get meaningSectionTitle => _t('Arti', 'Meaning');
  String get relatedBunpouTitle => _t('Bunpou Terkait', 'Related Bunpou');
  String get wordExamplesTitle => _t('Contoh Kata', 'Word Examples');
  String kanjiQuizTitle(String levelName) =>
      _t('Kuis · Kanji $levelName', 'Quiz · Kanji $levelName');
  String get whatIsKanjiMeaning => _t('Apa arti kanji ini?', "What does this kanji mean?");
  String get whichKanjiMeans =>
      _t('Kanji mana yang berarti ini?', 'Which kanji means this?');
  String get reviewKanjiAgain =>
      _t('Yuk, pelajari lagi kanjinya!', "Let's review the kanji again!");

  // --- Kotoba module ---
  String failedToLoadCategories(Object e) =>
      _t('Gagal memuat kategori: $e', 'Failed to load categories: $e');
  String wordCount(int n) => _t('$n kata', '$n words');
  String failedToLoadWords(Object e) =>
      _t('Gagal memuat kata: $e', 'Failed to load words: $e');
  String get noWordsForCategory => _t(
        'Kata untuk kategori ini belum tersedia.',
        'No words available for this category yet.',
      );
  String kotobaQuizTitle(String categoryName) =>
      _t('Kuis · $categoryName', 'Quiz · $categoryName');
  String get whatIsWordMeaning => _t('Apa arti kata ini?', 'What does this word mean?');
  String get reviewWordsAgain =>
      _t('Yuk, pelajari lagi kata-katanya!', "Let's review the words again!");

  // --- Bunpou module ---
  String bunpouLevelComingSoon(String levelName) =>
      _t('Bunpou $levelName segera hadir!', 'Bunpou $levelName coming soon!');
  String bunpouLevelTitle(String levelName) => 'Bunpou $levelName';
  String bunpouPatternCount(int n) => _t('$n pola', '$n patterns');
  String failedToLoadBunpou(Object e) =>
      _t('Gagal memuat pola: $e', 'Failed to load grammar patterns: $e');
  String get noBunpouForLevel => _t(
        'Pola tata bahasa untuk level ini belum tersedia.',
        'No grammar patterns available for this level yet.',
      );
  String get noBunpouMatchesFilter => _t(
        'Tidak ada pola yang cocok dengan filter.',
        'No patterns match this filter.',
      );
  String bunpouQuizTitle(String levelName) =>
      _t('Kuis · Bunpou $levelName', 'Quiz · Bunpou $levelName');
  String get whatIsPatternMeaning =>
      _t('Apa arti pola ini?', 'What does this pattern mean?');
  String get whichPatternMeans =>
      _t('Pola mana yang berarti ini?', 'Which pattern means this?');
  String get reviewPatternsAgain =>
      _t('Yuk, pelajari lagi polanya!', "Let's review the patterns again!");
  String get patternToMeaningTitle => _t('Pola → Arti', 'Pattern → Meaning');
  String get patternToMeaningSubtitle =>
      _t('Lihat pola, pilih artinya', 'See the pattern, pick its meaning');
  String get meaningToPatternTitle => _t('Arti → Pola', 'Meaning → Pattern');
  String get meaningToPatternSubtitle =>
      _t('Lihat artinya, pilih polanya', 'See the meaning, pick the pattern');
  String get formationSectionTitle => _t('Pembentukan', 'Formation');
  String get usageNotesSectionTitle => _t('Catatan Pemakaian', 'Usage Notes');
  String get similarPatternsTitle => _t('Pola Serupa', 'Similar Patterns');

  // --- Partikel module ---
  String particleCount(int n) => _t('$n partikel', '$n particles');
  String failedToLoadParticles(Object e) =>
      _t('Gagal memuat partikel: $e', 'Failed to load particles: $e');
  String get noParticlesForCategory => _t(
        'Partikel untuk kategori ini belum tersedia.',
        'No particles available for this category yet.',
      );
  String get noParticlesMatchFilter => _t(
        'Tidak ada partikel yang cocok dengan filter.',
        'No particles match this filter.',
      );
  // No "Partikel"/"Particle" of its own: every category is already named
  // "Partikel Kasus" / "Case Particles", so adding the word here produced
  // "Kuis · Partikel Partikel Kasus" on screen — and, differently but just
  // as wrongly, "Quiz · Particle Case Particles" in English.
  String particleQuizTitle(String categoryName) =>
      _t('Kuis · $categoryName', 'Quiz · $categoryName');
  String get whichParticleFits => _t(
        'Partikel mana yang tepat untuk mengisi kalimat ini?',
        'Which particle correctly fills this sentence?',
      );
  String get reviewParticlesAgain => _t(
        'Yuk, pelajari lagi partikelnya!',
        "Let's review the particles again!",
      );
  String get summarySectionTitle => _t('Ringkasan', 'Summary');
  String get similarParticlesTitle => _t('Partikel Serupa', 'Similar Particles');
  String get functionsSectionTitle => _t('Fungsi', 'Functions');

  // --- Kaiwa module ---
  String kaiwaLevelComingSoon(String levelName) =>
      _t('Kaiwa $levelName segera hadir!', 'Kaiwa $levelName coming soon!');
  String kaiwaLevelLockedReason(String previousLevelKey) => _t(
        'Pelajari semua dialog $previousLevelKey dulu untuk membuka level ini.',
        'Learn every $previousLevelKey dialogue first to unlock this level.',
      );
  String kaiwaLevelTitle(String levelName) => 'Kaiwa $levelName';
  String themeCount(int n) => _t('$n tema', '$n themes');
  String failedToLoadThemes(Object e) =>
      _t('Gagal memuat tema: $e', 'Failed to load themes: $e');
  String get noThemesForLevel => _t(
        'Tema untuk level ini belum tersedia.',
        'No themes available for this level yet.',
      );
  String dialogueCount(int n) => _t('$n dialog', '$n dialogues');
  String failedToLoadDialogues(Object e) =>
      _t('Gagal memuat dialog: $e', 'Failed to load dialogues: $e');
  String get noDialoguesForCategory => _t(
        'Dialog untuk kategori ini belum tersedia.',
        'No dialogues available for this category yet.',
      );
  String get noDialoguesMatchFilter => _t(
        'Tidak ada dialog yang cocok dengan filter.',
        'No dialogues match this filter.',
      );
  String get yourTurnPickAnswer => _t(
        'Giliranmu — pilih jawaban di bawah',
        'Your turn — pick the answer below',
      );
  String get pickCorrectAnswer =>
      _t('Pilih jawaban yang tepat:', 'Pick the correct answer:');

  // --- Shared: dictionary/detail screens (Search, Cam Detector) ---
  String get saveToLearningListFailed => _t(
        'Gagal menyimpan ke daftar belajar. Coba lagi.',
        'Could not save to your learning list. Please try again.',
      );
  String get savedToLearningList =>
      _t('Tersimpan ke Daftar Belajar!', 'Saved to Learning List!');
  String get saveToLearningList =>
      _t('Simpan ke Daftar Belajar', 'Save to Learning List');
  String get viewFullDetail => _t('Lihat Detail Lengkap', 'View Full Detail');
  String get done => _t('Selesai', 'Done');
  String get leave => _t('Keluar', 'Leave');

  // --- Search ---
  String get searchHint =>
      _t('Cari kanji, hiragana, romaji, atau arti...', 'Search kanji, hiragana, romaji, or meaning...');
  String get searchHintMessage => _t(
        'Ketik kanji, hiragana, romaji, atau arti untuk mencari',
        'Type kanji, hiragana, romaji, or meaning to search',
      );
  String get searchNoResults =>
      _t('Tidak ditemukan. Coba kata kunci lain.', 'No results found. Try a different keyword.');
  String get dictionaryTag => _t('Kamus', 'Dictionary');

  // --- Leaderboard ---
  String get leaderboardTitle => _t('Papan Peringkat', 'Leaderboard');
  String get tabGlobalScore => _t('Skor Global', 'Global Score');
  String get tabCardGameStars => _t('Bintang', 'Stars');
  String get tabClan => _t('Clan', 'Clan');

  /// Short labels for the four Rekor categories that make up the global
  /// score — rendered as a compact breakdown line under each ranked name,
  /// so the total is visibly "these four added up" rather than an opaque
  /// number. Deliberately terser than the old tab labels ("Rekor Kana"),
  /// which had a whole tab's width to breathe in.
  String get scorePartKana => _t('Kana', 'Kana');
  String get scorePartDokkai => _t('Dokkai', 'Dokkai');
  String get scorePartChoukai => _t('Choukai', 'Choukai');
  String get scorePartKanjiCombo => _t('Kanji', 'Kanji');

  String globalScorePoints(String points) => _t('$points poin', '$points pts');
  String get globalScoreExplainer => _t(
        'Skor Global = Rekor Kana + Dokkai + Choukai + Kanji-Kombinasi',
        'Global Score = Kana + Dokkai + Choukai + Kanji Combo records',
      );
  String get noRankingData => _t('Belum ada data peringkat.', 'No ranking data yet.');

  // --- Public profile (tapping a ranked row) ---
  String get publicProfileTitle => _t('Profil', 'Profile');
  String get curriculumProgressTitle => _t('Progres Kurikulum', 'Curriculum Progress');
  String babProgressOf(int done, int total) =>
      _t('$done dari $total bab selesai', '$done of $total chapters done');
  String babFurthestChapter(String title) =>
      _t('Terakhir: $title', 'Furthest: $title');
  String get babNotStartedYet =>
      _t('Belum mulai kurikulum.', "Hasn't started the curriculum yet.");
  String get scoreBreakdownTitle => _t('Rincian Skor', 'Score Breakdown');
  String failedToLoadLeaderboard(Object e) =>
      _t('Gagal memuat papan peringkat: $e', 'Failed to load leaderboard: $e');
  String rankOf(int rank) => _t('Peringkat ke-$rank', 'Rank #$rank');
  String get notRankedYet => _t('Belum berperingkat', 'Not ranked yet');
  String get noRecordYet => _t('Belum ada', 'No record yet');

  // --- Clan (Leaderboard tab 2) ---
  String failedToLoadClan(Object e) =>
      _t('Gagal memuat clan: $e', 'Failed to load clan: $e');
  String get createClan => _t('Buat Clan', 'Create Clan');
  String get joinWithCode => _t('Gabung dengan Kode', 'Join with Code');
  String get noClanYetTitle => _t('Belum punya clan', "You don't have a clan yet");
  String get noClanYetBody => _t(
        'Buat clan untuk sekolah/kelasmu, atau gabung dengan kode dari guru/temanmu.',
        'Create a clan for your school/class, or join with a code from your teacher/friend.',
      );
  String codeAndMembers(String code, int count) =>
      _t('Kode: $code · $count anggota', 'Code: $code · $count members');
  String get copyCode => _t('Salin Kode', 'Copy Code');
  String get codeCopied => _t('Kode disalin.', 'Code copied.');
  String get leaveClanTooltip => _t('Keluar dari Clan', 'Leave Clan');
  String get noMembersYet => _t('Belum ada anggota.', 'No members yet.');
  String failedToLoadMembers(Object e) =>
      _t('Gagal memuat anggota: $e', 'Failed to load members: $e');
  String get leaveClanConfirmTitle => _t('Keluar dari Clan?', 'Leave clan?');
  String leaveClanConfirmBody(String name) => _t(
        'Kamu akan keluar dari "$name". Kamu bisa gabung lagi nanti dengan kode yang sama.',
        'You will leave "$name". You can rejoin later with the same code.',
      );
  String get leaveClanFailed => _t(
        'Gagal keluar dari clan, coba lagi.',
        'Failed to leave the clan, try again.',
      );
  String get clanCreatedTitle => _t('Clan Dibuat!', 'Clan Created!');
  String get shareCodeMessage => _t(
        'Bagikan kode ini ke murid supaya bisa bergabung:',
        'Share this code with students so they can join:',
      );
  String get clanNameHint =>
      _t('Nama clan (mis. SMA 1 Kelas 9A)', 'Clan name (e.g. Class 9A)');
  String get createClanFailed =>
      _t('Gagal membuat clan, coba lagi.', 'Failed to create clan, try again.');
  String get createButton => _t('Buat', 'Create');
  String get clanExtraPremiumTitle => _t('Clan Tambahan', 'Extra Clan');
  String get clanCreationLimitTitle =>
      _t('Jatah Gratis Sudah Terpakai', "You've Used Your Free Clan");
  String get clanCreationLimitBody => _t(
        'Setiap akun hanya bisa membuat 1 clan gratis. Upgrade premium atau tonton iklan untuk membuat clan tambahan.',
        "Every account gets 1 free clan. Upgrade to premium or watch an ad to create another one.",
      );
  String get clanCreationLimitButton => _t('Buka Penawaran', 'View Offer');
  String get clanCodeHint => _t('Kode clan', 'Clan code');
  String get codeNotFound => _t('Kode tidak ditemukan.', 'Code not found.');
  String get joinClanFailed =>
      _t('Gagal bergabung, coba lagi.', 'Failed to join, try again.');
  String get joinButton => _t('Gabung', 'Join');

  // --- Clan roles / kick / invite ---
  String get roleLeader => _t('Leader', 'Leader');
  String get roleCoLeader => _t('Co-Leader', 'Co-Leader');
  String get manageMembers => _t('Kelola Anggota', 'Manage Members');
  String get promoteToCoLeader =>
      _t('Jadikan Co-Leader', 'Promote to Co-Leader');
  String get demoteToMember => _t('Turunkan ke Anggota', 'Demote to Member');
  String get roleChangeFailed => _t(
        'Gagal mengubah peran, coba lagi.',
        'Failed to change role, try again.',
      );
  String get kickMember => _t('Tendang', 'Kick');
  String kickConfirmTitle(String name) =>
      _t('Tendang $name?', 'Kick $name?');
  String get kickConfirmBody => _t(
        'Anggota ini akan dikeluarkan dari clan dan perlu kode gabung lagi untuk kembali.',
        'This member will be removed from the clan and needs the join code again to come back.',
      );
  String get kickFailed =>
      _t('Gagal menendang anggota, coba lagi.', 'Failed to kick member, try again.');
  String get inviteMember => _t('Cari & Undang', 'Search & Invite');
  String get searchUserHint =>
      _t('Cari nama learner...', "Search a learner's name...");
  String get searchUserEmpty => _t(
        'Ketik nama untuk mencari learner.',
        "Type a name to search for a learner.",
      );
  String get searchUserNoResults =>
      _t('Tidak ada learner ditemukan.', 'No learner found.');
  String get inviteButton => _t('Undang', 'Invite');
  String get inviteSent => _t('Undangan terkirim.', 'Invite sent.');
  String get inviteSendFailed => _t(
        'Gagal mengirim undangan, coba lagi.',
        'Failed to send invite, try again.',
      );
  String get alreadyMemberError =>
      _t('Learner ini sudah ada di dalam clan.', 'This learner is already in the clan.');
  String pendingInvitesTitle(int count) => _t(
        'Kamu punya $count undangan clan',
        'You have $count clan invite${count == 1 ? '' : 's'}',
      );
  String invitedToClan(String clanName, String hostName) => _t(
        'Diundang ke "$clanName" oleh $hostName',
        'Invited to "$clanName" by $hostName',
      );
  String get acceptInvite => _t('Terima', 'Accept');
  String get declineInvite => _t('Tolak', 'Decline');
  String get inviteRespondFailed => _t(
        'Gagal merespons undangan, coba lagi.',
        'Failed to respond to invite, try again.',
      );
  String get tabTopClan => _t('Top Clan', 'Top Clan');
  String get noTopClansYet =>
      _t('Belum ada clan dengan skor.', 'No clans with a score yet.');
  String failedToLoadTopClans(Object e) =>
      _t('Gagal memuat top clan: $e', 'Failed to load top clans: $e');
  String topClanMembers(int count) =>
      _t('$count anggota', '$count members');
  String topClanScorePoints(String score) =>
      _t('$score poin', '$score points');

  // --- Clan chat ---
  String get clanChat => _t('Chat Clan', 'Clan Chat');
  String get clanChatEmpty => _t(
        'Belum ada pesan. Mulai obrolan clan-mu!',
        'No messages yet. Start your clan chat!',
      );
  String get messageHint => _t('Tulis pesan...', 'Write a message...');
  String get messageTooLong => _t(
        'Pesan terlalu panjang (maks 300 karakter).',
        'Message too long (max 300 characters).',
      );
  String get messageSendFailed => _t(
        'Gagal mengirim pesan, coba lagi.',
        'Failed to send message, try again.',
      );
  String get messageSendTooFast => _t(
        'Tunggu sebentar sebelum kirim pesan lagi.',
        'Wait a moment before sending another message.',
      );
  String get blockUser => _t('Blokir', 'Block');
  String get unblockUser => _t('Buka Blokir', 'Unblock');
  String blockConfirmTitle(String name) =>
      _t('Blokir $name?', 'Block $name?');
  String get blockConfirmBody => _t(
        'Pesan dari orang ini tidak akan lagi muncul di chat-mu. Ini tidak menendangnya dari clan.',
        "This person's messages will stop appearing in your chat. It does not remove them from the clan.",
      );
  String get blockActionFailed => _t(
        'Gagal memproses, coba lagi.',
        'Failed to process, try again.',
      );
  String get reportMessage => _t('Laporkan', 'Report');
  String get reportMessageTitle =>
      _t('Laporkan Pesan', 'Report Message');
  String get reportMessageHint => _t(
        'Ceritakan kenapa pesan ini dilaporkan...',
        'Tell us why this message is being reported...',
      );
  String get reportMessageSubmit => _t('Kirim Laporan', 'Submit Report');
  String get reportMessageSent =>
      _t('Laporan terkirim. Terima kasih.', 'Report sent. Thank you.');
  String get reportMessageFailed => _t(
        'Gagal mengirim laporan, coba lagi.',
        'Failed to send report, try again.',
      );
  String get blockedMessagePlaceholder =>
      _t('Pesan disembunyikan (diblokir)', 'Message hidden (blocked)');

  // --- Clan settings (icon/description) — leader only ---
  String get clanSettings => _t('Pengaturan Clan', 'Clan Settings');
  String get clanIconSectionTitle => _t('Ikon Clan', 'Clan Icon');
  // Bubarkan clan (leader-only). Sengaja pakai kata "bubarkan", bukan
  // "hapus" — yang hilang adalah clan-nya sebagai kelompok, bukan
  // progres belajar anggotanya, dan "hapus" gampang dibaca lebih ngeri
  // daripada yang sebenarnya terjadi.
  String get clanDisbandSectionTitle => _t('Bubarkan Clan', 'Disband Clan');
  String get clanDisbandExplanation => _t(
        'Semua anggota dikeluarkan dan clan ini hilang dari daftar semua '
            'orang. Progres belajar tiap anggota tidak terpengaruh sama '
            'sekali. Jatah clan gratismu tidak kembali, dan riwayat chat '
            'clan tidak bisa dibuka lagi.',
        'Every member is removed and this clan disappears from every '
            'list. No learning progress is affected for anyone. Your free '
            'clan slot is not returned, and the clan chat history can no '
            'longer be opened.',
      );
  String get clanDisbandButton => _t('Bubarkan Clan', 'Disband Clan');
  String clanDisbandConfirmTitle(String clanName) =>
      _t('Bubarkan "$clanName"?', 'Disband "$clanName"?');
  String clanDisbandConfirmBody(int memberCount) => _t(
        'Tindakan ini permanen. $memberCount anggota akan dikeluarkan, dan '
            'clan ini tidak bisa dikembalikan.',
        'This cannot be undone. $memberCount members will be removed, and '
            'this clan cannot be restored.',
      );
  String get clanDisbandConfirmAction => _t('Bubarkan', 'Disband');
  String get clanDisbanded => _t('Clan dibubarkan.', 'Clan disbanded.');
  String get clanDisbandFailed => _t(
        'Gagal membubarkan clan, coba lagi.',
        'Could not disband the clan, try again.',
      );
  String get clanDescriptionSectionTitle =>
      _t('Deskripsi Clan', 'Clan Description');
  String get clanDescriptionHint => _t(
        'Ceritakan tentang clan ini (opsional)...',
        'Tell members about this clan (optional)...',
      );
  String get clanDescriptionEmpty =>
      _t('Belum ada deskripsi.', 'No description yet.');
  String get clanIconSaved => _t('Ikon clan disimpan.', 'Clan icon saved.');
  String get clanIconSaveFailed => _t(
        'Gagal menyimpan ikon clan, coba lagi.',
        'Failed to save clan icon, try again.',
      );
  String get clanDescriptionSaved =>
      _t('Deskripsi clan disimpan.', 'Clan description saved.');
  String get clanDescriptionSaveFailed => _t(
        'Gagal menyimpan deskripsi clan, coba lagi.',
        'Failed to save clan description, try again.',
      );
  String get leaderOnlySectionNote => _t(
        'Hanya leader clan yang bisa mengubah ini.',
        'Only the clan leader can change this.',
      );

  // --- Clan announcements ---
  String get clanAnnouncements => _t('Pengumuman Clan', 'Clan Announcements');
  String get clanAnnouncementsEmpty => _t(
        'Belum ada pengumuman dari leader.',
        'No announcements from the leader yet.',
      );
  String get composeAnnouncement =>
      _t('Buat Pengumuman', 'Compose Announcement');
  String get announcementHint => _t(
        'Tulis pengumuman untuk semua anggota...',
        'Write an announcement for every member...',
      );
  String get postAnnouncementButton => _t('Kirim Pengumuman', 'Post Announcement');
  String get announcementTooLong => _t(
        'Pengumuman terlalu panjang (maks 500 karakter).',
        'Announcement too long (max 500 characters).',
      );
  String get announcementPosted => _t(
        'Pengumuman terkirim ke semua anggota.',
        'Announcement sent to every member.',
      );
  String get announcementSendFailed => _t(
        'Gagal mengirim pengumuman, coba lagi.',
        'Failed to send announcement, try again.',
      );
  String failedToLoadAnnouncements(Object e) => _t(
        'Gagal memuat pengumuman: $e',
        'Failed to load announcements: $e',
      );

  // --- Friends + Direct Message ---
  String failedToLoadFriends(Object e) =>
      _t('Gagal memuat daftar teman: $e', 'Failed to load friends: $e');
  String get removeFriend => _t('Hapus Teman', 'Remove Friend');
  String removeFriendConfirmTitle(String name) =>
      _t('Hapus $name dari teman?', 'Remove $name as a friend?');
  String removeFriendConfirmBody(String name) => _t(
        'Kamu dan $name tidak akan bisa saling mengirim pesan lagi sampai berteman ulang.',
        'You and $name will no longer be able to message each other until you become friends again.',
      );
  String get removeFriendFailed => _t(
        'Gagal menghapus teman, coba lagi.',
        'Failed to remove friend, try again.',
      );
  String get searchFriendTitle => _t('Cari Teman', 'Find Friend');
  String get searchFriendHint =>
      _t('Cari nama atau ID unik...', "Search a name or unique ID...");
  String get searchFriendEmpty => _t(
        'Ketik nama atau ID unik untuk mencari.',
        'Type a name or unique ID to search.',
      );
  String get sendFriendRequestButton => _t('Tambah', 'Add');
  String get friendRequestSent =>
      _t('Permintaan pertemanan terkirim.', 'Friend request sent.');
  String get friendRequestSendFailed => _t(
        'Gagal mengirim permintaan, coba lagi.',
        'Failed to send request, try again.',
      );
  String get alreadyFriendError =>
      _t('Kalian sudah berteman.', "You're already friends.");
  String pendingFriendRequestsTitle(int count) => _t(
        'Kamu punya $count permintaan pertemanan',
        'You have $count friend request${count == 1 ? '' : 's'}',
      );
  String friendRequestFrom(String name) =>
      _t('Permintaan pertemanan dari $name', 'Friend request from $name');
  String get friendRequestSubtitle =>
      _t('Ingin berteman denganmu', 'Wants to be your friend');
  String get acceptFriendRequest => _t('Terima', 'Accept');
  String get declineFriendRequest => _t('Tolak', 'Decline');
  String get friendRequestRespondFailed => _t(
        'Gagal merespons permintaan, coba lagi.',
        'Failed to respond to the request, try again.',
      );

  // --- Add Friend menu (dedicated Profile app-bar icon) ---
  String get addFriendMenuTitle => _t('Tambah Teman', 'Add Friend');
  String get addFriendTabSearch => _t('Cari', 'Search');
  String get addFriendTabIncoming => _t('Permintaan', 'Requests');
  String get noIncomingRequestsTitle =>
      _t('Belum ada permintaan', 'No requests yet');
  String get noIncomingRequestsBody => _t(
        'Permintaan pertemanan yang masuk untukmu akan muncul di sini.',
        'Friend requests sent to you will show up here.',
      );

  // --- Chat menu (dedicated Profile app-bar icon) ---
  String get chatMenuTitle => 'Chat';
  String get chatModeClan => _t('Chat Clan', 'Clan Chat');
  String get chatModePersonal => _t('Chat Pribadi', 'Personal Chat');
  String get selectClanToChatHint => _t('Pilih clan...', 'Choose a clan...');
  String get selectFriendToChatHint =>
      _t('Pilih teman...', 'Choose a friend...');
  String get openChatButton => _t('Buka Chat', 'Open Chat');
  String get noClansForChatTitle =>
      _t('Belum punya clan', "You don't have a clan yet");
  String get noClansForChatBody => _t(
        'Buat atau gabung clan dulu lewat tab Clan di Papan Peringkat.',
        'Create or join a clan first from the Clan tab on the leaderboard.',
      );
  String get noFriendsForChatTitle =>
      _t('Belum punya teman', "You don't have any friends yet");
  String get noFriendsForChatBody => _t(
        'Tambahkan teman dulu lewat menu Tambah Teman untuk mulai chat pribadi.',
        'Add a friend first from the Add Friend menu to start a personal chat.',
      );
  String get directMessageEmpty => _t(
        'Belum ada pesan. Sapa temanmu duluan!',
        'No messages yet. Say hi to your friend first!',
      );

  // --- Notification feed (Profile > Notifikasi) ---
  String get notificationsEmptyTitle =>
      _t('Belum ada notifikasi', 'No notifications yet');
  String get notificationsEmptyBody => _t(
        'Pemberitahuan dari aplikasi akan muncul di sini.',
        'Notifications from the app will show up here.',
      );
  String failedToLoadNotifications(Object e) => _t(
        'Gagal memuat notifikasi: $e',
        'Failed to load notifications: $e',
      );
  String get markAllNotificationsRead =>
      _t('Tandai semua dibaca', 'Mark all as read');

  // --- Exam / Ujian ---
  String get kanaCategorySubtitle =>
      _t('Hiragana, Katakana, atau campuran', 'Hiragana, Katakana, or mixed');
  String get dokkaiCategorySubtitle =>
      _t('Pemahaman bacaan, N5-N1', 'Reading comprehension, N5-N1');
  String get choukaiCategorySubtitle =>
      _t('Pemahaman mendengar, N5-N1', 'Listening comprehension, N5-N1');
  String get kanjiComboCategorySubtitle =>
      _t('Kanji tunggal atau kombinasi kata', 'Single kanji or word combinations');
  String get kanjiComboMeaningPrompt =>
      _t('Apa artinya kanji ini?', "What does this kanji mean?");
  String get kanjiComboReadingPrompt =>
      _t('Bagaimana bacaan kanji ini?', 'How is this kanji read?');
  String get kanjiComboCompoundPrompt =>
      _t('Bagaimana bacaan kata ini?', 'How is this word read?');
  String get kanaExamTitle => _t('Ujian Kana', 'Kana Exam');
  String get examHiraganaTitle => _t('Ujian Hiragana', 'Hiragana Exam');
  String get examHiraganaSubtitle => _t(
        'Soal dari 104 karakter hiragana',
        'Questions from 104 hiragana characters',
      );
  String get examKatakanaTitle => _t('Ujian Katakana', 'Katakana Exam');
  String get examKatakanaSubtitle => _t(
        'Soal dari 104 karakter katakana',
        'Questions from 104 katakana characters',
      );
  String get examMixedTitle => _t('Ujian Campuran', 'Mixed Exam');
  String get examMixedSubtitle =>
      _t('Gabungan hiragana & katakana', 'Combination of hiragana & katakana');
  String get failedToSaveExamResult =>
      _t('Gagal menyimpan hasil ujian, coba lagi.', 'Failed to save exam result, try again.');
  String get noQuestionsAvailable => _t('Soal tidak tersedia', 'No questions available');
  String get whatIsThisCharacterReading =>
      _t('Apa bacaan dari huruf ini?', "What's the reading of this character?");
  String get xpRewardClaimFailed => _t(
        'Gagal mengambil hadiah. Coba lagi.',
        'Could not claim the reward. Please try again.',
      );
  String get searchFailed =>
      _t('Pencarian gagal. Coba lagi.', 'Search failed. Please try again.');
  String get checkAnswerButton => _t('Periksa Jawaban', 'Check Answer');
  String get nextQuestionButton => _t('Soal Berikutnya', 'Next Question');

  // What the loading screen names while each dataset is read. Short —
  // they flick past in well under a second each.
  String get preloadKana => _t('Menyiapkan huruf kana...', 'Loading kana...');
  String get preloadCurriculum =>
      _t('Menyusun kurikulum...', 'Loading the curriculum...');
  String get preloadParticles =>
      _t('Menyiapkan partikel...', 'Loading particles...');
  String get preloadDictionary =>
      _t('Membuka kamus...', 'Loading the dictionary...');
  String get preloadListening =>
      _t('Menyiapkan latihan mendengar...', 'Loading listening practice...');
  String get preloadReading =>
      _t('Menyiapkan bacaan...', 'Loading reading practice...');
  String get preloadGrammar =>
      _t('Menyiapkan tata bahasa...', 'Loading grammar...');
  String get preloadKanji => _t('Memuat kanji...', 'Loading kanji...');
  String get preloadConversation =>
      _t('Menyiapkan percakapan...', 'Loading conversations...');

  String get loadingPreparing =>
      _t('Menyiapkan pelajaranmu...', 'Getting your lessons ready...');

  // --- First-run tutorial -------------------------------------------------
  // The mascot speaking, in first person, to a child who has just opened
  // the app and knows nothing about it. Each line names one real part of
  // the app and says what it is for — no marketing, no jargon.
  String get tutorialGreeting => _t(
        'Halo! Aku akan menemanimu belajar bahasa Jepang di sini.',
        "Hello! I'll be learning Japanese with you here.",
      );
  String get tutorialKana => _t(
        'Kita mulai dari Hiragana dan Katakana — huruf dasar Jepang. '
            'Kamu bisa belajar dan latihan menulisnya.',
        'We start with Hiragana and Katakana — the basic Japanese letters. '
            'You can learn them and practise writing them.',
      );
  String get tutorialCurriculum => _t(
        'Di Kurikulum ada bab-bab berurutan. Selesaikan kuis di akhir bab '
            'untuk membuka bab berikutnya.',
        'The Curriculum has chapters in order. Finish the quiz at the end '
            'of a chapter to open the next one.',
      );
  String get tutorialKanji => _t(
        'Di Kanji kamu bisa lihat urutan goresan tiap huruf, dan di '
            'Kosakata ada ribuan kata dengan contoh kalimat.',
        'In Kanji you can watch each character being drawn stroke by '
            'stroke, and Vocabulary has thousands of words with examples.',
      );
  String get tutorialPractice => _t(
        'Ada juga latihan percakapan, mendengar, dan membaca. Kalau mau '
            'diuji, buka tab Ujian di bawah.',
        'There is speaking, listening and reading practice too. For a real '
            'test, open the Exam tab below.',
      );
  String get tutorialReady => _t(
        'Kalau ada yang salah, tidak apa-apa — aku akan bantu. Siap mulai?',
        "If you get something wrong, that's fine — I'll help. Ready?",
      );
  String get tutorialSkip => _t('Lewati', 'Skip');
  String get tutorialNext => _t('Lanjut', 'Next');
  String get tutorialStart => _t('Mulai Belajar', 'Start Learning');
  String get tutorialReplay => _t('Lihat Tutorial Lagi', 'Watch Tutorial Again');

  // --- Mascot coach -------------------------------------------------------
  // What the mascot says while a learner works through a lesson. Written
  // for children: short, warm, and — for the wrong-answer lines — never
  // scolding. Each moment has several so ten questions do not carry the
  // same sentence ten times; see `MascotCoach` for the picking rule.
  String get coachCorrect1 => _t('Benar! Lanjut ya.', 'Correct! Keep going.');
  String get coachCorrect2 => _t('Tepat sekali!', 'Spot on!');
  String get coachCorrect3 => _t('Kamu paham ini.', 'You know this one.');
  String get coachCorrect4 => _t('Bagus, terus begitu.', 'Nice, just like that.');

  String coachStreak1(int run) =>
      _t('$run benar berturut-turut!', '$run right in a row!');
  String coachStreak2(int run) =>
      _t('Wah, $run kali benar. Keren!', 'Wow, $run correct. Amazing!');
  String coachStreak3(int run) =>
      _t('Lancar banget, $run berturut-turut!', 'On a roll — $run straight!');

  // The right answer is named in every one of these: it is the one piece
  // of teaching that is honest for any question, since a real explanation
  // would have to be written per question rather than guessed here.
  String coachWrong1(String answer) =>
      _t('Belum tepat. Jawabannya $answer.', 'Not quite. The answer is $answer.');
  String coachWrong2(String answer) =>
      _t('Hampir! Yang benar $answer.', 'So close! It is $answer.');
  String coachWrong3(String answer) =>
      _t('Tidak apa-apa, ini $answer. Ingat ya!',
          'That is okay — it is $answer. Remember it!');
  String coachWrong4(String answer) =>
      _t('Kita catat: $answer. Coba lagi nanti.',
          'Let us note it: $answer. Try again later.');

  String coachFinishedStrong1(int score, int total) =>
      _t('Selesai! $score dari $total benar. Hebat!',
          'Done! $score of $total correct. Excellent!');
  String coachFinishedStrong2(int score, int total) =>
      _t('$score dari $total. Aku bangga sama kamu!',
          '$score out of $total. I am proud of you!');
  String coachPerfect1(int total) => _t(
      'Sempurna! $total dari $total benar!', 'Perfect! $total out of $total!');
  String coachPerfect2(int total) => _t('Tidak ada yang salah sama sekali!',
      'Not a single one missed!');
  String coachFinishedWeak1(int score, int total) =>
      _t('Selesai! $score dari $total. Ayo coba lagi, pasti bisa.',
          'Done! $score of $total. Try again — you will get there.');
  String coachFinishedWeak2(int score, int total) =>
      _t('$score dari $total. Belajar lagi sebentar, yuk!',
          '$score out of $total. Let us go over it once more!');
  String failedToLoadQuestions(Object e) =>
      _t('Gagal memuat soal: $e', 'Failed to load questions: $e');
  String get examResultTitleGreat => _t('Hebat! Ujian Selesai 🎉', 'Great! Exam Complete 🎉');
  String get examResultTitleGood => _t('Bagus! Terus Berlatih 👍', 'Good! Keep Practicing 👍');
  String get examResultTitleTryAgain =>
      _t('Jangan Menyerah, Ayo Coba Lagi! 💪', "Don't Give Up, Try Again! 💪");
  String get simpleExamResultGreat => _t('Hebat! 🎉', 'Great! 🎉');
  String get simpleExamResultGood => _t('Bagus, terus berlatih! 👍', 'Good, keep practicing! 👍');
  String get simpleExamResultTryAgain =>
      _t('Jangan menyerah, coba lagi! 💪', "Don't give up, try again! 💪");
  String get correctLabel => _t('Benar', 'Correct');
  String get wrongLabel => _t('Salah', 'Wrong');
  String get retryExamButton => _t('Ulangi Ujian', 'Retry Exam');
  String get backToMenuButton => _t('Kembali ke Menu', 'Back to Menu');

  // --- Quiz/exam wrong-answer review ---
  String get reviewMistakesButton => _t('Lihat Kesalahan', 'Review Mistakes');
  String get reviewMistakesTitle => _t('Riwayat Kesalahan', 'Mistake Review');
  String get yourAnswerLabel => _t('Jawaban Anda', 'Your answer');
  String get correctAnswerLabel => _t('Jawaban benar', 'Correct answer');
  String reviewMistakesCount(int count) => _t(
        '$count soal yang salah',
        '$count question${count == 1 ? '' : 's'} answered wrong',
      );

  // --- Saved Words / About / Notification / Exam History ---
  String get noSavedWordsMessage => _t(
        'Belum ada kata tersimpan. Simpan kata lewat ikon bookmark di '
            'halaman Kanji/Kotoba (dari Pencarian) untuk melihatnya di sini. '
            '(Simpan dari Cam Detector belum bisa dipakai — Cam Detector '
            'sedang dalam perbaikan.)',
        'No saved words yet. Save a word via the bookmark icon on a '
            'Kanji/Kotoba page (from Search) to see it here. (Saving from '
            "Cam Detector isn't available yet — Cam Detector is currently "
            'under repair.)',
      );
  String get deleteWordConfirmTitle => _t('Hapus kata ini?', 'Delete this word?');
  String get deleteWordConfirmBody =>
      _t('Kata yang dihapus tidak bisa dikembalikan.', 'A deleted word cannot be recovered.');
  String appVersionLabel(String version) => _t('Versi $version', 'Version $version');
  String get aboutSectionTitle => _t('Tentang', 'About');
  String get aboutSectionBody => _t(
        'Teisou adalah teman belajar bahasa Jepang — dimulai dari '
            'Hiragana dan Katakana, menuju Kanji, Partikel, dan Tata '
            'Bahasa. Belajar Kana, langkah pertama menuju Jepang!',
        'Teisou is your Japanese-learning companion — starting from '
            'Hiragana and Katakana, on to Kanji, Particles, and Grammar. '
            "Learn Kana, your first step towards Japan!",
      );
  String get creditsSectionTitle => _t('Kredit', 'Credits');
  String get creditsSectionBody => _t(
        'Ilustrasi urutan goresan karakter menggunakan data dari '
            'proyek KanjiVG (© Ulrich Apel), dilisensikan di bawah '
            'Creative Commons Attribution-Share Alike 3.0.',
        'Character stroke-order illustrations use data from the '
            'KanjiVG project (© Ulrich Apel), licensed under '
            'Creative Commons Attribution-Share Alike 3.0.',
      );
  String get examHistoryPlaceholderMessage => _t(
        'Daftar lengkap riwayat ujianmu akan tersedia di sini.',
        'Your full exam history list will be available here.',
      );

  // --- Paywall ---
  String get storeUnavailable =>
      _t('Toko aplikasi tidak tersedia di perangkat ini.', 'The app store is not available on this device.');
  String purchaseComingSoon(String sku) => _t(
        'Pembelian Premium akan segera tersedia setelah paket "$sku" terdaftar di Play Console.',
        'Premium purchase will be available soon once the "$sku" product is registered in Play Console.',
      );
  String get previewUnlockFailed =>
      _t('Gagal membuka preview, coba lagi.', 'Failed to unlock preview, try again.');
  String previewUnlockedFor(String moduleTitle) => _t(
        '$moduleTitle terbuka untuk preview 24 jam!',
        '$moduleTitle unlocked for a 24-hour preview!',
      );
  String get adNotReadyYet =>
      _t('Iklan belum tersedia, coba lagi sebentar lagi.', 'Ad not ready yet, try again in a moment.');
  String get adClosedEarly =>
      _t('Iklan ditutup sebelum selesai.', 'Ad was closed before finishing.');
  String get unlockAllModulesTitle => _t('Buka Semua Modul!', 'Unlock All Modules!');
  String get unlockAllModulesSubtitle => _t(
        'Akses penuh Kanji, Partikel, Bunpou, dan lebih banyak lagi',
        'Full access to Kanji, Partikel, Bunpou, and more',
      );
  String get upgradePremiumButton =>
      _t('Upgrade Premium — Rp 29.000/bulan', 'Upgrade to Premium — Rp 29,000/month');
  String get orLabel => _t('atau', 'or');
  String get watchAdForPreviewButton =>
      _t('Nonton Iklan untuk Preview 24 Jam', 'Watch Ad for 24-Hour Preview');
  String get watchAdForSingleChangeButton =>
      _t('Nonton Iklan untuk Ganti Foto (1x)', 'Watch Ad to Change Photo (1x)');
  String previewUnlockedSingleUse(String moduleTitle) => _t(
        '$moduleTitle terbuka — berlaku untuk 1x ganti foto.',
        '$moduleTitle unlocked — good for one photo change.',
      );
  String get benefitAllModules => _t('Akses semua modul belajar', 'Access to all learning modules');
  String get benefitNoAds => _t('Tanpa iklan', 'No ads');
  String get benefitCloudProgress => _t('Progress tersimpan cloud', 'Cloud-saved progress');
  String get benefitExclusiveLeaderboard => _t('Leaderboard eksklusif', 'Exclusive leaderboard');

  // --- Cam Detector ---
  String get preparingCamera => _t('Menyiapkan kamera...', 'Preparing camera...');
  String get cameraPermissionNeeded => _t(
        'Izin kamera dibutuhkan untuk memindai karakter Jepang. '
            'Aplikasi tidak akan mengirim gambar kamu kemana pun.',
        'Camera permission is needed to scan Japanese characters. '
            'The app will never send your images anywhere.',
      );
  String get allowCameraButton => _t('Izinkan Kamera', 'Allow Camera');
  String get cameraPermissionDeniedPermanently => _t(
        'Izin kamera ditolak permanen. Buka Pengaturan untuk '
            'mengaktifkannya secara manual.',
        'Camera permission permanently denied. Open Settings to '
            'enable it manually.',
      );
  String get openSettingsButton => _t('Buka Pengaturan', 'Open Settings');
  String get noCameraAvailable =>
      _t('Tidak ada kamera yang tersedia di perangkat ini.', 'No camera available on this device.');
  String get genericError => _t('Terjadi kesalahan.', 'Something went wrong.');
  String get tryAgainButton => _t('Coba Lagi', 'Try Again');
  String get cameraOpenFailed => _t('Gagal membuka kamera. Coba lagi.', 'Failed to open camera. Try again.');
  String get recognitionModelNotReady => _t(
        'Model pengenalan teks belum siap. Pastikan koneksi '
            'internet aktif untuk pemakaian pertama, lalu coba lagi.',
        'Text recognition model is not ready yet. Make sure your '
            'internet connection is active for first-time use, then try again.',
      );
  String get toggleFlashTooltip => _t('Nyala/Matikan Flash', 'Toggle Flash');
  String get switchCameraTooltip => _t('Ganti Kamera', 'Switch Camera');
  String get resumeDetectionTooltip => _t('Lanjutkan Deteksi', 'Resume Detection');
  String get pauseDetectionTooltip => _t('Jeda Deteksi', 'Pause Detection');
  String get meaningNotAvailable => _t('Arti belum tersedia', 'Meaning not available yet');
  String get registerUsageTitle => _t('Register / Cara Pakai', 'Register / Usage');

  // --- Modules coming soon ---
  String get moduleInDevelopment =>
      _t('Modul ini sedang dalam pengembangan', 'This module is under development');
  String get remindMeButton => _t('Ingatkan Saya', 'Remind Me');
  String get willRemindYou =>
      _t('Kami akan mengingatkanmu saat modul ini siap!', "We'll remind you when this module is ready!");
  String get viewPremiumOptionsButton => _t('Lihat Opsi Premium', 'View Premium Options');
  String get closeButton => _t('Tutup', 'Close');

  // --- Profile: avatar picker / edit name / cover picker ---
  String get pickAvatarTitle => _t('Pilih Avatar', 'Choose Avatar');
  String get accountPhotoSection => _t('Foto Akun', 'Account Photo');
  String get googleAccountPhotoLabel => _t('Foto akun Google', 'Google account photo');
  String get freePresetsSection => _t('Preset Gratis', 'Free Presets');
  String get premiumPresetsSection => _t('Preset Premium', 'Premium Presets');
  String get avatarSaveFailed =>
      _t('Gagal menyimpan avatar, coba lagi.', 'Failed to save avatar, try again.');
  String get displayNameHint => _t('Nama tampilan', 'Display name');
  String get freeNameChangeHint => _t(
        'Ganti nama gratis dengan menonton iklan sebentar.',
        'Change your name for free by watching a short ad.',
      );
  String get firstNameChangeFreeHint => _t(
        'Ganti nama pertama kali gratis, tanpa iklan.',
        'Your first name change is free, no ad needed.',
      );
  String get saveButton => _t('Simpan', 'Save');
  String get watchAdAndSaveButton => _t('Nonton Iklan & Simpan', 'Watch Ad & Save');
  String get nameSaveFailed => _t('Gagal menyimpan nama, coba lagi.', 'Failed to save name, try again.');
  String get adLoadFailed => _t('Gagal memuat iklan, coba lagi.', 'Failed to load ad, try again.');
  String get pickCoverTitle => _t('Pilih Sampul', 'Choose Cover');
  String get coverSaveFailed =>
      _t('Gagal menyimpan sampul, coba lagi.', 'Failed to save cover, try again.');
  String get coverPremiumTitle => _t('Sampul Premium', 'Cover Premium');
  String get frameSection => _t('Bingkai', 'Frame');
  String get pickFrameTitle => _t('Pilih Bingkai', 'Choose Frame');
  String get noFrameLabel => _t('Tanpa Bingkai', 'No Frame');
  String get frameSaveFailed =>
      _t('Gagal menyimpan bingkai, coba lagi.', 'Failed to save frame, try again.');
  String get framePremiumTitle => _t('Bingkai Premium', 'Frame Premium');

  // --- Bab (curriculum) ---
  String get sectionKurikulum => _t('Kurikulum', 'Curriculum');
  String get babTitle => 'Bab';
  String get babSubtitle => _t(
        'Jalur belajar terpandu, gabungan kosakata, tata bahasa, dan percakapan',
        'A guided learning path combining vocabulary, grammar, and conversation',
      );
  String get babGuideIntro =>
      _t('Ayo mulai Bab 1!', 'Let\'s start Bab 1!');
  String babGuideContinue(String chapterTitle) => _t(
        'Lanjutkan ke "$chapterTitle", kamu pasti bisa!',
        'Continue with "$chapterTitle", you\'ve got this!',
      );
  String babLevelComingSoon(String levelKey) =>
      _t('Bab $levelKey segera hadir!', 'Bab $levelKey coming soon!');
  String babLevelCardTitle(String levelKey) => 'Bab $levelKey';
  String babChapterCount(int n) => _t('$n bab', '$n chapters');
  String babLevelLockedReason(String previousLevelKey) => _t(
        'Selesaikan semua bab $previousLevelKey dulu untuk membuka level ini.',
        'Finish every $previousLevelKey chapter first to unlock this level.',
      );
  String babLevelChapterProgress(int done, int total) =>
      _t('$done/$total bab selesai', '$done/$total chapters done');
  String get babLevelLockedBadge => _t('Terkunci', 'Locked');
  String get babLevelCompleteBadge => _t('Selesai', 'Complete');
  String get babCurrentLevelTitle => _t('Level Saat Ini', 'Current Level');
  String babLevelStandingSummary(String levelKey, int done, int total) => _t(
        'Sedang mengerjakan Bab $levelKey — $done dari $total bab.',
        'Working through Bab $levelKey — $done of $total chapters.',
      );
  String get babAllLevelsComplete => _t(
        'Seluruh kurikulum N5-N1 sudah selesai. Luar biasa!',
        'The whole N5-N1 curriculum is done. Outstanding!',
      );
  String babLevelAppBarTitle(String levelKey) => 'Bab $levelKey';
  String get kanjiGuideMessage => _t(
        'Pilih level JLPT, lalu pelajari urutan goresan tiap kanji. '
            'Tandai semua kanji "Sudah Dipelajari" untuk membuka level berikutnya.',
        'Pick a JLPT level, then learn each kanji stroke by stroke. '
            'Mark every kanji "Learned" to unlock the next level.',
      );
  String get kaiwaGuideMessage => _t(
        'Pilih level JLPT, lalu pelajari tiap dialog percakapan. '
            'Tandai semua dialog "Sudah Dipelajari" untuk membuka level berikutnya.',
        'Pick a JLPT level, then learn each conversation dialogue. '
            'Mark every dialogue "Learned" to unlock the next level.',
      );
  String get choukaiGuideMessage => _t(
        'Pilih level JLPT, lalu kerjakan ujian mendengarnya. '
            'Lulus dengan skor 70% ke atas untuk membuka level berikutnya.',
        'Pick a JLPT level, then take its listening exam. '
            'Score 70% or higher to unlock the next level.',
      );
  String get dokkaiGuideMessage => _t(
        'Pilih level JLPT, lalu kerjakan ujian bacaannya. '
            'Lulus dengan skor 70% ke atas untuk membuka level berikutnya.',
        'Pick a JLPT level, then take its reading exam. '
            'Score 70% or higher to unlock the next level.',
      );
  String get babLevelGuideMessage => _t(
        'Pilih satu bab untuk mulai belajar.',
        'Pick a chapter to start learning.',
      );
  String get babSectionKotoba => _t('Kosakata', 'Vocabulary');
  String get babSectionKanji => _t('Kanji', 'Kanji');
  String get babSectionBunpou => _t('Tata Bahasa', 'Grammar');
  String get babSectionParticle => _t('Partikel', 'Particles');
  String get babSectionKaiwa => _t('Percakapan', 'Conversation');
  String get babSectionDokkai => _t('Bacaan Tambahan', 'Extra Reading');
  /// [gated] mirrors `kBabGateQuizRequired`. While that switch is off
  /// nothing is actually locked, so promising an unlock would be a lie —
  /// the quiz is still worth taking, it just marks the chapter done
  /// rather than opening the next one.
  String babGuideQuizMessage(int order, {bool gated = true}) {
    final range = order == 1 ? 'Bab 1' : 'Bab 1-$order';
    if (!gated) {
      return _t(
        'Pelajari semua bagian di atas, lalu kerjakan kuis $range untuk menandai bab ini selesai.',
        'Work through everything above, then take the $range quiz to mark this chapter done.',
      );
    }
    return _t(
      'Pelajari semua bagian di atas, lalu kerjakan kuis $range untuk membuka bab berikutnya.',
      'Work through everything above, then take the $range quiz to unlock the next chapter.',
    );
  }
  String get babGuideDoneMessage =>
      _t('Kerja bagus! Bab ini sudah selesai.', 'Great job! This chapter is done.');
  String get babStartGateQuiz =>
      _t('Kerjakan Kuis untuk Lanjut', 'Take the Quiz to Continue');
  String get babCompletedLabel => _t('Bab Selesai', 'Chapter Complete');
  String babLockedReason(int previousOrder) => _t(
        'Selesaikan kuis Bab $previousOrder dulu untuk membuka bab ini.',
        'Finish the Bab $previousOrder quiz first to unlock this chapter.',
      );
  // --- Age question (AdMob audience) ---
  // Worded neutrally on purpose: Google requires an age screen that does
  // not hint which answer unlocks more, so nothing here mentions ads,
  // restrictions, or what changes based on the reply.
  String get ageQuestionTitle => _t('Tahun berapa kamu lahir?', 'What year were you born?');
  String get ageQuestionBody => _t(
        'Kami menanyakan ini satu kali saja, supaya isi aplikasi sesuai '
            'untuk umurmu.',
        'We ask this once, so the app can be suitable for your age.',
      );
  String get ageQuestionChooseYear => _t('Pilih tahun', 'Choose a year');
  String get ageQuestionSaveFailed => _t(
        'Gagal menyimpan jawaban. Coba lagi.',
        'Could not save your answer. Please try again.',
      );
  String get ageQuestionContinue => _t('Lanjut', 'Continue');

  String get babGateQuizTitle => _t('Kuis Pembuka Bab', 'Chapter Unlock Quiz');
  /// Shown only on iOS, which reports the screenshot gesture rather than
  /// its result — so this appears even when the captured image came out
  /// blank. Worded as "terdeteksi" rather than as a claim about whether
  /// anything was actually saved, since the platform does not tell us.
  /// Android never reaches this: there the capture is refused outright.
  String get screenshotDetectedNotice => _t(
        'Tangkapan layar terdeteksi. Soal kuis ini tidak untuk dibagikan, ya.',
        'Screenshot detected. These quiz questions are not for sharing.',
      );
  String get babGatePassedMessage => _t(
        'Hebat! Bab berikutnya sudah terbuka.',
        'Great work! The next chapter is now unlocked.',
      );
  String babGateFailedMessage(int passMark, int total) => _t(
        'Perlu minimal $passMark dari $total jawaban benar untuk membuka bab '
            'berikutnya. Coba lagi, ya!',
        'You need at least $passMark of $total correct to unlock the next '
            'chapter. Try again!',
      );
  String get babGateNoQuestions => _t(
        'Belum ada soal yang bisa dibuat untuk bab ini.',
        'No questions could be generated for this chapter yet.',
      );

  // --- Flashcard ---
  String get kanaDataNotFound =>
      _t('Data kana tidak ditemukan', 'Kana data not found');
  String failedToLoadData(Object e) =>
      _t('Gagal memuat data: $e', 'Failed to load data: $e');
  String get tapCardForMeaning => _t(
        'tekan kartu untuk melihat arti',
        'tap the card to see its meaning',
      );
  String get wordExampleBadge => _t('Contoh Kata', 'Word Example');
  String meaningIs(String meaning) =>
      _t('Artinya: $meaning', 'Meaning: $meaning');
  String get noWordExample =>
      _t('Belum ada contoh kata', 'No word example yet');

  // --- Kanji Combo (Ujian) ---
  // The mode labels reuse [examCategoryKanjiComboSingle]/[...Combination]
  // rather than declaring a second copy of the same two words, and the
  // question prompts already live above as [kanjiComboReadingPrompt] /
  // [kanjiComboCompoundPrompt].
  String get kanjiComboExamTitle => _t('Ujian Kanji', 'Kanji Exam');
  String kanjiComboNotEnoughData(String levelKey) => _t(
        '$levelKey belum cukup data untuk mode ini.',
        'Not enough $levelKey data for this mode yet.',
      );

  // --- Stroke order animator ---
  String get replayStrokes => _t('Ulangi', 'Replay');
  String get pauseStrokes => _t('Jeda', 'Pause');
  String get playStrokes => _t('Putar', 'Play');
  String get showAllStrokesNumbered => _t(
        'Tampilkan semua goresan bernomor',
        'Show all strokes, numbered',
      );

  // --- Choukai (listening) ---
  String choukaiLevelComingSoon(String levelName) =>
      _t('Choukai $levelName segera hadir!', 'Choukai $levelName coming soon!');
  String choukaiLevelLockedReason(String previousLevelKey) => _t(
        'Lulus ujian Choukai $previousLevelKey (skor minimal 70%) dulu untuk membuka level ini.',
        'Pass the $previousLevelKey Choukai exam (70% or higher) first to unlock this level.',
      );
  String choukaiLevelTitle(String levelName) => 'Choukai $levelName';
  String failedToLoadClips(Object e) =>
      _t('Gagal memuat klip: $e', 'Failed to load clips: $e');
  String get noClipsForLevel => _t(
        'Klip untuk level ini belum tersedia.',
        'No clips available for this level yet.',
      );
  String clipCount(int n) => _t('$n klip', n == 1 ? '$n clip' : '$n clips');
  String questionCount(int n) =>
      _t('$n soal', n == 1 ? '$n question' : '$n questions');
  String get tapToPlayAudio =>
      _t('Ketuk untuk memutar / mengulang', 'Tap to play / replay');
  String get audioScriptTitle => _t('Naskah Audio', 'Audio Script');

  // --- Dokkai (reading) ---
  String dokkaiLevelComingSoon(String levelName) =>
      _t('Dokkai $levelName segera hadir!', 'Dokkai $levelName coming soon!');
  String dokkaiLevelLockedReason(String previousLevelKey) => _t(
        'Lulus ujian Dokkai $previousLevelKey (skor minimal 70%) dulu untuk membuka level ini.',
        'Pass the $previousLevelKey Dokkai exam (70% or higher) first to unlock this level.',
      );
  String dokkaiLevelTitle(String levelName) => 'Dokkai $levelName';
  String dokkaiSessionTitle(int questions) =>
      _t('Dokkai · $questions Soal', 'Dokkai · $questions Questions');
  String noPassagesForLevel(String levelName) => _t(
        'Bacaan untuk Dokkai $levelName belum tersedia.',
        'No reading passages available for Dokkai $levelName yet.',
      );
  String dokkaiLevelSubtitle(int passages, int questionsPerSession) => _t(
        '$passages bacaan · $questionsPerSession soal acak setiap sesi',
        '$passages passages · $questionsPerSession random questions per session',
      );

  // --- Card Game Mode (see NOTES_CARD_GAME_MODE.md) ---
  String get battleTitle => _t('Pertandingan', 'Match');
  String battleLoadCardDataError(Object error) =>
      _t('Gagal memuat data kartu: $error', 'Failed to load card data: $error');
  String battleLoadMatchError(Object error) =>
      _t('Gagal memuat pertandingan: $error', 'Failed to load match: $error');
  String get battleNotSignedIn => _t('Belum masuk akun.', 'Not signed in.');
  String get battleCardNotFound =>
      _t('Kartu tidak ditemukan.', 'Card not found.');
  String battleCardProgress(int current, int total) =>
      _t('Kartu $current / $total', 'Card $current / $total');
  String get battleWaitingForOpponent => _t(
        'Menunggu jawaban lawan...',
        "Waiting for opponent's answer...",
      );
  String battleMyScore(int score) => _t('Kamu: $score', 'You: $score');
  String battleOpponentScore(int score) =>
      _t('Lawan: $score', 'Opponent: $score');
  String get battleSendAnswer => _t('Kirim', 'Send');
  String get battleRomajiHint => _t('Ketik romaji...', 'Type romaji...');
  String get battleResultWin => _t('Menang!', 'You win!');
  String get battleResultLose => _t('Kalah', 'You lose');
  String get battleResultDraw => _t('Seri!', 'Draw!');
  String get battleResultDone => _t('Selesai', 'Done');

  // Dev-only manual test screen — see BattleTestStartScreen's own doc
  // comment for why this exists and isn't wired into real navigation.
  String get battleTestTitle =>
      _t('Uji Coba Pertandingan (dev)', 'Test Match (dev)');
  String get battleTestDescription => _t(
        'Alat uji manual — bukan alur produk sungguhan. Masukkan uid akun '
        'kedua (device/akun lain yang sudah login) untuk membuat '
        'pertandingan uji coba. Isi kartu memakai tingkat akun ini untuk '
        'kedua pemain.',
        'Manual test tool — not a real product flow. Enter a second '
        'account\'s uid (another device/account already signed in) to '
        'create a test match. Card content uses this account\'s own tier '
        'for both players.',
      );
  String get battleTestOpponentUidLabel => _t('UID lawan', 'Opponent UID');
  String get battleTestCreateButton =>
      _t('Buat Pertandingan', 'Create Match');
  String get battleTestBotButton => _t('Lawan Bot', 'Play vs Bot');
  String get battleTestJoinDescription => _t(
        'Gabung ke match yang sudah dibuat perangkat lain (masukkan matchId '
        'yang ditampilkan di atas pada device yang membuatnya).',
        "Join a match another device already created (enter the matchId "
        "shown above on the device that created it).",
      );
  String get battleTestMatchIdLabel => _t('Match ID', 'Match ID');
  String get battleTestJoinButton => _t('Gabung ke Match', 'Join Match');
  String get battleDebugTooltip => _t(
        'DEBUG uji coba pertandingan',
        'DEBUG battle test',
      );

  // Tahap 3 butir 9 — undangan teman/clan (see NOTES_CARD_GAME_MODE.md).
  String get battleTierHiragana => _t('Hiragana Dasar', 'Basic Hiragana');
  String get battleTierKatakanaCombo =>
      _t('Katakana + Gabungan', 'Katakana + Combos');
  String get battleTierKanjiN5 => _t('Kanji N5', 'Kanji N5');
  String get battleTierKanjiN4N3 => _t('Kanji N4–N3', 'Kanji N4–N3');
  String get battleTierKanjiN2N1 => _t('Kanji N2–N1', 'Kanji N2–N1');
  String battleChallengeTitle(String targetName) =>
      _t('Tantang $targetName Bertanding Kartu', 'Challenge $targetName to a Card Match');
  String get battleChallengePickTier =>
      _t('Pilih tingkat kartu:', 'Pick a card tier:');
  String get battleChallengeSending =>
      _t('Mengirim tantangan...', 'Sending challenge...');
  String get battleChallengeFailed => _t(
        'Gagal mengirim tantangan, coba lagi.',
        'Failed to send challenge, try again.',
      );
  String get battleChallengeOfflineTooltip => _t(
        'Sedang tidak online',
        'Currently offline',
      );
  String get battleInviteWaitingTitle =>
      _t('Menunggu Lawan', 'Waiting for Opponent');
  String battleInviteWaitingFor(String targetName) => _t(
        'Menunggu $targetName menerima tantanganmu...',
        'Waiting for $targetName to accept your challenge...',
      );
  String battleInviteWaitingCountdown(int seconds) => _t(
        'Tantangan hangus dalam ${seconds}s',
        'Challenge expires in ${seconds}s',
      );
  String battleInviteDeclined(String targetName) => _t(
        '$targetName menolak tantanganmu.',
        '$targetName declined your challenge.',
      );
  String battleInviteNoAnswer(String targetName) => _t(
        '$targetName tidak menjawab tepat waktu.',
        '$targetName did not answer in time.',
      );
  String get battleInviteTryAgainHint => _t(
        'Kamu bisa menantang lagi kapan saja.',
        'You can challenge again any time.',
      );
  String get battleInviteCancel =>
      _t('Batalkan Tantangan', 'Cancel Challenge');
  String get battleInviteGoneAway => _t(
        'Tantangan ini sudah tidak berlaku.',
        'This challenge is no longer available.',
      );
  String battleChallengeNotificationTitle(String fromName) =>
      _t('$fromName menantangmu!', '$fromName challenged you!');
  String battleChallengeNotificationBody(String tierLabel) => _t(
        'Ayo bertanding kartu $tierLabel sekarang.',
        'Play a $tierLabel card match right now.',
      );
  String pendingBattleInvitesTitle(int count) => _t(
        'Kamu punya $count tantangan pertandingan',
        'You have $count battle challenge${count == 1 ? '' : 's'}',
      );
  String battleInvitedBy(String fromName, String tierLabel) => _t(
        '$fromName menantangmu — $tierLabel',
        '$fromName challenged you — $tierLabel',
      );

  // Tahap 3 butir 10 — matchmaking publik (see NOTES_CARD_GAME_MODE.md).
  // Dropped the "(dev)" this carried while the screen was reachable only
  // through a hand-edited main.dart — it is on the Home page now.
  String get battleMatchmakingTitle =>
      _t('Cari Lawan', 'Find an Opponent');
  String battleMatchmakingDescription(String tierLabel) => _t(
        'Kamu akan dicari lawan di tingkatmu sendiri ($tierLabel). Kalau '
            'tidak ada lawan dalam 20 detik, kamu otomatis melawan bot.',
        'You\'ll be matched with an opponent at your own tier ($tierLabel). '
            'If nobody\'s found within 20 seconds, you\'ll automatically '
            'play a bot instead.',
      );
  // --- Card Game Mode: lobby, result, skin picker (redesign) ---
  String get purchaseRestore => _t('Pulihkan Pembelian', 'Restore Purchases');
  String get purchaseDelivered =>
      _t('Terima kasih! Pembelian aktif.', 'Thank you! Purchase active.');
  String get purchaseCancelled =>
      _t('Pembelian dibatalkan.', 'Purchase cancelled.');
  String get purchaseFailed => _t(
        'Pembelian gagal. Kamu tidak ditagih.',
        'Purchase failed. You have not been charged.',
      );
  String get purchaseNotSetUp => _t(
        'Pembelian belum aktif di toko. Coba lagi nanti.',
        'Purchases are not live in the store yet. Try again later.',
      );
  String get premiumBadge => _t('PREMIUM', 'PREMIUM');
  String premiumLevelLocked(String level) => _t(
        '$level terkunci — buka dengan Premium',
        '$level is locked — unlock with Premium',
      );
  String get battleHandTitle => _t('Kartu di tanganmu', 'Cards in hand');
  String battleHandRemaining(int left, int total) => _t(
        '$left / $total',
        '$left / $total',
      );
  String get battleChooseInstruction => _t(
        'Pilih 1 kartu dari tanganmu untuk dikirim ke lawan!',
        'Pick one card from your hand to send to your opponent!',
      );
  String get battleCardToSend => _t('Kartu untuk lawan', 'Card to send');
  String get cardGameWordmark => _t('TEISOU BATTLE', 'TEISOU BATTLE');
  String get cardGameWordmarkSub =>
      _t('Card Battle Kana', 'Card Battle Kana');
  String get cardGameLobbyDeckTitle => _t('Dekmu', 'Your deck');
  String cardGameLobbyDeckCount(int count) =>
      _t('$count kartu', '$count cards');
  String get cardGameSearchSubtitle =>
      _t('Mulai pertandingan', 'Start a match');
  String get battleSearchingTitle =>
      _t('Mencari lawan...', 'Finding an opponent...');
  String get battleSearchingSubtitle => _t(
        'Mencocokkan kamu dengan pemain lain',
        'Matching you with another player',
      );
  String get battleStatCorrect => _t('Benar', 'Correct');
  String get battleStatWrong => _t('Salah', 'Wrong');
  String get battleStatCards => _t('Kartu', 'Cards');
  String get battleStatDuration => _t('Durasi', 'Duration');
  String get cardSkinFilterAll => _t('Semua', 'All');
  String get cardSkinFilterOwned => _t('Dimiliki', 'Unlocked');
  String get cardSkinCosmeticOnly => _t(
        'Skin hanya mengubah tampilan kartu — tidak mempengaruhi kekuatan.',
        'Skins only change how a card looks — they change nothing else.',
      );
  String get cardSkinSectionEvent => _t('Event', 'Event');
  String get cardSkinSectionEventSubtitle => _t(
        'Dibagikan saat acara tertentu. Tidak dijual, tidak dari bintang.',
        'Handed out during an event. Not sold, not earned with stars.',
      );
  String get cardSkinEventLocked => _t(
        'Belum dibagikan — tunggu acaranya.',
        'Not handed out yet — wait for the event.',
      );
  String get battleMatchmakingOffline => _t(
        'Tidak bisa terhubung. Cek koneksimu, lalu coba lagi.',
        'Cannot connect. Check your connection and try again.',
      );
  String get battleMatchmakingSearchButton =>
      _t('Cari Lawan', 'Find Opponent');
  String battleMatchmakingWaiting(int secondsLeft) => _t(
        'Menunggu lawan... ${secondsLeft}s',
        'Waiting for opponent... ${secondsLeft}s',
      );
  String get battleMatchmakingCancelButton => _t('Batal', 'Cancel');
  String get battleMatchmakingFallingBackToBot => _t(
        'Tidak ada lawan, melawan bot...',
        'No opponent found, playing a bot...',
      );
  String get battleMatchmakingFailed => _t(
        'Gagal mencari lawan, coba lagi.',
        'Failed to find an opponent, try again.',
      );

  // Tangga bintang. The tier names themselves (Bronze/Silver/Gold/
  // Diamond/Emerald) are deliberately not translated — they're the same
  // words in both languages here, and every ranked game an Indonesian
  // player has seen uses them untranslated.
  // Arena pertandingan (tampilan kartu).
  String get battleYouLabel => _t('Kamu', 'You');
  String get battleOpponentLabel => _t('Lawan', 'Opponent');
  String get recentMatchesTitle =>
      _t('Pertandingan terakhir', 'Recent matches');
  String get matchOutcomeWin => _t('Menang', 'Win');
  String get matchOutcomeLoss => _t('Kalah', 'Loss');
  String get matchOutcomeUnfinished =>
      _t('Belum selesai', 'Unfinished');
  String get matchOutcomeDraw => _t('Seri', 'Draw');
  String matchAgainst(String opponent) =>
      _t('lawan $opponent', 'vs $opponent');
  String get battleOpponentUnknown => _t('Pemain', 'Player');
  String get battleBotName => _t('Bot', 'Bot');
  String get battleCardFromOpponent =>
      _t('Kartu dari lawan — jawab!', 'Their card — answer it!');
  String get battleCardFromYou =>
      _t('Kartumu, lawan sedang menjawab', 'Your card, opponent is answering');
  String get battleReviewTitle => _t(
        'Kartu yang dimainkan — yang bergaris tebal kartumu',
        'Cards played — the bold ones were yours',
      );
  String get battlePlayAgain => _t('Main Lagi', 'Play Again');
  String get battleChooseYourCard =>
      _t('Pilih kartu untuk lawan', 'Pick a card for your opponent');
  String get battleOpponentChoosing =>
      _t('Lawan sedang memilih kartu...', 'Opponent is picking a card...');
  // Skin kartu — satu-satunya kosmetik yang dilihat lawan.
  // Mode Kartu — bottom nav dan dua tab barunya.
  String get cardGameTabHome => _t('Beranda', 'Home');
  String get cardGameTabDeck => _t('Deck', 'Deck');
  String get cardGameTabBattle => _t('Battle', 'Battle');
  String get cardGameTabSkin => _t('Skin', 'Skins');
  String get cardGameTabShop => _t('Toko', 'Shop');
  String get cardGameLobbyHint => _t(
        'Bintang hanya bergerak di pertandingan publik dan lawan bot. '
            'Lawan teman lewat Chat di Profil — santai, tanpa risiko.',
        'Stars only move in public and bot matches. Challenge a friend '
            'from Chat in your profile — casual, nothing at stake.',
      );
  String deckTabHeading(String tierContent) =>
      _t('Dekmu: $tierContent', 'Your deck: $tierContent');
  String deckTabExplanation(int poolSize) => _t(
        'Tiap pertandingan kamu dibagikan 20 kartu acak dari $poolSize '
            'kartu di bawah ini. Dek tidak bisa diatur — yang menentukan '
            'isinya adalah tingkatmu.',
        'Every match deals you 20 random cards from the $poolSize below. '
            'A deck cannot be arranged — your tier decides what is in it.',
      );
  String deckTabNextTier(String tier, String content) =>
      _t('Berikutnya di $tier: $content', 'Next at $tier: $content');
  String get deckTabNextTierHint => _t(
        'Naik tingkat berarti naik tahap belajar — ini sebagian yang '
            'menunggu di sana.',
        'Climbing a tier means climbing a stage of study — here is some '
            'of what waits there.',
      );
  String get shopNotOpenYet => _t(
        'Toko belum buka. Pembelian sungguhan menyusul; sekarang '
            'skin-nya bisa dilihat dulu.',
        'The shop is not open yet. Real purchases come later; for now the '
            'skins can be looked at.',
      );
  String get shopSkinsHeading => _t('Skin Berbayar', 'Paid Skins');
  String get shopSkinsSubtitle => _t(
        'Hanya bisa dibeli. Skin pencapaian tidak dijual di sini, dan '
            'skin di sini tidak bisa didapat dengan bintang.',
        'Bought only. Achievement skins are not sold here, and these are '
            'never opened by stars.',
      );
  String get shopSkinRowNote =>
      _t('Belum bisa dibeli', 'Not buyable yet');
  String get shopBuySoon => _t('Segera', 'Soon');
  String get cardSkinTitle => _t('Skin Kartu', 'Card Skins');
  String get cardSkinExplanation => _t(
        'Punggung kartu ini yang dilihat lawanmu setiap kali kamu '
            'mengeluarkan kartu. Yang terkunci bisa dibuka dengan premium '
            'atau menonton satu iklan.',
        'This card back is what your opponent sees every time you play a '
            'card. Locked ones open with premium, or by watching one ad.',
      );
  String cardSkinSectionTitle(CardSkinSource source) => switch (source) {
        CardSkinSource.free => _t('Gratis', 'Free'),
        CardSkinSource.achievement => _t('Pencapaian', 'Achievement'),
        CardSkinSource.paid => _t('Toko', 'Shop'),
        CardSkinSource.event => _t('Event', 'Event'),
      };
  String cardSkinSectionSubtitle(CardSkinSource source) => switch (source) {
        CardSkinSource.free =>
          _t('Punyamu sejak awal.', 'Yours from the start.'),
        CardSkinSource.achievement => _t(
            'Terbuka sendiri kalau bintangmu cukup — dan terkunci lagi '
                'kalau turun. Tidak bisa dibeli.',
            'Opens on its own once you have the stars, and locks again if '
                'you drop below. Not for sale.',
          ),
        CardSkinSource.paid => _t(
            'Dibeli di toko. Tidak bisa didapat dengan bintang.',
            'Bought in the shop. Stars will not open these.',
          ),
        CardSkinSource.event => _t(
            'Dibagikan saat acara tertentu. Tidak dijual, bukan dari '
                'bintang.',
            'Handed out during an event. Not sold, not earned with stars.',
          ),
      };
  String cardSkinNeedsStars(int required, int owned) => _t(
        'Butuh $required bintang — kamu punya $owned',
        'Needs $required stars — you have $owned',
      );
  String get cardSkinShopSoon => _t(
        'Toko belum buka — pembelian menyusul.',
        'The shop is not open yet — buying comes later.',
      );
  String get cardSkinDebugAllUnlocked => _t(
        'Mode uji: semua skin bisa dipilih supaya tampilannya bisa '
            'diperiksa. Di aplikasi rilis, penguncian tetap berlaku.',
        'Test build: every skin is selectable so the art can be checked. '
            'In a release build the locks still apply.',
      );
  String get cardSkinSaved => _t('Skin kartu dipakai.', 'Card skin applied.');
  String get cardSkinSaveFailed => _t(
        'Gagal menyimpan skin, coba lagi.',
        'Could not save the skin, try again.',
      );
  String get battleRankStandingLabel => _t('Peringkatmu', 'Your standing');
  // Perubahan bintang di layar hasil.
  String get battleStarsCounting =>
      _t('Menghitung bintang...', 'Counting stars...');
  String get battleStarsPending => _t(
        'Bintangmu sedang diperbarui — cek lagi sebentar lagi.',
        'Your stars are still updating — check again shortly.',
      );
  String get battleStarsCasual => _t(
        'Pertandingan santai — bintang tidak bergerak.',
        'Friendly match — stars do not move.',
      );
  String battleStarsGained(int delta) =>
      _t('+$delta bintang', '+$delta stars');
  String battleStarsLostAmount(int delta) =>
      _t('$delta bintang', '$delta stars');
  String get battleStarsUnchanged =>
      _t('Bintang tidak berubah', 'Stars unchanged');
  String get battleStarsProtected => _t(
        'Di Bronze & Silver kamu tidak kehilangan bintang.',
        'At Bronze & Silver you never lose stars.',
      );
  String get battleStarsFloorAbsorbed => _t(
        'Kamu sudah di dasar divisi ini — bintang tidak berkurang.',
        'You are already at this division\'s floor — no stars lost.',
      );
  String battleStarsPromotedTier(String standing) =>
      _t('Naik tingkat — $standing!', 'Promoted — $standing!');
  String battleStarsPromotedDivision(String standing) =>
      _t('Naik divisi — $standing!', 'Division up — $standing!');
  String battleStarsDroppedDivision(String standing) =>
      _t('Turun ke $standing', 'Dropped to $standing');
  String get cardGameTitle => _t('Mode Kartu', 'Card Mode');
  String get cardGameSubtitle => _t(
        'Adu cepat baca kana & kanji lawan pemain lain',
        'Race another player to read kana & kanji',
      );
  /// Shown once the player's standing has loaded, so the card itself
  /// answers "where am I?" without opening anything.
  String cardGameSubtitleWithRank(String standing, String stars) =>
      _t('$standing · $stars', '$standing · $stars');
  String battleRankStars(int stars, int perDivision) =>
      _t('$stars/$perDivision bintang', '$stars/$perDivision stars');
  String battleRankStarsUncapped(int stars) =>
      _t('$stars bintang', '$stars stars');
  String battleRankWinStreak(int wins) => _t(
        'Menang $wins kali beruntun — kemenangan berikutnya +2 bintang',
        '$wins wins in a row — the next win is worth +2 stars',
      );

  // --- Leaderboard: Card Game Mode star ranking tab ---
  String cardGameStarTotalLabel(int total) =>
      _t('$total bintang', '$total stars');
  String get cardGameStarsExplainer => _t(
        'Peringkat Mode Kartu — cuma pertandingan publik dan lawan bot yang '
            'menggerakkan bintang, lawan teman/clan santai tanpa risiko.',
        'Card Mode ranking — only public and bot matches move stars; '
            'friend/clan matches stay risk-free.',
      );
  String get cardGameNeverPlayed => _t(
        'Belum pernah bertanding Mode Kartu.',
        'Hasn\'t played Card Mode yet.',
      );
}
