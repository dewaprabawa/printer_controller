import 'dart:io';

import 'package:image/image.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:barcode_image/barcode_image.dart';

class CodeImageGeneratorHelper {
  static Future<File> generateBarcodeFile(String text) async {
    final tempDir = await getTemporaryDirectory();
    final image = Image(300, 150);

    String path = tempDir.path;
    fill(image, getColor(255, 255, 255));
    drawBarcode(image, Barcode.code128(), text);

    print(path);
    return await File('$path/imageBarcodeGenerated.jpg')
      ..writeAsBytesSync(encodeJpg(image));
  }

  static Future<Image> generateBarcodeImage(String text) async {
    final image = Image(300, 150);

    fill(image, getColor(255, 255, 255));
    drawBarcode(image, Barcode.code128(), text);

    return image;
  }

  static Future<File> generateQRCodeFile(String text, 
    {int height = 150, int width = 150}) async {
    final tempDir = await getTemporaryDirectory();
    final image = Image(width, height);

    String path = tempDir.path;
    fill(image, getColor(255, 255, 255));
    drawBarcode(image, Barcode.qrCode(), text);

    print(path);
    return await File('$path/imageQrCodeGenerated.jpg')
      ..writeAsBytesSync(encodeJpg(image));
  }

  static Future<Image> generateQRCodeImage(String text) async {
    final image = Image(150, 150);

    fill(image, getColor(255, 255, 255));
    drawBarcode(image, Barcode.qrCode(), text);

    return image;
  }
}
