import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Long-lived disk cache for on-demand Kaiwa dialogue illustrations, same
/// reasoning as `KotobaImageCache`: these images never change once
/// uploaded, so treating them as stale and re-downloading (the default
/// 30-day policy) would just waste bandwidth. A single static instance is
/// shared by every `KaiwaImage` so they all hit the same on-disk cache.
class KaiwaImageCache {
  KaiwaImageCache._();

  static final instance = CacheManager(
    Config(
      'kaiwaImageCache',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 500,
    ),
  );
}
