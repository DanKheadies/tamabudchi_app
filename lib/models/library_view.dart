import 'sprite_model.dart';

/// Which slice of the library a view shows.
enum LibraryScope { all, desktop, folder, unfiled }

/// A choice of view: a scope, plus the folder name when the scope is
/// [LibraryScope.folder]. Records compare by value, so two views with the
/// same scope and folder are equal.
typedef LibraryView = ({LibraryScope scope, String? folder});

const LibraryView allView = (scope: LibraryScope.all, folder: null);
const LibraryView desktopView = (scope: LibraryScope.desktop, folder: null);
const LibraryView unfiledView = (scope: LibraryScope.unfiled, folder: null);

LibraryView folderView(String name) =>
    (scope: LibraryScope.folder, folder: name);

/// Whether [sprite] belongs in [view].
bool spriteInView(Sprite sprite, LibraryView view) => switch (view.scope) {
  LibraryScope.all => true,
  LibraryScope.desktop => sprite.onDesktop,
  LibraryScope.folder => sprite.folders.contains(view.folder),
  LibraryScope.unfiled => sprite.folders.isEmpty,
};

/// A short name for [view], for messages.
String viewLabel(LibraryView view) => switch (view.scope) {
  LibraryScope.desktop => 'Desktop',
  LibraryScope.all => 'All',
  LibraryScope.unfiled => 'Unfiled',
  LibraryScope.folder => view.folder ?? 'this folder',
};

/// What's typed in a search box, as lowercase words.
List<String> searchTokens(String text) => text
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

/// Every word has to appear in the sprite's name or in one of its folder
/// names, so "char walk" finds CHAR_1_WALK and "walk dog" finds DOG_1_WALK.
bool matchesSearch(Sprite sprite, List<String> tokens) {
  if (tokens.isEmpty) return true;
  final haystack = '${sprite.name} ${sprite.folders.join(' ')}'.toLowerCase();
  return tokens.every(haystack.contains);
}

/// A–Z in natural order ("CHAR_2" before "CHAR_10"). Sprites with the same
/// name keep a stable order by id. Returns a new list.
List<Sprite> sortedByName(Iterable<Sprite> sprites) =>
    [...sprites]..sort((a, b) {
      final byName = compareNames(a.name, b.name);
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
