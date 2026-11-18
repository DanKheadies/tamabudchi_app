/// The two control bars around the grid in the editor.
enum BarKind { sequence, frames }

/// Which bars sit before the grid (left in landscape, top in portrait) and
/// which sit after it (right / bottom). Each list reads in the order you'd
/// see the bars on screen.
typedef BarPlacement = ({List<BarKind> before, List<BarKind> after});

enum BarLayout {
  /// Playback bar before the grid, frames bar after it (the original look).
  split,

  /// The same two bars, trading sides.
  swapped,

  /// Both bars before the grid (left in landscape, top in portrait).
  stackedStart,

  /// Both bars after the grid (right / bottom): a mirror of [stackedStart].
  stackedEnd;

  BarPlacement get placement => switch (this) {
    BarLayout.split => (
      before: <BarKind>[BarKind.sequence],
      after: <BarKind>[BarKind.frames],
    ),
    BarLayout.swapped => (
      before: <BarKind>[BarKind.frames],
      after: <BarKind>[BarKind.sequence],
    ),
    BarLayout.stackedStart => (
      before: <BarKind>[BarKind.sequence, BarKind.frames],
      after: <BarKind>[],
    ),
    BarLayout.stackedEnd => (
      before: <BarKind>[],
      after: <BarKind>[BarKind.frames, BarKind.sequence],
    ),
  };
}
