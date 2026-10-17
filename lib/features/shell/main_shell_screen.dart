import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nav_provider.dart';
import '../chat/views/chat_screen.dart';
import '../studio/views/studio_screen.dart';
import '../library/views/library_screen.dart';
import '../projects/views/projects_screen.dart';
import '../settings/views/credits_usage_screen.dart';
import '../settings/views/settings_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = [
    ChatScreen(),
    StudioScreen(),
    LibraryScreen(),
    ProjectsScreen(),
    CreditsUsageScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex.clamp(0, _screens.length - 1),
        children: _screens,
      ),
      // Bottom navigation bar is completely removed as requested
      // Navigation is now driven entirely from the Sidebar Drawer
    );
  }
}
