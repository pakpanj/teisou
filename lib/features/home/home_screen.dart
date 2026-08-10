import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/count_badge.dart';
import '../../core/widgets/sakura_decoration.dart';
import '../../core/widgets/sakura_fall_widget.dart';
import '../exam/exam_mode_picker_screen.dart';
import '../leaderboard/friend_providers.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'widgets/modules_section.dart';

/// Root tab shell: Home / Ujian / Profil share one bottom nav bar. A
/// [PageView] backs the tabs (not just the bottom nav) so swiping
/// left/right also switches tabs — each page is wrapped in [_KeepAlivePage]
/// so scroll/state survives switching, matching the old [IndexedStack]'s
/// guarantee.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _navIndex = 0;

  static const _tabs = [
    _KeepAlivePage(child: _HomeTabBody()),
    _KeepAlivePage(child: ExamModePickerScreen()),
    _KeepAlivePage(child: ProfileScreen()),
  ];

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _navIndex = index),
        children: _tabs,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        strings: strings,
      ),
    );
  }
}

/// Keeps [child]'s state alive once built, so swiping away and back to a
/// tab doesn't lose scroll position or rebuild it from scratch.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _HomeTabBody extends ConsumerWidget {
  const _HomeTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: [
          const Positioned.fill(child: SakuraFallWidget()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AppRefreshIndicator(
                    onRefresh: () => ref.refresh(appStartupProvider.future),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Kana\n',
                                      style: TextStyle(
                                        color: context.palette.textNavy,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Master',
                                      style: TextStyle(
                                        color: context.palette.primaryCoral,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: s.searchTooltip,
                                        onPressed: () =>
                                            AppNavigator.slideFromRight(
                                              context,
                                              const SearchScreen(),
                                            ),
                                        icon: Icon(
                                          Icons.search,
                                          color: context.palette.textNavy,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: s.leaderboardTooltip,
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const LeaderboardScreen(),
                                              ),
                                            ),
                                        icon: const Text(
                                          '🏆',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SakuraDecoration(size: 48),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.homeTagline,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.palette.textNavy,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: Image.asset(
                                    'assets/images/japan_station.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color.fromARGB(0, 155, 68, 138),
                                        const Color.fromARGB(53, 248, 90, 248),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const ModulesSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                const FreeTierBannerAd(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppStrings strings;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the Profil item ever carries a badge — it's the path to the
    // Leaderboard's "Teman" tab, the one place a pending friend request is
    // otherwise invisible until this app has some real way to push a
    // notification for it. See CountBadge's own doc comment.
    final pendingFriendRequests = ref.watch(pendingFriendRequestCountProvider);
    final items = [
      (icon: Icons.home_rounded, label: strings.navHome, badge: 0),
      (icon: Icons.assignment_rounded, label: strings.navExam, badge: 0),
      (
        icon: Icons.person_rounded,
        label: strings.navProfile,
        badge: pendingFriendRequests,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
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
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;
          final color =
        active ? context.palette.primaryCoral : context.palette.freeBadgeGrey;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CountBadge(
                    count: item.badge,
                    child: Icon(item.icon, color: color),
                  ),
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
