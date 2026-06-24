import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_view.dart';
import 'transactions_view.dart';
import 'roadmap_view.dart';
import 'coach_view.dart';
import 'goals_view.dart';
import 'simulator_view.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction.dart';
import '../providers/financial_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const TransactionsView(),
    const RoadmapView(),
    const CoachView(),
    const GoalsView(),
    const SimulatorView(),
  ];

  void _showQuickLogDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'Food';
    String paymentMethod = 'Cash';
    String interval = 'none';

    final categories = {
      'income': ['Salary', 'Freelance', 'Business', 'Equb Payout', 'Gift', 'Other'],
      'expense': ['Food', 'Rent', 'Transport', 'Utilities', 'Equb Contribution', 'Loan Repayment', 'Entertainment', 'Other']
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Quick Log Transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle Type
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Expense')),
                            selected: type == 'expense',
                            selectedColor: AppTheme.danger.withAlpha(50),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  type = 'expense';
                                  category = 'Food';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Income')),
                            selected: type == 'income',
                            selectedColor: AppTheme.primary.withAlpha(50),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  type = 'income';
                                  category = 'Salary';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Title',
                        hintText: 'e.g. Lunch, CBE Salary, Telebirr payout',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (Birr)',
                        prefixText: 'ETB ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      dropdownColor: AppTheme.surface,
                      items: categories[type]!.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      dropdownColor: AppTheme.surface,
                      items: ['Cash', 'Telebirr', 'CBE Birr', 'Bank'].map((method) {
                        return DropdownMenuItem(value: method, child: Text(method));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => paymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Recurring Interval
                    DropdownButtonFormField<String>(
                      value: interval,
                      decoration: const InputDecoration(labelText: 'Recurring Frequency'),
                      dropdownColor: AppTheme.surface,
                      items: [
                        DropdownMenuItem(value: 'none', child: const Text('One-time')),
                        DropdownMenuItem(value: 'daily', child: const Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: const Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: const Text('Monthly')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => interval = val);
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
                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and amount.')),
                      );
                      return;
                    }

                    final newTx = Transaction.create(
                      title: title,
                      amount: amount,
                      category: category,
                      type: type,
                      paymentMethod: paymentMethod,
                      isRecurring: interval != 'none',
                      recurringInterval: interval,
                    );

                    ref.read(transactionsProvider.notifier).addTransaction(newTx);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged "$title" successfully!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'income' ? AppTheme.primary : AppTheme.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for Wide Desktop/Web screens
          if (isLargeScreen)
            NavigationRail(
              backgroundColor: AppTheme.background,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppTheme.primary),
              unselectedIconTheme: const IconThemeData(color: AppTheme.textSecondary),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'FinancePilot',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: FloatingActionButton(
                      onPressed: _showQuickLogDialog,
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Transactions'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: Text('Roadmap'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.psychology_outlined),
                  selectedIcon: Icon(Icons.psychology),
                  label: Text('Coach'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag),
                  label: Text('Goals & Equb'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Simulator'),
                ),
              ],
            ),
          // Active Page Content
          Expanded(
            child: SafeArea(child: _pages[_currentIndex]),
          ),
        ],
      ),
      // Bottom Navigation Bar for Mobile/Vertical screens
      bottomNavigationBar: !isLargeScreen
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: AppTheme.surface,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'Wallets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Roadmap',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_outlined),
                  activeIcon: Icon(Icons.psychology),
                  label: 'Coach',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.flag_outlined),
                  activeIcon: Icon(Icons.flag),
                  label: 'Goals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics),
                  label: 'What-If',
                ),
              ],
            )
          : null,
      floatingActionButton: !isLargeScreen
          ? FloatingActionButton(
              onPressed: _showQuickLogDialog,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
