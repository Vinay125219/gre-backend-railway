import 'package:equatable/equatable.dart';

/// Student entity for admin management
class StudentEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final List<String> assignedCourses;
  final bool isActive;
  final DateTime enrolledAt;
  final DateTime? lastActiveAt;

  const StudentEntity({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.assignedCourses = const [],
    this.isActive = true,
    required this.enrolledAt,
    this.lastActiveAt,
  });

  /// Get initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }

  /// Check if student was active recently (last 7 days)
  bool get wasActiveRecently {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inDays <= 7;
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phone,
    avatarUrl,
    assignedCourses,
    isActive,
    enrolledAt,
    lastActiveAt,
  ];

  StudentEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? assignedCourses,
    bool? isActive,
    DateTime? enrolledAt,
    DateTime? lastActiveAt,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedCourses: assignedCourses ?? this.assignedCourses,
      isActive: isActive ?? this.isActive,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
