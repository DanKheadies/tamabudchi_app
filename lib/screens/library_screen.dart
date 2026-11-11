import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamabudchi_app/barrel.dart';

enum _LibraryAction { copyAll, deleteFolder, import, renameFolder }

enum _TileAction { copy, delete, organize, rename }

enum _Scope { all, desktop, folder }

typedef _View = ({_Scope scope, String? folder});

const _View _desktopView = (scope: _Scope.desktop, folder: null);
const _View _allView = (scope: _Scope.all, folder: null);

/// Home screen: every saved sprite, plus the only place new ones are made.
class LibraryScreen extends StatefulWidget {
  final SpriteLibrary library;

  const LibraryScreen({super.key, required this.library});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  SpriteLibrary get library => widget.library;

  _View _view = _desktopView;

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
                  _copyAll();
                case _LibraryAction.deleteFolder:
                  _deleteFolder();
                case _LibraryAction.import:
                  _import();
                case _LibraryAction.renameFolder:
                  _renameFolder();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _LibraryAction.copyAll,
                child: Text('Copy all sprites'),
              ),
              const PopupMenuItem(
                value: _LibraryAction.import,
                child: Text('Import sprites..'),
              ),
              if (_view.folder != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _LibraryAction.renameFolder,
                  child: Text('Rename the folder'),
                ),
                const PopupMenuItem(
                  value: _LibraryAction.deleteFolder,
                  child: Text('Delete this folder'),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New sprite'),
      ),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final folders = library.folders;
          final sprites = library.sprites;

          if (_view.scope == _Scope.folder && !folders.contains(_view.folder)) {
            _view = _allView;
          }

          if (sprites.isEmpty) {
            return const Center(
              child: Text(
                'No sprites yet.\nTap "New sprite" to make one,\n'
                'or import some from the menu.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final visible = [
            for (final s in sprites)
              if (_inView(s, _view)) s,
          ];

          return Column(
            children: [
              _viewChips(sprites, folders),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing on your desktop.\n'
                          'New sprites start here.\n'
                          'Tap "All" to see everything.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        // clear the New sprite button
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final sprite = visible[i];
                          return _SpriteTile(
                            // Keyed by id so a tile's preview state stays with
                            // its own sprite when the list changes.
                            key: ValueKey(sprite.id),
                            sprite: sprite,
                            onOpen: () => _open(sprite),
                            onRename: () => _rename(sprite),
                            onOrganize: () => _organize(sprite),
                            onCopy: () => _copyOne(sprite),
                            onDelete: () => _delete(sprite),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _inView(Sprite sprite, _View view) => switch (view.scope) {
    _Scope.desktop => sprite.onDesktop,
    _Scope.all => true,
    _Scope.folder => sprite.folders.contains(view.folder),
  };

  Future<void> _create() async {
    final details = await showNewSpriteDialog(
      context,
      suggestedName: 'Sprite ${library.sprites.length + 1}',
    );
    if (details == null || !context.mounted) return;

    final sprite = library.create(
      name: details.name,
      gridSize: details.gridSize,
      folder: _view.folder,
    );
    // A blank sprite is only useful to draw on, so open it ready to edit.
    _open(sprite, startEditing: true);
  }

  Future<void> _delete(Sprite sprite) async {
    if (await confirmDeleteSprite(context, sprite)) {
      library.delete(sprite.id);
    }
  }

  Future<void> _organize(Sprite sprite) async {
    final result = await showOrganizeDialog(
      context,
      sprite: sprite,
      knownFolders: library.folders,
    );
    if (result != null) {
      library.setOrganization(
        sprite.id,
        folders: result.folders,
        onDesktop: result.onDesktop,
      );
    }
  }

  Future<void> _rename(Sprite sprite) async {
    final name = await showRenameDialog(context, sprite.name);
    if (name != null) library.rename(sprite.id, name);
  }

  void _open(Sprite sprite, {bool startEditing = false}) {
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

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Desktop, All, then one chip per folder, each with its sprite count.
  Widget _viewChips(List<Sprite> sprites, List<String> folders) {
    Widget chip(String label, int count, _View view) => ChoiceChip(
      label: Text('$label · $count'),
      selected: _view == view,
      onSelected: (_) => setState(() => _view = view),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          chip(
            'Desktop',
            sprites.where((s) => s.onDesktop).length,
            _desktopView,
          ),
          chip('All', sprites.length, _allView),
          for (final folder in folders)
            chip(
              folder,
              sprites.where((s) => s.folders.contains(folder)).length,
              (scope: _Scope.folder, folder: folder),
            ),
        ],
      ),
    );
  }

  // ---- export / import ------

  Future<void> _copyAll() async {
    final count = library.sprites.length;
    if (count == 0) {
      _toast('Nothing to copy yet.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: library.exportJson()));
    if (!mounted) return;
    _toast(
      'Copied $count ${count == 1 ? 'sprite' : 'sprites'}. '
      'Paste them into a note or message to back up or move them.',
    );
  }

  Future<void> _copyOne(Sprite sprite) async {
    await Clipboard.setData(
      ClipboardData(text: library.exportJson(onlyId: sprite.id)),
    );
    if (!mounted) return;
    _toast('Copied "${sprite.name}".');
  }

  Future<void> _import() async {
    final result = await showImportDialog(context, library);
    if (result == null || !context.mounted) return;

    final parts = ['Added ${result.added}'];
    if (result.duplicates > 0) parts.add('${result.duplicates} already here');
    if (result.unreadable > 0) parts.add('${result.unreadable} unreadable');
    _toast(parts.join(' · '));
  }

  // ---- folders ------

  Future<void> _renameFolder() async {
    final old = _view.folder;
    if (old == null) return;

    final name = await showRenameFolderDialog(context, old);
    if (name == null || !mounted) return;

    // Stay on the folder, under whatever name it ended up with.
    final result = library.renameFolder(old, name);
    setState(() => _view = (scope: _Scope.folder, folder: result));
  }

  Future<void> _deleteFolder() async {
    final folder = _view.folder;
    if (folder == null) return;

    final count = library.sprites
        .where((s) => s.folders.contains(folder))
        .length;
    final confirmed = await confirmDeleteFolder(context, folder, count);
    if (!confirmed || !mounted) return;

    library.deleteFolder(folder);
    setState(() => _view = _allView);
  }
}

class _SpriteTile extends StatefulWidget {
  final Sprite sprite;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onOrganize;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _SpriteTile({
    super.key,
    required this.sprite,
    required this.onOpen,
    required this.onRename,
    required this.onOrganize,
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

    // Where this sprite lives: the desktop and/or its folders.
    final places = [
      if (sprite.onDesktop) 'Desktop',
      ...sprite.folders.toList()..sort(compareFolderNames),
    ];

    return ListTile(
      isThreeLine: places.isNotEmpty,
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
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sprite.gridSize} × ${sprite.gridSize} · '
            '$frames ${frames == 1 ? 'frame' : 'frames'}',
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
