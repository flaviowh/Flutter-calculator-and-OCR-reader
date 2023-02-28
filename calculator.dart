import 'dart:io';

import 'package:flutter/material.dart';
import 'package:numeros/calc_buttons.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';
import 'package:numeros/calc_logic.dart';
import 'package:numeros/providers/darktheme_provider.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key, required this.equationTextController})
      : super(key: key);
  final TextEditingController equationTextController;
  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final numbersProvider = Provider.of<NumbersProvider>(context);
    final mediaQuery = MediaQuery.of(context).size;
    bool hasOcrNumbers = numbersProvider.ocrNumbers.isNotEmpty;
    bool showingEndResult = numbersProvider.displayingResult;
    final aspectRatio = mediaQuery.height / mediaQuery.width;

    Color mainVisorColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 255, 255, 255);

    Color equationTextColor() {
      if (!showingEndResult) {
        return themeProvider.darkTheme
            ? const Color.fromRGBO(248, 242, 182, 1)
            : Colors.black;
      } else {
        return themeProvider.darkTheme
            ? Colors.orangeAccent //Color.fromARGB(255, 131, 179, 22)
            : Color.fromARGB(255, 20, 161, 216);
      }
    }

    Color resultTextColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 145, 116, 109)
        : const Color.fromARGB(255, 139, 143, 153);

    bool isValidResult(String result) {
      //RegExp(r'(((^|-)[\d\.]+($|e(\+|-))\d{0,3}))').hasMatch(result)
      if (result != widget.equationTextController.text.replaceAll(",", "") &&
          !calcErrorResults.contains(result)) {
        return true;
      } else {
        return false;
      }
    }

    Column calcVisor() {
      return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
                height: mediaQuery.height * 0.20,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                child: ListView(
                    reverse: true,
                    scrollDirection: Axis.vertical,
                    children: [
                      Theme(
                        data: ThemeData(
                            textSelectionTheme: TextSelectionThemeData(
                                selectionColor: themeProvider.darkTheme
                                    ? const Color.fromARGB(255, 168, 236, 89)
                                    : const Color.fromARGB(
                                        255, 130, 197, 252))),
                        child: TextField(
                          maxLines: null,
                          controller: widget.equationTextController,
                          showCursor: true,
                          cursorWidth: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          readOnly: true,
                          style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: !showingEndResult
                                  ? decreasingText(
                                      commaSeparate(
                                          widget.equationTextController.text),
                                      43,
                                      10,
                                      24)
                                  : decreasingText(
                                      commaSeparate(
                                          widget.equationTextController.text),
                                      48,
                                      10,
                                      24),
                              color: equationTextColor()),
                          textAlign: TextAlign.right,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ])),
            Container(
              height: mediaQuery.height * 0.10,
              padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
              child: Text(
                  isValidResult(numbersProvider.result) && !showingEndResult
                      ? commaSeparate(numbersProvider.result)
                      : '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: decreasingText(
                          commaSeparate(numbersProvider.result), 32, 10, 22),
                      color: resultTextColor,
                      fontWeight: FontWeight.w400)),
            ),
          ]);
    }

    List<int> getCursorIndexes(String initialEq) {
      var textSelection = widget.equationTextController.selection;
      var start =
          textSelection.start != -1 ? textSelection.start : initialEq.length;
      var end = textSelection.end != -1 ? textSelection.end : initialEq.length;
      return [start, end];
    }

    String editEquation(
        String initialEq, String operationSign, bool canStart, List indexes) {
      var equation = EditEvaluate(context).addToEquation(
          initialEq.replaceAll(',', ''),
          numbersProvider.result,
          operationSign,
          canStart,
          [indexes[0], indexes[1]]);
      return equation;
    }

    void updateIndexes(
        String initialEq, String formattedEditedEq, initialIndexes) {
      try {
        var offset = formattedEditedEq.length - initialEq.length;
        widget.equationTextController.selection =
            widget.equationTextController.selection.copyWith(
                baseOffset: initialIndexes[0] + offset,
                extentOffset: initialIndexes[1] + offset);
      } catch (e) {}
    }

    void setUpdatedEquation(
        String initialEq, List<int> initialIndexes, String updatedEquation) {
      var formattedEditedEq = commaSeparate(formatEq(updatedEquation));
      widget.equationTextController.text = formattedEditedEq;
      updateIndexes(initialEq, formattedEditedEq, initialIndexes);
    }

    void updateResult(String editedEq) {
      String newResult = evaluateEquation(editedEq, true);
      numbersProvider.setResult(newResult);
    }

    void buttonPressed(String operationSign, bool canStart) {
      String initialEq = widget.equationTextController.text;
      List<int> initialIndexes = getCursorIndexes(initialEq);
      String updatedEquation =
          editEquation(initialEq, operationSign, canStart, initialIndexes);

      setUpdatedEquation(initialEq, initialIndexes, updatedEquation);
      updateResult(updatedEquation);
    }

    insertIntoEquation(double number, [String subExpresion = '']) {
      String initialEq = widget.equationTextController.text.replaceAll(',', '');
      List<int> cursorIndexes = getCursorIndexes(initialEq);
      List<int> indexes =
          correctIndexes([cursorIndexes[0], cursorIndexes[1]], initialEq);

      String part1 = '';
      String part2 = '';
      String part3 = '';
      String numString = removeTrailingZero(number);

      if (indexes[0] == indexes[1]) {
        part1 = initialEq.substring(0, indexes[0]);
        part3 = initialEq.substring(indexes[0], initialEq.length);
        if (initialEq.endsWith(' ') || initialEq.isEmpty) {
          part2 = subExpresion.isNotEmpty ? subExpresion : numString;
        } else {
          part2 =
              subExpresion.isNotEmpty ? ' + $subExpresion' : ' + $numString';
        }
      } else {
        part1 = indexes[0] > 0 ? initialEq.substring(0, indexes[0]) : initialEq;
        if (part1.endsWith(' ')) {
          part2 = subExpresion.isNotEmpty ? subExpresion : numString;
        } else {
          part2 =
              subExpresion.isNotEmpty ? ' + $subExpresion' : ' + $numString';
        }

        part3 = initialEq.substring(indexes[1], initialEq.length);
      }

      String editedEq = part1 + part2 + part3;

      setUpdatedEquation(initialEq, indexes, editedEq);
      updateResult(editedEq);

      numbersProvider.setDisplayingResult(false);
    }

    return Scaffold(
        backgroundColor: themeProvider.darkTheme
            ? const Color.fromARGB(255, 0, 0, 0)
            : Colors.white,
        appBar: calculatorAppBar(context),
        drawer: const CalcDrawer(),
        body: Column(children: [
          Center(
              child: Container(
            decoration: BoxDecoration(
              color: mainVisorColor,
            ),
            height: (mediaQuery.height) * 0.31,
            width: mediaQuery.width,
            child: calcVisor(),
          )),
          hasOcrNumbers
              ? CapturedNumbers(
                  equationInserter: insertIntoEquation,
                )
              : SizedBox(
                  height: mediaQuery.height * 0.06,
                ),
          Container(
              // before : 10 2 10 0 ,  (6 , 0)   ?4:5
              padding: aspectRatio > 1.77
                  ? const EdgeInsets.fromLTRB(10, 2, 10, 0)
                  : const EdgeInsets.fromLTRB(30, 2, 30, 0),
              child: GridView.count(
                crossAxisSpacing: aspectRatio < 1.77 ? 40 : 6,
                mainAxisSpacing: aspectRatio < 1.77 ? 3 : 0,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 4,
                children: calcButtons(context, buttonPressed),
              ))
        ]));
  }
}

