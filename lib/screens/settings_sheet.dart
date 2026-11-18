import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Preferences that change how the app lays itself out or behaves.
Future<void> showSettingsSheet(BuildContext context, AppSettings settings) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SettingsSheet(settings: settings),
  );
}

class _SettingsSheet extends StatelessWidget {
  final AppSettings settings;

  const _SettingsSheet({required this.settings});

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return SafeArea(
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Editor bars',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final layout in BarLayout.values)
                _layoutTile(layout, landscape),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Library tile actions'),
              ),
              for (final mode in TileActions.values) _tileActionsTile(mode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layoutTile(BarLayout layout, bool landscape) {
    final chosen = layout == settings.barLayout;
    final text = _describe(layout, landscape: landscape);

    return ListTile(
      selected: chosen,
      title: Text(text.title),
      subtitle: Text(text.subtitle),
      trailing: chosen ? const Icon(Icons.check) : null,
      onTap: () => settings.setBarLayout(layout),
    );
  }

  Widget _tileActionsTile(TileActions mode) {
    final chosen = mode == settings.tileActions;
    final text = _describeTileActions(mode);

    return ListTile(
      selected: chosen,
      title: Text(text.title),
      subtitle: Text(text.subtitle),
      trailing: chosen ? const Icon(Icons.check) : null,
      onTap: () => settings.setTileActions(mode),
    );
  }
}

/// Words for each layout, using the sides that match how the phone is held.
({String title, String subtitle}) _describe(
  BarLayout layout, {
  required bool landscape,
}) {
  final start = landscape ? 'left' : 'top';
  final end = landscape ? 'right' : 'bottom';

  return switch (layout) {
    BarLayout.split => (
      title: 'Split',
      subtitle: 'Playback on the $start, frames on the $end',
    ),
    BarLayout.swapped => (
      title: 'Swapped',
      subtitle: 'Frames on the $start, playback on the $end',
    ),
    BarLayout.stackedStart => (
      title: 'Stacked $start',
      subtitle: 'Both bars on the $start',
    ),
    BarLayout.stackedEnd => (
      title: 'Stacked $end',
      subtitle: 'Both bars on the $end',
    ),
  };
}

({String title, String subtitle}) _describeTileActions(TileActions mode) {
  return switch (mode) {
    TileActions.menu => (
      title: 'Menu button',
      subtitle: 'Actions only from the menu on each tile',
    ),
    TileActions.swipe => (
      title: 'Swipe only',
      subtitle: 'Swipe a tile for its actions; no menu button',
    ),
    TileActions.both => (
      title: 'Menu and swipe',
      subtitle: 'Use whichever is handier',
    ),
  };
}
