import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:healora/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/video_model.dart';
import '../controllers/video_series_controller.dart';

class VideoSeriesScreen extends StatefulWidget {
  const VideoSeriesScreen({super.key});

  @override
  State<VideoSeriesScreen> createState() => _VideoSeriesScreenState();
}

class _VideoSeriesScreenState extends State<VideoSeriesScreen> {
  final controller = Get.put(VideoSeriesController());

  Color _topicColor(String? hex, {Color fallback = AppColors.teal}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      var value = hex.replaceAll('#', '');
      if (value.length == 6) value = 'FF$value';
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Immersive Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.bgNavy,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.teal),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.play_circle_filled, size: 200, color: Colors.white.withOpacity(0.05)),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health', style: AppTextStyles.heading2.copyWith(color: Colors.white.withOpacity(0.6), fontSize: 28)),
                        Text('Video Library', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  // Bottom Curve
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.bgNavy,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky Search and Filters ─────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchFilterDelegate(
              child: Container(
                color: AppColors.bgNavy,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    McSearchBar(
                      hint: 'Search medical videos...',
                      controller: controller.searchCtrl,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: Obx(() {
                        if (controller.isTopicsLoading.value) return const SizedBox();
                        final selectedIdx = controller.selectedTopicIndex.value;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.topics.length + 1,
                          itemBuilder: (_, i) {
                            final isAll = i == 0;
                            final label = isAll ? 'All Videos' : controller.topics[i - 1].name;
                            final color = isAll ? AppColors.teal : _topicColor(controller.topics[i - 1].backgroundColor);
                            final sel = selectedIdx == i;
                            return GestureDetector(
                              onTap: () => controller.changeTopic(i),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel ? color : AppColors.bgCardNavy,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: sel ? color : AppColors.border.withOpacity(0.3)),
                                  boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                                ),
                                child: Text(label, style: AppTextStyles.captionBold.copyWith(color: sel ? Colors.white : AppColors.textMuted, fontSize: 13)),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // ── Video List ───────────────────────────────────────────────────
          Obx(() {
            if (controller.isVideoLoading.value) {
              return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal)));
            }
            final list = controller.filteredVideos;
            if (list.isEmpty) {
              return const SliverFillRemaining(child: Center(child: Text('No videos found', style: TextStyle(color: Colors.white54))));
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final v = list[i];
                    final color = _topicColor("0xFF1B9E8E");
                    return _VideoTile(
                      video: v, 
                      themeColor: color, 
                      onTap: () => _openPlayer(context, v, color)
                    );
                  },
                  childCount: list.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, VideoModel video, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
          color: color,
          controller: controller,
        ),
      ),
    );
  }
}

