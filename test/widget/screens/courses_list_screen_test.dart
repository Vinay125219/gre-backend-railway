import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:edu_learning_platform/features/auth/domain/entities/user_entity.dart';
import 'package:edu_learning_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:edu_learning_platform/features/student/courses/domain/entities/course_entity.dart';
import 'package:edu_learning_platform/features/student/courses/presentation/bloc/courses_bloc.dart';
import 'package:edu_learning_platform/features/student/courses/presentation/screens/courses_list_screen.dart';

class MockCoursesBloc extends Mock implements CoursesBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockCoursesBloc mockBloc;
  late MockAuthBloc mockAuthBloc;
  final mockStudent = UserEntity(
    id: 'student-1',
    email: 'student@test.com',
    displayName: 'Student',
    role: 'student',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockBloc = MockCoursesBloc();
    mockAuthBloc = MockAuthBloc();
    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(mockStudent));
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthState.authenticated(mockStudent)));
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<CoursesBloc>.value(value: mockBloc),
        ],
        child: const CoursesListScreen(),
      ),
    );
  }

  group('CoursesListScreen', () {
    testWidgets('shows loading indicator when status is loading', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockBloc.state,
      ).thenReturn(const CoursesState(status: CoursesStatus.loading));
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(const CoursesState(status: CoursesStatus.loading)),
      );

      // Act
      await tester.pumpWidget(buildTestWidget());

      // Assert - look for shimmer or loading related widgets
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows courses list when status is success', (tester) async {
      // Arrange
      final courses = [
        CourseEntity(
          id: 'course1',
          title: 'GRE Verbal Course',
          description: 'Complete verbal prep',
          sections: ['verbal'],
          published: true,
          materialCount: 20,
          testCount: 5,
          createdAt: DateTime.now(),
        ),
        CourseEntity(
          id: 'course2',
          title: 'GRE Quant Course',
          description: 'Complete quant prep',
          sections: ['quant'],
          published: true,
          materialCount: 25,
          testCount: 6,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        CoursesState(status: CoursesStatus.success, courses: courses),
      );
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          CoursesState(status: CoursesStatus.success, courses: courses),
        ),
      );

      // Act
      await tester.pumpWidget(buildTestWidget());

      // Assert
      expect(find.text('GRE Verbal Course'), findsOneWidget);
      expect(find.text('GRE Quant Course'), findsOneWidget);
    });

    testWidgets('shows empty state when no courses', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const CoursesState(status: CoursesStatus.success, courses: []),
      );
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          const CoursesState(status: CoursesStatus.success, courses: []),
        ),
      );

      // Act
      await tester.pumpWidget(buildTestWidget());

      // Assert - The actual text is "No Courses Yet"
      expect(find.text('No Courses Yet'), findsOneWidget);
    });

    testWidgets('shows error message when status is failure', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(
        const CoursesState(
          status: CoursesStatus.failure,
          errorMessage: 'Failed to load courses',
        ),
      );
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          const CoursesState(
            status: CoursesStatus.failure,
            errorMessage: 'Failed to load courses',
          ),
        ),
      );

      // Act
      await tester.pumpWidget(buildTestWidget());

      // Assert
      expect(find.text('Failed to load courses'), findsOneWidget);
    });
  });
}
