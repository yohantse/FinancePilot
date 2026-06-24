import 'dart:math';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/equb.dart';
import '../models/profile.dart';

class FinancialHealth {
  final int overallScore;
  final int savingsRateScore;
  final int emergencyFundScore;
  final int debtRatioScore;
  final int investmentScore;
  final int stabilityScore;

  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> adviceList;

  FinancialHealth({
    required this.overallScore,
    required this.savingsRateScore,
    required this.emergencyFundScore,
    required this.debtRatioScore,
    required this.investmentScore,
    required this.stabilityScore,
    required this.strengths,
    required this.weaknesses,
    required this.adviceList,
  });
}

class FinanceRulesService {
  static FinancialHealth calculateHealth({
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Goal> goals,
    required List<Debt> debts,
    required List<Equb> equbs,
  }) {
    // 1. Determine Monthly Income
    // Use profile income, fallback to actual recent income if profile is zero
    final double monthlyIncome = profile.monthlyIncome > 0 ? profile.monthlyIncome : 10000.0;

    // 2. Determine Monthly Expenses (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final double recentExpenses = transactions
        .where((t) => t.type == 'expense' && t.date.isAfter(thirtyDaysAgo))
        .fold(0.0, (sum, t) => sum + t.amount);

    // If no recent transactions, assume basic expenses represent about 70% of income, or use profile debt obligations
    final double estimatedExpenses = recentExpenses > 0 ? recentExpenses : (monthlyIncome * 0.7);

    // 3. Savings Rate Score (25% Weight)
    // Savings Rate = (Income - Expenses) / Income
    final double actualSavings = max(0.0, monthlyIncome - recentExpenses);
    final double savingsRate = monthlyIncome > 0 ? (actualSavings / monthlyIncome) : 0.0;
    int savingsRateScore = 0;
    if (savingsRate >= 0.25) {
      savingsRateScore = 100;
    } else if (savingsRate >= 0.15) {
      savingsRateScore = 75;
    } else if (savingsRate >= 0.10) {
      savingsRateScore = 50;
    } else if (savingsRate >= 0.05) {
      savingsRateScore = 25;
    } else {
      savingsRateScore = 0;
    }

    // 4. Emergency Fund Score (25% Weight)
    // Find Emergency Fund Goal
    final emergencyGoal = goals.firstWhere(
      (g) => g.category == 'Emergency Fund',
      orElse: () => Goal(
        id: 'temp_ef',
        title: 'Emergency Fund',
        targetAmount: estimatedExpenses * profile.emergencyFundTargetMonths,
        currentSaved: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        category: 'Emergency Fund',
      ),
    );

    // Total savings in Hive box or allocated in Goals
    final double currentSavings = emergencyGoal.currentSaved;
    final double targetSavings = emergencyGoal.targetAmount > 0 
        ? emergencyGoal.targetAmount 
        : (estimatedExpenses * profile.emergencyFundTargetMonths);
    
    int emergencyFundScore = 0;
    if (targetSavings > 0) {
      final double ratio = currentSavings / targetSavings;
      emergencyFundScore = (ratio * 100).round();
      if (emergencyFundScore > 100) emergencyFundScore = 100;
    } else {
      emergencyFundScore = 100; // No expenses, so no emergency fund needed technically
    }

    // 5. Debt Ratio Score (20% Weight)
    // DTI = Monthly Debt Payments / Monthly Income
    final double monthlyDebtPayments = debts.fold(0.0, (sum, d) => sum + d.minimumMonthlyPayment) + 
        (profile.monthlyDebtObligation);
    final double dti = monthlyIncome > 0 ? (monthlyDebtPayments / monthlyIncome) : 0.0;
    int debtRatioScore = 100;
    if (dti <= 0.10) {
      debtRatioScore = 100;
    } else if (dti <= 0.20) {
      debtRatioScore = 80;
    } else if (dti <= 0.35) {
      debtRatioScore = 50;
    } else if (dti <= 0.45) {
      debtRatioScore = 25;
    } else {
      debtRatioScore = 0;
    }

    // 6. Investment Rate Score (15% Weight)
    // Investment Rate = Monthly Investments / Monthly Income
    final double monthlyInvestments = profile.currentInvestmentAllocation;
    final double investmentRate = monthlyIncome > 0 ? (monthlyInvestments / monthlyIncome) : 0.0;
    int investmentScore = 0;
    if (investmentRate >= 0.15) {
      investmentScore = 100;
    } else if (investmentRate >= 0.10) {
      investmentScore = 75;
    } else if (investmentRate >= 0.05) {
      investmentScore = 40;
    } else {
      investmentScore = 0;
    }

    // 7. Income Stability Score (15% Weight)
    int stabilityScore = 0;
    if (profile.hasStableIncome) {
      stabilityScore = 100;
    } else {
      // For daily earners, stability is 50, but rises if they have a healthy emergency fund (compensating buffer)
      stabilityScore = 50 + (emergencyFundScore * 0.5).round();
      if (stabilityScore > 100) stabilityScore = 100;
    }

    // 8. Overall Health Score (Weighted average)
    final double overall = (savingsRateScore * 0.25) +
        (emergencyFundScore * 0.25) +
        (debtRatioScore * 0.20) +
        (investmentScore * 0.15) +
        (stabilityScore * 0.15);
    final int overallScore = overall.round().clamp(0, 100);

    // 9. Strengths, Weaknesses, and Actions Generation (AI Coach Engine)
    final List<String> strengths = [];
    final List<String> weaknesses = [];
    final List<String> adviceList = [];

    final String currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';

    // Strengths analysis
    if (savingsRateScore >= 75) {
      strengths.add('High savings rate: You save ${(savingsRate * 100).toStringAsFixed(1)}% of your income.');
    }
    if (emergencyFundScore >= 80) {
      strengths.add('Robust emergency buffer: You have covered over 80% of your target reserve.');
    } else if (currentSavings > 0) {
      strengths.add('Active saver: You have started building an emergency buffer of ${currentSavings.toStringAsFixed(0)} $currencyStr.');
    }
    if (debtRatioScore >= 80) {
      strengths.add('Low debt burden: Your debt obligations are well within safe limits.');
    }
    if (investmentScore >= 75) {
      strengths.add('Wealth building: You are actively investing over 15% of your earnings.');
    }
    if (equbs.isNotEmpty) {
      final activeEqubs = equbs.where((e) => e.isActive).length;
      if (activeEqubs > 0) {
        strengths.add('Community-saving: You are participating in $activeEqubs active Equb group(s).');
      }
    }

    // Weaknesses analysis
    if (savingsRateScore < 50) {
      weaknesses.add('Low savings rate: You are saving less than 10% of your income. High vulnerability.');
    }
    if (emergencyFundScore < 40) {
      weaknesses.add('Inadequate emergency fund: You have less than 1.5 months of survival expenses reserved.');
    }
    if (debtRatioScore < 50) {
      weaknesses.add('High debt burden: Debt repayments consume over 35% of your monthly income.');
    }
    if (investmentScore == 0) {
      weaknesses.add('Lack of long-term investments: All excess capital is idle or spent instead of compounding.');
    }
    if (!profile.hasStableIncome && emergencyFundScore < 60) {
      weaknesses.add('High-risk profile: As a daily earner, your safety net is too small for income volatility.');
    }

    // Advice generation (Actions)
    if (emergencyFundScore < 100) {
      final double remainingEF = targetSavings - currentSavings;
      final int monthsNeeded = actualSavings > 0 ? (remainingEF / actualSavings).ceil() : 99;
      
      if (monthsNeeded <= 18) {
        adviceList.add(
          'Emergency Fund Focus: At your current savings rate, you will reach your ${profile.emergencyFundTargetMonths}-month emergency buffer in $monthsNeeded months. Maintain this priority.'
        );
      } else {
        final double suggestedMonthlyContribution = targetSavings / 12;
        adviceList.add(
          'Emergency Fund Warning: Your current savings rate is too slow. To secure a full safety net in 12 months, aim to allocate ${suggestedMonthlyContribution.toStringAsFixed(0)} $currencyStr/month.'
        );
      }
    }

    if (debtRatioScore < 80 && debts.isNotEmpty) {
      final highestInterestDebt = debts.reduce((a, b) => a.interestRate > b.interestRate ? a : b);
      adviceList.add(
        'Debt Paydown Priority: Prioritize clearing the "${highestInterestDebt.title}" loan (${highestInterestDebt.interestRate}% annual interest). Use any surplus income to pay more than the minimum.'
      );
    }

    // Custom Equb Advice (Ethiopian specific)
    final unpaidEqub = equbs.firstWhere((e) => e.isActive && !e.hasReceivedPayout, orElse: () => Equb(id: '', title: '', contributionAmount: 0, cycleType: '', totalMembers: 0, contributionDay: '', myPayoutRound: 0, startDate: DateTime.now()));
    if (unpaidEqub.id.isNotEmpty) {
      final double pot = unpaidEqub.totalPayoutPot;
      final int roundsRemaining = max(0, unpaidEqub.myPayoutRound - unpaidEqub.roundsCompleted);
      if (roundsRemaining > 0) {
        adviceList.add(
          'Equb Accelerator: You are scheduled to receive the "${unpaidEqub.title}" pot of ${pot.toStringAsFixed(0)} $currencyStr in approximately $roundsRemaining cycles. Plan to direct this entire lump sum into your emergency fund or clearing high-interest debts.'
        );
      } else if (unpaidEqub.myPayoutRound == unpaidEqub.roundsCompleted) {
        adviceList.add(
          'Equb Payout Alert: It is your turn to receive the "${unpaidEqub.title}" pot of ${pot.toStringAsFixed(0)} $currencyStr. Allocate this cash flow immediately to your top roadmap priorities.'
        );
      }
    }

    // Daily earner budgeting advice
    if (!profile.hasStableIncome) {
      adviceList.add(
        'Daily Earner Tip: Reconcile your cash and mobile money (Telebirr/CBE Birr) wallets daily. Move 20% of your daily income into savings immediately upon receipt before spending.'
      );
    }

    // Fallback if advice is empty
    if (adviceList.isEmpty) {
      adviceList.add('Excellent financial health! Consider accelerating your investment targets or expanding your long-term goals.');
    }

    return FinancialHealth(
      overallScore: overallScore,
      savingsRateScore: savingsRateScore,
      emergencyFundScore: emergencyFundScore,
      debtRatioScore: debtRatioScore,
      investmentScore: investmentScore,
      stabilityScore: stabilityScore,
      strengths: strengths,
      weaknesses: weaknesses,
      adviceList: adviceList,
    );
  }
}
