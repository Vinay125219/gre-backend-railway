import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/theme/theme.dart';

// Conditional import for web
import 'video_player_web.dart' if (dart.library.io) 'video_player_stub.dart';

/// Video Player Screen for YouTube videos
/// Uses native player on mobile, opens in browser on web
class VideoPlayerScreen extends StatefulWidget {
  final String materialId;
  final String title;
  final String url;

  const VideoPlayerScreen({
    super.key,
    required this.materialId,
    required this.title,
    required this.url,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  VideoPlayerController? _fileController;
  bool _isPlayerReady = false;
  bool _isFileReady = false;
  Duration _savedPosition = Duration.zero;
  bool _hasRestoredPosition = false;
  String? _iframeViewType;
  bool _isYouTube = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();

    _videoId = YoutubePlayer.convertUrlToId(widget.url);
    _isYouTube = _videoId != null && _videoId!.isNotEmpty;

    if (_isYouTube) {
      if (kIsWeb) {
        _iframeViewType = 'youtube-player-${widget.materialId}';
        registerYouTubeIframe(_iframeViewType!, _videoId!);
      } else {
        _controller = YoutubePlayerController(
          initialVideoId: _videoId!,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            forceHD: false,
          ),
        );
        _controller!.addListener(_onPlayerStateChange);
      }
    } else {
      _initFilePlayer();
    }
  }

  Future<void> _initFilePlayer() async {
    try {
      final uri = Uri.parse(widget.url);
      _fileController = VideoPlayerController.networkUrl(uri);
      await _fileController!.initialize();
      if (!mounted) return;
      setState(() {
        _isFileReady = true;
      });
      if (_savedPosition.inSeconds > 5) {
        _fileController!.seekTo(_savedPosition);
      }
      await _fileController!.play();
      _fileController!.addListener(_onFileStateChange);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFileReady = false;
      });
    }
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds =
        prefs.getInt('video_progress_${widget.materialId}') ?? 0;
    setState(() {
      _savedPosition = Duration(seconds: savedSeconds);
    });
  }

  void _onPlayerStateChange() {
    if (!mounted || _controller == null) return;

    if (_isPlayerReady) {
      // Save progress every time the listener fires
      _saveProgress(_controller!.value.position);

      // Restore position once when player is ready
      if (!_hasRestoredPosition && _savedPosition.inSeconds > 5) {
        _hasRestoredPosition = true;
        _controller!.seekTo(_savedPosition);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resuming from ${_formatDuration(_savedPosition)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onFileStateChange() {
    if (!mounted || _fileController == null) return;
    if (_fileController!.value.isInitialized) {
      _saveProgress(_fileController!.value.position);
    }
  }

  Future<void> _saveProgress(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'video_progress_${widget.materialId}',
      position.inSeconds,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    _fileController?.removeListener(_onFileStateChange);
    _fileController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _isYouTube ? _buildWebPlayer() : _buildFilePlayer();
    }

    return _isYouTube ? _buildMobilePlayer() : _buildFilePlayer();
  }

  Widget _buildWebPlayer() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInBrowser,
            tooltip: 'Open in YouTube',
          ),
        ],
      ),
      body: Column(
        children: [
          // Embedded YouTube Player using iframe
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              clipBehavior: Clip.hardEdge,
              child: _iframeViewType != null
                  ? HtmlElementView(viewType: _iframeViewType!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),

          // Content below video
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  final notes = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Notes', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Take notes while watching...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: notes),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  'Tip: Use timestamps in your notes to review key moments quickly.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        notes,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePlayer() {
    final controller = _fileController;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInBrowser,
            tooltip: 'Open',
          ),
        ],
      ),
      body: controller == null || !_isFileReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.border,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMobilePlayer() {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primaryLight,
          bufferedColor: AppColors.primaryContainer,
          backgroundColor: AppColors.border,
        ),
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (metaData) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video completed!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
              style: AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Column(
            children: [
              player,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;

                      final shortcuts = Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keyboard Shortcuts',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildShortcutItem('Space', 'Play / Pause'),
                            _buildShortcutItem('←/→', 'Seek 5 seconds'),
                            _buildShortcutItem('↑/↓', 'Volume'),
                            _buildShortcutItem('F', 'Fullscreen'),
                          ],
                        ),
                      );

                      final notes = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Notes', style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'Take notes while watching...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: AppTextStyles.titleLarge),
                          const SizedBox(height: AppSpacing.sm),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: shortcuts),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: notes),
                              ],
                            )
                          else ...[
                            shortcuts,
                            const SizedBox(height: AppSpacing.lg),
                            notes,
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutItem(String key, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              key,
              style: AppTextStyles.labelSmall.copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(action, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
