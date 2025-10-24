import 'package:flutter/material.dart';

class QuantityProvider extends ChangeNotifier {
  int _currentNumber = 1;
  List<double> _baseIngredientAmounts = [];

  int get currentNumber => _currentNumber;

  void setBaseIngredientAmounts(List<double> amounts) {
    _baseIngredientAmounts = amounts;
    notifyListeners();
  }

  List<double> get updateIngredientAmounts {
    return _baseIngredientAmounts
        .map<double>((amount) => amount * _currentNumber)
        .toList();
  }

  void increaseQuantity() {
    _currentNumber++;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void decreaseQuantity() {
    if (_currentNumber > 1) {
      _currentNumber--;
      notifyListeners();
    }
  }
}
//capnhatcode