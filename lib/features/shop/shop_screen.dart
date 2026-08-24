import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../battle/shop_tab.dart';
import '../profile/widgets/avatar_picker_sheet.dart';
import '../profile/widgets/cover_picker_sheet.dart';
import 'widgets/coin_balance_bar.dart';

/// One shop for everything cosmetic — card skins, avatar, frame, cover —
/// reachable from the main bottom nav (Home / Ujian / Toko / Profil)
/// instead of being buried inside Card Battle's own five-tab nav.
///
/// **Card Battle used to own the only "Toko" tab in the app**, which meant
/// a learner who never opened Card Battle never saw a shop at all, even
/// though three of the four things this screen sells (avatar, frame,
/// cover) have nothing to do with battling — they're Profile cosmetics.
/// Moving the shop out to the same level as Home/Ujian/Profil is what
/// actually puts it where every learner can find it; Card Battle's own
/// nav is back down to Beranda/Deck/Battle/Skin (see `CardGameShell`).
///
/// **No picking logic is duplicated, only re-displayed.** Every tab here
/// embeds the exact same widget the app already used elsewhere: [ShopTab]
/// (unchanged, still Card Battle's own skin-buying logic), and
/// [AvatarPickerBody]/[FramePickerBody]/[CoverPickerBody] — the bodies
/// `AvatarPickerSheet`/`CoverPickerSheet` were split into so the picking
/// logic (ad-reward unlocks, the actual Firestore write) lives in exactly
/// one place regardless of whether it's reached from Profile's bottom
/// sheet or from here. `popOnSelect: false` on all three: there is no
/// sheet to close, just a tab to keep browsing.
///
/// **Buying happens here, not in Profile.** `shopMode: true` on all three
/// bodies is what shows their locked ("Belum Dimiliki") section at all —
/// every preset still to unlock, whichever tier (ad, coin, or Premium),
/// lives in Toko. Profile's own avatar/frame/cover picker sheets
/// (`shopMode` defaults to false there) only ever show what's already
/// owned; a preset appears there the moment it's unlocked here, never
/// before. Per explicit product decision: Profile is where you wear
/// what you own, Toko is where you get more of it.
///
/// [CoinBalanceBar] sits above the tabs, not inside one of them — the
/// balance belongs to the account, not to whichever tab happens to be
/// open. Coins can currently only be *earned* (top-up, or the weekly
/// Skor Global reward) — there is no coin-priced item to actually spend
/// them on yet; that's a separate follow-up once the tier split from the
/// plan-intro/premium redesign session is applied to real presets.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: AppBar(
          title: Text(s.shopScreenTitle),
          bottom: TabBar(
            isScrollable: true,
            labelColor: context.palette.primaryCoral,
            unselectedLabelColor: context.palette.textNavy.withValues(
              alpha: 0.55,
            ),
            indicatorColor: context.palette.primaryCoral,
            tabs: [
              Tab(text: s.shopTabSkins),
              Tab(text: s.shopTabAvatar),
              Tab(text: s.shopTabFrame),
              Tab(text: s.shopTabCover),
            ],
          ),
        ),
        body: Column(
          children: [
            const CoinBalanceBar(),
            const Expanded(
              child: TabBarView(
                children: [
                  ShopTab(),
                  _ShopSubPage(
                    child: AvatarPickerBody(popOnSelect: false, shopMode: true),
                  ),
                  _ShopSubPage(
                    child: FramePickerBody(popOnSelect: false, shopMode: true),
                  ),
                  _ShopSubPage(
                    child: CoverPickerBody(popOnSelect: false, shopMode: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [ShopTab] already carries its own [ListView] and padding; the other
/// three bodies were built to sit inside an existing scroll view (the old
/// bottom sheets), so this gives them the same treatment here.
class _ShopSubPage extends StatelessWidget {
  final Widget child;

  const _ShopSubPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [child]);
  }
}
