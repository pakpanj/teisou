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
/// screen is built out.
const kComingSoonModules = <ModuleInfo>[
  ModuleInfo(
    id: 'kanji',
    title: 'Kanji N5',
    description: 'Belajar karakter Kanji dasar level N5',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
  ModuleInfo(
    id: 'particle',
    title: 'Partikel',
    description: 'Memahami partikel は, が, を, に, dan lainnya',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
  ModuleInfo(
    id: 'bunpou',
    title: 'Bunpou (Tata Bahasa)',
    description: 'Pola kalimat dan struktur tata bahasa Jepang',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
  ModuleInfo(
    id: 'choukai',
    title: 'Choukai (Listening)',
    description: 'Latihan mendengar percakapan sehari-hari',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
  ModuleInfo(
    id: 'kaiwa',
    title: 'Kaiwa (Percakapan)',
    description: 'Latihan percakapan dasar untuk situasi nyata',
    iconAsset: '',
    status: ModuleStatus.comingSoon,
    requiresPremium: true,
  ),
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
