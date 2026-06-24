import 'package:uuid/uuid.dart';

class Debt {
  final String id;
  final String title;
  final double totalAmount;
  final double remainingAmount;
  final double interestRate; // Annual interest rate percentage (e.g. 15.0 for 15%)
  final double minimumMonthlyPayment;
  final DateTime? dueDate;
  final String notes;

  Debt({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.minimumMonthlyPayment,
    this.dueDate,
    this.notes = '',
  });

  factory Debt.create({
    required String title,
    required double totalAmount,
    double? remainingAmount,
    required double interestRate,
    required double minimumMonthlyPayment,
    DateTime? dueDate,
    String notes = '',
  }) {
    return Debt(
      id: const Uuid().v4(),
      title: title,
      totalAmount: totalAmount,
      remainingAmount: remainingAmount ?? totalAmount,
      interestRate: interestRate,
      minimumMonthlyPayment: minimumMonthlyPayment,
      dueDate: dueDate,
      notes: notes,
    );
  }

  double get progressPercentage {
    if (totalAmount <= 0) return 100.0;
    final paid = totalAmount - remainingAmount;
    final pct = (paid / totalAmount) * 100;
    return pct < 0 ? 0.0 : (pct > 100.0 ? 100.0 : pct);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'interestRate': interestRate,
      'minimumMonthlyPayment': minimumMonthlyPayment,
      'dueDate': dueDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      title: json['title'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      minimumMonthlyPayment: (json['minimumMonthlyPayment'] as num).toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      notes: json['notes'] as String? ?? '',
    );
  }

  Debt copyWith({
    String? title,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    double? minimumMonthlyPayment,
    DateTime? dueDate,
    String? notes,
  }) {
    return Debt(
      id: id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      minimumMonthlyPayment: minimumMonthlyPayment ?? this.minimumMonthlyPayment,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
    );
  }
}
