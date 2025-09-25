import 'package:flutter/foundation.dart';

class GlobalProvider extends ChangeNotifier {
  Map<String, dynamic> globalData = {};

  void setValue(String key, dynamic value) {
    globalData[key] = value;
    notifyListeners();
  }

  dynamic getValue(String key) => globalData[key];
}
