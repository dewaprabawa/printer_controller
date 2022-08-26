import 'dart:convert';
import 'dart:typed_data';
import 'package:byte_flow/byte_flow.dart' as ByteFlow;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printer_controller/device_source/printer_device.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/star_mpop_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_58mm.dart';
import 'package:printer_controller/hardware_printer_device/print_data.dart';
import 'package:printer_controller/shared/global_method_helper.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart' as PrinterPaperSize;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:printer_controller/shared/show_toast.dart';

class BluetoothPrinterDevice extends PrinterDevice {

  static BlueThermalPrinter blueThermalPrinter = BlueThermalPrinter.instance;
  static BluetoothDevice? currentDevice;

  static bool bluetoothDiconnectedStatus = false;
  static bool bluetoothConnectedStatus = false;
   
  @override
  bool get stillPrinting => false; 

  @override
  set stillPrinting(bool _isStillPrinting) {
    super.stillPrinting = _isStillPrinting;
  }

  Future<bool> connect(String address) async {
    var value = ValueAddressBluetooth.fromAddress(address);
    bool isConnected = false;
    currentDevice = await BluetoothDevice(value.name, value.address);
    debugPrint("BT => Name:" + currentDevice!.name! + ", Address:" + currentDevice!.address!);
     bool isCon = false;
    isCon = await blueThermalPrinter.isDeviceConnected(currentDevice!)
        .then((isConnect) async {
          if (isConnect!) isCon = true;
          else {
            /*
            To try to connect to bluetooth for the first time
            because some devices can't reconnect bluetooth only once
            */
            isCon = true;
            await blueThermalPrinter.connect(currentDevice!).catchError((error) {
              isCon = false;
            });
          }
          return isCon;
    });

    debugPrint("isCon: " + isCon.toString());

    if (isCon) {
      debugPrint("Cek=Connected");
      isConnected = true;
    } else {
      bool? value =
          (await blueThermalPrinter.connect(currentDevice!).catchError((error) {
        debugPrint("Cek=ErrorReconnect");
        isConnected = false;
      }));

      if (value != null && value) {
        debugPrint("Cek=SuccessReconnect");
        isConnected = true;
      } else {
        debugPrint("Cek=ErrorReconnect");
        isConnected = false;
      }
    }
    return isConnected;
  }

