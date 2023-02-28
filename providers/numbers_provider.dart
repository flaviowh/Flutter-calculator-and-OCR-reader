import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingOption {
  ///checks wether the results should appear on numbers row
  ///
  setSavingPref(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("saveToNumRow", value);
  }

  Future<bool> getSavingPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("saveToNumRow") ?? false;
  }
}

class NumbersProvider with ChangeNotifier {
  SavingOption savingOption = SavingOption();
  List<double> _ocrNumbers = []; //
  String _equationResult = "";

  String get result => _equationResult;
  setResult(String newResult, [bool notifylisteners = false]) {
    _equationResult = newResult;
    if (notifylisteners) {
      notifyListeners();
    }
    ;
  }

  List<double> get ocrNumbers => _ocrNumbers;

  bool _saveToNumRow = false;
  bool get saveToNumRow => _saveToNumRow;
  bool _displayingResult = false;
  bool get displayingResult => _displayingResult;

  clearNumbers() {
    _ocrNumbers.clear();
    notifyListeners();
  }

  setOCRNumbers(List<double> newNumbers) {
    _ocrNumbers = [...newNumbers];
    notifyListeners();
  }

  setSavingOption(bool value) {
    _saveToNumRow = value;
    savingOption.setSavingPref(value);
    notifyListeners();
  }

  setDisplayingResult(bool value) {
    _displayingResult = value;
    notifyListeners();
  }
}
