class Album {
  final String id;
  final String name;
  final List<String> songIds;

  Album({ required this.id, required this.name, required this.songIds });

  factory Album.fromMap(String id, Map<String, dynamic> data) {
    return Album(
      id: id,
      name: data['name'] as String,
      songIds: List<String>.from(data['songIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'songIds': songIds,
  };
}
