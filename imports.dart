import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';
import 'providers/darktheme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropping/image_cropping.dart';
import 'firebase_ml_api.dart';

///GOOGLE API
///

/// MATH AND STATS
///
///
double sum(List<double> iterable) {
  return iterable.reduce((a, b) => (a + b));
}

double mean(List<double> iterable) {
  return sum(iterable) / iterable.length;
}

double variance(List<double> iterable) {
  double mean_ = mean(iterable);
  Iterable squares = iterable.map((e) => pow((e - mean_), 2));
  List<double> squares_ = [...squares];
  return sum(squares_) / (iterable.length - 1);
}

double stdev(List<double> iterable) {
  return sqrt(variance(iterable));
}

/// OTHER FUNCTIONS
///

List range(int end, [int? start]) {
  start ??= 0;
  return List.generate(end - start, (i) => i + start!);
}

/// FIND COMBINATIONS OF NUMBERS THAT RESULT IN TARGET
///
List combinations(List elements, [int? size]) {
  size ??= 2;

  void combine(int n, List lista, List got, List all) {
    if (n == 0) {
      if (got.isNotEmpty) {
        all.add(got);
      }
      return;
    }
    for (var j = 0; j < lista.length; j++) {
      combine(n - 1, lista.sublist(j + 1), got + [lista[j]], all);
    }
    return;
  }

  List all = [];

  combine(size, elements, [], all);

  return all;
}

//formatting functions & calculator

double stringToDouble(String unformatted) {
  String step1 = unformatted.replaceFirst(',', '.');
  String step2 = step1.replaceFirst('%', '');
  int numPoints = '.'.allMatches(step2).length;

  String valueString = step2;
  if (numPoints <= 1) {
    return double.parse(valueString);
  }

  for (var i = 1; i < numPoints; i++) {
    valueString = valueString.replaceFirst('.', '');
  }

  return double.parse(valueString);
}

bool isReadyToCalculate(String equation) {
  String lastDigit = equation.substring(equation.length - 1, equation.length);
  bool goodLastDigit = !["+", " ", "*", ' ', '('].contains(lastDigit);
  return goodLastDigit ? true : false;
}

const Map<String, String> operationsSigns = {
  '÷': '/',
  '×': '*',
  'x': '*',
  "√": "sqrt",
  "log(": "log(10, ",
  '℮': ' $e',
  "π": '$pi',
};

String closeParenthesis(String expression) {
  var numOpen = "(".allMatches(expression).length;
  var numClosed = ')'.allMatches(expression).length;
  if (numOpen != numClosed) {
    return numOpen > numClosed ? "$expression)" : "($expression";
  }

  return expression;
}

formatNum(String number) {
  RegExp pattern = RegExp(r"(\d\.\d+)|(\d\.)(0{2,})");
  var formatted = number.replaceFirstMapped(
      pattern, (match) => match.group(1)!.replaceFirst(RegExp(r'0{2,}$'), ''));
  return formatted.endsWith('.')
      ? formatted.substring(0, formatted.length - 1)
      : formatted;
}

String parseExp(String expression) {
  if (expression.isEmpty) {
    return expression;
  }
  operationsSigns.forEach((sign, sub) {
    expression = expression.replaceAll(sign, sub);
  });
  expression = closeParenthesis(expression);
  try {
    Parser p = Parser();
    Expression exp = p.parse(expression);
    ContextModel contextModel = ContextModel();
    var result = exp.evaluate(EvaluationType.REAL, contextModel);
    result = result.toStringAsFixed(10);
    return formatNum(result);
  } catch (e) {
    return "Error";
  }
}

// SEPARATES THE NUMBERS OF AN EQUATION WITH  ,
String commaSeparate(String equation) {
  String addCommas(String expression) {
    var length = expression.length;
    if (length <= 3) {
      return expression;
    }
    int thirds = (length ~/ 3);
    var rest = length % 3;
    for (var i in range(thirds)) {
      var split = (3 * i + rest).toInt();
      var part1 = expression.substring(0, split);
      var part2 = expression.substring(split);
      expression = '$part1,$part2';
      rest++;
    }
    return expression;
  }

  Iterable<String> matches = RegExp(r"(\(|^|\s|\-)\d{4,}")
      .allMatches(equation)
      .map((m) => m.group(0)!);

  for (var exp in matches) {
    equation = equation.replaceFirst(exp, addCommas(exp));
  }
  return equation.replaceAllMapped(
      RegExp("(√|!|g|n|÷|x|×|\\+|-|\\(|^|\\s),(\\d|(|\\s))"),
      (match) => match.group(0)!.replaceFirst(',', ''));
}

