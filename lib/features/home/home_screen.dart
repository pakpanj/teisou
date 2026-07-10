import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/mountain_scenery.dart';
import '../../core/widgets/sakura_decoration.dart';
import '../../data/models/kana_type.dart';
import '../exam/exam_mode_picker_screen.dart';
import '../flashcard/flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _navIndex = index);
      return;
    }
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExamModePickerScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            children: [
                              TextSpan(
                                text: 'Kana\n',
                                style: TextStyle(color: AppColors.textNavy),
                              ),
                              TextSpan(
                                text: 'Master',
                                style: TextStyle(color: AppColors.primaryCoral),
                              ),
                            ],
                          ),
                        ),
                        const SakuraDecoration(size: 56),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Belajar Kana, Langkah Pertama Menuju Jepang!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const MountainScenery(height: 120),
                    ),
                    const SizedBox(height: 24),
                    _MenuCard(
                      backgroundColor: AppColors.hiraganaCardBg,
                      iconBackgroundColor: AppColors.primaryCoral,
                      iconLabel: 'あ',
                      title: 'Belajar Hiragana',
                      subtitle: '46 karakter dasar',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FlashcardScreen(type: KanaType.hiragana),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuCard(
                      backgroundColor: AppColors.katakanaCardBg,
                      iconBackgroundColor: AppColors.secondaryBlue,
                      iconLabel: 'ア',
                      title: 'Belajar Katakana',
                      subtitle: '46 karakter dasar',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FlashcardScreen(type: KanaType.katakana),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuCard(
                      backgroundColor: AppColors.tertiaryAmberCardBg,
                      iconBackgroundColor: AppColors.tertiaryAmber,
                      icon: Icons.assignment_outlined,
                      title: 'Ujian',
                      subtitle: 'Uji kemampuanmu!',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExamModePickerScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final String? iconLabel;
  final IconData? icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.backgroundColor,
    required this.iconBackgroundColor,
    this.iconLabel,
    this.icon,
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
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: iconLabel != null
                    ? Text(
                        iconLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(icon, color: Colors.white),
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
              Icon(Icons.chevron_right, color: iconBackgroundColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.menu_book_rounded, label: 'Belajar'),
    (icon: Icons.assignment_rounded, label: 'Ujian'),
    (icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final active = index == currentIndex;
          final color = active ? AppColors.primaryCoral : Colors.grey;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: color),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
