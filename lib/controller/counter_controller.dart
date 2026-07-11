import 'package:flutter/foundation.dart';

import '../model/counter_model.dart';

class CounterController extends ChangeNotifier {
  CounterController({CounterModel? model}) : _model = model ?? CounterModel();

  final CounterModel _model;

  int get count => _model.value;

  void increment() {
    _model.increment();
    notifyListeners();
  }
}
