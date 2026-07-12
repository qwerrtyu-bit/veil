import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8445);
  print('🟢 WebRTC Signal Server запущен на ws://localhost:8445');

  final Map<String, WebSocket> clients = {};

  await for (final request in server) {
    if (request.uri.path == '/ws') {
      final socket = await WebSocketTransformer.upgrade(request);
      String? clientId;

      socket.listen(
        (data) {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          final type = msg['type'] as String?;

          switch (type) {
            case 'register':
              clientId = msg['userId'] as String;
              clients[clientId!] = socket;
              print('✅ WebRTC клиент: ${clientId!.substring(0, 8)}');
              socket.add(jsonEncode({'type': 'registered'}));
              break;

            case 'offer':
            case 'answer':
            case 'ice-candidate':
              final targetId = msg['targetId'] as String?;
              if (targetId != null && clients.containsKey(targetId)) {
                print('📡 Пересылаю ${type} → ${targetId.substring(0, 8)}');
                clients[targetId]!.add(data);
              }
              break;

            case 'hangup':
              final targetId = msg['targetId'] as String?;
              if (targetId != null && clients.containsKey(targetId)) {
                clients[targetId]!.add(data);
              }
              break;
          }
        },
        onDone: () {
          if (clientId != null) {
            clients.remove(clientId);
            print('👋 WebRTC клиент отключился: ${clientId!.substring(0, 8)}');
          }
        },
      );
    } else {
      request.response.write('WebRTC Signal Server OK');
      request.response.close();
    }
  }
}