import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize100x75mmLabel extends PaperSize{
  @override
  int get characterLength => 60;

  @override
  int get lineLength => 0;

  @override
  String get name => '100x75mm';

  @override
  PaperType get paperType => PaperType.label;

  @override
  int get height => 75;

  @override
  int get width => 100;

}