  @override
  Future<void> printToDevice(PrintData printData) async {
    List<String> listText = printData.printContent;
    try {
      PrinterDriver printerDriver = printData.selectedDriver;

      if (printData.printAction == PrinterHelperConstant.ACTION_OPEN_CASHDRAWER) return;

      PrinterPaperSize.PaperSize paperSize = printerDriver
          .paperSizeList
          .firstWhere((element) => element.name == printData.selectedPaperSize.name,
              orElse: () => PaperSize58mm());

      Generator generator = Generator(
          paperSize.width == 58 ? PaperSize.mm58 : PaperSize.mm80,
          await CapabilityProfile.load());

      stillPrinting = true;
      bool isCutLine = false;

      if (printerDriver.isCutLine) {
        isCutLine = true;
      } else {
        listText.removeWhere((element) {
          final _isCut = element.contains(PrinterHelperConstant.DATA_LINE_CUT);
          return _isCut;
        });
      }

      if (printerDriver.commandType == PrinterCommand.ESC) {
        listText = await translateToEscBytes(printData, listText);
      } else if (printerDriver.commandType == PrinterCommand.TSC) {
        listText = await translateToTscBytes(printData, listText);
      }

      debugPrint("START-PRINT-BLUETOOTH");
      String titlePrint =
          printData.printTitle;

      bool connected = await connect(printData.address);

      if (connected) {
        debugPrint("LANJUT-PRINT");
        if (!GlobalMethodHelper.isEmpty(titlePrint)){
            debugPrint("Print " + titlePrint + " ...");

        }
       
        if (printerDriver.INIT.isNotEmpty) {
          blueThermalPrinter.writeBytes(
              printData.address, Uint8List.fromList(printerDriver.INIT));
        }

        try {
          for (String text in listText) {
            debugPrint(">>>>>>> " + text);

            List<String> splitText = text.split("::");

            switch (splitText.first) {
              case PrinterHelperConstant.DATA_IMAGE_FILE:
                blueThermalPrinter.printImage(
                  jsonDecode(splitText[1]),
                  printerDriver.imagePadding,
                  address: printData.address,
                  driver: printerDriver is StarMPopPrinterDriver
                      ? PrinterBluetoothDriver.mPop
                      : PrinterBluetoothDriver.generic,
                );
                blueThermalPrinter.printNewLine(printData.address);
                break;
              default:
                Uint8List rawBytes = Uint8List.fromList(
                    List<int>.from(jsonDecode(splitText[1])));
                final _listText = _splitRawBytesData(
                  rawBytes,
                  splitter: printerDriver.isNeedDelay ? 128 : 756,
                );

                for (final _data in _listText) {
                  if (printerDriver.isNeedDelay) {
                    await Future.delayed(const Duration(milliseconds: 50));
                  }
                  if (String.fromCharCodes(Uint8List.fromList(_data))
                      .contains(PrinterHelperConstant.PRINT_STRUK_LABEL_COPY)) {
                    await blueThermalPrinter.printNewLine(
                      printData.address,
                    );
                    await blueThermalPrinter.writeBytes(
                      printData.address,
                      Uint8List.fromList(generator.text(
                        PrinterHelperConstant.PRINT_STRUK_LABEL_COPY,
                        styles: const PosStyles(
                            bold: true,
                            align: PosAlign.center,
                            width: PosTextSize.size2,
                            height: PosTextSize.size2),
                      )),
                    );
                    await blueThermalPrinter.writeBytes(
                      printData.address,
                      Uint8List.fromList(generator.reset()),
                    );
                    await blueThermalPrinter.printNewLine(
                       printData.address,
                    );
                  } else {
                    await blueThermalPrinter.writeBytes(
                      printData.address,
                      Uint8List.fromList(_data),
                    );
                  }
                }
                break;
            }
          }

          if (printerDriver.POST_PRINT.isNotEmpty) {
            await blueThermalPrinter.writeBytes(printData.address,
                Uint8List.fromList(printerDriver.POST_PRINT));
          }

          if (isCutLine) {
            List<String> cutText = [];
            if (printerDriver.commandType == PrinterCommand.TSC) {
              cutText = await translateToTscBytes(printData, listText);
            } else {
              cutText = await translateToEscBytes(printData,
                  ['${PrinterHelperConstant.DATA_LINE_CUT}::']);
            }

            final _text = cutText.first.split("::");
            Uint8List rawBytes =
                Uint8List.fromList(List<int>.from(jsonDecode(_text[1])));

            await blueThermalPrinter.writeBytes(
                printData.address, rawBytes);
          }

          if (!GlobalMethodHelper.isEmpty(titlePrint)){
              debugPrint("Print " + titlePrint + " selesai");
              ShowToast.present(message: "Print " + titlePrint + " selesai");
          }
             
        } on PlatformException catch (e) {
          if (e.code == "write_error" && e.message == "not connected") {
            // Try to print again if got error write error / socket closed
            printToDevice(printData);
          }
        } catch (exception, _) {
          String error =
              "Print " + titlePrint + " " + printData.name + " failed...!";
          debugPrint(error + "\n" + exception.toString());
          stillPrinting = false;
          ShowToast.present(message: error);
        }
      } else {
        String error = "Percobaan koneksi printer " +
            titlePrint +
            " " +
            printData.name +
            " gagal, silahkan buka menu pengaturan hardware untuk menghubungkan printer.";
        debugPrint(error);
        ShowToast.present(message: error);
        stillPrinting = false;
      }
    } catch (e, stacktrace) {
      stillPrinting = false;
      debugPrint("Exception: " + e.toString());
      debugPrint("Stacktrace: " + stacktrace.toString());
      rethrow;
    }

    stillPrinting = false;
  }

  @override
  Future<void> testPrint(PrintData printData) async {
    await printToDevice(printData.copyWith(printActionParams: 
    PrinterHelperConstant.DATA_TEST_PRINT, 
    printTitleParams: "test"));
  }

  List<List<int>> _splitRawBytesData(Uint8List rawBytes, {int splitter = 756}) {
    final chunksList = ByteFlow.chunk(rawBytes, splitter);
    List<List<int>> intResult = [];
    for (final chunk in chunksList) {
      final res = List<int>.from(chunk);
      intResult.add(res);
    }
    return intResult;
  }

}


class ValueAddressBluetooth {
  final String name;
  final String address;

  ValueAddressBluetooth({required this.name, required this.address});

  factory ValueAddressBluetooth.fromAddress(String address) {
    return ValueAddressBluetooth(
        name: address.split(":")[0], address: address.split(":")[1]);
  }
}
