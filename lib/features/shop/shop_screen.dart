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
///
/// **Category switching is tap-only, not swipe.** This used to be a
/// [TabBarView] — which is a horizontal [PageView] under the hood — sitting
/// one level inside `HomeScreen`'s own horizontal [PageView] (Home ↔ Ujian
/// ↔ Toko ↔ Profil). Two nested scrollables on the same axis with no
/// arbitration between them is exactly the kind of thing Flutter's gesture
/// arena resolves inconsistently: a fresh Toko let the outer swipe win,
/// but once this tab's own controller had any drag/settle history (one
/// chip tap, one partial internal drag) it started winning instead,
/// silently swallowing the app's own Home/Ujian/Toko/Profil swipe. An
/// [IndexedStack] driven only by [TabBar] taps has no horizontal
/// [Scrollable] of its own to compete with the outer one — the conflict is
/// removed rather than arbitrated, the same fix [CardGameShell] already
/// uses successfully for its own four tabs.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Drives the TabBar's own tap/indicator behaviour only — nothing here
    // reads from a TabBarView, so there is no swipeable body attached to
    // it at all.
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (_tabController.index != _index) {
          setState(() => _index = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.shopScreenTitle),
        bottom: TabBar(
          controller: _tabController,
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
          Expanded(
            // IndexedStack, not a TabBarView: every category is built and
            // kept alive regardless of which is showing (matching what
            // AutomaticKeepAliveClientMixin already gave the old
            // TabBarView), but with no Scrollable of its own — see the
            // class doc comment above for why that is the point.
            child: IndexedStack(
              index: _index,
              children: const [
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
