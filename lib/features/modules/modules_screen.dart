import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/kana_type.dart';
import '../../data/models/module_info.dart';
import '../cam_detector/cam_detector_screen.dart';
import '../flashcard/flashcard_screen.dart';
import 'widgets/coming_soon_content.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modul Belajar'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader('Tersedia'),
          const SizedBox(height: 12),
          _AvailableModuleCard(
            emoji: 'あ',
            backgroundColor: AppColors.hiraganaCardBg,
            iconColor: AppColors.primaryCoral,
            title: 'Belajar Hiragana',
            subtitle: '46 karakter dasar',
            onTap: () => AppNavigator.slideFromRight(
              context,
              const FlashcardScreen(type: KanaType.hiragana),
            ),
          ),
          const SizedBox(height: 12),
          _AvailableModuleCard(
            emoji: 'ア',
            backgroundColor: AppColors.katakanaCardBg,
            iconColor: AppColors.secondaryBlue,
            title: 'Belajar Katakana',
            subtitle: '46 karakter dasar',
            onTap: () => AppNavigator.slideFromRight(
              context,
              const FlashcardScreen(type: KanaType.katakana),
            ),
          ),
          const SizedBox(height: 12),
          _AvailableModuleCard(
            emoji: '📷',
            backgroundColor: AppColors.tertiaryAmberCardBg,
            iconColor: AppColors.tertiaryAmber,
            title: 'Cam Detector',
            subtitle: 'Scan karakter Jepang lewat kamera',
            onTap: () => AppNavigator.slideFromBottom(
              context,
              const CamDetectorScreen(),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionHeader('Segera Hadir'),
          const SizedBox(height: 12),
          ...kComingSoonModules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ComingSoonCard(module: module),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textNavy,
      ),
    );
  }
}

class _AvailableModuleCard extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvailableModuleCard({
    required this.emoji,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final ModuleInfo module;

  const _ComingSoonCard({required this.module});

  static const _icons = {
    'kanji': '字',
    'particle': 'を',
    'bunpou': '文',
    'choukai': '🎧',
    'kaiwa': '💬',
    'picture_learning': '🖼️',
    'video_learning': '🎬',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showComingSoonSheet(context, moduleId: module.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _icons[module.id] ?? '❓',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            module.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.freeBadgeGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Segera Hadir',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.freeBadgeGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (module.requiresPremium) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock, color: AppColors.freeBadgeGrey, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
