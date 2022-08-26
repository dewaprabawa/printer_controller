import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart';

extension ImageExt on Image {
  static Future<Image?> fromAsset(String assetPath) async {
    ByteData firstData = await rootBundle.load(assetPath);
    return decodeImage(firstData.buffer.asUint8List());
  }

   static bool isEmpty(text) {
    if (text == "" || text == null || text == "null") {
      return true;
    } else {
      return false;
    }
  }


  static Image? generateTextImage(String text) {
    if (isEmpty(text)) return null;
    String partedString = text.replaceFirst(' ', '\n');

    List<String> splitText = partedString.split('\n');
    // 32 is estimated width for every character.
    int maxWidth = splitText
            .reduce((value, element) =>
                value.length > element.length ? value : element)
            .length *
        32;
    int height = splitText.length * 48;
    Image image = Image(maxWidth, height);
    for (int i = 0; i < splitText.length; i++) {
      drawString(image, arial_48, 0, 48 * i, splitText[i], color: 0xff000000);
    }
    return image;
  }

  static Future<File> writeToFile(Image image, String path) async {
    return await File(path)
      ..writeAsBytesSync(encodeJpg(image));
  }
}
