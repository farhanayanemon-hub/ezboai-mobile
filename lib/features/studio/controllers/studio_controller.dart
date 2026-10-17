import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/media_item.dart';
import '../../auth/controllers/auth_controller.dart';

const _uuid = Uuid();
String _generateId() => _uuid.v4();

class StudioState {
  final bool isGenerating;
  final String? error;
  final MediaItem? lastGeneratedItem;
  final List<MediaItem> recentGenerations;
  final String? transcribedText;
  final String? voiceChangeAudioUrl;

  const StudioState({
    this.isGenerating = false,
    this.error,
    this.lastGeneratedItem,
    this.recentGenerations = const [],
    this.transcribedText,
    this.voiceChangeAudioUrl,
  });

  StudioState copyWith({
    bool? isGenerating,
    String? error,
    MediaItem? lastGeneratedItem,
    List<MediaItem>? recentGenerations,
    String? transcribedText,
    String? voiceChangeAudioUrl,
    bool clearError = false,
  }) {
    return StudioState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      lastGeneratedItem: lastGeneratedItem ?? this.lastGeneratedItem,
      recentGenerations: recentGenerations ?? this.recentGenerations,
      transcribedText: transcribedText ?? this.transcribedText,
      voiceChangeAudioUrl: voiceChangeAudioUrl ?? this.voiceChangeAudioUrl,
    );
  }
}

class StudioNotifier extends StateNotifier<StudioState> {
  final ApiClient _api = ApiClient();
  final Ref _ref;

  StudioNotifier(this._ref) : super(const StudioState());

