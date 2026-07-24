import '../../data/models/app_language.dart';

/// Hand-written UI-chrome string bundle — one getter per string, an id/en
/// pair each, picked by [language]. This app has no codegen anywhere else
/// (hand-written `fromJson`/`toJson` throughout `data/models`, no
/// freezed/json_serializable), so this follows suit instead of introducing
/// Flutter's ARB/gen-l10n pipeline for the first time.
///
/// **Coverage, not the whole app**: Home tab, Modules section, Profile
/// screen, language picker, and (as of the Kanji/Kotoba pass) the Kanji
/// and Kotoba modules' Home/Level-or-Category/Detail/Quiz screens are
/// wired to this. Bunpou/Partikel/Kaiwa's equivalent screens, and
/// everything outside the 5 learning modules (Search, Leaderboard, Ujian,
/// Saved Words, About, Notification, Paywall, Cam Detector, etc.) are
/// NOT yet — see CLAUDE.md's "Bahasa App" note for the exact scope and
/// why. Switching to English right now only changes what's listed there;
/// the rest of the app stays in Indonesian until a later pass extends
/// this, following the same `ref.watch(appStringsProvider)` pattern.
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
  String get basicChars46 => _t('46 karakter dasar', '46 basic characters');
  String get exam => _t('Ujian', 'Exam');
  String get testYourSkills => _t('Uji kemampuanmu!', 'Test your skills!');

  // --- Bottom nav ---
  String get navHome => _t('Home', 'Home');
  String get navExam => _t('Ujian', 'Exam');
  String get navProfile => _t('Profil', 'Profile');

  // --- Modules section ---
  String get otherModules => _t('Modul Lainnya', 'More Modules');
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
  String get savedWords => _t('Daftar Belajar', 'Saved Words');
  String get appLanguage => _t('Bahasa App', 'App Language');
  String get notifications => _t('Notifikasi', 'Notifications');
  String get aboutApp => _t('Tentang App', 'About App');
  String get resetProgress => _t('Reset Progress', 'Reset Progress');
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
  String get resetProgressConfirmTitle =>
      _t('Reset progress Hiragana & Katakana?', 'Reset Hiragana & Katakana progress?');
  String get resetProgressConfirmBody => _t(
        'Yakin mau reset progress Hiragana & Katakana? Ini tidak '
            'menghapus streak atau riwayat ujian kamu.',
        "Are you sure you want to reset your Hiragana & Katakana progress? "
            "This won't delete your streak or exam history.",
      );
  String get resetConfirmTitle => _t('Konfirmasi Reset', 'Confirm Reset');
  String get resetConfirmBody => _t(
        'Progress yang dihapus tidak bisa dikembalikan. Ketik RESET '
            'untuk konfirmasi.',
        "Deleted progress can't be recovered. Type RESET to confirm.",
      );
  String get resetSuccessSnackbar =>
      _t('Progress berhasil direset.', 'Progress reset successfully.');

  // --- Language screen ---
  String get chooseAppLanguage =>
      _t('Pilih bahasa aplikasi', 'Choose app language');
  String get languageScopeNote => _t(
        'Catatan: sebagian layar mungkin masih menggunakan Bahasa '
            'Indonesia untuk saat ini.',
        "Note: some screens may still show Indonesian text for now.",
      );
  String get languageSaved => _t('Bahasa disimpan.', 'Language saved.');

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
}