///CALCULATOR APPBAR
///
AppBar calculatorAppBar(BuildContext context) {
  final mediaQuery = MediaQuery.of(context).size;
  final themeProvider = Provider.of<DarkThemeProvider>(context);
  return AppBar(
    title: const Text(""),
    backgroundColor: themeProvider.darkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : Colors.white,
    toolbarHeight: mediaQuery.height * 0.05,
    iconTheme: IconThemeData(
        color: themeProvider.darkTheme
            ? const Color.fromARGB(255, 240, 227, 157)
            : Colors.black),
    actions: <Widget>[
      IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed("/calcHistory");
          },
          icon: const Icon(
            Icons.history,
          )),
      IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed("/textScanner");
          },
          icon: const Icon(
            Icons.text_fields,
          )),
    ],
  );
}

double decreasingText(
    String text, num initialSize, num breakpoint, num minSize) {
  var length = text.length;
  var size = length > 1
      ? text.length < breakpoint
          ? initialSize
          : max((initialSize - (length - breakpoint)), minSize)
      : initialSize;
  return size.toDouble();
}

scientToString(String numString) {
  final Function dec = (String s) => Decimal.parse(s);
  RegExp pattern = RegExp(r"(\d+\.\d+|\d+)e(\+|-)\d+");
  return numString.replaceAllMapped(
      pattern, (match) => dec(match.group(0)!).toString());
}

String formatEq(String equation, [bool toResult = false]) {
  String formattedEq = equation;
  List signals = [
    [' x x ', ' x '],
    [' ÷ ÷ ', ' ÷ '],
    [' × × ', ' × '],
    ['  ', ' '],
    [' + + ', ' + '],
    ['..', '.'],
    [' -  - ', ' - '],
  ];

  for (List pattern in signals) {
    formattedEq = formattedEq.replaceAll(pattern[0], pattern[1]);
  }

  if (toResult && equation.contains("e")) {
    try {
      formattedEq = scientToString(equation);
    } catch (e) {}
  }

  return formattedEq;
}

String evaluateEquation(String equation, [bool toResult = false]) {
  // to_result tells the formatter to translate scientific notation to full number
  // for the parser to display a correct result (in notation), but not do that to
  // the equation displayed on screen.
  if (!normalOperators.any((sign) => equation.endsWith(sign))) {
    String formattedEq = formatEq(equation, toResult);
    try {
      var prevResult = parseExp(formattedEq);
      if (prevResult.endsWith('.0')) {
        return prevResult.substring(0, prevResult.length - 2);
      } else {
        return prevResult;
      }
    } catch (e) {
      return '';
    }
  }
  return '';
}

/// LOADERS -  to be tested

/// To display loader with loading text
void showLoader() {
  if (EasyLoading.isShow) {
    return;
  }
  EasyLoading.show(status: 'Loading');
}

/// To hide loader
void hideLoader() {
  EasyLoading.dismiss();
}

class CaptureNumbers {
  final BuildContext context;
  final DarkThemeProvider themeProvider;
  File? imageFile;

  bool cropDone = false;

  CaptureNumbers(this.context, this.themeProvider);

  Future getNumbers(bool fromGallery) async {
    String ocrText = '';

    try {
      var image = await getPicture(fromGallery);
      if (image == null) return null;
      imageFile = File(image.path);

      await cropImage();

      if (imageFile == null) return null;
      ocrText = await readImage(imageFile!);
      List<double> foundNumbers = await lookForNumbers(ocrText);
      if (!cropDone) {
        showMessage(context, translate("Cancelled"));
        return;
      }
      if (foundNumbers.isNotEmpty) {
        return foundNumbers;
      } else {
        showMessage(
            context, translate('No numbers found.'), true); //, true, true);
      }
    } catch (e) {
      hideLoader();
    }
  }

  Future<File?> getPicture(bool fromGalery) async {
    ImageSource _source = fromGalery ? ImageSource.gallery : ImageSource.camera;
    try {
      final image = await ImagePicker().pickImage(source: _source);
      if (image == null) return null;
      return File(image.path);
    } catch (e) {}
  }

