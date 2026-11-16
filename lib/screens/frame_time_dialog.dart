import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamabudchi_app/barrel.dart';

/// What the dialog hands back: the base time and how much it may vary.
typedef FrameTiming = ({int frameMs, int jitterPercent});

/// Type an exact time per frame, in milliseconds, and how much each frame's
/// time may vary. Null if cancelled.
Future<FrameTiming?> showFrameTimeDialog(
  BuildContext context,
  int currentMs,
  int currentJitterPercent,
) {
  return showDialog<FrameTiming>(
    context: context,
    builder: (_) => _FrameTimeDialog(
      currentMs: currentMs,
      currentJitterPercent: currentJitterPercent,
    ),
  );
}

class _FrameTimeDialog extends StatefulWidget {
  final int currentMs;
  final int currentJitterPercent;

  const _FrameTimeDialog({
    required this.currentMs,
    required this.currentJitterPercent,
  });

  @override
  State<_FrameTimeDialog> createState() => _FrameTimeDialogState();
}

class _FrameTimeDialogState extends State<_FrameTimeDialog> {
  late final TextEditingController _text = TextEditingController(
    text: '${widget.currentMs}',
  );
  late int _jitter = widget.currentJitterPercent;

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
      title: const Text('Frame timing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Time per frame',
              suffixText: 'ms',
              helperText: value == null
                  ? 'Enter ${Sprite.minFrameMs} to ${Sprite.maxFrameMs}'
                  : 'About ${(1000 / value).toStringAsFixed(1)} frames per second',
            ),
            onChanged: (_) => setState(() {}), // re-check the value
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          Text('Variation: ±$_jitter%'),
          Slider(
            value: _jitter.toDouble(),
            min: 0,
            max: Sprite.maxJitterPercent.toDouble(),
            divisions: Sprite.maxJitterPercent ~/ 5, // steps of 5%
            label: '±$_jitter%',
            onChanged: (v) => setState(() => _jitter = v.round()),
          ),
          Text(_rangeHelp ?? '', style: Theme.of(context).textTheme.bodySmall),
        ],
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

  /// Shows what the variation means in milliseconds, using the same
  /// holdDuration the animation uses, so the preview can't disagree with it.
  String? get _rangeHelp {
    final ms = _value;
    if (ms == null) return null;
    if (_jitter == 0) return 'Every frame holds the same time';

    final base = Duration(milliseconds: ms);
    final low = holdDuration(base, 1 - _jitter / 100).inMilliseconds;
    final high = holdDuration(base, 1 + _jitter / 100).inMilliseconds;
    return 'Each frame holds $low to $high ms';
  }

  void _submit() {
    final value = _value;
    if (value != null) {
      Navigator.of(context).pop((frameMs: value, jitterPercent: _jitter));
    }
  }
}
