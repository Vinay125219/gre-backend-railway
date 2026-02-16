import 'package:equatable/equatable.dart';

/// Material types
enum MaterialType { pdf, video, note }

/// Material entity for domain layer
class MaterialEntity extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final MaterialType type;
  final String url; // Storage URL for PDFs, YouTube URL for videos
  final String? thumbnailUrl;
  final int? duration; // Duration in seconds for videos
  final int? pageCount; // Page count for PDFs
  final String section; // GRE section (Verbal, Quant, AWA)
  final int orderIndex;
  final DateTime createdAt;

  const MaterialEntity({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.pageCount,
    required this.section,
    this.orderIndex = 0,
    required this.createdAt,
  });

  /// Get material type icon
  String get typeIcon {
    switch (type) {
      case MaterialType.pdf:
        return '📄';
      case MaterialType.video:
        return '🎬';
      case MaterialType.note:
        return '📝';
    }
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    courseId,
    title,
    description,
    type,
    url,
    thumbnailUrl,
    duration,
    pageCount,
    section,
    orderIndex,
    createdAt,
  ];

  MaterialEntity copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    MaterialType? type,
    String? url,
    String? thumbnailUrl,
    int? duration,
    int? pageCount,
    String? section,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return MaterialEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      pageCount: pageCount ?? this.pageCount,
      section: section ?? this.section,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Material progress entity
class MaterialProgressEntity extends Equatable {
  final String id;
  final String materialId;
  final String studentId;
  final bool completed;
  final int? lastPage; // For PDFs
  final int? lastPosition; // For videos (in seconds)
  final DateTime? completedAt;
  final DateTime lastAccessedAt;

  const MaterialProgressEntity({
    required this.id,
    required this.materialId,
    required this.studentId,
    this.completed = false,
    this.lastPage,
    this.lastPosition,
    this.completedAt,
    required this.lastAccessedAt,
  });

  @override
  List<Object?> get props => [
    id,
    materialId,
    studentId,
    completed,
    lastPage,
    lastPosition,
    completedAt,
    lastAccessedAt,
  ];
}
