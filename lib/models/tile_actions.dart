/// How the actions on a library tile (rename, organize, delete, ...) are
/// reached.
enum TileActions {
  /// The menu button only.
  menu,

  /// Swipe only (no menu button).
  swipe,

  /// Either way.
  both;

  bool get showsMenu => this != TileActions.swipe;
  bool get showsSwipe => this != TileActions.menu;
}
