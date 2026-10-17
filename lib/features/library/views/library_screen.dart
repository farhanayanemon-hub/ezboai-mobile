import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/media_item.dart';
import '../controllers/library_controller.dart';
import 'media_viewer_modal.dart';
import '../../chat/views/chat_drawer.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libState = ref.watch(libraryProvider);
    final filter = libState.activeFilter;
    final query = _searchController.text.trim().toLowerCase();

    final filteredItems = libState.items.where((i) {
      if (query.isEmpty) return true;
      final promptMatch = i.prompt?.toLowerCase().contains(query) ?? false;
      final modelMatch = i.model?.toLowerCase().contains(query) ?? false;
      return promptMatch || modelMatch;
    }).toList();

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Central Library', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search library creations...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                {'label': 'All', 'key': 'all'},
                {'label': 'Images', 'key': 'images'},
                {'label': 'Videos', 'key': 'videos'},
                {'label': 'Music', 'key': 'music'},
                {'label': 'Voice / TTS', 'key': 'audio'},
                {'label': 'Sound Effects', 'key': 'sound_effects'},
              ].map((f) {
                final isSelected = filter == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f['label']!),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (val) {
                      if (val) ref.read(libraryProvider.notifier).setFilter(f['key']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),

          // Grid / List
          Expanded(
            child: libState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 50, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No media items found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => ref.read(libraryProvider.notifier).loadLibrary(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildMediaTile(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTile(MediaItem item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MediaViewerModal(
                item: item,
                onDelete: () => ref.read(libraryProvider.notifier).deleteItem(item),
              ),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content
            if (item.type == 'image')
              CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
              )
            else
              Container(
                color: AppColors.surfaceElevated,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.type == 'music'
                          ? Icons.music_note_rounded
                          : item.type == 'video'
                              ? Icons.videocam_rounded
                              : Icons.graphic_eq_rounded,
                      size: 38,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.prompt ?? item.type.toUpperCase(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            // Top badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
