class CreditPlanModel {
  final String id;
  final String name;
  final String description;
  final String creditType;
  final List<String> creditTypes;
  final Map<String, int> creditAmounts;
  final int creditAmount;
  final int priceAmount; // USD cents
  final int? priceAmountBdt; // BDT poisha or taka
  final bool isPopular;

  const CreditPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creditType,
    this.creditTypes = const [],
    this.creditAmounts = const {},
    required this.creditAmount,
    required this.priceAmount,
    this.priceAmountBdt,
    this.isPopular = false,
  });

  String get formattedUsd {
    return '\$${(priceAmount / 100).toStringAsFixed(priceAmount % 100 == 0 ? 0 : 2)}';
  }

  String get formattedBdt {
    if (priceAmountBdt == null || priceAmountBdt == 0) return '';
    final val = priceAmountBdt! > 10000 ? (priceAmountBdt! / 100).round() : priceAmountBdt!;
    return '৳$val BDT';
  }

  factory CreditPlanModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> amounts = {};
    if (json['creditAmounts'] != null && json['creditAmounts'] is Map) {
      (json['creditAmounts'] as Map).forEach((k, v) {
        if (v is num) amounts[k.toString()] = v.toInt();
      });
    }

    List<String> types = [];
    if (json['creditTypes'] != null && json['creditTypes'] is List) {
      types = (json['creditTypes'] as List).map((e) => e.toString()).toList();
    }

    return CreditPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Credit Package',
      description: json['description'] as String? ?? '',
      creditType: json['creditType'] as String? ?? 'text',
      creditTypes: types,
      creditAmounts: amounts,
      creditAmount: (json['creditAmount'] as num?)?.toInt() ?? 100,
      priceAmount: (json['priceAmount'] as num?)?.toInt() ?? 500,
      priceAmountBdt: (json['priceAmountBdt'] as num?)?.toInt(),
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  static const List<CreditPlanModel> defaultCreditPlans = [
    CreditPlanModel(
      id: 'cp_starter_text',
      name: 'Starter Text Booster',
      description: '1,000 High-Speed AI Text Messages for general writing, chatting, and coding.',
      creditType: 'text',
      creditTypes: ['text'],
      creditAmounts: {'text': 1000},
      creditAmount: 1000,
      priceAmount: 499,
      priceAmountBdt: 59000,
    ),
    CreditPlanModel(
      id: 'cp_pro_creative',
      name: 'Pro Creative Studio Pack',
      description: 'All-in-one pack: 2,500 Text credits + 150 High-res Images + 20 Video generations.',
      creditType: 'text',
      creditTypes: ['text', 'image', 'video'],
      creditAmounts: {'text': 2500, 'image': 150, 'video': 20},
      creditAmount: 2500,
      priceAmount: 1499,
      priceAmountBdt: 175000,
      isPopular: true,
    ),
    CreditPlanModel(
      id: 'cp_media_master',
      name: 'Media Master Power Pack',
      description: 'Heavy generation bundle: 500 Flux Images + 50 Ultra Videos + 100 Audio tracks.',
      creditType: 'image',
      creditTypes: ['image', 'video', 'audio'],
      creditAmounts: {'image': 500, 'video': 50, 'audio': 100},
      creditAmount: 500,
      priceAmount: 2999,
      priceAmountBdt: 350000,
    ),
    CreditPlanModel(
      id: 'cp_ultimate_unlimited',
      name: 'Mega Power Refill',
      description: 'Maximum credit allowance for power users and enterprise creators.',
      creditType: 'text',
      creditTypes: ['text', 'image', 'video', 'audio'],
      creditAmounts: {'text': 10000, 'image': 1000, 'video': 100, 'audio': 200},
      creditAmount: 10000,
      priceAmount: 4999,
      priceAmountBdt: 590000,
    ),
  ];
}
