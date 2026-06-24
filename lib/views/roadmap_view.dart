import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/goal.dart';
import '../providers/financial_provider.dart';

class RoadmapView extends ConsumerWidget {
  const RoadmapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final goals = ref.watch(goalsProvider);
    final debts = ref.watch(debtsProvider);
    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';

    // 1. Core financial data extracts
    final double monthlyIncome = profile.monthlyIncome > 0 ? profile.monthlyIncome : 10000.0;
    // Estimate basic expenses as 70% of income
    final double basicExpenses = profile.monthlyDebtObligation > 0 
        ? profile.monthlyDebtObligation 
        : (monthlyIncome * 0.7);

    // 2. Locate Emergency Fund goal
    final efGoal = goals.firstWhere(
      (g) => g.category == 'Emergency Fund',
      orElse: () => Goal(
        id: 'temp_ef',
        title: 'Emergency Fund',
        targetAmount: basicExpenses * profile.emergencyFundTargetMonths,
        currentSaved: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        category: 'Emergency Fund',
      ),
    );

    final double totalSavings = efGoal.currentSaved;

    // --- STEP 1: STARTER EMERGENCY FUND (Target: 1 Month of Expenses) ---
    final double step1Target = basicExpenses;
    final double step1Saved = totalSavings.clamp(0.0, step1Target);
    final double step1Progress = step1Target > 0 ? (step1Saved / step1Target) : 1.0;
    final bool step1Completed = step1Progress >= 1.0;

    // --- STEP 2: PAY OFF HIGH-INTEREST DEBTS ---
    final double totalDebtOriginal = debts.fold(0.0, (sum, d) => sum + d.totalAmount);
    final double totalDebtRemaining = debts.fold(0.0, (sum, d) => sum + d.remainingAmount);
    final double totalDebtPaid = totalDebtOriginal - totalDebtRemaining;
    
    final bool hasDebts = debts.isNotEmpty && totalDebtRemaining > 0;
    final double step2Progress = totalDebtOriginal > 0 
        ? (totalDebtPaid / totalDebtOriginal).clamp(0.0, 1.0) 
        : 1.0;
    final bool step2Completed = !hasDebts || (step2Progress >= 1.0);
    
    // Step 2 is active if Step 1 is done AND we have debts
    final bool step2Active = step1Completed && hasDebts;

    // --- STEP 3: FULL EMERGENCY FUND (Target: 3-6 Months of Expenses) ---
    final double step3Target = efGoal.targetAmount;
    final double step3Saved = totalSavings.clamp(0.0, step3Target);
    final double step3Progress = step3Target > 0 ? (step3Saved / step3Target) : 1.0;
    final bool step3Completed = step3Progress >= 1.0;
    
    // Step 3 is active if Step 1 and Step 2 are completed (or no debts)
    final bool step3Active = step1Completed && step2Completed && !step3Completed;

    // --- STEP 4: INVEST & SAVE FOR GOALS ---
    final otherGoals = goals.where((g) => g.category != 'Emergency Fund').toList();
    final double step4Target = otherGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final double step4Saved = otherGoals.fold(0.0, (sum, g) => sum + g.currentSaved);
    final double step4Progress = step4Target > 0 ? (step4Saved / step4Target).clamp(0.0, 1.0) : 0.0;
    final bool step4Completed = otherGoals.isNotEmpty && step4Progress >= 1.0;
    
    // Step 4 active if full emergency fund is funded
    final bool step4Active = step3Completed;

