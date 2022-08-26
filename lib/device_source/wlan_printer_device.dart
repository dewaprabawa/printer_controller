import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as prefix;
import 'package:flutter/material.dart';
import 'package:printer_controller/device_source/printer_device.dart';
import 'package:printer_controller/hardware_printer_device/drivers/epson_printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/print_data.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:printer_controller/shared/global_method_helper.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';
import 'package:epson_epos/epson_epos.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:printer_controller/shared/show_toast.dart';

class WlanPrinterDevice extends PrinterDevice {
  static String? currentPrintingDevice = '';

  @override
  bool get stillPrinting => false;

  @override
  set stillPrinting(bool _stillPrinting) {
    super.stillPrinting = _stillPrinting;
  }

  Future<String?> getLocalIp() async {
    String? ip = "";
    try {
      ip = (await _getIpAddress() as String);
      debugPrint('local ip:\t$ip');
      return ip;
    } catch (exception, stackTrace) {
      debugPrint('exception :\t$exception');
      debugPrint('stackTrace :\t$stackTrace');
      rethrow;
    }
  }

  static Future<String?> _getIpAddress() async {
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: true);
    try {
      // Try VPN connection first
      NetworkInterface vpnInterface =
          interfaces.firstWhere((element) => element.name == "tun0");
      return vpnInterface.addresses.first.address;
    } on StateError {
      // Try wlan connection next
      try {
        NetworkInterface interface =
            interfaces.firstWhere((element) => element.name == "wlan0");
        return interface.addresses.first.address;
      } catch (ex) {
        // Try any other connection next
        try {
          NetworkInterface interface = interfaces.firstWhere((element) =>
              !(element.name == "tun0" || element.name == "wlan0"));
          return interface.addresses.first.address;
        } catch (ex) {
          return null;
        }
      }
    }
  }

  Stream<NetworkAddress> connect(String address) {
    final value = ValueAdressWlan.fromAddress(address);
    final String subnet = value.ip.substring(0, value.ip.lastIndexOf('.'));

    debugPrint('subnet:\t$subnet, port:\t${value.port}');

    return NetworkAnalyzer.discover2(subnet, value.port,
            timeout: const Duration(seconds: 5))
        .where((event) => event.exists);
  }

  @override
  Future<void> printToDevice(PrintData printData) async {
    var listText = printData.printContent;
    stillPrinting = true;
    currentPrintingDevice = printData.address;

    PrinterDriver printerDriver = printData.selectedDriver;

    PaperSize paper = printData.selectedPaperSize.name ==
            PrinterHelperConstant.PRINTER_TIPE_KERTAS_58MM
        ? PaperSize.mm58
        : PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile, spaceBetweenRows: 0);

    if (printerDriver is EpsonPrinterDriver) {
      listText = await translateEpson(printData, listText);
    } else if (printerDriver.commandType == PrinterCommand.ESC) {
      listText = await translateToEscBytes(printData, listText);
    } else if (printerDriver.commandType == PrinterCommand.TSC) {
      listText = await translateToTscBytes(printData, listText);
    }

    debugPrint("START-PRINT-WIFI");
    String titlePrint = printData.printTitle;

    try {
      //todo: Address = IP dan Port adalah port
      final value = ValueAdressWlan.fromAddress(printData.address);
      final connect = await printer.connect(value.ip,
          port: value.port, timeout: const Duration(seconds: 15));
      if (connect != PosPrintResult.success) {
        throw TimeoutException('Koneksi printer gagal');
      }

      late final EpsonPrinterModel epsonModel;
      if (printerDriver is EpsonPrinterDriver) {
        final isImage = listText.firstWhere(
          (element) => element.contains(PrinterHelperConstant.DATA_IMAGE_FILE),
          orElse: () => '',
        );

        if (isImage != '') {
          epsonModel = EpsonPrinterModel(
            address: printData.address,
            type: 'TCP',
            series: 'TM_U220',
          );
        }
      }

      printer.setGlobalFont(PosFontType.fontA);
      printer.setStyles(const PosStyles(align: PosAlign.center));

      debugPrint("LANJUT-PRINT");
      if (!GlobalMethodHelper.isEmpty(titlePrint)) {
        debugPrint("Print " + titlePrint + " ...");
        ShowToast.present(message: "Print " + titlePrint + " ...");
      }

      try {
        List<Map<String, dynamic>> commands = [];
        for (String text in listText) {
          debugPrint(">>>>>>> " + text);
          List<String> splitText = text.split("::");

          if (printerDriver is EpsonPrinterDriver) {
            final command = await _handlePrintEpson(
              splitText.first,
              splitText[1],
              text,
              epsonModel,
            );
            if (command.isNotEmpty) {
              commands.add(command);
            }
          } else {
            await _handlePrintGeneric(
              printer: printer,
              textCase: splitText.first,
              dataText: splitText[1],
              rawText: text,
              isNeedDelay: printerDriver.isNeedDelay,
            );
          }
        }

        if (printerDriver is EpsonPrinterDriver) {
          int paperSize = printData.selectedPaperSize.name ==
                  PrinterHelperConstant.PRINTER_TIPE_KERTAS_58MM
              ? 58
              : 80;
          final epsonPrint = await EpsonEPOS.onPrint(
            epsonModel,
            commands,
            paperWidth: paperSize,
          );
          if (epsonPrint.contains('success\":false')) {
            throw 'connection failed';
          }
        } else {
          printer.rawBytes(printerDriver.POST_PRINT);
          printer.disconnect();
        }
        if (!GlobalMethodHelper.isEmpty(titlePrint)) {
          debugPrint("Print " + titlePrint + " selesai.");
          ShowToast.present(message:"Print " + titlePrint + " selesai.");
        }
      } catch (exception, _) {
        String error = "Print " + titlePrint + " " + printData.name + " gagal!";
        debugPrint(error + "\n" + exception.toString());
        ShowToast.present(message: error);
        rethrow;
      }
    } on TimeoutException catch (e, s) {
      debugPrint("Print $titlePrint ${printData.name} koneksi error!");
      ShowToast.present(message: "Print $titlePrint ${printData.name} koneksi error!");
      throw 'errorByConnection';
    } catch (e, _) {
      debugPrint("Print $titlePrint ${printData.name} koneksi error!");
      ShowToast.present(message: "Print $titlePrint ${printData.name} koneksi error!");
      rethrow;
    } finally {
      stillPrinting = false;
    }
  }

  @override
  Future<void> testPrint(PrintData printData) async {
    await printToDevice(printData.copyWith(
        printActionParams: PrinterHelperConstant.DATA_TEST_PRINT,
        printTitleParams: "test"));
  }

  Future<void> _handlePrintGeneric(
      {required NetworkPrinter printer,
      required String textCase,
      required String dataText,
      required String rawText,
      required bool isNeedDelay}) async {
    switch (textCase) {
      case PrinterHelperConstant.DATA_RAW_BYTES:
        List<int> rawBytes = List<int>.from(jsonDecode(dataText));
        for (int i = 0; i < rawBytes.length; i += 3000) {
          int end = i + 3000;
          var bytes = rawBytes.sublist(
              i, end < rawBytes.length ? end : rawBytes.length);
          if (String.fromCharCodes(Uint8List.fromList(bytes))
              .contains(PrinterHelperConstant.PRINT_STRUK_LABEL_COPY)) {
            printer.text(PrinterHelperConstant.PRINT_STRUK_LABEL_COPY,
                styles: const PosStyles(
                    bold: true,
                    align: PosAlign.center,
                    width: PosTextSize.size2,
                    height: PosTextSize.size2));
            printer.reset();
          } else {
            printer.rawBytes(bytes, isKanji: true);
          }
          if (isNeedDelay) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        break;
      case PrinterHelperConstant.DATA_IMAGE_FILE:
        String imagePath = jsonDecode(dataText);
        prefix.Image image =
            prefix.decodeImage(File(imagePath).readAsBytesSync())!;
        printer.image(image, align: PosAlign.center);
        printer.feed(1);
        break;
      default:
        if (rawText.endsWith("\n"))
          rawText = rawText.substring(0, rawText.length - 1);
        printer.text(rawText, styles: const PosStyles(align: PosAlign.center));
        break;
    }
  }

  Future<Map<String, dynamic>> _handlePrintEpson(
    String textCase,
    String dataText,
    String rawText,
    EpsonPrinterModel epsonModel,
  ) async {
    final EpsonEPOSCommand command = EpsonEPOSCommand();
    switch (textCase) {
      case PrinterHelperConstant.DATA_RAW_BYTES:
        return command.append(dataText);
      case PrinterHelperConstant.DATA_IMAGE_FILE:
        late String imagePath;
        try {
          imagePath = jsonDecode(dataText);
        } on FormatException catch (e) {
          imagePath = dataText;
        }
        prefix.Image image =
            prefix.decodeImage(File(imagePath).readAsBytesSync())!;
        final bytes = File(imagePath).readAsBytesSync();
        return command.appendBitmap(
          base64Encode(bytes),
          image.width,
          image.height,
          image.xOffset,
          image.yOffset,
        );
      case PrinterHelperConstant.DATA_LINE_CUT:
        return command.addCut(EpsonEPOSCut.CUT_FEED);
      default:
        if (rawText.endsWith("\n")) {
          rawText = rawText.substring(0, rawText.length - 1);
          return command.append(rawText);
        } else {
          return {};
        }
    }
  }
}

class ValueAdressWlan {
  final String ip;
  final int port;

  ValueAdressWlan({required this.ip, required this.port});

  factory ValueAdressWlan.fromAddress(String address) {
    return ValueAdressWlan(
        ip: address.split(":")[0],
        port: int.tryParse(address.split(":")[1])!);
  }
}
