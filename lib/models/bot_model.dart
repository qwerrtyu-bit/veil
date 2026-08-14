class VeilBot {
  final String id;
  final String name;
  final String username;
  final String token;
  final String ownerPublicKey;
  final bool isActive;
  final List<String> commands;
  final String welcomeMessage;
  final DateTime createdAt;
  final int totalMessages;

  VeilBot({
    required this.id,
    required this.name,
    required this.username,
    required this.token,
    required this.ownerPublicKey,
    this.isActive = true,
    this.commands = const [],
    this.welcomeMessage = '',
    required this.createdAt,
    this.totalMessages = 0,
  });

  factory VeilBot.fromJson(Map<String, dynamic> json) {
    return VeilBot(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      token: json['token'] as String,
      ownerPublicKey: json['ownerPublicKey'] as String,
      isActive: json['isActive'] as bool? ?? true,
      commands: List<String>.from(json['commands'] ?? []),
      welcomeMessage: json['welcomeMessage'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalMessages: json['totalMessages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'token': token,
      'ownerPublicKey': ownerPublicKey,
      'isActive': isActive,
      'commands': commands,
      'welcomeMessage': welcomeMessage,
      'createdAt': createdAt.toIso8601String(),
      'totalMessages': totalMessages,
    };
  }
}