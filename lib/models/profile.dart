class UserProfile {
  final String name;
  final String incomeType; // 'salaried' or 'daily_earner' or 'informal_worker'
  final double monthlyIncome; // Average monthly income
  final double monthlyDebtObligation; // Ongoing recurring debt obligations (like rent if treated as debt, or bank loans)
  final int emergencyFundTargetMonths; // e.g. 3 months or 6 months
  final String currency; // 'ETB' or 'USD'
  final bool hasStableIncome;
  final double currentInvestmentAllocation; // Current monthly investment amount

  UserProfile({
    required this.name,
    required this.incomeType,
    required this.monthlyIncome,
    this.monthlyDebtObligation = 0.0,
    required this.emergencyFundTargetMonths,
    this.currency = 'ETB',
    this.hasStableIncome = true,
    this.currentInvestmentAllocation = 0.0,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: 'Ethiopian Pioneer',
      incomeType: 'daily_earner',
      monthlyIncome: 12000.0, // Default 12,000 Birr/month
      monthlyDebtObligation: 1500.0,
      emergencyFundTargetMonths: 6, // Recommended 6 months for daily earners
      currency: 'ETB',
      hasStableIncome: false,
      currentInvestmentAllocation: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'incomeType': incomeType,
      'monthlyIncome': monthlyIncome,
      'monthlyDebtObligation': monthlyDebtObligation,
      'emergencyFundTargetMonths': emergencyFundTargetMonths,
      'currency': currency,
      'hasStableIncome': hasStableIncome,
      'currentInvestmentAllocation': currentInvestmentAllocation,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'User',
      incomeType: json['incomeType'] as String? ?? 'daily_earner',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 10000.0,
      monthlyDebtObligation: (json['monthlyDebtObligation'] as num?)?.toDouble() ?? 0.0,
      emergencyFundTargetMonths: json['emergencyFundTargetMonths'] as int? ?? 6,
      currency: json['currency'] as String? ?? 'ETB',
      hasStableIncome: json['hasStableIncome'] as bool? ?? false,
      currentInvestmentAllocation: (json['currentInvestmentAllocation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  UserProfile copyWith({
    String? name,
    String? incomeType,
    double? monthlyIncome,
    double? monthlyDebtObligation,
    int? emergencyFundTargetMonths,
    String? currency,
    bool? hasStableIncome,
    double? currentInvestmentAllocation,
  }) {
    return UserProfile(
      name: name ?? this.name,
      incomeType: incomeType ?? this.incomeType,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyDebtObligation: monthlyDebtObligation ?? this.monthlyDebtObligation,
      emergencyFundTargetMonths: emergencyFundTargetMonths ?? this.emergencyFundTargetMonths,
      currency: currency ?? this.currency,
      hasStableIncome: hasStableIncome ?? this.hasStableIncome,
      currentInvestmentAllocation: currentInvestmentAllocation ?? this.currentInvestmentAllocation,
    );
  }
}
