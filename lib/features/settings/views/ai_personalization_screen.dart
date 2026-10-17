import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/controllers/auth_controller.dart';

class AiPersonalizationScreen extends ConsumerStatefulWidget {
  const AiPersonalizationScreen({super.key});

  @override
  ConsumerState<AiPersonalizationScreen> createState() => _AiPersonalizationScreenState();
}

class _AiPersonalizationScreenState extends ConsumerState<AiPersonalizationScreen> {
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _instructionsController.text = user.personalInstructions ?? '';
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await ref.read(authProvider.notifier).updateProfile(
          personalInstructions: _instructionsController.text.trim(),
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI instructions saved!'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Personalization', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Custom Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'What would you like EzboAI to know about you to provide better, more tailored responses? These instructions will be included in all your conversations.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _instructionsController,
              hintText: 'e.g. Always write code in TypeScript. Be concise. Explain technical concepts with relatable analogies...',
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Save Instructions',
              isLoading: authState.isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
