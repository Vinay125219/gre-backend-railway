import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics_overview_entity.dart';

enum AdminAnalyticsStatus { initial, loading, success, failure }

class AdminAnalyticsState extends Equatable {
  final AdminAnalyticsStatus status;
  final AnalyticsOverviewEntity? data;
  final String? errorMessage;

  const AdminAnalyticsState({
    this.status = AdminAnalyticsStatus.initial,
    this.data,
    this.errorMessage,
  });

  AdminAnalyticsState copyWith({
    AdminAnalyticsStatus? status,
    AnalyticsOverviewEntity? data,
    String? errorMessage,
  }) {
    return AdminAnalyticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
