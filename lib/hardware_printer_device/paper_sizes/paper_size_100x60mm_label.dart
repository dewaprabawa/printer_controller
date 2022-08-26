
import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize100x60mmLabel extends PaperSize{
  @override
  int get characterLength => 60;

  @override
  int get lineLength => 0;

  @override
  String get name => '100x60mm';

  @override
  PaperType get paperType => PaperType.label;

  @override
  int get height => 60;

  @override
  int get width => 100;

}