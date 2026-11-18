import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tamabudchi_app/barrel.dart';

enum _LibraryAction { copyAll, deleteFolder, import, renameFolder, settings }

// enum _Scope { all, desktop, folder, unfiled }

// typedef _View = ({_Scope scope, String? folder});

// const _View _allView = (scope: _Scope.all, folder: null);
// const _View _desktopView = (scope: _Scope.desktop, folder: null);
// const _View _unfiledView = (scope: _Scope.unfiled, folder: null);

/// Home screen: every saved sprite, plus the only place new ones are made.
class LibraryScreen extends StatefulWidget {
  final AppSettings settings;
  final SpriteLibrary library;

  const LibraryScreen({
    super.key,
    required this.library,
    required this.settings,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _searching = false;
  LibraryView _view = desktopView;

  final TextEditingController _queryController = TextEditingController();

  // The list needs to redraw when either the sprites or a setting changes.
  late final Listenable _changes = Listenable.merge([
    widget.library,
    widget.settings,
  ]);

  AppSettings get settings => widget.settings;
  SpriteLibrary get library => widget.library;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _queryTokens.isNotEmpty;

    return PopScope(
      // Back closes the search box first instead of leaving the app.
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _searching
              ? TextField(
                  controller: _queryController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search names and folders',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : const Text('Sprites'),
          leading: _searching
              ? IconButton(
                  tooltip: 'Close search',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _closeSearch,
                )
              : null,
          actions: [
            if (!_searching)
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: _openSearch,
              )
            else if (searching)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _queryController.clear();
                  setState(() {});
                },
              ),

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
                  case _LibraryAction.settings:
                    showSettingsSheet(context, widget.settings);
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
                const PopupMenuItem(
                  value: _LibraryAction.settings,
                  child: Text('Show settings'),
                ),
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
          listenable: _changes,
          builder: (context, _) {
            final folders = library.folders;
            final sprites = library.sprites;
            final tokens = _queryTokens;

            if (_view.scope == LibraryScope.folder &&
                !folders.contains(_view.folder)) {
              _view = allView;
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

            final sorted = settings.sortAlphabetically;

            // Search narrows whatever view is selected. The chips are counted
            // from the matches, so you can see which views hold them.
            final matches = [
              for (final s in sprites)
                if (matchesSearch(s, tokens)) s,
            ];
            // final visible = [
            //   for (final s in matches)
            //     if (_inView(s, _view)) s,
            // ];
            // // A–Z is only a way of looking: the arranged order stays underneath.
            // if (sorted) {
            //   visible.sort((a, b) {
            //     final byName = compareNames(a.name, b.name);
            //     return byName != 0 ? byName : a.id.compareTo(b.id);
            //   });
            // }
            final inView = [
              for (final s in matches)
                if (spriteInView(s, _view)) s,
            ];
            // A–Z is only a way of looking: the arranged order stays underneath.
            final visible = sorted ? sortedByName(inView) : inView;

            return Column(
              children: [
                _viewChips(matches, folders),
                Expanded(
                  child: visible.isEmpty
                      ? _emptyMessage(searching: tokens.isNotEmpty)
                      : SlidableAutoCloseBehavior(
                          child: _spriteList(
                            visible,
                            // Dragging a search result would be ambiguous.
                            reorderable: !sorted && tokens.isEmpty,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // bool _inView(Sprite sprite, _View view) => switch (view.scope) {
  //   _Scope.all => true,
  //   _Scope.desktop => sprite.onDesktop,
  //   _Scope.folder => sprite.folders.contains(view.folder),
  //   _Scope.unfiled => sprite.folders.isEmpty,
  // };

  Future<void> _create() async {
    final details = await showNewSpriteDialog(
      context,
      suggestedName: 'Sprite ${library.sprites.length + 1}',
      initialGridSize: settings.lastGridSize,
    );
    if (details == null || !context.mounted) return;

    final sprite = library.create(
      name: details.name,
      gridSize: details.gridSize,
      folder: _view.folder,
    );
    // A blank sprite is only useful to draw on, so open it ready to edit.
    _open(sprite, startEditing: true);
    unawaited(settings.setLastGridSize(details.gridSize));
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
          settings: widget.settings,
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

  Widget _emptyMessage({required bool searching}) {
    if (searching) {
      final inAll = _view.scope == LibraryScope.all;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              inAll
                  ? 'No sprites match your search.'
                  : 'No matches in ${viewLabel(_view)}.',
              textAlign: TextAlign.center,
            ),
            if (!inAll)
              TextButton(
                onPressed: () => setState(() => _view = allView),
                child: const Text('Search all sprites'),
              ),
          ],
        ),
      );
    }

    final text = switch (_view.scope) {
      LibraryScope.desktop =>
        'Nothing on your desktop.\n'
            'New sprites start here.\n'
            'Tap "All" to see everything.',
      LibraryScope.unfiled => 'Every sprite is in a folder.',
      _ => 'Nothing here.',
    };
    return Center(child: Text(text, textAlign: TextAlign.center));
  }

  Widget _spriteList(List<Sprite> visible, {required bool reorderable}) {
    Widget tile(Sprite sprite) => SpriteTile(
      // Keyed by id so a tile's preview state stays with its own sprite when
      // the list changes.
      key: ValueKey(sprite.id),
      sprite: sprite,
      actions: settings.tileActions,
      onOpen: () => _open(sprite),
      onRename: () => _rename(sprite),
      onOrganize: () => _organize(sprite),
      onCopy: () => _copyOne(sprite),
      onDelete: () => _delete(sprite),
    );

    const padding = EdgeInsets.only(bottom: 96); // clear the New sprite button

    if (!reorderable) {
      return ListView.builder(
        padding: padding,
        itemCount: visible.length,
        itemBuilder: (context, i) => tile(visible[i]),
      );
    }

    // One order for the whole library; dragging in a filtered view only
    // rearranges the slots those sprites already occupy.
    final ids = [for (final s in visible) s.id];
    return ReorderableListView.builder(
      padding: padding,
      buildDefaultDragHandles: false, // long-press anywhere on a tile instead
      itemCount: visible.length,
      onReorderItem: (from, to) => library.moveWithin(ids, from, to),
      itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
        key: ValueKey(visible[i].id),
        index: i,
        child: tile(visible[i]),
      ),
    );
  }

  /// Desktop, All, then one chip per folder, each with its sprite count.
  Widget _viewChips(List<Sprite> sprites, List<String> folders) {
    Widget chip(String label, LibraryView view) => ChoiceChip(
      label: Text(
        '$label · ${sprites.where((s) => spriteInView(s, view)).length}',
      ),
      selected: _view == view,
      onSelected: (_) => setState(() => _view = view),
    );

    final sorted = settings.sortAlphabetically;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                chip('Desktop', desktopView),
                chip('All', allView),
                chip('Unfiled', unfiledView),
                for (final folder in folders) chip(folder, folderView(folder)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: sorted
              ? 'Sorted A–Z. Tap to use your own order.'
              : 'Sort A–Z',
          color: sorted ? Theme.of(context).colorScheme.primary : null,
          icon: const Icon(Icons.sort_by_alpha),
          onPressed: () => settings.setSortAlphabetically(!sorted),
        ),
      ],
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
    setState(() => _view = folderView(result));
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
    setState(() => _view = allView);
  }

  // ---- search -------------------------------------------------------------

  /// What's typed in the search box, as lowercase words.
  List<String> get _queryTokens => searchTokens(_queryController.text);

  // /// Every word has to appear in the sprite's name or in one of its folder
  // /// names, so "char walk" finds CHAR_1_WALK and "walk dog" finds DOG_1_WALK.
  // bool _matches(Sprite sprite, List<String> tokens) {
  //   if (tokens.isEmpty) return true;
  //   final haystack = '${sprite.name} ${sprite.folders.join(' ')}'.toLowerCase();
  //   return tokens.every(haystack.contains);
  // }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _queryController.clear();
    setState(() => _searching = false);
  }

  // String _viewLabel() => switch (_view.scope) {
  //   _Scope.desktop => 'Desktop',
  //   _Scope.all => 'All',
  //   _Scope.unfiled => 'Unfiled',
  //   _Scope.folder => _view.folder ?? 'this folder',
  // };
}
