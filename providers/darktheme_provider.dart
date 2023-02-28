import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkThemePreference {
  static const isDarkTheme = "isDarkTheme";

  setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(isDarkTheme, value);
  }

  Future<bool> getTheme() async {
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    bool isOSdarkMode = brightness == Brightness.dark;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isDarkTheme) ?? isOSdarkMode;
  }
}

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();

  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}

class MyStyles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      primaryColor: isDarkTheme ? Colors.black : Colors.white,
      disabledColor: Colors.grey,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
          colorScheme: isDarkTheme
              ? const ColorScheme.dark()
              : const ColorScheme.light()),
      appBarTheme: const AppBarTheme(
        elevation: 0.0,
      ),
      textSelectionTheme: TextSelectionThemeData(
          selectionColor: isDarkTheme ? Colors.white : Colors.black),
    );
  }
}

class ProcessStateProvider with ChangeNotifier {
  bool _processIsFinished = false;

  bool get processIsFinished => _processIsFinished;

  set processIsFinished(bool value) {
    _processIsFinished = value;
    notifyListeners();
  }
}
