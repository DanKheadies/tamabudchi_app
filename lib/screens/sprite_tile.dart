import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tamabudchi_app/barrel.dart';

enum _TileAction { copy, delete, organize, rename }

class SpriteTile extends StatefulWidget {
  final Sprite sprite;
  final TileActions actions;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onOrganize;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const SpriteTile({
    super.key,
    required this.sprite,
    required this.actions,
    required this.onOpen,
    required this.onRename,
    required this.onOrganize,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  State<SpriteTile> createState() => SpriteTileState();
}

class SpriteTileState extends State<SpriteTile> {
  bool _previewing = false;

  @override
  void didUpdateWidget(covariant SpriteTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Avoid running a preview from stale frames post edit / rename.
    if (_previewing && !identical(oldWidget.sprite, widget.sprite)) {
      _previewing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprite = widget.sprite;
    final frames = sprite.frameCount;

    // Where this sprite lives: the desktop and/or its folders.
    final places = [
      if (sprite.onDesktop) 'Desktop',
      ...sprite.folders.toList()..sort(compareFolderNames),
    ];

    final tile = ListTile(
      isThreeLine: places.isNotEmpty,
      leading: SizedBox.square(
        dimension: 48,
        child: _previewing
            ? LivePreview(sprite: sprite)
            // Thumbnail = first frame, drawn by the same painter as the grid.
            : CustomPaint(
                painter: PixelGridPainter(
                  frame: sprite.frames.first,
                  gridSize: sprite.gridSize,
                ),
              ),
      ),
      title: Text(sprite.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sprite.gridSize} × ${sprite.gridSize} · '
            '$frames ${frames == 1 ? 'frame' : 'frames'}'
            ' · ${sprite.frameMs}ms',
          ),
          if (places.isNotEmpty)
            Text(
              places.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
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
          if (widget.actions.showsMenu)
            PopupMenuButton<_TileAction>(
              onSelected: (action) {
                switch (action) {
                  case _TileAction.copy:
                    widget.onCopy();
                  case _TileAction.delete:
                    widget.onDelete();
                  case _TileAction.organize:
                    widget.onOrganize();
                  case _TileAction.rename:
                    widget.onRename();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: _TileAction.rename, child: Text('Rename')),
                PopupMenuItem(
                  value: _TileAction.organize,
                  child: Text('Folders & desktop…'),
                ),
                PopupMenuItem(value: _TileAction.copy, child: Text('Copy')),
                PopupMenuItem(value: _TileAction.delete, child: Text('Delete')),
              ],
            ),
        ],
      ),
      onTap: _open,
    );

    final colors = Theme.of(context).colorScheme;

    return Slidable(
      // Off in menu-only mode.
      enabled: widget.actions.showsSwipe,
      // Opening one tile closes any other that's open.
      groupTag: 'library-tiles',
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (_) => widget.onCopy(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: Icons.copy,
            label: 'Copy',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onRename(),
            backgroundColor: colors.secondary,
            foregroundColor: colors.onSecondary,
            icon: Icons.edit,
            label: 'Rename',
          ),
          SlidableAction(
            onPressed: (_) => widget.onOrganize(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: Icons.folder_outlined,
            label: 'Folders',
          ),
        ],
      ),
      child: tile,
    );
  }

  void _open() {
    setState(() => _previewing = false);
    widget.onOpen();
  }
}

/// A small looping animation (via PixelAnimation).
class LivePreview extends StatefulWidget {
  final Sprite sprite;

  const LivePreview({super.key, required this.sprite});

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
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
      baseFrameDuration: Duration(milliseconds: widget.sprite.frameMs),
      controller: _playback,
      frames: widget.sprite.frames,
      gridSize: widget.sprite.gridSize,
      jitterPercent: widget.sprite.jitterPercent,
    );
  }
}
