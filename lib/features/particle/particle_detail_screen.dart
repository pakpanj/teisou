import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/particle_entry.dart';
import '../../data/models/particle_function.dart';
import '../../data/models/sentence_example.dart';
import 'particle_providers.dart';

/// Full detail view for one particle, with next/prev navigation BETWEEN
/// PARTICLES across the [entries] list it was opened from (mirrors
/// `bunpou/bunpou_detail_screen.dart`'s paging shape). Unlike a Bunpou
/// pattern (one meaning per entry), one particle nests several distinct
/// [ParticleFunction]s — rendered here as a stack of [ExpansionTile]s
/// (first expanded, rest collapsed) rather than a single flat meaning
/// section, since a particle like に/で can carry 5-6 functions and
/// stacking all of them open unconditionally would make this the longest
/// page in the app.
class ParticleDetailScreen extends ConsumerStatefulWidget {
  final List<ParticleEntry> entries;
  final int initialIndex;
  final String categoryName;

  const ParticleDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.categoryName,
  });

  @override
  ConsumerState<ParticleDetailScreen> createState() => _ParticleDetailScreenState();
}

class _ParticleDetailScreenState extends ConsumerState<ParticleDetailScreen> {
  late int _index = widget.initialIndex;
  bool _togglingLearned = false;

  ParticleEntry get _entry => widget.entries[_index];

  void _goNext() {
    if (_index >= widget.entries.length - 1) return;
    setState(() => _index = _index + 1);
  }

  void _goPrev() {
    if (_index <= 0) return;
    setState(() => _index = _index - 1);
  }

  Future<void> _toggleLearned(bool currentlyLearned) async {
    setState(() => _togglingLearned = true);
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    final repo = ref.read(particleProgressRepositoryProvider);
    if (currentlyLearned) {
      await repo.unmarkLearned(_entry.id, uid: uid);
    } else {
      await repo.markLearned(_entry.id, _entry.category, uid: uid);
    }
    ref.invalidate(particleLearnedIdsProvider);
    if (!mounted) return;
    setState(() => _togglingLearned = false);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final learnedIds = ref.watch(particleLearnedIdsProvider).valueOrNull ?? const <String>{};
    final isLearned = learnedIds.contains(entry.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${_index + 1} / ${widget.entries.length}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Keyed on the particle id so the scroll position (and every
              // ExpansionTile's expand state) resets when paging next/prev,
              // instead of carrying over a stale scroll offset from an
              // entry with a very different number of functions.
              child: SingleChildScrollView(
                key: ValueKey(entry.id),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _ParticleDisplay(entry: entry),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _CategoryBadge(category: entry.category),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AudioButton(
                      onTap: () => ref.read(ttsServiceProvider).speak(entry.particle),
                    ),
                    const SizedBox(height: 16),
                    _LearnedButton(
                      learned: isLearned,
                      busy: _togglingLearned,
                      onTap: _togglingLearned ? null : () => _toggleLearned(isLearned),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Ringkasan'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(entry.overview, style: const TextStyle(color: AppColors.textNavy)),
                    ),
                    if (entry.similarParticles.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle('Partikel Serupa'),
                      const SizedBox(height: 8),
                      _SimilarParticlesRow(ids: entry.similarParticles),
                    ],
                    const SizedBox(height: 24),
                    const _SectionTitle('Fungsi'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < entry.functions.length; i++)
                      _FunctionTile(
                        function: entry.functions[i],
                        initiallyExpanded: i == 0,
                        onSpeak: (text) => ref.read(ttsServiceProvider).speak(text),
                      ),
                  ],
                ),
              ),
            ),
            _NavRow(
              hasPrev: _index > 0,
              hasNext: _index < widget.entries.length - 1,
              onPrev: _goPrev,
              onNext: _goNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticleDisplay extends StatelessWidget {
  final ParticleEntry entry;

  const _ParticleDisplay({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            entry.particle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.particleRomaji,
            style: TextStyle(fontSize: 14, color: AppColors.textNavy.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// Small inline category pill — [entry.category] is only ever "kasus" /
/// "keterangan" / "akhir_kalimat", but the display NAME lives in
/// [ParticleCategoryInfo] (`particleCategoriesProvider`), so this resolves
/// it the same way [_SimilarParticlesRow] resolves ids, rather than
/// hardcoding a second copy of the category-name mapping here. Can't reuse
/// `JlptBadge` (`features/search/widgets/jlpt_badge.dart`) — it's
/// hardcoded to [JlptLevel].
class _CategoryBadge extends ConsumerWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(particleCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        final name = categories
            .firstWhere(
              (c) => c.id == category,
              orElse: () => categories.first,
            )
            .name;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tertiaryAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tertiaryAmber),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Resolves [ids] (raw `ParticleEntry.id` values) to their display particle
/// text via [particleAllProvider] before rendering as pills — falls back
/// to the raw id only if a lookup genuinely can't find a match.
class _SimilarParticlesRow extends ConsumerWidget {
  final List<String> ids;

  const _SimilarParticlesRow({required this.ids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(particleAllProvider);
    return allAsync.when(
      data: (all) {
        final byId = {for (final e in all) e.id: e.particle};
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ids
              .map((id) => _Pill(text: byId[id] ?? id, color: AppColors.primaryCoral))
              .toList(),
        );
      },
      loading: () => const SizedBox(
        height: 24,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textNavy,
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AudioButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryCoral,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.volume_up, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _LearnedButton extends StatelessWidget {
  final bool learned;
  final bool busy;
  final VoidCallback? onTap;

  const _LearnedButton({required this.learned, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: learned ? AppColors.secondaryBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: learned ? null : Border.all(color: AppColors.secondaryBlue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  learned ? Icons.check_circle : Icons.check_circle_outline,
                  size: 18,
                  color: learned ? Colors.white : AppColors.secondaryBlue,
                ),
              const SizedBox(width: 8),
              Text(
                learned ? 'Sudah Dipelajari' : 'Tandai Sudah Dipelajari',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: learned ? Colors.white : AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FunctionTile extends StatelessWidget {
  final ParticleFunction function;
  final bool initiallyExpanded;
  final ValueChanged<String> onSpeak;

  const _FunctionTile({
    required this.function,
    required this.initiallyExpanded,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            function.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textNavy),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                function.explanation,
                style: const TextStyle(color: AppColors.textNavy, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  function.formation,
                  style: TextStyle(color: AppColors.textNavy.withValues(alpha: 0.8), height: 1.4),
                ),
              ),
            ),
            if (function.sentenceExamples.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...function.sentenceExamples.map(
                (example) => _SentenceExampleCard(
                  example: example,
                  onSpeak: () => onSpeak(example.japanese),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentenceExampleCard extends StatelessWidget {
  final SentenceExample example;
  final VoidCallback onSpeak;

  const _SentenceExampleCard({required this.example, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.japanese,
                  style: const TextStyle(fontSize: 15, color: AppColors.textNavy),
                ),
                if (example.romaji != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    example.romaji!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textNavy.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  example.translation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textNavy.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppColors.primaryCoral),
            onPressed: onSpeak,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavRow({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.arrow_back,
            background: Colors.grey.shade300,
            iconColor: AppColors.textNavy,
            onTap: hasPrev ? onPrev : null,
          ),
          _NavButton(
            icon: Icons.arrow_forward,
            background: AppColors.primaryCoral,
            iconColor: Colors.white,
            onTap: hasNext ? onNext : null,
          ),
        ],
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
