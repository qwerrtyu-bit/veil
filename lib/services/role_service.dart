import 'package:hive_flutter/hive_flutter.dart';
import '../models/role_model.dart';

class RoleService {
  final Box _settingsBox = Hive.box('settings');

  // Сохранить роль пользователя
  Future<void> setRole(String publicKey, UserRole role) async {
    final roles = _getAllRoles();
    roles[publicKey] = role.index;
    await _settingsBox.put('user_roles', roles);
  }

  // Получить роль пользователя
  UserRole getRole(String publicKey) {
    final roles = _getAllRoles();
    final roleIndex = roles[publicKey];
    if (roleIndex == null) return UserRole.user;
    return UserRole.values[roleIndex];
  }

  // Проверить, является ли пользователь админом
  bool isAdmin(String publicKey) {
    return getRole(publicKey) == UserRole.admin;
  }

  // Проверить, имеет ли пользователь доступ к админ-панели
  bool hasAdminAccess(String publicKey) {
    final role = getRole(publicKey);
    return role == UserRole.admin || role == UserRole.moderator;
  }

  // Получить всех пользователей с ролями
  Map<String, UserRole> getAllRoles() {
    final roles = _getAllRoles();
    final result = <String, UserRole>{};
    for (final entry in roles.entries) {
      result[entry.key] = UserRole.values[entry.value];
    }
    return result;
  }

  // Удалить роль (сбросить до обычного пользователя)
  Future<void> removeRole(String publicKey) async {
    final roles = _getAllRoles();
    roles.remove(publicKey);
    await _settingsBox.put('user_roles', roles);
  }

  Map<String, int> _getAllRoles() {
    final raw = _settingsBox.get('user_roles');
    if (raw is Map) {
      return Map<String, int>.from(raw);
    }
    return {};
  }
}