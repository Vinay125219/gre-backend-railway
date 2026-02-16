import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Auth repository interface
/// Defines the contract for authentication operations
abstract class AuthRepository {
  /// Get current authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  /// Create new user account (admin only)
  Future<Either<Failure, UserEntity>> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String? phoneNumber,
  });

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  });

  /// Auth state changes stream
  Stream<UserEntity?> get authStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current user ID
  String? get currentUserId;
}
