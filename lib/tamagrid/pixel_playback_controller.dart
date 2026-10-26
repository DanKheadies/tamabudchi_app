import 'package:flutter/material.dart';

class PixelPlaybackController extends ChangeNotifier {
  // PixelPlaybackController({required int frameCount}) : frameCount = frameCount;
  PixelPlaybackController({required this._frameCount});

  static const maxSpeed = 8.0;
  static const minSpeed = 0.25;

  int _frameCount;
  int _frameIndex = 0;
  bool _playing = true;
  double _speed = 1.0;

  int get frameIndex => _frameIndex;
  bool get playing => _playing;
  double get speed => _speed;
  int get frameCount => _frameCount;

  set frameCount(int value) {
    _frameCount = value;
    if (_frameIndex >= value) _frameIndex = value == 0 ? 0 : value - 1;
    notifyListeners();
  }

  void pause() {
    print('pause');
    _playing = false;
    notifyListeners();
  }

  void play() {
    print('play');
    _playing = true;
    notifyListeners();
  }

  void toggle() => _playing ? pause() : play();

  void _setSpeed(double s) {
    _speed = s.clamp(minSpeed, maxSpeed);
    notifyListeners();
  }

  void speedUp() => _setSpeed(_speed * 2);
  void slowDown() => _setSpeed(_speed / 2);

  void _move(int delta) {
    if (_frameCount == 0) return;
    _frameIndex = (_frameIndex + delta) % _frameCount;
    if (_frameIndex < 0) _frameIndex += _frameCount;
    notifyListeners();
  }

  void advance() => _move(1);

  void jumpTo(int index) {
    _frameIndex = index.clamp(0, _frameCount - 1);
    notifyListeners();
  }

  // TODO: test if passing "-1" causes it to step back
  void step([int delta = 1]) {
    _playing = false;
    _move(delta);
  }
}
