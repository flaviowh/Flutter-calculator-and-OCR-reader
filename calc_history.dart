import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:numeros/imports.dart';
import 'package:numeros/model/historyentry.dart';
import 'package:numeros/providers/darktheme_provider.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';

class CalcHistory extends StatefulWidget {
  const CalcHistory({Key? key, required this.equationTextController})
      : super(key: key);
  final TextEditingController equationTextController;

  @override
  State<CalcHistory> createState() => _CalcHistoryState();
}

class _CalcHistoryState extends State<CalcHistory> {
  List selectedIndexes = [];

  List<HistoryEntry> entries = Hive.box<HistoryEntry>('history')
      .values
      .toList()
      .reversed
      .toList()
      .cast<HistoryEntry>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final numbersProvider = Provider.of<NumbersProvider>(context);

    Color appbarColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 0, 0, 0)
        : Colors.white;
    Color appbarText = themeProvider.darkTheme
        ? const Color.fromARGB(255, 248, 239, 189)
        : const Color.fromARGB(255, 3, 1, 20);

    Color appBarIconColor = appbarText;
    Color bubbleColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 37, 37, 33)
        : const Color.fromARGB(255, 216, 228, 235);
    Color resultColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 72, 134, 160)
        : const Color.fromARGB(255, 58, 91, 183);
    Color equationColor = themeProvider.darkTheme
        ? Color.fromARGB(255, 224, 191, 128)
        : const Color.fromARGB(255, 3, 1, 20);

    void clearAllEntries() {
      Hive.box<HistoryEntry>('history').clear();
      Navigator.of(context).pop();
      setState(() {
        entries.clear();
        selectedIndexes.clear();
      });
    }

    void deleteSelectedSlide(int index) {
      try {
        setState(() {
          entries.removeAt(index);
          selectedIndexes.clear();
        });
        int idx = entries.length - index;
        int correctedIdx = idx == -1 ? entries.length : idx;

        Hive.box<HistoryEntry>('history').deleteAt(correctedIdx);
      } catch (e) {}
    }

    void deleteSelectedIndexes() {
      List indexes = [...selectedIndexes]..sort((a, b) => a.compareTo(b));
      int count = 0;
      for (int index in indexes) {
        deleteSelectedSlide(index + count);
        count = count - 1;
      }
      Navigator.of(context).pop();
    }

    void smartlyDelete() {
      if (entries.length == 1 ||
          selectedIndexes.isEmpty ||
          selectedIndexes.length == entries.length) {
        clearAllEntries();
      } else {
        deleteSelectedIndexes();
      }
    }

    void selectAll() {
      setState(() {
        selectedIndexes = selectedIndexes.length == entries.length
            ? []
            : range(entries.length);
      });
    }

    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!

        builder: (BuildContext context) {
          return AlertDialog(
            title: selectedIndexes.isEmpty ||
                    selectedIndexes.length == entries.length
                ? Text(translate('Clear the entire history?'))
                : Text(translate("Delete the selected entries?")),
            content: const SingleChildScrollView(),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            actions: <Widget>[
              TextButton(
                  onPressed: smartlyDelete,
                  child: Text(
                    translate("Yes"),
                    style: TextStyle(color: appbarText),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    translate("No"),
                    style: TextStyle(color: appbarText),
                  )),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: appbarColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: appBarIconColor),
        title: Text(
          translate("History"),
          style: TextStyle(color: appbarText),
        ),
        backgroundColor: appbarColor,
        actions: [
          IconButton(
              onPressed: () {
                selectAll();
              },
              icon: const Icon(Icons.checklist)),
          IconButton(
              onPressed: () {
                entries.isNotEmpty ? showMyDialog() : null;
              },
              icon: const Icon(Icons.delete_forever))
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                translate('No entries'),
                style: Theme.of(context)
                    .textTheme
                    .caption
                    ?.copyWith(fontSize: 25.0),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20.0),
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                return Dismissible(
                  direction: DismissDirection.horizontal,
                  key: UniqueKey(),
                  background: Container(
                    color: themeProvider.darkTheme
                        ? Colors.orange
                        : const Color.fromARGB(255, 228, 154, 154),
                    child: const Padding(
                      padding: EdgeInsets.all(1),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  secondaryBackground: Container(
                    color: themeProvider.darkTheme
                        ? Colors.green
                        : Colors.greenAccent,
                    child: const Padding(
                      padding: EdgeInsets.all(1),
                      child: Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  child: Wrap(
                    children: [
                      CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: themeProvider.darkTheme
                              ? Colors.red
                              : Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          tileColor: bubbleColor,
                          title: Text(
                            entries[index].title,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                                fontSize: 24,
                                color: resultColor,
                                fontWeight: FontWeight.w400),
                          ),
                          subtitle: Text(entries[index].subtitle,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                  fontSize: 20,
                                  color: equationColor,
                                  fontWeight: FontWeight.w300)),
                          value: selectedIndexes.contains(index),
                          onChanged: (_) {
                            setState(() {
                              if (selectedIndexes.contains(index)) {
                                selectedIndexes.remove(index); // unselect
                              } else {
                                selectedIndexes.add(index); // select
                              }
                            });
                          }),
                    ],
                  ),
                  onDismissed: (DismissDirection direction) {
                    if (direction == DismissDirection.startToEnd) {
                      deleteSelectedSlide(index);
                    } else {
                      retrieveEntry(numbersProvider, index);
                    }
                  },
                );
              },
            ),
    );
  }

  void retrieveEntry(NumbersProvider numbersProvider, int index) {
    try {
      if (numbersProvider.saveToNumRow) {
        numbersProvider.setOCRNumbers([
          double.parse(entries[index].title),
          ...numbersProvider.ocrNumbers
        ]);
      }
      String entryEquation = entries[index].subtitle;
      String initialEq = widget.equationTextController.text;
      String composedEq;
      if (initialEq.isEmpty) {
        composedEq = entryEquation;
      } else if (normalOperators.any((sign) => initialEq.endsWith(sign))) {
        composedEq =
            "${widget.equationTextController.text} ($entryEquation)   ";
      } else {
        composedEq =
            "${widget.equationTextController.text} + ($entryEquation)   ";
      }
      widget.equationTextController.text = commaSeparate(composedEq);
      String result = parseExp(composedEq.replaceAll(",", ""));
      numbersProvider.setResult(commaSeparate(result), true);
      showMessage(context, translate("entry retrieved"));
    } catch (e) {}
  }
}
