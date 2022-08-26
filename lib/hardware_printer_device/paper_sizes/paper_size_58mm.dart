
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize58mm extends PaperSize{
  @override
  int get characterLength => 32;

  @override
  int get lineLength => 0;

  @override
  String get name => '58mm';

  @override
  PaperType get paperType => PaperType.continuous;

  @override
  int get height => 0;

  @override
  int get width => 58;

  @override
  int get maxImageWidth => 384;

}

class PaperSize58mmBellav extends PaperSize58mm {
  @override
  int get characterLength => 31;
}

