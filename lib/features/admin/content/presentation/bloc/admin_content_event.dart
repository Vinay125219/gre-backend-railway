import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/content_entity.dart';

abstract class AdminContentEvent extends Equatable {
  const AdminContentEvent();

  @override
  List<Object?> get props => [];
}

class AdminContentLoadRequested extends AdminContentEvent {
  final String? courseId;

  const AdminContentLoadRequested({this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class AdminContentUploadRequested extends AdminContentEvent {
  final File file;
  final String courseId;
  final String title;
  final ContentType type;
  final String section;

  const AdminContentUploadRequested({
    required this.file,
    required this.courseId,
    required this.title,
    required this.type,
    required this.section,
  });

  @override
  List<Object?> get props => [file, courseId, title, type, section];
}

class AdminContentNoteCreated extends AdminContentEvent {
  final String courseId;
  final String title;
  final String content;
  final String section;

  const AdminContentNoteCreated({
    required this.courseId,
    required this.title,
    required this.content,
    required this.section,
  });

  @override
  List<Object> get props => [courseId, title, content, section];
}

class AdminContentDeleteRequested extends AdminContentEvent {
  final ContentEntity content;

  const AdminContentDeleteRequested(this.content);

  @override
  List<Object?> get props => [content];
}
