import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/audio_waveform_player.dart';
import '../controllers/studio_controller.dart';
import '../../library/views/media_viewer_modal.dart';
import '../../chat/views/chat_drawer.dart';

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imagePicker = ImagePicker();

  // Image Tab
  final _imgPromptController = TextEditingController();
  final _imgNegativeController = TextEditingController();
  String _selectedImgModel = 'black-forest-labs/flux-schnell';
  String _selectedAspectRatio = '1:1';
  String _selectedStyle = 'realistic';
  final String _selectedQuality = 'standard';

  // Video Tab
  final _videoPromptController = TextEditingController();
  int _videoDuration = 5;
  String _videoAspectRatio = '16:9';
  bool _isImageToVideo = false;
  String? _videoSourceImagePath;

  // Music Tab
  final _musicPromptController = TextEditingController();
  String _selectedGenre = 'Lo-Fi';
  String _selectedMood = 'Chill';
  bool _forceInstrumental = false;

  // SFX Tab
  final _sfxPromptController = TextEditingController();
  double _sfxDuration = 5.0;

  // TTS Tab
  final _ttsTextController = TextEditingController();
  String _selectedVoice = '21m00Tcm4TlvDq8ikWAM'; // Rachel
  double _ttsSpeed = 1.0;

  // STT Tab
  String? _sttAudioFilePath;

  // Voice Changer Tab
  String? _voiceChangerSamplePath;
  String _targetVoiceId = '21m00Tcm4TlvDq8ikWAM';
  bool _removeNoise = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imgPromptController.dispose();
    _imgNegativeController.dispose();
    _videoPromptController.dispose();
    _musicPromptController.dispose();
    _sfxPromptController.dispose();
    _ttsTextController.dispose();
    super.dispose();
  }

  Future<void> _saveMediaToGallery(String url, String type) async {
    try {
      if (url.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading to gallery...'), duration: Duration(seconds: 1)),
      );

      bool? success;
      if (type == 'image') {
        success = await GallerySaver.saveImage(url, albumName: 'EzboAI');
      } else if (type == 'video') {
        success = await GallerySaver.saveVideo(url, albumName: 'EzboAI');
      }

      if (mounted) {
        if (success == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to device gallery!'), backgroundColor: AppColors.success),
          );
        } else {
          // Fallback to opening link
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (__) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioState = ref.watch(studioProvider);

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('AI Studio', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Images', icon: Icon(Icons.image_outlined, size: 20)),
            Tab(text: 'Videos', icon: Icon(Icons.videocam_outlined, size: 20)),
            Tab(text: 'Music', icon: Icon(Icons.music_note_outlined, size: 20)),
            Tab(text: 'SFX', icon: Icon(Icons.graphic_eq_rounded, size: 20)),
            Tab(text: 'Voice (TTS)', icon: Icon(Icons.record_voice_over_outlined, size: 20)),
            Tab(text: 'Speech to Text', icon: Icon(Icons.mic_none_rounded, size: 20)),
            Tab(text: 'Voice Changer', icon: Icon(Icons.transform_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImagesTab(studioState),
          _buildVideosTab(studioState),
          _buildMusicTab(studioState),
          _buildSfxTab(studioState),
          _buildTtsTab(studioState),
          _buildSttTab(studioState),
          _buildVoiceChangerTab(studioState),
        ],
      ),
    );
  }

  // 1. IMAGES TAB
  Widget _buildImagesTab(StudioState state) {
    final imageModels = [
      {'id': 'black-forest-labs/flux-schnell', 'name': 'Flux Schnell (Ultra Fast)'},
      {'id': 'stabilityai/stable-diffusion-xl-base-1.0', 'name': 'SDXL Base (High Fidelity)'},
      {'id': 'black-forest-labs/flux-dev', 'name': 'Flux Dev (Professional Quality)'},
    ];

    final styles = ['realistic', 'anime', 'cinematic', 'digital-art', '3d-render'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _imgPromptController,
            labelText: 'Image Prompt',
            hintText: 'A futuristic cybernetic tiger prowling neon Tokyo streets, 8k octane render...',
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _imgNegativeController,
            labelText: 'Negative Prompt (Optional)',
            hintText: 'blurry, low quality, distorted, extra limbs, watermark...',
            maxLines: 1,
          ),
          const SizedBox(height: 14),

          // Model Selector
          const Text('Model', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedImgModel,
                isExpanded: true,
                dropdownColor: AppColors.card,
                items: imageModels.map((m) {
                  return DropdownMenuItem(
                    value: m['id']!,
                    child: Text(m['name']!, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedImgModel = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Aspect Ratio chips
          const Text('Aspect Ratio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: ['1:1', '16:9', '9:16', '4:3'].map((ratio) {
              final isSelected = _selectedAspectRatio == ratio;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(ratio),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.card,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedAspectRatio = ratio);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Styles chips
          const Text('Style Preset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: styles.map((style) {
                final isSelected = _selectedStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(style.replaceAll('-', ' ').toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStyle = style);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: 'Generate Image',
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_imgPromptController.text.trim().isNotEmpty) {
                ref.read(studioProvider.notifier).generateImage(
                      prompt: _imgPromptController.text,
                      negativePrompt: _imgNegativeController.text,
                      model: _selectedImgModel,
                      aspectRatio: _selectedAspectRatio,
                      style: _selectedStyle,
                      quality: _selectedQuality,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          // Result preview
          if (state.lastGeneratedItem?.type == 'image') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Generated Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.primaryLight),
                      tooltip: 'Save to Gallery',
                      onPressed: () => _saveMediaToGallery(state.lastGeneratedItem!.url, 'image'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Share',
                      onPressed: () => Share.share(state.lastGeneratedItem!.url),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MediaViewerModal(item: state.lastGeneratedItem!),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: state.lastGeneratedItem!.url,
                  placeholder: (_, __) => Container(
                    height: 220,
                    color: AppColors.card,
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.card,
                    child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: AppColors.textMuted)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. VIDEOS TAB
  Widget _buildVideosTab(StudioState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Switch between Text to Video and Image to Video
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Text to Video')),
                  selected: !_isImageToVideo,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.card,
                  labelStyle: TextStyle(color: !_isImageToVideo ? Colors.white : AppColors.textSecondary),
                  onSelected: (val) {
                    if (val) setState(() => _isImageToVideo = false);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Image to Video')),
                  selected: _isImageToVideo,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.card,
                  labelStyle: TextStyle(color: _isImageToVideo ? Colors.white : AppColors.textSecondary),
                  onSelected: (val) {
                    if (val) setState(() => _isImageToVideo = true);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isImageToVideo) ...[
            InkWell(
              onTap: () async {
                final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _videoSourceImagePath = picked.path);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: _videoSourceImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_videoSourceImagePath!), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primaryLight),
                          SizedBox(height: 6),
                          Text('Select starting image frame', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          CustomTextField(
            controller: _videoPromptController,
            labelText: 'Motion / Video Prompt',
            hintText: 'Drone shot flying smoothly through emerald pine mountains at dawn with morning mist...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [3, 5, 10].map((d) {
                        final isSelected = _videoDuration == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('${d}s'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.card,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                            onSelected: (val) {
                              if (val) setState(() => _videoDuration = d);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aspect Ratio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['16:9', '9:16'].map((r) {
                        final isSelected = _videoAspectRatio == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(r),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.card,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                            onSelected: (val) {
                              if (val) setState(() => _videoAspectRatio = r);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: 'Generate Video',
            icon: const Icon(Icons.movie_creation_outlined, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_videoPromptController.text.trim().isNotEmpty) {
                ref.read(studioProvider.notifier).generateVideo(
                      prompt: _videoPromptController.text,
                      duration: _videoDuration,
                      aspectRatio: _videoAspectRatio,
                      imageUrl: _videoSourceImagePath,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.lastGeneratedItem?.type == 'video') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
                  const SizedBox(height: 8),
                  const Text('Video generation task submitted!', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(state.lastGeneratedItem!.url, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Video'),
                        onPressed: () => _saveMediaToGallery(state.lastGeneratedItem!.url, 'video'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. MUSIC TAB
  Widget _buildMusicTab(StudioState state) {
    final genres = ['Lo-Fi', 'Electronic', 'Cinematic', 'Rock', 'Jazz', 'Classical', 'Ambient'];
    final moods = ['Chill', 'Energetic', 'Dark', 'Uplifting', 'Melancholic', 'Dreamy'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _musicPromptController,
            labelText: 'Music Description & Theme',
            hintText: 'Warm Rhodes chords with vinyl crackle and smooth bassline...',
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          const Text('Genre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: genres.map((g) {
                final isSelected = _selectedGenre == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                    onSelected: (val) {
                      if (val) setState(() => _selectedGenre = g);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Mood', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: moods.map((m) {
                final isSelected = _selectedMood == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                    onSelected: (val) {
                      if (val) setState(() => _selectedMood = m);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Instrumental Only', style: TextStyle(fontSize: 14)),
            value: _forceInstrumental,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _forceInstrumental = val),
          ),
          const SizedBox(height: 16),

          CustomButton(
            text: 'Generate Music Track',
            icon: const Icon(Icons.audiotrack_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_musicPromptController.text.trim().isNotEmpty) {
                ref.read(studioProvider.notifier).generateMusic(
                      prompt: _musicPromptController.text,
                      genre: _selectedGenre,
                      mood: _selectedMood,
                      forceInstrumental: _forceInstrumental,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.lastGeneratedItem?.type == 'music') ...[
            AudioWaveformPlayer(
              audioUrl: state.lastGeneratedItem!.url,
              title: state.lastGeneratedItem!.prompt ?? 'Generated Music',
            ),
          ],
        ],
      ),
    );
  }

  // 4. SOUND EFFECTS TAB
  Widget _buildSfxTab(StudioState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _sfxPromptController,
            labelText: 'Sound Effect Description',
            hintText: 'Sci-fi laser blaster charging up and firing with deep bass echo...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('${_sfxDuration.toStringAsFixed(1)}s', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _sfxDuration,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _sfxDuration = val),
          ),
          const SizedBox(height: 16),

          CustomButton(
            text: 'Generate Sound Effect',
            icon: const Icon(Icons.graphic_eq_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_sfxPromptController.text.trim().isNotEmpty) {
                ref.read(studioProvider.notifier).generateSoundEffect(
                      text: _sfxPromptController.text,
                      durationSeconds: _sfxDuration,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.lastGeneratedItem?.type == 'sound_effect') ...[
            AudioWaveformPlayer(
              audioUrl: state.lastGeneratedItem!.url,
              title: state.lastGeneratedItem!.prompt ?? 'Sound Effect',
            ),
          ],
        ],
      ),
    );
  }

  // 5. TTS TAB
  Widget _buildTtsTab(StudioState state) {
    final voices = [
      {'id': '21m00Tcm4TlvDq8ikWAM', 'name': 'Rachel (Warm & Natural)'},
      {'id': 'AZnzlk1XvdvUeBnXmlld', 'name': 'Domi (Confident & Clear)'},
      {'id': 'EXAVITQu4vr4xnSDxMaL', 'name': 'Bella (Soft Narration)'},
      {'id': 'ErXwobaYiN019PkySvjV', 'name': 'Antoni (Dynamic & Professional)'},
      {'id': 'pNInz6obpgDQGcFmaJgB', 'name': 'Adam (Deep & Narrator)'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _ttsTextController,
            labelText: 'Script to Speak',
            hintText: 'Welcome to EzboAI! Experience the most natural, lifelike AI voice synthesis...',
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          const Text('Voice Character', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVoice,
                isExpanded: true,
                dropdownColor: AppColors.card,
                items: voices.map((v) {
                  return DropdownMenuItem(
                    value: v['id']!,
                    child: Text(v['name']!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVoice = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Speed', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('${_ttsSpeed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _ttsSpeed,
            min: 0.5,
            max: 1.5,
            divisions: 10,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _ttsSpeed = val),
          ),
          const SizedBox(height: 16),

          CustomButton(
            text: 'Generate Speech',
            icon: const Icon(Icons.record_voice_over_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_ttsTextController.text.trim().isNotEmpty) {
                ref.read(studioProvider.notifier).generateSpeech(
                      text: _ttsTextController.text,
                      voiceId: _selectedVoice,
                      speed: _ttsSpeed,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.lastGeneratedItem?.type == 'audio') ...[
            AudioWaveformPlayer(
              audioUrl: state.lastGeneratedItem!.url,
              title: state.lastGeneratedItem!.prompt ?? 'Generated Voice',
            ),
          ],
        ],
      ),
    );
  }

  // 6. STT TAB (Speech to Text)
  Widget _buildSttTab(StudioState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Speech to Text Transcription',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload any recorded audio file (.mp3, .wav, .m4a) to generate high-accuracy AI transcriptions.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: () async {
              final res = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
              );
              if (res != null && res.files.single.path != null) {
                setState(() => _sttAudioFilePath = res.files.single.path);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.audio_file_rounded, size: 40, color: AppColors.primaryLight),
                  const SizedBox(height: 10),
                  Text(
                    _sttAudioFilePath != null
                        ? _sttAudioFilePath!.split(Platform.pathSeparator).last
                        : 'Tap to select audio file',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: 'Transcribe Audio',
            icon: const Icon(Icons.transcribe_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_sttAudioFilePath != null) {
                ref.read(studioProvider.notifier).transcribeAudio(_sttAudioFilePath!);
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.transcribedText != null && state.transcribedText!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transcription', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.transcribedText!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transcription copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.transcribedText!,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 7. VOICE CHANGER TAB
  Widget _buildVoiceChangerTab(StudioState state) {
    final targetVoices = [
      {'id': '21m00Tcm4TlvDq8ikWAM', 'name': 'Rachel (Warm & Female)'},
      {'id': 'ErXwobaYiN019PkySvjV', 'name': 'Antoni (Male Hero)'},
      {'id': 'AZnzlk1XvdvUeBnXmlld', 'name': 'Domi (Punchy & Energetic)'},
      {'id': 'pNInz6obpgDQGcFmaJgB', 'name': 'Adam (Deep Baritone)'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Voice Changer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Transform any speech sample into another character voice while preserving timing, inflection, and emotion.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: () async {
              final res = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'],
              );
              if (res != null && res.files.single.path != null) {
                setState(() => _voiceChangerSamplePath = res.files.single.path);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mic_external_on_rounded, size: 40, color: AppColors.secondaryLight),
                  const SizedBox(height: 10),
                  Text(
                    _voiceChangerSamplePath != null
                        ? _voiceChangerSamplePath!.split(Platform.pathSeparator).last
                        : 'Select speech sample file',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Target Voice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetVoiceId,
                isExpanded: true,
                dropdownColor: AppColors.card,
                items: targetVoices.map((v) {
                  return DropdownMenuItem(
                    value: v['id']!,
                    child: Text(v['name']!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _targetVoiceId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remove Background Noise', style: TextStyle(fontSize: 14)),
            value: _removeNoise,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _removeNoise = val),
          ),
          const SizedBox(height: 20),

          CustomButton(
            text: 'Transform Voice',
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            isLoading: state.isGenerating,
            onPressed: () {
              if (_voiceChangerSamplePath != null) {
                ref.read(studioProvider.notifier).changeVoice(
                      filePath: _voiceChangerSamplePath!,
                      targetVoiceId: _targetVoiceId,
                      removeBackgroundNoise: _removeNoise,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          if (state.voiceChangeAudioUrl != null && state.voiceChangeAudioUrl!.isNotEmpty) ...[
            AudioWaveformPlayer(
              audioUrl: state.voiceChangeAudioUrl!,
              title: 'Transformed Voice Output',
            ),
          ],
        ],
      ),
    );
  }
}
