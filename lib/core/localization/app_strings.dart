import '../../data/models/app_language.dart';

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
  String particleQuizTitle(String categoryName) =>
      _t('Kuis · Partikel $categoryName', 'Quiz · Particle $categoryName');
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
  String get tabExamScore => _t('Skor Ujian', 'Exam Score');
  String get tabKanaRecord => _t('Rekor Kana', 'Kana Record');
  String get tabDokkaiRecord => _t('Rekor Dokkai', 'Dokkai Record');
  String get tabChoukaiRecord => _t('Rekor Choukai', 'Choukai Record');
  String get tabKanjiComboRecord => _t('Rekor Kanji-Kombinasi', 'Kanji Combo Record');
  String get noRankingData => _t('Belum ada data peringkat.', 'No ranking data yet.');
  String failedToLoadLeaderboard(Object e) =>
      _t('Gagal memuat papan peringkat: $e', 'Failed to load leaderboard: $e');
  String rankOf(int rank) => _t('Peringkat ke-$rank', 'Rank #$rank');
  String get notRankedYet => _t('Belum berperingkat', 'Not ranked yet');
  String get noRecordYet => _t('Belum ada', 'No record yet');

  // --- Clan (Leaderboard tab 7) ---
  String failedToLoadClan(Object e) =>
      _t('Gagal memuat clan: $e', 'Failed to load clan: $e');
  String get createClan => _t('Buat Clan', 'Create Clan');
  String get joinWithCode => _t('Gabung dengan Kode', 'Join with Code');
  String get sortByLabel => _t('Urutkan berdasarkan', 'Sort by');
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
  String get clanCodeHint => _t('Kode clan', 'Clan code');
  String get codeNotFound => _t('Kode tidak ditemukan.', 'Code not found.');
  String get joinClanFailed =>
      _t('Gagal bergabung, coba lagi.', 'Failed to join, try again.');
  String get joinButton => _t('Gabung', 'Join');

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
  String get examHiraganaSubtitle =>
      _t('Soal dari 46 karakter hiragana', 'Questions from 46 hiragana characters');
  String get examKatakanaTitle => _t('Ujian Katakana', 'Katakana Exam');
  String get examKatakanaSubtitle =>
      _t('Soal dari 46 karakter katakana', 'Questions from 46 katakana characters');
  String get examMixedTitle => _t('Ujian Campuran', 'Mixed Exam');
  String get examMixedSubtitle =>
      _t('Gabungan hiragana & katakana', 'Combination of hiragana & katakana');
  String get failedToSaveExamResult =>
      _t('Gagal menyimpan hasil ujian, coba lagi.', 'Failed to save exam result, try again.');
  String get noQuestionsAvailable => _t('Soal tidak tersedia', 'No questions available');
  String get whatIsThisCharacterReading =>
      _t('Apa bacaan dari huruf ini?', "What's the reading of this character?");
  String get nextQuestionButton => _t('Soal Berikutnya', 'Next Question');
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

  // --- Saved Words / About / Notification / Exam History ---
  String get noSavedWordsMessage => _t(
        'Belum ada kata tersimpan. Simpan kata dari Cam Detector untuk melihatnya di sini.',
        'No saved words yet. Save a word from Cam Detector to see it here.',
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
  String get notificationsPlaceholderMessage => _t(
        'Pengaturan pengingat belajar harian akan tersedia di sini.',
        'Daily study reminder settings will be available here.',
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
  String get uploadFromGallerySection => _t('Upload dari Galeri', 'Upload from Gallery');
  String get avatarUploadFailed =>
      _t('Gagal mengunggah avatar, coba lagi.', 'Failed to upload avatar, try again.');
  String get avatarSaveFailed =>
      _t('Gagal menyimpan avatar, coba lagi.', 'Failed to save avatar, try again.');
  String get displayNameHint => _t('Nama tampilan', 'Display name');
  String get freeNameChangeHint => _t(
        'Ganti nama gratis dengan menonton iklan sebentar.',
        'Change your name for free by watching a short ad.',
      );
  String get saveButton => _t('Simpan', 'Save');
  String get watchAdAndSaveButton => _t('Nonton Iklan & Simpan', 'Watch Ad & Save');
  String get nameSaveFailed => _t('Gagal menyimpan nama, coba lagi.', 'Failed to save name, try again.');
  String get adLoadFailed => _t('Gagal memuat iklan, coba lagi.', 'Failed to load ad, try again.');
  String get pickCoverTitle => _t('Pilih Sampul', 'Choose Cover');
  String get defaultLabel => _t('Default', 'Default');
  String get coverSaveFailed =>
      _t('Gagal menyimpan sampul, coba lagi.', 'Failed to save cover, try again.');
}
