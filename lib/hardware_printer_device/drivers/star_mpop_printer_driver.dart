import 'package:image/image.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';

class StarMPopPrinterDriver extends PrinterDriver {
  @override
  final List<int> CASHDRAWER_1 = [27, 7, 20, 20];

  @override
  final List<int> CASHDRAWER_2 = [7];

  @override
  final List<int> FEED_PAPER_AND_CUT = [27, 100, 0];

  @override
  final List<int> POST_PRINT = [10, 10, 10];

  @override
  Image preprintImageProcess(Image? image, int maxImageWidth) {
    Image resizedImage = image!.width > maxImageWidth
        ? copyResize(image, width: maxImageWidth)
        : Image.from(image);

    int imagePadding = (maxImageWidth ~/ 2) - (resizedImage.width ~/ 2);
    Image paddedImage = Image(maxImageWidth, resizedImage.width);
    drawImage(paddedImage, resizedImage, dstX: imagePadding);

    /// NOTE: change to white
    final rawImage = paddedImage.getBytes();
    for (var i = 0, len = rawImage.length; i < len; i += 4) {
      if (rawImage[i + 3] != 255) {
        rawImage[i] = 255;
        rawImage[i + 1] = 255;
        rawImage[i + 2] = 255;
        rawImage[i + 3] = 255;
      }
    }

    return paddedImage;
  }
}