class CapturedNumbers extends StatefulWidget {
  const CapturedNumbers({Key? key, required this.equationInserter})
      : super(key: key);
  final Function equationInserter;
  @override
  State<CapturedNumbers> createState() => _CapturedNumbersState();
}

class _CapturedNumbersState extends State<CapturedNumbers> {
  bool openDrawer = false;
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final numbersProvider = Provider.of<NumbersProvider>(context);
    Size mediaQuery = MediaQuery.of(context).size;
    List<double> ocrNumbers = numbersProvider.ocrNumbers;

    deleteNumber(double number) {
      List<double> newNumbersList = [...numbersProvider.ocrNumbers];
      newNumbersList.remove(number);
      numbersProvider.setOCRNumbers(newNumbersList);
    }

    String reduceOperation(List<double> numbers, String sign) {
      var summation = "(${numbers[0]}";
      for (var i = 1; i < numbers.length - 1; i++) {
        summation = '$summation $sign ${numbers[i]}';
      }
      summation = '$summation $sign ${numbers.last})';
      return summation;
    }

//                     σ
    List<String> specialButtons = [
      "🗑️",
      'Σ',
      'μ',
      '∏',
      's',
      //   's²',
    ]; //'Σ?'
    List<Function> specialFunctions = [
      () {
        numbersProvider.clearNumbers();
        setState(() {
          openDrawer = false;
        });
      },
      () {
        if (ocrNumbers.length > 1) {
          var subExpression = reduceOperation(ocrNumbers, "+");
          widget.equationInserter(0.0, subExpression);
        }
      },
      () {
        widget.equationInserter(mean(ocrNumbers));
      },
      () {
        if (ocrNumbers.length > 1) {
          var subExpression = reduceOperation(ocrNumbers, ' × ');
          widget.equationInserter(0.0, subExpression);
        }
      },
      () {
        if (ocrNumbers.length > 1) {
          widget.equationInserter(stdev(ocrNumbers));
        } else {
          widget.equationInserter(0.0);
        }
      },
      () {
        widget.equationInserter(variance(ocrNumbers));
      },
      () {}
    ];

