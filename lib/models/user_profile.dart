/// Enum representing the role of the user.
enum UserRole { parent, waliKelas, superadmin, guru }

/// Model class representing the current user profile.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.role,
    this.childStudentId,
    this.homeroomClassName,
  });

  final String name;
  final UserRole role;
  final String? childStudentId; // NISN of the child, for parent role
  final String? homeroomClassName; // Name of homeroom class, for guru role

  bool get isParent => role == UserRole.parent;
  bool get isAdmin => role == UserRole.waliKelas || role == UserRole.superadmin || homeroomClassName != null;
  bool get isSuperAdmin => role == UserRole.superadmin;
  bool get isGuru => role == UserRole.guru;
  bool get isWaliKelas => role == UserRole.waliKelas || homeroomClassName != null;
}
