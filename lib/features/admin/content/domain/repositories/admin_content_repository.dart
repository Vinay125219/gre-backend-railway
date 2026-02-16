import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/content_entity.dart';

abstract class AdminContentRepository {
  /// Upload content (PDF/Video)
  /// If [file] is provided, uploads it to storage first.
  /// Then creates a record in Firestore.
  Future<Either<Failure, ContentEntity>> uploadContent({
    required File file,
    required String courseId,
    required String title,
    required ContentType type,
    required String section,
    String? description,
  });

  /// Create a Note (no file upload)
  Future<Either<Failure, ContentEntity>> createNote({
    required String courseId,
    required String title,
    required String
    content, // Stored in 'description' or separate field? using 'url' as content for notes?
    // or maybe description.
    required String section,
  });

  /// Delete content (and file if applicable)
  Future<Either<Failure, void>> deleteContent(ContentEntity content);

  /// Get content for a specific course
  Future<Either<Failure, List<ContentEntity>>> getContentForCourse(
    String courseId,
  );

  /// Get all content (across all courses)
  Future<Either<Failure, List<ContentEntity>>> getAllContent();
}
