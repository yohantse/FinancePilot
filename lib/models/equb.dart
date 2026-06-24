import 'package:uuid/uuid.dart';

class Equb {
  final String id;
  final String title;
  final double contributionAmount; // Amount contributed per cycle (e.g. 500 Birr)
  final String cycleType; // 'weekly', 'monthly'
  final int totalMembers;
  final String contributionDay; // e.g., 'Monday', 'Friday'
  final int myPayoutRound; // The round the user is scheduled or drew to get the pot (1-indexed)
  final int roundsCompleted; // Current round number or how many rounds completed
  final bool hasReceivedPayout;
  final DateTime startDate;
  final bool isActive;

  Equb({
    required this.id,
    required this.title,
    required this.contributionAmount,
    required this.cycleType,
    required this.totalMembers,
    required this.contributionDay,
    required this.myPayoutRound,
    this.roundsCompleted = 0,
    this.hasReceivedPayout = false,
    required this.startDate,
    this.isActive = true,
  });

  factory Equb.create({
    required String title,
    required double contributionAmount,
    required String cycleType,
    required int totalMembers,
    required String contributionDay,
    int myPayoutRound = 1,
    DateTime? startDate,
  }) {
    return Equb(
      id: const Uuid().v4(),
      title: title,
      contributionAmount: contributionAmount,
      cycleType: cycleType,
      totalMembers: totalMembers,
      contributionDay: contributionDay,
      myPayoutRound: myPayoutRound,
      startDate: startDate ?? DateTime.now(),
    );
  }

  // The total lump sum received when it is the user's turn
  double get totalPayoutPot {
    return contributionAmount * totalMembers;
  }

  // Total amount contributed so far by the user
  double get totalContributedSoFar {
    return contributionAmount * roundsCompleted;
  }

  double get progressPercentage {
    if (totalMembers <= 0) return 0.0;
    final pct = (roundsCompleted / totalMembers) * 100;
    return pct > 100.0 ? 100.0 : pct;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contributionAmount': contributionAmount,
      'cycleType': cycleType,
      'totalMembers': totalMembers,
      'contributionDay': contributionDay,
      'myPayoutRound': myPayoutRound,
      'roundsCompleted': roundsCompleted,
      'hasReceivedPayout': hasReceivedPayout,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Equb.fromJson(Map<String, dynamic> json) {
    return Equb(
      id: json['id'] as String,
      title: json['title'] as String,
      contributionAmount: (json['contributionAmount'] as num).toDouble(),
      cycleType: json['cycleType'] as String,
      totalMembers: json['totalMembers'] as int,
      contributionDay: json['contributionDay'] as String,
      myPayoutRound: json['myPayoutRound'] as int? ?? 1,
      roundsCompleted: json['roundsCompleted'] as int? ?? 0,
      hasReceivedPayout: json['hasReceivedPayout'] as bool? ?? false,
      startDate: DateTime.parse(json['startDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Equb copyWith({
    String? title,
    double? contributionAmount,
    String? cycleType,
    int? totalMembers,
    String? contributionDay,
    int? myPayoutRound,
    int? roundsCompleted,
    bool? hasReceivedPayout,
    DateTime? startDate,
    bool? isActive,
  }) {
    return Equb(
      id: id,
      title: title ?? this.title,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      cycleType: cycleType ?? this.cycleType,
      totalMembers: totalMembers ?? this.totalMembers,
      contributionDay: contributionDay ?? this.contributionDay,
      myPayoutRound: myPayoutRound ?? this.myPayoutRound,
      roundsCompleted: roundsCompleted ?? this.roundsCompleted,
      hasReceivedPayout: hasReceivedPayout ?? this.hasReceivedPayout,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
