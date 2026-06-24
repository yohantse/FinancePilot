import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String category; // 'Emergency Fund', 'House', 'Car', 'Wedding', 'Vacation', 'Business', 'Retirement'
  final String notes;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentSaved,
    required this.targetDate,
    required this.category,
    this.notes = '',
  });

  factory Goal.create({
    required String title,
    required double targetAmount,
    double currentSaved = 0.0,
    required DateTime targetDate,
    required String category,
    String notes = '',
  }) {
    return Goal(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      currentSaved: currentSaved,
      targetDate: targetDate,
      category: category,
      notes: notes,
    );
  }

  // Calculate required monthly savings to meet the deadline
  double get requiredMonthlySavings {
    final monthsRemaining = getMonthsRemaining();
    if (monthsRemaining <= 0) {
      return targetAmount - currentSaved > 0 ? targetAmount - currentSaved : 0.0;
    }
    final remainingAmount = targetAmount - currentSaved;
    return remainingAmount > 0 ? remainingAmount / monthsRemaining : 0.0;
  }

  int getMonthsRemaining() {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return (difference / 30.44).round(); // Average days in a month
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final pct = (currentSaved / targetAmount) * 100;
    return pct > 100.0 ? 100.0 : pct;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentSaved': currentSaved,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'notes': notes,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentSaved: (json['currentSaved'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: json['category'] as String,
      notes: json['notes'] as String? ?? '',
    );
  }

  Goal copyWith({
    String? title,
    double? targetAmount,
    double? currentSaved,
    DateTime? targetDate,
    String? category,
    String? notes,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentSaved: currentSaved ?? this.currentSaved,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
