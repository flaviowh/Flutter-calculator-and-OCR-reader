import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/providers/darktheme_provider.dart';
import 'package:provider/provider.dart';

class OCRtextWidget extends StatefulWidget {
  const OCRtextWidget({
    Key? key,
    required this.textString,
    required this.openCalculatorFunction,
    required this.cancelFunction,
  }) : super(key: key);
  final String textString;
  final Function openCalculatorFunction;
  final Function cancelFunction;

  @override
  State<OCRtextWidget> createState() => _OCRtextWidgetState();
}

class _OCRtextWidgetState extends State<OCRtextWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<DarkThemeProvider>(context, listen: false);
    String editableText = widget.textString;
    TextEditingController ocrController =
        TextEditingController(text: editableText);
    final mediaQuery = MediaQuery.of(context).size;

    return Column(children: [
      Center(
          child: Container(
        decoration: BoxDecoration(
            color: themeProvider.darkTheme
                ? const Color.fromARGB(255, 233, 228, 207)
                : const Color.fromARGB(255, 225, 232, 235),
            // border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
        height: 300,
        width: mediaQuery.width * 0.92,
        child: ListView(children: [
          TextField(
            maxLines: null,
            controller: ocrController,
            showCursor: true,
            cursorWidth: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            readOnly: false,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: decreasingText(ocrController.text, 45, 10, 20),
                color: Colors.black),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.top,
          ),
        ]),
      )),
      Wrap(spacing: 10, children: [
        IconButton(
            onPressed: () {
              widget.cancelFunction();
            },
            icon: const Icon(Icons.replay_outlined, size: 32)),
        IconButton(
            onPressed: () {
              widget.openCalculatorFunction(ocrController.text);
            },
            icon: const Icon(Icons.calculate_sharp, size: 32)),
        IconButton(
          onPressed: () {
            FlutterClipboard.copy(widget.textString);
            showMessage(context, translate("Copied text to the clipboard."));
          },
          icon: const Icon(Icons.copy_all_outlined, size: 32),
        ),
      ]),
    ]);
  }
}
