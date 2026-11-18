// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:tamabudchi_app/barrel.dart';

// bool inView(Sprite sprite, _View view) => switch (view.scope) {
//   _Scope.all => true,
//   _Scope.desktop => sprite.onDesktop,
//   _Scope.folder => sprite.folders.contains(view.folder),
//   _Scope.unfiled => sprite.folders.isEmpty,
// };

// /// What's typed in the search box, as lowercase words.
// List<String> get queryTokens => _queryController.text
//     .toLowerCase()
//     .split(RegExp(r'\s+'))
//     .where((t) => t.isNotEmpty)
//     .toList();

// /// Every word has to appear in the sprite's name or in one of its folder
// /// names, so "char walk" finds CHAR_1_WALK and "walk dog" finds DOG_1_WALK.
// bool matches(Sprite sprite, List<String> tokens) {
//   if (tokens.isEmpty) return true;
//   final haystack = '${sprite.name} ${sprite.folders.join(' ')}'.toLowerCase();
//   return tokens.every(haystack.contains);
// }
