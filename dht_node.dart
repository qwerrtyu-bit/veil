import 'dart:convert';
import 'dart:io';
import 'dart:math';

// DHT узел — хранит зашифрованные фрагменты
class DhtNode {
  final Map<String, List<Map<String, dynamic>>> _storage = {};
  final String _nodeId;
  final int _port;

  DhtNode(this._port) : _nodeId = _generateId();

  static String _generateId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    print('🟢 DHT узел ${_nodeId.substring(0, 8)} запущен на порту $_port');

    await for (final request in server) {
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        request.response.close();
        continue;
      }

      final path = request.uri.path;

      if (path == '/store') {
        final body = await utf8.decodeStream(request);
        final data = jsonDecode(body) as Map<String, dynamic>;
        final key = data['key'] as String;
        final value = data['value'] as Map<String, dynamic>;
        _storage[key] ??= [];
        _storage[key]!.add(value);
        print('💾 DHT: сохранено по ключу ${key.substring(0, 8)} (всего: ${_storage[key]!.length})');
        request.response.write(jsonEncode({'status': 'ok', 'nodeId': _nodeId}));
      } else if (path == '/find') {
        final key = request.uri.queryParameters['key'] ?? '';
        final result = _storage[key] ?? [];
        print('🔍 DHT: найдено ${result.length} по ключу ${key.substring(0, 8)}');
        request.response.write(jsonEncode({'messages': result, 'nodeId': _nodeId}));
      } else if (path == '/stats') {
        request.response.write(jsonEncode({
          'nodeId': _nodeId,
          'keys': _storage.length,
          'totalMessages': _storage.values.fold(0, (sum, list) => sum + list.length),
        }));
      } else if (path == '/ping') {
        request.response.write('pong');
      } else {
        request.response.write('DHT Node OK');
      }
      request.response.close();
    }
  }
}

void main() async {
  final port = int.tryParse(Platform.environment['DHT_PORT'] ?? '8444') ?? 8444;
  final node = DhtNode(port);
  await node.start();
}