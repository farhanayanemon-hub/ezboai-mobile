import 'credit_balance.dart';

class UserModel {
  final String id;
  final String? name;
  final String email;
  final String? image;
  final String planTier;
  final bool isAdmin;
  final String? profession;
  final String? personalInstructions;
  final String? subscriptionStatus;
  final CreditBalance credits;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.image,
    this.planTier = 'free',
    this.isAdmin = false,
    this.profession,
    this.personalInstructions,
    this.subscriptionStatus,
    this.credits = const CreditBalance(),
  });

  factory UserModel.fromJson(Map<String, dynamic> json, [CreditBalance? credits]) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      image: json['image'] as String?,
      planTier: json['planTier'] as String? ?? 'free',
      isAdmin: json['isAdmin'] as bool? ?? false,
      profession: json['profession'] as String?,
      personalInstructions: json['personalInstructions'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      credits: credits ??
          (json['credits'] != null
              ? CreditBalance.fromJson(json['credits'] as Map<String, dynamic>)
              : const CreditBalance()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'planTier': planTier,
      'isAdmin': isAdmin,
      'profession': profession,
      'personalInstructions': personalInstructions,
      'subscriptionStatus': subscriptionStatus,
      'credits': credits.toJson(),
    };
  }

  UserModel copyWith({
    String? name,
    String? image,
    String? planTier,
    bool? isAdmin,
    String? profession,
    String? personalInstructions,
    String? subscriptionStatus,
    CreditBalance? credits,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      image: image ?? this.image,
      planTier: planTier ?? this.planTier,
      isAdmin: isAdmin ?? this.isAdmin,
      profession: profession ?? this.profession,
      personalInstructions: personalInstructions ?? this.personalInstructions,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      credits: credits ?? this.credits,
    );
  }
}
