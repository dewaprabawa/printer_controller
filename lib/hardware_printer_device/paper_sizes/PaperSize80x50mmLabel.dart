import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize80x50mmLabel extends PaperSize{
  @override
  int get characterLength => 48;

  @override
  int get lineLength => 0;

  @override
  String get name => '80x50mm';

  @override
  PaperType get paperType => PaperType.label;

  @override
  int get height => 50;

  @override
  int get width => 80;

}