import 'package:printer_controller/device_source/bluetooth_printer_device.dart';
import 'package:printer_controller/device_source/printer_device.dart';
import 'package:printer_controller/device_source/wlan_printer_device.dart';
import 'package:printer_controller/hardware_printer_device/print_data.dart';

class PrinterDeviceFactory{
  static PrinterDeviceFactory? _instance;
  static get instance {
    _instance ??= PrinterDeviceFactory._internal();
    return _instance;
  }
  PrinterDeviceFactory._internal();


  static PrinterDevice createPrinterDevice({required ConnectionType connectionType}){
    switch(connectionType){
      case ConnectionType.USB:
         return WlanPrinterDevice();
      case ConnectionType.BLUETOOTH:
        // TODO: Handle this case.
        return BluetoothPrinterDevice();
      case ConnectionType.WIFI:
        // TODO: Handle this case.
        return BluetoothPrinterDevice();
    }
  }
}