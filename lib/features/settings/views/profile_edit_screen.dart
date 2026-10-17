import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  String? _avatarImage;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _professionController.text = user.profession ?? '';
      _avatarImage = user.image;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = picked.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        setState(() {
          _avatarImage = 'data:$mimeType;base64,$base64String';
          _avatarChanged = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                title: const Text('Take a Photo', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAvatar(ImageSource.camera);
                },
              ),
              if (_avatarImage != null && _avatarImage!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _avatarImage = '';
                      _avatarChanged = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final user = ref.watch(authProvider).user;
    final initial = (user?.name?.isNotEmpty == true
            ? user!.name![0]
            : (user?.email.isNotEmpty == true ? user!.email[0] : 'U'))
        .toUpperCase();

    Widget imageContent;

    if (_avatarImage != null && _avatarImage!.startsWith('data:image')) {
      try {
        final commaIdx = _avatarImage!.indexOf(',');
        final base64Data = commaIdx != -1 ? _avatarImage!.substring(commaIdx + 1) : _avatarImage!;
        final decodedBytes = base64Decode(base64Data);
        imageContent = ClipOval(
          child: Image.memory(
            decodedBytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        imageContent = _buildInitialFallback(initial);
      }
    } else if (_avatarImage != null && _avatarImage!.startsWith('http')) {
      imageContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: _avatarImage!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (_, __) => const CircularProgressIndicator(color: AppColors.primary),
          errorWidget: (_, __, ___) => _buildInitialFallback(initial),
        ),
      );
    } else {
      imageContent = _buildInitialFallback(initial);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2.5),
            ),
            child: imageContent,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showAvatarOptions,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialFallback(String initial) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppColors.error),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).updateProfile(
          name: name,
          profession: _professionController.text.trim(),
          image: _avatarChanged ? _avatarImage : null,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildAvatarWidget(),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'Your display name',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _professionController,
              labelText: 'Profession / Role',
              hintText: 'e.g. Software Engineer, Designer, Student',
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Save Profile',
              isLoading: authState.isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
