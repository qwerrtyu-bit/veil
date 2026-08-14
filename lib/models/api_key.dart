import 'package:uuid/uuid.dart';

class ApiKey {
  final String id;
  final String key;
  final String name;
  final String userId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> permissions;

  ApiKey({
    String? id,
    required this.key,
    required this.name,
    required this.userId,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.permissions = const ['read'],
  }) : id = id ?? const Uuid().v4();

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      permissions: List<String>.from(json['permissions'] ?? ['read']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('admin');
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    for (final permission in requiredPermissions) {
      if (hasPermission(permission)) {
        return true;
      }
    }
    return false;
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    for (final permission in requiredPermissions) {
      if (!hasPermission(permission)) {
        return false;
      }
    }
    return true;
  }
}