import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/premium_icons.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/premium_purchase_flow.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';
import '../battle/widgets/battle_arena.dart' show BattleBackdrop;

/// Free-vs-Premium, shown once per device, right after the age question
/// and before the home-screen tutorial — see `main.dart`'s `_PlanIntroGate`
/// for exactly where this sits and why there, and
/// `PlanIntroRepository` for how "once" is remembered.
///
/// Two pages: an overview ([_WelcomePage]) and a real feature comparison
/// with the actual purchase button ([_ComparePage]) — mirroring a
/// reference mockup's shape, but with **Teisou's own features**, not the
/// mockup's (a clan/tournament app's — this app has neither). The
/// mockup's yearly price was dropped for the same reason: there is no
/// yearly product in Play Console, only `teisou_premium_monthly`, and
/// this app never shows a price it cannot actually charge.
class PlanIntroFlow extends ConsumerStatefulWidget {
  const PlanIntroFlow({super.key});

  @override
  ConsumerState<PlanIntroFlow> createState() => _PlanIntroFlowState();
}

class _PlanIntroFlowState extends ConsumerState<PlanIntroFlow> {
  final _controller = PageController();
  int _page = 0;
  late final PremiumPurchaseFlow _purchase;
  StreamSubscription<IapOutcome>? _outcomeSub;

  @override
  void initState() {
    super.initState();
    _purchase = PremiumPurchaseFlow(ref);
    _purchase.loadPrice().then((_) {
      if (mounted) setState(() {});
    });
    _outcomeSub = _purchase.outcomes.listen((outcome) {
      if (!mounted) return;
      final s = ref.read(appStringsProvider);
      final message = switch (outcome) {
        IapOutcome.delivered => s.purchaseDelivered,
        IapOutcome.cancelled => s.purchaseCancelled,
        IapOutcome.unavailable => s.storeUnavailable,
        IapOutcome.failed => s.purchaseFailed,
        IapOutcome.pendingVerification => s.purchasePendingVerification,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      // pendingVerification deliberately does NOT finish/dismiss — the
      // learner stays here, told the truth, until either a later retry
      // resolves it (IapService.notePremiumConfirmed fires a real
      // `delivered` on this same stream once Firestore confirms) or they
      // choose Free themselves. Finishing now on an unconfirmed purchase
      // would be the exact bug this state exists to close.
      if (outcome == IapOutcome.delivered) _finish(premiumOverride: true);
    });
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Marks this **account** as having seen the intro and lets the
  /// startup gate move on to the tutorial/home screen — see
  /// `_PlanIntroGate` in `main.dart`, which rebuilds off the same
  /// [planIntroShouldShowProvider] this invalidates.
  ///
  /// [premiumOverride] is passed `true` from the purchase-delivered
  /// path: `subscriptionProvider`'s Firestore snapshot can lag a moment
  /// behind `verifyPurchase` actually landing, so the outcome that just
  /// fired is a more reliable "premium now" than re-reading it. Every
  /// other dismissal (the Free Plan button) reads whatever
  /// `subscriptionProvider` currently holds — by this point
  /// `planIntroShouldShowProvider` has already awaited its first value,
  /// so it's available synchronously.
  Future<void> _finish({bool? premiumOverride}) async {
    final user = ref.read(appStartupProvider).valueOrNull;
    if (user != null) {
      final isPremiumNow =
          premiumOverride ??
          ref.read(subscriptionProvider).valueOrNull?.isPremium ??
          false;
      await ref
          .read(progressRepositoryProvider)
          .markPlanIntroSeen(user.uid, premiumNow: isPremiumNow);
    }
    ref.invalidate(planIntroShouldShowProvider);
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: BattleBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(strings: s, onContinue: _next),
                  _ComparePage(
                    strings: s,
                    purchase: _purchase,
                    onSkip: _finish,
                  ),
                ],
              ),
              if (_page == 1)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textNavy,
                    ),
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? context.palette.primaryCoral
                            : context.palette.mutedSurface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One floating feature badge around the mascot — same illustrated art
/// as `PaywallScreen`'s own `_FeatureBadge` (see `PremiumIcons`'s doc
/// comment for where it came from). Kept as its own small copy rather
/// than importing that screen's private widget: two near-identical
/// four-line widgets in different features is cheaper than a shared
/// public export just to save one class.
class _IconBadge extends StatelessWidget {
  final String asset;

