import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../shell/nav_provider.dart';
import '../controllers/chat_controller.dart';

class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(ChatSession chat) {
    final controller = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref.read(chatProvider.notifier).renameChat(chat.id, newTitle);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ChatSession chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text('This conversation will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(chatProvider.notifier).deleteChat(chat.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportChat(ChatSession chat) {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('Model: ${chat.model}');
    buffer.writeln('Date: ${chat.createdAt.toLocal().toString().split('.')[0]}');
    buffer.writeln('---\n');

    for (final msg in chat.messages) {
      final sender = msg.isUser ? 'User' : (msg.model ?? 'EzboAI');
      buffer.writeln('### $sender:\n${msg.content}\n');
    }

    Share.share(
      buffer.toString(),
      subject: 'EzboAI Chat - ${chat.title}',
    );
  }

  void _branchChat(ChatSession chat) async {
    final branchIndex = chat.messages.isNotEmpty ? chat.messages.length - 1 : 0;
    final success = await ref.read(chatProvider.notifier).branchChat(chat.id, branchIndex);
    if (mounted) {
      Navigator.of(context).pop();
      if (success) {
        ref.read(shellNavIndexProvider.notifier).state = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat branched successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider).user;
    final currentNavIndex = ref.watch(shellNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final query = _searchController.text.trim().toLowerCase();
    final filteredList = chatState.chatList.where((c) {
      if (query.isEmpty) return true;
      return c.title.toLowerCase().contains(query);
    }).toList();

    final pinnedChats = filteredList.where((c) => c.pinned).toList();
    final otherChats = filteredList.where((c) => !c.pinned).toList();

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header: Brand & Close
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/branding/default-dark-logo.png'
                        : 'assets/branding/default-light-logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'EzboAI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Top-Level Navigation Menu (Replaces bottom navigation bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: [
                  _buildNavTile(
                    index: 0,
                    currentIndex: currentNavIndex,
                    title: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                  ),
                  _buildNavTile(
                    index: 1,
                    currentIndex: currentNavIndex,
                    title: 'AI Studio',
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome_rounded,
                  ),
                  _buildNavTile(
                    index: 2,
                    currentIndex: currentNavIndex,
                    title: 'Library',
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library_rounded,
                  ),
                  _buildNavTile(
                    index: 3,
                    currentIndex: currentNavIndex,
                    title: 'Projects',
                    icon: Icons.folder_open_outlined,
                    activeIcon: Icons.folder_rounded,
                  ),
                  _buildNavTile(
                    index: 4,
                    currentIndex: currentNavIndex,
                    title: 'Credits & Usage',
                    icon: Icons.bolt_rounded,
                    activeIcon: Icons.bolt_rounded,
                  ),
                  _buildNavTile(
                    index: 5,
                    currentIndex: currentNavIndex,
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // New Chat Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.card : AppColors.cardSecondaryLight,
                  foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                  side: BorderSide(color: theme.dividerColor),
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                onPressed: () {
                  ref.read(shellNavIndexProvider.notifier).state = 0;
                  ref.read(chatProvider.notifier).startNewChat();
                  Navigator.of(context).pop();
                },
              ),
            ),

            const SizedBox(height: 6),

            // Search History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Chat History Section
            Expanded(
              child: chatState.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredList.isEmpty
                      ? Center(
                          child: Text(
                            'No chats yet',
                            style: TextStyle(color: theme.hintColor, fontSize: 13),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          children: [
                            if (pinnedChats.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  'PINNED',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              ...pinnedChats.map((c) => _buildChatItem(c, isDark)),
                              const SizedBox(height: 8),
                            ],
                            if (otherChats.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  'RECENT',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              ...otherChats.map((c) => _buildChatItem(c, isDark)),
                            ],
                          ],
                        ),
            ),

            // User Profile Section at Bottom
            const Divider(height: 1),
            InkWell(
              onTap: () {
                ref.read(shellNavIndexProvider.notifier).state = 5; // Settings
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: ClipOval(
                        child: Builder(
                          builder: (ctx) {
                            final initial = (user?.name?.isNotEmpty == true
                                    ? user!.name![0]
                                    : (user?.email.isNotEmpty == true ? user!.email[0] : 'U'))
                                .toUpperCase();
                            if (user?.image != null && user!.image!.startsWith('data:image')) {
                              try {
                                final commaIdx = user.image!.indexOf(',');
                                final base64Data = commaIdx != -1 ? user.image!.substring(commaIdx + 1) : user.image!;
                                return Image.memory(base64Decode(base64Data), fit: BoxFit.cover);
                              } catch (_) {}
                            } else if (user?.image != null && user!.image!.startsWith('http')) {
                              return CachedNetworkImage(
                                imageUrl: user.image!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                                ),
                              );
                            }
                            return Center(
                              child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.name ?? 'EzboAI User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${user?.credits.total ?? 0}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required int index,
    required int currentIndex,
    required String title,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () {
        ref.read(shellNavIndexProvider.notifier).state = index;
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? AppColors.primary : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatSession chat, bool isDark) {
    final isSelected = ref.watch(chatProvider).currentChat?.id == chat.id;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: isSelected,
      selectedTileColor: isDark ? AppColors.card : AppColors.cardSecondaryLight,
      leading: Icon(
        chat.pinned
            ? Icons.push_pin_rounded
            : (chat.isBranch ? Icons.fork_right_rounded : Icons.chat_bubble_outline_rounded),
        size: 16,
        color: chat.pinned
            ? AppColors.warning
            : (chat.isBranch ? AppColors.secondaryLight : Theme.of(context).hintColor),
      ),
      title: Text(
        chat.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, size: 16, color: Theme.of(context).hintColor),
        onSelected: (val) {
          if (val == 'pin') {
            ref.read(chatProvider.notifier).pinChat(chat.id, !chat.pinned);
          } else if (val == 'rename') {
            _showRenameDialog(chat);
          } else if (val == 'branch') {
            _branchChat(chat);
          } else if (val == 'export') {
            _exportChat(chat);
          } else if (val == 'delete') {
            _confirmDelete(chat);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(chat.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 16),
                const SizedBox(width: 8),
                Text(chat.pinned ? 'Unpin' : 'Pin'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'branch',
            child: Row(
              children: [
                Icon(Icons.fork_right_rounded, size: 16),
                SizedBox(width: 8),
                Text('Branch Chat'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.share_outlined, size: 16),
                SizedBox(width: 8),
                Text('Export Chat'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        ref.read(shellNavIndexProvider.notifier).state = 0; // Go to chat
        ref.read(chatProvider.notifier).selectChat(chat.id);
        Navigator.of(context).pop();
      },
    );
  }
}
