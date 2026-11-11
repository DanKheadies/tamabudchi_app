import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

typedef SpriteOrganization = ({Set<String> folders, bool onDesktop});

/// Choose which folders a sprite is in and whether it's on the desktop.
/// Null if cancelled.
///
/// [knownFolders] are the folders that already exist in the library. New ones
/// typed here only come into being if the sprite ends up in them.
Future<SpriteOrganization?> showOrganizeDialog(
  BuildContext context, {
  required Sprite sprite,
  required List<String> knownFolders,
}) {
  return showDialog<SpriteOrganization>(
    context: context,
    builder: (_) => _OrganizeDialog(sprite: sprite, knownFolders: knownFolders),
  );
}

class _OrganizeDialog extends StatefulWidget {
  final Sprite sprite;
  final List<String> knownFolders;

  const _OrganizeDialog({required this.sprite, required this.knownFolders});

  @override
  State<_OrganizeDialog> createState() => _OrganizeDialogState();
}

class _OrganizeDialogState extends State<_OrganizeDialog> {
  late final Set<String> _selected = {...widget.sprite.folders};
  late bool _onDesktop = widget.sprite.onDesktop;

  // Folders typed in this dialog that don't exist in the library yet.
  final Set<String> _created = {};
  final TextEditingController _newFolder = TextEditingController();

  // Until the switch is touched by hand, the desktop flag follows the sprite
  // being filed or un-filed.
  bool _desktopTouched = false;

  List<String> get _allFolders =>
      {...widget.knownFolders, ..._created}.toList()..sort(compareFolderNames);

  /// Check or uncheck a folder. Call inside setState.
  void _select(String name, bool value) {
    final wasEmpty = _selected.isEmpty;
    if (value) {
      _selected.add(name);
    } else {
      _selected.remove(name);
    }

    // Filing a loose sprite takes it off the desktop; emptying its folders
    // puts it back (it shouldn't end up nowhere). Only the moment it goes
    // from "no folders" to "some" (or back) counts, so a sprite you've
    // pinned stays pinned as you add more folders.
    if (_desktopTouched) return;
    if (wasEmpty && _selected.isNotEmpty) _onDesktop = false;
    if (!wasEmpty && _selected.isEmpty) _onDesktop = true;
  }

  void _addFolder() {
    final typed = _newFolder.text.trim();
    if (typed.isEmpty) return;

    // Match existing folders ignoring case, so "char_1" reuses "CHAR_1".
    final lower = typed.toLowerCase();
    final existing = _allFolders.where((f) => f.toLowerCase() == lower);
    final name = existing.isEmpty ? typed : existing.first;

    setState(() {
      if (existing.isEmpty) _created.add(name);
      _select(name, true);
      _newFolder.clear();
    });
  }

  void _save() {
    _addFolder(); // keep a folder name that was typed but not added yet
    Navigator.of(
      context,
    ).pop((folders: Set<String>.of(_selected), onDesktop: _onDesktop));
  }

  @override
  void dispose() {
    _newFolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = _allFolders;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      scrollable: true, // keeps the dialog usable with the keyboard open
      title: Text(
        'Organize "${widget.sprite.name}"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('On desktop'),
            subtitle: const Text('Quick access while you work'),
            value: _onDesktop,
            onChanged: (value) => setState(() {
              _onDesktop = value;
              _desktopTouched = true;
            }),
          ),
          const Divider(),
          Text('Folders', style: textTheme.titleSmall),
          if (folders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No folders yet. Add one below.',
                style: textTheme.bodySmall,
              ),
            ),
          for (final name in folders)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(name),
              value: _selected.contains(name),
              onChanged: (value) =>
                  setState(() => _select(name, value ?? false)),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _newFolder,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'New folder',
              suffixIcon: IconButton(
                tooltip: 'Add folder',
                icon: const Icon(Icons.add),
                onPressed: _addFolder,
              ),
            ),
            onSubmitted: (_) => _addFolder(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
