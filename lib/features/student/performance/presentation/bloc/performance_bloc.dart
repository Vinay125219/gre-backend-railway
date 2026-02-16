import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/performance_entity.dart';
import '../../domain/repositories/performance_repository.dart';

// Events
abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();

  @override
  List<Object?> get props => [];
}

class PerformanceLoadRequested extends PerformanceEvent {
  final String studentId;

  const PerformanceLoadRequested({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class PerformanceLoadByDateRange extends PerformanceEvent {
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  const PerformanceLoadByDateRange({
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [studentId, startDate, endDate];
}

// States
enum PerformanceStatus { initial, loading, success, failure }

class PerformanceState extends Equatable {
  final PerformanceStatus status;
  final PerformanceEntity? performance;
  final String? errorMessage;
  final DateTimeRange? dateRange;

  const PerformanceState({
    this.status = PerformanceStatus.initial,
    this.performance,
    this.errorMessage,
    this.dateRange,
  });

  PerformanceState copyWith({
    PerformanceStatus? status,
    PerformanceEntity? performance,
    String? errorMessage,
    DateTimeRange? dateRange,
  }) {
    return PerformanceState(
      status: status ?? this.status,
      performance: performance ?? this.performance,
      errorMessage: errorMessage ?? this.errorMessage,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  @override
  List<Object?> get props => [status, performance, errorMessage, dateRange];
}

// Bloc
class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceRepository _repository;

  PerformanceBloc({required PerformanceRepository repository})
    : _repository = repository,
      super(const PerformanceState()) {
    on<PerformanceLoadRequested>(_onLoadRequested);
    on<PerformanceLoadByDateRange>(_onLoadByDateRange);
  }

  Future<void> _onLoadRequested(
    PerformanceLoadRequested event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(state.copyWith(status: PerformanceStatus.loading));

    final result = await _repository.getStudentPerformance(event.studentId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PerformanceStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (performance) => emit(
        state.copyWith(
          status: PerformanceStatus.success,
          performance: performance,
          dateRange: null,
        ),
      ),
    );
  }

  Future<void> _onLoadByDateRange(
    PerformanceLoadByDateRange event,
    Emitter<PerformanceState> emit,
  ) async {
    emit(state.copyWith(status: PerformanceStatus.loading));

    final result = await _repository.getPerformanceByDateRange(
      event.studentId,
      event.startDate,
      event.endDate,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PerformanceStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (performance) => emit(
        state.copyWith(
          status: PerformanceStatus.success,
          performance: performance,
          dateRange: DateTimeRange(start: event.startDate, end: event.endDate),
        ),
      ),
    );
  }
}