  Future<void> cropImage() async {
    int patience = 0;
    final tempDir = await getTemporaryDirectory();
    File newFile = await File('${tempDir.path}/edited_image.png').create();
    showLoader();
    Uint8List imageBytes = await imageFile!.readAsBytes();
    try {
      while (!cropDone) {
        if (patience > 0) {
          break;
        }
        await ImageCropping.cropImage(
            context: context,
            imageBytes: imageBytes,
            onImageDoneListener: (data) {
              imageBytes = data;
              newFile.writeAsBytesSync(imageBytes);
              cropDone = true;
              imageFile = newFile;
            },
            onImageStartLoading: showLoader,
            onImageEndLoading: hideLoader,
            visibleOtherAspectRatios: false,
            squareBorderWidth: 2,
            squareCircleSize: 22,
            isConstrain: false,
            squareCircleColor: Color.fromARGB(255, 199, 120, 18),
            defaultTextColor: Colors.black,
            selectedTextColor: Colors.orange,
            colorForWhiteSpace:
                themeProvider.darkTheme ? Colors.black : Colors.white,
            makeDarkerOutside: true,
            outputImageFormat: OutputImageFormat.png,
            encodingQuality: 10);
        patience = patience + 1;
      }
    } catch (e) {
      hideLoader();
    }
  }

  Future<String> readImage(File image) async {
    String text = await GoogleMlAPI.scanImage(image);
    return text;
  }
}
//CORRECT CURSOR INDEXES

List<int> correctIndexes(List<int> cursorIndexes, equation) {
  int x = cursorIndexes[0];
  int y = cursorIndexes[1];
  var formattedEq = commaSeparate(equation);
  int numCommas;
  if (x == y) {
    numCommas = ','.allMatches(formattedEq.substring(0, x)).length;
  } else {
    numCommas = ','.allMatches(formattedEq.substring(0, y)).length;
  }
  return [x - numCommas, y - numCommas];
}
// LOOK FOR NUMBERS IN STRING

Future lookForNumbers(String text) async {
  List<double> found = [];
  final RegExp numbersPattern = //if breaks, remove  '?'
      RegExp(r'((\d{1,3}(,|\.)?)+(\d{1,3})|(\s|^)\d+(\s|%|$))');

  void findNumbers(RegExp pattern) {
    for (var m in pattern.allMatches(text)) {
      var res = m[0];
      if (res != null) {
        var value = stringToDouble(res);
        if (value != 0.0) {
          found.add(stringToDouble(res));
        }
      }
    }
  }

  findNumbers(numbersPattern);
  return found;
}

String removeTrailingZero(double value) {
  var str = value.toString();
  return str.endsWith(".0") ? str.substring(0, str.length - 2) : str;
}

