import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../domain/entities/test_entity.dart';
import '../bloc/test_taking_bloc.dart';

/// Test Taking Screen - Main exam interface
class TestTakingScreen extends StatelessWidget {
  final String testId;

  const TestTakingScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestTakingBloc, TestTakingState>(
      listener: (context, state) {
        if (state.status == TestTakingStatus.completed) {
          // Navigate to results
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test submitted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }

        if (state.status == TestTakingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == TestTakingStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Test...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == TestTakingStatus.submitting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Submitting...', style: AppTextStyles.titleMedium),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: Column(
            children: [
              // Progress & Navigation Bar
              _buildProgressBar(context, state),

              // Question Area
              Expanded(child: _buildQuestionArea(context, state)),

              // Bottom Navigation
              _buildBottomNav(context, state),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TestTakingState state,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        state.test?.title ?? 'Test',
        style: AppTextStyles.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            color: state.isTimeRunningLow
                ? AppColors.errorLight
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: state.isTimeRunningLow
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.formattedTime,
                style: AppTextStyles.titleSmall.copyWith(
                  color: state.isTimeRunningLow
                      ? AppColors.error
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),

        // Submit button
        TextButton(
          onPressed: () => _showSubmitDialog(context),
          child: Text(
            'Submit',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, TestTakingState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          final progress = LinearProgressIndicator(
            value: state.progress,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Q ${state.currentQuestionIndex + 1}/${state.questions.length}',
                      style: AppTextStyles.labelLarge,
                    ),
                    const Spacer(),
                    _StatBadge(
                      icon: Icons.check_circle_outline,
                      count: state.answeredCount,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatBadge(
                      icon: Icons.flag_outlined,
                      count: state.markedCount,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                progress,
              ],
            );
          }

          return Row(
            children: [
              // Question counter
              Text(
                'Q ${state.currentQuestionIndex + 1}/${state.questions.length}',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(width: AppSpacing.md),

              // Progress bar
              Expanded(child: progress),
              const SizedBox(width: AppSpacing.md),

              // Stats
              _StatBadge(
                icon: Icons.check_circle_outline,
                count: state.answeredCount,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatBadge(
                icon: Icons.flag_outlined,
                count: state.markedCount,
                color: AppColors.warning,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionArea(BuildContext context, TestTakingState state) {
    final question = state.currentQuestion;
    if (question == null) {
      return const Center(child: Text('No questions'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              question.typeName,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Passage (if any)
          if (question.passage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(question.passage!, style: AppTextStyles.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Question text
          Text(question.question, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),

          // Answer options based on type
          if (question.type == QuestionType.mcq)
            _buildMCQOptions(context, state, question),
          if (question.type == QuestionType.msq)
            _buildMSQOptions(context, state, question),
          if (question.type == QuestionType.nat)
            _buildNATInput(context, state, question),
        ],
      ),
    );
  }

  Widget _buildMCQOptions(
    BuildContext context,
    TestTakingState state,
    QuestionEntity question,
  ) {
    final selectedAnswer = state.answers[question.id] as String?;

    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswer == option;
        final letter = String.fromCharCode(65 + index);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              context.read<TestTakingBloc>().add(
                TestTakingAnswerSaved(questionId: question.id, answer: option),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMSQOptions(
    BuildContext context,
    TestTakingState state,
    QuestionEntity question,
  ) {
    final selectedAnswers = List<String>.from(
      (state.answers[question.id] as List?) ?? [],
    );

    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswers.contains(option);
        final letter = String.fromCharCode(65 + index);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              final updated = List<String>.from(selectedAnswers);
              if (isSelected) {
                updated.remove(option);
              } else {
                updated.add(option);
              }
              context.read<TestTakingBloc>().add(
                TestTakingAnswerSaved(questionId: question.id, answer: updated),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Center(
                            child: Text(
                              letter,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNATInput(
    BuildContext context,
    TestTakingState state,
    QuestionEntity question,
  ) {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: (value) {
        context.read<TestTakingBloc>().add(
          TestTakingAnswerSaved(questionId: question.id, answer: value),
        );
      },
      decoration: const InputDecoration(
        hintText: 'Enter your numeric answer',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, TestTakingState state) {
    final question = state.currentQuestion;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;

            final prevButton = IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: state.currentQuestionIndex > 0
                  ? () => context.read<TestTakingBloc>().add(
                      TestTakingQuestionChanged(
                        questionIndex: state.currentQuestionIndex - 1,
                      ),
                    )
                  : null,
            );

            final markButton = question == null
                ? const SizedBox.shrink()
                : TextButton.icon(
                    icon: Icon(
                      state.isCurrentMarked ? Icons.flag : Icons.flag_outlined,
                      color: state.isCurrentMarked ? AppColors.warning : null,
                    ),
                    label: Text(state.isCurrentMarked ? 'Marked' : 'Mark'),
                    onPressed: () {
                      context.read<TestTakingBloc>().add(
                        TestTakingMarkToggled(questionId: question.id),
                      );
                    },
                  );

            final clearButton = state.isCurrentAnswered
                ? TextButton(
                    onPressed: () {
                      context.read<TestTakingBloc>().add(
                        TestTakingAnswerCleared(questionId: question!.id),
                      );
                    },
                    child: const Text('Clear'),
                  )
                : const SizedBox.shrink();

            final paletteButton = IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () => _showQuestionPalette(context, state),
            );

            final nextButton = ElevatedButton(
              onPressed: state.currentQuestionIndex < state.questions.length - 1
                  ? () => context.read<TestTakingBloc>().add(
                      TestTakingQuestionChanged(
                        questionIndex: state.currentQuestionIndex + 1,
                      ),
                    )
                  : null,
              child: const Text('Next'),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      prevButton,
                      markButton,
                      if (state.isCurrentAnswered) clearButton,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      paletteButton,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: nextButton),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                prevButton,
                markButton,
                if (state.isCurrentAnswered) clearButton,
                const Spacer(),
                paletteButton,
                nextButton,
              ],
            );
          },
        ),
      ),
    );
  }

  void _showQuestionPalette(BuildContext context, TestTakingState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuestionPalette(state: state),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final state = context.read<TestTakingBloc>().state;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Answered: ${state.answeredCount}/${state.questions.length}'),
            Text('Unanswered: ${state.questions.length - state.answeredCount}'),
            Text('Marked for review: ${state.markedCount}'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Are you sure you want to submit?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TestTakingBloc>().add(const TestTakingSubmitted());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _QuestionPalette extends StatelessWidget {
  final TestTakingState state;

  const _QuestionPalette({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question Palette', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _buildLegend(),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(state.questions.length, (index) {
              final question = state.questions[index];
              final isAnswered = state.answers.containsKey(question.id);
              final isMarked = state.markedForReview[question.id] ?? false;
              final isCurrent = index == state.currentQuestionIndex;

              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.read<TestTakingBloc>().add(
                    TestTakingQuestionChanged(questionIndex: index),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : isMarked
                        ? AppColors.warningLight
                        : isAnswered
                        ? AppColors.successLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : isMarked
                          ? AppColors.warning
                          : isAnswered
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isCurrent ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem(AppColors.successLight, 'Answered'),
        const SizedBox(width: AppSpacing.md),
        _legendItem(AppColors.warningLight, 'Marked'),
        const SizedBox(width: AppSpacing.md),
        _legendItem(AppColors.surfaceVariant, 'Not Answered'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
