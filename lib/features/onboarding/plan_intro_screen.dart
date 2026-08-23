import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/premium_purchase_flow.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/mascot_widget.dart';

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
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      if (outcome == IapOutcome.delivered) _finish();
    });
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Marks this device as having seen the intro and lets the startup
  /// gate move on to the tutorial/home screen — see `_PlanIntroGate` in
  /// `main.dart`, which rebuilds off the same [hasSeenPlanIntroProvider]
  /// this invalidates.
  Future<void> _finish() async {
    await ref.read(planIntroRepositoryProvider).markSeen();
    ref.invalidate(hasSeenPlanIntroProvider);
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
      body: SafeArea(
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
                  icon: Icon(Icons.arrow_back, color: context.palette.textNavy),
                  onPressed: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            if (_page == 1)
              Positioned(
                top: 8,
                right: 12,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(s.planIntroSkip),
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
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onContinue;

  const _WelcomePage({required this.strings, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final s = strings;
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
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const MascotWidget(mood: MascotMood.waving, size: 150),
                Positioned(
                  left: 0,
                  top: 10,
                  child: _IconBadge(
                    icon: Icons.style,
                    color: context.palette.secondaryBlue,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 10,
                  child: _IconBadge(
                    icon: Icons.groups,
                    color: context.palette.tertiaryAmber,
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 10,
                  child: _IconBadge(
                    icon: Icons.sports_esports,
                    color: context.palette.primaryCoral,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 10,
                  child: _IconBadge(
                    icon: Icons.auto_stories,
                    color: context.palette.successGreen,
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
                    icon: Icons.card_giftcard,
                    iconColor: context.palette.secondaryBlue,
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
                    icon: Icons.workspace_premium,
                    iconColor: context.palette.premiumGoldStart,
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
                          color: context.palette.textNavy.withValues(alpha: 0.7),
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
              onPressed: onContinue,
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
  final IconData icon;
  final Color iconColor;
  final List<String> bullets;
  final bool highlighted;

  const _PlanSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bullets,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? context.palette.premiumGoldStart
              : context.palette.mutedSurface,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: context.palette.textNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: context.palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 14, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 11,
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

class _ComparePage extends ConsumerWidget {
  final AppStrings strings;
  final PremiumPurchaseFlow purchase;
  final VoidCallback onSkip;

  const _ComparePage({
    required this.strings,
    required this.purchase,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
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
          const MascotWidget(mood: MascotMood.excited, size: 110),
          const SizedBox(height: 16),
          _ComparisonTable(strings: s),
          const SizedBox(height: 20),
          _PremiumPriceCard(strings: s, purchase: purchase),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.premiumGoldStart,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                await purchase.buy(context, s);
              },
              icon: const Icon(Icons.workspace_premium),
              label: Text(s.planIntroStartPremiumButton),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: Text(s.planIntroUseFreeButton),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final AppStrings strings;

  const _ComparisonTable({required this.strings});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final rows = <(String, String, String)>[
      (s.planIntroRowKanji, s.planIntroValueKanjiFree, s.planIntroValueKanjiPremium),
      (s.planIntroRowBunpou, s.planIntroValueBunpouFree, s.planIntroValueBunpouPremium),
      (s.planIntroRowPartikelKaiwaChoukai, s.planIntroValueLocked, s.planIntroValueUnlocked),
      (s.planIntroRowCardSkins, s.planIntroValueBasic, s.planIntroValueExclusive),
      (s.planIntroRowPractice, s.planIntroValueBasic, s.planIntroValuePremium),
      (s.planIntroRowAds, s.planIntroValueAdsShown, s.planIntroValueAdsFree),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    s.planIntroFreeTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: context.palette.textNavy.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: context.palette.premiumGoldStart.withValues(alpha: 0.12),
                  child: Text(
                    s.planIntroPremiumTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: context.palette.premiumGoldEnd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final row in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.palette.textNavy,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textNavy.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: context.palette.premiumGoldStart.withValues(alpha: 0.06),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      row.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              _PriceFeature(icon: Icons.event_busy, label: s.planIntroCancelAnytime),
              _PriceFeature(icon: Icons.star, label: s.planIntroAllFeatures),
              _PriceFeature(icon: Icons.security, label: s.planIntroSecurePayment),
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
