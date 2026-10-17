import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_model.dart';
import '../../../shared/widgets/audio_waveform_player.dart';
import 'code_block_view.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  final Future<void> Function()? onReadAloud;

  const ChatBubble({
    super.key,
    required this.message,
    required this.index,
    this.onReadAloud,
  });

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildAssistantBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, right: 12, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.userBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.userBubble.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attached images preview if any
            if (message.imageUrls.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.imageUrls.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img.startsWith('http')
                        ? Image.network(img, width: 90, height: 90, fit: BoxFit.cover)
                        : Image.file(File(img), width: 90, height: 90, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            // Content
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 40, top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Tag Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.model ?? 'EzboAI',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (message.isStreaming)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Message Body (Markdown)
          if (message.content.isEmpty && message.isStreaming)
            const Text(
              'Thinking...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            )
          else
            MarkdownBody(
              data: message.content,
              selectable: true,
              builders: {
                'code': CustomCodeElementBuilder(),
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.5),
                h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                code: const TextStyle(
                  backgroundColor: Color(0xFF202024),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.primaryLight,
                ),
                blockquote: const TextStyle(color: AppColors.textSecondary),
                blockquoteDecoration: BoxDecoration(
                  border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                  color: AppColors.background.withValues(alpha: 0.5),
                ),
              ),
            ),

          // Audio player if Read Aloud audio generated
          if (message.audioUrl != null) ...[
            const SizedBox(height: 12),
            AudioWaveformPlayer(
              audioUrl: message.audioUrl!,
              title: 'Audio Response',
            ),
          ],

          // Footer actions (Copy, Read Aloud)
          if (!message.isStreaming && message.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: AppColors.textMuted,
                  tooltip: 'Copy Message',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  onPressed: () => _copyContent(context),
                ),
                if (onReadAloud != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 18),
                    color: AppColors.textMuted,
                    tooltip: 'Read Aloud',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    onPressed: onReadAloud,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CustomCodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final code = element.textContent;
    return CodeBlockView(code: code, language: language);
  }
}
