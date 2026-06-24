import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/financial_provider.dart';

class CoachView extends ConsumerWidget {
  const CoachView({super.key});

  IconData _getAdviceIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('emergency') || lower.contains('buffer') || lower.contains('reserve')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('debt') || lower.contains('loan') || lower.contains('repayment')) {
      return Icons.money_off_outlined;
    }
    if (lower.contains('equb')) {
      return Icons.groups_outlined;
    }
    if (lower.contains('daily') || lower.contains('reconcile')) {
      return Icons.phone_android_outlined;
    }
    return Icons.psychology_outlined;
  }

  Color _getAdviceColor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('warning') || lower.contains('risk') || lower.contains('slow')) {
      return AppTheme.danger;
    }
    if (lower.contains('focus') || lower.contains('priority') || lower.contains('schedule')) {
      return AppTheme.secondary;
    }
    if (lower.contains('tip') || lower.contains('accelerator')) {
      return AppTheme.purple;
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);
    ref.watch(profileProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COACH BANNER HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: AppTheme.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Financial Coach',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Smart rules-based planning, not generic bookkeeping.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // LIVE RECOMMENDATIONS FEED
            Text(
              'Active Advisor Guidance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...health.adviceList.map((advice) {
              final color = _getAdviceColor(advice);
              final icon = _getAdviceIcon(advice);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              advice.split(':')[0], // Topic
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              advice.contains(':') ? advice.substring(advice.indexOf(':') + 1).trim() : advice,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // LEARN THE RULES PANEL
            Text(
              'How to Read Your Financial GPS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildEducationalCard(
              title: 'Emergency Fund: 3 vs 6 Months',
              description: 'Corporate employees with stable salaries can operate on a 3-month expense cushion. However, for freelancers, small business owners, and daily earners, income is volatile. A 6-month emergency buffer represents the baseline required to guarantee resilience during lean periods.',
              icon: Icons.shield_outlined,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 10),
            _buildEducationalCard(
              title: 'The 20% Savings Rate Standard',
              description: 'The golden rule of wealth building is saving at least 20% of your net monthly earnings. If you save below 10%, your financial safety is highly vulnerable to shocks. Allocating 20% guarantees you build assets and pay down debts rapidly.',
              icon: Icons.trending_up_outlined,
              color: AppTheme.secondary,
            ),
            const SizedBox(height: 10),
            _buildEducationalCard(
              title: 'Debt-to-Income (DTI) Limit of 36%',
              description: 'DTI is your total monthly debt payments divided by monthly income. Keeping your DTI below 15% is excellent. Exceeding 36% means too much cash flow is locked in repayment, causing massive vulnerability. Over 40% is considered high-risk.',
              icon: Icons.speed_outlined,
              color: AppTheme.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
