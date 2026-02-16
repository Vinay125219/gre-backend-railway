import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/repositories/admin_content_repository.dart';

class AdminContentRepositoryImpl implements AdminContentRepository {
  static const String _samplePdfUrl =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
  static const String _sampleVideoUrl =
      'https://www.youtube.com/watch?v=aqz-KE-bpKQ';

  final MockDatabase _db;

  AdminContentRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<ContentEntity>>> getContentForCourse(
    String courseId,
  ) async {
    final content =
        _db.contentItems.where((item) => item.courseId == courseId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(content);
  }

  @override
  Future<Either<Failure, List<ContentEntity>>> getAllContent() async {
    final content = List<ContentEntity>.from(_db.contentItems)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Right(content);
  }

  @override
  Future<Either<Failure, ContentEntity>> uploadContent({
    required File file,
    required String courseId,
    required String title,
    required ContentType type,
    required String section,
    String? description,
  }) async {
    final courseExists = _db.courses.any((course) => course.id == courseId);
    if (!courseExists) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }

    final size = await _safeFileSize(file);
    final now = DateTime.now();
    final content = ContentEntity(
      id: 'content-${now.microsecondsSinceEpoch}',
      courseId: courseId,
      title: title.trim(),
      description: description,
      type: type,
      url: type == ContentType.pdf ? _samplePdfUrl : _sampleVideoUrl,
      section: section.trim().toLowerCase(),
      metadata: {
        if (size != null) 'size': size,
        'sourceFileName': file.path.split('/').last,
      },
      createdAt: now,
    );

    _db.contentItems.add(content);
    return Right(content);
  }

  @override
  Future<Either<Failure, ContentEntity>> createNote({
    required String courseId,
    required String title,
    required String content,
    required String section,
  }) async {
    final courseExists = _db.courses.any((course) => course.id == courseId);
    if (!courseExists) {
      return const Left(NotFoundFailure(message: 'Course not found.'));
    }

    final created = ContentEntity(
      id: 'content-${DateTime.now().microsecondsSinceEpoch}',
      courseId: courseId,
      title: title.trim(),
      description: content.trim(),
      type: ContentType.note,
      url: '',
      section: section.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );

    _db.contentItems.add(created);
    return Right(created);
  }

  @override
  Future<Either<Failure, void>> deleteContent(ContentEntity content) async {
    final index = _db.contentItems.indexWhere((item) => item.id == content.id);
    if (index < 0) {
      return const Left(NotFoundFailure(message: 'Content not found.'));
    }

    _db.contentItems.removeAt(index);
    return const Right(null);
  }

  Future<int?> _safeFileSize(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }
      return await file.length();
    } catch (_) {
      return null;
    }
  }
}
