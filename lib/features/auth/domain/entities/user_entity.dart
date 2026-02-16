import 'package:equatable/equatable.dart';

/// User entity for domain layer
/// Represents an authenticated user in the system
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String role; // 'admin' or 'student'
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool disabled;
  final DateTime? expiryDate;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.disabled = false,
    this.expiryDate,
  });

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is student
  bool get isStudent => role == 'student';

  /// Check if account is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Get initials for avatar
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    role,
    phoneNumber,
    photoUrl,
    createdAt,
    lastLoginAt,
    disabled,
    expiryDate,
  ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? disabled,
    DateTime? expiryDate,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      disabled: disabled ?? this.disabled,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  /// Empty user for initial state
  static UserEntity get empty => UserEntity(
    id: '',
    email: '',
    displayName: '',
    role: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Check if user is empty
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
}
