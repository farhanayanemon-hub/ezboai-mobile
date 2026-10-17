import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';
import '../../shell/main_shell_screen.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerifyScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    final success = await ref.read(authProvider.notifier).verifyOtp(widget.email, code);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    } else {
      final error = ref.read(authProvider).error ?? 'Verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit verification code to:\n${widget.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _codeController,
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textMuted, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter the code';
                    if (val.trim().length < 4) return 'Please enter a valid code';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Verify & Continue',
                  isLoading: authState.isLoading,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await ref
                                .read(authProvider.notifier)
                                .resendOtp(widget.email);
                            if (!mounted) return;
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('A new verification code has been sent to your email.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              final err = ref.read(authProvider).error ?? 'Failed to resend code';
                              messenger.showSnackBar(
                                SnackBar(content: Text(err), backgroundColor: AppColors.error),
                              );
                            }
                          },
                    child: const Text(
                      "Didn't receive code? Resend",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
