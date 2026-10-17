import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/pricing_plan.dart';
import '../../../core/models/credit_plan_model.dart';

class SubscriptionState {
  final List<PricingPlan> plans;
  final List<CreditPlanModel> creditPlans;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.plans = PricingPlan.defaultPlans,
    this.creditPlans = CreditPlanModel.defaultCreditPlans,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    List<PricingPlan>? plans,
    List<CreditPlanModel>? creditPlans,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      creditPlans: creditPlans ?? this.creditPlans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiClient _api = ApiClient();

  SubscriptionNotifier() : super(const SubscriptionState()) {
    loadPlans();
    loadCreditPlans();
  }

  Future<void> loadPlans() async {
    try {
      final res = await _api.get(ApiEndpoints.pricingPlans);
      if (res.statusCode == 200 && res.data != null && res.data is List) {
        final list = (res.data as List).map((p) => PricingPlan.fromJson(p)).toList();
        if (list.isNotEmpty) {
          state = state.copyWith(plans: list);
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> loadCreditPlans() async {
    try {
      final res = await _api.get(ApiEndpoints.creditPlans);
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List
            ? res.data as List
            : (res.data['creditPlans'] as List? ?? []);
        if (list.isNotEmpty) {
          final parsed = list.map((c) => CreditPlanModel.fromJson(c)).toList();
          state = state.copyWith(creditPlans: parsed);
          return;
        }
      }
    } catch (_) {}
  }

  // Create Subscription Checkout Session (Stripe or OpayBD)
  Future<Map<String, dynamic>?> createCheckoutSession(String priceId) async {
    try {
      final res = await _api.post(
        ApiEndpoints.stripeCheckout,
        data: {'priceId': priceId},
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Create Credit Top-up Checkout Session (Stripe or OpayBD)
  Future<Map<String, dynamic>?> createCreditPurchaseSession(String creditPlanId) async {
    try {
      final res = await _api.post(
        ApiEndpoints.creditPurchase,
        data: {'creditPlanId': creditPlanId},
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Manual payment submission for either subscription or credit plan
  Future<bool> submitManualPayment({
    String? planId,
    String? creditPlanId,
    required String gateway,
    required String txnReference,
    String? senderInfo,
    String? userNotes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'gateway': gateway,
        'txnReference': txnReference.trim(),
        'senderInfo': senderInfo?.trim(),
        'userNotes': userNotes?.trim(),
      };
      if (planId != null && planId.isNotEmpty) {
        payload['planId'] = planId;
      }
      if (creditPlanId != null && creditPlanId.isNotEmpty) {
        payload['creditPlanId'] = creditPlanId;
      }

      final res = await _api.post(
        ApiEndpoints.manualCheckout,
        data: payload,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});
