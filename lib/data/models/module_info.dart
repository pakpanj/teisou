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
/// screen is built out. Choukai is deliberately NOT here — listening
/// comprehension now lives as an exam type inside the Ujian tab instead of
/// being its own standalone module (see lib/features/choukai/).
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
