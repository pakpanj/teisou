import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/kana_glyph.dart';
import '../../data/models/kana_character.dart';
import '../../data/models/kana_progress.dart';
import '../../data/models/kana_type.dart';
import '../../data/models/kana_type_progress.dart';
import 'widgets/flip_card.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final KanaType type;

  const FlashcardScreen({super.key, required this.type});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int? _index;

  bool get _isHiragana => widget.type == KanaType.hiragana;

  void _goNext(int total) {
    if (_index == null || _index! >= total - 1) return;
    setState(() => _index = _index! + 1);
    _persistIndex();
  }

  void _goPrev() {
    if (_index == null || _index! <= 0) return;
    setState(() => _index = _index! - 1);
    _persistIndex();
  }

  void _persistIndex() {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null || _index == null) return;
    ref
        .read(progressRepositoryProvider)
        .setLastIndex(uid, widget.type, _index!);
  }

  Future<void> _handleFlip(
    bool isFront,
    KanaCharacter kana,
    KanaProgress currentProgress,
  ) async {
    if (isFront) return;
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref
        .read(progressRepositoryProvider)
        .recordCardViewed(uid, widget.type, kana.id, currentProgress);
  }

  @override
  Widget build(BuildContext context) {
    final kanaListAsync = ref.watch(kanaListProvider(widget.type));
    final progressAsync = ref.watch(typeProgressProvider(widget.type));

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isHiragana ? 'Belajar Hiragana' : 'Belajar Katakana'),
      ),
      body: kanaListAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Data kana tidak ditemukan'));
          }
          return progressAsync.when(
            data: (progress) => _buildBody(list, progress),
            loading: () => _buildBody(list, KanaTypeProgress.empty()),
            error: (e, _) => _buildBody(list, KanaTypeProgress.empty()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
      ),
    );
  }

  Widget _buildBody(List<KanaCharacter> list, KanaTypeProgress progress) {
    _index ??= progress.lastIndex.clamp(0, list.length - 1);
    final index = _index!;
    final kana = list[index];
    final currentProgress = progress.progressFor(kana.id);
    final accent = _isHiragana
        ? AppColors.primaryCoral
        : AppColors.secondaryBlue;

    final cardBackground = _isHiragana
        ? 'assets/images/hiragana_card_bg.png'
        : 'assets/images/katakana_card_bg.png';

    return Column(
      children: [
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${index + 1} / ${list.length}',
            style: TextStyle(fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        SizedBox(
          height: 800,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 700,
                child: FlipCard(
                  key: ValueKey(kana.id),
                  onFlipped: (isFront) =>
                      _handleFlip(isFront, kana, currentProgress),

                  front: _CardFace(
                    background: cardBackground,
                    child: _FrontContent(kana: kana, accent: accent),
                  ),

                  back: _CardFace(
                    background: cardBackground,
                    child: _BackContent(kana: kana, accent: accent),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Text(
          'Geser atau tekan kartu untuk melihat arti',
          style: TextStyle(color: AppColors.textNavy, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.arrow_back,
                background: Colors.grey.shade300,
                iconColor: AppColors.textNavy,
                onTap: index > 0 ? _goPrev : null,
              ),
              _NavButton(
                icon: Icons.arrow_forward,
                background: accent,
                iconColor: Colors.white,
                onTap: index < list.length - 1
                    ? () => _goNext(list.length)
                    : null,
              ),
            ],
          ),
        ),
        const FreeTierBannerAd(),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;
  final String background;

  const _CardFace({required this.child, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: AssetImage(background),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FrontContent extends ConsumerWidget {
  final KanaCharacter kana;
  final Color accent;

  const _FrontContent({required this.kana, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Center(child: KanaGlyph(kana: kana, size: 140)),
        Positioned(
          top: 16,
          right: 16,
          child: _AudioButton(
            color: accent,
            onTap: () => ref.read(ttsServiceProvider).speak(kana.character),
          ),
        ),
      ],
    );
  }
}

class _BackContent extends ConsumerWidget {
  final KanaCharacter kana;
  final Color accent;

  const _BackContent({required this.kana, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final example = kana.examples.isNotEmpty ? kana.examples.first : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            KanaGlyph(kana: kana, size: 64),
            const SizedBox(height: 8),
            Text(
              kana.romaji.toUpperCase(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            if (example != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Contoh Kata',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${example.word} (${example.reading})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Artinya: ${example.meaning}',
                style: const TextStyle(color: AppColors.textNavy),
              ),
              const SizedBox(height: 12),
              _AudioButton(
                color: accent,
                onTap: () => ref.read(ttsServiceProvider).speak(example.word),
              ),
            ] else
              const Text(
                'Belum ada contoh kata',
                style: TextStyle(color: AppColors.textNavy),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _AudioButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.volume_up, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? background.withValues(alpha: 0.4) : background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
