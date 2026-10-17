class PricingPlan {
  final String id;
  final String name;
  final String description;
  final String tier; // 'free' | 'starter' | 'pro' | 'advanced'
  final int priceAmount; // In USD cents
  final int? priceAmountBdt; // In BDT poisha
  final String? stripePriceId;
  final List<String> features;
  final bool isPopular;

  const PricingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.priceAmount,
    this.priceAmountBdt,
    this.stripePriceId,
    required this.features,
    this.isPopular = false,
  });

  String get formattedUsd {
    if (priceAmount == 0) return 'Free';
    return '\$${(priceAmount / 100).toStringAsFixed(0)}/mo';
  }

  String get formattedBdt {
    if (priceAmountBdt == null || priceAmountBdt == 0) return 'Free';
    return '৳${(priceAmountBdt! / 100).toStringAsFixed(0)}/mo';
  }

  String get priceId => stripePriceId ?? id;

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tier: json['tier'] as String? ?? 'free',
      priceAmount: (json['priceAmount'] as num?)?.toInt() ?? 0,
      priceAmountBdt: (json['priceAmountBdt'] as num?)?.toInt(),
      stripePriceId: json['stripePriceId'] as String? ?? json['priceId'] as String?,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  static const List<PricingPlan> defaultPlans = [
    PricingPlan(
      id: 'plan_free',
      name: 'Free',
      description: 'Get started with essential AI features and explore EzboAI.',
      tier: 'free',
      priceAmount: 0,
      priceAmountBdt: 0,
      features: [
        '50 Daily Text Messages',
        'Access to Ezbo Flash & Open Models',
        'Standard Generation Speed',
        'Community Support',
      ],
    ),
    PricingPlan(
      id: 'plan_starter',
      name: 'Starter',
      description: 'Perfect for enthusiasts and daily AI creative tasks.',
      tier: 'starter',
      priceAmount: 900, // $9
      priceAmountBdt: 105000, // ৳1,050
      features: [
        '500 Monthly Text Credits',
        '50 Image Generations',
        'Access to Claude 3.5 & GPT-4o',
        'Audio Generation (TTS & SFX)',
        'Standard Queue Priority',
      ],
    ),
    PricingPlan(
      id: 'plan_pro',
      name: 'Pro',
      description: 'Best for professionals, power users, and content creators.',
      tier: 'pro',
      priceAmount: 1900, // $19
      priceAmountBdt: 220000, // ৳2,200
      isPopular: true,
      features: [
        'Unlimited Fast Text Chat',
        '300 High-Res Image Generations',
        '30 Video Generations',
        'Full Audio Studio & Voice Changer',
        'Web Search & Deep Research',
        'Priority GPU Processing',
      ],
    ),
    PricingPlan(
      id: 'plan_advanced',
      name: 'Advanced',
      description: 'Maximum power and limits for enterprise and heavy workloads.',
      tier: 'advanced',
      priceAmount: 3900, // $39
      priceAmountBdt: 450000, // ৳4,500
      features: [
        'Unlimited Ultra Reasoning Models',
        '1,000+ Image Generations',
        '100+ Video Generations',
        'Studio Quality Voice Cloning & Music',
        'Dedicated Fast Lane Support',
      ],
    ),
  ];
}
