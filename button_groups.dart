import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:numeros/providers/darktheme_provider.dart';
import 'package:numeros/imports.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';

class DialButtons extends StatefulWidget {
  const DialButtons({
    Key? key,
    required this.isDialOpen,
    required this.folderFunction,
    required this.takeNewPhoto,
    required this.textReseter,
  }) : super(key: key);

  final ValueNotifier<bool> isDialOpen;
  final Function takeNewPhoto;
  final Function folderFunction;
  final Function textReseter;

  @override
  State<DialButtons> createState() => _DialButtonsState();
}

class _DialButtonsState extends State<DialButtons> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);

    return SpeedDial(
      // buttonSize: Size(50, 50),
      icon: Icons.search,
      switchLabelPosition: true,

      overlayColor: themeProvider.darkTheme
          ? const Color.fromARGB(255, 44, 50, 61)
          : const Color.fromARGB(255, 85, 111, 119),

      foregroundColor: themeProvider.darkTheme
          ? Color.fromARGB(255, 240, 227, 157)
          : Colors.black,
      backgroundColor: !themeProvider.darkTheme ? Colors.white : Colors.black,
      spacing: 20.0,
      spaceBetweenChildren: 10,
      childrenButtonSize: const Size(70, 70),
      openCloseDial: widget.isDialOpen,
      //icon: Icons.image,
      children: [
        SpeedDialChild(
            label: translate("Get numbers from image"),
            labelStyle: const TextStyle(fontSize: 14),
            child: const Icon(
              Icons.image,
              size: 33,
            ),
            onTap: (() => widget.folderFunction())),
        SpeedDialChild(
          label: translate("Get numbers from camera"),
          labelStyle: const TextStyle(fontSize: 14),
          child: const Icon(
            Icons.camera_alt,
            size: 33,
          ),
          onTap: (() => widget.takeNewPhoto()),
        ),
      ],
    );
  }
}

class EditButtons extends StatefulWidget {
  const EditButtons({
    Key? key,
    required this.confirmImageFunction,
    required this.cancelFunction,
  }) : super(key: key);

  final Function confirmImageFunction;
  final Function cancelFunction;

  @override
  State<EditButtons> createState() => _EditButtonsState();
}

class _EditButtonsState extends State<EditButtons> {
  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<DarkThemeProvider>(context, listen: false);
    return Wrap(
      children: [
        IconButton(
            iconSize: 40,
            onPressed: () {
              widget.cancelFunction();
            },
            color: Colors.black,
            icon: Icon(
              Icons.replay_outlined,
              color: themeProvider.darkTheme ? Colors.white : Colors.black,
            )),
        IconButton(
            iconSize: 40,
            onPressed: () {
              widget.confirmImageFunction();
            },
            color: Colors.green,
            icon: const Icon(Icons.done))
      ],
    );
  }
}
