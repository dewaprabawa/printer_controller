import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:printer_controller/hardware_printer_device/drivers/advan_harvard_o1_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/bellav_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/generic_2_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/star_mpop_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart' as PrinterPaperSize;
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_58mm.dart';
import 'package:printer_controller/hardware_printer_device/print_data.dart';
import 'package:image/image.dart' as prefix;
import 'package:printer_controller/shared/code_image_generator_helper.dart';
import 'package:printer_controller/shared/image_extension.dart';
import 'package:printer_controller/shared/image_helper.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:printer_controller/shared/tsc_command_plugin.dart';
import '../hardware_printer_device/print_data.dart';
import 'package:path_provider/path_provider.dart';

abstract class PrinterDevice {
  
  bool stillPrinting = false;

  Future<void> printToDevice(PrintData printData);

  Future<void> testPrint(PrintData printData);

  Future<List<String>> translateToEscBytes(
      PrintData printData, List<String> listText) async {
      PrinterDriver printerDriver = printData.selectedDriver;

    List<String> translatedString = [];

    PrinterPaperSize.PaperSize paperSize = printData.selectedDriver.paperSizeList
        .firstWhere((element) => element.name == printData.selectedPaperSize.name,
            orElse: () => PaperSize58mm());

    Generator generator = Generator(
        paperSize.width == 58 ? PaperSize.mm58 : PaperSize.mm80,
        await CapabilityProfile.load());

    for (var i = 0; i < listText.length; i++) {
      if (listText.isNotEmpty) {
        String text = listText[i];
        if (text.contains(PrinterHelperConstant.DATA_IMAGE_FILE) ||
            text.contains(PrinterHelperConstant.DATA_IMAGE_ASSET) ||
            text.contains(PrinterHelperConstant.DATA_LOGO) ||
            text.contains(PrinterHelperConstant.DATA_QR) ||
            text.contains(PrinterHelperConstant.DATA_BARCODE)) {
          if (printerDriver is Generic2PrinterDriver ||
              printerDriver is StarMPopPrinterDriver ||
              printerDriver is AdvanHarvardPrinterDriver ||
              printerDriver is BellavPrinterDriver) {
            final _translated = await _translateImageGeneric2Driver(
                text, printData, generator, paperSize);
            translatedString.addAll(_translated);
          }
          final _translated = await _translateImageGeneric1Driver(
              text, printData, generator, paperSize);
          translatedString.addAll(_translated);
        } else if (text.contains(PrinterHelperConstant.DATA_LINE_CUT)) {
          if (printerDriver.isCutLine) {
            translatedString.addAll(
                [_addRawBytesIdentifier(printerDriver.FEED_PAPER_AND_CUT)]);
          }
        } else if (text.contains(PrinterHelperConstant.DATA_DRAWER)) {
          if (!(printerDriver.CASHDRAWER_1 == [27, 112, 0, 200, 250])) {
            translatedString.addAll([
              _addRawBytesIdentifier(printerDriver.CASHDRAWER_1),
              _addRawBytesIdentifier(printerDriver.CASHDRAWER_2)
            ]);
          } else {
            translatedString.addAll([
              _addRawBytesIdentifier(generator.drawer(pin: PosDrawer.pin2)),
              _addRawBytesIdentifier(generator.drawer(pin: PosDrawer.pin5))
            ]);
          }
        } else {
          translatedString.add(_addRawBytesIdentifier(utf8.encode(text)));
        }
      }
    }

    return translatedString;
  }

  Future<List<String>> translateToTscBytes(
      PrintData printData, List<String> printText) async {
    int width = printData.selectedDriver.paperSizeList
        .firstWhere((element) => element.name == printData.selectedPaperSize.name,
            orElse: () => PaperSize58mm())
        .width;
    int height = printData.selectedDriver.paperSizeList
        .firstWhere((element) => element.name == printData.selectedPaperSize.name,
            orElse: () => PaperSize58mm())
        .height;

    List<List<String>> pages = _breakToSubPages(printText);
    List<String> translatedText = [];

    for (var i = 0; i < pages.length; i++) {
      if (pages[i].isNotEmpty) {
        translatedText.add(PrinterHelperConstant.DATA_RAW_BYTES +
            '::' +
            jsonEncode(
                await TscCommandPlugin.getRawBytes(pages[i], width, height)));
      }
    }
    return translatedText;
  }

  Future<List<String>> translateEpson(
      PrintData printData, List<String> printText) async {
    List<String> translatedString = [];

    PrinterPaperSize.PaperSize paperSize = printData.selectedDriver.paperSizeList
        .firstWhere((element) => element.name == printData.selectedPaperSize.name,
            orElse: () => PaperSize58mm());

    Generator generator = Generator(
        paperSize.width == 58 ? PaperSize.mm58 : PaperSize.mm80,
        await CapabilityProfile.load());

    for (var i = 0; i < printText.length; i++) {
      if (printText[i].isNotEmpty) {
        String text = printText[i];
        if (text.contains(PrinterHelperConstant.DATA_IMAGE_FILE) ||
            text.contains(PrinterHelperConstant.DATA_IMAGE_ASSET) ||
            text.contains(PrinterHelperConstant.DATA_LOGO) ||
            text.contains(PrinterHelperConstant.DATA_QR) ||
            text.contains(PrinterHelperConstant.DATA_BARCODE)) {
          final _translated = await _translateImageGeneric2Driver(
              text, printData, generator, paperSize);
          translatedString.addAll(_translated);
        } else if (text.contains('::')) {
          translatedString.add(text);
        } else {
          translatedString
              .add(PrinterHelperConstant.DATA_RAW_BYTES + '::' + text);
        }
      }
    }

    return translatedString;
  }

