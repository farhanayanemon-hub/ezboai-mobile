import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/media_item.dart';

class LibraryState {
  final List<MediaItem> items;
  final bool isLoading;
  final String activeFilter; // 'all', 'images', 'videos', 'audio', 'music', 'sound_effects'
  final String searchQuery;

  const LibraryState({
    this.items = const [],
    this.isLoading = false,
    this.activeFilter = 'all',
    this.searchQuery = '',
  });

  LibraryState copyWith({
    List<MediaItem>? items,
    bool? isLoading,
    String? activeFilter,
    String? searchQuery,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final ApiClient _api = ApiClient();

  LibraryNotifier() : super(const LibraryState()) {
    loadLibrary();
  }

  Future<void> loadLibrary([String? filter]) async {
    final effectiveFilter = filter ?? state.activeFilter;
    state = state.copyWith(isLoading: true, activeFilter: effectiveFilter);

    try {
      final queryParams = <String, dynamic>{};
      if (effectiveFilter != 'all') {
        queryParams['type'] = effectiveFilter;
      }

      final response = await _api.get(
        ApiEndpoints.library,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw = response.data['media'] ?? [];
        final parsed = raw.map((item) => MediaItem.fromJson(item)).toList();
        state = state.copyWith(items: parsed, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  void setFilter(String filter) {
    loadLibrary(filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> deleteItem(MediaItem item) async {
    try {
      String endpoint = '';
      if (item.type == 'image') endpoint = '${ApiEndpoints.images}/${item.id}';
      if (item.type == 'video') endpoint = '/api/videos/${item.id}';
      if (item.type == 'music') endpoint = '/api/music/${item.id}';
      if (item.type == 'audio') endpoint = '/api/audio/${item.id}';
      if (item.type == 'sound_effect') endpoint = '/api/sound-effects/${item.id}';

      if (endpoint.isNotEmpty) {
        await _api.delete(endpoint);
        state = state.copyWith(
          items: state.items.where((i) => i.id != item.id).toList(),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});
