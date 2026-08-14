import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/role_model.dart';
import 'role_service.dart';

class AdminService {
  final _secureStorage = const FlutterSecureStorage();
  final _roleService = RoleService();

  static const String _devPublicKey = 'cccd1468561d56b9111c3f1896bad5052fd9ba31db5a903b4ac3aa793e56bd99';

  Future<String?> getCurrentUserKey() async {
    return await _secureStorage.read(key: 'public_key');
  }

  Future<bool> isAdmin() async {
    final currentUserKey = await getCurrentUserKey();
    if (currentUserKey == null) return false;
    if (currentUserKey == _devPublicKey) return true;
    final role = _roleService.getRole(currentUserKey);
    return role == UserRole.admin || role == UserRole.cofounder;
  }

  Future<bool> isCofounder() async {
    final currentUserKey = await getCurrentUserKey();
    if (currentUserKey == null) return false;
    if (currentUserKey == _devPublicKey) return true;
    return _roleService.getRole(currentUserKey) == UserRole.cofounder;
  }

  Future<bool> hasAdminAccess() async {
    final currentUserKey = await getCurrentUserKey();
    if (currentUserKey == null) return false;
    if (currentUserKey == _devPublicKey) return true;
    final role = _roleService.getRole(currentUserKey);
    return role == UserRole.admin || role == UserRole.cofounder || role == UserRole.moderator;
  }

  Future<UserRole> getCurrentUserRole() async {
    final currentUserKey = await getCurrentUserKey();
    if (currentUserKey == null) return UserRole.user;
    if (currentUserKey == _devPublicKey) return UserRole.admin;
    return _roleService.getRole(currentUserKey);
  }

  Future<bool> checkAdminAccess(BuildContext context) async {
    final hasAccess = await hasAdminAccess();
    if (!hasAccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ запрещён. Только для администраторов, соучредителей и модераторов.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/chats');
      }
      return false;
    }
    return true;
  }

  Future<bool> checkCofounderAccess(BuildContext context) async {
    final hasAccess = await isCofounder() || await isAdmin();
    if (!hasAccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Доступ запрещён. Только для соучредителей и администраторов.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/chats');
      }
      return false;
    }
    return true;
  }
}