  Future<List<String>> _translateImageGeneric1Driver(
      String text,
      PrintData printData,
      Generator generator,
      PrinterPaperSize.PaperSize paperSize) async {
    PrinterDriver printerDriver = printData.selectedDriver;

    if (text.contains(PrinterHelperConstant.DATA_IMAGE_FILE)) {
      String path = text.split("::")[1];

      // Decode image from file
       prefix.Image image = prefix.decodeImage(File(path).readAsBytesSync())!;
       prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      return [
        _addRawBytesIdentifier(
            generator.image(processedImage, align: PosAlign.center))
      ];
    } else if (text.contains(PrinterHelperConstant.DATA_IMAGE_ASSET)) {
      List<String> assets = jsonDecode(text.split("::")[1]).cast<String>();

      // Decode image from file
      prefix.Image? image = await ImageExt.fromAsset(assets[0]);
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      return [
        _addRawBytesIdentifier(
            generator.image(processedImage, align: PosAlign.center))
      ];
    } else if (text.contains(PrinterHelperConstant.DATA_LOGO)) {
      // Decode image from file
      prefix.Image? image = prefix.decodeImage(
          File(await ImageHelper.getPathImageLogoBill()).readAsBytesSync());
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;

      return [
        _addRawBytesIdentifier(
            generator.image(processedImage, align: PosAlign.center)),
        _addRawBytesIdentifier(generator.emptyLines(1))
      ];
    } else if (text.contains(PrinterHelperConstant.DATA_QR)) {
      List<String> splitText = text.split("::");
      prefix.Image image =
          await CodeImageGeneratorHelper.generateQRCodeImage(splitText[1]);
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;

      return [
        _addRawBytesIdentifier(
            generator.image(processedImage, align: PosAlign.center))
      ];
    } else if (text.contains(PrinterHelperConstant.DATA_BARCODE)) {
      List<String> splitText = text.split("::");
      prefix.Image image =
          await CodeImageGeneratorHelper.generateBarcodeImage(splitText[1]);
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;

      return [
        _addRawBytesIdentifier(
            generator.image(processedImage, align: PosAlign.center))
      ];
    } else {
      return [];
    }
  }

  Future<List<String>> _translateImageGeneric2Driver(
      String text,
      PrintData printData,
      Generator generator,
      PrinterPaperSize.PaperSize paperSize) async {
    PrinterDriver printerDriver = printData.selectedDriver;

    if (text.contains(PrinterHelperConstant.DATA_IMAGE_FILE)) {
      String path = text.split("::")[1];

      // Decode image from file
      prefix.Image image = prefix.decodeImage(File(path).readAsBytesSync())!;
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      final processedPath = await _saveImageToLocalPath(processedImage);

      return [_addImageIdentifier(processedPath)];
    } else if (text.contains(PrinterHelperConstant.DATA_IMAGE_ASSET)) {
      List<String> assets = jsonDecode(text.split("::")[1]).cast<String>();

      // Decode image from file
      prefix.Image? image = await ImageExt.fromAsset(assets[0]);
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      final processedPath = await _saveImageToLocalPath(processedImage);

      return [_addImageIdentifier(processedPath)];
    } else if (text.contains(PrinterHelperConstant.DATA_LOGO)) {
      // Decode image from file
      prefix.Image? image = prefix.decodeImage(
          File(await ImageHelper.getPathImageLogoBill()).readAsBytesSync());
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      final processedPath = await _saveImageToLocalPath(processedImage);

      return [
        _addImageIdentifier(processedPath),
        _addRawBytesIdentifier(generator.emptyLines(1))
      ];
    } else if (text.contains(PrinterHelperConstant.DATA_QR)) {
      List<String> splitText = text.split("::");
       prefix.Image image =
          await CodeImageGeneratorHelper.generateQRCodeImage(splitText[1]);
       prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      final processedPath = await _saveImageToLocalPath(processedImage);

      return [_addImageIdentifier(processedPath)];
    } else if (text.contains(PrinterHelperConstant.DATA_BARCODE)) {
      List<String> splitText = text.split("::");
      prefix.Image image =
          await CodeImageGeneratorHelper.generateBarcodeImage(splitText[1]);
      prefix.Image processedImage =
          printerDriver.preprintImageProcess(image, paperSize.maxImageWidth)!;
      final processedPath = await _saveImageToLocalPath(processedImage);

      return [_addImageIdentifier(processedPath)];
    } else {
      return [];
    }
  }

  List<List<String>> _breakToSubPages(List<String> printText) {
    List<List<String>> pages = [[]];

    for (var i = 0; i < printText.length; i++) {
      if (printText[i].contains(PrinterHelperConstant.DATA_LINE_CUT)) {
        if (i != printText.length - 1) pages.add([]);
      } else if (printText[i].contains(PrinterHelperConstant.DATA_DRAWER)) {
        // Skip cashdrawer
      } else {
        // Split new lines [\n] to individual element.
        List<String> lineSplit =
            printText[i] == '\n' ? [printText[i]] : printText[i].split('\n')
              ..removeWhere((element) => element.isEmpty);
        pages.last.addAll(lineSplit);
      }
    }
    return pages;
  }

  String _addRawBytesIdentifier(List<int> value) {
    return PrinterHelperConstant.DATA_RAW_BYTES + '::' + jsonEncode(value);
  }

  String _addImageIdentifier(String path) {
    return PrinterHelperConstant.DATA_IMAGE_FILE + '::' + jsonEncode(path);
  }

  Future<String> _saveImageToLocalPath(prefix.Image image) async {
    Random random = new Random();
    int name = random.nextInt(100000);

    final _tempDirectory = (await getTemporaryDirectory()).path;

    final file =
        await File('$_tempDirectory/$name.png').writeAsBytes(prefix.encodePng(image));

    return file.path;
  }
}
