import 'package:image/image.dart' as prefix;
import 'package:flutter/material.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';

class AdvanHarvardPrinterDriver extends PrinterDriver {
  // Double line feed
  @override
  List<int> POST_PRINT = [10, 10];

  @override
  bool isNeedRestart = true;

  @override
  prefix.Image preprintImageProcess(prefix.Image? image, int maxImageWidth) {
    prefix.Image resizedImage = prefix.copyResize(image!, width: (image!.width ~/ 2));

    int imagePadding = (maxImageWidth ~/ 2) - (resizedImage.width ~/ 2);

     prefix.Image paddedImage =
         prefix.Image(maxImageWidth, resizedImage.width).fill(0xFFFFFFFF);

     prefix.drawImage(paddedImage, resizedImage, dstX: imagePadding);
    return image.width > maxImageWidth ? image : paddedImage;
  }
}
