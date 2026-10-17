import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';

class AudioWaveformPlayer extends StatefulWidget {
  final String audioUrl;
  final String? title;
  final VoidCallback? onDownload;

  const AudioWaveformPlayer({
    super.key,
    required this.audioUrl,
    this.title,
    this.onDownload,
  });

  @override
  State<AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<AudioWaveformPlayer> {
  late AudioPlayer _player;
  bool _isInit = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      String fullUrl = widget.audioUrl;
      if (fullUrl.startsWith('/')) {
        fullUrl = '${ApiEndpoints.baseUrl}$fullUrl';
      }
      await _player.setUrl(fullUrl);
      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Unable to load audio playback',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering ||
                      !_isInit) {
                    return const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      iconSize: 36,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _player.play,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      iconSize: 36,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _player.pause,
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.duration ?? Duration.zero;

                    return ProgressBar(
                      progress: position,
                      total: duration,
                      buffered: _player.bufferedPosition,
                      progressBarColor: AppColors.primary,
                      baseBarColor: AppColors.border,
                      bufferedBarColor: AppColors.surfaceElevated,
                      thumbColor: AppColors.primaryLight,
                      thumbRadius: 5,
                      timeLabelTextStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      onSeek: (duration) {
                        _player.seek(duration);
                      },
                    );
                  },
                ),
              ),
              if (widget.onDownload != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDownload,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
