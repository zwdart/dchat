import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void select(int value) {
    if (value == _index) return;
    _index = value;
    notifyListeners();
  }

  void openSettings() => select(3);

  void openDevices() => select(1);

  void openShare() => select(2);
}
