import 'package:printer_controller/hardware_printer_device/paper_sizes/paper_size.dart';

class PaperSize80mm implements PaperSize{
  @override
  int get characterLength => 48;

  @override
  int get lineLength => 0;

  @override
  String get name => '80mm';

  @override
  PaperType get paperType => PaperType.continuous;

  @override
  int get height => 0;

  @override
  int get width => 80;

  @override
  int get maxImageWidth => 576;
}