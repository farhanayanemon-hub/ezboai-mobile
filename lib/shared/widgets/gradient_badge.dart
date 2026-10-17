import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientBadge extends StatelessWidget {
  final String text;
  final Gradient? gradient;
  final double fontSize;

  const GradientBadge({
    super.key,
    required this.text,
    this.gradient,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
