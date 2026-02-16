import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Auth BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({required this.authRepository}) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes with error handling
    _authStateSubscription = authRepository.authStateChanges.listen(
      (user) => add(AuthStateChanged(user: user)),
      onError: (error) {
        // Log error but don't crash - user will be prompted to login
        // ignore: avoid_print
        print('Auth state stream error: $error');
      },
    );
  }

  /// Handle auth check on app start
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await authRepository.getCurrentUser();

    result.fold((failure) => emit(const AuthState.unauthenticated()), (user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await authRepository.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );

    result.fold((failure) => emit(AuthState.error(failure.message)), (user) {
      // Check if account is expired
      if (user.isExpired) {
        authRepository.signOut();
        emit(
          AuthState.error(
            'Your account has expired. Please contact administrator.',
          ),
        );
      } else {
        emit(AuthState.authenticated(user));
      }
    });
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await authRepository.signOut();

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await authRepository.sendPasswordResetEmail(
      email: event.email,
    );

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.passwordResetSent()),
    );
  }

  /// Handle auth state changes from stream
  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