void showMessage(BuildContext context, String message, [bool redIcon = false]) {
  final themeProvider = Provider.of<DarkThemeProvider>(context, listen: false);
  var snackbar = SnackBar(
    duration: const Duration(seconds: 2),
    content: Wrap(spacing: 20, children: [
      Icon(
        Icons.info,
        semanticLabel: "Alert",
        color: redIcon && themeProvider.darkTheme
            ? Colors.redAccent
            : Colors.white,
        size: 25,
      ),
      Text(
        message,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    ]),
    backgroundColor: themeProvider.darkTheme
        ? const Color.fromARGB(255, 4, 5, 3)
        : Colors.blueGrey,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackbar);
}

class CalcDrawer extends StatefulWidget {
  const CalcDrawer({Key? key}) : super(key: key);

  @override
  State<CalcDrawer> createState() => _CalcDrawerState();
}

class _CalcDrawerState extends State<CalcDrawer> {
  bool savingOption = false;

  @override
  Widget build(BuildContext context) {
    final numbersProvider = Provider.of<NumbersProvider>(context, listen: true);
    final themeProvider =
        Provider.of<DarkThemeProvider>(context, listen: false);

    Future<void> openPrivacyNotice() async {
      if (!await launchUrl(
        Uri.parse(
            'https://sites.google.com/view/simpleocrcalculator-privacy/home'),
        mode: LaunchMode.inAppWebView,
      )) {
        throw 'Could not open website.';
      }
    }

    Color logoColor = themeProvider.darkTheme
        ? Color.fromARGB(255, 255, 185, 93)
        : Color.fromARGB(255, 47, 90, 230);
    Color drawerTextColor = themeProvider.darkTheme
        ? Color.fromARGB(255, 240, 227, 157)
        : Colors.black;
    Color drawerTextColorSelected = themeProvider.darkTheme
        ? Color.fromARGB(255, 240, 227, 157)
        : Colors.black;

    return Drawer(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          DrawerHeader(
            child: Text(
              'Simple OCR Calculator',
              style: TextStyle(color: logoColor, fontSize: 25),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: SwitchListTile(
                onChanged: (value) {
                  numbersProvider
                      .setSavingOption(!numbersProvider.saveToNumRow);
                },
                selected: numbersProvider.saveToNumRow,
                title: Text(translate("Add results to row"),
                    style: TextStyle(color: drawerTextColorSelected)),
                value: numbersProvider.saveToNumRow,
                activeColor: Color.fromARGB(255, 146, 202, 255)),
          ),
          ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: <Widget>[
              const Divider(
                thickness: 0.5,
              ),
              ListTile(
                leading: Icon(Icons.text_fields, color: drawerTextColor),
                title: Text(translate('Text Scanner'),
                    style: TextStyle(color: drawerTextColor)),
                onTap: () => {Navigator.of(context).pushNamed("/textScanner")},
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                  leading: Icon(
                    Icons.privacy_tip,
                    color: drawerTextColor,
                  ),
                  title: Text(translate('Privacy Notice'),
                      style: TextStyle(color: drawerTextColor)),
                  onTap: () => {openPrivacyNotice()}),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                  padding: const EdgeInsets.all(20),
                  onPressed: () => {
                        setState((() =>
                            themeProvider.darkTheme = !themeProvider.darkTheme))
                      },
                  icon: Icon(
                    themeProvider.darkTheme
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// IMPORTANT LISTS

final List<String> wrappingOperators = [
  "√",
  "log",
  "!",
  "cos",
  "sin",
  "tan",
  "abs"
];
final List<String> normalOperators = [
  " + ",
  " * ",
  " / ",
  ' × ',
  ' ÷ ',
  ' x ',
  ' ^ ',
  ' - ',
];
final List<String> specialSymbols = [
  "π",
  "℮",
];

List NUMBERS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

List<String> calcErrorResults = ["Error", 'Infinity', 'NaN', '-Infinity'];

String translate(String text) {
  final String locationInfo = Platform.localeName.toString();

  Map<String, List> translations = {
    'No numbers found.': [
      "Nenhum número encontrado.",
      "No se puede encontrar números."
    ],
    "Cancelled": ["Operação cancelada", "operación cancelada"],
    "Add results to row": [
      "Adicionar resultados à lista",
      "Añadir los resultados a la lista",
    ],
    "Text Scanner": [
      "Escaneador de texto",
      "Escáner de texto",
    ],
    "Privacy Notice": [
      "Política de Privacidade",
      'Términos y privacidad',
    ],
    "Take photo and scan": ["Tirar foto e escanear", 'Escanear nueva foto'],
    "Scan from image": [
      "Escanear uma imagem",
      "Escanear imagen",
    ],
    "Get numbers from camera": [
      "Capturar números com câmera",
      'Captura números con cámara'
    ],
    "Get numbers from image": [
      "Capturar números de uma imagem",
      "Capturar números de una imagen"
    ],
    "the image contains no text.": [
      "imagem não contem texto",
      "la imagen no contiene texto"
    ],
    'Clear the entire history?': [
      "Apagar todo histórico?",
      "¿Eliminar todo el histórico?"
    ],
    "Delete the selected entries?": [
      "Apagar selecionados?",
      "¿Eliminar seleccionado?"
    ],
    "Yes": [
      "Sim",
      "Si",
    ],
    "No": [
      "Cancelar",
      "Cancelar",
    ],
    "History": [
      "Histórico",
      "Histórico",
    ],
    'No entries': [
      "Sem histórico",
      "Sin historia",
    ],
    "Copied text to the clipboard.": ["Texto copiado", "Copiado al clipboard"],
    "entry retrieved": ["expressão recuperada", "expression recuperada"]
  };

  if (locationInfo.contains("pt_")) {
    return translations[text]![0];
  } else if (locationInfo.contains("es_")) {
    return translations[text]![1];
  }

  return text;
}
