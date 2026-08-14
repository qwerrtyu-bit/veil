import 'package:flutter/material.dart';

enum UserRole {
  user,
  beta,
  moderator,
  cofounder,   
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Пользователь';
      case UserRole.beta:
        return 'Бета-тестер';
      case UserRole.moderator:
        return 'Модератор';
      case UserRole.cofounder:
        return 'Соучредитель';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.user:
        return '👤';
      case UserRole.beta:
        return '🧪';
      case UserRole.moderator:
        return '🛡️';
      case UserRole.cofounder:
        return '👑';
      case UserRole.admin:
        return '⚡';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.user:
        return Colors.grey;
      case UserRole.beta:
        return Colors.blue;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.cofounder:
        return const Color(0xFFF59E0B); // золотой
      case UserRole.admin:
        return const Color(0xFF6C5CE7); // фиолетовый
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserRole.user:
        return ['read'];
      case UserRole.beta:
        return ['read', 'beta_access'];
      case UserRole.moderator:
        return ['read', 'moderate_reports', 'view_logs'];
      case UserRole.cofounder:
        return ['read', 'write', 'delete', 'transfer', 'giftcard', 'backup', 'plugin', 'settings', 'moderate_reports', 'view_logs', 'manage_roles', 'admin_access'];
      case UserRole.admin:
        return ['read', 'write', 'delete', 'transfer', 'giftcard', 'backup', 'plugin', 'settings', 'moderate_reports', 'view_logs', 'manage_roles', 'admin_access'];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    for (final p in requiredPermissions) {
      if (hasPermission(p)) {
        return true;
      }
    }
    return false;
  }
}