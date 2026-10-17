import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/pricing_plan.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/subscription_controller.dart';
import 'manual_checkout_sheet.dart';

class PricingPlansScreen extends ConsumerWidget {
  const PricingPlansScreen({super.key});

  void _showCheckoutOptions(BuildContext context, WidgetRef ref, PricingPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Subscribe to ${plan.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${plan.formattedUsd} ${plan.formattedBdt.isNotEmpty ? '• ${plan.formattedBdt}' : ''}',
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Option 1: Online / Instant (Cards / OpayBD)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.background,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: AppColors.primaryLight, size: 22),
                ),
                title: const Text('Instant Checkout (Cards & Mobile Banking)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Pay securely via Stripe or OpayBD', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final res = await ref.read(subscriptionProvider.notifier).createCheckoutSession(plan.priceId);
                  if (res != null) {
                    final url = res['paymentUrl'] ?? res['url'];
                    if (url != null && url.toString().isNotEmpty) {
                      await launchUrl(Uri.parse(url.toString()), mode: LaunchMode.externalApplication);
                      return;
                    }
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening secure checkout session...')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Manual Payment (bKash / Nagad / Rocket / Crypto / Wise)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.background,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondaryLight, size: 22),
                ),
                title: const Text('Manual Gateway (bKash, Nagad, Crypto)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Submit transaction ID / TrxID for manual verification', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ManualCheckoutSheet(plan: plan),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).user;
    final currentTier = user?.planTier ?? 'free';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upgrade Plan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: subState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose Your AI Power',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unlock ultra-reasoning models, high-res generation, and priority GPU lanes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ...subState.plans.map((plan) {
                    final isCurrent = plan.tier.toLowerCase() == currentTier.toLowerCase();
                    return _buildPlanCard(context, ref, plan, isCurrent);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, PricingPlan plan, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : AppColors.border,
          width: plan.isPopular ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              if (plan.isPopular) const GradientBadge(text: 'MOST POPULAR'),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('CURRENT PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedUsd,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              if (plan.priceAmountBdt != null && plan.priceAmountBdt! > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${plan.formattedBdt})',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          ...plan.features.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          CustomButton(
            text: isCurrent ? 'Active Plan' : 'Select ${plan.name}',
            onPressed: isCurrent
                ? null
                : () => _showCheckoutOptions(context, ref, plan),
          ),
        ],
      ),
    );
  }
}
