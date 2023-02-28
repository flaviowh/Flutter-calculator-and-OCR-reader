import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:numeros/ocr_text_widget.dart';
import 'package:numeros/button_groups.dart';
import 'package:numeros/imports.dart';
import 'package:image_picker/image_picker.dart';
import 'package:numeros/providers/numbers_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'firebase_ml_api.dart';
import 'providers/darktheme_provider.dart';
import 'package:image_cropping/image_cropping.dart';
import 'package:path_provider/path_provider.dart';

class TextScanner extends StatefulWidget {
  const TextScanner({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> {
  final isDialOpen = ValueNotifier(false);

  late File currentImage;
  bool imageIsSelected = false;
  bool imageIsConfirmed = false;
  bool textWasReceived = false;
  String ocrText = '';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    final numbersProvider = Provider.of<NumbersProvider>(context);

    void resetImageAndText() {
      setState(() {
        imageIsConfirmed = false;
        textWasReceived = false;
      });
    }

    Future pickImage() async {
      setState(() {
        textWasReceived = false;
        imageIsConfirmed = false;
      });
      try {
        final image =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image == null) return;
        final imageTemp = File(image.path);
        setState(() => {
              currentImage = imageTemp,
              imageIsSelected = true,
              imageIsConfirmed = false
            });
      } catch (e) {
        showMessage(context, translate("Cancelled"));
      }
    }

    Future takeNewPhoto() async {
      setState(() {
        textWasReceived = false;
        imageIsConfirmed = false;
      });
      try {
        final image = await ImagePicker().pickImage(source: ImageSource.camera);
        if (image == null) return;
        final imageTemp = File(image.path);
        setState(() => {
              currentImage = imageTemp,
              imageIsSelected = true,
              imageIsConfirmed = false
            });
      } catch (e) {}
    }

    void cropImage() async {
      late Uint8List imageBytes;
      final tempDir = await getTemporaryDirectory();
      File newFile = await File('${tempDir.path}/edited_image.png').create();

      showLoader();
      imageBytes = await currentImage.readAsBytes();
      if (imageBytes.isNotEmpty) {
        ImageCropping.cropImage(
            context: context,
            imageBytes: imageBytes,
            onImageDoneListener: (data) {
              setState(
                () {
                  imageBytes = data;
                  newFile.writeAsBytesSync(imageBytes);
                  currentImage = newFile;
                },
              );
            },
            onImageStartLoading: showLoader,
            onImageEndLoading: hideLoader,
            visibleOtherAspectRatios: false,
            squareBorderWidth: 2,
            isConstrain: false,
            squareCircleColor: Colors.red,
            defaultTextColor: Colors.black,
            selectedTextColor: Colors.orange,
            colorForWhiteSpace:
                themeProvider.darkTheme ? Colors.black : Colors.white,
            makeDarkerOutside: true,
            outputImageFormat: OutputImageFormat.png,
            encodingQuality: 10);
      } else {
        hideLoader();
      }
      resetImageAndText();
    }

    Future<void> readImage() async {
      String text = await GoogleMlAPI.scanImage(currentImage);
      if (text.isNotEmpty) {
        setState(() {
          textWasReceived = true;
          ocrText = text;
        });
      } else {
        showMessage(context, translate("the image contains no text."),
            true); // true, true);
        setState(() => imageIsConfirmed = !imageIsConfirmed);
      }
    }

    void sendToCalculator(String editedText) async {
      List<double> newNumbers = await lookForNumbers(editedText);
      if (newNumbers.isNotEmpty) {
        numbersProvider.setOCRNumbers(newNumbers);
        Navigator.pop(context);
      } else {
        showMessage(context, translate('No numbers found.'), true);
      }
    }

    Widget imageContainer() {
      return GestureDetector(
        onTap: () => cropImage(),
        child: AnimatedContainer(
          alignment: Alignment.topCenter,
          margin: const EdgeInsets.fromLTRB(5, 30, 5, 30),
          duration: const Duration(milliseconds: 100),
          height: imageIsConfirmed ? 150 : 500,
          child: imageIsSelected
              ? Image.file(currentImage)
              : const Icon(
                  Icons.image,
                  size: 70.0,
                ),
        ),
      );
    }

    void cancelFunction() {
      setState(() => {imageIsSelected = false});
    }

    Color appbarColor = themeProvider.darkTheme ? Colors.black : Colors.white;
    Color appbarTextColor = themeProvider.darkTheme
        ? const Color.fromARGB(255, 240, 227, 157)
        : const Color.fromARGB(255, 3, 1, 20);

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
        child: Scaffold(
          backgroundColor: appbarColor,
          appBar: AppBar(
            foregroundColor: appbarTextColor,
            backgroundColor: appbarColor,
            title: Text(
              widget.title,
              textAlign: TextAlign.center,
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  !imageIsSelected
                      ? Center(
                          child: Column(children: [
                          GestureDetector(
                            onTap: takeNewPhoto,
                            child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          themeProvider.darkTheme
                                              ? Color.fromARGB(
                                                  255, 14, 106, 109)
                                              : Colors.blue,
                                          themeProvider.darkTheme
                                              ? Colors.grey
                                              : Colors.cyan
                                        ],
                                      )),
                                  width: 180,
                                  height: 180,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt,
                                          size: 45,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          translate("Take photo and scan"),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: pickImage,
                            child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      gradient: LinearGradient(
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                        colors: [
                                          themeProvider.darkTheme
                                              ? Colors.amber
                                              : Colors.blue,
                                          themeProvider.darkTheme
                                              ? Colors.grey
                                              : Colors.blueGrey
                                        ],
                                      )),
                                  width: 180,
                                  height: 180,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.image,
                                          size: 45,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          translate("Scan from image"),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                          ),
                        ]))
                      : Column(children: <Widget>[
                          imageContainer(),
                          imageIsConfirmed
                              ? const SizedBox(
                                  width: 2,
                                )
                              : EditButtons(
                                  confirmImageFunction: () {
                                    setState(() =>
                                        imageIsConfirmed = !imageIsConfirmed);
                                    readImage();
                                  },
                                  cancelFunction: () {
                                    cancelFunction();
                                  },
                                ),
                          textWasReceived
                              ? OCRtextWidget(
                                  textString: ocrText,
                                  openCalculatorFunction: sendToCalculator,
                                  cancelFunction: cancelFunction,
                                )
                              : const SizedBox()
                        ]),
                ],
              ),
            ],
          ),
        ));
  }
}
