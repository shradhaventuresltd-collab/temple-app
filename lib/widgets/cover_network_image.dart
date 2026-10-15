import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/utils/cover_thumb.dart';

/// List-card image. [url] is tried first. On failure, [fallbackUrl] is
/// requested once. A second failure shows [error].
///
/// When [fallbackUrl] is omitted, a `_480_g` Storage thumb falls back to the
/// public URL of its original. That original is readable under the same
/// Storage rule as the thumb. A Wikimedia `/thumb/` URL falls back to the
/// original file, including a `thumb.wikimedia.org` host rewritten to
/// `upload.wikimedia.org`.
class CoverNetworkImage extends StatelessWidget {
  const CoverNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    required this.error,
    this.fallbackUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheManager,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  final String url;
  final String? fallbackUrl;
  final Widget placeholder;
  final Widget error;
  final double? height;
  final double? width;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// Disk cache. Defaults to the shared directory cache (1,000 objects).
  final BaseCacheManager? cacheManager;
  final Duration fadeInDuration;

  String? get _fallback {
    final known = fallbackUrl?.trim() ?? '';
    if (known.startsWith('https://') && known != url) return known;
    final derived = fullCoverUrlFromThumb(url) ?? wikimediaOriginalUrl(url);
    if (derived != null && derived != url) return derived;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _fallback;
    final manager = cacheManager ?? ClientCache.images;
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      cacheManager: manager,
      fadeInDuration: fadeInDuration,
      placeholder: (context, imageUrl) => placeholder,
      errorWidget: (context, failedUrl, failure) {
        if (next == null) return error;
        return CachedNetworkImage(
          imageUrl: next,
          height: height,
          width: width,
          fit: fit,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          cacheManager: manager,
          fadeInDuration: fadeInDuration,
          placeholder: (context, imageUrl) => placeholder,
          errorWidget: (context, imageUrl, secondFailure) => error,
        );
      },
    );
  }
}
