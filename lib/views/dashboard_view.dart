import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/profile.dart';
import '../models/goal.dart';
import '../providers/financial_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  void _showProfileEditSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final incomeController = TextEditingController(text: profile.monthlyIncome.toString());
    final debtController = TextEditingController(text: profile.monthlyDebtObligation.toString());
    final investmentController = TextEditingController(text: profile.currentInvestmentAllocation.toString());
    
    String incomeType = profile.incomeType;
    bool hasStableIncome = profile.hasStableIncome;
    String currency = profile.currency;
    int targetMonths = profile.emergencyFundTargetMonths;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust Financial Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: incomeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Average Monthly Income',
                        prefixText: 'ETB ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: debtController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rent & Existing Loan Payments / Month',
                        prefixText: 'ETB ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: investmentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Investment Allocation',
                        prefixText: 'ETB ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Income Type Selector
                    Text('Income Type', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Salaried')),
                            selected: incomeType == 'salaried',
                            onSelected: (val) {
                              if (val) {
                                setSheetState(() {
                                  incomeType = 'salaried';
                                  hasStableIncome = true;
                                  targetMonths = 3; // 3 months emergency fund for salaried
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Daily Earner')),
                            selected: incomeType == 'daily_earner',
                            onSelected: (val) {
                              if (val) {
                                setSheetState(() {
                                  incomeType = 'daily_earner';
                                  hasStableIncome = false;
                                  targetMonths = 6; // 6 months emergency fund for daily earners
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Currency Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Default Currency'),
                        DropdownButton<String>(
                          value: currency,
                          dropdownColor: AppTheme.surface,
                          items: const [
                            DropdownMenuItem(value: 'ETB', child: Text('Birr (ETB)')),
                            DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => currency = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Emergency target months
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Emergency Fund Buffer: $targetMonths Months'),
                        SizedBox(
                          width: 150,
                          child: Slider(
                            value: targetMonths.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            onChanged: (val) {
                              setSheetState(() => targetMonths = val.round());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final income = double.tryParse(incomeController.text.trim()) ?? 0.0;
                          final debt = double.tryParse(debtController.text.trim()) ?? 0.0;
                          final invest = double.tryParse(investmentController.text.trim()) ?? 0.0;

                          final updated = UserProfile(
                            name: name.isNotEmpty ? name : profile.name,
                            incomeType: incomeType,
                            monthlyIncome: income,
                            monthlyDebtObligation: debt,
                            emergencyFundTargetMonths: targetMonths,
                            currency: currency,
                            hasStableIncome: hasStableIncome,
                            currentInvestmentAllocation: invest,
                          );

                          ref.read(profileProvider.notifier).updateProfile(updated);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Financial profile updated successfully!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Update Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 50) return AppTheme.accent;
    return AppTheme.danger;
  }

  String _getScoreRating(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Vulnerable';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final health = ref.watch(financialHealthProvider);
    // final transactions = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);

    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';
    
    // Active roadmap step
    String nextMoveTitle = 'Starter Emergency Fund';
    double nextMoveProgress = 0.0;
    String nextMoveDetail = 'Build an initial 1-month buffer.';

    final efGoal = goals.firstWhere(
      (g) => g.category == 'Emergency Fund',
      orElse: () => Goal(
        id: 'temp',
        title: 'Emergency Fund',
        targetAmount: profile.monthlyIncome * 0.5,
        currentSaved: 0.0,
        targetDate: DateTime.now(),
        category: 'Emergency Fund',
      ),
    );

    if (efGoal.currentSaved < (efGoal.targetAmount * 0.2)) {
      nextMoveTitle = 'Build Starter Buffer';
      nextMoveProgress = efGoal.currentSaved / (efGoal.targetAmount * 0.2);
      nextMoveDetail = 'Aim to save first ${(efGoal.targetAmount * 0.2).toStringAsFixed(0)} $currencyStr as a protective buffer.';
    } else if (efGoal.progressPercentage < 100) {
      nextMoveTitle = 'Complete Full Emergency Reserve';
      nextMoveProgress = efGoal.currentSaved / efGoal.targetAmount;
      nextMoveDetail = 'Build your full ${profile.emergencyFundTargetMonths}-month reserve of ${efGoal.targetAmount.toStringAsFixed(0)} $currencyStr.';
    } else {
      nextMoveTitle = 'Accelerate Long-term Goals';
      nextMoveProgress = 1.0;
      nextMoveDetail = 'Your emergency reserve is funded. Start directing surpluses into investments or custom goals.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showProfileEditSheet(context, ref, profile),
              child: CircleAvatar(
                backgroundColor: AppTheme.primary.withAlpha(40),
                child: const Icon(Icons.person, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${profile.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile.incomeType == 'daily_earner' ? 'Daily Earner • ETB' : 'Salaried • ETB',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppTheme.textSecondary),
            onPressed: () => _showProfileEditSheet(context, ref, profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DYNAMIC FINANCIAL HEALTH GAUGE CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Dial Gauge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: health.overallScore / 100,
                            strokeWidth: 10,
                            color: _getScoreColor(health.overallScore),
                            backgroundColor: AppTheme.surfaceLight,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${health.overallScore}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Summary description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getScoreColor(health.overallScore).withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getScoreRating(health.overallScore),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(health.overallScore),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Financial GPS Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.incomeType == 'daily_earner'
                                ? 'Adjusted for daily earnings and high income volatility.'
                                : 'Calculated for stable monthly salaried employment.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // NEXT BEST MOVE GPS NAVIGATION CARD
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E38), Color(0xFF16202A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.secondary.withAlpha(80), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.navigation_outlined, color: AppTheme.secondary),
                        const SizedBox(width: 8),
                        const Text(
                          'YOUR NEXT BEST MOVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nextMoveTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextMoveDetail,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: nextMoveProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        color: AppTheme.secondary,
                        backgroundColor: AppTheme.surfaceLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: ${(nextMoveProgress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const Text(
                          'GPS Active',
                          style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DYNAMIC STRENGTHS & WEAKNESSES CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rule-Engine Findings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Strengths
                    if (health.strengths.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'STRENGTHS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...health.strengths.map((str) => Padding(
                            padding: const EdgeInsets.only(left: 26.0, bottom: 8.0),
                            child: Text('• $str', style: const TextStyle(fontSize: 13)),
                          )),
                    ],

                    const SizedBox(height: 12),

                    // Weaknesses
                    if (health.weaknesses.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'WEAKNESSES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...health.weaknesses.map((weak) => Padding(
                            padding: const EdgeInsets.only(left: 26.0, bottom: 8.0),
                            child: Text('• $weak', style: const TextStyle(fontSize: 13)),
                          )),
                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'No weaknesses found. Outstanding discipline!',
                            style: TextStyle(fontSize: 13, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CASH FLOW SUMMARY SUMMARY
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Cash Flow Budget',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCashFlowItem('Monthly Income', profile.monthlyIncome, AppTheme.primary, currencyStr),
                        _buildCashFlowItem('Declared Debts', profile.monthlyDebtObligation, AppTheme.danger, currencyStr),
                        _buildCashFlowItem('Savings Target', profile.currentInvestmentAllocation, AppTheme.purple, currencyStr),
                      ],
                    ),
                    const Divider(height: 24, color: AppTheme.surfaceLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Surplus Runway:',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${(profile.monthlyIncome - profile.monthlyDebtObligation - profile.currentInvestmentAllocation).toStringAsFixed(0)} $currencyStr',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowItem(String label, double amount, Color color, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(0)} $currency',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
