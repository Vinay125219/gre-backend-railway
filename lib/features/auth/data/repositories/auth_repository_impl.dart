import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../../core/mock/mock_database.dart';

/// Mock Implementation of AuthRepository (No Firebase)
class AuthRepositoryImpl implements AuthRepository {
  // Mock Data
  static UserEntity? _currentUser;

  final List<UserEntity> _mockUsers = MockDatabase().users;

  final _authStreamController = StreamController<UserEntity?>.broadcast();

  AuthRepositoryImpl() {
    // Emit initial state
    _authStreamController.add(_currentUser);
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authStreamController.stream;

  @override
  String? get currentUserId => _currentUser?.id;

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return Right(_currentUser);
  }

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay

    UserEntity user = UserEntity.empty;
    try {
      user = _mockUsers.firstWhere((u) => u.email == email);
    } catch (_) {
      // Not found
    }

    if (user.isEmpty) {
      if (email == 'admin@test.com') {
        // Auto-create admin if missing in mock (fallback)
        final admin = UserEntity(
          id: 'mock-admin-id',
          email: 'admin@test.com',
          displayName: 'Admin User',
          role: 'admin',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _currentUser = admin;
        _authStreamController.add(admin);
        return Right(admin);
      }
      return const Left(AuthFailure(message: 'User not found'));
    }

    // Passwords irrelevant in mock mode usually, or simple check
    if (password.length < 6) {
      return const Left(AuthFailure(message: 'Password too short'));
    }

    _currentUser = user;
    _authStreamController.add(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStreamController.add(null);
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? phoneNumber,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final newUser = UserEntity(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      role: role,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    _mockUsers.add(newUser);
    return Right(newUser);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    // Find and update in list
    // simplified for mock
    return Right(_currentUser!);
  }
}
