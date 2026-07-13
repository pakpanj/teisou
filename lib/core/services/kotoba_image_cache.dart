import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Long-lived disk cache for on-demand Kotoba vocab illustrations.
/// `cached_network_image`'s default cache manager treats files as stale
/// after 30 days and re-downloads them; these illustrations never change
/// once uploaded, so re-fetching them is just wasted bandwidth. A single
/// static instance is shared by every [KotobaImage] so they all hit the
/// same on-disk cache instead of each creating (and possibly duplicating)
/// their own.
class KotobaImageCache {
  KotobaImageCache._();

  static final instance = CacheManager(
    Config(
      'kotobaImageCache',
      stalePeriod: const Duration(days: 365),
      // Headroom past the ~1800-word roadmap target for the full 45
      // categories, so a fully-populated library doesn't start evicting.
      maxNrOfCacheObjects: 2000,
    ),
  );
}
