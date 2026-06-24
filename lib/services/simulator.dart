import 'dart:math';
import '../models/profile.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/equb.dart';
import '../models/transaction.dart';
import 'finance_rules.dart';

class SimulationDataPoint {
  final int monthIndex;
  final String monthName;
  final double projectedSavings;
  final double projectedDebt;
  final int projectedHealthScore;

  SimulationDataPoint({
    required this.monthIndex,
    required this.monthName,
    required this.projectedSavings,
    required this.projectedDebt,
    required this.projectedHealthScore,
  });
}

class SimulationResult {
  final List<SimulationDataPoint> timeline;
  final int finalHealthScore;
  final double finalSavings;
  final double finalDebt;
  final Map<String, int> goalTargetMonthsDiff; // Goal ID to months shifted (+ means delayed, - means accelerated)
  final String summaryAdvice;

  SimulationResult({
    required this.timeline,
    required this.finalHealthScore,
    required this.finalSavings,
    required this.finalDebt,
    required this.goalTargetMonthsDiff,
    required this.summaryAdvice,
  });
}

class SimulatorService {
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static SimulationResult run24MonthSimulation({
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required List<Debt> debts,
    required List<Equb> equbs,
    // What-If Scenarios
    double extraMonthlySavings = 0.0,
    double incomeIncreasePercent = 0.0, // e.g. 20.0 for 20%
    double majorPurchaseAmount = 0.0,
    double majorPurchaseDownPayment = 0.0,
    double majorPurchaseMonthlyCost = 0.0,
    int majorPurchaseMonthIndex = 3, // Month 1 to 24
  }) {
    final List<SimulationDataPoint> timeline = [];
    final Map<String, int> goalTargetMonthsDiff = {};

    // 1. Initial values from current state
    double baseIncome = profile.monthlyIncome > 0 ? profile.monthlyIncome : 10000.0;
    
    // Calculate current recent expenses
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final double recentExpenses = transactions
        .where((t) => t.type == 'expense' && t.date.isAfter(thirtyDaysAgo))
        .fold(0.0, (sum, t) => sum + t.amount);
    double baseExpenses = recentExpenses > 0 ? recentExpenses : (baseIncome * 0.7);

    // Initial reserves
    final emergencyGoal = goals.firstWhere(
      (g) => g.category == 'Emergency Fund',
      orElse: () => Goal(
        id: 'temp_ef',
        title: 'Emergency Fund',
        targetAmount: baseExpenses * profile.emergencyFundTargetMonths,
        currentSaved: 0.0,
        targetDate: now.add(const Duration(days: 365)),
        category: 'Emergency Fund',
      ),
    );
    double currentSavingsAccumulated = goals.fold(0.0, (sum, g) => sum + g.currentSaved);

    // Debts
    List<Debt> simulatedDebts = debts.map((d) => d.copyWith()).toList();

    // Create mutable goals for tracking completion
    List<Goal> simulatedGoals = goals.map((g) => g.copyWith()).toList();
    if (!simulatedGoals.any((g) => g.category == 'Emergency Fund')) {
      simulatedGoals.add(emergencyGoal);
    }

    final String currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';
    
    // Track months completed for each goal in simulation
    final Map<String, int> originalTargetMonths = {};
    final Map<String, int> simulatedCompletionMonths = {};
    
    for (var g in simulatedGoals) {
      originalTargetMonths[g.id] = g.getMonthsRemaining();
    }

    // Determine current month index for calendar names
    int startMonthNum = now.month - 1; // 0-indexed

    // Run month-by-month simulation for 24 months
    for (int m = 1; m <= 24; m++) {
      final monthName = _monthNames[(startMonthNum + m) % 12];

      // Apply What-If adjustments
      double monthIncome = baseIncome * (1 + (incomeIncreasePercent / 100));
      double monthExpenses = baseExpenses;
      
      // If major purchase happens this month
      if (m == majorPurchaseMonthIndex && majorPurchaseAmount > 0) {
        // Deduct down payment from savings
        currentSavingsAccumulated = max(0.0, currentSavingsAccumulated - majorPurchaseDownPayment);
      }
      
      // If major purchase has happened, add recurring monthly cost
      if (m >= majorPurchaseMonthIndex && majorPurchaseAmount > 0) {
        monthExpenses += majorPurchaseMonthlyCost;
      }

      // Calculate monthly surplus (Base Savings)
      double monthlySurplus = max(0.0, monthIncome - monthExpenses);
      
      // Add extra savings what-if
      monthlySurplus += extraMonthlySavings;

      // 1. Pay off debts first (Priority 1)
      double remainingSurplus = monthlySurplus;
      double totalMinimumDebtPayments = 0.0;

      // Make minimum payments first
      for (int i = 0; i < simulatedDebts.length; i++) {
        final d = simulatedDebts[i];
        if (d.remainingAmount > 0) {
          final payment = min(d.remainingAmount, d.minimumMonthlyPayment);
          totalMinimumDebtPayments += payment;
          
          // Apply interest and deduct payment
          double interest = (d.remainingAmount * (d.interestRate / 100)) / 12;
          double newRemaining = max(0.0, d.remainingAmount + interest - payment);
          simulatedDebts[i] = d.copyWith(remainingAmount: newRemaining);
        }
      }

      // Allocate remaining surplus as extra debt payment (Debt Snowball/Avalanche)
      if (remainingSurplus > totalMinimumDebtPayments) {
        remainingSurplus -= totalMinimumDebtPayments;
        
        // Find highest interest debt that is not fully paid
        simulatedDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
        for (int i = 0; i < simulatedDebts.length; i++) {
          final d = simulatedDebts[i];
          if (d.remainingAmount > 0 && remainingSurplus > 0) {
            final extraPayment = min(d.remainingAmount, remainingSurplus);
            final newRemaining = max(0.0, d.remainingAmount - extraPayment);
            simulatedDebts[i] = d.copyWith(remainingAmount: newRemaining);
            remainingSurplus -= extraPayment;
          }
        }
      } else {
        remainingSurplus = 0.0; // Surplus fully absorbed by minimum payments
      }

      // 2. Allocate remaining surplus to Goals (Priority 2)
      if (remainingSurplus > 0) {
        // Prioritize: Emergency Fund first, then others
        simulatedGoals.sort((a, b) {
          if (a.category == 'Emergency Fund') return -1;
          if (b.category == 'Emergency Fund') return 1;
          return a.targetDate.compareTo(b.targetDate);
        });

        for (int i = 0; i < simulatedGoals.length; i++) {
          final g = simulatedGoals[i];
          final remainingToSave = g.targetAmount - g.currentSaved;
          if (remainingToSave > 0 && remainingSurplus > 0) {
            final double contribution = min(remainingToSave, remainingSurplus);
            simulatedGoals[i] = g.copyWith(currentSaved: g.currentSaved + contribution);
            currentSavingsAccumulated += contribution;
            remainingSurplus -= contribution;

            // If goal is fully funded this month
            if (simulatedGoals[i].currentSaved >= simulatedGoals[i].targetAmount && 
                !simulatedCompletionMonths.containsKey(g.id)) {
              simulatedCompletionMonths[g.id] = m;
            }
          }
        }

        // If all goals are funded and surplus remains, it accumulates in cash savings
        if (remainingSurplus > 0) {
          currentSavingsAccumulated += remainingSurplus;
        }
      }

      // 3. Compute Projected Health Score for this future month
      final double totalRemainingDebt = simulatedDebts.fold(0.0, (sum, d) => sum + d.remainingAmount);
      
      // Dummy profile adaptation for rules engine
      final simProfile = profile.copyWith(
        monthlyIncome: monthIncome,
        monthlyDebtObligation: totalMinimumDebtPayments,
      );

      final tempHealth = FinanceRulesService.calculateHealth(
        profile: simProfile,
        transactions: transactions, // static history
        goals: simulatedGoals,
        debts: simulatedDebts,
        equbs: equbs,
      );

      timeline.add(SimulationDataPoint(
        monthIndex: m,
        monthName: monthName,
        projectedSavings: currentSavingsAccumulated,
        projectedDebt: totalRemainingDebt,
        projectedHealthScore: tempHealth.overallScore,
      ));
    }

    // Calculate goal shifts
    for (var g in goals) {
      final originalMonths = originalTargetMonths[g.id] ?? 24;
      final simulatedMonths = simulatedCompletionMonths[g.id];
      
      if (simulatedMonths != null) {
        // Difference: how much sooner or later they reach the goal
        goalTargetMonthsDiff[g.id] = simulatedMonths - originalMonths;
      } else {
        // If not completed in 24 months, check if it was originally, or estimate
        goalTargetMonthsDiff[g.id] = 24 - originalMonths; // Cap/placeholder
      }
    }

    // Generate summary explanation
    final finalDP = timeline.last;
    final startHealth = FinanceRulesService.calculateHealth(
      profile: profile,
      transactions: transactions,
      goals: goals,
      debts: debts,
      equbs: equbs,
    ).overallScore;

    final healthDiff = finalDP.projectedHealthScore - startHealth;
    String summaryAdvice = '';

    if (majorPurchaseAmount > 0 && majorPurchaseMonthIndex <= 24) {
      final totalDebtImpact = simulatedDebts.fold(0.0, (sum, d) => sum + d.remainingAmount);
      if (finalDP.projectedHealthScore < startHealth) {
        summaryAdvice = 'Buying this asset will decrease your Financial Health Score by ${healthDiff.abs()} points (to ${finalDP.projectedHealthScore}/100) due to the reduced emergency runway and added monthly expenses.';
      } else {
        summaryAdvice = 'You can comfortably absorb this purchase. Your final Health Score will be ${finalDP.projectedHealthScore}/100, showing strong resilience.';
      }
    } else if (extraMonthlySavings > 0 || incomeIncreasePercent > 0) {
      summaryAdvice = 'Excellent scenario! By increasing savings/earnings, your Financial Health Score rises from $startHealth to ${finalDP.projectedHealthScore}/100. ';
      
      // Mention goals accelerated
      final accelerated = goalTargetMonthsDiff.entries.where((e) => e.value < 0);
      if (accelerated.isNotEmpty) {
        final gNames = accelerated.map((e) {
          final g = goals.firstWhere((gl) => gl.id == e.key, orElse: () => emergencyGoal);
          return '"${g.title}" by ${e.value.abs()} months';
        }).join(', ');
        summaryAdvice += 'This accelerates your goals: $gNames.';
      } else {
        summaryAdvice += 'This adds an extra ${(finalDP.projectedSavings - currentSavingsAccumulated).toStringAsFixed(0)} $currencyStr in reserves by month 24.';
      }
    } else {
      summaryAdvice = 'Baseline projection: Without changes, your Financial Health Score will reach ${finalDP.projectedHealthScore}/100 in 24 months, with total savings of ${finalDP.projectedSavings.toStringAsFixed(0)} $currencyStr.';
    }

    return SimulationResult(
      timeline: timeline,
      finalHealthScore: finalDP.projectedHealthScore,
      finalSavings: finalDP.projectedSavings,
      finalDebt: finalDP.projectedDebt,
      goalTargetMonthsDiff: goalTargetMonthsDiff,
      summaryAdvice: summaryAdvice,
    );
  }
}
