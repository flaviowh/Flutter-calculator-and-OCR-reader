import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:numeros/button_groups.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/providers/darktheme_provider.dart';
import 'package:numeros/providers/numbers_provider.dart';

class CalculatorBtn extends StatefulWidget {
  final List<String> commandLabels;
  final bool highlighted, isSpecialButton, canStart;

  const CalculatorBtn(
    this.commandLabels, {
    this.highlighted = false,
    this.isSpecialButton = false,
    this.canStart = true,
    Key? key,
    required this.buttonPressFunction,
  }) : super(key: key);
  final Function buttonPressFunction;

  @override
  State<CalculatorBtn> createState() => _CalculatorBtnState();
}

class _CalculatorBtnState extends State<CalculatorBtn> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final hasDoubleFunction = widget.commandLabels.length == 2 ? true : false;
    final TextStyle? textStyle = Theme.of(context).textTheme.headline6;
    final aspectRatio =
        MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;
    final double buttonsMargin = aspectRatio > 1.77 ? 4 : 0;

    Color buttonSpecialTextColor = Colors.white;
    Color operationButtonColor = themeProvider.darkTheme
        ? Color.fromARGB(255, 218, 146, 13)
        : Color.fromARGB(255, 94, 161, 214);
    Color numberButtonsColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 26, 25, 25)
        : const Color.fromARGB(255, 216, 228, 235);
    Color doubleBtnPrimaryText = themeProvider.darkTheme
        ? Color.fromARGB(255, 240, 224, 154)
        : const Color.fromARGB(255, 3, 1, 20);
    Color doubleBtnSecondaryText = themeProvider.darkTheme
        ? Colors.orangeAccent
        : Color.fromARGB(255, 123, 2, 160);

    Color specialButtonColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 26, 25, 25)
        : const Color.fromARGB(255, 216, 228, 235);

    Color equalSignColor = themeProvider.darkTheme
        ? Color.fromARGB(255, 56, 66, 33)
        : Color.fromARGB(255, 20, 161, 216);

    Color clearButtonTextColor =
        themeProvider.darkTheme ? Colors.redAccent : Colors.red;

    Color getSpecialButtonColor(String sign) {
      if (sign == "=") {
        return equalSignColor;
      } else if (sign == "C") {
        return specialButtonColor;
      } else {
        return operationButtonColor;
      }
    }

    double specialFontSize(String sign) {
      if (["C"].contains(sign)) {
        return aspectRatio > 1.77 ? 33 : 23;
      } else {
        return aspectRatio > 1.77 ? 42 : 32;
      }
    }

    return Material(
      color: themeProvider.darkTheme ? Colors.black : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () {
          widget.buttonPressFunction(widget.commandLabels[0], widget.canStart);
        },
        onLongPress: hasDoubleFunction
            ? () {
                var sign = widget.commandLabels[1];
                widget.buttonPressFunction(
                  commandSignDetails[sign][0],
                  commandSignDetails[sign][1],
                );
              }
            : () {},
        child: widget.isSpecialButton
            ? Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(buttonsMargin),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: getSpecialButtonColor(widget.commandLabels[0])),
                child: Center(
                    child: Text(
                  widget.commandLabels[0],
                  style: textStyle?.copyWith(
                    color: widget.commandLabels[0] == "C"
                        ? clearButtonTextColor
                        : buttonSpecialTextColor,
                    fontSize: specialFontSize(widget.commandLabels[0]),
                    fontWeight: FontWeight.w400,
                  ),
                )),
              )
            : hasDoubleFunction
                ? Container(
                    margin: EdgeInsets.all(buttonsMargin),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: numberButtonsColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.commandLabels[0],
                          style: TextStyle(
                            color: doubleBtnPrimaryText,
                            fontSize: aspectRatio > 1.77 ? 34 : 24,
                          ),
                        ),
                        Text(
                          widget.commandLabels[1],
                          style: TextStyle(
                            color: doubleBtnSecondaryText,
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                  )
                : Container(
                    margin: EdgeInsets.all(buttonsMargin),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: numberButtonsColor),
                    child: Center(
                      child: Text(
                        widget.commandLabels[0],
                        style: TextStyle(
                            color: widget.highlighted
                                ? buttonSpecialTextColor
                                : doubleBtnPrimaryText,
                            fontSize: widget.highlighted ? 30 : 26),
                      ),
                    ),
                  ),
      ),
    );
  }
}

