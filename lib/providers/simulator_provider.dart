import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'financial_provider.dart';
import '../services/simulator.dart';

class SimulationInput {
  final double extraMonthlySavings;
  final double incomeIncreasePercent;
  final double majorPurchaseAmount;
  final double majorPurchaseDownPayment;
  final double majorPurchaseMonthlyCost;
  final int majorPurchaseMonthIndex;

  SimulationInput({
    this.extraMonthlySavings = 0.0,
    this.incomeIncreasePercent = 0.0,
    this.majorPurchaseAmount = 0.0,
    this.majorPurchaseDownPayment = 0.0,
    this.majorPurchaseMonthlyCost = 0.0,
    this.majorPurchaseMonthIndex = 3,
  });

  SimulationInput copyWith({
    double? extraMonthlySavings,
    double? incomeIncreasePercent,
    double? majorPurchaseAmount,
    double? majorPurchaseDownPayment,
    double? majorPurchaseMonthlyCost,
    int? majorPurchaseMonthIndex,
  }) {
    return SimulationInput(
      extraMonthlySavings: extraMonthlySavings ?? this.extraMonthlySavings,
      incomeIncreasePercent: incomeIncreasePercent ?? this.incomeIncreasePercent,
      majorPurchaseAmount: majorPurchaseAmount ?? this.majorPurchaseAmount,
      majorPurchaseDownPayment: majorPurchaseDownPayment ?? this.majorPurchaseDownPayment,
      majorPurchaseMonthlyCost: majorPurchaseMonthlyCost ?? this.majorPurchaseMonthlyCost,
      majorPurchaseMonthIndex: majorPurchaseMonthIndex ?? this.majorPurchaseMonthIndex,
    );
  }
}

class SimulatorInputNotifier extends StateNotifier<SimulationInput> {
  SimulatorInputNotifier() : super(SimulationInput());

  void setExtraMonthlySavings(double val) {
    state = state.copyWith(extraMonthlySavings: val);
  }

  void setIncomeIncreasePercent(double val) {
    state = state.copyWith(incomeIncreasePercent: val);
  }

  void setMajorPurchase(double amount, double downPayment, double monthlyCost, int monthIndex) {
    state = state.copyWith(
      majorPurchaseAmount: amount,
      majorPurchaseDownPayment: downPayment,
      majorPurchaseMonthlyCost: monthlyCost,
      majorPurchaseMonthIndex: monthIndex,
    );
  }

  void updateMajorPurchaseAmount(double val) {
    state = state.copyWith(majorPurchaseAmount: val);
  }

  void updateMajorPurchaseDownPayment(double val) {
    state = state.copyWith(majorPurchaseDownPayment: val);
  }

  void updateMajorPurchaseMonthlyCost(double val) {
    state = state.copyWith(majorPurchaseMonthlyCost: val);
  }

  void updateMajorPurchaseMonthIndex(int val) {
    state = state.copyWith(majorPurchaseMonthIndex: val);
  }

  void reset() {
    state = SimulationInput();
  }
}

// Sliders input state provider
final simulatorInputProvider = StateNotifierProvider<SimulatorInputNotifier, SimulationInput>((ref) {
  return SimulatorInputNotifier();
});

// Reactive simulation output provider
final simulationResultProvider = Provider<SimulationResult>((ref) {
  final input = ref.watch(simulatorInputProvider);
  
  final profile = ref.watch(profileProvider);
  final transactions = ref.watch(transactionsProvider);
  final goals = ref.watch(goalsProvider);
  final debts = ref.watch(debtsProvider);
  final equbs = ref.watch(equbsProvider);

  return SimulatorService.run24MonthSimulation(
    profile: profile,
    transactions: transactions,
    goals: goals,
    debts: debts,
    equbs: equbs,
    extraMonthlySavings: input.extraMonthlySavings,
    incomeIncreasePercent: input.incomeIncreasePercent,
    majorPurchaseAmount: input.majorPurchaseAmount,
    majorPurchaseDownPayment: input.majorPurchaseDownPayment,
    majorPurchaseMonthlyCost: input.majorPurchaseMonthlyCost,
    majorPurchaseMonthIndex: input.majorPurchaseMonthIndex,
  );
});
