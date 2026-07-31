import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => _VideoPlayerScreen(video: video, color: color, controller: controller)));
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

// ── Improved Video Player Screen ──────────────────────────────────────────────
class _VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final Color color;
  final VideoSeriesController controller;
  const _VideoPlayerScreen({required this.video, required this.color, required this.controller});
  @override State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _playerController;
  bool _isInitialized = false;
  bool _hasError = false;
  late bool _isLiked = widget.video.isLiked;
  late bool _isBookmarked = widget.video.isBookmarked;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.video.videoUrl;
    if (url == null || url.isEmpty) { setState(() => _hasError = true); return; }
    try {
      _playerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _playerController!.initialize();
      _playerController!.play();
      setState(() => _isInitialized = true);
      _playerController!.addListener(() {
        if (mounted && _playerController != null && _playerController!.value.isPlaying) {
          final pos = _playerController!.value.position.inSeconds;
          if (pos % 5 == 0 && pos > 0) widget.controller.updateProgress(widget.video.videoId, pos);
        }
      });
    } catch (e) { setState(() => _hasError = true); }
  }

  @override
  void dispose() { _playerController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _hasError ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16), Text('Video playback error', style: AppTextStyles.body.copyWith(color: Colors.white))])
                : !_isInitialized ? const CircularProgressIndicator(color: AppColors.teal)
                : AspectRatio(aspectRatio: _playerController!.value.aspectRatio, child: VideoPlayer(_playerController!)),
          ),
          
          // Custom Controls Overlays
          Positioned(top: 40, left: 20, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back()))),
          
          // Action Sidebar
          Positioned(
            right: 20, bottom: 120,
            child: Column(
              children: [
                _PlayerAction(icon: _isLiked ? Icons.favorite : Icons.favorite_border, label: '${widget.video.totalLikes}', color: _isLiked ? Colors.red : Colors.white, onTap: () { setState(() => _isLiked = !_isLiked); widget.controller.toggleLike(widget.video); }),
                const SizedBox(height: 24),
                _PlayerAction(icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border, label: 'Save', color: _isBookmarked ? AppColors.orange : Colors.white, onTap: () { setState(() => _isBookmarked = !_isBookmarked); widget.controller.toggleBookmark(widget.video); }),
                const SizedBox(height: 24),
                _PlayerAction(icon: Icons.share_outlined, label: 'Share', color: Colors.white, onTap: () => widget.controller.shareVideo(widget.video)),
              ],
            ),
          ),

          // Title & Progress
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.95), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.video.title, style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('by ${widget.video.presenterName}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 24),
                  if (_isInitialized) VideoProgressIndicator(_playerController!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppColors.teal, bufferedColor: Colors.white24, backgroundColor: Colors.white10)),
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
