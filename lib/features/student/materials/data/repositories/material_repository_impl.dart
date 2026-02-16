import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/mock/mock_database.dart';
import '../../../../admin/content/domain/entities/content_entity.dart';
import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MockDatabase _db;

  MaterialRepositoryImpl({MockDatabase? database})
    : _db = database ?? MockDatabase();

  @override
  Future<Either<Failure, List<MaterialEntity>>> getMaterialsByCourse(
    String courseId,
  ) async {
    final materials =
        _db.contentItems
            .where((item) => item.courseId == courseId)
            .map(_toMaterial)
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Right(materials);
  }

  @override
  Future<Either<Failure, List<MaterialEntity>>> getMaterialsBySection(
    String courseId,
    String section,
  ) async {
    final normalizedSection = section.trim().toLowerCase();
    final materials =
        _db.contentItems
            .where(
              (item) =>
                  item.courseId == courseId &&
                  item.section.trim().toLowerCase() == normalizedSection,
            )
            .map(_toMaterial)
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Right(materials);
  }

  @override
  Future<Either<Failure, MaterialEntity>> getMaterialById(
    String materialId,
  ) async {
    try {
      final item = _db.contentItems.firstWhere(
        (content) => content.id == materialId,
      );
      return Right(_toMaterial(item));
    } catch (_) {
      return const Left(NotFoundFailure(message: 'Material not found.'));
    }
  }

  @override
  Future<Either<Failure, MaterialProgressEntity?>> getProgress(
    String studentId,
    String materialId,
  ) async {
    try {
      final progress = _db.materialProgress.firstWhere(
        (entry) =>
            entry.studentId == studentId && entry.materialId == materialId,
      );
      return Right(progress);
    } catch (_) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> updateProgress(
    MaterialProgressEntity progress,
  ) async {
    final index = _db.materialProgress.indexWhere(
      (entry) =>
          entry.studentId == progress.studentId &&
          entry.materialId == progress.materialId,
    );

    if (index >= 0) {
      _db.materialProgress[index] = progress;
      return const Right(null);
    }

    final id = progress.id.trim().isEmpty
        ? 'progress-${DateTime.now().microsecondsSinceEpoch}'
        : progress.id;
    _db.materialProgress.add(
      MaterialProgressEntity(
        id: id,
        materialId: progress.materialId,
        studentId: progress.studentId,
        completed: progress.completed,
        lastPage: progress.lastPage,
        lastPosition: progress.lastPosition,
        completedAt: progress.completedAt,
        lastAccessedAt: progress.lastAccessedAt,
      ),
    );

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markCompleted(
    String studentId,
    String materialId,
  ) async {
    final index = _db.materialProgress.indexWhere(
      (entry) => entry.studentId == studentId && entry.materialId == materialId,
    );

    final now = DateTime.now();

    if (index >= 0) {
      final existing = _db.materialProgress[index];
      _db.materialProgress[index] = MaterialProgressEntity(
        id: existing.id,
        materialId: existing.materialId,
        studentId: existing.studentId,
        completed: true,
        lastPage: existing.lastPage,
        lastPosition: existing.lastPosition,
        completedAt: now,
        lastAccessedAt: now,
      );
      return const Right(null);
    }

    _db.materialProgress.add(
      MaterialProgressEntity(
        id: 'progress-${DateTime.now().microsecondsSinceEpoch}',
        materialId: materialId,
        studentId: studentId,
        completed: true,
        completedAt: now,
        lastAccessedAt: now,
      ),
    );

    return const Right(null);
  }

  MaterialEntity _toMaterial(ContentEntity content) {
    MaterialType type;
    switch (content.type) {
      case ContentType.video:
        type = MaterialType.video;
        break;
      case ContentType.note:
        type = MaterialType.note;
        break;
      case ContentType.pdf:
        type = MaterialType.pdf;
        break;
    }

    return MaterialEntity(
      id: content.id,
      courseId: content.courseId,
      title: content.title,
      description: content.description ?? '',
      type: type,
      url: content.url,
      duration: _toInt(content.metadata['duration']),
      pageCount: _toInt(content.metadata['pages']),
      section: content.section,
      orderIndex: 0,
      createdAt: content.createdAt,
    );
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
