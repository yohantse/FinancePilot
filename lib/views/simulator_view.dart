import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/simulator_provider.dart';
import '../providers/financial_provider.dart';

class SimulatorView extends ConsumerWidget {
  const SimulatorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(simulatorInputProvider);
    final result = ref.watch(simulationResultProvider);
    final profile = ref.watch(profileProvider);
    final goals = ref.watch(goalsProvider);
    final currencyStr = profile.currency == 'ETB' ? 'Birr' : '\$';

    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    // Build chart data spots
    final List<FlSpot> savingsSpots = [];
    final List<FlSpot> debtSpots = [];
    
    for (int i = 0; i < result.timeline.length; i++) {
      final dp = result.timeline[i];
      savingsSpots.add(FlSpot(dp.monthIndex.toDouble(), dp.projectedSavings));
      debtSpots.add(FlSpot(dp.monthIndex.toDouble(), dp.projectedDebt));
    }

    // Determine max values for scaling chart axis nicely
    double maxVal = 50000.0;
    for (var dp in result.timeline) {
      if (dp.projectedSavings > maxVal) maxVal = dp.projectedSavings;
      if (dp.projectedDebt > maxVal) maxVal = dp.projectedDebt;
    }
    maxVal = (maxVal / 10000).ceil() * 10000.0; // Round up to nearest 10k

    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              ref.read(simulatorInputProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SCENARIO INPUT SLIDERS
            Text(
              'Adjust What-If Assumptions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Grid or Column layout depending on screen size
            if (isCompact) ...[
              _buildSliderCard(
                context: context,
                title: 'Save Extra Monthly',
                value: input.extraMonthlySavings,
                min: 0,
                max: 10000,
                divisions: 20,
                suffix: ' $currencyStr/mo',
                onChanged: (val) {
                  ref.read(simulatorInputProvider.notifier).setExtraMonthlySavings(val);
                },
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              _buildSliderCard(
                context: context,
                title: 'Salary Increase %',
                value: input.incomeIncreasePercent,
                min: 0,
                max: 100,
                divisions: 20,
                suffix: '%',
                onChanged: (val) {
                  ref.read(simulatorInputProvider.notifier).setIncomeIncreasePercent(val);
                },
                color: AppTheme.secondary,
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _buildSliderCard(
                      context: context,
                      title: 'Save Extra Monthly',
                      value: input.extraMonthlySavings,
                      min: 0,
                      max: 10000,
                      divisions: 20,
                      suffix: ' $currencyStr/mo',
                      onChanged: (val) {
                        ref.read(simulatorInputProvider.notifier).setExtraMonthlySavings(val);
                      },
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSliderCard(
                      context: context,
                      title: 'Salary Increase %',
                      value: input.incomeIncreasePercent,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      suffix: '%',
                      onChanged: (val) {
                        ref.read(simulatorInputProvider.notifier).setIncomeIncreasePercent(val);
                      },
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ASSET PURCHASE SIMULATION CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: AppTheme.purple, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Simulate Asset Purchase (e.g., Car, House)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: input.majorPurchaseAmount == 0.0 ? '' : input.majorPurchaseAmount.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total Cost', prefixText: 'ETB '),
                            onChanged: (val) {
                              final numVal = double.tryParse(val) ?? 0.0;
                              ref.read(simulatorInputProvider.notifier).updateMajorPurchaseAmount(numVal);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: input.majorPurchaseDownPayment == 0.0 ? '' : input.majorPurchaseDownPayment.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Down Payment', prefixText: 'ETB '),
                            onChanged: (val) {
                              final numVal = double.tryParse(val) ?? 0.0;
                              ref.read(simulatorInputProvider.notifier).updateMajorPurchaseDownPayment(numVal);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: input.majorPurchaseMonthlyCost == 0.0 ? '' : input.majorPurchaseMonthlyCost.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Monthly Cost (Fuel/Maintenance)', prefixText: 'ETB '),
                            onChanged: (val) {
                              final numVal = double.tryParse(val) ?? 0.0;
                              ref.read(simulatorInputProvider.notifier).updateMajorPurchaseMonthlyCost(numVal);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: input.majorPurchaseMonthIndex,
                            decoration: const InputDecoration(labelText: 'Purchase In'),
                            dropdownColor: AppTheme.surface,
                            items: List.generate(24, (i) {
                              return DropdownMenuItem(value: i + 1, child: Text('Month ${i + 1}'));
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(simulatorInputProvider.notifier).updateMajorPurchaseMonthIndex(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SIMULATION GPS FORECAST BANNER
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withAlpha(80), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PROJECTED SCENARIO OUTCOME',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Score: ${result.finalHealthScore}/100',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.summaryAdvice,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // LINE CHART VISUALIZATION
            Text(
              '24-Month Balance Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visualizing savings reserves (Teal) vs outstanding debt liabilities (Red).',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // FlChart Line Chart
            Container(
              height: 220,
              padding: const EdgeInsets.only(right: 16, left: 6),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.surfaceLight.withAlpha(50),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0 || value > 24) return const SizedBox();
                          return Text(
                            'M${value.toInt()}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10));
                          final kAmount = (value / 1000).toStringAsFixed(0);
                          return Text(
                            '${kAmount}k',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: 24,
                  minY: 0,
                  maxY: maxVal,
                  lineBarsData: [
                    // Savings Line (Teal)
                    LineChartBarData(
                      spots: savingsSpots,
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withAlpha(20),
                      ),
                    ),
                    // Debt Line (Red)
                    LineChartBarData(
                      spots: debtSpots,
                      isCurved: true,
                      color: AppTheme.danger,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.danger.withAlpha(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // GOAL IMPACT LIST
            if (goals.length > 1) ...[
              Text(
                'Assumptions Impact on Goals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...result.goalTargetMonthsDiff.entries.map((entry) {
                final g = goals.firstWhere((gl) => gl.id == entry.key, orElse: () => goals.first);
                if (g.category == 'Emergency Fund') return const SizedBox(); // EF is baseline
                
                final val = entry.value;
                final isDelayed = val > 0;
                final isAccelerated = val < 0;
                // final isUnchanged = val == 0;

                Color diffColor = AppTheme.textSecondary;
                String diffText = 'No impact';
                IconData diffIcon = Icons.remove_circle_outline;

                if (isAccelerated) {
                  diffColor = AppTheme.success;
                  diffText = 'Accelerated by ${val.abs()} months!';
                  diffIcon = Icons.offline_bolt_outlined;
                } else if (isDelayed) {
                  diffColor = AppTheme.danger;
                  diffText = 'Delayed by $val months';
                  diffIcon = Icons.hourglass_empty_outlined;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(diffIcon, color: diffColor),
                    title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      'Original target: ${DateFormat('MMM yyyy').format(g.targetDate)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      diffText,
                      style: TextStyle(fontWeight: FontWeight.bold, color: diffColor, fontSize: 12),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                Text(
                  '${value.toStringAsFixed(0)}$suffix',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
