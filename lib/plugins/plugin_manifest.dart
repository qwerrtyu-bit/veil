class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final List<String> permissions;
  final String entryPoint;
  final String? icon;
  final String? repository;
  final List<String> dependencies;

  PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    this.permissions = const [],
    required this.entryPoint,
    this.icon,
    this.repository,
    this.dependencies = const [],
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      permissions: List<String>.from(json['permissions'] ?? []),
      entryPoint: json['entryPoint'] as String,
      icon: json['icon'] as String?,
      repository: json['repository'] as String?,
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'permissions': permissions,
      'entryPoint': entryPoint,
      'icon': icon,
      'repository': repository,
      'dependencies': dependencies,
    };
  }
}