    Color borderColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 252, 223, 145)
        : Colors.black;

    Color ocrNumbersColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 72, 134, 160)
        : const Color.fromARGB(255, 58, 91, 183);

    return Container(
        height: mediaQuery.height * 0.06,
        width: mediaQuery.width,
        decoration: BoxDecoration(
            color: themeProvider.darkTheme
                ? const Color.fromARGB(255, 0, 0, 0)
                : const Color.fromARGB(255, 255, 255, 255),
            border: Border(
              //top: BorderSide(width: 0.5, color: borderColor),
              bottom: BorderSide(width: 0.5, color: borderColor),
            )),
        child: Container(
          color: themeProvider.darkTheme
              ? const Color.fromARGB(255, 26, 25, 25)
              : const Color.fromARGB(255, 216, 228, 235),
          child: Row(
            children: [
              IconButton(
                  padding: openDrawer
                      ? const EdgeInsets.all(0)
                      : const EdgeInsets.fromLTRB(10, 0, 20, 0),
                  onPressed: () {
                    setState(() {
                      openDrawer = !openDrawer;
                    });
                  },
                  icon: openDrawer
                      ? const Icon(Icons.remove)
                      : const Icon(Icons.more_horiz_outlined)),
              openDrawer
                  ? AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      alignment: Alignment.center,
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(0),
                        scrollDirection: Axis.horizontal,
                        children: List.generate(
                            specialButtons.length,
                            (index) => TextButton(
                                onPressed: () {
                                  specialFunctions[index]();
                                },
                                child: Text(
                                  specialButtons[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 22,
                                      color: themeProvider.darkTheme
                                          ? Colors.deepOrangeAccent
                                          : const Color.fromARGB(
                                              255, 34, 13, 37)),
                                ))),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: ocrNumbers.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      right: BorderSide(
                                          width: 0.2,
                                          color: themeProvider.darkTheme
                                              ? Color.fromARGB(
                                                  255, 64, 163, 255)
                                              : Colors.blueAccent))),
                              child: Dismissible(
                                direction: DismissDirection.vertical,
                                key: UniqueKey(),
                                background: Container(
                                  color: themeProvider.darkTheme
                                      ? Colors.redAccent
                                      : const Color.fromARGB(
                                          255, 228, 154, 154),
                                  child: const Padding(
                                    padding: EdgeInsets.all(1),
                                    child:
                                        Icon(Icons.delete, color: Colors.white),
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: themeProvider.darkTheme
                                      ? Colors.green
                                      : Colors.greenAccent,
                                  child: const Padding(
                                      padding: EdgeInsets.all(1),
                                      child: Icon(Icons.add_sharp)),
                                ),
                                onDismissed: (DismissDirection direction) {
                                  if (direction == DismissDirection.up) {
                                    widget.equationInserter(ocrNumbers[index]);
                                  } else {
                                    deleteNumber(ocrNumbers[index]);
                                  }

                                  setState(() {
                                    ocrNumbers.removeAt(index);
                                  });
                                },
                                child: Container(
                                  width: 70,
                                  child: Center(
                                    child: Text(
                                      removeTrailingZero(ocrNumbers[index]),
                                      style: TextStyle(
                                          fontSize: 18, color: ocrNumbersColor),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
            ],
          ),
        ));
  }
}
