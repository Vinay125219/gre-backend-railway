import 'package:equatable/equatable.dart';

enum ContentType { pdf, video, note }

class ContentEntity extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final ContentType type;
  final String url;
  final String section; // 'verbal', 'quant', 'awa'
  final Map<String, dynamic> metadata; // pages, duration, etc.
  final DateTime createdAt;

  const ContentEntity({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    required this.section,
    this.metadata = const {},
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    courseId,
    title,
    description,
    type,
    url,
    section,
    metadata,
    createdAt,
  ];
}
