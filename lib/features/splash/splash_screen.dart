import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/controllers/auth_controller.dart';
import '../shell/main_shell_screen.dart';
import '../auth/views/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // ~1 second animated intro per user request
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bgColor = isDark ? AppColors.background : AppColors.backgroundLight;
    final logoAsset = isDark
        ? 'assets/branding/default-dark-logo.png'
        : 'assets/branding/default-light-logo.png';

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated 3D ribbon mark / app icon card
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.25),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon-192.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.white),
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Official wordmark logo with transparent background
            Image.asset(
              logoAsset,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ezbo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 450.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),
            const SizedBox(height: 10),
            Text(
              'The All-in-One AI Studio',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
