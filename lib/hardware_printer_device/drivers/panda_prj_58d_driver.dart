
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';

class PandaPRJ58DPrinterDriver extends PrinterDriver {
  @override
  bool isCutLine = false;

  @override
  List<int> INIT = [];

  @override
  List<int> POST_PRINT = [10, 10];
}
