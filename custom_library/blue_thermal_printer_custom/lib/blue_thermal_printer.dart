import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class BlueThermalPrinter {
  static const int STATE_OFF = 10;
  static const int STATE_TURNING_ON = 11;
  static const int STATE_ON = 12;
  static const int STATE_TURNING_OFF = 13;
  static const int STATE_BLE_TURNING_ON = 14;
  static const int STATE_BLE_ON = 15;
  static const int STATE_BLE_TURNING_OFF = 16;
  static const int ERROR = -1;
  static const int CONNECTED = 1;
  static const int DISCONNECTED = 0;

  static const String namespace = 'blue_thermal_printer';

  static const MethodChannel _channel =
      const MethodChannel('$namespace/methods');

  static const EventChannel _readChannel =
      const EventChannel('$namespace/read');

  static const EventChannel _stateChannel =
      const EventChannel('$namespace/state');

  final StreamController<MethodCall> _methodStreamController =
      new StreamController.broadcast();

  //Stream<MethodCall> get _methodStream => _methodStreamController.stream;

  BlueThermalPrinter._() {
    _channel.setMethodCallHandler((MethodCall call) {
      _methodStreamController.add(call);
      return Future.value();
    });
  }

  static BlueThermalPrinter _instance = new BlueThermalPrinter._();

  static BlueThermalPrinter get instance => _instance;

  Stream<int?> onStateChanged() =>
      _stateChannel.receiveBroadcastStream().map((buffer) => buffer);

  Stream<String> onRead() =>
      _readChannel.receiveBroadcastStream().map((buffer) => buffer.toString());

  Future<bool?> get isAvailable async =>
      await _channel.invokeMethod('isAvailable');

  Future<bool?> get isOn async => await _channel.invokeMethod('isOn');

  Future<bool?> isConnected(String address) async =>
      await _channel.invokeMethod('isConnected', {'address': address});

  Future<bool?> isDeviceConnected(BluetoothDevice device) =>
      _channel.invokeMethod('isDeviceConnected', device.toMap());

  Future<bool?> get openSettings async =>
      await _channel.invokeMethod('openSettings');

  Future<List<BluetoothDevice>> getBondedDevices() async {
    final List list = await _channel.invokeMethod('getBondedDevices');
    return list.map((map) => BluetoothDevice.fromMap(map)).toList();
  }

  Future<dynamic> connect(BluetoothDevice device) =>
      _channel.invokeMethod('connect', device.toMap());

  Future<dynamic> disconnect(String address) =>
      _channel.invokeMethod('disconnect', {'address': address});

  Future<dynamic> write(String address, String message) =>
      _channel.invokeMethod('write', {'message': message, 'address': address});

  Future<dynamic> writeBytes(String address, Uint8List message) => _channel
      .invokeMethod('writeBytes', {'message': message, 'address': address});

  Future<dynamic> printCustom(String message, int size, int align) =>
      _channel.invokeMethod(
          'printCustom', {'message': message, 'size': size, 'align': align});

  Future<dynamic> printNewLine(String address) =>
      _channel.invokeMethod('printNewLine', {'address': address});

  Future<dynamic> paperCut(String address) =>
      _channel.invokeMethod('paperCut', {'address': address});

  Future<dynamic> openCashdrawer() => _channel.invokeMethod('openCashdrawer');

  Future<dynamic> printImage(String pathImage, int leftMargin,
          {required String address,
          PrinterBluetoothDriver driver = PrinterBluetoothDriver.generic}) =>
      _channel.invokeMethod('printImage', {
        'pathImage': pathImage,
        'leftMargin': leftMargin,
        'address': address,
        'driver': driver == PrinterBluetoothDriver.mPop ? 'mpop' : null,
      });

  Future<dynamic> printQRcode(String textToQR) =>
      _channel.invokeMethod('printQRcode', {'textToQR': textToQR});

  Future<dynamic> printLeftRight(String string1, String string2, int size) =>
      _channel.invokeMethod('printLeftRight',
          {'string1': string1, 'string2': string2, 'size': size});

  Future<dynamic> printSeparator(
          String karakter, int jumlah_karakter, int line) =>
      _channel.invokeMethod('printSeparator', {
        'karakter': karakter,
        'jumlah_karakter': jumlah_karakter,
        'line': line
      });
}

class BluetoothDevice {
  final String? name;
  final String? address;
  final int type = 0;
  bool connected = false;

  BluetoothDevice(this.name, this.address);

  BluetoothDevice.fromMap(Map map)
      : name = map['name'],
        address = map['address'];

  Map<String, dynamic> toMap() => {
        'name': this.name,
        'address': this.address,
        'type': this.type,
        'connected': this.connected,
      };

  operator ==(Object other) {
    return other is BluetoothDevice && other.address == this.address;
  }

  @override
  int get hashCode => address.hashCode;
}

enum PrinterBluetoothDriver {
  generic,
  mPop,
}
