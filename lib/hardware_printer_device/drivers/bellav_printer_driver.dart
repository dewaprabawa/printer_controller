
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_58mm.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_76mm.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size_80mm.dart';

class BellavPrinterDriver extends PrinterDriver {
  @override
  final List<PaperSize> paperSizeList = [
    PaperSize58mmBellav(),
    PaperSize76mm(),
    PaperSize80mm(),
  ];

  @override
  final bool isNeedDelay = true;
}