  // 1. Generate Image
  Future<bool> generateImage({
    required String prompt,
    String? negativePrompt,
    String model = 'black-forest-labs/flux-schnell',
    String aspectRatio = '1:1',
    String style = 'realistic',
    String quality = 'standard',
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.imageGeneration,
        data: {
          'prompt': prompt.trim(),
          if (negativePrompt != null && negativePrompt.trim().isNotEmpty)
            'negativePrompt': negativePrompt.trim(),
          'model': model,
          'size': aspectRatio == '16:9'
              ? '1024x576'
              : aspectRatio == '9:16'
                  ? '576x1024'
                  : aspectRatio == '4:3'
                      ? '1024x768'
                      : '1024x1024',
          'style': style,
          'quality': quality,
          'stream': false,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String imageUrl = '';
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          imageUrl = data['images'][0]['url'] ?? '';
        } else if (data['url'] != null) {
          imageUrl = data['url'];
        }

        final item = MediaItem(
          id: data['id'] ?? data['imageId'] ?? _generateId(),
          type: 'image',
          url: imageUrl,
          prompt: prompt,
          model: model,
          aspectRatio: aspectRatio,
        );

        state = state.copyWith(
          isGenerating: false,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Image generation failed: ${e.toString()}');
    }
    state = state.copyWith(isGenerating: false);
    return false;
  }

  // 2. Generate Video (Text-to-Video and Image-to-Video)
  Future<bool> generateVideo({
    required String prompt,
    String model = 'luma/ray-2',
    int duration = 5,
    String aspectRatio = '16:9',
    String? imageUrl,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.videoGeneration,
        data: {
          'prompt': prompt.trim(),
          'model': model,
          'duration': duration,
          'aspectRatio': aspectRatio,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final item = MediaItem(
          id: data['videoId'] ?? data['id'] ?? _generateId(),
          type: 'video',
          url: data['videoUrl'] ?? data['url'] ?? '',
          prompt: prompt,
          model: model,
          aspectRatio: aspectRatio,
        );

        state = state.copyWith(
          isGenerating: false,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Video generation failed');
    }
    state = state.copyWith(isGenerating: false);
    return false;
  }

  // 3. Generate Music
  Future<bool> generateMusic({
    required String prompt,
    String? genre,
    String? mood,
    int? musicLengthMs,
    bool forceInstrumental = false,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      String fullPrompt = prompt.trim();
      if (genre != null && genre.isNotEmpty) fullPrompt += ', Genre: $genre';
      if (mood != null && mood.isNotEmpty) fullPrompt += ', Mood: $mood';

      final response = await _api.post(
        ApiEndpoints.musicGeneration,
        data: {
          'prompt': fullPrompt,
          'musicLengthMs': musicLengthMs,
          'forceInstrumental': forceInstrumental,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final item = MediaItem(
          id: data['musicId'] ?? data['id'] ?? _generateId(),
          type: 'music',
          url: data['audioUrl'] ?? data['url'] ?? '',
          prompt: fullPrompt,
          durationMs: data['durationMs'],
        );

        state = state.copyWith(
          isGenerating: false,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Music generation failed');
    }
    state = state.copyWith(isGenerating: false);
    return false;
  }

  // 4. Generate Sound Effects
  Future<bool> generateSoundEffect({
    required String text,
    double? durationSeconds,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.soundEffectsGeneration,
        data: {
          'text': text.trim(),
          if (durationSeconds != null) 'durationSeconds': durationSeconds,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final item = MediaItem(
          id: data['id'] ?? _generateId(),
          type: 'sound_effect',
          url: data['audioUrl'] ?? data['url'] ?? '',
          prompt: text,
        );

        state = state.copyWith(
          isGenerating: false,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Sound effect generation failed');
    }
    state = state.copyWith(isGenerating: false);
    return false;
  }

  // 5. Text to Speech (TTS)
  Future<bool> generateSpeech({
    required String text,
    String voiceId = '21m00Tcm4TlvDq8ikWAM', // Rachel
    String model = 'eleven_multilingual_v2',
    double speed = 1.0,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.audioGeneration,
        data: {
          'text': text.trim(),
          'voiceId': voiceId,
          'model': model,
          'speed': speed,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final item = MediaItem(
          id: data['audioId'] ?? data['id'] ?? _generateId(),
          type: 'audio',
          url: data['audioUrl'] ?? data['url'] ?? '',
          prompt: text,
        );

        state = state.copyWith(
          isGenerating: false,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Speech generation failed');
    }
    state = state.copyWith(isGenerating: false);
    return false;
  }

  // 6. Speech to Text (STT)
  Future<String?> transcribeAudio(String filePath) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'modelId': 'scribe_v1',
      });

      final response = await _api.post(
        ApiEndpoints.audioTranscription,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final text = response.data['text'] as String? ?? '';
        state = state.copyWith(isGenerating: false, transcribedText: text);
        _ref.read(authProvider.notifier).refreshProfile();
        return text;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Transcription failed');
    }
    state = state.copyWith(isGenerating: false);
    return null;
  }

  // 7. Voice Changer
  Future<String?> changeVoice({
    required String filePath,
    required String targetVoiceId,
    String modelId = 'eleven_multilingual_sts_v2',
    bool removeBackgroundNoise = true,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'targetVoiceId': targetVoiceId,
        'modelId': modelId,
        'removeBackgroundNoise': removeBackgroundNoise.toString(),
      });

      final response = await _api.post(
        ApiEndpoints.voiceChange,
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final audioUrl = response.data['audioUrl'] as String? ?? '';
        final item = MediaItem(
          id: response.data['voiceChangeId'] ?? _generateId(),
          type: 'audio',
          url: audioUrl,
          prompt: 'Voice converted to $targetVoiceId',
        );

        state = state.copyWith(
          isGenerating: false,
          voiceChangeAudioUrl: audioUrl,
          lastGeneratedItem: item,
          recentGenerations: [item, ...state.recentGenerations],
        );
        _ref.read(authProvider.notifier).refreshProfile();
        return audioUrl;
      }
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Voice change failed');
    }
    state = state.copyWith(isGenerating: false);
    return null;
  }
}

final studioProvider = StateNotifierProvider<StudioNotifier, StudioState>((ref) {
  return StudioNotifier(ref);
});