class _StickySearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySearchFilterDelegate({required this.child});
  @override Widget build(context, shrinkOffset, overlapsContent) => child;
  @override double get maxExtent => 120;
  @override double get minExtent => 120;
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class _VideoTile extends StatelessWidget {
  final VideoModel video;
  final Color themeColor;
  final VoidCallback onTap;
  const _VideoTile({required this.video, required this.themeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(24),
          // Premium Accent Border (Same as Reminders)
          border: Border(
            left: BorderSide(color: themeColor, width: 4),
            top: BorderSide(color: themeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area
            Stack(
              children: [
                Hero(
                  tag: 'video_${video.videoId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 16/9,
                      child: video.thumbnail != null && video.thumbnail!.isNotEmpty
                          ? Image.network(video.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                ),
                // Play Icon Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 60)),
                  ),
                ),
                // Duration Badge
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                    child: Text(video.formattedDuration, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            // Info Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: themeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(video.topic.name.toUpperCase(), style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                      const Spacer(),
                      const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(video.formattedViews, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(video.title, style: AppTextStyles.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(video.presenterName, style: AppTextStyles.caption.copyWith(color: AppColors.teal, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(color: AppColors.teal.withOpacity(0.1), child: const Center(child: Icon(Icons.movie_filter_rounded, color: AppColors.teal, size: 40)));
}

// ── Video Player Screen (also opened from Home Learn rail) ───────────────────
class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final Color color;
  final VideoSeriesController controller;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.color,
    required this.controller,
  });

  /// Open player from Home / anywhere — ensures VideoSeriesController exists.
  static Future<void> open(VideoModel video, {Color? color}) {
    final c = Get.isRegistered<VideoSeriesController>()
        ? Get.find<VideoSeriesController>()
        : Get.put(VideoSeriesController());
    Color theme = color ?? AppColors.teal;
    final hex = video.topic.backgroundColor;
    if (hex.isNotEmpty) {
      try {
        var value = hex.replaceAll('#', '');
        if (value.length == 6) value = 'FF$value';
        theme = Color(int.parse(value, radix: 16));
      } catch (_) {}
    }
    return Get.to(
          () => VideoPlayerScreen(
            video: video,
            color: theme,
            controller: c,
          ),
          transition: Transition.fadeIn,
        ) ??
        Future.value();
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _playerController;
  WebViewController? _webController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isWebVideo = false;
  String? _errorMessage;
  late bool _isLiked = widget.video.isLiked;
  late bool _isBookmarked = widget.video.isBookmarked;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  /// Chrome 91 Mobile — newer Chrome WebViews pick WebGPU and fail on
  /// GPUs with no adapter (PowerVR Rogue, "No available adapters").
  static const _chromeMobileUa =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';

  bool _isYoutube(String url) {
    final u = url.toLowerCase();
    return u.contains('youtube.com') || u.contains('youtu.be');
  }

  bool _isVimeo(String url) => url.toLowerCase().contains('vimeo.com');

  bool _isFacebook(String url) {
    final u = url.toLowerCase();
    return u.contains('facebook.com') ||
        u.contains('fb.watch') ||
        u.contains('fb.com/');
  }

  bool _isDirectMedia(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    return path.contains('.mp4') ||
        path.contains('.m3u8') ||
        path.contains('.mov') ||
        path.contains('.webm');
  }

  String? _youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return id.isEmpty ? null : id.split('.').first;
    }
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final parts = uri.pathSegments;
    final embedIdx = parts.indexOf('embed');
    if (embedIdx >= 0 && embedIdx + 1 < parts.length) return parts[embedIdx + 1];
    final shortsIdx = parts.indexOf('shorts');
    if (shortsIdx >= 0 && shortsIdx + 1 < parts.length) {
      return parts[shortsIdx + 1];
    }
    return null;
  }

  String? _vimeoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    for (final p in uri.pathSegments.reversed) {
      if (RegExp(r'^\d+$').hasMatch(p)) return p;
    }
    return null;
  }

  String _iframePage({required String src, required String title}) {
    final safeSrc = src.replaceAll('"', '%22');
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<title>$title</title>
<style>
html,body,.box{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden}
iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
</style>
<script>
try {
  Object.defineProperty(navigator, 'gpu', {
    configurable: true,
    get: function () { return undefined; }
  });
} catch (e) {}
</script>
</head>
<body>
<div class="box">
<iframe
  src="$safeSrc"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
  allowfullscreen
  playsinline></iframe>
</div>
</body>
</html>
''';
  }

  Future<WebViewController> _buildWebController() async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_chromeMobileUa)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            // Ads / CORS / lookaside images fail often — only fail the main frame.
            if (error.isForMainFrame != true) return;
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _errorMessage = 'Could not load video';
            });
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  Future<void> _initWebHtml(String html, String baseUrl) async {
    final controller = await _buildWebController();
    await controller.loadHtmlString(html, baseUrl: baseUrl);
    _webController = controller;
    _isWebVideo = true;
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _initWebUrl(String embedUrl) async {
    final controller = await _buildWebController();
    await controller.loadRequest(Uri.parse(embedUrl));
    _webController = controller;
    _isWebVideo = true;
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _initDirectPlayer(String url) async {
    _playerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _playerController!.initialize();
    await _playerController!.play();
    _playerController!.addListener(() {
      if (!mounted || _playerController == null) return;
      if (_playerController!.value.isPlaying) {
        final pos = _playerController!.value.position.inSeconds;
        if (pos % 5 == 0 && pos > 0) {
          widget.controller.updateProgress(widget.video.videoId, pos);
        }
      }
    });
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _openExternally() async {
    final raw = widget.video.videoUrl?.trim() ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _failOrOpen(String message) async {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  Future<void> _initPlayer() async {
    final url = widget.video.videoUrl?.trim() ?? '';
    if (url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video link available';
      });
      return;
    }

    try {
      if (_isYoutube(url)) {
        final id = _youtubeId(url);
        if (id == null || !RegExp(r'^[\w-]{6,}$').hasMatch(id)) {
          await _failOrOpen('Invalid YouTube link');
          return;
        }
        // youtube-nocookie + html5=1 avoids the WebGPU iframe path.
        final src =
            'https://www.youtube-nocookie.com/embed/$id?autoplay=1&playsinline=1&rel=0&modestbranding=1&fs=1&html5=1';
        await _initWebHtml(
          _iframePage(src: src, title: 'YouTube'),
          'https://www.youtube-nocookie.com',
        );
        return;
      }

      if (_isFacebook(url)) {
        final src =
            'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(url)}&show_text=false&autoplay=true';
        await _initWebHtml(
          _iframePage(src: src, title: 'Facebook'),
          'https://www.facebook.com',
        );
        return;
      }

      if (_isVimeo(url)) {
        final id = _vimeoId(url);
        if (id == null) {
          await _failOrOpen('Invalid Vimeo link');
          return;
        }
        await _initWebHtml(
          _iframePage(
            src: 'https://player.vimeo.com/video/$id?autoplay=1&playsinline=1',
            title: 'Vimeo',
          ),
          'https://player.vimeo.com',
        );
        return;
      }

      if (_isDirectMedia(url)) {
        await _initDirectPlayer(url);
        return;
      }

      // Unknown host — try native player, then WebView.
      try {
        await _initDirectPlayer(url);
      } catch (_) {
        await _initWebUrl(url);
      }
    } catch (_) {
      await _failOrOpen('Video playback error');
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Widget _buildPlayer() {
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Video playback error',
              style: AppTextStyles.body.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text(
                'Open in browser',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (!_isInitialized) {
      return const CircularProgressIndicator(color: AppColors.teal);
    }
    if (_isWebVideo && _webController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _webController!),
      );
    }
    if (_playerController != null) {
      return AspectRatio(
        aspectRatio: _playerController!.value.aspectRatio == 0
            ? 16 / 9
            : _playerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_playerController!),
            IconButton(
              iconSize: 56,
              color: Colors.white,
              icon: Icon(
                _playerController!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              onPressed: () {
                setState(() {
                  if (_playerController!.value.isPlaying) {
                    _playerController!.pause();
                  } else {
                    _playerController!.play();
                  }
                });
              },
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _buildPlayer()),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 120,
            child: Column(
              children: [
                _PlayerAction(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${widget.video.totalLikes}',
                  color: _isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() => _isLiked = !_isLiked);
                    widget.controller.toggleLike(widget.video);
                  },
                ),
                const SizedBox(height: 24),
                _PlayerAction(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  color: _isBookmarked ? AppColors.orange : Colors.white,
                  onTap: () {
                    setState(() => _isBookmarked = !_isBookmarked);
                    widget.controller.toggleBookmark(widget.video);
                  },
                ),
                const SizedBox(height: 24),
                _PlayerAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.white,
                  onTap: () => widget.controller.shareVideo(widget.video),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${widget.video.presenterName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (_isInitialized &&
                      !_isWebVideo &&
                      _playerController != null) ...[
                    const SizedBox(height: 24),
                    VideoProgressIndicator(
                      _playerController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.teal,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PlayerAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Column(children: [Icon(icon, color: color, size: 34), const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]));
  }
}
