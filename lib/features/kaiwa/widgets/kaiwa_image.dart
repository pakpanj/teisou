import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../../core/services/kaiwa_image_cache.dart';
import '../../../core/theme/app_palette.dart';

/// Renders a Kaiwa NPC-line illustration fetched on-demand from Firebase
/// Storage, cached to disk permanently after the first download via
/// [KaiwaImageCache]. Falls back to a pastel speech-bubble placeholder if
/// [imagePath] is null, the file doesn't exist in Storage yet (404), or the
/// download otherwise fails — mirrors `KotobaImage` exactly, same "never
/// crash, never show Flutter's broken-image icon" contract.
class KaiwaImage extends StatefulWidget {
  final String? imagePath;
  final double size;
  final BorderRadius borderRadius;

  const KaiwaImage({
    super.key,
    required this.imagePath,
    this.size = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<KaiwaImage> createState() => _KaiwaImageState();
}

class _KaiwaImageState extends State<KaiwaImage> {
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
  void didUpdateWidget(covariant KaiwaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      setState(() {
        _urlFuture = _resolveUrl();
      });
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
              return _Placeholder(size: widget.size, loading: true);
            }
            final url = snapshot.data;
            if (url == null) {
              return _Placeholder(size: widget.size);
            }
            return CachedNetworkImage(
              imageUrl: url,
              cacheManager: KaiwaImageCache.instance,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
              placeholder: (context, url) =>
                  _Placeholder(size: widget.size, loading: true),
              errorWidget: (context, url, error) =>
                  _Placeholder(size: widget.size),
            );
          },
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final bool loading;

  const _Placeholder({required this.size, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.hiraganaCardBg,
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: size * 0.14,
              height: size * 0.14,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text('💬', style: TextStyle(fontSize: size * 0.32)),
    );
  }
}
