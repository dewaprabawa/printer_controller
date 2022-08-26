
import 'package:printer_controller/hardware_printer_device/drivers/generic_printer_driver.dart';

class SunmiT2MiniPrinterDriver extends GenericPrinterDriver {

  @override
  final List<int> CASHDRAWER_1 = [0x10, 0x14, 0x00, 0x00, 0x00];
}