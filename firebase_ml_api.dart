import 'dart:io';
import 'package:google_ml_vision/google_ml_vision.dart';

class GoogleMlAPI {
  static Future<String> scanImage(File imageFile) async {
    final GoogleVisionImage visionImage = GoogleVisionImage.fromFile(imageFile);
    final TextRecognizer textRecognizer =
        GoogleVision.instance.textRecognizer();

    VisionText visionText = await textRecognizer.processImage(visionImage);

    try {
      final visionText = await textRecognizer.processImage(visionImage);
      await textRecognizer.close();

      final text = extractText(visionText);
      return text.isEmpty ? '' : text;
    } catch (error) {
      return error.toString();
    }
  }
}

String extractText(VisionText visionText) {
  String text = '';

  for (TextBlock block in visionText.blocks) {
    for (TextLine line in block.lines) {
      for (TextElement word in line.elements) {
        text = '$text${word.text} ';
      }
      text = '$text\n';
    }
  }
  return text;
}
