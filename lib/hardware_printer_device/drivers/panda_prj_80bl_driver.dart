
import 'package:printer_controller/hardware_printer_device/drivers/printer_driver.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/PaperSize80x50mmLabel.dart';
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';
import 'package:printer_controller/shared/printer_helper_constant.dart';

class PandaPrj80BlDriver extends PrinterDriver {
  @override
  PrinterCommand get commandType => PrinterCommand.TSC;

  @override
  final List<PaperSize> paperSizeList = [
    PaperSize80x50mmLabel(),
  ];

  @override
  final List<int> characterLengths = [
    PrinterHelperConstant.PRINTER_JUMLAHKARAKTER_TIPE_KERTAS_LABEL_80x50MM,
  ];

  @override
  List<int> POST_PRINT = [10, 10];
}