Map commandSignDetails = {
  /// symbol on button [ symbol on visor, can be used at the start?]
  "X^Y": [" ^ ", false],
  "2√": ["√", true],
  "log": ["log", true],
  "n!": ["!", true],
  "cos": ["cos", true],
  "sin": ["sin", true],
  "tan": ["tan", true],
  "π": ["π", true],
  "℮": ["℮", true],
  "| x |": ['abs', false],
};

class BackSpaceBtn extends StatefulWidget {
  const BackSpaceBtn({Key? key, required this.buttonPressFunction})
      : super(key: key);
  final Function buttonPressFunction;

  @override
  State<BackSpaceBtn> createState() => _BackSpaceBtnState();
}

class _BackSpaceBtnState extends State<BackSpaceBtn> {
  bool _buttonPressed = false;
  bool _loopActive = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final aspectRatio =
        MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;
    final double paddingValue = aspectRatio > 1.77 ? 4 : 0;

    Color backbuttonColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 26, 25, 25)
        : const Color.fromARGB(255, 216, 228, 235);

    void callFunction() async {
      // make sure that only one loop is active
      if (_loopActive) return;
      _loopActive = true;
      while (_buttonPressed) {
        // do your thing
        widget.buttonPressFunction("⌫", false);
        // wait a bit
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _loopActive = false;
    }

    return Listener(
        onPointerDown: (details) {
          _buttonPressed = true;
          callFunction();
        },
        onPointerUp: (details) {
          _buttonPressed = false;
        },
        child: InkWell(
            borderRadius: BorderRadius.circular(20.0),
            onTap: () {},
            child: Center(
                child: Container(
              margin: EdgeInsets.all(paddingValue),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: backbuttonColor),
              child: const Center(
                child: Text(
                  "⌫",
                  style: TextStyle(color: Colors.red, fontSize: 30),
                ),
              ),
            ))));
  }
}

parenthesisButton(Function buttonPress, BuildContext context) {
  String sign = ' ( ) ';
  final themeProvider = Provider.of<DarkThemeProvider>(context);
  final aspectRatio =
      MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;
  final double paddingValue = aspectRatio > 1.77 ? 4 : 0;
  themeProvider.darkTheme ? Colors.amber : Color.fromARGB(255, 30, 4, 63);
  Color parButtonColor = themeProvider.darkTheme
      ? const Color.fromARGB(255, 26, 25, 25)
      : const Color.fromARGB(255, 216, 228, 235);

  return InkWell(
    borderRadius: BorderRadius.circular(20.0),
    onTap: () {
      buttonPress(sign, true);
    },
    onLongPress: () {
      buttonPress('wrap', false);
    },
    child: Center(
        child: Container(
      margin: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), color: parButtonColor),
      child: Center(
        child: Text(
          sign,
          style: TextStyle(
              color: themeProvider.darkTheme
                  ? const Color.fromARGB(255, 240, 224, 154)
                  : const Color.fromARGB(255, 3, 1, 20),
              fontSize: 28),
        ),
      ),
    )),
  );
  // );
}

class CameraButton extends StatefulWidget {
  const CameraButton({Key? key}) : super(key: key);

