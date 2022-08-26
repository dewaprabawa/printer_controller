
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_100x75mm_label.dart';

class HoneywellDriver extends PrinterDriver {
  @override
  PrinterCommand get commandType => PrinterCommand.TSC;

  @override
  final List<PaperSize> paperSizeList = [
    PaperSize100x75mmLabel(),
  ];

}
