import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds
  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF121215);
  static const Color card = Color(0xFF18181B);
  static const Color cardSecondary = Color(0xFF202024);
  static const Color surfaceElevated = Color(0xFF27272A);

  // Borders & Dividers
  static const Color border = Color(0xFF27272A);
  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const Color borderActive = Color(0xFF6366F1);

  // Vibrant Accents (Matches EzboAI brand)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600
  static const Color secondary = Color(0xFF8B5CF6); // Purple 500
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFA855F7); // Purple 600

  // Text Colors
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF52525B);

  // Light Mode Tokens
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardSecondaryLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color aiBubbleLight = Color(0xFFF1F5F9);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0x226366F1), Color(0x118B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF18181B), Color(0xFF121215)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Chat message bubbles
  static const Color userBubble = Color(0xFF4F46E5);
  static const Color aiBubble = Color(0xFF18181B);
}
