import 'package:flutter_test/flutter_test.dart';
import 'package:finance_pilot/models/profile.dart';
import 'package:finance_pilot/models/goal.dart';
import 'package:finance_pilot/models/debt.dart';
import 'package:finance_pilot/models/transaction.dart';
import 'package:finance_pilot/services/finance_rules.dart';
import 'package:finance_pilot/services/simulator.dart';

void main() {
  group('Goal Savings calculations', () {
    test('Calculates correct required monthly savings when deadline is in the future', () {
      final targetDate = DateTime.now().add(const Duration(days: 730)); // 24 months
      final goal = Goal(
        id: 'test_goal',
        title: 'Buy a Car',
        targetAmount: 12000.0,
        currentSaved: 0.0,
        targetDate: targetDate,
        category: 'Car',
      );

      // 12,000 Birr over 24 months should be 500 Birr/month
      expect(goal.requiredMonthlySavings, closeTo(500.0, 5.0));
    });

    test('Calculates correct savings progress percentage', () {
      final goal = Goal(
        id: 'test_goal',
        title: 'Emergency Fund',
        targetAmount: 10000.0,
        currentSaved: 4500.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        category: 'Emergency Fund',
      );

      expect(goal.progressPercentage, equals(45.0));
    });
  });

  group('Financial Rule Engine - Health Score', () {
    test('Calculates high score for a stable salaried user with no debt and high savings rate', () {
      final profile = UserProfile(
        name: 'Stable User',
        incomeType: 'salaried',
        monthlyIncome: 20000.0,
        monthlyDebtObligation: 0.0,
        emergencyFundTargetMonths: 3,
        hasStableIncome: true,
        currentInvestmentAllocation: 3000.0, // 15% investment rate
      );

      // Low recent expenses (high actual savings rate)
      final transactions = [
        Transaction(
          id: 'tx1',
          title: 'Freelance pay',
          amount: 20000.0,
          category: 'Salary',
          type: 'income',
          date: DateTime.now(),
          paymentMethod: 'Bank',
        ),
        Transaction(
          id: 'tx2',
          title: 'Food',
          amount: 4000.0, // only 4,000 expense
          category: 'Food',
          type: 'expense',
          date: DateTime.now(),
          paymentMethod: 'Cash',
        ),
      ];

      // Fully funded emergency fund
      final goals = [
        Goal(
          id: 'ef',
          title: 'Emergency Fund',
          targetAmount: 12000.0, // 3 months of 4k expenses = 12k
          currentSaved: 12000.0, // 100% funded
          targetDate: DateTime.now().add(const Duration(days: 100)),
          category: 'Emergency Fund',
        ),
      ];

      final health = FinanceRulesService.calculateHealth(
        profile: profile,
        transactions: transactions,
        goals: goals,
        debts: [],
        equbs: [],
      );

      // Score should be excellent (>= 90) because no debt, high savings rate, and fully funded emergency reserve
      expect(health.overallScore, greaterThanOrEqualTo(90));
      expect(health.strengths, contains(contains('savings rate')));
      expect(health.weaknesses, isEmpty);
    });

    test('Calculates lower score for a daily earner with high debt and low savings rate', () {
      final profile = UserProfile(
        name: 'Vulnerable User',
        incomeType: 'daily_earner',
        monthlyIncome: 8000.0,
        monthlyDebtObligation: 3500.0, // High debt ratio ( rent + loans )
        emergencyFundTargetMonths: 6,
        hasStableIncome: false,
        currentInvestmentAllocation: 0.0,
      );

      // Low savings because expenses are close to income
      final transactions = [
        Transaction(
          id: 'tx1',
          title: 'Rent and utilities',
          amount: 7500.0,
          category: 'Rent',
          type: 'expense',
          date: DateTime.now(),
          paymentMethod: 'Cash',
        ),
      ];

      final goals = [
        Goal(
          id: 'ef',
          title: 'Emergency Fund',
          targetAmount: 45000.0,
          currentSaved: 1000.0, // Tiny emergency fund
          targetDate: DateTime.now().add(const Duration(days: 365)),
          category: 'Emergency Fund',
        ),
      ];

      final debts = [
        Debt(
          id: 'debt1',
          title: 'CBE Loan',
          totalAmount: 15000.0,
          remainingAmount: 15000.0,
          interestRate: 15.0,
          minimumMonthlyPayment: 1500.0,
        ),
      ];

      final health = FinanceRulesService.calculateHealth(
        profile: profile,
        transactions: transactions,
        goals: goals,
        debts: debts,
        equbs: [],
      );

      // Score should be low (< 55) because emergency fund is lacking, DTI is high, and savings rate is poor
      expect(health.overallScore, lessThan(55));
      expect(health.weaknesses, contains(contains('emergency fund')));
    });
  });

  group('What-If Simulator Projections', () {
    test('Simulates 24-month savings growth and debt reduction correctly', () {
      final profile = UserProfile(
        name: 'Test Simulator',
        incomeType: 'salaried',
        monthlyIncome: 10000.0,
        emergencyFundTargetMonths: 3,
        hasStableIncome: true,
      );

      final goals = [
        Goal(
          id: 'ef',
          title: 'Emergency Fund',
          targetAmount: 15000.0,
          currentSaved: 5000.0,
          targetDate: DateTime.now().add(const Duration(days: 365)),
          category: 'Emergency Fund',
        ),
      ];

      final debts = [
        Debt(
          id: 'debt',
          title: 'Personal Loan',
          totalAmount: 4000.0,
          remainingAmount: 4000.0,
          interestRate: 0.0, // interest free for simple test
          minimumMonthlyPayment: 500.0,
        ),
      ];

      // Run simulation with 1,500 extra monthly savings what-if
      final result = SimulatorService.run24MonthSimulation(
        profile: profile,
        transactions: [],
        goals: goals,
        debts: debts,
        equbs: [],
        extraMonthlySavings: 1500.0,
      );

      // Check results
      expect(result.timeline.length, equals(24));
      // By month 24, savings should grow significantly, and debt should be fully cleared (0.0)
      expect(result.finalDebt, equals(0.0));
      expect(result.finalSavings, greaterThan(15000.0));
      expect(result.finalHealthScore, greaterThan(80));
    });
  });
}
