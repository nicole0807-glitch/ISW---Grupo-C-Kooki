import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KookiRemoteImage extends StatefulWidget {
  final String? imageUrl;
  final String? bucketHint;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final bool bustCache;
  final Color? color;
  final BlendMode? colorBlendMode;

  const KookiRemoteImage({
    super.key,
    required this.imageUrl,
    this.bucketHint,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.bustCache = false,
    this.color,
    this.colorBlendMode,
  });

  static String? resolveUrl(
    String? imageUrl, {
    String? bucketHint,
    bool bustCache = false,
  }) {
    final candidates = buildCandidates(
      imageUrl,
      bucketHint: bucketHint,
      bustCache: bustCache,
    );
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  static List<String> buildCandidates(
    String? imageUrl, {
    String? bucketHint,
    bool bustCache = false,
  }) {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final candidates = <String>[];

    void addCandidate(String? url) {
      if (url == null || url.trim().isEmpty) {
        return;
      }

      final withCache = _appendCacheBust(url.trim(), bustCache);
      if (!candidates.contains(withCache)) {
        candidates.add(withCache);
      }
    }

    addCandidate(raw);

    final encoded = Uri.encodeFull(raw);
    if (encoded != raw) {
      addCandidate(encoded);
    }

    for (final storageUrl in _resolveStorageUrls(raw, bucketHint: bucketHint)) {
      addCandidate(storageUrl);
    }

    return candidates;
  }

  static List<String> _resolveStorageUrls(String raw, {String? bucketHint}) {
    final urls = <String>[];

    void addPublicUrl(String bucket, String path) {
      final cleanedPath = path.replaceFirst(RegExp(r'^/+'), '');
      if (cleanedPath.isEmpty) {
        return;
      }
      final publicUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(cleanedPath);
      if (!urls.contains(publicUrl)) {
        urls.add(publicUrl);
      }
    }

    final directBucketMatch = RegExp(
      r'^(avatars|recipe_images)/(.+)$',
    ).firstMatch(raw);
    if (directBucketMatch != null) {
      addPublicUrl(directBucketMatch.group(1)!, directBucketMatch.group(2)!);
    }

    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final segments = uri.pathSegments.map(Uri.decodeComponent).toList();
      final storageIndex = _findPublicStorageIndex(segments);
      if (storageIndex != -1 && segments.length > storageIndex + 1) {
        final bucket = segments[storageIndex];
        final path = segments.skip(storageIndex + 1).join('/');
        addPublicUrl(bucket, path);
      }
    }

    if (bucketHint != null && !raw.contains('://')) {
      final path = raw.startsWith('$bucketHint/')
          ? raw.substring(bucketHint.length + 1)
          : raw;
      addPublicUrl(bucketHint, path);
    }

    return urls;
  }

  static int _findPublicStorageIndex(List<String> segments) {
    for (var i = 0; i <= segments.length - 4; i++) {
      if (segments[i] == 'storage' &&
          segments[i + 1] == 'v1' &&
          segments[i + 2] == 'object' &&
          segments[i + 3] == 'public') {
        return i + 4;
      }
    }
    return -1;
  }

  static String _appendCacheBust(String url, bool bustCache) {
    if (!bustCache) {
      return url;
    }

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  State<KookiRemoteImage> createState() => _KookiRemoteImageState();
}

class _KookiRemoteImageState extends State<KookiRemoteImage> {
  late List<String> _candidates;
  int _currentIndex = 0;
  bool _queuedAdvance = false;

  @override
  void initState() {
    super.initState();
    _resetCandidates();
  }

  @override
  void didUpdateWidget(covariant KookiRemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.bucketHint != widget.bucketHint ||
        oldWidget.bustCache != widget.bustCache) {
      _resetCandidates();
    }
  }

  void _resetCandidates() {
    _candidates = KookiRemoteImage.buildCandidates(
      widget.imageUrl,
      bucketHint: widget.bucketHint,
      bustCache: widget.bustCache,
    );
    _currentIndex = 0;
    _queuedAdvance = false;
  }

  void _tryNextCandidate() {
    if (_queuedAdvance || _currentIndex >= _candidates.length - 1) {
      return;
    }

    _queuedAdvance = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentIndex++;
        _queuedAdvance = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) {
      return _buildPlaceholder(context);
    }

    return Image.network(
      _candidates[_currentIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _buildPlaceholder(context, isLoading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        if (_currentIndex < _candidates.length - 1) {
          _tryNextCandidate();
          return _buildPlaceholder(context, isLoading: true);
        }
        return _buildPlaceholder(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, {bool isLoading = false}) {
    if (widget.placeholder != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            )
          : Icon(
              Icons.image_outlined,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
    );
  }
}
