import 'package:image/image.dart' as prefix;
import 'package:flutter/material.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';

class EpsonPrinterDriver extends PrinterDriver {
  @override
  prefix.Image preprintImageProcess(prefix.Image? image, int maxImageWidth) {
    prefix.Image resizedImage = image!.width > maxImageWidth
        ? prefix.copyResize(image, width: maxImageWidth)
        : prefix.Image.from(image);

    int imagePadding = (maxImageWidth ~/ 8) - (resizedImage.width ~/ 8);

    prefix.Image paddedImage = prefix.Image(maxImageWidth, resizedImage.width ~/ 2);
    prefix.drawImage(paddedImage, resizedImage, dstX: imagePadding);
    return paddedImage;
  }
}
