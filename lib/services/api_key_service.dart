import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/api_key.dart';

class ApiKeyService {
  Box? _box;

  Box get _hiveBox {
    if (_box == null) {
      try {
        _box = Hive.box('api_keys');
      } catch (e) {
        Hive.openBox('api_keys').then((box) {
          _box = box;
        });
        _box = Hive.box('api_keys');
      }
    }
    return _box!;
  }

  bool get isBoxOpen {
    try {
      Hive.box('api_keys');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureBoxOpen() async {
    try {
      Hive.box('api_keys');
    } catch (_) {
      await Hive.openBox('api_keys');
    }
  }

  String _generateKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'veil_sk_' + List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<ApiKey> createKey({
    required String name,
    required String userId,
    List<String> permissions = const ['read'],
    Duration? expiresIn,
  }) async {
    await ensureBoxOpen();
    
    final key = ApiKey(
      key: _generateKey(),
      name: name,
      userId: userId,
      createdAt: DateTime.now(),
      expiresAt: expiresIn != null ? DateTime.now().add(expiresIn) : null,
      permissions: permissions,
    );

    final keys = _getAllKeys();
    keys.add(key);
    _saveKeys(keys);

    return key;
  }

  List<ApiKey> getKeysByUser(String userId) {
    try {
      return _getAllKeys().where((k) => k.userId == userId).toList();
    } catch (_) {
      return [];
    }
  }

  ApiKey? getKeyByValue(String keyValue) {
    try {
      return _getAllKeys().firstWhere((k) => k.key == keyValue);
    } catch (_) {
      return null;
    }
  }

  bool isKeyValid(String keyValue) {
    final key = getKeyByValue(keyValue);
    if (key == null) return false;
    if (!key.isActive) return false;
    if (key.expiresAt != null && key.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  bool hasPermission(String keyValue, String permission) {
    final key = getKeyByValue(keyValue);
    if (key == null) return false;
    return key.hasPermission(permission);
  }

  bool hasAnyPermission(String keyValue, List<String> requiredPermissions) {
    final key = getKeyByValue(keyValue);
    if (key == null) return false;
    return key.hasAnyPermission(requiredPermissions);
  }

  Future<void> revokeKey(String keyId) async {
    await ensureBoxOpen();
    final keys = _getAllKeys();
    final index = keys.indexWhere((k) => k.id == keyId);
    if (index != -1) {
      keys[index] = ApiKey(
        id: keys[index].id,
        key: keys[index].key,
        name: keys[index].name,
        userId: keys[index].userId,
        createdAt: keys[index].createdAt,
        expiresAt: keys[index].expiresAt,
        isActive: false,
        permissions: keys[index].permissions,
      );
      _saveKeys(keys);
    }
  }

  Future<void> deleteKey(String keyId) async {
    await ensureBoxOpen();
    final keys = _getAllKeys();
    keys.removeWhere((k) => k.id == keyId);
    _saveKeys(keys);
  }

  List<ApiKey> getAllKeys() {
    return _getAllKeys();
  }

  List<ApiKey> _getAllKeys() {
    try {
      final raw = _hiveBox.get('keys');
      if (raw is List) {
        return raw
            .where((item) => item is Map)
            .map((item) => ApiKey.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _saveKeys(List<ApiKey> keys) {
    try {
      _hiveBox.put('keys', keys.map((k) => k.toJson()).toList());
    } catch (_) {}
  }
}