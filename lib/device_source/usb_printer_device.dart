import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as prefix;
import 'package:flutter/material.dart';
import 'package:printer_controller/device_source/printer_device.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/star_mpop_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_58mm.dart';
import 'package:printer_controller/hardware_printer_device/print_data.dart';
import 'package:printer_controller/hardware_printer_device/usb_service/usb_printer_plugin.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart' as PrinterPaperSize;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:printer_controller/shared/code_image_generator_helper.dart';
import 'package:printer_controller/shared/image_helper.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:printer_controller/shared/show_toast.dart';

class UsbPrinterDevice extends PrinterDevice {
  
  @override
  bool get stillPrinting => false;

  @override
  set stillPrinting(bool _stillPrinting) {
    super.stillPrinting = _stillPrinting;
  }
  

  Future<bool> connect(String address) async {
     var value = ValueAdressUsb.fromAddress(address);
     try {
      return await UsbPrinterPlugin.connectPrinter(
          value.vendorId, value.productId) ?? false;
    } catch (_) {
      debugPrint("USB FAILED TO CONNECT");
      rethrow;
      //response = 'Failed to get platform version.';
    }
  }

  @override
  Future<void> printToDevice(PrintData printData) async {
    stillPrinting = true;

    PrinterDriver printerDriver = printData.selectedDriver;
    List<String> listText = printData.printContent;

    if (printerDriver.commandType == PrinterCommand.ESC) {
      listText = await translateToEscBytes(printData, listText);
    } else if (printerDriver.commandType == PrinterCommand.TSC) {
      listText = await translateToTscBytes(printData, listText);
    }

    debugPrint("START-PRINT-USB");
    String titlePrint = printData.printTitle;

    bool connected = await connect(printData.address);

    PrinterPaperSize.PaperSize paperSize = printerDriver.paperSizeList
        .firstWhere((element) => element.name == printData.selectedPaperSize.name,
        orElse: () => PaperSize58mm());

    Generator generator = Generator(
        paperSize.width == 58 ? PaperSize.mm58 : PaperSize.mm80,
        await CapabilityProfile.load());


    if (connected) {
      debugPrint("LANJUT-PRINT");

      if (titlePrint.isNotEmpty){
         debugPrint("Print " + titlePrint + " ...");
         ShowToast.present(message: "Print " + titlePrint + " ...");
      }
       
      try {
        for (String text in listText) {
          debugPrint(">>>>>>> " + text);
          List<String> splitText = text.split("::");
          if (text.contains(PrinterHelperConstant.DATA_RAW_BYTES)) {
            Uint8List rawBytes =
                Uint8List.fromList(List<int>.from(jsonDecode(splitText[1])));
              if(String.fromCharCodes(Uint8List.fromList(rawBytes)).
              contains(PrinterHelperConstant.PRINT_STRUK_LABEL_COPY)) {
                await UsbPrinterPlugin.printRawData(Uint8List.fromList(generator.text(
                    PrinterHelperConstant.PRINT_STRUK_LABEL_COPY,
                    styles: const PosStyles(
                        align: PosAlign.center,
                        bold: true,
                        width: PosTextSize.size2,
                        height: PosTextSize.size2))));
                await UsbPrinterPlugin.printRawData(Uint8List.fromList(generator.reset()));
              }else{
                await UsbPrinterPlugin.printRawData(rawBytes);
              }
          } else if (text.contains(PrinterHelperConstant.DATA_LOGO)) {

              String imgPath = await ImageHelper.getPathImageLogoBill();
              await UsbPrinterPlugin.printImage(
                imgPath,
                driver: (printerDriver is StarMPopPrinterDriver)
                    ? PrinterUSBDriver.mPop
                    : PrinterUSBDriver.generic,
              );
            
          } else if (text.contains(PrinterHelperConstant.DATA_QR)) {
           
              File qrFile = await CodeImageGeneratorHelper.generateQRCodeFile(
                  splitText[1]);
              String qrCodePath = qrFile.path;
              
              await UsbPrinterPlugin.printQRBarcode(qrCodePath);
            
          } else if (text.contains(PrinterHelperConstant.DATA_BARCODE)) {
            
              List<String> splitText = text.split("::");
//            File qrFile = await CodeImageGeneratorHelper().generateBarcode(splitText[1]);
//            String qrCodePath = qrFile.path;
//            Image image = decodeImage(File(qrCodePath).readAsBytesSync());
              //TODO Print Image Belum bisa di USB
            
          } else if (text.contains(PrinterHelperConstant.DATA_LINE_CUT)) {
            await UsbPrinterPlugin.printText("\n\n\n");
          } else if (text.contains(PrinterHelperConstant.DATA_DRAWER)) {
            await UsbPrinterPlugin.printRawData(
                Uint8List.fromList(printerDriver.CASHDRAWER_1));
            await UsbPrinterPlugin.printRawData(
                Uint8List.fromList(printerDriver.CASHDRAWER_2));
            stillPrinting = false;
            return;
          } else if (text.contains(PrinterHelperConstant.DATA_IMAGE_FILE)) {
            await UsbPrinterPlugin.printImage(
              jsonDecode(splitText[1]),
              driver: (printerDriver is StarMPopPrinterDriver)
                  ? PrinterUSBDriver.mPop
                  : PrinterUSBDriver.generic,
            );
          } else {
            await UsbPrinterPlugin.printText(text);
          }
        }

        await UsbPrinterPlugin.printRawData(
            Uint8List.fromList(printerDriver.POST_PRINT));

        if (titlePrint.isNotEmpty){
            debugPrint("Print " + titlePrint + " selesai.");
            ShowToast.present(message: "Print " + titlePrint + " selesai.");
        }
        
      } catch (exception) {
        String error =
            "Print " + titlePrint + " " + printData.name + " gagal!";
         stillPrinting = false;
         debugPrint(error + "\n" + exception.toString());
         debugPrint(error);
        ShowToast.present(message: error);
        rethrow;
        //response = 'Failed to get platform version.';
      }
    } else {
      String error = "Print " +
          titlePrint +
          " " +
          printData.name +
          " koneksi error!";
      debugPrint(error);
      ShowToast.present(message: error);
      stillPrinting = false;
      return;
    }

    stillPrinting = false;
  }

  @override
  Future<void> testPrint(PrintData printData) async {
     await printToDevice(printData.copyWith(printActionParams: 
    PrinterHelperConstant.DATA_TEST_PRINT, 
    printTitleParams: "test"));
  }

 
}

class ValueAdressUsb {
  final int productId;
  final int vendorId;

  ValueAdressUsb({required this.productId, required this.vendorId});

  factory ValueAdressUsb.fromAddress(String address) {
    return ValueAdressUsb(
        productId: int.tryParse(address.split(":")[0])!,
        vendorId: int.tryParse(address.split(":")[1])!);
  }
}