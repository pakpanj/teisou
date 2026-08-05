enum ModuleStatus { available, comingSoon, locked, previewUnlocked }

class ModuleInfo {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final ModuleStatus status;
  final bool requiresPremium;

  const ModuleInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.status,
    this.requiresPremium = false,
  });
}

/// Static registry of learning modules. Hiragana/Katakana are already
/// shipped; everything else is a "Segera Hadir" placeholder until its
/// screen is built out. Choukai is deliberately NOT here, but not for the
/// reason this comment used to give: it does not live in the Ujian tab
/// either. `ExamModePickerScreen` offers only Kana and Kanji; Choukai and
/// Dokkai are practice material, so both are `_AvailableModuleCard`s under
/// the Home tab's "Latihan" section (see `modules_section.dart`).
const kComingSoonModules = <ModuleInfo>[
  ModuleInfo(
    id: 'picture_learning',
    title: 'Belajar dari Gambar',
    description: 'Perkaya kosakata lewat asosiasi gambar',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
  ModuleInfo(
    id: 'video_learning',
    title: 'Belajar dari Video',
    description: 'Video singkat dengan subtitle dwibahasa',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
];
