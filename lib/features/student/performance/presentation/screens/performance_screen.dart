import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/performance_entity.dart';
import '../bloc/performance_bloc.dart';

/// Performance Dashboard Screen
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  void _loadPerformance() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user != null) {
      if (_selectedDateRange != null) {
        context.read<PerformanceBloc>().add(
          PerformanceLoadByDateRange(
            studentId: authState.user!.id,
            startDate: _selectedDateRange!.start,
            endDate: _selectedDateRange!.end,
          ),
        );
      } else {
        context.read<PerformanceBloc>().add(
          PerformanceLoadRequested(studentId: authState.user!.id),
        );
      }
    }
  }

  String get _dateRangeText {
    if (_selectedDateRange == null) return 'All Time';
    final formatter = DateFormat('MMM d');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _selectedDateRange = result);
      _loadPerformance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dateRangeText, style: const TextStyle(fontSize: 12)),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: BlocBuilder<PerformanceBloc, PerformanceState>(
        builder: (context, state) {
          if (state.status == PerformanceStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PerformanceStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.errorMessage ?? 'Failed to load performance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _loadPerformance,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final performance = state.performance;
          if (performance == null || performance.totalAttempts == 0) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadPerformance(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallStats(performance),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAccuracyChart(performance),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionBreakdown(performance),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentTests(performance),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Performance Data Yet',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete some tests to see your performance analytics here.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(PerformanceEntity performance) {
    final trend = performance.improvementTrend;
    final trendStr = trend > 0
        ? '+${trend.toStringAsFixed(1)}%'
        : '${trend.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 600
              ? 2
              : 1;
          const spacing = AppSpacing.md;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          final cards = [
            _buildStatCard(
              '${performance.overallAccuracy.toStringAsFixed(0)}%',
              'Accuracy',
              Colors.white,
            ),
            _buildStatCard(
              '${performance.totalAttempts}',
              'Tests',
              Colors.white,
            ),
            _buildStatCard(trendStr, 'Trend', Colors.white),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Performance',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statLarge.copyWith(color: color)),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart(PerformanceEntity performance) {
    final scores = performance.recentScores.reversed.take(7).toList();

    if (scores.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = scores.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.accuracy);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accuracy Trend', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTextStyles.labelSmall,
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < scores.length) {
                          return Text(
                            'T${idx + 1}',
                            style: AppTextStyles.labelSmall,
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (scores.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBreakdown(PerformanceEntity performance) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section Breakdown', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _buildSectionRow(
            'Verbal Reasoning',
            performance.verbalAccuracy.toInt(),
            AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSectionRow(
            'Quantitative Reasoning',
            performance.quantAccuracy.toInt(),
            AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSectionRow(
            'Analytical Writing',
            performance.awaAccuracy.toInt(),
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow(String section, int accuracy, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        final progress = LinearProgressIndicator(
          value: accuracy / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              progress,
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$accuracy%',
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(section, style: AppTextStyles.bodyMedium),
            ),
            Expanded(flex: 3, child: progress),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 45,
              child: Text(
                '$accuracy%',
                style: AppTextStyles.labelLarge.copyWith(color: color),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTests(PerformanceEntity performance) {
    final recentTests = performance.recentScores.take(5).toList();

    if (recentTests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Tests', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...recentTests.asMap().entries.map((e) {
            final test = e.value;
            final isLast = e.key == recentTests.length - 1;
            return Column(
              children: [
                _buildTestItem(
                  test.testTitle,
                  '${test.accuracy.toStringAsFixed(0)}%',
                  DateFormat('MMM d').format(test.attemptedAt),
                  _getScoreColor(test.accuracy),
                ),
                if (!isLast) const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getScoreColor(double accuracy) {
    if (accuracy >= 80) return AppColors.success;
    if (accuracy >= 60) return AppColors.primary;
    if (accuracy >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildTestItem(String title, String score, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(score, style: AppTextStyles.titleMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
