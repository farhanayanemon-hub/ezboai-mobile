import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/pricing_plan.dart';
import '../../../core/models/credit_plan_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/subscription_controller.dart';

class ManualGatewayInfo {
  final String id;
  final String name;
  final String accountInfo;
  final String accountType;
  final String instructions;
  final IconData icon;

  const ManualGatewayInfo({
    required this.id,
    required this.name,
    required this.accountInfo,
    required this.accountType,
    required this.instructions,
    required this.icon,
  });
}

class ManualCheckoutSheet extends ConsumerStatefulWidget {
  final PricingPlan? plan;
  final CreditPlanModel? creditPlan;

  const ManualCheckoutSheet({
    super.key,
    this.plan,
    this.creditPlan,
  }) : assert(plan != null || creditPlan != null);

  @override
  ConsumerState<ManualCheckoutSheet> createState() => _ManualCheckoutSheetState();
}

class _ManualCheckoutSheetState extends ConsumerState<ManualCheckoutSheet> {
  final _trxController = TextEditingController();
  final _senderController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedGatewayId = 'bkash';
  bool _isSubmitting = false;

  final List<ManualGatewayInfo> _gateways = const [
    ManualGatewayInfo(
      id: 'bkash',
      name: 'bKash',
      accountInfo: '01886882299',
      accountType: 'Personal (Send Money)',
      instructions: '1. Open bKash App and select "Send Money".\n2. Enter receiver number: 01886882299.\n3. Enter amount in BDT and your username/email as reference.\n4. Complete transfer, copy the 10-digit TrxID and paste below.',
      icon: Icons.phone_android_rounded,
    ),
    ManualGatewayInfo(
      id: 'nagad',
      name: 'Nagad',
      accountInfo: '01886882299',
      accountType: 'Personal (Send Money)',
      instructions: '1. Open Nagad App and select "Send Money".\n2. Enter receiver number: 01886882299.\n3. Complete payment, copy the 8-character TrxID and enter below with your sender mobile number.',
      icon: Icons.phonelink_ring_rounded,
    ),
    ManualGatewayInfo(
      id: 'rocket',
      name: 'Rocket',
      accountInfo: '01886882299-8',
      accountType: 'Personal (Send Money)',
      instructions: '1. Dial *322# or open Rocket App.\n2. Select "Send Money" to 01886882299-8.\n3. Enter TrxID and sender mobile number below.',
      icon: Icons.rocket_launch_rounded,
    ),
    ManualGatewayInfo(
      id: 'binance',
      name: 'Binance Pay (USDT)',
      accountInfo: 'ezboai@binance (Pay ID: 382910291)',
      accountType: 'Binance Pay / USDT (TRC20)',
      instructions: '1. Open Binance App > Pay > Send.\n2. Enter Binance Pay ID: 382910291.\n3. Send equivalent USDT amount.\n4. Paste the Binance Order ID / TxID below.',
      icon: Icons.currency_bitcoin_rounded,
    ),
    ManualGatewayInfo(
      id: 'bybit',
      name: 'Bybit (USDT)',
      accountInfo: 'ezboai@bybit (UID: 49201928)',
      accountType: 'Bybit UID / USDT',
      instructions: '1. In Bybit, transfer equivalent USDT to UID: 49201928.\n2. Paste your Bybit Order ID or TxID below.',
      icon: Icons.monetization_on_rounded,
    ),
    ManualGatewayInfo(
      id: 'wise',
      name: 'Wise Transfer',
      accountInfo: 'billing@ezboai.com',
      accountType: 'USD / EUR Account',
      instructions: '1. In Wise, send USD or EUR to billing@ezboai.com.\n2. Paste your Wise transfer reference and sender name below.',
      icon: Icons.account_balance_rounded,
    ),
    ManualGatewayInfo(
      id: 'paypal',
      name: 'PayPal',
      accountInfo: 'billing@ezboai.com',
      accountType: 'Friends & Family (USD)',
      instructions: '1. Send USD to billing@ezboai.com via "Friends & Family" (no fees).\n2. Copy the PayPal Transaction ID and paste below.',
      icon: Icons.payment_rounded,
    ),
  ];

  @override
  void dispose() {
    _trxController.dispose();
    _senderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ManualGatewayInfo get _selectedGateway {
    return _gateways.firstWhere(
      (g) => g.id == _selectedGatewayId,
      orElse: () => _gateways.first,
    );
  }

  String _getFormattedPrice() {
    final plan = widget.plan;
    final cp = widget.creditPlan;

    if (_selectedGatewayId == 'bkash' || _selectedGatewayId == 'nagad' || _selectedGatewayId == 'rocket') {
      if (cp != null) {
        if (cp.formattedBdt.isNotEmpty) return cp.formattedBdt;
        final bdt = (cp.priceAmount / 100 * 120).round();
        return '৳$bdt BDT';
      }
      if (plan != null) {
        if (plan.priceAmountBdt != null && plan.priceAmountBdt! > 0) {
          return plan.formattedBdt;
        }
        if (plan.tier == 'starter') return '৳1,190 BDT';
        if (plan.tier == 'pro') return '৳2,390 BDT';
        if (plan.tier == 'advanced') return '৳4,790 BDT';
        final bdt = (plan.priceAmount / 100 * 120).round();
        return '৳$bdt BDT';
      }
    }
    if (cp != null) return '${cp.formattedUsd} USD';
    return '${plan?.formattedUsd ?? "\$0"} USD';
  }

  Future<void> _handleSubmit() async {
    final trx = _trxController.text.trim();
    if (trx.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Transaction ID / TrxID'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref.read(subscriptionProvider.notifier).submitManualPayment(
          planId: widget.plan?.id,
          creditPlanId: widget.creditPlan?.id,
          gateway: _selectedGatewayId,
          txnReference: trx,
          senderInfo: _senderController.text.trim(),
          userNotes: _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted! Admin will verify and activate your plan within 15–60 minutes.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit order. Please check connection and try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gateway = _selectedGateway;
    final priceDisplay = _getFormattedPrice();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Checkout · ${widget.plan?.name ?? widget.creditPlan?.name ?? "Package"}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: $priceDisplay',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),

            // Gateway Selector Chips / Dropdown
            const Text(
              'Select Payment Gateway',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGatewayId,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  items: _gateways.map((g) {
                    return DropdownMenuItem(
                      value: g.id,
                      child: Row(
                        children: [
                          Icon(g.icon, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 10),
                          Text(g.name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(g.accountType.split(' ')[0], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGatewayId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gateway Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        gateway.accountType,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                      ),
                      InkWell(
                        onTap: () => _copyToClipboard(gateway.accountInfo, gateway.name),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryLight),
                            SizedBox(width: 4),
                            Text('Copy', style: TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    gateway.accountInfo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    gateway.instructions,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Form Fields
            CustomTextField(
              controller: _trxController,
              labelText: 'Transaction ID / TrxID *',
              hintText: 'e.g. 9J8K7L6M5N or 0x48...8f',
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _senderController,
              labelText: 'Sender Phone / Email / Wallet Address',
              hintText: 'e.g. 017XXXXXXXX or user@gmail.com',
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _notesController,
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any extra details for quick verification',
              maxLines: 2,
            ),
            const SizedBox(height: 22),

            // Submit Button
            CustomButton(
              text: 'Submit Payment Reference',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account will be automatically updated once payment is verified.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
