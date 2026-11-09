import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

enum _TileAction { rename, delete }

/// Home screen: every saved sprite, plus the only place new ones are made.
class LibraryScreen extends StatelessWidget {
  final SpriteLibrary library;

  const LibraryScreen({super.key, required this.library});

  void _open(BuildContext context, Sprite sprite, {bool startEditing = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          library: library,
          sprite: sprite,
          startEditing: startEditing,
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final details = await showNewSpriteDialog(
      context,
      suggestedName: 'Sprite ${library.sprites.length + 1}',
    );
    if (details == null || !context.mounted) return;

    final sprite = library.create(
      name: details.name,
      gridSize: details.gridSize,
    );
    // A blank sprite is only useful to draw on, so open it ready to edit.
    _open(context, sprite, startEditing: true);
  }

  Future<void> _rename(BuildContext context, Sprite sprite) async {
    final name = await showRenameDialog(context, sprite.name);
    if (name != null) library.rename(sprite.id, name);
  }

  Future<void> _delete(BuildContext context, Sprite sprite) async {
    if (await confirmDeleteSprite(context, sprite)) {
      library.delete(sprite.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sprites')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('New sprite'),
      ),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final sprites = library.sprites;

          if (sprites.isEmpty) {
            return const Center(
              child: Text(
                'No sprites yet.\nTap "New sprite" to make one.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96), // clear the button
            itemCount: sprites.length,
            itemBuilder: (context, i) {
              final sprite = sprites[i];
              return _SpriteTile(
                sprite: sprite,
                onOpen: () => _open(context, sprite),
                onRename: () => _rename(context, sprite),
                onDelete: () => _delete(context, sprite),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpriteTile extends StatelessWidget {
  final Sprite sprite;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SpriteTile({
    required this.sprite,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final frames = sprite.frameCount;

    return ListTile(
      leading: SizedBox.square(
        dimension: 48,
        // Thumbnail = first frame, drawn by the same painter as the grid.
        child: CustomPaint(
          painter: PixelGridPainter(
            frame: sprite.frames.first,
            gridSize: sprite.gridSize,
          ),
        ),
      ),
      title: Text(sprite.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${sprite.gridSize} × ${sprite.gridSize} · '
        '$frames ${frames == 1 ? 'frame' : 'frames'}',
      ),
      trailing: PopupMenuButton<_TileAction>(
        onSelected: (action) {
          switch (action) {
            case _TileAction.rename:
              onRename();
            case _TileAction.delete:
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _TileAction.rename, child: Text('Rename')),
          PopupMenuItem(value: _TileAction.delete, child: Text('Delete')),
        ],
      ),
      onTap: onOpen,
    );
  }
}
