import 'package:equatable/equatable.dart';
import '../../domain/entities/content_entity.dart';

enum AdminContentStatus { initial, loading, success, failure }

class AdminContentState extends Equatable {
  final AdminContentStatus status;
  final List<ContentEntity> content;
  final String? errorMessage;
  final String activeCourseId;

  const AdminContentState({
    this.status = AdminContentStatus.initial,
    this.content = const [],
    this.errorMessage,
    this.activeCourseId = 'all',
  });

  AdminContentState copyWith({
    AdminContentStatus? status,
    List<ContentEntity>? content,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? activeCourseId,
  }) {
    return AdminContentState(
      status: status ?? this.status,
      content: content ?? this.content,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      activeCourseId: activeCourseId ?? this.activeCourseId,
    );
  }

  List<ContentEntity> get pdfs =>
      content.where((e) => e.type == ContentType.pdf).toList();

  List<ContentEntity> get videos =>
      content.where((e) => e.type == ContentType.video).toList();

  List<ContentEntity> get notes =>
      content.where((e) => e.type == ContentType.note).toList();

  @override
  List<Object?> get props => [status, content, errorMessage, activeCourseId];
}
