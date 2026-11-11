import 'package:flutter/material.dart';

/// Ask for a folder's new name. Null if cancelled.
Future<String?> showRenameFolderDialog(
  BuildContext context,
  String currentName,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FolderNameDialog(currentName: currentName),
  );
}

/// Deleting a folder never deletes sprites, but say so before doing it.
Future<bool> confirmDeleteFolder(
  BuildContext context,
  String name,
  int spriteCount,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete folder?'),
      content: Text(
        'The folder "$name" will be removed. Its $spriteCount '
        '${spriteCount == 1 ? 'sprite is' : 'sprites are'} not deleted: they '
        'just leave the folder, and any left with no folder go back to the '
        'desktop.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete folder'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _FolderNameDialog extends StatefulWidget {
  final String currentName;

  const _FolderNameDialog({required this.currentName});

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.currentName,
  );

  bool get _valid => _name.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Rename folder'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Folder name'),
        onChanged: (_) => setState(() {}), // re-check _valid
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
