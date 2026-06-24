import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction.dart';
import '../providers/financial_provider.dart';

class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key});

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  String _activeFilter = 'all'; // 'all', 'income', 'expense'

  // Dynamic wallet balance calculator
  Map<String, double> _calculateWalletBalances(List<Transaction> transactions) {
    double cash = 0.0;
    double telebirr = 0.0;
    double cbeBirr = 0.0;
    double bank = 0.0;

    for (var tx in transactions) {
      final amount = tx.amount;
      final isIncome = tx.type == 'income';
      
      switch (tx.paymentMethod) {
        case 'Cash':
          cash += isIncome ? amount : -amount;
          break;
        case 'Telebirr':
          telebirr += isIncome ? amount : -amount;
          break;
        case 'CBE Birr':
          cbeBirr += isIncome ? amount : -amount;
          break;
        case 'Bank':
          bank += isIncome ? amount : -amount;
          break;
      }
    }

    return {
      'Cash': cash,
      'Telebirr': telebirr,
      'CBE Birr': cbeBirr,
      'Bank': bank,
      'Total': cash + telebirr + cbeBirr + bank,
    };
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Salary':
      case 'Freelance':
        return Icons.work_outline;
      case 'Business':
        return Icons.storefront_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Rent':
        return Icons.home_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Utilities':
        return Icons.lightbulb_outline;
      case 'Equb Contribution':
      case 'Equb Payout':
        return Icons.groups_outlined;
      case 'Loan Repayment':
        return Icons.payment_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Equb')) return AppTheme.purple;
    if (category == 'Salary' || category == 'Freelance' || category == 'Business') return AppTheme.primary;
    if (category == 'Food' || category == 'Rent' || category == 'Transport' || category == 'Loan Repayment') return AppTheme.danger;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final profile = ref.watch(profileProvider);
    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';
    
    final wallets = _calculateWalletBalances(transactions);

    // Filtered list
    final filteredTransactions = transactions.where((tx) {
      if (_activeFilter == 'income') return tx.type == 'income';
      if (_activeFilter == 'expense') return tx.type == 'expense';
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallets & Cash Balance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // HORIZONTAL WALLET CARD SLIDER
            SizedBox(
              height: 115,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildWalletCard('Total Net Balance', wallets['Total']!, const Color(0xFF0EA5E9), Icons.account_balance_outlined, currencyStr),
                  const SizedBox(width: 12),
                  _buildWalletCard('Telebirr', wallets['Telebirr']!, const Color(0xFF10B981), Icons.phone_android_outlined, currencyStr),
                  const SizedBox(width: 12),
                  _buildWalletCard('CBE Birr', wallets['CBE Birr']!, const Color(0xFF8B5CF6), Icons.account_balance_wallet_outlined, currencyStr),
                  const SizedBox(width: 12),
                  _buildWalletCard('Cash Wallet', wallets['Cash']!, const Color(0xFFF59E0B), Icons.money_outlined, currencyStr),
                  const SizedBox(width: 12),
                  _buildWalletCard('Bank Account', wallets['Bank']!, const Color(0xFF3B82F6), Icons.credit_card_outlined, currencyStr),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TRANS LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Logs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Custom toggle chips
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Income', 'income'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Expense', 'expense'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // LIST CONTENT
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_outlined, color: AppTheme.textMuted, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No transactions logged yet.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Use the "+" button to log your first transaction.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final isIncome = tx.type == 'income';

                        return Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${tx.title}"'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    ref.read(transactionsProvider.notifier).addTransaction(tx);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(tx.category).withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(tx.category),
                                  color: _getCategoryColor(tx.category),
                                ),
                              ),
                              title: Text(
                                tx.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM d, yyyy').format(tx.date)} • ${tx.paymentMethod}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'} ${tx.amount.toStringAsFixed(0)} $currencyStr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome ? AppTheme.primary : AppTheme.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                                    onPressed: () {
                                      ref.read(transactionsProvider.notifier).deleteTransaction(tx.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(String title, double balance, Color accentColor, IconData icon, String currency) {
    final isNegative = balance < 0;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(50), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${balance.toStringAsFixed(0)} $currency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? AppTheme.danger : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isNegative ? 'Overdrawn' : 'Available',
                style: TextStyle(
                  fontSize: 9,
                  color: isNegative ? AppTheme.danger : AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;

    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFF2E3E53),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