  @override
  State<CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<CameraButton> {
  final isDialOpen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final numbersProvider = Provider.of<NumbersProvider>(context);
    Size mediaQuery = MediaQuery.of(context).size;
    final aspectRatio = mediaQuery.height / mediaQuery.width;
    final double paddingValue = aspectRatio > 1.77 ? 4 : 0;
    void getNumbers(bool fromGalery) async {
      var capturer = CaptureNumbers(context, themeProvider);
      List<double>? foundNumbers = await capturer.getNumbers(fromGalery);
      if (foundNumbers != null && foundNumbers.isNotEmpty) {
        numbersProvider
            .setOCRNumbers([...numbersProvider.ocrNumbers, ...foundNumbers]);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        if (isDialOpen.value) {
          isDialOpen.value = false;

          return false;
        }
        {
          return true;
        }
      },
      child: Container(
          padding: EdgeInsets.all(paddingValue),
          decoration: BoxDecoration(
            color: themeProvider.darkTheme ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          child: DialButtons(
            isDialOpen: isDialOpen,
            folderFunction: () {
              getNumbers(true);
            },
            takeNewPhoto: () {
              getNumbers(false);
            },
            textReseter: () {},
          )),
    );
  }
}

List<Widget> calcButtons(BuildContext context, Function buttonPressFunction) {
  final Map<String, Widget> buttons = {
    "clear": CalculatorBtn(
      const ['C'],
      highlighted: true,
      canStart: false,
      buttonPressFunction: buttonPressFunction,
      isSpecialButton: true,
    ),
    "backspace": BackSpaceBtn(
      buttonPressFunction: buttonPressFunction,
    ),
    "division": CalculatorBtn(
      const [' ÷ '],
      highlighted: true,
      canStart: false,
      buttonPressFunction: buttonPressFunction,
      isSpecialButton: true,
    ),
    "multiplication": CalculatorBtn(
      const [' × '],
      highlighted: true,
      canStart: false,
      buttonPressFunction: buttonPressFunction,
      isSpecialButton: true,
    ),
    "sum": CalculatorBtn(
      const [' + '],
      highlighted: true,
      canStart: false,
      buttonPressFunction: buttonPressFunction,
      isSpecialButton: true,
    ),
    "subtraction": CalculatorBtn(
      const [' - '],
      highlighted: true,
      canStart: true,
      buttonPressFunction: buttonPressFunction,
      isSpecialButton: true,
    ),
    "6": CalculatorBtn(
      const ['6', 'tan'],
      buttonPressFunction: buttonPressFunction,
    ),
    "7": CalculatorBtn(
      const ['7', "2√"],
      buttonPressFunction: buttonPressFunction,
    ),
    "8": CalculatorBtn(
      const ['8', 'X^Y'],
      buttonPressFunction: buttonPressFunction,
    ),
    "9": CalculatorBtn(
      const ['9', 'log'],
      buttonPressFunction: buttonPressFunction,
    ),
    "1": CalculatorBtn(
      const ['1', "n!"],
      buttonPressFunction: buttonPressFunction,
    ),
    "2": CalculatorBtn(
      const ['2', "π"],
      buttonPressFunction: buttonPressFunction,
    ),
    "3": CalculatorBtn(
      const ['3', '℮'],
      buttonPressFunction: buttonPressFunction,
    ),
    "4": CalculatorBtn(
      const ['4', "cos"],
      buttonPressFunction: buttonPressFunction,
    ),
    "5": CalculatorBtn(
      const ['5', "sin"],
      buttonPressFunction: buttonPressFunction,
    ),
    "0": CalculatorBtn(
      const ['0', "| x |"],
      buttonPressFunction: buttonPressFunction,
    ),
    "search": const CameraButton(),
    "dot": CalculatorBtn(
      const ['.'],
      buttonPressFunction: buttonPressFunction,
    ),
    "equal": CalculatorBtn(
      const ['='],
      isSpecialButton: true,
      canStart: false,
      buttonPressFunction: buttonPressFunction,
    ),
    "brackets": parenthesisButton(buttonPressFunction, context),
  };

  return [
    buttons["clear"]!,
    buttons["backspace"]!,
    buttons["brackets"]!,
    buttons["division"]!,
    buttons["7"]!,
    buttons["8"]!,
    buttons["9"]!,
    buttons["multiplication"]!,
    buttons["4"]!,
    buttons["5"]!,
    buttons["6"]!,
    buttons["subtraction"]!,
    buttons["1"]!,
    buttons["2"]!,
    buttons["3"]!,
    buttons["sum"]!,
    buttons["search"]!,
    buttons["0"]!,
    buttons["dot"]!,
    buttons["equal"]!,
  ];
}
