import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/hive_storage.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/debt.dart';
import '../models/equb.dart';
import '../services/finance_rules.dart';

// --- PROFILE PROVIDER ---
class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(UserProfile.defaultProfile()) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final map = HiveStorage.getMap(HiveStorage.profileBoxName, 'user_profile');
    if (map != null) {
      state = UserProfile.fromJson(map);
    }
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    state = newProfile;
    await HiveStorage.saveMap(HiveStorage.profileBoxName, 'user_profile', newProfile.toJson());
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  return ProfileNotifier();
});

// --- TRANSACTIONS PROVIDER ---
class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final list = HiveStorage.getList(HiveStorage.transactionsBoxName);
    state = list.map((json) => Transaction.fromJson(json)).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  Future<void> addTransaction(Transaction tx) async {
    final updatedList = [tx, ...state];
    state = updatedList;
    await _saveToHive();
  }

  Future<void> deleteTransaction(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    final listJson = state.map((t) => t.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.transactionsBoxName, listJson);
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier();
});

// --- GOALS PROVIDER ---
class GoalsNotifier extends StateNotifier<List<Goal>> {
  GoalsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final list = HiveStorage.getList(HiveStorage.goalsBoxName);
    final goals = list.map((json) => Goal.fromJson(json)).toList();
    
    // Ensure an Emergency Fund goal exists by default
    if (!goals.any((g) => g.category == 'Emergency Fund')) {
      final defaultEF = Goal.create(
        title: 'Emergency Fund',
        targetAmount: 36000.0, // Default target
        currentSaved: 5000.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        category: 'Emergency Fund',
        notes: 'Targeting 6 months of basic expenses.',
      );
      goals.add(defaultEF);
      HiveStorage.saveList(HiveStorage.goalsBoxName, goals.map((g) => g.toJson()).toList());
    }
    state = goals;
  }

  Future<void> addGoal(Goal goal) async {
    state = [...state, goal];
    await _saveToHive();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    state = state.map((g) => g.id == updatedGoal.id ? updatedGoal : g).toList();
    await _saveToHive();
  }

  Future<void> deleteGoal(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    final listJson = state.map((g) => g.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.goalsBoxName, listJson);
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  return GoalsNotifier();
});

// --- DEBTS PROVIDER ---
class DebtsNotifier extends StateNotifier<List<Debt>> {
  DebtsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final list = HiveStorage.getList(HiveStorage.debtsBoxName);
    state = list.map((json) => Debt.fromJson(json)).toList();
  }

  Future<void> addDebt(Debt debt) async {
    state = [...state, debt];
    await _saveToHive();
  }

  Future<void> updateDebt(Debt updatedDebt) async {
    state = state.map((d) => d.id == updatedDebt.id ? updatedDebt : d).toList();
    await _saveToHive();
  }

  Future<void> deleteDebt(String id) async {
    state = state.where((d) => d.id != id).toList();
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    final listJson = state.map((d) => d.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.debtsBoxName, listJson);
  }
}

final debtsProvider = StateNotifierProvider<DebtsNotifier, List<Debt>>((ref) {
  return DebtsNotifier();
});

// --- EQUBS PROVIDER ---
class EqubsNotifier extends StateNotifier<List<Equb>> {
  EqubsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final list = HiveStorage.getList(HiveStorage.equbsBoxName);
    state = list.map((json) => Equb.fromJson(json)).toList();
  }

  Future<void> addEqub(Equb equb) async {
    state = [...state, equb];
    await _saveToHive();
  }

  Future<void> updateEqub(Equb updatedEqub) async {
    state = state.map((e) => e.id == updatedEqub.id ? updatedEqub : e).toList();
    await _saveToHive();
  }

  Future<void> deleteEqub(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    final listJson = state.map((e) => e.toJson()).toList();
    await HiveStorage.saveList(HiveStorage.equbsBoxName, listJson);
  }
}

final equbsProvider = StateNotifierProvider<EqubsNotifier, List<Equb>>((ref) {
  return EqubsNotifier();
});

// --- COMBINED REACTIVE HEALTH PROVIDER ---
// This provider recalculates automatically if profile, transactions, goals, debts, or equbs change!
final financialHealthProvider = Provider<FinancialHealth>((ref) {
  final profile = ref.watch(profileProvider);
  final transactions = ref.watch(transactionsProvider);
  final goals = ref.watch(goalsProvider);
  final debts = ref.watch(debtsProvider);
  final equbs = ref.watch(equbsProvider);

  return FinanceRulesService.calculateHealth(
    profile: profile,
    transactions: transactions,
    goals: goals,
    debts: debts,
    equbs: equbs,
  );
});
