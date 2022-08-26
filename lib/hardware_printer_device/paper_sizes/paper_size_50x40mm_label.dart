
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize50x40mmLabel extends PaperSize{
  @override
  int get characterLength => 32;

  @override
  int get lineLength => 0;

  @override
  String get name => '50x40mm';

  @override
  PaperType get paperType => PaperType.label;

  @override
  int get height => 40;

  @override
  int get width => 50;

}