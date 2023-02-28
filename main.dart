import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:numeros/firebase_options.dart';
import 'package:numeros/providers/darktheme_provider.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:numeros/calculator.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/text_scanner_page.dart';
import 'package:numeros/calc_history.dart';
import 'package:numeros/model/historyentry.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    await Firebase.initializeApp();
    await Hive.initFlutter();
    Hive.registerAdapter(HistoryEntryAdapter());
    await Hive.openBox<HistoryEntry>('history');

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    runApp(const MyApp());
  },
      (error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  ProcessStateProvider processStatusProvider = ProcessStateProvider();
  NumbersProvider numbersProvider = NumbersProvider();
  TextEditingController mainTextController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
    getSavingPreference();
  }

  void getCurrentAppTheme() async {
    bool isDarkMode = await themeChangeProvider.darkThemePreference.getTheme();
    themeChangeProvider.darkTheme = isDarkMode;
    var overlayStyle =
        isDarkMode ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  void getSavingPreference() async {
    var preference = await SavingOption().getSavingPref();
    numbersProvider.setSavingOption(preference);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, DarkThemeProvider, child) {
          return ChangeNotifierProvider(
              create: (context) => numbersProvider,
              child: Consumer<NumbersProvider>(
                builder: (context, numbersProvider, child) => MaterialApp(
                  builder: EasyLoading.init(),
                  theme: MyStyles.themeData(
                      themeChangeProvider.darkTheme, context),
                  routes: {
                    '/': (context) => Calculator(
                          equationTextController: mainTextController,
                        ),
                    '/textScanner': (context) =>
                        TextScanner(title: translate('Text Scanner')),
                    '/calcHistory': (context) => CalcHistory(
                          equationTextController: mainTextController,
                        ),
                  },
                ),
              ));
        },
      ),
    );
  }
}