    // Determine currently active step index for the GPS indicator
    int activeStepIndex = 1;
    if (step4Active) {
      activeStepIndex = 4;
    } else if (step3Active) {
      activeStepIndex = 3;
    } else if (step2Active) {
      activeStepIndex = 2;
    } else {
      activeStepIndex = 1;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial GPS Roadmap',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your personalized step-by-step navigation map. Complete each milestone in sequence.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // ROADMAP TIMELINE LIST
            _buildRoadmapStep(
              context: context,
              stepNum: 1,
              title: 'Build Starter Emergency Fund',
              description: 'Save 1 month of basic expenses as an immediate defensive shield. Prevents falling back into debt during small emergencies.',
              targetText: 'Target: ${step1Target.toStringAsFixed(0)} $currencyStr',
              savedText: 'Saved: ${step1Saved.toStringAsFixed(0)} $currencyStr',
              progress: step1Progress,
              isActive: activeStepIndex == 1,
              isCompleted: step1Completed,
              color: AppTheme.primary,
            ),
            
            _buildRoadmapConnector(activeStepIndex > 1),

            _buildRoadmapStep(
              context: context,
              stepNum: 2,
              title: 'Eradicate High-Interest Debt',
              description: debts.isEmpty
                  ? 'No outstanding debts logged. You can skip this step and accelerate directly to your full emergency reserve!'
                  : 'Pay off all non-mortgage debt. We recommend allocating all extra monthly surpluses using the snowball method.',
              targetText: debts.isEmpty ? '' : 'Total Debt: ${totalDebtOriginal.toStringAsFixed(0)} $currencyStr',
              savedText: debts.isEmpty ? '' : 'Paid Off: ${totalDebtPaid.toStringAsFixed(0)} $currencyStr',
              progress: debts.isEmpty ? 1.0 : step2Progress,
              isActive: activeStepIndex == 2,
              isCompleted: step2Completed,
              color: AppTheme.danger,
              isLocked: !step1Completed,
            ),
            
            _buildRoadmapConnector(activeStepIndex > 2),

            _buildRoadmapStep(
              context: context,
              stepNum: 3,
              title: 'Establish Full Emergency Reserve',
              description: 'Accumulate ${profile.emergencyFundTargetMonths} months of expenses. This guarantees peace of mind and complete insulation against income loss.',
              targetText: 'Target: ${step3Target.toStringAsFixed(0)} $currencyStr',
              savedText: 'Saved: ${step3Saved.toStringAsFixed(0)} $currencyStr',
              progress: step3Progress,
              isActive: activeStepIndex == 3,
              isCompleted: step3Completed,
              color: AppTheme.secondary,
              isLocked: !step1Completed || !step2Completed,
            ),
            
            _buildRoadmapConnector(activeStepIndex > 3),

            _buildRoadmapStep(
              context: context,
              stepNum: 4,
              title: 'Fund Life Goals & Invest',
              description: 'Now that you are bulletproof, allocate surplus income parallelly to custom goals (House, Car, Wedding, Equb) and long-term wealth investments.',
              targetText: otherGoals.isEmpty ? 'Set up savings goals in the "Goals" tab.' : 'Target: ${step4Target.toStringAsFixed(0)} $currencyStr',
              savedText: otherGoals.isEmpty ? '' : 'Accumulated: ${step4Saved.toStringAsFixed(0)} $currencyStr',
              progress: step4Progress,
              isActive: activeStepIndex == 4,
              isCompleted: step4Completed,
              color: AppTheme.purple,
              isLocked: !step3Completed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 30,
      width: 4,
      color: isActive ? AppTheme.primary.withAlpha(120) : AppTheme.surfaceLight,
    );
  }

  Widget _buildRoadmapStep({
    required BuildContext context,
    required int stepNum,
    required String title,
    required String description,
    required String targetText,
    required String savedText,
    required double progress,
    required bool isActive,
    required bool isCompleted,
    required Color color,
    bool isLocked = false,
  }) {
    Color stepColor = isCompleted 
        ? AppTheme.success 
        : (isActive ? color : AppTheme.textMuted);

    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceLight.withAlpha(60) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color.withAlpha(120) : const BorderSide(color: Color(0xFF2E3E53)).color,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Number Badge / Status Icon
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.success.withAlpha(40)
                          : (isActive ? color.withAlpha(40) : AppTheme.surfaceLight),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: stepColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: AppTheme.success, size: 20)
                          : (isLocked
                              ? const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 18)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isActive ? color : AppTheme.textSecondary,
                                  ),
                                )),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              // Step text & progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.success : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    if (!isLocked && targetText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(targetText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(savedText, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          color: stepColor,
                          backgroundColor: AppTheme.surfaceLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}% Completed',
                        style: TextStyle(fontSize: 10, color: stepColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
