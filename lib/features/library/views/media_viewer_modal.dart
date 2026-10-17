import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/media_item.dart';
import '../../../shared/widgets/audio_waveform_player.dart';

class MediaViewerModal extends StatefulWidget {
  final MediaItem item;
  final VoidCallback? onDelete;

  const MediaViewerModal({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  State<MediaViewerModal> createState() => _MediaViewerModalState();
}

class _MediaViewerModalState extends State<MediaViewerModal> {
  bool _isSaving = false;

  Future<void> _handleDownload() async {
    if (_isSaving) return;
    if (widget.item.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media URL is not available'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading media...'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final isImage = widget.item.type.toLowerCase() == 'image';
      final isVideo = widget.item.type.toLowerCase() == 'video';

      bool? saved = false;
      if (isImage) {
        saved = await GallerySaver.saveImage(widget.item.url, albumName: 'EzboAI');
      } else if (isVideo) {
        saved = await GallerySaver.saveVideo(widget.item.url, albumName: 'EzboAI');
      }

      if (saved == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully saved to phone gallery!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Fallback to launching URL in browser/download manager
        final uri = Uri.parse(widget.item.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Media opened for download in browser'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          throw Exception('Cannot open download link');
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Fallback
      try {
        final uri = Uri.parse(widget.item.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download to Gallery',
            onPressed: _isSaving ? null : _handleDownload,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Share',
            onPressed: () {
              if (widget.item.url.isNotEmpty) {
                Share.share('Check out this creation generated with EzboAI: ${widget.item.url}');
              }
            },
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Delete',
              onPressed: () {
                widget.onDelete!();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Media Presentation
          Expanded(
            child: Center(
              child: widget.item.type == 'image'
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        imageUrl: widget.item.url,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          size: 60,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: AudioWaveformPlayer(
                        audioUrl: widget.item.url,
                        title: widget.item.prompt ?? 'Audio Generation',
                      ),
                    ),
            ),
          ),

          // Metadata Drawer Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.prompt != null && widget.item.prompt!.isNotEmpty) ...[
                    const Text('Prompt', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.prompt!,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (widget.item.model != null) ...[
                        _buildBadge(Icons.auto_awesome, widget.item.model!),
                        const SizedBox(width: 8),
                      ],
                      if (widget.item.aspectRatio != null) ...[
                        _buildBadge(Icons.aspect_ratio, widget.item.aspectRatio!),
                        const SizedBox(width: 8),
                      ],
                      _buildBadge(Icons.category_outlined, widget.item.type.toUpperCase()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
