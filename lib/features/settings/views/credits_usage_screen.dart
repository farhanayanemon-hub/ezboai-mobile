import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/credit_plan_model.dart';
import '../../../shared/widgets/gradient_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/views/chat_drawer.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../subscription/views/manual_checkout_sheet.dart';

class CreditsUsageScreen extends ConsumerStatefulWidget {
  const CreditsUsageScreen({super.key});

  @override
  ConsumerState<CreditsUsageScreen> createState() => _CreditsUsageScreenState();
}

class _CreditsUsageScreenState extends ConsumerState<CreditsUsageScreen> {
  String? _purchasingPlanId;

  Future<void> _handleOnlinePurchase(CreditPlanModel plan) async {
    setState(() => _purchasingPlanId = plan.id);
    final res = await ref.read(subscriptionProvider.notifier).createCreditPurchaseSession(plan.id);
    if (!mounted) return;
    setState(() => _purchasingPlanId = null);

    if (res != null && (res['url'] != null || res['paymentUrl'] != null)) {
      final url = (res['paymentUrl'] ?? res['url']) as String;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Fallback to manual checkout sheet if online gateway not configured
      _openManualCheckout(plan);
    }
  }

  void _openManualCheckout(CreditPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualCheckoutSheet(creditPlan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final subState = ref.watch(subscriptionProvider);
    final credits = user?.credits;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Credits & Usage', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Balance Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Available Credits',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${credits?.total ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CURRENT PLAN: ${(user?.planTier ?? "Free").toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Credit Breakdown
            _buildSectionHeader('CURRENT CREDIT ALLOTMENT', theme),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildBreakdownTile(
                    title: 'Text & Chat',
                    count: credits?.text ?? 0,
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBreakdownTile(
                    title: 'Images',
                    count: credits?.image ?? 0,
                    icon: Icons.image_outlined,
                    color: AppColors.secondary,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownTile(
                    title: 'Videos',
                    count: credits?.video ?? 0,
                    icon: Icons.videocam_outlined,
                    color: AppColors.warning,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBreakdownTile(
                    title: 'Audio Studio',
                    count: credits?.audio ?? 0,
                    icon: Icons.graphic_eq_rounded,
                    color: AppColors.success,
                    theme: theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // All Credit Packages & Top-Up
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'TOP-UP CREDIT PACKS',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Add credits instantly without changing your subscription tier. Credits never expire.',
              style: TextStyle(fontSize: 12.5, color: theme.hintColor),
            ),
            const SizedBox(height: 14),

            // Credit Plans List
            ...subState.creditPlans.map((plan) => _buildCreditPlanCard(plan, theme, isDark)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: theme.hintColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildBreakdownTile({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPlanCard(CreditPlanModel plan, ThemeData theme, bool isDark) {
    final isPurchasing = _purchasingPlanId == plan.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : theme.dividerColor,
          width: plan.isPopular ? 1.8 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Popular badge, Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            const GradientBadge(text: 'POPULAR'),
                          ],
                        ],
                      ),
                      if (plan.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedUsd,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    if (plan.formattedBdt.isNotEmpty)
                      Text(
                        plan.formattedBdt,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Credit Grants Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (plan.creditAmounts.isNotEmpty)
                  ...plan.creditAmounts.entries.map((entry) {
                    final type = entry.key.toUpperCase();
                    final count = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '+$count $type',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  })
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '+${plan.creditAmount} ${plan.creditType.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Purchase Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isPurchasing ? null : () => _handleOnlinePurchase(plan),
                    child: isPurchasing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Buy Online',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    onPressed: () => _openManualCheckout(plan),
                    child: const Text(
                      'bKash / Nagad / Crypto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
