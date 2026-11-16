import 'package:flutter/material.dart';

class PixelPlaybackController extends ChangeNotifier {
  PixelPlaybackController({required this._frameCount});

  int _frameCount;
  int _frameIndex = 0;
  bool _playing = true;

  int get frameIndex => _frameIndex;
  bool get playing => _playing;
  int get frameCount => _frameCount;

  set frameCount(int value) {
    _frameCount = value;
    if (_frameIndex >= value) _frameIndex = value == 0 ? 0 : value - 1;
    notifyListeners();
  }

  void pause() {
    _playing = false;
    notifyListeners();
  }

  void play() {
    _playing = true;
    notifyListeners();
  }

  void toggle() => _playing ? pause() : play();

  void _move(int delta) {
    if (_frameCount == 0) return;
    _frameIndex = (_frameIndex + delta) % _frameCount;
    // if (_frameIndex < 0) _frameIndex += _frameCount;
    notifyListeners();
  }

  void advance() => _move(1);

  void jumpTo(int index) {
    _frameIndex = index.clamp(0, _frameCount - 1);
    notifyListeners();
  }

  void step([int delta = 1]) {
    _playing = false;
    _move(delta);
  }
}
