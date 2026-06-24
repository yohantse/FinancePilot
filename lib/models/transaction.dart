import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category; // e.g. Salary, Food, Rent, Transport, Freelance, Equb, CBE loan
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String paymentMethod; // 'Cash', 'Telebirr', 'CBE Birr', 'Bank'
  final bool isRecurring;
  final String recurringInterval; // 'none', 'daily', 'weekly', 'monthly'
  final String notes;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.paymentMethod,
    this.isRecurring = false,
    this.recurringInterval = 'none',
    this.notes = '',
  });

  factory Transaction.create({
    required String title,
    required double amount,
    required String category,
    required String type,
    required String paymentMethod,
    DateTime? date,
    bool isRecurring = false,
    String recurringInterval = 'none',
    String notes = '',
  }) {
    return Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: category,
      type: type,
      date: date ?? DateTime.now(),
      paymentMethod: paymentMethod,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'notes': notes,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringInterval: json['recurringInterval'] as String? ?? 'none',
      notes: json['notes'] as String? ?? '',
    );
  }

  Transaction copyWith({
    String? title,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
    String? paymentMethod,
    bool? isRecurring,
    String? recurringInterval,
    String? notes,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      notes: notes ?? this.notes,
    );
  }
}
