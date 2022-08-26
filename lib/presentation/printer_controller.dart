
import 'dart:async';

import 'package:printer_controller/hardware_printer_device/print_data.dart';
import 'package:printer_controller/repository/printer_repository.dart';
import 'package:printer_controller/repository/printer_repository_impl.dart';

class PrinterController implements PrinterRepository {

  @override
  Future<bool> startPrintToAllConnectedDevice(PrintData data) async {
    // TODO: implement startPrintToAllConnectedDevice
    return await PrinterRepositoryImpl().startPrintToAllConnectedDevice(data);
  }

}