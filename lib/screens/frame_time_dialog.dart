import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Type an exact time per frame, in milliseconds. Null if cancelled.
Future<int?> showFrameTimeDialog(BuildContext context, int currentMs) {
  return showDialog<int>(
    context: context,
    builder: (_) => _FrameTimeDialog(currentMs: currentMs),
  );
}

class _FrameTimeDialog extends StatefulWidget {
  final int currentMs;

  const _FrameTimeDialog({required this.currentMs});

  @override
  State<_FrameTimeDialog> createState() => _FrameTimeDialogState();
}

class _FrameTimeDialogState extends State<_FrameTimeDialog> {
  late final TextEditingController _text = TextEditingController(
    text: '${widget.currentMs}',
  );

  @override
  void initState() {
    super.initState();
    // Start with the number selected, so typing replaces it.
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;

    return AlertDialog(
      scrollable: true,
      title: const Text('Time per frame'),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          suffixText: 'ms',
          helperText: value == null
              ? 'Enter ${Sprite.minFrameMs} to ${Sprite.maxFrameMs}'
              : 'About ${(1000 / value).toStringAsFixed(1)} frames per second',
        ),
        onChanged: (_) => setState(() {}), // re-check the value
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: value == null ? null : _submit,
          child: const Text('Set'),
        ),
      ],
    );
  }

  /// The typed value, or null if it's empty or out of range.
  int? get _value {
    final value = int.tryParse(_text.text);
    if (value == null) return null;
    if (value < Sprite.minFrameMs || value > Sprite.maxFrameMs) return null;
    return value;
  }

  void _submit() {
    final value = _value;
    if (value != null) Navigator.of(context).pop(value);
  }
}
