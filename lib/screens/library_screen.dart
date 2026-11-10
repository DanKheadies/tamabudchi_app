import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamabudchi_app/barrel.dart';

enum _LibraryAction { copyAll, import }

enum _TileAction { copy, delete, rename }

/// Home screen: every saved sprite, plus the only place new ones are made.
class LibraryScreen extends StatelessWidget {
  final SpriteLibrary library;

  const LibraryScreen({super.key, required this.library});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprites'),
        actions: [
          PopupMenuButton<_LibraryAction>(
            onSelected: (action) {
              switch (action) {
                case _LibraryAction.copyAll:
                  _copyAll(context);
                case _LibraryAction.import:
                  _import(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _LibraryAction.copyAll,
                child: Text('Copy all sprites'),
              ),
              PopupMenuItem(
                value: _LibraryAction.import,
                child: Text('Import sprites..'),
              ),
            ],
          ),
        ],
      ),
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
                'No sprites yet.\nTap "New sprite" to make one,\n'
                'or import some from the menu.',
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
                onCopy: () => _copyOne(context, sprite),
                onDelete: () => _delete(context, sprite),
              );
            },
          );
        },
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

  Future<void> _delete(BuildContext context, Sprite sprite) async {
    if (await confirmDeleteSprite(context, sprite)) {
      library.delete(sprite.id);
    }
  }

  Future<void> _rename(BuildContext context, Sprite sprite) async {
    final name = await showRenameDialog(context, sprite.name);
    if (name != null) library.rename(sprite.id, name);
  }

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

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- export / import ------

  Future<void> _copyAll(BuildContext context) async {
    final count = library.sprites.length;
    if (count == 0) {
      _toast(context, 'Nothing to copy yet.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: library.exportJson()));
    if (!context.mounted) return;
    _toast(
      context,
      'Copied $count ${count == 1 ? 'sprite' : 'sprites'}. '
      'Paste them into a note or message to back up or move them.',
    );
  }

  Future<void> _copyOne(BuildContext context, Sprite sprite) async {
    await Clipboard.setData(
      ClipboardData(text: library.exportJson(onlyId: sprite.id)),
    );
    if (!context.mounted) return;
    _toast(context, 'Copied "${sprite.name}".');
  }

  Future<void> _import(BuildContext context) async {
    final result = await showImportDialog(context, library);
    if (result == null || !context.mounted) return;

    final parts = ['Added ${result.added}'];
    if (result.duplicates > 0) parts.add('${result.duplicates} already here');
    if (result.unreadable > 0) parts.add('${result.unreadable} unreadable');
    _toast(context, parts.join(' · '));
  }
}

class _SpriteTile extends StatefulWidget {
  final Sprite sprite;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _SpriteTile({
    required this.sprite,
    required this.onOpen,
    required this.onRename,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  State<_SpriteTile> createState() => _SpriteTileState();
}

class _SpriteTileState extends State<_SpriteTile> {
  bool _previewing = false;

  @override
  void didUpdateWidget(covariant _SpriteTile old) {
    super.didUpdateWidget(old);

    // Avoid running a preview from stale frames post edit / rename.
    if (_previewing && !identical(old.sprite, widget.sprite)) {
      _previewing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprite = widget.sprite;
    final frames = sprite.frameCount;

    return ListTile(
      leading: SizedBox.square(
        dimension: 48,
        child: _previewing
            ? _LivePreview(sprite: sprite)
            // Thumbnail = first frame, drawn by the same painter as the grid.
            : CustomPaint(
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_previewing ? Icons.pause : Icons.play_arrow),
            onPressed: frames > 1
                ? () => setState(() => _previewing = !_previewing)
                : null,
            tooltip: _previewing ? 'Pause preview' : 'Play preview',
          ),
          PopupMenuButton<_TileAction>(
            onSelected: (action) {
              switch (action) {
                case _TileAction.copy:
                  widget.onCopy();
                case _TileAction.delete:
                  widget.onDelete();
                case _TileAction.rename:
                  widget.onRename();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TileAction.rename, child: Text('Rename')),
              PopupMenuItem(value: _TileAction.copy, child: Text('Copy')),
              PopupMenuItem(value: _TileAction.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
      onTap: _open,
    );
  }

  void _open() {
    setState(() => _previewing = false);
    widget.onOpen();
  }
}

/// A small looping animation (via PixelAnimation).
class _LivePreview extends StatefulWidget {
  final Sprite sprite;

  const _LivePreview({required this.sprite});

  @override
  State<_LivePreview> createState() => __LivePreviewState();
}

class __LivePreviewState extends State<_LivePreview> {
  late final PixelPlaybackController _playback = PixelPlaybackController(
    frameCount: widget.sprite.frameCount,
  );

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PixelAnimation(
      controller: _playback,
      frames: widget.sprite.frames,
      gridSize: widget.sprite.gridSize,
    );
  }
}
