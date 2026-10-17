import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/gradient_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';
import '../../chat/views/chat_drawer.dart';
import 'profile_edit_screen.dart';
import 'ai_personalization_screen.dart';
import 'credits_usage_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of your EzboAI account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Settings & Account', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
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
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primary,
                                child: Center(child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                              ),
                            );
                          }
                          return Container(
                            color: AppColors.primary,
                            child: Center(child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'EzboAI User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: theme.hintColor),
                        ),
                        const SizedBox(height: 6),
                        GradientBadge(text: (user?.planTier ?? 'FREE').toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance Section
            _buildSectionHeader('APPEARANCE', theme),
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isDark ? 'Dark theme enabled' : 'Light theme enabled (default)',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme(val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Account Section
            _buildSectionHeader('ACCOUNT', theme),
            _buildSettingsItem(
              theme: theme,
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your display name and profession',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                );
              },
            ),
            _buildSettingsItem(
              theme: theme,
              icon: Icons.psychology_outlined,
              title: 'AI Personalization',
              subtitle: 'Custom instructions for all AI chats',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiPersonalizationScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Billing & Credits Section
            _buildSectionHeader('BILLING & CREDITS', theme),
            _buildSettingsItem(
              theme: theme,
              icon: Icons.bolt_rounded,
              title: 'Credits & Usage',
              subtitle: 'View balance & top up credit packages',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreditsUsageScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // About Section (EzboAI Cloud Server removed as requested)
            _buildSectionHeader('ABOUT', theme),
            _buildSettingsItem(
              theme: theme,
              icon: Icons.info_outline_rounded,
              title: 'Application Version',
              subtitle: 'EzboAI v1.0.0 (Production Build)',
            ),
            _buildSettingsItem(
              theme: theme,
              icon: Icons.shield_outlined,
              title: 'Terms & Privacy',
              subtitle: 'End-to-end encrypted AI workspace',
            ),
            const SizedBox(height: 24),

            // Log out button
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
              tileColor: theme.cardTheme.color,
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Log Out',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.hintColor)),
        trailing: onTap != null
            ? Icon(Icons.chevron_right_rounded, size: 20, color: theme.hintColor)
            : null,
        onTap: onTap,
      ),
    );
  }
}
