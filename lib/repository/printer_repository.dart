import 'package:printer_controller/hardware_printer_device/print_data.dart';

abstract class PrinterRepository {
 Future<bool> startPrintToAllConnectedDevice
(PrintData data);
}