  const _IconBadge(this.asset);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _WelcomePage extends StatefulWidget {
  final AppStrings strings;
  final VoidCallback onContinue;

  const _WelcomePage({required this.strings, required this.onContinue});

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  // Slower than MascotWidget's own 850ms waving idle on purpose — matching
  // it one-to-one made the badges flicker up and down distractingly fast.
  // This still reads as "orbiting the character" without being frantic.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  /// Wraps one badge with a gentle vertical float. [phase] offsets where
  /// in the cycle each badge starts, so all four don't bob in lockstep —
  /// a little stagger reads as alive, perfect unison reads as mechanical.
  Widget _floating(Widget child, {double phase = 0}) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, _) {
        final t = (_bob.value + phase) % 1.0;
        final lift = math.sin(t * 2 * math.pi) * 5;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          Text(
            s.planIntroWelcomeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.planIntroWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.palette.textNavy.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            width: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const MascotWidget(
                  mood: MascotMood.waving,
                  size: 140,
                  showBackdrop: false,
                  groundShadow: true,
                ),
                Positioned(
                  left: 0,
                  top: 14,
                  child: _floating(
                    const _IconBadge(PremiumIcons.skin),
                    phase: 0,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 14,
                  child: _floating(
                    const _IconBadge(PremiumIcons.kanji),
                    phase: 0.25,
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 14,
                  child: _floating(
                    const _IconBadge(PremiumIcons.kaiwa),
                    phase: 0.5,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 14,
                  child: _floating(
                    const _IconBadge(PremiumIcons.noAds),
                    phase: 0.75,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.planIntroChooseTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PlanSummaryCard(
                    title: s.planIntroFreeTitle,
                    subtitle: s.planIntroFreeSubtitle,
                    imageAsset: PremiumIcons.chestFree,
                    bullets: [
                      s.planIntroFreeBulletKana,
                      s.planIntroFreeBulletKanjiBunpou,
                      s.planIntroFreeBulletBab,
                      s.planIntroFreeBulletCardGame,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanSummaryCard(
                    title: s.planIntroPremiumTitle,
                    subtitle: s.planIntroPremiumSubtitle,
                    imageAsset: PremiumIcons.chestPremium,
                    highlighted: true,
                    bullets: [
                      s.planIntroPremiumBulletAllModules,
                      s.benefitExclusiveCardSkins,
                      s.benefitPremiumPractice,
                      s.benefitNoAds,
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.mutedSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: context.palette.successGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.planIntroSecureTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: context.palette.textNavy,
                        ),
                      ),
                      Text(
                        s.planIntroSecureSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textNavy.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.primaryCoral,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: widget.onContinue,
              child: Text(s.planIntroContinueButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  /// The plan's chest illustration — `PremiumIcons.chestFree` or
  /// `.chestPremium` (see that class's doc comment). Replaced the
  /// generic gift-box / crown Material icons this card used before the
  /// chest art existed.
  final String imageAsset;
  final List<String> bullets;
  final bool highlighted;

  const _PlanSummaryCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.bullets,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? context.palette.premiumGoldStart
              : context.palette.mutedSurface,
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: context.palette.premiumGoldStart.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imageAsset, width: 48, height: 48),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: highlighted
                        ? context.palette.premiumGoldStart
                        : context.palette.secondaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: context.palette.textNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Which plan the page 2 picker currently has selected — drives both the
/// detail box's content and the single CTA button's label/action below it.
enum _Plan { free, premium }

class _ComparePage extends ConsumerStatefulWidget {
  final AppStrings strings;
  final PremiumPurchaseFlow purchase;
  final VoidCallback onSkip;

  const _ComparePage({
    required this.strings,
    required this.purchase,
    required this.onSkip,
  });

  @override
  ConsumerState<_ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<_ComparePage> {
  // Premium first — this page exists to sell Premium, so the picker opens
  // on the plan the page is trying to show off, not a neutral default.
  _Plan _selected = _Plan.premium;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isPremium = _selected == _Plan.premium;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
      child: Column(
        children: [
          Text(
            s.planIntroCompareTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 12),
          const MascotWidget(
            mood: MascotMood.cheering,
            size: 110,
            showBackdrop: false,
            groundShadow: true,
          ),
          const SizedBox(height: 20),
          _PlanPickerToggle(
            selected: _selected,
            freeLabel: s.planIntroFreeTitle,
            premiumLabel: s.planIntroPremiumTitle,
            onChanged: (plan) => setState(() => _selected = plan),
          ),
          const SizedBox(height: 16),
          _PlanDetailBox(strings: s, premium: isPremium),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: isPremium
                ? Padding(
                    key: const ValueKey('premium-price'),
                    padding: const EdgeInsets.only(top: 20),
                    child: _PremiumPriceCard(
                      strings: s,
                      purchase: widget.purchase,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('free-price')),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: isPremium
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.palette.premiumGoldStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      await widget.purchase.buy(context, s);
                    },
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(s.planIntroStartPremiumButton),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.palette.primaryCoral,
                        width: 1.5,
                      ),
                      foregroundColor: context.palette.primaryCoral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: widget.onSkip,
                    child: Text(s.planIntroUseFreeButton),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A tappable — and swipeable — segmented picker replacing the old static
/// side-by-side comparison. One plan is "on" at a time; [_PlanDetailBox]
/// and the CTA button below react to whichever one that is.
class _PlanPickerToggle extends StatelessWidget {
  final _Plan selected;
  final String freeLabel;
  final String premiumLabel;
  final ValueChanged<_Plan> onChanged;

  const _PlanPickerToggle({
    required this.selected,
    required this.freeLabel,
    required this.premiumLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 200) {
          onChanged(_Plan.free);
        } else if (v < -200) {
          onChanged(_Plan.premium);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.palette.mutedSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PickerSegment(
                label: freeLabel,
                icon: Icons.card_giftcard,
                active: selected == _Plan.free,
                activeColor: context.palette.secondaryBlue,
                onTap: () => onChanged(_Plan.free),
              ),
            ),
            Expanded(
              child: _PickerSegment(
                label: premiumLabel,
                icon: Icons.workspace_premium,
                active: selected == _Plan.premium,
                activeColor: context.palette.premiumGoldEnd,
                onTap: () => onChanged(_Plan.premium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _PickerSegment({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? context.palette.cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? activeColor
                  : context.palette.textNavy.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? context.palette.textNavy
                    : context.palette.textNavy.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The enlarged detail box beneath the picker — shows every feature row
/// for whichever plan [premium] currently points at, one column instead
/// of the old two-column table, so the picker above genuinely drives what
/// this renders rather than just decorating an unchanged table.
class _PlanDetailBox extends StatelessWidget {
  final AppStrings strings;
  final bool premium;

  const _PlanDetailBox({required this.strings, required this.premium});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final rows = <(IconData, String, String)>[
      (
        Icons.menu_book,
        s.planIntroRowKanji,
        premium ? s.planIntroValueKanjiPremium : s.planIntroValueKanjiFree,
      ),
      (
        Icons.school,
        s.planIntroRowBunpou,
        premium ? s.planIntroValueBunpouPremium : s.planIntroValueBunpouFree,
      ),
      (
        Icons.lock_open,
        s.planIntroRowPartikelKaiwaChoukai,
        premium ? s.planIntroValueUnlocked : s.planIntroValueLocked,
      ),
      (
        Icons.style,
        s.planIntroRowCardSkins,
        premium ? s.planIntroValueExclusive : s.planIntroValueBasic,
      ),
      (
        Icons.fitness_center,
        s.planIntroRowPractice,
        premium ? s.planIntroValuePremium : s.planIntroValueBasic,
      ),
      (
        Icons.block,
        s.planIntroRowAds,
        premium ? s.planIntroValueAdsFree : s.planIntroValueAdsShown,
      ),
    ];
    final accent = premium
        ? context.palette.premiumGoldEnd
        : context.palette.secondaryBlue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: premium
              ? context.palette.premiumGoldStart.withValues(alpha: 0.45)
              : context.palette.divider,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.palette.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 20, color: accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rows[i].$3,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumPriceCard extends StatelessWidget {
  final AppStrings strings;
  final PremiumPurchaseFlow purchase;

  const _PremiumPriceCard({required this.strings, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.palette.premiumGoldStart,
            context.palette.premiumGoldEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            s.planIntroPremiumTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.planIntroPriceLabel(purchase.price),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PriceFeature(
                icon: Icons.event_busy,
                label: s.planIntroCancelAnytime,
              ),
              _PriceFeature(icon: Icons.star, label: s.planIntroAllFeatures),
              _PriceFeature(
                icon: Icons.security,
                label: s.planIntroSecurePayment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PriceFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
