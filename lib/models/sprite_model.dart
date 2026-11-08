class Sprite {
  final String id;
  final String name;
  final int gridSize;
  final List<Set<int>> frames;

  const Sprite({
    required this.id,
    required this.name,
    required this.gridSize,
    required this.frames,
  });

  int get frameCount => frames.length;

  Sprite copyWith({String? name, List<Set<int>>? frames}) => Sprite(
    id: id,
    name: name ?? this.name,
    gridSize: gridSize, // fixed at creation
    frames: frames ?? this.frames,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gridSize': gridSize,
    'frames': [for (final f in frames) f.toList()..sort()],
  };

  factory Sprite.fromJson(Map<String, dynamic> j) {
    final size = j['gridSize'] as int;
    return Sprite(
      id: j['id'] as String,
      name: j['name'] as String,
      gridSize: size,
      frames: [
        for (final f in j['frames'] as List)
          {
            for (final i in f as List)
              if (i as int < size * size) i,
          },
      ],
    );
  }
}
