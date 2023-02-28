import 'dart:math';

import 'package:flutter/material.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/model/historyentry.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';

class EditEvaluate {
  bool openedParenthesis = false;
  List<String> activeRecurOp = [];
  BuildContext context;

  EditEvaluate(this.context);

  bool equationIsReady(equation) {
    var previousDigit =
        equation.substring(equation.length - 1, equation.length);
    return !["+", "log", ' ', "(", "×", '÷'].any((el) => previousDigit == el);
  }

  String backSpacePress(String equation, List<int> indexes) {
    num selectionLength;
    selectionLength = indexes[1] - indexes[0];
    if (selectionLength > 0) {
      final cutEquation =
          equation.replaceRange(max(indexes[0], 0), indexes[1], "");
      return cutEquation.replaceAll(',', '');
    } else {
      if (equation.endsWith("(")) {
        for (var sign in wrappingOperators) {
          if (equation.endsWith('$sign(')) {
            return equation.substring(0, indexes[0] - '$sign('.length) +
                equation.substring(indexes[0], equation.length);
          }
        }
      } else if (equation.endsWith(' ')) {
        var space = 1;
        for (var sign in normalOperators) {
          if (equation.endsWith(sign)) {
            space = sign.length;
          }
        }
        return equation.substring(0, indexes[0] - space) +
            equation.substring(indexes[0], equation.length);
      }

      return indexes[0] > 0
          ? equation.substring(0, indexes[0] - 1) +
              equation.substring(indexes[0], equation.length)
          : equation;
    }
  }

  String addParenthesis(String equation) {
    if (openedParenthesis) {
      if ([...NUMBERS, ...specialSymbols, ")"]
          .any((sign) => equation.endsWith(sign))) {
        equation = '$equation)';
      } else {
        return '$equation(';
      }
    } else if (!openedParenthesis &&
        [...normalOperators].any((sign) => equation.endsWith(sign))) {
      equation = '$equation(';
    }
    return equation;
  }

  String addWrappingFunction(
    String equation,
    String sign,
  ) {
    var modEquation = '';
    if (equation != '') {
      if (equation.endsWith(' ')) {
        modEquation = '$equation$sign(';
      } else {
        modEquation = "$sign($equation)";
      }
    } else {
      modEquation = '$sign(';
    }
    activeRecurOp.add('$sign(');
    return modEquation;
  }

  bool eqIsReady(String equation) {
    return [...normalOperators, ...wrappingOperators]
            .any((sign) => equation.contains(sign))
        ? true
        : false;
  }

  String processResult(String equation, String result) {
    if (result.isEmpty || calcErrorResults.contains(result)) return result;
    final numbersProvider =
        Provider.of<NumbersProvider>(context, listen: false);
    var res = result;
    if (eqIsReady(equation)) {
      final historyEntry = HistoryEntry()
        ..title = result
        ..subtitle = equation;
      Hive.box<HistoryEntry>('history').add(historyEntry);
      numbersProvider.setDisplayingResult(true);
    } else {
      res = numbersProvider.saveToNumRow ? '' : result;
    }

    if (numbersProvider.saveToNumRow && result != "0") {
      try {
        numbersProvider.setOCRNumbers(
            [double.parse(result), ...numbersProvider.ocrNumbers]);
      } catch (e) {}
    }
    return res;
  }

  bool isOpenedParenthesis(String equation) {
    return "(".allMatches(equation).length != ")".allMatches(equation).length;
  }

  String addToEquation(String previousEquation, String result, String sign,
      bool canStart, List<int> initialIndexes) {
    if (calcErrorResults.contains(previousEquation)) {
      return '';
    }
    final numbersProvider =
        Provider.of<NumbersProvider>(context, listen: false);
    numbersProvider.setDisplayingResult(false);
    String equation = previousEquation;
    String part1 = equation;
    String part2 = '';
    String part3 = '';
    List<int> cursorIndexes = correctIndexes(initialIndexes, equation);

    if (sign == '=') {
      if (!normalOperators.any((sign) => equation.endsWith(sign))) {
        return processResult(equation, result);
      } else {
        return part1;
      }
    } else if (cursorIndexes[1] == equation.length) {
      part1 = equation;
    } else if (cursorIndexes[0] != cursorIndexes[1]) {
      if (['C', "⌫"].contains(sign)) {
        part1 = equation.substring(0, cursorIndexes[1]);
        part2 = equation.substring(max(cursorIndexes[0], 0), cursorIndexes[1]);
        part3 = equation.substring(cursorIndexes[1], equation.length);
      } else {
        part1 = equation.substring(0, max(cursorIndexes[0], 0));
        part3 = equation.substring(cursorIndexes[1], equation.length);
      }
    } else {
      part1 = equation.substring(0, cursorIndexes[1]);
      part2 = equation.substring(cursorIndexes[1], equation.length);
    }

    if (equation.isEmpty) {
      if (sign == '.') {
        part1 = '0.';
      } else if (wrappingOperators.contains(sign)) {
        part1 = '$sign(';
      } else if (canStart && sign != ' ( ) ') {
        part1 = sign;
      } else if (sign == ' ( ) ') {
        part1 = '(';
      }
    } else {
      openedParenthesis = isOpenedParenthesis(equation);
      String previousDigit =
          part1 != '' ? part1.substring(part1.length - 1, part1.length) : '';

      if (previousDigit == '.' && sign == '.' ||
          NUMBERS.contains(sign) && previousDigit == ")" ||
          previousDigit == "(" &&
              ![...NUMBERS, ...specialSymbols, ' - ', 'C', "⌫"]
                  .contains(sign) ||
          part1 == ' - ' && sign.endsWith(' ') ||
          specialSymbols.contains(previousDigit) && NUMBERS.contains(sign) ||
          part1.endsWith(' 0') && sign == '0') {
        return part1 + part2 + part3;
      }
      if (sign == "C") {
        return '';
      } else if (sign == "⌫") {
        var reduced = backSpacePress(equation, cursorIndexes);
        return reduced;
      } else if (sign == 'wrap') {
        if (equation.startsWith("(") && equation.endsWith(")")) {
          return part1;
        }
        return "($part1)$part2$part3";
      } else if (specialSymbols.contains(sign)) {
        if (NUMBERS.any((element) => part1.endsWith(element))) {
          return '$part1 × $sign';
        }
        return "$part1$sign";
      } else if (wrappingOperators.contains(sign)) {
        part1 = addWrappingFunction(part1, sign);
      } else if (part1.endsWith(' ') && sign == '.') {
        part1 = '${equation}0.';
      } else if (previousDigit == ' ' && canStart == false ||
          previousDigit == ' ' && sign == (" - ")) {
        part1 = part1.substring(0, max(0, part1.length - 3)) + sign;
      } else if (sign == ' ( ) ') {
        part1 = addParenthesis(part1);
      } else {
        part1 = part1 + sign;
      }
    }
    if (part1 == '0') {
      part1 = '';
    }

    return part1 + part2 + part3;
  }
}
