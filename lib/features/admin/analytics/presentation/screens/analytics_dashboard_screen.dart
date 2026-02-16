import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/analytics_overview_entity.dart';
import '../bloc/admin_analytics_bloc.dart';
import '../bloc/admin_analytics_event.dart';
import '../bloc/admin_analytics_state.dart';

/// Admin Analytics Dashboard Screen
class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AdminAnalyticsBloc>()..add(AdminAnalyticsLoadRequested()),
      child: BlocBuilder<AdminAnalyticsBloc, AdminAnalyticsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Analytics Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                  tooltip: 'Export Report',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<AdminAnalyticsBloc>().add(
                      AdminAnalyticsLoadRequested(),
                    );
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminAnalyticsState state) {
    if (state.status == AdminAnalyticsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AdminAnalyticsStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage ?? 'Failed to load analytics',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AdminAnalyticsBloc>().add(
                    AdminAnalyticsLoadRequested(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No data available', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Once students start taking tests, analytics will appear here.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final data = state.data!;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminAnalyticsBloc>().add(AdminAnalyticsLoadRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            _buildOverviewCards(data),
            const SizedBox(height: AppSpacing.lg),

            // Student Activity Chart
            _buildActivityChart(data.activityData),
            const SizedBox(height: AppSpacing.lg),

            // Two-column layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      _buildTestPerformance(data.performanceDistribution),
                      const SizedBox(height: AppSpacing.md),
                      _buildTopStudents(data.topStudents),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTestPerformance(
                        data.performanceDistribution,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildTopStudents(data.topStudents)),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section-wise Performance
            _buildSectionPerformance(data.sectionPerformance),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(AnalyticsOverviewEntity data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 800
            ? 2
            : 1;
        const spacing = AppSpacing.md;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final cards = [
          _buildStatCard(
            'Total Students',
            '${data.totalStudents}',
            Icons.people,
            AppColors.primary,
            '',
          ),
          _buildStatCard(
            'Active Students',
            '${data.activeStudents}',
            Icons.person_pin,
            AppColors.success,
            '${data.totalStudents > 0 ? ((data.activeStudents / data.totalStudents) * 100).toStringAsFixed(0) : 0}% active',
          ),
          _buildStatCard(
            'Tests Completed',
            '${data.testsCompleted}',
            Icons.quiz,
            AppColors.secondary,
            '',
          ),
          _buildStatCard(
            'Avg. Accuracy',
            '${data.avgAccuracy.toStringAsFixed(1)}%',
            Icons.trending_up,
            AppColors.warning,
            '',
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.displaySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildActivityChart(List<double> activityData) {
    final hasActivity =
        activityData.isNotEmpty && activityData.any((value) => value > 0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Student Activity (Last 7 Days)',
                style: AppTextStyles.titleMedium,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasActivity)
            SizedBox(
              height: 220,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('No activity yet', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Student activity will appear here once tests are taken.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: _getActivityData(activityData),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: AppTextStyles.caption,
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
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          // Just map to index for now, ideally shift based on Today
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: AppTextStyles.caption,
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: AppColors.border, strokeWidth: 1);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getActivityData(List<double> values) {
    return List.generate(values.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            color: AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildTestPerformance(Map<String, double> distribution) {
    // Check if we have any data
    final total = distribution.values.fold<double>(0, (sum, val) => sum + val);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Performance Distribution',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No test attempts yet',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Performance Distribution',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  if ((distribution['Excellent'] ?? 0) > 0)
                    PieChartSectionData(
                      value: distribution['Excellent'] ?? 0,
                      title: 'High\n(>80%)',
                      color: AppColors.success,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  if ((distribution['Average'] ?? 0) > 0)
                    PieChartSectionData(
                      value: distribution['Average'] ?? 0,
                      title: 'Avg\n(50-79%)',
                      color: AppColors.warning,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  if ((distribution['Needs Work'] ?? 0) > 0)
                    PieChartSectionData(
                      value: distribution['Needs Work'] ?? 0,
                      title: 'Low\n(<50%)',
                      color: AppColors.error,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStudents(List<StudentPerformanceEntity> students) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Top Performers', style: AppTextStyles.titleMedium),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No top performers yet',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'This list will update after students complete tests.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...students.asMap().entries.map((e) {
              final rank = e.key + 1;
              final student = e.value;
              return _buildStudentRow(
                rank,
                student.name,
                student.avgScore.toInt(),
                student.trend,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudentRow(int rank, String name, int score, String trend) {
    final isPositive = trend.startsWith('+');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.warningLight
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.labelMedium.copyWith(
                  color: rank <= 3
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(name, style: AppTextStyles.bodyMedium)),
          Text(
            '$score%',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            trend,
            style: AppTextStyles.caption.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPerformance(Map<String, double> perf) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section-wise Performance', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildSectionCard(
                      'Verbal Reasoning',
                      perf['Verbal Reasoning']?.toInt() ?? 0,
                      AppColors.primary,
                      '',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      'Quantitative Reasoning',
                      perf['Quantitative Reasoning']?.toInt() ?? 0,
                      AppColors.secondary,
                      '',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      'Analytical Writing',
                      perf['Analytical Writing']?.toInt() ?? 0,
                      AppColors.warning,
                      '',
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      'Verbal Reasoning',
                      perf['Verbal Reasoning']?.toInt() ?? 0,
                      AppColors.primary,
                      '',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSectionCard(
                      'Quantitative Reasoning',
                      perf['Quantitative Reasoning']?.toInt() ?? 0,
                      AppColors.secondary,
                      '',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSectionCard(
                      'Analytical Writing',
                      perf['Analytical Writing']?.toInt() ?? 0,
                      AppColors.warning,
                      '',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    int score,
    Color color,
    String insight,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge.copyWith(color: color)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '$score%',
                style: AppTextStyles.displaySmall.copyWith(color: color),
              ),
              const Spacer(),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withValues(alpha: 0.2),
                  color: color,
                  strokeWidth: 6,
                ),
              ),
            ],
          ),
          if (insight.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(insight, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
