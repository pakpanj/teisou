import 'package:flutter/material.dart';

import '../../features/bab/widgets/bab_ring_badge.dart';
import '../theme/app_palette.dart';
import 'module_card_frame.dart';

/// The level-picker row shared by Bunpou/Partikel/Kaiwa/Dokkai/Choukai's
/// home screens — a petal-ringed badge, title, a progress bar or plain
/// count line, and a circular chevron button. Reuses [BabRingBadge]/
/// [BabPercentPill]/[BabChevronButton] rather than re-deriving the same
/// "wreath" motif a fourth time; those widgets live under `features/bab/`
/// for now (built there first) but carry no Bab-specific logic, so
/// importing them here is borrowing a visual language, not a layering
/// violation.
///
/// Deliberately primitive-typed (label/title/subtitle/progress), not tied
/// to any one module's model — the same reasoning
/// `modules_section.dart`'s `_AvailableModuleCard` is generic rather than
/// Kanji- or Kotoba-shaped.
class ModuleLevelCard extends StatelessWidget {
  final String badgeLabel;
  final String title;
  final String subtitle;
  final int? percent;
  final bool available;
  final String soonLabel;
  final Color accent;
  final VoidCallback onTap;

  const ModuleLevelCard({
    super.key,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.soonLabel,
    required this.accent,
    required this.onTap,
    this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // An available card sits on the pale sakura frame; a locked one sits on
    // the theme's own muted surface. Those are two different grounds, so
    // they take two different sets of colours — see [onFramePalette].
    final surface = available ? onFramePalette : palette;
    final color = available ? onFramePalette.primaryCoral : palette.freeBadgeGrey;

    final card = Material(
      // An available card gets the sakura nine-patch frame's own flat pink
      // fill behind it (see ModuleCardFrame); a locked/muted card keeps the
      // plain flat colour it always had — same "no festive decoration on
      // an unavailable card" rule BabRingBadge's wreath already follows.
      color: available ? Colors.transparent : palette.mutedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              BabRingBadge(
                size: 64,
                color: color,
                showPetals: available,
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: available ? surface.textNavy : palette.freeBadgeGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (available) ...[
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: surface.textNavy.withValues(alpha: 0.6),
                        ),
                      ),
                      if (percent != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: percent! / 100,
                                  minHeight: 6,
                                  backgroundColor: palette.progressTrack,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BabPercentPill(percent: percent!, color: accent),
                          ],
                        ),
                      ],
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: palette.freeBadgeGrey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          soonLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: palette.freeBadgeGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BabChevronButton(color: color, size: 34),
            ],
          ),
        ),
      ),
    );

    return available ? ModuleCardFrame(child: card) : card;
  }
}
