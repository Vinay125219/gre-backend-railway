import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/analytics_overview_entity.dart';

abstract class AdminAnalyticsRepository {
  Future<Either<Failure, AnalyticsOverviewEntity>> getAnalyticsOverview();
}
