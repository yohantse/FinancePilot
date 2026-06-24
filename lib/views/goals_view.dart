import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/goal.dart';
import '../models/equb.dart';
import '../models/transaction.dart';
import '../providers/financial_provider.dart';

class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends ConsumerState<GoalsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentSavedController = TextEditingController(text: '0');
    String category = 'House';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Saving Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g. Buy a Toyota Vitz, Wedding'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Target Amount (Birr)', prefixText: 'ETB '),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentSavedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Current Saved (Birr)', prefixText: 'ETB '),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      dropdownColor: AppTheme.surface,
                      items: ['Emergency Fund', 'House', 'Car', 'Wedding', 'Vacation', 'Business', 'Retirement'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target Date:', style: TextStyle(fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(DateFormat('MMM yyyy').format(selectedDate)),
                          onPressed: () async {
                            final picker = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picker != null) {
                              setDialogState(() => selectedDate = picker);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final target = double.tryParse(targetController.text.trim()) ?? 0.0;
                    final saved = double.tryParse(currentSavedController.text.trim()) ?? 0.0;

                    if (title.isEmpty || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and target amount.')),
                      );
                      return;
                    }

                    final newGoal = Goal.create(
                      title: title,
                      targetAmount: target,
                      currentSaved: saved,
                      targetDate: selectedDate,
                      category: category,
                    );

                    ref.read(goalsProvider.notifier).addGoal(newGoal);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEqubDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final membersController = TextEditingController(text: '10');
    final payoutRoundController = TextEditingController(text: '5');
    String cycleType = 'weekly';
    String contributionDay = 'Monday';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create Equb Planner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Equb Name', hintText: 'e.g. Neighborhood Equb, Shop Keepers'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Contribution / Cycle', prefixText: 'ETB '),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: membersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Members (Duration in cycles)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: payoutRoundController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'My Payout Round (Lottery/Schedule)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cycleType,
                      decoration: const InputDecoration(labelText: 'Cycle Frequency'),
                      dropdownColor: AppTheme.surface,
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => cycleType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: contributionDay,
                      decoration: const InputDecoration(labelText: 'Contribution Day'),
                      dropdownColor: AppTheme.surface,
                      items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => contributionDay = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    final members = int.tryParse(membersController.text.trim()) ?? 10;
                    final payoutRound = int.tryParse(payoutRoundController.text.trim()) ?? 1;

                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and contribution amount.')),
                      );
                      return;
                    }

                    final newEqub = Equb.create(
                      title: title,
                      contributionAmount: amount,
                      cycleType: cycleType,
                      totalMembers: members,
                      contributionDay: contributionDay,
                      myPayoutRound: payoutRound,
                    );

                    ref.read(equbsProvider.notifier).addEqub(newEqub);
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleEqubContribution(Equb equb) {
    if (equb.roundsCompleted >= equb.totalMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This Equb cycle has already finished!')),
      );
      return;
    }

    final nextRound = equb.roundsCompleted + 1;
    final isPayoutRound = nextRound == equb.myPayoutRound;

    // 1. Log contribution expense transaction
    final contributionTx = Transaction.create(
      title: 'Equb contribution: ${equb.title} (R$nextRound)',
      amount: equb.contributionAmount,
      category: 'Equb Contribution',
      type: 'expense',
      paymentMethod: 'Cash', // Default Cash, can be changed
      notes: 'Equb contribution round $nextRound of ${equb.totalMembers}',
    );
    ref.read(transactionsProvider.notifier).addTransaction(contributionTx);

    // 2. Update Equb round
    var updatedEqub = equb.copyWith(
      roundsCompleted: nextRound,
    );

    // 3. Check if we hit the payout round
    if (isPayoutRound) {
      updatedEqub = updatedEqub.copyWith(hasReceivedPayout: true);
      
      // Log the payout income transaction
      final payoutPot = equb.totalPayoutPot;
      final payoutTx = Transaction.create(
        title: 'Equb Payout POT: ${equb.title}',
        amount: payoutPot,
        category: 'Equb Payout',
        type: 'income',
        paymentMethod: 'Cash',
        notes: 'Lump-sum payout pot collected in round $nextRound.',
      );
      ref.read(transactionsProvider.notifier).addTransaction(payoutTx);

      // Trigger Celebration Dialog
      _showEqubWinnerDialog(equb.title, payoutPot);
    }

    ref.read(equbsProvider.notifier).updateEqub(updatedEqub);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${equb.contributionAmount} Birr contribution for "${equb.title}".'),
        backgroundColor: isPayoutRound ? AppTheme.success : AppTheme.secondary,
      ),
    );
  }

  void _showEqubWinnerDialog(String title, double potAmount) {
    final profile = ref.read(profileProvider);
    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: AppTheme.accent, size: 48),
              SizedBox(height: 8),
              Text('Equb Payout Received!', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations! It is your round to collect the "$title" savings pot!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${potAmount.toStringAsFixed(0)} $currencyStr',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.success),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GPS Recommendation: Allocate at least 50% of this lump sum directly to your Emergency Fund, or clear outstanding loan balances.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Awesome, Log Payout!'),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getGoalIcon(String cat) {
    switch (cat) {
      case 'Emergency Fund':
        return Icons.shield_outlined;
      case 'House':
        return Icons.home_outlined;
      case 'Car':
        return Icons.directions_car_outlined;
      case 'Wedding':
        return Icons.favorite_border_outlined;
      case 'Business':
        return Icons.storefront_outlined;
      case 'Retirement':
        return Icons.elderly_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _getGoalColor(String cat) {
    switch (cat) {
      case 'Emergency Fund':
        return AppTheme.primary;
      case 'House':
        return AppTheme.secondary;
      case 'Car':
        return AppTheme.danger;
      case 'Business':
        return AppTheme.purple;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final equbs = ref.watch(equbsProvider);
    final profile = ref.watch(profileProvider);
    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Equb Planners'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Savings Goals', icon: Icon(Icons.track_changes_outlined, size: 20)),
            Tab(text: 'Traditional Equb', icon: Icon(Icons.groups_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SAVINGS GOALS VIEW
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Saving Plans',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Goal', style: TextStyle(fontSize: 12)),
                      onPressed: _showAddGoalDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: goals.isEmpty
                      ? const Center(child: Text('No custom goals configured.'))
                      : ListView.builder(
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            final g = goals[index];
                            final color = _getGoalColor(g.category);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(30),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(_getGoalIcon(g.category), color: color),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(
                                                'Deadline: ${DateFormat('MMM yyyy').format(g.targetDate)} • ${g.getMonthsRemaining()} months left',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quick Delete Button
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                                          onPressed: () {
                                            if (g.category == 'Emergency Fund') {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Core Emergency Fund goal cannot be deleted.')),
                                              );
                                              return;
                                            }
                                            ref.read(goalsProvider.notifier).deleteGoal(g.id);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${g.currentSaved.toStringAsFixed(0)} / ${g.targetAmount.toStringAsFixed(0)} $currencyStr',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          '${g.progressPercentage.toStringAsFixed(0)}%',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: g.progressPercentage / 100,
                                        minHeight: 6,
                                        color: color,
                                        backgroundColor: AppTheme.surfaceLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Required Savings GPS Advice
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceLight.withAlpha(50),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'GPS Required Savings Rate:',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                          Text(
                                            '${g.requiredMonthlySavings.toStringAsFixed(0)} $currencyStr/month',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // 2. ETHIOPIAN EQUB VIEW
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Traditional Equb Planners',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Join Equb', style: TextStyle(fontSize: 12)),
                      onPressed: _showAddEqubDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'A traditional Ethiopian community savings group. Members contribute a fixed amount each cycle, and one member takes the full pot in turns.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: equbs.isEmpty
                      ? const Center(
                          child: Text(
                            'No Equbs configured yet.\nTap "Join Equb" to start tracking!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: equbs.length,
                          itemBuilder: (context, index) {
                            final eq = equbs[index];
                            final roundsLeft = eq.totalMembers - eq.roundsCompleted;
                            final hasFinished = roundsLeft <= 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppTheme.purple.withAlpha(30),
                                              child: const Icon(Icons.groups_rounded, color: AppTheme.purple),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(eq.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                Text(
                                                  '${eq.cycleType.toUpperCase()} • ${eq.contributionDay}',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Delete
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                                          onPressed: () {
                                            ref.read(equbsProvider.notifier).deleteEqub(eq.id);
                                          },
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: AppTheme.surfaceLight),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildEqubMetric('Contribution', '${eq.contributionAmount.toStringAsFixed(0)} $currencyStr'),
                                        _buildEqubMetric('Total Payout Pot', '${eq.totalPayoutPot.toStringAsFixed(0)} $currencyStr'),
                                        _buildEqubMetric('My Payout Cycle', 'Round ${eq.myPayoutRound}'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Cycle Progress: Round ${eq.roundsCompleted} of ${eq.totalMembers}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                        Text(
                                          eq.hasReceivedPayout ? 'Pot Collected' : 'Pending Payout',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: eq.hasReceivedPayout ? AppTheme.success : AppTheme.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: eq.progressPercentage / 100,
                                        minHeight: 6,
                                        color: AppTheme.purple,
                                        backgroundColor: AppTheme.surfaceLight,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Action Buttons
                                    if (!hasFinished)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.payments_outlined, size: 16),
                                              label: const Text('Pay Contribution'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.purple,
                                                side: const BorderSide(color: AppTheme.purple),
                                              ),
                                              onPressed: () => _handleEqubContribution(eq),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      const Center(
                                        child: Text(
                                          'This Equb cycle has concluded successfully.',
                                          style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqubMetric(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
