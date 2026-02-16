import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/course_repository.dart';
import '../../../tests/domain/repositories/test_repository.dart';
import '../../../../admin/content/domain/repositories/admin_content_repository.dart';
import 'course_details_event.dart';
import 'course_details_state.dart';

class CourseDetailsBloc extends Bloc<CourseDetailsEvent, CourseDetailsState> {
  final CourseRepository _courseRepository;
  final TestRepository _testRepository;
  final AdminContentRepository _contentRepository;

  CourseDetailsBloc({
    required CourseRepository courseRepository,
    required TestRepository testRepository,
    required AdminContentRepository contentRepository,
  }) : _courseRepository = courseRepository,
       _testRepository = testRepository,
       _contentRepository = contentRepository,
       super(const CourseDetailsState()) {
    on<CourseDetailsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    CourseDetailsLoadRequested event,
    Emitter<CourseDetailsState> emit,
  ) async {
    emit(state.copyWith(status: CourseDetailsStatus.loading));

    // 1. Fetch Course Details
    final courseResult = await _courseRepository.getCourseById(event.courseId);
    if (courseResult.isLeft()) {
      courseResult.fold(
        (failure) => emit(
          state.copyWith(
            status: CourseDetailsStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (r) => null,
      );
      return;
    }

    final course = courseResult.getOrElse(() => throw Exception());

    // 2. Fetch Tests
    // Note: ensure we import TestEntity
    final testsResult = await _testRepository.getTestsByCourse(event.courseId);
    final tests = testsResult.getOrElse(() => []);

    // 3. Fetch Content
    // Note: ensure we import ContentEntity
    final contentResult = await _contentRepository.getContentForCourse(
      event.courseId,
    );
    final content = contentResult.getOrElse(() => []);

    emit(
      state.copyWith(
        status: CourseDetailsStatus.success,
        course: course,
        tests: tests,
        content: content,
      ),
    );
  }
}
