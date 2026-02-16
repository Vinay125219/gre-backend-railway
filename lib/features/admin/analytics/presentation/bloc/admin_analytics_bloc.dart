import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_analytics_repository.dart';
import 'admin_analytics_event.dart';
import 'admin_analytics_state.dart';

class AdminAnalyticsBloc
    extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  final AdminAnalyticsRepository _repository;

  AdminAnalyticsBloc({required AdminAnalyticsRepository repository})
    : _repository = repository,
      super(const AdminAnalyticsState()) {
    on<AdminAnalyticsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AdminAnalyticsLoadRequested event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: AdminAnalyticsStatus.loading));
    final result = await _repository.getAnalyticsOverview();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AdminAnalyticsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(status: AdminAnalyticsStatus.success, data: data),
      ),
    );
  }
}
