import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../../core/services/kotoba_image_cache.dart';
import '../../../core/theme/app_colors.dart';

/// Renders a Kotoba vocab illustration fetched on-demand from Firebase
/// Storage, cached to disk permanently after the first download via
/// [KotobaImageCache]. Falls back to a pastel + category-icon placeholder
/// if [imagePath] is null, the file doesn't exist in Storage yet (404), or
/// the download otherwise fails — this widget never crashes and never
/// shows Flutter's broken-image icon.
class KotobaImage extends StatefulWidget {
  final String? imagePath;
  final String categoryIcon;
  final double size;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  const KotobaImage({
    super.key,
    required this.imagePath,
    required this.categoryIcon,
    this.size = 96,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor = AppColors.hiraganaCardBg,
  });

  @override
  State<KotobaImage> createState() => _KotobaImageState();
}

class _KotobaImageState extends State<KotobaImage> {
  late Future<String?> _urlFuture = _resolveUrl();

  Future<String?> _resolveUrl() async {
    final path = widget.imagePath;
    if (path == null) return null;
    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (_) {
      // Not uploaded yet (object-not-found) or any other Storage error —
      // both cases just fall back to the placeholder.
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant KotobaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      setState(() => _urlFuture = _resolveUrl());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<String?>(
          future: _urlFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _Placeholder(
                icon: widget.categoryIcon,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
                loading: true,
              );
            }
            final url = snapshot.data;
            if (url == null) {
              return _Placeholder(
                icon: widget.categoryIcon,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
              );
            }
            return CachedNetworkImage(
              imageUrl: url,
              cacheManager: KotobaImageCache.instance,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
              placeholder: (context, url) => _Placeholder(
                icon: widget.categoryIcon,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
                loading: true,
              ),
              errorWidget: (context, url, error) => _Placeholder(
                icon: widget.categoryIcon,
                size: widget.size,
                backgroundColor: widget.backgroundColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String icon;
  final double size;
  final Color backgroundColor;
  final bool loading;

  const _Placeholder({
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: size * 0.22,
              height: size * 0.22,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(icon, style: TextStyle(fontSize: size * 0.4)),
    );
  }
}
