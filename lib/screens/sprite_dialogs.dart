import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

typedef SpriteDetails = ({String name, int gridSize});

/// Ask for a name and grid size. Null if cancelled.
Future<SpriteDetails?> showNewSpriteDialog(
  BuildContext context, {
  required String suggestedName,
}) {
  return showDialog<SpriteDetails>(
    context: context,
    builder: (_) => _SpriteDialog(
      title: 'New sprite',
      confirmLabel: 'Create',
      initialName: suggestedName,
      pickGridSize: true,
    ),
  );
}

/// Ask for a new name. Null if cancelled. (Grid size is fixed per sprite, so
/// there's no size picker here.)
Future<String?> showRenameDialog(
  BuildContext context,
  String currentName,
) async {
  final details = await showDialog<SpriteDetails>(
    context: context,
    builder: (_) => _SpriteDialog(
      title: 'Rename sprite',
      confirmLabel: 'Rename',
      initialName: currentName,
      pickGridSize: false,
    ),
  );
  return details?.name;
}

/// Deleting has no undo, so always confirm.
Future<bool> confirmDeleteSprite(BuildContext context, Sprite sprite) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete sprite?'),
      content: Text('"${sprite.name}" will be deleted. This can\'t be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _SpriteDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final bool pickGridSize;

  const _SpriteDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.pickGridSize,
  });

  @override
  State<_SpriteDialog> createState() => _SpriteDialogState();
}

class _SpriteDialogState extends State<_SpriteDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  int _gridSize = 5;

  bool get _valid => _name.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop((name: _name.text.trim(), gridSize: _gridSize));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}), // re-check _valid
            onSubmitted: (_) => _submit(),
          ),
          if (widget.pickGridSize) ...[
            const SizedBox(height: 24),
            Text('Grid size: $_gridSize × $_gridSize'),
            Slider(
              min: SpriteLibrary.minGridSize.toDouble(),
              max: SpriteLibrary.maxGridSize.toDouble(),
              divisions: SpriteLibrary.maxGridSize - SpriteLibrary.minGridSize,
              value: _gridSize.toDouble(),
              label: '$_gridSize',
              onChanged: (v) => setState(() => _gridSize = v.round()),
            ),
            Text(
              'Can\'t be changed after the sprite is created.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? _submit : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
