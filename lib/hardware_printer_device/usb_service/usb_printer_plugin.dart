import 'dart:typed_data';

import 'package:flutter/services.dart';

class UsbPrinterPlugin {
  static const _channel = const MethodChannel('com.klopos/usb_printer');

  static Future<List?> get getUSBDeviceList async {
    final List? devices = await _channel.invokeMethod('getUSBDeviceList');
    return devices;
  }

  static Future<bool?> connectPrinter(int vendor, int product) async {
    Map<String, dynamic> params = {"vendor": vendor, "product": product};
    final bool? returned =
        await _channel.invokeMethod('connectPrinter', params);
    return returned;
  }

  static Future<bool?> get closeConn async {
    final bool? returned = await _channel.invokeMethod('closeConn');
    return returned;
  }

  static Future<bool?> printText(String text) async {
    Map<String, dynamic> params = {"text": text};
    final bool? returned = await _channel.invokeMethod('printText', params);
    await Future.delayed(Duration(milliseconds: 20));
    return returned;
  }

  static Future<bool?> printRawData(Uint8List rawData) async {
    Map<String, dynamic> params = {"raw": rawData};
    final bool? returned = await _channel.invokeMethod('printRawData', params);
    return returned;
  }

  static Future<bool?> printImage(String text,
      {PrinterUSBDriver driver = PrinterUSBDriver.generic}) async {
    Map<String, dynamic> params = {
      "text": text,
      "driver": driver == PrinterUSBDriver.mPop ? 'mpop' : null,
    };
    final bool? returned = await _channel.invokeMethod('printImage', params);
    return returned;
  }

  static Future<bool?> printQRBarcode(String text,
      {PrinterUSBDriver driver = PrinterUSBDriver.generic}) async {
    Map<String, dynamic> params = {
      "text": text,
      "driver": driver == PrinterUSBDriver.mPop ? 'mpop' : null,
    };
    final bool? returned =
        await _channel.invokeMethod('printQRBarcode', params);
    return returned;
  }
}

enum PrinterUSBDriver {
  generic,
  mPop,
}
