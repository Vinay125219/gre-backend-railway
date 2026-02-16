import 'package:equatable/equatable.dart';

abstract class AdminAnalyticsEvent extends Equatable {
  const AdminAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class AdminAnalyticsLoadRequested extends AdminAnalyticsEvent {}
