/// Core model; includes static and dynamic
class Sprite {
  final bool onDesktop;
  final int frameMs;
  final int gridSize;
  final List<Set<int>> frames;
  final Set<String> folders;
  final String id;
  final String name;

  static const int defaultFrameMs = 400;
  static const int minFrameMs = 20;
  static const int maxFrameMs = 5000;

  const Sprite({
    required this.id,
    required this.name,
    required this.gridSize,
    required this.frames,
    this.folders = const {},
    this.onDesktop = true, // new sprites start on desktop
    this.frameMs = defaultFrameMs,
  });

  int get frameCount => frames.length;

  Sprite copyWith({
    bool? onDesktop,
    int? frameMs,
    List<Set<int>>? frames,
    Set<String>? folders,
    String? name,
  }) => Sprite(
    id: id,
    name: name ?? this.name,
    gridSize: gridSize, // fixed at creation
    frames: frames ?? this.frames,
    frameMs: frameMs ?? this.frameMs,
    folders: folders ?? this.folders,
    onDesktop: onDesktop ?? this.onDesktop,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gridSize': gridSize,
    'frames': [for (final f in frames) f.toList()..sort()],
    'frameMs': frameMs,
    'folders': folders.toList()..sort(compareFolderNames),
    'onDesktop': onDesktop,
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
      frameMs: (j['frameMs'] as num?)?.round() ?? defaultFrameMs,
      folders: {
        for (final f in (j['folders'] as List?) ?? const []) f as String,
      },
      onDesktop: (j['onDesktop'] as bool?) ?? true,
    );
  }
}

/// Case-insensitive ordering for folder names, so "char_1" sorts next to
/// "CHAR_1" instead of after every capital letter.
int compareFolderNames(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());

/// Natural, case-insensitive name order: runs of digits compare as numbers,
/// so "CHAR_2" sorts before "CHAR_10".
int compareNames(String a, String b) {
  final parts = RegExp(r'(\d+)|(\D+)');
  final pa = [for (final m in parts.allMatches(a.toLowerCase())) m[0]!];
  final pb = [for (final m in parts.allMatches(b.toLowerCase())) m[0]!];

  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final x = pa[i];
    final y = pb[i];
    final xNum = int.tryParse(x);
    final yNum = int.tryParse(y);
    final c = (xNum != null && yNum != null)
        ? xNum.compareTo(yNum)
        : x.compareTo(y);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}
